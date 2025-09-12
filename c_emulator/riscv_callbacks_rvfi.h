#pragma once
#include "sail.h"
#include "riscv_callbacks_if.h"

class rvfi_callbacks : public callbacks_if {

public:
  // callbacks_if
  void mem_write_callback(model::Model &model, const char *type, sbits paddr,
                          uint64_t width, lbits value) override;
  void mem_read_callback(model::Model &model, const char *type, sbits paddr,
                         uint64_t width, lbits value) override;
  void mem_exception_callback(model::Model &model, sbits paddr,
                              uint64_t num_of_exception) override;
  void xreg_full_write_callback(model::Model &model, const_sail_string abi_name,
                                sbits reg, sbits value) override;
  void freg_write_callback(model::Model &model, unsigned reg,
                           sbits value) override;
  void csr_full_write_callback(model::Model &model, const_sail_string csr_name,
                               unsigned reg, sbits value) override;
  void csr_full_read_callback(model::Model &model, const_sail_string csr_name,
                              unsigned reg, sbits value) override;
  void vreg_write_callback(model::Model &model, unsigned reg,
                           lbits value) override;
  void pc_write_callback(model::Model &model, sbits value) override;
  void trap_callback(model::Model &model) override;
};
