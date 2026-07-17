#include "requests.h"
#include "gdb_run_info.h"
#include "parse_utils.h"

#include <cassert>
#include <cstdint>
#include <inttypes.h>
#include <iostream>
#include <sstream>

namespace {

class qsupported : public request::request_parser {
public:
  qsupported() = default;

  // qSupported [:gdbfeature [;gdbfeature]… ]
  std::optional<response_handler_ptr> parse(const std::string &cmd, gdb_run_info &) const override {
    std::vector<std::string> features;
    std::string tag{"qSupported"};
    auto idx = cmd.find(tag);
    if (idx != 0) {
      return std::nullopt;
    }
    idx += tag.length();
    if (idx < cmd.length() && cmd[idx] == ':') {
      ++idx;
    }

    auto last_idx = idx;
    idx = cmd.find(';', last_idx);
    while (idx != std::string::npos) {
      auto feature = cmd.substr(last_idx, idx - last_idx);
      features.emplace_back(feature);
      ++idx;
      last_idx = idx;
      idx = cmd.find(";", last_idx);
    }
    {
      auto feature = cmd.substr(last_idx);
      if (!feature.empty()) {
        features.emplace_back(feature);
      }
    }
    std::set<std::string> gdb_features(features.cbegin(), features.cend());
    return response_handler_ptr(new response::qsupported(std::move(gdb_features)));
  }
};

class empty_responses : public request::request_parser {
public:
  empty_responses() = default;

  std::optional<response_handler_ptr> parse(const std::string &cmd, gdb_run_info &) const override {
    static const std::vector<std::string> prefixes = {
      "vMustReplyEmpty",
      // We don't have threads or processes.
      "vCont?",
      "qTStatus",
      "qfThreadInfo",
      "qsThreadInfo",
      "qC",
      "qL",
      // `x` responses send binary data, which will require escaping.
      // The client will usually fall back to `m` packets.
      "x",

      // The below are specific to LLDB.
      "QListThreadsInStopReply",
      "qVAttachOrWaitSupported",
      "qProcessInfo",
      "qStructuredDataPlugins",
      "qShlibInfoAddr",
      "jThreadsInfo",
      "jThreadExtendedInfo:",
      // QSet* are currently inapplicable in our case.  This might
      // have to be periodically reviewed.
      "QSet",
      // This is intended more for process memory than system memory.
      "qMemoryRegionInfo:",
    };
    for (const auto &p : prefixes) {
      auto idx = cmd.find(p);
      if (idx == 0) {
        return response_handler_ptr(new response::empty_response());
      }
    }
    return std::nullopt;
  }
};

class simple : public request::request_parser {
public:
  simple() = default;

  std::optional<response_handler_ptr> parse(const std::string &cmd, gdb_run_info &) const override {
    // H op thread-id
    // "Set thread for subsequent operations (‘m’, ‘M’, ‘g’, ‘G’, et.al.)."
    if (cmd.find("H") == 0) {
      // Since we don't have any threads, send 'OK' for success.  Another
      // implementation choice seems to be to send an empty response (i.e. command
      // unknown).
      return response_handler_ptr(new response::ok());
    }
    if (cmd == "?") {
      return response_handler_ptr(new response::question());
    }
    if (cmd.find("qAttached") == 0) {
      return response_handler_ptr(new response::qattached());
    }
    if (cmd.find("qOffsets") == 0) {
      return response_handler_ptr(new response::qoffsets());
    }
    if (cmd.find("qSymbol::") == 0) {
      // We don't need symbol lookups.
      return response_handler_ptr(new response::ok());
    }
    if (cmd.find("QStartNoAckMode") == 0) {
      return response_handler_ptr(new response::qstartnoackmode());
    }
    if (cmd.find("g") == 0) {
      // LLDB sends thread-id suffixes, which we ignore since we don't have threads.
      return response_handler_ptr(new response::read_general_registers());
    }
    if (cmd == "k") {
      // treat this as a vKill;0
      return response_handler_ptr(new response::vkill(0));
    }
    if (cmd == "D" || cmd.find("D;") == 0) {
      // Treat detach as a no-op, since the debugger is likely to next
      // close the connection anyway.
      return response_handler_ptr(new response::ok());
    }
    // LLDB prefers thread suffixes on some packets.
    if (cmd.find("QThreadSuffixSupported") == 0) {
      return response_handler_ptr(new response::ok());
    }
    if (cmd.find("qHostInfo") == 0) {
      return response_handler_ptr(new response::qhostinfo());
    }
    if (cmd.find("QEnableErrorStrings") == 0) {
      return response_handler_ptr(new response::ok());
    }
    return std::nullopt;
  }
};

class qXfer_features_read : public request::request_parser {
public:
  qXfer_features_read() = default;

