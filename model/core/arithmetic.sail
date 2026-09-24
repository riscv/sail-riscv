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
    if   a[i] == 0b1
    then result = result ^ (zero_extend(b) << i);
  };
  result
}

// Reverse carry-less multiply.
val carryless_mulr : forall 'n, 'n > 0. (bits('n), bits('n)) -> bits('n)
function carryless_mulr(a, b) = {
  var result : bits('n) = zeros();
  foreach (i from 0 to ('n - 1)) {
    if   a[i] == 0b1
    then result = result ^ (b >> ('n - i - 1));
  };
  result
}

// Equivalent reverse carry-less multiply.
private val carryless_mul_reversed : forall 'n, 'n > 0. (bits('n), bits('n)) -> bits('n)
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
    if x[i] == 0b1 then {
      let new_count = count + 1;
      assert(new_count <= 'n);
      count = new_count;
    }
  };
  count
}

val lowest_index_of : forall 'n, 'n >= 0. (bits('n), bits(1)) -> option(range(0, 'n - 1))
function lowest_index_of(x, b) = {
  foreach (i from 0 to ('n - 1)) {
    if x[i] == b then return Some(i);
  };
  None()
}

$[test]
private function test_lowest_index_of() -> unit = {
  assert(lowest_index_of(0x0, 0b1) == None());
  assert(lowest_index_of(0x0, 0b0) == Some(0));
  assert(lowest_index_of(0x1, 0b0) == Some(1));
  assert(lowest_index_of(0x8, 0b0) == Some(0));
  assert(lowest_index_of(0xe, 0b0) == Some(0));
  assert(lowest_index_of(0x7, 0b0) == Some(3));
}

val highest_index_of : forall 'n, 'n >= 0. (bits('n), bits(1)) -> option(range(0, 'n - 1))
function highest_index_of(x, b) = {
  foreach (i from ('n - 1) downto 0) {
    if x[i] == b then return Some(i);
  };
  None()
}

$[test]
private function test_highest_index_of() -> unit = {
  assert(highest_index_of(0x0, 0b1) == None());
  assert(highest_index_of(0x0, 0b0) == Some(3));
  assert(highest_index_of(0x1, 0b0) == Some(3));
  assert(highest_index_of(0x8, 0b0) == Some(2));
  assert(highest_index_of(0xe, 0b0) == Some(0));
  assert(highest_index_of(0x7, 0b0) == Some(3));
}

val least_significant_zero : forall 'n, 'n >= 0. (bits('n)) -> option(range(0, 'n - 1))
function least_significant_zero(x) =
  lowest_index_of(x, 0b0)

val least_significant_one : forall 'n, 'n >= 0. (bits('n)) -> option(range(0, 'n - 1))
function least_significant_one(x) =
  lowest_index_of(x, 0b1)

val most_significant_zero : forall 'n, 'n >= 0. (bits('n)) -> option(range(0, 'n - 1))
function most_significant_zero(x) =
  highest_index_of(x, 0b0)

val most_significant_one : forall 'n, 'n >= 0. (bits('n)) -> option(range(0, 'n - 1))
function most_significant_one(x) =
  highest_index_of(x, 0b1)
