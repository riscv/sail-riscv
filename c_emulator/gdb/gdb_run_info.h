#pragma once

#include <stdio.h>

struct gdb_run_info {
  bool enable_trace;
  FILE *trace_log;
};
