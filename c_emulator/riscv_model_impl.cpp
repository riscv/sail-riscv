#include "riscv_model_impl.h"
#include <algorithm>
#include <cassert>
#include <random>
#include <unistd.h>

#include "config_utils.h"
#include "riscv_callbacks_if.h"
#include "symbol_table.h"

void ModelImpl::register_callback(callbacks_if *cb) {
  if (std::find(m_callbacks.begin(), m_callbacks.end(), cb) == m_callbacks.end()) {
    m_callbacks.push_back(cb);
  }
}

void ModelImpl::remove_callback(callbacks_if *cb) {
  m_callbacks.erase(std::remove(m_callbacks.begin(), m_callbacks.end(), cb), m_callbacks.end());
}

void ModelImpl::call_pre_step_callbacks(bool is_waiting) {
  for (auto c : m_callbacks) {
    c->pre_step_callback(*this, is_waiting);
  }
}

void ModelImpl::call_post_step_callbacks(bool is_waiting) {
  for (auto c : m_callbacks) {
    c->post_step_callback(*this, is_waiting);
  }
}

void ModelImpl::set_enable_experimental_extensions(bool en) {
  m_enable_experimental_extensions = en;
}

void ModelImpl::set_reservation_set_size_exp(uint64_t exponent) {
  m_reservation_set_addr_mask = ~((1 << exponent) - 1);
}

void ModelImpl::set_reservation_require_exact_addr_match(bool require_exact_addr) {
  m_reservation_require_exact_addr = require_exact_addr;
}

void ModelImpl::set_reservation_invalidate_on_same_hart_store(bool invalidate_on_same_hart_store) {
  m_reservation_invalidate_on_same_hart_store = invalidate_on_same_hart_store;
}

unit ModelImpl::fetch_callback(sbits opcode) {
  for (auto c : m_callbacks) {
    c->fetch_callback(*this, opcode);
  }
  return UNIT;
}

unit ModelImpl::mem_write_callback(const char *type, sbits paddr, uint64_t width, lbits value) {
  for (auto c : m_callbacks) {
    c->mem_write_callback(*this, type, paddr, width, value);
  }
  if (m_reservation_invalidate_on_same_hart_store && match_reservation(paddr)) {
    cancel_reservation(UNIT);
  };
  return UNIT;
}
unit ModelImpl::mem_read_callback(const char *type, sbits paddr, uint64_t width, lbits value) {
  for (auto c : m_callbacks) {
    c->mem_read_callback(*this, type, paddr, width, value);
  }
  return UNIT;
}

unit ModelImpl::mem_exception_callback(sbits paddr, uint64_t num_of_exception) {
  for (auto c : m_callbacks) {
    c->mem_exception_callback(*this, paddr, num_of_exception);
  }
  return UNIT;
}

unit ModelImpl::xreg_full_write_callback(const_sail_string abi_name, sbits reg, sbits value) {
  for (auto c : m_callbacks) {
    c->xreg_full_write_callback(*this, abi_name, reg, value);
  }
  return UNIT;
}

unit ModelImpl::freg_write_callback(unsigned reg, sbits value) {
  for (auto c : m_callbacks) {
    c->freg_write_callback(*this, reg, value);
  }
  return UNIT;
}

unit ModelImpl::csr_full_write_callback(const_sail_string csr_name, unsigned reg, sbits value) {
  for (auto c : m_callbacks) {
    c->csr_full_write_callback(*this, csr_name, reg, value);
  }
  return UNIT;
}

unit ModelImpl::csr_full_read_callback(const_sail_string csr_name, unsigned reg, sbits value) {
  for (auto c : m_callbacks) {
    c->csr_full_read_callback(*this, csr_name, reg, value);
  }
  return UNIT;
}

unit ModelImpl::vreg_write_callback(unsigned reg, lbits value) {
  for (auto c : m_callbacks) {
    c->vreg_write_callback(*this, reg, value);
  }
  return UNIT;
}

unit ModelImpl::pc_write_callback(sbits new_pc) {
  for (auto c : m_callbacks) {
    c->pc_write_callback(*this, new_pc);
  }
  return UNIT;
}

unit ModelImpl::redirect_callback(sbits new_pc) {
  for (auto c : m_callbacks) {
    c->redirect_callback(*this, new_pc);
  }
  return UNIT;
}

unit ModelImpl::trap_callback(bool is_interrupt, fbits cause) {
  for (auto c : m_callbacks) {
    c->trap_callback(*this, is_interrupt, cause);
  }
  return UNIT;
}

unit ModelImpl::xret_callback(bool is_mret) {
  for (auto c : m_callbacks) {
    c->xret_callback(*this, is_mret);
  }
  return UNIT;
}

unit ModelImpl::instret_callback(unit) {
  for (auto c : m_callbacks) {
    c->instret_callback(*this);
  }
  return UNIT;
}

