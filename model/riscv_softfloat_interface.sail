/* **************************************************************** */
/* This file lists all the external Berkeley softfloat functions    */
/* invoked from the SAIL spec for RISC-V F and D extensions         */
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
type bits_S      = bits(32)   /* Single-precision float value */
type bits_D      = bits(64)   /* Double-precision float value */

type bits_W      = bits(32)   /* Signed integer */
type bits_WU     = bits(32)   /* Unsigned integer */

type bits_L      = bits(64)   /* Signed integer */
type bits_LU     = bits(64)   /* Unsigned integer */

/* ***************************************************************** */
/* Internal registers to pass results across the softfloat interface
 * to avoid return types involving structures.
 */
register float_result : bits(64)
register float_fflags : bits(64)

/* **************************************************************** */
/* ADD/SUB/MUL/DIV                                                  */

val     extern_f32Add = {c: "softfloat_f32add"} : (bits_rm, bits_S, bits_S) -> unit
val      riscv_f32Add : (bits_rm, bits_S, bits_S) -> (bits_fflags, bits_S) effect {rreg}
function riscv_f32Add (rm, v1, v2) = {
  extern_f32Add(rm, v1, v2);
  (float_fflags[4 .. 0], float_result[31 .. 0])
}

val     extern_f32Sub = {c: "softfloat_f32sub"} : (bits_rm, bits_S, bits_S) -> unit
val      riscv_f32Sub : (bits_rm, bits_S, bits_S) -> (bits_fflags, bits_S) effect {rreg}
function riscv_f32Sub (rm, v1, v2) = {
  extern_f32Sub(rm, v1, v2);
  (float_fflags[4 .. 0], float_result[31 .. 0])
}

val     extern_f32Mul = {c: "softfloat_f32mul"} : (bits_rm, bits_S, bits_S) -> unit
val      riscv_f32Mul : (bits_rm, bits_S, bits_S) -> (bits_fflags, bits_S) effect {rreg}
function riscv_f32Mul (rm, v1, v2) = {
  extern_f32Mul(rm, v1, v2);
  (float_fflags[4 .. 0], float_result[31 .. 0])
}

val     extern_f32Div = {c: "softfloat_f32div"} : (bits_rm, bits_S, bits_S) -> unit
val      riscv_f32Div : (bits_rm, bits_S, bits_S) -> (bits_fflags, bits_S) effect {rreg}
function riscv_f32Div (rm, v1, v2) = {
  extern_f32Div(rm, v1, v2);
  (float_fflags[4 .. 0], float_result[31 .. 0])
}

val     extern_f64Add = {c: "softfloat_f64add"} : (bits_rm, bits_D, bits_D) -> unit
val      riscv_f64Add : (bits_rm, bits_D, bits_D) -> (bits_fflags, bits_D) effect {rreg}
function riscv_f64Add (rm, v1, v2) = {
  extern_f64Add(rm, v1, v2);
  (float_fflags[4 .. 0], float_result)
}

val     extern_f64Sub = {c: "softfloat_f64sub"} : (bits_rm, bits_D, bits_D) -> unit
val      riscv_f64Sub : (bits_rm, bits_D, bits_D) -> (bits_fflags, bits_D) effect {rreg}
function riscv_f64Sub (rm, v1, v2) = {
  extern_f64Sub(rm, v1, v2);
  (float_fflags[4 .. 0], float_result)
}

val     extern_f64Mul = {c: "softfloat_f64mul"} : (bits_rm, bits_D, bits_D) -> unit
val      riscv_f64Mul : (bits_rm, bits_D, bits_D) -> (bits_fflags, bits_D) effect {rreg}
function riscv_f64Mul (rm, v1, v2) = {
  extern_f64Mul(rm, v1, v2);
  (float_fflags[4 .. 0], float_result)
}

val     extern_f64Div = {c: "softfloat_f64div"} : (bits_rm, bits_D, bits_D) -> unit
val      riscv_f64Div : (bits_rm, bits_D, bits_D) -> (bits_fflags, bits_D) effect {rreg}
function riscv_f64Div (rm, v1, v2) = {
  extern_f64Div(rm, v1, v2);
  (float_fflags[4 .. 0], float_result)
}

/* **************************************************************** */
/* MULTIPLY-ADD                                                     */

val     extern_f32MulAdd = {c: "softfloat_f32muladd"} : (bits_rm, bits_S, bits_S, bits_S) -> unit
val      riscv_f32MulAdd : (bits_rm, bits_S, bits_S, bits_S) -> (bits_fflags, bits_S) effect {rreg}
function riscv_f32MulAdd (rm, v1, v2, v3) = {
  extern_f32MulAdd(rm, v1, v2, v3);
  (float_fflags[4 .. 0], float_result[31 .. 0])
}

