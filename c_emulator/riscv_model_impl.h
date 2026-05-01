#pragma once

#include <cstdint>
#include <cstdio>
#include <map>
#include <memory>
#include <optional>
#include <random>
#include <vector>

#include "sail.h"
#include "sail_riscv_model.h"

struct MemoryRegion {
  uint64_t base = 0;
  uint64_t size = 0;
};

// Model wrapped with an implementation of its platform callbacks.
class ModelImpl final : private hart::Model {
public:
  // types

  using Privilege = hart::ztuple_z8z5enumz0zzPrivilegezCz0z5unitz9;
  using MemoryAccessType = hart::zMemoryAccessTypezIEmem_payloadz5zK;
  using PTW_Error = hart::zPTW_Error;
  using TLB = hart::zz5vecz8z5unionz0zzoptionzzIRTLB_EntryzzKz9;

  // callbacks

  void register_callback(std::shared_ptr<callbacks_if> cb);
  void remove_callback(std::shared_ptr<callbacks_if> cb);

  void call_pre_step_callbacks(bool is_waiting);
  void call_post_step_callbacks(bool is_waiting);

  // configuration

  void set_enable_experimental_extensions(bool en);
  void set_reservation_set_size_exp(uint64_t exponent);
  void set_reservation_require_exact_addr_match(bool require_exact_addr_match);
  void set_reservation_invalidate_on_same_hart_store(bool invalidate_on_same_hart_store);

  void set_config_print_instr(bool on);
  void set_config_print_clint(bool on);
  void set_config_print_exception(bool on);
  void set_config_print_interrupt(bool on);
  void set_config_print_htif(bool on);
  void set_config_print_pma(bool on);
  void set_config_print_step(bool on);

  void set_config_rvfi(bool on);
  void set_config_use_abi_names(bool on);

  void set_elf_symbols(std::map<uint64_t, std::string> symbols);
  void set_term_fd(int fd);
  void set_trace_log(FILE *log);

  // initialization

  void init_platform_constants();
  void init_sail(uint64_t entry, const char *config_file, const std::optional<uint64_t> &htif_tohost_address);
  void reinit_sail();
  void model_init();
  void model_fini();

  // string conversions

  std::string memory_access_type_to_string(MemoryAccessType access_type);
  std::string privilege_to_string(Privilege privilege);
  std::string ptw_error_to_string(PTW_Error error_type);

  // access to model configuration

  bool config_is_valid();
  bool dtb_within_configured_pma_memory(uint64_t addr, uint64_t size);
  std::vector<MemoryRegion> main_memory_regions() const;
  std::string generate_dts();
  std::string generate_isa_string();

  // read access to model state

  void tick_clock();
  bool try_step(int64_t step_no, bool exit_wait);

  int64_t xlen() const;
  int64_t flen() const;
  int64_t physaddrbits_len() const;
  uint64_t mepc() const;
  uint64_t sepc() const;
  uint64_t htif_exit_code() const;
  bool htif_done() const;
  bool had_exception() const;
  uint64_t pc() const;
  uint64_t fcsr() const;

  // These state accessors are not const due to the generated read
  // accessors not being marked const in hart::Model.
  uint64_t xreg(int64_t reg);
  uint64_t freg(int64_t reg);
  // returns std::nullopt if the model has not thrown an exception.
  std::optional<std::string> string_of_current_exception();

  // write access to model state

  void set_xreg(int64_t reg, uint64_t val);
  void set_freg(int64_t reg, uint64_t val);
  void set_pc(uint64_t val);
  void set_fcsr(uint64_t val);

  // RVFI support

  friend class rvfi_handler;
  friend class rvfi_callbacks;

private:
  // Internal functions.
  void init_sail_impl();

  // These functions are called by the Sail code.

