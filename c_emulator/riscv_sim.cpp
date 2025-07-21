#include <ctype.h>
#include <climits>
#include <getopt.h>
#include <stdio.h>
#include <stdlib.h>
#include <errno.h>
#include <unistd.h>
#include <sys/types.h>
#include <sys/stat.h>
#include <sys/mman.h>
#include <sys/time.h>
#include <fcntl.h>
#include <optional>
#include <iostream>
#include <vector>

#include "CLI11.hpp"
#include "elf.h"
#include "sail.h"
#include "sail_config.h"
#include "rts.h"
#ifdef SAILCOV
#include "sail_coverage.h"
#endif
#include "riscv_platform_impl.h"
#include "riscv_sail.h"
#include "rvfi_dii.h"
#include "default_config.h"
#include "config_utils.h"
#include "sail_riscv_version.h"

enum {
  OPT_TRACE_OUTPUT = 1000,
  OPT_PRINT_CONFIG,
  OPT_VALIDATE_CONFIG,
  OPT_SAILCOV,
  OPT_ENABLE_EXPERIMENTAL_EXTENSIONS,
  OPT_PRINT_VERSION,
  OPT_BUILD_INFO,
  OPT_PRINT_DTS,
  OPT_PRINT_ISA,
};

bool do_show_times = false;
bool do_print_version = false;
bool do_print_build_info = false;
bool do_print_default_config = false;
bool do_print_dts = false;
bool do_validate_config = false;
bool do_print_isa = false;

std::string config_file;
std::string term_log;
std::string trace_log_path;
FILE *trace_log = NULL;
std::string dtb_file;
unsigned char *dtb = NULL;
size_t dtb_len = 0;
int rvfi_dii_port = 0;
std::optional<rvfi_handler> rvfi;
std::vector<std::string> elfs;

std::string sig_file;
uint64_t mem_sig_start = 0;
uint64_t mem_sig_end = 0;
const int DEFAULT_SIGNATURE_GRANULARITY = 4;
int signature_granularity = DEFAULT_SIGNATURE_GRANULARITY;

bool config_print_instr = true;
bool config_print_reg = true;
bool config_print_mem_access = true;
bool config_print_platform = true;
bool config_print_rvfi = false;
bool config_print_step = false;

bool config_use_abi_names = false;
bool config_enable_rvfi = false;

std::map<std::string, std::tuple<bool *, std::string>> printers {
    {"instr",    {&config_print_instr, "Instruction execution"}     },
    {"reg",      {&config_print_reg, "Register accesses"}           },
    {"mem",      {&config_print_mem_access, "Memory accesses"}      },
    {"rvfi",     {&config_print_rvfi, "RVFI tracing"}               },
    {"platform",
     {&config_print_platform, "Privilege changes, MMIO, interrupts"}},
    {"step",     {&config_print_step, "Steps"}                      },
    {"all",      {NULL, "All of the other tracers"}                 },
};

std::function<void(const std::string &)> enable_printer {
    [](const std::string &opt) {
      auto ent = printers.find(opt);
      if (ent != printers.end()) {
        if (opt == "all") {
          config_print_instr = true;
          config_print_mem_access = true;
          config_print_reg = true;
          config_print_platform = true;
          config_print_rvfi = true;
        } else {
          *std::get<0>(ent->second) = true;
        }
      }
    }};

std::function<void(const std::string &)> disable_printer {
    [](const std::string &opt) {
      auto ent = printers.find(opt);
      if (ent != printers.end()) {
        if (opt == "all") {
          config_print_instr = false;
          config_print_mem_access = false;
          config_print_reg = false;
          config_print_platform = false;
          config_print_rvfi = false;
        } else {
          *std::get<0>(ent->second) = false;
        }
      }
    }};

struct timeval init_start, init_end, run_end;
uint64_t total_insns = 0;
uint64_t insn_limit = 0;
#ifdef SAILCOV
char *sailcov_file = NULL;
#endif

