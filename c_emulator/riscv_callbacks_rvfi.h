#pragma once
#include "riscv_callbacks_if.h"
#include "sail.h"

class rvfi_callbacks : public callbacks_if {

public:
  // callbacks_if
  void mem_write_callback(ModelImpl &model, const char *type, sbits paddr, int64_t width, lbits value) override;
  void mem_read_callback(ModelImpl &model, const char *type, sbits paddr, int64_t width, lbits value) override;
  void mem_exception_callback(ModelImpl &model, sbits paddr, uint64_t num_of_exception) override;
  void xreg_full_write_callback(ModelImpl &model, const_sail_string abi_name, sbits reg, sbits value) override;
  void trap_callback(ModelImpl &model, bool is_interrupt, fbits cause) override;
};
