#include "riscv_callbacks_log.h"
#include "sail_riscv_model.h"
#include <algorithm>
#include <inttypes.h>
#include <vector>

log_callbacks::log_callbacks(
  bool config_print_gpr,
  bool config_print_fpr,
  bool config_print_vreg,
  bool config_print_csr,
  bool config_print_mem_access,
  bool config_print_ptw,
  bool config_print_tlb,
  bool config_use_abi_names,
  FILE *trace_log
) :
    config_print_gpr(config_print_gpr),
    config_print_fpr(config_print_fpr),
    config_print_vreg(config_print_vreg),
    config_print_csr(config_print_csr),
    config_print_mem_access(config_print_mem_access),
    config_use_abi_names(config_use_abi_names),
    config_print_ptw(config_print_ptw),
    config_print_tlb(config_print_tlb),
    trace_log(trace_log) {
}

// Implementations of default callbacks for trace printing.
// The model assumes that these functions do not change the state of the model.

void log_callbacks::mem_write_callback(hart::Model &model, const char *type, sbits paddr, uint64_t width, lbits value) {
  // This is just passed due to Sail type system requirements.
  (void)width;
  if (trace_log != nullptr && config_print_mem_access) {
    fprintf(
      trace_log,
      "mem[%s,0x%0*" PRIX64 "] <- ",
      type,
      static_cast<int>((model.zphysaddrbits_len + 3) / 4),
      paddr.bits
    );
    gmp_fprintf(trace_log, "0x%0*ZX\n", value.len / 4, *value.bits);
  }
}

void log_callbacks::mem_read_callback(hart::Model &model, const char *type, sbits paddr, uint64_t width, lbits value) {
  // This is just passed due to Sail type system requirements.
  (void)width;
  if (trace_log != nullptr && config_print_mem_access) {
    fprintf(
      trace_log,
      "mem[%s,0x%0*" PRIX64 "] -> ",
      type,
      static_cast<int>((model.zphysaddrbits_len + 3) / 4),
      paddr.bits
    );
    gmp_fprintf(trace_log, "0x%0*ZX\n", value.len / 4, *value.bits);
  }
}

void log_callbacks::xreg_full_write_callback(hart::Model &, const_sail_string abi_name, sbits reg, sbits value) {
  if (trace_log != nullptr && config_print_gpr) {
    if (config_use_abi_names) {
      fprintf(trace_log, "%s <- 0x%0*" PRIX64 "\n", abi_name, static_cast<int>(value.len / 4), value.bits);
    } else {
      fprintf(trace_log, "x%" PRIu64 " <- 0x%0*" PRIX64 "\n", reg.bits, static_cast<int>(value.len / 4), value.bits);
    }
  }
}

void log_callbacks::freg_write_callback(hart::Model &, unsigned reg, sbits value) {
  // TODO: will only print bits; should we print in floating point format?
  if (trace_log != nullptr && config_print_fpr) {
    // TODO: Might need to change from PRIX64 to PRIX128 once the "Q"
    // extension is supported
    fprintf(trace_log, "f%d <- 0x%0*" PRIX64 "\n", reg, static_cast<int>(value.len / 4), value.bits);
  }
}

