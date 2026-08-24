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
    // SEIP and SSIP are read-only zero if the hart does not support supervisor mode.
    SEI = if currentlyEnabled(Ext_S) then sig_seip else 0b0,
  ]

function sig_machine_software_interrupt_pending() -> bits(1) =
  sig_msip

function sig_supervisor_software_interrupt_pending() -> bits(1) =
  sig_ssip
