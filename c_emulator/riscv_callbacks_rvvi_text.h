#pragma once

#include "riscv_callbacks_if.h"
#include "sail.h"

#include <cstdint>
#include <cstdio>
#include <string>
#include <vector>

class rvvi_text_callbacks : public callbacks_if {
public:
  rvvi_text_callbacks(FILE *trace_log, uint64_t xlen, uint64_t flen, uint64_t vlen);

  void post_step_callback(ModelImpl &model, bool is_waiting) override;
  void fetch_callback(ModelImpl &model, sbits opcode) override;
  void vmem_access_callback(ModelImpl &model, sbits vaddr, sbits paddr, bool is_fetch, bool is_write) override;
  void xreg_full_write_callback(ModelImpl &model, const_sail_string abi_name, sbits reg, sbits value) override;
  void freg_write_callback(ModelImpl &model, unsigned reg, sbits value) override;
  void csr_full_write_callback(ModelImpl &model, const_sail_string csr_name, unsigned reg, sbits value) override;
  void vreg_write_callback(ModelImpl &model, unsigned reg, lbits value) override;
  void trap_callback(ModelImpl &model, bool is_interrupt, fbits cause) override;
  void instret_callback(ModelImpl &model) override;
  void ptw_step_callback(ModelImpl &model, int64_t level, sbits pte_addr, uint64_t pte) override;
  void ptw_success_callback(ModelImpl &model, uint64_t final_ppn, int64_t level) override;

private:
  // Per-instruction buffer, reset at the start of each step.
  struct RegChange {
    char kind;         // 'X', 'F', 'V', 'C'
    uint64_t index;    // decimal for X/F/V, hex for C
    std::string value; // bare hex, MSB-first, no 0x prefix
  };

  struct MemAccess {
    bool is_fetch = false;
    bool is_write = false;
    uint64_t vaddr = 0;
    uint64_t paddr = 0;
    // VM signals from the most recent PTW for this access.
    bool has_pte = false;
    uint64_t pte = 0;
    uint64_t ppn = 0;
    int64_t page_level = -1; // -1=unknown, 0=K 1=M 2=G 3=T 4=P
  };

  void emit_header();
  void emit_instruction(ModelImpl &model);
  void reset_instruction_buffer();

  static std::string hex_value(const sbits &value);
  static std::string hex_value_lbits(const lbits &value);
  // 0..4 -> page type letter per RVVI-TEXT spec (K/M/G/T/P).
  static std::string page_type_letter(int64_t level);

  FILE *m_trace_log;
  uint64_t m_xlen;
  uint64_t m_flen;
  uint64_t m_vlen;
  bool m_header_emitted = false;

  uint64_t m_pending_pc = 0;
  uint64_t m_pending_inst = 0;
  bool m_have_inst = false;
  bool m_pending_trap = false;
  std::vector<RegChange> m_reg_changes;
  std::vector<MemAccess> m_mem_accesses;
  // Most recent PTW outcome, attached to the next vmem_access_callback.
  bool m_ptw_success = false;
  uint64_t m_last_pte = 0;
  uint64_t m_last_pte_ppn = 0;
  int64_t m_ptw_success_level = -1;
};
