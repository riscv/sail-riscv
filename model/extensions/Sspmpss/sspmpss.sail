// =======================================================================================
// This Sail RISC-V architecture model, comprising all files and
// directories except where otherwise noted is subject the BSD
// two-clause license in the LICENSE file.
//
// SPDX-License-Identifier: BSD-2-Clause
// =======================================================================================

// Sspmpss: Supervisor-level PMP shadow stack.

function clause currentlyEnabled(Ext_Sspmpss) =
  hartSupports(Ext_Sspmpss)
  & currentlyEnabled(Ext_Zicfiss)
  & currentlyEnabled(Ext_Sspmp)

// SPMP SS region: XWR=010, SHARED=0, menvcfg.SSE=1.
function spmp_is_ss_region(cfg : Spmpcfg_ent) -> bool =
  currentlyEnabled(Ext_Sspmpss)
  & menvcfg[SSE] == 0b1
  & cfg[SHARED] == 0b0
  & cfg[X] == 0b0 & cfg[W] == 0b1 & cfg[R] == 0b0

// The U bit identifies User-mode entries. mstatus.SUM lets Supervisor mode access them, except for instruction fetches.
function spmp_check_ss_privilege(cfg : Spmpcfg_ent, access : MemoryAccessType(mem_payload), priv : Privilege) -> bool = {
  let is_u_entry = cfg[U] == 0b1;
  let do_sum     = mstatus[SUM] == 0b1;
  match priv {
    Machine           => true,
    Supervisor        => if not(is_u_entry) then true
                         else match access {
                           InstructionFetch() => false,
                           _                  => do_sum,
                         },
    User              => is_u_entry,
    VirtualSupervisor => false,
    VirtualUser       => false,
  }
}

// S-mode and U-mode shadow-stack accesses and explicit loads are allowed. All others fault.
function spmp_check_ss_access(access : MemoryAccessType(mem_payload), priv : Privilege) -> bool =
  match (priv, access) {
    (Supervisor, Load(ShadowStack))        => true,
    (Supervisor, Store(ShadowStack))       => true,
    (Supervisor, Atomic(_, _, _, ShadowStack, ShadowStack)) => true,
    (Supervisor, Load(Data))               => true,
    (Supervisor, Load(Vector))             => true,
    (Supervisor, LoadReserved(_, _, Data)) => true,
    (User,       Load(ShadowStack))        => true,
    (User,       Store(ShadowStack))       => true,
    (User,       Atomic(_, _, _, ShadowStack, ShadowStack)) => true,
    (User,       Load(Data))               => true,
    (User,       Load(Vector))             => true,
    (User,       LoadReserved(_, _, Data)) => true,
    _                                      => false,
  }
