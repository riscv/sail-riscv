#pragma once

#include "sail.h"

namespace hart {

class Model;

struct zMemoryAccessTypezIEmem_payloadz5zK;
struct ztuple_z8z5enumz0zzPrivilegezCz0z5unitz9;
struct zPTW_Error;

} // namespace hart

class callbacks_if {
public:
  virtual ~callbacks_if() = default;

  // Callback invoked before each step
  virtual void pre_step_callback(hart::Model &model, bool is_waiting);

  // Callback invoked after each step
  virtual void post_step_callback(hart::Model &model, bool is_waiting);

  virtual void fetch_callback(hart::Model &model, sbits opcode);

  virtual void mem_write_callback(hart::Model &model, const char *type, sbits paddr, uint64_t width, lbits value);

  virtual void mem_read_callback(hart::Model &model, const char *type, sbits paddr, uint64_t width, lbits value);

  virtual void mem_exception_callback(hart::Model &model, sbits paddr, uint64_t num_of_exception);

  virtual void xreg_full_write_callback(hart::Model &model, const_sail_string abi_name, sbits reg, sbits value);

  virtual void freg_write_callback(hart::Model &model, unsigned reg, sbits value);

  virtual void csr_full_write_callback(hart::Model &model, const_sail_string csr_name, unsigned reg, sbits value);

  virtual void csr_full_read_callback(hart::Model &model, const_sail_string csr_name, unsigned reg, sbits value);

  virtual void vreg_write_callback(hart::Model &model, unsigned reg, lbits value);

  virtual void pc_write_callback(hart::Model &model, sbits new_pc);

  virtual void redirect_callback(hart::Model &model, sbits new_pc);

  virtual void trap_callback(hart::Model &model, bool is_interrupt, fbits cause);

  // Page table walk callbacks
  virtual void ptw_start_callback(
    hart::Model &model,
    uint64_t vpn,
    hart::zMemoryAccessTypezIEmem_payloadz5zK access_type,
    hart::ztuple_z8z5enumz0zzPrivilegezCz0z5unitz9 privilege
  );

  virtual void ptw_step_callback(hart::Model &model, int64_t level, sbits pte_addr, uint64_t pte);

  virtual void ptw_success_callback(hart::Model &model, uint64_t final_ppn, int64_t level);

  virtual void ptw_fail_callback(hart::Model &model, hart::zPTW_Error error_type, int64_t level, sbits pte_addr);
};
