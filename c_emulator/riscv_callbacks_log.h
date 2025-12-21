#pragma once
#include "riscv_callbacks_if.h"
#include "sail.h"

class log_callbacks : public callbacks_if {

public:
  explicit log_callbacks(
    bool config_print_reg = true,
    bool config_print_mem_access = true,
    bool config_print_ptw = true,
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
    hart::zMemoryAccessTypezIuzK access_type,
    hart::ztuple_z8z5enumz0zzPrivilegezCz0z5unitz9 privilege
  ) override;
  void ptw_step_callback(hart::Model &model, int64_t level, sbits pte_addr, uint64_t pte) override;
  void ptw_success_callback(hart::Model &model, uint64_t final_ppn, int64_t level) override;
  void ptw_fail_callback(
    hart::Model &model,
    struct hart::zPTW_Error error_type,
    int64_t level,
    sbits pte_addr
  ) override;

private:
  bool config_print_reg;
  bool config_print_mem_access;
  bool config_use_abi_names;
  bool config_print_ptw;
  FILE *trace_log;
};
