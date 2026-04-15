#pragma once
#include "riscv_callbacks_if.h"
#include "sail.h"

class traploop_detector : public callbacks_if {

public:
  explicit traploop_detector();

  bool loop_detected() const;
  void reset();

  uint64_t mepc() const;
  uint64_t sepc() const;

  // callbacks_if
  void trap_callback(hart::Model &model, bool is_interrupt, fbits cause) override;
  void xret_callback(hart::Model &model, bool is_mret) override;
  void instret_callback(hart::Model &model) override;

private:
  uint64_t mepc_at_first_trap = 0;
  uint64_t sepc_at_first_trap = 0;
  uint32_t instrets_since_last_trap = 0;
  uint32_t nested_trap_count = 0;

  // A trap loop is detected if the nested trap count goes higher than
  // this threshold.
  const uint32_t nested_trap_count_threshold = 10;
  // If instrets since the last trap exceed this, a tight nested trap loop
  // is unlikely and the detector is reset.
  const uint32_t instrets_to_reset_loop = 20;
};
