// =======================================================================================
// This Sail RISC-V architecture model, comprising all files and
// directories except where otherwise noted is subject the BSD
// two-clause license in the LICENSE file.
//
// SPDX-License-Identifier: BSD-2-Clause
// =======================================================================================

// ***************************************************************
// This file lists all the external Berkeley softfloat functions
// invoked from the Sail spec for RISC-V floating point extensions.
//
// Each of these functions corresponds to one in 'SoftFloat.hs'
// in    https://github.com/GaloisInc/softfloat-hs.git
// written by Ben Selfridge,
// which is a set of pure-functional Haskell wrappers on the
// Berkely softfloat C library written by John Hauser.

// ***************************************************************
// All arguments and results have one of these types

type bits_rm     = bits(3)    // Rounding mode
type bits_fflags = bits(5)    // Accrued exceptions: NV,DZ,OF,UF,NX
type bits_BF16   = bits(16)   // BFloat16-precision float value
type bits_H      = bits(16)   // Half-precision float value
type bits_S      = bits(32)   // Single-precision float value
type bits_D      = bits(64)   // Double-precision float value
type bits_Q      = bits(128)  // Quad-precision float value
type bits_Q_low  = bits(64)   // Quad-precision float low bits
type bits_Q_high = bits(64)   // Quad-precision float high bits

type bits_W      = bits(32)   // Signed integer
type bits_WU     = bits(32)   // Unsigned integer

type bits_L      = bits(64)   // Signed integer
type bits_LU     = bits(64)   // Unsigned integer

// ****************************************************************
// ADD/SUB/MUL/DIV

val riscv_f16Add = pure {cpp: "softfloat_f16add", lem: "softfloat_f16_add"} : (bits_rm, bits_H, bits_H) -> (bits_fflags, bits_H)
val riscv_f16Sub = pure {cpp: "softfloat_f16sub", lem: "softfloat_f16_sub"} : (bits_rm, bits_H, bits_H) -> (bits_fflags, bits_H)
val riscv_f16Mul = pure {cpp: "softfloat_f16mul", lem: "softfloat_f16_mul"} : (bits_rm, bits_H, bits_H) -> (bits_fflags, bits_H)
val riscv_f16Div = pure {cpp: "softfloat_f16div", lem: "softfloat_f16_div"} : (bits_rm, bits_H, bits_H) -> (bits_fflags, bits_H)
val riscv_f32Add = pure {cpp: "softfloat_f32add", lem: "softfloat_f32_add"} : (bits_rm, bits_S, bits_S) -> (bits_fflags, bits_S)
val riscv_f32Sub = pure {cpp: "softfloat_f32sub", lem: "softfloat_f32_sub"} : (bits_rm, bits_S, bits_S) -> (bits_fflags, bits_S)
val riscv_f32Mul = pure {cpp: "softfloat_f32mul", lem: "softfloat_f32_mul"} : (bits_rm, bits_S, bits_S) -> (bits_fflags, bits_S)
val riscv_f32Div = pure {cpp: "softfloat_f32div", lem: "softfloat_f32_div"} : (bits_rm, bits_S, bits_S) -> (bits_fflags, bits_S)
val riscv_f64Add = pure {cpp: "softfloat_f64add", lem: "softfloat_f64_add"} : (bits_rm, bits_D, bits_D) -> (bits_fflags, bits_D)
val riscv_f64Sub = pure {cpp: "softfloat_f64sub", lem: "softfloat_f64_sub"} : (bits_rm, bits_D, bits_D) -> (bits_fflags, bits_D)
val riscv_f64Mul = pure {cpp: "softfloat_f64mul", lem: "softfloat_f64_mul"} : (bits_rm, bits_D, bits_D) -> (bits_fflags, bits_D)
val riscv_f64Div = pure {cpp: "softfloat_f64div", lem: "softfloat_f64_div"} : (bits_rm, bits_D, bits_D) -> (bits_fflags, bits_D)

