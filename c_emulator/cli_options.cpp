#include "cli_options.h"
#include "CLI11.hpp"

static bool have_gdbserver() {
#ifdef ENABLE_GDBSERVER
  return true;
#else
  return false;
#endif
}

CLIOptions parse_cli(int argc, char **argv) {
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
  if (have_gdbserver()) {
    app.add_flag("--print-gdb-target-xml", opts.do_print_gdb_target_xml, "Print GDB XML target description");
  }
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

  app.add_option("--signature-granularity", opts.signature_granularity, "Signature granularity")
    ->option_text("<uint>")
    ->check(CLI::PositiveNumber);
  app.add_option("--rvfi-dii", opts.rvfi_dii_port, "RVFI DII port")
    ->check(CLI::Range(1, 65535))
    ->option_text("<int> (within [1 - 65535])");
  app.add_option("--inst-limit", opts.insn_limit, "Instruction limit")->option_text("<uint>");
#ifdef SAILCOV
  app.add_option("--sailcov-file", opts.sailcov_file, "Sail coverage output file")->option_text("<file>");
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
  if (have_gdbserver()) {
    app.add_flag("--trace-gdbserver", opts.config_print_gdbserver, "Enable trace output for gdbserver");
  }

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
    (have_gdbserver() ? "Enable all trace output except TLB, PTW and gdbserver traces"
                      : "Enable all trace output except TLB and PTW traces")
  );

  if (have_gdbserver()) {
    app.add_option("--gdb-server-port", opts.gdb_server_port, "GDB server port")
      ->check(CLI::Range(1, 65535))
      ->option_text("<int> (within [1 - 65535])")
      ->excludes("--rvfi-dii")
      ->excludes("--inst-limit")
      ->excludes("--test-signature");
  }

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
  app.get_formatter()->long_option_alignment_ratio(6.f / static_cast<float>(column_width));
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
