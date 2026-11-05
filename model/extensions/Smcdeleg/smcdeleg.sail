// =======================================================================================
// This Sail RISC-V architecture model, comprising all files and
// directories except where otherwise noted is subject the BSD
// two-clause license in the LICENSE file.
//
// SPDX-License-Identifier: BSD-2-Clause
// =======================================================================================

// TODO: Section "Virtualizing Local-Counter-Overflow Interrupts" needs Smaia/Ssaia.
// Once supported, make LCOFI writable in mvip, mvien, hvip and hvien.

function clause currentlyEnabled(Ext_Smcdeleg) = hartSupports(Ext_Smcdeleg) & currentlyEnabled(Ext_Sscsrind)
function clause currentlyEnabled(Ext_Ssccfg) = hartSupports(Ext_Ssccfg) & currentlyEnabled(Ext_Sscsrind)

// siselect 0x40 to 0x5F
function clause indirect_reg_implemented((Sireg, sel, i) if unsigned(0x40) <= unsigned(sel) & unsigned(sel) <= unsigned(0x5F)) = {
  // Indirect HPM State Mappings table
  let state_exists : bool = match (sel[7 .. 0], i) {
    (0x40, 1) => currentlyEnabled(Ext_Zicntr),                 // mcycle
    (0x40, 2) => currentlyEnabled(Ext_Smcntrpmf),              // mcyclecfg
    (0x40, 4) => xlen == 32 & currentlyEnabled(Ext_Zicntr),    // mcycleh
    (0x40, 5) => xlen == 32 & currentlyEnabled(Ext_Smcntrpmf), // mcyclecfgh
    (0x41, _) => false,                                        // mtime
    (0x42, 1) => currentlyEnabled(Ext_Zicntr),                 // minstret
    (0x42, 2) => currentlyEnabled(Ext_Smcntrpmf),              // minstretcfg
    (0x42, 4) => xlen == 32 & currentlyEnabled(Ext_Zicntr),    // minstreth
    (0x42, 5) => xlen == 32 & currentlyEnabled(Ext_Smcntrpmf), // minstretcfgh
    (_, 1)    => currentlyEnabled(Ext_Zihpm),                  // mhpmcounterN
    (_, 2)    => currentlyEnabled(Ext_Zihpm),                  // mhpmeventN
    (_, 4)    => xlen == 32 & currentlyEnabled(Ext_Zihpm),     // mhpmcounterNh
    (_, 5)    => xlen == 32 & currentlyEnabled(Ext_Sscofpmf),  // mhpmeventNh
    _         => false,                                        // sireg3, sireg6
  };
  currentlyEnabled(Ext_Ssccfg) & menvcfg[CDE] == 0b1 & mcounteren.bits[unsigned(sel[4 .. 0])] == 0b1 & state_exists
}
