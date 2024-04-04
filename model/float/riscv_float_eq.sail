/*=======================================================================================*/
/*  This Sail RISC-V architecture model, comprising all files and                        */
/*  directories except where otherwise noted is subject the BSD                          */
/*  two-clause license in the LICENSE file.                                              */
/*                                                                                       */
/*  SPDX-License-Identifier: BSD-2-Clause                                                */
/*=======================================================================================*/

/* **************************************************************** */
/* This file implements the floating-point for equal. The below     */
/* floating-point types are supported.                              */
/*                                                                  */
/* 1. Double-precision, aka 64 bits floating-point.                 */
/* 2. Single-precision, aka 32 bits floating-point.                 */
/* 3. Half-precision, aka 16 bits floating-point.                   */
/* **************************************************************** */

val f_is_NaN      : forall 'm, 'm in {16, 32, 64}. bits('m) -> bool
val f_is_SNaN     : forall 'm, 'm in {16, 32, 64}. bits('m) -> bool
val accrue_fflags : (bits_fflags) -> unit

val      float_eq : forall 'm, 'm in {16, 32, 64}. (bits('m), bits('m)) -> (bits_fflags, bool)
function float_eq (op1, op2) = {
  let is_nan    = f_is_NaN(op1) | f_is_NaN(op2);
  let is_snan   = f_is_SNaN(op1) | f_is_SNaN(op2);
  let fflags    = if   is_snan
                  then float_flag_invalid
                  else zeros();
  let is_equal  = not(is_nan) & (op1 == op2) | ((op1 | op2) << 1) == zeros();

  (fflags, is_equal)
}

val      float_raise_flags_eq : forall 'm, 'm in {16, 32, 64}. (bits('m), bits('m)) -> bool
function float_raise_flags_eq (op1, op2) = {
  let (fflags, is_equal) = float_eq(op1, op2);

  accrue_fflags(fflags);

  is_equal
}
