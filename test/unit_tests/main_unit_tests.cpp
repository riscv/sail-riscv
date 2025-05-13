#include <filesystem>
#include <fstream>
#include <sstream>
#include <unistd.h>

#include <sail.h>
#include <sail_config.h>

#include "default_config.h"

// Generated in the model C code. This is a simple test runner that just
// runs the tests in series and aborts on the first failure. In future
// we can do something fancier.
extern "C" void model_test();

bool config_print_instr = false;
bool config_print_step = false;
bool config_print_reg = false;
bool config_print_mem_access = false;
bool config_print_platform = false;
bool config_enable_rvfi = false;
FILE *trace_log = NULL;

int main()
{
  trace_log = stdout;

  std::filesystem::path path = std::filesystem::temp_directory_path();
  pid_t pid = getpid();
  std::ostringstream filename;
  filename << "default_config" << pid << ".json";
  path = path / filename.str();
  std::ofstream tmp(path);
  tmp << DEFAULT_JSON;
  tmp.close();

  sail_config_set_file(path.c_str());
  std::filesystem::remove(path);

  model_test();
}