val extern_f128Add = pure {cpp: "softfloat_f128add", lem: "softfloat_f128_add"} : (bits_rm, bits_Q_low, bits_Q_high, bits_Q_low, bits_Q_high) -> (bits_fflags, bits_Q_low, bits_Q_high)
function riscv_f128Add (rm : bits_rm, v1 : bits_Q, v2 : bits_Q) -> (bits_fflags, bits_Q) = {
    let (fflags, res_low, res_high) = extern_f128Add(rm, v1[63..0], v1[127..64], v2[63..0], v2[127..64]);
    return (fflags, res_high @ res_low);
}
val extern_f128Sub = pure {cpp: "softfloat_f128sub", lem: "softfloat_f128_sub"} : (bits_rm, bits_Q_low, bits_Q_high, bits_Q_low, bits_Q_high) -> (bits_fflags, bits_Q_low, bits_Q_high)
function riscv_f128Sub (rm : bits_rm, v1 : bits_Q, v2 : bits_Q) -> (bits_fflags, bits_Q) = {
    let (fflags, res_low, res_high) = extern_f128Sub(rm, v1[63..0], v1[127..64], v2[63..0], v2[127..64]);
    return (fflags, res_high @ res_low);
}
val extern_f128Mul = pure {cpp: "softfloat_f128add", lem: "softfloat_f128_add"} : (bits_rm, bits_Q_low, bits_Q_high, bits_Q_low, bits_Q_high) -> (bits_fflags, bits_Q_low, bits_Q_high)
function riscv_f128Mul (rm : bits_rm, v1 : bits_Q, v2 : bits_Q) -> (bits_fflags, bits_Q) = {
    let (fflags, res_low, res_high) = extern_f128Mul(rm, v1[63..0], v1[127..64], v2[63..0], v2[127..64]);
    return (fflags, res_high @ res_low);
}
val extern_f128Div = pure {cpp: "softfloat_f128div", lem: "softfloat_f128_div"} : (bits_rm, bits_Q_low, bits_Q_high, bits_Q_low, bits_Q_high) -> (bits_fflags, bits_Q_low, bits_Q_high)
function riscv_f128Div (rm : bits_rm, v1 : bits_Q, v2 : bits_Q) -> (bits_fflags, bits_Q) = {
    let (fflags, res_low, res_high) = extern_f128Div(rm, v1[63..0], v1[127..64], v2[63..0], v2[127..64]);
    return (fflags, res_high @ res_low);
}

// ****************************************************************
// MULTIPLY-ADD

val riscv_f16MulAdd = pure {cpp: "softfloat_f16muladd", lem: "softfloat_f16_muladd"} : (bits_rm, bits_H, bits_H, bits_H) -> (bits_fflags, bits_H)
val riscv_f32MulAdd = pure {cpp: "softfloat_f32muladd", lem: "softfloat_f32_muladd"} : (bits_rm, bits_S, bits_S, bits_S) -> (bits_fflags, bits_S)
val riscv_f64MulAdd = pure {cpp: "softfloat_f64muladd", lem: "softfloat_f64_muladd"} : (bits_rm, bits_D, bits_D, bits_D) -> (bits_fflags, bits_D)

val extern_f128MulAdd = pure {cpp: "softfloat_f128muladd", lem: "softfloat_f128_muladd"} : (bits_rm, bits_Q_low, bits_Q_high, bits_Q_low, bits_Q_high, bits_Q_low, bits_Q_high) -> (bits_fflags, bits_Q_low, bits_Q_high)
function riscv_f128MulAdd (rm : bits_rm, v1 : bits_Q, v2 : bits_Q, v3 : bits_Q) -> (bits_fflags, bits_Q) = {
    let (fflags, res_low, res_high) = extern_f128MulAdd(rm, v1[63..0], v1[127..64], v2[63..0], v2[127..64], v3[63..0], v3[127..64]);
    return (fflags, res_high @ res_low);
}

// ****************************************************************
// SQUARE ROOT

