#include "riscv_callbacks_log.h"
#include "riscv_model_impl.h"
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

void log_callbacks::mem_write_callback(ModelImpl &model, const char *type, sbits paddr, int64_t width, lbits value) {
  // This is just passed due to Sail type system requirements.
  (void)width;
  if (trace_log != nullptr && config_print_mem_access) {
    fprintf(
      trace_log,
      "mem[%s,0x%0*" PRIX64 "] <- ",
      type,
      static_cast<int>((model.physaddrbits_len() + 3) / 4),
      paddr.bits
    );
    gmp_fprintf(trace_log, "0x%0*ZX\n", value.len / 4, *value.bits);
  }
}

void log_callbacks::mem_read_callback(ModelImpl &model, const char *type, sbits paddr, int64_t width, lbits value) {
  // This is just passed due to Sail type system requirements.
  (void)width;
  if (trace_log != nullptr && config_print_mem_access) {
    fprintf(
      trace_log,
      "mem[%s,0x%0*" PRIX64 "] -> ",
      type,
      static_cast<int>((model.physaddrbits_len() + 3) / 4),
      paddr.bits
    );
    gmp_fprintf(trace_log, "0x%0*ZX\n", value.len / 4, *value.bits);
  }
}

void log_callbacks::xreg_full_write_callback(ModelImpl &, const_sail_string abi_name, sbits reg, sbits value) {
  if (trace_log != nullptr && config_print_gpr) {
    if (config_use_abi_names) {
      fprintf(trace_log, "%s <- 0x%0*" PRIX64 "\n", abi_name, static_cast<int>(value.len / 4), value.bits);
    } else {
      fprintf(trace_log, "x%" PRIu64 " <- 0x%0*" PRIX64 "\n", reg.bits, static_cast<int>(value.len / 4), value.bits);
    }
  }
}

void log_callbacks::freg_write_callback(ModelImpl &, unsigned reg, sbits value) {
  // TODO: will only print bits; should we print in floating point format?
  if (trace_log != nullptr && config_print_fpr) {
    // TODO: Might need to change from PRIX64 to PRIX128 once the "Q"
    // extension is supported
    fprintf(trace_log, "f%d <- 0x%0*" PRIX64 "\n", reg, static_cast<int>(value.len / 4), value.bits);
  }
}

void log_callbacks::csr_full_write_callback(ModelImpl &, const_sail_string csr_name, unsigned reg, sbits value) {
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

void log_callbacks::csr_full_read_callback(ModelImpl &, const_sail_string csr_name, unsigned reg, sbits value) {
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

void log_callbacks::vreg_write_callback(ModelImpl &, unsigned reg, lbits value) {
  if (trace_log != nullptr && config_print_vreg) {
    fprintf(trace_log, "v%d <- ", reg);
    gmp_fprintf(trace_log, "0x%0*ZX\n", value.len / 4, *value.bits);
  }
}

// Page table walk callback
void log_callbacks::ptw_start_callback(
  ModelImpl &model,
  uint64_t vpn,
  ModelImpl::MemoryAccessType access_type,
  ModelImpl::Privilege privilege
) {
  if (trace_log != nullptr && config_print_ptw) {
    fprintf(
      trace_log,
      "PTW: Start, vpn=0x%" PRIx64 ", access_type=%s, privilege=%s\n",
      vpn,
      model.memory_access_type_to_string(access_type).c_str(),
      model.privilege_to_string(privilege).c_str()
    );
  }
}

void log_callbacks::ptw_step_callback(ModelImpl & /*model*/, int64_t level, sbits pte_addr, uint64_t pte) {
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

void log_callbacks::ptw_success_callback(ModelImpl & /*model*/, uint64_t final_ppn, int64_t level) {
  if (trace_log != nullptr && config_print_ptw) {
    fprintf(trace_log, "PTW: Success, final_ppn=0x%" PRIx64 ", level=%" PRId64 "\n", final_ppn, level);
  }
}

void log_callbacks::ptw_fail_callback(
  ModelImpl &model,
  ModelImpl::PTW_Error error_type,
  int64_t level,
  sbits pte_addr
) {
  if (trace_log != nullptr && config_print_ptw) {
    fprintf(
      trace_log,
      "PTW: failed, error=%s, level=%" PRId64 ", pte_addr=0x%" PRIX64 "\n",
      model.ptw_error_to_string(error_type).c_str(),
      level,
      pte_addr.bits
    );
  }
}

namespace {

void print_tlb(FILE *trace_log, ModelImpl &, ModelImpl::TLB tlb, const std::vector<uint64_t> &indices, bool is_flush) {
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

} // namespace

void log_callbacks::tlb_add_callback(ModelImpl &model, ModelImpl::TLB tlb, uint64_t index) {
  if (trace_log != nullptr && config_print_tlb) {
    print_tlb(trace_log, model, tlb, {index}, false);
  }
}

void log_callbacks::tlb_flush_begin_callback(ModelImpl &) {
  pending_flush_indices.clear();
}

void log_callbacks::tlb_flush_callback(ModelImpl &, uint64_t index) {
  if (config_print_tlb) {
    pending_flush_indices.push_back(index);
  }
}

void log_callbacks::tlb_flush_end_callback(ModelImpl &model, ModelImpl::TLB tlb) {
  if (trace_log != nullptr && config_print_tlb && !pending_flush_indices.empty()) {
    print_tlb(trace_log, model, tlb, pending_flush_indices, true);
  }
}
