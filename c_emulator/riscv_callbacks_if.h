#pragma once

#include "sail.h"

namespace model {
class Model;
}

class callbacks_if {
public:
  virtual ~callbacks_if() = default;

  virtual void fetch_callback([[maybe_unused]] model::Model &model,
                              [[maybe_unused]] sbits opcode)
  {
  }
  virtual void mem_write_callback([[maybe_unused]] model::Model &model,
                                  [[maybe_unused]] const char *type,
                                  [[maybe_unused]] sbits paddr,
                                  [[maybe_unused]] uint64_t width,
                                  [[maybe_unused]] lbits value)
  {
  }
  virtual void mem_read_callback([[maybe_unused]] model::Model &model,
                                 [[maybe_unused]] const char *type,
                                 [[maybe_unused]] sbits paddr,
                                 [[maybe_unused]] uint64_t width,
                                 [[maybe_unused]] lbits value)
  {
  }
  virtual void
  mem_exception_callback([[maybe_unused]] model::Model &model,
                         [[maybe_unused]] sbits paddr,
                         [[maybe_unused]] uint64_t num_of_exception)
  {
  }
  virtual void
  xreg_full_write_callback([[maybe_unused]] model::Model &model,
                           [[maybe_unused]] const_sail_string abi_name,
                           [[maybe_unused]] sbits reg,
                           [[maybe_unused]] sbits value)
  {
  }
  virtual void freg_write_callback([[maybe_unused]] model::Model &model,
                                   [[maybe_unused]] unsigned reg,
                                   [[maybe_unused]] sbits value)
  {
  }
  virtual void
  csr_full_write_callback([[maybe_unused]] model::Model &model,
                          [[maybe_unused]] const_sail_string csr_name,
                          [[maybe_unused]] unsigned reg,
                          [[maybe_unused]] sbits value)
  {
  }
  virtual void
  csr_full_read_callback([[maybe_unused]] model::Model &model,
                         [[maybe_unused]] const_sail_string csr_name,
                         [[maybe_unused]] unsigned reg,
                         [[maybe_unused]] sbits value)
  {
  }
  virtual void vreg_write_callback([[maybe_unused]] model::Model &model,
                                   [[maybe_unused]] unsigned reg,
                                   [[maybe_unused]] lbits value)
  {
  }
  virtual void pc_write_callback([[maybe_unused]] model::Model &model,
                                 [[maybe_unused]] sbits new_pc)
  {
  }
  virtual void redirect_callback([[maybe_unused]] model::Model &model,
                                 [[maybe_unused]] sbits new_pc)
  {
  }
  virtual void trap_callback([[maybe_unused]] model::Model &model,
                             [[maybe_unused]] bool is_interrupt,
                             [[maybe_unused]] fbits cause)
  {
  }
};
