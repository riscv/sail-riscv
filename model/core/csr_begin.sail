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

union CSRAccessIllegalReason = {
  // Attempt to perform an unsupported operation (e.g., write to a read-only CSR)
  CSR_Illegal_AccessType : unit,

  // Current privilege level is lower than the CSR's minimum required privilege
  CSR_Illegal_Privilege : unit,

  // Extension is not enabled
  CSR_Illegal_ExtDisabled : unit,

  // CSR is not accessible in the current XLEN mode (e.g., RV32-only CSR in RV64)
  CSR_Illegal_XlenMismatch : unit,

  // Other complex constraints not covered above, describe the specific reason using a string
  CSR_Illegal_Condition : string,

  // CSR is not defined in spec or not implemented by sail-model yet
  CSR_Illegal_NotDefined : unit,
}

union CSRAccessResult = {
  CSRAccess_Success : unit,

  // Accessing the CSR is illegal currently and should raise Illegal_Instruction Exception
  CSRAccess_Illegal : CSRAccessIllegalReason,

  // TODO: wait for hypervisor extension
  // Like CSRAccess_Illegal, but raise Virtual_Instruction Exception
  // CSRAccess_Virtual : ...,
}

// returns whether a CSR exists
val is_CSR_accessible : (csreg, Privilege, CSRAccessType) -> CSRAccessResult
scattered function is_CSR_accessible

function csr_defined_if(exist : bool) -> CSRAccessResult = if exist then CSRAccess_Success() else CSRAccess_Illegal(CSR_Illegal_NotDefined())

function csr_require_ext(ext : extension) -> CSRAccessResult = if currentlyEnabled(ext) then CSRAccess_Success() else CSRAccess_Illegal(CSR_Illegal_ExtDisabled())
function csr_require_xlen(len : int) -> CSRAccessResult = if xlen == len then CSRAccess_Success() else CSRAccess_Illegal(CSR_Illegal_XlenMismatch())
function csr_require_cond(cond : bool, reason : string) -> CSRAccessResult = if cond then CSRAccess_Success() else CSRAccess_Illegal(CSR_Illegal_Condition(reason))

function csr_access_result_and(r1 : CSRAccessResult, r2 : CSRAccessResult) -> CSRAccessResult =
  if      r1 != CSRAccess_Success() then r1
  else if r2 != CSRAccess_Success() then r2
  else    CSRAccess_Success()

overload operator & = { csr_access_result_and }

// returns the value of the CSR if it is defined
val read_CSR : csreg -> xlenbits
scattered function read_CSR

// returns new value (after legalisation) if the CSR is defined,
// otherwise a unit value indicating an illegal instruction.
val write_CSR : (csreg, xlenbits) -> result(xlenbits, unit)
scattered function write_CSR
