// =======================================================================================
// This Sail RISC-V architecture model, comprising all files and
// directories except where otherwise noted is subject the BSD
// two-clause license in the LICENSE file.
//
// SPDX-License-Identifier: BSD-2-Clause
// =======================================================================================

// This file implements utilities for access splitting for misaligned accesses.

// Helpers to check address alignment.
//
//   is_aligned_addr - checks for alignment of a physical or virtual address

function is_aligned_paddr(Physaddr(addr) : physaddr, width : nat1) -> bool =
  unsigned(addr) % width == 0

function is_aligned_vaddr(Virtaddr(addr) : virtaddr, width : nat1) -> bool =
  unsigned(addr) % width == 0

overload is_aligned_addr = {is_aligned_paddr, is_aligned_vaddr}

// The misaligned atomicity granule size is restricted by the page size.
type mag_size_exp = range(0, pagesize_bits)

// This is an external option used for misaligned scalar or vector
// load/store accesses to physical memory regions that do not specify
// a MAG PMA or accesses to which the MAG PMA does not apply, and the
// regions do not raise exceptions for misaligned accesses.
//
// It specifies an integer N, such that when N is greater than zero,
// accesses (as atomic events) are allowed provided the access occurs
// within a naturally aligned 2^N byte region. If the access spans
// more than one of these regions it will be split into multiple
// memory operations.  For the current implementation this region must
// not be more than the page size (i.e. 2^12 = 4096 bytes).

let sys_misaligned_allowed_within_exp : mag_size_exp = config memory.misaligned.allowed_within_exp

// This is a external option that controls the order in which the model
// performs misaligned accesses.
let sys_misaligned_order_decreasing : bool = config memory.misaligned.order_decreasing

// This is an external option that, when true, causes misaligned load/store accesses
// to be split into single byte operations.  Otherwise, such misaligned accesses
// are split into multiple accesses of smaller widths such that each of the latter
// accesses is aligned.
let sys_misaligned_byte_by_byte : bool = config memory.misaligned.byte_by_byte

enum Splittability = {CanSplit, CannotSplit}

private val split_misaligned : forall 'width, 0 < 'width <= max_mem_access.
  (physaddr, int('width), range(0, 12), Splittability) -> {'n 'bytes, 'width == 'n * 'bytes & 'bytes > 0. (int('n), int('bytes))}

function split_misaligned(Physaddr(addr), width, allowed_within_exp, splittable) = {
  let do_not_split = splittable == CannotSplit |
     (unsigned(addr) % width == 0) |
     allowed_misaligned(addr[xlen -1 .. 0], width, allowed_within_exp);

  if do_not_split then (1, width)
  else if sys_misaligned_byte_by_byte then (width, 1)
  else {
    let bytes_per_access = 2 ^ count_trailing_zeros(addr);
    let num_accesses = width / bytes_per_access;
    assert(width == num_accesses * bytes_per_access);
    (num_accesses, bytes_per_access)
  }
}

type valid_misaligned_order('n, 'first, 'last, 'step) -> Bool =
    ('first == 0 & 'last == 'n - 1 & 'step == 1)
  | ('first == 'n - 1 & 'last == 0 & 'step == -1)

private val misaligned_order : forall 'n.
  int('n) -> {'first 'last 'step, valid_misaligned_order('n, 'first, 'last, 'step). (int('first), int('last), int('step))}

function misaligned_order(n) = {
  if sys_misaligned_order_decreasing then {
    (n - 1, 0, -1)
  } else {
    (0, n - 1, 1)
  }
}

val split_on_page_boundary : forall 'n 'width, 13 <= 'n <= 64 & is_mem_width('width).
  (bits('n), int('width)) -> {'p 'q, 0 < 'p <= 'width & 'width == 'p + 'q. (int('p), int('q))}

function split_on_page_boundary(addr, width) = {
  let page_mask = [(ones() : bits('n)) with (pagesize_bits - 1) .. 0 = zeros()];
  let intra_page_access = (addr & page_mask) == ((addr + width - 1) & page_mask);
  if intra_page_access then (width, 0)
  else {
    let nbytes_to_boundary = sizeof(max_mem_width) - unsigned(addr[sizeof(max_mem_width_bits) - 1 .. 0]);
    assert(nbytes_to_boundary < width);
    (nbytes_to_boundary, width - nbytes_to_boundary)
  }
}

$[property]
private val access_in_same_page : forall 'width, is_mem_width('width). (bits(16), int('width)) -> bool
function access_in_same_page(addr, width) = {
  let (p, q) = split_on_page_boundary(addr, width);
  let page_mask : bits(16) = 0xF000;
  (q == 0 ==> (addr & page_mask) == ((addr + width - 1) & page_mask))
  & ((addr & page_mask) == ((addr + width - 1) & page_mask) ==> q == 0)
}

$[property]
private val access_across_page_boundary : forall 'width, is_mem_width('width). (bits(16), int('width)) -> bool
function access_across_page_boundary(addr, width) = {
  let (p, q) = split_on_page_boundary(addr, width);
  let page_mask : bits(16) = 0xF000;
  (q != 0 ==> (addr & page_mask) != ((addr + width - 1) & page_mask))
  & ((addr & page_mask) != ((addr + width - 1) & page_mask) ==> q != 0)
}
