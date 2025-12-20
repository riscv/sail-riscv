#pragma once
#include "sail.h"
#include "riscv_callbacks_if.h"

class rvfi_callbacks : public callbacks_if {

public:
  // callbacks_if
  void mem_write_callback(hart::Model &model, const char *type, sbits paddr,
                          uint64_t width, lbits value) override;
  void mem_read_callback(hart::Model &model, const char *type, sbits paddr,
                         uint64_t width, lbits value) override;
  void mem_exception_callback(hart::Model &model, sbits paddr,
                              uint64_t num_of_exception) override;
  void xreg_full_write_callback(hart::Model &model, const_sail_string abi_name,
                                sbits reg, sbits value) override;
  void trap_callback(hart::Model &model, bool is_interrupt,
                     fbits cause, hart::zoptionzIUtrap_reasonzK reason) override;
};
