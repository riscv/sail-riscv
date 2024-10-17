#include "riscv_config.h"

int zrvfi_write(uint64_t addr, int64_t width, lbits value);
int zrvfi_read(uint64_t addr, sail_int width, lbits value);
int zrvfi_mem_exception(uint64_t addr);
int zrvfi_wX(int64_t reg, uint64_t value);

int mem_write_callback(uint64_t addr, uint64_t width, lbits value)
{
  if (rv_enable_callbacks)
    zrvfi_write(addr, width, value);
}
int mem_read_callback(const char *type, uint64_t addr, uint64_t width,
                      lbits value)
{
  if (rv_enable_callbacks) {
    sail_int len;
    CREATE(sail_int)(&len);
    CONVERT_OF(sail_int, mach_int)(&len, width);
    zrvfi_read(addr, len, value);
    KILL(sail_int)(&len);
  }
}
int mem_exception_callback(uint64_t addr, uint64_t num_of_exception)
{
  if (rv_enable_callbacks)
    zrvfi_mem_exception(addr);
}
int xreg_write_callback(unsigned reg, uint64_t value)
{
  if (rv_enable_callbacks)
    zrvfi_wX(reg, value);
}
int freg_write_callback(unsigned reg, uint64_t value) { }
int csr_write_callback(unsigned reg, uint64_t value) { }
int csr_read_callback(unsigned reg, uint64_t value) { }
int vreg_write_callback(unsigned reg, lbits value) { }
int pc_write_callback(uint64_t value) { }
