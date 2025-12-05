#include <sail.h>
#include <sail_config.h>

#include "config_utils.h"

// Generated in the model C code. This is a simple test runner that just
// runs the tests in series and aborts on the first failure. In future
// we can do something fancier.
extern void model_test();

bool config_print_instr = false;
bool config_print_step = false;
bool config_print_reg = false;
bool config_print_mem_access = false;
bool config_print_clint = false;
bool config_print_exception = false;
bool config_print_interrupt = false;
bool config_print_htif = false;
bool config_print_pma = false;
bool config_enable_rvfi = false;
bool config_use_abi_names = false;

FILE *trace_log = stdout;

int main()
{
  sail_config_set_string(get_default_config());
  model_test();
}
