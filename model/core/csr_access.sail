// =======================================================================================
// This Sail RISC-V architecture model, comprising all files and
// directories except where otherwise noted is subject the BSD
// two-clause license in the LICENSE file.
//
// SPDX-License-Identifier: BSD-2-Clause
// =======================================================================================

// When hypervisor is enabled, `Supervisor` (HS-mode) and
// `VirtualSupervisor` (VS-mode) privileges are encoded as `0b01` in
// `privLevel_bits()`, but the CSR addresses for hypervisor and VS
// CSRs encode the required privilege as `0b10`.  This overrides
// the encoding in `privLevel_bits()` for the purposes of CSR privilege
// checks.
private function privLevel_to_CSR_privbits(p : Privilege) -> nom_priv_bits =
  match p {
    User              => 0b00,
    VirtualUser       => 0b00,
    // Note that this `if` is not strictly necessary. We could return
    // 0b10 unconditionally if other checks ensure that hypervisor
    // CSRs do not exist if H is not enabled.
    Supervisor        => if currentlyEnabled(Ext_H) then 0b10 else 0b01,
    VirtualSupervisor => 0b01,
    Machine           => 0b11,
  }

function csrAccess(csr : csreg) -> csrRW = csr[11..10]
function csrPriv(csr : csreg) -> nom_priv_bits = csr[9..8]

// Check that the CSR access is made with sufficient privilege.
function check_CSR_priv(csr : csreg, p : Privilege) -> bool =
  privLevel_to_CSR_privbits(p) >=_u csrPriv(csr)

// Check that the CSR access isn't a write to a read-only CSR.
function check_CSR_access_type(csr : csreg, access_type : CSRAccessType) -> bool =
  not((access_type == CSRWrite | access_type == CSRReadWrite) & (csrAccess(csr) == 0b11))

// Combine the two checks into a default access check.
function default_CSR_access_allowed(csr : csreg, p : Privilege, access_type : CSRAccessType) -> bool =
  check_CSR_priv(csr, p) & check_CSR_access_type(csr, access_type)

// This is the default CSR access checker which implements HS-qualified checks
// by default.  It cannot be used for CSRs that do not use HS-qualification.
function check_CSR_access(csr : csreg, p : Privilege, access_type : CSRAccessType, condition : bool) -> result(unit, (csr_access_failure, csr_access_failure_reason)) = {
  if not(condition) then return Err((CSR_Access_Illegal, CSR_Access_Failed_Condition()));

  // Stateen defaults to allowing CSRs that are not gated by the xstateen registers.
  if not(stateen_allows_CSR_access(csr, p, access_type)) then {
    return Err((if privLevel_is_virtual(p) & stateen_allows_CSR_access(csr, Supervisor, access_type)
               then CSR_Access_Virtual else CSR_Access_Illegal),
               CSR_Access_Failed_Stateen())
  };

  if default_CSR_access_allowed(csr, p, access_type)
  then return Ok(());

  Err((if privLevel_is_virtual(p) & default_CSR_access_allowed(csr, Supervisor, access_type)
      then CSR_Access_Virtual else CSR_Access_Illegal),
      CSR_Access_Failed_Default_Check())
}
