#include "sail.h"
#include "riscv_platform.h"
#include "riscv_platform_impl.h"
#include "riscv_sail.h"

#ifdef DEBUG_RESERVATION
#include <stdio.h>
#include <inttypes.h>
#define RESERVATION_DBG(args...) fprintf(stderr, args)
#else
#define RESERVATION_DBG(args...)
#endif

/* This file contains the definitions of the C externs of Sail model. */

static mach_bits reservation = 0;
static bool reservation_valid = false;

// Provides entropy for the scalar cryptography extension.
mach_bits plat_get_16_random_bits(unit)
{
  return rv_16_random_bits();
}

// Note: Store-Conditionals are allowed to spuriously fail. If you want
// that to happen you can spuriously set `reservation_valid = false`
// either directly in `load_reservation()` or by calling
// `cancel_reservation()`.

unit load_reservation(sbits addr)
{
  reservation = addr.bits;
  reservation_valid = true;
  RESERVATION_DBG("reservation <- %0" PRIx64 "\n", reservation);
  return UNIT;
}

static mach_bits check_mask()
{
  return (zxlen == 32) ? 0x00000000FFFFFFFF : -1;
}

bool match_reservation(sbits addr)
{
  mach_bits mask = check_mask();
  bool ret = reservation_valid && (reservation & mask) == (addr.bits & mask);
  RESERVATION_DBG("reservation(%c): %0" PRIx64 ", key=%0" PRIx64 ": %s\n",
                  reservation_valid ? 'v' : 'i', reservation, addr,
                  ret ? "ok" : "fail");
  return ret;
}

unit cancel_reservation(unit)
{
  RESERVATION_DBG("reservation <- none\n");
  reservation_valid = false;
  return UNIT;
}

bool valid_reservation(unit)
{
  return reservation_valid;
}

unit plat_term_write(mach_bits s)
{
  char c = s & 0xff;
  plat_term_write_impl(c);
  return UNIT;
}

bool plat_enable_htif(unit)
{
  return rv_enable_htif;
}

mach_bits plat_htif_tohost(unit)
{
  return rv_htif_tohost;
}

bool sys_enable_experimental_extensions(unit)
{
  return rv_enable_experimental_extensions;
}

unit memea(mach_bits, sail_int)
{
  return UNIT;
}
