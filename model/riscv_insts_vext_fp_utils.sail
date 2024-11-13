/*=======================================================================================*/
/*  This Sail RISC-V architecture model, comprising all files and                        */
/*  directories except where otherwise noted is subject the BSD                          */
/*  two-clause license in the LICENSE file.                                              */
/*                                                                                       */
/*  SPDX-License-Identifier: BSD-2-Clause                                                */
/*=======================================================================================*/

/* ******************************************************************************* */
/* This file implements functions used by vector instructions.                     */
/* ******************************************************************************* */

/* Check for valid floating-point operation types
 *  1. Valid element width of floating-point numbers
 *  2. Valid floating-point rounding mode
 */
val valid_fp_op : ({8, 16, 32, 64}, bits(3)) -> bool
function valid_fp_op(SEW, rm_3b) = {
  /* 128-bit floating-point values will be supported in future extensions */
  let valid_sew = (SEW >= 16 & SEW <= 128);
  let valid_rm = not(rm_3b == 0b101 | rm_3b == 0b110 | rm_3b == 0b111);
  valid_sew & valid_rm
}

/* a. Normal check for floating-point instructions */
val illegal_fp_normal : (regidx, bits(1), {8, 16, 32, 64}, bits(3)) -> bool
function illegal_fp_normal(vd, vm, SEW, rm_3b) = {
  not(valid_vtype()) | not(valid_rd_mask(vd, vm)) | not(valid_fp_op(SEW, rm_3b))
}

/* b. Masked check for floating-point instructions encoded with vm = 0 */
val illegal_fp_vd_masked : (regidx, {8, 16, 32, 64}, bits(3)) -> bool
function illegal_fp_vd_masked(vd, SEW, rm_3b) = {
  not(valid_vtype()) | vd == 0b00000 | not(valid_fp_op(SEW, rm_3b))
}

/* c. Unmasked check for floating-point instructions encoded with vm = 1 */
val illegal_fp_vd_unmasked : ({8, 16, 32, 64}, bits(3)) -> bool
function illegal_fp_vd_unmasked(SEW, rm_3b) = {
  not(valid_vtype()) | not(valid_fp_op(SEW, rm_3b))
}

/* d. Variable width check for floating-point widening/narrowing instructions */
val illegal_fp_variable_width : (regidx, bits(1), {8, 16, 32, 64}, bits(3), int, int) -> bool
function illegal_fp_variable_width(vd, vm, SEW, rm_3b, SEW_new, LMUL_pow_new) = {
  not(valid_vtype()) | not(valid_rd_mask(vd, vm)) | not(valid_fp_op(SEW, rm_3b)) |
  not(valid_eew_emul(SEW_new, LMUL_pow_new))
}

/* e. Normal check for floating-point reduction instructions */
val illegal_fp_reduction : ({8, 16, 32, 64}, bits(3)) -> bool
function illegal_fp_reduction(SEW, rm_3b) = {
  not(valid_vtype()) | not(assert_vstart(0)) | not(valid_fp_op(SEW, rm_3b))
}

/* f. Variable width check for floating-point widening reduction instructions */
val illegal_fp_reduction_widen : ({8, 16, 32, 64}, bits(3), int, int) -> bool
function illegal_fp_reduction_widen(SEW, rm_3b, SEW_widen, LMUL_pow_widen) = {
  not(valid_vtype()) | not(assert_vstart(0)) | not(valid_fp_op(SEW, rm_3b)) |
  not(valid_eew_emul(SEW_widen, LMUL_pow_widen))
}

/* Floating point classification functions */
val f_is_neg_inf : forall 'm, 'm in {16, 32, 64}. bits('m) -> bool
function f_is_neg_inf(xf) = {
  match 'm {
    16 => f_is_neg_inf_H(xf),
    32 => f_is_neg_inf_S(xf),
    64 => f_is_neg_inf_D(xf)
  }
}

val f_is_neg_norm : forall 'm, 'm in {16, 32, 64}. bits('m) -> bool
function f_is_neg_norm(xf) = {
  match 'm {
    16 => f_is_neg_norm_H(xf),
    32 => f_is_neg_norm_S(xf),
    64 => f_is_neg_norm_D(xf)
  }
}

