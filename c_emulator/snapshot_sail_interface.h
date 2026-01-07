#pragma once

#include <cstdint>
#include <vector>
#include <map>
#include <string>

#include "sail.h"
#include "sail_riscv_model.h"

namespace snapshot {

// PC state structure
struct PCState {
  uint64_t pc;
  uint64_t next_pc;
};

// Get PC values from model
PCState get_pc(hart::Model &model);

// Set PC values in model
void set_pc(hart::Model &model, uint64_t pc, uint64_t next_pc);

// Get all integer registers
std::vector<uint64_t> get_xregs(hart::Model &model);

// Set all integer registers
void set_xregs(hart::Model &model, const std::vector<uint64_t> &regs);

// Get all floating point registers
std::vector<uint64_t> get_fregs(hart::Model &model);

// Set all floating point registers
void set_fregs(hart::Model &model, const std::vector<uint64_t> &regs);

// Get all vector registers
std::vector<std::vector<uint8_t>> get_vregs(hart::Model &model);

// Set all vector registers
void set_vregs(hart::Model &model, const std::vector<std::vector<uint8_t>> &regs);

// Get all accessible CSRs
// Returns map of CSR address -> value
std::map<uint16_t, uint64_t> get_csrs(hart::Model &model);

// Set a CSR value
void set_csr(hart::Model &model, uint16_t addr, uint64_t value);

// Get current privilege level
std::string get_cur_privilege(hart::Model &model);

// Get hart state
std::string get_hart_state(hart::Model &model);

} // namespace snapshot

