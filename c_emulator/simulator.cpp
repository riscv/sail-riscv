#include "simulator.h"

#include <cerrno>
#include <chrono>
#include <cinttypes>
#include <cstdio>
#include <cstring>
#include <optional>

#include <fcntl.h>
#include <sys/stat.h>
#include <unistd.h>

#include "riscv_callbacks_log.h"
#include "riscv_callbacks_rvfi.h"
#include "riscv_model_impl.h"
#include "rts.h"
#include "rvfi_dii.h"
#include "sail.h"
#include "traploop_detector.h"

extern int term_fd;

// Global trace_log used by riscv_model_impl. Lives here so any main that
// links against this library gets it for free.
FILE *trace_log = stdout;

namespace riscv_sim {

using std::chrono::duration_cast;
using std::chrono::milliseconds;
using std::chrono::steady_clock;

struct Simulator::Impl {
  ModelImpl &model;
  SimulatorConfig cfg;

  bool owns_trace_log = false;
  std::optional<rvfi_handler> rvfi;
  std::optional<log_callbacks> log_cbs;
  rvfi_callbacks rvfi_cbs;
  traploop_detector loop_detector;

  uint64_t total_insns = 0;
  steady_clock::time_point init_start;
  steady_clock::time_point init_end;

  Impl(ModelImpl &m, const SimulatorConfig &c) : model(m), cfg(c) {
  }
};

Simulator::Simulator(ModelImpl &model, const SimulatorConfig &cfg) : impl_(std::make_unique<Impl>(model, cfg)) {

  impl_->init_start = steady_clock::now();

  if (!cfg.term_log_path.empty()) {
    term_fd = open(cfg.term_log_path.c_str(), O_WRONLY | O_CREAT | O_TRUNC, S_IRUSR | S_IRGRP | S_IROTH | S_IWUSR);
    if (term_fd < 0) {
      throw ConfigError("Cannot create terminal log '" + cfg.term_log_path + "': " + std::strerror(errno));
    }
  }

  if (!cfg.trace_log_path.empty()) {
    trace_log = std::fopen(cfg.trace_log_path.c_str(), "w+");
    if (trace_log == nullptr) {
      trace_log = stdout;
      throw ConfigError("Cannot create trace log '" + cfg.trace_log_path + "': " + std::strerror(errno));
    }
    impl_->owns_trace_log = true;
  }

  if (cfg.rvfi_dii_port != 0) {
    impl_->rvfi.emplace(cfg.rvfi_dii_port, model);
    if (!impl_->rvfi->setup_socket(cfg.trace_rvfi)) {
      throw ConfigError("RVFI socket setup failed");
    }
    model.register_callback(&impl_->rvfi_cbs);
  }

  if (cfg.enable_trap_loop_detection) {
    model.register_callback(&impl_->loop_detector);
  }

  impl_->log_cbs.emplace(
    cfg.trace_gpr,
    cfg.trace_fpr,
    cfg.trace_vreg,
    cfg.trace_csr,
    cfg.trace_mem_access,
    cfg.trace_ptw,
    cfg.trace_tlb,
    cfg.use_abi_names,
    trace_log
  );
  model.register_callback(&*impl_->log_cbs);

  impl_->init_end = steady_clock::now();
}

Simulator::~Simulator() {
  if (impl_->owns_trace_log && trace_log != stdout) {
    std::fclose(trace_log);
    trace_log = stdout;
  }
  if (term_fd >= 0) {
    close(term_fd);
    term_fd = -1;
  }
}

RunResult Simulator::run() {
  auto &m = impl_->model;
  auto &cfg = impl_->cfg;

  bool is_waiting = false;
  // The emulator tick increments time by 1 at every step, so the number
  // of steps to wait is equal to the needed increment in the time CSR.
  const uint64_t max_wait_steps = cfg.max_time_to_wait;
  uint64_t wait_steps_remaining = 0;

  // initialize the step number
  mach_int step_no = 0;
  uint64_t insn_cnt = 0;

  const uint64_t insns_per_tick = cfg.insns_per_tick;

  auto interval_start = steady_clock::now();

  while (!m.zhtif_done && (cfg.insn_limit == 0 || impl_->total_insns < cfg.insn_limit)) {
    if (impl_->rvfi.has_value()) {
      switch (impl_->rvfi->pre_step(cfg.trace_rvfi)) {
      case RVFI_prestep_continue:
        continue;
      case RVFI_prestep_eof:
        return {RunStatus::RvfiEof};
      case RVFI_prestep_end_trace:
        return {RunStatus::RvfiEndTrace};
      case RVFI_prestep_ok:
        break;
      }
    }

    m.call_pre_step_callbacks(is_waiting);

    { // run a Sail step
      sail_int sail_step;
      CREATE(sail_int)(&sail_step);
      CONVERT_OF(sail_int, mach_int)(&sail_step, step_no);
      is_waiting = m.ztry_step(sail_step, wait_steps_remaining == 0);
      KILL(sail_int)(&sail_step);

      if (m.have_exception) {
        m.print_current_exception();
        return {RunStatus::SailException};
      }
      if (cfg.trace_instr) {
        std::fflush(stderr);
        std::fflush(stdout);
        std::fflush(trace_log);
      }
      if (impl_->rvfi) {
        impl_->rvfi->send_trace(cfg.trace_rvfi);
      }
      if (is_waiting) {
        if (wait_steps_remaining == 0) {
          wait_steps_remaining = max_wait_steps;
        } else {
          --wait_steps_remaining;
        }
      } else {
        wait_steps_remaining = 0;
      }
    }

    m.call_post_step_callbacks(is_waiting);

    if (!is_waiting) {
      if (cfg.trace_step) {
        std::fprintf(trace_log, "\n");
      }
      step_no++;
      insn_cnt++;
      impl_->total_insns++;
    }

    if (cfg.show_times && (impl_->total_insns & 0xfffff) == 0) {
      const auto now = steady_clock::now();
      const auto interval = now - interval_start;
      interval_start = now;

      uint64_t kips = 0x100000 / duration_cast<milliseconds>(interval).count();
      std::fprintf(stdout, "kips: %" PRIu64 "\n", kips);
    }

    if (m.zhtif_done) {
      // check exit code
      if (m.zhtif_exit_code == 0) {
        return {RunStatus::HtifSuccess};
      } else {
        return {RunStatus::HtifFailure, m.zhtif_exit_code};
      }
    }

    if (insn_cnt == insns_per_tick) {
      insn_cnt = 0;
      m.ztick_clock(UNIT);
    } else if (wait_steps_remaining > 0) {
      m.ztick_clock(UNIT);
    }

    if (impl_->loop_detector.loop_detected()) {
      return {RunStatus::TrapLoop, 0, impl_->loop_detector.mepc(), impl_->loop_detector.sepc()};
    }
  }

  // This is reached if there is a Sail exception, HTIF has indicated
  // successful completion, or the instruction limit has been reached.
  return {RunStatus::InstructionLimit};
}

void Simulator::write_signature() {
  if (impl_->cfg.sig_file.empty()) {
    return;
  }
  if (!impl_->cfg.sig_start.has_value() || !impl_->cfg.sig_end.has_value() ||
      *impl_->cfg.sig_start >= *impl_->cfg.sig_end) {
    std::fprintf(stderr, "Invalid signature region to %s.\n", impl_->cfg.sig_file.c_str());
    return;
  }
  FILE *f = std::fopen(impl_->cfg.sig_file.c_str(), "w");
  if (!f) {
    std::fprintf(stderr, "Cannot open file '%s': %s\n", impl_->cfg.sig_file.c_str(), std::strerror(errno));
    return;
  }
  // write out words depending on signature granularity in signature area
  const unsigned gran = impl_->cfg.sig_granularity;
  for (uint64_t addr = *impl_->cfg.sig_start; addr < *impl_->cfg.sig_end; addr += gran) {
    // most-significant byte first
    for (int i = static_cast<int>(gran) - 1; i >= 0; i--) {
      uint8_t byte = (uint8_t)read_mem(addr + i);
      std::fprintf(f, "%02x", byte);
    }
    std::fprintf(f, "\n");
  }
  std::fclose(f);
}

void Simulator::reset_for_next_run(uint64_t entry, std::optional<uint64_t> htif_tohost, const char *config_file) {
  reinit_sail(impl_->model, entry, htif_tohost, config_file);
  impl_->loop_detector.reset();
  impl_->total_insns = 0;
}

uint64_t Simulator::rvfi_entry() const {
  return impl_->rvfi->get_entry();
}

void Simulator::print_times() const {
  auto run_end = steady_clock::now();
  uint64_t init_msecs = duration_cast<milliseconds>(impl_->init_end - impl_->init_start).count();
  uint64_t exec_msecs = duration_cast<milliseconds>(run_end - impl_->init_end).count();
  uint64_t kips = exec_msecs > 0 ? impl_->total_insns / exec_msecs : 0;
  std::fprintf(stderr, "Initialization:   %" PRIu64 " ms\n", init_msecs);
  std::fprintf(stderr, "Execution:        %" PRIu64 " ms\n", exec_msecs);
  std::fprintf(stderr, "Instructions:     %" PRIu64 "\n", impl_->total_insns);
  std::fprintf(stderr, "Performance:      %" PRIu64 " kIPS\n", kips);
}

uint64_t Simulator::total_insns() const {
  return impl_->total_insns;
}

} // namespace riscv_sim
