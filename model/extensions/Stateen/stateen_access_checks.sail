//=======================================================================================
// This Sail RISC-V architecture model, comprising all files and
// directories except where otherwise noted is subject the BSD
// two-clause license in the LICENSE file.
//
// SPDX-License-Identifier: BSD-2-Clause
//=======================================================================================

// Stateen permission checks for CSRs gated by `xstateen` bits.

// These checks could be close to the extensions where the CSRs are
// defined using a scattered definition; however, this creates a
// module dependency problem, especially for registers like
// `senvcfg` where there would be a cyclic dependency between Core and
// Sstateen.
//
// Instead, a scattered definition is declared in Core along with the
// other CSR-related scattered definitions, and its clauses are
// implemented below.  This may also enable building the model without
// the Stateen module.

// hstateen0
function clause stateen_allows_CSR_access(0x60C, priv, _) = check_stateen_bit(priv, STATEEN_SE, 0)
// hstateen0h
function clause stateen_allows_CSR_access(0x61C, priv, _) = check_stateen_bit(priv, STATEEN_SE, 0)
// hstateen1
function clause stateen_allows_CSR_access(0x60D, priv, _) = check_stateen_bit(priv, STATEEN_SE, 1)
// hstateen1h
function clause stateen_allows_CSR_access(0x61D, priv, _) = check_stateen_bit(priv, STATEEN_SE, 1)
// hstateen2
function clause stateen_allows_CSR_access(0x60E, priv, _) = check_stateen_bit(priv, STATEEN_SE, 2)
// hstateen2h
function clause stateen_allows_CSR_access(0x61E, priv, _) = check_stateen_bit(priv, STATEEN_SE, 2)
// hstateen3
function clause stateen_allows_CSR_access(0x60F, priv, _) = check_stateen_bit(priv, STATEEN_SE, 3)
// hstateen3h
function clause stateen_allows_CSR_access(0x61F, priv, _) = check_stateen_bit(priv, STATEEN_SE, 3)

// sstateen0
function clause stateen_allows_CSR_access(0x10C, priv, _) = check_stateen_bit(priv, STATEEN_SE, 0)
// sstateen1
function clause stateen_allows_CSR_access(0x10D, priv, _) = check_stateen_bit(priv, STATEEN_SE, 1)
// sstateen2
function clause stateen_allows_CSR_access(0x10E, priv, _) = check_stateen_bit(priv, STATEEN_SE, 2)
// sstateen3
function clause stateen_allows_CSR_access(0x10F, priv, _) = check_stateen_bit(priv, STATEEN_SE, 3)

// senvcfg
function clause stateen_allows_CSR_access(0x10A, priv, _) = check_stateen_bit(priv, STATEEN_ENVCFG, 0)

// srmcfg
function clause stateen_allows_CSR_access(0x181, priv, _) = check_stateen_bit(priv, STATEEN_SRMCFG, 0)

// fflags
function clause stateen_allows_CSR_access(0x001, priv, _) = if hartSupports(Ext_Zfinx) then check_stateen_bit(priv, STATEEN_FCSR, 0) else true
// frm
function clause stateen_allows_CSR_access(0x002, priv, _) = if hartSupports(Ext_Zfinx) then check_stateen_bit(priv, STATEEN_FCSR, 0) else true
// fcsr
function clause stateen_allows_CSR_access(0x003, priv, _) = if hartSupports(Ext_Zfinx) then check_stateen_bit(priv, STATEEN_FCSR, 0) else true