val riscv_f16Sqrt = pure {cpp: "softfloat_f16sqrt", lem: "softfloat_f16_sqrt"} : (bits_rm, bits_H) -> (bits_fflags, bits_H)
val riscv_f32Sqrt = pure {cpp: "softfloat_f32sqrt", lem: "softfloat_f32_sqrt"} : (bits_rm, bits_S) -> (bits_fflags, bits_S)
val riscv_f64Sqrt = pure {cpp: "softfloat_f64sqrt", lem: "softfloat_f64_sqrt"} : (bits_rm, bits_D) -> (bits_fflags, bits_D)

val extern_f128Sqrt = pure {cpp: "softfloat_f128sqrt", lem: "softfloat_f128_sqrt"} : (bits_rm, bits_Q_low, bits_Q_high) -> (bits_fflags, bits_Q_low, bits_Q_high)
function riscv_f128Sqrt (rm : bits_rm, v1 : bits_Q) -> (bits_fflags, bits_Q) = {
    let (fflags, res_low, res_high) = extern_f128Sqrt(rm, v1[63..0], v1[127..64]);
    return (fflags, res_high @ res_low);
}

// ****************************************************************
// CONVERSIONS

val riscv_f16ToI32 = pure {cpp: "softfloat_f16toi32", lem: "softfloat_f16_to_i32"} : (bits_rm, bits_H) -> (bits_fflags, bits_W)
val riscv_f16ToUi32 = pure {cpp: "softfloat_f16toui32", lem: "softfloat_f16_to_ui32"} : (bits_rm, bits_H) -> (bits_fflags, bits_WU)
val riscv_i32ToF16 = pure {cpp: "softfloat_i32tof16", lem: "softfloat_i32_to_f16"} : (bits_rm, bits_W) -> (bits_fflags, bits_H)
val riscv_ui32ToF16 = pure {cpp: "softfloat_ui32tof16", lem: "softfloat_ui32_to_f16"} : (bits_rm, bits_WU) -> (bits_fflags, bits_H)
val riscv_f16ToI64 = pure {cpp: "softfloat_f16toi64", lem: "softfloat_f16_to_i64"} : (bits_rm, bits_H) -> (bits_fflags, bits_L)
val riscv_f16ToUi64 = pure {cpp: "softfloat_f16toui64", lem: "softfloat_f16_to_ui64"} : (bits_rm, bits_H) -> (bits_fflags, bits_LU)
val riscv_i64ToF16 = pure {cpp: "softfloat_i64tof16", lem: "softfloat_i64_to_f16"} : (bits_rm, bits_L) -> (bits_fflags, bits_H)
val riscv_ui64ToF16 = pure {cpp: "softfloat_ui64tof16", lem: "softfloat_ui64_to_f16"} : (bits_rm, bits_LU) -> (bits_fflags, bits_H)

