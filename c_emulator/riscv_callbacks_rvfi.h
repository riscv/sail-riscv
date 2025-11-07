#pragma once
#include "sail.h"
#include "riscv_callbacks_if.h"

class rvfi_callbacks : public callbacks_if {

public:
  // callbacks_if
  void mem_write_callback(const char *type, sbits paddr, uint64_t width,
                          lbits value) override;
  void mem_read_callback(const char *type, sbits paddr, uint64_t width,
                         lbits value) override;
  void mem_exception_callback(sbits paddr, uint64_t num_of_exception) override;
  void xreg_full_write_callback(const_sail_string abi_name, sbits reg,
                                sbits value) override;
  void trap_callback(bool is_interrupt, fbits cause) override;
};

extern "C" {
// TODO: Move these implementations to C.
unit zrvfi_write(sbits paddr, int64_t width, lbits value);
unit zrvfi_read(sbits paddr, sail_int width, lbits value);
unit zrvfi_mem_exception(sbits paddr);
unit zrvfi_wX(int64_t reg, sbits value);
unit zrvfi_trap(unit);
}
