// =======================================================================================
// This Sail RISC-V architecture model, comprising all files and
// directories except where otherwise noted is subject the BSD
// two-clause license in the LICENSE file.
//
// SPDX-License-Identifier: BSD-2-Clause
// =======================================================================================

// Classify floating point numbers into one of these classes. All floating point
// numbers must be in exactly one class.
//
// These must be exactly in the order used by the RISC-V encoding.
// See the "Format of result of FCLASS instruction" table in the ISA manual.
enum floating_point_class = {
  fp_neg_inf,
  fp_neg_norm,
  fp_neg_subnorm,
  fp_neg_zero,
  fp_pos_zero,
  fp_pos_subnorm,
  fp_pos_norm,
  fp_pos_inf,
  fp_snan,
  fp_qnan,
}

// Convert the floating point class to the RISC-V one-hot encoding. This
// relies on the order of the enum entries being correct.
function float_point_class_bits(class : floating_point_class) -> bits(10) =
  zero_extend(0b1 @ zeros(num_of_floating_point_class(class)))

// Classify a floating point number into exactly one of the possible classes.
val float_classify : forall 'n, 'n in { 16, 32, 64, 128 } . bits('n) -> floating_point_class
function float_classify(f) =
  if      float_is_snan(f)     then fp_snan
  else if float_is_qnan(f)     then fp_qnan
  else if float_is_zero(f)     then (if float_is_positive(f) then fp_pos_zero    else fp_neg_zero)
  else if float_is_denormal(f) then (if float_is_positive(f) then fp_pos_subnorm else fp_neg_subnorm)
  else if float_is_normal(f)   then (if float_is_positive(f) then fp_pos_norm    else fp_neg_norm)
  else if float_is_inf(f)      then (if float_is_positive(f) then fp_pos_inf     else fp_neg_inf)
  else internal_error(__FILE__, __LINE__, "float_classify internal logic error")

// Helper function for proofs.
function bool_int(b : bool) -> {0, 1} = if b then 1 else 0

// Prove that the float is in one broad class.
$[property]
function float_in_one_broad_class(f : bits(16)) -> bool =
  bool_int(float_is_snan(f)) +
  bool_int(float_is_qnan(f)) +
  bool_int(float_is_zero(f)) +
  bool_int(float_is_denormal(f)) +
  bool_int(float_is_normal(f)) +
  bool_int(float_is_inf(f)) == 1

// Prove that all floats must be positive or negative.
// This includes NaNs.
$[property]
function float_pos_neg_or_nan(f : bits(16)) -> bool =
  float_is_positive(f) != float_is_negative(f)

// Another overall class proof. A bit redundant but can't hurt.
$[property]
function float_in_one_class(f : bits(16)) -> bool =
  bool_int(float_is_negative(f) & float_is_inf(f)) +
  bool_int(float_is_negative(f) & float_is_normal(f)) +
  bool_int(float_is_negative(f) & float_is_denormal(f)) +
  bool_int(float_is_negative(f) & float_is_zero(f)) +
  bool_int(float_is_positive(f) & float_is_zero(f)) +
  bool_int(float_is_positive(f) & float_is_denormal(f)) +
  bool_int(float_is_positive(f) & float_is_normal(f)) +
  bool_int(float_is_positive(f) & float_is_inf(f)) +
  bool_int(float_is_snan(f)) +
  bool_int(float_is_qnan(f)) == 1
