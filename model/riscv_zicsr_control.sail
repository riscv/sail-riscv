/*=======================================================================================*/
/*  This Sail RISC-V architecture model, comprising all files and                        */
/*  directories except where otherwise noted is subject the BSD                          */
/*  two-clause license in the LICENSE file.                                              */
/*                                                                                       */
/*  SPDX-License-Identifier: BSD-2-Clause                                                */
/*=======================================================================================*/

/* CSR access control */

function csrAccess(csr : csreg) -> csrRW = csr[11..10]
function csrPriv(csr : csreg) -> priv_level = csr[9..8]

val check_CSR_access : (csrRW, priv_level, Privilege, Virtualization, bool) -> bool
function check_CSR_access(csrrw, csrpr, p, v, isWrite) = {
  let check_priv: bool = match p { /* privilege */
    Machine => (privLevel_to_bits(Machine) >=_u csrpr),
    Supervisor => match v {
      V0 => (0b10>=_u csrpr), /* hypervisor CSRs (0b10) are accessible in HS-mode */
      V1 => (privLevel_to_bits(Supervisor) >=_u csrpr)},
    User => (privLevel_to_bits(User) >=_u csrpr),
  };
  let check_RW = not(isWrite == true & csrrw == 0b11);  /* read/write */
  check_priv & check_RW
}

function check_TVM_SATP(csr : csreg, p : Privilege, v: Virtualization) -> bool =
  match (p, v) {
    (Supervisor, V0) => not(csr == 0x180 & mstatus[TVM] == 0b1),
    (Supervisor, V1) => not(csr == 0x180 & hstatus[VTVM] == 0b1),
    (_, _)           => true
  }

// There are several features that are controlled by machine/supervisor enable
// bits (m/senvcfg, m/scounteren, etc.). This abstracts that logic.
function feature_enabled_for_priv(p : Privilege, v : Virtualization, machine_enable_bit : bit, hypervisor_enable_bit : bit, supervisor_enable_bit : bit) -> bool = match (p, v) {
  (Machine, _)    => true,
  (Supervisor,V0) => machine_enable_bit == bitone,
  (Supervisor,V1) => machine_enable_bit == bitone & hypervisor_enable_bit == bitone,
  (User, V0)      => machine_enable_bit == bitone & (not(extensionEnabled(Ext_S)) | supervisor_enable_bit == bitone),
  // Note: S-mode is always present when H-ext is implemented (when V1 is possible)
  (User, V1)      => machine_enable_bit == bitone & hypervisor_enable_bit == bitone & supervisor_enable_bit == bitone,
}

// Return true if the counter is enabled OR the CSR is not a counter.
function check_Counteren(csr : csreg, p : Privilege, v : Virtualization) -> bool = {
  // Check if it is not a counter.
  if csr <_u 0xC00 | 0xC1F <_u csr
  then return true;

  // Check the relevant bit in m/scounteren.
  let index = unsigned(csr[4 .. 0]);
  feature_enabled_for_priv(p, v, mcounteren.bits[index], hcounteren.bits[index], scounteren.bits[index])
}

/* Seed may only be accessed if we are doing a write, and access has been
 * allowed in the current priv mode
 */
function check_seed_CSR (csr : csreg, p : Privilege, isWrite : bool) -> bool = {
  if not(csr == 0x015) then {
    true
  } else if not(isWrite) then {
    /* Read-only access to the seed CSR is not allowed */
    false
  } else {
    match (p) {
      Machine => true,
      Supervisor => false, /* TODO: base this on mseccfg */
      User => false, /* TODO: base this on mseccfg */
    }
  }
}

function check_CSR(csr : csreg, p : Privilege, v: Virtualization, isWrite : bool) -> bool =
    is_CSR_defined(csr)
  & check_CSR_access(csrAccess(csr), csrPriv(csr), p, v, isWrite)
  & check_TVM_SATP(csr, p, v)
  & check_Counteren(csr, p, v)
  & check_seed_CSR(csr, p, isWrite)
