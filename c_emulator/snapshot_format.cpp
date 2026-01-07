#include "snapshot_format.h"

#include <fstream>
#include <iomanip>
#include <sstream>

#include "jsoncons/json.hpp"

namespace snapshot {

// Helper to convert uint64_t to hex string
std::string uint64_to_hex(uint64_t value) {
  std::stringstream ss;
  ss << "0x" << std::hex << std::uppercase << value;
  return ss.str();
}

// Helper to parse hex string to uint64_t
uint64_t hex_to_uint64(const std::string &str) {
  if (str.empty() || str[0] != '0' || (str.size() > 1 && str[1] != 'x' && str[1] != 'X')) {
    return 0;
  }
  return std::stoull(str, nullptr, 16);
}

bool serialize_snapshot(const SnapshotState &state, const std::string &filepath) {
  try {
    jsoncons::json j;

    // Version and metadata
    j["version"] = state.metadata.version;
    j["timestamp"] = state.metadata.timestamp;
    j["sail_version"] = state.metadata.sail_version;
    j["model_version"] = state.metadata.model_version;

    // Configuration
    jsoncons::json config;
    config["xlen"] = state.config.xlen;
    config["flen"] = state.config.flen;
    config["vlen"] = state.config.vlen;
    config["extensions"] = jsoncons::json::array(state.config.extensions.begin(),
                                                 state.config.extensions.end());
    config["isa_string"] = state.config.isa_string;
    j["configuration"] = config;

    // Registers
    jsoncons::json registers;
    registers["pc"] = uint64_to_hex(state.pc);
    registers["next_pc"] = uint64_to_hex(state.next_pc);

    jsoncons::json xregs_obj;
    for (size_t i = 0; i < state.xregs.size() && i < 32; i++) {
      std::string reg_name = "x" + std::to_string(i);
      xregs_obj[reg_name] = uint64_to_hex(state.xregs[i]);
    }
    registers["xregs"] = xregs_obj;

    if (!state.fregs.empty()) {
      jsoncons::json fregs_obj;
      for (size_t i = 0; i < state.fregs.size() && i < 32; i++) {
        std::string reg_name = "f" + std::to_string(i);
        fregs_obj[reg_name] = uint64_to_hex(state.fregs[i]);
      }
      registers["fregs"] = fregs_obj;
    }

    if (!state.vregs.empty()) {
      jsoncons::json vregs_obj;
      for (size_t i = 0; i < state.vregs.size() && i < 32; i++) {
        std::string reg_name = "v" + std::to_string(i);
      
        std::stringstream ss;
        ss << "0x";
        for (auto it = state.vregs[i].rbegin(); it != state.vregs[i].rend(); ++it) {
          ss << std::hex << std::setfill('0') << std::setw(2)
             << static_cast<unsigned>(*it);
        }
        vregs_obj[reg_name] = ss.str();
      }
      registers["vregs"] = vregs_obj;
    }
    j["registers"] = registers;

    // CSRs
    jsoncons::json csrs_obj;
    for (const auto &pair : state.csrs) {
      std::stringstream ss;
      ss << "0x" << std::hex << std::uppercase << std::setfill('0') << std::setw(3)
         << pair.first;
      csrs_obj[ss.str()] = uint64_to_hex(pair.second);
    }
    j["csrs"] = csrs_obj;

    // Platform state
    jsoncons::json platform;
    platform["cur_privilege"] = state.platform.cur_privilege;
    platform["hart_state"] = state.platform.hart_state;
    platform["htif_tohost"] = uint64_to_hex(state.platform.htif_tohost);
    platform["htif_done"] = state.platform.htif_done;
    platform["htif_exit_code"] = uint64_to_hex(state.platform.htif_exit_code);
    platform["mtime"] = uint64_to_hex(state.platform.mtime);
    platform["mtimecmp"] = uint64_to_hex(state.platform.mtimecmp);
    platform["reservation"]["valid"] = state.platform.reservation_valid;
    platform["reservation"]["address"] = uint64_to_hex(state.platform.reservation_address);
    j["platform"] = platform;

    // Memory
    jsoncons::json memory;
    memory["format"] = "sparse_binary";
    memory["file"] = state.memory_file;
    memory["index_file"] = state.memory_index_file;
    j["memory"] = memory;

    // Metadata
    jsoncons::json metadata;
    metadata["instruction_count"] = state.metadata.instruction_count;
    metadata["checkpoint_reason"] = state.metadata.reason;
    metadata["notes"] = state.metadata.notes;
    j["metadata"] = metadata;

    // Write to file
    std::ofstream file(filepath);
    if (!file.is_open()) {
      return false;
    }
    file << jsoncons::pretty_print(j);
    file.close();

    return true;
  } catch (...) {
    return false;
  }
}

bool deserialize_snapshot(SnapshotState &state, const std::string &filepath) {
  try {
    std::ifstream file(filepath);
    if (!file.is_open()) {
      return false;
    }

    jsoncons::json j = jsoncons::json::parse(file);
    file.close();

    // Version and metadata
    state.metadata.version = j["version"].as_string();
    state.metadata.timestamp = j["timestamp"].as_string();
    state.metadata.sail_version = j["sail_version"].as_string();
    state.metadata.model_version = j["model_version"].as_string();

    // Configuration
    const auto &config = j["configuration"];
    state.config.xlen = config["xlen"].as<uint64_t>();
    state.config.flen = config["flen"].as<uint64_t>();
    state.config.vlen = config["vlen"].as<uint64_t>();
    state.config.extensions.clear();
    for (const auto &ext : config["extensions"].array_range()) {
      state.config.extensions.push_back(ext.as_string());
    }
    state.config.isa_string = config["isa_string"].as_string();

    // Registers
    const auto &registers = j["registers"];
    state.pc = hex_to_uint64(registers["pc"].as_string());
    state.next_pc = hex_to_uint64(registers["next_pc"].as_string());

    state.xregs.clear();
    state.xregs.resize(32, 0);
    const auto &xregs_obj = registers["xregs"];
    for (size_t i = 0; i < 32; i++) {
      std::string reg_name = "x" + std::to_string(i);
      if (xregs_obj.contains(reg_name)) {
        state.xregs[i] = hex_to_uint64(xregs_obj[reg_name].as_string());
      }
    }

    if (registers.contains("fregs")) {
      state.fregs.clear();
      state.fregs.resize(32, 0);
      const auto &fregs_obj = registers["fregs"];
      for (size_t i = 0; i < 32; i++) {
        std::string reg_name = "f" + std::to_string(i);
        if (fregs_obj.contains(reg_name)) {
          state.fregs[i] = hex_to_uint64(fregs_obj[reg_name].as_string());
        }
      }
    }

    if (registers.contains("vregs")) {
      state.vregs.clear();
      state.vregs.resize(32);
      const auto &vregs_obj = registers["vregs"];
      for (size_t i = 0; i < 32; i++) {
        std::string reg_name = "v" + std::to_string(i);
        if (vregs_obj.contains(reg_name)) {
          std::string hex_str = vregs_obj[reg_name].as_string();
    
          if (hex_str.size() >= 2 && hex_str.substr(0, 2) == "0x") {
            hex_str = hex_str.substr(2);
            state.vregs[i].clear();
            for (size_t j = 0; j < hex_str.size(); j += 2) {
              std::string byte_str = hex_str.substr(j, 2);
              uint8_t byte = static_cast<uint8_t>(std::stoul(byte_str, nullptr, 16));
              state.vregs[i].push_back(byte);
            }
          }
        }
      }
    }

    // CSRs
    state.csrs.clear();
    const auto &csrs_obj = j["csrs"];
    for (const auto &pair : csrs_obj.object_range()) {
      uint16_t addr = static_cast<uint16_t>(hex_to_uint64(pair.key()));
      uint64_t value = hex_to_uint64(pair.value().as_string());
      state.csrs[addr] = value;
    }

    // Platform state
    const auto &platform = j["platform"];
    state.platform.cur_privilege = platform["cur_privilege"].as_string();
    state.platform.hart_state = platform["hart_state"].as_string();
    state.platform.htif_tohost = hex_to_uint64(platform["htif_tohost"].as_string());
    state.platform.htif_done = platform["htif_done"].as<bool>();
    state.platform.htif_exit_code = hex_to_uint64(platform["htif_exit_code"].as_string());
    state.platform.mtime = hex_to_uint64(platform["mtime"].as_string());
    state.platform.mtimecmp = hex_to_uint64(platform["mtimecmp"].as_string());
    state.platform.reservation_valid = platform["reservation"]["valid"].as<bool>();
    state.platform.reservation_address =
        hex_to_uint64(platform["reservation"]["address"].as_string());

    // Memory
    const auto &memory = j["memory"];
    state.memory_file = memory["file"].as_string();
    state.memory_index_file = memory["index_file"].as_string();

    // Metadata
    const auto &metadata = j["metadata"];
    state.metadata.instruction_count = metadata["instruction_count"].as<uint64_t>();
    state.metadata.reason = metadata["checkpoint_reason"].as_string();
    state.metadata.notes = metadata["notes"].as_string();

    return true;
  } catch (...) {
    return false;
  }
}

bool serialize_memory_index(const MemoryIndex &index, const std::string &filepath) {
  try {
    jsoncons::json j;
    j["total_size"] = index.total_size;

    jsoncons::json blocks_array = jsoncons::json::array();
    for (const auto &block : index.blocks) {
      jsoncons::json block_obj;
      block_obj["block_id"] = uint64_to_hex(block.block_id);
      block_obj["offset"] = block.offset;
      block_obj["size"] = block.size;
      blocks_array.push_back(block_obj);
    }
    j["blocks"] = blocks_array;

    std::ofstream file(filepath);
    if (!file.is_open()) {
      return false;
    }
    file << jsoncons::pretty_print(j);
    file.close();

    return true;
  } catch (...) {
    return false;
  }
}

bool deserialize_memory_index(MemoryIndex &index, const std::string &filepath) {
  try {
    std::ifstream file(filepath);
    if (!file.is_open()) {
      return false;
    }

    jsoncons::json j = jsoncons::json::parse(file);
    file.close();

    index.total_size = j["total_size"].as<uint64_t>();
    index.blocks.clear();

    for (const auto &block_obj : j["blocks"].array_range()) {
      MemoryBlockInfo block;
      block.block_id = hex_to_uint64(block_obj["block_id"].as_string());
      block.offset = block_obj["offset"].as<uint64_t>();
      block.size = block_obj["size"].as<uint64_t>();
      index.blocks.push_back(block);
    }

    return true;
  } catch (...) {
    return false;
  }
}

} // namespace snapshot

