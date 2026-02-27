#include <cassert>
#include <chrono>
#include <climits>
#include <cstring>
#include <ctype.h>
#include <errno.h>
#include <exception>
#include <fcntl.h>
#include <iostream>
#include <optional>
#include <stdexcept>
#include <stdio.h>
#include <stdlib.h>
#include <sys/mman.h>
#include <sys/stat.h>
#include <sys/time.h>
#include <sys/types.h>
#include <unistd.h>
#include <vector>

#include "CLI11.hpp"
#include "elf_loader.h"
#include "jsoncons/config/version.hpp"
#include "jsoncons/json.hpp"
#include "rts.h"
#include "sail.h"
#include "sail_config.h"
#include "symbol_table.h"
#ifdef SAILCOV
#include "sail_coverage.h"
#endif
#include "config_utils.h"
#include "file_utils.h"
#include "riscv_callbacks_log.h"
#include "riscv_callbacks_rvfi.h"
#include "riscv_model_impl.h"
#include "rvfi_dii.h"
#include "sail_riscv_version.h"

using std::chrono::duration_cast;
using std::chrono::milliseconds;
using std::chrono::steady_clock;

namespace {

std::optional<rvfi_handler> rvfi;

// The address of the HTIF tohost port, if it is enabled.
std::optional<uint64_t> htif_tohost_address;

rvfi_callbacks rvfi_cbs;

uint64_t mem_sig_start = 0;
uint64_t mem_sig_end = 0;

steady_clock::time_point init_start;
steady_clock::time_point init_end;

uint64_t total_insns = 0;
#ifdef SAILCOV
char *sailcov_file = nullptr;
#endif

} // namespace

FILE *trace_log = stdout;

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

static jsoncons::json parse_json_or_exit(const std::string &json_text, const std::string &source_desc) {
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
  bool config_print_reg = false;
  bool config_print_mem_access = false;
  bool config_print_clint = false;
  bool config_print_exception = false;
  bool config_print_interrupt = false;
  bool config_print_htif = false;
  bool config_print_pma = false;
  bool config_print_rvfi = false;
  bool config_print_step = false;
  bool config_print_ptw = false;

  bool config_use_abi_names = false;

  bool config_enable_experimental_extensions = false;
};

// Parse CLI options. This calls `exit()` on failure.
static CLIOptions parse_cli(int argc, char **argv) {
  CLI::App app("Sail RISC-V Model");
  argv = app.ensure_utf8(argv);

  if (argc == 1) {
    fprintf(stdout, "%s\n", app.help().c_str());
    exit(EXIT_FAILURE);
  }

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

  app.add_option("--device-tree-blob", opts.dtb_file, "Device tree blob file")
    ->check(CLI::ExistingFile)
    ->option_text("<file>");
  app.add_option("--terminal-log", opts.term_log, "Terminal log output file")->option_text("<file>");
  app.add_option("--test-signature", opts.sig_file, "Test signature file")->option_text("<file>");
  app.add_option("--config", opts.config_file, "Configuration file")->check(CLI::ExistingFile)->option_text("<file>");
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
  app.add_flag("--trace-reg", opts.config_print_reg, "Enable trace output for register access");
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
    "--trace-all",
    [&opts] {
      opts.config_print_instr = true;
      opts.config_print_reg = true;
      opts.config_print_mem_access = true;
      opts.config_print_rvfi = true;
      opts.config_print_clint = true;
      opts.config_print_exception = true;
      opts.config_print_interrupt = true;
      opts.config_print_htif = true;
      opts.config_print_pma = true;
      opts.config_print_step = true;
      opts.config_print_ptw = true;
    },
    "Enable all trace output"
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

  try {
    app.parse(argc, argv);
  } catch (const CLI::ParseError &e) {
    exit(app.exit(e));
  }

  return opts;
}

