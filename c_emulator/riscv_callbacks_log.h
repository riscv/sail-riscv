#pragma once
#include "sail.h"
#include "riscv_callbacks_if.h"

class log_callbacks : public callbacks_if {

public:
  log_callbacks(bool config_print_reg = true,
                bool config_print_mem_access = true,
                bool config_use_abi_names = false, FILE *trace_log = NULL);

  // callbacks_if
  void mem_write_callback(const char *type, sbits paddr, uint64_t width,
                          lbits value) override;
  void mem_read_callback(const char *type, sbits paddr, uint64_t width,
                         lbits value) override;
  void mem_exception_callback(sbits paddr, uint64_t num_of_exception) override;
  void xreg_full_write_callback(const_sail_string abi_name, sbits reg,
                                sbits value) override;
  void freg_write_callback(unsigned reg, sbits value) override;
  void csr_full_write_callback(const_sail_string csr_name, unsigned reg,
                               sbits value) override;
  void csr_full_read_callback(const_sail_string csr_name, unsigned reg,
                              sbits value) override;
  void vreg_write_callback(unsigned reg, lbits value) override;
  void pc_write_callback(sbits value) override;
  void trap_callback() override;

private:
  bool config_print_reg;
  bool config_print_mem_access;
  bool config_use_abi_names;
  FILE *trace_log;
};
