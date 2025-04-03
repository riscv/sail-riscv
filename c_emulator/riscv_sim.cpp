#include <ctype.h>
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
#include <filesystem>
#include <fstream>
#include <iostream>
#include <sstream>
#include <vector>

#include "elf.h"
#include "sail.h"
#include "sail_config.h"
#include "rts.h"
#ifdef SAILCOV
#include "sail_coverage.h"
#endif
#include "riscv_platform.h"
#include "riscv_platform_impl.h"
#include "riscv_sail.h"
#include "rvfi_dii.h"
#include "default_config.h"

enum {
  OPT_TRACE_OUTPUT = 1000,
  OPT_PRINT_CONFIG,
  OPT_SAILCOV,
};

static bool do_show_times = false;
bool do_report_arch = false;
char *term_log = NULL;
static const char *trace_log_path = NULL;
FILE *trace_log = NULL;
char *dtb_file = NULL;
unsigned char *dtb = NULL;
size_t dtb_len = 0;
std::optional<rvfi_handler> rvfi;

char *sig_file = NULL;
uint64_t mem_sig_start = 0;
uint64_t mem_sig_end = 0;
int signature_granularity = 4;

bool config_print_instr = true;
bool config_print_reg = true;
bool config_print_mem_access = true;
bool config_print_platform = true;
bool config_print_rvfi = false;
bool config_print_step = false;

void set_config_print(char *var, bool val)
{
  if (var == NULL || strcmp("all", var) == 0) {
    config_print_instr = val;
    config_print_mem_access = val;
    config_print_reg = val;
    config_print_platform = val;
    config_print_rvfi = val;
  } else if (strcmp("instr", var) == 0) {
    config_print_instr = val;
  } else if (strcmp("reg", var) == 0) {
    config_print_reg = val;
  } else if (strcmp("mem", var) == 0) {
    config_print_mem_access = val;
  } else if (strcmp("rvfi", var) == 0) {
    config_print_rvfi = val;
  } else if (strcmp("platform", var) == 0) {
    config_print_platform = val;
  } else if (strcmp("step", var) == 0) {
    config_print_step = val;
  } else {
    fprintf(stderr, "Unknown trace category: '%s' (should be %s)\n", var,
            "instr|reg|mem|rvfi|platform|step|all");
    exit(1);
  }
}

struct timeval init_start, init_end, run_end;
uint64_t total_insns = 0;
uint64_t insn_limit = 0;
#ifdef SAILCOV
char *sailcov_file = NULL;
#endif

static struct option options[] = {
    {"device-tree-blob",      required_argument, 0, 'b'             },
    {"terminal-log",          required_argument, 0, 't'             },
    {"show-times",            required_argument, 0, 'p'             },
    {"report-arch",           no_argument,       0, 'a'             },
    {"test-signature",        required_argument, 0, 'T'             },
    {"signature-granularity", required_argument, 0, 'g'             },
#ifdef RVFI_DII
    {"rvfi-dii",              required_argument, 0, 'r'             },
#endif
    {"help",                  no_argument,       0, 1               },
    {"config",                required_argument, 0, 'c'             },
    {"print-default-config",  no_argument,       0, OPT_PRINT_CONFIG},
    {"trace",                 optional_argument, 0, 'v'             },
    {"no-trace",              optional_argument, 0, 'V'             },
    {"trace-output",          required_argument, 0, OPT_TRACE_OUTPUT},
    {"inst-limit",            required_argument, 0, 'l'             },
#ifdef SAILCOV
    {"sailcov-file",          required_argument, 0, OPT_SAILCOV     },
#endif
    {0,                       0,                 0, 0               }
};

static void print_usage(const char *argv0, int ec)
{
  fprintf(stdout, "Usage: %s [options] <elf_file> [<elf_file> ...]\n", argv0);
#ifdef RVFI_DII
  fprintf(stdout, "       %s [options] -r <port>\n", argv0);
#endif
  struct option *opt = options;
  while (opt->name) {
    if (isprint(opt->val))
      fprintf(stdout, "\t -%c\t --%s\n", (char)opt->val, opt->name);
    else
      fprintf(stdout, "\t   \t --%s\n", opt->name);
    opt++;
  }
  exit(ec);
}

static void report_arch(void)
{
  fprintf(stdout, "RV%" PRIu64 "\n", zxlen_val);
  exit(0);
}

static bool is_32bit_model(void)
{
  return zxlen_val == 32;
}

static void read_dtb(const char *path)
{
  int fd = open(path, O_RDONLY);
  if (fd < 0) {
    fprintf(stderr, "Unable to read DTB file %s: %s\n", path, strerror(errno));
    exit(1);
  }
  struct stat st;
  if (fstat(fd, &st) < 0) {
    fprintf(stderr, "Unable to stat DTB file %s: %s\n", path, strerror(errno));
    exit(1);
  }
  char *m = (char *)mmap(NULL, st.st_size, PROT_READ, MAP_PRIVATE, fd, 0);
  if (m == MAP_FAILED) {
    fprintf(stderr, "Unable to map DTB file %s: %s\n", path, strerror(errno));
    exit(1);
  }
  dtb = (unsigned char *)malloc(st.st_size);
  if (dtb == NULL) {
    fprintf(stderr, "Cannot allocate DTB from file %s!\n", path);
    exit(1);
  }
  memcpy(dtb, m, st.st_size);
  dtb_len = st.st_size;
  munmap(m, st.st_size);
  close(fd);

  fprintf(stdout, "Read %zd bytes of DTB from %s.\n", dtb_len, path);
}

