#pragma once
#include "riscv_callbacks_if.h"
#include "sail.h"

class log_callbacks : public callbacks_if {

public:
  explicit log_callbacks(
    bool config_print_gpr = true,
    bool config_print_fpr = true,
    bool config_print_vreg = true,
    bool config_print_csr = true,
    bool config_print_mem_access = true,
    bool config_print_ptw = true,
    bool config_print_tlb = true,
    bool config_use_abi_names = false,

    FILE *trace_log = nullptr
  );

  // callbacks_if
  void mem_write_callback(ModelImpl &model, const char *type, sbits paddr, int64_t width, lbits value) override;
  void mem_read_callback(ModelImpl &model, const char *type, sbits paddr, int64_t width, lbits value) override;
  void xreg_full_write_callback(ModelImpl &model, const_sail_string abi_name, sbits reg, sbits value) override;
  void freg_write_callback(ModelImpl &model, unsigned reg, sbits value) override;
  void csr_full_write_callback(ModelImpl &model, const_sail_string csr_name, unsigned reg, sbits value) override;
  void csr_full_read_callback(ModelImpl &model, const_sail_string csr_name, unsigned reg, sbits value) override;
  void vreg_write_callback(ModelImpl &model, unsigned reg, lbits value) override;
  // Page table walk callback
  void ptw_start_callback(
    ModelImpl &model,
    uint64_t vpn,
    ModelImpl::MemoryAccessType access_type,
    ModelImpl::Privilege privilege
  ) override;
  void ptw_step_callback(ModelImpl &model, int64_t level, sbits pte_addr, uint64_t pte) override;
  void ptw_success_callback(ModelImpl &model, uint64_t final_ppn, int64_t level) override;
  void ptw_fail_callback(ModelImpl &model, ModelImpl::PTW_Error error_type, int64_t level, sbits pte_addr) override;
  void tlb_add_callback(ModelImpl &model, ModelImpl::TLB_Entry tlb, uint64_t index) override;
  void tlb_flush_begin_callback(ModelImpl &model) override;
  void tlb_flush_callback(ModelImpl &model, uint64_t index) override;
  void tlb_flush_end_callback(ModelImpl &model, ModelImpl::TLB_Entry tlb) override;

private:
  bool config_print_gpr;
  bool config_print_fpr;
  bool config_print_vreg;
  bool config_print_csr;
  bool config_print_mem_access;
  bool config_use_abi_names;
  bool config_print_ptw;
  bool config_print_tlb;
  FILE *trace_log;
};
