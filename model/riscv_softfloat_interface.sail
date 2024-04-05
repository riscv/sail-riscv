/*=======================================================================================*/
/*  This Sail RISC-V architecture model, comprising all files and                        */
/*  directories except where otherwise noted is subject the BSD                          */
/*  two-clause license in the LICENSE file.                                              */
/*                                                                                       */
/*  SPDX-License-Identifier: BSD-2-Clause                                                */
/*=======================================================================================*/

/* **************************************************************** */
/* This file lists all the external Berkeley softfloat functions    */
/* invoked from the SAIL spec for RISC-V F, D and Q extensions      */
/* (in:    riscv_insts_fdext.sail)                                  */
/*                                                                  */
/* Each of these functions corresponds to one in 'SoftFloat.hs'     */
/* in    https://github.com/GaloisInc/softfloat-hs.git              */
/* written by Ben Selfridge,                                        */
/* which is a set of pure-functional Haskell wrappers on the        */
/* Berkely softfloat C library written by John Hauser.              */

/* For now, the bodies of all these functions are placeholders      */
/* while we develop    riscv_insts_fdext.sail                       */
/* They should be replaced with external calls to Berkeley softfloat*/
/* functions in a similar manner to the Haskell softfloat wrappers. */

/* **************************************************************** */
/* All arguments and results have one of these types                */

type bits_rm     = bits(3)    /* Rounding mode */
type bits_fflags = bits(5)    /* Accrued exceptions: NV,DZ,OF,UF,NX */
type bits_H      = bits(16)   /* Half-precision float value */
type bits_S      = bits(32)   /* Single-precision float value */
type bits_D      = bits(64)   /* Double-precision float value */
type bits_Q      = bits(128)  /* Quad-precision float value */
type bits_Q_low  = bits(64)   /* Quad-precision float low bits */
type bits_Q_high = bits(64)   /* Quad-precision float high bits */

type bits_W      = bits(32)   /* Signed integer */
type bits_WU     = bits(32)   /* Unsigned integer */

type bits_L      = bits(64)   /* Signed integer */
type bits_LU     = bits(64)   /* Unsigned integer */

/* ***************************************************************** */
/* Internal registers to pass results across the softfloat interface
 * to avoid return types involving structures.
 */
register float_result : bits(64)
register float_result_high : bits(64)
register float_fflags : bits(64)

/* **************************************************************** */
/* ADD/SUB/MUL/DIV                                                  */

val     extern_f16Add = pure {c: "softfloat_f16add", lem: "softfloat_f16_add"} : (bits_rm, bits_H, bits_H) -> unit
val      riscv_f16Add : (bits_rm, bits_H, bits_H) -> (bits_fflags, bits_H)
function riscv_f16Add (rm, v1, v2) = {
  extern_f16Add(rm, v1, v2);
  (float_fflags[4 .. 0], float_result[15 .. 0])
}

val     extern_f16Sub = pure {c: "softfloat_f16sub", lem: "softfloat_f16_sub"} : (bits_rm, bits_H, bits_H) -> unit
val      riscv_f16Sub : (bits_rm, bits_H, bits_H) -> (bits_fflags, bits_H)
function riscv_f16Sub (rm, v1, v2) = {
  extern_f16Sub(rm, v1, v2);
  (float_fflags[4 .. 0], float_result[15 .. 0])
}

val     extern_f16Mul = pure {c: "softfloat_f16mul", lem: "softfloat_f16_mul"} : (bits_rm, bits_H, bits_H) -> unit
val      riscv_f16Mul : (bits_rm, bits_H, bits_H) -> (bits_fflags, bits_H)
function riscv_f16Mul (rm, v1, v2) = {
  extern_f16Mul(rm, v1, v2);
  (float_fflags[4 .. 0], float_result[15 .. 0])
}

val     extern_f16Div = pure {c: "softfloat_f16div", lem: "softfloat_f16_div"} : (bits_rm, bits_H, bits_H) -> unit
val      riscv_f16Div : (bits_rm, bits_H, bits_H) -> (bits_fflags, bits_H)
function riscv_f16Div (rm, v1, v2) = {
  extern_f16Div(rm, v1, v2);
  (float_fflags[4 .. 0], float_result[15 .. 0])
}

val     extern_f32Add = pure {c: "softfloat_f32add", lem: "softfloat_f32_add"} : (bits_rm, bits_S, bits_S) -> unit
val      riscv_f32Add : (bits_rm, bits_S, bits_S) -> (bits_fflags, bits_S)
function riscv_f32Add (rm, v1, v2) = {
  extern_f32Add(rm, v1, v2);
  (float_fflags[4 .. 0], float_result[31 .. 0])
}

val     extern_f32Sub = pure {c: "softfloat_f32sub", lem: "softfloat_f32_sub"} : (bits_rm, bits_S, bits_S) -> unit
val      riscv_f32Sub : (bits_rm, bits_S, bits_S) -> (bits_fflags, bits_S)
function riscv_f32Sub (rm, v1, v2) = {
  extern_f32Sub(rm, v1, v2);
  (float_fflags[4 .. 0], float_result[31 .. 0])
}

val     extern_f32Mul = pure {c: "softfloat_f32mul", lem: "softfloat_f32_mul"} : (bits_rm, bits_S, bits_S) -> unit
val      riscv_f32Mul : (bits_rm, bits_S, bits_S) -> (bits_fflags, bits_S)
function riscv_f32Mul (rm, v1, v2) = {
  extern_f32Mul(rm, v1, v2);
  (float_fflags[4 .. 0], float_result[31 .. 0])
}

