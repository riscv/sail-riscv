#pragma once

#include "sail.h"

#ifdef __cplusplus

#include <optional>
extern std::optional<rvfi_handler> rvfi;

extern "C" {
#endif

// ****************************************************************************
// Sail API

uint32_t rvfi_get_insn(unit);

unit rvfi_set_pc_data_rdata(uint64_t data);
unit rvfi_set_pc_data_wdata(uint64_t data);

unit rvfi_set_inst_data_insn(uint64_t insn);
unit rvfi_set_inst_data_order(uint64_t order);
unit rvfi_set_inst_data_mode(uint8_t mode);
unit rvfi_set_inst_data_ixl(uint8_t ixl);

// ****************************************************************************

#ifdef __cplusplus
} // extern "C"
#endif
