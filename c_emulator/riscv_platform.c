#include "sail.h"
#include "rts.h"
#include "riscv_prelude.h"
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
mach_bits plat_get_16_random_bits(unit u)
{
  return rv_16_random_bits();
}

unit load_reservation(mach_bits addr)
{
  reservation = addr;
  reservation_valid = true;
  RESERVATION_DBG("reservation <- %0" PRIx64 "\n", reservation);
  return UNIT;
}

bool speculate_conditional(unit u)
{
  return true;
}

static mach_bits check_mask(void)
{
  return (zxlen_val == 32) ? 0x00000000FFFFFFFF : -1;
}

bool match_reservation(mach_bits addr)
{
  mach_bits mask = check_mask();
  bool ret = reservation_valid && (reservation & mask) == (addr & mask);
  RESERVATION_DBG("reservation(%c): %0" PRIx64 ", key=%0" PRIx64 ": %s\n",
                  reservation_valid ? 'v' : 'i', reservation, addr,
                  ret ? "ok" : "fail");
  return ret;
}

unit cancel_reservation(unit u)
{
  RESERVATION_DBG("reservation <- none\n");
  reservation_valid = false;
  return UNIT;
}

unit plat_term_write(mach_bits s)
{
  char c = s & 0xff;
  plat_term_write_impl(c);
  return UNIT;
}

mach_bits plat_htif_tohost(unit u)
{
  return rv_htif_tohost;
}

unit memea(mach_bits len, sail_int n)
{
  return UNIT;
}
