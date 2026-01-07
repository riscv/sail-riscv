#pragma once

#include <string>
#include <memory>

#include "sail_riscv_model.h"
#include "snapshot_format.h"
#include "snapshot_memory.h"

namespace snapshot {

class SnapshotManager {
public:
  explicit SnapshotManager(hart::Model &model);
  ~SnapshotManager() = default;

  // Create a snapshot of current state
  bool create_snapshot(const std::string &filepath,
                       const std::string &reason = "manual",
                       const std::string &notes = "");

  // Restore state from snapshot
  bool restore_snapshot(const std::string &filepath);

  // Get snapshot metadata without full restore
  std::unique_ptr<SnapshotMetadata> get_metadata(const std::string &filepath);

  // Validate snapshot file
  bool validate_snapshot(const std::string &filepath);

private:
  hart::Model &m_model;

  // State capture
  std::unique_ptr<SnapshotState> capture_state();

  // State restoration
  bool restore_state(const SnapshotState &state);

  // Memory operations
  bool dump_memory(const std::string &base_path, MemoryIndex &index);
  bool restore_memory(const std::string &base_path, const MemoryIndex &index);

  // Register operations
  bool capture_registers(SnapshotState &state);
  bool restore_registers(const SnapshotState &state);

  // CSR operations
  bool capture_csrs(SnapshotState &state);
  bool restore_csrs(const SnapshotState &state);

  // Platform state
  bool capture_platform_state(SnapshotState &state);
  bool restore_platform_state(const SnapshotState &state);

  // Configuration
  bool capture_config(SnapshotState &state);
};

} // namespace snapshot

