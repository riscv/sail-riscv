#include "sail.h"
#include "rts.h"
#include "riscv_sail.h"
#include "riscv_softfloat.h"
#include "softfloat.h"
#include "gmp.h"

static uint_fast8_t uint8_of_rm(mach_bits rm) {
  // TODO.
  return (uint_fast8_t)rm;
}

#define SOFTFLOAT_PRELUDE(rm)                           \
  softfloat_exceptionFlags = 0;                         \
  softfloat_roundingMode = (uint_fast8_t) rm

#define SOFTFLOAT_POSTLUDE(res)                             \
  recreate_lbits_of_fbits(&zfloat_result, res.v, 128ull, true);      \
  zfloat_fflags |= (mach_bits) softfloat_exceptionFlags     \

static float128_t to_float128(sail_bits v1) {
  static mpz_t tmp;
  static bool isInitialized = false;

  float128_t res;
  uint32_t lo;
  uint32_t hi;
  mpz_t *from = v1.bits;

  // I don't know if you mind a small memory leak or not
  if (!isInitialized) {
    mpz_init(tmp);
    isInitialized = true;
  }

  mpz_mod_2exp(tmp, *from, 64); // lower 64 bits of v1
  lo = mpz_get_ui(tmp);
  mpz_div_2exp(tmp, tmp, 32);
  hi = mpz_get_ui(tmp);

  res.v[0] = (((uint64_t)hi) << 32) + lo;

  mpz_div_2exp(tmp, *from, 64); // higher 64 bits of v1
  lo = mpz_get_ui(tmp);
  mpz_div_2exp(tmp, tmp, 32);
  hi = mpz_get_ui(tmp);

  res.v[1] = (((uint64_t)hi) << 32) + lo;

  return res;
}


#define SOFTFLOAT_POSTLUDE_128 softfloat_postlude_128

static void softfloat_postlude_128(float128_t res) {
  static sail_int _64;
  static mpz_t lo;
  static bool isInitialized = false;

  // I don't know if you mind a small memory leak or not
  if (!isInitialized) {
    create_sail_int_of_mach_int(&_64, 64ull);
    mpz_init(lo);
  }

  // set upper 64 bits
  recreate_lbits_of_fbits(&zfloat_result, res.v[0], 128ull, true);
  shiftl(&zfloat_result, zfloat_result, _64);
  
  // set lower 64 bits
  mpz_set_ui(lo, (uint32_t)(res.v[1] >> 32));
  mpz_mul_2exp(lo, lo, 32);
  mpz_add_ui(lo, lo, (uint32_t) res.v[1]);
  add_bits_int(&zfloat_result, zfloat_result, lo);

  zfloat_fflags |= (mach_bits) softfloat_exceptionFlags;
}

unit softfloat_f16add(mach_bits rm, mach_bits v1, mach_bits v2) {
  SOFTFLOAT_PRELUDE(rm);

  float16_t a, b, res;
  a.v = v1;
  b.v = v2;
  res = f16_add(a, b);

  SOFTFLOAT_POSTLUDE(res);

  return UNIT;
}

unit softfloat_f16sub(mach_bits rm, mach_bits v1, mach_bits v2) {
  SOFTFLOAT_PRELUDE(rm);

  float16_t a, b, res;
  a.v = v1;
  b.v = v2;
  res = f16_sub(a, b);

  SOFTFLOAT_POSTLUDE(res);

  return UNIT;
}

unit softfloat_f16mul(mach_bits rm, mach_bits v1, mach_bits v2) {
  SOFTFLOAT_PRELUDE(rm);

  float16_t a, b, res;
  a.v = v1;
  b.v = v2;
  res = f16_mul(a, b);

  SOFTFLOAT_POSTLUDE(res);

  return UNIT;
}

unit softfloat_f16div(mach_bits rm, mach_bits v1, mach_bits v2) {
  SOFTFLOAT_PRELUDE(rm);

  float16_t a, b, res;
  a.v = v1;
  b.v = v2;
  res = f16_div(a, b);

  SOFTFLOAT_POSTLUDE(res);

  return UNIT;
}

