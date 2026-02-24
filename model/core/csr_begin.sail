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

// CSR access control
enum csr_access_failure = { CSR_Access_Illegal, CSR_Access_Virtual }

// CSR access failure code
union csr_access_failure_reason = {
  CSR_Access_Insufficient_Privilege : unit,
  CSR_Access_Failed_Condition : unit,
  CSR_Access_Failed_Stateen : unit,
  CSR_Access_Failed_Default_Check : unit,
  CSR_Access_Illegal_SEED_Privilege : unit,
  CSR_Access_Illegal_SEED_Access : unit,
  CSR_Access_Disabled_Extension : unit,
  CSR_Access_Invalid_Address : unit,
}

// returns the result of a CSR access check
// TODO: change the function name
val is_CSR_accessible : (csreg, Privilege, CSRAccessType) -> result(unit, (csr_access_failure, csr_access_failure_reason))
scattered function is_CSR_accessible

// declaration of functions in `extensions/Stateen/stateen_access_checks.sail`.
val stateen_allows_CSR_access : (csreg, Privilege, CSRAccessType) -> bool
scattered function stateen_allows_CSR_access

// returns the value of the CSR if it is defined
val read_CSR : csreg -> xlenbits
scattered function read_CSR

// returns new value (after legalisation) if the CSR is defined,
// otherwise a unit value indicating an illegal instruction.
val write_CSR : (csreg, xlenbits) -> result(xlenbits, unit)
scattered function write_CSR
