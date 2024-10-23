#include <ctype.h>
#include <getopt.h>
#include <stdio.h>
#include <stdlib.h>
#include <errno.h>
#include <unistd.h>
#include <arpa/inet.h>
#include <sys/types.h>
#include <sys/stat.h>
#include <sys/mman.h>
#include <sys/time.h>
#include <sys/socket.h>
#include <netinet/ip.h>
#include <fcntl.h>

#include "elf.h"
#include "sail.h"
#include "rts.h"
#ifdef SAILCOV
#include "sail_coverage.h"
#endif
#include "riscv_platform.h"
#include "riscv_platform_impl.h"
#include "riscv_sail.h"

#ifdef ENABLE_SPIKE
#include "tv_spike_intf.h"
#else
struct tv_spike_t;
#endif

const char *RV64ISA = "RV64IMAC";
const char *RV32ISA = "RV32IMAC";

/* Selected CSRs from riscv-isa-sim/riscv/encoding.h */
#define CSR_STVEC 0x105
#define CSR_SEPC 0x141
#define CSR_SCAUSE 0x142
#define CSR_STVAL 0x143

#define CSR_MSTATUS 0x300
#define CSR_MISA 0x301
#define CSR_MEDELEG 0x302
#define CSR_MIDELEG 0x303
#define CSR_MIE 0x304
#define CSR_MTVEC 0x305
#define CSR_MEPC 0x341
#define CSR_MCAUSE 0x342
#define CSR_MTVAL 0x343
#define CSR_MIP 0x344

enum {
  OPT_TRACE_OUTPUT = 1000,
  OPT_ENABLE_WRITABLE_FIOM,
  OPT_PMP_COUNT,
  OPT_PMP_GRAIN,
  OPT_ENABLE_SVINVAL,
  OPT_ENABLE_ZCB,
  OPT_ENABLE_ZICBOM,
  OPT_ENABLE_ZICBOZ,
  OPT_CACHE_BLOCK_SIZE,
};

static bool do_dump_dts = false;
static bool do_show_times = false;
struct tv_spike_t *s = NULL;
char *term_log = NULL;
static const char *trace_log_path = NULL;
FILE *trace_log = NULL;
char *dtb_file = NULL;
unsigned char *dtb = NULL;
size_t dtb_len = 0;
#ifdef RVFI_DII
static bool rvfi_dii = false;
/* Needs to be global to avoid the needed for a set-version packet on each trace
 */
static unsigned rvfi_trace_version = 1;
static int rvfi_dii_port;
static int rvfi_dii_sock;
#endif

unsigned char *spike_dtb = NULL;
size_t spike_dtb_len = 0;

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
bool rv_enable_callbacks = true;

