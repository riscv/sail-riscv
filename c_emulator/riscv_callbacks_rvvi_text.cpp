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
  str << "0x" << std::setw(nibbles) << std::hex << std::setfill('0') << value.bits;
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

void buf_append_sbits(std::ostringstream &buf, const sbits &sbits) {
  const int nibbles = static_cast<int>((sbits.len + 3) / 4);
  buf << " 0x" << std::hex << std::setw(nibbles) << std::setfill('0') << sbits.bits;
}

void buf_append_uint64(std::ostringstream &buf, uint64_t bits, int64_t len) {
  const int nibbles = static_cast<int>((len + 3) / 4);
  buf << " 0x" << std::hex << std::setw(nibbles) << std::setfill('0') << bits;
}

} // namespace

rvvi_text_callbacks::rvvi_text_callbacks(FILE *trace_log) : m_trace_log(trace_log) {
}

void rvvi_text_callbacks::reset_instruction_buffer() {
  m_pending_pc = 0;
  m_pending_inst = 0;
  m_have_inst = false;
  m_pending_trap = false;
  m_reg_changes.clear();

  m_mem_accesses.clear();
  m_sstage_translation.reset();
  m_vsstage_translation.reset();
}

void rvvi_text_callbacks::record_reg(char kind, uint64_t index, std::string value) {
  if (m_first_fetch_seen) {
    m_reg_changes.push_back({kind, index, std::move(value)});
  }
}

void rvvi_text_callbacks::fetch_callback(ModelImpl &model, sbits pc, sbits opcode) {
  emit_header(model);
  m_first_fetch_seen = true;
  m_event_mode = model.privilege_as_bits(model.cur_privilege());
  m_event_virt = ModelImpl::is_virtual_privilege(model.cur_privilege()) ? 1 : 0;
  // A second fetch without instret means the previous insn was abandoned.
  if (m_have_inst) {
    reset_instruction_buffer();
  }
  m_pending_pc = pc.bits;
  m_pending_inst = opcode.bits;
  m_have_inst = true;
}

void rvvi_text_callbacks::xreg_full_write_callback(ModelImpl &, const_sail_string, sbits reg, sbits value) {
  record_reg('X', reg.bits, hex_value(value));
}

void rvvi_text_callbacks::freg_write_callback(ModelImpl &model, unsigned reg, sbits value) {
  record_reg('F', reg, hex_value(value));
}

void rvvi_text_callbacks::csr_full_write_callback(ModelImpl &, const_sail_string, unsigned reg, sbits value) {
  record_reg('C', reg, hex_value(value));
}

void rvvi_text_callbacks::vreg_write_callback(ModelImpl &model, unsigned reg, lbits value) {
  record_reg('V', reg, hex_value_lbits(value));
}

void rvvi_text_callbacks::ptw_step_callback(
  ModelImpl &,
  ModelImpl::TranslationStage stage,
  int64_t level,
  sbits pte_addr,
  uint64_t pte
) {
  switch (stage) {
  case hart::zS_Stage: {
    assert(m_sstage_translation.has_value());
    auto &translation = m_sstage_translation.value();
    translation.last_ptw_step = {level, pte_addr, pte};
    break;
  };
  case hart::zVS_Stage: {
    assert(m_vsstage_translation.has_value());
    auto &translation = m_vsstage_translation.value();
    translation.vs_state.last_ptw_step = {level, pte_addr, pte};
    break;
  };
  case hart::zG_Stage: {
    assert(m_vsstage_translation.has_value());
    auto &translation = m_vsstage_translation.value();
    assert(translation.g_state.has_value());
    auto &g_state = translation.g_state.value();
    g_state.last_ptw_step = {level, pte_addr, pte};
    break;
  };
  }
}

void rvvi_text_callbacks::address_translation_start_callback(
  ModelImpl &,
  ModelImpl::TranslationStage stage,
  ModelImpl::Privilege privilege,
  sbits vaddr,
  ModelImpl::MemoryAccessType access,
  int64_t width
) {
  switch (stage) {
  case hart::zS_Stage: {
    m_sstage_translation = {vaddr, width, std::nullopt, std::nullopt};
    break;
  };
  case hart::zVS_Stage: {
    TranslationState vs_state = {vaddr, width, std::nullopt, std::nullopt};
    m_vsstage_translation = {vs_state, std::nullopt};
    break;
  };
  case hart::zG_Stage: {
    assert(m_vsstage_translation.has_value());
    auto &translation = m_vsstage_translation.value();
    translation.g_state = {vaddr, width, std::nullopt, std::nullopt};
    break;
  };
  }
}

