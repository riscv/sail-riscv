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

// This is a external option that controls the order in which the model
// performs misaligned accesses.
let sys_misaligned_order_decreasing : bool = config memory.misaligned.order_decreasing

// This is an external option that, when true, causes misaligned load/store accesses
// to be split into single byte operations.  Otherwise, such misaligned accesses
// are split into multiple accesses of smaller widths such that each of the latter
// accesses is aligned.
let sys_misaligned_byte_by_byte : bool = config memory.misaligned.byte_by_byte

// This is an external option that returns an integer N, such that
// when N is greater than zero, misaligned load/store accesses to physical memory
// (as atomic events) are allowed provided the access occurs within a
// naturally aligned 2^N byte region. If the access spans more than one of these
// regions it will be split into multiple memory operations.
// For the current implementation this region must not be more than the page
// size (i.e. 2^12 = 4096 bytes) so that accesses that span discontiguously
// mapped pages work correctly.
//
// This is an over-constraint: it isn't necessary when virtual memory isn't
// enabled, or for contiguously mapped pages, and in fact a memory operation
// itself can be discontiguous, so even an access spanning discontiguously
// mapped pages could still result in one memory operation.
// However limiting this to 2^12 is an easy way to ensure that accesses
// spanning pages always work.
let sys_misaligned_allowed_within_exp : range(0, 12) = config memory.misaligned.allowed_within_exp

private val split_misaligned : forall 'width, is_mem_width('width).
  (virtaddr, int('width)) -> {'n 'bytes, 'width == 'n * 'bytes & 'bytes > 0. (int('n), int('bytes))}

function split_misaligned(vaddr, width) = {
  let vaddr_bits = bits_of(vaddr);
  if is_aligned_addr(vaddr, width) | allowed_misaligned(vaddr_bits, width, sys_misaligned_allowed_within_exp) then (1, width)
  else if sys_misaligned_byte_by_byte then (width, 1)
  else {
    let bytes_per_access = 2 ^ count_trailing_zeros(vaddr_bits);
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
