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
unit print_platform(sail_string s);

bool get_config_print_instr(unit);
bool get_config_print_platform(unit);

#ifdef __cplusplus
} // extern "C"
#endif
