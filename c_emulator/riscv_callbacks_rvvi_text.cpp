#include "riscv_callbacks_rvvi_text.h"
#include "riscv_model_impl.h"
#include "sail.h"

#include <array>
#include <cassert>
#include <iomanip>
#include <sstream>

namespace {

std::string hex_value(const sbits &value) {
  std::ostringstream str;
  const int nibbles = static_cast<int>((value.len + 3) / 4);
  str << "0x" << std::hex << std::setw(nibbles) << std::setfill('0') << value.bits;
  return str.str();
}

std::string hex_value_lbits(const lbits &value) {
  sail_string sstr = nullptr;
  CREATE(sail_string)(&sstr);
  hex_str_upper(&sstr, *value.bits);
  std::string str(sstr);
  KILL(sail_string)(&sstr);
  return str;
}

bool operator==(const sbits &lhs, const sbits &rhs) {
  return lhs.len == rhs.len && lhs.bits == rhs.bits;
}

char page_type_letter(int64_t level) {
  static std::array<char, 5> letters{'K', 'M', 'G', 'T', 'P'};
  if (level >= 0 && level < letters.size()) {
    return letters.at(level);
  }
  return '?';
}

void buf_append_sbits(std::ostringstream &buf, const sbits &sbits, bool prefix_with_space = true) {
  const int nibbles = static_cast<int>((sbits.len + 3) / 4);
  if (prefix_with_space) {
    buf << " ";
  }
  buf << "0x" << std::hex << std::setw(nibbles) << std::setfill('0') << sbits.bits;
}

void buf_append_uint64(std::ostringstream &buf, uint64_t bits, int64_t len) {
  const int nibbles = static_cast<int>((len + 3) / 4);
  buf << " 0x" << std::hex << std::setw(nibbles) << std::setfill('0') << bits;
}

} // namespace

rvvi_text_callbacks::rvvi_text_callbacks(FILE *trace_log) : m_trace_log(trace_log) {
}

void rvvi_text_callbacks::reset_instruction_buffer() {
  m_event_pc = 0;
  m_event_inst = {};
  m_trapped = false;

  m_reg_changes.clear();
  m_trigger_tdata_write.reset();

  m_mem_accesses.clear();
  m_sstage_translation.reset();
  m_vsstage_translation.reset();
  m_faulting_access.reset();
}

void rvvi_text_callbacks::record_reg(char kind, uint64_t index, std::string value) {
  // Ignore registers written on reset (e.g. `misa`, `mstatus`,
  // `mcause` etc. in `sys_control.sail:reset_sys()` ) and startup
  // (`a0` and `a1` in `model.sail:init_boot_requirements()`).  These
  // are all written before the first instruction is executed.
  if (!m_execution_started) {
    return;
  }

  m_reg_changes[{kind, index}] = {kind, index, std::move(value)};
}

void rvvi_text_callbacks::pre_step_callback(ModelImpl &model, bool) {
  emit_header(model);
  m_execution_started = true;

  m_event_priv = model.cur_privilege();
  m_event_virt = ModelImpl::is_virtual_privilege(model.cur_privilege());
  m_event_pc = model.pc();
}

void rvvi_text_callbacks::fetch_callback(ModelImpl &, sbits pc, sbits opcode) {
  assert(m_event_pc == pc.bits);
  m_event_inst = opcode;
}

void rvvi_text_callbacks::xreg_full_write_callback(ModelImpl &, const_sail_string, sbits reg, sbits value) {
  record_reg('X', reg.bits, hex_value(value));
}

void rvvi_text_callbacks::freg_write_callback(ModelImpl &, uint64_t reg, sbits value) {
  record_reg('F', reg, hex_value(value));
}

