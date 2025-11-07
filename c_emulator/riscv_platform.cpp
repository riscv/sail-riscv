#include <stdio.h>
#include <inttypes.h>
#include <assert.h>
#include "sail.h"
#include "riscv_platform.h"
#include "riscv_platform_impl.h"
#include "riscv_sail.h"

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

unit load_reservation(sbits addr, uint64_t width)
{
  reservation = addr.bits & reservation_set_addr_mask;
  reservation_valid = true;

  // Ensure the reservation set subsumes the reserved bytes.
  assert((width > 0)
         && (((addr.bits + width - 1) & reservation_set_addr_mask)
             == reservation));

  if (trace_log != nullptr && config_print_reservation) {
    fprintf(trace_log,
            "reservation <- 0x%0" PRIx64 " (addr: 0x%0" PRIx64
            ", width: %0" PRId64 ")\n",
            reservation, addr.bits, width);
  }
  return UNIT;
}

static mach_bits check_mask()
{
  return ((zxlen == 32) ? 0x00000000FFFFFFFF : -1) & reservation_set_addr_mask;
}

bool match_reservation(sbits addr)
{
  mach_bits mask = check_mask();
  bool ret = reservation_valid && (reservation & mask) == (addr.bits & mask);

  if (trace_log != nullptr && config_print_reservation) {
    fprintf(trace_log,
            "reservation(%c): 0x%0" PRIx64 ", key=0x%0" PRIx64 ": %s\n",
            reservation_valid ? 'v' : 'i', reservation, addr.bits,
            ret ? "ok" : "fail");
  }
  return ret;
}

unit cancel_reservation(unit)
{
  reservation_valid = false;
  if (trace_log != nullptr && config_print_reservation) {
    fprintf(trace_log, "reservation <- none\n");
  }
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

bool sys_enable_experimental_extensions(unit)
{
  return rv_enable_experimental_extensions;
}

unit memea(mach_bits, sail_int)
{
  return UNIT;
}
