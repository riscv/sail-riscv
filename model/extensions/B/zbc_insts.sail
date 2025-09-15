// =======================================================================================
// This Sail RISC-V architecture model, comprising all files and
// directories except where otherwise noted is subject the BSD
// two-clause license in the LICENSE file.
//
// SPDX-License-Identifier: BSD-2-Clause
// =======================================================================================

function clause currentlyEnabled(Ext_Zbc) = hartSupports(Ext_Zbc)
function clause currentlyEnabled(Ext_Zbkc) = hartSupports(Ext_Zbkc)

// *****************************************************************
union clause instruction = CLMUL : (regidx, regidx, regidx)

mapping clause encdec = CLMUL(rs2, rs1, rd)
  <-> 0b0000101 @ encdec_reg(rs2) @ encdec_reg(rs1) @ 0b001 @ encdec_reg(rd) @ 0b0110011
  when currentlyEnabled(Ext_Zbc) | currentlyEnabled(Ext_Zbkc)

mapping clause assembly = CLMUL(rs2, rs1, rd)
  <-> "clmul" ^ spc() ^ reg_name(rd) ^ sep() ^ reg_name(rs1) ^ sep() ^ reg_name(rs2)

function clause execute (CLMUL(rs2, rs1, rd)) = {
  let prod = carryless_mul(X(rs1), X(rs2));
  X(rd) = prod[xlen - 1 .. 0];
  RETIRE_SUCCESS
}

// *****************************************************************
union clause instruction = CLMULH : (regidx, regidx, regidx)

mapping clause encdec = CLMULH(rs2, rs1, rd)
  <-> 0b0000101 @ encdec_reg(rs2) @ encdec_reg(rs1) @ 0b011 @ encdec_reg(rd) @ 0b0110011
  when currentlyEnabled(Ext_Zbc) | currentlyEnabled(Ext_Zbkc)

mapping clause assembly = CLMULH(rs2, rs1, rd)
  <-> "clmulh" ^ spc() ^ reg_name(rd) ^ sep() ^ reg_name(rs1) ^ sep() ^ reg_name(rs2)

function clause execute (CLMULH(rs2, rs1, rd)) = {
  let prod = carryless_mul(X(rs1), X(rs2));
  X(rd) = prod[2 * xlen - 1 .. xlen];
  RETIRE_SUCCESS
}

// *****************************************************************
union clause instruction = CLMULR : (regidx, regidx, regidx)

mapping clause encdec = CLMULR(rs2, rs1, rd)
  <-> 0b0000101 @ encdec_reg(rs2) @ encdec_reg(rs1) @ 0b010 @ encdec_reg(rd) @ 0b0110011
  when currentlyEnabled(Ext_Zbc)

mapping clause assembly = CLMULR(rs2, rs1, rd)
  <-> "clmulr" ^ spc() ^ reg_name(rd) ^ sep() ^ reg_name(rs1) ^ sep() ^ reg_name(rs2)

function clause execute (CLMULR(rs2, rs1, rd)) = {
  X(rd) = carryless_mulr(X(rs1), X(rs2));
  RETIRE_SUCCESS
}
