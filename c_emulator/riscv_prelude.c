#include "riscv_prelude.h"
#include "riscv_config.h"
#include "riscv_platform_impl.h"

unit print_string(sail_string prefix, sail_string msg)
{
  printf("%s%s\n", prefix, msg);
  return UNIT;
}

unit print_instr(sail_string s)
{
  if (config_print_instr)
    fprintf(trace_log, "%s\n", s);
  return UNIT;
}

unit print_step(unit u)
{
  if (config_print_step)
    fprintf(trace_log, "\n");
  return UNIT;
}

unit print_reg(sail_string s)
{
  if (config_print_reg)
    fprintf(trace_log, "%s\n", s);
  return UNIT;
}

unit print_mem_access(sail_string s)
{
  if (config_print_mem_access)
    fprintf(trace_log, "%s\n", s);
  return UNIT;
}

unit print_platform(sail_string s)
{
  if (config_print_platform)
    fprintf(trace_log, "%s\n", s);
  return UNIT;
}

bool get_config_print_instr(unit u)
{
  return (config_print_instr) ? true : false;
}

bool get_config_print_reg(unit u)
{
  return (config_print_reg) ? true : false;
}

bool get_config_print_mem(unit u)
{
  return (config_print_mem_access) ? true : false;
}

bool get_config_print_platform(unit u)
{
  return (config_print_platform) ? true : false;
}