unit softfloat_f32add(mach_bits rm, mach_bits v1, mach_bits v2) {
  SOFTFLOAT_PRELUDE(rm);

  float32_t a, b, res;
  a.v = v1;
  b.v = v2;
  res = f32_add(a, b);

  SOFTFLOAT_POSTLUDE(res);

  return UNIT;
}

unit softfloat_f32sub(mach_bits rm, mach_bits v1, mach_bits v2) {
  SOFTFLOAT_PRELUDE(rm);

  float32_t a, b, res;
  a.v = v1;
  b.v = v2;
  res = f32_sub(a, b);

  SOFTFLOAT_POSTLUDE(res);

  return UNIT;
}

unit softfloat_f32mul(mach_bits rm, mach_bits v1, mach_bits v2) {
  SOFTFLOAT_PRELUDE(rm);

  float32_t a, b, res;
  a.v = v1;
  b.v = v2;
  res = f32_mul(a, b);

  SOFTFLOAT_POSTLUDE(res);

  return UNIT;
}

unit softfloat_f32div(mach_bits rm, mach_bits v1, mach_bits v2) {
  SOFTFLOAT_PRELUDE(rm);

  float32_t a, b, res;
  a.v = v1;
  b.v = v2;
  res = f32_div(a, b);

  SOFTFLOAT_POSTLUDE(res);

  return UNIT;
}

unit softfloat_f64add(mach_bits rm, mach_bits v1, mach_bits v2) {
  SOFTFLOAT_PRELUDE(rm);

  float64_t a, b, res;
  a.v = v1;
  b.v = v2;
  res = f64_add(a, b);

  SOFTFLOAT_POSTLUDE(res);

  return UNIT;
}

unit softfloat_f64sub(mach_bits rm, mach_bits v1, mach_bits v2) {
  SOFTFLOAT_PRELUDE(rm);

  float64_t a, b, res;
  a.v = v1;
  b.v = v2;
  res = f64_sub(a, b);

  SOFTFLOAT_POSTLUDE(res);

  return UNIT;
}

unit softfloat_f64mul(mach_bits rm, mach_bits v1, mach_bits v2) {
  SOFTFLOAT_PRELUDE(rm);

  float64_t a, b, res;
  a.v = v1;
  b.v = v2;
  res = f64_mul(a, b);

  SOFTFLOAT_POSTLUDE(res);

  return UNIT;
}

unit softfloat_f64div(mach_bits rm, mach_bits v1, mach_bits v2) {
  SOFTFLOAT_PRELUDE(rm);

  float64_t a, b, res;
  a.v = v1;
  b.v = v2;
  res = f64_div(a, b);

  SOFTFLOAT_POSTLUDE(res);

  return UNIT;
}


unit softfloat_f128add(mach_bits rm, sail_bits v1, sail_bits v2) {
  SOFTFLOAT_PRELUDE(rm);

  float128_t a, b, res;
  a = to_float128(v1);
  b = to_float128(v2);
  res = f128_add(a, b);

  SOFTFLOAT_POSTLUDE_128(res);

  return UNIT;
}

unit softfloat_f128sub(mach_bits rm, sail_bits v1, sail_bits v2) {
  SOFTFLOAT_PRELUDE(rm);

  float128_t a, b, res;
  a = to_float128(v1);
  b = to_float128(v2);
  res = f128_sub(a, b);

  SOFTFLOAT_POSTLUDE_128(res);

  return UNIT;
}

unit softfloat_f128div(mach_bits rm, sail_bits v1, sail_bits v2) {
  SOFTFLOAT_PRELUDE(rm);

  float128_t a, b, res;
  a = to_float128(v1);
  b = to_float128(v2);
  res = f128_div(a, b);

  SOFTFLOAT_POSTLUDE_128(res);

  return UNIT;
}

unit softfloat_f128mul(mach_bits rm, sail_bits v1, sail_bits v2) {
  SOFTFLOAT_PRELUDE(rm);

  float128_t a, b, res;
  a = to_float128(v1);
  b = to_float128(v2);
  res = f128_mul(a, b);

  SOFTFLOAT_POSTLUDE_128(res);

  return UNIT;
}


