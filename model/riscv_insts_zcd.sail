/*=======================================================================================*/
/*  This Sail RISC-V architecture model, comprising all files and                        */
/*  directories except where otherwise noted is subject the BSD                          */
/*  two-clause license in the LICENSE file.                                              */
/*                                                                                       */
/*  SPDX-License-Identifier: BSD-2-Clause                                                */
/*=======================================================================================*/

function clause currentlyEnabled(Ext_Zcd) = hartSupports(Ext_Zcd) & currentlyEnabled(Ext_D) & currentlyEnabled(Ext_Zca) & not(currentlyEnabled(Ext_Zcmt)) & (currentlyEnabled(Ext_C) | not(hartSupports(Ext_C)))

union clause ast = C_FLDSP : (bits(6), fregidx)

mapping clause encdec_compressed = C_FLDSP(ui86 @ ui5 @ ui43, rd)
  <-> 0b001 @ ui5 : bits(1) @ encdec_freg(rd) @ ui43 : bits(2) @ ui86 : bits(3) @ 0b10
  when currentlyEnabled(Ext_Zcd)

function clause execute (C_FLDSP(uimm, rd)) = {
  let imm : bits(12) = zero_extend(uimm @ 0b000);
  execute(LOAD_FP(imm, sp, rd, DOUBLE))
}

mapping clause assembly = C_FLDSP(uimm, rd)
      if (xlen == 32 | xlen == 64)
  <-> "c.fldsp" ^ spc() ^ freg_name(rd) ^ sep() ^ hex_bits_6(uimm)
      if (xlen == 32 | xlen == 64)

/* ****************************************************************** */
union clause ast = C_FSDSP : (bits(6), fregidx)

mapping clause encdec_compressed = C_FSDSP(ui86 @ ui53, rs2)
  <-> 0b101 @ ui53 : bits(3) @ ui86 : bits(3) @ encdec_freg(rs2) @ 0b10
  when currentlyEnabled(Ext_Zcd)

function clause execute (C_FSDSP(uimm, rs2)) = {
  let imm : bits(12) = zero_extend(uimm @ 0b000);
  execute(STORE_FP(imm, rs2, sp, DOUBLE))
}

mapping clause assembly = C_FSDSP(uimm, rs2)
      if (xlen == 32 | xlen == 64)
  <-> "c.fsdsp" ^ spc() ^ freg_name(rs2) ^ sep() ^ hex_bits_6(uimm)
      if (xlen == 32 | xlen == 64)

/* ****************************************************************** */
union clause ast = C_FLD : (bits(5), cregidx, cregidx)

mapping clause encdec_compressed = C_FLD(ui76 @ ui53, rs1, rd)
  <-> 0b001 @ ui53 : bits(3) @ encdec_creg(rs1) @ ui76 : bits(2) @ encdec_creg(rd) @ 0b00
  when currentlyEnabled(Ext_Zcd)

function clause execute (C_FLD(uimm, rsc, rdc)) = {
  let imm : bits(12) = zero_extend(uimm @ 0b000);
  let rd = cregidx_to_fregidx(rdc);
  let rs = creg2reg_idx(rsc);
  execute(LOAD_FP(imm, rs, rd, DOUBLE))
}

mapping clause assembly = C_FLD(uimm, rsc, rdc)
      if (xlen == 32 | xlen == 64)
  <-> "c.fld" ^ spc() ^ creg_name(rdc) ^ sep() ^ creg_name(rsc) ^ sep() ^ hex_bits_8(uimm @ 0b000)
      if (xlen == 32 | xlen == 64)

/* ****************************************************************** */
union clause ast = C_FSD : (bits(5), cregidx, cregidx)

mapping clause encdec_compressed = C_FSD(ui76 @ ui53, rs1, rs2)
  <-> 0b101 @ ui53 : bits(3) @ encdec_creg(rs1) @ ui76 : bits(2) @ encdec_creg(rs2) @ 0b00
  when currentlyEnabled(Ext_Zcd)

function clause execute (C_FSD(uimm, rsc1, rsc2)) = {
  let imm : bits(12) = zero_extend(uimm @ 0b000);
  let rs1 = creg2reg_idx(rsc1);
  let rs2 = cregidx_to_fregidx(rsc2);
  execute(STORE_FP(imm, rs2, rs1, DOUBLE))
}

mapping clause assembly = C_FSD(uimm, rsc1, rsc2)
      if (xlen == 32 | xlen == 64)
  <-> "c.fsd" ^ spc() ^ creg_name(rsc1) ^ sep() ^ creg_name(rsc2) ^ sep() ^ hex_bits_8(uimm @ 0b000)
      if (xlen == 32 | xlen == 64)