  // qXfer:features:read:annex:offset,length
  std::optional<response_handler_ptr> parse(const std::string &cmd, gdb_run_info &) const override {
    std::string tag{"qXfer:features:read:"};
    auto idx = cmd.find(tag);
    if (idx != 0) {
      return std::nullopt;
    }
    idx += tag.length();
    if (idx >= cmd.length()) {
      return std::nullopt;
    }
    // get annex
    auto last_idx = idx;
    idx = cmd.find(':', last_idx);
    if (idx == std::string::npos) {
      return std::nullopt;
    }
    auto annex = cmd.substr(last_idx, idx - last_idx);
    ++idx;
    if (idx >= cmd.length()) {
      return std::nullopt;
    }
    // get offset,length
    last_idx = idx;
    idx = cmd.find(',');
    if (idx == std::string::npos) {
      return std::nullopt;
    }
    uint64_t offset{};
    {
      auto offset_str = cmd.substr(last_idx, idx - last_idx);
      ++idx;
      if (idx >= cmd.length()) {
        return std::nullopt;
      }
      last_idx = idx;
      auto opt_offset = string_to_opt_uint64t(offset_str);
      if (!opt_offset.has_value()) {
        return std::nullopt;
      }
      offset = opt_offset.value();
    }
    uint64_t length{};
    {
      auto length_str = cmd.substr(last_idx);
      auto opt_length = string_to_opt_uint64t(length_str);
      if (!opt_length.has_value()) {
        return std::nullopt;
      }
      length = opt_length.value();
    }
    return response_handler_ptr(new response::qXfer_features_read(std::move(annex), offset, length));
  }
};

class read_register : public request::request_parser {
public:
  read_register() = default;

  // p n
  std::optional<response_handler_ptr> parse(const std::string &cmd, gdb_run_info &) const override {
    std::string tag{"p"};
    auto idx = cmd.find(tag);
    if (idx != 0) {
      return std::nullopt;
    }
    idx += tag.length();
    if (idx >= cmd.length()) {
      return std::nullopt;
    }
    auto last_idx = idx;
    // LLDB puts thread suffixes in these packets since we said this
    // was supported in QThreadSuffixSupported.
    // e.g. p0;thread:0001;
    idx = cmd.find(';', last_idx);
    if (idx == std::string::npos) {
      idx = cmd.length();
    }
    uint64_t regidx{};
    {
      auto reg_str = cmd.substr(last_idx, idx - last_idx);
      auto opt_reg = string_to_opt_uint64t(reg_str);
      if (!opt_reg.has_value()) {
        return std::nullopt;
      }
      regidx = opt_reg.value();
    }
    // Ignore any thread suffix since we don't have threads.
    return response_handler_ptr(new response::read_register(regidx));
  }
};

class write_register : public request::request_parser {
public:
  write_register() = default;

