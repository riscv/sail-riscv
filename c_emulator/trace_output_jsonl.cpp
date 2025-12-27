#include "trace_output_jsonl.h"
#include "sail_riscv_model.h"

#include <cassert>
#include <cstdlib>
#include <iostream>
#include <stdexcept>

// Schema follows this Serde definition. Some notes:
//
//  * Tuples are represented as arrays.
//  * Optional values that are None are simply omitted.
//  * This uses unsigned 64-bit integers which some JSON libraries may not support.
//    You need to use one that does. This works fine in Python, Rust (serde_json),
//    and C++ (Nlohmann/JSON for Modern C++). For Javascript (JSON.parse) you
//    need to use the `reviver` parameter and parse `context.source` into a BigInt.
//
// #[derive(Serialize, Deserialize)]
// struct TraceEntry {
//     /// PC when this step was executed. This is always known and must be always present.
//     pc: u64,
//     /// PC for the next step. This is mostly redundant but useful for verifying branches
//     /// in verification flows where PC is forced every step.
//     next_pc: u64,
//     /// Whether this step involved a redirect (branch, jump, exception, etc).
//     /// If omitted defaults to `false`.
//     #[serde(default)]
//     redirect: bool,
//     /// Opcode may be missing e.g. for fetch faults.
//     opcode: Option<u32>,
//     /// On exception, this is equal to the cause. Mutually exclusive with interrupt.
//     exception: Option<u64>,
//     /// On interrupt, this is equal to the cause. Mutually exclusive with
//     /// exception. The top 'interrupt' bit of mstatus is not included.
//     interrupt: Option<u64>,
//     /// List of x/f/v/csr register writes. May be missing if none.
//     x: Vec<(u8, u64)>,
//     f: Vec<(u8, u64)>,
//     v: Vec<(u8, Vec<u8>)>,
//     csr: Vec<(u16, u64)>,
//     /// Loads and stores. May be missing if none.
//     loads: Vec<MemAccess>,
//     stores: Vec<MemAccess>,
// }
//
// #[derive(Serialize, Deserialize)]
// struct MemAccess {
//     /// Physical address.
//     paddr: u64,
//     /// Virtual address. TODO: Not included yet.
//     vaddr: u64,
//     /// Access width in bytes.
//     width: u8,
//     /// Value read or written.
//     value: Vec<u8>,
// }

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

void trace_output_jsonl::mem_write_callback(
  hart::Model &model,
  const char *type,
  sbits paddr,
  uint64_t width,
  lbits value
)

{
  if (!m_stores.empty()) {
    m_stores += ',';
  }
  assert(value.len % 8 == 0);
  std::vector<uint8_t> data((value.len + 7) / 8);
  mpz_export(data.data(), nullptr, -1, 1, 0, 0, *value.bits);

  m_stores += "{" + std::string("\"paddr\":") + std::to_string(paddr.bits) + "," + std::string("\"width\":") +
              std::to_string(width) + "," + std::string("\"value\":[");
  bool comma = false;
  for (unsigned v : data) {
    if (comma) {
      m_stores += ',';
      comma = true;
    }
    m_stores += std::to_string(v);
  }
  m_stores += "]}";
}

void trace_output_jsonl::mem_read_callback(
  hart::Model &model,
  const char *type,
  sbits paddr,
  uint64_t width,
  lbits value
) {
  if (!m_loads.empty()) {
    m_loads += ',';
  }
  assert(value.len % 8 == 0);
  std::vector<uint8_t> data((value.len + 7) / 8);
  mpz_export(data.data(), nullptr, -1, 1, 0, 0, *value.bits);

  m_loads += "{" + std::string("\"paddr\":") + std::to_string(paddr.bits) + "," + std::string("\"width\":") +
             std::to_string(width) + "," + std::string("\"value\":[");
  bool comma = false;
  for (unsigned v : data) {
    if (comma) {
      m_loads += ',';
      comma = true;
    }
    m_loads += std::to_string(v);
  }
  m_loads += "]}";
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

void trace_output_jsonl::csr_full_write_callback(hart::Model &, const_sail_string csr_name, unsigned reg, sbits value) {
  if (!m_csr_writes.empty()) {
    m_csr_writes += ',';
  }
  m_csr_writes += "[" + std::to_string(reg) + "," + std::to_string(value.bits) + "]";
}

void trace_output_jsonl::vreg_write_callback(hart::Model &model, unsigned reg, lbits value) {
  if (!m_v_writes.empty()) {
    m_v_writes += ',';
  }
  assert(value.len % 8 == 0);
  std::vector<uint8_t> data((value.len + 7) / 8);
  mpz_export(data.data(), nullptr, -1, 1, 0, 0, *value.bits);

  m_v_writes += "[" + std::to_string(reg) + ",[";
  bool comma = false;
  for (unsigned v : data) {
    if (comma) {
      m_v_writes += ',';
      comma = true;
    }
    m_v_writes += std::to_string(v);
  }
  m_v_writes += "]]";
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
