#pragma once

#include "sail.h"

namespace hart {

class Model;

struct zMemoryAccessTypezIuzK;
struct ztuple_z8z5enumz0zzPrivilegezCz0z5unitz9;
struct zPTW_Error;

}

class callbacks_if {
public:
  virtual ~callbacks_if() = default;

  // Callback invoked before each step
  virtual void pre_step_callback([[maybe_unused]] hart::Model &model,
                                 [[maybe_unused]] bool is_waiting);

  // Callback invoked after each step
  virtual void post_step_callback([[maybe_unused]] hart::Model &model,
                                  [[maybe_unused]] bool is_waiting);

  virtual void fetch_callback([[maybe_unused]] hart::Model &model,
                              [[maybe_unused]] sbits opcode);

  virtual void mem_write_callback([[maybe_unused]] hart::Model &model,
                                  [[maybe_unused]] const char *type,
                                  [[maybe_unused]] sbits paddr,
                                  [[maybe_unused]] uint64_t width,
                                  [[maybe_unused]] lbits value);

  virtual void mem_read_callback([[maybe_unused]] hart::Model &model,
                                 [[maybe_unused]] const char *type,
                                 [[maybe_unused]] sbits paddr,
                                 [[maybe_unused]] uint64_t width,
                                 [[maybe_unused]] lbits value);

  virtual void
  mem_exception_callback([[maybe_unused]] hart::Model &model,
                         [[maybe_unused]] sbits paddr,
                         [[maybe_unused]] uint64_t num_of_exception);

  virtual void
  xreg_full_write_callback([[maybe_unused]] hart::Model &model,
                           [[maybe_unused]] const_sail_string abi_name,
                           [[maybe_unused]] sbits reg,
                           [[maybe_unused]] sbits value);

  virtual void freg_write_callback([[maybe_unused]] hart::Model &model,
                                   [[maybe_unused]] unsigned reg,
                                   [[maybe_unused]] sbits value);

  virtual void
  csr_full_write_callback([[maybe_unused]] hart::Model &model,
                          [[maybe_unused]] const_sail_string csr_name,
                          [[maybe_unused]] unsigned reg,
                          [[maybe_unused]] sbits value);

  virtual void
  csr_full_read_callback([[maybe_unused]] hart::Model &model,
                         [[maybe_unused]] const_sail_string csr_name,
                         [[maybe_unused]] unsigned reg,
                         [[maybe_unused]] sbits value);

  virtual void vreg_write_callback([[maybe_unused]] hart::Model &model,
                                   [[maybe_unused]] unsigned reg,
                                   [[maybe_unused]] lbits value);

  virtual void pc_write_callback([[maybe_unused]] hart::Model &model,
                                 [[maybe_unused]] sbits new_pc);

  virtual void redirect_callback([[maybe_unused]] hart::Model &model,
                                 [[maybe_unused]] sbits new_pc);

  virtual void trap_callback([[maybe_unused]] hart::Model &model,
                             [[maybe_unused]] bool is_interrupt,
                             [[maybe_unused]] fbits cause);

  // Page table walk callbacks
  virtual void ptw_start_callback(
      [[maybe_unused]] hart::Model &model, [[maybe_unused]] uint64_t vpn,
      [[maybe_unused]] hart::zMemoryAccessTypezIuzK access_type,
      [[maybe_unused]] hart::ztuple_z8z5enumz0zzPrivilegezCz0z5unitz9
          privilege);

  virtual void ptw_step_callback([[maybe_unused]] hart::Model &model,
                                 [[maybe_unused]] int64_t level,
                                 [[maybe_unused]] sbits pte_addr,
                                 [[maybe_unused]] uint64_t pte);

  virtual void ptw_success_callback([[maybe_unused]] hart::Model &model,
                                    [[maybe_unused]] uint64_t final_ppn,
                                    [[maybe_unused]] int64_t level);

  virtual void ptw_fail_callback([[maybe_unused]] hart::Model &model,
                                 [[maybe_unused]] hart::zPTW_Error error_type,
                                 [[maybe_unused]] int64_t level,
                                 [[maybe_unused]] sbits pte_addr);
};