  unit fetch_callback(sbits opcode) override;
  unit mem_write_callback(const char *type, sbits paddr, int64_t width, lbits value) override;
  unit mem_read_callback(const char *type, sbits paddr, int64_t width, lbits value) override;
  unit mem_exception_callback(sbits paddr, uint64_t num_of_exception) override;
  unit xreg_full_write_callback(const_sail_string abi_name, sbits reg, sbits value) override;
  unit freg_write_callback(unsigned reg, sbits value) override;
  // `full` indicates that the name and index of the CSR are provided.
  // 64 bit CSRs use a long_csr_write_callback Sail function that automatically
  // makes two csr_full_write_callback calls on RV32.
  unit csr_full_write_callback(const_sail_string csr_name, unsigned reg, sbits value) override;
  unit csr_full_read_callback(const_sail_string csr_name, unsigned reg, sbits value) override;
  unit vreg_write_callback(unsigned reg, lbits value) override;
  unit pc_write_callback(sbits new_pc) override;
  unit redirect_callback(sbits new_pc) override;
  unit trap_callback(bool is_interrupt, fbits cause) override;
  unit xret_callback(bool is_mret) override;
  unit instret_callback(unit) override;

  // Page table walk callbacks
  unit ptw_start_callback(uint64_t vpn, MemoryAccessType access_type, Privilege privilege) override;
  unit ptw_step_callback(int64_t level, sbits pte_addr, uint64_t pte) override;
  unit ptw_success_callback(uint64_t final_ppn, int64_t level) override;
  unit ptw_fail_callback(PTW_Error error_type, int64_t level, sbits pte_addr) override;
  unit tlb_add_callback(TLB tlb, uint64_t index) override;
  unit tlb_flush_begin_callback(unit) override;
  unit tlb_flush_callback(uint64_t index) override;
  unit tlb_flush_end_callback(TLB tlb) override;
  // Provides entropy for the scalar cryptography extension.
  mach_bits plat_get_16_random_bits(unit) override;

  unit load_reservation(sbits, uint64_t) override;
  bool match_reservation(sbits) override;
  unit cancel_reservation(unit) override;
  bool valid_reservation(unit) override;

  unit plat_term_write(mach_bits) override;

  bool sys_enable_experimental_extensions(unit) override;

  unit print_string(const_sail_string prefix, const_sail_string msg) override;

  unit print_log(const_sail_string s) override;
  unit print_log_instr(const_sail_string s, uint64_t pc) override;
  unit print_step(unit) override;

  bool get_config_print_instr(unit) override;
  bool get_config_print_clint(unit) override;
  bool get_config_print_exception(unit) override;
  bool get_config_print_interrupt(unit) override;
  bool get_config_print_htif(unit) override;
  bool get_config_print_pma(unit) override;
  bool get_config_rvfi(unit) override;
  bool get_config_use_abi_names(unit) override;

  bool m_config_print_instr = false;
  bool m_config_print_clint = false;
  bool m_config_print_exception = false;
  bool m_config_print_interrupt = false;
  bool m_config_print_htif = false;
  bool m_config_print_pma = false;
  bool m_config_rvfi = false;
  bool m_config_use_abi_names = false;

  bool m_config_print_step = false;

  // Initialization.
  uint64_t m_elf_entry = 0;
  std::string m_config_file = {};
  std::optional<uint64_t> m_htif_tohost_address = {};

  std::map<uint64_t, std::string> m_symbols;
  int m_term_fd = 1;

  std::vector<std::shared_ptr<callbacks_if>> m_callbacks;

  uint64_t m_reservation = 0;
  uint64_t m_reservation_addr = 0;
  bool m_reservation_valid = false;

  uint64_t m_reservation_set_addr_mask = 0;
  bool m_reservation_require_exact_addr = false;
  bool m_reservation_invalidate_on_same_hart_store = false;

  bool m_enable_experimental_extensions = false;

  static unsigned seed() {
    std::random_device rd;
    return rd();
  }

  // Randomly seeded PRNG.
  std::mt19937_64 m_gen64{seed()};

  // Trace log file
  FILE *m_trace_log = stdout;
};
