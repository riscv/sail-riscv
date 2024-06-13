/* The model assumes that these functions do not change the state of the model.
 */
int __attribute__((weak))
mem_update_callback(uint64_t addr, uint64_t width, lbits data)
{
}
int __attribute__((weak)) xreg_update_callback(unsigned reg, uint64_t value) { }
int __attribute__((weak)) freg_update_callback(unsigned reg, uint64_t value) { }
int __attribute__((weak))
csr_update_callback(const char *reg_name, uint64_t value)
{
}
int __attribute__((weak))
csr_read_callback(const char *reg_name, uint64_t value)
{
}
int __attribute__((weak)) vreg_update_callback(unsigned reg, lbits value) { }
int __attribute__((weak)) pc_update_callback(uint64_t value) { }
