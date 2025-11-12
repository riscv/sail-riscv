#pragma once
#include "sail.h"

#ifdef __cplusplus
extern "C" {
#endif

// Provides entropy for the scalar cryptography extension.
mach_bits plat_get_16_random_bits(unit);

unit load_reservation(sbits, uint64_t);
bool match_reservation(sbits);
unit cancel_reservation(unit);
bool valid_reservation(unit);

unit plat_term_write(mach_bits);

bool sys_enable_experimental_extensions(unit);

unit memea(mach_bits, sail_int);

#ifdef __cplusplus
} // extern "C"
#endif
