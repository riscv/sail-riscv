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

union clause instruction = FENCEI : (bits(12), regidx, regidx)

$[wavedrom "0 0 FENCE.I 0 MISC-MEM"]
mapping clause encdec = FENCEI(imm, rs, rd)
  <-> imm : bits(12) @ encdec_reg(rs) @ 0b001 @ encdec_reg(rd) @ 0b0001111

// fence.i is a nop for the memory model
function clause execute FENCEI(imm, rs, rd) = {
  // "The unused fields in the FENCE.I instruction, funct12, rs1, and rd, are
  // reserved for finer-grain fences in future extensions. For forward
  // compatibility, base implementations shall ignore these fields, and
  // standard software shall zero these fields."
  //
  // `funct12` is `imm` here.

  sail_barrier(Barrier_RISCV_i);
  RETIRE_SUCCESS
}

// There's no assembly that encodes reserved fence.i's as far as I know.
// Unfortunately we need to split forwards and backwards because there's
// no way to write a zero regidx as a literal.
mapping clause assembly =
  forwards FENCEI(0x000, rs, rd) => "fence.i"
    when rs == zreg & rd == zreg

mapping clause assembly =
  backwards "fence.i" => FENCEI(0x000, zreg, zreg)
