#include "riscv_callbacks_rvfi.h"
#include "riscv_config.h"
#include <inttypes.h>
#include <stdlib.h>

#include "sail_riscv_model.h"

// Implementations of default callbacks for RVFI.
// The model assumes that these functions do not change the state of the model.

void rvfi_callbacks::mem_write_callback(hart::Model &model, const char *, sbits paddr, uint64_t width, lbits value) {
  if (config_enable_rvfi) {
    model.zrvfi_write(paddr, width, value);
  }
}

void rvfi_callbacks::mem_read_callback(hart::Model &model, const char *, sbits paddr, uint64_t width, lbits value) {
  if (config_enable_rvfi) {
    sail_int len;
    CREATE(sail_int)(&len);
    CONVERT_OF(sail_int, mach_int)(&len, width);
    model.zrvfi_read(paddr, len, value);
    KILL(sail_int)(&len);
  }
}

void rvfi_callbacks::mem_exception_callback(hart::Model &model, sbits paddr, uint64_t) {
  if (config_enable_rvfi) {
    model.zrvfi_mem_exception(paddr);
  }
}

void rvfi_callbacks::xreg_full_write_callback(hart::Model &model, const_sail_string, sbits reg, sbits value) {
  if (config_enable_rvfi) {
    model.zrvfi_wX(reg.bits, value);
  }
}

void rvfi_callbacks::trap_callback(
    hart::Model &model, bool is_interrupt, fbits cause,
    [[maybe_unused]] const hart::zTrapReason &reason)
{
  (void)is_interrupt;
  (void)cause;
  if (config_enable_rvfi) {
    model.zrvfi_trap(UNIT);
  }
}
