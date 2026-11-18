#include "riscv_softfloat.h"

// softfloat.h is missing #ifdef __cplusplus etc.
extern "C" {
#include "softfloat.h"
}

namespace {

uint_fast8_t uint8_of_rm(uint64_t rm) {
  return static_cast<uint_fast8_t>(rm);
}

void softfloat_init(uint64_t rm) {
  softfloat_exceptionFlags = 0;
  softfloat_roundingMode = uint8_of_rm(rm);
}

} // namespace

static float128_t to_float128(uint64_t low, uint64_t high) {
  float128_t res;
  res.v[0] = low;
  res.v[1] = high;
  return res;
}

bv5_bv16 softfloat_f16add(uint64_t rm, uint64_t v1, uint64_t v2) {
  softfloat_init(rm);

  float16_t a, b, res;
  a.v = v1;
  b.v = v2;
  res = f16_add(a, b);

  return {softfloat_exceptionFlags, res.v};
}

bv5_bv16 softfloat_f16sub(uint64_t rm, uint64_t v1, uint64_t v2) {
  softfloat_init(rm);

  float16_t a, b, res;
  a.v = v1;
  b.v = v2;
  res = f16_sub(a, b);

  return {softfloat_exceptionFlags, res.v};
}

bv5_bv16 softfloat_f16mul(uint64_t rm, uint64_t v1, uint64_t v2) {
  softfloat_init(rm);

  float16_t a, b, res;
  a.v = v1;
  b.v = v2;
  res = f16_mul(a, b);

  return {softfloat_exceptionFlags, res.v};
}

bv5_bv16 softfloat_f16div(uint64_t rm, uint64_t v1, uint64_t v2) {
  softfloat_init(rm);

  float16_t a, b, res;
  a.v = v1;
  b.v = v2;
  res = f16_div(a, b);

  return {softfloat_exceptionFlags, res.v};
}

bv5_bv32 softfloat_f32add(uint64_t rm, uint64_t v1, uint64_t v2) {
  softfloat_init(rm);

  float32_t a, b, res;
  a.v = v1;
  b.v = v2;
  res = f32_add(a, b);

  return {softfloat_exceptionFlags, res.v};
}

bv5_bv32 softfloat_f32sub(uint64_t rm, uint64_t v1, uint64_t v2) {
  softfloat_init(rm);

  float32_t a, b, res;
  a.v = v1;
  b.v = v2;
  res = f32_sub(a, b);

  return {softfloat_exceptionFlags, res.v};
}

bv5_bv32 softfloat_f32mul(uint64_t rm, uint64_t v1, uint64_t v2) {
  softfloat_init(rm);

  float32_t a, b, res;
  a.v = v1;
  b.v = v2;
  res = f32_mul(a, b);

  return {softfloat_exceptionFlags, res.v};
}

bv5_bv32 softfloat_f32div(uint64_t rm, uint64_t v1, uint64_t v2) {
  softfloat_init(rm);

  float32_t a, b, res;
  a.v = v1;
  b.v = v2;
  res = f32_div(a, b);

  return {softfloat_exceptionFlags, res.v};
}

bv5_bv64 softfloat_f64add(uint64_t rm, uint64_t v1, uint64_t v2) {
  softfloat_init(rm);

  float64_t a, b, res;
  a.v = v1;
  b.v = v2;
  res = f64_add(a, b);

  return {softfloat_exceptionFlags, res.v};
}

bv5_bv64 softfloat_f64sub(uint64_t rm, uint64_t v1, uint64_t v2) {
  softfloat_init(rm);

  float64_t a, b, res;
  a.v = v1;
  b.v = v2;
  res = f64_sub(a, b);

  return {softfloat_exceptionFlags, res.v};
}

bv5_bv64 softfloat_f64mul(uint64_t rm, uint64_t v1, uint64_t v2) {
  softfloat_init(rm);

  float64_t a, b, res;
  a.v = v1;
  b.v = v2;
  res = f64_mul(a, b);

  return {softfloat_exceptionFlags, res.v};
}

