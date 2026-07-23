#include "riscv_callbacks_rvvi_text.h"

#include "riscv_model_impl.h"

#include <cctype>
#include <gmp.h>
#include <inttypes.h>

rvvi_text_callbacks::rvvi_text_callbacks(FILE *trace_log, uint64_t xlen, uint64_t flen, uint64_t vlen) :
    m_trace_log(trace_log),
    m_xlen(xlen),
    m_flen(flen),
    m_vlen(vlen) {
  emit_header();
}

std::string rvvi_text_callbacks::hex_value(const sbits &value) {
  const unsigned nibbles = static_cast<unsigned>((value.len + 3) / 4);
  char buf[32];
  snprintf(buf, sizeof(buf), "%0*" PRIX64, nibbles, value.bits);
  return std::string(buf);
}

std::string rvvi_text_callbacks::hex_value_lbits(const lbits &value) {
  const unsigned nibbles = static_cast<unsigned>((value.len + 3) / 4);
  char *raw = mpz_get_str(nullptr, 16, *value.bits);
  std::string s = raw ? raw : "";
  free(raw);
  if (s.length() < nibbles) {
    s.insert(0, nibbles - s.length(), '0');
  }
  for (char &c : s) {
    c = static_cast<char>(std::toupper(static_cast<unsigned char>(c)));
  }
  return s;
}

const char *rvvi_text_callbacks::page_type_letter(int64_t level) {
  static const char *const letters[] = {"K", "M", "G", "T", "P"};
  if (level >= 0 && level < 5) {
    return letters[level];
  }
  return "?";
}

void rvvi_text_callbacks::emit_header() {
  if (m_trace_log == nullptr || m_header_emitted) {
    return;
  }
  m_header_emitted = true;
  fprintf(m_trace_log, "VERSION 0 5\n");
  fprintf(m_trace_log, "VENDOR \"sail_riscv\" 0 1\n");
  fprintf(
    m_trace_log,
    "PARAMS 6 ILEN 32 XLEN %llu FLEN %llu VLEN %llu NHART 1 RETIRE 1\n",
    static_cast<unsigned long long>(m_xlen),
    static_cast<unsigned long long>(m_flen),
    static_cast<unsigned long long>(m_vlen)
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
  if (!m_first_fetch_seen) {
    return;
  }
  m_reg_changes.push_back({kind, index, std::move(value)});
}

void rvvi_text_callbacks::fetch_callback(ModelImpl &model, sbits opcode) {
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
  bool is_fetch,
  bool is_write,
  int64_t width
) {
  (void)model;
  MemAccess access;
  access.is_fetch = is_fetch;
  access.is_write = is_write;
  access.width = width;
  access.vaddr = vaddr.bits;
  access.paddr = paddr.bits;
  if (m_ptw_success) {
    access.has_pte = true;
    access.pte = m_last_pte;
    access.page_level = m_ptw_success_level;
    m_ptw_success = false;
  }
  m_mem_accesses.push_back(access);
}

void rvvi_text_callbacks::xreg_full_write_callback(
  ModelImpl &model,
  const_sail_string abi_name,
  sbits reg,
  sbits value
) {
  (void)model;
  (void)abi_name;
  record_reg('X', reg.bits, hex_value(value));
}

void rvvi_text_callbacks::freg_write_callback(ModelImpl &model, unsigned reg, sbits value) {
  (void)model;
  if (m_flen == 0) {
    return;
  }
  record_reg('F', reg, hex_value(value));
}

void rvvi_text_callbacks::csr_full_write_callback(
  ModelImpl &model,
  const_sail_string csr_name,
  unsigned reg,
  sbits value
) {
  (void)model;
  (void)csr_name;
  record_reg('C', reg, hex_value(value));
}

void rvvi_text_callbacks::vreg_write_callback(ModelImpl &model, unsigned reg, lbits value) {
  (void)model;
  if (m_vlen == 0) {
    return;
  }
  record_reg('V', reg, hex_value_lbits(value));
}

void rvvi_text_callbacks::trap_callback(ModelImpl &model, bool is_interrupt, fbits cause) {
  (void)is_interrupt;
  (void)cause;
  // Fetch faults never call fetch_callback; capture the faulting PC here.
  if (!m_have_inst) {
    m_pending_pc = model.pc();
    m_pending_inst = 0;
    m_have_inst = true;
  }
  m_pending_trap = true;
}

void rvvi_text_callbacks::post_step_callback(ModelImpl &model, bool is_waiting) {
  (void)model;
  (void)is_waiting;
  // Retired insns are emitted from instret_callback. Traps skip instret.
  if (m_have_inst && m_pending_trap) {
    emit_instruction();
    reset_instruction_buffer();
  }
}

void rvvi_text_callbacks::ptw_step_callback(ModelImpl &model, int64_t level, sbits pte_addr, uint64_t pte) {
  (void)model;
  (void)pte_addr;
  (void)level;
  m_last_pte = pte;
}

void rvvi_text_callbacks::ptw_success_callback(ModelImpl &model, uint64_t final_ppn, int64_t level) {
  (void)model;
  (void)final_ppn;
  m_ptw_success = true;
  m_ptw_success_level = level;
}

void rvvi_text_callbacks::instret_callback(ModelImpl &model) {
  (void)model;
  emit_instruction();
  reset_instruction_buffer();
}

void rvvi_text_callbacks::emit_instruction() {
  if (m_trace_log == nullptr) {
    return;
  }

  const int xlen_nibbles = static_cast<int>((m_xlen + 3) / 4);
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
      fprintf(m_trace_log, " C 0x%llX 0x%s", static_cast<unsigned long long>(change.index), change.value.c_str());
    } else {
      fprintf(
        m_trace_log,
        " %c %llu 0x%s",
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
        " MEM %s %d 0x%0*llX 0x%0*llX 2 PTE 0x%0*llX PT %s",
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
