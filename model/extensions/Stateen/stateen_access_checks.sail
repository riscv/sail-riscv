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
// Sstateen.  Instead, for now, all the Stateen checks are centralized
// into the below function.
// TODO: refactor the Core module to prevent such cyclic dependencies;
// this would ideally allow the below checks to be inlined into the
// `is_CSR_accessible` function.

function stateen_allows_CSR_access(csr : csreg, priv : Privilege, _access_type : CSRAccessType) -> bool =
  match (csr, priv) {
    // hstateen0
    (0x60C, priv) => check_stateen_bit(priv, STATEEN_SE, 0),
    // hstateen0h
    (0x61C, priv) => check_stateen_bit(priv, STATEEN_SE, 0),
    // hstateen1
    (0x60D, priv) => check_stateen_bit(priv, STATEEN_SE, 1),
    // hstateen1h
    (0x61D, priv) => check_stateen_bit(priv, STATEEN_SE, 1),
    // hstateen2
    (0x60E, priv) => check_stateen_bit(priv, STATEEN_SE, 2),
    // hstateen2h
    (0x61E, priv) => check_stateen_bit(priv, STATEEN_SE, 2),
    // hstateen3
    (0x60F, priv) => check_stateen_bit(priv, STATEEN_SE, 3),
    // hstateen3h
    (0x61F, priv) => check_stateen_bit(priv, STATEEN_SE, 3),

    // sstateen0
    (0x10C, priv) => check_stateen_bit(priv, STATEEN_SE, 0),
    // sstateen1
    (0x10D, priv) => check_stateen_bit(priv, STATEEN_SE, 1),
    // sstateen2
    (0x10E, priv) => check_stateen_bit(priv, STATEEN_SE, 2),
    // sstateen3
    (0x10F, priv) => check_stateen_bit(priv, STATEEN_SE, 3),

    // senvcfg
    (0x10A, priv) => check_stateen_bit(priv, STATEEN_ENVCFG, 0),

    // srmcfg
    (0x181, priv) => check_stateen_bit(priv, STATEEN_SRMCFG, 0),

    // fflags
    (0x001, priv) => if hartSupports(Ext_Zfinx) then check_stateen_bit(priv, STATEEN_FCSR, 0) else true,
    // frm
    (0x002, priv) => if hartSupports(Ext_Zfinx) then check_stateen_bit(priv, STATEEN_FCSR, 0) else true,
    // fcsr
    (0x003, priv) => if hartSupports(Ext_Zfinx) then check_stateen_bit(priv, STATEEN_FCSR, 0) else true,

    // CSRs that are not governed by xstateen are not gated by
    // this function
    (_, _)        => true,
  }