bv5_bv64 softfloat_f64div(uint64_t rm, uint64_t v1, uint64_t v2) {
  softfloat_init(rm);

  float64_t a, b, res;
  a.v = v1;
  b.v = v2;
  res = f64_div(a, b);

  return {softfloat_exceptionFlags, res.v};
}

bv5_bv64_bv64 softfloat_f128add(uint64_t rm, uint64_t v1_low, uint64_t v1_high, uint64_t v2_low, uint64_t v2_high) {
  softfloat_init(rm);

  float128_t a, b, res;
  a = to_float128(v1_low, v1_high);
  b = to_float128(v2_low, v2_high);
  res = f128_add(a, b);

  return {softfloat_exceptionFlags, res.v[0], res.v[1]};
}

bv5_bv64_bv64 softfloat_f128sub(uint64_t rm, uint64_t v1_low, uint64_t v1_high, uint64_t v2_low, uint64_t v2_high) {
  softfloat_init(rm);

  float128_t a, b, res;
  a = to_float128(v1_low, v1_high);
  b = to_float128(v2_low, v2_high);
  res = f128_sub(a, b);

  return {softfloat_exceptionFlags, res.v[0], res.v[1]};
}

bv5_bv64_bv64 softfloat_f128div(uint64_t rm, uint64_t v1_low, uint64_t v1_high, uint64_t v2_low, uint64_t v2_high) {
  softfloat_init(rm);

  float128_t a, b, res;
  a = to_float128(v1_low, v1_high);
  b = to_float128(v2_low, v2_high);
  res = f128_div(a, b);

  return {softfloat_exceptionFlags, res.v[0], res.v[1]};
}

bv5_bv64_bv64 softfloat_f128mul(uint64_t rm, uint64_t v1_low, uint64_t v1_high, uint64_t v2_low, uint64_t v2_high) {
  softfloat_init(rm);

  float128_t a, b, res;
  a = to_float128(v1_low, v1_high);
  b = to_float128(v2_low, v2_high);
  res = f128_mul(a, b);

  return {softfloat_exceptionFlags, res.v[0], res.v[1]};
}

bv5_bv16 softfloat_f16muladd(uint64_t rm, uint64_t v1, uint64_t v2, uint64_t v3) {
  softfloat_init(rm);

  float16_t a, b, c, res;
  a.v = v1;
  b.v = v2;
  c.v = v3;
  res = f16_mulAdd(a, b, c);

  return {softfloat_exceptionFlags, res.v};
}

bv5_bv32 softfloat_f32muladd(uint64_t rm, uint64_t v1, uint64_t v2, uint64_t v3) {
  softfloat_init(rm);

  float32_t a, b, c, res;
  a.v = v1;
  b.v = v2;
  c.v = v3;
  res = f32_mulAdd(a, b, c);

  return {softfloat_exceptionFlags, res.v};
}

bv5_bv64 softfloat_f64muladd(uint64_t rm, uint64_t v1, uint64_t v2, uint64_t v3) {
  softfloat_init(rm);

  float64_t a, b, c, res;
  a.v = v1;
  b.v = v2;
  c.v = v3;
  res = f64_mulAdd(a, b, c);

  return {softfloat_exceptionFlags, res.v};
}

bv5_bv64_bv64 softfloat_f128muladd(
  uint64_t rm,
  uint64_t v1_low,
  uint64_t v1_high,
  uint64_t v2_low,
  uint64_t v2_high,
  uint64_t v3_low,
  uint64_t v3_high
) {
  softfloat_init(rm);

  float128_t a, b, c, res;
  a = to_float128(v1_low, v1_high);
  b = to_float128(v2_low, v2_high);
  c = to_float128(v3_low, v3_high);
  res = f128_mulAdd(a, b, c);

  return {softfloat_exceptionFlags, res.v[0], res.v[1]};
}