unit ModelImpl::ptw_start_callback(
  uint64_t vpn,
  hart::zMemoryAccessTypezIEmem_payloadz5zK access_type,
  hart::ztuple_z8z5enumz0zzPrivilegezCz0z5unitz9 privilege
) {
  for (auto c : m_callbacks) {
    c->ptw_start_callback(*this, vpn, access_type, privilege);
  }
  return UNIT;
}

unit ModelImpl::ptw_step_callback(int64_t level, sbits pte_addr, uint64_t pte) {
  for (auto c : m_callbacks) {
    c->ptw_step_callback(*this, level, pte_addr, pte);
  }
  return UNIT;
}

unit ModelImpl::ptw_success_callback(uint64_t final_ppn, int64_t level) {
  for (auto c : m_callbacks) {
    c->ptw_success_callback(*this, final_ppn, level);
  }
  return UNIT;
}

unit ModelImpl::ptw_fail_callback(hart::zPTW_Error error_type, int64_t level, sbits pte_addr) {
  for (auto c : m_callbacks) {
    c->ptw_fail_callback(*this, error_type, level, pte_addr);
  }
  return UNIT;
}

unit ModelImpl::tlb_add_callback(hart::zz5vecz8z5unionz0zzoptionzzIRTLB_EntryzzKz9 tlb, uint64_t index) {
  for (auto c : m_callbacks) {
    c->tlb_add_callback(*this, tlb, index);
  }
  return UNIT;
}

unit ModelImpl::tlb_flush_begin_callback(unit) {
  for (auto c : m_callbacks) {
    c->tlb_flush_begin_callback(*this);
  }
  return UNIT;
}

unit ModelImpl::tlb_flush_callback(uint64_t index) {
  for (auto c : m_callbacks) {
    c->tlb_flush_callback(*this, index);
  }
  return UNIT;
}

unit ModelImpl::tlb_flush_end_callback(hart::zz5vecz8z5unionz0zzoptionzzIRTLB_EntryzzKz9 tlb) {
  for (auto c : m_callbacks) {
    c->tlb_flush_end_callback(*this, tlb);
  }
  return UNIT;
}

// Provides entropy for the scalar cryptography extension.
mach_bits ModelImpl::plat_get_16_random_bits(unit) {
  // This function can be changed to support deterministic sequences of
  // pseudo-random bytes. This is useful for testing.
  return m_gen64();
}

// Note: Store-Conditionals are allowed to spuriously fail. If you want
// that to happen you can spuriously set `reservation_valid = false`
// either directly in `load_reservation()` or by calling
// `cancel_reservation()`.

unit ModelImpl::load_reservation(sbits addr, uint64_t width) {
  m_reservation_addr = addr.bits;
  m_reservation = addr.bits & m_reservation_set_addr_mask;
  m_reservation_valid = true;

  // Ensure the reservation set subsumes the reserved bytes.
  assert((width > 0) && (((addr.bits + width - 1) & m_reservation_set_addr_mask) == m_reservation));

  return UNIT;
}

bool ModelImpl::match_reservation(sbits addr) {
  return m_reservation_valid && (m_reservation_require_exact_addr ? (addr.bits == m_reservation_addr)
                                                                  : (m_reservation & m_reservation_set_addr_mask) ==
                                                                      (addr.bits & m_reservation_set_addr_mask));
}

unit ModelImpl::cancel_reservation(unit) {
  m_reservation_valid = false;
  return UNIT;
}

bool ModelImpl::valid_reservation(unit) {
  return m_reservation_valid;
}

unit ModelImpl::plat_term_write(mach_bits s) {
  char c = static_cast<char>(s);
  if (write(m_term_fd, &c, sizeof(c)) < 0) {
    fprintf(stderr, "Unable to write to terminal!\n");
  }
  return UNIT;
}

bool ModelImpl::sys_enable_experimental_extensions(unit) {
  return m_enable_experimental_extensions;
}

unit ModelImpl::print_string(const_sail_string prefix, const_sail_string msg) {
  printf("%s%s\n", prefix, msg);
  return UNIT;
}

unit ModelImpl::print_log(const_sail_string s) {
  fprintf(trace_log, "%s\n", s);
  return UNIT;
}

unit ModelImpl::print_log_instr(const_sail_string s, uint64_t pc) {
  auto maybe_symbol = symbolize_address(m_symbols, pc);
  if (maybe_symbol.has_value()) {
    fprintf(trace_log, "%-80s    %s+%" PRIu64 "\n", s, maybe_symbol->second.c_str(), pc - maybe_symbol->first);
  } else {
    fprintf(trace_log, "%s\n", s);
  }
  return UNIT;
}

unit ModelImpl::print_step(unit) {
  if (m_config_print_step) {
    fprintf(trace_log, "\n");
  }
  return UNIT;
}

