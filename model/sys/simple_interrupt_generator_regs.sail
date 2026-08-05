// =======================================================================================
// This Sail RISC-V architecture model, comprising all files and
// directories except where otherwise noted is subject the BSD
// two-clause license in the LICENSE file.
//
// SPDX-License-Identifier: BSD-2-Clause
// =======================================================================================

// The last value written to the Simple Interrupt Generator.
private register sig_msip : bits(1) = 0b0
private register sig_meip : bits(1) = 0b0
private register sig_seip : bits(1) = 0b0
private register sig_ssip : bits(1) = 0b0

function sig_external_interrupts_pending() -> Minterrupts =
  [Mk_Minterrupts(zeros()) with
    MEI = sig_meip,
    // SEIP is read-only zero if the hart does not support supervisor mode.
    SEI = if currentlyEnabled(Ext_S) then sig_seip else 0b0,
    // Guest external interrupts are driven by hgeip, which the generator writes
    // directly. Both of these are read-only functions of it, so they are
    // supplied here instead of being stored in mip.
    SGEI = if currentlyEnabled(Ext_H) then bool_to_bit((hgeip & hgeie) != zeros()) else 0b0,
    VSEI = if currentlyEnabled(Ext_H) then selected_hgeip() else 0b0,
  ]

function sig_machine_software_interrupt_pending() -> bits(1) =
  sig_msip

function sig_supervisor_software_interrupt_pending() -> bits(1) =
  sig_ssip
