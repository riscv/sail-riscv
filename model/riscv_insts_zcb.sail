/*=======================================================================================*/
/*  This Sail RISC-V architecture model, comprising all files and                        */
/*  directories except where otherwise noted is subject the BSD                          */
/*  two-clause license in the LICENSE file.                                              */
/*                                                                                       */
/*  SPDX-License-Identifier: BSD-2-Clause                                                */
/*=======================================================================================*/

function clause currentlyEnabled(Ext_Zcb) = hartSupports(Ext_Zcb) & currentlyEnabled(Ext_Zca)

union clause instruction = C_LBU : (bits(2), cregidx, cregidx)

mapping clause encdec_compressed = C_LBU(uimm1 @ uimm0, rdc, rsc1)
  <-> 0b100 @ 0b000 @ encdec_creg(rsc1) @ uimm0 : bits(1) @ uimm1 : bits(1) @ encdec_creg(rdc) @ 0b00
  when currentlyEnabled(Ext_Zcb)

mapping clause assembly = C_LBU(uimm, rdc, rsc1) <->
  "c.lbu" ^ spc() ^ creg_name(rdc) ^ sep() ^ hex_bits_2(uimm) ^ opt_spc() ^ "(" ^ opt_spc() ^ creg_name(rsc1) ^ opt_spc() ^ ")"

function clause execute C_LBU(uimm, rdc, rsc1) = {
  let imm : bits(12) = zero_extend(uimm);
  let rd = creg2reg_idx(rdc);
  let rs1 = creg2reg_idx(rsc1);
  execute(LOAD(imm, rs1, rd, true, 1))
}

/* ****************************************************************** */

union clause instruction = C_LHU : (bits(2), cregidx, cregidx)

mapping clause encdec_compressed = C_LHU(uimm1 @ 0b0, rdc, rsc1)
  <-> 0b100 @ 0b001 @ encdec_creg(rsc1) @ 0b0 @ uimm1 : bits(1) @ encdec_creg(rdc) @ 0b00
  when currentlyEnabled(Ext_Zcb)

mapping clause assembly = C_LHU(uimm, rdc, rsc1) <->
  "c.lhu" ^ spc() ^ creg_name(rdc) ^ sep() ^ hex_bits_2(uimm) ^ opt_spc() ^ "(" ^ opt_spc() ^ creg_name(rsc1) ^ opt_spc() ^ ")"

function clause execute C_LHU(uimm, rdc, rsc1) = {
  let imm : bits(12) = zero_extend(uimm);
  let rd = creg2reg_idx(rdc);
  let rs1 = creg2reg_idx(rsc1);
  execute(LOAD(imm, rs1, rd, true, 2))
}

/* ****************************************************************** */

union clause instruction = C_LH : (bits(2), cregidx, cregidx)

mapping clause encdec_compressed = C_LH(uimm1 @ 0b0, rdc, rsc1)
  <-> 0b100 @ 0b001 @ encdec_creg(rsc1) @ 0b1 @ uimm1 : bits(1) @ encdec_creg(rdc) @ 0b00
  when currentlyEnabled(Ext_Zcb)

mapping clause assembly = C_LH(uimm, rdc, rsc1) <->
  "c.lh" ^ spc() ^ creg_name(rdc) ^ sep() ^ hex_bits_2(uimm) ^ opt_spc() ^ "(" ^ opt_spc() ^ creg_name(rsc1) ^ opt_spc() ^ ")"

function clause execute C_LH(uimm, rdc, rsc1) = {
  let imm : bits(12) = zero_extend(uimm);
  let rd = creg2reg_idx(rdc);
  let rs1 = creg2reg_idx(rsc1);
  execute(LOAD(imm, rs1, rd, false, 2))
}

/* ****************************************************************** */

union clause instruction = C_SB : (bits(2), cregidx, cregidx)

mapping clause encdec_compressed = C_SB(uimm1 @ uimm0, rsc1, rsc2)
  <-> 0b100 @ 0b010 @ encdec_creg(rsc1) @ uimm0 : bits(1) @ uimm1 : bits(1) @ encdec_creg(rsc2) @ 0b00
  when currentlyEnabled(Ext_Zcb)

mapping clause assembly = C_SB(uimm, rsc1, rsc2) <->
  "c.sb" ^ spc() ^ creg_name(rsc2) ^ sep() ^ hex_bits_2(uimm) ^ opt_spc() ^ "(" ^ opt_spc() ^ creg_name(rsc1) ^ opt_spc() ^ ")"

function clause execute C_SB(uimm, rsc1, rsc2) = {
  let imm : bits(12) = zero_extend(uimm);
  let rs1 = creg2reg_idx(rsc1);
  let rs2 = creg2reg_idx(rsc2);
  execute(STORE(imm, rs2, rs1, 1))
}

/* ****************************************************************** */

union clause instruction = C_SH : (bits(2), cregidx, cregidx)

mapping clause encdec_compressed = C_SH(uimm1 @ 0b0, rsc1, rsc2)
  <-> 0b100 @ 0b011 @ encdec_creg(rsc1) @ 0b0 @ uimm1 : bits(1) @ encdec_creg(rsc2) @ 0b00
  when currentlyEnabled(Ext_Zcb)

mapping clause assembly = C_SH(uimm, rsc1, rsc2) <->
  "c.sh" ^ spc() ^ creg_name(rsc2) ^ sep() ^ hex_bits_2(uimm) ^ opt_spc() ^ "(" ^ opt_spc() ^ creg_name(rsc1) ^ opt_spc() ^ ")"

