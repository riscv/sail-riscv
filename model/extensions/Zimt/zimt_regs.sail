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

// ---------------------------------------------------------------------
// MT_MODE lookup ("Enabling memory tagging", MEM_TAG_EN)
//
// Return the MemTaggingMode controlling regular explicit accesses and
// Zimt instructions at the given (effective) privilege:
//   M    : mseccfg.MT_MODE
//   HS/S : menvcfg.MT_MODE
//   U    : senvcfg.MT_MODE
//   VS   : henvcfg.MT_MODE
//   VU   : senvcfg.MT_MODE
// HLV*/HSV* executed from HU with effective privilege VU use
// hstatus.VUMT_MODE instead; that case is handled by the (future)
// HLV/HSV tag check plumbing, not here.
function get_mt_mode(priv : Privilege) -> MemTaggingMode = {
  if not(currentlyEnabled(Ext_Zimt)) then return MT_MODE_Disabled;
  match priv {
    Machine    => mt_mode(mseccfg[MT_MODE]),
    Supervisor => mt_mode(menvcfg[MT_MODE]),
    User       => if currentlyEnabled(Ext_S) then mt_mode(read_senvcfg()[MT_MODE]) else mt_mode(menvcfg[MT_MODE]),
    VirtualSupervisor => mt_mode(read_henvcfg()[MT_MODE]),
    VirtualUser       => mt_mode(read_senvcfg()[MT_MODE]),
  }
}

// Whether memory tagging is active at the given privilege. When
// inactive, the Zimt instructions implement their Zimop fallback
// behavior (see zimt_insts.sail).
function zimt_active(priv : Privilege) -> bool =
  get_mt_mode(priv) != MT_MODE_Disabled
