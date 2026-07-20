// =======================================================================================
// This Sail RISC-V architecture model, comprising all files and
// directories except where otherwise noted is subject the BSD
// two-clause license in the LICENSE file.
//
// SPDX-License-Identifier: BSD-2-Clause
// =======================================================================================

// These two definitions refer to the architectural physical address.
type physaddrbits = bits(physaddrbits_len)
let physaddrbits_len = sizeof(physaddrbits_len)

// Note: `virtaddr` includes physical addresses when address translation is disabled.
// It is used where the address would be virtual if address translation is active.
newtype physaddr = Physaddr : physaddrbits
newtype virtaddr = Virtaddr : xlenbits

function bits_of_physaddr(Physaddr(paddr) : physaddr) -> physaddrbits = paddr

function bits_of_virtaddr(Virtaddr(vaddr) : virtaddr) -> xlenbits = vaddr

function sub_virtaddr_xlenbits(Virtaddr(addr) : virtaddr, offset : xlenbits) -> virtaddr = Virtaddr(addr - offset)

overload operator - = { sub_virtaddr_xlenbits }

overload bits_of = { bits_of_physaddr, bits_of_virtaddr }

// This refers to the size of an _implemented_ physical address, which
// may be smaller than the architectural physical address.
type physaddr_bits : Int = config memory.physaddr_bits
// The lower bound of 13 is required to prevent empty bitvectors during address translation.
constraint 13 <= physaddr_bits & physaddr_bits <= (if xlen == 32 then 34 else 64)
let physaddr_bits = sizeof(physaddr_bits)