unit softfloat_f16muladd(mach_bits rm, mach_bits v1, mach_bits v2, mach_bits v3) {
  SOFTFLOAT_PRELUDE(rm);

  float16_t a, b, c, res;
  a.v = v1;
  b.v = v2;
  c.v = v3;
  res = f16_mulAdd(a, b, c);

  SOFTFLOAT_POSTLUDE(res);

  return UNIT;
}

unit softfloat_f32muladd(mach_bits rm, mach_bits v1, mach_bits v2, mach_bits v3) {
  SOFTFLOAT_PRELUDE(rm);

  float32_t a, b, c, res;
  a.v = v1;
  b.v = v2;
  c.v = v3;
  res = f32_mulAdd(a, b, c);

  SOFTFLOAT_POSTLUDE(res);

  return UNIT;
}

unit softfloat_f64muladd(mach_bits rm, mach_bits v1, mach_bits v2, mach_bits v3) {
  SOFTFLOAT_PRELUDE(rm);

  float64_t a, b, c, res;
  a.v = v1;
  b.v = v2;
  c.v = v3;
  res = f64_mulAdd(a, b, c);

  SOFTFLOAT_POSTLUDE(res);

  return UNIT;
}

unit softfloat_f128muladd(mach_bits rm, sail_bits v1, sail_bits v2, sail_bits v3) {
  SOFTFLOAT_PRELUDE(rm);

  float128_t a, b, c, res;
  a = to_float128(v1);
  b = to_float128(v2);
  c = to_float128(v3);
  res = f128_mulAdd(a, b, c);

  SOFTFLOAT_POSTLUDE_128(res);

  return UNIT;
}



unit softfloat_f16sqrt(mach_bits rm, mach_bits v) {
  SOFTFLOAT_PRELUDE(rm);

  float16_t a, res;
  a.v = v;
  res = f16_sqrt(a);

  SOFTFLOAT_POSTLUDE(res);

  return UNIT;
}

unit softfloat_f32sqrt(mach_bits rm, mach_bits v) {
  SOFTFLOAT_PRELUDE(rm);

  float32_t a, res;
  a.v = v;
  res = f32_sqrt(a);

  SOFTFLOAT_POSTLUDE(res);

  return UNIT;
}

unit softfloat_f64sqrt(mach_bits rm, mach_bits v) {
  SOFTFLOAT_PRELUDE(rm);

  float64_t a, res;
  a.v = v;
  res = f64_sqrt(a);

  SOFTFLOAT_POSTLUDE(res);

  return UNIT;
}

unit softfloat_f128sqrt(mach_bits rm, sail_bits v) {
  SOFTFLOAT_PRELUDE(rm);

  float128_t a, res;
  a = to_float128(v);
  res = f128_sqrt(a);

  SOFTFLOAT_POSTLUDE_128(res);

  return UNIT;
}

// The boolean 'true' argument in the conversion calls below selects
// 'exact' conversion, which sets the Inexact exception flag if
// needed.
unit softfloat_f16toi32(mach_bits rm, mach_bits v) {
  SOFTFLOAT_PRELUDE(rm);

  float16_t a;
  float32_t res;
  uint_fast8_t rm8 = uint8_of_rm(rm);
  a.v = v;
  res.v = f16_to_i32(a, rm8, true);

  SOFTFLOAT_POSTLUDE(res);

  return UNIT;
}

unit softfloat_f16toui32(mach_bits rm, mach_bits v) {
  SOFTFLOAT_PRELUDE(rm);

  float16_t a;
  float32_t res;
  uint_fast8_t rm8 = uint8_of_rm(rm);
  a.v = v;
  res.v = f16_to_ui32(a, rm8, true);

  SOFTFLOAT_POSTLUDE(res);

  return UNIT;
}

unit softfloat_f16toi64(mach_bits rm, mach_bits v) {
  SOFTFLOAT_PRELUDE(rm);

  float16_t a;
  float64_t res;
  uint_fast8_t rm8 = uint8_of_rm(rm);
  a.v = v;
  res.v = f16_to_i64(a, rm8, true);

  SOFTFLOAT_POSTLUDE(res);

  return UNIT;
}

unit softfloat_f16toui64(mach_bits rm, mach_bits v) {
  SOFTFLOAT_PRELUDE(rm);

  float16_t a;
  float64_t res;
  uint_fast8_t rm8 = uint8_of_rm(rm);
  a.v = v;
  res.v = f16_to_ui64(a, rm8, true);

  SOFTFLOAT_POSTLUDE(res);

  return UNIT;
}