void log_callbacks::csr_full_write_callback(hart::Model &, const_sail_string csr_name, unsigned reg, sbits value) {
  if (trace_log != nullptr && config_print_csr) {
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
  if (trace_log != nullptr && config_print_csr) {
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
  if (trace_log != nullptr && config_print_vreg) {
    fprintf(trace_log, "v%d <- ", reg);
    gmp_fprintf(trace_log, "0x%0*ZX\n", value.len / 4, *value.bits);
  }
}

// Page table walk callback
void log_callbacks::ptw_start_callback(
  hart::Model &model,
  uint64_t vpn,
  hart::zMemoryAccessTypezIEmem_payloadz5zK access_type,
  hart::ztuple_z8z5enumz0zzPrivilegezCz0z5unitz9 privilege,
  bool is_pure_lookup
) {
  if (trace_log != nullptr && config_print_ptw && !is_pure_lookup) {
    sail_string str_ac, str_pr;
    CREATE(sail_string)(&str_ac);
    CREATE(sail_string)(&str_pr);
    model.zaccessType_to_str(&str_ac, access_type);
    model.zprivLevel_to_str(&str_pr, privilege.ztup0);
    fprintf(trace_log, "PTW: Start, vpn=0x%" PRIx64 ", access_type=%s, privilege=%s\n", vpn, str_ac, str_pr);
    KILL(sail_string)(&str_ac);
    KILL(sail_string)(&str_pr);
  }
}

void log_callbacks::ptw_step_callback(
  hart::Model & /*model*/,
  int64_t level,
  sbits pte_addr,
  uint64_t pte,
  bool is_pure_lookup
) {
  if (trace_log != nullptr && config_print_ptw && !is_pure_lookup) {
    fprintf(
      trace_log,
      "PTW: Step, level=%" PRId64 ", pte=0x%" PRIX64 ", pte_addr=0x%" PRIX64 "\n",
      level,
      pte,
      pte_addr.bits
    );
  }
}

void log_callbacks::ptw_success_callback(
  hart::Model & /*model*/,
  uint64_t final_ppn,
  int64_t level,
  bool is_pure_lookup
) {
  if (trace_log != nullptr && config_print_ptw && !is_pure_lookup) {
    fprintf(trace_log, "PTW: Success, final_ppn=0x%" PRIx64 ", level=%" PRId64 "\n", final_ppn, level);
  }
}

void log_callbacks::ptw_fail_callback(
  hart::Model &model,
  struct hart::zPTW_Error error_type,
  int64_t level,
  sbits pte_addr,
  bool is_pure_lookup
) {
  if (trace_log != nullptr && config_print_ptw && !is_pure_lookup) {
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

static void print_tlb(
  FILE *trace_log,
  hart::Model &model,
  hart::zz5vecz8z5unionz0zzoptionzzIRTLB_EntryzzKz9 tlb,
  const std::vector<uint64_t> &indices,
  bool is_flush
) {
  fprintf(
    trace_log,
    "TLB %s [ len=%zu ]\n"
    "╔═════╦════╦══════════╦══════════════════════╦══════════════════════╦══════════════════════╦══════════════════════"
    "╦══════════════════════"
    "╗\n"
    "║ IDX ║ GL ║   ASID   ║         VPN          ║         PTE          ║     LEVEL_MASK       ║         PPN          "
    "║       PTE_ADDR       "
    "║\n"
    "╠═════╬════╬══════════╬══════════════════════╬══════════════════════╬══════════════════════╬══════════════════════"
    "╬══════════════════════"
    "╣\n",
    is_flush ? "flush" : "add",
    tlb.len
  );
  for (size_t i = 0; i < tlb.len; i++) {
    bool is_entry_selected = std::find(indices.begin(), indices.end(), i) != indices.end();
    const char *annotation = is_entry_selected ? (is_flush ? "  <- flushed" : "  <- added") : "";

    const auto &entry = tlb.data[i];
    if (entry.kind == hart::Kind_zSomezIRTLB_EntryzK) {
      const auto &e = entry.variants.zSomezIRTLB_EntryzK;
      fprintf(
        trace_log,
        "║ %3zu ║  %c ║ 0x%06" PRIX64 " ║ 0x%018" PRIX64 " ║ 0x%018" PRIX64 " ║ 0x%018" PRIX64 " ║ 0x%018" PRIX64
        " ║ 0x%018" PRIX64 " ║%s\n",
        i,
        e.zglobal ? 'Y' : 'N',
        e.zasid.bits,
        e.zvpn,
        e.zpte,
        e.zlevelMask,
        e.zppn,
        e.zpteAddr.bits,
        annotation
      );
    } else {
      fprintf(
        trace_log,
        "║ %3zu ║  - ║   ----   ║         ----         ║         ----         ║         ----         ║         ----    "
        "     ║         ----    "
        "     ║%s\n",
        i,
        annotation
      );
    }
  }
  fprintf(
    trace_log,
    "╚═════╩════╩══════════╩══════════════════════╩══════════════════════╩══════════════════════╩══════════════════════"
    "╩══════════════════════"
    "╝\n"
  );
}

void log_callbacks::tlb_add_callback(
  hart::Model &model,
  hart::zz5vecz8z5unionz0zzoptionzzIRTLB_EntryzzKz9 tlb,
  uint64_t index
) {
  if (trace_log != nullptr && config_print_tlb) {
    print_tlb(trace_log, model, tlb, {index}, false);
  }
}

std::vector<uint64_t> pending_flush_indices;

void log_callbacks::tlb_flush_begin_callback(hart::Model &model) {
  pending_flush_indices.clear();
}

void log_callbacks::tlb_flush_callback(hart::Model &model, uint64_t index) {
  if (config_print_tlb) {
    pending_flush_indices.push_back(index);
  }
}

void log_callbacks::tlb_flush_end_callback(hart::Model &model, hart::zz5vecz8z5unionz0zzoptionzzIRTLB_EntryzzKz9 tlb) {
  if (trace_log != nullptr && config_print_tlb && !pending_flush_indices.empty()) {
    print_tlb(trace_log, model, tlb, pending_flush_indices, true);
  }
}