  // p n=r
  std::optional<response_handler_ptr> parse(const std::string &cmd, gdb_run_info &) const override {
    std::string tag{"P"};
    auto idx = cmd.find(tag);
    if (idx != 0) {
      return std::nullopt;
    }
    idx += tag.length();
    if (idx >= cmd.length()) {
      return std::nullopt;
    }
    auto last_idx = idx;
    idx = cmd.find('=', last_idx);
    if (idx == std::string::npos) {
      return std::nullopt;
    }
    uint64_t regidx{};
    {
      auto reg_str = cmd.substr(last_idx, idx - last_idx);
      auto opt_reg = string_to_opt_uint64t(reg_str);
      if (!opt_reg.has_value()) {
        return std::nullopt;
      }
      regidx = opt_reg.value();
    }
    ++idx;
    if (idx >= cmd.length()) {
      return std::nullopt;
    }
    last_idx = idx;
    // LLDB puts thread suffixes in these packets since we said this
    // was supported in QThreadSuffixSupported.
    // e.g. P20=1234abcd;thread:0001;
    idx = cmd.find(';', last_idx);
    if (idx == std::string::npos) {
      idx = cmd.length();
    }
    uint64_t regval{};
    {
      auto val_str = cmd.substr(last_idx, idx - last_idx);
      auto opt_val = string_to_opt_uint64t(val_str);
      if (!opt_val.has_value()) {
        return std::nullopt;
      }
      regval = opt_val.value();
    }
    // Ignore any thread suffix since we don't have threads.
    return response_handler_ptr(new response::write_register(regidx, regval));
  }
};

class read_memory : public request::request_parser {
public:
  read_memory() = default;

  // m addr,length
  std::optional<response_handler_ptr> parse(const std::string &cmd, gdb_run_info &) const override {
    std::string tag{"m"};
    auto idx = cmd.find(tag);
    if (idx != 0) {
      return std::nullopt;
    }
    idx += tag.length();
    if (idx >= cmd.length()) {
      return std::nullopt;
    }
    auto last_idx = idx;
    idx = cmd.find(',', last_idx);
    if (idx == std::string::npos) {
      return std::nullopt;
    }
    uint64_t addr{};
    {
      auto addr_str = cmd.substr(last_idx, idx - last_idx);
      ++idx;
      if (idx >= cmd.length()) {
        return std::nullopt;
      }
      last_idx = idx;
      auto opt_addr = string_to_opt_uint64t(addr_str);
      if (!opt_addr.has_value()) {
        return std::nullopt;
      }
      addr = opt_addr.value();
    }
    uint64_t length{};
    {
      auto length_str = cmd.substr(last_idx);
      auto opt_length = string_to_opt_uint64t(length_str);
      if (!opt_length.has_value()) {
        return std::nullopt;
      }
      length = opt_length.value();
    }
    return response_handler_ptr(new response::read_memory(addr, length));
  }
};

class single_step : public request::request_parser {
public:
  single_step() = default;

  // s [addr]
  std::optional<response_handler_ptr> parse(const std::string &cmd, gdb_run_info &info) const override {
    std::string tag{"s"};
    auto idx = cmd.find(tag);
    if (idx != 0) {
      return std::nullopt;
    }
    idx += tag.length();
    auto last_idx = idx;
    std::optional<uint64_t> addr{};
    if (last_idx < cmd.length()) {
      auto addr_str = cmd.substr(last_idx);
      auto opt_addr = string_to_opt_uint64t(addr_str);
      if (opt_addr.has_value()) {
        addr = opt_addr;
      } else {
        if (info.enable_trace) {
          fprintf(info.trace_log, "single_step: failed to parse step addr [%s]\n", addr_str.c_str());
        }
        return std::nullopt;
      }
    }
    return response_handler_ptr(new response::single_step(std::move(addr)));
  }
};

class forward_continue : public request::request_parser {
public:
  forward_continue() = default;

