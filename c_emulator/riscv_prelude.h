#pragma once
#include "sail.h"
#include "rts.h"
#include "riscv_softfloat.h"

#ifdef __cplusplus
extern "C" {
#endif

unit print_string(sail_string prefix, sail_string msg);

unit print_instr(sail_string s);
unit print_step(unit);
unit print_reg(sail_string s);
unit print_mem_access(sail_string s);
unit print_platform(sail_string s);

bool get_config_print_instr(unit);
bool get_config_print_reg(unit);
bool get_config_print_mem(unit);
bool get_config_print_platform(unit);

#ifdef __cplusplus
} // extern "C"
#endif
