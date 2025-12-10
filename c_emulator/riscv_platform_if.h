#pragma once

#include "sail.h"
#include "sail_riscv_model.h"

class callbacks_if;

// The Model class derives from this one so when Sail calls C callback
// functions it actually calls methods of this class. However they are
// virtual functions so they actually call the Platform implementations
// (see riscv_model_impl.h). It's done this way because:
//
// a) This allows the platform implementation to access the Model.
// b) This allows exposing the Model in the library without fixing
//    the Platform implementation.
//
// We must provide default implementations so the automatically generated
// model_test() function can instantiate hart::Model.

class PlatformInterface {
public:
  virtual unit fetch_callback([[maybe_unused]] sbits opcode)
  {
    return UNIT;
  }
  virtual unit mem_write_callback([[maybe_unused]] const char *type,
                                  [[maybe_unused]] sbits paddr,
                                  [[maybe_unused]] uint64_t width,
                                  [[maybe_unused]] lbits value)
  {
    return UNIT;
  }
  virtual unit mem_read_callback([[maybe_unused]] const char *type,
                                 [[maybe_unused]] sbits paddr,
                                 [[maybe_unused]] uint64_t width,
                                 [[maybe_unused]] lbits value)
  {
    return UNIT;
  }
  virtual unit
  mem_exception_callback([[maybe_unused]] sbits paddr,
                         [[maybe_unused]] uint64_t num_of_exception)
  {
    return UNIT;
  }
  virtual unit
  xreg_full_write_callback([[maybe_unused]] const_sail_string abi_name,
                           [[maybe_unused]] sbits reg,
                           [[maybe_unused]] sbits value)
  {
    return UNIT;
  }
  virtual unit freg_write_callback([[maybe_unused]] unsigned reg,
                                   [[maybe_unused]] sbits value)
  {
    return UNIT;
  }
  virtual unit
  csr_full_write_callback([[maybe_unused]] const_sail_string csr_name,
                          [[maybe_unused]] unsigned reg,
                          [[maybe_unused]] sbits value)
  {
    return UNIT;
  }
  virtual unit
  csr_full_read_callback([[maybe_unused]] const_sail_string csr_name,
                         [[maybe_unused]] unsigned reg,
                         [[maybe_unused]] sbits value)
  {
    return UNIT;
  }
  virtual unit vreg_write_callback([[maybe_unused]] unsigned reg,
                                   [[maybe_unused]] lbits value)
  {
    return UNIT;
  }
  virtual unit pc_write_callback([[maybe_unused]] sbits new_pc)
  {
    return UNIT;
  }
  virtual unit redirect_callback([[maybe_unused]] sbits new_pc)
  {
    return UNIT;
  }
  virtual unit trap_callback([[maybe_unused]] bool is_interrupt,
                             [[maybe_unused]] fbits cause)
  {
    return UNIT;
  }

// Page table walk callbacks
virtual unit ptw_start_callback([[maybe_unused]] uint64_t vpn,
                          [[maybe_unused]] struct hart::zMemoryAccessTypezIuzK access_type,
                          [[maybe_unused]] enum hart::zPrivilege privilege) {
    return UNIT;
  }
  virtual unit ptw_step_callback([[maybe_unused]] int64_t level, [[maybe_unused]] sbits pte_addr, [[maybe_unused]] uint64_t pte){
    return UNIT;
  }
  virtual unit ptw_success_callback([[maybe_unused]] uint64_t final_ppn, [[maybe_unused]] int64_t level){
    return UNIT;
  }
  virtual unit ptw_fail_callback([[maybe_unused]] struct hart::zPTW_Error error_type, [[maybe_unused]] int64_t level,
                         [[maybe_unused]] sbits pte_addr){
    return UNIT;
  }



  // Provides entropy for the scalar cryptography extension.
  virtual mach_bits plat_get_16_random_bits(unit)
  {
    return 0;
  }

  virtual unit load_reservation(sbits, uint64_t)
  {
    return UNIT;
  }
  virtual bool match_reservation(sbits)
  {
    return false;
  }
  virtual unit cancel_reservation(unit)
  {
    return UNIT;
  }
  virtual bool valid_reservation(unit)
  {
    return false;
  }

  virtual unit plat_term_write(mach_bits)
  {
    return UNIT;
  }

  virtual bool sys_enable_experimental_extensions(unit)
  {
    return true;
  }

  virtual unit print_string(const_sail_string prefix, const_sail_string msg)
  {
    (void)prefix;
    (void)msg;
    return UNIT;
  }

  virtual unit print_log(const_sail_string s)
  {
    (void)s;
    return UNIT;
  }

  virtual unit print_log_instr(const_sail_string s, uint64_t pc)
  {
    (void)s;
    (void)pc;
    return UNIT;
  }

  virtual unit print_step(unit)
  {
    return UNIT;
  }

  virtual bool get_config_print_instr(unit)
  {
    return false;
  }

  virtual bool get_config_print_clint(unit)
  {
    return false;
  }

  virtual bool get_config_print_exception(unit)
  {
    return false;
  }

  virtual bool get_config_print_interrupt(unit)
  {
    return false;
  }

  virtual bool get_config_print_htif(unit)
  {
    return false;
  }

  virtual bool get_config_print_pma(unit)
  {
    return false;
  }

  virtual bool get_config_rvfi(unit)
  {
    return false;
  }

  virtual bool get_config_use_abi_names(unit)
  {
    return false;
  }
};
