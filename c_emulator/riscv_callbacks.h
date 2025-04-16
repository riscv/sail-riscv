#pragma once
#include "sail.h"

#ifdef __cplusplus
extern "C" {
#endif

void zcsr_name_map_forwards(sail_string *rop, uint64_t);

unit mem_write_callback(uint64_t addr, uint64_t width, lbits value);
unit mem_read_callback(const char *type, uint64_t addr, uint64_t width,
                       lbits value);
unit mem_exception_callback(uint64_t addr, uint64_t num_of_exception);
unit xreg_write_callback(unsigned reg, uint64_t value);
unit freg_write_callback(unsigned reg, uint64_t value);
unit csr_write_callback(unsigned reg, uint64_t value);
unit csr_read_callback(unsigned reg, uint64_t value);
unit vreg_write_callback(unsigned reg, lbits value);
unit pc_write_callback(uint64_t value);

#ifdef __cplusplus
}
#endif