function clause execute C_SH(uimm, rsc1, rsc2) = {
  let imm : bits(12) = zero_extend(uimm);
  let rs1 = creg2reg_idx(rsc1);
  let rs2 = creg2reg_idx(rsc2);
  execute(STORE(imm, rs2, rs1, 2))
}

/* ****************************************************************** */

union clause instruction = C_ZEXT_B : (cregidx)

mapping clause encdec_compressed = C_ZEXT_B(rsdc)
  <-> 0b100 @ 0b111 @ encdec_creg(rsdc) @ 0b11 @ 0b000 @ 0b01
  when currentlyEnabled(Ext_Zcb)

mapping clause assembly = C_ZEXT_B(rsdc) <->
  "c.zext.b" ^ spc() ^ creg_name(rsdc)

function clause execute C_ZEXT_B(rsdc) = {
  let rsd = creg2reg_idx(rsdc);
  X(rsd) = zero_extend(X(rsd)[7..0]);
  RETIRE_SUCCESS
}

/* ****************************************************************** */

union clause instruction = C_SEXT_B : (cregidx)

mapping clause encdec_compressed = C_SEXT_B(rsdc)
  <-> 0b100 @ 0b111 @ encdec_creg(rsdc) @ 0b11 @ 0b001 @ 0b01
  when currentlyEnabled(Ext_Zcb) & currentlyEnabled(Ext_Zbb)

mapping clause assembly = C_SEXT_B(rsdc) <->
  "c.sext.b" ^ spc() ^ creg_name(rsdc)

function clause execute C_SEXT_B(rsdc) = {
  let rsd = creg2reg_idx(rsdc);
  execute(ZBB_EXTOP(rsd, rsd, SEXTB))
}

/* ****************************************************************** */

union clause instruction = C_ZEXT_H : (cregidx)

mapping clause encdec_compressed = C_ZEXT_H(rsdc)
  <-> 0b100 @ 0b111 @ encdec_creg(rsdc) @ 0b11 @ 0b010 @ 0b01
  when currentlyEnabled(Ext_Zcb) & currentlyEnabled(Ext_Zbb)

mapping clause assembly = C_ZEXT_H(rsdc) <->
  "c.zext.h" ^ spc() ^ creg_name(rsdc)

function clause execute C_ZEXT_H(rsdc) = {
  let rsd = creg2reg_idx(rsdc);
  execute(ZBB_EXTOP(rsd, rsd, ZEXTH))
}

/* ****************************************************************** */

union clause instruction = C_SEXT_H : (cregidx)

mapping clause encdec_compressed = C_SEXT_H(rsdc)
  <-> 0b100 @ 0b111 @ encdec_creg(rsdc) @ 0b11 @ 0b011 @ 0b01
  when currentlyEnabled(Ext_Zcb) & currentlyEnabled(Ext_Zbb)

mapping clause assembly = C_SEXT_H(rsdc) <->
  "c.sext.h" ^ spc() ^ creg_name(rsdc)

function clause execute C_SEXT_H(rsdc) = {
  let rsd = creg2reg_idx(rsdc);
  execute(ZBB_EXTOP(rsd, rsd,  SEXTH))
}

/* ****************************************************************** */

union clause instruction = C_ZEXT_W : (cregidx)

mapping clause encdec_compressed = C_ZEXT_W(rsdc)
  <-> 0b100 @ 0b111 @ encdec_creg(rsdc) @ 0b11 @ 0b100 @ 0b01
  when currentlyEnabled(Ext_Zcb) & currentlyEnabled(Ext_Zba) & xlen == 64

mapping clause assembly = C_ZEXT_W(rsdc) <->
  "c.zext.w" ^ spc() ^ creg_name(rsdc)

function clause execute C_ZEXT_W(rsdc) = {
  let rsd = creg2reg_idx(rsdc);
  execute (ZBA_RTYPEUW(zreg, rsd, rsd, 0b00))
}

/* ****************************************************************** */

union clause instruction = C_NOT : (cregidx)

mapping clause encdec_compressed = C_NOT(rsdc)
  <-> 0b100 @ 0b111 @ encdec_creg(rsdc) @ 0b11 @ 0b101 @ 0b01
  when currentlyEnabled(Ext_Zcb)

mapping clause assembly = C_NOT(rsdc) <->
  "c.not" ^ spc() ^ creg_name(rsdc)

function clause execute C_NOT(rsdc) = {
  let r = creg2reg_idx(rsdc);
  X(r) = ~(X(r));
  RETIRE_SUCCESS
}

/* ****************************************************************** */

union clause instruction = C_MUL : (cregidx, cregidx)

mapping clause encdec_compressed = C_MUL(rsdc, rsc2)
  <-> 0b100 @ 0b111 @ encdec_creg(rsdc) @ 0b10 @ encdec_creg(rsc2) @ 0b01
  when currentlyEnabled(Ext_Zcb) & (currentlyEnabled(Ext_M) | currentlyEnabled(Ext_Zmmul))

mapping clause assembly = C_MUL(rsdc, rsc2) <->
  "c.mul" ^ spc() ^ creg_name(rsdc) ^ sep() ^ creg_name(rsc2)

function clause execute C_MUL(rsdc, rsc2) = {
  let rd = creg2reg_idx(rsdc);
  let rs = creg2reg_idx(rsc2);
  execute(MUL(rs, rd, rd, struct { high = false, signed_rs1 = true, signed_rs2 = true }))
}
