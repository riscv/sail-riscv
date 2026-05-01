#include "protocol_handler.h"
#include "connection.h"
#include "gdb_run_info.h"
#include "responses.h"
#include <iomanip>
#include <iostream>
#include <sstream>

// Reception

void protocol_handler::receive_data(const std::string &data) {
  m_parse_buffer += data;
  if (m_run_info.enable_trace) {
    fprintf(m_run_info.trace_log, "gdbserver <-- %s\n", data.c_str());
  }
  parse();
}

void protocol_handler::parse() {
  while (!m_parse_buffer.empty()) {
    char c = m_parse_buffer[0];

    // The protocol also includes notification packets starting with
    // '%' instead of '$'.  But the currently defined notification
    // packets are sent by the stub/server, not by the debugger
    // client.  So this parser does not handle notifications.
    if (c != '-' && c != '\x03' && c != '+' && c != '$') {
      std::cerr << "Leading $, + or ^C not found in [" << m_parse_buffer << "]" << std::endl;
      std::exit(EXIT_FAILURE);
    }

    if (c == '-') {
      std::cerr << "Peer indicates receipt error, requests retransmission; likely protocol error, exiting."
                << std::endl;
      std::exit(EXIT_FAILURE);
    }
    if (c == '\x03') {
      if (m_run_info.enable_trace) {
        fprintf(m_run_info.trace_log, "Received Ctrl^C!\n");
      }
      m_parse_buffer.erase(0, 1);
      auto resp = response::interrupt();
      resp.dispatch(*this, m_run_info);
      continue;
    }
    if (c == '+') {
      m_parse_buffer.erase(0, 1);
      continue;
    }
    // buffer begins with '$'.
    auto hash_idx = m_parse_buffer.find('#');
    if (hash_idx == std::string::npos || hash_idx + 2 >= m_parse_buffer.length()) {
      if (m_run_info.enable_trace) {
        fprintf(m_run_info.trace_log, "Incomplete request: [%s]\n", m_parse_buffer.c_str());
      }
      break;
    }
    // Handle checksum.
    int checksum = 0;
    for (std::string::size_type i = 1; i < hash_idx; ++i) {
      checksum += m_parse_buffer[i];
    }
    checksum &= 255;
    auto pkt_checksum_str = std::string(m_parse_buffer, hash_idx + 1, hash_idx + 3);
    int pkt_checksum = std::stoi(pkt_checksum_str, nullptr, 16);
    if (pkt_checksum != checksum) {
      std::cerr << "Checksum mismatch: computed " << checksum << " but got " << pkt_checksum << "(" << pkt_checksum_str
                << ")" << std::endl;
      std::cerr << " for msg " << m_parse_buffer << std::endl;
      std::exit(EXIT_FAILURE);
    }
    // Skip the leading '$' and checksum.
    auto raw_req = m_parse_buffer.substr(1, hash_idx - 1);
    m_parse_buffer.erase(0, hash_idx + 3);
    process_raw_request(std::move(raw_req));
  }
}

void protocol_handler::process_raw_request(std::string req) {
  // Unescape the buffer.
  std::string::size_type read_idx = 0, write_idx = 0, len = req.length();
  while (read_idx < len) {
    if (req[read_idx] == '}') {
      ++read_idx;
      req[write_idx] = static_cast<char>(req[read_idx] ^ 0x20);
    } else {
      req[write_idx] = req[read_idx];
    }
    ++read_idx;
    ++write_idx;
  }
  req.erase(write_idx);

  std::optional<response_handler_ptr> resp;
  for (auto &parser : m_parsers.get_parsers()) {
    resp = parser->parse(req, m_run_info);
    if (resp.has_value()) {
      break;
    }
  }
  if (resp.has_value()) {
    queue_response(std::move(resp.value()));
  } else {
    std::cerr << "Request was not recognized!" << std::endl;
    // TODO: We should generally send an unsupported response.  But we
    // don't send any response for now since the interaction stops
    // without a response and this helps to find remaining protocol
    // packets that may need to be supported.
  }
}

// Transmission

void protocol_handler::send_response(const std::string &resp) {
  std::string data;
  data.append("$");

  // TODO: escape special characters in `resp`.  This will be needed
  // if any response sends binary data, but there is no such response
  // as yet (e.g. the `x` request is responded to as not-supported).
  data.append(resp);

  data.append("#");
  {
    // Compute checksum.
    int checksum = 0;
    for (const auto &c : resp) {
      checksum += c;
    }
    checksum &= 255;
    std::stringstream cs;
    cs << std::setfill('0') << std::setw(2) << std::hex << checksum;
    data.append(cs.str());
  }
  send_data(data);
}

