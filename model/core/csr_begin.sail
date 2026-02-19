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
  CSR_Illegal_AccessType : CSRAccessType,

  // Current privilege level is lower than the CSR's minimum required privilege
  CSR_Illegal_Privilege : Privilege,

  // Extension is not enabled
  CSR_Illegal_ExtDisabled : extension,

  // CSR is not accessible in the current XLEN mode (e.g., RV32-only CSR in RV64)
  CSR_Illegal_XlenMismatch : unit,

  // Counter CSR bit not enabled
  CSR_Illegal_Counter : (range(0, 31), Privilege),

  // Attempted read without a write raises an illegal-instruction exception
  // regardless of mode and access control bits
  CSR_Illegal_SeedReadWithoutWrite : unit,
  // Attempted access seed csr, but mseccfg[XSEED] is not enabled
  CSR_Illegal_XSEEDNotEnabled : Privilege,

  // Used for one or more specific CSRS that are inaccessible due to complex conditions
  // (e.g., OR, or privilege mixed bit checks).
  CSR_Illegal_FCSR    : unit,
  CSR_Illegal_Mseccfg : unit,
  CSR_Illegal_Satp    : unit,
  CSR_Illegal_Stateen : unit,
  CSR_Illegal_Sstc    : unit,

  // CSR is not defined in spec or not implemented by sail-model yet
  CSR_Illegal_NotDefined : unit,
}

union CSRAccessResult = {
  CSRAccess_Success : unit,

  // Accessing the CSR is illegal currently and should raise Illegal_Instruction Exception
  CSRAccess_Illegal : CSRAccessIllegalReason,

  // Like CSRAccess_Illegal, but raise Virtual_Instruction Exception
  CSRAccess_Virtual : unit,
}

// returns whether a CSR exists
val is_CSR_accessible : (csreg, Privilege, CSRAccessType) -> CSRAccessResult
scattered function is_CSR_accessible

function csr_defined_if(exist : bool) -> CSRAccessResult =
  if   exist
  then CSRAccess_Success()
  else CSRAccess_Illegal(CSR_Illegal_NotDefined())

// CSR require ext is enabled.
function csr_requires_ext(ext : extension) -> CSRAccessResult =
  if   currentlyEnabled(ext)
  then CSRAccess_Success()
  else CSRAccess_Illegal(CSR_Illegal_ExtDisabled(ext))

function csr_requires_xlen_32() -> CSRAccessResult =
  if   xlen == 32
  then CSRAccess_Success()
  else CSRAccess_Illegal(CSR_Illegal_XlenMismatch())

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
