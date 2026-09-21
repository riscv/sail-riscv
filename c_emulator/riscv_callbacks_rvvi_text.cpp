#include "riscv_callbacks_rvvi_text.h"
#include "riscv_model_impl.h"
#include "sail.h"

#include <array>
#include <iomanip>
#include <sstream>

rvvi_text_callbacks::rvvi_text_callbacks(FILE *trace_log) : m_trace_log(trace_log) {
}

std::string rvvi_text_callbacks::hex_value(const sbits &value) {
  std::ostringstream str;
  const int nibbles = static_cast<int>((value.len + 3) / 4);
  str << "0x" << std::setw(nibbles) << std::hex << std::setfill('0') << value.bits;
  return str.str();
}

std::string rvvi_text_callbacks::hex_value_lbits(const lbits &value) {
  sail_string sstr = nullptr;
  CREATE(sail_string)(&sstr);
  hex_str_upper(&sstr, *value.bits);
  std::string str(sstr);
  KILL(sail_string)(&sstr);
  return str;
}

char rvvi_text_callbacks::page_type_letter(int64_t level) {
  static std::array<char, 5> letters{'K', 'M', 'G', 'T', 'P'};
  if (level >= 0 && level < letters.size()) {
    return letters.at(level);
  }
  return '?';
}

bool rvvi_text_callbacks::access_is_fetch(ModelImpl &model, ModelImpl::MemoryAccessType access) {
  return model.memory_access_type_to_string(access) == "X";
}

void rvvi_text_callbacks::emit_header(ModelImpl &model) {
  if (m_trace_log == nullptr || m_header_emitted) {
    return;
  }
  m_header_emitted = true;
  fprintf(m_trace_log, "VERSION 0 5\n");
  fprintf(m_trace_log, "VENDOR \"sail_riscv\" 0 1\n");
  fprintf(
    m_trace_log,
    "PARAMS 6 ILEN 32 XLEN %llu FLEN %llu VLEN %llu NHART 1 RETIRE 1\n",
    static_cast<unsigned long long>(model.xlen()),
    static_cast<unsigned long long>(model.has_float_registers() ? model.flen() : 0),
    static_cast<unsigned long long>(model.has_vector_registers() ? model.vlen() : 0)
  );
}

void rvvi_text_callbacks::reset_instruction_buffer() {
  m_pending_pc = 0;
  m_pending_inst = 0;
  m_have_inst = false;
  m_pending_trap = false;
  m_reg_changes.clear();
  m_mem_accesses.clear();
  m_ptw_success = false;
  m_last_pte = 0;
  m_ptw_success_level = -1;
}

void rvvi_text_callbacks::record_reg(char kind, uint64_t index, std::string value) {
  if (m_first_fetch_seen) {
    m_reg_changes.push_back({kind, index, std::move(value)});
  }
}

void rvvi_text_callbacks::fetch_callback(ModelImpl &model, sbits opcode) {
  emit_header(model);
  m_first_fetch_seen = true;
  m_event_mode = model.cur_privilege_mode();
  m_event_virt = model.virt_enabled() ? 1 : 0;
  // A second fetch without instret means the previous insn was abandoned.
  if (m_have_inst) {
    reset_instruction_buffer();
  }
  m_pending_pc = model.pc();
  m_pending_inst = opcode.bits;
  m_have_inst = true;
}

void rvvi_text_callbacks::vmem_access_callback(
  ModelImpl &model,
  sbits vaddr,
  sbits paddr,
  ModelImpl::MemoryAccessType access,
  int64_t width
) {
  MemAccess mem;
  mem.is_fetch = access_is_fetch(model, access);
  mem.width = width;
  mem.vaddr = vaddr.bits;
  mem.paddr = paddr.bits;
  if (m_ptw_success) {
    mem.has_pte = true;
    mem.pte = m_last_pte;
    mem.page_level = m_ptw_success_level;
    m_ptw_success = false;
  }
  m_mem_accesses.push_back(mem);
}