unit softfloat_f32toi32(mach_bits rm, mach_bits v) {
  SOFTFLOAT_PRELUDE(rm);

  float32_t a, res;
  uint_fast8_t rm8 = uint8_of_rm(rm);
  a.v = v;
  res.v = f32_to_i32(a, rm8, true);

  SOFTFLOAT_POSTLUDE(res);

  return UNIT;
}

unit softfloat_f32toui32(mach_bits rm, mach_bits v) {
  SOFTFLOAT_PRELUDE(rm);

  float32_t a, res;
  uint_fast8_t rm8 = uint8_of_rm(rm);
  a.v = v;
  res.v = f32_to_ui32(a, rm8, true);

  SOFTFLOAT_POSTLUDE(res);

  return UNIT;
}

unit softfloat_f32toi64(mach_bits rm, mach_bits v) {
  SOFTFLOAT_PRELUDE(rm);

  float32_t a;
  float64_t res;
  uint_fast8_t rm8 = uint8_of_rm(rm);
  a.v = v;
  res.v = f32_to_i64(a, rm8, true);

  SOFTFLOAT_POSTLUDE(res);

  return UNIT;
}

unit softfloat_f32toui64(mach_bits rm, mach_bits v) {
  SOFTFLOAT_PRELUDE(rm);

  float32_t a;
  float64_t res;
  uint_fast8_t rm8 = uint8_of_rm(rm);
  a.v = v;
  res.v = f32_to_ui64(a, rm8, true);

  SOFTFLOAT_POSTLUDE(res);

  return UNIT;
}

unit softfloat_f64toi32(mach_bits rm, mach_bits v) {
  SOFTFLOAT_PRELUDE(rm);

  float64_t a;
  float32_t res;
  uint_fast8_t rm8 = uint8_of_rm(rm);
  a.v = v;
  res.v = f64_to_i32(a, rm8, true);

  SOFTFLOAT_POSTLUDE(res);

  return UNIT;
}

unit softfloat_f64toui32(mach_bits rm, mach_bits v) {
  SOFTFLOAT_PRELUDE(rm);

  float64_t a;
  float32_t res;
  uint_fast8_t rm8 = uint8_of_rm(rm);
  a.v = v;
  res.v = f64_to_ui32(a, rm8, true);

  SOFTFLOAT_POSTLUDE(res);

  return UNIT;
}

unit softfloat_f64toi64(mach_bits rm, mach_bits v) {
  SOFTFLOAT_PRELUDE(rm);

  float64_t a, res;
  uint_fast8_t rm8 = uint8_of_rm(rm);
  a.v = v;
  res.v = f64_to_i64(a, rm8, true);

  SOFTFLOAT_POSTLUDE(res);

  return UNIT;
}

unit softfloat_f64toui64(mach_bits rm, mach_bits v) {
  SOFTFLOAT_PRELUDE(rm);

  float64_t a, res;
  uint_fast8_t rm8 = uint8_of_rm(rm);
  a.v = v;
  res.v = f64_to_ui64(a, rm8, true);

  SOFTFLOAT_POSTLUDE(res);

  return UNIT;
}

unit softfloat_i32tof16(mach_bits rm, mach_bits v) {
  SOFTFLOAT_PRELUDE(rm);

  float16_t res;
  res = i32_to_f16((int32_t)v);

  SOFTFLOAT_POSTLUDE(res);

  return UNIT;
}

unit softfloat_ui32tof16(mach_bits rm, mach_bits v) {
  SOFTFLOAT_PRELUDE(rm);

  float16_t res;
  res = ui32_to_f16((uint32_t)v);

  SOFTFLOAT_POSTLUDE(res);

  return UNIT;
}

unit softfloat_i64tof16(mach_bits rm, mach_bits v) {
  SOFTFLOAT_PRELUDE(rm);

  float16_t res;
  res = i64_to_f16(v);

  SOFTFLOAT_POSTLUDE(res);

  return UNIT;
}

