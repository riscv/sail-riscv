// =======================================================================================
// This Sail RISC-V architecture model, comprising all files and
// directories except where otherwise noted is subject the BSD
// two-clause license in the LICENSE file.
//
// SPDX-License-Identifier: BSD-2-Clause
// =======================================================================================

function accessFaultFromAccessType(access : MemoryAccessType(ext_access_type)) -> ExceptionType =
  match access {
    InstructionFetch() => E_Fetch_Access_Fault(),
    Load(_)            => E_Load_Access_Fault(),
    Store(_)           => E_SAMO_Access_Fault(),
    LoadStore(_)       => E_SAMO_Access_Fault(),
  }

function alignmentFaultFromAccessType(access : MemoryAccessType(ext_access_type)) -> ExceptionType =
  match access {
    InstructionFetch() => E_Fetch_Addr_Align(),
    Load(_)            => E_Load_Addr_Align(),
    Store(_)           => E_SAMO_Addr_Align(),
    LoadStore(_)       => E_SAMO_Addr_Align(),
  }
