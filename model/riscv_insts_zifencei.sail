// =======================================================================================
// This Sail RISC-V architecture model, comprising all files and
// directories except where otherwise noted is subject the BSD
// two-clause license in the LICENSE file.
//
// SPDX-License-Identifier: BSD-2-Clause
// =======================================================================================

// *****************************************************************
// This file specifies the instructions in the 'Zifencei' extension.

// *****************************************************************

function clause currentlyEnabled(Ext_Zifencei) = hartSupports(Ext_Zifencei)

union clause instruction = FENCEI : unit

mapping clause encdec = FENCEI()
  <-> 0b000000000000 @ 0b00000 @ 0b001 @ 0b00000 @ 0b0001111
  when currentlyEnabled(Ext_Zifencei)

// fence.i is a nop for the memory model
function clause execute FENCEI() = { /* __barrier(Barrier_RISCV_i); */ RETIRE_SUCCESS }

mapping clause assembly = FENCEI() <-> "fence.i"