void rvvi_text_callbacks::csr_full_write_callback(ModelImpl &, const_sail_string, uint64_t reg, sbits value) {
  // Some CSR addresses need to be swizzled when they are accessed with virtual privilege.
  static std::map<uint64_t, uint64_t> csr_swizzle_map{
    {0x100, 0x200}, // sstatus    -> vsstatus
    {0x104, 0x204}, // sie        -> vsie
    {0x105, 0x205}, // stvec      -> vstvec
    {0x140, 0x240}, // sscratch   -> vsscratch
    {0x141, 0x241}, // sepc       -> vsepc
    {0x142, 0x242}, // scause     -> vscause
    {0x143, 0x243}, // stval      -> vstval
    {0x144, 0x244}, // sip        -> vsip
    {0x14D, 0x24D}, // stimecmp   -> vstimecmp
    {0x15D, 0x25D}, // stimecmph  -> vstimecmph
    {0x180, 0x280}, // satp       -> vsatp
  };
  if (ModelImpl::is_virtual_privilege(m_event_priv) && csr_swizzle_map.find(reg) != csr_swizzle_map.end()) {
    reg = csr_swizzle_map[reg];
  }
  record_reg('C', reg, hex_value(value));
}

void rvvi_text_callbacks::vreg_write_callback(ModelImpl &, uint64_t reg, lbits value) {
  record_reg('V', reg, hex_value_lbits(value));
}

void rvvi_text_callbacks::trigger_tdata_write_callback(ModelImpl &, sbits tselect, int64_t tdata_num, sbits data) {
  m_trigger_tdata_write = {tselect, tdata_num, data};
}

rvvi_text_callbacks::PTWStep rvvi_text_callbacks::record_ptw_step(
  ModelImpl &,
  ModelImpl::TranslationStage stage,
  int64_t level,
  sbits pte_addr,
  uint64_t pte
) {
  PTWStep step = {level, pte_addr, pte};
  switch (stage) {
  case hart::zS_Stage: {
    assert(m_sstage_translation.has_value());
    auto &translation = m_sstage_translation.value();
    translation.last_ptw_step = step;
    break;
  }
  case hart::zVS_Stage: {
    assert(m_vsstage_translation.has_value());
    auto &translation = m_vsstage_translation.value();
    translation.vs_state.last_ptw_step = step;
    break;
  }
  case hart::zG_Stage: {
    assert(m_vsstage_translation.has_value());
    auto &translation = m_vsstage_translation.value();
    assert(translation.g_state.has_value());
    auto &g_state = translation.g_state.value();
    g_state.last_ptw_step = step;
    break;
  }
  }

  return step;
}

void rvvi_text_callbacks::ptw_step_callback(
  ModelImpl &model,
  ModelImpl::TranslationStage stage,
  int64_t level,
  sbits pte_addr,
  uint64_t pte
) {
  auto step = record_ptw_step(model, stage, level, pte_addr, pte);
  // This callback occurs right after a PTE is read.  There should
  // have been a memory read callback right before this, so we should
  // have memory accesses.
  assert(!m_mem_accesses.empty());

  switch (stage) {
  case hart::zS_Stage: {
    MemoryAccess &mem_access = m_mem_accesses.back();
    assert(mem_access.paddr == pte_addr);
    assert(!mem_access.pte.has_value());
    mem_access.pte = step;
    mem_access.is_pte = true;
    break;
  }
  case hart::zG_Stage: {
    MemoryAccess &mem_access = m_mem_accesses.back();
    assert(mem_access.paddr == pte_addr);
    assert(mem_access.gpaddr.has_value());
    assert(!mem_access.gpte.has_value());
    mem_access.gpte = step;
    mem_access.is_pte = true;
    break;
  }
  case hart::zVS_Stage: {
    MemoryAccess &mem_access = m_mem_accesses.back();
    // When reading a VS-stage PTE, the `pte_addr` matches the `gpaddr`
    // of the memory access.
    assert(mem_access.gpaddr.has_value() && mem_access.gpaddr.value() == pte_addr);
    assert(mem_access.gpaddr.has_value());
    assert(!mem_access.pte.has_value());
    mem_access.pte = step;
    mem_access.is_pte = true;
    break;
  }
  }
}

