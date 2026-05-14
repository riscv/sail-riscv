// =======================================================================================
// This Sail RISC-V architecture model, comprising all files and
// directories except where otherwise noted is subject the BSD
// two-clause license in the LICENSE file.
//
// SPDX-License-Identifier: BSD-2-Clause
// =======================================================================================

function fsplit_BF16 (v : bits(16)) -> (bits(1), bits(8), bits(7)) = (v[15..15], v[14..7], v[6..0])

function fmake_BF16 (sign : bits(1), exp : bits(8), mant : bits(7)) -> (bits(16)) = (sign @ exp @ mant)

function bf16_classify(v : bits_BF16) -> float_class = {
  let (sign, exp, mant) = fsplit_BF16(v);
  match (exp, mant == zeros(), sign, mant[6]) {
    (0b11111111, true, 0b1, _)  => float_class_negative_inf,
    (0b11111111, true, 0b0, _)  => float_class_positive_inf,
    (0b11111111, false, _, 0b0) => float_class_snan,
    (0b11111111, false, _, 0b1) => float_class_qnan,
    (0b00000000, true, 0b1, _)  => float_class_negative_zero,
    (0b00000000, true, 0b0, _)  => float_class_positive_zero,
    (0b00000000, false, 0b1, _) => float_class_negative_subnormal,
    (0b00000000, false, 0b0, _) => float_class_positive_subnormal,
    (_, _, 0b1, _)              => float_class_negative_normal,
    (_, _, 0b0, _)              => float_class_positive_normal,
  }
}

function bf16_to_f32 (v : bits(16)) -> (bits_fflags, bits(32)) = {
  let (sign, exp, mant) = fsplit_BF16(v);
  let is_nan = exp == ones() & mant != zeros();
  let is_inf = exp == ones() & mant == zeros();

  let fflags = if is_nan & signed(mant) >= 0 then nvFlag() else zeros();
  let value =
    if is_nan then canonical_NaN_S()
    else if is_inf then fmake_S(sign, ones(), zeros())
    else fmake_S(sign, exp, mant @ zeros(16));

  (fflags, value)
}

function bf16_to_f32_set_flags(nval : bits(16)) -> bits(32) = {
  let (fflags, wval) = bf16_to_f32(nval);
  accrue_fflags(fflags);
  wval
}

function get_scalar_BF16(rs1 : fregidx) -> bits_BF16 =
  F_BF16(rs1)

function negate_BF16(xf16 : bits_BF16) -> bits_BF16 = {
  let (sign, exp, mant) = fsplit_BF16(xf16);
  let new_sign = if sign == 0b0 then 0b1 else 0b0;
  fmake_BF16(new_sign, exp, mant)
}

function bf16_add(rm_3b : bits_rm, op1 : bits_BF16, op2 : bits_BF16) -> bits_BF16 = {
  let (fflags, result_val) = riscv_bf16Add(rm_3b, op1, op2);
  accrue_fflags(fflags);
  result_val
}

function bf16_sub(rm_3b : bits_rm, op1 : bits_BF16, op2 : bits_BF16) -> bits_BF16 = {
  let (fflags, result_val) = riscv_bf16Sub(rm_3b, op1, op2);
  accrue_fflags(fflags);
  result_val
}

function bf16_mul(rm_3b : bits_rm, op1 : bits_BF16, op2 : bits_BF16) -> bits_BF16 = {
  let (fflags, result_val) = riscv_bf16Mul(rm_3b, op1, op2);
  accrue_fflags(fflags);
  result_val
}

// not used by Zvfbfa; retained only as a generic emulator helper
function bf16_div(rm_3b : bits_rm, op1 : bits_BF16, op2 : bits_BF16) -> bits_BF16 = {
  let (fflags, result_val) = riscv_bf16Div(rm_3b, op1, op2);
  accrue_fflags(fflags);
  result_val
}

function bf16_muladd(rm_3b : bits_rm, op1 : bits_BF16, op2 : bits_BF16, opadd : bits_BF16) -> bits_BF16 = {
  let (fflags, result_val) = riscv_bf16MulAdd(rm_3b, op1, op2, opadd);
  accrue_fflags(fflags);
  result_val
}

function bf16_nmuladd(rm_3b : bits_rm, op1 : bits_BF16, op2 : bits_BF16, opadd : bits_BF16) -> bits_BF16 =
  bf16_muladd(rm_3b, negate_BF16(op1), op2, opadd)

function bf16_mulsub(rm_3b : bits_rm, op1 : bits_BF16, op2 : bits_BF16, opsub : bits_BF16) -> bits_BF16 =
  bf16_muladd(rm_3b, op1, op2, negate_BF16(opsub))

function bf16_nmulsub(rm_3b : bits_rm, op1 : bits_BF16, op2 : bits_BF16, opsub : bits_BF16) -> bits_BF16 =
  bf16_muladd(rm_3b, negate_BF16(op1), op2, negate_BF16(opsub))

function bf16_min(op1 : bits_BF16, op2 : bits_BF16) -> bits_BF16 = {
  let op1_f32 = bf16_to_f32_set_flags(op1);
  let op2_f32 = bf16_to_f32_set_flags(op2);
  let (fflags, op1_lt_op2) = riscv_f32Lt_quiet(op1_f32, op2_f32);
  let result_val =
    if f_is_NaN_S(op1_f32) & f_is_NaN_S(op2_f32) then canonical_NaN_BF16
    else if f_is_NaN_S(op1_f32) then op2
    else if f_is_NaN_S(op2_f32) then op1
    else if f_is_neg_zero_S(op1_f32) & f_is_pos_zero_S(op2_f32) then op1
    else if f_is_neg_zero_S(op2_f32) & f_is_pos_zero_S(op1_f32) then op2
    else if op1_lt_op2 then op1
    else op2;
  accrue_fflags(fflags);
  result_val
}

function bf16_max(op1 : bits_BF16, op2 : bits_BF16) -> bits_BF16 = {
  let op1_f32 = bf16_to_f32_set_flags(op1);
  let op2_f32 = bf16_to_f32_set_flags(op2);
  let (fflags, op1_lt_op2) = riscv_f32Lt_quiet(op1_f32, op2_f32);
  let result_val =
    if f_is_NaN_S(op1_f32) & f_is_NaN_S(op2_f32) then canonical_NaN_BF16
    else if f_is_NaN_S(op1_f32) then op2
    else if f_is_NaN_S(op2_f32) then op1
    else if f_is_neg_zero_S(op1_f32) & f_is_pos_zero_S(op2_f32) then op2
    else if f_is_neg_zero_S(op2_f32) & f_is_pos_zero_S(op1_f32) then op1
    else if op1_lt_op2 then op2
    else op1;
  accrue_fflags(fflags);
  result_val
}
