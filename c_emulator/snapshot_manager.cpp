#include "snapshot_manager.h"

#include <ctime>
#include <fstream>
#include <iomanip>
#include <sstream>
#include <filesystem>
#include <set>

#include "snapshot_sail_interface.h"
#include "snapshot_format.h"
#include "snapshot_memory.h"

namespace snapshot {

SnapshotManager::SnapshotManager(hart::Model &model) : m_model(model) {}

std::string get_current_timestamp() {
  auto now = std::time(nullptr);
  auto tm = *std::gmtime(&now);
  std::stringstream ss;
  ss << std::put_time(&tm, "%Y-%m-%dT%H:%M:%SZ");
  return ss.str();
}

std::unique_ptr<SnapshotState> SnapshotManager::capture_state() {
  auto state = std::make_unique<SnapshotState>();

  // Capture configuration
  if (!capture_config(*state)) {
    return nullptr;
  }

  // Capture PC
  PCState pc_state = get_pc(m_model);
  state->pc = pc_state.pc;
  state->next_pc = pc_state.next_pc;

  // Capture registers
  if (!capture_registers(*state)) {
    return nullptr;
  }

  // Capture CSRs
  if (!capture_csrs(*state)) {
    return nullptr;
  }

  // Capture platform state
  if (!capture_platform_state(*state)) {
    return nullptr;
  }

  // Set metadata
  state->metadata.timestamp = get_current_timestamp();
  state->metadata.sail_version = "unknown";  // TODO: Get from build info
  state->metadata.model_version = "unknown";  // TODO: Get from build info

  return state;
}

bool SnapshotManager::create_snapshot(const std::string &filepath,
                                      const std::string &reason,
                                      const std::string &notes) {
  // Capture state
  auto state = capture_state();
  if (!state) {
    return false;
  }

  state->metadata.reason = reason;
  state->metadata.notes = notes;

  // Determine base path for memory files
  std::filesystem::path json_path(filepath);
  std::filesystem::path base_dir = json_path.parent_path();
  std::string base_name = json_path.stem().string();

  std::string mem_file = (base_dir / (base_name + "_memory.bin")).string();
  std::string index_file = (base_dir / (base_name + "_memory_index.json")).string();

  state->memory_file = std::filesystem::path(mem_file).filename().string();
  state->memory_index_file = std::filesystem::path(index_file).filename().string();

  // Dump memory
  MemoryIndex mem_index;
  if (!dump_memory((base_dir / base_name).string(), mem_index)) {
    return false;
  }

  // Serialize memory index
  if (!serialize_memory_index(mem_index, index_file)) {
    return false;
  }

  // Serialize snapshot
  if (!serialize_snapshot(*state, filepath)) {
    return false;
  }

  return true;
}

bool SnapshotManager::restore_snapshot(const std::string &filepath) {
  SnapshotState state;

  // Deserialize snapshot
  if (!deserialize_snapshot(state, filepath)) {
    return false;
  }

  // Validate configuration
  // TODO: Check if current model configuration matches snapshot

  // Determine base path for memory files
  std::filesystem::path json_path(filepath);
  std::filesystem::path base_dir = json_path.parent_path();
  std::string base_name = json_path.stem().string();

  // Load memory index
  std::string index_file = (base_dir / state.memory_index_file).string();
  MemoryIndex mem_index;
  if (!deserialize_memory_index(mem_index, index_file)) {
    return false;
  }

  // Restore memory
  if (!restore_memory((base_dir / base_name).string(), mem_index)) {
    return false;
  }

  // Restore state
  if (!restore_state(state)) {
    return false;
  }

  return true;
}

std::unique_ptr<SnapshotMetadata> SnapshotManager::get_metadata(const std::string &filepath) {
  SnapshotState state;
  if (!deserialize_snapshot(state, filepath)) {
    return nullptr;
  }

  auto metadata = std::make_unique<SnapshotMetadata>(state.metadata);
  return metadata;
}

bool SnapshotManager::validate_snapshot(const std::string &filepath) {
  SnapshotState state;
  if (!deserialize_snapshot(state, filepath)) {
    return false;
  }

  // Check version
  if (state.metadata.version != "1.0") {
    return false;
  }

  // Check that memory files exist
  std::filesystem::path json_path(filepath);
  std::filesystem::path base_dir = json_path.parent_path();

  std::string mem_file = (base_dir / state.memory_file).string();
  std::string index_file = (base_dir / state.memory_index_file).string();

  if (!std::filesystem::exists(mem_file) || !std::filesystem::exists(index_file)) {
    return false;
  }

  return true;
}

bool SnapshotManager::capture_config(SnapshotState &state) {
  // TODO: Get configuration from model
  // For now, set defaults
  state.config.xlen = 64;  // TODO: Get from model.zxlen
  state.config.flen = 64;
  state.config.vlen = 256;
  state.config.extensions = {"I", "M", "A"};  // TODO: Get from model
  state.config.isa_string = "rv64ima";  // TODO: Get from model

  return true;
}

bool SnapshotManager::capture_registers(SnapshotState &state) {
  // Capture integer registers
  state.xregs = get_xregs(m_model);
  if (state.xregs.size() != 32) {
    return false;
  }

  // Capture floating point registers (if enabled)
  state.fregs = get_fregs(m_model);
  // Note: fregs may be empty if extension not enabled

  // Capture vector registers (if enabled)
  state.vregs = get_vregs(m_model);
  // Note: vregs may be empty if extension not enabled

  return true;
}

bool SnapshotManager::restore_registers(const SnapshotState &state) {
  // Restore integer registers
  if (state.xregs.size() != 32) {
    return false;
  }
  set_xregs(m_model, state.xregs);

  // Restore floating point registers (if present)
  if (!state.fregs.empty() && state.fregs.size() == 32) {
    set_fregs(m_model, state.fregs);
  }

  // Restore vector registers (if present)
  if (!state.vregs.empty() && state.vregs.size() == 32) {
    set_vregs(m_model, state.vregs);
  }

  return true;
}

bool SnapshotManager::capture_csrs(SnapshotState &state) {
  state.csrs = get_csrs(m_model);
  return true;
}

bool SnapshotManager::restore_csrs(const SnapshotState &state) {
  // List of read-only CSRs that should not be restored
  // These are typically machine information registers
  static const std::set<uint16_t> read_only_csrs = {
    0xf11,  // mvendorid
    0xf12,  // marchid
    0xf13,  // mimpid
    0xf14,  // mhartid
    0xf15,  // mconfigptr
  };
  
  for (const auto &pair : state.csrs) {
    // Skip read-only CSRs
    if (read_only_csrs.find(pair.first) != read_only_csrs.end()) {
      continue;
    }
    set_csr(m_model, pair.first, pair.second);
  }
  return true;
}

bool SnapshotManager::capture_platform_state(SnapshotState &state) {
  state.platform.cur_privilege = get_cur_privilege(m_model);
  state.platform.hart_state = get_hart_state(m_model);

  // TODO: Get HTIF state from model
  // state.platform.htif_tohost = ...;
  // state.platform.htif_done = ...;
  // state.platform.htif_exit_code = ...;

  // TODO: Get timer state
  // state.platform.mtime = ...;
  // state.platform.mtimecmp = ...;

  // TODO: Get reservation state
  // state.platform.reservation_valid = ...;
  // state.platform.reservation_address = ...;

  return true;
}

bool SnapshotManager::restore_platform_state(const SnapshotState &state) {
  // TODO: Restore platform state
  // This may require additional Sail functions or direct model access
  return true;
}

bool SnapshotManager::restore_state(const SnapshotState &state) {
  // Restore PC
  set_pc(m_model, state.pc, state.next_pc);

  // Restore registers
  if (!restore_registers(state)) {
    return false;
  }

  // Restore CSRs
  if (!restore_csrs(state)) {
    return false;
  }

  // Restore platform state
  if (!restore_platform_state(state)) {
    return false;
  }

  return true;
}

bool SnapshotManager::dump_memory(const std::string &base_path, MemoryIndex &index) {
  struct memory_block_info *blocks = nullptr;
  size_t count = snapshot_get_memory_blocks(&blocks);

  if (blocks == nullptr && count > 0) {
    return false;
  }

  std::string mem_file = base_path + "_memory.bin";
  std::ofstream mem_stream(mem_file, std::ios::binary);
  if (!mem_stream.is_open()) {
    snapshot_free_memory_blocks(blocks);
    return false;
  }

  index.blocks.clear();
  uint64_t offset = 0;
  uint64_t total_size = 0;

  struct memory_block_info *current = blocks;
  while (current != nullptr) {
    MemoryBlockInfo block_info;
    block_info.block_id = current->block_id;
    block_info.offset = offset;
    block_info.size = current->size;

    mem_stream.write(reinterpret_cast<const char *>(current->data), current->size);
    if (mem_stream.fail()) {
      mem_stream.close();
      snapshot_free_memory_blocks(blocks);
      return false;
    }

    index.blocks.push_back(block_info);
    offset += current->size;
    total_size += current->size;

    current = current->next;
  }

  index.total_size = total_size;
  mem_stream.close();
  snapshot_free_memory_blocks(blocks);

  return true;
}

bool SnapshotManager::restore_memory(const std::string &base_path, const MemoryIndex &index) {
  // Clear existing memory
  snapshot_clear_memory();

  std::string mem_file = base_path + "_memory.bin";
  std::ifstream mem_stream(mem_file, std::ios::binary);
  if (!mem_stream.is_open()) {
    return false;
  }

  for (const auto &block_info : index.blocks) {
    std::vector<uint8_t> data(block_info.size);
    mem_stream.read(reinterpret_cast<char *>(data.data()), block_info.size);
    if (mem_stream.fail()) {
      mem_stream.close();
      return false;
    }

    snapshot_restore_memory_block(block_info.block_id, data.data(), block_info.size);
  }

  mem_stream.close();
  return true;
}

} // namespace snapshot

