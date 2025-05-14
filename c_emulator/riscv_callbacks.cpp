#include "riscv_callbacks.h"
#include "riscv_config.h"
#include "riscv_platform_impl.h"
#include "riscv_sail.h"
#include <stdlib.h>
#include <vector>
#include <inttypes.h>

void print_lbits_hex(lbits val, int length = 0)
{
  if (length == 0) {
    length = val.len;
  }
  std::vector<uint8_t> data(length);
  mpz_export(data.data(), nullptr, -1, 1, 0, 0, *val.bits);
  for (int i = length - 1; i >= 0; --i) {
    fprintf(trace_log, "%02" PRIX8, data[i]);
  }
  fprintf(trace_log, "\n");
}

// Implementations of default callbacks for trace printing and RVFI.
// The model assumes that these functions do not change the state of the model.
unit mem_write_callback(const char *type, uint64_t paddr, uint64_t width,
                        lbits value)
{
  if (config_print_mem_access) {
    fprintf(trace_log, "mem[%s,0x%0*" PRIX64 "] <- 0x", type,
            zxlen == 64 ? 16 : 9, paddr);
    print_lbits_hex(value, width);
  }
  if (config_enable_rvfi) {
    zrvfi_write(paddr, width, value);
  }
  return UNIT;
}

unit mem_read_callback(const char *type, uint64_t paddr, uint64_t width,
                       lbits value)
{
  if (config_print_mem_access) {
    fprintf(trace_log, "mem[%s,0x%0*" PRIX64 "] -> 0x", type,
            zxlen == 64 ? 16 : 9, paddr);
    print_lbits_hex(value, width);
  }
  if (config_enable_rvfi) {
    sail_int len;
    CREATE(sail_int)(&len);
    CONVERT_OF(sail_int, mach_int)(&len, width);
    zrvfi_read(paddr, len, value);
    KILL(sail_int)(&len);
  }
  return UNIT;
}

unit mem_exception_callback(uint64_t paddr, uint64_t num_of_exception)
{
  (void)num_of_exception;
  if (config_enable_rvfi) {
    zrvfi_mem_exception(paddr);
  }
  return UNIT;
}

unit xreg_write_callback(unsigned reg, uint64_t value)
{
  if (config_print_reg) {
    fprintf(trace_log, "x%d <- 0x%016" PRIX64 "\n", reg, value);
  }
  if (config_enable_rvfi) {
    zrvfi_wX(reg, value);
  }
  return UNIT;
}

unit freg_write_callback(unsigned reg, uint64_t value)
{
  // TODO: will only print bits; should we print in floating point format?
  if (config_print_reg) {
    fprintf(trace_log, "f%d <- 0x%016" PRIX64 "\n", reg, value);
  }
  return UNIT;
}

unit csr_full_write_callback(const_sail_string csr_name, unsigned reg,
                             uint64_t value)
{
  if (config_print_reg) {
    fprintf(trace_log, "CSR %s (0x%03X) <- 0x%016" PRIX64 "\n", csr_name, reg,
            value);
  }
  return UNIT;
}

unit csr_full_read_callback(const_sail_string csr_name, unsigned reg,
                            uint64_t value)
{
  if (config_print_reg) {
    fprintf(trace_log, "CSR %s (0x%03X) -> 0x%016" PRIX64 "\n", csr_name, reg,
            value);
  }
  return UNIT;
}

unit vreg_write_callback(unsigned reg, lbits value)
{
  if (config_print_reg) {
    fprintf(trace_log, "v%d <- ", reg);
    // TODO: the width of `value` is currently `vlenmax` bits which can be much
    // greater than VLEN. In future we will remove `vlenmax`, then we can remove
    // the `zVLEN / 8` argument here.
    print_lbits_hex(value, zVLEN / 8);
  }
  return UNIT;
}

unit pc_write_callback(uint64_t value)
{
  (void)value;
  return UNIT;
}

unit trap_callback(unit)
{
  if (config_enable_rvfi) {
    zrvfi_trap(UNIT);
  }
  return UNIT;
}
