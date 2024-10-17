#include "riscv_config.h"
#include <stdlib.h>

void zcsr_name_map_forwards(sail_string *rop, uint64_t);

static uint8_t *get_lbits_data(lbits val)
{
  uint8_t *data = (uint8_t *)calloc(val.len, sizeof(uint8_t));
  mpz_export(data, NULL, -1, 1, 0, 0, val.bits);
  return data;
}

/* Implementations of default callbacks for trace printing.
 *
 * The model assumes that these functions do not change the state of the model.
 */
int mem_write_callback(uint64_t addr, uint64_t width, lbits value)
{
  if (config_print_mem_access) {
    char *lbits_data = get_lbits_data(value);
    printf("mem[0x%.16lX] <- 0x", addr);
    for (int i = width - 1; i >= 0; --i)
      printf("%02hhX", lbits_data[i]);
    printf("\n");
    free(lbits_data);
  }
}

int mem_read_callback(const char *type, uint64_t addr, uint64_t width,
                      lbits value)
{
  if (config_print_mem_access) {
    char *lbits_data = get_lbits_data(value);
    printf("mem[%s,0x%.16lX] -> 0x", type, addr);
    for (int i = width - 1; i >= 0; --i)
      printf("%02hhX", lbits_data[i]);
    printf("\n");
    free(lbits_data);
  }
}

int mem_exception_callback(uint64_t addr, uint64_t num_of_exception) { }

int xreg_write_callback(unsigned reg, uint64_t value)
{
  if (config_print_reg)
    printf("x%d <- 0x%.16lX\n", reg, value);
}

int freg_write_callback(unsigned reg, uint64_t value)
{
  /* TODO: will only print bits; should we print in floating point format? */
  if (config_print_reg)
    printf("f%d <- 0x%.16lX\n", reg, value);
}

int csr_write_callback(unsigned reg, uint64_t value)
{
  if (config_print_reg) {
    sail_string csr_name;
    CREATE(sail_string)(&csr_name);
    zcsr_name_map_forwards(&csr_name, reg);
    printf("CSR %s <- 0x%.16lX (input: 0x%.16lX)\n", csr_name, value, value);
    KILL(sail_string)(&csr_name);
  }
}

int csr_read_callback(unsigned reg, uint64_t value)
{
  if (config_print_reg) {
    sail_string csr_name;
    CREATE(sail_string)(&csr_name);
    zcsr_name_map_forwards(&csr_name, reg);
    printf("CSR %s -> 0x%.16lX\n", csr_name, value);
    KILL(sail_string)(&csr_name);
  }
}

int vreg_write_callback(unsigned reg, lbits value)
{
  if (config_print_reg) {
    char *lbits_data = get_lbits_data(value);
    printf("v%d <- ", reg);
    for (int i = value.len - 1; i >= 0; --i)
      printf("%02hhX", lbits_data[i]);
    printf("\n");
    free(lbits_data);
  }
}

int pc_write_callback(uint64_t value) { }