val riscv_f32ToI32 = pure {cpp: "softfloat_f32toi32", lem: "softfloat_f32_to_i32"} : (bits_rm, bits_S) -> (bits_fflags, bits_W)
val riscv_f32ToUi32 = pure {cpp: "softfloat_f32toui32", lem: "softfloat_f32_to_ui32"} : (bits_rm, bits_S) -> (bits_fflags, bits_WU)
val riscv_i32ToF32 = pure {cpp: "softfloat_i32tof32", lem: "softfloat_i32_to_f32"} : (bits_rm, bits_W) -> (bits_fflags, bits_S)
val riscv_ui32ToF32 = pure {cpp: "softfloat_ui32tof32", lem: "softfloat_ui32_to_f32"} : (bits_rm, bits_WU) -> (bits_fflags, bits_S)
val riscv_f32ToI64 = pure {cpp: "softfloat_f32toi64", lem: "softfloat_f32_to_i64"} : (bits_rm, bits_S) -> (bits_fflags, bits_L)
val riscv_f32ToUi64 = pure {cpp: "softfloat_f32toui64", lem: "softfloat_f32_to_ui64"} : (bits_rm, bits_S) -> (bits_fflags, bits_LU)
val riscv_i64ToF32 = pure {cpp: "softfloat_i64tof32", lem: "softfloat_i64_to_f32"} : (bits_rm, bits_L) -> (bits_fflags, bits_S)
val riscv_ui64ToF32 = pure {cpp: "softfloat_ui64tof32", lem: "softfloat_ui64_to_f32"} : (bits_rm, bits_LU) -> (bits_fflags, bits_S)
val riscv_f64ToI32 = pure {cpp: "softfloat_f64toi32", lem: "softfloat_f64_to_i32"} : (bits_rm, bits_D) -> (bits_fflags, bits_W)
val riscv_f64ToUi32 = pure {cpp: "softfloat_f64toui32", lem: "softfloat_f64_to_ui32"} : (bits_rm, bits_D) -> (bits_fflags, bits_WU)
val riscv_i32ToF64 = pure {cpp: "softfloat_i32tof64", lem: "softfloat_i32_to_f64"} : (bits_rm, bits_W) -> (bits_fflags, bits_D)
val riscv_ui32ToF64 = pure {cpp: "softfloat_ui32tof64", lem: "softfloat_ui32_to_f64"} : (bits_rm, bits_WU) -> (bits_fflags, bits_D)
val riscv_f64ToI64 = pure {cpp: "softfloat_f64toi64", lem: "softfloat_f64_to_i64"} : (bits_rm, bits_D) -> (bits_fflags, bits_L)
val riscv_f64ToUi64 = pure {cpp: "softfloat_f64toui64", lem: "softfloat_f64_to_ui64"} : (bits_rm, bits_D) -> (bits_fflags, bits_LU)
val riscv_i64ToF64 = pure {cpp: "softfloat_i64tof64", lem: "softfloat_i64_to_f64"} : (bits_rm, bits_L) -> (bits_fflags, bits_D)
val riscv_ui64ToF64 = pure {cpp: "softfloat_ui64tof64", lem: "softfloat_ui64_to_f64"} : (bits_rm, bits_LU) -> (bits_fflags, bits_D)
val riscv_f16ToF32 = pure {cpp: "softfloat_f16tof32", lem: "softfloat_f16_to_f32"} : (bits_rm, bits_H) -> (bits_fflags, bits_S)
val riscv_f16ToF64 = pure {cpp: "softfloat_f16tof64", lem: "softfloat_f16_to_f64"} : (bits_rm, bits_H) -> (bits_fflags, bits_D)
val riscv_f32ToF64 = pure {cpp: "softfloat_f32tof64", lem: "softfloat_f32_to_f64"} : (bits_rm, bits_S) -> (bits_fflags, bits_D)
val riscv_f32ToF16 = pure {cpp: "softfloat_f32tof16", lem: "softfloat_f32_to_f16"} : (bits_rm, bits_S) -> (bits_fflags, bits_H)
val riscv_f64ToF16 = pure {cpp: "softfloat_f64tof16", lem: "softfloat_f64_to_f16"} : (bits_rm, bits_D) -> (bits_fflags, bits_H)
val riscv_f64ToF32 = pure {cpp: "softfloat_f64tof32", lem: "softfloat_f64_to_f32"} : (bits_rm, bits_D) -> (bits_fflags, bits_S)
val riscv_f32ToBF16 = pure {cpp: "softfloat_f32tobf16", lem: "softfloat_f32_to_bf16"} : (bits_rm, bits_S) -> (bits_fflags, bits_BF16)