unit softfloat_ui64tof16(mach_bits rm, mach_bits v) {
  SOFTFLOAT_PRELUDE(rm);

  float16_t res;
  res = ui64_to_f16(v);

  SOFTFLOAT_POSTLUDE(res);

  return UNIT;
}

unit softfloat_i32tof32(mach_bits rm, mach_bits v) {
  SOFTFLOAT_PRELUDE(rm);

  float32_t res;
  res = i32_to_f32((int32_t)v);

  SOFTFLOAT_POSTLUDE(res);

  return UNIT;
}

unit softfloat_ui32tof32(mach_bits rm, mach_bits v) {
  SOFTFLOAT_PRELUDE(rm);

  float32_t res;
  res = ui32_to_f32((uint32_t)v);

  SOFTFLOAT_POSTLUDE(res);

  return UNIT;
}

unit softfloat_i64tof32(mach_bits rm, mach_bits v) {
  SOFTFLOAT_PRELUDE(rm);

  float32_t res;
  res = i64_to_f32(v);

  SOFTFLOAT_POSTLUDE(res);

  return UNIT;
}

unit softfloat_ui64tof32(mach_bits rm, mach_bits v) {
  SOFTFLOAT_PRELUDE(rm);

  float32_t res;
  res = ui64_to_f32(v);

  SOFTFLOAT_POSTLUDE(res);

  return UNIT;
}

unit softfloat_i32tof64(mach_bits rm, mach_bits v) {
  SOFTFLOAT_PRELUDE(rm);

  float64_t res;
  res = i32_to_f64((int32_t)v);

  SOFTFLOAT_POSTLUDE(res);

  return UNIT;
}

unit softfloat_ui32tof64(mach_bits rm, mach_bits v) {
  SOFTFLOAT_PRELUDE(rm);

  float64_t res;
  res = ui32_to_f64((uint32_t)v);

  SOFTFLOAT_POSTLUDE(res);

  return UNIT;
}

unit softfloat_i64tof64(mach_bits rm, mach_bits v) {
  SOFTFLOAT_PRELUDE(rm);

  float64_t res;
  res = i64_to_f64(v);

  SOFTFLOAT_POSTLUDE(res);

  return UNIT;
}

unit softfloat_ui64tof64(mach_bits rm, mach_bits v) {
  SOFTFLOAT_PRELUDE(rm);

  float64_t res;
  res = ui64_to_f64(v);

  SOFTFLOAT_POSTLUDE(res);

  return UNIT;
}

unit softfloat_f16tof32(mach_bits rm, mach_bits v) {
  SOFTFLOAT_PRELUDE(rm);

  float16_t a;
  float32_t res;
  a.v = v;
  res = f16_to_f32(a);

  SOFTFLOAT_POSTLUDE(res);

  return UNIT;
}

unit softfloat_f16tof64(mach_bits rm, mach_bits v) {
  SOFTFLOAT_PRELUDE(rm);

  float16_t a;
  float64_t res;
  a.v = v;
  res = f16_to_f64(a);

  SOFTFLOAT_POSTLUDE(res);

  return UNIT;
}

unit softfloat_f32tof64(mach_bits rm, mach_bits v) {
  SOFTFLOAT_PRELUDE(rm);

  float32_t a;
  float64_t res;
  a.v = v;
  res = f32_to_f64(a);

  SOFTFLOAT_POSTLUDE(res);

  return UNIT;
}

unit softfloat_f32tof16(mach_bits rm, mach_bits v) {
  SOFTFLOAT_PRELUDE(rm);

  float32_t a;
  float16_t res;
  a.v = v;
  res = f32_to_f16(a);

  SOFTFLOAT_POSTLUDE(res);

  return UNIT;
}

unit softfloat_f64tof16(mach_bits rm, mach_bits v) {
  SOFTFLOAT_PRELUDE(rm);

  float64_t a;
  float16_t res;
  a.v = v;
  res = f64_to_f16(a);

  SOFTFLOAT_POSTLUDE(res);

  return UNIT;
}

unit softfloat_f64tof32(mach_bits rm, mach_bits v) {
  SOFTFLOAT_PRELUDE(rm);

  float64_t a;
  float32_t res;
  a.v = v;
  res = f64_to_f32(a);

  SOFTFLOAT_POSTLUDE(res);

  return UNIT;
}