uint64_t load_sail(ModelImpl &model, const std::string &filename, bool main_file) {
  ELF elf = ELF::open(filename);

  switch (elf.architecture()) {
  case Architecture::RV32:
    if (model.zxlen != 32) {
      fprintf(stderr, "32-bit ELF not supported by RV%" PRIu64 " model.\n", model.zxlen);
      exit(EXIT_FAILURE);
    }
    break;
  case Architecture::RV64:
    if (model.zxlen != 64) {
      fprintf(stderr, "64-bit ELF not supported by RV%" PRIu64 " model.\n", model.zxlen);
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
  g_symbols.insert(reversed_symbols.begin(), reversed_symbols.end());

  if (main_file) {
    // Only scan for test-signature/htif symbols in the main ELF file.

    const auto &tohost = symbols.find("tohost");
    if (tohost == symbols.end()) {
      fprintf(stderr, "Unable to locate tohost symbol; disabling HTIF.\n");
      htif_tohost_address = std::nullopt;
    } else {
      htif_tohost_address = tohost->second;
      fprintf(stdout, "HTIF located at 0x%0" PRIx64 "\n", *htif_tohost_address);
    }
    // Locate test-signature locations if any.
    const auto &begin_sig = symbols.find("begin_signature");
    if (begin_sig != symbols.end()) {
      fprintf(stdout, "begin_signature: 0x%0" PRIx64 "\n", begin_sig->second);
      mem_sig_start = begin_sig->second;
    }
    const auto &end_sig = symbols.find("end_signature");
    if (end_sig != symbols.end()) {
      fprintf(stdout, "end_signature: 0x%0" PRIx64 "\n", end_sig->second);
      mem_sig_end = end_sig->second;
    }
  }

  return elf.entry();
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
  if (!model.zdtb_within_configured_pma_memory(addr, size)) {
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

void init_platform_constants(ModelImpl &model) {
  model.set_reservation_set_size_exp(get_config_uint64({"platform", "reservation_set_size_exp"}));
}

void init_sail(ModelImpl &model, uint64_t elf_entry, const char *config_file) {
  // zset_pc_reset_address must be called before zinit_model
  // because reset happens inside init_model().
  model.zset_pc_reset_address(elf_entry);
  if (htif_tohost_address.has_value()) {
    model.zenable_htif(*htif_tohost_address);
  }
  model.zinit_model(config_file != nullptr ? config_file : "");
  model.zinit_boot_requirements(UNIT);
}

/* reinitialize to clear state and memory, typically across tests runs */
void reinit_sail(ModelImpl &model, uint64_t elf_entry, const char *config_file) {
  model.model_fini();
  model.model_init();
  init_sail(model, elf_entry, config_file);
}

void write_signature(const std::string &file, unsigned signature_granularity) {
  if (mem_sig_start >= mem_sig_end) {
    fprintf(
      stderr,
      "Invalid signature region [0x%0" PRIx64 ",0x%0" PRIx64 "] to %s.\n",
      mem_sig_start,
      mem_sig_end,
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
  for (uint64_t addr = mem_sig_start; addr < mem_sig_end; addr += signature_granularity) {
    /* most-significant byte first */
    for (int i = signature_granularity - 1; i >= 0; i--) {
      uint8_t byte = (uint8_t)read_mem(addr + i);
      fprintf(f, "%02x", byte);
    }
    fprintf(f, "\n");
  }
  fclose(f);
}

void close_logs() {
#ifdef SAILCOV
  if (sail_coverage_exit() != 0) {
    fprintf(stderr, "Could not write coverage information!\n");
    exit(EXIT_FAILURE);
  }
#endif
  if (trace_log != stdout) {
    fclose(trace_log);
  }
}

void finish(ModelImpl &model, const CLIOptions &opts) {
  // Don't write a signature if there was an internal Sail exception.
  if (!model.have_exception && !opts.sig_file.empty()) {
    write_signature(opts.sig_file, opts.signature_granularity);
  }

  // `model_fini()` exits with failure if there was a Sail exception.
  model.model_fini();

  if (opts.do_show_times) {
    auto run_end = steady_clock::now();
    uint64_t init_msecs = duration_cast<milliseconds>(init_end - init_start).count();
    uint64_t exec_msecs = duration_cast<milliseconds>(run_end - init_end).count();
    uint64_t kips = total_insns / exec_msecs;
    fprintf(stderr, "Initialization:   %" PRIu64 " ms\n", init_msecs);
    fprintf(stderr, "Execution:        %" PRIu64 " ms\n", exec_msecs);
    fprintf(stderr, "Instructions:     %" PRIu64 "\n", total_insns);
    fprintf(stderr, "Performance:      %" PRIu64 " kIPS\n", kips);
  }
  close_logs();
  exit(EXIT_SUCCESS);
}

void flush_logs() {
  fflush(stderr);
  fflush(stdout);
  fflush(trace_log);
}

void run_sail(ModelImpl &model, const CLIOptions &opts) {
  bool is_waiting = false;
  uint64_t max_wait_steps = get_config_uint64({"platform", "max_steps_to_wait"});
  uint64_t wait_steps_remaining = 0;

  /* initialize the step number */
  mach_int step_no = 0;
  uint64_t insn_cnt = 0;

  uint64_t insns_per_tick = get_config_uint64({"platform", "instructions_per_tick"});

  auto interval_start = steady_clock::now();

  while (!model.zhtif_done && (opts.insn_limit == 0 || total_insns < opts.insn_limit)) {
    if (rvfi.has_value()) {
      switch (rvfi->pre_step(opts.config_print_rvfi)) {
      case RVFI_prestep_continue:
        continue;
      case RVFI_prestep_eof:
        rvfi = std::nullopt;
        return;
      case RVFI_prestep_end_trace:
        return;
      case RVFI_prestep_ok:
        break;
      }
    }

    model.call_pre_step_callbacks(is_waiting);

    { /* run a Sail step */
      sail_int sail_step;
      CREATE(sail_int)(&sail_step);
      CONVERT_OF(sail_int, mach_int)(&sail_step, step_no);
      is_waiting = model.ztry_step(sail_step, wait_steps_remaining == 0);
      KILL(sail_int)(&sail_step);

      if (model.have_exception) {
        model.print_current_exception();
        break;
      }
      if (opts.config_print_instr) {
        flush_logs();
      }
      if (rvfi) {
        rvfi->send_trace(opts.config_print_rvfi);
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
        fprintf(trace_log, "\n");
      }
      step_no++;
      insn_cnt++;
      total_insns++;
    }

    if (opts.do_show_times && (total_insns & 0xfffff) == 0) {
      const auto now = steady_clock::now();
      const auto interval = now - interval_start;
      interval_start = now;

      uint64_t kips = 0x100000 / duration_cast<milliseconds>(interval).count();
      fprintf(stdout, "kips: %" PRIu64 "\n", kips);
    }

    if (model.zhtif_done) {
      /* check exit code */
      if (model.zhtif_exit_code == 0) {
        fprintf(stdout, "SUCCESS\n");
      } else {
        fprintf(stdout, "FAILURE: %" PRIi64 "\n", model.zhtif_exit_code);
        exit(EXIT_FAILURE);
      }
    }

    if (insn_cnt == insns_per_tick) {
      insn_cnt = 0;
      model.ztick_clock(UNIT);
    } else if (wait_steps_remaining > 0) {
      model.ztick_clock(UNIT);
    }
  }

  // This is reached if there is a Sail exception, HTIF has indicated
  // successful completion, or the instruction limit has been reached.
  finish(model, opts);
}

void init_logs(const CLIOptions &opts) {
  if (!opts.term_log.empty() &&
      (term_fd = open(opts.term_log.c_str(), O_WRONLY | O_CREAT | O_TRUNC, S_IRUSR | S_IRGRP | S_IROTH | S_IWUSR)) <
        0) {
    fprintf(stderr, "Cannot create terminal log '%s': %s\n", opts.term_log.c_str(), strerror(errno));
    exit(EXIT_FAILURE);
  }

  if (!opts.trace_log_path.empty()) {
    trace_log = fopen(opts.trace_log_path.c_str(), "w+");
    if (trace_log == nullptr) {
      fprintf(stderr, "Cannot create trace log '%s': %s\n", opts.trace_log_path.c_str(), strerror(errno));
      exit(EXIT_FAILURE);
    }
  }

#ifdef SAILCOV
  if (!sailcov_file.empty()) {
    sail_set_coverage_file(sailcov_file.c_str());
  }
#endif
}

int inner_main(int argc, char **argv) {

  CLIOptions opts = parse_cli(argc, argv);

  ModelImpl model;

  if (opts.do_print_version) {
    std::cout << version_info::release_version << std::endl;
    return EXIT_SUCCESS;
  }
  if (opts.do_print_build_info) {
    print_build_info();
    return EXIT_SUCCESS;
  }
  if (opts.do_print_default_config) {
    printf("%s", get_default_config());
    return EXIT_SUCCESS;
  }
  if (opts.do_print_config_schema) {
    printf("%s", get_config_schema());
    return EXIT_SUCCESS;
  }
  if (opts.rvfi_dii_port != 0) {
    rvfi.emplace(opts.rvfi_dii_port, model);
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

  model.set_config_print_instr(opts.config_print_instr);
  model.set_config_print_clint(opts.config_print_clint);
  model.set_config_print_exception(opts.config_print_exception);
  model.set_config_print_interrupt(opts.config_print_interrupt);
  model.set_config_print_htif(opts.config_print_htif);
  model.set_config_print_pma(opts.config_print_pma);
  model.set_config_rvfi(rvfi.has_value());
  model.set_config_use_abi_names(opts.config_use_abi_names);

  model.set_config_print_step(opts.config_print_step);

  std::string config_json_string;
  if (!opts.config_file.empty()) {
    config_json_string = read_file_to_string(opts.config_file);
  } else {
    config_json_string = get_default_config();
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

  // Initialize the model.
  sail_config_set_string(config_json_string.c_str());

  // Initialize platform.
  init_platform_constants(model);

  model.model_init();

  // Validate the configuration; exit if that's all we were asked to do
  // or if the validation failed.
  {
    bool config_is_valid = model.zconfig_is_valid(UNIT);
    const char *s = config_is_valid ? "valid" : "invalid";
    if (!config_is_valid || opts.do_validate_config) {
      if (opts.config_file.empty()) {
        fprintf(stderr, "Default configuration is %s.\n", s);
      } else {
        fprintf(stderr, "Configuration in %s is %s.\n", opts.config_file.c_str(), s);
      }
      return config_is_valid ? EXIT_SUCCESS : EXIT_FAILURE;
    }
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

  // If we get here, we need to have ELF files to run.
  if (opts.elfs.empty()) {
    fprintf(stderr, "No elf file provided.\n");
    return EXIT_FAILURE;
  }

  init_logs(opts);
  log_callbacks log_cbs(
    opts.config_print_reg,
    opts.config_print_mem_access,
    opts.config_print_ptw,
    opts.config_use_abi_names,
    trace_log
  );
  model.register_callback(&log_cbs);

  init_start = steady_clock::now();

  if (rvfi) {
    if (!rvfi->setup_socket(opts.config_print_rvfi)) {
      return 1;
    }
    model.register_callback(&rvfi_cbs);
  }

  if (!opts.dtb_file.empty()) {
    fprintf(stderr, "using %s as DTB file.\n", opts.dtb_file.c_str());
    write_dtb_to_rom(model, read_file(opts.dtb_file));
  }

  const std::string &initial_elf_file = opts.elfs[0];
  uint64_t entry = rvfi ? rvfi->get_entry() : load_sail(model, initial_elf_file, /*main_file=*/true);

  fprintf(stdout, "Entry point: 0x%" PRIx64 "\n", entry);

  /* Load any additional ELF files into memory */
  for (auto it = opts.elfs.cbegin() + 1; it != opts.elfs.cend(); it++) {
    fprintf(stdout, "Loading additional ELF file %s.\n", it->c_str());
    (void)load_sail(model, *it, /*main_file=*/false);
  }

  init_sail(model, entry, opts.config_file.c_str());

  init_end = steady_clock::now();

  do {
    run_sail(model, opts);
    // `run_sail` only returns in the case of rvfi.
    if (rvfi) {
      /* Reset for next test */
      reinit_sail(model, entry, opts.config_file.c_str());
    }
  } while (rvfi);

  model.model_fini();
  flush_logs();
  close_logs();

  return EXIT_SUCCESS;
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
