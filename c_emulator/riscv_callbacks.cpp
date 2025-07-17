#include "riscv_callbacks_if.h"
#include "riscv_callbacks.h"
#include <set>

std::set<callbacks_if *> callbacks;

void register_callback_if(callbacks_if *cbi)
{
  callbacks.insert(cbi);
}

void remove_callback_if(callbacks_if *cbi)
{
  callbacks.erase(cbi);
}

unit mem_write_callback(const char *type, sbits paddr, uint64_t width,
                        lbits value)
{
  for (auto c : callbacks) {
    c->mem_write_callback(type, paddr, width, value);
  }
  return UNIT;
}
unit mem_read_callback(const char *type, sbits paddr, uint64_t width,
                       lbits value)
{
  for (auto c : callbacks) {
    c->mem_read_callback(type, paddr, width, value);
  }
  return UNIT;
}

unit mem_exception_callback(sbits paddr, uint64_t num_of_exception)
{
  for (auto c : callbacks) {
    c->mem_exception_callback(paddr, num_of_exception);
  }
  return UNIT;
}

unit xreg_full_write_callback(const_sail_string abi_name, unsigned reg,
                              sbits value)
{
  for (auto c : callbacks) {
    c->xreg_full_write_callback(abi_name, reg, value);
  }
  return UNIT;
}

unit freg_write_callback(unsigned reg, sbits value)
{
  for (auto c : callbacks) {
    c->freg_write_callback(reg, value);
  }
  return UNIT;
}

unit csr_full_write_callback(const_sail_string csr_name, unsigned reg,
                             sbits value)
{
  for (auto c : callbacks) {
    c->csr_full_write_callback(csr_name, reg, value);
  }
  return UNIT;
}

unit csr_full_read_callback(const_sail_string csr_name, unsigned reg,
                            sbits value)
{
  for (auto c : callbacks) {
    c->csr_full_read_callback(csr_name, reg, value);
  }
  return UNIT;
}

unit vreg_write_callback(unsigned reg, lbits value)
{
  for (auto c : callbacks) {
    c->vreg_write_callback(reg, value);
  }
  return UNIT;
}

unit pc_write_callback(sbits value)
{
  for (auto c : callbacks) {
    c->pc_write_callback(value);
  }
  return UNIT;
}

unit trap_callback(unit)
{
  for (auto c : callbacks) {
    c->trap_callback();
  }
  return UNIT;
}
