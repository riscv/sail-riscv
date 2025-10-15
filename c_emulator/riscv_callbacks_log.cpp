#include "riscv_config.h"
#include "riscv_callbacks_log.h"
#include "riscv_sail.h"
#include <stdlib.h>
#include <vector>
#include <inttypes.h>

void print_lbits_hex(FILE *trace_log, lbits val, int length = 0)
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

log_callbacks::log_callbacks(bool config_print_reg,
                             bool config_print_mem_access,
                             bool config_use_abi_names, FILE *trace_log)
    : config_print_reg(config_print_reg)
    , config_print_mem_access(config_print_mem_access)
    , config_use_abi_names(config_use_abi_names)
    , trace_log(trace_log)
{
}

// Implementations of default callbacks for trace printing.
// The model assumes that these functions do not change the state of the model.

void log_callbacks::mem_write_callback(model::Model &model, const char *type,
                                       sbits paddr, uint64_t width, lbits value)
{
  if (trace_log != nullptr && config_print_mem_access) {
    fprintf(trace_log, "mem[%s,0x%0*" PRIX64 "] <- 0x", type,
            static_cast<int>((model.zphysaddrbits_len + 3) / 4), paddr.bits);
    print_lbits_hex(trace_log, value, width);
  }
}

void log_callbacks::mem_read_callback(model::Model &model, const char *type,
                                      sbits paddr, uint64_t width, lbits value)
{
  if (trace_log != nullptr && config_print_mem_access) {
    fprintf(trace_log, "mem[%s,0x%0*" PRIX64 "] -> 0x", type,
            static_cast<int>((model.zphysaddrbits_len + 3) / 4), paddr.bits);
    print_lbits_hex(trace_log, value, width);
  }
}

void log_callbacks::mem_exception_callback(model::Model &model, sbits, uint64_t)
{
  (void)model;
}

void log_callbacks::xreg_full_write_callback(model::Model &model,
                                             const_sail_string abi_name,
                                             sbits reg, sbits value)
{
  (void)model;
  if (trace_log != nullptr && config_print_reg) {
    if (config_use_abi_names) {
      fprintf(trace_log, "%s <- 0x%0*" PRIX64 "\n", abi_name,
              static_cast<int>(value.len / 4), value.bits);
    } else {
      fprintf(trace_log, "x%" PRIu64 " <- 0x%0*" PRIX64 "\n", reg.bits,
              static_cast<int>(value.len / 4), value.bits);
    }
  }
}

void log_callbacks::freg_write_callback(model::Model &model, unsigned reg,
                                        sbits value)
{
  (void)model;
  // TODO: will only print bits; should we print in floating point format?
  if (trace_log != nullptr && config_print_reg) {
    // TODO: Might need to change from PRIX64 to PRIX128 once the "Q"
    // extension is supported
    fprintf(trace_log, "f%d <- 0x%0*" PRIX64 "\n", reg,
            static_cast<int>(value.len / 4), value.bits);
  }
}

void log_callbacks::csr_full_write_callback(model::Model &model,
                                            const_sail_string csr_name,
                                            unsigned reg, sbits value)
{
  (void)model;
  if (trace_log != nullptr && config_print_reg) {
    fprintf(trace_log, "CSR %s (0x%03X) <- 0x%0*" PRIX64 "\n", csr_name, reg,
            static_cast<int>(value.len / 4), value.bits);
  }
}

void log_callbacks::csr_full_read_callback(model::Model &model,
                                           const_sail_string csr_name,
                                           unsigned reg, sbits value)
{
  (void)model;
  if (trace_log != nullptr && config_print_reg) {
    fprintf(trace_log, "CSR %s (0x%03X) -> 0x%0*" PRIX64 "\n", csr_name, reg,
            static_cast<int>(value.len / 4), value.bits);
  }
}

void log_callbacks::vreg_write_callback(model::Model &model, unsigned reg,
                                        lbits value)
{
  (void)model;
  if (trace_log != nullptr && config_print_reg) {
    fprintf(trace_log, "v%d <- 0x", reg);
    print_lbits_hex(trace_log, value);
  }
}

void log_callbacks::pc_write_callback(model::Model &model, sbits)
{
  (void)model;
}

void log_callbacks::trap_callback(model::Model &model)
{
  (void)model;
}
