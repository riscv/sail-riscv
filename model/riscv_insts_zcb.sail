/*=======================================================================================*/
/*  This Sail RISC-V architecture model, comprising all files and                        */
/*  directories except where otherwise noted is subject the BSD                          */
/*  two-clause license in the LICENSE file.                                              */
/*                                                                                       */
/*  SPDX-License-Identifier: BSD-2-Clause                                                */
/*=======================================================================================*/

function clause extensionEnabled(Ext_Zcb) = sys_enable_zcb() & extensionEnabled(Ext_Zca)

union clause ast = C_LBU : (bits(2), cregidx, cregidx)

mapping clause encdec_compressed =
      C_LBU(uimm1 @ uimm0, rdc, rs1c)                                                           if extensionEnabled(Ext_Zcb)
  <-> 0b100 @ 0b000 @ rs1c : cregidx @ uimm0 : bits(1) @ uimm1 : bits(1) @ rdc : cregidx @ 0b00 if extensionEnabled(Ext_Zcb)

mapping clause assembly = C_LBU(uimm, rdc, rs1c) <->
  "c.lbu" ^ spc() ^ creg_name(rdc) ^ sep() ^ hex_bits_2(uimm) ^ opt_spc() ^ "(" ^ opt_spc() ^ creg_name(rs1c) ^ opt_spc() ^ ")"

function clause execute C_LBU(uimm, rdc, rs1c) = {
  let imm : bits(12) = zero_extend(uimm);
  let rd = creg2reg_idx(rdc);
  let rs1 = creg2reg_idx(rs1c);
  execute(LOAD(imm, rs1, rd, true, BYTE, false, false))
}

/* ****************************************************************** */

union clause ast = C_LHU : (bits(2), cregidx, cregidx)

mapping clause encdec_compressed =
      C_LHU(uimm1 @ 0b0, rdc, rs1c)                                                 if extensionEnabled(Ext_Zcb)
  <-> 0b100 @ 0b001 @ rs1c : cregidx @ 0b0 @ uimm1 : bits(1) @ rdc : cregidx @ 0b00 if extensionEnabled(Ext_Zcb)

mapping clause assembly = C_LHU(uimm, rdc, rs1c) <->
  "c.lhu" ^ spc() ^ creg_name(rdc) ^ sep() ^ hex_bits_2(uimm) ^ opt_spc() ^ "(" ^ opt_spc() ^ creg_name(rs1c) ^ opt_spc() ^ ")"

function clause execute C_LHU(uimm, rdc, rs1c) = {
  let imm : bits(12) = zero_extend(uimm);
  let rd = creg2reg_idx(rdc);
  let rs1 = creg2reg_idx(rs1c);
  execute(LOAD(imm, rs1, rd, true, HALF, false, false))
}

/* ****************************************************************** */

union clause ast = C_LH : (bits(2), cregidx, cregidx)

mapping clause encdec_compressed =
      C_LH(uimm1 @ 0b0, rdc, rs1c)                                                  if extensionEnabled(Ext_Zcb)
  <-> 0b100 @ 0b001 @ rs1c : cregidx @ 0b1 @ uimm1 : bits(1) @ rdc : cregidx @ 0b00 if extensionEnabled(Ext_Zcb)

mapping clause assembly = C_LH(uimm, rdc, rs1c) <->
  "c.lh" ^ spc() ^ creg_name(rdc) ^ sep() ^ hex_bits_2(uimm) ^ opt_spc() ^ "(" ^ opt_spc() ^ creg_name(rs1c) ^ opt_spc() ^ ")"

function clause execute C_LH(uimm, rdc, rs1c) = {
  let imm : bits(12) = zero_extend(uimm);
  let rd = creg2reg_idx(rdc);
  let rs1 = creg2reg_idx(rs1c);
  execute(LOAD(imm, rs1, rd, false, HALF, false, false))
}

/* ****************************************************************** */

union clause ast = C_SB : (bits(2), cregidx, cregidx)