bv5_bv16 softfloat_f16sqrt(uint64_t rm, uint64_t v) {
  softfloat_init(rm);

  float16_t a, res;
  a.v = v;
  res = f16_sqrt(a);

  return {softfloat_exceptionFlags, res.v};
}

bv5_bv32 softfloat_f32sqrt(uint64_t rm, uint64_t v) {
  softfloat_init(rm);

  float32_t a, res;
  a.v = v;
  res = f32_sqrt(a);

  return {softfloat_exceptionFlags, res.v};
}

bv5_bv64 softfloat_f64sqrt(uint64_t rm, uint64_t v) {
  softfloat_init(rm);

  float64_t a, res;
  a.v = v;
  res = f64_sqrt(a);

  return {softfloat_exceptionFlags, res.v};
}

bv5_bv64_bv64 softfloat_f128sqrt(uint64_t rm, uint64_t v_low, uint64_t v_high) {
  softfloat_init(rm);

  float128_t a, res;
  a = to_float128(v_low, v_high);
  res = f128_sqrt(a);

  return {softfloat_exceptionFlags, res.v[0], res.v[1]};
}

// The boolean 'true' argument in the conversion calls below selects
// 'exact' conversion, which sets the Inexact exception flag if
// needed.
bv5_bv32 softfloat_f16toi32(uint64_t rm, uint64_t v) {
  softfloat_init(rm);

  float16_t a;
  float32_t res;
  uint_fast8_t rm8 = uint8_of_rm(rm);
  a.v = v;
  res.v = f16_to_i32(a, rm8, true);

  return {softfloat_exceptionFlags, res.v};
}

bv5_bv32 softfloat_f16toui32(uint64_t rm, uint64_t v) {
  softfloat_init(rm);

  float16_t a;
  float32_t res;
  uint_fast8_t rm8 = uint8_of_rm(rm);
  a.v = v;
  res.v = f16_to_ui32(a, rm8, true);

  return {softfloat_exceptionFlags, res.v};
}

bv5_bv64 softfloat_f16toi64(uint64_t rm, uint64_t v) {
  softfloat_init(rm);

  float16_t a;
  float64_t res;
  uint_fast8_t rm8 = uint8_of_rm(rm);
  a.v = v;
  res.v = f16_to_i64(a, rm8, true);

  return {softfloat_exceptionFlags, res.v};
}

bv5_bv64 softfloat_f16toui64(uint64_t rm, uint64_t v) {
  softfloat_init(rm);

  float16_t a;
  float64_t res;
  uint_fast8_t rm8 = uint8_of_rm(rm);
  a.v = v;
  res.v = f16_to_ui64(a, rm8, true);

  return {softfloat_exceptionFlags, res.v};
}

bv5_bv32 softfloat_f32toi32(uint64_t rm, uint64_t v) {
  softfloat_init(rm);

  float32_t a, res;
  uint_fast8_t rm8 = uint8_of_rm(rm);
  a.v = v;
  res.v = f32_to_i32(a, rm8, true);

  return {softfloat_exceptionFlags, res.v};
}

bv5_bv32 softfloat_f32toui32(uint64_t rm, uint64_t v) {
  softfloat_init(rm);

  float32_t a, res;
  uint_fast8_t rm8 = uint8_of_rm(rm);
  a.v = v;
  res.v = f32_to_ui32(a, rm8, true);

  return {softfloat_exceptionFlags, res.v};
}

bv5_bv64 softfloat_f32toi64(uint64_t rm, uint64_t v) {
  softfloat_init(rm);

  float32_t a;
  float64_t res;
  uint_fast8_t rm8 = uint8_of_rm(rm);
  a.v = v;
  res.v = f32_to_i64(a, rm8, true);

  return {softfloat_exceptionFlags, res.v};
}

