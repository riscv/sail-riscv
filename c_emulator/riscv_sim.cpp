#include <cassert>
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
#include "rts.h"
#include "sail.h"
#include "sail_config.h"
#include "symbol_table.h"
#ifdef SAILCOV
#include "sail_coverage.h"
#endif
#include "config_utils.h"
#include "riscv_callbacks_log.h"
#include "riscv_callbacks_rvfi.h"
#include "riscv_model_impl.h"
#include "rvfi_dii.h"
#include "sail_riscv_version.h"

bool do_show_times = false;
bool do_print_version = false;
bool do_print_build_info = false;
bool do_print_default_config = false;
bool do_print_config_schema = false;
bool do_print_dts = false;
bool do_validate_config = false;
bool do_print_isa = false;

std::string config_file;
std::string term_log;
std::string trace_log_path;
FILE *trace_log = stdout;
std::string dtb_file;
int rvfi_dii_port = 0;
std::optional<rvfi_handler> rvfi;
std::vector<std::string> elfs;

// The address of the HTIF tohost port, if it is enabled.
std::optional<uint64_t> htif_tohost_address;

rvfi_callbacks rvfi_cbs;

std::string sig_file;
uint64_t mem_sig_start = 0;
uint64_t mem_sig_end = 0;
const int DEFAULT_SIGNATURE_GRANULARITY = 4;
int signature_granularity = DEFAULT_SIGNATURE_GRANULARITY;

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
bool config_enable_rvfi = false;

bool config_enable_experimental_extensions = false;

struct timeval init_start, init_end, run_end;
uint64_t total_insns = 0;
uint64_t insn_limit = 0;
#ifdef SAILCOV
char *sailcov_file = nullptr;
#endif

// Single global model instance.
// TODO: This shouldn't be global, but it is to facilitate gradual transition
// from the C Sail output which was necessarily global.
ModelImpl g_model;

static void print_dts(void) {
  char *dts = nullptr;
  g_model.zgenerate_dts(&dts, UNIT);
  fprintf(stdout, "%s", dts);
  KILL(sail_string)(&dts);
}

static void print_isa(void) {
  char *isa = nullptr;
  g_model.zgenerate_canonical_isa_string(&isa, UNIT);
  fprintf(stdout, "%s\n", isa);
  KILL(sail_string)(&isa);
}

static void print_build_info(void) {
  std::cout << "Sail RISC-V release: " << version_info::release_version << std::endl;
  std::cout << "Sail RISC-V git: " << version_info::git_version << std::endl;
  std::cout << "Sail: " << version_info::sail_version << std::endl;
  std::cout << "C++ compiler: " << version_info::cxx_compiler_version << std::endl;
  std::cout << "CLI11: " << CLI11_VERSION << std::endl;
  std::cout << "ELFIO: " << ELFIO_VERSION << std::endl;
  std::cout << "JSONCONS: " << jsoncons::version() << std::endl;
}

std::vector<uint8_t> read_file(const std::string &file_path) {
  std::ifstream instream(file_path, std::ios::in | std::ios::binary);
  return {std::istreambuf_iterator<char>(instream), std::istreambuf_iterator<char>()};
}