val f_is_neg_subnorm : forall 'm, 'm in {16, 32, 64}. bits('m) -> bool
function f_is_neg_subnorm(xf) = {
  match 'm {
    16 => f_is_neg_subnorm_H(xf),
    32 => f_is_neg_subnorm_S(xf),
    64 => f_is_neg_subnorm_D(xf)
  }
}

val f_is_neg_zero : forall 'm, 'm in {16, 32, 64}. bits('m) -> bool
function f_is_neg_zero(xf) = {
  match 'm {
    16 => f_is_neg_zero_H(xf),
    32 => f_is_neg_zero_S(xf),
    64 => f_is_neg_zero_D(xf)
  }
}

val f_is_pos_zero : forall 'm, 'm in {16, 32, 64}. bits('m) -> bool
function f_is_pos_zero(xf) = {
  match 'm {
    16 => f_is_pos_zero_H(xf),
    32 => f_is_pos_zero_S(xf),
    64 => f_is_pos_zero_D(xf)
  }
}

val f_is_pos_subnorm : forall 'm, 'm in {16, 32, 64}. bits('m) -> bool
function f_is_pos_subnorm(xf) = {
  match 'm {
    16 => f_is_pos_subnorm_H(xf),
    32 => f_is_pos_subnorm_S(xf),
    64 => f_is_pos_subnorm_D(xf)
  }
}

val f_is_pos_norm : forall 'm, 'm in {16, 32, 64}. bits('m) -> bool
function f_is_pos_norm(xf) = {
  match 'm {
    16 => f_is_pos_norm_H(xf),
    32 => f_is_pos_norm_S(xf),
    64 => f_is_pos_norm_D(xf)
  }
}

val f_is_pos_inf : forall 'm, 'm in {16, 32, 64}. bits('m) -> bool
function f_is_pos_inf(xf) = {
  match 'm {
    16 => f_is_pos_inf_H(xf),
    32 => f_is_pos_inf_S(xf),
    64 => f_is_pos_inf_D(xf)
  }
}

val f_is_SNaN : forall 'm, 'm in {16, 32, 64}. bits('m) -> bool
function f_is_SNaN(xf) = {
  match 'm {
    16 => f_is_SNaN_H(xf),
    32 => f_is_SNaN_S(xf),
    64 => f_is_SNaN_D(xf)
  }
}

val f_is_QNaN : forall 'm, 'm in {16, 32, 64}. bits('m) -> bool
function f_is_QNaN(xf) = {
  match 'm {
    16 => f_is_QNaN_H(xf),
    32 => f_is_QNaN_S(xf),
    64 => f_is_QNaN_D(xf)
  }
}

val f_is_NaN : forall 'm, 'm in {16, 32, 64}. bits('m) -> bool
function f_is_NaN(xf) = {
  match 'm {
    16 => f_is_NaN_H(xf),
    32 => f_is_NaN_S(xf),
    64 => f_is_NaN_D(xf)
  }
}

/* Scalar register shaping for floating point operations */
val get_scalar_fp : forall 'n, 'n in {16, 32, 64}. (regidx, int('n)) -> bits('n)
function get_scalar_fp(rs1, SEW) = {
  assert(flen >= SEW, "invalid vector floating-point type width: FLEN < SEW");
  match SEW {
    16 => F_H(rs1),
    32 => F_S(rs1),
    64 => F_D(rs1)
  }
}

/* Get the floating point rounding mode from csr fcsr */
val get_fp_rounding_mode : unit -> rounding_mode
function get_fp_rounding_mode() = encdec_rounding_mode(fcsr[FRM])

/* Negate a floating point number */
val negate_fp : forall 'm, 'm in {16, 32, 64}. bits('m) -> bits('m)
function negate_fp(xf) = {
  match 'm {
    16 => negate_H(xf),
    32 => negate_S(xf),
    64 => negate_D(xf)
  }
}