static void validate_config(const char *conf_file)
{
  const char *s = zconfig_is_valid(UNIT) ? "valid" : "invalid";
  if (conf_file) {
    fprintf(stdout, "Configuration in %s is %s.\n", conf_file, s);
  } else {
    fprintf(stdout, "Default configuration is %s.\n", s);
  }
  exit(EXIT_SUCCESS);
}

static void print_dts(void)
{
  char *dts = NULL;
  zgenerate_dts(&dts, UNIT);
  fprintf(stdout, "%s", dts);
  KILL(sail_string)(&dts);
  exit(EXIT_SUCCESS);
}

static void print_isa(void)
{
  char *isa = NULL;
  zgenerate_canonical_isa_string(&isa, UNIT);
  fprintf(stdout, "%s\n", isa);
  KILL(sail_string)(&isa);
  exit(EXIT_SUCCESS);
}

static void print_build_info(void)
{
  std::cout << "Sail RISC-V release: " << version_info::release_version
            << std::endl;
  std::cout << "Sail RISC-V git: " << version_info::git_version << std::endl;
  std::cout << "Sail: " << version_info::sail_version << std::endl;
  std::cout << "C++ compiler: " << version_info::cxx_compiler_version
            << std::endl;
  std::cout << "CLI11: " << CLI11_VERSION << std::endl;
}

static bool is_32bit_model(void)
{
  return zxlen == 32;
}

static void read_dtb(const char *path)
{
  int fd = open(path, O_RDONLY);
  if (fd < 0) {
    fprintf(stderr, "Unable to read DTB file %s: %s\n", path, strerror(errno));
    exit(EXIT_FAILURE);
  }
  struct stat st;
  if (fstat(fd, &st) < 0) {
    fprintf(stderr, "Unable to stat DTB file %s: %s\n", path, strerror(errno));
    exit(EXIT_FAILURE);
  }
  char *m = (char *)mmap(NULL, st.st_size, PROT_READ, MAP_PRIVATE, fd, 0);
  if (m == MAP_FAILED) {
    fprintf(stderr, "Unable to map DTB file %s: %s\n", path, strerror(errno));
    exit(EXIT_FAILURE);
  }
  dtb = (unsigned char *)malloc(st.st_size);
  if (dtb == NULL) {
    fprintf(stderr, "Cannot allocate DTB from file %s!\n", path);
    exit(EXIT_FAILURE);
  }
  memcpy(dtb, m, st.st_size);
  dtb_len = st.st_size;
  munmap(m, st.st_size);
  close(fd);

  fprintf(stdout, "Read %zd bytes of DTB from %s.\n", dtb_len, path);
}

/**
 * Set up command line option processing.
 */

class HelpFormatter : public CLI::Formatter {
public:
  // The default footer rendering uses paragraph formatting, removing
  // all spacing adjustments.  The only way to customize that is to
  // override the whole `make_help` formatter.  Customizing
  // `make_help` also allows us to remove the `make_positionals` call
  // instead of customizing it.
  std::string make_help(const CLI::App *app, std::string name,
                        CLI::AppFormatMode mode) const override
  {
    // See the comments in the base `make_help`.

    if (mode == CLI::AppFormatMode::Sub)
      return make_expanded(app, mode);

    std::stringstream out;
    if ((app->get_name().empty()) && (app->get_parent() != nullptr)) {
      if (app->get_group() != "SUBCOMMANDS") {
        out << app->get_group() << ':';
      }
    }

    CLI::detail::streamOutAsParagraph(out, make_description(app),
                                      description_paragraph_width_, "");
    out << make_usage(app, name);
    // Suppress the unnecessary "POSITIONALS" options help.
    // out << make_positionals(app);
    out << make_groups(app, mode);
    out << make_subcommands(app, mode);

    // Render the footer without any further formatting.
    out << make_footer(app);

    return out.str();
  }
};

