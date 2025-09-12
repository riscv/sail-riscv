#include "riscv_model_impl.h"
#include <algorithm>
#include <random>
#include <unistd.h>

#include "riscv_callbacks_if.h"
#include "symbol_table.h"
#include "riscv_config.h"

bool rv_enable_experimental_extensions = false;

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

unit ModelImpl::pc_write_callback(sbits value)
{
  for (auto c : m_callbacks) {
    c->pc_write_callback(*this, value);
  }
  return UNIT;
}

unit ModelImpl::trap_callback(unit)
{
  for (auto c : m_callbacks) {
    c->trap_callback(*this);
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

unit ModelImpl::load_reservation(sbits addr)
{
  m_reservation = addr.bits;
  m_reservation_valid = true;
  return UNIT;
}

static mach_bits check_mask()
{
  return -1;
  // return (zxlen == 32) ? 0x00000000FFFFFFFF : -1;
}

bool ModelImpl::match_reservation(sbits addr)
{
  mach_bits mask = check_mask();
  bool ret
      = m_reservation_valid && (m_reservation & mask) == (addr.bits & mask);
  return ret;
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
  char c = s & 0xff;
  plat_term_write_impl(c);
  return UNIT;
}

bool ModelImpl::sys_enable_experimental_extensions(unit)
{
  return rv_enable_experimental_extensions;
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
  if (config_print_step)
    fprintf(trace_log, "\n");
  return UNIT;
}

bool ModelImpl::get_config_print_instr(unit)
{
  return config_print_instr;
}

bool ModelImpl::get_config_print_platform(unit)
{
  return config_print_platform;
}

bool ModelImpl::get_config_rvfi(unit)
{
  return config_enable_rvfi;
}

bool ModelImpl::get_config_use_abi_names(unit)
{
  return config_use_abi_names;
}
