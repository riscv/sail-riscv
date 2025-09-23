#pragma once

#include <stdbool.h>
#include <stdint.h>
#include <stdio.h>

// Provides entropy for the scalar cryptography extension.
extern uint64_t rv_16_random_bits(void);

extern bool rv_enable_experimental_extensions;
extern bool rv_enable_semihosting;

extern FILE *trace_log;
extern int term_fd;
void plat_term_write_impl(char c);
