/*=======================================================================================*/
/*  This Sail RISC-V architecture model, comprising all files and                        */
/*  directories except where otherwise noted is subject the BSD                          */
/*  two-clause license in the LICENSE file.                                              */
/*                                                                                       */
/*  SPDX-License-Identifier: BSD-2-Clause                                                */
/*=======================================================================================*/

function get_xLPE(p : Privilege) -> bool =
  // When S-mode is implemented:
  //   Priv      xLPE
  //   ----------------------
  //   M         mseccfg.MLPE
  //   S/HS      menvcfg.LPE
  //   VS        henvcfg.LPE
  //   U/VU      senvcfg.LPE
  //
  // When S-mode is not implemented:
  //   Priv      xLPE
  //   ----------------------
  //   M         mseccfg.MLPE
  //   U         menvcfg.LPE
  //
  match p {
    Machine    => bool_bits(mseccfg[MLPE]),
    Supervisor => bool_bits(menvcfg[LPE]),      // TODO: check henvcfg for VS mode
    User       => if   currentlyEnabled(Ext_S)
                  then bool_bits(senvcfg[LPE])
                  else bool_bits(menvcfg[LPE]),
  }

function clause currentlyEnabled(Ext_Zicfilp) =
  hartSupports(Ext_Zicfilp) & get_xLPE(cur_privilege)

/// Architectural state for the Zicfilp extension.

// Expected Landing Pad
register elp : bool

let NO_LP_EXPECTED = false
let LP_EXPECTED = true

function update_elp_state(rs1 : regidx) -> unit =
  if currentlyEnabled(Ext_Zicfilp) then {
    let is_software_guarded_branch = rs1 == Regidx(zero_extend(0x7));
    let is_return = rs1 == Regidx(zero_extend(0x1)) | rs1 == Regidx(zero_extend(0x5));
    elp = not(is_software_guarded_branch) & not(is_return);
  }

function is_landing_pad_expected() -> bool =
  elp == LP_EXPECTED

function reset_elp() -> unit =
  elp = NO_LP_EXPECTED

/// Interaction with system registers.

// When a trap is taken into privilege mode x, the xPELP is set
// to ELP and ELP is set to NO_LP_EXPECTED.
function zicfilp_preserve_elp_on_trap(x : Privilege) -> unit = {
  // When Sdext is added, ELP will need to be preserved there as well.
  match x {
    Machine    => { mstatus[MPELP] = bool_bits(elp); },
    Supervisor => { mstatus[SPELP] = bool_bits(elp); },
    User       => internal_error(__FILE__, __LINE__, "Invalid privilege level"),
  };
  reset_elp();
}

// When executing an xRET instruction, if the new privilege mode is y,
// then ELP is set to the value of xPELP if yLPE is 1; otherwise, it
// is set to NO_LP_EXPECTED; xPELP is set to NO_LP_EXPECTED.
function zicfilp_restore_elp_on_xret(xret : xRET_type, y : Privilege) -> unit = {
  let pelp : bits(1) = match xret {
    mRET => {
      let pelp = mstatus[MPELP];
      mstatus[MPELP] = 0b0;
      pelp
    },
    sRET => {
      let pelp = mstatus[SPELP];
      mstatus[SPELP] = 0b0;
      pelp
    },
  };
  elp = if get_xLPE(y) then bool_bits(pelp) else NO_LP_EXPECTED;
}