void rvvi_text_callbacks::address_translated_callback(
  ModelImpl &,
  ModelImpl::TranslationStage stage,
  sbits vaddr,
  sbits paddr,
  ModelImpl::MemoryAccessType,
  int64_t width
) {
  switch (stage) {
  case hart::zS_Stage: {
    assert(m_sstage_translation.has_value());
    auto &translation = m_sstage_translation.value();
    assert(vaddr == translation.vaddr);
    assert(width == translation.width);
    translation.paddr = paddr;
    break;
  };
  case hart::zVS_Stage: {
    assert(m_vsstage_translation.has_value());
    auto &translation = m_vsstage_translation.value();
    assert(vaddr == translation.vs_state.vaddr);
    assert(width == translation.vs_state.width);
    translation.vs_state.paddr = paddr;
    break;
  };
  case hart::zG_Stage: {
    assert(m_vsstage_translation.has_value());
    auto &translation = m_vsstage_translation.value();
    assert(translation.g_state.has_value());
    auto &g_state = translation.g_state.value();
    g_state.paddr = paddr;
    break;
  };
  }
}

void rvvi_text_callbacks::record_mem_access(
  ModelImpl::Privilege privilege,
  ModelImpl::MemoryAccessType access,
  sbits paddr,
  int64_t width
) {
  // M-mode Bare address translations are reported as S_Stage.
  auto use_vsstage = privilege == hart::zVirtualUser || privilege == hart::zVirtualSupervisor;
  if (use_vsstage) {
    if (m_vsstage_translation.has_value()) {
      const auto &translation = m_vsstage_translation.value();
      // A G-stage translation should always complete before a memory
      // access, though a VS-stage translation may still be in progress.
      assert(translation.g_state.has_value());
      const auto &g_state = translation.g_state.value();
      assert(g_state.paddr.has_value());
      std::optional<sbits> gpaddr = std::nullopt;
      std::optional<PTWStep> gpte = std::nullopt;
      std::optional<PTWStep> pte = std::nullopt;
      // If the VS-Stage translation is incomplete (e.g. this is an
      // access for an intermediate PTE), use the paddr as vaddr.
      auto vaddr = paddr;
      if (paddr == g_state.paddr.value()) {
        // The access is using the same paddr as the output of the
        // G-stage translation, so record the access as using the
        // G-stage input as the guest physical address and its last
        // G-stage pte.
        gpaddr = g_state.vaddr;
        gpte = g_state.last_ptw_step;
      }
      if (translation.vs_state.paddr.has_value() && paddr == translation.vs_state.paddr.value()) {
        // The VS-stage translation has completed and the access is
        // using the same paddr as the output of the VS-stage
        // translation, so record the access as using the VS-stage
        // input as the virtual address and its last pte.
        pte = translation.vs_state.last_ptw_step;
        vaddr = translation.vs_state.vaddr;
      }
      MemoryAccess mem_access{access, paddr, translation.vs_state.vaddr, width, pte, gpaddr, gpte};
      m_mem_accesses.push_back(std::move(mem_access));
      return;
    }
  } else if (m_sstage_translation.has_value()) {
    const auto &translation = m_sstage_translation.value();
    const auto &opt_paddr = translation.paddr;
    if (opt_paddr.has_value() && paddr == opt_paddr.value()) {
      // The access is using the same paddr as the output of the
      // S-stage translation.  Record the access as using the input
      // vaddr, and copy the last_pte used in the translation.
      auto pte = translation.last_ptw_step;
      MemoryAccess mem_access{access, paddr, translation.vaddr, width, pte, std::nullopt, std::nullopt};
      m_mem_accesses.push_back(std::move(mem_access));
      return;
    }
  }

  // Default to using vaddr = paddr when paddr is not known to be a
  // translated address.  This can happen for PTE accesses that occur
  // before the translation completes.
  MemoryAccess mem_access{access, paddr, paddr, width, std::nullopt, std::nullopt, std::nullopt};
  m_mem_accesses.push_back(std::move(mem_access));
}
void rvvi_text_callbacks::mem_write_callback(
  ModelImpl &,
  ModelImpl::Privilege privilege,
  ModelImpl::MemoryAccessType access,
  sbits paddr,
  int64_t width,
  lbits
) {
  record_mem_access(privilege, access, paddr, width);
}

