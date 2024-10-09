#include "riscv_config.h"

int zmem_write_callback_default(long unsigned int addr, long int width, lbits value);
int zmem_read_callback_default(const char *type, long unsigned int addr,
                               long int width, lbits value);
int zxreg_write_callback_default(long unsigned int reg, long unsigned int value);
int zfreg_write_callback_default(long unsigned int reg, long unsigned int value);
int zcsr_write_callback_default(long unsigned int reg, long unsigned int value);
int zcsr_read_callback_default(long unsigned int reg, long unsigned int value);
int zvreg_write_callback_default(long unsigned int reg, lbits value);

/* The model assumes that these functions do not change the state of the model.
 */
int mem_write_callback(uint64_t addr, uint64_t width, lbits value) {
  if (config_print_mem_access)
    zmem_write_callback_default(addr, width, value);
}

int mem_read_callback(const char *type, uint64_t addr, uint64_t width,
                      lbits value)
{
  if (config_print_mem_access)
    zmem_read_callback_default(type, addr, width, value);
}

int mem_exception_callback(uint64_t addr, uint64_t num_of_exception) { }

int xreg_write_callback(unsigned reg, uint64_t value) { 
  if (config_print_reg)
    zxreg_write_callback_default(reg, value);
}

int freg_write_callback(unsigned reg, uint64_t value) {
  /* TODO: will only print bits; should we print in floating point format? */
  if (config_print_reg)
    zfreg_write_callback_default(reg, value);
}

int csr_write_callback(unsigned reg, uint64_t value) {
  if (config_print_reg)
    zcsr_write_callback_default(reg, value);
}

int csr_read_callback(unsigned reg, uint64_t value) {
  if (config_print_reg)
    zcsr_read_callback_default(reg, value);
}

int vreg_write_callback(unsigned reg, lbits value) {
  if (config_print_reg)
    zvreg_write_callback_default(reg, value);
}

int pc_write_callback(uint64_t value) { }