unit softfloat_f16lt(mach_bits v1, mach_bits v2) {
  SOFTFLOAT_PRELUDE(0);

  float16_t a, b, res;
  a.v = v1;
  b.v = v2;
  res.v = f16_lt(a, b);

  SOFTFLOAT_POSTLUDE(res);

  return UNIT;
}

unit softfloat_f16le(mach_bits v1, mach_bits v2) {
  SOFTFLOAT_PRELUDE(0);

  float16_t a, b, res;
  a.v = v1;
  b.v = v2;
  res.v = f16_le(a, b);

  SOFTFLOAT_POSTLUDE(res);

  return UNIT;
}

unit softfloat_f16eq(mach_bits v1, mach_bits v2) {
  SOFTFLOAT_PRELUDE(0);

  float16_t a, b, res;
  a.v = v1;
  b.v = v2;
  res.v = f16_eq(a, b);

  SOFTFLOAT_POSTLUDE(res);

  return UNIT;
}

unit softfloat_f32lt(mach_bits v1, mach_bits v2) {
  SOFTFLOAT_PRELUDE(0);

  float32_t a, b, res;
  a.v = v1;
  b.v = v2;
  res.v = f32_lt(a, b);

  SOFTFLOAT_POSTLUDE(res);

  return UNIT;
}

unit softfloat_f32le(mach_bits v1, mach_bits v2) {
  SOFTFLOAT_PRELUDE(0);

  float32_t a, b, res;
  a.v = v1;
  b.v = v2;
  res.v = f32_le(a, b);

  SOFTFLOAT_POSTLUDE(res);

  return UNIT;
}

unit softfloat_f32eq(mach_bits v1, mach_bits v2) {
  SOFTFLOAT_PRELUDE(0);

  float32_t a, b, res;
  a.v = v1;
  b.v = v2;
  res.v = f32_eq(a, b);

  SOFTFLOAT_POSTLUDE(res);

  return UNIT;
}

unit softfloat_f64lt(mach_bits v1, mach_bits v2) {
  SOFTFLOAT_PRELUDE(0);

  float64_t a, b, res;
  a.v = v1;
  b.v = v2;
  res.v = f64_lt(a, b);

  SOFTFLOAT_POSTLUDE(res);

  return UNIT;
}

unit softfloat_f64le(mach_bits v1, mach_bits v2) {
  SOFTFLOAT_PRELUDE(0);

  float64_t a, b, res;
  a.v = v1;
  b.v = v2;
  res.v = f64_le(a, b);

  SOFTFLOAT_POSTLUDE(res);

  return UNIT;
}

unit softfloat_f64eq(mach_bits v1, mach_bits v2) {
  SOFTFLOAT_PRELUDE(0);

  float64_t a, b, res;
  a.v = v1;
  b.v = v2;
  res.v = f64_eq(a, b);

  SOFTFLOAT_POSTLUDE(res);

  return UNIT;
}


unit softfloat_f128lt(sail_bits v1, sail_bits v2){
  SOFTFLOAT_PRELUDE(0);

  float128_t a, b;
  float64_t res;
  a = to_float128(v1);
  b = to_float128(v2);
  res.v = f128_lt(a, b);

  SOFTFLOAT_POSTLUDE(res);

  return UNIT;
}
unit softfloat_f128le(sail_bits v1, sail_bits v2) {
  SOFTFLOAT_PRELUDE(0);

  float128_t a, b;
  float64_t res;
  a = to_float128(v1);
  b = to_float128(v2);
  res.v = f128_le(a, b);

  SOFTFLOAT_POSTLUDE(res);

  return UNIT;
}
unit softfloat_f128eq(sail_bits v1, sail_bits v2) {
  SOFTFLOAT_PRELUDE(0);

  float128_t a, b;
  float64_t res;
  a = to_float128(v1);
  b = to_float128(v2);
  res.v = f128_eq(a, b);

  SOFTFLOAT_POSTLUDE(res);

  return UNIT;
}

