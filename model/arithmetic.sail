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
