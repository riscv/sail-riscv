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
  void freg_write_callback(unsigned reg, sbits value) override;
  void csr_full_write_callback(const_sail_string csr_name, unsigned reg,
                               sbits value) override;
  void csr_full_read_callback(const_sail_string csr_name, unsigned reg,
                              sbits value) override;
  void vreg_write_callback(unsigned reg, lbits value) override;
  void pc_write_callback(sbits value) override;
  void trap_callback() override;
};

extern "C" {
// TODO: Move these implementations to C.
unit zrvfi_write(sbits paddr, int64_t width, lbits value);
unit zrvfi_read(sbits paddr, sail_int width, lbits value);
unit zrvfi_mem_exception(sbits paddr);
unit zrvfi_wX(int64_t reg, sbits value);
unit zrvfi_trap(unit);
}
