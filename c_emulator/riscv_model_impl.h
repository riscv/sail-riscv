#pragma once

#include <cstdint>
#include <cstdio>
#include <random>
#include <vector>

#include "sail.h"
#include "riscv_sail.h"

extern bool rv_enable_experimental_extensions;

extern FILE *trace_log;
extern int term_fd;
void plat_term_write_impl(char c);

// Model wrapped with an implementation of its platform callbacks.
class ModelImpl : public model::Model {
public:
  void register_callback(callbacks_if *cb);
  void remove_callback(callbacks_if *cb);

private:
  // These functions are called by the Sail code.

  unit mem_write_callback(const char *type, sbits paddr, uint64_t width,
                          lbits value) override;
  unit mem_read_callback(const char *type, sbits paddr, uint64_t width,
                         lbits value) override;
  unit mem_exception_callback(sbits paddr, uint64_t num_of_exception) override;
  unit xreg_full_write_callback(const_sail_string abi_name, sbits reg,
                                sbits value) override;
  unit freg_write_callback(unsigned reg, sbits value) override;
  // `full` indicates that the name and index of the CSR are provided.
  // 64 bit CSRs use a long_csr_write_callback Sail function that automatically
  // makes two csr_full_write_callback calls on RV32.
  unit csr_full_write_callback(const_sail_string csr_name, unsigned reg,
                               sbits value) override;
  unit csr_full_read_callback(const_sail_string csr_name, unsigned reg,
                              sbits value) override;
  unit vreg_write_callback(unsigned reg, lbits value) override;
  unit pc_write_callback(sbits value) override;
  unit trap_callback(unit) override;

  // Provides entropy for the scalar cryptography extension.
  mach_bits plat_get_16_random_bits(unit) override;

  unit load_reservation(sbits) override;
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
  bool get_config_print_platform(unit) override;
  bool get_config_rvfi(unit) override;
  bool get_config_use_abi_names(unit) override;

  // TODO: Probably better with std::shared_ptr<callbacks_if>.
  std::vector<callbacks_if *> m_callbacks;

  mach_bits m_reservation = 0;
  bool m_reservation_valid = false;

  static unsigned seed()
  {
    std::random_device rd;
    return rd();
  }

  // Randomly seeded PRNG.
  std::mt19937_64 m_gen64 {seed()};
};
