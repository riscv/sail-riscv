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
  // CSR is read/write/... only
  CSRAccessTypeNotAllowed : unit,

  // CSR is not allowed to access with current privilege
  CSRAccessPrivilegeNotAllowed : unit,

  // CSR required extensions are not enabled
  CSRRequiredExtNotEnabled : unit,

  // CSR required extensions are disabled by config
  CSRRequiredExtNotSupported : unit,

  // CSR is only available in specific XLEN
  CSRNotRequiredXlen : unit,

  // CSR is disabled maybe by some bits
  CSRNotEnabled : string,

  // CSR is not defined in spec or not implemented by sail-model yet
  CSRNotDefined : unit,
}

union CSRAccessResult = {
  CSRAccessSuccess : unit,

  // Accessing the CSR is illegal currently and should raise Illegal_Instruction Exception
  CSRAccessIllegal : CSRAccessIllegalReason,

  // TODO: wait for hypervisor extension
  // Like CSRAccessIllegal, but raise Virtual_Instruction Exception
  // CSRAccessVirtual : ...,
}

// returns whether a CSR exists
val is_CSR_accessible : (csreg, Privilege, CSRAccessType) -> CSRAccessResult
scattered function is_CSR_accessible

function CSRDefinedIf(exist : bool) -> CSRAccessResult = if exist then CSRAccessSuccess() else CSRAccessIllegal(CSRNotDefined())

function CSRRequireExt(ext : extension) -> CSRAccessResult = if currentlyEnabled(ext) then CSRAccessSuccess() else CSRAccessIllegal(CSRRequiredExtNotEnabled())
function CSRRequireHartSupport(ext : extension) -> CSRAccessResult = if hartSupports(ext) then CSRAccessSuccess() else CSRAccessIllegal(CSRRequiredExtNotSupported())
function CSRRequireXlen(len : int) -> CSRAccessResult = if xlen == len then CSRAccessSuccess() else CSRAccessIllegal(CSRNotRequiredXlen())
function CSRRequire(cond : bool, reason : string) -> CSRAccessResult = if cond then CSRAccessSuccess() else CSRAccessIllegal(CSRNotEnabled(reason))
function CSRRequirePrivilege(priv : Privilege, required_priv : Privilege) -> CSRAccessResult = if priv == required_priv then CSRAccessSuccess() else CSRAccessIllegal(CSRAccessPrivilegeNotAllowed())

function CSRAccessResultAnd(r1 : CSRAccessResult, r2 : CSRAccessResult) -> CSRAccessResult = if r1 == CSRAccessSuccess() then r2 else r1
function CSRAccessResultOr(r1 : CSRAccessResult, r2 : CSRAccessResult) -> CSRAccessResult = if r1 == CSRAccessSuccess() & r2 == CSRAccessSuccess() then CSRAccessSuccess() else r1
overload operator & = { CSRAccessResultAnd }
overload operator | = { CSRAccessResultOr }

// returns the value of the CSR if it is defined
val read_CSR : csreg -> xlenbits
scattered function read_CSR

// returns new value (after legalisation) if the CSR is defined,
// otherwise a unit value indicating an illegal instruction.
val write_CSR : (csreg, xlenbits) -> result(xlenbits, unit)
scattered function write_CSR
