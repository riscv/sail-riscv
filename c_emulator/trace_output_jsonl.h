#pragma once

#include <fstream>
#include <string>

#include "riscv_callbacks_if.h"

// See `doc/jsonl` for the schema and documentation. Please update it if you make changes!

class trace_output_jsonl : public callbacks_if {
public:
  // Open a file (closes any existing ones).
  void open(const std::string &filename);

  // Flush and close the trace if it is open (safe to call if it isn't).
  void close();

  // Currently must be called manually.
  void pre_step_callback(hart::Model &model, bool waiting) override;
  void post_step_callback(hart::Model &model, bool waiting) override;

  // Callbacks from the model.
  void fetch_callback(hart::Model &model, sbits opcode) override;
  void mem_write_callback(hart::Model &model, const char *type, sbits paddr, uint64_t width, lbits value) override;
  void mem_read_callback(hart::Model &model, const char *type, sbits paddr, uint64_t width, lbits value) override;
  void xreg_full_write_callback(hart::Model &model, const_sail_string abi_name, sbits reg, sbits value) override;
  void freg_write_callback(hart::Model &model, unsigned reg, sbits value) override;
  void csr_full_write_callback(hart::Model &model, const_sail_string csr_name, unsigned reg, sbits value) override;
  void vreg_write_callback(hart::Model &model, unsigned reg, lbits value) override;
  void pc_write_callback(hart::Model &model, sbits new_pc) override;
  void redirect_callback(hart::Model &model, sbits new_pc) override;
  void trap_callback(hart::Model &model, bool is_interrupt, fbits cause) override;

private:
  std::ofstream m_ofs;

  std::string m_x_writes;
  std::string m_f_writes;
  std::string m_v_writes;
  std::string m_csr_writes;

  std::string m_loads;
  std::string m_stores;
};
