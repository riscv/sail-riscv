#include <stdbool.h>
#include <stdio.h>

// Generated in the model C code. This is a simple test runner that just
// runs the tests in series and aborts on the first failure. In future
// we can do something fancier.
void model_test();

bool config_print_instr = false;
bool config_print_reg = false;
bool config_print_mem_access = false;
bool config_print_platform = false;
bool config_print_rvfi = false;
bool config_print_step = false;
FILE *trace_log = NULL;

int main()
{
  trace_log = stdout;
  model_test();
}
