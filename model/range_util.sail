/*=======================================================================================*/
/*  This Sail RISC-V architecture model, comprising all files and                        */
/*  directories except where otherwise noted is subject the BSD                          */
/*  two-clause license in the LICENSE file.                                              */
/*                                                                                       */
/*  SPDX-License-Identifier: BSD-2-Clause                                                */
/*=======================================================================================*/

// Return true if the right-open range `a` is a subset of `b` (or equal to it).
// Ranges wrap around the end. The 64 bit limit is just so Sail generates more
// efficient C code.
function range_subset forall 'n, 0 <= 'n <= 64 . (
  a_begin : bits('n),
  a_end   : bits('n),
  b_begin : bits('n),
  b_end   : bits('n),
) -> bool = {
  let b_end = b_end - b_begin;
  let a_begin = a_begin - b_begin;
  let a_end = a_end - b_begin;
  a_begin <=_u b_end & a_end <=_u b_end
}

$[test]
function test_range_subset() -> unit = {
    assert(range_subset(0x0, 0x0, 0x0, 0x0));
    assert(range_subset(0x1, 0x1, 0x1, 0x1));
    assert(range_subset(0x0, 0x0, 0x0, 0x1));
    assert(range_subset(0x1, 0x1, 0x0, 0x1));
    assert(range_subset(0x8, 0x4, 0x8, 0x4));
    assert(not(range_subset(0x8, 0x4, 0x9, 0x4)));
    assert(not(range_subset(0x8, 0x4, 0x8, 0x3)));
}
