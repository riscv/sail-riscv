#include "riscv_model_impl.h"
#include <algorithm>
#include <cassert>
#include <random>
#include <unistd.h>

#include "riscv_callbacks_if.h"
#include "symbol_table.h"
#include "riscv_config.h"

int term_fd = 1; // set during startup
void plat_term_write_impl(char c)
{
  if (write(term_fd, &c, sizeof(c)) < 0) {
    fprintf(stderr, "Unable to write to terminal!\n");
  }
}

void ModelImpl::register_callback(callbacks_if *cb)
{
  if (std::find(m_callbacks.begin(), m_callbacks.end(), cb)
      == m_callbacks.end()) {
    m_callbacks.push_back(cb);
  }
}

void ModelImpl::remove_callback(callbacks_if *cb)
{
  m_callbacks.erase(std::remove(m_callbacks.begin(), m_callbacks.end(), cb),
                    m_callbacks.end());
}

void ModelImpl::call_pre_step_callbacks(bool is_waiting)
{
  for (auto c : m_callbacks) {
    c->pre_step_callback(*this, is_waiting);
  }
}

void ModelImpl::call_post_step_callbacks(bool is_waiting)
{
  for (auto c : m_callbacks) {
    c->post_step_callback(*this, is_waiting);
  }
}

void ModelImpl::set_enable_experimental_extensions(bool en)
{
  m_enable_experimental_extensions = en;
}

void ModelImpl::set_reservation_set_size_exp(uint64_t exponent)
{
  m_reservation_set_addr_mask = ~((1 << exponent) - 1);
}

unit ModelImpl::fetch_callback(sbits opcode)
{
  for (auto c : m_callbacks) {
    c->fetch_callback(*this, opcode);
  }
  return UNIT;
}

unit ModelImpl::mem_write_callback(const char *type, sbits paddr,
                                   uint64_t width, lbits value)
{
  for (auto c : m_callbacks) {
    c->mem_write_callback(*this, type, paddr, width, value);
  }
  return UNIT;
}
unit ModelImpl::mem_read_callback(const char *type, sbits paddr, uint64_t width,
                                  lbits value)
{
  for (auto c : m_callbacks) {
    c->mem_read_callback(*this, type, paddr, width, value);
  }
  return UNIT;
}

unit ModelImpl::mem_exception_callback(sbits paddr, uint64_t num_of_exception)
{
  for (auto c : m_callbacks) {
    c->mem_exception_callback(*this, paddr, num_of_exception);
  }
  return UNIT;
}

unit ModelImpl::xreg_full_write_callback(const_sail_string abi_name, sbits reg,
                                         sbits value)
{
  for (auto c : m_callbacks) {
    c->xreg_full_write_callback(*this, abi_name, reg, value);
  }
  return UNIT;
}

unit ModelImpl::freg_write_callback(unsigned reg, sbits value)
{
  for (auto c : m_callbacks) {
    c->freg_write_callback(*this, reg, value);
  }
  return UNIT;
}

unit ModelImpl::csr_full_write_callback(const_sail_string csr_name,
                                        unsigned reg, sbits value)
{
  for (auto c : m_callbacks) {
    c->csr_full_write_callback(*this, csr_name, reg, value);
  }
  return UNIT;
}

unit ModelImpl::csr_full_read_callback(const_sail_string csr_name, unsigned reg,
                                       sbits value)
{
  for (auto c : m_callbacks) {
    c->csr_full_read_callback(*this, csr_name, reg, value);
  }
  return UNIT;
}

unit ModelImpl::vreg_write_callback(unsigned reg, lbits value)
{
  for (auto c : m_callbacks) {
    c->vreg_write_callback(*this, reg, value);
  }
  return UNIT;
}

unit ModelImpl::pc_write_callback(sbits new_pc)
{
  for (auto c : m_callbacks) {
    c->pc_write_callback(*this, new_pc);
  }
  return UNIT;
}

unit ModelImpl::redirect_callback(sbits new_pc)
{
  for (auto c : m_callbacks) {
    c->redirect_callback(*this, new_pc);
  }
  return UNIT;
}

unit ModelImpl::trap_callback(bool is_interrupt, fbits cause)
{
  for (auto c : m_callbacks) {
    c->trap_callback(*this, is_interrupt, cause);
  }
  return UNIT;
}

// Provides entropy for the scalar cryptography extension.
mach_bits ModelImpl::plat_get_16_random_bits(unit)
{
  // This function can be changed to support deterministic sequences of
  // pseudo-random bytes. This is useful for testing.
  return m_gen64();
}

// Note: Store-Conditionals are allowed to spuriously fail. If you want
// that to happen you can spuriously set `reservation_valid = false`
// either directly in `load_reservation()` or by calling
// `cancel_reservation()`.

unit ModelImpl::load_reservation(sbits addr, uint64_t width)
{
  m_reservation = addr.bits & m_reservation_set_addr_mask;
  m_reservation_valid = true;

  // Ensure the reservation set subsumes the reserved bytes.
  assert((width > 0)
         && (((addr.bits + width - 1) & m_reservation_set_addr_mask)
             == m_reservation));

  return UNIT;
}

bool ModelImpl::match_reservation(sbits addr)
{
  return m_reservation_valid
      && (m_reservation & m_reservation_set_addr_mask)
      == (addr.bits & m_reservation_set_addr_mask);
}

unit ModelImpl::cancel_reservation(unit)
{
  m_reservation_valid = false;
  return UNIT;
}

bool ModelImpl::valid_reservation(unit)
{
  return m_reservation_valid;
}

unit ModelImpl::plat_term_write(mach_bits s)
{
  plat_term_write_impl(static_cast<char>(s));
  return UNIT;
}

bool ModelImpl::sys_enable_experimental_extensions(unit)
{
  return m_enable_experimental_extensions;
}

unit ModelImpl::print_string(const_sail_string prefix, const_sail_string msg)
{
  printf("%s%s\n", prefix, msg);
  return UNIT;
}

unit ModelImpl::print_log(const_sail_string s)
{
  fprintf(trace_log, "%s\n", s);
  return UNIT;
}

unit ModelImpl::print_log_instr(const_sail_string s, uint64_t pc)
{
  auto maybe_symbol = symbolize_address(g_symbols, pc);
  if (maybe_symbol.has_value()) {
    fprintf(trace_log, "%-80s    %s+%" PRIu64 "\n", s,
            maybe_symbol->second.c_str(), pc - maybe_symbol->first);
  } else {
    fprintf(trace_log, "%s\n", s);
  }
  return UNIT;
}

unit ModelImpl::print_step(unit)
{
  if (config_print_step) {
    fprintf(trace_log, "\n");
  }
  return UNIT;
}

bool ModelImpl::get_config_print_instr(unit)
{
  return config_print_instr;
}

bool ModelImpl::get_config_print_clint(unit)
{
  return config_print_clint;
}
bool ModelImpl::get_config_print_exception(unit)
{
  return config_print_exception;
}
bool ModelImpl::get_config_print_interrupt(unit)
{
  return config_print_interrupt;
}
bool ModelImpl::get_config_print_htif(unit)
{
  return config_print_htif;
}
bool ModelImpl::get_config_print_pma(unit)
{
  return config_print_pma;
}

bool ModelImpl::get_config_rvfi(unit)
{
  return config_enable_rvfi;
}

bool ModelImpl::get_config_use_abi_names(unit)
{
  return config_use_abi_names;
}
