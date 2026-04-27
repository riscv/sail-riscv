#include <cassert>
#include <chrono>
#include <climits>
#include <cstring>
#include <ctype.h>
#include <errno.h>
#include <exception>
#include <iostream>
#include <optional>
#include <stdexcept>
#include <stdio.h>
#include <stdlib.h>
#include <vector>

#include "CLI11.hpp"
#include "elf_loader.h"
#include "jsoncons/config/version.hpp"
#include "jsoncons/json.hpp"
#include "riscv_sim_utils.h"
#include "sail.h"
#include "sail_config.h"
#ifdef SAILCOV
#include "sail_coverage.h"
#endif
#include "config_utils.h"
#include "file_utils.h"
#include "riscv_model_impl.h"
#include "sail_riscv_version.h"
#include "simulator.h"

#ifdef SAILCOV
namespace {
char *sailcov_file = nullptr;
} // namespace
#endif

static void print_dts(ModelImpl &model) {
  char *dts = nullptr;
  model.zgenerate_dts(&dts, UNIT);
  fprintf(stdout, "%s", dts);
  KILL(sail_string)(&dts);
}

static void print_isa(ModelImpl &model) {
  char *isa = nullptr;
  model.zgenerate_canonical_isa_string(&isa, UNIT);
  fprintf(stdout, "%s\n", isa);
  KILL(sail_string)(&isa);
}

static void print_build_info() {
  std::cout << "Sail RISC-V release: " << version_info::release_version << std::endl;
  std::cout << "Sail RISC-V git: " << version_info::git_version << std::endl;
  std::cout << "Sail: " << version_info::sail_version << std::endl;
  std::cout << "C++ compiler: " << version_info::cxx_compiler_version << std::endl;
  std::cout << "CLI11: " << CLI11_VERSION << std::endl;
  std::cout << "ELFIO: " << ELFIO_VERSION << std::endl;
  std::cout << "JSONCONS: " << jsoncons::version() << std::endl;
}

