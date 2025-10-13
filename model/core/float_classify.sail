// =======================================================================================
// This Sail RISC-V architecture model, comprising all files and
// directories except where otherwise noted is subject the BSD
// two-clause license in the LICENSE file.
//
// SPDX-License-Identifier: BSD-2-Clause
// =======================================================================================

// Convert the floating point class to the RISC-V one-hot encoding.
mapping float_class_onehot_bits : float_class <-> bits(10) = {
  float_class_negative_inf       <-> 0b0000000001,
  float_class_negative_normal    <-> 0b0000000010,
  float_class_negative_subnormal <-> 0b0000000100,
  float_class_negative_zero      <-> 0b0000001000,
  float_class_positive_zero      <-> 0b0000010000,
  float_class_positive_subnormal <-> 0b0000100000,
  float_class_positive_normal    <-> 0b0001000000,
  float_class_positive_inf       <-> 0b0010000000,
  float_class_snan               <-> 0b0100000000,
  float_class_qnan               <-> 0b1000000000,
}

// Helper function for proofs.
function bool_int(b : bool) -> {0, 1} = if b then 1 else 0

// Prove that the float is in one broad class.
$[property]
function float_in_one_broad_class(f : bits(16)) -> bool =
  bool_int(float_is_snan(f)) +
  bool_int(float_is_qnan(f)) +
  bool_int(float_is_zero(f)) +
  bool_int(float_is_subnormal(f)) +
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
  bool_int(float_is_negative(f) & float_is_subnormal(f)) +
  bool_int(float_is_negative(f) & float_is_zero(f)) +
  bool_int(float_is_positive(f) & float_is_zero(f)) +
  bool_int(float_is_positive(f) & float_is_subnormal(f)) +
  bool_int(float_is_positive(f) & float_is_normal(f)) +
  bool_int(float_is_positive(f) & float_is_inf(f)) +
  bool_int(float_is_snan(f)) +
  bool_int(float_is_qnan(f)) == 1
