#pragma once
#include "sail.h"

#ifdef __cplusplus
extern "C" {
#endif

// Provides entropy for the scalar cryptography extension.
mach_bits plat_get_16_random_bits(unit);

unit load_reservation(mach_bits);
bool match_reservation(mach_bits);
unit cancel_reservation(unit);
bool valid_reservation(unit);

unit plat_term_write(mach_bits);

mach_bits plat_htif_tohost(unit);
bool plat_enable_htif(unit);

bool sys_enable_experimental_extensions(unit);

unit memea(mach_bits, sail_int);

#ifdef __cplusplus
} // extern "C"
#endif
