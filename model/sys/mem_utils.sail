// =======================================================================================
// This Sail RISC-V architecture model, comprising all files and
// directories except where otherwise noted is subject the BSD
// two-clause license in the LICENSE file.
//
// SPDX-License-Identifier: BSD-2-Clause
// =======================================================================================

// Check if an 'n byte access for an address is within an aligned 2^'r byte region
private val access_within : forall 'width 'n ('r : Nat), 'r <= 'width & 1 <= 'n <= 2^'r.
  (bits('width), int('n), int('r)) -> bool
function access_within(addr, bytes, region_width_exp) = {
  let mask : bits('width) = ~(zero_extend(ones(region_width_exp)));
  (addr & mask) == ((addr + (bytes - 1)) & mask)
}

// This property demonstrates that when bytes == 2^region_width_exp, the access_within check above is
// equivalent to a regular alignment check (for a constrained set of inputs to help the SMT solver).
$[property]
private function prop_access_within_is_aligned(addr : bits(32), region_width_exp : bits(4)) -> bool = {
  let region_width_exp = unsigned(region_width_exp);
  let bytes = 2 ^ region_width_exp;
  access_within(addr, bytes, region_width_exp) == (unsigned(addr) % bytes == 0)
}

// A 1-byte access is always within a 2^0 = 1-byte region.
$[property]
private function prop_access_within_single(addr : bits(32)) -> bool = {
  access_within(addr, 1, 0)
}

private val allowed_misaligned : forall 'width, 0 < 'width <= max_mem_access. (xlenbits, int('width), range(0, 12)) -> bool
function allowed_misaligned(addr, width, region_width_exp) = {
  let region_width = 2 ^ region_width_exp;

  if width > region_width then return false;

  access_within(addr, width, region_width_exp)
}
