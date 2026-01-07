#include "checkpoint_manager.h"

#include <algorithm>
#include <cstring>
#include <filesystem>
#include <iomanip>
#include <sstream>
#include <stdexcept>

#include "snapshot_sail_interface.h"
#include "sail.h"

// Helper function to get uint64_t from sbits (same as in snapshot_sail_interface.cpp)
namespace {
uint64_t get_sbits_value(const sbits &sb) {
  return sb.bits;  // sbits has .bits and .len fields
}
}

namespace checkpoint {

CheckpointManager::CheckpointManager(snapshot::SnapshotManager &snapshot_mgr)
  : m_snapshot_mgr(snapshot_mgr)
  , m_enabled(true)
  , m_instruction_count(0)
  , m_total_checkpoints(0)
{
}

void CheckpointManager::add_condition(const CheckpointCondition &condition)
{
  // Check for duplicate names
  auto it = std::find_if(m_conditions.begin(), m_conditions.end(),
                         [&condition](const CheckpointCondition &c) {
                           return c.name == condition.name;
                         });
  if (it != m_conditions.end()) {
    throw std::runtime_error("Checkpoint condition with name '" + condition.name +
                            "' already exists");
  }
  
  CheckpointCondition new_condition = condition;
  new_condition.trigger_count = 0;
  new_condition.last_instruction_count = 0;
  m_conditions.push_back(new_condition);
}

void CheckpointManager::remove_condition(const std::string &name)
{
  m_conditions.erase(
    std::remove_if(m_conditions.begin(), m_conditions.end(),
                   [&name](const CheckpointCondition &c) {
                     return c.name == name;
                   }),
    m_conditions.end());
}

void CheckpointManager::clear_conditions()
{
  m_conditions.clear();
}

std::map<std::string, uint64_t> CheckpointManager::get_condition_stats() const
{
  std::map<std::string, uint64_t> stats;
  for (const auto &condition : m_conditions) {
    stats[condition.name] = condition.trigger_count;
  }
  return stats;
}

void CheckpointManager::pre_step_callback(hart::Model &model, bool is_waiting)
{
  if (!m_enabled || is_waiting) {
    return;
  }
  
  // Check instruction count conditions
  for (auto &condition : m_conditions) {
    if (condition.type == ConditionType::INSTRUCTION_COUNT) {
      if (m_instruction_count >= condition.last_instruction_count +
          condition.params.instruction_count.interval) {
        condition.last_instruction_count = m_instruction_count;
        check_conditions(model, ConditionType::INSTRUCTION_COUNT, m_instruction_count);
      }
    }
  }
}

void CheckpointManager::post_step_callback(hart::Model &model, bool is_waiting)
{
  if (!m_enabled || is_waiting) {
    return;
  }
  
  m_instruction_count++;
  
  // Also check PC conditions after step (PC is now updated)
  uint64_t pc = get_pc_value(model);
  for (const auto &condition : m_conditions) {
    if (condition.type == ConditionType::PC_VALUE) {
      if (pc == condition.params.pc_value.pc_value) {
        check_conditions(model, ConditionType::PC_VALUE, pc);
      }
    } else if (condition.type == ConditionType::PC_RANGE) {
      if (pc >= condition.params.pc_range.pc_start &&
          pc <= condition.params.pc_range.pc_end) {
        check_conditions(model, ConditionType::PC_RANGE, pc);
      }
    }
  }
}

void CheckpointManager::pc_write_callback(hart::Model &model, sbits new_pc)
{
  if (!m_enabled) {
    return;
  }
  
  // Use the new_pc parameter directly (it's the PC being written)
  uint64_t pc = get_address_value(new_pc);
  
  // Check PC value and range conditions
  for (const auto &condition : m_conditions) {
    if (condition.type == ConditionType::PC_VALUE) {
      if (pc == condition.params.pc_value.pc_value) {
        check_conditions(model, ConditionType::PC_VALUE, pc);
      }
    } else if (condition.type == ConditionType::PC_RANGE) {
      if (pc >= condition.params.pc_range.pc_start &&
          pc <= condition.params.pc_range.pc_end) {
        check_conditions(model, ConditionType::PC_RANGE, pc);
      }
    }
  }
}

void CheckpointManager::mem_read_callback(hart::Model &model, [[maybe_unused]] const char *type,
                                          sbits paddr, [[maybe_unused]] uint64_t width, [[maybe_unused]] lbits value)
{
  if (!m_enabled) {
    return;
  }
  
  uint64_t addr = get_address_value(paddr);
  
  // Check memory read conditions
  for (const auto &condition : m_conditions) {
    if (condition.type == ConditionType::MEMORY_READ) {
      if (addr == condition.params.memory_address.address) {
        check_conditions(model, ConditionType::MEMORY_READ, addr);
      }
    } else if (condition.type == ConditionType::MEMORY_RANGE) {
      if (addr >= condition.params.memory_range.start &&
          addr <= condition.params.memory_range.end) {
        check_conditions(model, ConditionType::MEMORY_RANGE, addr);
      }
    }
  }
}

void CheckpointManager::mem_write_callback(hart::Model &model, [[maybe_unused]] const char *type,
                                           sbits paddr, [[maybe_unused]] uint64_t width, [[maybe_unused]] lbits value)
{
  if (!m_enabled) {
    return;
  }
  
  uint64_t addr = get_address_value(paddr);
  
  // Check memory write conditions
  for (const auto &condition : m_conditions) {
    if (condition.type == ConditionType::MEMORY_WRITE) {
      if (addr == condition.params.memory_address.address) {
        check_conditions(model, ConditionType::MEMORY_WRITE, addr);
      }
    } else if (condition.type == ConditionType::MEMORY_RANGE) {
      if (addr >= condition.params.memory_range.start &&
          addr <= condition.params.memory_range.end) {
        check_conditions(model, ConditionType::MEMORY_RANGE, addr);
      }
    }
  }
}

void CheckpointManager::xreg_full_write_callback(hart::Model &model,
                                                 [[maybe_unused]] const_sail_string abi_name,
                                                 sbits reg, [[maybe_unused]] sbits value)
{
  if (!m_enabled) {
    return;
  }
  
  unsigned reg_index = get_register_index(reg);
  
  // Check register write conditions
  for (const auto &condition : m_conditions) {
    if (condition.type == ConditionType::REGISTER_WRITE &&
        !condition.params.register_write.is_freg &&
        reg_index == condition.params.register_write.reg_index) {
      check_conditions(model, ConditionType::REGISTER_WRITE, 0, reg_index);
    }
  }
}

void CheckpointManager::freg_write_callback(hart::Model &model, unsigned reg,
                                            [[maybe_unused]] sbits value)
{
  if (!m_enabled) {
    return;
  }
  
  // Check floating point register write conditions
  for (const auto &condition : m_conditions) {
    if (condition.type == ConditionType::REGISTER_WRITE &&
        condition.params.register_write.is_freg &&
        reg == condition.params.register_write.reg_index) {
      check_conditions(model, ConditionType::REGISTER_WRITE, 0, reg);
    }
  }
}

void CheckpointManager::csr_full_write_callback(hart::Model &model,
                                                 [[maybe_unused]] const_sail_string csr_name,
                                                 unsigned reg, [[maybe_unused]] sbits value)
{
  if (!m_enabled) {
    return;
  }
  
  // Check CSR write conditions
  for (const auto &condition : m_conditions) {
    if (condition.type == ConditionType::CSR_WRITE &&
        reg == condition.params.csr_access.csr_addr) {
      check_conditions(model, ConditionType::CSR_WRITE, reg);
    }
  }
}

void CheckpointManager::csr_full_read_callback(hart::Model &model,
                                                [[maybe_unused]] const_sail_string csr_name,
                                                unsigned reg, [[maybe_unused]] sbits value)
{
  if (!m_enabled) {
    return;
  }
  
  // Check CSR read conditions
  for (const auto &condition : m_conditions) {
    if (condition.type == ConditionType::CSR_READ &&
        reg == condition.params.csr_access.csr_addr) {
      check_conditions(model, ConditionType::CSR_READ, reg);
    }
  }
}

void CheckpointManager::trap_callback(hart::Model &model, [[maybe_unused]] bool is_interrupt,
                                     fbits cause)
{
  if (!m_enabled) {
    return;
  }
  
  // Check trap conditions
  for (const auto &condition : m_conditions) {
    if (condition.type == ConditionType::TRAP) {
      check_conditions(model, ConditionType::TRAP, cause);
    }
  }
}

uint64_t CheckpointManager::get_pc_value(hart::Model &model)
{
  snapshot::PCState pc_state = snapshot::get_pc(model);
  return pc_state.pc;
}

uint64_t CheckpointManager::get_address_value(const sbits &addr)
{
  return get_sbits_value(addr);
}

unsigned CheckpointManager::get_register_index(const sbits &reg)
{
  return static_cast<unsigned>(get_sbits_value(reg));
}

void CheckpointManager::check_conditions(hart::Model &model,
                                         ConditionType trigger_type,
                                         uint64_t trigger_value,
                                         unsigned reg_index)
{
  for (auto &condition : m_conditions) {
    if (condition.type == trigger_type) {
      // Additional type-specific matching
      bool matches = true;
      
      if (trigger_type == ConditionType::REGISTER_WRITE) {
        matches = (reg_index == condition.params.register_write.reg_index);
      } else if (trigger_type == ConditionType::CSR_WRITE ||
                 trigger_type == ConditionType::CSR_READ) {
        matches = (trigger_value == condition.params.csr_access.csr_addr);
      } else if (trigger_type == ConditionType::MEMORY_READ ||
                 trigger_type == ConditionType::MEMORY_WRITE) {
        matches = (trigger_value == condition.params.memory_address.address);
      }
      
      if (matches) {
        condition.trigger_count++;
        std::string reason = "Checkpoint: " + condition.name + " (trigger #" +
                            std::to_string(condition.trigger_count) + ")";
        if (create_checkpoint_snapshot(model, condition, reason)) {
          m_total_checkpoints++;
        }
      }
    }
  }
}

bool CheckpointManager::create_checkpoint_snapshot([[maybe_unused]] hart::Model &model,
                                                   const CheckpointCondition &condition,
                                                   const std::string &reason)
{
  std::string filename = generate_snapshot_filename(condition);
  std::string filepath;
  
  if (!condition.snapshot_dir.empty()) {
    std::filesystem::path dir(condition.snapshot_dir);
    if (!std::filesystem::exists(dir)) {
      std::filesystem::create_directories(dir);
    }
    filepath = (dir / filename).string();
  } else {
    filepath = filename;
  }
  
  std::string notes = "Auto-generated checkpoint: " + condition.name;
  return m_snapshot_mgr.create_snapshot(filepath, reason, notes);
}

std::string CheckpointManager::generate_snapshot_filename(const CheckpointCondition &condition)
{
  std::ostringstream oss;
  
  if (!condition.snapshot_prefix.empty()) {
    oss << condition.snapshot_prefix;
  } else {
    oss << "checkpoint_" << condition.name;
  }
  
  if (condition.auto_increment) {
    oss << "_" << std::setfill('0') << std::setw(6) << condition.trigger_count;
  }
  
  oss << ".snapshot";
  
  return oss.str();
}

} // namespace checkpoint

