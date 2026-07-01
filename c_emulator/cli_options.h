#pragma once

#include <cstdint>
#include <string>
#include <vector>

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
  bool do_print_gdb_target_xml = false;

  bool use_rv32_default = false;
  bool disable_trap_loop_detection = false;
  std::string config_file = {};
  std::vector<std::string> config_overrides = {};
  std::string term_log = {};
  std::string trace_log_path = {};
  std::string dtb_file;
  unsigned rvfi_dii_port = 0;
  unsigned gdb_server_port = 0;
  std::vector<std::string> elfs;
  uint64_t insn_limit = 0;

  std::string sig_file = {};
  unsigned signature_granularity = DEFAULT_SIGNATURE_GRANULARITY;

#ifdef SAILCOV
  std::string sailcov_file = {};
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
  bool config_print_gdbserver = false;

  bool config_use_abi_names = false;

  bool config_enable_experimental_extensions = false;
};

// Parse CLI options. This calls `exit()` on failure.
CLIOptions parse_cli(int argc, char **argv);