val     extern_f32Div = pure {c: "softfloat_f32div", lem: "softfloat_f32_div"} : (bits_rm, bits_S, bits_S) -> unit
val      riscv_f32Div : (bits_rm, bits_S, bits_S) -> (bits_fflags, bits_S)
function riscv_f32Div (rm, v1, v2) = {
  extern_f32Div(rm, v1, v2);
  (float_fflags[4 .. 0], float_result[31 .. 0])
}

val     extern_f64Add = pure {c: "softfloat_f64add", lem: "softfloat_f64_add"} : (bits_rm, bits_D, bits_D) -> unit
val      riscv_f64Add : (bits_rm, bits_D, bits_D) -> (bits_fflags, bits_D)
function riscv_f64Add (rm, v1, v2) = {
  extern_f64Add(rm, v1, v2);
  (float_fflags[4 .. 0], float_result)
}

val     extern_f64Sub = pure {c: "softfloat_f64sub", lem: "softfloat_f64_sub"} : (bits_rm, bits_D, bits_D) -> unit
val      riscv_f64Sub : (bits_rm, bits_D, bits_D) -> (bits_fflags, bits_D)
function riscv_f64Sub (rm, v1, v2) = {
  extern_f64Sub(rm, v1, v2);
  (float_fflags[4 .. 0], float_result)
}

val     extern_f64Mul = pure {c: "softfloat_f64mul", lem: "softfloat_f64_mul"} : (bits_rm, bits_D, bits_D) -> unit
val      riscv_f64Mul : (bits_rm, bits_D, bits_D) -> (bits_fflags, bits_D)
function riscv_f64Mul (rm, v1, v2) = {
  extern_f64Mul(rm, v1, v2);
  (float_fflags[4 .. 0], float_result)
}

val     extern_f64Div = pure {c: "softfloat_f64div", lem: "softfloat_f64_div"} : (bits_rm, bits_D, bits_D) -> unit
val      riscv_f64Div : (bits_rm, bits_D, bits_D) -> (bits_fflags, bits_D)
function riscv_f64Div (rm, v1, v2) = {
  extern_f64Div(rm, v1, v2);
  (float_fflags[4 .. 0], float_result)
}

val     extern_f128Add = pure {c: "softfloat_f128add", lem: "softfloat_f128_add"} : (bits_rm, bits_Q_low, bits_Q_high, bits_Q_low, bits_Q_high) -> unit
val      riscv_f128Add : (bits_rm, bits_Q, bits_Q) -> (bits_fflags, bits_Q)
function riscv_f128Add (rm, v1, v2) = {
  extern_f128Add(rm, v1[63..0], v1[127..64], v2[63..0], v2[127..64]);
  (float_fflags[4 .. 0], float_result_high @ float_result)
}

val     extern_f128Sub = pure {c: "softfloat_f128sub", lem: "softfloat_f128_sub"} : (bits_rm, bits_Q_low, bits_Q_high, bits_Q_low, bits_Q_high) -> unit
val      riscv_f128Sub : (bits_rm, bits_Q, bits_Q) -> (bits_fflags, bits_Q)
function riscv_f128Sub (rm, v1, v2) = {
  extern_f128Sub(rm, v1[63..0], v1[127..64], v2[63..0], v2[127..64]);
  (float_fflags[4 .. 0], float_result_high @ float_result)
}

val     extern_f128Mul = pure {c: "softfloat_f128mul", lem: "softfloat_f128_mul"} : (bits_rm, bits_Q_low, bits_Q_high, bits_Q_low, bits_Q_high) -> unit
val      riscv_f128Mul : (bits_rm, bits_Q, bits_Q) -> (bits_fflags, bits_Q)
function riscv_f128Mul (rm, v1, v2) = {
  extern_f128Mul(rm, v1[63..0], v1[127..64], v2[63..0], v2[127..64]);
  (float_fflags[4 .. 0], float_result_high @ float_result)
}

val     extern_f128Div = pure {c: "softfloat_f128div", lem: "softfloat_f128_div"} : (bits_rm, bits_Q_low, bits_Q_high, bits_Q_low, bits_Q_high) -> unit
val      riscv_f128Div : (bits_rm, bits_Q, bits_Q) -> (bits_fflags, bits_Q)
function riscv_f128Div (rm, v1, v2) = {
  extern_f128Div(rm, v1[63..0], v1[127..64], v2[63..0], v2[127..64]);
  (float_fflags[4 .. 0], float_result_high @ float_result)
}
/* **************************************************************** */
/* MULTIPLY-ADD                                                     */

val     extern_f16MulAdd = pure {c: "softfloat_f16muladd", lem: "softfloat_f16_muladd"} : (bits_rm, bits_H, bits_H, bits_H) -> unit
val      riscv_f16MulAdd : (bits_rm, bits_H, bits_H, bits_H) -> (bits_fflags, bits_H)
function riscv_f16MulAdd (rm, v1, v2, v3) = {
  extern_f16MulAdd(rm, v1, v2, v3);
  (float_fflags[4 .. 0], float_result[15 .. 0])
}

val     extern_f32MulAdd = pure {c: "softfloat_f32muladd", lem: "softfloat_f32_muladd"} : (bits_rm, bits_S, bits_S, bits_S) -> unit
val      riscv_f32MulAdd : (bits_rm, bits_S, bits_S, bits_S) -> (bits_fflags, bits_S)
function riscv_f32MulAdd (rm, v1, v2, v3) = {
  extern_f32MulAdd(rm, v1, v2, v3);
  (float_fflags[4 .. 0], float_result[31 .. 0])
}