void rvvi_text_callbacks::address_translation_start_callback(
  ModelImpl &,
  ModelImpl::TranslationStage stage,
  ModelImpl::Privilege,
  sbits vaddr,
  ModelImpl::MemoryAccessType access
) {
  switch (stage) {
  case hart::zS_Stage: {
    m_sstage_translation = {vaddr, access, std::nullopt, std::nullopt};
    break;
  }
  case hart::zVS_Stage: {
    TranslationState vs_state = {vaddr, access, std::nullopt, std::nullopt};
    m_vsstage_translation = {vs_state, std::nullopt};
    break;
  }
  case hart::zG_Stage: {
    assert(m_vsstage_translation.has_value());
    auto &translation = m_vsstage_translation.value();
    translation.g_state = {vaddr, access, std::nullopt, std::nullopt};
    break;
  }
  }
}

void rvvi_text_callbacks::address_translated_callback(
  ModelImpl &,
  ModelImpl::TranslationStage stage,
  sbits vaddr,
  sbits paddr,
  ModelImpl::MemoryAccessType
) {
  switch (stage) {
  case hart::zS_Stage: {
    assert(m_sstage_translation.has_value());
    auto &translation = m_sstage_translation.value();
    assert(vaddr == translation.vaddr);
    assert(!translation.paddr.has_value());
    translation.paddr = paddr;
    break;
  }
  case hart::zVS_Stage: {
    assert(m_vsstage_translation.has_value());
    auto &translation = m_vsstage_translation.value();
    assert(vaddr == translation.vs_state.vaddr);
    assert(!translation.vs_state.paddr.has_value());
    translation.vs_state.paddr = paddr;
    break;
  }
  case hart::zG_Stage: {
    assert(m_vsstage_translation.has_value());
    auto &translation = m_vsstage_translation.value();
    assert(translation.g_state.has_value());
    auto &g_state = translation.g_state.value();
    assert(g_state.vaddr == vaddr);
    assert(!g_state.paddr.has_value());
    g_state.paddr = paddr;
    break;
  }
  }
}

void rvvi_text_callbacks::record_mem_access(
  ModelImpl &model,
  ModelImpl::Privilege,
  ModelImpl::MemoryAccessType access,
  sbits paddr,
  int64_t width,
  bool is_write
) {
  // The memory access should always have a corresponding translation
  // state for that access, though the translation state may not be
  // complete (e.g. the access could be for a PTE in a PTW that is
  // completing the translation).

  // Notes:
  // - M-mode Bare address translations are reported as S-stage.
  // - G-stage PTW accesses occur with User privilege.
  // - This memory access could be for the A/D bit write update to a
  //   PTE entry; this happens before the address translation is
  //   completed.
  char kind = model.is_fetch(access) ? 'I' : 'D';

  // First check VS/G translation state; this is to account for
  // HLV/HSV that can be fetched using S-stage and perform memory
  // accesses using 2-stage translation.
  if (m_vsstage_translation.has_value()) {
    const auto &translation = m_vsstage_translation.value();
    // By the time a memory access is made, the G-stage translation should also exist.
    assert(translation.g_state.has_value());
    const auto &g_state = translation.g_state.value();

    // The virtual address for this access is the address the VS-stage
    // is translating.
    auto vaddr = translation.vs_state.vaddr;

    // If this is a read access to a PTE, then there should be
    // `ptw_step_callback()` before the next memory access; that
    // callback will provide the `pte` or `gpte` for this access
    // and set `is_pte`.
    //
    // However, if this is a write access to the PTE to update the A/D
    // bits, then there will not be a subsequent `ptw_step_callback()`
    // to update the `pte`/`gpte`; copy them here, since these will be
    // the same as that of the previous entry (modulo the A/D bits).

    bool vs_stage_completed = false;
    bool g_stage_completed = false;
    std::optional<PTWStep> pte = std::nullopt;
    std::optional<PTWStep> gpte = std::nullopt;
    sbits gpaddr{};
    bool is_pte = true;

    if (translation.vs_state.paddr.has_value()) {
      // The VS-stage translation has completed, and the `paddr` it
      // found is the `gpaddr` for this access.
      vs_stage_completed = true;
      gpaddr = translation.vs_state.paddr.value();
    };
    if (vs_stage_completed) {
      assert(gpaddr == g_state.vaddr);
      if (g_state.paddr.has_value()) {
        g_stage_completed = true;
        // Both stages are complete.  This cannot be an access to a PTE.
        is_pte = false;
      }
    } else {
      // The guest-physical address for this access is the address the
      // G-stage is translating.
      gpaddr = g_state.vaddr;
    }

    if (is_pte && is_write) {
      if (g_stage_completed) {
        // This is the access to the VS-stage PTE.
        pte = translation.vs_state.last_ptw_step;
        assert(pte.has_value());
      } else {
        // This is access to the G-state PTE.
        gpte = g_state.last_ptw_step;
        assert(gpte.has_value());
      }
    }

    assert(is_pte == model.is_pte_access(access));
    MemoryAccess mem_access{kind, paddr, vaddr, width, pte, gpaddr, gpte, is_pte};
    m_mem_accesses.push_back(std::move(mem_access));
    return;
  }

  if (m_sstage_translation.has_value()) {
    const auto &translation = m_sstage_translation.value();
    // The virtual address for this access is the address the S-stage is translating.
    auto vaddr = translation.vaddr;

    std::optional<PTWStep> pte = std::nullopt;
    bool is_pte = true;
    if (translation.paddr.has_value()) {
      is_pte = false;
    } else {
      pte = is_write ? translation.last_ptw_step : std::nullopt;
    }
    assert(is_pte == model.is_pte_access(access));

    MemoryAccess mem_access{kind, paddr, vaddr, width, pte, std::nullopt, std::nullopt, is_pte};
    m_mem_accesses.push_back(std::move(mem_access));
    return;
  }

  // We should never get here.  Every memory access (including Bare
  // accesses) should have a translation state apply to it.
  assert(false);
}