mapping clause encdec_compressed =
      C_SB(uimm1 @ uimm0, rs1c, rs2c)                                                  if extensionEnabled(Ext_Zcb)
  <-> 0b100 @ 0b010 @ rs1c : cregidx @ uimm0 : bits(1) @ uimm1 : bits(1) @ rs2c @ 0b00 if extensionEnabled(Ext_Zcb)

mapping clause assembly = C_SB(uimm, rs1c, rs2c) <->
  "c.sb" ^ spc() ^ creg_name(rs2c) ^ sep() ^ hex_bits_2(uimm) ^ opt_spc() ^ "(" ^ opt_spc() ^ creg_name(rs1c) ^ opt_spc() ^ ")"

function clause execute C_SB(uimm, rs1c, rs2c) = {
  let imm : bits(12) = zero_extend(uimm);
  let rs1 = creg2reg_idx(rs1c);
  let rs2 = creg2reg_idx(rs2c);
  execute(STORE(imm, rs2, rs1, BYTE, false, false))
}

/* ****************************************************************** */

union clause ast = C_SH : (bits(2), cregidx, cregidx)

mapping clause encdec_compressed =
      C_SH(uimm1 @ 0b0, rs1c, rs2c)                                                  if extensionEnabled(Ext_Zcb)
  <-> 0b100 @ 0b011 @ rs1c : cregidx @ 0b0 @ uimm1 : bits(1) @ rs2c : cregidx @ 0b00 if extensionEnabled(Ext_Zcb)

mapping clause assembly = C_SH(uimm, rs1c, rs2c) <->
  "c.sh" ^ spc() ^ creg_name(rs1c) ^ sep() ^ hex_bits_2(uimm) ^ opt_spc() ^ "(" ^ opt_spc() ^ creg_name(rs2c) ^ opt_spc() ^ ")"

function clause execute C_SH(uimm, rs1c, rs2c) = {
  let imm : bits(12) = zero_extend(uimm);
  let rs1 = creg2reg_idx(rs1c);
  let rs2 = creg2reg_idx(rs2c);
  execute(STORE(imm, rs2, rs1, HALF, false, false))
}

/* ****************************************************************** */

union clause ast = C_ZEXT_B : (cregidx)

mapping clause encdec_compressed =
      C_ZEXT_B(rsdc)                                       if extensionEnabled(Ext_Zcb)
  <-> 0b100 @ 0b111 @ rsdc : cregidx @ 0b11 @ 0b000 @ 0b01 if extensionEnabled(Ext_Zcb)

mapping clause assembly = C_ZEXT_B(rsdc) <->
  "c.zext.b" ^ spc() ^ creg_name(rsdc)

function clause execute C_ZEXT_B(rsdc) = {
  let rsd = creg2reg_idx(rsdc);
  X(rsd) = zero_extend(X(rsd)[7..0]);
  RETIRE_SUCCESS
}

/* ****************************************************************** */

union clause ast = C_SEXT_B : (cregidx)

mapping clause encdec_compressed =
      C_SEXT_B(rsdc)                                       if extensionEnabled(Ext_Zcb) & extensionEnabled(Ext_Zbb)
  <-> 0b100 @ 0b111 @ rsdc : cregidx @ 0b11 @ 0b001 @ 0b01 if extensionEnabled(Ext_Zcb) & extensionEnabled(Ext_Zbb)

mapping clause assembly = C_SEXT_B(rsdc) <->
  "c.sext.b" ^ spc() ^ creg_name(rsdc)

function clause execute C_SEXT_B(rsdc) = {
  let rsd = creg2reg_idx(rsdc);
  execute(ZBB_EXTOP(rsd, rsd, RISCV_SEXTB))
}

/* ****************************************************************** */

union clause ast = C_ZEXT_H : (cregidx)

mapping clause encdec_compressed =
      C_ZEXT_H(rsdc)                                       if extensionEnabled(Ext_Zcb) & extensionEnabled(Ext_Zbb)
  <-> 0b100 @ 0b111 @ rsdc : cregidx @ 0b11 @ 0b010 @ 0b01 if extensionEnabled(Ext_Zcb) & extensionEnabled(Ext_Zbb)