static jsoncons::json parse_json(const std::string &json_text, const std::string &source_desc) {
  try {
    return jsoncons::json::parse(json_text);
  } catch (const jsoncons::json_exception &e) {
    throw riscv_sim::ConfigError("JSON parse error in " + source_desc + ":\n" + e.what());
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

const unsigned DEFAULT_SIGNATURE_GRANULARITY = 4;

struct CLIOptions {
  bool do_show_times = false;
  bool do_print_version = false;
  bool do_print_build_info = false;
  bool do_print_default_config = false;
  bool do_print_config_schema = false;
  bool do_print_dts = false;
  bool do_validate_config = false;
  bool do_print_isa = false;

  bool use_rv32_default = false;
  bool disable_trap_loop_detection = false;
  std::string config_file;
  std::vector<std::string> config_overrides;
  std::string term_log;
  std::string trace_log_path;
  std::string dtb_file;
  unsigned rvfi_dii_port = 0;
  std::vector<std::string> elfs;
  uint64_t insn_limit = 0;

  std::string sig_file;
  unsigned signature_granularity = DEFAULT_SIGNATURE_GRANULARITY;

#ifdef SAILCOV
  std::string sailcov_file;
#endif

  bool config_print_instr = false;
  bool config_print_gpr = false;
  bool config_print_fpr = false;
  bool config_print_vreg = false;
  bool config_print_csr = false;
  bool config_print_mem_access = false;
  bool config_print_clint = false;
  bool config_print_exception = false;
  bool config_print_interrupt = false;
  bool config_print_htif = false;
  bool config_print_pma = false;
  bool config_print_rvfi = false;
  bool config_print_step = false;
  bool config_print_ptw = false;
  bool config_print_tlb = false;

  bool config_use_abi_names = false;

  bool config_enable_experimental_extensions = false;
};

// Parse CLI options. This calls `exit()` on failure.
static CLIOptions parse_cli(int argc, char **argv) {
  CLI::App app("Sail RISC-V Model");
  argv = app.ensure_utf8(argv);

  CLIOptions opts;

  app.add_flag("--show-times", opts.do_show_times, "Show execution times");
  app.add_flag("--version", opts.do_print_version, "Print model version");
  app.add_flag("--build-info", opts.do_print_build_info, "Print build information");
  app.add_flag("--print-default-config", opts.do_print_default_config, "Print default configuration");
  app.add_flag("--print-config-schema", opts.do_print_config_schema, "Print configuration schema");
  app.add_flag("--validate-config", opts.do_validate_config, "Exit after config validation (it is always validated)");
  app.add_flag("--print-device-tree", opts.do_print_dts, "Print device tree");
  app.add_flag("--print-isa-string", opts.do_print_isa, "Print ISA string");
  app.add_flag(
    "--enable-experimental-extensions",
    opts.config_enable_experimental_extensions,
    "Enable experimental extensions"
  );
  app.add_flag("--use-abi-names", opts.config_use_abi_names, "Use ABI register names in trace log");
  app.add_flag("--rv32", opts.use_rv32_default, "Use the default RV32 configuration");
  app.add_flag(
    "--disable-trap-loop-detection",
    opts.disable_trap_loop_detection,
    "Disable detection of potentially infinite trap loops"
  );

  app.add_option("--device-tree-blob", opts.dtb_file, "Device tree blob file")
    ->check(CLI::ExistingFile)
    ->option_text("<file>");
  app.add_option("--terminal-log", opts.term_log, "Terminal log output file")->option_text("<file>");
  app.add_option("--test-signature", opts.sig_file, "Test signature file")->option_text("<file>");
  app.add_option("--config", opts.config_file, "Configuration file")
    ->check(CLI::ExistingFile)
    ->option_text("<file>")
    ->excludes("--rv32");
  app
    .add_option(
      "--config-override",
      opts.config_overrides,
      "Configuration override file (repeatable; later files override earlier ones). Use this when you only want to "
      "change a small part of the base configuration."
    )
    ->check(CLI::ExistingFile)
    ->option_text("<file>")
    ->allow_extra_args(false);
  app.add_option("--trace-output", opts.trace_log_path, "Trace output file")->option_text("<file>");

  app.add_option("--signature-granularity", opts.signature_granularity, "Signature granularity")->option_text("<uint>");
  app.add_option("--rvfi-dii", opts.rvfi_dii_port, "RVFI DII port")
    ->check(CLI::Range(1, 65535))
    ->option_text("<int> (within [1 - 65535])");
  app.add_option("--inst-limit", opts.insn_limit, "Instruction limit")->option_text("<uint>");
#ifdef SAILCOV
  app.add_option("--sailcov-file", sailcov_file, "Sail coverage output file")->option_text("<file>");
#endif

  app.add_flag("--trace-instr", opts.config_print_instr, "Enable trace output for instruction execution");
  app.add_flag("--trace-ptw", opts.config_print_ptw, "Enable trace output for Page Table walk");
  app.add_flag("--trace-tlb", opts.config_print_tlb, "Enable trace output for TLB adds and flushes");
  app.add_flag(
    "--trace-gpr",
    opts.config_print_gpr,
    "Enable trace output for general purpose register reads and writes"
  );
  app.add_flag(
    "--trace-fpr",
    opts.config_print_fpr,
    "Enable trace output for floating-point registers reads and writes"
  );
  app.add_flag("--trace-vreg", opts.config_print_vreg, "Enable trace output for vector register reads and writes");
  app.add_flag("--trace-csr", opts.config_print_csr, "Enable trace output for CSR reads and writes");
  app.add_flag_callback(
    "--trace-arch-regs",
    [&opts] {
      opts.config_print_gpr = true;
      opts.config_print_fpr = true;
      opts.config_print_vreg = true;
    },
    "Enable trace output for architectural register reads and writes (i.e. general purpose, floating-point, and "
    "vector registers)"
  );
  app.add_flag_callback(
    "--trace-reg",
    [&opts] {
      opts.config_print_gpr = true;
      opts.config_print_fpr = true;
      opts.config_print_vreg = true;
      opts.config_print_csr = true;
    },
    "Enable trace output for register access"
  );
  app.add_flag("--trace-mem", opts.config_print_mem_access, "Enable trace output for memory accesses");
  app.add_flag("--trace-rvfi", opts.config_print_rvfi, "Enable trace output for RVFI");
  app.add_flag("--trace-clint", opts.config_print_clint, "Enable trace output for CLINT memory accesses and status");
  app.add_flag("--trace-exception", opts.config_print_exception, "Enable trace output for exceptions");
  app.add_flag("--trace-interrupt", opts.config_print_interrupt, "Enable trace output for interrupts");
  app.add_flag("--trace-htif", opts.config_print_htif, "Enable trace output for HTIF operations");
  app.add_flag("--trace-pma", opts.config_print_pma, "Enable trace output for PMA checks");
  app.add_flag_callback(
    "--trace-platform",
    [&opts] {
      opts.config_print_clint = true;
      opts.config_print_exception = true;
      opts.config_print_interrupt = true;
      opts.config_print_htif = true;
      opts.config_print_pma = true;
    },
    "Enable trace output for platform-level events (MMIO, interrupts, "
    "exceptions, CLINT, HTIF, PMA)"
  );
  app.add_flag("--trace-step", opts.config_print_step, "Add a blank line between steps in the trace output");

  app.add_flag_callback(
    "--trace",
    [&opts] {
      opts.config_print_instr = true;
      opts.config_print_gpr = true;
      opts.config_print_fpr = true;
      opts.config_print_vreg = true;
      opts.config_print_csr = true;
      opts.config_print_mem_access = true;
      opts.config_print_rvfi = true;
      opts.config_print_clint = true;
      opts.config_print_exception = true;
      opts.config_print_interrupt = true;
      opts.config_print_htif = true;
      opts.config_print_pma = true;
      opts.config_print_step = true;
    },
    "Enable all trace output except TLB and PTW traces"
  );

  // All positional arguments are treated as ELF files.  All ELF files
  // are loaded into memory, but only the first is scanned for the
  // magic `tohost/{begin,end}_signature` symbols.
  app.add_option(
    "elfs",
    opts.elfs,
    "List of ELF files to load. They will be loaded in order, possibly "
    "overwriting each other. PC will be set to the entry point of the first "
    "file. This is optional with some arguments, e.g. --print-isa-string."
  );

  std::size_t column_width = 45;
  app.get_formatter()->long_option_alignment_ratio(6.f / column_width);
  app.get_formatter()->column_width(column_width);

  if (argc == 1) {
    fprintf(stdout, "%s\n", app.help().c_str());
    exit(EXIT_FAILURE);
  }

  try {
    app.parse(argc, argv);
  } catch (const CLI::ParseError &e) {
    exit(app.exit(e));
  }

  return opts;
}

void init_platform_constants(ModelImpl &model) {
  model.set_reservation_set_size_exp(get_config_uint64({"platform", "reservation", "reservation_set_size_exp"}));
  model.set_reservation_require_exact_addr_match(
    get_config_bool({"platform", "reservation", "require_exact_reservation_addr"})
  );
}

std::optional<int> handle_early_print_modes(const CLIOptions &opts) {
  if (opts.do_print_version) {
    std::cout << version_info::release_version << std::endl;
    return EXIT_SUCCESS;
  }
  if (opts.do_print_build_info) {
    print_build_info();
    return EXIT_SUCCESS;
  }
  if (opts.do_print_default_config) {
    std::cout << (opts.use_rv32_default ? get_default_rv32_config() : get_default_config());
    return EXIT_SUCCESS;
  }
  if (opts.do_print_config_schema) {
    std::cout << get_config_schema();
    return EXIT_SUCCESS;
  }
  return std::nullopt;
}

std::optional<int> handle_late_print_modes(const CLIOptions &opts, ModelImpl &model) {
  // Validate the configuration, exit if that's all we were asked to do
  // or if the validation failed.
  bool config_is_valid = model.zconfig_is_valid(UNIT);
  std::string s = config_is_valid ? "valid" : "invalid";
  if (!config_is_valid || opts.do_validate_config) {
    if (opts.config_file.empty()) {
      std::cerr << "Default configuration is " << s << ".\n";
    } else {
      std::cerr << "Configuration in " << opts.config_file << " is " << s << ".\n";
    }
    return config_is_valid ? EXIT_SUCCESS : EXIT_FAILURE;
  }

  // Print a device tree or an ISA string only after the configuration
  // is validated above.
  if (opts.do_print_dts) {
    print_dts(model);
    return EXIT_SUCCESS;
  }
  if (opts.do_print_isa) {
    print_isa(model);
    return EXIT_SUCCESS;
  }
  return std::nullopt;
}

void load_and_init_config(const CLIOptions &opts, ModelImpl &model) {
  std::string config_json_string;
  if (!opts.config_file.empty()) {
    config_json_string = read_file_to_string(opts.config_file);
  } else {
    config_json_string = opts.use_rv32_default ? get_default_rv32_config() : get_default_config();
  }

  // Check json config and merge overrides
  const std::string base_source_desc =
    opts.config_file.empty() ? "default configuration" : "configuration file " + opts.config_file;
  jsoncons::json config_json = parse_json(config_json_string, base_source_desc);
  for (const auto &override_path : opts.config_overrides) {
    std::string override_json_string = read_file_to_string(override_path);
    jsoncons::json override_item = parse_json(override_json_string, "override file " + override_path);
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

  // Initialize the model.
  sail_config_set_string(config_json_string.c_str());

  // Initialize platform. Must run before model_init(), these values are
  // read during initialization.
  init_platform_constants(model);

  model.model_init();
}

int inner_main(int argc, char **argv) {
  CLIOptions opts = parse_cli(argc, argv);
  ModelImpl model;

  if (auto code = handle_early_print_modes(opts)) {
    return *code;
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
  if (opts.config_enable_experimental_extensions) {
    fprintf(stderr, "enabling unratified extensions.\n");
    model.set_enable_experimental_extensions(true);
  }
  if (!opts.trace_log_path.empty()) {
    fprintf(stderr, "using %s for trace output.\n", opts.trace_log_path.c_str());
  }

  const bool use_rvfi = (opts.rvfi_dii_port != 0);

  model.set_config_print_instr(opts.config_print_instr);
  model.set_config_print_clint(opts.config_print_clint);
  model.set_config_print_exception(opts.config_print_exception);
  model.set_config_print_interrupt(opts.config_print_interrupt);
  model.set_config_print_htif(opts.config_print_htif);
  model.set_config_print_pma(opts.config_print_pma);
  model.set_config_rvfi(use_rvfi);
  model.set_config_use_abi_names(opts.config_use_abi_names);
  model.set_config_print_step(opts.config_print_step);

  load_and_init_config(opts, model);

  if (auto code = handle_late_print_modes(opts, model)) {
    return *code;
  }

  // If we get here, we need to have ELF files to run (except in RVFI mode).
  if (opts.elfs.empty() && !use_rvfi) {
    fprintf(stderr, "No elf file provided.\n");
    return EXIT_FAILURE;
  }

  // DTB
  if (!opts.dtb_file.empty()) {
    fprintf(stderr, "using %s as DTB file.\n", opts.dtb_file.c_str());
    riscv_sim::write_dtb_to_rom(model, read_file(opts.dtb_file), get_config_uint64({"memory", "dtb_address"}));
  }

  // Load ELFs
  riscv_sim::LoadResult main_load;
  if (!use_rvfi) {
    main_load = riscv_sim::load_sail(model, opts.elfs[0], true);
  }

  // Config simulator
  riscv_sim::SimulatorConfig sim_cfg;
  sim_cfg.insn_limit = opts.insn_limit;
  sim_cfg.max_time_to_wait = get_config_uint64({"platform", "max_time_to_wait"});
  sim_cfg.insns_per_tick = get_config_uint64({"platform", "instructions_per_tick"});
  sim_cfg.trace_instr = opts.config_print_instr;
  sim_cfg.trace_step = opts.config_print_step;
  sim_cfg.trace_rvfi = opts.config_print_rvfi;
  sim_cfg.show_times = opts.do_show_times;
  sim_cfg.trace_gpr = opts.config_print_gpr;
  sim_cfg.trace_fpr = opts.config_print_fpr;
  sim_cfg.trace_vreg = opts.config_print_vreg;
  sim_cfg.trace_csr = opts.config_print_csr;
  sim_cfg.trace_mem_access = opts.config_print_mem_access;
  sim_cfg.trace_ptw = opts.config_print_ptw;
  sim_cfg.trace_tlb = opts.config_print_tlb;
  sim_cfg.use_abi_names = opts.config_use_abi_names;
  sim_cfg.sig_file = opts.sig_file;
  sim_cfg.sig_granularity = opts.signature_granularity;
  sim_cfg.sig_start = main_load.sig_start;
  sim_cfg.sig_end = main_load.sig_end;
  sim_cfg.trace_log_path = opts.trace_log_path;
  sim_cfg.term_log_path = opts.term_log;
  sim_cfg.rvfi_dii_port = opts.rvfi_dii_port;
  sim_cfg.enable_trap_loop_detection = !opts.disable_trap_loop_detection;

  // Initialize simulator (opens logs, sockets, registers callbacks)
  riscv_sim::Simulator simulator(model, sim_cfg);

#ifdef SAILCOV
  if (!sailcov_file.empty()) {
    sail_set_coverage_file(sailcov_file.c_str());
  }
#endif

  // Resolve entry, load remaining ELFs, init sail
  uint64_t entry = use_rvfi ? simulator.rvfi_entry() : main_load.entry;
  fprintf(stdout, "Entry point: 0x%" PRIx64 "\n", entry);

  for (auto it = opts.elfs.cbegin() + (use_rvfi ? 0 : 1); it != opts.elfs.cend(); ++it) {
    fprintf(stdout, "Loading additional ELF file %s.\n", it->c_str());
    (void)riscv_sim::load_sail(model, *it, false);
  }

  riscv_sim::init_sail(model, entry, main_load.htif_tohost, opts.config_file.c_str());

  // Run loop
  int exit_code = EXIT_SUCCESS;
  bool keep_running = true;
  while (keep_running) {
    auto result = simulator.run();
    switch (result.status) {
    case riscv_sim::RunStatus::HtifSuccess:
      fprintf(stdout, "SUCCESS\n");
      keep_running = false;
      break;
    case riscv_sim::RunStatus::HtifFailure:
      fprintf(stdout, "FAILURE: %" PRIu64 "\n", result.htif_exit_code);
      exit_code = EXIT_FAILURE;
      keep_running = false;
      break;
    case riscv_sim::RunStatus::TrapLoop:
      fprintf(
        stdout,
        "FAILURE: possible trap loop detected with MEPC=0x%" PRIx64 " and SEPC=0x%" PRIx64 "\n",
        result.mepc,
        result.sepc
      );
      exit_code = EXIT_FAILURE;
      keep_running = false;
      break;
    case riscv_sim::RunStatus::SailException:
    case riscv_sim::RunStatus::InstructionLimit:
    case riscv_sim::RunStatus::RvfiEof:
      keep_running = false;
      break;
    case riscv_sim::RunStatus::RvfiEndTrace:
      if (use_rvfi) {
        simulator.reset_for_next_run(entry, main_load.htif_tohost, opts.config_file.c_str());
      } else {
        keep_running = false;
      }
      break;
    }
  }

  // Finish
  if (!model.have_exception) {
    simulator.write_signature();
  }
  model.model_fini();
  if (sim_cfg.show_times) {
    simulator.print_times();
  }

#ifdef SAILCOV
  if (sail_coverage_exit() != 0) {
    fprintf(stderr, "Could not write coverage information!\n");
    exit_code = EXIT_FAILURE;
  }
#endif

  return exit_code;
}

int main(int argc, char **argv) {
  // Catch all exceptions and print them a bit more nicely than the default.
  try {
    return inner_main(argc, argv);
  } catch (const std::exception &exc) {
    std::cerr << "Error: " << exc.what() << std::endl;
  }
  return EXIT_FAILURE;
}
