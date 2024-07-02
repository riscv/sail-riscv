/* The model assumes that these functions do not change the state of the model.
 */
int mem_update_callback(uint64_t addr, uint64_t width, lbits value,
                        bool is_exception)
{
}
int mem_read_callback(uint64_t addr, uint64_t width, lbits value,
                      bool is_exception)
{
}
int xreg_update_callback(unsigned reg, uint64_t value) { }
int freg_update_callback(unsigned reg, uint64_t value) { }
int csr_update_callback(const char *reg_name, uint64_t value) { }
int csr_read_callback(const char *reg_name, uint64_t value) { }
int vreg_update_callback(unsigned reg, lbits value) { }
int pc_update_callback(uint64_t value) { }