  // c [addr]
  std::optional<response_handler_ptr> parse(const std::string &cmd, gdb_run_info &info) const override {
    std::string tag{"c"};
    auto idx = cmd.find(tag);
    if (idx != 0) {
      return std::nullopt;
    }
    idx += tag.length();
    auto last_idx = idx;
    std::optional<uint64_t> addr{};
    if (last_idx < cmd.length()) {
      auto addr_str = cmd.substr(last_idx);
      auto opt_addr = string_to_opt_uint64t(addr_str);
      if (!opt_addr.has_value()) {
        if (info.enable_trace) {
          fprintf(info.trace_log, "forward_continue: failed to parse continue addr [%s]\n", addr_str.c_str());
        }
        return std::nullopt;
      }
      addr = std::move(opt_addr);
    }
    return response_handler_ptr(new response::forward_continue(std::move(addr)));
  }
};

class write_binary_data : public request::request_parser {
public:
  write_binary_data() = default;

  // X addr,length:XX...
  // `length` is in units of bytes (in `addressable memory units` really, but this is the same as bytes here).
  // `XX...` is binary data.
  std::optional<response_handler_ptr> parse(const std::string &cmd, gdb_run_info &info) const override {
    std::string tag{"X"};
    auto idx = cmd.find(tag);
    if (idx != 0) {
      return std::nullopt;
    }
    idx += tag.length();
    auto last_idx = idx;
    idx = cmd.find(",", last_idx);
    if (idx == std::string::npos) {
      return std::nullopt;
    }
    uint64_t addr{};
    {
      auto addr_str = cmd.substr(last_idx, idx - last_idx);
      ++idx;
      last_idx = idx;
      auto opt_addr = string_to_opt_uint64t(addr_str);
      if (!opt_addr.has_value()) {
        return std::nullopt;
      }
      addr = opt_addr.value();
    }
    idx = cmd.find(":", last_idx);
    if (idx == std::string::npos) {
      return std::nullopt;
    }
    uint64_t length{};
    {
      auto length_str = cmd.substr(last_idx, idx - last_idx);
      ++idx;
      last_idx = idx;
      auto opt_length = string_to_opt_uint64t(length_str);
      if (!opt_length.has_value()) {
        return std::nullopt;
      }
      length = opt_length.value();
    }
    // This string will have binary data (including possible '\0').
    std::string data = cmd.substr(idx);
    if (data.length() < length) {
      if (info.enable_trace) {
        std::ostringstream msg;
        msg << "write_binary_data: packet specifies " << length << " bytes of data, but payload has only "
            << data.length() << " bytes.";
        fprintf(info.trace_log, "%s\n", msg.str().c_str());
      }
      return std::nullopt;
    }
    if (data.length() > length) {
      if (info.enable_trace) {
        std::ostringstream msg;
        msg << "write_binary_data: packet specifies " << length << " bytes of data; trimming excess "
            << data.length() - length << " bytes from payload of " << data.length() << " bytes.";
        fprintf(info.trace_log, "%s\n", msg.str().c_str());
      }
      data.erase(length);
    }
    return response_handler_ptr(new response::write_binary_data(addr, length, std::move(data)));
  }
};

class vkill : public request::request_parser {
public:
  vkill() = default;

