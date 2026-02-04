// =======================================================================================
// This Sail RISC-V architecture model, comprising all files and
// directories except where otherwise noted is subject the BSD
// two-clause license in the LICENSE file.
//
// SPDX-License-Identifier: BSD-2-Clause
// =======================================================================================

function accessFaultFromAccessType(access : MemoryAccessType(mem_payload)) -> ExceptionType =
  match access {
    InstructionFetch()                  => E_Fetch_Access_Fault(),
    Load(Data)                          => E_Load_Access_Fault(),
    LoadReserved(Data)                  => E_Load_Access_Fault(),
    Store(Data)                         => E_SAMO_Access_Fault(),
    StoreConditional(Data)              => E_SAMO_Access_Fault(),
    Atomic(_, Data, Data)               => E_SAMO_Access_Fault(),

    // "For shadow stack instructions, the reported instruction type
    // is always as though it were a store or AMO, even for instructions
    // SSPOPCHK and C.SSPOPCHK that only read from memory and do not
    // write to it."
    Load(ShadowStack)                   => E_SAMO_Access_Fault(),
    Store(ShadowStack)                  => E_SAMO_Access_Fault(),
    Atomic(_, ShadowStack, ShadowStack) => E_SAMO_Access_Fault(),

    LoadReserved(ShadowStack)           => internal_error(__FILE__, __LINE__, "Invalid payload (ShadowStack) for LoadReserved."),
    StoreConditional(ShadowStack)       => internal_error(__FILE__, __LINE__, "Invalid payload (ShadowStack) for StoreConditional."),
    Atomic(_, ShadowStack, Data)        => internal_error(__FILE__, __LINE__, "Invalid payloads (ShadowStack, Data) for Atomic."),
    Atomic(_, Data, ShadowStack)        => internal_error(__FILE__, __LINE__, "Invalid payloads (Data, ShadowStack) for Atomic."),

    // Cache-block management (CB_manage) and zero (CB_zero)
    // instructions raise store faults.
    CacheAccess(CB_manage(_))           => E_SAMO_Access_Fault(),
    CacheAccess(CB_zero())              => E_SAMO_Access_Fault(),
    // Though prefetches don't raise exceptions, we return a nominal
    // exception here to propagate the failed address translation to
    // the execute of the calling instruction so that it could decide
    // whether to actually proceed with a prefetch.
    CacheAccess(CB_prefetch(p)) => match p {
      PREFETCH_R => E_Load_Access_Fault(),
      PREFETCH_W => E_SAMO_Access_Fault(),
      PREFETCH_I => E_Fetch_Access_Fault(),
    },
  }

function alignmentFaultFromAccessType(access : MemoryAccessType(mem_payload)) -> ExceptionType =
  match access {
    InstructionFetch()                  => E_Fetch_Addr_Align(),
    Load(Data)                          => E_Load_Addr_Align(),
    LoadReserved(Data)                  => E_Load_Addr_Align(),
    Store(Data)                         => E_SAMO_Addr_Align(),
    StoreConditional(Data)              => E_SAMO_Addr_Align(),
    Atomic(_, Data, Data)               => E_SAMO_Addr_Align(),

    // "For shadow stack instructions, the reported instruction type
    // is always as though it were a store or AMO, even for instructions
    // SSPOPCHK and C.SSPOPCHK that only read from memory and do not
    // write to it."
    Load(ShadowStack)                   => E_SAMO_Addr_Align(),
    Store(ShadowStack)                  => E_SAMO_Addr_Align(),
    Atomic(_, ShadowStack, ShadowStack) => E_SAMO_Addr_Align(),

    LoadReserved(ShadowStack)           => internal_error(__FILE__, __LINE__, "Invalid payload (ShadowStack) for LoadReserved."),
    StoreConditional(ShadowStack)       => internal_error(__FILE__, __LINE__, "Invalid payload (ShadowStack) for StoreConditional."),
    Atomic(_, ShadowStack, Data)        => internal_error(__FILE__, __LINE__, "Invalid payloads (ShadowStack, Data) for Atomic."),
    Atomic(_, Data, ShadowStack)        => internal_error(__FILE__, __LINE__, "Invalid payloads (Data, ShadowStack) for Atomic."),

    // Cache-block management (CB_manage) and zero (CB_zero)
    // instructions raise store faults.
    CacheAccess(CB_manage(_))           => E_SAMO_Addr_Align(),
    CacheAccess(CB_zero())              => E_SAMO_Addr_Align(),
    // Though prefetches don't raise exceptions, we return a nominal
    // exception here to propagate the failed address translation to
    // the execute of the calling instruction so that it could decide
    // whether to actually proceed with a prefetch.
    CacheAccess(CB_prefetch(p)) => match p {
      PREFETCH_R => E_Load_Addr_Align(),
      PREFETCH_W => E_SAMO_Addr_Align(),
      PREFETCH_I => E_Fetch_Addr_Align(),
    },
  }
