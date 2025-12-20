#include "riscv_callbacks_log.h"
#include "riscv_config.h"
#include "sail_riscv_model.h"
#include <inttypes.h>
#include <stdlib.h>
#include <vector>

void print_lbits_hex(FILE *trace_log, lbits val, int length = 0) {
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

log_callbacks::log_callbacks(
  bool config_print_reg,
  bool config_print_mem_access,
  bool config_print_ptw,
  bool config_use_abi_names,
  FILE *trace_log
) :
    config_print_reg(config_print_reg),
    config_print_mem_access(config_print_mem_access),
    config_use_abi_names(config_use_abi_names),
    config_print_ptw(config_print_ptw),
    trace_log(trace_log) {
}

// Implementations of default callbacks for trace printing.
// The model assumes that these functions do not change the state of the model.

void log_callbacks::mem_write_callback(hart::Model &model, const char *type, sbits paddr, uint64_t width, lbits value) {
  if (trace_log != nullptr && config_print_mem_access) {
    fprintf(
      trace_log,
      "mem[%s,0x%0*" PRIX64 "] <- 0x",
      type,
      static_cast<int>((model.zphysaddrbits_len + 3) / 4),
      paddr.bits
    );
    print_lbits_hex(trace_log, value, width);
  }
}

void log_callbacks::mem_read_callback(hart::Model &model, const char *type, sbits paddr, uint64_t width, lbits value) {
  if (trace_log != nullptr && config_print_mem_access) {
    fprintf(
      trace_log,
      "mem[%s,0x%0*" PRIX64 "] -> 0x",
      type,
      static_cast<int>((model.zphysaddrbits_len + 3) / 4),
      paddr.bits
    );
    print_lbits_hex(trace_log, value, width);
  }
}

void log_callbacks::xreg_full_write_callback(hart::Model &, const_sail_string abi_name, sbits reg, sbits value) {
  if (trace_log != nullptr && config_print_reg) {
    if (config_use_abi_names) {
      fprintf(trace_log, "%s <- 0x%0*" PRIX64 "\n", abi_name, static_cast<int>(value.len / 4), value.bits);
    } else {
      fprintf(trace_log, "x%" PRIu64 " <- 0x%0*" PRIX64 "\n", reg.bits, static_cast<int>(value.len / 4), value.bits);
    }
  }
}

void log_callbacks::freg_write_callback(hart::Model &, unsigned reg, sbits value) {
  // TODO: will only print bits; should we print in floating point format?
  if (trace_log != nullptr && config_print_reg) {
    // TODO: Might need to change from PRIX64 to PRIX128 once the "Q"
    // extension is supported
    fprintf(trace_log, "f%d <- 0x%0*" PRIX64 "\n", reg, static_cast<int>(value.len / 4), value.bits);
  }
}

void log_callbacks::csr_full_write_callback(hart::Model &, const_sail_string csr_name, unsigned reg, sbits value) {
  if (trace_log != nullptr && config_print_reg) {
    fprintf(
      trace_log,
      "CSR %s (0x%03X) <- 0x%0*" PRIX64 "\n",
      csr_name,
      reg,
      static_cast<int>(value.len / 4),
      value.bits
    );
  }
}

void log_callbacks::csr_full_read_callback(hart::Model &, const_sail_string csr_name, unsigned reg, sbits value) {
  if (trace_log != nullptr && config_print_reg) {
    fprintf(
      trace_log,
      "CSR %s (0x%03X) -> 0x%0*" PRIX64 "\n",
      csr_name,
      reg,
      static_cast<int>(value.len / 4),
      value.bits
    );
  }
}

void log_callbacks::vreg_write_callback(hart::Model &, unsigned reg, lbits value) {
  if (trace_log != nullptr && config_print_reg) {
    fprintf(trace_log, "v%d <- 0x", reg);
    print_lbits_hex(trace_log, value);
  }
}

// Page table walk callback
void log_callbacks::ptw_start_callback(
  hart::Model &model,
  uint64_t vpn,
  hart::zMemoryAccessTypezIuzK access_type,
  hart::ztuple_z8z5enumz0zzPrivilegezCz0z5unitz9 privilege
) {
  if (trace_log != nullptr && config_print_ptw) {
    sail_string str_ac, str_pr;
    CREATE(sail_string)(&str_ac);
    CREATE(sail_string)(&str_pr);
    model.zaccessType_to_str(&str_ac, access_type);
    model.zprivLevel_to_str(&str_pr, privilege.ztup0);
    fprintf(trace_log, "PTW: Start, vpn=0x%" PRIx64 ", access_type=%s, privilege=%s", vpn, str_ac, str_pr);
    KILL(sail_string)(&str_ac);
    KILL(sail_string)(&str_pr);
  }
}

void log_callbacks::ptw_step_callback(hart::Model & /*model*/, int64_t level, sbits pte_addr, uint64_t pte) {
  if (trace_log != nullptr && config_print_ptw) {
    fprintf(
      trace_log,
      "PTW: Step, level=%" PRId64 ", pte=0x%" PRIX64 ", pte_addr=0x%" PRIX64 "\n",
      level,
      pte,
      pte_addr.bits
    );
  }
}

void log_callbacks::ptw_success_callback(hart::Model & /*model*/, uint64_t final_ppn, int64_t level) {
  if (trace_log != nullptr && config_print_ptw) {
    fprintf(trace_log, "PTW: Success, final_ppn=0x%" PRIx64 ", level=%" PRId64, final_ppn, level);
  }
}

void log_callbacks::ptw_fail_callback(
  hart::Model &model,
  struct hart::zPTW_Error error_type,
  int64_t level,
  sbits pte_addr
) {
  // failed trace is always available
  if (trace_log != nullptr) {
    sail_string str_et;
    CREATE(sail_string)(&str_et);
    model.zptw_error_to_str(&str_et, error_type);
    fprintf(
      trace_log,
      "PTW: failed, error=%s, level=%" PRId64 ", pte_addr=0x%" PRIX64 "\n",
      str_et,
      level,
      pte_addr.bits
    );
    KILL(sail_string)(&str_et);
  }
}