val     extern_f64MulAdd = pure {c: "softfloat_f64muladd", lem: "softfloat_f64_muladd"} : (bits_rm, bits_D, bits_D, bits_D) -> unit
val      riscv_f64MulAdd : (bits_rm, bits_D, bits_D, bits_D) -> (bits_fflags, bits_D)
function riscv_f64MulAdd (rm, v1, v2, v3) = {
  extern_f64MulAdd(rm, v1, v2, v3);
  (float_fflags[4 .. 0], float_result)
}

val     extern_f128MulAdd = pure {c: "softfloat_f128muladd", lem: "softfloat_f128_muladd"} : (bits_rm, bits_Q_low, bits_Q_high, bits_Q_low, bits_Q_high, bits_Q_low, bits_Q_high) -> unit
val      riscv_f128MulAdd : (bits_rm, bits_Q, bits_Q, bits_Q) -> (bits_fflags, bits_Q)
function riscv_f128MulAdd (rm, v1, v2, v3) = {
  extern_f128MulAdd(rm, v1[63..0], v1[127..64], v2[63..0], v2[127..64], v3[63..0], v3[127..64]);
  (float_fflags[4 .. 0], float_result_high @ float_result)
}


/* **************************************************************** */
/* SQUARE ROOT                                                      */

val     extern_f16Sqrt = pure {c: "softfloat_f16sqrt", lem: "softfloat_f16_sqrt"} : (bits_rm, bits_H) -> unit
val      riscv_f16Sqrt : (bits_rm, bits_H) -> (bits_fflags, bits_H)
function riscv_f16Sqrt (rm, v) = {
  extern_f16Sqrt(rm, v);
  (float_fflags[4 .. 0], float_result[15 .. 0])
}

val     extern_f32Sqrt = pure {c: "softfloat_f32sqrt", lem: "softfloat_f32_sqrt"} : (bits_rm, bits_S) -> unit
val      riscv_f32Sqrt : (bits_rm, bits_S) -> (bits_fflags, bits_S)
function riscv_f32Sqrt (rm, v) = {
  extern_f32Sqrt(rm, v);
  (float_fflags[4 .. 0], float_result[31 .. 0])
}

val     extern_f64Sqrt = pure {c: "softfloat_f64sqrt", lem: "softfloat_f64_sqrt"} : (bits_rm, bits_D) -> unit
val      riscv_f64Sqrt : (bits_rm, bits_D) -> (bits_fflags, bits_D)
function riscv_f64Sqrt (rm, v) = {
  extern_f64Sqrt(rm, v);
  (float_fflags[4 .. 0], float_result)
}

val     extern_f128Sqrt = pure {c: "softfloat_f128sqrt", lem: "softfloat_f128_sqrt"} : (bits_rm, bits_Q_low, bits_Q_high) -> unit
val      riscv_f128Sqrt : (bits_rm, bits_Q) -> (bits_fflags, bits_Q)
function riscv_f128Sqrt (rm, v) = {
  extern_f128Sqrt(rm, v[63..0], v[127..64]);
  (float_fflags[4 .. 0], float_result_high @ float_result)

}

/* **************************************************************** */
/* CONVERSIONS                                                      */

val     extern_f16ToI32 = pure {c: "softfloat_f16toi32", lem: "softfloat_f16_to_i32"} : (bits_rm, bits_H) -> unit
val      riscv_f16ToI32 : (bits_rm, bits_H) -> (bits_fflags, bits_W)
function riscv_f16ToI32 (rm, v) = {
  extern_f16ToI32(rm, v);
  (float_fflags[4 .. 0], float_result[31 .. 0])
}

val     extern_f16ToUi32 = pure {c: "softfloat_f16toui32", lem: "softfloat_f16_to_ui32"} : (bits_rm, bits_H) -> unit
val      riscv_f16ToUi32 : (bits_rm, bits_H) -> (bits_fflags, bits_WU)
function riscv_f16ToUi32 (rm, v) = {
  extern_f16ToUi32(rm, v);
  (float_fflags[4 .. 0], float_result[31 .. 0])
}

val     extern_i32ToF16 = pure {c: "softfloat_i32tof16", lem: "softfloat_i32_to_f16"} : (bits_rm, bits_W) -> unit
val      riscv_i32ToF16 : (bits_rm, bits_W) -> (bits_fflags, bits_H)
function riscv_i32ToF16 (rm, v) = {
  extern_i32ToF16(rm, v);
  (float_fflags[4 .. 0], float_result[15 .. 0])
}

val     extern_ui32ToF16 = pure {c: "softfloat_ui32tof16", lem: "softfloat_ui32_to_f16"} : (bits_rm, bits_WU) -> unit
val      riscv_ui32ToF16 : (bits_rm, bits_WU) -> (bits_fflags, bits_H)
function riscv_ui32ToF16 (rm, v) = {
  extern_ui32ToF16(rm, v);
  (float_fflags[4 .. 0], float_result[15 .. 0])
}

val     extern_f16ToI64 = pure {c: "softfloat_f16toi64", lem: "softfloat_f16_to_i64"} : (bits_rm, bits_H) -> unit
val      riscv_f16ToI64 : (bits_rm, bits_H) -> (bits_fflags, bits_L)
function riscv_f16ToI64 (rm, v) = {
  extern_f16ToI64(rm, v);
  (float_fflags[4 .. 0], float_result)
}

val     extern_f16ToUi64 = pure {c: "softfloat_f16toui64", lem: "softfloat_f16_to_ui64"} : (bits_rm, bits_H) -> unit
val      riscv_f16ToUi64 : (bits_rm, bits_H) -> (bits_fflags, bits_LU)
function riscv_f16ToUi64 (rm, v) = {
  extern_f16ToUi64(rm, v);
  (float_fflags[4 .. 0], float_result)
}

