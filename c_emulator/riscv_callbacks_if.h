#pragma once

#include "riscv_model_impl.h"
#include "sail.h"

class callbacks_if {
public:
  virtual ~callbacks_if() = default;

  // Callback invoked before each step
  virtual void pre_step_callback(ModelImpl &model, bool is_waiting);

  // Callback invoked after each step
  virtual void post_step_callback(ModelImpl &model, bool is_waiting);

  virtual void fetch_callback(ModelImpl &model, sbits opcode);

  virtual void mem_write_callback(ModelImpl &model, const char *type, sbits paddr, int64_t width, lbits value);

  virtual void mem_read_callback(ModelImpl &model, const char *type, sbits paddr, int64_t width, lbits value);

  virtual void mem_exception_callback(ModelImpl &model, sbits paddr, uint64_t num_of_exception);

  virtual void xreg_full_write_callback(ModelImpl &model, const_sail_string abi_name, sbits reg, sbits value);

  virtual void freg_write_callback(ModelImpl &model, unsigned reg, lbits value);

  virtual void csr_full_write_callback(ModelImpl &model, const_sail_string csr_name, unsigned reg, sbits value);

  virtual void csr_full_read_callback(ModelImpl &model, const_sail_string csr_name, unsigned reg, sbits value);

  virtual void vreg_write_callback(ModelImpl &model, unsigned reg, lbits value);

  virtual void pc_write_callback(ModelImpl &model, sbits new_pc);

  virtual void redirect_callback(ModelImpl &model, sbits new_pc);

  virtual void trap_callback(ModelImpl &model, bool is_interrupt, fbits cause);

  virtual void xret_callback(ModelImpl &model, bool is_mret);

  virtual void instret_callback(ModelImpl &model);

  // Page table walk callbacks
  virtual void ptw_start_callback(
    ModelImpl &model,
    uint64_t vpn,
    ModelImpl::MemoryAccessType access_type,
    ModelImpl::Privilege privilege
  );

  virtual void ptw_step_callback(ModelImpl &model, int64_t level, sbits pte_addr, uint64_t pte);

  virtual void ptw_success_callback(ModelImpl &model, uint64_t final_ppn, int64_t level);

  virtual void ptw_fail_callback(ModelImpl &model, ModelImpl::PTW_Error error_type, int64_t level, sbits pte_addr);

  virtual void tlb_add_callback(ModelImpl &model, ModelImpl::TLB tlb, uint64_t index);

  virtual void tlb_flush_begin_callback(ModelImpl &model);

  virtual void tlb_flush_callback(ModelImpl &model, uint64_t index);

  virtual void tlb_flush_end_callback(ModelImpl &model, ModelImpl::TLB tlb);
};
