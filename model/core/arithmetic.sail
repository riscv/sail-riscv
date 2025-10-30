// =======================================================================================
// This Sail RISC-V architecture model, comprising all files and
// directories except where otherwise noted is subject the BSD
// two-clause license in the LICENSE file.
//
// SPDX-License-Identifier: BSD-2-Clause
// =======================================================================================

// Reverse bits in each byte
val brev8 : forall 'm, 'm >= 0 & mod('m, 8) == 0. (bits('m)) -> bits('m)
function brev8(input) = {
  var output : bits('m) = zeros();
  foreach (i from 0 to ('m - 8) by 8)
    output[i+7..i] = reverse_bits(input[i+7..i]);
  output
}

// Carry-less multiply.
val carryless_mul : forall 'n, 'n > 0. (bits('n), bits('n)) -> bits(2 * 'n)
function carryless_mul(a, b) = {
  var result : bits(2 * 'n) = zeros();
  foreach (i from 0 to ('n - 1)) {
    if   a[i] == bitone
    then result = result ^ (zero_extend(b) << i);
  };
  result
}

// Reverse carry-less multiply.
val carryless_mulr : forall 'n, 'n > 0. (bits('n), bits('n)) -> bits('n)
function carryless_mulr(a, b) = {
  var result : bits('n) = zeros();
  foreach (i from 0 to ('n - 1)) {
    if   a[i] == bitone
    then result = result ^ (b >> ('n - i - 1));
  };
  result
}

// Equivalent reverse carry-less multiply.
val carryless_mul_reversed : forall 'n, 'n > 0. (bits('n), bits('n)) -> bits('n)
function carryless_mul_reversed(a, b) = {
  let prod = carryless_mul(reverse_bits(a), reverse_bits(b));
  reverse_bits(prod['n - 1 .. 0])
}

val mult_to_bits_half : forall 'l, 'l > 0 . (implicit('l), Signedness, Signedness, bits('l), bits('l), VectorHalf) -> bits('l)
function mult_to_bits_half(l, sign1, sign2, rs1_bits, rs2_bits, result_part) = {
  let rs1_int : int = match sign1 {
    Signed   => signed(rs1_bits),
    Unsigned => unsigned(rs1_bits),
  };
  let rs2_int : int = match sign2 {
    Signed   => signed(rs2_bits),
    Unsigned => unsigned(rs2_bits),
  };

  let result_wide = to_bits_truncate(2 * l, rs1_int * rs2_int);
  match result_part {
    High => result_wide[(2 * l - 1) .. l],
    Low  => result_wide[(l - 1) .. 0],
  }
}

$[property]
function cmulr_equivalence(a : bits(16), b : bits(16)) -> bool = {
  carryless_mul_reversed(a, b) == carryless_mulr(a, b)
}

val rev8 : forall 'm, 'm >= 0 & mod('m, 8) == 0. (bits('m)) -> bits('m)
function rev8(input) = {
  var output : bits('m) = zeros();
  foreach (i from 0 to ('m - 8) by 8) {
    output[(i + 7)..i] = input[('m - i - 1) .. ('m - i - 8)];
  };
  output
}

val count_ones : forall 'n, 'n >= 0. (bits('n)) -> range(0, 'n)
function count_ones(x) = {
  var count : range(0, 'n) = 0;
  foreach (i from 0 to ('n - 1)) {
    if x[i] == bitone then {
      let new_count = count + 1;
      assert(new_count <= 'n);
      count = new_count;
    }
  };
  count
}
