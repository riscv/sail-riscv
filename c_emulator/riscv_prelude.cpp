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

unit print_step(unit)
{
  if (config_print_step)
    fprintf(trace_log, "\n");
  return UNIT;
}

unit print_platform(sail_string s)
{
  if (config_print_platform)
    fprintf(trace_log, "%s\n", s);
  return UNIT;
}

bool get_config_print_instr(unit)
{
  return config_print_instr;
}

bool get_config_print_platform(unit)
{
  return config_print_platform;
}

bool get_config_rvfi(unit)
{
  return config_enable_rvfi;
}
