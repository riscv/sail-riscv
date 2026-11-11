#pragma once

#include "riscv_callbacks_if.h"
#include "sail.h"

#include <cstdint>
#include <cstdio>
#include <map>
#include <memory>
#include <optional>
#include <string>
#include <vector>

class rvvi_text_callbacks : public callbacks_if {
public:
  rvvi_text_callbacks(FILE *trace_log);

  void pre_step_callback(ModelImpl &model, bool is_waiting) override;
  void post_step_callback(ModelImpl &model, bool is_waiting) override;
  void fetch_callback(ModelImpl &model, sbits pc, sbits opcode) override;
  void xreg_full_write_callback(ModelImpl &model, const_sail_string abi_name, sbits reg, sbits value) override;
  void freg_write_callback(ModelImpl &model, uint64_t reg, sbits value) override;
  void csr_full_write_callback(ModelImpl &model, const_sail_string csr_name, uint64_t reg, sbits value) override;
  void vreg_write_callback(ModelImpl &model, uint64_t reg, lbits value) override;
  void trigger_tdata_write_callback(ModelImpl &model, sbits tselect, int64_t tdata_num, sbits data) override;
  void interrupt_callback(ModelImpl &model, fbits cause) override;
  void exception_callback(ModelImpl &model, fbits cause, const ModelImpl::ExceptionContext &ctx) override;
  void address_translation_start_callback(
    ModelImpl &model,
    ModelImpl::TranslationStage stage,
    ModelImpl::Privilege privilege,
    sbits vaddr,
    ModelImpl::MemoryAccessType access
  ) override;
  void address_translated_callback(
    ModelImpl &model,
    ModelImpl::TranslationStage stage,
    sbits vaddr,
    sbits paddr,
    ModelImpl::MemoryAccessType access
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
    // Vector values are in `lbits`, others in `sbits`; use a string
    // as a common representation since they will be output as strings
    // anyway.
    std::string value;
  };
  using RegIdx = std::pair<char, uint64_t>;

  struct TriggerTdataChange {
    sbits tselect;
    int64_t tdata_num;
    sbits data;
  };

  struct PTWStep {
    int64_t level;
    sbits pte_addr;
    uint64_t pte;
  };
  struct MemoryAccess {
    char kind; // 'I', 'D'
    sbits paddr;
    sbits vaddr;
    int64_t width;
    std::optional<PTWStep> pte;
    std::optional<sbits> gpaddr;
    std::optional<PTWStep> gpte;
    // Whether this is an access to a PTE.  Accesses performed when
    // address translation is incomplete are PTE accesses.
    bool is_pte;

    std::string print(ModelImpl &model) const;
  };
  struct FaultingAccess {
    sbits vaddr;
    bool is_fetch;
  };

  struct TranslationState {
    sbits vaddr = {0, 0};
    ModelImpl::MemoryAccessType access_type;
    std::optional<sbits> paddr;
    std::optional<PTWStep> last_ptw_step;

    void reset() {
      vaddr = {0, 0};
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
    ModelImpl &model,
    ModelImpl::Privilege privilege,
    ModelImpl::MemoryAccessType access,
    sbits paddr,
    int64_t width,
    bool is_write
  );
  PTWStep record_ptw_step(
    ModelImpl &model,
    ModelImpl::TranslationStage stage,
    int64_t level,
    sbits pte_addr,
    uint64_t pte
  );
  static std::string print_faulting_access(ModelImpl &model, const FaultingAccess &fault);

  FILE *m_trace_log;
  bool m_header_emitted = false;

  // Register writes before the first fetch are reset/init, not
  // instruction side-effects.  Execution starts with the first fetch
  // or trap.
  bool m_execution_started = false;

  uint64_t m_event_pc = 0;
  sbits m_event_inst{};
  bool m_trapped = false;

  // The privilege mode is sampled at `pre_step`: the mode the insn
  // is fetched and executed in, not the mode after a trap/`xret`.
  ModelImpl::Privilege m_event_priv = hart::zMachine;
  bool m_event_virt = false;

  // register writes
  //
  // This is stored as a map so that only the last write is reported
  // (e.g. vector registers and CSRs may be written multiple times
  // during a single instruction).
  std::map<RegIdx, RegChange> m_reg_changes;
  std::optional<TriggerTdataChange> m_trigger_tdata_write;

  // memory accesses
  std::vector<MemoryAccess> m_mem_accesses;
  std::optional<TranslationState> m_sstage_translation;
  std::optional<VSTranslationState> m_vsstage_translation;
  std::optional<FaultingAccess> m_faulting_access;
};
