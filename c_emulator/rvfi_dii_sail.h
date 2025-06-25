#pragma once

#include "sail.h"

#ifdef __cplusplus
extern "C" {
#endif

// ****************************************************************************
// Sail API

mach_bits rvfi_get_cmd(unit);
mach_bits rvfi_get_insn(unit);

unit rvfi_set_pc_data_rdata(mach_bits data);
unit rvfi_set_pc_data_wdata(mach_bits data);

unit rvfi_set_inst_data_insn(mach_bits insn);
unit rvfi_set_inst_data_order(mach_bits);
unit rvfi_set_inst_data_mode(mach_bits);
unit rvfi_set_inst_data_ixl(mach_bits);

// ****************************************************************************

#ifdef __cplusplus
} // extern "C"
#endif
