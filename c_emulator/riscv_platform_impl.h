#pragma once

#include <stdbool.h>
#include <stdint.h>
#include <stdio.h>

/* Settings of the platform implementation. */

#define DEFAULT_RSTVEC 0x00001000

extern uint64_t rv_pmp_count;
extern uint64_t rv_pmp_grain;

extern uint64_t rv_vector_vlen_exp;
extern uint64_t rv_vector_elen_exp;

extern bool rv_enable_svinval;
extern bool rv_enable_zcb;
extern bool rv_enable_zfinx;
extern bool rv_enable_rvc;
extern bool rv_enable_fdext;
extern bool rv_enable_vext;
extern bool rv_enable_bext;
extern bool rv_enable_zicbom;
extern bool rv_enable_zicboz;
extern bool rv_enable_sstc;
extern bool rv_enable_writable_misa;
extern bool rv_enable_dirty_update;
extern bool rv_enable_misaligned;
extern bool rv_mtval_has_illegal_inst_bits;
extern bool rv_enable_writable_fiom;
extern uint64_t rv_writable_hpm_counters;

extern uint64_t rv_ram_base;
extern uint64_t rv_ram_size;

extern uint64_t rv_rom_base;
extern uint64_t rv_rom_size;

extern uint64_t rv_cache_block_size_exp;

extern bool rv_vext_vl_use_ceil;

// Provides entropy for the scalar cryptography extension.
extern uint64_t rv_16_random_bits(void);

extern uint64_t rv_clint_base;
extern uint64_t rv_clint_size;

extern uint64_t rv_htif_tohost;
extern uint64_t rv_insns_per_tick;

extern FILE *trace_log;
extern int term_fd;
void plat_term_write_impl(char c);