mapping clause assembly = C_ZEXT_H(rsdc) <->
  "c.zext.h" ^ spc() ^ creg_name(rsdc)

function clause execute C_ZEXT_H(rsdc) = {
  let rsd = creg2reg_idx(rsdc);
  execute(ZBB_EXTOP(rsd, rsd, RISCV_ZEXTH))
}

/* ****************************************************************** */

union clause ast = C_SEXT_H : (cregidx)

mapping clause encdec_compressed =
      C_SEXT_H(rsdc)                                       if extensionEnabled(Ext_Zcb) & extensionEnabled(Ext_Zbb)
  <-> 0b100 @ 0b111 @ rsdc : cregidx @ 0b11 @ 0b011 @ 0b01 if extensionEnabled(Ext_Zcb) & extensionEnabled(Ext_Zbb)

mapping clause assembly = C_SEXT_H(rsdc) <->
  "c.sext.h" ^ spc() ^ creg_name(rsdc)

function clause execute C_SEXT_H(rsdc) = {
  let rsd = creg2reg_idx(rsdc);
  execute(ZBB_EXTOP(rsd, rsd,  RISCV_SEXTH))
}

/* ****************************************************************** */

union clause ast = C_ZEXT_W : (cregidx)

mapping clause encdec_compressed =
      C_ZEXT_W(rsdc)                                       if extensionEnabled(Ext_Zcb) & extensionEnabled(Ext_Zba) & xlen == 64
  <-> 0b100 @ 0b111 @ rsdc : cregidx @ 0b11 @ 0b100 @ 0b01 if extensionEnabled(Ext_Zcb) & extensionEnabled(Ext_Zba) & xlen == 64

mapping clause assembly = C_ZEXT_W(rsdc) <->
  "c.zext.w" ^ spc() ^ creg_name(rsdc)

function clause execute C_ZEXT_W(rsdc) = {
  let rsd = creg2reg_idx(rsdc);
  execute (ZBA_RTYPEUW(0b00000, rsd, rsd, RISCV_ADDUW)) // Note 0b00000 is the regidx of the zero register
}

/* ****************************************************************** */

union clause ast = C_NOT : (cregidx)

mapping clause encdec_compressed =
      C_NOT(rsdc)                                          if extensionEnabled(Ext_Zcb)
  <-> 0b100 @ 0b111 @ rsdc : cregidx @ 0b11 @ 0b101 @ 0b01 if extensionEnabled(Ext_Zcb)

mapping clause assembly = C_NOT(rsdc) <->
  "c.not" ^ spc() ^ creg_name(rsdc)

function clause execute C_NOT(rsdc) = {
  let r = creg2reg_idx(rsdc);
  X(r) = ~(X(r));
  RETIRE_SUCCESS
}

/* ****************************************************************** */

union clause ast = C_MUL : (cregidx, cregidx)

mapping clause encdec_compressed =
      C_MUL(rsdc, rs2c)                                             if extensionEnabled(Ext_Zcb) & (extensionEnabled(Ext_M) | extensionEnabled(Ext_Zmmul))
  <-> 0b100 @ 0b111 @ rsdc : cregidx @ 0b10 @ rs2c : cregidx @ 0b01 if extensionEnabled(Ext_Zcb) & (extensionEnabled(Ext_M) | extensionEnabled(Ext_Zmmul))

mapping clause assembly = C_MUL(rsdc, rs2c) <->
  "c.mul" ^ spc() ^ creg_name(rsdc) ^ sep() ^ creg_name(rs2c)

function clause execute C_MUL(rsdc, rs2c) = {
  let rd = creg2reg_idx(rsdc);
  let rs = creg2reg_idx(rs2c);
  execute(MUL(rs, rd, rd, struct { high = false, signed_rs1 = true, signed_rs2 = true }))
}
