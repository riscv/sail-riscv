#pragma once
#include <stdbool.h>

extern bool config_print_instr;
extern bool config_print_step;
extern bool config_print_reg;
extern bool config_print_mem_access;
extern bool config_print_clint;
extern bool config_print_exception;
extern bool config_print_interrupt;
extern bool config_print_htif;
extern bool config_print_pma;
extern bool config_enable_rvfi;
extern bool config_use_abi_names;
extern uint64_t config_plic_nsrc;
extern uint64_t config_plic_nctx;
