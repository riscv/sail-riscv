#pragma once
#include "sail.h"
#include "rts.h"
#include "riscv_softfloat.h"

#ifdef __cplusplus
extern "C" {
#endif

unit print_string(sail_string prefix, sail_string msg);

unit print_log(sail_string s);
unit print_log_instr(sail_string s, uint64_t pc);
unit print_step(unit);

bool get_config_print_instr(unit);
bool get_config_print_platform(unit);
bool get_config_rvfi(unit);
bool get_config_use_abi_names(unit);

#ifdef __cplusplus
} // extern "C"
#endif
