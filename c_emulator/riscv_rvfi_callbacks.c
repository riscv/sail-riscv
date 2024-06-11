int zrvfi_write(uint64_t addr, int64_t width, lbits value, bool is_exception);
int zrvfi_read(uint64_t addr, sail_int width, lbits value, bool is_exception);
int zrvfi_wX(int64_t reg, uint64_t value);

int mem_update_callback(uint64_t addr, uint64_t width, lbits value,
                        bool is_exception)
{
  zrvfi_write(addr, width, value, is_exception);
}
int mem_read_callback(uint64_t addr, uint64_t width, lbits value,
                      bool is_exception)
{
  sail_int len;
  CREATE(sail_int)(&len);
  CONVERT_OF(sail_int, mach_int)(&len, width);
  zrvfi_read(addr, len, value, is_exception);
  KILL(sail_int)(&len);
}
int xreg_update_callback(unsigned reg, uint64_t value)
{
  zrvfi_wX(reg, value);
}
int freg_update_callback(unsigned reg, uint64_t value) { }
int csr_update_callback(const char *reg_name, uint64_t value) { }
int csr_read_callback(const char *reg_name, uint64_t value) { }
int vreg_update_callback(unsigned reg, lbits value) { }
int pc_update_callback(uint64_t value) { }
