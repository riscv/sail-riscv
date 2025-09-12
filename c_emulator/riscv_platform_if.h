#pragma once

#include "sail.h"

class callbacks_if;

namespace model {
class Model;
}

// The Model class derives from this one so when Sail calls C callback
// functions it actually calls methods of this class. However they are
// virtual functions so they actually call the Platform implementations
// (see riscv_platform_impl.h). It's done this way because:
//
// a) This allows the platform implementation to access the Model.
// b) This allows exposing the Model in the library without fixing
//    the Platform implementation.
//
// We must provide default implementations so the automatically generated
// model_test() function can instantiate model::Model.

class PlatformInterface {
public:
  virtual unit mem_write_callback(const char *type, sbits paddr, uint64_t width,
                                  lbits value)
  {
    (void)type;
    (void)paddr;
    (void)width;
    (void)value;
    return UNIT;
  }
  virtual unit mem_read_callback(const char *type, sbits paddr, uint64_t width,
                                 lbits value)
  {
    (void)type;
    (void)paddr;
    (void)width;
    (void)value;
    return UNIT;
  }
  virtual unit mem_exception_callback(sbits paddr, uint64_t num_of_exception)
  {
    (void)paddr;
    (void)num_of_exception;
    return UNIT;
  }
  virtual unit xreg_full_write_callback(const_sail_string abi_name, sbits reg,
                                        sbits value)
  {
    (void)abi_name;
    (void)reg;
    (void)value;
    return UNIT;
  }
  virtual unit freg_write_callback(unsigned reg, sbits value)
  {
    (void)reg;
    (void)value;
    return UNIT;
  }
  // `full` indicates that the name and index of the CSR are provided.
  // 64 bit CSRs use a long_csr_write_callback Sail function that automatically
  // makes two csr_full_write_callback calls on RV32.
  virtual unit csr_full_write_callback(const_sail_string csr_name, unsigned reg,
                                       sbits value)
  {
    (void)csr_name;
    (void)reg;
    (void)value;
    return UNIT;
  }
  virtual unit csr_full_read_callback(const_sail_string csr_name, unsigned reg,
                                      sbits value)
  {
    (void)csr_name;
    (void)reg;
    (void)value;
    return UNIT;
  }
  virtual unit vreg_write_callback(unsigned reg, lbits value)
  {
    (void)reg;
    (void)value;
    return UNIT;
  }
  virtual unit pc_write_callback(sbits value)
  {
    (void)value;
    return UNIT;
  }
  virtual unit trap_callback(unit)
  {
    return UNIT;
  }

  // Provides entropy for the scalar cryptography extension.
  virtual mach_bits plat_get_16_random_bits(unit)
  {
    return UNIT;
  }

  virtual unit load_reservation(sbits)
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
  virtual bool get_config_print_platform(unit)
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
