#pragma once

#include "riscv_callbacks_if.h"
#include "sail.h"

#include <cstdint>
#include <cstdio>
#include <memory>
#include <optional>
#include <string>
#include <vector>

class rvvi_text_callbacks : public callbacks_if {
public:
  rvvi_text_callbacks(FILE *trace_log);

  void post_step_callback(ModelImpl &model, bool is_waiting) override;
  void fetch_callback(ModelImpl &model, sbits opcode) override;
  void xreg_full_write_callback(ModelImpl &model, const_sail_string abi_name, sbits reg, sbits value) override;
  void freg_write_callback(ModelImpl &model, unsigned reg, sbits value) override;
  void csr_full_write_callback(ModelImpl &model, const_sail_string csr_name, unsigned reg, sbits value) override;
  void vreg_write_callback(ModelImpl &model, unsigned reg, lbits value) override;
  void trap_callback(ModelImpl &model, bool is_interrupt, fbits cause) override;
  void instret_callback(ModelImpl &model) override;
  void ptw_step_callback(
    ModelImpl &model,
    ModelImpl::TranslationStage stage,
    int64_t level,
    sbits pte_addr,
    uint64_t pte
  ) override;
  void address_translation_start_callback(
    ModelImpl &model,
    ModelImpl::Privilege privilege,
    sbits vaddr,
    ModelImpl::MemoryAccessType access,
    int64_t width
  ) override;
  void address_translated_callback(
    ModelImpl &model,
    ModelImpl::TranslationStage stage,
    sbits vaddr,
    sbits paddr,
    ModelImpl::MemoryAccessType access,
    int64_t width
  ) override;

private:
  struct RegChange {
    char kind; // 'X', 'F', 'V', 'C'
    uint64_t index;
    std::string value;
  };

  struct MemAccess {
    bool is_fetch = false;
    int64_t width = 0;
    uint64_t vaddr = 0;
    uint64_t paddr = 0;
    bool has_pte = false;
    uint64_t pte = 0;
    int64_t page_level = -1;
  };

  struct PTWStep {
    ModelImpl::TranslationStage stage;
    int64_t level;
    uint64_t pte_addr;
    uint64_t pte;
  };

  struct MemoryAccessTrace {
    MemoryAccessTrace(ModelImpl::Privilege p, uint64_t vaddr, ModelImpl::MemoryAccessType a, int64_t w) :
        privilege(p),
        virt_addr(vaddr),
        access_type(a),
        width(w) {};

    bool is_eligible(ModelImpl &model) const;

    std::string print(ModelImpl &model) const;

    ModelImpl::Privilege privilege;
    uint64_t virt_addr = 0;
    ModelImpl::MemoryAccessType access_type;
    int64_t width = 0;
    std::optional<uint64_t> guest_phys_addr;
    std::optional<uint64_t> phys_addr;
    std::vector<PTWStep> ptw_steps;
  };

  void emit_header(ModelImpl &model);
  void emit_instruction(ModelImpl &model);
  void reset_instruction_buffer();
  void record_reg(char kind, uint64_t index, std::string value);

  FILE *m_trace_log;
  bool m_header_emitted = false;
  // Writes before the first fetch are reset/init, not instruction side-effects.
  bool m_first_fetch_seen = false;

  uint64_t m_pending_pc = 0;
  uint64_t m_pending_inst = 0;
  bool m_have_inst = false;
  bool m_pending_trap = false;
  // Sampled at fetch: the mode the insn executed in, not the mode after a trap/xret.
  uint64_t m_event_mode = 3;
  unsigned m_event_virt = 0;
  std::vector<RegChange> m_reg_changes;
  std::vector<MemAccess> m_mem_accesses;

  std::vector<std::unique_ptr<MemoryAccessTrace>> m_mem_traces;
  std::unique_ptr<MemoryAccessTrace> m_cur_mem_trace;
};
