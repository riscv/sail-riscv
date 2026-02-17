#pragma once

#include <cstdint>
#include <cstdio>
#include <random>
#include <vector>

#include "sail.h"
#include "sail_riscv_model.h"

extern FILE *trace_log;
extern int term_fd;
void plat_term_write_impl(char c);

// Model wrapped with an implementation of its platform callbacks.
class ModelImpl final : public hart::Model {
public:
  void register_callback(callbacks_if *cb);
  void remove_callback(callbacks_if *cb);

  void call_pre_step_callbacks(bool is_waiting);
  void call_post_step_callbacks(bool is_waiting);

  void set_enable_experimental_extensions(bool en);
  void set_reservation_set_size_exp(uint64_t exponent);

  void set_config_print_instr(bool on);
  void set_config_print_clint(bool on);
  void set_config_print_exception(bool on);
  void set_config_print_interrupt(bool on);
  void set_config_print_htif(bool on);
  void set_config_print_pma(bool on);
  void set_config_rvfi(bool on);
  void set_config_use_abi_names(bool on);

  void set_config_print_step(bool on);

  void print_current_exception();

private:
  // These functions are called by the Sail code.

  unit fetch_callback(sbits opcode) override;
  unit mem_write_callback(const char *type, sbits paddr, uint64_t width, lbits value) override;
  unit mem_read_callback(const char *type, sbits paddr, uint64_t width, lbits value) override;
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

  // Page table walk callbacks
  unit ptw_start_callback(
    uint64_t vpn,
    hart::zMemoryAccessTypezIEmem_payloadz5zK access_type,
    hart::ztuple_z8z5enumz0zzPrivilegezCz0z5unitz9 privilege
  ) override;
  unit ptw_step_callback(int64_t level, sbits pte_addr, uint64_t pte) override;
  unit ptw_success_callback(uint64_t final_ppn, int64_t level) override;
  unit ptw_fail_callback(hart::zPTW_Error error_type, int64_t level, sbits pte_addr) override;
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

  // TODO: Probably better with std::shared_ptr<callbacks_if>.
  std::vector<callbacks_if *> m_callbacks;

  uint64_t m_reservation = 0;
  bool m_reservation_valid = false;

  uint64_t m_reservation_set_addr_mask = 0;

  bool m_enable_experimental_extensions = false;

  static unsigned seed() {
    std::random_device rd;
    return rd();
  }

  // Randomly seeded PRNG.
  std::mt19937_64 m_gen64{seed()};
};
