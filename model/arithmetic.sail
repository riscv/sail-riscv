/*=======================================================================================*/
/*  This Sail RISC-V architecture model, comprising all files and                        */
/*  directories except where otherwise noted is subject the BSD                          */
/*  two-clause license in the LICENSE file.                                              */
/*                                                                                       */
/*  SPDX-License-Identifier: BSD-2-Clause                                                */
/*=======================================================================================*/

/* Carry-less multiply. */
val carryless_mul : forall 'n, 'n > 0. (bits('n), bits('n)) -> bits(2 * 'n)
function carryless_mul(a, b) = {
  var result : bits(2 * 'n) = zeros();
  foreach (i from 0 to ('n - 1)) {
    if   a[i] == bitone
    then result = result ^ (zero_extend(b) << i);
  };
  result
}

/* Reverse carry-less multiply. */
val carryless_mulr : forall 'n, 'n > 0. (bits('n), bits('n)) -> bits('n)
function carryless_mulr(a, b) = {
  var result : bits('n) = zeros();
  foreach (i from 0 to ('n - 1)) {
    if   a[i] == bitone
    then result = result ^ (b >> ('n - i - 1));
  };
  result
}

/* Equivalent reverse carry-less multiply. */
val carryless_mul_reversed : forall 'n, 'n > 0. (bits('n), bits('n)) -> bits('n)
function carryless_mul_reversed(a, b) = {
  let prod = carryless_mul(reverse_bits(a), reverse_bits(b));
  reverse_bits(prod['n - 1 .. 0])
}

$[property]
function cmulr_equivalence(a : bits(16), b : bits(16)) -> bool = {
  carryless_mul_reversed(a, b) == carryless_mulr(a, b)
}