val extern_f128ToI32 = pure {cpp: "softfloat_f128toi32", lem: "softfloat_f128_to_i32"} : (bits_rm, bits_Q_low, bits_Q_high) -> (bits_fflags, bits_W)
function riscv_f128ToI32 (rm : bits_rm, v1 : bits_Q) -> (bits_fflags, bits_W) = {
    return extern_f128ToI32(rm, v1[63..0], v1[127..64]);
}
val extern_f128ToUi32 = pure {cpp: "softfloat_f128toui32", lem: "softfloat_f128_to_ui32"} : (bits_rm, bits_Q_low, bits_Q_high) -> (bits_fflags, bits_WU)
function riscv_f128ToUi32 (rm : bits_rm, v1 : bits_Q) -> (bits_fflags, bits_WU) = {
    return extern_f128ToUi32(rm, v1[63..0], v1[127..64]);
}
val extern_f128ToI64 = pure {cpp: "softfloat_f128toi64", lem: "softfloat_f128_to_i64"} : (bits_rm, bits_Q_low, bits_Q_high) -> (bits_fflags, bits_L)
function riscv_f128ToI64 (rm : bits_rm, v1 : bits_Q) -> (bits_fflags, bits_L) = {
    return extern_f128ToI64(rm, v1[63..0], v1[127..64]);
}
val extern_f128ToUi64 = pure {cpp: "softfloat_f128toui64", lem: "softfloat_f128_to_ui64"} : (bits_rm, bits_Q_low, bits_Q_high) -> (bits_fflags, bits_LU)
function riscv_f128ToUi64 (rm : bits_rm, v1 : bits_Q) -> (bits_fflags, bits_LU) = {
    return extern_f128ToUi64(rm, v1[63..0], v1[127..64]);
}
val extern_i32ToF128 = pure {cpp: "softfloat_i32tof128", lem: "softfloat_i32_to_f128"} : (bits_rm, bits_W) -> (bits_fflags, bits_Q_low, bits_Q_high)
function riscv_i32ToF128 (rm : bits_rm, v1 : bits_W) -> (bits_fflags, bits_Q) = {
    let (fflags, res_low, res_high) = extern_i32ToF128(rm, v1);
    return (fflags, res_high @ res_low);
}
val extern_ui32ToF128 = pure {cpp: "softfloat_ui32tof128", lem: "softfloat_ui32_to_f128"} : (bits_rm, bits_WU) -> (bits_fflags, bits_Q_low, bits_Q_high)
function riscv_ui32ToF128 (rm : bits_rm, v1 : bits_WU) -> (bits_fflags, bits_Q) = {
    let (fflags, res_low, res_high) = extern_ui32ToF128(rm, v1);
    return (fflags, res_high @ res_low);
}
val extern_i64ToF128 = pure {cpp: "softfloat_i64tof128", lem: "softfloat_i64_to_f128"} : (bits_rm, bits_L) -> (bits_fflags, bits_Q_low, bits_Q_high)
function riscv_i64ToF128 (rm : bits_rm, v1 : bits_L) -> (bits_fflags, bits_Q) = {
    let (fflags, res_low, res_high) = extern_i64ToF128(rm, v1);
    return (fflags, res_high @ res_low);
}
val extern_ui64ToF128 = pure {cpp: "softfloat_ui64tof128", lem: "softfloat_ui64_to_f128"} : (bits_rm, bits_LU) -> (bits_fflags, bits_Q_low, bits_Q_high)
function riscv_ui64ToF128 (rm : bits_rm, v1 : bits_LU) -> (bits_fflags, bits_Q) = {
    let (fflags, res_low, res_high) = extern_ui64ToF128(rm, v1);
    return (fflags, res_high @ res_low);
}

val extern_f16ToF128 = pure {cpp: "softfloat_f16tof128", lem: "softfloat_f16_to_f128"} : (bits_rm, bits_H) -> (bits_fflags, bits_Q_low, bits_Q_high)
function riscv_f16ToF128 (rm : bits_rm, v1 : bits_H) -> (bits_fflags, bits_Q) = {
    let (fflags, res_low, res_high) = extern_f16ToF128(rm, v1);
    return (fflags, res_high @ res_low);
}
val extern_f32ToF128 = pure {cpp: "softfloat_f32tof128", lem: "softfloat_f32_to_f128"} : (bits_rm, bits_S) -> (bits_fflags, bits_Q_low, bits_Q_high)
function riscv_f32ToF128 (rm : bits_rm, v1 : bits_S) -> (bits_fflags, bits_Q) = {
    let (fflags, res_low, res_high) = extern_f32ToF128(rm, v1);
    return (fflags, res_high @ res_low);
}
val extern_f64ToF128 = pure {cpp: "softfloat_f64tof128", lem: "softfloat_f64_to_f128"} : (bits_rm, bits_D) -> (bits_fflags, bits_Q_low, bits_Q_high)
function riscv_f64ToF128 (rm : bits_rm, v1 : bits_D) -> (bits_fflags, bits_Q) = {
    let (fflags, res_low, res_high) = extern_f64ToF128(rm, v1);
    return (fflags, res_high @ res_low);
}

