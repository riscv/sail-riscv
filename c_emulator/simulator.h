#pragma once

#include <cstdint>
#include <memory>
#include <optional>
#include <string>

#include "riscv_sim_utils.h"

class ModelImpl;

namespace riscv_sim {

enum class RunStatus {
  HtifSuccess,
  HtifFailure,
  TrapLoop,
  SailException,
  InstructionLimit,
  RvfiEof,
  RvfiEndTrace,
};

struct RunResult {
  RunStatus status;
  uint64_t htif_exit_code = 0;
  uint64_t mepc = 0;
  uint64_t sepc = 0;
};

struct SimulatorConfig {
  // Simulation loop control
  uint64_t insn_limit = 0;
  uint64_t max_time_to_wait = 0;
  uint64_t insns_per_tick = 1;

  // Trace options
  bool trace_instr = false;
  bool trace_step = false;
  bool trace_rvfi = false;
  bool trace_gpr = false;
  bool trace_fpr = false;
  bool trace_vreg = false;
  bool trace_csr = false;
  bool trace_mem_access = false;
  bool trace_ptw = false;
  bool trace_tlb = false;

  bool use_abi_names = false;
  bool show_times = false;

  // Signature region
  std::optional<uint64_t> sig_start;
  std::optional<uint64_t> sig_end;
  std::string sig_file;
  unsigned sig_granularity = 4;

  // Simulator trace output, empty = stdout
  std::string trace_log_path;
  // HTIF Console output, empty = no terminal log file
  std::string term_log_path;

  // RVFI (0 = disabled)
  unsigned rvfi_dii_port = 0;

  bool enable_trap_loop_detection = true;
};

class Simulator {
public:
  Simulator(ModelImpl &model, const SimulatorConfig &cfg);
  ~Simulator();

  Simulator(const Simulator &) = delete;
  Simulator &operator=(const Simulator &) = delete;

  RunResult run();

  void write_signature();
  void reset_for_next_run(uint64_t entry, std::optional<uint64_t> htif_tohost, const char *config_file);

  // Only valid if rvfi_dii_port was non-zero.
  uint64_t rvfi_entry() const;

  void print_times() const;

  uint64_t total_insns() const;

private:
  struct Impl;
  std::unique_ptr<Impl> impl_;
};

} // namespace riscv_sim