// Set up command line option processing.
static void setup_options(CLI::App &app) {
  app.add_flag("--show-times", do_show_times, "Show execution times");
  app.add_flag("--version", do_print_version, "Print model version");
  app.add_flag("--build-info", do_print_build_info, "Print build information");
  app.add_flag("--print-default-config", do_print_default_config, "Print default configuration");
  app.add_flag("--print-config-schema", do_print_config_schema, "Print configuration schema");
  app.add_flag("--validate-config", do_validate_config, "Exit after config validation (it is always validated)");
  app.add_flag("--print-device-tree", do_print_dts, "Print device tree");
  app.add_flag("--print-isa-string", do_print_isa, "Print ISA string");
  app.add_flag(
    "--enable-experimental-extensions",
    config_enable_experimental_extensions,
    "Enable experimental extensions"
  );
  app.add_flag("--use-abi-names", config_use_abi_names, "Use ABI register names in trace log");

  app.add_option("--device-tree-blob", dtb_file, "Device tree blob file")
    ->check(CLI::ExistingFile)
    ->option_text("<file>");
  app.add_option("--terminal-log", term_log, "Terminal log output file")->option_text("<file>");
  app.add_option("--test-signature", sig_file, "Test signature file")->option_text("<file>");
  app.add_option("--config", config_file, "Configuration file")->check(CLI::ExistingFile)->option_text("<file>");
  app.add_option("--trace-output", trace_log_path, "Trace output file")->option_text("<file>");

  app.add_option("--signature-granularity", signature_granularity, "Signature granularity")->option_text("<uint>");
  app.add_option("--rvfi-dii", rvfi_dii_port, "RVFI DII port")
    ->check(CLI::Range(1, 65535))
    ->option_text("<int> (within [1 - 65535])");
  app.add_option("--inst-limit", insn_limit, "Instruction limit")->option_text("<uint>");
#ifdef SAILCOV
  app.add_option("--sailcov-file", sailcov_file, "Sail coverage output file")->option_text("<file>");
#endif

  app.add_flag("--trace-instr", config_print_instr, "Enable trace output for instruction execution");
  app.add_flag("--trace-ptw", config_print_ptw, "Enable trace output for Page Table walk");
  app.add_flag("--trace-reg", config_print_reg, "Enable trace output for register access");
  app.add_flag("--trace-mem", config_print_mem_access, "Enable trace output for memory accesses");
  app.add_flag("--trace-rvfi", config_print_rvfi, "Enable trace output for RVFI");
  app.add_flag("--trace-clint", config_print_clint, "Enable trace output for CLINT memory accesses and status");
  app.add_flag("--trace-exception", config_print_exception, "Enable trace output for exceptions");
  app.add_flag("--trace-interrupt", config_print_interrupt, "Enable trace output for interrupts");
  app.add_flag("--trace-htif", config_print_htif, "Enable trace output for HTIF operations");
  app.add_flag("--trace-pma", config_print_pma, "Enable trace output for PMA checks");
  app.add_flag_callback(
    "--trace-platform",
    [] {
      config_print_clint = true;
      config_print_exception = true;
      config_print_interrupt = true;
      config_print_htif = true;
      config_print_pma = true;
    },
    "Enable trace output for platform-level events (MMIO, interrupts, "
    "exceptions, CLINT, HTIF, PMA)"
  );
  app.add_flag("--trace-step", config_print_step, "Add a blank line between steps in the trace output");

  app.add_flag_callback(
    "--trace-all",
    [] {
      config_print_instr = true;
      config_print_reg = true;
      config_print_mem_access = true;
      config_print_rvfi = true;
      config_print_clint = true;
      config_print_exception = true;
      config_print_interrupt = true;
      config_print_htif = true;
      config_print_pma = true;
      config_print_step = true;
      config_print_ptw = true;
    },
    "Enable all trace output"
  );

  // All positional arguments are treated as ELF files.  All ELF files
  // are loaded into memory, but only the first is scanned for the
  // magic `tohost/{begin,end}_signature` symbols.
  app.add_option(
    "elfs",
    elfs,
    "List of ELF files to load. They will be loaded in order, possibly "
    "overwriting each other. PC will be set to the entry point of the first "
    "file. This is optional with some arguments, e.g. --print-isa-string."
  );
}

