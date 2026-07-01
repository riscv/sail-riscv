#pragma once

#include "rvfi_dii.h"

#include <chrono>
#include <map>
#include <optional>
#include <string>
#include <unistd.h>

using std::chrono::steady_clock;

struct CLIOptions;
class traploop_detector;
class ModelImpl;

struct elf_info {
  // The address of the HTIF tohost port, if it is enabled.
  std::optional<uint64_t> htif_tohost_address = {};
  uint64_t mem_sig_start = 0;
  uint64_t mem_sig_end = 0;
  std::map<uint64_t, std::string> symbols = {};
};

struct run_info {
  std::optional<rvfi_handler> rvfi = {};
  // Terminal output goes to stdout unless changed via the `--terminal-log` option.
  int term_fd = STDOUT_FILENO;
  bool close_term_fd = false;
  steady_clock::time_point init_start = {};
  steady_clock::time_point init_end = {};
  uint64_t total_insns = 0;
  FILE *trace_log = stdout;
};

// Initialization result used during startup.
enum class InitResult {
  ExitFailure,
  ExitSuccess,
  Continue,
};

// Startup and execution

// Processes options that don't need an initialized model and gets the
// json configuration string; returns whether to continue with model
// initialization.
InitResult preinit_args(CLIOptions &opts, std::string &config_json_string);

// Configures the model, validates the configuration, processes
// options requiring a configured model and returns whether to continue with
// model simulation.
InitResult preinit_model(CLIOptions &opts, ModelImpl &model, const std::string &config_json_string, run_info &run_info);

// Returns the entry address.
uint64_t init_model(CLIOptions &opts, ModelImpl &model, elf_info &elf_info, run_info &run_info);

uint64_t load_sail(ModelImpl &model, const std::string &filename, bool main_file, elf_info &elf_info);

void run_sail(
  ModelImpl &model,
  const CLIOptions &opts,
  std::shared_ptr<traploop_detector> loop_detector,
  const elf_info &elf_info,
  run_info &run_info,
  uint64_t entry
);

void finish(ModelImpl &model, const CLIOptions &opts, const elf_info &elf_info, run_info &run_info);

// Log management

void init_logs(const CLIOptions &opts, run_info &run_info);

void flush_logs(run_info &run_info);

void close_logs(run_info &run_info);
