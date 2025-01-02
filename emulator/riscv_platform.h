#pragma once
#include "sail.h"

bool sys_enable_rvc(unit);
bool sys_enable_fdext(unit);
bool sys_enable_svinval(unit);
bool sys_enable_zcb(unit);
bool sys_enable_zfinx(unit);
bool sys_enable_writable_misa(unit);
bool sys_enable_writable_fiom(unit);
bool sys_enable_vext(unit);
bool sys_enable_bext(unit);
bool sys_enable_zicbom(unit);
bool sys_enable_zicboz(unit);
bool sys_enable_sstc(unit);

uint64_t sys_pmp_count(unit);
uint64_t sys_pmp_grain(unit);

bool sys_vext_vl_use_ceil(unit);
uint64_t sys_vector_vlen_exp(unit);
uint64_t sys_vector_elen_exp(unit);

bool plat_enable_dirty_update(unit);
bool plat_enable_misaligned_access(unit);
bool plat_mtval_has_illegal_inst_bits(unit);
mach_bits sys_writable_hpm_counters(unit u);

mach_bits plat_ram_base(unit);
mach_bits plat_ram_size(unit);
bool within_phys_mem(mach_bits, sail_int);

mach_bits plat_rom_base(unit);
mach_bits plat_rom_size(unit);

mach_bits plat_cache_block_size_exp(unit);

// Provides entropy for the scalar cryptography extension.
mach_bits plat_get_16_random_bits(unit);

mach_bits plat_clint_base(unit);
mach_bits plat_clint_size(unit);

bool speculate_conditional(unit);
unit load_reservation(mach_bits);
bool match_reservation(mach_bits);
unit cancel_reservation(unit);

void plat_insns_per_tick(sail_int *rop, unit);

unit plat_term_write(mach_bits);
mach_bits plat_htif_tohost(unit);

unit memea(mach_bits, sail_int);
