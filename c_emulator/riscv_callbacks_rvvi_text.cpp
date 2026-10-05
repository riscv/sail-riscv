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

char page_type_letter(int64_t level) {
  static std::array<char, 5> letters{'K', 'M', 'G', 'T', 'P'};
  if (level >= 0 && level < letters.size()) {
    return letters.at(level);
  }
  return '?';
}

bool is_GStage(ModelImpl::TranslationStage stage) {
  return stage == hart::zG_Stage;
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
  m_mem_traces.clear();
  m_cur_mem_trace.reset();
}

void rvvi_text_callbacks::record_reg(char kind, uint64_t index, std::string value) {
  if (m_first_fetch_seen) {
    m_reg_changes.push_back({kind, index, std::move(value)});
  }
}

void rvvi_text_callbacks::fetch_callback(ModelImpl &model, sbits opcode) {
  emit_header(model);
  m_first_fetch_seen = true;
  m_event_mode = model.privilege_as_bits(model.cur_privilege());
  m_event_virt = ModelImpl::is_virtual_privilege(model.cur_privilege()) ? 1 : 0;
  // A second fetch without instret means the previous insn was abandoned.
  if (m_have_inst) {
    reset_instruction_buffer();
  }
  m_pending_pc = model.pc();
  m_pending_inst = opcode.bits;
  m_have_inst = true;
}

void rvvi_text_callbacks::xreg_full_write_callback(ModelImpl &, const_sail_string, sbits reg, sbits value) {
  record_reg('X', reg.bits, hex_value(value));
}

void rvvi_text_callbacks::freg_write_callback(ModelImpl &model, unsigned reg, sbits value) {
  if (model.has_float_registers()) {
    record_reg('F', reg, hex_value(value));
  }
}

void rvvi_text_callbacks::csr_full_write_callback(ModelImpl &, const_sail_string, unsigned reg, sbits value) {
  record_reg('C', reg, hex_value(value));
}

void rvvi_text_callbacks::vreg_write_callback(ModelImpl &model, unsigned reg, lbits value) {
  if (model.has_vector_registers()) {
    record_reg('V', reg, hex_value_lbits(value));
  }
}

void rvvi_text_callbacks::ptw_step_callback(
  ModelImpl &,
  ModelImpl::TranslationStage stage,
  int64_t level,
  sbits pte_addr,
  uint64_t pte
) {
  assert(m_cur_mem_trace);
  m_cur_mem_trace->ptw_steps.push_back({stage, level, pte_addr.bits, pte});
}

void rvvi_text_callbacks::address_translation_start_callback(
  ModelImpl &,
  ModelImpl::Privilege privilege,
  sbits vaddr,
  ModelImpl::MemoryAccessType access,
  int64_t width
) {
  if (m_cur_mem_trace) {
    m_mem_traces.push_back(std::move(m_cur_mem_trace));
  }
  m_cur_mem_trace = std::make_unique<MemoryAccessTrace>(privilege, vaddr.bits, access, width);
}

void rvvi_text_callbacks::address_translated_callback(
  ModelImpl &,
  ModelImpl::TranslationStage stage,
  sbits vaddr,
  sbits paddr,
  ModelImpl::MemoryAccessType,
  int64_t width
) {
  assert(m_cur_mem_trace);
  assert(m_cur_mem_trace->width == width);

  switch (stage) {
  case hart::zS_Stage:
    assert(m_cur_mem_trace->virt_addr == vaddr.bits);
    m_cur_mem_trace->phys_addr = paddr.bits;
    // End this trace.
    m_mem_traces.push_back(std::move(m_cur_mem_trace));
    break;
  case hart::zVS_Stage:
    assert(m_cur_mem_trace->virt_addr == vaddr.bits);
    m_cur_mem_trace->guest_phys_addr = paddr.bits;
    break;
  case hart::zG_Stage:
    assert(m_cur_mem_trace->guest_phys_addr.has_value());
    assert(m_cur_mem_trace->guest_phys_addr.value() == vaddr.bits);
    m_cur_mem_trace->phys_addr = paddr.bits;
    // End this trace.
    m_mem_traces.push_back(std::move(m_cur_mem_trace));
    break;
  }
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

  if (m_cur_mem_trace) {
    m_mem_traces.push_back(std::move(m_cur_mem_trace));
  }
}

void rvvi_text_callbacks::post_step_callback(ModelImpl &model, bool) {
  // Retired insns are emitted from instret_callback. Traps skip instret.
  if (m_have_inst && m_pending_trap) {
    emit_instruction(model);
    reset_instruction_buffer();
  }
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

bool rvvi_text_callbacks::MemoryAccessTrace::is_eligible(ModelImpl &model) const {
  // For now, print only complete traces.
  if (!phys_addr.has_value()) {
    return false;
  }
  // If a store-conditional did not match its reservation, it does not
  // access memory.
  if (model.is_store_conditional(access_type) && !model.last_reservation_match()) {
    return false;
  }
  return true;
}

std::string rvvi_text_callbacks::MemoryAccessTrace::print(ModelImpl &model) const {
  // For now, print only complete traces.
  assert(phys_addr.has_value());

  std::ostringstream buf;
  // The python linter/checker scripts expect uppercase hex.  This should not
  // be strictly necessary.
  buf << std::uppercase;
  buf << "MEM ";
  // "bus"
  buf << (model.is_fetch(access_type) ? "I " : "D ");
  // "bytes"
  buf << std::dec << width;
  // "vaddr"
  buf << " 0x" << std::hex << virt_addr;
  // "paddr"
  buf << " 0x" << std::hex << phys_addr.value();
  // "count"
  auto count = (ptw_steps.size() * 2) + (guest_phys_addr.has_value() ? 1 : 0);
  buf << " " << std::dec << count;
  for (const auto &step : ptw_steps) {
    bool is_gstage = is_GStage(step.stage);
    // pte
    buf << (is_gstage ? " GPTE " : " PTE ");
    buf << "0x" << std::hex << step.pte;
    // pt
    buf << (is_gstage ? " GPT " : " PT ");
    buf << page_type_letter(step.level);
  }
  if (guest_phys_addr.has_value()) {
    buf << " GPADDR 0x" << std::hex << guest_phys_addr.value();
  }
  return buf.str();
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

  for (const auto &mem : m_mem_traces) {
    if (mem->is_eligible(model)) {
      std::string mem_record = mem->print(model);
      fprintf(m_trace_log, " %s", mem_record.c_str());
    }
  }

  fprintf(m_trace_log, " MODE 0x%llX", static_cast<unsigned long long>(m_event_mode));
  fprintf(m_trace_log, " VIRT 0x%X\n", m_event_virt);
}
