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

enum CSRAccessIllegalReason = {
  // CSR is not accessible currently
  CSRNotAccessible,

  // CSR is not defined in spec or not implemented by sail-model yet
  CSRNotDefined,
}


union CSRAccessResult = {
  CSRAccessSuccess : unit,

  // Accessing the CSR is illegal currently and should raise Illegal_Instruction Exception
  //
  // 1. The CSR is explicitly disabled by the json configuration, it can't be
  //    enabled at runtime
  // 2. The CSR is disabled by misa bit, it could be modified at runtime
  // 3. The CSR does not exist in current xlen.
  CSRAccessIllegal : CSRAccessIllegalReason,

  // TODO: wait for hypervisor extension
  // Like CSRAccessIllegal, but raise Virtual_Instruction Exception
  // CSRAccessVirtual : ...,
}

// returns whether a CSR is accessible
val is_CSR_accessible : (csreg, Privilege, CSRAccessType) -> CSRAccessResult
scattered function is_CSR_accessible

function CSRDefinedIf(exist : bool) -> CSRAccessResult =
  if exist then CSRAccessSuccess()
  else CSRAccessIllegal(CSRNotDefined)

function CSRAccessibleIfBool(accessible : bool) -> CSRAccessResult =
  if accessible then CSRAccessSuccess()
  else CSRAccessIllegal(CSRNotAccessible)

function CSRAccessibleIfExtEnabled(ext : extension) -> CSRAccessResult =
  if currentlyEnabled(ext) then CSRAccessSuccess()
  else CSRAccessIllegal(CSRNotAccessible)

function CSRAccessibleIfExtEnabledAndBool(ext : extension, accessible : bool) -> CSRAccessResult =
  if currentlyEnabled(ext) & accessible then CSRAccessSuccess()
  else CSRAccessIllegal(CSRNotAccessible)

overload CSRAccessibleIf = { CSRAccessibleIfBool, CSRAccessibleIfExtEnabled, CSRAccessibleIfExtEnabledAndBool }

// returns the value of the CSR if it is defined
val read_CSR : csreg -> xlenbits
scattered function read_CSR

// returns new value (after legalisation) if the CSR is defined,
// otherwise a unit value indicating an illegal instruction.
val write_CSR : (csreg, xlenbits) -> result(xlenbits, unit)
scattered function write_CSR
