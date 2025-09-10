// =======================================================================================
// This Sail RISC-V architecture model, comprising all files and
// directories except where otherwise noted is subject the BSD
// two-clause license in the LICENSE file.
//
// SPDX-License-Identifier: BSD-2-Clause
// =======================================================================================

union clause instruction = FENCE_RESERVED : (bits(4), bits(4), bits(4), regidx, regidx)

mapping clause encdec = FENCE_RESERVED(fm, pred, succ, rs, rd)
  <-> fm : bits(4) @ pred : bits(4) @ succ : bits(4) @ encdec_reg(rs) @ 0b000 @ encdec_reg(rd) @ 0b0001111
      when (fm != 0b0000 & fm != 0b1000) | rs != zreg | rd != zreg

function clause execute (FENCE_RESERVED(fm, pred, succ, rs, rd)) = RETIRE_SUCCESS

mapping clause assembly = FENCE_RESERVED(fm, pred, succ, rs, rd)
  <-> "fence.reserved." ^ fence_bits(pred) ^ "." ^ fence_bits(succ) ^ "."
      ^ reg_name(rs) ^ "." ^ reg_name(rd) ^ "." ^ hex_bits_4(fm)
      when (fm != 0b0000 & fm != 0b1000) | rs != zreg | rd != zreg

// *****************************************************************
union clause instruction = FENCEI_RESERVED : (bits(12), regidx, regidx)

mapping clause encdec = FENCEI_RESERVED(imm, rs, rd)
  <-> imm : bits(12) @ encdec_reg(rs) @ 0b001 @ encdec_reg(rd) @ 0b0001111
      when imm != 0b000000000000 | rs != zreg | rd != zreg

function clause execute FENCEI_RESERVED(imm, rs, rd) = RETIRE_SUCCESS

mapping clause assembly = FENCEI_RESERVED(imm, rs, rd)
  <-> "fence.i.reserved." ^ reg_name(rd) ^ "." ^ reg_name(rs) ^ "." ^ hex_bits_12(imm)
      when imm != 0b000000000000 | rs != zreg | rd != zreg