bool ModelImpl::get_config_print_instr(unit) {
  return m_config_print_instr;
}

bool ModelImpl::get_config_print_clint(unit) {
  return m_config_print_clint;
}

bool ModelImpl::get_config_print_exception(unit) {
  return m_config_print_exception;
}

bool ModelImpl::get_config_print_interrupt(unit) {
  return m_config_print_interrupt;
}

bool ModelImpl::get_config_print_htif(unit) {
  return m_config_print_htif;
}

bool ModelImpl::get_config_print_pma(unit) {
  return m_config_print_pma;
}

bool ModelImpl::get_config_rvfi(unit) {
  return m_config_rvfi;
}

bool ModelImpl::get_config_use_abi_names(unit) {
  return m_config_use_abi_names;
}

void ModelImpl::set_config_print_instr(bool on) {
  m_config_print_instr = on;
}

void ModelImpl::set_config_print_clint(bool on) {
  m_config_print_clint = on;
}

void ModelImpl::set_config_print_exception(bool on) {
  m_config_print_exception = on;
}

void ModelImpl::set_config_print_interrupt(bool on) {
  m_config_print_interrupt = on;
}

void ModelImpl::set_config_print_htif(bool on) {
  m_config_print_htif = on;
}

void ModelImpl::set_config_print_pma(bool on) {
  m_config_print_pma = on;
}

void ModelImpl::set_config_rvfi(bool on) {
  m_config_rvfi = on;
}

void ModelImpl::set_config_use_abi_names(bool on) {
  m_config_use_abi_names = on;
}

void ModelImpl::set_config_print_step(bool on) {
  m_config_print_step = on;
}

void ModelImpl::set_elf_symbols(std::map<uint64_t, std::string> symbols) {
  m_symbols = std::move(symbols);
}

void ModelImpl::set_term_fd(int fd) {
  m_term_fd = fd;
}

void ModelImpl::init_platform_constants() {
  set_reservation_set_size_exp(get_config_uint64({"platform", "reservation", "reservation_set_size_exp"}));
  set_reservation_require_exact_addr_match(
    get_config_bool({"platform", "reservation", "require_exact_reservation_addr"})
  );
  set_reservation_invalidate_on_same_hart_store(
    get_config_bool({"platform", "reservation", "invalidate_on_same_hart_store"})
  );
}

void ModelImpl::init_sail(
  uint64_t elf_entry,
  const char *config_file,
  const std::optional<uint64_t> &htif_tohost_address
) {
  // zset_pc_reset_address must be called before zinit_model
  // because reset happens inside init_model().
  zset_pc_reset_address(elf_entry);
  if (htif_tohost_address.has_value()) {
    zenable_htif(*htif_tohost_address);
  }
  zinit_model(config_file != nullptr ? config_file : "");
  zinit_boot_requirements(UNIT);
}

void ModelImpl::reinit_sail(
  uint64_t elf_entry,
  const char *config_file,
  const std::optional<uint64_t> &htif_tohost_address
) {
  model_fini();
  model_init();
  init_sail(elf_entry, config_file, htif_tohost_address);
}

bool ModelImpl::config_is_valid() {
  return zconfig_is_valid(UNIT);
}

bool ModelImpl::dtb_within_configured_pma_memory(uint64_t addr, uint64_t size) {
  return zdtb_within_configured_pma_memory(addr, size);
}

std::string ModelImpl::generate_dts() {
  char *c_dts = nullptr;
  zgenerate_dts(&c_dts, UNIT);
  std::string dts(c_dts);
  KILL(sail_string)(&c_dts);
  return dts;
}

std::string ModelImpl::generate_isa_string() {
  char *c_isa = nullptr;
  zgenerate_canonical_isa_string(&c_isa, UNIT);
  std::string isa(c_isa);
  KILL(sail_string)(&c_isa);
  return isa;
}

void ModelImpl::print_current_exception() {
  if (current_exception != nullptr) {
    zprint_exception(*current_exception);
  }
}

void ModelImpl::tick_clock() {
  ztick_clock(UNIT);
}

bool ModelImpl::try_step(int64_t step_no, bool exit_wait) {
  sail_int sail_step;
  CREATE(sail_int)(&sail_step);
  CONVERT_OF(sail_int, mach_int)(&sail_step, static_cast<mach_int>(step_no));
  bool is_waiting = ztry_step(sail_step, exit_wait);
  KILL(sail_int)(&sail_step);
  return is_waiting;
}

int64_t ModelImpl::xlen() const {
  return zxlen;
}

uint64_t ModelImpl::htif_exit_code() const {
  return zhtif_exit_code;
}

bool ModelImpl::htif_done() const {
  return zhtif_done;
}

bool ModelImpl::had_exception() const {
  return have_exception;
}
