// =======================================================================================
// This Sail RISC-V architecture model, comprising all files and
// directories except where otherwise noted is subject the BSD
// two-clause license in the LICENSE file.
//
// SPDX-License-Identifier: BSD-2-Clause
// =======================================================================================

function clause currentlyEnabled(Ext_Zcd) = hartSupports(Ext_Zcd) & currentlyEnabled(Ext_D) & currentlyEnabled(Ext_Zca) & (currentlyEnabled(Ext_C) | not(hartSupports(Ext_C)))

union clause instruction = C_FLDSP : (bits(6), fregidx)

mapping clause encdec_compressed = C_FLDSP(uimm, rd)
  <-> 0b001 @ uimm[2] : bits(1) @ encdec_freg(rd) @ uimm[1..0] : bits(2) @ uimm[5..3] : bits(3) @ 0b10
  when currentlyEnabled(Ext_Zcd)

function clause execute C_FLDSP(uimm, rd) = {
  let imm : bits(12) = zero_extend(uimm @ 0b000);
  execute(LOAD_FP(imm, sp, rd, 8))
}

mapping clause assembly = C_FLDSP(uimm, rd)
  <-> "c.fldsp" ^ spc() ^ freg_name(rd) ^ sep() ^ hex_bits_9(uimm @ 0b000) ^ "(" ^ sp_reg_name() ^ ")"

// *****************************************************************
union clause instruction = C_FSDSP : (bits(6), fregidx)

mapping clause encdec_compressed = C_FSDSP(uimm, rs2)
  <-> 0b101 @ uimm[2..0] : bits(3) @ uimm[5..3] : bits(3) @ encdec_freg(rs2) @ 0b10
  when currentlyEnabled(Ext_Zcd)

function clause execute C_FSDSP(uimm, rs2) = {
  let imm : bits(12) = zero_extend(uimm @ 0b000);
  execute(STORE_FP(imm, rs2, sp, 8))
}

mapping clause assembly = C_FSDSP(uimm, rs2)
  <-> "c.fsdsp" ^ spc() ^ freg_name(rs2) ^ sep() ^ hex_bits_9(uimm @ 0b000) ^ "(" ^ sp_reg_name() ^ ")"

// *****************************************************************
union clause instruction = C_FLD : (bits(5), cregidx, cfregidx)

mapping clause encdec_compressed = C_FLD(uimm, rs1, rd)
  <-> 0b001 @ uimm[2..0] : bits(3) @ encdec_creg(rs1) @ uimm[4..3] : bits(2) @ encdec_cfreg(rd) @ 0b00
  when currentlyEnabled(Ext_Zcd)

function clause execute C_FLD(uimm, rsc, rdc) = {
  let imm : bits(12) = zero_extend(uimm @ 0b000);
  let rd = cfregidx_to_fregidx(rdc);
  let rs = creg2reg_idx(rsc);
  execute(LOAD_FP(imm, rs, rd, 8))
}

mapping clause assembly = C_FLD(uimm, rsc, rdc)
  <-> "c.fld" ^ spc() ^ cfreg_name(rdc) ^ sep() ^ hex_bits_8(uimm @ 0b000) ^ "(" ^ creg_name(rsc) ^ ")"

// *****************************************************************
union clause instruction = C_FSD : (bits(5), cregidx, cfregidx)

mapping clause encdec_compressed = C_FSD(uimm, rs1, rs2)
  <-> 0b101 @ uimm[2..0] : bits(3) @ encdec_creg(rs1) @ uimm[4..3] : bits(2) @ encdec_cfreg(rs2) @ 0b00
  when currentlyEnabled(Ext_Zcd)

function clause execute C_FSD(uimm, rsc1, rsc2) = {
  let imm : bits(12) = zero_extend(uimm @ 0b000);
  let rs1 = creg2reg_idx(rsc1);
  let rs2 = cfregidx_to_fregidx(rsc2);
  execute(STORE_FP(imm, rs2, rs1, 8))
}

mapping clause assembly = C_FSD(uimm, rsc1, rsc2)
  <-> "c.fsd" ^ spc() ^ cfreg_name(rsc2) ^ sep() ^ hex_bits_8(uimm @ 0b000) ^ "(" ^ creg_name(rsc1) ^ ")"