bv5_bv64 softfloat_f32toui64(uint64_t rm, uint64_t v) {
  softfloat_init(rm);

  float32_t a;
  float64_t res;
  uint_fast8_t rm8 = uint8_of_rm(rm);
  a.v = v;
  res.v = f32_to_ui64(a, rm8, true);

  return {softfloat_exceptionFlags, res.v};
}

bv5_bv32 softfloat_f64toi32(uint64_t rm, uint64_t v) {
  softfloat_init(rm);

  float64_t a;
  float32_t res;
  uint_fast8_t rm8 = uint8_of_rm(rm);
  a.v = v;
  res.v = f64_to_i32(a, rm8, true);

  return {softfloat_exceptionFlags, res.v};
}

bv5_bv32 softfloat_f64toui32(uint64_t rm, uint64_t v) {
  softfloat_init(rm);

  float64_t a;
  float32_t res;
  uint_fast8_t rm8 = uint8_of_rm(rm);
  a.v = v;
  res.v = f64_to_ui32(a, rm8, true);

  return {softfloat_exceptionFlags, res.v};
}

bv5_bv64 softfloat_f64toi64(uint64_t rm, uint64_t v) {
  softfloat_init(rm);

  float64_t a, res;
  uint_fast8_t rm8 = uint8_of_rm(rm);
  a.v = v;
  res.v = f64_to_i64(a, rm8, true);

  return {softfloat_exceptionFlags, res.v};
}

bv5_bv64 softfloat_f64toui64(uint64_t rm, uint64_t v) {
  softfloat_init(rm);

  float64_t a, res;
  uint_fast8_t rm8 = uint8_of_rm(rm);
  a.v = v;
  res.v = f64_to_ui64(a, rm8, true);

  return {softfloat_exceptionFlags, res.v};
}

bv5_bv32 softfloat_f128toi32(uint64_t rm, uint64_t v_low, uint64_t v_high) {
  softfloat_init(rm);

  float128_t a;
  float32_t res;
  uint_fast8_t rm8 = uint8_of_rm(rm);

  a = to_float128(v_low, v_high);
  res.v = f128_to_i32(a, rm8, true);

  return {softfloat_exceptionFlags, res.v};
}

bv5_bv32 softfloat_f128toui32(uint64_t rm, uint64_t v_low, uint64_t v_high) {
  softfloat_init(rm);

  float128_t a;
  float32_t res;
  uint_fast8_t rm8 = uint8_of_rm(rm);

  a = to_float128(v_low, v_high);
  res.v = f128_to_ui32(a, rm8, true);

  return {softfloat_exceptionFlags, res.v};
}

bv5_bv64 softfloat_f128toi64(uint64_t rm, uint64_t v_low, uint64_t v_high) {
  softfloat_init(rm);

  float128_t a;
  float64_t res;
  uint_fast8_t rm8 = uint8_of_rm(rm);

  a = to_float128(v_low, v_high);
  res.v = f128_to_i64(a, rm8, true);

  return {softfloat_exceptionFlags, res.v};
}

bv5_bv64 softfloat_f128toui64(uint64_t rm, uint64_t v_low, uint64_t v_high) {
  softfloat_init(rm);

  float128_t a;
  float64_t res;
  uint_fast8_t rm8 = uint8_of_rm(rm);

  a = to_float128(v_low, v_high);
  res.v = f128_to_ui64(a, rm8, true);

  return {softfloat_exceptionFlags, res.v};
}

bv5_bv16 softfloat_i32tof16(uint64_t rm, uint64_t v) {
  softfloat_init(rm);

  float16_t res;
  res = i32_to_f16(static_cast<int32_t>(v));

  return {softfloat_exceptionFlags, res.v};
}

bv5_bv16 softfloat_ui32tof16(uint64_t rm, uint64_t v) {
  softfloat_init(rm);

  float16_t res;
  res = ui32_to_f16(static_cast<uint32_t>(v));

  return {softfloat_exceptionFlags, res.v};
}

