#include "traploop_detector.h"
#include "sail_riscv_model.h"
#include <cstdlib>
#include <inttypes.h>

traploop_detector::traploop_detector() {
  reset();
}

void traploop_detector::reset() {
  mepc_at_first_trap = 0;
  sepc_at_first_trap = 0;
  instrets_since_last_trap = 0;
  nested_trap_count = 0;
}

void traploop_detector::trap_callback(hart::Model &model, bool, fbits) {
  if (nested_trap_count == 0) {
    mepc_at_first_trap = model.zmepc.bits;
    sepc_at_first_trap = model.zsepc.bits;
  }
  nested_trap_count++;
  instrets_since_last_trap = 0;
}

void traploop_detector::xret_callback(hart::Model &, bool) {
  reset();
}

void traploop_detector::instret_callback(hart::Model &) {
  if (nested_trap_count != 0) {
    instrets_since_last_trap++;
    if (instrets_since_last_trap > instrets_to_reset_loop) {
      reset();
    }
  }
}

bool traploop_detector::loop_detected() const {
  return nested_trap_count > nested_trap_count_threshold;
}

uint64_t traploop_detector::mepc() const {
  return mepc_at_first_trap;
}

uint64_t traploop_detector::sepc() const {
  return sepc_at_first_trap;
}