void protocol_handler::send_empty_response() {
  send_data("$#00");
}

void protocol_handler::send_data(const std::string &data) {
  if (m_run_info.enable_trace) {
    fprintf(m_run_info.trace_log, "gdbserver --> %s\n", data.c_str());
  }
  m_connection.send_data(data);
}

void protocol_handler::send_stop_reply() {
  if (m_model.htif_done()) {
    // Send `W AA`, where AA is the exit status in big-endian hex.
    auto exit_code = m_model.htif_exit_code();
    int n = static_cast<int>(sizeof(exit_code));
    std::ostringstream buf;
    buf << "W" << std::hex << std::setfill('0');
    for (int i = n - 1; i >= 0; --i) {
      unsigned byte = (exit_code >> (i * 8)) & 0xFF;
      buf << std::setw(2) << byte;
    }
    send_response(buf.str());
    return;
  }

  // Simulate being stopped by a breakpoint.
  send_response("S05");
}

// Queue management

void protocol_handler::queue_response(response_handler_ptr resp) {
  // Since we are always reading from the connection, in order to
  // receive asynchronous messages like interrupts (0x03), we might
  // receive new requests even before we've responded to the last one
  // (e.g. continue).  LLDB sometimes sends new requests even before
  // the previous request has been responded to.  We should not access
  // the model while it is executing in a continue response, so we
  // queue them up until the continue finishes.

  m_pending_responses.push_back(std::move(resp));
  handle_pending_responses();
}

void protocol_handler::handle_pending_responses() {
  while (!m_in_continue && !m_pending_responses.empty()) {
    auto resp = m_pending_responses.front();
    m_pending_responses.pop_front();
    if (!m_in_noack_mode) {
      send_data("+");
    }
    resp->dispatch(*this, m_run_info);
  }
}

// Execution helpers

void protocol_handler::do_step() {
  if (m_model.had_exception()) {
    if (m_run_info.enable_trace) {
      fprintf(m_run_info.trace_log, "Cannot execute step after exception.\n");
    }
    return;
  }

  if (m_model.htif_done()) {
    if (m_run_info.enable_trace) {
      fprintf(m_run_info.trace_log, "Cannot execute step after program exit.\n");
    }
    return;
  }

  m_model.try_step(m_step_no, /* exit_wait */ true);

  if (m_model.had_exception() || m_model.htif_done()) {
    return;
  }

  ++m_step_no;
  ++m_insn_cnt;

  if (m_insn_cnt == m_insns_per_tick) {
    m_model.tick_clock();
  }

  check_pc_breakpoint();
}

void protocol_handler::start_continue() {
  m_has_trapped = false;
  m_triggered = false;
  m_in_continue = true;

  auto parent(m_connection.shared_from_this());
  asio::post(m_executor, [parent, this]() {
    do_step();
    continue_continue();
  });
}

void protocol_handler::continue_continue() {
  if (m_has_trapped || m_triggered || m_interrupt_count || m_model.htif_done() || m_model.had_exception()) {
    end_continue();
    return;
  }

  auto parent(m_connection.shared_from_this());
  asio::post(m_executor, [parent, this]() {
    do_step();
    continue_continue();
  });
}

void protocol_handler::end_continue() {
  send_stop_reply();

  if (m_interrupt_count > 0) {
    --m_interrupt_count;
  }
  m_has_trapped = false;
  m_triggered = false;
  m_in_continue = false;

  // Handle any requests that arrived during the continue.
  handle_pending_responses();
}

// Callbacks.

void protocol_handler::trap_callback(ModelImpl &, bool, fbits) {
  m_has_trapped = true;
}

namespace {

// Zero upper bits of `s.bits` according to `s.len`.
inline uint64_t zero_hi(sbits s) {
  return s.bits & UINT64_MAX >> (64 - s.len);
}

} // namespace

// Trigger checks.
//
// When checking triggers below, make sure to not reset `m_triggered`
// if it was already set.

void protocol_handler::mem_write_callback(ModelImpl &, const char *, sbits paddr, int64_t width, lbits) {
  if (m_triggers.at_watchpoint(AccessType::Write, zero_hi(paddr), width)) {
    m_triggered = true;
  }
}

void protocol_handler::mem_read_callback(ModelImpl &, const char *, sbits paddr, int64_t width, lbits) {
  if (m_triggers.at_watchpoint(AccessType::Read, zero_hi(paddr), width)) {
    m_triggered = true;
  }
}

// Another approach would be to intercept the `pc_write_callback` and
// put the check there.
void protocol_handler::check_pc_breakpoint() {
  if (m_triggers.at_breakpoint(m_model.pc())) {
    m_triggered = true;
  }
}
