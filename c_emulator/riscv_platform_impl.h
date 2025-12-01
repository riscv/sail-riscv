#pragma once

#include <stdbool.h>
#include <stdint.h>
#include <stdio.h>
#include <optional>

void rv_set_rng_seed(std::optional<uint64_t> seed);
// Provides entropy for the scalar cryptography extension.
extern uint64_t rv_16_random_bits(void);

extern bool rv_enable_experimental_extensions;

extern bool config_print_reservation;
extern uint64_t reservation_set_size_exp;
extern uint64_t reservation_set_addr_mask;

extern FILE *trace_log;
extern int term_fd;
void plat_term_write_impl(char c);
