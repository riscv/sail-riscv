// =======================================================================================
// This Sail RISC-V architecture model, comprising all files and
// directories except where otherwise noted is subject the BSD
// two-clause license in the LICENSE file.
//
// SPDX-License-Identifier: BSD-2-Clause
// =======================================================================================

// Smucfiss: User-mode shadow stack for M+U systems (no S-mode).

function clause currentlyEnabled(Ext_Smucfiss) =
  hartSupports(Ext_Smucfiss)
  & currentlyEnabled(Ext_Zicfiss)
  & currentlyEnabled(Ext_Smcfiss)
  & currentlyEnabled(Ext_U)
  & not(currentlyEnabled(Ext_S))

// U-mode SS region: E=1, XWR=110, menvcfg.SSE=1.
function pmp_is_u_ss_region(cfg : Pmpcfg_ent, e_bit : bits(1)) -> bool =
  currentlyEnabled(Ext_Smucfiss)
  & e_bit == 0b1
  & menvcfg[SSE] == 0b1
  & cfg[X] == 0b1 & cfg[W] == 0b1 & cfg[R] == 0b0

// U-mode shadow-stack accesses and explicit loads are allowed. All others fault.
function pmp_check_u_ss_access(access : MemoryAccessType(mem_payload), priv : Privilege) -> bool =
  match (priv, access) {
    (User, Load(ShadowStack))        => true,
    (User, Store(ShadowStack))       => true,
    (User, Atomic(_, _, _, ShadowStack, ShadowStack)) => true,
    (User, Load(Data))               => true,
    (User, Load(Vector))             => true,
    (User, LoadReserved(_, _, Data)) => true,
    _                                => false,
  }