val     extern_i64ToF16 = pure {c: "softfloat_i64tof16", lem: "softfloat_i64_to_f16"} : (bits_rm, bits_L) -> unit
val      riscv_i64ToF16 : (bits_rm, bits_L) -> (bits_fflags, bits_H)
function riscv_i64ToF16 (rm, v) = {
  extern_i64ToF16(rm, v);
  (float_fflags[4 .. 0], float_result[15 .. 0])
}

val     extern_ui64ToF16 = pure {c: "softfloat_ui64tof16", lem: "softfloat_ui64_to_f16"} : (bits_rm, bits_L) -> unit
val      riscv_ui64ToF16 : (bits_rm, bits_LU) -> (bits_fflags, bits_H)
function riscv_ui64ToF16 (rm, v) = {
  extern_ui64ToF16(rm, v);
  (float_fflags[4 .. 0], float_result[15 .. 0])
}


val     extern_f32ToI32 = pure {c: "softfloat_f32toi32", lem: "softfloat_f32_to_i32"} : (bits_rm, bits_S) -> unit
val      riscv_f32ToI32 : (bits_rm, bits_S) -> (bits_fflags, bits_W)
function riscv_f32ToI32 (rm, v) = {
  extern_f32ToI32(rm, v);
  (float_fflags[4 .. 0], float_result[31 .. 0])
}

val     extern_f32ToUi32 = pure {c: "softfloat_f32toui32", lem: "softfloat_f32_to_ui32"} : (bits_rm, bits_S) -> unit
val      riscv_f32ToUi32 : (bits_rm, bits_S) -> (bits_fflags, bits_WU)
function riscv_f32ToUi32 (rm, v) = {
  extern_f32ToUi32(rm, v);
  (float_fflags[4 .. 0], float_result[31 .. 0])
}

val     extern_i32ToF32 = pure {c: "softfloat_i32tof32", lem: "softfloat_i32_to_f32"} : (bits_rm, bits_W) -> unit
val      riscv_i32ToF32 : (bits_rm, bits_W) -> (bits_fflags, bits_S)
function riscv_i32ToF32 (rm, v) = {
  extern_i32ToF32(rm, v);
  (float_fflags[4 .. 0], float_result[31 .. 0])
}

val     extern_ui32ToF32 = pure {c: "softfloat_ui32tof32", lem: "softfloat_ui32_to_f32"} : (bits_rm, bits_WU) -> unit
val      riscv_ui32ToF32 : (bits_rm, bits_WU) -> (bits_fflags, bits_S)
function riscv_ui32ToF32 (rm, v) = {
  extern_ui32ToF32(rm, v);
  (float_fflags[4 .. 0], float_result[31 .. 0])
}

val     extern_f32ToI64 = pure {c: "softfloat_f32toi64", lem: "softfloat_f32_to_i64"} : (bits_rm, bits_S) -> unit
val      riscv_f32ToI64 : (bits_rm, bits_S) -> (bits_fflags, bits_L)
function riscv_f32ToI64 (rm, v) = {
  extern_f32ToI64(rm, v);
  (float_fflags[4 .. 0], float_result)
}

val     extern_f32ToUi64 = pure {c: "softfloat_f32toui64", lem: "softfloat_f32_to_ui64"} : (bits_rm, bits_S) -> unit
val      riscv_f32ToUi64 : (bits_rm, bits_S) -> (bits_fflags, bits_LU)
function riscv_f32ToUi64 (rm, v) = {
  extern_f32ToUi64(rm, v);
  (float_fflags[4 .. 0], float_result)
}

val     extern_i64ToF32 = pure {c: "softfloat_i64tof32", lem: "softfloat_i64_to_f32"} : (bits_rm, bits_L) -> unit
val      riscv_i64ToF32 : (bits_rm, bits_L) -> (bits_fflags, bits_S)
function riscv_i64ToF32 (rm, v) = {
  extern_i64ToF32(rm, v);
  (float_fflags[4 .. 0], float_result[31 .. 0])
}

val     extern_ui64ToF32 = pure {c: "softfloat_ui64tof32", lem: "softfloat_ui64_to_f32"} : (bits_rm, bits_L) -> unit
val      riscv_ui64ToF32 : (bits_rm, bits_LU) -> (bits_fflags, bits_S)
function riscv_ui64ToF32 (rm, v) = {
  extern_ui64ToF32(rm, v);
  (float_fflags[4 .. 0], float_result[31 .. 0])
}

val     extern_f64ToI32 = pure {c: "softfloat_f64toi32", lem: "softfloat_f64_to_i32"} : (bits_rm, bits_D) -> unit
val      riscv_f64ToI32 : (bits_rm, bits_D) -> (bits_fflags, bits_W)
function riscv_f64ToI32 (rm, v) = {
  extern_f64ToI32(rm, v);
  (float_fflags[4 .. 0], float_result[31 .. 0])
}

val     extern_f64ToUi32 = pure {c: "softfloat_f64toui32", lem: "softfloat_f64_to_ui32"} : (bits_rm, bits_D) -> unit
val      riscv_f64ToUi32 : (bits_rm, bits_D) -> (bits_fflags, bits_WU)
function riscv_f64ToUi32 (rm, v) = {
  extern_f64ToUi32(rm, v);
  (float_fflags[4 .. 0], float_result[31 .. 0])
}

val     extern_i32ToF64 = pure {c: "softfloat_i32tof64", lem: "softfloat_i32_to_f64"} : (bits_rm, bits_W) -> unit
val      riscv_i32ToF64 : (bits_rm, bits_W) -> (bits_fflags, bits_D)
function riscv_i32ToF64 (rm, v) = {
  extern_i32ToF64(rm, v);
  (float_fflags[4 .. 0], float_result)
}

