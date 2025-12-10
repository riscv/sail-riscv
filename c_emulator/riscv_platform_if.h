#pragma once

#include "sail.h"

class callbacks_if;

namespace hart {

class Model;

struct zMemoryAccessTypezIuzK;
struct ztuple_z8z5enumz0zzPrivilegezCz0z5unitz9;
struct zPTW_Error;

}

// The Model class derives from this one so when Sail calls C callback
// functions it actually calls methods of this class. However they are
// virtual functions so they actually call the Platform implementations
// (see riscv_model_impl.h). It's done this way because:
//
// a) This allows the platform implementation to access the Model.
// b) This allows exposing the Model in the library without fixing
//    the Platform implementation.

class PlatformInterface {
public:
  virtual unit fetch_callback([[maybe_unused]] sbits opcode);

  virtual unit mem_write_callback([[maybe_unused]] const char *type,
                                  [[maybe_unused]] sbits paddr,
                                  [[maybe_unused]] uint64_t width,
                                  [[maybe_unused]] lbits value);

  virtual unit mem_read_callback([[maybe_unused]] const char *type,
                                 [[maybe_unused]] sbits paddr,
                                 [[maybe_unused]] uint64_t width,
                                 [[maybe_unused]] lbits value);

  virtual unit
  mem_exception_callback([[maybe_unused]] sbits paddr,
                         [[maybe_unused]] uint64_t num_of_exception);

  virtual unit
  xreg_full_write_callback([[maybe_unused]] const_sail_string abi_name,
                           [[maybe_unused]] sbits reg,
                           [[maybe_unused]] sbits value);

  virtual unit freg_write_callback([[maybe_unused]] unsigned reg,
                                   [[maybe_unused]] sbits value);

  virtual unit
  csr_full_write_callback([[maybe_unused]] const_sail_string csr_name,
                          [[maybe_unused]] unsigned reg,
                          [[maybe_unused]] sbits value);

  virtual unit
  csr_full_read_callback([[maybe_unused]] const_sail_string csr_name,
                         [[maybe_unused]] unsigned reg,
                         [[maybe_unused]] sbits value);

  virtual unit vreg_write_callback([[maybe_unused]] unsigned reg,
                                   [[maybe_unused]] lbits value);

  virtual unit pc_write_callback([[maybe_unused]] sbits new_pc);

  virtual unit redirect_callback([[maybe_unused]] sbits new_pc);

  virtual unit trap_callback([[maybe_unused]] bool is_interrupt,
                             [[maybe_unused]] fbits cause);

  // Page table walk callbacks
  virtual unit ptw_start_callback(
      [[maybe_unused]] uint64_t vpn,
      [[maybe_unused]] hart::zMemoryAccessTypezIuzK access_type,
      [[maybe_unused]] hart::ztuple_z8z5enumz0zzPrivilegezCz0z5unitz9
          privilege);
  virtual unit ptw_step_callback([[maybe_unused]] int64_t level,
                                 [[maybe_unused]] sbits pte_addr,
                                 [[maybe_unused]] uint64_t pte);
  virtual unit ptw_success_callback([[maybe_unused]] uint64_t final_ppn,
                                    [[maybe_unused]] int64_t level);
  virtual unit ptw_fail_callback([[maybe_unused]] hart::zPTW_Error error_type,
                                 [[maybe_unused]] int64_t level,
                                 [[maybe_unused]] sbits pte_addr);

  // Provides entropy for the scalar cryptography extension.
  virtual mach_bits plat_get_16_random_bits(unit);

  virtual unit load_reservation(sbits, uint64_t);
  virtual bool match_reservation(sbits);
  virtual unit cancel_reservation(unit);

  virtual bool valid_reservation(unit);

  virtual unit plat_term_write(mach_bits);

  virtual bool sys_enable_experimental_extensions(unit);

  virtual unit print_string(const_sail_string prefix, const_sail_string msg);
  virtual unit print_log(const_sail_string s);
  virtual unit print_log_instr(const_sail_string s, uint64_t pc);
  virtual unit print_step(unit);

  virtual bool get_config_print_instr(unit);
  virtual bool get_config_print_clint(unit);
  virtual bool get_config_print_exception(unit);
  virtual bool get_config_print_interrupt(unit);
  virtual bool get_config_print_htif(unit);
  virtual bool get_config_print_pma(unit);
  virtual bool get_config_rvfi(unit);
  virtual bool get_config_use_abi_names(unit);
};