void rvvi_text_callbacks::mem_write_callback(
  ModelImpl &model,
  ModelImpl::Privilege privilege,
  ModelImpl::MemoryAccessType access,
  sbits paddr,
  int64_t width,
  lbits
) {
  record_mem_access(model, privilege, access, paddr, width, true);
}

void rvvi_text_callbacks::mem_read_callback(
  ModelImpl &model,
  ModelImpl::Privilege privilege,
  ModelImpl::MemoryAccessType access,
  sbits paddr,
  int64_t width,
  lbits
) {
  record_mem_access(model, privilege, access, paddr, width, false);
}

void rvvi_text_callbacks::interrupt_callback(ModelImpl &, fbits) {
  m_trapped = true;
}

void rvvi_text_callbacks::exception_callback(ModelImpl &model, fbits, const ModelImpl::ExceptionContext &ctx) {
  if (model.is_memory_exception(ctx)) {
    // The exception context does not store the access (or its width)
    // that caused the exception, so we can't generate a complete
    // MemoryAccess record.
    bool is_fetch = model.is_fetch_exception(ctx);
    m_faulting_access = {ctx.zexcinfo, is_fetch};
  }
  m_trapped = true;
}

void rvvi_text_callbacks::post_step_callback(ModelImpl &model, bool) {
  emit_instruction(model);
  reset_instruction_buffer();
}

std::string rvvi_text_callbacks::MemoryAccess::print(ModelImpl &model) const {
  std::ostringstream buf;
  buf << "MEM ";
  // "bus"
  buf << kind << " ";
  // "bytes"
  buf << std::dec << width;
  // "vaddr"
  buf_append_sbits(buf, vaddr);
  // "paddr"
  buf_append_sbits(buf, paddr);
  // "count"
  int count = (pte.has_value() ? 2 : 0) + (gpte.has_value() ? 2 : 0) + (gpaddr.has_value() ? 1 : 0);
  buf << " " << std::dec << count;

  if (is_pte) {
    assert(pte.has_value() || gpte.has_value());
  } else {
    assert(!pte.has_value() && !gpte.has_value());
  }
  if (pte.has_value()) {
    const auto &step = pte.value();
    buf << " PTE";
    buf_append_uint64(buf, step.pte, model.xlen());
    buf << " PT " << page_type_letter(step.level);
    // buf << " PTW " << std::dec << step.level;
  }
  if (gpte.has_value()) {
    const auto &step = gpte.value();
    buf << " GPTE";
    buf_append_uint64(buf, step.pte, model.xlen());
    buf << " GPT " << page_type_letter(step.level);
    // buf << " GPTW " << std::dec << step.level;
  }

  // Both implicit and explicit addresses may have a `gpaddr`.
  if (gpaddr.has_value()) {
    buf << " GPADDR";
    buf_append_sbits(buf, gpaddr.value());
  }

  return buf.str();
}

