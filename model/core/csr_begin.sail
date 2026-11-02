// =======================================================================================
// This Sail RISC-V architecture model, comprising all files and
// directories except where otherwise noted is subject the BSD
// two-clause license in the LICENSE file.
//
// SPDX-License-Identifier: BSD-2-Clause
// =======================================================================================

// Mapping of csr addresses to their names.

val csr_name_map : csreg <-> string

scattered mapping csr_name_map

function csr_name(csr : csreg) -> string = csr_name_map(csr)
overload to_str = {csr_name}

// returns whether a CSR exists
val is_CSR_accessible : (csreg, Privilege, CSRAccessType) -> bool
scattered function is_CSR_accessible

// returns the value of the CSR if it is defined
val read_CSR : csreg -> xlenbits
scattered function read_CSR

// returns new value (after legalisation) if the CSR is defined,
// otherwise a unit value indicating an illegal instruction.
val write_CSR : (csreg, xlenbits) -> result(xlenbits, unit)
scattered function write_CSR

// returns whether a virtual instruction exception has occurred
val is_CSR_exception_virtual : (csreg, Privilege, CSRAccessType) -> bool
scattered function is_CSR_exception_virtual

// The following definitions enable CSR access for the S{m,s}csrind extensions.

// True when *select maps to a register reachable via the corresponding *ireg*.
// in the address space given by IregType.
val indirect_reg_implemented : (IregType, xlenbits, range(1, 6)) -> bool
scattered function indirect_reg_implemented

// Read/write access to the register determined by the value of
// *select in the address space given by IregType.

val get_ireg : (IregType, xlenbits, range(1, 6)) -> xlenbits
scattered function get_ireg

// set_ireg returns Err(()) for an illegal access.
val set_ireg : (IregType, xlenbits, range(1, 6), xlenbits) -> result(xlenbits, unit)
scattered function set_ireg
