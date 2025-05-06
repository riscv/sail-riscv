#pragma once

#include <stdbool.h>
#include <stdint.h>
#include <stdio.h>

// Provides entropy for the scalar cryptography extension.
extern uint64_t rv_16_random_bits(void);

extern uint64_t rv_htif_tohost;
extern bool rv_enable_htif;

extern bool rv_enable_experimental_extensions;

extern FILE *trace_log;
extern int term_fd;
void plat_term_write_impl(char c);
