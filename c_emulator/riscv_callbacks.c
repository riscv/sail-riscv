#include "riscv_callbacks.h"

#include "riscv_config.h"
#include <stdlib.h>

#ifdef RVFI_DII
// TODO: Move these implementations to C.
unit zrvfi_write(uint64_t addr, int64_t width, lbits value);
unit zrvfi_read(uint64_t addr, sail_int width, lbits value);
unit zrvfi_mem_exception(uint64_t addr);
unit zrvfi_wX(int64_t reg, uint64_t value);
#endif

void zcsr_name_map_forwards(sail_string *rop, uint64_t);

static uint8_t *get_lbits_data(lbits val)
{
  uint8_t *data = (uint8_t *)calloc(val.len, sizeof(uint8_t));
  mpz_export(data, NULL, -1, 1, 0, 0, *val.bits);
  return data;
}

// Implementations of default callbacks for trace printing.
//
// The model assumes that these functions do not change the state of the model.
unit mem_write_callback(uint64_t addr, uint64_t width, lbits value)
{
  if (config_print_mem_access) {
    uint8_t *lbits_data = get_lbits_data(value);
    printf("mem[0x%.16lX] <- 0x", addr);
    for (int i = width - 1; i >= 0; --i)
      printf("%02hhX", lbits_data[i]);
    printf("\n");
    free(lbits_data);
  }
#ifdef RVFI_DII
  zrvfi_write(addr, width, value);
#endif
  return UNIT;
}

unit mem_read_callback(const char *type, uint64_t addr, uint64_t width,
                       lbits value)
{
  if (config_print_mem_access) {
    uint8_t *lbits_data = get_lbits_data(value);
    printf("mem[%s,0x%.16lX] -> 0x", type, addr);
    for (int i = width - 1; i >= 0; --i)
      printf("%02hhX", lbits_data[i]);
    printf("\n");
    free(lbits_data);
  }
#ifdef RVFI_DII
  sail_int len;
  CREATE(sail_int)(&len);
  CONVERT_OF(sail_int, mach_int)(&len, width);
  zrvfi_read(addr, len, value);
  KILL(sail_int)(&len);
#endif
  return UNIT;
}

unit mem_exception_callback(uint64_t addr, uint64_t num_of_exception)
{
#ifdef RVFI_DII
  zrvfi_mem_exception(addr);
#endif
  return UNIT;
}

unit xreg_write_callback(unsigned reg, uint64_t value)
{
  if (config_print_reg) {
    printf("x%d <- 0x%.16lX\n", reg, value);
  }
#ifdef RVFI_DII
  zrvfi_wX(reg, value);
#endif
  return UNIT;
}

unit freg_write_callback(unsigned reg, uint64_t value)
{
  // TODO: will only print bits; should we print in floating point format?
  if (config_print_reg) {
    printf("f%d <- 0x%.16lX\n", reg, value);
  }
  return UNIT;
}

unit csr_write_callback(unsigned reg, uint64_t value)
{
  if (config_print_reg) {
    sail_string csr_name;
    CREATE(sail_string)(&csr_name);
    zcsr_name_map_forwards(&csr_name, reg);
    printf("CSR %s <- 0x%.16lX (input: 0x%.16lX)\n", csr_name, value, value);
    KILL(sail_string)(&csr_name);
  }
  return UNIT;
}

unit csr_read_callback(unsigned reg, uint64_t value)
{
  if (config_print_reg) {
    sail_string csr_name;
    CREATE(sail_string)(&csr_name);
    zcsr_name_map_forwards(&csr_name, reg);
    printf("CSR %s -> 0x%.16lX\n", csr_name, value);
    KILL(sail_string)(&csr_name);
  }
  return UNIT;
}

unit vreg_write_callback(unsigned reg, lbits value)
{
  if (config_print_reg) {
    uint8_t *lbits_data = get_lbits_data(value);
    printf("v%d <- ", reg);
    for (int i = value.len - 1; i >= 0; --i)
      printf("%02hhX", lbits_data[i]);
    printf("\n");
    free(lbits_data);
  }
  return UNIT;
}

unit pc_write_callback(uint64_t value)
{
  return UNIT;
}
