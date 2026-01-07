#pragma once

#include <cstdint>
#include <string>
#include <vector>
#include <map>
#include <memory>
#include <functional>

#include "sail.h"
#include "sail_riscv_model.h"
#include "riscv_callbacks_if.h"
#include "snapshot_manager.h"

namespace checkpoint {

// Checkpoint condition types
enum class ConditionType {
  INSTRUCTION_COUNT,  // Every N instructions
  PC_VALUE,           // When PC reaches a value
  PC_RANGE,           // When PC is in a range
  MEMORY_READ,        // When memory address is read
  MEMORY_WRITE,       // When memory address is written
  MEMORY_RANGE,       // When memory access is in a range
  REGISTER_WRITE,     // When register is written
  CSR_WRITE,          // When CSR is written
  CSR_READ,           // When CSR is read
  TRAP,               // When trap occurs
};

// Checkpoint condition
struct CheckpointCondition {
  ConditionType type;
  std::string name;  // Human-readable name for this checkpoint
  
  // Condition-specific parameters
  union {
    struct {
      uint64_t interval;  // For INSTRUCTION_COUNT
    } instruction_count;
    
    struct {
      uint64_t pc_value;
    } pc_value;
    
    struct {
      uint64_t pc_start;
      uint64_t pc_end;
    } pc_range;
    
    struct {
      uint64_t address;
    } memory_address;
    
    struct {
      uint64_t start;
      uint64_t end;
    } memory_range;
    
    struct {
      unsigned reg_index;  // For integer/float registers
      bool is_freg;        // false for xreg, true for freg
    } register_write;
    
    struct {
      uint16_t csr_addr;
    } csr_access;
  } params;
  
  // Snapshot settings
  std::string snapshot_dir;  // Directory to save snapshots
  std::string snapshot_prefix;  // Prefix for snapshot filenames
  bool auto_increment;  // Auto-increment snapshot number
  
  // State tracking
  uint64_t trigger_count;  // How many times this condition has triggered
  uint64_t last_instruction_count;  // Last instruction count when checked
};

// Checkpoint manager - implements callbacks to monitor simulation
class CheckpointManager : public callbacks_if {
public:
  explicit CheckpointManager(snapshot::SnapshotManager &snapshot_mgr);
  ~CheckpointManager() override = default;
  
  // Configuration
  void add_condition(const CheckpointCondition &condition);
  void remove_condition(const std::string &name);
  void clear_conditions();
  
  // Enable/disable checkpointing
  void set_enabled(bool enabled) { m_enabled = enabled; }
  bool is_enabled() const { return m_enabled; }
  
  // Get statistics
  uint64_t get_total_checkpoints_created() const { return m_total_checkpoints; }
  std::map<std::string, uint64_t> get_condition_stats() const;
  
  // Callback implementations
  void pre_step_callback(hart::Model &model, bool is_waiting) override;
  void post_step_callback(hart::Model &model, bool is_waiting) override;
  void pc_write_callback(hart::Model &model, sbits new_pc) override;
  void mem_read_callback(hart::Model &model, const char *type,
                         sbits paddr, uint64_t width, lbits value) override;
  void mem_write_callback(hart::Model &model, const char *type,
                          sbits paddr, uint64_t width, lbits value) override;
  void xreg_full_write_callback(hart::Model &model,
                                 const_sail_string abi_name, sbits reg,
                                 sbits value) override;
  void freg_write_callback(hart::Model &model, unsigned reg,
                           sbits value) override;
  void csr_full_write_callback(hart::Model &model,
                                const_sail_string csr_name, unsigned reg,
                                sbits value) override;
  void csr_full_read_callback(hart::Model &model,
                               const_sail_string csr_name, unsigned reg,
                               sbits value) override;
  void trap_callback(hart::Model &model, bool is_interrupt,
                     fbits cause) override;
  
  // Other callbacks (no-op for now)
  void fetch_callback(hart::Model &model, sbits opcode) override {}
  void mem_exception_callback(hart::Model &model, sbits paddr,
                              uint64_t num_of_exception) override {}
  void vreg_write_callback(hart::Model &model, unsigned reg,
                           lbits value) override {}
  void redirect_callback(hart::Model &model, sbits new_pc) override {}
  void ptw_start_callback(hart::Model &model, uint64_t vpn,
                          hart::zMemoryAccessTypezIuzK access_type,
                          hart::ztuple_z8z5enumz0zzPrivilegezCz0z5unitz9 privilege) override {}
  void ptw_step_callback(hart::Model &model, int64_t level,
                        sbits pte_addr, uint64_t pte) override {}
  void ptw_success_callback(hart::Model &model, uint64_t final_ppn,
                            int64_t level) override {}
  void ptw_fail_callback(hart::Model &model, hart::zPTW_Error error_type,
                         int64_t level, sbits pte_addr) override {}

private:
  snapshot::SnapshotManager &m_snapshot_mgr;
  std::vector<CheckpointCondition> m_conditions;
  bool m_enabled;
  uint64_t m_instruction_count;
  uint64_t m_total_checkpoints;
  
  // Helper to get current PC from model
  uint64_t get_pc_value(hart::Model &model);
  
  // Helper to get physical address from sbits
  uint64_t get_address_value(const sbits &addr);
  
  // Helper to get register index from sbits
  unsigned get_register_index(const sbits &reg);
  
  // Check conditions and create snapshots if needed
  void check_conditions(hart::Model &model, ConditionType trigger_type,
                        uint64_t trigger_value = 0, unsigned reg_index = 0);
  
  // Create snapshot for a condition
  bool create_checkpoint_snapshot(hart::Model &model,
                                  const CheckpointCondition &condition,
                                  const std::string &reason);
  
  // Generate snapshot filename
  std::string generate_snapshot_filename(const CheckpointCondition &condition);
};

} // namespace checkpoint

