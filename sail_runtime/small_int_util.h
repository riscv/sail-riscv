#pragma once

#include "sail.h"
#include <assert.h>
#include <stdbool.h>

// Fast implementations of sail_signed and sail_unsigned when we know the
// size is <= 64 bits.

static inline bool fast_bits_lt_s(sbits x, sbits y) {
  assert(x.len >= 1);
  assert(x.len == y.len);
  return int64_t(x.bits << (64 - x.len)) < int64_t(y.bits << (64 - y.len));
}

static inline bool fast_bits_gt_s(sbits x, sbits y) {
  assert(x.len >= 1);
  assert(x.len == y.len);
  return int64_t(x.bits << (64 - x.len)) > int64_t(y.bits << (64 - y.len));
}

static inline bool fast_bits_le_s(sbits x, sbits y) {
  assert(x.len >= 1);
  assert(x.len == y.len);
  return int64_t(x.bits << (64 - x.len)) <= int64_t(y.bits << (64 - y.len));
}

static inline bool fast_bits_ge_s(sbits x, sbits y) {
  assert(x.len >= 1);
  assert(x.len == y.len);
  return int64_t(x.bits << (64 - x.len)) >= int64_t(y.bits << (64 - y.len));
}

static inline bool fast_bits_lt_u(sbits x, sbits y) {
  return x.bits < y.bits;
}

static inline bool fast_bits_gt_u(sbits x, sbits y) {
  return x.bits > y.bits;
}

static inline bool fast_bits_le_u(sbits x, sbits y) {
  return x.bits <= y.bits;
}

static inline bool fast_bits_ge_u(sbits x, sbits y) {
  return x.bits >= y.bits;
}