static void setup_options(CLI::App &app)
{
  app.formatter(std::make_shared<HelpFormatter>());
  // The default formatter gives short options 1/3 of `column_width`
  // and long options 2/3, which is not great for our options.  Use a
  // smaller left column width than the default {30} to bring the
  // short and long options closer together.  This however pushes some
  // of the option descriptions into the next line, since the long
  // options now flow into the descriptions column.
  app.get_formatter()->column_width(20);

  app.add_flag("--show-times", do_show_times, "Show execution times");
  app.add_flag("--version", do_print_version, "Print model version");
  app.add_flag("--build-info", do_print_build_info, "Print build information");
  app.add_flag("--print-default-config", do_print_default_config,
               "Print default configuration");
  app.add_flag("--validate-config", do_validate_config,
               "Validate configuration");
  app.add_flag("--print-device-tree", do_print_dts, "Print device tree");
  app.add_flag("--print-isa-string", do_print_isa, "Print ISA string");
  app.add_flag("--enable-experimental-extensions",
               rv_enable_experimental_extensions,
               "Enable experimental extensions");
  app.add_flag("--use-abi-names", config_use_abi_names,
               "Use ABI register names in trace log");

  app.add_option("--device-tree-blob", dtb_file, "Device tree blob file")
      ->check(CLI::ExistingFile)
      ->option_text("<file>");
  app.add_option("--terminal-log", term_log, "Terminal log output file")
      ->option_text("<file>");
  app.add_option("--test-signature", sig_file, "Test signature file")
      ->option_text("<file>");
  app.add_option("--config", config_file, "Configuration file")
      ->check(CLI::ExistingFile)
      ->option_text("<file>");
  app.add_option("--trace-output", trace_log_path, "Trace output file")
      ->option_text("<file>");

  app.add_option("--signature-granularity", signature_granularity,
                 "Signature granularity")
      ->option_text("<uint>");
  app.add_option("--rvfi-dii", rvfi_dii_port, "RVFI DII port")
      ->check(CLI::Range(1, 65535))
      ->option_text("<int> (within [1 - 65535])");
  app.add_option("--inst-limit", insn_limit, "Instruction limit")
      ->option_text("<uint>");
#ifdef SAILCOV
  app.add_option("--sailcov-file", sailcov_file, "Sail coverage output file")
      ->option_text("<file>");
#endif

  app.add_option_function("--trace", enable_printer, "Enable tracing option")
      ->check(CLI::IsMember(printers))
      ->option_text("<tracer>");
  app.add_option_function("--no-trace", disable_printer,
                          "Disable tracing option")
      ->check(CLI::IsMember(printers))
      ->option_text("<tracer>");

  // All positional arguments are treated as ELF files.  All ELF files
  // are loaded into memory, but only the first is scanned for the
  // magic `tohost/{begin,end}_signature` symbols.
  app.add_option("elfs", elfs, "<elf_file> [<elf_file> ...]");

  // Add help for tracing options in the footer in the absence of a
  // better place to put it.  Unfortunately, the footer is rendered as
  // a paragraph, without a way of customizing it without overriding
  // the whole `make_help` function as above.
  std::ostringstream buf;
  buf << " where <tracer> is one of the following in the left column: "
      << std::endl;
  for (auto const &p : printers) {
    buf << "   " << p.first << " : " << std::get<1>(p.second) << std::endl;
  }
  app.footer(buf.str());
}

void check_elf(bool is32bit)
{
  if (is32bit) {
    if (zxlen != 32) {
      fprintf(stderr, "32-bit ELF not supported by RV%" PRIu64 " model.\n",
              zxlen);
      exit(EXIT_FAILURE);
    }
  } else {
    if (zxlen != 64) {
      fprintf(stderr, "64-bit ELF not supported by RV%" PRIu64 " model.\n",
              zxlen);
      exit(EXIT_FAILURE);
    }
  }
}
uint64_t load_sail(const char *f, bool main_file)
{
  bool is32bit;
  uint64_t entry;
  uint64_t begin_sig, end_sig;
  // Needs a change in Sail lib API to remove const_cast.
  load_elf(const_cast<char *>(f), &is32bit, &entry);
  check_elf(is32bit);
  if (!main_file) {
    /* Don't scan for test-signature/htif symbols for additional ELF files. */
    return entry;
  }
  fprintf(stdout, "ELF Entry @ 0x%" PRIx64 "\n", entry);
  /* locate htif ports */
  if (lookup_sym(f, "tohost", &rv_htif_tohost) < 0) {
    fprintf(stderr, "Unable to locate tohost symbol; disabling HTIF.\n");
    rv_enable_htif = false;
  } else {
    fprintf(stdout, "HTIF located at 0x%0" PRIx64 "\n", rv_htif_tohost);
  }
  /* locate test-signature locations if any */
  if (!lookup_sym(f, "begin_signature", &begin_sig)) {
    fprintf(stdout, "begin_signature: 0x%0" PRIx64 "\n", begin_sig);
    mem_sig_start = begin_sig;
  }
  if (!lookup_sym(f, "end_signature", &end_sig)) {
    fprintf(stdout, "end_signature: 0x%0" PRIx64 "\n", end_sig);
    mem_sig_end = end_sig;
  }
  return entry;
}

