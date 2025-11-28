#include "riscv_callbacks_if.h"
#include "riscv_callbacks.h"
#include <vector>
#include <algorithm>

std::vector<callbacks_if *> callbacks;

void register_callback(callbacks_if *cb)
{
  if (std::find(callbacks.begin(), callbacks.end(), cb) == callbacks.end()) {
    callbacks.push_back(cb);
  }
}

void remove_callback(callbacks_if *cb)
{
  callbacks.erase(std::remove(callbacks.begin(), callbacks.end(), cb),
                  callbacks.end());
}

// Invoke pre_step_callback on all registered callbacks before each step.
void call_pre_step_callbacks(bool is_waiting)
{
  for (auto c : callbacks) {
    c->pre_step_callback(is_waiting);
  }
}

// Invoke post_step_callback on all registered callbacks after each step.
void call_post_step_callbacks(bool is_waiting)
{
  for (auto c : callbacks) {
    c->post_step_callback(is_waiting);
  }
}

unit fetch_callback(sbits opcode)
{
  for (auto c : callbacks) {
    c->fetch_callback(opcode);
  }
  return UNIT;
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

unit xreg_full_write_callback(const_sail_string abi_name, sbits reg,
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

unit pc_write_callback(sbits new_pc)
{
  for (auto c : callbacks) {
    c->pc_write_callback(new_pc);
  }
  return UNIT;
}

unit redirect_callback(sbits new_pc)
{
  for (auto c : callbacks) {
    c->redirect_callback(new_pc);
  }
  return UNIT;
}

unit trap_callback(bool is_interrupt, fbits cause)
{
  for (auto c : callbacks) {
    c->trap_callback(is_interrupt, cause);
  }
  return UNIT;
}