bv5_bv16 softfloat_i64tof16(uint64_t rm, uint64_t v) {
  softfloat_init(rm);

  float16_t res;
  res = i64_to_f16(static_cast<int64_t>(v));

  return {softfloat_exceptionFlags, res.v};
}

bv5_bv16 softfloat_ui64tof16(uint64_t rm, uint64_t v) {
  softfloat_init(rm);

  float16_t res;
  res = ui64_to_f16(v);

  return {softfloat_exceptionFlags, res.v};
}

bv5_bv32 softfloat_i32tof32(uint64_t rm, uint64_t v) {
  softfloat_init(rm);

  float32_t res;
  res = i32_to_f32(static_cast<int32_t>(v));

  return {softfloat_exceptionFlags, res.v};
}

bv5_bv32 softfloat_ui32tof32(uint64_t rm, uint64_t v) {
  softfloat_init(rm);

  float32_t res;
  res = ui32_to_f32(static_cast<uint32_t>(v));

  return {softfloat_exceptionFlags, res.v};
}

bv5_bv32 softfloat_i64tof32(uint64_t rm, uint64_t v) {
  softfloat_init(rm);

  float32_t res;
  res = i64_to_f32(static_cast<int64_t>(v));

  return {softfloat_exceptionFlags, res.v};
}

bv5_bv32 softfloat_ui64tof32(uint64_t rm, uint64_t v) {
  softfloat_init(rm);

  float32_t res;
  res = ui64_to_f32(v);

  return {softfloat_exceptionFlags, res.v};
}

bv5_bv64 softfloat_i32tof64(uint64_t rm, uint64_t v) {
  softfloat_init(rm);

  float64_t res;
  res = i32_to_f64(static_cast<int32_t>(v));

  return {softfloat_exceptionFlags, res.v};
}

bv5_bv64 softfloat_ui32tof64(uint64_t rm, uint64_t v) {
  softfloat_init(rm);

  float64_t res;
  res = ui32_to_f64(static_cast<uint32_t>(v));

  return {softfloat_exceptionFlags, res.v};
}

bv5_bv64 softfloat_i64tof64(uint64_t rm, uint64_t v) {
  softfloat_init(rm);

  float64_t res;
  res = i64_to_f64(static_cast<int64_t>(v));

  return {softfloat_exceptionFlags, res.v};
}

bv5_bv64 softfloat_ui64tof64(uint64_t rm, uint64_t v) {
  softfloat_init(rm);

  float64_t res;
  res = ui64_to_f64(v);

  return {softfloat_exceptionFlags, res.v};
}

bv5_bv64_bv64 softfloat_i32tof128(uint64_t rm, uint64_t v) {
  softfloat_init(rm);

  int32_t a;
  float128_t res;

  a = (int32_t)v;
  res = i32_to_f128(a);

  return {softfloat_exceptionFlags, res.v[0], res.v[1]};
}

bv5_bv64_bv64 softfloat_ui32tof128(uint64_t rm, uint64_t v) {
  softfloat_init(rm);

  uint32_t a;
  float128_t res;

  a = (uint32_t)v;
  res = ui32_to_f128(a);

  return {softfloat_exceptionFlags, res.v[0], res.v[1]};
}

bv5_bv64_bv64 softfloat_i64tof128(uint64_t rm, uint64_t v) {
  softfloat_init(rm);

  int64_t a;
  float128_t res;

  a = (int64_t)v;
  res = i64_to_f128(a);

  return {softfloat_exceptionFlags, res.v[0], res.v[1]};
}

bv5_bv64_bv64 softfloat_ui64tof128(uint64_t rm, uint64_t v) {
  softfloat_init(rm);

  uint64_t a;
  float128_t res;

  a = (uint64_t)v;
  res = ui64_to_f128(a);

  return {softfloat_exceptionFlags, res.v[0], res.v[1]};
}