val     extern_ui32ToF64 = pure {c: "softfloat_ui32tof64", lem: "softfloat_ui32_to_f64"} : (bits_rm, bits_WU) -> unit
val      riscv_ui32ToF64 : (bits_rm, bits_WU) -> (bits_fflags, bits_D)
function riscv_ui32ToF64 (rm, v) = {
  extern_ui32ToF64(rm, v);
  (float_fflags[4 .. 0], float_result)
}

val     extern_f64ToI64 = pure {c: "softfloat_f64toi64", lem: "softfloat_f64_to_i64"} : (bits_rm, bits_D) -> unit
val      riscv_f64ToI64 : (bits_rm, bits_D) -> (bits_fflags, bits_L)
function riscv_f64ToI64 (rm, v) = {
  extern_f64ToI64(rm, v);
  (float_fflags[4 .. 0], float_result)
}

val     extern_f64ToUi64 = pure {c: "softfloat_f64toui64", lem: "softfloat_f64_to_ui64"} : (bits_rm, bits_D) -> unit
val      riscv_f64ToUi64 : (bits_rm, bits_D) -> (bits_fflags, bits_LU)
function riscv_f64ToUi64 (rm, v) = {
  extern_f64ToUi64(rm, v);
  (float_fflags[4 .. 0], float_result)
}

val     extern_i64ToF64 = pure {c: "softfloat_i64tof64", lem: "softfloat_i64_to_f64"} : (bits_rm, bits_L) -> unit
val      riscv_i64ToF64 : (bits_rm, bits_L) -> (bits_fflags, bits_D)
function riscv_i64ToF64 (rm, v) = {
  extern_i64ToF64(rm, v);
  (float_fflags[4 .. 0], float_result)
}

val     extern_ui64ToF64 = pure {c: "softfloat_ui64tof64", lem: "softfloat_ui64_to_f64"} : (bits_rm, bits_LU) -> unit
val      riscv_ui64ToF64 : (bits_rm, bits_LU) -> (bits_fflags, bits_D)
function riscv_ui64ToF64 (rm, v) = {
  extern_ui64ToF64(rm, v);
  (float_fflags[4 .. 0], float_result)
}

val     extern_f128ToI32 = pure {c: "softfloat_f128toi32", lem: "softfloat_f128_to_i32"} : (bits_rm, bits_Q_low, bits_Q_high) -> unit
val      riscv_f128ToI32 : (bits_rm, bits_Q) -> (bits_fflags, bits_W)
function riscv_f128ToI32 (rm, v) = {
  extern_f128ToI32(rm, v[63..0], v[127..64]);
  (float_fflags[4 .. 0], float_result[31..0])
}

val     extern_f128ToUi32 = pure {c: "softfloat_f128toui32", lem: "softfloat_f128_to_ui32"} : (bits_rm, bits_Q_low, bits_Q_high) -> unit
val      riscv_f128ToUi32 : (bits_rm, bits_Q) -> (bits_fflags, bits_W)
function riscv_f128ToUi32 (rm, v) = {
  extern_f128ToUi32(rm, v[63..0], v[127..64]);
  (float_fflags[4 .. 0], float_result[31..0])
}

val     extern_i32ToF128 = pure {c: "softfloat_i32tof128", lem: "softfloat_i32_to_f128"} : (bits_rm, bits_W) -> unit
val      riscv_i32ToF128 : (bits_rm, bits_W) -> (bits_fflags, bits_Q)
function riscv_i32ToF128 (rm, v) = {
  extern_i32ToF128(rm, v);
  (float_fflags[4 .. 0], float_result_high @ float_result)
}

val     extern_ui32ToF128 = pure {c: "softfloat_ui32tof128", lem: "softfloat_ui32_to_f128"} : (bits_rm, bits_W) -> unit
val      riscv_ui32ToF128 : (bits_rm, bits_W) -> (bits_fflags, bits_Q)
function riscv_ui32ToF128 (rm, v) = {
  extern_ui32ToF128(rm, v);
  (float_fflags[4 .. 0], float_result_high @ float_result)
}

val     extern_f128ToI64 = pure {c: "softfloat_f128toi64", lem: "softfloat_f128_to_i64"} : (bits_rm, bits_Q_low, bits_Q_high) -> unit
val      riscv_f128ToI64 : (bits_rm, bits_Q) -> (bits_fflags, bits_L)
function riscv_f128ToI64 (rm, v) = {
  extern_f128ToI64(rm, v[63..0], v[127..64]);
  (float_fflags[4 .. 0], float_result)
}

val     extern_f128ToUi64 = pure {c: "softfloat_f128toui64", lem: "softfloat_f128_to_ui64"} : (bits_rm, bits_Q_low, bits_Q_high) -> unit
val      riscv_f128ToUi64 : (bits_rm, bits_Q) -> (bits_fflags, bits_LU)
function riscv_f128ToUi64 (rm, v) = {
  extern_f128ToUi64(rm, v[63..0], v[127..64]);
  (float_fflags[4 .. 0], float_result)
}

val     extern_i64ToF128 = pure {c: "softfloat_i64tof128", lem: "softfloat_i64_to_f128"} : (bits_rm, bits_L) -> unit
val      riscv_i64ToF128 : (bits_rm, bits_L) -> (bits_fflags, bits_Q)
function riscv_i64ToF128 (rm, v) = {
  extern_i64ToF128(rm, v);
  (float_fflags[4 .. 0], float_result_high @ float_result)
}

