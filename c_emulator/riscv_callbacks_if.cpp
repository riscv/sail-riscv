#include "riscv_callbacks_if.h"

// Default implementations that do nothing.

// Callback invoked before each step
void callbacks_if::pre_step_callback([[maybe_unused]] ModelImpl &model, [[maybe_unused]] bool is_waiting) {
}

// Callback invoked after each step
void callbacks_if::post_step_callback([[maybe_unused]] ModelImpl &model, [[maybe_unused]] bool is_waiting) {
}

void callbacks_if::fetch_callback([[maybe_unused]] ModelImpl &model, [[maybe_unused]] sbits opcode) {
}

void callbacks_if::mem_write_callback(
  [[maybe_unused]] ModelImpl &model,
  [[maybe_unused]] const char *type,
  [[maybe_unused]] sbits paddr,
  [[maybe_unused]] int64_t width,
  [[maybe_unused]] lbits value
) {
}

void callbacks_if::mem_read_callback(
  [[maybe_unused]] ModelImpl &model,
  [[maybe_unused]] const char *type,
  [[maybe_unused]] sbits paddr,
  [[maybe_unused]] int64_t width,
  [[maybe_unused]] lbits value
) {
}

void callbacks_if::mem_exception_callback(
  [[maybe_unused]] ModelImpl &model,
  [[maybe_unused]] sbits paddr,
  [[maybe_unused]] uint64_t num_of_exception
) {
}

void callbacks_if::xreg_full_write_callback(
  [[maybe_unused]] ModelImpl &model,
  [[maybe_unused]] const_sail_string abi_name,
  [[maybe_unused]] sbits reg,
  [[maybe_unused]] sbits value
) {
}

void callbacks_if::freg_write_callback(
  [[maybe_unused]] ModelImpl &model,
  [[maybe_unused]] unsigned reg,
  [[maybe_unused]] sbits value
) {
}

void callbacks_if::csr_full_write_callback(
  [[maybe_unused]] ModelImpl &model,
  [[maybe_unused]] const_sail_string csr_name,
  [[maybe_unused]] unsigned reg,
  [[maybe_unused]] sbits value
) {
}

void callbacks_if::csr_full_read_callback(
  [[maybe_unused]] ModelImpl &model,
  [[maybe_unused]] const_sail_string csr_name,
  [[maybe_unused]] unsigned reg,
  [[maybe_unused]] sbits value
) {
}

void callbacks_if::vreg_write_callback(
  [[maybe_unused]] ModelImpl &model,
  [[maybe_unused]] unsigned reg,
  [[maybe_unused]] lbits value
) {
}

void callbacks_if::pc_write_callback([[maybe_unused]] ModelImpl &model, [[maybe_unused]] sbits new_pc) {
}

void callbacks_if::redirect_callback([[maybe_unused]] ModelImpl &model, [[maybe_unused]] sbits new_pc) {
}

void callbacks_if::trap_callback(
  [[maybe_unused]] ModelImpl &model,
  [[maybe_unused]] bool is_interrupt,
  [[maybe_unused]] fbits cause
) {
}

void callbacks_if::xret_callback([[maybe_unused]] ModelImpl &model, [[maybe_unused]] bool is_mret) {
}

void callbacks_if::instret_callback([[maybe_unused]] ModelImpl &model) {
}

void callbacks_if::trigger_match_callback([[maybe_unused]] hart::Model &model, [[maybe_unused]] sail_int trig_index) {
}

void callbacks_if::trigger_fire_callback([[maybe_unused]] hart::Model &model, [[maybe_unused]] sail_int trig_index) {
}

// Page table walk callbacks
void callbacks_if::ptw_start_callback(
  [[maybe_unused]] ModelImpl &model,
  [[maybe_unused]] uint64_t vpn,
  [[maybe_unused]] ModelImpl::MemoryAccessType access_type,
  [[maybe_unused]] ModelImpl::Privilege privilege
) {
}

void callbacks_if::ptw_step_callback(
  [[maybe_unused]] ModelImpl &model,
  [[maybe_unused]] int64_t level,
  [[maybe_unused]] sbits pte_addr,
  [[maybe_unused]] uint64_t pte
) {
}

void callbacks_if::ptw_success_callback(
  [[maybe_unused]] ModelImpl &model,
  [[maybe_unused]] uint64_t final_ppn,
  [[maybe_unused]] int64_t level
) {
}

void callbacks_if::ptw_fail_callback(
  [[maybe_unused]] ModelImpl &model,
  [[maybe_unused]] ModelImpl::PTW_Error error_type,
  [[maybe_unused]] int64_t level,
  [[maybe_unused]] sbits pte_addr
) {
}

void callbacks_if::tlb_add_callback(
  [[maybe_unused]] ModelImpl &model,
  [[maybe_unused]] ModelImpl::TLB_Entry tlb,
  [[maybe_unused]] uint64_t index
) {
}

void callbacks_if::tlb_flush_begin_callback([[maybe_unused]] ModelImpl &model) {
}

void callbacks_if::tlb_flush_callback([[maybe_unused]] ModelImpl &model, [[maybe_unused]] uint64_t index) {
}

void callbacks_if::tlb_flush_end_callback(
  [[maybe_unused]] ModelImpl &model,
  [[maybe_unused]] ModelImpl::TLB_Entry tlb
) {
}