val extern_f128ToF16 = pure {cpp: "softfloat_f128tof16", lem: "softfloat_f128_to_f16"} : (bits_rm, bits_Q_low, bits_Q_high) -> (bits_fflags, bits_H)
function riscv_f128ToF16 (rm : bits_rm, v1 : bits_Q) -> (bits_fflags, bits_H) = {
    return extern_f128ToF16(rm, v1[63..0], v1[127..64]);
}
val extern_f128ToF32 = pure {cpp: "softfloat_f128tof32", lem: "softfloat_f128_to_f32"} : (bits_rm, bits_Q_low, bits_Q_high) -> (bits_fflags, bits_S)
function riscv_f128ToF32 (rm : bits_rm, v1 : bits_Q) -> (bits_fflags, bits_S) = {
    return extern_f128ToF32(rm, v1[63..0], v1[127..64]);
}
val extern_f128ToF64 = pure {cpp: "softfloat_f128tof64", lem: "softfloat_f128_to_f64"} : (bits_rm, bits_Q_low, bits_Q_high) -> (bits_fflags, bits_D)
function riscv_f128ToF64 (rm : bits_rm, v1 : bits_Q) -> (bits_fflags, bits_D) = {
    return extern_f128ToF64(rm, v1[63..0], v1[127..64]);
}

// ****************************************************************
// COMPARISONS

val riscv_f16Lt = pure {cpp: "softfloat_f16lt", lem: "softfloat_f16_lt"} : (bits_H, bits_H) -> (bits_fflags, bool)
val riscv_f16Lt_quiet = pure {cpp: "softfloat_f16lt_quiet", lem: "softfloat_f16_lt_quiet"} : (bits_H, bits_H) -> (bits_fflags, bool)
val riscv_f16Le = pure {cpp: "softfloat_f16le", lem: "softfloat_f16_le"} : (bits_H, bits_H) -> (bits_fflags, bool)
val riscv_f16Le_quiet = pure {cpp: "softfloat_f16le_quiet", lem: "softfloat_f16_le_quiet"} : (bits_H, bits_H) -> (bits_fflags, bool)
val riscv_f16Eq = pure {cpp: "softfloat_f16eq", lem: "softfloat_f16_eq"} : (bits_H, bits_H) -> (bits_fflags, bool)
val riscv_f32Lt = pure {cpp: "softfloat_f32lt", lem: "softfloat_f32_lt"} : (bits_S, bits_S) -> (bits_fflags, bool)
val riscv_f32Lt_quiet = pure {cpp: "softfloat_f32lt_quiet", lem: "softfloat_f32_lt_quiet"} : (bits_S, bits_S) -> (bits_fflags, bool)
val riscv_f32Le = pure {cpp: "softfloat_f32le", lem: "softfloat_f32_le"} : (bits_S, bits_S) -> (bits_fflags, bool)
val riscv_f32Le_quiet = pure {cpp: "softfloat_f32le_quiet", lem: "softfloat_f32_le_quiet"} : (bits_S, bits_S) -> (bits_fflags, bool)
val riscv_f32Eq = pure {cpp: "softfloat_f32eq", lem: "softfloat_f32_eq"} : (bits_S, bits_S) -> (bits_fflags, bool)
val riscv_f64Lt = pure {cpp: "softfloat_f64lt", lem: "softfloat_f64_lt"} : (bits_D, bits_D) -> (bits_fflags, bool)
val riscv_f64Lt_quiet = pure {cpp: "softfloat_f64lt_quiet", lem: "softfloat_f64_lt_quiet"} : (bits_D, bits_D) -> (bits_fflags, bool)
val riscv_f64Le = pure {cpp: "softfloat_f64le", lem: "softfloat_f64_le"} : (bits_D, bits_D) -> (bits_fflags, bool)
val riscv_f64Le_quiet = pure {cpp: "softfloat_f64le_quiet", lem: "softfloat_f64_le_quiet"} : (bits_D, bits_D) -> (bits_fflags, bool)
val riscv_f64Eq = pure {cpp: "softfloat_f64eq", lem: "softfloat_f64_eq"} : (bits_D, bits_D) -> (bits_fflags, bool)

