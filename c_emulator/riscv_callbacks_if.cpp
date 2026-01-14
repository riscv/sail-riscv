#include "riscv_callbacks_if.h"

#include "sail_riscv_model.h"

// Default implementations that do nothing.

// Callback invoked before each step
void callbacks_if::pre_step_callback([[maybe_unused]] hart::Model &model, [[maybe_unused]] bool is_waiting) {
}

// Callback invoked after each step
void callbacks_if::post_step_callback([[maybe_unused]] hart::Model &model, [[maybe_unused]] bool is_waiting) {
}

void callbacks_if::fetch_callback([[maybe_unused]] hart::Model &model, [[maybe_unused]] sbits opcode) {
}

void callbacks_if::mem_write_callback(
  [[maybe_unused]] hart::Model &model,
  [[maybe_unused]] const char *type,
  [[maybe_unused]] sbits paddr,
  [[maybe_unused]] uint64_t width,
  [[maybe_unused]] lbits value
) {
}

void callbacks_if::mem_read_callback(
  [[maybe_unused]] hart::Model &model,
  [[maybe_unused]] const char *type,
  [[maybe_unused]] sbits paddr,
  [[maybe_unused]] uint64_t width,
  [[maybe_unused]] lbits value
) {
}

void callbacks_if::mem_exception_callback(
  [[maybe_unused]] hart::Model &model,
  [[maybe_unused]] sbits paddr,
  [[maybe_unused]] uint64_t num_of_exception
) {
}

void callbacks_if::xreg_full_write_callback(
  [[maybe_unused]] hart::Model &model,
  [[maybe_unused]] const_sail_string abi_name,
  [[maybe_unused]] sbits reg,
  [[maybe_unused]] sbits value
) {
}

void callbacks_if::freg_write_callback(
  [[maybe_unused]] hart::Model &model,
  [[maybe_unused]] unsigned reg,
  [[maybe_unused]] sbits value
) {
}

void callbacks_if::csr_full_write_callback(
  [[maybe_unused]] hart::Model &model,
  [[maybe_unused]] const_sail_string csr_name,
  [[maybe_unused]] unsigned reg,
  [[maybe_unused]] sbits value
) {
}

void callbacks_if::csr_full_read_callback(
  [[maybe_unused]] hart::Model &model,
  [[maybe_unused]] const_sail_string csr_name,
  [[maybe_unused]] unsigned reg,
  [[maybe_unused]] sbits value
) {
}

void callbacks_if::vreg_write_callback(
  [[maybe_unused]] hart::Model &model,
  [[maybe_unused]] unsigned reg,
  [[maybe_unused]] lbits value
) {
}

void callbacks_if::pc_write_callback([[maybe_unused]] hart::Model &model, [[maybe_unused]] sbits new_pc) {
}

void callbacks_if::redirect_callback([[maybe_unused]] hart::Model &model, [[maybe_unused]] sbits new_pc) {
}

void callbacks_if::trap_callback(
  [[maybe_unused]] hart::Model &model,
  [[maybe_unused]] bool is_interrupt,
  [[maybe_unused]] fbits cause
) {
}

// Page table walk callbacks
void callbacks_if::ptw_start_callback(
  [[maybe_unused]] hart::Model &model,
  [[maybe_unused]] uint64_t vpn,
  [[maybe_unused]] hart::zMemoryAccessTypezIEmem_payloadz5zK access_type,
  [[maybe_unused]] hart::ztuple_z8z5enumz0zzPrivilegezCz0z5unitz9 privilege
) {
}

void callbacks_if::ptw_step_callback(
  [[maybe_unused]] hart::Model &model,
  [[maybe_unused]] int64_t level,
  [[maybe_unused]] sbits pte_addr,
  [[maybe_unused]] uint64_t pte
) {
}

void callbacks_if::ptw_success_callback(
  [[maybe_unused]] hart::Model &model,
  [[maybe_unused]] uint64_t final_ppn,
  [[maybe_unused]] int64_t level
) {
}

void callbacks_if::ptw_fail_callback(
  [[maybe_unused]] hart::Model &model,
  [[maybe_unused]] hart::zPTW_Error error_type,
  [[maybe_unused]] int64_t level,
  [[maybe_unused]] sbits pte_addr
) {
}
