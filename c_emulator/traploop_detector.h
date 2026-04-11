#pragma once
#include "riscv_callbacks_if.h"
#include "sail.h"

class traploop_detector : public callbacks_if {

public:
  explicit traploop_detector();

  bool loop_detected();
  void reset();

  uint64_t mepc() const;
  uint64_t sepc() const;

  // callbacks_if
  void trap_callback(hart::Model &model, bool is_interrupt, fbits cause) override;
  void xret_callback(hart::Model &model, bool is_mret) override;

private:
  uint64_t trap_count = 0;
  uint64_t trap_mepc = 0;
  uint64_t trap_sepc = 0;
  uint64_t xret_count = 0;
  const uint64_t trap_count_threshold = 10;
};