bv5_bv32 softfloat_f16tof32(uint64_t rm, uint64_t v) {
  softfloat_init(rm);

  float16_t a;
  float32_t res;
  a.v = v;
  res = f16_to_f32(a);

  return {softfloat_exceptionFlags, res.v};
}

bv5_bv64 softfloat_f16tof64(uint64_t rm, uint64_t v) {
  softfloat_init(rm);

  float16_t a;
  float64_t res;
  a.v = v;
  res = f16_to_f64(a);

  return {softfloat_exceptionFlags, res.v};
}

bv5_bv64_bv64 softfloat_f16tof128(uint64_t rm, uint64_t v) {
  softfloat_init(rm);

  float16_t a;
  float128_t res;

  a.v = v;
  res = f16_to_f128(a);

  return {softfloat_exceptionFlags, res.v[0], res.v[1]};
}

bv5_bv64_bv64 softfloat_f32tof128(uint64_t rm, uint64_t v) {
  softfloat_init(rm);

  float32_t a;
  float128_t res;

  a.v = v;
  res = f32_to_f128(a);

  return {softfloat_exceptionFlags, res.v[0], res.v[1]};
}

bv5_bv64 softfloat_f32tof64(uint64_t rm, uint64_t v) {
  softfloat_init(rm);

  float32_t a;
  float64_t res;
  a.v = v;
  res = f32_to_f64(a);

  return {softfloat_exceptionFlags, res.v};
}

bv5_bv16 softfloat_f32tof16(uint64_t rm, uint64_t v) {
  softfloat_init(rm);

  float32_t a;
  float16_t res;
  a.v = v;
  res = f32_to_f16(a);

  return {softfloat_exceptionFlags, res.v};
}

bv5_bv16 softfloat_f64tof16(uint64_t rm, uint64_t v) {
  softfloat_init(rm);

  float64_t a;
  float16_t res;
  a.v = v;
  res = f64_to_f16(a);

  return {softfloat_exceptionFlags, res.v};
}

bv5_bv32 softfloat_f64tof32(uint64_t rm, uint64_t v) {
  softfloat_init(rm);

  float64_t a;
  float32_t res;
  a.v = v;
  res = f64_to_f32(a);

  return {softfloat_exceptionFlags, res.v};
}

bv5_bv64_bv64 softfloat_f64tof128(uint64_t rm, uint64_t v) {
  softfloat_init(rm);

  float64_t a;
  float128_t res;

  a.v = v;
  res = f64_to_f128(a);

  return {softfloat_exceptionFlags, res.v[0], res.v[1]};
}

bv5_bv16 softfloat_f32tobf16(uint64_t rm, uint64_t v) {
  softfloat_init(rm);

  float32_t a;
  bfloat16_t res;
  a.v = v;
  res = f32_to_bf16(a);

  return {softfloat_exceptionFlags, res.v};
}

bv5_bv16 softfloat_f128tof16(uint64_t rm, uint64_t v_low, uint64_t v_high) {
  softfloat_init(rm);

  float128_t a;
  float16_t res;

  a = to_float128(v_low, v_high);
  res = f128_to_f16(a);

  return {softfloat_exceptionFlags, res.v};
}

bv5_bv32 softfloat_f128tof32(uint64_t rm, uint64_t v_low, uint64_t v_high) {
  softfloat_init(rm);

  float128_t a;
  float32_t res;

  a = to_float128(v_low, v_high);
  res = f128_to_f32(a);

  return {softfloat_exceptionFlags, res.v};
}

bv5_bv64 softfloat_f128tof64(uint64_t rm, uint64_t v_low, uint64_t v_high) {
  softfloat_init(rm);

  float128_t a;
  float64_t res;

  a = to_float128(v_low, v_high);
  res = f128_to_f64(a);

  return {softfloat_exceptionFlags, res.v};
}

