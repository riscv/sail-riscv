#pragma once
#include "sail.h"

#ifdef __cplusplus
extern "C" {
#endif

unit mem_write_callback(const char *type, sbits paddr, uint64_t width,
                        lbits value);
unit mem_read_callback(const char *type, sbits paddr, uint64_t width,
                       lbits value);
unit mem_exception_callback(sbits paddr, uint64_t num_of_exception);
unit xreg_full_write_callback(const_sail_string abi_name, sbits reg,
                              sbits value);
unit freg_write_callback(unsigned reg, sbits value);
// `full` indicates that the name and index of the CSR are provided.
// 64 bit CSRs use a long_csr_write_callback Sail function that automatically
// makes two csr_full_write_callback calls on RV32.
unit csr_full_write_callback(const_sail_string csr_name, unsigned reg,
                             sbits value);
unit csr_full_read_callback(const_sail_string csr_name, unsigned reg,
                            sbits value);
unit vreg_write_callback(unsigned reg, lbits value);
unit pc_write_callback(sbits value);
unit trap_callback(unit);

#ifdef __cplusplus
}
#endif
