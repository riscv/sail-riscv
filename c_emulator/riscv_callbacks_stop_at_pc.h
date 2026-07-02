#pragma once

#include <cstdint>

#include "riscv_callbacks_if.h"
#include "sail.h"

class stop_at_pc_callbacks : public callbacks_if {
public:
  explicit stop_at_pc_callbacks(uint64_t pc) : m_pc(pc) {
  }

  bool stop_requested() const {
    return m_stop_requested;
  }

  void pc_write_callback(ModelImpl &, sbits new_pc) override {
    if (new_pc.bits == m_pc) {
      m_stop_requested = true;
    }
  }

private:
  uint64_t m_pc = 0;
  bool m_stop_requested = false;
};
