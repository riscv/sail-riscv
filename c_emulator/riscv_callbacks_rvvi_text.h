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
  void fetch_callback(ModelImpl &model, sbits pc, sbits opcode) override;
  void xreg_full_write_callback(ModelImpl &model, const_sail_string abi_name, sbits reg, sbits value) override;
  void freg_write_callback(ModelImpl &model, unsigned reg, sbits value) override;
  void csr_full_write_callback(ModelImpl &model, const_sail_string csr_name, unsigned reg, sbits value) override;
  void vreg_write_callback(ModelImpl &model, unsigned reg, lbits value) override;
  void trap_callback(ModelImpl &model, bool is_interrupt, fbits cause) override;
  void instret_callback(ModelImpl &model) override;
  void address_translation_start_callback(
    ModelImpl &model,
    ModelImpl::TranslationStage stage,
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
  void ptw_step_callback(
    ModelImpl &model,
    ModelImpl::TranslationStage stage,
    int64_t level,
    sbits pte_addr,
    uint64_t pte
  ) override;
  void mem_write_callback(
    ModelImpl &model,
    ModelImpl::Privilege privilege,
    ModelImpl::MemoryAccessType access,
    sbits paddr,
    int64_t width,
    lbits value
  ) override;
  void mem_read_callback(
    ModelImpl &model,
    ModelImpl::Privilege privilege,
    ModelImpl::MemoryAccessType access,
    sbits paddr,
    int64_t width,
    lbits value
  ) override;

private:
  struct RegChange {
    char kind; // 'X', 'F', 'V', 'C'
    uint64_t index;
    std::string value;
  };

  struct PTWStep {
    int64_t level;
    sbits pte_addr;
    uint64_t pte;
  };
  struct MemoryAccess {
    ModelImpl::MemoryAccessType access_type;
    sbits paddr;
    sbits vaddr;
    int64_t width;
    std::optional<PTWStep> pte;
    std::optional<sbits> gpaddr;
    std::optional<PTWStep> gpte;

    std::string print(ModelImpl &model) const;
  };

  struct TranslationState {
    sbits vaddr = {0, 0};
    int64_t width;
    std::optional<sbits> paddr;
    std::optional<PTWStep> last_ptw_step;

    void reset() {
      vaddr = {0, 0};
      width = 0;
      paddr.reset();
      last_ptw_step.reset();
    }
  };

  struct VSTranslationState {
    TranslationState vs_state;
    // A VS-stage translation may involve multiple G-stage translations.
    // This records the last one.
    std::optional<TranslationState> g_state;
  };

  void emit_header(ModelImpl &model);
  void emit_instruction(ModelImpl &model);
  void reset_instruction_buffer();
  void record_reg(char kind, uint64_t index, std::string value);
  void record_mem_access(
    ModelImpl::Privilege privilege,
    ModelImpl::MemoryAccessType access,
    sbits paddr,
    int64_t width
  );

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

  // memory accesses
  std::vector<MemoryAccess> m_mem_accesses;
  std::optional<TranslationState> m_sstage_translation;
  std::optional<VSTranslationState> m_vsstage_translation;
};
