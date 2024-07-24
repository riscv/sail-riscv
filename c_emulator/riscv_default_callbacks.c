/* The model assumes that these functions do not change the state of the model.
 */
int mem_write_callback(uint64_t addr, uint64_t width, lbits value) { }
int mem_read_callback(uint64_t addr, uint64_t width, lbits value) { }
int mem_exception_callback(uint64_t addr, uint64_t num_of_exception) { }
int xreg_write_callback(unsigned reg, uint64_t value) { }
int freg_write_callback(unsigned reg, uint64_t value) { }
int csr_write_callback(unsigned reg, uint64_t value) { }
int csr_read_callback(unsigned reg, uint64_t value) { }
int vreg_write_callback(unsigned reg, lbits value) { }
int pc_write_callback(uint64_t value) { }