/**
 * Parses the command line arguments and returns the argv index for the first
 * ELF file that should be loaded. As getopt transforms the argv array, all
 * argv values following that index are non-options and can be treated as
 * additional ELF files that should be loaded into memory (but not scanned
 * for the magic tohost/{begin,end}_signature symbols).
 */
static int process_args(int argc, char **argv)
{
  int c;
  bool have_config = false;
  while (true) {
    c = getopt_long(argc, argv,
                    "a"
                    "p"
                    "b:"
                    "t:"
                    "T:"
                    "g:"
                    "h"
                    "c:"
#ifdef RVFI_DII
                    "r:"
#endif
                    "V::"
                    "v::"
                    "l:",
                    options, NULL);
    if (c == -1)
      break;
    switch (c) {
    case 'a':
      do_report_arch = true;
      break;
    case 'p':
      fprintf(stderr, "will show execution times on completion.\n");
      do_show_times = true;
      break;
    case 'b':
      dtb_file = strdup(optarg);
      fprintf(stderr, "using %s as DTB file.\n", dtb_file);
      break;
    case 't':
      term_log = strdup(optarg);
      fprintf(stderr, "using %s for terminal output.\n", term_log);
      break;
    case 'T':
      sig_file = strdup(optarg);
      fprintf(stderr, "using %s for test-signature output.\n", sig_file);
      break;
    case 'g':
      signature_granularity = atoi(optarg);
      fprintf(stderr, "setting signature-granularity to %d bytes\n",
              signature_granularity);
      break;
    case 'h':
      print_usage(argv[0], 0);
      break;
    case 'c': {
      if (access(optarg, R_OK) == 0) {
        sail_config_set_file(optarg);
        have_config = true;
      } else {
        fprintf(stderr, "configuration file '%s' does not exist.\n", optarg);
        exit(1);
      }
      break;
    }
    case OPT_PRINT_CONFIG:
      printf("%s", DEFAULT_JSON);
      exit(0);
#ifdef RVFI_DII
    case 'r': {
      int rvfi_dii_port = atoi(optarg);
      rvfi = rvfi_handler(rvfi_dii_port);
      break;
    }
#endif
    case 'V':
      set_config_print(optarg, false);
      break;
    case 'v':
      set_config_print(optarg, true);
      break;
    case 'l': {
      char *p;
      unsigned long long val;
      errno = 0;
      val = strtoull(optarg, &p, 0);
      if (*p != '\0' || val > UINT64_MAX
          || (val == ULLONG_MAX && errno == ERANGE)) {
        fprintf(stderr, "invalid instruction limit %s\n", optarg);
        exit(1);
      }
      insn_limit = val;
      break;
    }
#ifdef SAILCOV
    case OPT_SAILCOV:
      sailcov_file = strdup(optarg);
      break;
#endif
    case OPT_TRACE_OUTPUT:
      trace_log_path = optarg;
      fprintf(stderr, "using %s for trace output.\n", trace_log_path);
      break;
    case '?':
      print_usage(argv[0], 1);
      break;
    }
  }

  if (!have_config) {
    std::filesystem::path path = std::filesystem::temp_directory_path();
    pid_t pid = getpid();
    std::ostringstream filename;
    filename << "default_config" << pid << ".json";
    path = path / filename.str();
    std::ofstream tmp(path);
    tmp << DEFAULT_JSON;
    tmp.close();

    sail_config_set_file(path.c_str());
    std::filesystem::remove(path);
  }

#ifdef RVFI_DII
  if (optind > argc || (optind == argc && !rvfi))
    print_usage(argv[0], 0);
#else
  if (optind >= argc) {
    fprintf(stderr, "No elf file provided.\n");
    print_usage(argv[0], 0);
  }
#endif
  if (dtb_file)
    read_dtb(dtb_file);

  if (!rvfi && !do_report_arch)
    fprintf(stdout, "Running file %s.\n", argv[optind]);
  return optind;
}