val     extern_ui64ToF128 = pure {c: "softfloat_ui64tof128", lem: "softfloat_ui64_to_f128"} : (bits_rm, bits_LU) -> unit
val      riscv_ui64ToF128 : (bits_rm, bits_LU) -> (bits_fflags, bits_Q)
function riscv_ui64ToF128 (rm, v) = {
  extern_ui64ToF128(rm, v);
  (float_fflags[4 .. 0], float_result_high @ float_result)
}

val     extern_f16ToF32 = pure {c: "softfloat_f16tof32", lem: "softfloat_f16_to_f32"} : (bits_rm, bits_H) -> unit
val      riscv_f16ToF32 : (bits_rm, bits_H) -> (bits_fflags, bits_S)
function riscv_f16ToF32 (rm, v) = {
  extern_f16ToF32(rm, v);
  (float_fflags[4 .. 0], float_result[31 .. 0])
}

val     extern_f16ToF64 = pure {c: "softfloat_f16tof64", lem: "softfloat_f16_to_f64"} : (bits_rm, bits_H) -> unit
val      riscv_f16ToF64 : (bits_rm, bits_H) -> (bits_fflags, bits_D)
function riscv_f16ToF64 (rm, v) = {
  extern_f16ToF64(rm, v);
  (float_fflags[4 .. 0], float_result)
}

val     extern_f16ToF128 = pure {c: "softfloat_f16tof128", lem: "softfloat_f16_to_f128"} : (bits_rm, bits_H) -> unit
val      riscv_f16ToF128 : (bits_rm, bits_H) -> (bits_fflags, bits_Q)
function riscv_f16ToF128 (rm, v) = {
  extern_f16ToF128(rm, v);
  (float_fflags[4 .. 0], float_result_high @ float_result)
}

val     extern_f32ToF16 = pure {c: "softfloat_f32tof16", lem: "softfloat_f32_to_f16"} : (bits_rm, bits_S) -> unit
val      riscv_f32ToF16 : (bits_rm, bits_S) -> (bits_fflags, bits_H)
function riscv_f32ToF16 (rm, v) = {
  extern_f32ToF16(rm, v);
  (float_fflags[4 .. 0], float_result[15 .. 0])
}

val     extern_f32ToF64 = pure {c: "softfloat_f32tof64", lem: "softfloat_f32_to_f64"} : (bits_rm, bits_S) -> unit
val      riscv_f32ToF64 : (bits_rm, bits_S) -> (bits_fflags, bits_D)
function riscv_f32ToF64 (rm, v) = {
  extern_f32ToF64(rm, v);
  (float_fflags[4 .. 0], float_result)
}

val     extern_f32ToF128 = pure {c: "softfloat_f32tof128", lem: "softfloat_f32_to_f128"} : (bits_rm, bits_S) -> unit
val      riscv_f32ToF128 : (bits_rm, bits_S) -> (bits_fflags, bits_Q)
function riscv_f32ToF128 (rm, v) = {
  extern_f32ToF128(rm, v);
  (float_fflags[4 .. 0], float_result_high @ float_result)
}

val     extern_f64ToF16 = pure {c: "softfloat_f64tof16", lem: "softfloat_f64_to_f16"} : (bits_rm, bits_D) -> unit
val      riscv_f64ToF16 : (bits_rm, bits_D) -> (bits_fflags, bits_H)
function riscv_f64ToF16 (rm, v) = {
  extern_f64ToF16(rm, v);
  (float_fflags[4 .. 0], float_result[15 .. 0])
}

val     extern_f64ToF32 = pure {c: "softfloat_f64tof32", lem: "softfloat_f64_to_f32"} : (bits_rm, bits_D) -> unit
val      riscv_f64ToF32 : (bits_rm, bits_D) -> (bits_fflags, bits_S)
function riscv_f64ToF32 (rm, v) = {
  extern_f64ToF32(rm, v);
  (float_fflags[4 .. 0], float_result[31 .. 0])
}

val     extern_f64ToF128 = pure {c: "softfloat_f64tof128", lem: "softfloat_f64_to_f128"} : (bits_rm, bits_D) -> unit
val      riscv_f64ToF128 : (bits_rm, bits_D) -> (bits_fflags, bits_Q)
function riscv_f64ToF128 (rm, v) = {
  extern_f64ToF128(rm, v);
  (float_fflags[4 .. 0], float_result_high @ float_result)
}

val     extern_f128ToF16 = pure {c: "softfloat_f128tof16", lem: "softfloat_f128_to_f16"} : (bits_rm, bits_Q_low, bits_Q_high) -> unit
val      riscv_f128ToF16 : (bits_rm, bits_Q) -> (bits_fflags, bits_H)
function riscv_f128ToF16 (rm, v) = {
  extern_f128ToF16(rm, v[63..0], v[127..64]);
  (float_fflags[4 .. 0], float_result[15..0])
}

val     extern_f128ToF32 = pure {c: "softfloat_f128tof32", lem: "softfloat_f128_to_f32"} : (bits_rm, bits_Q_low, bits_Q_high) -> unit
val      riscv_f128ToF32 : (bits_rm, bits_Q) -> (bits_fflags, bits_S)
function riscv_f128ToF32 (rm, v) = {
  extern_f128ToF32(rm, v[63..0], v[127..64]);
  (float_fflags[4 .. 0], float_result[31..0])
}

val     extern_f128ToF64 = pure {c: "softfloat_f128tof64", lem: "softfloat_f128_to_f64"} : (bits_rm, bits_Q_low, bits_Q_high) -> unit
val      riscv_f128ToF64 : (bits_rm, bits_Q) -> (bits_fflags, bits_D)
function riscv_f128ToF64 (rm, v) = {
  extern_f128ToF64(rm, v[63..0], v[127..64]);
  (float_fflags[4 .. 0], float_result)
}

/* **************************************************************** */
/* COMPARISONS                                                      */