/* Floating point functions using softfloat interface */
val fp_add: forall 'm, 'm in {16, 32, 64}. (bits(3), bits('m), bits('m)) -> bits('m)
function fp_add(rm_3b, op1, op2) = {
  let (fflags, result_val) : (bits_fflags, bits('m)) = match 'm {
    16  => riscv_f16Add(rm_3b, op1, op2),
    32  => riscv_f32Add(rm_3b, op1, op2),
    64  => riscv_f64Add(rm_3b, op1, op2)
  };
  accrue_fflags(fflags);
  result_val
}

val fp_sub: forall 'm, 'm in {16, 32, 64}. (bits(3), bits('m), bits('m)) -> bits('m)
function fp_sub(rm_3b, op1, op2) = {
  let (fflags, result_val) : (bits_fflags, bits('m)) = match 'm {
    16  => riscv_f16Sub(rm_3b, op1, op2),
    32  => riscv_f32Sub(rm_3b, op1, op2),
    64  => riscv_f64Sub(rm_3b, op1, op2)
  };
  accrue_fflags(fflags);
  result_val
}

val fp_min : forall 'm, 'm in {16, 32, 64}. (bits('m), bits('m)) -> bits('m)
function fp_min(op1, op2) = {
  let (fflags, op1_lt_op2) : (bits_fflags, bool) = match 'm {
    16  => riscv_f16Lt_quiet(op1, op2),
    32  => riscv_f32Lt_quiet(op1, op2),
    64  => riscv_f64Lt_quiet(op1, op2)
  };

  let result_val = if (f_is_NaN(op1) & f_is_NaN(op2)) then canonical_NaN('m)
                else if f_is_NaN(op1) then op2
                else if f_is_NaN(op2) then op1
                else if (f_is_neg_zero(op1) & f_is_pos_zero(op2)) then op1
                else if (f_is_neg_zero(op2) & f_is_pos_zero(op1)) then op2
                else if op1_lt_op2 then op1
                else op2;
  accrue_fflags(fflags);
  result_val
}

val fp_max : forall 'm, 'm in {16, 32, 64}. (bits('m), bits('m)) -> bits('m)
function fp_max(op1, op2) = {
  let (fflags, op1_lt_op2) : (bits_fflags, bool) = match 'm {
    16  => riscv_f16Lt_quiet(op1, op2),
    32  => riscv_f32Lt_quiet(op1, op2),
    64  => riscv_f64Lt_quiet(op1, op2)
  };

  let result_val = if (f_is_NaN(op1) & f_is_NaN(op2)) then canonical_NaN('m)
                else if f_is_NaN(op1) then op2
                else if f_is_NaN(op2) then op1
                else if (f_is_neg_zero(op1) & f_is_pos_zero(op2)) then op2
                else if (f_is_neg_zero(op2) & f_is_pos_zero(op1)) then op1
                else if op1_lt_op2 then op2
                else op1;
  accrue_fflags(fflags);
  result_val
}

val fp_eq : forall 'm, 'm in {16, 32, 64}. (bits('m), bits('m)) -> bool
function fp_eq(op1, op2) = {
  let (fflags, result_val) : (bits_fflags, bool) = match 'm {
    16  => riscv_f16Eq(op1, op2),
    32  => riscv_f32Eq(op1, op2),
    64  => riscv_f64Eq(op1, op2)
  };
  accrue_fflags(fflags);
  result_val
}

val fp_gt : forall 'm, 'm in {16, 32, 64}. (bits('m), bits('m)) -> bool
function fp_gt(op1, op2) = {
  let (fflags, temp_val) : (bits_fflags, bool) = match 'm {
    16  => riscv_f16Le(op1, op2),
    32  => riscv_f32Le(op1, op2),
    64  => riscv_f64Le(op1, op2)
  };
  let result_val = (if fflags == 0b10000 then false else not(temp_val));
  accrue_fflags(fflags);
  result_val
}

val fp_ge : forall 'm, 'm in {16, 32, 64}. (bits('m), bits('m)) -> bool
function fp_ge(op1, op2) = {
  let (fflags, temp_val) : (bits_fflags, bool) = match 'm {
    16  => riscv_f16Lt(op1, op2),
    32  => riscv_f32Lt(op1, op2),
    64  => riscv_f64Lt(op1, op2)
  };
  let result_val = (if fflags == 0b10000 then false else not(temp_val));
  accrue_fflags(fflags);
  result_val
}

val fp_lt : forall 'm, 'm in {16, 32, 64}. (bits('m), bits('m)) -> bool
function fp_lt(op1, op2) = {
  let (fflags, result_val) : (bits_fflags, bool) = match 'm {
    16  => riscv_f16Lt(op1, op2),
    32  => riscv_f32Lt(op1, op2),
    64  => riscv_f64Lt(op1, op2)
  };
  accrue_fflags(fflags);
  result_val
}

val fp_le : forall 'm, 'm in {16, 32, 64}. (bits('m), bits('m)) -> bool
function fp_le(op1, op2) = {
  let (fflags, result_val) : (bits_fflags, bool) = match 'm {
    16  => riscv_f16Le(op1, op2),
    32  => riscv_f32Le(op1, op2),
    64  => riscv_f64Le(op1, op2)
  };
  accrue_fflags(fflags);
  result_val
}

val fp_mul : forall 'm, 'm in {16, 32, 64}. (bits(3), bits('m), bits('m)) -> bits('m)
function fp_mul(rm_3b, op1, op2) = {
  let (fflags, result_val) : (bits_fflags, bits('m)) = match 'm {
    16  => riscv_f16Mul(rm_3b, op1, op2),
    32  => riscv_f32Mul(rm_3b, op1, op2),
    64  => riscv_f64Mul(rm_3b, op1, op2)
  };
  accrue_fflags(fflags);
  result_val
}

val fp_div : forall 'm, 'm in {16, 32, 64}. (bits(3), bits('m), bits('m)) -> bits('m)
function fp_div(rm_3b, op1, op2) = {
  let (fflags, result_val) : (bits_fflags, bits('m)) = match 'm {
    16  => riscv_f16Div(rm_3b, op1, op2),
    32  => riscv_f32Div(rm_3b, op1, op2),
    64  => riscv_f64Div(rm_3b, op1, op2)
  };
  accrue_fflags(fflags);
  result_val
}

val fp_muladd : forall 'm, 'm in {16, 32, 64}. (bits(3), bits('m), bits('m), bits('m)) -> bits('m)
function fp_muladd(rm_3b, op1, op2, opadd) = {
  let (fflags, result_val) : (bits_fflags, bits('m)) = match 'm {
    16  => riscv_f16MulAdd(rm_3b, op1, op2, opadd),
    32  => riscv_f32MulAdd(rm_3b, op1, op2, opadd),
    64  => riscv_f64MulAdd(rm_3b, op1, op2, opadd)
  };
  accrue_fflags(fflags);
  result_val
}

val fp_nmuladd : forall 'm, 'm in {16, 32, 64}. (bits(3), bits('m), bits('m), bits('m)) -> bits('m)
function fp_nmuladd(rm_3b, op1, op2, opadd) = {
  let op1 = negate_fp(op1);
  let (fflags, result_val) : (bits_fflags, bits('m)) = match 'm {
    16  => riscv_f16MulAdd(rm_3b, op1, op2, opadd),
    32  => riscv_f32MulAdd(rm_3b, op1, op2, opadd),
    64  => riscv_f64MulAdd(rm_3b, op1, op2, opadd)
  };
  accrue_fflags(fflags);
  result_val
}

val fp_mulsub : forall 'm, 'm in {16, 32, 64}. (bits(3), bits('m), bits('m), bits('m)) -> bits('m)
function fp_mulsub(rm_3b, op1, op2, opsub) = {
  let opsub = negate_fp(opsub);
  let (fflags, result_val) : (bits_fflags, bits('m)) = match 'm {
    16  => riscv_f16MulAdd(rm_3b, op1, op2, opsub),
    32  => riscv_f32MulAdd(rm_3b, op1, op2, opsub),
    64  => riscv_f64MulAdd(rm_3b, op1, op2, opsub)
  };
  accrue_fflags(fflags);
  result_val
}

val fp_nmulsub : forall 'm, 'm in {16, 32, 64}. (bits(3), bits('m), bits('m), bits('m)) -> bits('m)
function fp_nmulsub(rm_3b, op1, op2, opsub) = {
  let opsub = negate_fp(opsub);
  let op1 = negate_fp(op1);
  let (fflags, result_val) : (bits_fflags, bits('m)) = match 'm {
    16  => riscv_f16MulAdd(rm_3b, op1, op2, opsub),
    32  => riscv_f32MulAdd(rm_3b, op1, op2, opsub),
    64  => riscv_f64MulAdd(rm_3b, op1, op2, opsub)
  };
  accrue_fflags(fflags);
  result_val
}

val fp_class : forall 'm, 'm in {16, 32, 64}. bits('m) -> bits('m)
function fp_class(xf) = {
  let result_val_10b : bits(10) =
    if      f_is_neg_inf(xf)     then 0b_00_0000_0001
    else if f_is_neg_norm(xf)    then 0b_00_0000_0010
    else if f_is_neg_subnorm(xf) then 0b_00_0000_0100
    else if f_is_neg_zero(xf)    then 0b_00_0000_1000
    else if f_is_pos_zero(xf)    then 0b_00_0001_0000
    else if f_is_pos_subnorm(xf) then 0b_00_0010_0000
    else if f_is_pos_norm(xf)    then 0b_00_0100_0000
    else if f_is_pos_inf(xf)     then 0b_00_1000_0000
    else if f_is_SNaN(xf)        then 0b_01_0000_0000
    else if f_is_QNaN(xf)        then 0b_10_0000_0000
    else zeros();

  zero_extend(result_val_10b)
}

val fp_widen : forall 'm, 'm in {16, 32}. bits('m) -> bits('m * 2)
function fp_widen(nval) = {
  let rm_3b = fcsr[FRM];
  let (fflags, wval) : (bits_fflags, bits('m * 2)) = match 'm {
    16 => riscv_f16ToF32(rm_3b, nval),
    32 => riscv_f32ToF64(rm_3b, nval)
  };
  accrue_fflags(fflags);
  wval
}

/* Floating point functions without softfloat support */
val riscv_f16ToI16 : (bits_rm, bits_H) -> (bits_fflags, bits(16))
function riscv_f16ToI16 (rm, v) = {
  let (_, sig32) = riscv_f16ToI32(rm, v);
  if signed(sig32) > signed(0b0 @ ones(15)) then (nvFlag(), 0b0 @ ones(15))
  else if signed(sig32) < signed(0b1 @ zeros(15)) then (nvFlag(), 0b1 @ zeros(15))
  else (zeros(5), sig32[15 .. 0]);
}

val riscv_f16ToI8 : (bits_rm, bits_H) -> (bits_fflags, bits(8))
function riscv_f16ToI8 (rm, v) = {
  let (_, sig32) = riscv_f16ToI32(rm, v);
  if signed(sig32) > signed(0b0 @ ones(7)) then (nvFlag(), 0b0 @ ones(7))
  else if signed(sig32) < signed(0b1 @ zeros(7)) then (nvFlag(), 0b1 @ zeros(7))
  else (zeros(5), sig32[7 .. 0]);
}

val riscv_f32ToI16 : (bits_rm, bits_S) -> (bits_fflags, bits(16))
function riscv_f32ToI16 (rm, v) = {
  let (_, sig32) = riscv_f32ToI32(rm, v);
  if signed(sig32) > signed(0b0 @ ones(15)) then (nvFlag(), 0b0 @ ones(15))
  else if signed(sig32) < signed(0b1 @ zeros(15)) then (nvFlag(), 0b1 @ zeros(15))
  else (zeros(5), sig32[15 .. 0]);
}

val riscv_f16ToUi16 : (bits_rm, bits_H) -> (bits_fflags, bits(16))
function riscv_f16ToUi16 (rm, v) = {
  let (_, sig32) = riscv_f16ToUi32(rm, v);
  if unsigned(sig32) > unsigned(ones(16)) then (nvFlag(), ones(16))
  else (zeros(5), sig32[15 .. 0]);
}

val riscv_f16ToUi8 : (bits_rm, bits_H) -> (bits_fflags, bits(8))
function riscv_f16ToUi8 (rm, v) = {
  let (_, sig32) = riscv_f16ToUi32(rm, v);
  if unsigned(sig32) > unsigned(ones(8)) then (nvFlag(), ones(8))
  else (zeros(5), sig32[7 .. 0]);
}

val riscv_f32ToUi16 : (bits_rm, bits_S) -> (bits_fflags, bits(16))
function riscv_f32ToUi16 (rm, v) = {
  let (_, sig32) = riscv_f32ToUi32(rm, v);
  if unsigned(sig32) > unsigned(ones(16)) then (nvFlag(), ones(16))
  else (zeros(5), sig32[15 .. 0]);
}

val rsqrt7 : forall 'm, 'm in {16, 32, 64}. (bits('m), bool) -> bits_D
function rsqrt7 (v, sub) = {
  let (sig, exp, sign, e, s) : (bits(64), bits(64), bits(1), nat, nat) = match 'm {
    16 => (zero_extend(64, v[9 .. 0]), zero_extend(64, v[14 .. 10]), [v[15]], 5, 10),
    32 => (zero_extend(64, v[22 .. 0]), zero_extend(64, v[30 .. 23]), [v[31]], 8, 23),
    64 => (zero_extend(64, v[51 .. 0]), zero_extend(64, v[62 .. 52]), [v[63]], 11, 52)
  };
  assert(s == 10 & e == 5 | s == 23 & e == 8 | s == 52 & e == 11);
  let table : vector(128, int) = [
      52, 51, 50, 48, 47, 46, 44, 43,
      42, 41, 40, 39, 38, 36, 35, 34,
      33, 32, 31, 30, 30, 29, 28, 27,
      26, 25, 24, 23, 23, 22, 21, 20,
      19, 19, 18, 17, 16, 16, 15, 14,
      14, 13, 12, 12, 11, 10, 10, 9,
      9, 8, 7, 7, 6, 6, 5, 4,
      4, 3, 3, 2, 2, 1, 1, 0,
      127, 125, 123, 121, 119, 118, 116, 114,
      113, 111, 109, 108, 106, 105, 103, 102,
      100, 99, 97, 96, 95, 93, 92, 91,
      90, 88, 87, 86, 85, 84, 83, 82,
      80, 79, 78, 77, 76, 75, 74, 73,
      72, 71, 70, 70, 69, 68, 67, 66,
      65, 64, 63, 63, 62, 61, 60, 59,
      59, 58, 57, 56, 56, 55, 54, 53];

  let (normalized_exp, normalized_sig) =
      if sub then {
        let nr_leadingzeros = count_leadingzeros(sig, s);
        assert(nr_leadingzeros >= 0);
        (to_bits(64, (0 - nr_leadingzeros)), zero_extend(64, sig[(s - 1) .. 0] << (1 + nr_leadingzeros)))
      } else {
        (exp, sig)
      };

  let idx : nat = match 'm {
    16 => unsigned([normalized_exp[0]] @ normalized_sig[9 .. 4]),
    32 => unsigned([normalized_exp[0]] @ normalized_sig[22 .. 17]),
    64 => unsigned([normalized_exp[0]] @ normalized_sig[51 .. 46])
  };
  assert(idx >= 0 & idx < 128);
  let out_sig = to_bits(s, table[(127 - idx)]) << (s - 7);
  let out_exp = to_bits(e, (3 * (2 ^ (e - 1) - 1) - 1 - signed(normalized_exp)) / 2);
  zero_extend(64, sign @ out_exp @ out_sig)
}

val riscv_f16Rsqrte7 : (bits_rm, bits_H) -> (bits_fflags, bits_H)
function riscv_f16Rsqrte7 (rm, v) = {
  match fp_class(v) {
    0x0001 => (nvFlag(), 0x7e00),
    0x0002 => (nvFlag(), 0x7e00),
    0x0004 => (nvFlag(), 0x7e00),
    0x0100 => (nvFlag(), 0x7e00),
    0x0200 => (zeros(5), 0x7e00),
    0x0008 => (dzFlag(), 0xfc00),
    0x0010 => (dzFlag(), 0x7c00),
    0x0080 => (zeros(5), 0x0000),
    0x0020 => (zeros(5), rsqrt7(v, true)[15 .. 0]),
    _      => (zeros(5), rsqrt7(v, false)[15 .. 0])
  }
}

val riscv_f32Rsqrte7 : (bits_rm, bits_S) -> (bits_fflags, bits_S)
function riscv_f32Rsqrte7 (rm, v) = {
  match fp_class(v)[15 .. 0] {
    0x0001 => (nvFlag(), 0x7fc00000),
    0x0002 => (nvFlag(), 0x7fc00000),
    0x0004 => (nvFlag(), 0x7fc00000),
    0x0100 => (nvFlag(), 0x7fc00000),
    0x0200 => (zeros(5), 0x7fc00000),
    0x0008 => (dzFlag(), 0xff800000),
    0x0010 => (dzFlag(), 0x7f800000),
    0x0080 => (zeros(5), 0x00000000),
    0x0020 => (zeros(5), rsqrt7(v, true)[31 .. 0]),
    _      => (zeros(5), rsqrt7(v, false)[31 .. 0])
  }
}

val riscv_f64Rsqrte7 : (bits_rm, bits_D) -> (bits_fflags, bits_D)
function riscv_f64Rsqrte7 (rm, v) = {
  match fp_class(v)[15 .. 0] {
    0x0001 => (nvFlag(), 0x7ff8000000000000),
    0x0002 => (nvFlag(), 0x7ff8000000000000),
    0x0004 => (nvFlag(), 0x7ff8000000000000),
    0x0100 => (nvFlag(), 0x7ff8000000000000),
    0x0200 => (zeros(5), 0x7ff8000000000000),
    0x0008 => (dzFlag(), 0xfff0000000000000),
    0x0010 => (dzFlag(), 0x7ff0000000000000),
    0x0080 => (zeros(5), zeros(64)),
    0x0020 => (zeros(5), rsqrt7(v, true)[63 .. 0]),
    _      => (zeros(5), rsqrt7(v, false)[63 .. 0])
  }
}

val recip7 : forall 'm, 'm in {16, 32, 64}. (bits('m), bits(3), bool) -> (bool, bits_D)
function recip7 (v, rm_3b, sub) = {
  let (sig, exp, sign, e, s) : (bits(64), bits(64), bits(1), nat, nat) = match 'm {
    16 => (zero_extend(64, v[9 .. 0]), zero_extend(64, v[14 .. 10]), [v[15]], 5, 10),
    32 => (zero_extend(64, v[22 .. 0]), zero_extend(64, v[30 .. 23]), [v[31]], 8, 23),
    64 => (zero_extend(64, v[51 .. 0]), zero_extend(64, v[62 .. 52]), [v[63]], 11, 52)
  };
  assert(s == 10 & e == 5 | s == 23 & e == 8 | s == 52 & e == 11);
  let table : vector(128, int) = [
      127, 125, 123, 121, 119, 117, 116, 114,
      112, 110, 109, 107, 105, 104, 102, 100,
      99, 97, 96, 94, 93, 91, 90, 88,
      87, 85, 84, 83, 81, 80, 79, 77,
      76, 75, 74, 72, 71, 70, 69, 68,
      66, 65, 64, 63, 62, 61, 60, 59,
      58, 57, 56, 55, 54, 53, 52, 51,
      50, 49, 48, 47, 46, 45, 44, 43,
      42, 41, 40, 40, 39, 38, 37, 36,
      35, 35, 34, 33, 32, 31, 31, 30,
      29, 28, 28, 27, 26, 25, 25, 24,
      23, 23, 22, 21, 21, 20, 19, 19,
      18, 17, 17, 16, 15, 15, 14, 14,
      13, 12, 12, 11, 11, 10, 9, 9,
      8, 8, 7, 7, 6, 5, 5, 4,
      4, 3, 3, 2, 2, 1, 1, 0];

  let nr_leadingzeros = count_leadingzeros(sig, s);
  assert(nr_leadingzeros >= 0);
  let (normalized_exp, normalized_sig) =
      if sub then {
        (to_bits(64, (0 - nr_leadingzeros)), zero_extend(64, sig[(s - 1) .. 0] << (1 + nr_leadingzeros)))
      } else {
        (exp, sig)
      };

  let idx : nat = match 'm {
    16 => unsigned(normalized_sig[9 .. 3]),
    32 => unsigned(normalized_sig[22 .. 16]),
    64 => unsigned(normalized_sig[51 .. 45])
  };
  assert(idx >= 0 & idx < 128);
  let mid_exp = to_bits(e, 2 * (2 ^ (e - 1) - 1) - 1 - signed(normalized_exp));
  let mid_sig = to_bits(s, table[(127 - idx)]) << (s - 7);

  let (out_exp, out_sig)=
      if mid_exp == zeros(e) then {
        (mid_exp, mid_sig >> 1 | 0b1 @ zeros(s - 1))
      } else if mid_exp == ones(e) then {
        (zeros(e), mid_sig >> 2 | 0b01 @ zeros(s - 2))
      } else (mid_exp, mid_sig);

  if sub & nr_leadingzeros > 1 then {
      if (rm_3b == 0b001 | rm_3b == 0b010 & sign == 0b0 | rm_3b == 0b011 & sign == 0b1) then {
        (true, zero_extend(64, sign @ ones(e - 1) @ 0b0 @ ones(s)))
      }
      else (true, zero_extend(64, sign @ ones(e) @ zeros(s)))
    } else (false, zero_extend(64, sign @ out_exp @ out_sig))
}

val riscv_f16Recip7 : (bits_rm, bits_H) -> (bits_fflags, bits_H)
function riscv_f16Recip7 (rm, v) = {
  let (round_abnormal_true, res_true) = recip7(v, rm, true);
  let (round_abnormal_false, res_false) = recip7(v, rm, false);
  match fp_class(v) {
    0x0001 => (zeros(5), 0x8000),
    0x0080 => (zeros(5), 0x0000),
    0x0008 => (dzFlag(), 0xfc00),
    0x0010 => (dzFlag(), 0x7c00),
    0x0100 => (nvFlag(), 0x7e00),
    0x0200 => (zeros(5), 0x7e00),
    0x0004 => if round_abnormal_true then (nxFlag() | ofFlag(), res_true[15 .. 0]) else (zeros(5), res_true[15 .. 0]),
    0x0020 => if round_abnormal_true then (nxFlag() | ofFlag(), res_true[15 .. 0]) else (zeros(5), res_true[15 .. 0]),
    _      => if round_abnormal_false then (nxFlag() | ofFlag(), res_false[15 .. 0]) else (zeros(5), res_false[15 .. 0])
  }
}

val riscv_f32Recip7 : (bits_rm, bits_S) -> (bits_fflags, bits_S)
function riscv_f32Recip7 (rm, v) = {
  let (round_abnormal_true, res_true) = recip7(v, rm, true);
  let (round_abnormal_false, res_false) = recip7(v, rm, false);
  match fp_class(v)[15 .. 0] {
    0x0001 => (zeros(5), 0x80000000),
    0x0080 => (zeros(5), 0x00000000),
    0x0008 => (dzFlag(), 0xff800000),
    0x0010 => (dzFlag(), 0x7f800000),
    0x0100 => (nvFlag(), 0x7fc00000),
    0x0200 => (zeros(5), 0x7fc00000),
    0x0004 => if round_abnormal_true then (nxFlag() | ofFlag(), res_true[31 .. 0]) else (zeros(5), res_true[31 .. 0]),
    0x0020 => if round_abnormal_true then (nxFlag() | ofFlag(), res_true[31 .. 0]) else (zeros(5), res_true[31 .. 0]),
    _      => if round_abnormal_false then (nxFlag() | ofFlag(), res_false[31 .. 0]) else (zeros(5), res_false[31 .. 0])
  }
}

val riscv_f64Recip7 : (bits_rm, bits_D) -> (bits_fflags, bits_D)
function riscv_f64Recip7 (rm, v) = {
  let (round_abnormal_true, res_true) = recip7(v, rm, true);
  let (round_abnormal_false, res_false) = recip7(v, rm, false);
  match fp_class(v)[15 .. 0] {
    0x0001 => (zeros(5), 0x8000000000000000),
    0x0080 => (zeros(5), 0x0000000000000000),
    0x0008 => (dzFlag(), 0xfff0000000000000),
    0x0010 => (dzFlag(), 0x7ff0000000000000),
    0x0100 => (nvFlag(), 0x7ff8000000000000),
    0x0200 => (zeros(5), 0x7ff8000000000000),
    0x0004 => if round_abnormal_true then (nxFlag() | ofFlag(), res_true[63 .. 0]) else (zeros(5), res_true[63 .. 0]),
    0x0020 => if round_abnormal_true then (nxFlag() | ofFlag(), res_true[63 .. 0]) else (zeros(5), res_true[63 .. 0]),
    _      => if round_abnormal_false then (nxFlag() | ofFlag(), res_false[63 .. 0]) else (zeros(5), res_false[63 .. 0])
  }
}
