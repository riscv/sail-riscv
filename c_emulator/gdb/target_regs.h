#pragma once

#include <cstdint>
#include <string>

class ModelImpl;

// The indices of the registers in the register map.
struct register_map {
  // Registers before the PC are integer (X) registers, 0-31.
  int64_t pc_offset; // = 32 for the (non-E) base ISA.
  // Registers after the PC but before CSRs are floating-point
  // registers.
  int64_t fpr_offset; // = pc_offset + 1
  // Register after the floating-point registers.
  int64_t fcsr_offset;
  // TODO: add a CSR map.
};

register_map get_register_map();

// Generates the response for `qXfer:features:read:target.xml`.
std::string get_target_xml(const ModelImpl &model);

// TODO: make these take `const ModelImpl &`.

// Generates the response for `g` (read general registers).
std::string get_general_regs(ModelImpl &model);
// Generates the response for `p` (read register).
std::string get_register(ModelImpl &model, uint64_t regidx);
// Generates the response for `P` (write register).
std::string set_register(ModelImpl &model, uint64_t regidx, uint64_t val);
