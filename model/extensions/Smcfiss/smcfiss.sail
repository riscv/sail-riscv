// =======================================================================================
// This Sail RISC-V architecture model, comprising all files and
// directories except where otherwise noted is subject the BSD
// two-clause license in the LICENSE file.
//
// SPDX-License-Identifier: BSD-2-Clause
// =======================================================================================

// Smcfiss: Machine-mode shadow stack.

function clause currentlyEnabled(Ext_Smcfiss) =
  hartSupports(Ext_Smcfiss)
  & currentlyEnabled(Ext_Zicfiss)
  & currentlyEnabled(Ext_Smpmpind)

// M-mode SS region: E=1, XWR=010, mseccfg.MSSE=1.
function pmp_is_m_ss_region(cfg : Pmpcfg_ent, e_bit : bits(1)) -> bool =
  currentlyEnabled(Ext_Smcfiss)
  & e_bit == 0b1
  & mseccfg[MSSE] == 0b1
  & cfg[X] == 0b0 & cfg[W] == 0b1 & cfg[R] == 0b0

// M-mode shadow-stack accesses and explicit loads are allowed. All others fault.
function pmp_check_m_ss_access(access : MemoryAccessType(mem_payload), priv : Privilege) -> bool =
  match (priv, access) {
    (Machine, Load(ShadowStack))        => true,
    (Machine, Store(ShadowStack))       => true,
    (Machine, Atomic(_, _, _, ShadowStack, ShadowStack)) => true,
    (Machine, Load(Data))               => true,
    (Machine, Load(Vector))             => true,
    (Machine, LoadReserved(_, _, Data)) => true,
    _                                   => false,
  }