void rvvi_text_callbacks::xreg_full_write_callback(ModelImpl &, const_sail_string, sbits reg, sbits value) {
  record_reg('X', reg.bits, hex_value(value));
}

void rvvi_text_callbacks::freg_write_callback(ModelImpl &model, unsigned reg, sbits value) {
  if (model.has_float_registers()) {
    record_reg('F', reg, hex_value(value));
  }
}

void rvvi_text_callbacks::csr_full_write_callback(ModelImpl &, const_sail_string, unsigned reg, sbits value) {
  record_reg('C', reg, hex_value(value));
}

void rvvi_text_callbacks::vreg_write_callback(ModelImpl &model, unsigned reg, lbits value) {
  if (model.has_vector_registers()) {
    record_reg('V', reg, hex_value_lbits(value));
  }
}

void rvvi_text_callbacks::trap_callback(ModelImpl &model, bool, fbits) {
  // Fetch faults never call fetch_callback; capture the faulting PC here.
  emit_header(model);
  if (!m_have_inst) {
    m_pending_pc = model.pc();
    m_pending_inst = 0;
    m_have_inst = true;
  }
  m_pending_trap = true;
}

void rvvi_text_callbacks::post_step_callback(ModelImpl &model, bool) {
  // Retired insns are emitted from instret_callback. Traps skip instret.
  if (m_have_inst && m_pending_trap) {
    emit_instruction(model);
    reset_instruction_buffer();
  }
}

void rvvi_text_callbacks::ptw_step_callback(ModelImpl &, int64_t, sbits, uint64_t pte) {
  m_last_pte = pte;
}

void rvvi_text_callbacks::ptw_success_callback(ModelImpl &, uint64_t, int64_t level) {
  m_ptw_success = true;
  m_ptw_success_level = level;
}

void rvvi_text_callbacks::instret_callback(ModelImpl &model) {
  emit_instruction(model);
  reset_instruction_buffer();
}

void rvvi_text_callbacks::emit_instruction(ModelImpl &model) {
  if (m_trace_log == nullptr) {
    return;
  }

  const int xlen_nibbles = static_cast<int>((model.xlen() + 3) / 4);
  const char *event = m_pending_trap ? "TRAP" : "RET";
  fprintf(
    m_trace_log,
    "HART 0 %s 0x%0*llX 0x%08llX",
    event,
    xlen_nibbles,
    static_cast<unsigned long long>(m_pending_pc),
    static_cast<unsigned long long>(m_pending_inst)
  );

  for (const auto &change : m_reg_changes) {
    if (change.kind == 'C') {
      fprintf(m_trace_log, " C 0x%llX %s", static_cast<unsigned long long>(change.index), change.value.c_str());
    } else {
      fprintf(
        m_trace_log,
        " %c %llu %s",
        change.kind,
        static_cast<unsigned long long>(change.index),
        change.value.c_str()
      );
    }
  }

  for (const auto &access : m_mem_accesses) {
    if (access.width <= 0) {
      continue;
    }
    const char *bus = access.is_fetch ? "I" : "D";
    const int nbytes = static_cast<int>(access.width);
    if (access.has_pte) {
      fprintf(
        m_trace_log,
        " MEM %s %d 0x%0*llX 0x%0*llX 2 PTE 0x%0*llX PT %c",
        bus,
        nbytes,
        xlen_nibbles,
        static_cast<unsigned long long>(access.vaddr),
        xlen_nibbles,
        static_cast<unsigned long long>(access.paddr),
        xlen_nibbles,
        static_cast<unsigned long long>(access.pte),
        page_type_letter(access.page_level)
      );
    } else {
      fprintf(
        m_trace_log,
        " MEM %s %d 0x%0*llX 0x%0*llX 0",
        bus,
        nbytes,
        xlen_nibbles,
        static_cast<unsigned long long>(access.vaddr),
        xlen_nibbles,
        static_cast<unsigned long long>(access.paddr)
      );
    }
  }

  fprintf(m_trace_log, " MODE 0x%llX", static_cast<unsigned long long>(m_event_mode));
  fprintf(m_trace_log, " VIRT 0x%X\n", m_event_virt);
}