void init_sail_reset_vector(uint64_t entry)
{
#define RST_VEC_SIZE 8
  uint32_t reset_vec[RST_VEC_SIZE]
      = {0x297,                              // auipc  t0,0x0
         0x28593 + (RST_VEC_SIZE * 4 << 20), // addi   a1, t0, &dtb
         0xf1402573,                         // csrr   a0, mhartid
         is_32bit_model() ? 0x0182a283u :    // lw     t0,24(t0)
             0x0182b283u,                    // ld     t0,24(t0)
         0x28067,                            // jr     t0
         0,
         (uint32_t)(entry & 0xffffffff),
         (uint32_t)(entry >> 32)};

  uint64_t rom_base = get_config_uint64({"platform", "reset_vector"});
  uint64_t addr = rom_base;

  for (int i = 0; i < sizeof(reset_vec); i++)
    write_mem(addr++, (uint64_t)((char *)reset_vec)[i]);

  if (dtb && dtb_len) {
    for (size_t i = 0; i < dtb_len; i++)
      write_mem(addr++, dtb[i]);
  }

  /* zero-fill to page boundary */
  const int align = 0x1000;
  uint64_t rom_end = (addr + align - 1) / align * align;
  for (uint64_t i = addr; i < rom_end; i++)
    write_mem(addr++, 0);

  /* calculate rom size */
  uint64_t rom_size = rom_end - rom_base;

  /* check calculated rom values match configuration */
  if (rom_base != get_config_uint64({"platform", "rom", "base"})) {
    fprintf(stderr,
            "Configuration value platform.rom.base does not match %" PRIu64
            ".\n",
            rom_base);
  }
  if (rom_size != get_config_uint64({"platform", "rom", "size"})) {
    fprintf(stderr,
            "Configuration value platform.rom.size does not match %" PRIu64
            ".\n",
            rom_size);
  }

  /* boot at reset vector */
  zforce_pc(rom_base);
}

void init_sail(uint64_t elf_entry, const char *config_file)
{
  zinit_model(config_file != nullptr ? config_file : "");
  if (rvfi) {
    /*
    rv_ram_base = UINT64_C(0x80000000);
    rv_ram_size = UINT64_C(0x800000);
    rv_rom_base = UINT64_C(0);
    rv_rom_size = UINT64_C(0);
    rv_clint_base = UINT64_C(0);
    rv_clint_size = UINT64_C(0);
    rv_htif_tohost = UINT64_C(0);
    */
    zforce_pc(elf_entry);
  } else {
    init_sail_reset_vector(elf_entry);
  }
}

/* reinitialize to clear state and memory, typically across tests runs */
void reinit_sail(uint64_t elf_entry, const char *config_file)
{
  model_fini();
  sail_set_abstract_xlen();
  sail_set_abstract_ext_d_supported();
  model_init();
  init_sail(elf_entry, config_file);
}

