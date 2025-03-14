/*=======================================================================================*/
/*  This Sail RISC-V architecture model, comprising all files and                        */
/*  directories except where otherwise noted is subject the BSD                          */
/*  two-clause license in the LICENSE file.                                              */
/*                                                                                       */
/*  SPDX-License-Identifier: BSD-2-Clause                                                */
/*=======================================================================================*/

/* Note: virtaddr includes physical addresses when address translation is disabled.
 * It is used where the address would be virtual if address translation is active.
 */
type physaddrbits = bits(physaddrbits_len)

let physaddrbits_len = sizeof(physaddrbits_len)

newtype physaddr = physaddr : physaddrbits
newtype virtaddr = virtaddr : xlenbits

function physaddr_bits(physaddr(paddr) : physaddr) -> physaddrbits = paddr

function virtaddr_bits(virtaddr(vaddr) : virtaddr) -> xlenbits = vaddr

function sub_virtaddr_xlenbits(virtaddr(addr) : virtaddr, offset : xlenbits) -> virtaddr = virtaddr(addr - offset)

overload operator - = { sub_virtaddr_xlenbits }
