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
  void mem_write_callback(hart::Model &model, const char *type, sbits paddr, uint64_t width, lbits value) override;
  void mem_read_callback(hart::Model &model, const char *type, sbits paddr, uint64_t width, lbits value) override;
  void xreg_full_write_callback(hart::Model &model, const_sail_string abi_name, sbits reg, sbits value) override;
  void freg_write_callback(hart::Model &model, unsigned reg, sbits value) override;
  void csr_full_write_callback(hart::Model &model, const_sail_string csr_name, unsigned reg, sbits value) override;
  void csr_full_read_callback(hart::Model &model, const_sail_string csr_name, unsigned reg, sbits value) override;
  void vreg_write_callback(hart::Model &model, unsigned reg, lbits value) override;
  // Page table walk callback
  void ptw_start_callback(
    hart::Model &model,
    uint64_t vpn,
    hart::zMemoryAccessTypezIEmem_payloadz5zK access_type,
    hart::ztuple_z8z5enumz0zzPrivilegezCz0z5unitz9 privilege,
    bool is_pure_lookup
  ) override;
  void ptw_step_callback(hart::Model &model, int64_t level, sbits pte_addr, uint64_t pte, bool is_pure_lookup) override;
  void ptw_success_callback(hart::Model &model, uint64_t final_ppn, int64_t level, bool is_pure_lookup) override;
  void ptw_fail_callback(
    hart::Model &model,
    struct hart::zPTW_Error error_type,
    int64_t level,
    sbits pte_addr,
    bool is_pure_lookup
  ) override;
  void tlb_add_callback(
    hart::Model &model,
    hart::zz5vecz8z5unionz0zzoptionzzIRTLB_EntryzzKz9 tlb,
    uint64_t index
  ) override;
  void tlb_flush_begin_callback(hart::Model &model) override;
  void tlb_flush_callback(hart::Model &model, uint64_t index) override;
  void tlb_flush_end_callback(hart::Model &model, hart::zz5vecz8z5unionz0zzoptionzzIRTLB_EntryzzKz9 tlb) override;

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
