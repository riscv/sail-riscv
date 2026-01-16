#include "trace_output_jsonl.h"
#include "sail_riscv_model.h"

#include <cassert>
#include <cstdlib>
#include <iostream>
#include <stdexcept>
#include <vector>

// See `doc/jsonl` for the schema and documentation. Please update it if you make changes!

void trace_output_jsonl::open(const std::string &filename) {
  m_ofs.open(filename);
  if (!m_ofs) {
    throw std::runtime_error("Failed to open JSONL trace output file: " + filename);
  }
}

void trace_output_jsonl::close() {
  m_ofs.close();
}

void trace_output_jsonl::pre_step_callback(hart::Model &model, bool waiting) {
  if (waiting) {
    return;
  }

  m_ofs << "{\"pc\":" << model.zPC.bits;
}
void trace_output_jsonl::post_step_callback(hart::Model &, bool waiting) {
  if (waiting) {
    return;
  }

  if (!m_x_writes.empty()) {
    m_ofs << ",\"x\":[" << m_x_writes << "]";
  }
  if (!m_f_writes.empty()) {
    m_ofs << ",\"f\":[" << m_f_writes << "]";
  }
  if (!m_v_writes.empty()) {
    m_ofs << ",\"v\":[" << m_v_writes << "]";
  }
  if (!m_csr_writes.empty()) {
    m_ofs << ",\"csr\":[" << m_csr_writes << "]";
  }
  if (!m_loads.empty()) {
    m_ofs << ",\"loads\":[" << m_loads << "]";
  }
  if (!m_stores.empty()) {
    m_ofs << ",\"stores\":[" << m_stores << "]";
  }

  m_x_writes.clear();
  m_f_writes.clear();
  m_v_writes.clear();
  m_csr_writes.clear();
  m_loads.clear();
  m_stores.clear();

  m_ofs << "}\n";
}

void trace_output_jsonl::fetch_callback(hart::Model &, sbits opcode) {
  m_ofs << ",\"opcode\":" << opcode.bits;
}

// Append an lbits value as a JSON array of bytes to `out`. It must
// be a multiple of 8 bits.
static void append_lbits_array(std::string &out, lbits value) {
  assert(value.len % 8 == 0);
  std::vector<uint8_t> data((value.len + 7) / 8);
  mpz_export(data.data(), nullptr, -1, 1, 0, 0, *value.bits);

  out += '[';

  bool first = true;
  for (unsigned byte : data) {
    if (!first) {
      out += ',';
    }
    first = false;
    out += std::to_string(byte);
  }

  out += ']';
}

void trace_output_jsonl::mem_write_callback(hart::Model &, const char *, sbits paddr, uint64_t width, lbits value) {
  if (!m_stores.empty()) {
    m_stores += ',';
  }

  m_stores += "{\"paddr\":" + std::to_string(paddr.bits) + ",\"width\":" + std::to_string(width) + ",\"value\":";
  append_lbits_array(m_stores, value);
  m_stores += "}";
}

void trace_output_jsonl::mem_read_callback(hart::Model &, const char *, sbits paddr, uint64_t width, lbits value) {
  if (!m_loads.empty()) {
    m_loads += ',';
  }

  m_loads += "{\"paddr\":" + std::to_string(paddr.bits) + ",\"width\":" + std::to_string(width) + ",\"value\":";
  append_lbits_array(m_loads, value);
  m_loads += "}";
}

void trace_output_jsonl::xreg_full_write_callback(hart::Model &, const_sail_string, sbits reg, sbits value) {
  if (!m_x_writes.empty()) {
    m_x_writes += ',';
  }
  m_x_writes += "[" + std::to_string(reg.bits) + "," + std::to_string(value.bits) + "]";
}

void trace_output_jsonl::freg_write_callback(hart::Model &, unsigned reg, sbits value) {
  if (!m_f_writes.empty()) {
    m_f_writes += ',';
  }
  m_f_writes += "[" + std::to_string(reg) + "," + std::to_string(value.bits) + "]";
}

void trace_output_jsonl::csr_full_write_callback(hart::Model &, const_sail_string, unsigned reg, sbits value) {
  if (!m_csr_writes.empty()) {
    m_csr_writes += ',';
  }
  m_csr_writes += "[" + std::to_string(reg) + "," + std::to_string(value.bits) + "]";
}

void trace_output_jsonl::vreg_write_callback(hart::Model &, unsigned reg, lbits value) {
  if (!m_v_writes.empty()) {
    m_v_writes += ',';
  }

  m_v_writes += "[" + std::to_string(reg) + ",";
  append_lbits_array(m_v_writes, value);
  m_v_writes += "]";
}

void trace_output_jsonl::pc_write_callback(hart::Model &, sbits new_pc) {
  // This is always called at the end of a step with the next PC.
  // If it's a branch then redirect_callback will be called first with the same value.
  m_ofs << ",\"next_pc\":" << new_pc.bits;
}

void trace_output_jsonl::redirect_callback(hart::Model &, sbits) {
  m_ofs << ",\"redirect\":true";
}

void trace_output_jsonl::trap_callback(hart::Model &, bool is_interrupt, fbits cause) {
  if (is_interrupt) {
    m_ofs << ",\"interrupt\":" << cause;
  } else {
    m_ofs << ",\"exception\":" << cause;
  }
}