  // vKill;pid
  std::optional<response_handler_ptr> parse(const std::string &cmd, gdb_run_info &) const override {
    std::string tag{"vKill;"};
    auto idx = cmd.find(tag);
    if (idx != 0) {
      return std::nullopt;
    }
    idx += tag.length();
    if (idx >= cmd.length()) {
      return std::nullopt;
    }
    auto last_idx = idx;
    uint64_t pid{};
    {
      auto pid_str = cmd.substr(last_idx);
      auto opt_pid = string_to_opt_uint64t(pid_str);
      if (!opt_pid.has_value()) {
        return std::nullopt;
      }
      pid = opt_pid.value();
    }
    return response_handler_ptr(new response::vkill(pid));
  }
};

class trigger : public request::request_parser {
public:
  trigger() = default;
  // {Z,z}type,addr,kind’
  // type : {0,1,2,3,4}
  // kind is architecture specific for types 0 and 1 (breakpoints),
  // and specifies bytes to watch for types 2,3 and 4 (watchpoints).
  std::optional<response_handler_ptr> parse(const std::string &cmd, gdb_run_info &info) const override {
    std::string add_tag{"Z"};
    std::string remove_tag{"z"};
    auto add_idx = cmd.find(add_tag);
    auto remove_idx = cmd.find(remove_tag);
    if (add_idx != 0 && remove_idx != 0) {
      return std::nullopt;
    }
    response::TriggerCmd trigger_cmd = (add_idx == 0) ? response::TriggerCmd::Add : response::TriggerCmd::Remove;
    assert(add_tag.length() == remove_tag.length());
    auto idx = add_tag.length();
    if (idx >= cmd.length()) {
      return std::nullopt;
    }
    auto trigger_ch = cmd[idx];
    if (trigger_ch != '0' && trigger_ch != '1' && trigger_ch != '2' && trigger_ch != '3' && trigger_ch != '4') {
      return std::nullopt;
    }
    ++idx;
    if (idx >= cmd.length() || (cmd[idx] != ',')) {
      return std::nullopt;
    }
    ++idx;
    auto last_idx = idx;
    idx = cmd.find(",", last_idx);
    if (idx == std::string::npos) {
      return std::nullopt;
    }
    uint64_t addr{};
    {
      auto addr_str = cmd.substr(last_idx, idx - last_idx);
      auto opt_addr = string_to_opt_uint64t(addr_str);
      if (!opt_addr.has_value()) {
        return std::nullopt;
      }
      addr = opt_addr.value();
    }
    ++idx;
    if (idx >= cmd.length()) {
      return std::nullopt;
    }
    last_idx = idx;
    // The full format is
    //   Z0,addr,kind[;cond_list…][;cmds:persist,cmd_list…]
    idx = cmd.find(";", last_idx);
    if (idx == std::string::npos) {
      idx = cmd.length();
    } else {
      if (info.enable_trace) {
        fprintf(info.trace_log, "TODO: trigger::parse: handle optional args: [%s]\n", cmd.substr(last_idx).c_str());
      }
      return std::nullopt;
    }
    std::string kind_str = cmd.substr(last_idx, idx - last_idx);
    last_idx = idx;
    // Leave `kind` as a string for breakpoints.
    if (trigger_ch == '0' || trigger_ch == '1') {
      response::BreakpointType t =
        trigger_ch == '0' ? response::BreakpointType::Software : response::BreakpointType::Hardware;
      return response_handler_ptr(new response::breakpoint(t, trigger_cmd, addr, std::move(kind_str)));
    }
    // Convert `kind` into an `int` for watchpoints.
    uint64_t kind{};
    {
      auto opt_kind = string_to_opt_uint64t(kind_str);
      if (!opt_kind.has_value()) {
        return std::nullopt;
      }
      kind = opt_kind.value();
    }
    WatchType t = trigger_ch == '2' ? WatchType::Write : (trigger_ch == '3' ? WatchType::Read : WatchType::Access);
    return response_handler_ptr(new response::watchpoint(t, trigger_cmd, addr, kind));
  }
};

} // namespace

request_parsers::request_parsers() {
  parsers.push_back(request_parser_ptr(new qsupported()));
  parsers.push_back(request_parser_ptr(new empty_responses()));
  parsers.push_back(request_parser_ptr(new simple()));
  parsers.push_back(request_parser_ptr(new read_register()));
  parsers.push_back(request_parser_ptr(new write_register()));
  parsers.push_back(request_parser_ptr(new qXfer_features_read()));
  parsers.push_back(request_parser_ptr(new read_memory()));
  parsers.push_back(request_parser_ptr(new single_step()));
  parsers.push_back(request_parser_ptr(new write_binary_data()));
  parsers.push_back(request_parser_ptr(new forward_continue()));
  parsers.push_back(request_parser_ptr(new vkill()));
  parsers.push_back(request_parser_ptr(new trigger()));
}

const std::vector<request_parser_ptr> &request_parsers::get_parsers() const {
  return parsers;
}
