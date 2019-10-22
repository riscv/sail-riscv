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

/* **************************************************************** */
/* ADD/SUB/MUL/DIV                                                  */

/* ---- cf. SoftFloat.hs:f32Add() */
val      external_fadd_S : (bits_rm, bits_S, bits_S) -> (bits_fflags, bits_S)
function external_fadd_S (rm, v1, v2) = (0b_00000, 0x_0000_0000)

/* ---- cf. SoftFloat.hs:f32Sub() */
val      external_fsub_S : (bits_rm, bits_S, bits_S) -> (bits_fflags, bits_S)
function external_fsub_S (rm, v1, v2) = (0b_00000, 0x_0000_0000)

/* ---- cf. SoftFloat.hs:f32Mul() */
val      external_fmul_S : (bits_rm, bits_S, bits_S) -> (bits_fflags, bits_S)
function external_fmul_S (rm, v1, v2) = (0b_00000, 0x_0000_0000)

/* ---- cf. SoftFloat.hs:f32Div() */
val      external_fdiv_S : (bits_rm, bits_S, bits_S) -> (bits_fflags, bits_S)
function external_fdiv_S (rm, v1, v2) = (0b_00000, 0x_0000_0000)

/* ---- cf. SoftFloat.hs:f64Add() */
val      external_fadd_D : (bits_rm, bits_D, bits_D) -> (bits_fflags, bits_D)
function external_fadd_D (rm, v1, v2) = (0b_00000, 0x_0000_0000_0000_0000)

/* ---- cf. SoftFloat.hs:f64Sub() */
val      external_fsub_D : (bits_rm, bits_D, bits_D) -> (bits_fflags, bits_D)
function external_fsub_D (rm, v1, v2) = (0b_00000, 0x_0000_0000_0000_0000)

/* ---- cf. SoftFloat.hs:f64Mul() */
val      external_fmul_D : (bits_rm, bits_D, bits_D) -> (bits_fflags, bits_D)
function external_fmul_D (rm, v1, v2) = (0b_00000, 0x_0000_0000_0000_0000)

/* ---- cf. SoftFloat.hs:f64Div() */
val      external_fdiv_D : (bits_rm, bits_D, bits_D) -> (bits_fflags, bits_D)
function external_fdiv_D (rm, v1, v2) = (0b_00000, 0x_0000_0000_0000_0000)

/* **************************************************************** */
/* MULTIPLY-ADD                                                     */

/* ---- cf. SoftFloat.hs:f64MulAdd() */
val      external_fmuladd_S : (bits_rm, bits_S, bits_S, bits_S) -> (bits_fflags, bits_S)
function external_fmuladd_S (rm, v1, v2, v3) = (0b_00000, 0x_0000_0000)

/* ---- cf. SoftFloat.hs:f64MulAdd() */
val      external_fmuladd_D : (bits_rm, bits_D, bits_D, bits_D) -> (bits_fflags, bits_D)
function external_fmuladd_D (rm, v1, v2, v3) = (0b_00000, 0x_0000_0000_0000_0000)

/* **************************************************************** */