val     extern_f64MulAdd = {c: "softfloat_f64muladd"} : (bits_rm, bits_D, bits_D, bits_D) -> unit
val      riscv_f64MulAdd : (bits_rm, bits_D, bits_D, bits_D) -> (bits_fflags, bits_D) effect {rreg}
function riscv_f64MulAdd (rm, v1, v2, v3) = {
  extern_f64MulAdd(rm, v1, v2, v3);
  (float_fflags[4 .. 0], float_result)
}

/* **************************************************************** */
/* SQUARE ROOT                                                      */

val     extern_f32Sqrt = {c: "softfloat_f32sqrt"} : (bits_rm, bits_S) -> unit
val      riscv_f32Sqrt : (bits_rm, bits_S) -> (bits_fflags, bits_S) effect {rreg}
function riscv_f32Sqrt (rm, v) = {
  extern_f32Sqrt(rm, v);
  (float_fflags[4 .. 0], float_result[31 .. 0])
}

val     extern_f64Sqrt = {c: "softfloat_f64sqrt"} : (bits_rm, bits_D) -> unit
val      riscv_f64Sqrt : (bits_rm, bits_D) -> (bits_fflags, bits_D) effect {rreg}
function riscv_f64Sqrt (rm, v) = {
  extern_f64Sqrt(rm, v);
  (float_fflags[4 .. 0], float_result)
}

/* **************************************************************** */
/* CONVERSIONS                                                      */

val      riscv_f32ToI32 : (bits_rm, bits_S) -> (bits_fflags, bits_W)
function riscv_f32ToI32 (rm, v) = (0b_00000, 0x_0000_0000)

val      riscv_f32ToUi32 : (bits_rm, bits_S) -> (bits_fflags, bits_WU)
function riscv_f32ToUi32 (rm, v) = (0b_00000, 0x_0000_0000)

val      riscv_i32ToF32 : (bits_rm, bits_W) -> (bits_fflags, bits_S)
function riscv_i32ToF32 (rm, v) = (0b_00000, 0x_0000_0000)

val      riscv_ui32ToF32 : (bits_rm, bits_WU) -> (bits_fflags, bits_S)
function riscv_ui32ToF32 (rm, v) = (0b_00000, 0x_0000_0000)

val      riscv_f32ToI64 : (bits_rm, bits_S) -> (bits_fflags, bits_L)
function riscv_f32ToI64 (rm, v) = (0b_00000, 0x_0000_0000_0000_0000)

val      riscv_f32ToUi64 : (bits_rm, bits_S) -> (bits_fflags, bits_LU)
function riscv_f32ToUi64 (rm, v) = (0b_00000, 0x_0000_0000_0000_0000)

val      riscv_i64ToF32 : (bits_rm, bits_L) -> (bits_fflags, bits_S)
function riscv_i64ToF32 (rm, v) = (0b_00000, 0x_0000_0000)

val      riscv_ui64ToF32 : (bits_rm, bits_LU) -> (bits_fflags, bits_S)
function riscv_ui64ToF32 (rm, v) = (0b_00000, 0x_0000_0000)

val      riscv_f64ToI32 : (bits_rm, bits_D) -> (bits_fflags, bits_W)
function riscv_f64ToI32 (rm, v) = (0b_00000, 0x_0000_0000)

val      riscv_f64ToUi32 : (bits_rm, bits_D) -> (bits_fflags, bits_WU)
function riscv_f64ToUi32 (rm, v) = (0b_00000, 0x_0000_0000)

val      riscv_i32ToF64 : (bits_rm, bits_W) -> (bits_fflags, bits_D)
function riscv_i32ToF64 (rm, v) = (0b_00000, 0x_0000_0000_0000_0000)

val      riscv_ui32ToF64 : (bits_rm, bits_WU) -> (bits_fflags, bits_D)
function riscv_ui32ToF64 (rm, v) = (0b_00000, 0x_0000_0000_0000_0000)

val      riscv_f64ToI64 : (bits_rm, bits_D) -> (bits_fflags, bits_L)
function riscv_f64ToI64 (rm, v) = (0b_00000, 0x_0000_0000_0000_0000)

val      riscv_f64ToUi64 : (bits_rm, bits_D) -> (bits_fflags, bits_LU)
function riscv_f64ToUi64 (rm, v) = (0b_00000, 0x_0000_0000_0000_0000)

val      riscv_i64ToF64 : (bits_rm, bits_L) -> (bits_fflags, bits_D)
function riscv_i64ToF64 (rm, v) = (0b_00000, 0x_0000_0000_0000_0000)

val      riscv_ui64ToF64 : (bits_rm, bits_LU) -> (bits_fflags, bits_D)
function riscv_ui64ToF64 (rm, v) = (0b_00000, 0x_0000_0000_0000_0000)

/* **************************************************************** */
