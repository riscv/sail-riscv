#pragma once

#include <stdbool.h>
#include <stdint.h>

/* Settings of the platform implementation. */

#define DEFAULT_RSTVEC     0x00001000

extern bool rv_enable_pmp;
extern bool rv_enable_rvc;
extern bool rv_enable_next;
extern bool rv_enable_fdext;
extern bool rv_enable_writable_misa;
extern bool rv_enable_dirty_update;
extern bool rv_enable_misaligned;
extern bool rv_mtval_has_illegal_inst_bits;

extern uint64_t rv_ram_base;
extern uint64_t rv_ram_size;

extern uint64_t rv_rom_base;
extern uint64_t rv_rom_size;

// Provides entropy for the scalar cryptography extension.
extern uint64_t rv_16_random_bits(void);

extern uint64_t rv_clint_base;
extern uint64_t rv_clint_size;

extern uint64_t rv_htif_tohost;
extern uint64_t rv_insns_per_tick;

extern int term_fd;
void plat_term_write_impl(char c);