bv5_bool softfloat_f16lt(uint64_t v1, uint64_t v2) {
  softfloat_init(0);

  float16_t a, b;
  a.v = v1;
  b.v = v2;
  bool res = f16_lt(a, b);

  return {softfloat_exceptionFlags, res};
}

bv5_bool softfloat_f16lt_quiet(uint64_t v1, uint64_t v2) {
  softfloat_init(0);

  float16_t a, b;
  a.v = v1;
  b.v = v2;
  bool res = f16_lt_quiet(a, b);

  return {softfloat_exceptionFlags, res};
}

bv5_bool softfloat_f16le(uint64_t v1, uint64_t v2) {
  softfloat_init(0);

  float16_t a, b;
  a.v = v1;
  b.v = v2;
  bool res = f16_le(a, b);

  return {softfloat_exceptionFlags, res};
}

bv5_bool softfloat_f16le_quiet(uint64_t v1, uint64_t v2) {
  softfloat_init(0);

  float16_t a, b;
  a.v = v1;
  b.v = v2;
  bool res = f16_le_quiet(a, b);

  return {softfloat_exceptionFlags, res};
}

bv5_bool softfloat_f16eq(uint64_t v1, uint64_t v2) {
  softfloat_init(0);

  float16_t a, b;
  a.v = v1;
  b.v = v2;
  bool res = f16_eq(a, b);

  return {softfloat_exceptionFlags, res};
}

bv5_bool softfloat_f32lt(uint64_t v1, uint64_t v2) {
  softfloat_init(0);

  float32_t a, b;
  a.v = v1;
  b.v = v2;
  bool res = f32_lt(a, b);

  return {softfloat_exceptionFlags, res};
}

bv5_bool softfloat_f32lt_quiet(uint64_t v1, uint64_t v2) {
  softfloat_init(0);

  float32_t a, b;
  a.v = v1;
  b.v = v2;
  bool res = f32_lt_quiet(a, b);

  return {softfloat_exceptionFlags, res};
}

bv5_bool softfloat_f32le(uint64_t v1, uint64_t v2) {
  softfloat_init(0);

  float32_t a, b;
  a.v = v1;
  b.v = v2;
  bool res = f32_le(a, b);

  return {softfloat_exceptionFlags, res};
}

bv5_bool softfloat_f32le_quiet(uint64_t v1, uint64_t v2) {
  softfloat_init(0);

  float32_t a, b;
  a.v = v1;
  b.v = v2;
  bool res = f32_le_quiet(a, b);

  return {softfloat_exceptionFlags, res};
}

bv5_bool softfloat_f32eq(uint64_t v1, uint64_t v2) {
  softfloat_init(0);

  float32_t a, b;
  a.v = v1;
  b.v = v2;
  bool res = f32_eq(a, b);

  return {softfloat_exceptionFlags, res};
}

bv5_bool softfloat_f64lt(uint64_t v1, uint64_t v2) {
  softfloat_init(0);

  float64_t a, b;
  a.v = v1;
  b.v = v2;
  bool res = f64_lt(a, b);

  return {softfloat_exceptionFlags, res};
}

bv5_bool softfloat_f64lt_quiet(uint64_t v1, uint64_t v2) {
  softfloat_init(0);

  float64_t a, b;
  a.v = v1;
  b.v = v2;
  bool res = f64_lt_quiet(a, b);

  return {softfloat_exceptionFlags, res};
}

bv5_bool softfloat_f64le(uint64_t v1, uint64_t v2) {
  softfloat_init(0);

  float64_t a, b;
  a.v = v1;
  b.v = v2;
  bool res = f64_le(a, b);

  return {softfloat_exceptionFlags, res};
}

bv5_bool softfloat_f64le_quiet(uint64_t v1, uint64_t v2) {
  softfloat_init(0);

  float64_t a, b;
  a.v = v1;
  b.v = v2;
  bool res = f64_le_quiet(a, b);

  return {softfloat_exceptionFlags, res};
}

