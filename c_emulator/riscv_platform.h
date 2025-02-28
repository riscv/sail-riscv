#pragma once
#include "sail.h"

// Provides entropy for the scalar cryptography extension.
mach_bits plat_get_16_random_bits(unit);

bool speculate_conditional(unit);
unit load_reservation(mach_bits);
bool match_reservation(mach_bits);
unit cancel_reservation(unit);

unit plat_term_write(mach_bits);

mach_bits plat_htif_tohost(unit);

unit memea(mach_bits, sail_int);