val     extern_f16Lt = pure {c: "softfloat_f16lt", lem: "softfloat_f16_lt"} : (bits_H, bits_H) -> unit
val      riscv_f16Lt : (bits_H, bits_H) -> (bits_fflags, bool)
function riscv_f16Lt (v1, v2) = {
  extern_f16Lt(v1, v2);
  (float_fflags[4 .. 0], bit_to_bool(float_result[0]))
}

val     extern_f16Lt_quiet = pure {c: "softfloat_f16lt_quiet", lem: "softfloat_f16_lt_quiet"} : (bits_H, bits_H) -> unit
val      riscv_f16Lt_quiet : (bits_H, bits_H) -> (bits_fflags, bool)
function riscv_f16Lt_quiet (v1, v2) = {
  extern_f16Lt_quiet(v1, v2);
  (float_fflags[4 .. 0], bit_to_bool(float_result[0]))
}

val     extern_f16Le = pure {c: "softfloat_f16le", lem: "softfloat_f16_le"} : (bits_H, bits_H) -> unit
val      riscv_f16Le : (bits_H, bits_H) -> (bits_fflags, bool)
function riscv_f16Le (v1, v2) = {
  extern_f16Le(v1, v2);
  (float_fflags[4 .. 0], bit_to_bool(float_result[0]))
}

val     extern_f16Le_quiet = pure {c: "softfloat_f16le_quiet", lem: "softfloat_f16_le_quiet"} : (bits_H, bits_H) -> unit
val      riscv_f16Le_quiet : (bits_H, bits_H) -> (bits_fflags, bool)
function riscv_f16Le_quiet (v1, v2) = {
  extern_f16Le_quiet(v1, v2);
  (float_fflags[4 .. 0], bit_to_bool(float_result[0]))
}

val     extern_f16Eq = pure {c: "softfloat_f16eq", lem: "softfloat_f16_eq"} : (bits_H, bits_H) -> unit
val      riscv_f16Eq : (bits_H, bits_H) -> (bits_fflags, bool)
function riscv_f16Eq (v1, v2) = {
  extern_f16Eq(v1, v2);
  (float_fflags[4 .. 0], bit_to_bool(float_result[0]))
}

val     extern_f32Lt = pure {c: "softfloat_f32lt", lem: "softfloat_f32_lt"} : (bits_S, bits_S) -> unit
val      riscv_f32Lt : (bits_S, bits_S) -> (bits_fflags, bool)
function riscv_f32Lt (v1, v2) = {
  extern_f32Lt(v1, v2);
  (float_fflags[4 .. 0], bit_to_bool(float_result[0]))
}

val     extern_f32Lt_quiet = pure {c: "softfloat_f32lt_quiet", lem: "softfloat_f32_lt_quiet"} : (bits_S, bits_S) -> unit
val      riscv_f32Lt_quiet : (bits_S, bits_S) -> (bits_fflags, bool)
function riscv_f32Lt_quiet (v1, v2) = {
  extern_f32Lt_quiet(v1, v2);
  (float_fflags[4 .. 0], bit_to_bool(float_result[0]))
}

val     extern_f32Le = pure {c: "softfloat_f32le", lem: "softfloat_f32_le"} : (bits_S, bits_S) -> unit
val      riscv_f32Le : (bits_S, bits_S) -> (bits_fflags, bool)
function riscv_f32Le (v1, v2) = {
  extern_f32Le(v1, v2);
  (float_fflags[4 .. 0], bit_to_bool(float_result[0]))
}

val     extern_f32Le_quiet = pure {c: "softfloat_f32le_quiet", lem: "softfloat_f32_le_quiet"} : (bits_S, bits_S) -> unit
val      riscv_f32Le_quiet : (bits_S, bits_S) -> (bits_fflags, bool)
function riscv_f32Le_quiet (v1, v2) = {
  extern_f32Le_quiet(v1, v2);
  (float_fflags[4 .. 0], bit_to_bool(float_result[0]))
}

val     extern_f32Eq = pure {c: "softfloat_f32eq", lem: "softfloat_f32_eq"} : (bits_S, bits_S) -> unit
val      riscv_f32Eq : (bits_S, bits_S) -> (bits_fflags, bool)
function riscv_f32Eq (v1, v2) = {
  extern_f32Eq(v1, v2);
  (float_fflags[4 .. 0], bit_to_bool(float_result[0]))
}

val     extern_f64Lt = pure {c: "softfloat_f64lt", lem: "softfloat_f64_lt"} : (bits_D, bits_D) -> unit
val      riscv_f64Lt : (bits_D, bits_D) -> (bits_fflags, bool)
function riscv_f64Lt (v1, v2) = {
  extern_f64Lt(v1, v2);
  (float_fflags[4 .. 0], bit_to_bool(float_result[0]))
}

val     extern_f64Lt_quiet = pure {c: "softfloat_f64lt_quiet", lem: "softfloat_f64_lt_quiet"} : (bits_D, bits_D) -> unit
val      riscv_f64Lt_quiet : (bits_D, bits_D) -> (bits_fflags, bool)
function riscv_f64Lt_quiet (v1, v2) = {
  extern_f64Lt_quiet(v1, v2);
  (float_fflags[4 .. 0], bit_to_bool(float_result[0]))
}

val     extern_f64Le = pure {c: "softfloat_f64le", lem: "softfloat_f64_le"} : (bits_D, bits_D) -> unit
val      riscv_f64Le : (bits_D, bits_D) -> (bits_fflags, bool)
function riscv_f64Le (v1, v2) = {
  extern_f64Le(v1, v2);
  (float_fflags[4 .. 0], bit_to_bool(float_result[0]))
}

