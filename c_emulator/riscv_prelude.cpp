#include "riscv_prelude.h"
#include "riscv_config.h"
#include "riscv_platform_impl.h"
#include "symbol_table.h"

unit print_string(const_sail_string prefix, const_sail_string msg)
{
  printf("%s%s\n", prefix, msg);
  return UNIT;
}

unit print_log(const_sail_string s)
{
  fprintf(trace_log, "%s\n", s);
  return UNIT;
}

unit print_log_instr(const_sail_string s, uint64_t pc)
{
  auto maybe_symbol = symbolize_address(g_symbols, pc);
  if (maybe_symbol.has_value()) {
    fprintf(trace_log, "%-80s    %s+%" PRIu64 "\n", s,
            maybe_symbol->second.c_str(), pc - maybe_symbol->first);
  } else {
    fprintf(trace_log, "%s\n", s);
  }
  return UNIT;
}

unit print_step(unit)
{
  if (config_print_step) {
    fprintf(trace_log, "\n");
  }
  return UNIT;
}

bool get_config_print_instr(unit)
{
  return config_print_instr;
}

bool get_config_print_clint(unit)
{
  return config_print_clint;
}

bool get_config_print_exception(unit)
{
  return config_print_exception;
}

bool get_config_print_interrupt(unit)
{
  return config_print_interrupt;
}

bool get_config_print_htif(unit)
{
  return config_print_htif;
}

bool get_config_print_pma(unit)
{
  return config_print_pma;
}

bool get_config_rvfi(unit)
{
  return config_enable_rvfi;
}

bool get_config_use_abi_names(unit)
{
  return config_use_abi_names;
}
