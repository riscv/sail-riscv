#pragma once
#include <cstdint>
#include <optional>
#include <string>

class ModelImpl;
struct gdb_run_info;

void run_gdbserver(ModelImpl &model, gdb_run_info &info, unsigned port);
