// =======================================================================================
// This Sail RISC-V architecture model, comprising all files and
// directories except where otherwise noted is subject the BSD
// two-clause license in the LICENSE file.
//
// SPDX-License-Identifier: BSD-2-Clause
// =======================================================================================

// The last value written to the Simple Interrupt Generator.
private register sig_meip : bits(1) = 0b0
private register sig_seip : bits(1) = 0b0

function external_interrupts_pending() -> Minterrupts =
  [Mk_Minterrupts(zeros()) with
    MEI = sig_meip,
    SEI = sig_seip,
  ]