unit softfloat_f128toi32(mach_bits rm, sail_bits v) {
  SOFTFLOAT_PRELUDE(rm);

  float128_t a;
  float32_t res;
  uint_fast8_t rm8 = uint8_of_rm(rm);

  a = to_float128(v);
  res.v = f128_to_i32(a, rm8, true);

  SOFTFLOAT_POSTLUDE(res);

  return UNIT;
}

unit softfloat_f128toui32(mach_bits rm, sail_bits v) {
  SOFTFLOAT_PRELUDE(rm);

  float128_t a;
  float32_t res;
  uint_fast8_t rm8 = uint8_of_rm(rm);

  a = to_float128(v);
  res.v = f128_to_ui32(a, rm8, true);

  SOFTFLOAT_POSTLUDE(res);

  return UNIT;
}

unit softfloat_f128toi64(mach_bits rm, sail_bits v) {
  SOFTFLOAT_PRELUDE(rm);

  float128_t a;
  float64_t res;
  uint_fast8_t rm8 = uint8_of_rm(rm);

  a = to_float128(v);
  res.v = f128_to_i64(a, rm8, true);

  SOFTFLOAT_POSTLUDE(res);

  return UNIT;
}

unit softfloat_f128toui64(mach_bits rm, sail_bits v) {
  SOFTFLOAT_PRELUDE(rm);

  float128_t a;
  float64_t res;
  uint_fast8_t rm8 = uint8_of_rm(rm);

  a = to_float128(v);
  res.v = f128_to_ui64(a, rm8, true);

  SOFTFLOAT_POSTLUDE(res);

  return UNIT;
}

unit softfloat_i32tof128(mach_bits rm, mach_bits v) {
  SOFTFLOAT_PRELUDE(rm);

  int32_t a;
  float128_t res;

  a = (int32_t) v;
  res = i32_to_f128(a);

  SOFTFLOAT_POSTLUDE_128(res);

  return UNIT; 
}

unit softfloat_ui32tof128(mach_bits rm, mach_bits v) {
  SOFTFLOAT_PRELUDE(rm);

  uint32_t a;
  float128_t res;

  a = (uint32_t) v;
  res = ui32_to_f128(a);

  SOFTFLOAT_POSTLUDE_128(res);

  return UNIT; 
}

unit softfloat_i64tof128(mach_bits rm, mach_bits v) {
  SOFTFLOAT_PRELUDE(rm);

  int64_t a;
  float128_t res;

  a = (int64_t) v;
  res = i64_to_f128(a);

  SOFTFLOAT_POSTLUDE_128(res);

  return UNIT; 
}

unit softfloat_ui64tof128(mach_bits rm, mach_bits v) {
  SOFTFLOAT_PRELUDE(rm);

  uint64_t a;
  float128_t res;

  a = (uint64_t) v;
  res = ui64_to_f128(a);

  SOFTFLOAT_POSTLUDE_128(res);

  return UNIT; 
}

unit softfloat_f32tof128(mach_bits rm, sail_bits v) {
  SOFTFLOAT_PRELUDE(rm);

  float128_t tmp;
  float32_t a;
  float128_t res;

  tmp = to_float128(v);
  a.v = (uint32_t) tmp.v[1];
  res = f32_to_f128(a);

  SOFTFLOAT_POSTLUDE_128(res);

  return UNIT; 
}
unit softfloat_f64tof128(mach_bits rm, sail_bits v) {
    SOFTFLOAT_PRELUDE(rm);

  float128_t tmp;
  float64_t a;
  float128_t res;

  tmp = to_float128(v);
  a.v = (uint64_t) tmp.v[1];
  res = f64_to_f128(a);

  SOFTFLOAT_POSTLUDE_128(res);

  return UNIT; 
}
unit softfloat_f128tof32(mach_bits rm, sail_bits v) {
  SOFTFLOAT_PRELUDE(rm);

  float128_t a;
  float32_t res;

  a = to_float128(v);
  res = f128_to_f32(a);

  SOFTFLOAT_POSTLUDE(res);

  return UNIT; 
}
unit softfloat_f128tof64(mach_bits rm, sail_bits v) {
  SOFTFLOAT_PRELUDE(rm);

  float128_t a;
  float64_t res;

  a = to_float128(v);
  res = f128_to_f64(a);

  SOFTFLOAT_POSTLUDE(res);

  return UNIT; 
}