void write_signature(const char *file)
{
  if (mem_sig_start >= mem_sig_end) {
    fprintf(stderr,
            "Invalid signature region [0x%0" PRIx64 ",0x%0" PRIx64 "] to %s.\n",
            mem_sig_start, mem_sig_end, file);
    return;
  }
  FILE *f = fopen(file, "w");
  if (!f) {
    fprintf(stderr, "Cannot open file '%s': %s\n", file, strerror(errno));
    return;
  }
  /* write out words depending on signature granularity in signature area */
  for (uint64_t addr = mem_sig_start; addr < mem_sig_end;
       addr += signature_granularity) {
    /* most-significant byte first */
    for (int i = signature_granularity - 1; i >= 0; i--) {
      uint8_t byte = (uint8_t)read_mem(addr + i);
      fprintf(f, "%02x", byte);
    }
    fprintf(f, "\n");
  }
  fclose(f);
}

void close_logs(void)
{
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

void finish(int ec)
{
  if (!sig_file.empty())
    write_signature(sig_file.c_str());

  model_fini();
  if (gettimeofday(&run_end, NULL) < 0) {
    fprintf(stderr, "Cannot gettimeofday: %s\n", strerror(errno));
    exit(EXIT_FAILURE);
  }
  if (do_show_times) {
    int init_msecs = (init_end.tv_sec - init_start.tv_sec) * 1000
        + (init_end.tv_usec - init_start.tv_usec) / 1000;
    int exec_msecs = (run_end.tv_sec - init_end.tv_sec) * 1000
        + (run_end.tv_usec - init_end.tv_usec) / 1000;
    double Kips = ((double)total_insns) / ((double)exec_msecs);
    fprintf(stderr, "Initialization:   %d msecs\n", init_msecs);
    fprintf(stderr, "Execution:        %d msecs\n", exec_msecs);
    fprintf(stderr, "Instructions:     %" PRIu64 "\n", total_insns);
    fprintf(stderr, "Perf:             %.3f Kips\n", Kips);
  }
  close_logs();
  exit(ec);
}

void flush_logs(void)
{
  if (config_print_instr) {
    fflush(stderr);
    fflush(trace_log);
  }
}

void run_sail(void)
{
  bool is_waiting;
  bool exit_wait = true;
  bool diverged = false;

  /* initialize the step number */
  mach_int step_no = 0;
  uint64_t insn_cnt = 0;

  uint64_t insns_per_tick
      = get_config_uint64({"platform", "instructions_per_tick"});

  struct timeval interval_start;
  if (gettimeofday(&interval_start, NULL) < 0) {
    fprintf(stderr, "Cannot gettimeofday: %s\n", strerror(errno));
    exit(EXIT_FAILURE);
  }

  while (!zhtif_done && (insn_limit == 0 || total_insns < insn_limit)) {
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
    { /* run a Sail step */
      sail_int sail_step;
      CREATE(sail_int)(&sail_step);
      CONVERT_OF(sail_int, mach_int)(&sail_step, step_no);
      is_waiting = ztry_step(sail_step, exit_wait);
      if (have_exception)
        goto step_exception;
      flush_logs();
      KILL(sail_int)(&sail_step);
      if (rvfi) {
        rvfi->send_trace(config_print_rvfi);
      }
    }
    if (!is_waiting) {
      if (config_print_step) {
        fprintf(trace_log, "\n");
      }
      step_no++;
      insn_cnt++;
      total_insns++;
    }

    if (do_show_times && (total_insns & 0xfffff) == 0) {
      uint64_t start_us = 1000000 * ((uint64_t)interval_start.tv_sec)
          + ((uint64_t)interval_start.tv_usec);
      if (gettimeofday(&interval_start, NULL) < 0) {
        fprintf(stderr, "Cannot gettimeofday: %s\n", strerror(errno));
        exit(EXIT_FAILURE);
      }
      uint64_t end_us = 1000000 * ((uint64_t)interval_start.tv_sec)
          + ((uint64_t)interval_start.tv_usec);
      fprintf(stdout, "kips: %" PRIu64 "\n",
              ((uint64_t)1000) * 0x100000 / (end_us - start_us));
    }

    if (zhtif_done) {
      /* check exit code */
      if (zhtif_exit_code == 0) {
        fprintf(stdout, "SUCCESS\n");
      } else {
        fprintf(stdout, "FAILURE: %" PRIi64 "\n", zhtif_exit_code);
        exit(EXIT_FAILURE);
      }
    }

    if (insn_cnt == insns_per_tick) {
      insn_cnt = 0;
      ztick_clock(UNIT);
    }
  }

dump_state:
  if (diverged) {
    /* TODO */
  }
  finish(diverged);

step_exception:
  fprintf(stderr, "Sail exception!");
  goto dump_state;
}

void init_logs()
{
  if (!term_log.empty()
      && (term_fd = open(term_log.c_str(), O_WRONLY | O_CREAT | O_TRUNC,
                         S_IRUSR | S_IRGRP | S_IROTH | S_IWUSR))
          < 0) {
    fprintf(stderr, "Cannot create terminal log '%s': %s\n", term_log.c_str(),
            strerror(errno));
    exit(EXIT_FAILURE);
  }

  if (trace_log_path.empty()) {
    trace_log = stdout;
  } else if ((trace_log = fopen(trace_log_path.c_str(), "w+")) == NULL) {
    fprintf(stderr, "Cannot create trace log '%s': %s\n",
            trace_log_path.c_str(), strerror(errno));
    exit(EXIT_FAILURE);
  }

#ifdef SAILCOV
  if (sailcov_file != NULL) {
    sail_set_coverage_file(sailcov_file);
  }
#endif
}

int main(int argc, char **argv)
{
  CLI::App app("Sail RISC-V Model");
  argv = app.ensure_utf8(argv);
  setup_options(app);
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
    printf("%s", DEFAULT_JSON);
    exit(EXIT_SUCCESS);
  }
  if (rvfi_dii_port != 0) {
    config_enable_rvfi = true;
    rvfi = rvfi_handler(rvfi_dii_port);
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
    fprintf(stderr, "setting signature-granularity to %d bytes\n",
            signature_granularity);
  }
  if (rv_enable_experimental_extensions) {
    fprintf(stderr, "enabling unratified extensions.\n");
  }
  if (!trace_log_path.empty()) {
    fprintf(stderr, "using %s for trace output.\n", trace_log_path.c_str());
  }
  if (!dtb_file.empty()) {
    fprintf(stderr, "using %s as DTB file.\n", dtb_file.c_str());
    read_dtb(dtb_file.c_str());
  }

  // Initialize the model.
  if (!config_file.empty()) {
    sail_config_set_file(config_file.c_str());
  } else {
    sail_config_set_string(DEFAULT_JSON);
  }
  sail_set_abstract_xlen();
  sail_set_abstract_ext_d_supported();
  model_init();

  if (do_validate_config) {
    validate_config(config_file.c_str());
  }
  if (do_print_dts) {
    print_dts();
  }
  if (do_print_isa) {
    print_isa();
  }

  // If we get here, we need to have ELF files to run.
  if (elfs.empty()) {
    fprintf(stderr, "No elf file provided.\n");
    exit(EXIT_FAILURE);
  }

  init_logs();

  if (gettimeofday(&init_start, NULL) < 0) {
    fprintf(stderr, "Cannot gettimeofday: %s\n", strerror(errno));
    exit(EXIT_FAILURE);
  }

  if (rvfi) {
    if (!rvfi->setup_socket(config_print_rvfi))
      return 1;
  }

  const std::string &initial_elf_file = elfs[0];
  uint64_t entry = rvfi
      ? rvfi->get_entry()
      : load_sail(initial_elf_file.c_str(), /*main_file=*/true);

  /* Load any additional ELF files into memory */
  std::vector<std::string>::const_iterator it = elfs.begin();
  std::advance(it, 1);
  for (; it != elfs.end(); it++) {
    fprintf(stdout, "Loading additional ELF file %s.\n", it->c_str());
    (void)load_sail(it->c_str(), /*main_file=*/false);
  }

  init_sail(entry, config_file.c_str());

  if (gettimeofday(&init_end, NULL) < 0) {
    fprintf(stderr, "Cannot gettimeofday: %s\n", strerror(errno));
    exit(EXIT_FAILURE);
  }

  do {
    run_sail();
    if (rvfi) {
      /* Reset for next test */
      reinit_sail(entry, config_file.c_str());
    }
  } while (rvfi);

  model_fini();
  flush_logs();
  close_logs();
}
