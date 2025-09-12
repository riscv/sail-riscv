#include "riscv_config.h"
#include "riscv_callbacks_rvfi.h"
#include <stdlib.h>
#include <inttypes.h>

#include "riscv_sail.h"

// Implementations of default callbacks for RVFI.
// The model assumes that these functions do not change the state of the model.
void rvfi_callbacks::mem_write_callback(model::Model &model, const char *,
                                        sbits paddr, uint64_t width,
                                        lbits value)
{
  if (config_enable_rvfi) {
    model.zrvfi_write(paddr, width, value);
  }
}

void rvfi_callbacks::mem_read_callback(model::Model &model, const char *,
                                       sbits paddr, uint64_t width, lbits value)
{
  if (config_enable_rvfi) {
    sail_int len;
    CREATE(sail_int)(&len);
    CONVERT_OF(sail_int, mach_int)(&len, width);
    model.zrvfi_read(paddr, len, value);
    KILL(sail_int)(&len);
  }
}

void rvfi_callbacks::mem_exception_callback(model::Model &model, sbits paddr,
                                            uint64_t)
{
  if (config_enable_rvfi) {
    model.zrvfi_mem_exception(paddr);
  }
}

void rvfi_callbacks::xreg_full_write_callback(model::Model &model,
                                              const_sail_string, sbits reg,
                                              sbits value)
{
  if (config_enable_rvfi) {
    model.zrvfi_wX(reg.bits, value);
  }
}

void rvfi_callbacks::freg_write_callback(model::Model &model, unsigned, sbits)
{
  (void)model;
}

void rvfi_callbacks::csr_full_write_callback(model::Model &model,
                                             const_sail_string, unsigned, sbits)
{
  (void)model;
}

void rvfi_callbacks::csr_full_read_callback(model::Model &model,
                                            const_sail_string, unsigned, sbits)
{
  (void)model;
}

void rvfi_callbacks::vreg_write_callback(model::Model &model, unsigned, lbits)
{
  (void)model;
}

void rvfi_callbacks::pc_write_callback(model::Model &model, sbits)
{
  (void)model;
}

void rvfi_callbacks::trap_callback(model::Model &model)
{
  if (config_enable_rvfi) {
    model.zrvfi_trap(UNIT);
  }
}
