#pragma once

#include "sail.h"

namespace model {
class Model;
}

class callbacks_if {
public:
  virtual ~callbacks_if() = default;

  // TODO: finding ways to improve the format
  virtual void mem_write_callback(model::Model &model, const char *type,
                                  sbits paddr, uint64_t width, lbits value)
      = 0;
  virtual void mem_read_callback(model::Model &model, const char *type,
                                 sbits paddr, uint64_t width, lbits value)
      = 0;
  virtual void mem_exception_callback(model::Model &model, sbits paddr,
                                      uint64_t num_of_exception)
      = 0;
  virtual void xreg_full_write_callback(model::Model &model,
                                        const_sail_string abi_name, sbits reg,
                                        sbits value)
      = 0;
  virtual void freg_write_callback(model::Model &model, unsigned reg,
                                   sbits value)
      = 0;
  virtual void csr_full_write_callback(model::Model &model,
                                       const_sail_string csr_name, unsigned reg,
                                       sbits value)
      = 0;
  virtual void csr_full_read_callback(model::Model &model,
                                      const_sail_string csr_name, unsigned reg,
                                      sbits value)
      = 0;
  virtual void vreg_write_callback(model::Model &model, unsigned reg,
                                   lbits value)
      = 0;
  virtual void pc_write_callback(model::Model &model, sbits value) = 0;
  virtual void trap_callback(model::Model &model) = 0;
};
