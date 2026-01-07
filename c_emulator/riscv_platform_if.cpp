#include "riscv_platform_if.h"

#include "sail_riscv_model.h"

// We must provide default implementations so the automatically generated
// model_test() function can instantiate hart::Model.
//
// A better solution is to allow passing in `hart::Model&` to `model_test()`.
// See https://github.com/rems-project/sail/issues/1556

unit PlatformInterface::fetch_callback([[maybe_unused]] sbits opcode) {
  return UNIT;
}

unit PlatformInterface::mem_write_callback(
  [[maybe_unused]] const char *type,
  [[maybe_unused]] sbits paddr,
  [[maybe_unused]] uint64_t width,
  [[maybe_unused]] lbits value
) {
  return UNIT;
}

unit PlatformInterface::mem_read_callback(
  [[maybe_unused]] const char *type,
  [[maybe_unused]] sbits paddr,
  [[maybe_unused]] uint64_t width,
  [[maybe_unused]] lbits value
) {
  return UNIT;
}

unit PlatformInterface::mem_exception_callback(
  [[maybe_unused]] sbits paddr,
  [[maybe_unused]] uint64_t num_of_exception
) {
  return UNIT;
}

unit PlatformInterface::xreg_full_write_callback(
  [[maybe_unused]] const_sail_string abi_name,
  [[maybe_unused]] sbits reg,
  [[maybe_unused]] sbits value
) {
  return UNIT;
}

unit PlatformInterface::freg_write_callback([[maybe_unused]] unsigned reg, [[maybe_unused]] sbits value) {
  return UNIT;
}

unit PlatformInterface::csr_full_write_callback(
  [[maybe_unused]] const_sail_string csr_name,
  [[maybe_unused]] unsigned reg,
  [[maybe_unused]] sbits value
) {
  return UNIT;
}

unit PlatformInterface::csr_full_read_callback(
  [[maybe_unused]] const_sail_string csr_name,
  [[maybe_unused]] unsigned reg,
  [[maybe_unused]] sbits value
) {
  return UNIT;
}

unit PlatformInterface::vreg_write_callback([[maybe_unused]] unsigned reg, [[maybe_unused]] lbits value) {
  return UNIT;
}

unit PlatformInterface::pc_write_callback([[maybe_unused]] sbits new_pc) {
  return UNIT;
}

unit PlatformInterface::redirect_callback([[maybe_unused]] sbits new_pc) {
  return UNIT;
}

unit PlatformInterface::trap_callback(
    [[maybe_unused]] bool is_interrupt, [[maybe_unused]] fbits cause,
    [[maybe_unused]] const hart::zTrapReason &reason)
{
  return UNIT;
}

unit PlatformInterface::ptw_start_callback(
  [[maybe_unused]] uint64_t vpn,
  [[maybe_unused]] hart::zMemoryAccessTypezIuzK access_type,
  [[maybe_unused]] hart::ztuple_z8z5enumz0zzPrivilegezCz0z5unitz9 privilege
) {
  return UNIT;
}

unit PlatformInterface::ptw_step_callback(
  [[maybe_unused]] int64_t level,
  [[maybe_unused]] sbits pte_addr,
  [[maybe_unused]] uint64_t pte
) {
  return UNIT;
}
unit PlatformInterface::ptw_success_callback([[maybe_unused]] uint64_t final_ppn, [[maybe_unused]] int64_t level) {
  return UNIT;
}
unit PlatformInterface::ptw_fail_callback(
  [[maybe_unused]] hart::zPTW_Error error_type,
  [[maybe_unused]] int64_t level,
  [[maybe_unused]] sbits pte_addr
) {
  return UNIT;
}

mach_bits PlatformInterface::plat_get_16_random_bits(unit) {
  return 0;
}

unit PlatformInterface::load_reservation(sbits, uint64_t) {
  return UNIT;
}

bool PlatformInterface::match_reservation(sbits) {
  return false;
}

unit PlatformInterface::cancel_reservation(unit) {
  return UNIT;
}

bool PlatformInterface::valid_reservation(unit) {
  return false;
}

unit PlatformInterface::plat_term_write(mach_bits) {
  return UNIT;
}

bool PlatformInterface::sys_enable_experimental_extensions(unit) {
  return true;
}

unit PlatformInterface::print_string(const_sail_string prefix, const_sail_string msg) {
  (void)prefix;
  (void)msg;
  return UNIT;
}

unit PlatformInterface::print_log(const_sail_string s) {
  (void)s;
  return UNIT;
}

unit PlatformInterface::print_log_instr(const_sail_string s, uint64_t pc) {
  (void)s;
  (void)pc;
  return UNIT;
}

unit PlatformInterface::print_step(unit) {
  return UNIT;
}

bool PlatformInterface::get_config_print_instr(unit) {
  return false;
}

bool PlatformInterface::get_config_print_clint(unit) {
  return false;
}

bool PlatformInterface::get_config_print_exception(unit) {
  return false;
}

bool PlatformInterface::get_config_print_interrupt(unit) {
  return false;
}

bool PlatformInterface::get_config_print_htif(unit) {
  return false;
}

bool PlatformInterface::get_config_print_pma(unit) {
  return false;
}

bool PlatformInterface::get_config_rvfi(unit) {
  return false;
}

bool PlatformInterface::get_config_use_abi_names(unit) {
  return false;
}