val extern_f128Lt = pure {cpp: "softfloat_f128lt", lem: "softfloat_f128_lt"} : (bits_Q_low, bits_Q_high, bits_Q_low, bits_Q_high) -> (bits_fflags, bool)
function riscv_f128Lt (v1 : bits_Q, v2 : bits_Q) -> (bits_fflags, bool) = {
    return extern_f128Lt(v1[63..0], v1[127..64], v2[63..0], v2[127..64]);
}
val extern_f128Lt_quiet = pure {cpp: "softfloat_f128lt_quiet", lem: "softfloat_f128_lt_quiet"} : (bits_Q_low, bits_Q_high, bits_Q_low, bits_Q_high) -> (bits_fflags, bool)
function riscv_f128Lt_quiet (v1 : bits_Q, v2 : bits_Q) -> (bits_fflags, bool) = {
    return extern_f128Lt_quiet(v1[63..0], v1[127..64], v2[63..0], v2[127..64]);
}
val extern_f128Le = pure {cpp: "softfloat_f128le", lem: "softfloat_f128_le"} : (bits_Q_low, bits_Q_high, bits_Q_low, bits_Q_high) -> (bits_fflags, bool)
function riscv_f128Le (v1 : bits_Q, v2 : bits_Q) -> (bits_fflags, bool) = {
    return extern_f128Le(v1[63..0], v1[127..64], v2[63..0], v2[127..64]);
}
val extern_f128Le_quiet = pure {cpp: "softfloat_f128le_quiet", lem: "softfloat_f128_le_quiet"} : (bits_Q_low, bits_Q_high, bits_Q_low, bits_Q_high) -> (bits_fflags, bool)
function riscv_f128Le_quiet (v1 : bits_Q, v2 : bits_Q) -> (bits_fflags, bool) = {
    return extern_f128Le_quiet(v1[63..0], v1[127..64], v2[63..0], v2[127..64]);
}
val extern_f128Eq = pure {cpp: "softfloat_f128eq", lem: "softfloat_f128_eq"} : (bits_Q_low, bits_Q_high, bits_Q_low, bits_Q_high) -> (bits_fflags, bool)
function riscv_f128Eq (v1 : bits_Q, v2 : bits_Q) -> (bits_fflags, bool) = {
    return extern_f128Eq(v1[63..0], v1[127..64], v2[63..0], v2[127..64]);
}

val riscv_f16roundToInt = pure {cpp: "softfloat_f16roundToInt", lem: "softfloat_f16_round_to_int"} : (bits_rm, bits_H, bool) -> (bits_fflags, bits_H)
val riscv_f32roundToInt = pure {cpp: "softfloat_f32roundToInt", lem: "softfloat_f32_round_to_int"} : (bits_rm, bits_S, bool) -> (bits_fflags, bits_S)
val riscv_f64roundToInt = pure {cpp: "softfloat_f64roundToInt", lem: "softfloat_f64_round_to_int"} : (bits_rm, bits_D, bool) -> (bits_fflags, bits_D)

val extern_f128roundToInt = pure {cpp: "softfloat_f128roundToInt", lem: "softfloat_f128_round_to_int"} : (bits_rm, bits_Q_low, bits_Q_high, bool) -> (bits_fflags, bits_Q_low, bits_Q_high)
function riscv_f128roundToInt (rm : bits_rm, v1 : bits_Q, exact : bool) -> (bits_fflags, bits_Q) = {
    let (fflags, res_low, res_high) = extern_f128roundToInt(rm, v1[63..0], v1[127..64], exact);
    return (fflags, res_high @ res_low);
}
