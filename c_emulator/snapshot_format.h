#pragma once

#include <cstdint>
#include <map>
#include <string>
#include <vector>

namespace snapshot {

// Snapshot metadata structure
struct SnapshotMetadata {
  std::string version = "1.0";
  std::string timestamp;
  std::string sail_version;
  std::string model_version;
  uint64_t instruction_count = 0;
  std::string reason = "manual";
  std::string notes;
};

// Configuration information
struct SnapshotConfig {
  uint64_t xlen = 64;
  uint64_t flen = 64;
  uint64_t vlen = 256;
  std::vector<std::string> extensions;
  std::string isa_string;
};

// Platform state
struct PlatformState {
  std::string cur_privilege;
  std::string hart_state;
  uint64_t htif_tohost = 0;
  bool htif_done = false;
  uint64_t htif_exit_code = 0;
  uint64_t mtime = 0;
  uint64_t mtimecmp = 0;
  bool reservation_valid = false;
  uint64_t reservation_address = 0;
};

// Complete snapshot state
struct SnapshotState {
  SnapshotConfig config;
  uint64_t pc = 0;
  uint64_t next_pc = 0;
  std::vector<uint64_t> xregs;  // 32 integer registers
  std::vector<uint64_t> fregs;  // 32 floating point registers (if enabled)
  std::vector<std::vector<uint8_t>> vregs;  // 32 vector registers (if enabled)
  std::map<uint16_t, uint64_t> csrs;  // CSR address -> value
  PlatformState platform;
  std::string memory_file;  // Path to binary memory dump
  std::string memory_index_file;  // Path to memory index JSON
  SnapshotMetadata metadata;
};

// Memory block information for index
struct MemoryBlockInfo {
  uint64_t block_id;
  uint64_t offset;
  uint64_t size;
};

// Memory index structure
struct MemoryIndex {
  std::vector<MemoryBlockInfo> blocks;
  uint64_t total_size = 0;
};

// JSON serialization functions
bool serialize_snapshot(const SnapshotState &state, const std::string &filepath);
bool deserialize_snapshot(SnapshotState &state, const std::string &filepath);

// Memory index serialization
bool serialize_memory_index(const MemoryIndex &index, const std::string &filepath);
bool deserialize_memory_index(MemoryIndex &index, const std::string &filepath);

} // namespace snapshot

