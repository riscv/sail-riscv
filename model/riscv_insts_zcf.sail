/*=======================================================================================*/
/*  This Sail RISC-V architecture model, comprising all files and                        */
/*  directories except where otherwise noted is subject the BSD                          */
/*  two-clause license in the LICENSE file.                                              */
/*                                                                                       */
/*  SPDX-License-Identifier: BSD-2-Clause                                                */
/*=======================================================================================*/

function clause currentlyEnabled(Ext_Zcf) = hartSupports(Ext_Zcf) & currentlyEnabled(Ext_F) & currentlyEnabled(Ext_Zca) & (currentlyEnabled(Ext_C) | not(hartSupports(Ext_C)))

union clause ast = C_FLWSP : (bits(6), fregidx)

mapping clause encdec_compressed = C_FLWSP(ui76 @ ui5 @ ui42, rd)
  <-> 0b011 @ ui5 : bits(1) @ encdec_freg(rd) @ ui42 : bits(3) @ ui76 : bits(2) @ 0b10
  when currentlyEnabled(Ext_Zcf)

function clause execute (C_FLWSP(imm, rd)) = {
  let imm : bits(12) = zero_extend(imm @ 0b00);
  execute(LOAD_FP(imm, sp, rd, WORD))
}

mapping clause assembly = C_FLWSP(imm, rd)
  <-> "c.flwsp" ^ spc() ^ freg_name(rd) ^ sep() ^ hex_bits_6(imm) ^ "(" ^ reg_name_func(sp) ^ ")"
  when xlen == 32

/* ****************************************************************** */
union clause ast = C_FSWSP : (bits(6), fregidx)

mapping clause encdec_compressed = C_FSWSP(ui76 @ ui52, rs2)
  <-> 0b111 @ ui52 : bits(4) @ ui76 : bits(2) @ encdec_freg(rs2) @ 0b10
  when currentlyEnabled(Ext_Zcf)

function clause execute (C_FSWSP(uimm, rs2)) = {
  let imm : bits(12) = zero_extend(uimm @ 0b00);
  execute(STORE_FP(imm, rs2, sp, WORD))
}

mapping clause assembly = C_FSWSP(uimm, rs2)
  <-> "c.fswsp" ^ spc() ^ freg_name(rs2) ^ sep() ^ hex_bits_6(uimm) ^ "(" ^ reg_name_func(sp) ^ ")"
  when xlen == 32

/* ****************************************************************** */
union clause ast = C_FLW : (bits(5), cregidx, cregidx)

mapping clause encdec_compressed = C_FLW(ui6 @ ui53 @ ui2, rs1, rd)
  <-> 0b011 @ ui53 : bits(3) @ encdec_creg(rs1) @ ui2 : bits(1) @ ui6 : bits(1) @ encdec_creg(rd) @ 0b00
  when currentlyEnabled(Ext_Zcf)

function clause execute (C_FLW(uimm, rsc, rdc)) = {
  let imm : bits(12) = zero_extend(uimm @ 0b00);
  let rd = cregidx_to_fregidx(rdc);
  let rs = creg2reg_idx(rsc);
  execute(LOAD_FP(imm, rs, rd, WORD))
}

mapping clause assembly = C_FLW(uimm, rsc, rdc)
  <-> "c.flw" ^ spc() ^ creg_name(rdc) ^ sep() ^ hex_bits_7(uimm @ 0b00) ^ "(" ^ creg_name(rsc) ^ ")"
  when xlen == 32

/* ****************************************************************** */
union clause ast = C_FSW : (bits(5), cregidx, cregidx)

mapping clause encdec_compressed = C_FSW(ui6 @ ui53 @ ui2, rs1, rs2)
  <-> 0b111 @ ui53 : bits(3) @ encdec_creg(rs1) @ ui2 : bits(1) @ ui6 : bits(1) @ encdec_creg(rs2) @ 0b00
  when currentlyEnabled(Ext_Zcf)

function clause execute (C_FSW(uimm, rsc1, rsc2)) = {
  let imm : bits(12) = zero_extend(uimm @ 0b00);
  let rs1 = creg2reg_idx(rsc1);
  let rs2 = cregidx_to_fregidx(rsc2);
  execute(STORE_FP(imm, rs2, rs1, WORD))
}

mapping clause assembly = C_FSW(uimm, rsc1, rsc2)
  <-> "c.fsw" ^ spc() ^ creg_name(rsc2) ^ sep() ^ hex_bits_7(uimm @ 0b00) ^ "(" ^ creg_name(rsc1) ^ ")"
  when xlen == 32
