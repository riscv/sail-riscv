#include "riscv_sim.h"
#include "CLI11.hpp"
#include "cli_options.h"
#include "config_utils.h"
#include "elf_loader.h"
#include "file_utils.h"
#include "jsoncons/config/version.hpp"
#include "jsoncons/json.hpp"
#include "riscv_callbacks_rvfi.h"
#include "riscv_callbacks_stop_at_pc.h"
#include "riscv_model_impl.h"
#ifdef SAILCOV
#include "sail_coverage.h"
#endif
#include "sail_riscv_version.h"
#include "symbol_table.h"
#include "traploop_detector.h"

#include <fcntl.h>

using std::chrono::duration_cast;
using std::chrono::milliseconds;

// Internal utilities.

namespace {

void print_build_info() {
  std::cout << "Sail RISC-V release: " << version_info::release_version() << std::endl;
  std::cout << "Sail RISC-V git: " << version_info::git_version() << std::endl;
  std::cout << "Sail: " << version_info::sail_version() << std::endl;
  std::cout << "C++ compiler: " << version_info::cxx_compiler_version() << std::endl;
  std::cout << "CLI11: " << CLI11_VERSION << std::endl;
  std::cout << "ELFIO: " << ELFIO_VERSION << std::endl;
  std::cout << "JSONCONS: " << jsoncons::version() << std::endl;
}

jsoncons::json parse_json_or_exit(const std::string &json_text, const std::string &source_desc) {
  try {
    return jsoncons::json::parse(json_text);
  } catch (const jsoncons::json_exception &e) {
    std::cerr << "JSON parse error in " << source_desc << ":\n" << e.what() << "\n\n";
    exit(EXIT_FAILURE);
  }
}

// JSON objects are merged by replacing/adding fields from the override config.
// If a given field is an object in the base and override then instead of
// replacing the field entirely the merging process recurses into it.
// All other field types (including arrays) are simply replaced.
void deep_merge_json(jsoncons::json &base, const jsoncons::json &json_override) {
  for (const auto &entry : json_override.object_range()) {
    const auto &key = entry.key();
    const auto &value = entry.value();
    if (base.contains(key) && base[key].is_object() && value.is_object()) {
      deep_merge_json(base[key], value);
    } else {
      base[key] = value;
    }
  }
}

void write_dtb_to_rom(ModelImpl &model, const std::vector<uint8_t> &dtb) {
  uint64_t addr = get_config_uint64({"memory", "dtb_address"});
  uint64_t size = static_cast<uint64_t>(dtb.size());

  // Overflow check for addr + size - 1
  uint64_t end = addr + size - 1;
  if (end < addr) {
    fprintf(stderr, "DTB address/size overflow: addr=0x%0" PRIx64 ", size=0x%0" PRIx64 "\n", addr, size);
    exit(EXIT_FAILURE);
  }

  // Validate DTB range against configured PMA memory regions.
  if (!model.dtb_within_configured_pma_memory(addr, size)) {
    fprintf(
      stderr,
      "DTB does not fit in any configured PMA memory region: "
      "addr=0x%0" PRIx64 ", size=0x%0" PRIx64 " (end=0x%0" PRIx64 ")\n"
      "Hint: adjust memory.dtb_address or memory.regions in the config.\n",
      addr,
      size,
      end
    );
    exit(EXIT_FAILURE);
  }

  for (uint8_t d : dtb) {
    write_mem(addr++, d);
  }
}

void write_signature(const std::string &file, unsigned signature_granularity, const elf_info &elf_info) {
  if (elf_info.mem_sig_start >= elf_info.mem_sig_end) {
    fprintf(
      stderr,
      "Invalid signature region [0x%0" PRIx64 ",0x%0" PRIx64 "] to %s.\n",
      elf_info.mem_sig_start,
      elf_info.mem_sig_end,
      file.c_str()
    );
    return;
  }
  FILE *f = fopen(file.c_str(), "w");
  if (!f) {
    fprintf(stderr, "Cannot open file '%s': %s\n", file.c_str(), strerror(errno));
    return;
  }
  /* write out words depending on signature granularity in signature area */
  for (uint64_t addr = elf_info.mem_sig_start; addr < elf_info.mem_sig_end; addr += signature_granularity) {
    /* most-significant byte first */
    for (unsigned i = signature_granularity; i > 0; --i) {
      uint8_t byte = static_cast<uint8_t>(read_mem(addr + i - 1));
      fprintf(f, "%02x", byte);
    }
    fprintf(f, "\n");
  }
  fclose(f);
}

} // namespace

