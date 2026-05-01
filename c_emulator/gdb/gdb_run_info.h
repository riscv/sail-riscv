#pragma once

#include <stdio.h>

struct gdb_run_info {
  bool enable_trace = false;
  FILE *trace_log = nullptr;
};
