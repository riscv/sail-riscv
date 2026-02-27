// =======================================================================================
// This Sail RISC-V architecture model, comprising all files and
// directories except where otherwise noted is subject the BSD
// two-clause license in the LICENSE file.
//
// SPDX-License-Identifier: BSD-2-Clause
// =======================================================================================

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
    Machine           => bool_bit(mseccfg[MLPE]),
    Supervisor        => bool_bit(menvcfg[LPE]),
    User              => if   currentlyEnabled(Ext_S)
                         then bool_bit(read_senvcfg()[LPE])
                         else bool_bit(menvcfg[LPE]),
    // TODO: check henvcfg for VS mode
    VirtualSupervisor => internal_error(__FILE__, __LINE__, "Hypervisor extension not supported"),
    VirtualUser       => internal_error(__FILE__, __LINE__, "Hypervisor extension not supported"),
  }

// This measure needs to be > currentlyEnabled_measure(Ext_S), currently equal
// to 1, see currentlyEnabled_measure in extensions.sail
termination_measure get_xLPE(_) = 2

function clause currentlyEnabled(Ext_Zicfilp) =
  currentlyEnabled(Ext_Zicsr) & hartSupports(Ext_Zicfilp) & get_xLPE(cur_privilege)

/// Architectural state for the Zicfilp extension.
private enum landing_pad_expectation = { NO_LP_EXPECTED, LP_EXPECTED }

// Expected Landing Pad
register elp : bits(1)

private mapping landing_pad_bits : bits(1) <-> landing_pad_expectation = {
  0b0 <-> NO_LP_EXPECTED,
  0b1 <-> LP_EXPECTED,
}

function update_elp_state(rs1 : regidx) -> unit =
  if currentlyEnabled(Ext_Zicfilp) then {
    let is_software_guarded_branch = rs1 == Regidx(zero_extend(0x7));
    let is_return = rs1 == Regidx(zero_extend(0x1)) | rs1 == Regidx(zero_extend(0x5));
    elp = bool_to_bit(not(is_software_guarded_branch) & not(is_return))
  }

function is_landing_pad_expected() -> bool =
  elp == landing_pad_bits(LP_EXPECTED)

function reset_elp() -> unit =
  elp = landing_pad_bits(NO_LP_EXPECTED)

// Interaction with system registers.

// When a trap is taken into privilege mode x, the xPELP is set
// to ELP and ELP is set to NO_LP_EXPECTED.
function zicfilp_preserve_elp_on_trap(x : Privilege) -> unit = {
  // When Sdext is added, ELP will need to be preserved there as well.
  match x {
    Machine           => { mstatus[MPELP] = elp; },
    Supervisor        => { mstatus[SPELP] = elp; },
    User              => internal_error(__FILE__, __LINE__, "Invalid privilege level"),
    VirtualSupervisor => internal_error(__FILE__, __LINE__, "Hypervisor extension not supported"),
    VirtualUser       => internal_error(__FILE__, __LINE__, "Hypervisor extension not supported"),
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
      mstatus[MPELP] = landing_pad_bits(NO_LP_EXPECTED);
      pelp
    },
    sRET => {
      let pelp = mstatus[SPELP];
      mstatus[SPELP] = landing_pad_bits(NO_LP_EXPECTED);
      pelp
    },
  };
  elp = if get_xLPE(y) then pelp else landing_pad_bits(NO_LP_EXPECTED);
}
