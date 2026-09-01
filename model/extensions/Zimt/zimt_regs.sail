// =======================================================================================
// This Sail RISC-V architecture model, comprising all files and
// directories except where otherwise noted is subject the BSD
// two-clause license in the LICENSE file.
//
// SPDX-License-Identifier: BSD-2-Clause
// =======================================================================================

// Architectural state and enablement for the Zimt memory tagging
// extension and the Svatag/Smvatag tag storage extensions (v0.2, DRAFT).
// https://github.com/riscv/riscv-memory-tagging

// "The Zimt extension depends on Zicsr, Zimop and pointer masking
// extensions and is applicable only for XLEN=64."
function clause currentlyEnabled(Ext_Zimt) =
  hartSupports(Ext_Zimt) & currentlyEnabled(Ext_Zicsr) & currentlyEnabled(Ext_Zimop)
  & (currentlyEnabled(Ext_Ssnpm) | currentlyEnabled(Ext_Smnpm) | currentlyEnabled(Ext_Smmpm))

// Svatag defines the virtually indexed tag table (VITT) for
// S/HS/U/VS/VU modes; Smvatag defines it for M-mode.
function clause currentlyEnabled(Ext_Svatag) = hartSupports(Ext_Svatag) & currentlyEnabled(Ext_Zimt)
function clause currentlyEnabled(Ext_Smvatag) = hartSupports(Ext_Smvatag) & currentlyEnabled(Ext_Zimt)