void set_config_print(char *var, bool val)
{
  if (var == NULL || strcmp("all", var) == 0) {
    config_print_instr = val;
    config_print_mem_access = val;
    config_print_reg = val;
    config_print_platform = val;
    config_print_rvfi = val;
    rv_enable_callbacks = val;
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
int total_insns = 0;
int insn_limit = 0;
#ifdef SAILCOV
char *sailcov_file = NULL;
#endif

static struct option options[] = {
    {"enable-dirty-update",         no_argument,       0, 'd'                     },
    {"enable-misaligned",           no_argument,       0, 'm'                     },
    {"pmp-count",                   required_argument, 0, OPT_PMP_COUNT           },
    {"pmp-grain",                   required_argument, 0, OPT_PMP_GRAIN           },
    {"enable-next",                 no_argument,       0, 'N'                     },
    {"ram-size",                    required_argument, 0, 'z'                     },
    {"disable-compressed",          no_argument,       0, 'C'                     },
    {"disable-writable-misa",       no_argument,       0, 'I'                     },
    {"disable-fdext",               no_argument,       0, 'F'                     },
    {"mtval-has-illegal-inst-bits", no_argument,       0, 'i'                     },
    {"device-tree-blob",            required_argument, 0, 'b'                     },
    {"terminal-log",                required_argument, 0, 't'                     },
    {"show-times",                  required_argument, 0, 'p'                     },
    {"report-arch",                 no_argument,       0, 'a'                     },
    {"test-signature",              required_argument, 0, 'T'                     },
    {"signature-granularity",       required_argument, 0, 'g'                     },
#ifdef RVFI_DII
    {"rvfi-dii",                    required_argument, 0, 'r'                     },
#endif
    {"help",                        no_argument,       0, 'h'                     },
    {"trace",                       optional_argument, 0, 'v'                     },
    {"no-trace",                    optional_argument, 0, 'V'                     },
    {"trace-output",                required_argument, 0, OPT_TRACE_OUTPUT        },
    {"inst-limit",                  required_argument, 0, 'l'                     },
    {"enable-zfinx",                no_argument,       0, 'x'                     },
    {"enable-writable-fiom",        no_argument,       0, OPT_ENABLE_WRITABLE_FIOM},
    {"enable-svinval",              no_argument,       0, OPT_ENABLE_SVINVAL      },
    {"enable-zcb",                  no_argument,       0, OPT_ENABLE_ZCB          },
    {"enable-zicbom",               no_argument,       0, OPT_ENABLE_ZICBOM       },
    {"enable-zicboz",               no_argument,       0, OPT_ENABLE_ZICBOZ       },
    {"cache-block-size",            required_argument, 0, OPT_CACHE_BLOCK_SIZE    },
#ifdef SAILCOV
    {"sailcov-file",                required_argument, 0, 'c'                     },
#endif
    {0,                             0,                 0, 0                       }
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

static void dump_dts(void)
{
#ifdef ENABLE_SPIKE
  size_t dts_len = 0;
  const char *isa = is_32bit_model() ? RV32ISA : RV64ISA;
  struct tv_spike_t *s = tv_init(isa, rv_ram_size, 0);
  tv_get_dts(s, NULL, &dts_len);
  if (dts_len > 0) {
    unsigned char *dts = (unsigned char *)malloc(dts_len + 1);
    dts[dts_len] = '\0';
    tv_get_dts(s, dts, &dts_len);
    fprintf(stdout, "%s\n", dts);
  }
#else
  fprintf(stdout, "Spike linkage is currently needed to generate DTS.\n");
#endif
  exit(0);
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

// Return log2(x), or -1 if x is not a power of 2.
static int ilog2(uint64_t x)
{
  for (unsigned i = 0; i < sizeof(x) * 8; ++i) {
    if (x == (UINT64_C(1) << i)) {
      return i;
    }
  }
  return -1;
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
  uint64_t ram_size = 0;
  uint64_t pmp_count = 0;
  uint64_t pmp_grain = 0;
  uint64_t block_size_exp = 0;
  while (true) {
    c = getopt_long(argc, argv,
                    "a"
                    "B"
                    "d"
                    "m"
                    "P"
                    "C"
                    "N"
                    "I"
                    "F"
                    "W"
                    "i"
                    "s"
                    "p"
                    "z:"
                    "b:"
                    "t:"
                    "T:"
                    "g:"
                    "h"
#ifdef RVFI_DII
                    "r:"
#endif
#ifdef SAILCOV
                    "c:"
#endif
                    "V::"
                    "v::"
                    "l:"
                    "x",
                    options, NULL);
    if (c == -1)
      break;
    switch (c) {
    case 'a':
      report_arch();
      break;
    case 'B':
      fprintf(stderr, "enabling B extension.\n");
      rv_enable_bext = true;
      break;
    case 'd':
      fprintf(stderr, "enabling dirty update.\n");
      rv_enable_dirty_update = true;
      break;
    case 'm':
      fprintf(stderr, "enabling misaligned access.\n");
      rv_enable_misaligned = true;
      break;
    case OPT_PMP_COUNT:
      pmp_count = atol(optarg);
      fprintf(stderr, "PMP count: %" PRIu64 "\n", pmp_count);
      if (pmp_count != 0 && pmp_count != 16 && pmp_count != 64) {
        fprintf(stderr, "invalid PMP count: must be 0, 16 or 64");
        exit(1);
      }
      rv_pmp_count = pmp_count;
      break;
    case OPT_PMP_GRAIN:
      pmp_grain = atol(optarg);
      fprintf(stderr, "PMP grain: %" PRIu64 "\n", pmp_grain);
      if (pmp_grain >= 64) {
        fprintf(stderr, "invalid PMP grain: must less than 64");
        exit(1);
      }
      rv_pmp_grain = pmp_grain;
      break;
    case 'C':
      fprintf(stderr, "disabling RVC compressed instructions.\n");
      rv_enable_rvc = false;
      break;
    case 'N':
      fprintf(stderr, "enabling N extension.\n");
      rv_enable_next = true;
      break;
    case 'I':
      fprintf(stderr, "disabling writable misa CSR.\n");
      rv_enable_writable_misa = false;
      break;
    case 'F':
      fprintf(stderr, "disabling floating point (F and D extensions).\n");
      rv_enable_fdext = false;
      break;
    case 'W':
      fprintf(stderr, "disabling RVV vector instructions.\n");
      rv_enable_vext = false;
      break;
    case 'i':
      fprintf(stderr, "enabling storing illegal instruction bits in mtval.\n");
      rv_mtval_has_illegal_inst_bits = true;
      break;
    case OPT_ENABLE_WRITABLE_FIOM:
      fprintf(stderr,
              "enabling FIOM (Fence of I/O implies Memory) bit in menvcfg.\n");
      rv_enable_writable_fiom = true;
      break;
    case 's':
      do_dump_dts = true;
      break;
    case 'p':
      fprintf(stderr, "will show execution times on completion.\n");
      do_show_times = true;
      break;
    case 'z':
      ram_size = atol(optarg);
      if (ram_size) {
        fprintf(stderr, "setting ram-size to %" PRIu64 " MB\n", ram_size);
        rv_ram_size = ram_size << 20;
      } else {
        fprintf(stderr, "invalid ram-size '%s' provided.\n", optarg);
        exit(1);
      }
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
#ifdef RVFI_DII
    case 'r':
      rvfi_dii = true;
      rvfi_dii_port = atoi(optarg);
      fprintf(stderr, "using %d as RVFI port.\n", rvfi_dii_port);
      break;
#endif
    case 'V':
      set_config_print(optarg, false);
      break;
    case 'v':
      set_config_print(optarg, true);
      break;
    case 'l':
      insn_limit = atoi(optarg);
      break;
    case OPT_ENABLE_SVINVAL:
      fprintf(stderr, "enabling svinval extension.\n");
      rv_enable_svinval = true;
      break;
    case OPT_ENABLE_ZCB:
      fprintf(stderr, "enabling Zcb extension.\n");
      rv_enable_zcb = true;
      break;
    case OPT_ENABLE_ZICBOM:
      fprintf(stderr, "enabling Zicbom extension.\n");
      rv_enable_zicbom = true;
      break;
    case OPT_ENABLE_ZICBOZ:
      fprintf(stderr, "enabling Zicboz extension.\n");
      rv_enable_zicboz = true;
      break;
    case OPT_CACHE_BLOCK_SIZE:
      block_size_exp = ilog2(atol(optarg));

      if (block_size_exp < 0 || block_size_exp > 12) {
        fprintf(stderr, "invalid cache-block-size '%s' provided.\n", optarg);
        exit(1);
      }

      fprintf(stderr, "setting cache-block-size to 2^%" PRIu64 " = %u B\n",
              block_size_exp, 1 << block_size_exp);
      rv_cache_block_size_exp = block_size_exp;
      break;
    case 'x':
      fprintf(stderr, "enabling Zfinx support.\n");
      rv_enable_zfinx = true;
      rv_enable_fdext = false;
      break;
#ifdef SAILCOV
    case 'c':
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
  if (do_dump_dts)
    dump_dts();
#ifdef RVFI_DII
  if (optind > argc || (optind == argc && !rvfi_dii))
    print_usage(argv[0], 0);
#else
  if (optind >= argc) {
    fprintf(stderr, "No elf file provided.\n");
    print_usage(argv[0], 0);
  }
#endif
  if (dtb_file)
    read_dtb(dtb_file);

#ifdef RVFI_DII
  if (!rvfi_dii)
#endif
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

void init_spike(const char *f, uint64_t entry, uint64_t ram_size)
{
#ifdef ENABLE_SPIKE
  bool mismatch = false;
  const char *isa = is_32bit_model() ? RV32ISA : RV64ISA;
  s = tv_init(isa, ram_size, 1);
  if (tv_is_dirty_enabled(s) != rv_enable_dirty_update) {
    mismatch = true;
    fprintf(stderr,
            "inconsistent enable-dirty-update setting: spike %s, sail %s\n",
            tv_is_dirty_enabled(s) ? "on" : "off",
            rv_enable_dirty_update ? "on" : "off");
  }
  if (tv_is_misaligned_enabled(s) != rv_enable_misaligned) {
    mismatch = true;
    fprintf(stderr,
            "inconsistent enable-misaligned-access setting: "
            "spike %s, sail %s\n",
            tv_is_misaligned_enabled(s) ? "on" : "off",
            rv_enable_misaligned ? "on" : "off");
  }
  if (tv_ram_size(s) != rv_ram_size) {
    mismatch = true;
    fprintf(stderr,
            "inconsistent ram-size setting: spike 0x%" PRIx64
            ", sail 0x%" PRIx64 "\n",
            tv_ram_size(s), rv_ram_size);
  }
  if (mismatch)
    exit(1);

  /* The initialization order below matters. */
  tv_set_verbose(s, 1);
  tv_set_dtb_in_rom(s, 1);
  tv_load_elf(s, f);
  tv_reset(s);

  /* sync the insns per tick */
  rv_insns_per_tick = tv_get_insns_per_tick(s);

  /* get DTB from spike */
  tv_get_dtb(s, NULL, &spike_dtb_len);
  if (spike_dtb_len > 0) {
    spike_dtb = (unsigned char *)malloc(spike_dtb_len + 1);
    spike_dtb[spike_dtb_len] = '\0';
    if (!tv_get_dtb(s, spike_dtb, &spike_dtb_len)) {
      fprintf(stderr, "Got %" PRIu64 " bytes of dtb at %p\n", spike_dtb_len,
              spike_dtb);
    } else {
      fprintf(stderr, "Error getting DTB from Spike.\n");
      exit(1);
    }
  } else {
    fprintf(stderr, "No DTB available from Spike.\n");
  }
#else
  s = NULL;
#endif
}

void tick_spike()
{
#ifdef ENABLE_SPIKE
  tv_tick_clock(s);
  tv_step_io(s);
#endif
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

  rv_rom_base = DEFAULT_RSTVEC;
  uint64_t addr = rv_rom_base;
  for (int i = 0; i < sizeof(reset_vec); i++)
    write_mem(addr++, (uint64_t)((char *)reset_vec)[i]);

  if (dtb && dtb_len) {
    for (size_t i = 0; i < dtb_len; i++)
      write_mem(addr++, dtb[i]);
  }

#ifdef ENABLE_SPIKE
  if (dtb && dtb_len) {
    // Ensure that Spike's DTB matches the one provided.
    bool matched = dtb_len == spike_dtb_len;
    if (matched) {
      for (size_t i = 0; i < dtb_len; i++)
        matched = matched && (dtb[i] == spike_dtb[i]);
    }
    if (!matched) {
      fprintf(stderr, "Provided DTB does not match Spike's!\n");
      exit(1);
    }
  } else {
    if (spike_dtb_len > 0) {
      // Use the DTB from Spike.
      for (size_t i = 0; i < spike_dtb_len; i++)
        write_mem(addr++, spike_dtb[i]);
    } else {
      fprintf(stderr, "Running without rom device tree.\n");
    }
  }
#endif

  /* zero-fill to page boundary */
  const int align = 0x1000;
  uint64_t rom_end = (addr + align - 1) / align * align;
  for (int i = addr; i < rom_end; i++)
    write_mem(addr++, 0);

  /* set rom size */
  rv_rom_size = rom_end - rv_rom_base;
  /* boot at reset vector */
  zPC = rv_rom_base;
}

void preinit_sail()
{
  model_init();
}

void init_sail(uint64_t elf_entry)
{
  zinit_model(UNIT);
#ifdef RVFI_DII
  if (rvfi_dii) {
    zext_rvfi_init(UNIT);
    rv_ram_base = UINT64_C(0x80000000);
    rv_ram_size = UINT64_C(0x800000);
    rv_rom_base = UINT64_C(0);
    rv_rom_size = UINT64_C(0);
    rv_clint_base = UINT64_C(0);
    rv_clint_size = UINT64_C(0);
    rv_htif_tohost = UINT64_C(0);
    zPC = elf_entry;
  } else
#endif
    init_sail_reset_vector(elf_entry);

  // this is probably unnecessary now; remove
  if (!rv_enable_rvc)
    z_set_Misa_C(&zmisa, 0);
}

/* reinitialize to clear state and memory, typically across tests runs */
void reinit_sail(uint64_t elf_entry)
{
  model_fini();
  model_init();
  init_sail(elf_entry);
}

int init_check(struct tv_spike_t *s)
{
  int passed = 1;
#ifdef ENABLE_SPIKE
  passed &= tv_check_csr(s, CSR_MISA, zmisa.zMisa_chunk_0);
#endif
  return passed;
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
#ifdef ENABLE_SPIKE
  tv_free(s);
#endif
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
    fprintf(stderr, "Instructions:     %d\n", total_insns);
    fprintf(stderr, "Perf:             %.3f Kips\n", Kips);
  }
  close_logs();
  exit(ec);
}

int compare_states(struct tv_spike_t *s)
{
  int passed = 1;

#ifdef ENABLE_SPIKE
#define TV_CHECK(reg, spike_reg, sail_reg)                                     \
  passed &= tv_check_##reg(s, spike_reg, sail_reg);

  // fix default C enum map for cur_privilege
  uint8_t priv = (zcur_privilege == 2) ? 3 : zcur_privilege;
  passed &= tv_check_priv(s, priv);

  passed &= tv_check_pc(s, zPC);

  TV_CHECK(gpr, 1, zx1);
  TV_CHECK(gpr, 2, zx2);
  TV_CHECK(gpr, 3, zx3);
  TV_CHECK(gpr, 4, zx4);
  TV_CHECK(gpr, 5, zx5);
  TV_CHECK(gpr, 6, zx6);
  TV_CHECK(gpr, 7, zx7);
  TV_CHECK(gpr, 8, zx8);
  TV_CHECK(gpr, 9, zx9);
  TV_CHECK(gpr, 10, zx10);
  TV_CHECK(gpr, 11, zx11);
  TV_CHECK(gpr, 12, zx12);
  TV_CHECK(gpr, 13, zx13);
  TV_CHECK(gpr, 14, zx14);
  TV_CHECK(gpr, 15, zx15);
  TV_CHECK(gpr, 15, zx15);
  TV_CHECK(gpr, 16, zx16);
  TV_CHECK(gpr, 17, zx17);
  TV_CHECK(gpr, 18, zx18);
  TV_CHECK(gpr, 19, zx19);
  TV_CHECK(gpr, 20, zx20);
  TV_CHECK(gpr, 21, zx21);
  TV_CHECK(gpr, 22, zx22);
  TV_CHECK(gpr, 23, zx23);
  TV_CHECK(gpr, 24, zx24);
  TV_CHECK(gpr, 25, zx25);
  TV_CHECK(gpr, 25, zx25);
  TV_CHECK(gpr, 26, zx26);
  TV_CHECK(gpr, 27, zx27);
  TV_CHECK(gpr, 28, zx28);
  TV_CHECK(gpr, 29, zx29);
  TV_CHECK(gpr, 30, zx30);
  TV_CHECK(gpr, 31, zx31);

  /* some selected CSRs for now */

  TV_CHECK(csr, CSR_MCAUSE, zmcause.zMcause_chunk_0);
  TV_CHECK(csr, CSR_MEPC, zmepc);
  TV_CHECK(csr, CSR_MTVAL, zmtval);
  TV_CHECK(csr, CSR_MSTATUS, zmstatus);

  TV_CHECK(csr, CSR_SCAUSE, zscause.zMcause_chunk_0);
  TV_CHECK(csr, CSR_SEPC, zsepc);
  TV_CHECK(csr, CSR_STVAL, zstval);

#undef TV_CHECK
#endif

  return passed;
}

void flush_logs(void)
{
  if (config_print_instr) {
    fflush(stderr);
    fflush(trace_log);
  }
}

#ifdef RVFI_DII

typedef void (*packet_reader_fn)(lbits *rop, unit);
static void get_and_send_rvfi_packet(packet_reader_fn reader)
{
  lbits packet;
  CREATE(lbits)(&packet);
  reader(&packet, UNIT);
  /* Note: packet.len is the size in bits, not bytes. */
  if (packet.len % 8 != 0) {
    fprintf(stderr, "RVFI-DII trace packet not byte aligned: %d\n",
            (int)packet.len);
    exit(1);
  }
  const size_t send_size = packet.len / 8;
  if (config_print_rvfi) {
    print_bits("packet = ", packet);
    fprintf(stderr, "Sending packet with length %zd... ", send_size);
  }
  if (send_size > 4096) {
    fprintf(stderr, "Unexpected large packet size (> 4KB): %zd\n", send_size);
    exit(1);
  }
  unsigned char bytes[send_size];
  /* mpz_export might not write all of the null bytes */
  memset(bytes, 0, sizeof(bytes));
  mpz_export(bytes, NULL, -1, 1, 0, 0, *(packet.bits));
  /* Ensure that we can send a full packet */
  if (write(rvfi_dii_sock, bytes, send_size) != send_size) {
    fprintf(stderr, "Writing RVFI DII trace failed: %s\n", strerror(errno));
    exit(1);
  }
  if (config_print_rvfi) {
    fprintf(stderr, "Wrote %zd byte response to socket.\n", send_size);
  }
  KILL(lbits)(&packet);
}

void rvfi_send_trace(unsigned version)
{
  if (config_print_rvfi) {
    fprintf(stderr, "Sending v%d trace response...\n", version);
  }
  if (version == 1) {
    get_and_send_rvfi_packet(zrvfi_get_exec_packet_v1);
  } else if (version == 2) {
    mach_bits trace_size = zrvfi_get_v2_trace_sizze(UNIT);
    get_and_send_rvfi_packet(zrvfi_get_exec_packet_v2);
    if (zrvfi_int_data_present)
      get_and_send_rvfi_packet(zrvfi_get_int_data);
    if (zrvfi_mem_data_present)
      get_and_send_rvfi_packet(zrvfi_get_mem_data);
  } else {
    fprintf(stderr, "Sending v%d packets not implemented yet!\n", version);
    abort();
  }
}

#endif

void run_sail(void)
{
  bool spike_done;
  bool stepped;
  bool diverged = false;

  /* initialize the step number */
  mach_int step_no = 0;
  int insn_cnt = 0;
#ifdef RVFI_DII
  bool need_instr = true;
#endif

  struct timeval interval_start;
  if (gettimeofday(&interval_start, NULL) < 0) {
    fprintf(stderr, "Cannot gettimeofday: %s\n", strerror(errno));
    exit(1);
  }

  while (!zhtif_done && (insn_limit == 0 || total_insns < insn_limit)) {
#ifdef RVFI_DII
    if (rvfi_dii) {
      mach_bits instr_bits;
      if (config_print_rvfi) {
        fprintf(stderr, "Waiting for cmd packet... ");
      }
      int res = read(rvfi_dii_sock, &instr_bits, sizeof(instr_bits));
      if (config_print_rvfi) {
        fprintf(stderr, "Read cmd packet: %016jx\n", (intmax_t)instr_bits);
        zprint_instr_packet(instr_bits);
      }
      if (res == 0) {
        if (config_print_rvfi) {
          fprintf(stderr, "Got EOF, exiting... ");
        }
        rvfi_dii = false;
        return;
      }
      if (res == -1) {
        fprintf(stderr, "Reading RVFI DII command failed: %s", strerror(errno));
        exit(1);
      }
      if (res < sizeof(instr_bits)) {
        fprintf(stderr, "Reading RVFI DII command failed: insufficient input");
        exit(1);
      }
      zrvfi_set_instr_packet(instr_bits);
      zrvfi_zzero_exec_packet(UNIT);
      mach_bits cmd = zrvfi_get_cmd(UNIT);
      switch (cmd) {
      case 0: { /* EndOfTrace */
        if (config_print_rvfi) {
          fprintf(stderr, "Got EndOfTrace packet.\n");
        }
        mach_bits insn = zrvfi_get_insn(UNIT);
        if (insn == (('V' << 24) | ('E' << 16) | ('R' << 8) | 'S')) {
          /*
           * Reset with insn set to 'VERS' is a version negotiation request
           * and not a actual reset request. Respond with a message say that
           * we support version 2.
           */
          if (config_print_rvfi) {
            fprintf(stderr,
                    "EndOfTrace was actually a version negotiation packet.\n");
          }
          get_and_send_rvfi_packet(&zrvfi_get_v2_support_packet);
          continue;
        } else {
          zrvfi_halt_exec_packet(UNIT);
          rvfi_send_trace(rvfi_trace_version);
          return;
        }
      }
      case 1: /* Instruction */
        break;
      case 'v': { /* Set wire format version */
        mach_bits insn = zrvfi_get_insn(UNIT);
        if (config_print_rvfi) {
          fprintf(stderr, "Got request for v%jd trace format!\n",
                  (intmax_t)insn);
        }
        if (insn == 1) {
          fprintf(stderr, "Requested trace in legacy format!\n");
        } else if (insn == 2) {
          fprintf(stderr, "Requested trace in v2 format!\n");
        } else {
          fprintf(stderr, "Requested trace in unsupported format %jd!\n",
                  (intmax_t)insn);
          exit(1);
        }
        rvfi_trace_version
            = insn; // From now on send traces in the requested format
        struct {
          char msg[8];
          uint64_t version;
        } version_response = {"version=", rvfi_trace_version};
        if (write(rvfi_dii_sock, &version_response, sizeof(version_response))
            != sizeof(version_response)) {
          fprintf(stderr, "Sending version response failed: %s\n",
                  strerror(errno));
          exit(1);
        }
        continue;
      }
      default:
        fprintf(stderr, "Unknown RVFI-DII command: %#02x\n", (int)cmd);
        exit(1);
      }
      sail_int sail_step;
      CREATE(sail_int)(&sail_step);
      CONVERT_OF(sail_int, mach_int)(&sail_step, step_no);
      stepped = zstep(sail_step);
      if (have_exception)
        goto step_exception;
      flush_logs();
      KILL(sail_int)(&sail_step);
      rvfi_send_trace(rvfi_trace_version);
    } else /* if (!rvfi_dii) */
#endif
    { /* run a Sail step */
      sail_int sail_step;
      CREATE(sail_int)(&sail_step);
      CONVERT_OF(sail_int, mach_int)(&sail_step, step_no);
      stepped = zstep(sail_step);
      if (have_exception)
        goto step_exception;
      flush_logs();
      KILL(sail_int)(&sail_step);
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
#ifdef ENABLE_SPIKE
    { /* run a Spike step */
      tv_step(s);
      spike_done = tv_is_done(s);
      flush_logs();
    }

    if (zhtif_done) {
      if (!spike_done) {
        fprintf(stdout, "Sail done (exit-code %" PRIi64 "), but not Spike!\n",
                zhtif_exit_code);
        exit(1);
      }
    } else {
      if (spike_done) {
        fprintf(stdout, "Spike done, but not Sail!\n");
        exit(1);
      }
    }
    if (!compare_states(s)) {
      diverged = true;
      break;
    }
#endif
    if (zhtif_done) {
      /* check exit code */
      if (zhtif_exit_code == 0)
        fprintf(stdout, "SUCCESS\n");
      else
        fprintf(stdout, "FAILURE: %" PRIi64 "\n", zhtif_exit_code);
    }

    if (insn_cnt == rv_insns_per_tick) {
      insn_cnt = 0;
      ztick_clock(UNIT);
      ztick_platform(UNIT);

      tick_spike();
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
#ifdef ENABLE_SPIKE
  // The Spike interface uses stdout for terminal output, and stderr for logs.
  // Do the same here.
  if (dup2(1, 2) < 0) {
    fprintf(stderr, "Unable to dup 1 -> 2: %s\n", strerror(errno));
    exit(1);
  }
#endif

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
  } else if ((trace_log = fopen(trace_log_path, "w+")) < 0) {
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
  // Initialize model so that we can check or report its architecture.
  preinit_sail();

  int files_start = process_args(argc, argv);
  char *initial_elf_file = argv[files_start];
  init_logs();

  if (gettimeofday(&init_start, NULL) < 0) {
    fprintf(stderr, "Cannot gettimeofday: %s\n", strerror(errno));
    exit(1);
  }

#ifdef RVFI_DII
  uint64_t entry;
  if (rvfi_dii) {
    entry = 0x80000000;
    int listen_sock = socket(AF_INET, SOCK_STREAM, 0);
    if (listen_sock == -1) {
      fprintf(stderr, "Unable to create socket: %s\n", strerror(errno));
      return 1;
    }
    int reuseaddr = 1;
    if (setsockopt(listen_sock, SOL_SOCKET, SO_REUSEADDR, &reuseaddr,
                   sizeof(reuseaddr))
        == -1) {
      fprintf(stderr, "Unable to set reuseaddr on socket: %s\n",
              strerror(errno));
      return 1;
    }
    struct sockaddr_in addr = {.sin_family = AF_INET,
                               .sin_addr.s_addr = htonl(INADDR_LOOPBACK),
                               .sin_port = htons(rvfi_dii_port)};
    if (bind(listen_sock, (struct sockaddr *)&addr, sizeof(addr)) == -1) {
      fprintf(stderr, "Unable to set bind socket: %s\n", strerror(errno));
      return 1;
    }
    if (listen(listen_sock, 1) == -1) {
      fprintf(stderr, "Unable to listen on socket: %s\n", strerror(errno));
      return 1;
    }
    socklen_t addrlen = sizeof(addr);
    if (getsockname(listen_sock, (struct sockaddr *)&addr, &addrlen) == -1) {
      fprintf(stderr, "Unable to getsockname() on socket: %s\n",
              strerror(errno));
      return 1;
    }
    printf("Waiting for connection on port %d.\n", ntohs(addr.sin_port));
    rvfi_dii_sock = accept(listen_sock, NULL, NULL);
    if (rvfi_dii_sock == -1) {
      fprintf(stderr, "Unable to accept connection on socket: %s\n",
              strerror(errno));
      return 1;
    }
    close(listen_sock);
    // Ensure that the socket is blocking
    int fd_flags = fcntl(rvfi_dii_sock, F_GETFL);
    if (fd_flags == -1) {
      fprintf(stderr, "Failed to get file descriptor flags for socket!\n");
      return 1;
    }
    if (config_print_rvfi) {
      fprintf(stderr, "RVFI socket fd flags=%d, nonblocking=%d\n", fd_flags,
              (fd_flags & O_NONBLOCK) != 0);
    }
    if (fd_flags & O_NONBLOCK) {
      fprintf(stderr, "Socket was non-blocking, this will not work!\n");
      return 1;
    }
    printf("Connected\n");
  } else
    entry = load_sail(initial_elf_file, /*main_file=*/true);
#else
  uint64_t entry = load_sail(initial_elf_file, /*main_file=*/true);
#endif
  /* Load any additional ELF files into memory */
  for (int i = files_start + 1; i < argc; i++) {
    fprintf(stdout, "Loading additional ELF file %s.\n", argv[i]);
    (void)load_sail(argv[i], /*main_file=*/false);
  }

  /* initialize spike before sail so that we can access the device-tree blob,
   * until we roll our own.
   */
  init_spike(initial_elf_file, entry, rv_ram_size);
  init_sail(entry);

  if (!init_check(s))
    finish(1);

  if (gettimeofday(&init_end, NULL) < 0) {
    fprintf(stderr, "Cannot gettimeofday: %s\n", strerror(errno));
    exit(1);
  }

  do {
    run_sail();
#ifndef RVFI_DII
  } while (0);
#else
    if (rvfi_dii) {
      /* Reset for next test */
      reinit_sail(entry);
    }
  } while (rvfi_dii);
#endif
  model_fini();
  flush_logs();
  close_logs();
}