std::string rvvi_text_callbacks::print_faulting_access(ModelImpl &model, const FaultingAccess &fault) {
  // Generate a minimal MEM record, using 0 for the physical address and the access width.
  std::ostringstream buf;
  buf << "MEM ";
  // "bus"
  buf << (fault.is_fetch ? "I " : "D ");
  // "bytes".
  buf << "0 ";
  // "vaddr"
  buf_append_sbits(buf, fault.vaddr);
  // "paddr".
  buf_append_uint64(buf, 0, model.xlen());
  // "count"
  buf << " 1";
  // Mark this with a special `FAULTED 1` key-value pair.
  buf << " FAULTED 1";

  return buf.str();
}

void rvvi_text_callbacks::emit_header(ModelImpl &model) {
  if (m_trace_log == nullptr || m_header_emitted) {
    return;
  }

  std::ostringstream buf;
  buf << "VERSION 0 5" << std::endl;
  buf << "VENDOR \"sail_riscv\" 0 1" << std::endl;
  buf << "PARAMS 6"
      // maximum permissible instruction length in bits.
      << " ILEN 32"
      // maximum permissible General purpose register size in bits.
      << " XLEN "
      << model.xlen()
      // maximum permissible Floating point register size in bits.
      << " FLEN "
      << (model.has_float_registers() ? model.flen() : 0)
      // maximum permissible Vector register size in bits.
      << " VLEN "
      << (model.has_vector_registers() ? model.vlen() : 0)
      // number of harts that will be reported on this interface.
      << " NHART 1"
      // maximum number of instructions that can be retired during a valid event.
      << " RETIRE 1" << std::endl;
  fprintf(m_trace_log, "%s", buf.str().c_str());
  m_header_emitted = true;
}

void rvvi_text_callbacks::emit_instruction(ModelImpl &model) {
  if (m_trace_log == nullptr) {
    return;
  }

  std::ostringstream buf;
  buf << (m_trapped ? "TRAP" : "RET");
  buf_append_uint64(buf, m_event_pc, model.xlen());
  buf_append_sbits(buf, m_event_inst);

  for (const auto &[_, change] : m_reg_changes) {
    // CSR indices use hex, other register files use decimal.
    if (change.kind == 'C') {
      buf << " C 0x" << std::hex << std::setw(3) << std::setfill('0') << change.index << " " << change.value;
    } else {
      buf << " " << change.kind << " " << std::dec << change.index << " " << change.value;
    }
  }
  if (m_trigger_tdata_write.has_value()) {
    auto &tdata_write = m_trigger_tdata_write.value();
    // STATE key value pairs are both strings.
    buf << " STATE \"csr_tdata" << tdata_write.tdata_num << "_tselect" << tdata_write.tselect.bits << "\" \"";
    buf_append_sbits(buf, tdata_write.data, false);
    buf << "\"";
  }

  for (const auto &mem_access : m_mem_accesses) {
    buf << " " << mem_access.print(model);
  }
  if (m_faulting_access.has_value()) {
    buf << " " << print_faulting_access(model, m_faulting_access.value());
  }

  buf << " MODE 0x" << std::hex << model.privilege_as_bits(m_event_priv);
  buf << " VIRT 0x" << std::hex << (m_event_virt ? 1 : 0);
  buf << std::endl;

  fprintf(m_trace_log, "%s", buf.str().c_str());
}
