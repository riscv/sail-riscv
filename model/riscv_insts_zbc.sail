/*=======================================================================================*/
/*  This Sail RISC-V architecture model, comprising all files and                        */
/*  directories except where otherwise noted is subject the BSD                          */
/*  two-clause license in the LICENSE file.                                              */
/*                                                                                       */
/*  SPDX-License-Identifier: BSD-2-Clause                                                */
/*=======================================================================================*/

function clause currentlyEnabled(Ext_Zbc) = true
function clause currentlyEnabled(Ext_Zbkc) = true

/* ****************************************************************** */
union clause ast = RISCV_CLMUL : (regidx, regidx, regidx)

mapping clause encdec = RISCV_CLMUL(rs2, rs1, rd)
  <-> 0b0000101 @ encdec_reg(rs2) @ encdec_reg(rs1) @ 0b001 @ encdec_reg(rd) @ 0b0110011
  when currentlyEnabled(Ext_Zbc) | currentlyEnabled(Ext_Zbkc)

mapping clause assembly = RISCV_CLMUL(rs2, rs1, rd)
  <-> "clmul" ^ spc() ^ reg_name(rd) ^ sep() ^ reg_name(rs1) ^ sep() ^ reg_name(rs2)

function clause execute (RISCV_CLMUL(rs2, rs1, rd)) = {
  let prod = carryless_mul(X(rs1), X(rs2));
  X(rd) = prod[xlen - 1 .. 0];
  RETIRE_SUCCESS
}

/* ****************************************************************** */
union clause ast = RISCV_CLMULH : (regidx, regidx, regidx)

mapping clause encdec = RISCV_CLMULH(rs2, rs1, rd)
  <-> 0b0000101 @ encdec_reg(rs2) @ encdec_reg(rs1) @ 0b011 @ encdec_reg(rd) @ 0b0110011
  when currentlyEnabled(Ext_Zbc) | currentlyEnabled(Ext_Zbkc)

mapping clause assembly = RISCV_CLMULH(rs2, rs1, rd)
  <-> "clmulh" ^ spc() ^ reg_name(rd) ^ sep() ^ reg_name(rs1) ^ sep() ^ reg_name(rs2)

function clause execute (RISCV_CLMULH(rs2, rs1, rd)) = {
  let prod = carryless_mul(X(rs1), X(rs2));
  X(rd) = prod[2 * xlen - 1 .. xlen];
  RETIRE_SUCCESS
}

/* ****************************************************************** */
union clause ast = RISCV_CLMULR : (regidx, regidx, regidx)

mapping clause encdec = RISCV_CLMULR(rs2, rs1, rd)
  <-> 0b0000101 @ encdec_reg(rs2) @ encdec_reg(rs1) @ 0b010 @ encdec_reg(rd) @ 0b0110011
  when currentlyEnabled(Ext_Zbc)

mapping clause assembly = RISCV_CLMULR(rs2, rs1, rd)
  <-> "clmulr" ^ spc() ^ reg_name(rd) ^ sep() ^ reg_name(rs1) ^ sep() ^ reg_name(rs2)

function clause execute (RISCV_CLMULR(rs2, rs1, rd)) = {
  let prod = carryless_mul(reverse(X(rs1)), reverse(X(rs2)));
  X(rd) = reverse(prod[xlen - 1 .. 0]);
  RETIRE_SUCCESS
}
