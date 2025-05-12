#pragma once
#include "sail.h"

#ifdef __cplusplus
extern "C" {
#endif

unit mem_write_callback(uint64_t paddr, uint64_t width, lbits value);
unit mem_read_callback(const char *type, uint64_t paddr, uint64_t width,
                       lbits value);
unit mem_exception_callback(uint64_t paddr, uint64_t num_of_exception);
unit xreg_write_callback(unsigned reg, uint64_t value);
unit freg_write_callback(unsigned reg, uint64_t value);
// `full` indicates that the name and index of the CSR are provided.
// 64 bit CSRs use a long_csr_write_callback Sail function that automatically
// makes two csr_full_write_callback calls on RV32.
unit csr_full_write_callback(const_sail_string csr_name, unsigned reg,
                             uint64_t value);
unit csr_full_read_callback(const_sail_string csr_name, unsigned reg,
                            uint64_t value);
unit vreg_write_callback(unsigned reg, lbits value);
unit pc_write_callback(uint64_t value);
unit trap_callback(unit);

// TODO: Move these implementations to C.
unit zrvfi_write(uint64_t paddr, int64_t width, lbits value);
unit zrvfi_read(uint64_t paddr, sail_int width, lbits value);
unit zrvfi_mem_exception(uint64_t paddr);
unit zrvfi_wX(int64_t reg, uint64_t value);
unit zrvfi_trap();

#ifdef __cplusplus
}
#endif
