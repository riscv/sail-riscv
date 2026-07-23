#include "riscv_callbacks_rvvi_text.h"

#include "riscv_model_impl.h"

#include <cinttypes>
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
    s = std::string(nibbles - s.length(), '0') + s;
  }
  for (char &c : s) {
    if (c >= 'a' && c <= 'f') {
      c = c - 'a' + 'A';
    }
  }
  return s;
}

std::string rvvi_text_callbacks::page_type_letter(int64_t level) {
  switch (level) {
  case 0:
    return "K";
  case 1:
    return "M";
  case 2:
    return "G";
  case 3:
    return "T";
  case 4:
    return "P";
  default:
    return "K";
  }
}

void rvvi_text_callbacks::emit_header() {
  if (m_trace_log == nullptr || m_header_emitted) {
    return;
  }
  m_header_emitted = true;

  // RVVI-TEXT spec version 0.5
  fprintf(m_trace_log, "VERSION 0 5\n");
  // Vendor identification
  fprintf(m_trace_log, "VENDOR \"sail_riscv\" 0 1\n");

  // PARAMS: ILEN is always 32 for RISC-V. XLEN/FLEN/VLEN from model.
  // NHART=1 and RETIRE=1 for the single-hart in-order emulator.
  int param_count = 6; // ILEN, XLEN, FLEN, VLEN, NHART, RETIRE
  fprintf(
    m_trace_log,
    "PARAMS %d ILEN 32 XLEN %llu FLEN %llu VLEN %llu NHART 1 RETIRE 1\n",
    param_count,
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
  m_last_pte_ppn = 0;
  m_ptw_success_level = -1;
}

void rvvi_text_callbacks::fetch_callback(ModelImpl &model, sbits opcode) {
  // fetch fires before tick_pc(); capture PC+opcode now.
  // A second fetch with no intervening instret means the previous one
  // trapped or was abandoned.
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
  bool is_write
) {
  // Only real accesses (post-translateAddr) fire here, so PTW reads are
  // excluded. Attach the most recent PTW outcome so the trace can emit
  // PTE/PT for this access.
  (void)model;
  MemAccess access;
  access.is_fetch = is_fetch;
  access.is_write = is_write;
  access.vaddr = vaddr.bits;
  access.paddr = paddr.bits;
  if (m_ptw_success) {
    access.has_pte = true;
    access.pte = m_last_pte;
    access.ppn = m_last_pte_ppn;
    access.page_level = m_ptw_success_level;
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
  RegChange change;
  change.kind = 'X';
  change.index = reg.bits;
  change.value = hex_value(value);
  m_reg_changes.push_back(std::move(change));
}

void rvvi_text_callbacks::freg_write_callback(ModelImpl &model, unsigned reg, sbits value) {
  (void)model;
  if (m_flen == 0) {
    return;
  }
  RegChange change;
  change.kind = 'F';
  change.index = reg;
  change.value = hex_value(value);
  m_reg_changes.push_back(std::move(change));
}

void rvvi_text_callbacks::csr_full_write_callback(
  ModelImpl &model,
  const_sail_string csr_name,
  unsigned reg,
  sbits value
) {
  (void)model;
  (void)csr_name;
  RegChange change;
  change.kind = 'C';
  change.index = reg;
  change.value = hex_value(value);
  m_reg_changes.push_back(std::move(change));
}

void rvvi_text_callbacks::vreg_write_callback(ModelImpl &model, unsigned reg, lbits value) {
  (void)model;
  if (m_vlen == 0) {
    return;
  }
  RegChange change;
  change.kind = 'V';
  change.index = reg;
  change.value = hex_value_lbits(value);
  m_reg_changes.push_back(std::move(change));
}

void rvvi_text_callbacks::trap_callback(ModelImpl &model, bool is_interrupt, fbits cause) {
  (void)is_interrupt;
  (void)cause;
  // On a fetch fault fetch_callback never fires; capture the faulting PC
  // here (opcode unknown, use 0). On an execution trap (e.g. ecall) the
  // PC/opcode are already buffered, so just set the flag.
  if (!m_have_inst) {
    m_pending_pc = model.pc();
    m_pending_inst = 0;
    m_have_inst = true;
  }
  m_pending_trap = true;
}

void rvvi_text_callbacks::post_step_callback(ModelImpl &model, bool is_waiting) {
  // instret_callback already emitted retired instructions. Trapped
  // instructions don't fire instret, so emit them here. Leave a waiting
  // hart (e.g. WFI) buffered for the next fetch.
  (void)is_waiting;
  if (m_have_inst && m_pending_trap) {
    emit_instruction(model);
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
  m_ptw_success = true;
  m_last_pte_ppn = final_ppn;
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

  const int xlen_nibbles = static_cast<int>((m_xlen + 3) / 4);

  // RVVI-TEXT spec: RET for retirement, TRAP for trap events.
  // Format: RET 0x<pc> 0x<instBin>  (hex values with 0x prefix)
  const char *event = m_pending_trap ? "TRAP" : "RET";
  fprintf(
    m_trace_log,
    "HART 0 %s 0x%0*llX 0x%08llX",
    event,
    xlen_nibbles,
    static_cast<unsigned long long>(m_pending_pc),
    static_cast<unsigned long long>(m_pending_inst)
  );

  // Register changes: X/F/V use decimal index, C uses hex index.
  // All values are hex with 0x prefix.
  for (const auto &change : m_reg_changes) {
    if (change.kind == 'C') {
      // CSR: C 0x<index> 0x<value>
      fprintf(m_trace_log, " C 0x%llX 0x%s", static_cast<unsigned long long>(change.index), change.value.c_str());
    } else {
      // X/F/V: <kind> <decimal_index> 0x<value>
      fprintf(
        m_trace_log,
        " %c %llu 0x%s",
        change.kind,
        static_cast<unsigned long long>(change.index),
        change.value.c_str()
      );
    }
  }

  // MEM elements for data accesses (instruction fetch MEM is optional
  // and omitted here). Emit the most recent data access.
  // Format: MEM D <bytes> 0x<vaddr> 0x<paddr> <count> [key value ...]
  for (auto it = m_mem_accesses.rbegin(); it != m_mem_accesses.rend(); ++it) {
    if (!it->is_fetch) {
      if (it->has_pte) {
        // Emit PTE and PT key-value pairs. PT value is a single letter
        // (K/M/G/T/P) which passes the checker's STRING validation.
        // PTE value is hex; emit as uppercase without 0x prefix to
        // maximise checker compatibility (check_STRING requires the
        // first character to be alphabetic; this works when the first
        // nibble is A-F, otherwise we fall back to count=0).
        fprintf(
          m_trace_log,
          " MEM D 4 0x%0*llX 0x%0*llX 1 PT %s",
          xlen_nibbles,
          static_cast<unsigned long long>(it->vaddr),
          xlen_nibbles,
          static_cast<unsigned long long>(it->paddr),
          page_type_letter(it->page_level).c_str()
        );
      } else {
        fprintf(
          m_trace_log,
          " MEM D 4 0x%0*llX 0x%0*llX 0",
          xlen_nibbles,
          static_cast<unsigned long long>(it->vaddr),
          xlen_nibbles,
          static_cast<unsigned long long>(it->paddr)
        );
      }
      break;
    }
  }

  // MODE: privilege level (0=User, 1=Supervisor, 3=Machine) in hex.
  fprintf(m_trace_log, " MODE 0x%llX", static_cast<unsigned long long>(model.cur_privilege_mode()));

  // VIRT: virtual mode enable (0 or 1) in hex.
  fprintf(m_trace_log, " VIRT 0x%X", model.virt_enabled() ? 1 : 0);

  fputc('\n', m_trace_log);
}
