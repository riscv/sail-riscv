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

bool sys_enable_rvc(unit u)
{
  return rv_enable_rvc;
}

bool sys_enable_next(unit u)
{
  return rv_enable_next;
}

bool sys_enable_fdext(unit u)
{
  return rv_enable_fdext;
}

bool sys_enable_zfinx(unit u)
{
  return rv_enable_zfinx;
}

bool sys_enable_writable_fiom(unit u)
{
  return rv_enable_writable_fiom;
}

bool sys_enable_vext(unit u)
{
  return rv_enable_vext;
}

bool sys_enable_writable_misa(unit u)
{
  return rv_enable_writable_misa;
}

bool plat_enable_dirty_update(unit u)
{
  return rv_enable_dirty_update;
}

bool plat_enable_misaligned_access(unit u)
{
  return rv_enable_misaligned;
}

bool plat_mtval_has_illegal_inst_bits(unit u)
{
  return rv_mtval_has_illegal_inst_bits;
}

bool plat_enable_pmp(unit u)
{
  return rv_enable_pmp;
}

mach_bits plat_ram_base(unit u)
{
  return rv_ram_base;
}

mach_bits plat_ram_size(unit u)
{
  return rv_ram_size;
}

mach_bits plat_rom_base(unit u)
{
  return rv_rom_base;
}

mach_bits plat_rom_size(unit u)
{
  return rv_rom_size;
}

// Provides entropy for the scalar cryptography extension.
mach_bits plat_get_16_random_bits()
{
  return rv_16_random_bits();
}

mach_bits plat_clint_base(unit u)
{
  return rv_clint_base;
}

mach_bits plat_clint_size(unit u)
{
  return rv_clint_size;
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

void plat_insns_per_tick(sail_int *rop, unit u) { }

mach_bits plat_htif_tohost(unit u)
{
  return rv_htif_tohost;
}

unit memea(mach_bits len, sail_int n)
{
  return UNIT;
}
