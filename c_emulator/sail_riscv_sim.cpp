#include "cli_options.h"
#include "riscv_callbacks_log.h"
#include "riscv_model_impl.h"
#include "riscv_sim.h"
#include "traploop_detector.h"

#include <iostream>

#ifdef ENABLE_GDBSERVER
#include "gdb/gdb_run_info.h"
#include "gdb/gdbserver.h"
#include "gdb/target_regs.h"
#include <asio.hpp>
#endif

namespace {

void run_model(CLIOptions &opts, ModelImpl &model, uint64_t, const elf_info &elf_info, run_info &run_info) {
  auto loop_detector = std::make_shared<traploop_detector>();
  if (!opts.disable_trap_loop_detection) {
    model.register_callback(loop_detector);
  }

  auto log_cbs = std::make_shared<log_callbacks>(
    opts.config_print_gpr,
    opts.config_print_fpr,
    opts.config_print_vreg,
    opts.config_print_csr,
    opts.config_print_mem_access,
    opts.config_print_ptw,
    opts.config_print_tlb,
    opts.config_use_abi_names,
    run_info.trace_log
  );
  model.register_callback(log_cbs);

  do {
    run_sail(model, opts, loop_detector, elf_info, run_info);
    // `run_sail` only returns in the case of rvfi.
    if (run_info.rvfi) {
      /* Reset for next test */
      model.reinit_sail();
      loop_detector->reset();
    }
  } while (run_info.rvfi);
}

int inner_main(int argc, char **argv) {

  CLIOptions opts = parse_cli(argc, argv);

  std::string config_json_string;
  switch (preinit_args(opts, config_json_string)) {
  case InitResult::ExitSuccess:
    return EXIT_SUCCESS;
  case InitResult::ExitFailure:
    return EXIT_FAILURE;
  case InitResult::Continue:
    break;
  }

  ModelImpl model;
  run_info run_info;
  switch (preinit_model(opts, model, config_json_string, run_info)) {
  case InitResult::ExitSuccess:
    return EXIT_SUCCESS;
  case InitResult::ExitFailure:
    return EXIT_FAILURE;
  case InitResult::Continue:
    break;
  }

  elf_info elf_info;
  uint64_t entry = init_model(opts, model, elf_info, run_info);

  if (opts.gdb_server_port != 0) {
#ifdef ENABLE_GDBSERVER
    gdb_run_info info = {
      .enable_trace = opts.config_print_gdbserver,
      .trace_log = run_info.trace_log,
    };
    run_gdbserver(model, info, opts.gdb_server_port);
#endif
  } else {
    run_model(opts, model, entry, elf_info, run_info);
  }

  model.model_fini();
  flush_logs(run_info);
  close_logs(run_info);

  return EXIT_SUCCESS;
}

} // namespace

int main(int argc, char **argv) {
  // Catch all exceptions and print them a bit more nicely than the default.
  try {
    return inner_main(argc, argv);
  } catch (const std::exception &exc) {
    std::cerr << "Error: " << exc.what() << std::endl;
  }
  return EXIT_FAILURE;
}