void rvvi_text_callbacks::mem_read_callback(
  ModelImpl &,
  ModelImpl::Privilege privilege,
  ModelImpl::MemoryAccessType access,
  sbits paddr,
  int64_t width,
  lbits
) {
  record_mem_access(privilege, access, paddr, width);
}

void rvvi_text_callbacks::instret_callback(ModelImpl &model) {
  emit_instruction(model);
  reset_instruction_buffer();
}

void rvvi_text_callbacks::trap_callback(ModelImpl &model, bool, fbits) {
  // Fetch faults never call fetch_callback; capture the faulting PC here.
  emit_header(model);
  if (!m_have_inst) {
    m_pending_pc = model.pc();
    m_pending_inst = 0;
    m_have_inst = true;
  }
  m_pending_trap = true;
}

void rvvi_text_callbacks::post_step_callback(ModelImpl &model, bool) {
  // Retired insns are emitted from instret_callback. Traps skip instret.
  if (m_have_inst && m_pending_trap) {
    emit_instruction(model);
    reset_instruction_buffer();
  }
}

std::string rvvi_text_callbacks::MemoryAccess::print(ModelImpl &model) const {
  std::ostringstream buf;
  // The python linter/checker scripts expect uppercase hex.  This
  // should not be strictly necessary.
  buf << std::uppercase;
  buf << "MEM ";
  // "bus"
  buf << (model.is_fetch(access_type) ? "I " : "D ");
  // "bytes"
  buf << std::dec << width;
  // "vaddr"
  buf_append_sbits(buf, vaddr);
  // "paddr"
  buf_append_sbits(buf, paddr);
  // "count"
  int count = (pte.has_value() ? 2 : 0) + (gpte.has_value() ? 2 : 0) + (gpaddr.has_value() ? 1 : 0);
  buf << " " << std::dec << count;
  if (pte.has_value()) {
    const auto &step = pte.value();
    buf << " PTE";
    buf_append_uint64(buf, step.pte, model.xlen());
    buf << " PT " << page_type_letter(step.level);
  }
  if (gpte.has_value()) {
    const auto &step = gpte.value();
    buf << " GPTE";
    buf_append_uint64(buf, step.pte, model.xlen());
    buf << " GPT " << page_type_letter(step.level);
  }
  if (gpaddr.has_value()) {
    buf << " GPADDR";
    buf_append_sbits(buf, gpaddr.value());
  }
  return buf.str();
}

void rvvi_text_callbacks::emit_header(ModelImpl &model) {
  if (m_trace_log == nullptr || m_header_emitted) {
    return;
  }
  m_header_emitted = true;
  fprintf(m_trace_log, "VERSION 0 5\n");
  fprintf(m_trace_log, "VENDOR \"sail_riscv\" 0 1\n");
  fprintf(
    m_trace_log,
    "PARAMS 6 ILEN 32 XLEN %llu FLEN %llu VLEN %llu NHART 1 RETIRE 1\n",
    static_cast<unsigned long long>(model.xlen()),
    static_cast<unsigned long long>(model.has_float_registers() ? model.flen() : 0),
    static_cast<unsigned long long>(model.has_vector_registers() ? model.vlen() : 0)
  );
}

void rvvi_text_callbacks::emit_instruction(ModelImpl &model) {
  if (m_trace_log == nullptr) {
    return;
  }

  const int xlen_nibbles = static_cast<int>((model.xlen() + 3) / 4);
  const char *event = m_pending_trap ? "TRAP" : "RET";
  fprintf(
    m_trace_log,
    "HART 0 %s 0x%0*llX 0x%08llX",
    event,
    xlen_nibbles,
    static_cast<unsigned long long>(m_pending_pc),
    static_cast<unsigned long long>(m_pending_inst)
  );

  for (const auto &change : m_reg_changes) {
    if (change.kind == 'C') {
      fprintf(m_trace_log, " C 0x%llX %s", static_cast<unsigned long long>(change.index), change.value.c_str());
    } else {
      fprintf(
        m_trace_log,
        " %c %llu %s",
        change.kind,
        static_cast<unsigned long long>(change.index),
        change.value.c_str()
      );
    }
  }

  for (const auto &mem_access : m_mem_accesses) {
    std::string mem_record = mem_access.print(model);
    fprintf(m_trace_log, " %s", mem_record.c_str());
  }

  fprintf(m_trace_log, " MODE 0x%llX", static_cast<unsigned long long>(m_event_mode));
  fprintf(m_trace_log, " VIRT 0x%X\n", m_event_virt);
}