void check_elf(bool is32bit)
{
  if (is32bit) {
    if (zxlen_val != 32) {
      fprintf(stderr, "32-bit ELF not supported by RV%" PRIu64 " model.\n",
              zxlen_val);
      exit(1);
    }
  } else {
    if (zxlen_val != 64) {
      fprintf(stderr, "64-bit ELF not supported by RV%" PRIu64 " model.\n",
              zxlen_val);
      exit(1);
    }
  }
}
uint64_t load_sail(char *f, bool main_file)
{
  bool is32bit;
  uint64_t entry;
  uint64_t begin_sig, end_sig;
  load_elf(f, &is32bit, &entry);
  check_elf(is32bit);
  if (!main_file) {
    /* Don't scan for test-signature/htif symbols for additional ELF files. */
    return entry;
  }
  fprintf(stdout, "ELF Entry @ 0x%" PRIx64 "\n", entry);
  /* locate htif ports */
  if (lookup_sym(f, "tohost", &rv_htif_tohost) < 0) {
    fprintf(stderr, "Unable to locate htif tohost port.\n");
    exit(1);
  }
  fprintf(stderr, "tohost located at 0x%0" PRIx64 "\n", rv_htif_tohost);
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

uint64_t get_config_uint64(std::vector<const char *> keypath)
{
  sail_config_json json = sail_config_get(keypath.size(), keypath.data());

  if (!json) {
    std::cerr << "Failed to find configuration option '";
    for (auto part : keypath) {
      std::cerr << "." << part;
    }
    std::cerr << "'.\n";
    exit(1);
  }

  sail_int big_n;
  uint64_t n;

  if (!sail_config_is_int(json)) {
    std::cerr << "Configuration option '";
    for (auto part : keypath) {
      std::cerr << "." << part;
    }
    std::cerr << "' could not be parsed as an integer.\n";
    exit(1);
  }

  CREATE(sail_int)(&big_n);
  sail_config_unwrap_int(&big_n, json);
  n = sail_int_get_ui(big_n);
  KILL(sail_int)(&big_n);
  return n;
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
  zPC = rom_base;
}

void init_sail(uint64_t elf_entry)
{
  zinit_model(UNIT);
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
    zPC = elf_entry;
  } else
    init_sail_reset_vector(elf_entry);
}

/* reinitialize to clear state and memory, typically across tests runs */
void reinit_sail(uint64_t elf_entry)
{
  model_fini();
  model_init();
  init_sail(elf_entry);
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
  if (sig_file)
    write_signature(sig_file);

  model_fini();
  if (gettimeofday(&run_end, NULL) < 0) {
    fprintf(stderr, "Cannot gettimeofday: %s\n", strerror(errno));
    exit(1);
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
  bool stepped;
  bool diverged = false;

  /* initialize the step number */
  mach_int step_no = 0;
  uint64_t insn_cnt = 0;

  uint64_t insns_per_tick
      = get_config_uint64({"platform", "instructions_per_tick"});

  struct timeval interval_start;
  if (gettimeofday(&interval_start, NULL) < 0) {
    fprintf(stderr, "Cannot gettimeofday: %s\n", strerror(errno));
    exit(1);
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
      stepped = zstep(sail_step);
      if (have_exception)
        goto step_exception;
      flush_logs();
      KILL(sail_int)(&sail_step);
      if (rvfi) {
        rvfi->send_trace(config_print_rvfi);
      }
    }
    if (stepped) {
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
        exit(1);
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
        exit(1);
      }
    }

    if (insn_cnt == insns_per_tick) {
      insn_cnt = 0;
      ztick_clock(UNIT);
      ztick_platform(UNIT);
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
  if (term_log != NULL
      && (term_fd = open(term_log, O_WRONLY | O_CREAT | O_TRUNC,
                         S_IRUSR | S_IRGRP | S_IROTH | S_IWUSR))
          < 0) {
    fprintf(stderr, "Cannot create terminal log '%s': %s\n", term_log,
            strerror(errno));
    exit(1);
  }

  if (trace_log_path == NULL) {
    trace_log = stdout;
  } else if ((trace_log = fopen(trace_log_path, "w+")) == NULL) {
    fprintf(stderr, "Cannot create trace log '%s': %s\n", trace_log_path,
            strerror(errno));
    exit(1);
  }

#ifdef SAILCOV
  if (sailcov_file != NULL) {
    sail_set_coverage_file(sailcov_file);
  }
#endif
}

int main(int argc, char **argv)
{
  int files_start = process_args(argc, argv);

  model_init();

  if (do_report_arch) {
    report_arch();
  }

  char *initial_elf_file = argv[files_start];
  init_logs();

  if (gettimeofday(&init_start, NULL) < 0) {
    fprintf(stderr, "Cannot gettimeofday: %s\n", strerror(errno));
    exit(1);
  }

  if (rvfi) {
    if (!rvfi->setup_socket(config_print_rvfi))
      return 1;
  }

  uint64_t entry = rvfi ? rvfi->get_entry()
                        : load_sail(initial_elf_file, /*main_file=*/true);

  /* Load any additional ELF files into memory */
  for (int i = files_start + 1; i < argc; i++) {
    fprintf(stdout, "Loading additional ELF file %s.\n", argv[i]);
    (void)load_sail(argv[i], /*main_file=*/false);
  }

  init_sail(entry);

  if (gettimeofday(&init_end, NULL) < 0) {
    fprintf(stderr, "Cannot gettimeofday: %s\n", strerror(errno));
    exit(1);
  }

  do {
    run_sail();
    if (rvfi) {
      /* Reset for next test */
      reinit_sail(entry);
    }
  } while (rvfi);

  model_fini();
  flush_logs();
  close_logs();
}