uint64_t load_sail(ModelImpl &model, const std::string &filename, bool main_file, elf_info &elf_info) {
  ELF elf = ELF::open(filename);

  switch (elf.architecture()) {
  case Architecture::RV32:
    if (model.xlen() != 32) {
      fprintf(stderr, "32-bit ELF not supported by RV%" PRIi64 " model.\n", model.xlen());
      exit(EXIT_FAILURE);
    }
    break;
  case Architecture::RV64:
    if (model.xlen() != 64) {
      fprintf(stderr, "64-bit ELF not supported by RV%" PRIi64 " model.\n", model.xlen());
      exit(EXIT_FAILURE);
    }
    break;
  }

  // Load into memory.
  elf.load([](uint64_t address, const uint8_t *data, uint64_t length) {
    // TODO: We could definitely improve on rts.c's memory implementation
    // (which is O(N^2)) and writing one byte at a time here.
    for (uint64_t i = 0; i < length; ++i) {
      write_mem(address + i, data[i]);
    }
  });

  // Load the entire symbol table.
  const auto symbols = elf.symbols();

  // Save reversed symbol table for log symbolization.
  // If multiple symbols from different ELF files have the same value the first
  // one wins.
  const auto reversed_symbols = reverse_symbol_table(symbols);
  elf_info.symbols.insert(reversed_symbols.begin(), reversed_symbols.end());

  if (main_file) {
    // Only scan for test-signature/htif symbols in the main ELF file.

    const auto &tohost = symbols.find("tohost");
    if (tohost == symbols.end()) {
      fprintf(stderr, "Unable to locate tohost symbol; disabling HTIF.\n");
      elf_info.htif_tohost_address = std::nullopt;
    } else {
      elf_info.htif_tohost_address = tohost->second;
      fprintf(stdout, "HTIF located at 0x%0" PRIx64 "\n", *elf_info.htif_tohost_address);
    }
    // Locate test-signature locations if any.
    const auto &begin_sig = symbols.find("begin_signature");
    if (begin_sig != symbols.end()) {
      fprintf(stdout, "begin_signature: 0x%0" PRIx64 "\n", begin_sig->second);
      elf_info.mem_sig_start = begin_sig->second;
    }
    const auto &end_sig = symbols.find("end_signature");
    if (end_sig != symbols.end()) {
      fprintf(stdout, "end_signature: 0x%0" PRIx64 "\n", end_sig->second);
      elf_info.mem_sig_end = end_sig->second;
    }
  }

  return elf.entry();
}

void close_logs(run_info &run_info) {
  if (run_info.close_term_fd) {
    close(run_info.term_fd);
  }
  if (run_info.trace_log != stdout) {
    fclose(run_info.trace_log);
  }
#ifdef SAILCOV
  if (sail_coverage_exit() != 0) {
    fprintf(stderr, "Could not write coverage information!\n");
    exit(EXIT_FAILURE);
  }
#endif
}

void finish(ModelImpl &model, const CLIOptions &opts, const elf_info &elf_info, run_info &run_info) {
  // Don't write a signature if there was an internal Sail exception.
  if (!model.had_exception() && !opts.sig_file.empty()) {
    write_signature(opts.sig_file, opts.signature_granularity, elf_info);
  }

  // `model_fini()` exits with failure if there was a Sail exception.
  model.model_fini();

  if (opts.do_show_times) {
    auto run_end = steady_clock::now();
    uint64_t init_msecs = duration_cast<milliseconds>(run_info.init_end - run_info.init_start).count();
    uint64_t exec_msecs = duration_cast<milliseconds>(run_end - run_info.init_end).count();
    fprintf(stderr, "Initialization:   %" PRIu64 " ms\n", init_msecs);
    fprintf(stderr, "Execution:        %" PRIu64 " ms\n", exec_msecs);
    fprintf(stderr, "Instructions:     %" PRIu64 "\n", run_info.total_insns);
    fprintf(stderr, "Performance:      %" PRIu64 " kIPS\n", exec_msecs == 0 ? 0 : run_info.total_insns / exec_msecs);
  }
  close_logs(run_info);
  exit(model.had_exception() ? EXIT_FAILURE : EXIT_SUCCESS);
}