bv5_bool softfloat_f64eq(uint64_t v1, uint64_t v2) {
  softfloat_init(0);

  float64_t a, b;
  a.v = v1;
  b.v = v2;
  bool res = f64_eq(a, b);

  return {softfloat_exceptionFlags, res};
}

bv5_bool softfloat_f128lt(uint64_t v1_low, uint64_t v1_high, uint64_t v2_low, uint64_t v2_high) {
  softfloat_init(0);

  float128_t a, b;
  bool res;
  a = to_float128(v1_low, v1_high);
  b = to_float128(v2_low, v2_high);
  res = f128_lt(a, b);

  return {softfloat_exceptionFlags, res};
}

bv5_bool softfloat_f128lt_quiet(uint64_t v1_low, uint64_t v1_high, uint64_t v2_low, uint64_t v2_high) {
  softfloat_init(0);

  float128_t a, b;
  bool res;
  a = to_float128(v1_low, v1_high);
  b = to_float128(v2_low, v2_high);
  res = f128_lt_quiet(a, b);

  return {softfloat_exceptionFlags, res};
}

bv5_bool softfloat_f128le(uint64_t v1_low, uint64_t v1_high, uint64_t v2_low, uint64_t v2_high) {
  softfloat_init(0);

  float128_t a, b;
  bool res;
  a = to_float128(v1_low, v1_high);
  b = to_float128(v2_low, v2_high);
  res = f128_le(a, b);

  return {softfloat_exceptionFlags, res};
}

bv5_bool softfloat_f128le_quiet(uint64_t v1_low, uint64_t v1_high, uint64_t v2_low, uint64_t v2_high) {
  softfloat_init(0);

  float128_t a, b;
  bool res;
  a = to_float128(v1_low, v1_high);
  b = to_float128(v2_low, v2_high);
  res = f128_le_quiet(a, b);

  return {softfloat_exceptionFlags, res};
}

bv5_bool softfloat_f128eq(uint64_t v1_low, uint64_t v1_high, uint64_t v2_low, uint64_t v2_high) {
  softfloat_init(0);

  float128_t a, b;
  bool res;
  a = to_float128(v1_low, v1_high);
  b = to_float128(v2_low, v2_high);
  res = f128_eq(a, b);

  return {softfloat_exceptionFlags, res};
}

bv5_bv16 softfloat_f16roundToInt(uint64_t rm, uint64_t v, bool exact) {
  softfloat_init(rm);

  float16_t a, res;
  uint_fast8_t rm8 = uint8_of_rm(rm);
  a.v = v;
  res = f16_roundToInt(a, rm8, exact);

  return {softfloat_exceptionFlags, res.v};
}

bv5_bv32 softfloat_f32roundToInt(uint64_t rm, uint64_t v, bool exact) {
  softfloat_init(rm);

  float32_t a, res;
  uint_fast8_t rm8 = uint8_of_rm(rm);
  a.v = v;
  res = f32_roundToInt(a, rm8, exact);

  return {softfloat_exceptionFlags, res.v};
}

bv5_bv64 softfloat_f64roundToInt(uint64_t rm, uint64_t v, bool exact) {
  softfloat_init(rm);

  float64_t a, res;
  uint_fast8_t rm8 = uint8_of_rm(rm);
  a.v = v;
  res = f64_roundToInt(a, rm8, exact);

  return {softfloat_exceptionFlags, res.v};
}

bv5_bv64_bv64 softfloat_f128roundToInt(uint64_t rm, uint64_t v_low, uint64_t v_high, bool exact) {
  softfloat_init(rm);

  float128_t a, res;
  uint_fast8_t rm8 = uint8_of_rm(rm);
  a = to_float128(v_low, v_high);
  res = f128_roundToInt(a, rm8, exact);

  return {softfloat_exceptionFlags, res.v[0], res.v[1]};
}
