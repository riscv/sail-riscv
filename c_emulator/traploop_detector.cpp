#include "traploop_detector.h"
#include "sail_riscv_model.h"
#include <cstdlib>
#include <inttypes.h>

traploop_detector::traploop_detector() {
  reset();
}

void traploop_detector::reset() {
  trap_count = 0;
  trap_mepc = 0;
  trap_sepc = 0;
  xret_count = 0;
}

void traploop_detector::trap_callback(hart::Model &model, bool, fbits) {
  trap_count++;
  trap_mepc = model.zmepc.bits;
  trap_sepc = model.zsepc.bits;
}

void traploop_detector::xret_callback(hart::Model &, bool) {
  xret_count++;
}

bool traploop_detector::loop_detected() {
  // It would be very unusual to have xrets exceeding trap-count by a
  // large amount.  Should this be handled as well?
  uint64_t diff = (trap_count > xret_count) ? trap_count - xret_count : 0;
  return (diff > trap_count_threshold);
}

uint64_t traploop_detector::mepc() const {
  return trap_mepc;
}

uint64_t traploop_detector::sepc() const {
  return trap_sepc;
}
