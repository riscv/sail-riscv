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

/* **************************************************************** */
/* ADD/SUB/MUL/DIV                                                  */

val      external_f32Add : (bits_rm, bits_S, bits_S) -> (bits_fflags, bits_S)
function external_f32Add (rm, v1, v2) = (0b_00000, 0x_0000_0000)

val      external_f32Sub : (bits_rm, bits_S, bits_S) -> (bits_fflags, bits_S)
function external_f32Sub (rm, v1, v2) = (0b_00000, 0x_0000_0000)

val      external_f32Mul : (bits_rm, bits_S, bits_S) -> (bits_fflags, bits_S)
function external_f32Mul (rm, v1, v2) = (0b_00000, 0x_0000_0000)

val      external_f32Div : (bits_rm, bits_S, bits_S) -> (bits_fflags, bits_S)
function external_f32Div (rm, v1, v2) = (0b_00000, 0x_0000_0000)

val      external_f64Add : (bits_rm, bits_D, bits_D) -> (bits_fflags, bits_D)
function external_f64Add (rm, v1, v2) = (0b_00000, 0x_0000_0000_0000_0000)

val      external_f64Sub : (bits_rm, bits_D, bits_D) -> (bits_fflags, bits_D)
function external_f64Sub (rm, v1, v2) = (0b_00000, 0x_0000_0000_0000_0000)

val      external_f64Mul : (bits_rm, bits_D, bits_D) -> (bits_fflags, bits_D)
function external_f64Mul (rm, v1, v2) = (0b_00000, 0x_0000_0000_0000_0000)

val      external_f64Div : (bits_rm, bits_D, bits_D) -> (bits_fflags, bits_D)
function external_f64Div (rm, v1, v2) = (0b_00000, 0x_0000_0000_0000_0000)

/* **************************************************************** */
/* MULTIPLY-ADD                                                     */

val      external_f32MulAdd : (bits_rm, bits_S, bits_S, bits_S) -> (bits_fflags, bits_S)
function external_f32MulAdd (rm, v1, v2, v3) = (0b_00000, 0x_0000_0000)

val      external_f64MulAdd : (bits_rm, bits_D, bits_D, bits_D) -> (bits_fflags, bits_D)
function external_f64MulAdd (rm, v1, v2, v3) = (0b_00000, 0x_0000_0000_0000_0000)

/* **************************************************************** */
/* SQUARE ROOT                                                      */

val      external_f32Sqrt : (bits_rm, bits_S) -> (bits_fflags, bits_S)
function external_f32Sqrt (rm, v) = (0b_00000, 0x_0000_0000)

val      external_f64Sqrt : (bits_rm, bits_D) -> (bits_fflags, bits_D)
function external_f64Sqrt (rm, v) = (0b_00000, 0x_0000_0000_0000_0000)

/* **************************************************************** */
/* CONVERSIONS                                                      */

val      external_f32ToI32 : (bits_rm, bits_S) -> (bits_fflags, bits_W)
function external_f32ToI32 (rm, v) = (0b_00000, 0x_0000_0000)

val      external_f32ToUi32 : (bits_rm, bits_S) -> (bits_fflags, bits_WU)
function external_f32ToUi32 (rm, v) = (0b_00000, 0x_0000_0000)

val      external_i32ToF32 : (bits_rm, bits_W) -> (bits_fflags, bits_S)
function external_i32ToF32 (rm, v) = (0b_00000, 0x_0000_0000)

val      external_ui32ToF32 : (bits_rm, bits_WU) -> (bits_fflags, bits_S)
function external_ui32ToF32 (rm, v) = (0b_00000, 0x_0000_0000)

val      external_f32ToI64 : (bits_rm, bits_S) -> (bits_fflags, bits_L)
function external_f32ToI64 (rm, v) = (0b_00000, 0x_0000_0000_0000_0000)

val      external_f32ToUi64 : (bits_rm, bits_S) -> (bits_fflags, bits_LU)
function external_f32ToUi64 (rm, v) = (0b_00000, 0x_0000_0000_0000_0000)

val      external_i64ToF32 : (bits_rm, bits_L) -> (bits_fflags, bits_S)
function external_i64ToF32 (rm, v) = (0b_00000, 0x_0000_0000)

val      external_ui64ToF32 : (bits_rm, bits_LU) -> (bits_fflags, bits_S)
function external_ui64ToF32 (rm, v) = (0b_00000, 0x_0000_0000)

val      external_f64ToI32 : (bits_rm, bits_D) -> (bits_fflags, bits_W)
function external_f64ToI32 (rm, v) = (0b_00000, 0x_0000_0000)

val      external_f64ToUi32 : (bits_rm, bits_D) -> (bits_fflags, bits_WU)
function external_f64ToUi32 (rm, v) = (0b_00000, 0x_0000_0000)

val      external_i32ToF64 : (bits_rm, bits_W) -> (bits_fflags, bits_D)
function external_i32ToF64 (rm, v) = (0b_00000, 0x_0000_0000_0000_0000)

val      external_ui32ToF64 : (bits_rm, bits_WU) -> (bits_fflags, bits_D)
function external_ui32ToF64 (rm, v) = (0b_00000, 0x_0000_0000_0000_0000)

val      external_f64ToI64 : (bits_rm, bits_D) -> (bits_fflags, bits_L)
function external_f64ToI64 (rm, v) = (0b_00000, 0x_0000_0000_0000_0000)

val      external_f64ToUi64 : (bits_rm, bits_D) -> (bits_fflags, bits_LU)
function external_f64ToUi64 (rm, v) = (0b_00000, 0x_0000_0000_0000_0000)

val      external_i64ToF64 : (bits_rm, bits_L) -> (bits_fflags, bits_D)
function external_i64ToF64 (rm, v) = (0b_00000, 0x_0000_0000_0000_0000)

val      external_ui64ToF64 : (bits_rm, bits_LU) -> (bits_fflags, bits_D)
function external_ui64ToF64 (rm, v) = (0b_00000, 0x_0000_0000_0000_0000)

/* **************************************************************** */