uint64_t load_sail(const std::string &filename, bool main_file) {
  ELF elf = ELF::open(filename);

  switch (elf.architecture()) {
  case Architecture::RV32:
    if (g_model.zxlen != 32) {
      fprintf(stderr, "32-bit ELF not supported by RV%" PRIu64 " model.\n", g_model.zxlen);
      exit(EXIT_FAILURE);
    }
    break;
  case Architecture::RV64:
    if (g_model.zxlen != 64) {
      fprintf(stderr, "64-bit ELF not supported by RV%" PRIu64 " model.\n", g_model.zxlen);
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

void write_dtb_to_rom(const std::vector<uint8_t> &dtb) {
  uint64_t addr = get_config_uint64({"memory", "dtb_address"});
  uint64_t size = static_cast<uint64_t>(dtb.size());

  // Overflow check for addr + size - 1
  uint64_t end = addr + size - 1;
  if (end < addr) {
    fprintf(stderr, "DTB address/size overflow: addr=0x%0" PRIx64 ", size=0x%0" PRIx64 "\n", addr, size);
    exit(EXIT_FAILURE);
  }

  // Validate DTB range against configured PMA memory regions.
  if (!g_model.zdtb_within_configured_pma_memory(addr, size)) {
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

void init_platform_constants() {
  g_model.set_reservation_set_size_exp(get_config_uint64({"platform", "reservation_set_size_exp"}));
}

void init_sail(uint64_t elf_entry, const char *config_file) {
  // zset_pc_reset_address must be called before zinit_model
  // because reset happens inside init_model().
  g_model.zset_pc_reset_address(elf_entry);
  if (htif_tohost_address.has_value()) {
    g_model.zenable_htif(*htif_tohost_address);
  }
  g_model.zinit_model(config_file != nullptr ? config_file : "");
  g_model.zinit_boot_requirements(UNIT);
}

/* reinitialize to clear state and memory, typically across tests runs */
void reinit_sail(uint64_t elf_entry, const char *config_file) {
  g_model.model_fini();
  g_model.model_init();
  init_sail(elf_entry, config_file);
}

void write_signature(const char *file) {
  if (mem_sig_start >= mem_sig_end) {
    fprintf(
      stderr,
      "Invalid signature region [0x%0" PRIx64 ",0x%0" PRIx64 "] to %s.\n",
      mem_sig_start,
      mem_sig_end,
      file
    );
    return;
  }
  FILE *f = fopen(file, "w");
  if (!f) {
    fprintf(stderr, "Cannot open file '%s': %s\n", file, strerror(errno));
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

void close_logs(void) {
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

void finish() {
  // Don't write a signature if there was an internal Sail exception.
  if (!g_model.have_exception && !sig_file.empty()) {
    write_signature(sig_file.c_str());
  }

  // `model_fini()` exits with failure if there was a Sail exception.
  g_model.model_fini();

  if (do_show_times) {
    if (gettimeofday(&run_end, nullptr) < 0) {
      fprintf(stderr, "Cannot gettimeofday: %s\n", strerror(errno));
      exit(EXIT_FAILURE);
    }
    int init_msecs = (init_end.tv_sec - init_start.tv_sec) * 1000 + (init_end.tv_usec - init_start.tv_usec) / 1000;
    int exec_msecs = (run_end.tv_sec - init_end.tv_sec) * 1000 + (run_end.tv_usec - init_end.tv_usec) / 1000;
    double Kips = ((double)total_insns) / ((double)exec_msecs);
    fprintf(stderr, "Initialization:   %d msecs\n", init_msecs);
    fprintf(stderr, "Execution:        %d msecs\n", exec_msecs);
    fprintf(stderr, "Instructions:     %" PRIu64 "\n", total_insns);
    fprintf(stderr, "Perf:             %.3f Kips\n", Kips);
  }
  close_logs();
  exit(EXIT_SUCCESS);
}

void flush_logs(void) {
  if (config_print_instr) {
    fflush(stderr);
    fflush(trace_log);
  }
}

void run_sail(void) {
  bool is_waiting = false;
  bool exit_wait = true;

  /* initialize the step number */
  mach_int step_no = 0;
  uint64_t insn_cnt = 0;

  uint64_t insns_per_tick = get_config_uint64({"platform", "instructions_per_tick"});

  struct timeval interval_start;
  if (gettimeofday(&interval_start, nullptr) < 0) {
    fprintf(stderr, "Cannot gettimeofday: %s\n", strerror(errno));
    exit(EXIT_FAILURE);
  }

  while (!g_model.zhtif_done && (insn_limit == 0 || total_insns < insn_limit)) {
    if (rvfi) {
      switch (rvfi->pre_step(config_print_rvfi)) {
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

    g_model.call_pre_step_callbacks(is_waiting);

    { /* run a Sail step */
      sail_int sail_step;
      CREATE(sail_int)(&sail_step);
      CONVERT_OF(sail_int, mach_int)(&sail_step, step_no);
      is_waiting = g_model.ztry_step(sail_step, exit_wait);
      if (g_model.have_exception) {
        break;
      }
      flush_logs();
      KILL(sail_int)(&sail_step);
      if (rvfi) {
        rvfi->send_trace(config_print_rvfi);
      }
    }

    g_model.call_post_step_callbacks(is_waiting);

    if (!is_waiting) {
      if (config_print_step) {
        fprintf(trace_log, "\n");
      }
      step_no++;
      insn_cnt++;
      total_insns++;
    }

    if (do_show_times && (total_insns & 0xfffff) == 0) {
      uint64_t start_us = 1000000 * ((uint64_t)interval_start.tv_sec) + ((uint64_t)interval_start.tv_usec);
      if (gettimeofday(&interval_start, nullptr) < 0) {
        fprintf(stderr, "Cannot gettimeofday: %s\n", strerror(errno));
        exit(EXIT_FAILURE);
      }
      uint64_t end_us = 1000000 * ((uint64_t)interval_start.tv_sec) + ((uint64_t)interval_start.tv_usec);
      fprintf(stdout, "kips: %" PRIu64 "\n", ((uint64_t)1000) * 0x100000 / (end_us - start_us));
    }

    if (g_model.zhtif_done) {
      /* check exit code */
      if (g_model.zhtif_exit_code == 0) {
        fprintf(stdout, "SUCCESS\n");
      } else {
        fprintf(stdout, "FAILURE: %" PRIi64 "\n", g_model.zhtif_exit_code);
        exit(EXIT_FAILURE);
      }
    }

    if (insn_cnt == insns_per_tick) {
      insn_cnt = 0;
      g_model.ztick_clock(UNIT);
    }
  }

  // This is reached if there is a Sail exception, HTIF has indicated
  // successful completion, or the instruction limit has been reached.
  finish();
}

void init_logs() {
  if (!term_log.empty() &&
      (term_fd = open(term_log.c_str(), O_WRONLY | O_CREAT | O_TRUNC, S_IRUSR | S_IRGRP | S_IROTH | S_IWUSR)) < 0) {
    fprintf(stderr, "Cannot create terminal log '%s': %s\n", term_log.c_str(), strerror(errno));
    exit(EXIT_FAILURE);
  }

  if (!trace_log_path.empty()) {
    trace_log = fopen(trace_log_path.c_str(), "w+");
    if (trace_log == nullptr) {
      fprintf(stderr, "Cannot create trace log '%s': %s\n", trace_log_path.c_str(), strerror(errno));
      exit(EXIT_FAILURE);
    }
  }

#ifdef SAILCOV
  if (sailcov_file != nullptr) {
    sail_set_coverage_file(sailcov_file);
  }
#endif
}

int inner_main(int argc, char **argv) {
  CLI::App app("Sail RISC-V Model");
  argv = app.ensure_utf8(argv);
  setup_options(app);

  if (argc == 1) {
    fprintf(stdout, "%s\n", app.help().c_str());
    exit(EXIT_FAILURE);
  }

  // long_options_offset() is a local addition, so when updating CLI11,
  // see how https://github.com/CLIUtils/CLI11/pull/1185 ended up,
  // and possibly implement the upstream solution.
  app.get_formatter()->long_options_offset(6);
  app.get_formatter()->column_width(45);

  try {
    app.parse(argc, argv);
  } catch (const CLI::ParseError &e) {
    return app.exit(e);
  }

  if (do_print_version) {
    std::cout << version_info::release_version << std::endl;
    exit(EXIT_SUCCESS);
  }
  if (do_print_build_info) {
    print_build_info();
    exit(EXIT_SUCCESS);
  }
  if (do_print_default_config) {
    printf("%s", get_default_config());
    exit(EXIT_SUCCESS);
  }
  if (do_print_config_schema) {
    printf("%s", get_config_schema());
    exit(EXIT_SUCCESS);
  }
  if (rvfi_dii_port != 0) {
    config_enable_rvfi = true;
    rvfi.emplace(rvfi_dii_port, g_model);
  }
  if (do_show_times) {
    fprintf(stderr, "will show execution times on completion.\n");
  }
  if (!term_log.empty()) {
    fprintf(stderr, "using %s for terminal output.\n", term_log.c_str());
  }
  if (!sig_file.empty()) {
    fprintf(stderr, "using %s for test-signature output.\n", sig_file.c_str());
  }
  if (signature_granularity != DEFAULT_SIGNATURE_GRANULARITY) {
    fprintf(stderr, "setting signature-granularity to %d bytes\n", signature_granularity);
  }
  if (config_enable_experimental_extensions) {
    fprintf(stderr, "enabling unratified extensions.\n");
    g_model.set_enable_experimental_extensions(true);
  }
  if (!trace_log_path.empty()) {
    fprintf(stderr, "using %s for trace output.\n", trace_log_path.c_str());
  }

  // Always validate the schema conformance of the config.
  validate_config_schema(config_file);

  // Initialize the model.
  if (!config_file.empty()) {
    sail_config_set_file(config_file.c_str());
  } else {
    sail_config_set_string(get_default_config());
  }

  // Initialize platform.
  init_platform_constants();

  g_model.model_init();

  // Validate the configuration; exit if that's all we were asked to do
  // or if the validation failed.
  {
    bool config_is_valid = g_model.zconfig_is_valid(UNIT);
    const char *s = config_is_valid ? "valid" : "invalid";
    if (!config_is_valid || do_validate_config) {
      if (config_file.empty()) {
        fprintf(stderr, "Default configuration is %s.\n", s);
      } else {
        fprintf(stderr, "Configuration in %s is %s.\n", config_file.c_str(), s);
      }
      exit(config_is_valid ? EXIT_SUCCESS : EXIT_FAILURE);
    }
  }

  // Print a device tree or an ISA string only after the configuration
  // is validated above.
  if (do_print_dts) {
    print_dts();
    exit(EXIT_SUCCESS);
  }
  if (do_print_isa) {
    print_isa();
    exit(EXIT_SUCCESS);
  }

  // If we get here, we need to have ELF files to run.
  if (elfs.empty()) {
    fprintf(stderr, "No elf file provided.\n");
    exit(EXIT_FAILURE);
  }

  init_logs();
  log_callbacks log_cbs(config_print_reg, config_print_mem_access, config_print_ptw, config_use_abi_names, trace_log);
  g_model.register_callback(&log_cbs);

  if (gettimeofday(&init_start, nullptr) < 0) {
    fprintf(stderr, "Cannot gettimeofday: %s\n", strerror(errno));
    exit(EXIT_FAILURE);
  }

  if (rvfi) {
    if (!rvfi->setup_socket(config_print_rvfi)) {
      return 1;
    }
    g_model.register_callback(&rvfi_cbs);
  }

  if (!dtb_file.empty()) {
    fprintf(stderr, "using %s as DTB file.\n", dtb_file.c_str());
    write_dtb_to_rom(read_file(dtb_file));
  }

  const std::string &initial_elf_file = elfs[0];
  uint64_t entry = rvfi ? rvfi->get_entry() : load_sail(initial_elf_file, /*main_file=*/true);

  fprintf(stdout, "Entry point: 0x%" PRIx64 "\n", entry);

  /* Load any additional ELF files into memory */
  for (auto it = elfs.cbegin() + 1; it != elfs.cend(); it++) {
    fprintf(stdout, "Loading additional ELF file %s.\n", it->c_str());
    (void)load_sail(*it, /*main_file=*/false);
  }

  init_sail(entry, config_file.c_str());

  if (gettimeofday(&init_end, nullptr) < 0) {
    fprintf(stderr, "Cannot gettimeofday: %s\n", strerror(errno));
    exit(EXIT_FAILURE);
  }

  do {
    run_sail();
    // `run_sail` only returns in the case of rvfi.
    if (rvfi) {
      /* Reset for next test */
      reinit_sail(entry, config_file.c_str());
    }
  } while (rvfi);

  g_model.model_fini();
  flush_logs();
  close_logs();

  return 0;
}

int main(int argc, char **argv) {
  // Catch all exceptions and print them a bit more nicely than the default.
  try {
    return inner_main(argc, argv);
  } catch (const std::exception &exc) {
    std::cerr << "Error: " << exc.what() << std::endl;
  }
  return 1;
}
