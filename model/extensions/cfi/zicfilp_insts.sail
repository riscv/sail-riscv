// =======================================================================================
// This Sail RISC-V architecture model, comprising all files and
// directories except where otherwise noted is subject the BSD
// two-clause license in the LICENSE file.
//
// SPDX-License-Identifier: BSD-2-Clause
// =======================================================================================

function make_landing_pad_exception() -> sync_exception =
  struct { trap    = E_Software_Check(),
           excinfo = Some(zero_extend(software_check_cause(SWC_LANDING_PAD_FAULT))),
           ext     = None(),
           reason  = None() }

union clause instruction = LPAD : (landing_pad_label)

// LPAD is encoded as AUIPC with rd as x0
mapping clause encdec = LPAD(lpl)
  <-> lpl @ 0b00000 @ 0b0010111
  when currentlyEnabled(Ext_Zicfilp)

function clause execute LPAD(lpl) = {
  if is_landing_pad_expected() then {
    let unaligned_pc = get_arch_pc()[1 .. 0] != 0b00;
    let label_mismatch = X(Regno(7))[31 .. 12] != lpl & lpl != zeros();
    if unaligned_pc | label_mismatch then {
      Trap(cur_privilege, CTL_TRAP(make_landing_pad_exception()), PC)
    } else {
      reset_elp();
      RETIRE_SUCCESS
    }
  } else {
      RETIRE_SUCCESS
  }
}

mapping clause assembly = LPAD(lpl) <-> "lpad" ^ spc() ^ hex_bits_20(lpl)

function is_lpad_instruction(i : instruction) -> bool =
  match i {
    LPAD(_) => true,
    _       => false,
  }