void flush_logs(run_info &run_info) {
  fflush(stderr);
  fflush(stdout);
  fflush(run_info.trace_log);
}

void run_sail(
  ModelImpl &model,
  const CLIOptions &opts,
  std::shared_ptr<traploop_detector> loop_detector,
  std::shared_ptr<stop_at_pc_callbacks> stop_at_pc,
  const elf_info &elf_info,
  run_info &run_info
) {
  bool is_waiting = false;
  // The emulator tick increments time by 1 at every step, so the number
  // of steps to wait is equal to the needed increment in the time CSR.
  uint64_t max_wait_steps = get_config_uint64({"platform", "max_time_to_wait"});
  uint64_t wait_steps_remaining = 0;

  /* initialize the step number */
  mach_int step_no = 0;
  uint64_t insn_cnt = 0;

  uint64_t insns_per_tick = get_config_uint64({"platform", "instructions_per_tick"});

  auto interval_start = steady_clock::now();

  while (!model.htif_done() && !(stop_at_pc && stop_at_pc->stop_requested()) &&
         (opts.insn_limit == 0 || run_info.total_insns < opts.insn_limit)) {
    if (run_info.rvfi.has_value()) {
      switch (run_info.rvfi->pre_step(opts.config_print_rvfi)) {
      case RVFI_prestep_continue:
        continue;
      case RVFI_prestep_eof:
        run_info.rvfi = std::nullopt;
        return;
      case RVFI_prestep_end_trace:
        return;
      case RVFI_prestep_ok:
        break;
      }
    }

    model.call_pre_step_callbacks(is_waiting);

    { /* run a Sail step */
      is_waiting = model.try_step(step_no, wait_steps_remaining == 0);

      std::optional<std::string> opt_str = model.string_of_current_exception();
      if (opt_str.has_value()) {
        fprintf(stdout, "%s\n", opt_str.value().c_str());
        break;
      }
      if (opts.config_print_instr) {
        flush_logs(run_info);
      }
      if (run_info.rvfi) {
        run_info.rvfi->send_trace(opts.config_print_rvfi);
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

    model.call_post_step_callbacks(is_waiting);

    if (!is_waiting) {
      if (opts.config_print_step) {
        fprintf(run_info.trace_log, "\n");
      }
      step_no++;
      insn_cnt++;
      run_info.total_insns++;
    }

    if (opts.do_show_times && (run_info.total_insns & 0xfffff) == 0) {
      const auto now = steady_clock::now();
      const auto interval = now - interval_start;
      interval_start = now;

      uint64_t kips = 0x100000 / duration_cast<milliseconds>(interval).count();
      fprintf(stdout, "kips: %" PRIu64 "\n", kips);
    }

    if (model.htif_done()) {
      /* check exit code */
      if (model.htif_exit_code() == 0) {
        fprintf(stdout, "SUCCESS\n");
      } else {
        fprintf(stdout, "FAILURE: %" PRIu64 " (0x%08" PRIx64 ")\n", model.htif_exit_code(), model.htif_exit_code());
        exit(EXIT_FAILURE);
      }
    }

    if (insn_cnt == insns_per_tick) {
      insn_cnt = 0;
      model.tick_clock();
    } else if (wait_steps_remaining > 0) {
      model.tick_clock();
    }

    if (loop_detector->loop_detected()) {
      fprintf(
        stdout,
        "FAILURE: possible trap loop detected with MEPC=0x%" PRIx64 " and SEPC=0x%" PRIx64 "\n",
        loop_detector->mepc(),
        loop_detector->sepc()
      );
      exit(EXIT_FAILURE);
    }
  }

  // This is reached if there is a Sail exception, HTIF has indicated
  // successful completion, or the instruction limit has been reached.
  finish(model, opts, elf_info, run_info);
}

void init_logs(const CLIOptions &opts, run_info &run_info) {
  if (!opts.term_log.empty()) {
    run_info.term_fd = open(opts.term_log.c_str(), O_WRONLY | O_CREAT | O_TRUNC, S_IRUSR | S_IRGRP | S_IROTH | S_IWUSR);
    if (run_info.term_fd < 0) {
      fprintf(stderr, "Cannot create terminal log '%s': %s\n", opts.term_log.c_str(), strerror(errno));
      exit(EXIT_FAILURE);
    }
    run_info.close_term_fd = true;
  }

  if (!opts.trace_log_path.empty()) {
    run_info.trace_log = fopen(opts.trace_log_path.c_str(), "w+");
    if (run_info.trace_log == nullptr) {
      fprintf(stderr, "Cannot create trace log '%s': %s\n", opts.trace_log_path.c_str(), strerror(errno));
      exit(EXIT_FAILURE);
    }
  }

#ifdef SAILCOV
  if (!opts.sailcov_file.empty()) {
    sail_set_coverage_file(opts.sailcov_file.c_str());
  }
#endif
}

// Processes options that don't need an initialized model and gets the
// json configuration string; returns whether to continue with model
// initialization.
InitResult preinit_args(CLIOptions &opts, std::string &config_json_string) {
  if (opts.do_print_version) {
    std::cout << version_info::release_version() << std::endl;
    return InitResult::ExitSuccess;
  }
  if (opts.do_print_build_info) {
    print_build_info();
    return InitResult::ExitSuccess;
  }
  if (opts.do_print_default_config) {
    printf("%s", opts.use_rv32_default ? get_default_rv32_config() : get_default_config());
    return InitResult::ExitSuccess;
  }
  if (opts.do_print_config_schema) {
    printf("%s", get_config_schema());
    return InitResult::ExitSuccess;
  }

  if (opts.do_show_times) {
    fprintf(stderr, "will show execution times on completion.\n");
  }
  if (!opts.term_log.empty()) {
    fprintf(stderr, "using %s for terminal output.\n", opts.term_log.c_str());
  }
  if (!opts.sig_file.empty()) {
    fprintf(stderr, "using %s for test-signature output.\n", opts.sig_file.c_str());
  }
  if (opts.signature_granularity != DEFAULT_SIGNATURE_GRANULARITY) {
    fprintf(stderr, "setting signature-granularity to %d bytes\n", opts.signature_granularity);
  }
  if (!opts.trace_log_path.empty()) {
    fprintf(stderr, "using %s for trace output.\n", opts.trace_log_path.c_str());
  }

  if (!opts.config_file.empty()) {
    config_json_string = read_file_to_string(opts.config_file);
  } else {
    config_json_string = opts.use_rv32_default ? get_default_rv32_config() : get_default_config();
  }

  // Check json config and merge overrides
  const std::string base_source_desc =
    opts.config_file.empty() ? "default configuration" : "configuration file " + opts.config_file;
  jsoncons::json config_json = parse_json_or_exit(config_json_string, base_source_desc);
  for (const auto &override_path : opts.config_overrides) {
    std::string override_json_string = read_file_to_string(override_path);
    jsoncons::json override_item = parse_json_or_exit(override_json_string, "override file " + override_path);
    deep_merge_json(config_json, override_item);
  }

  std::ostringstream os;
  os << config_json;
  config_json_string = os.str();

  // Always validate the schema conformance of the config.
  std::string config_source_desc = opts.config_file.empty() ? "default configuration" : opts.config_file;
  if (!opts.config_overrides.empty()) {
    config_source_desc = "merged configuration from " + config_source_desc;
    for (const auto &override_path : opts.config_overrides) {
      config_source_desc = config_source_desc + ", " + override_path;
    }
  }
  validate_config_schema(config_json, config_source_desc);

  return InitResult::Continue;
}

// Configures the model, validates the configuration, processes
// options requiring a configured model and returns whether to continue with
// model simulation.
InitResult preinit_model(
  CLIOptions &opts,
  ModelImpl &model,
  const std::string &config_json_string,
  run_info &run_info
) {
  if (opts.rvfi_dii_port != 0) {
    run_info.rvfi.emplace(opts.rvfi_dii_port, model);
  }

  if (opts.config_enable_experimental_extensions) {
    fprintf(stderr, "enabling unratified extensions.\n");
    model.set_enable_experimental_extensions(true);
  }

  // Initialize the model.

  model.set_config_print_instr(opts.config_print_instr);
  model.set_config_print_clint(opts.config_print_clint);
  model.set_config_print_exception(opts.config_print_exception);
  model.set_config_print_interrupt(opts.config_print_interrupt);
  model.set_config_print_htif(opts.config_print_htif);
  model.set_config_print_pma(opts.config_print_pma);
  model.set_config_rvfi(run_info.rvfi.has_value());
  model.set_config_use_abi_names(opts.config_use_abi_names);

  model.set_config_print_step(opts.config_print_step);

  sail_config_set_string(config_json_string.c_str());

  // Initialize platform.
  model.init_platform_constants();

  model.model_init();

  // Validate the configuration; exit if that's all we were asked to do
  // or if the validation failed.
  {
    bool config_is_valid = model.config_is_valid();
    const char *s = config_is_valid ? "valid" : "invalid";
    if (!config_is_valid || opts.do_validate_config) {
      if (opts.config_file.empty()) {
        fprintf(stderr, "Default configuration is %s.\n", s);
      } else {
        fprintf(stderr, "Configuration in %s is %s.\n", opts.config_file.c_str(), s);
      }
      return config_is_valid ? InitResult::ExitSuccess : InitResult::ExitFailure;
    }
  }

  // Print a device tree or an ISA string only after the configuration
  // is validated above.
  if (opts.do_print_dts) {
    fprintf(stdout, "%s", model.generate_dts().c_str());
    return InitResult::ExitSuccess;
  }
  if (opts.do_print_isa) {
    fprintf(stdout, "%s\n", model.generate_isa_string().c_str());
    return InitResult::ExitSuccess;
  }

  // If we get here, we need to have ELF files to run (except in RVFI mode).
  if (opts.elfs.empty() && !run_info.rvfi.has_value()) {
    fprintf(stderr, "No elf file provided.\n");
    return InitResult::ExitFailure;
  }

  init_logs(opts, run_info);
  model.set_term_fd(run_info.term_fd);
  model.set_trace_log(run_info.trace_log);

  return InitResult::Continue;
}

uint64_t init_model(CLIOptions &opts, ModelImpl &model, elf_info &elf_info, run_info &run_info) {
  run_info.init_start = steady_clock::now();

  if (run_info.rvfi.has_value()) {
    if (!run_info.rvfi->setup_socket(opts.config_print_rvfi)) {
      return 1;
    }
    model.register_callback(std::make_shared<rvfi_callbacks>());
  }

  if (!opts.dtb_file.empty()) {
    fprintf(stderr, "using %s as DTB file.\n", opts.dtb_file.c_str());
    write_dtb_to_rom(model, read_file(opts.dtb_file));
  }

  uint64_t entry = run_info.rvfi.has_value() ? run_info.rvfi->get_entry()
                                             : load_sail(model, opts.elfs[0], /*main_file=*/true, elf_info);

  fprintf(stdout, "Entry point: 0x%" PRIx64 "\n", entry);

  // Load any additional ELF files into memory. If RVFI was NOT used skip
  // the first one because it was loaded above.
  for (auto it = opts.elfs.cbegin() + (run_info.rvfi.has_value() ? 0 : 1); it != opts.elfs.cend(); it++) {
    fprintf(stdout, "Loading additional ELF file %s.\n", it->c_str());
    (void)load_sail(model, *it, /*main_file=*/false, elf_info);
  }

  model.set_elf_symbols(std::move(elf_info.symbols));
  model.init_sail(entry, opts.config_file.c_str(), elf_info.htif_tohost_address);

  run_info.init_end = steady_clock::now();

  return entry;
}