val     extern_f64Le_quiet = pure {c: "softfloat_f64le_quiet", lem: "softfloat_f64_le_quiet"} : (bits_D, bits_D) -> unit
val      riscv_f64Le_quiet : (bits_D, bits_D) -> (bits_fflags, bool)
function riscv_f64Le_quiet (v1, v2) = {
  extern_f64Le_quiet(v1, v2);
  (float_fflags[4 .. 0], bit_to_bool(float_result[0]))
}

val     extern_f64Eq = pure {c: "softfloat_f64eq", lem: "softfloat_f64_eq"} : (bits_D, bits_D) -> unit
val      riscv_f64Eq : (bits_D, bits_D) -> (bits_fflags, bool)
function riscv_f64Eq (v1, v2) = {
  extern_f64Eq(v1, v2);
  (float_fflags[4 .. 0], bit_to_bool(float_result[0]))
}

val     extern_f128Lt = pure {c: "softfloat_f128lt", lem: "softfloat_f128_lt"} : (bits_Q_low, bits_Q_high, bits_Q_low, bits_Q_high) -> unit
val      riscv_f128Lt : (bits_Q, bits_Q) -> (bits_fflags, bool)
function riscv_f128Lt (v1, v2) = {
  extern_f128Lt(v1[63..0], v1[127..64], v2[63..0], v2[127..64]);
  (float_fflags[4 .. 0], bit_to_bool(float_result[0]))
}

val     extern_f128Lt_quiet = pure {c: "softfloat_f128lt_quiet", lem: "softfloat_f128_lt_quiet"} : (bits_Q_low, bits_Q_high, bits_Q_low, bits_Q_high) -> unit
val      riscv_f128Lt_quiet : (bits_Q, bits_Q) -> (bits_fflags, bool)
function riscv_f128Lt_quiet (v1, v2) = {
  extern_f128Lt_quiet(v1[63..0], v1[127..64], v2[63..0], v2[127..64]);
  (float_fflags[4 .. 0], bit_to_bool(float_result[0]))
}

val     extern_f128Le = pure {c: "softfloat_f128le", lem: "softfloat_f128_le"} : (bits_Q_low, bits_Q_high, bits_Q_low, bits_Q_high) -> unit
val      riscv_f128Le : (bits_Q, bits_Q) -> (bits_fflags, bool)
function riscv_f128Le (v1, v2) = {
  extern_f128Le(v1[63..0], v1[127..64], v2[63..0], v2[127..64]);
  (float_fflags[4 .. 0], bit_to_bool(float_result[0]))
}

val     extern_f128Le_quiet = pure {c: "softfloat_f128le_quiet", lem: "softfloat_f128_le_quiet"} : (bits_Q_low, bits_Q_high, bits_Q_low, bits_Q_high) -> unit
val      riscv_f128Le_quiet : (bits_Q, bits_Q) -> (bits_fflags, bool)
function riscv_f128Le_quiet (v1, v2) = {
  extern_f128Le_quiet(v1[63..0], v1[127..64], v2[63..0], v2[127..64]);
  (float_fflags[4 .. 0], bit_to_bool(float_result[0]))
}

val     extern_f128Eq = pure {c: "softfloat_f128eq", lem: "softfloat_f128_eq"} : (bits_Q_low, bits_Q_high, bits_Q_low, bits_Q_high) -> unit
val      riscv_f128Eq : (bits_Q, bits_Q) -> (bits_fflags, bool)
function riscv_f128Eq (v1, v2) = {
  extern_f128Eq(v1[63..0], v1[127..64], v2[63..0], v2[127..64]);
  (float_fflags[4 .. 0], bit_to_bool(float_result[0]))
}

val     extern_f16roundToInt = pure {c: "softfloat_f16roundToInt", lem: "softfloat_f16_round_to_int"} : (bits_rm, bits_H, bool) -> unit
val      riscv_f16roundToInt : (bits_rm, bits_H, bool) -> (bits_fflags, bits_H)
function riscv_f16roundToInt (rm, v, exact) = {
  extern_f16roundToInt(rm, v, exact);
  (float_fflags[4 .. 0], float_result[15 .. 0])
}

val     extern_f32roundToInt = pure {c: "softfloat_f32roundToInt", lem: "softfloat_f32_round_to_int"} : (bits_rm, bits_S, bool) -> unit
val      riscv_f32roundToInt : (bits_rm, bits_S, bool) -> (bits_fflags, bits_S)
function riscv_f32roundToInt (rm, v, exact) = {
  extern_f32roundToInt(rm, v, exact);
  (float_fflags[4 .. 0], float_result[31 .. 0])
}

val     extern_f64roundToInt = pure {c: "softfloat_f64roundToInt", lem: "softfloat_f64_round_to_int"} : (bits_rm, bits_D, bool) -> unit
val      riscv_f64roundToInt : (bits_rm, bits_D, bool) -> (bits_fflags, bits_D)
function riscv_f64roundToInt (rm, v, exact) = {
  extern_f64roundToInt(rm, v, exact);
  (float_fflags[4 .. 0], float_result[63 .. 0])
}

val     extern_f128roundToInt = pure {c: "softfloat_f128roundToInt", lem: "softfloat_f128_round_to_int"} : (bits_rm, bits_Q_low, bits_Q_high, bool) -> unit
val      riscv_f128roundToInt : (bits_rm, bits_Q, bool) -> (bits_fflags, bits_Q)
function riscv_f128roundToInt (rm, v, exact) = {
  extern_f128roundToInt(rm, v[63..0], v[127..64], exact);
  (float_fflags[4 .. 0], float_result_high @ float_result)
}
/* **************************************************************** */
