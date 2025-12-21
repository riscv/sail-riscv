// =======================================================================================
// This Sail RISC-V architecture model, comprising all files and
// directories except where otherwise noted is subject the BSD
// two-clause license in the LICENSE file.
//
// SPDX-License-Identifier: BSD-2-Clause
// =======================================================================================

// Return true if the right-open range `a` is a subset of `b` (or equal to it).
// Ranges wrap around the end. The 64 bit limit is just so Sail generates more
// efficient C code.
function range_subset forall 'n, 0 <= 'n <= 64 . (
  a_begin : bits('n),
  a_size  : bits('n),
  b_begin : bits('n),
  b_size  : bits('n),
) -> bool = {
  // Rotate so that be starts at 0.
  let a_end = (a_begin + a_size) - b_begin;
  let b_end = (b_begin + b_size) - b_begin;
  let a_begin = a_begin - b_begin;
  a_begin <=_u b_end & a_end <=_u b_end & a_begin <=_u a_end
}

$[test]
private function test_range_subset() -> unit = {
  assert(range_subset(0x0, 0x0, 0x0, 0x0));
  assert(range_subset(0x1, 0x0, 0x1, 0x0));
  assert(range_subset(0x0, 0x0, 0x0, 0x1));
  assert(range_subset(0x1, 0x0, 0x0, 0x1));
  assert(range_subset(0x8, 0xc, 0x8, 0xc));
  assert(not(range_subset(0x8, 0xc, 0x9, 0xc)));
  assert(not(range_subset(0x8, 0xc, 0x8, 0xb)));
  assert(not(range_subset(0x3e, 0xe0, 0xc1, 0x9f)));
  assert(not(range_subset(0xc1, 0x9f, 0x3e, 0xe0)));
}

// Check if two ranges are subsets of each other they must be equal.
$[property]
private function range_subset_equals(a_begin : bits(8), a_size : bits(8), b_begin : bits(8), b_size : bits(8)) -> bool =
  range_subset(a_begin, a_size, b_begin, b_size) & range_subset(b_begin, b_size, a_begin, a_size)
    ==> (a_begin == b_begin & a_size == b_size)

// Check that if A is a subset of B, then all indices in A must be in B.
// Also check that an index exists that is in A but not B then A cannot be a subset of B.
$[property]
private function range_subset_precise(a_begin : bits(8), a_size : bits(8), b_begin : bits(8), b_size : bits(8), index : bits(8)) -> bool = {
  let index_in_a = (index - a_begin) <_u a_size;
  let index_in_b = (index - b_begin) <_u b_size;
  let is_subset = range_subset(a_begin, a_size, b_begin, b_size);

  (is_subset & index_in_a ==> index_in_b) & ((index_in_a & not(index_in_b)) ==> not(is_subset))
}
