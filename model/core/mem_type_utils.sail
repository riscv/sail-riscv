// =======================================================================================
// This Sail RISC-V architecture model, comprising all files and
// directories except where otherwise noted is subject the BSD
// two-clause license in the LICENSE file.
//
// SPDX-License-Identifier: BSD-2-Clause
// =======================================================================================

function accessFaultFromAccessType(access : MemoryAccessType(mem_payload)) -> ExceptionType =
  match access {
    InstructionFetch()          => E_Fetch_Access_Fault(),
    Load(_)                     => E_Load_Access_Fault(),
    LoadReserved(_)             => E_Load_Access_Fault(),
    Store(_)                    => E_SAMO_Access_Fault(),
    StoreConditional(_)         => E_SAMO_Access_Fault(),
    Atomic(_)                   => E_SAMO_Access_Fault(),
    // Cache-block management (CB_manage) and zero (CB_zero)
    // instructions raise store faults.
    CacheAccess(CB_manage())    => E_SAMO_Access_Fault(),
    CacheAccess(CB_zero())      => E_SAMO_Access_Fault(),
    // Though prefetches don't raise exceptions, we return a nominal
    // exception here to propagate the failed address translation to
    // the execute of the calling instruction so that it could decide
    // whether to actually proceed with a prefetch.
    CacheAccess(CB_prefetch(_)) => E_Load_Access_Fault(),
  }

function alignmentFaultFromAccessType(access : MemoryAccessType(mem_payload)) -> ExceptionType =
  match access {
    InstructionFetch()          => E_Fetch_Addr_Align(),
    Load(_)                     => E_Load_Addr_Align(),
    LoadReserved(_)             => E_Load_Addr_Align(),
    Store(_)                    => E_SAMO_Addr_Align(),
    StoreConditional(_)         => E_SAMO_Addr_Align(),
    Atomic(_)                   => E_SAMO_Addr_Align(),
    // Cache-block management (CB_manage) and zero (CB_zero)
    // instructions raise store faults.
    CacheAccess(CB_manage())    => E_SAMO_Addr_Align(),
    CacheAccess(CB_zero())      => E_SAMO_Addr_Align(),
    // Though prefetches don't raise exceptions, we return a nominal
    // exception here to propagate the failed address translation to
    // the execute of the calling instruction so that it could decide
    // whether to actually proceed with a prefetch.
    CacheAccess(CB_prefetch(_)) => E_Load_Addr_Align(),
  }
