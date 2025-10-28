// =======================================================================================
// This Sail RISC-V architecture model, comprising all files and
// directories except where otherwise noted is subject the BSD
// two-clause license in the LICENSE file.
//
// SPDX-License-Identifier: BSD-2-Clause
// =======================================================================================

// ********************************************************************
// This file specifies the compressed instructions in the 'Zca' extension.

// Instead of checking for Zca in every execute clause, we currently do
// the check in one place in the fetch-execute logic.

// *****************************************************************
union clause instruction = C_NOP : (bits(6))

mapping clause encdec_compressed = C_NOP(imm)
  <-> 0b000 @ imm[5] : bits(1) @ 0b00000 @ imm[4..0] : bits(5) @ 0b01
  when currentlyEnabled(Ext_Zca)

function clause execute C_NOP(_) = RETIRE_SUCCESS

// imm=0 corresponds to `c.nop` without an argument (`c.nop 0` is not legal).
mapping clause assembly = C_NOP(0b000000)
  <-> "c.nop"

mapping clause assembly = C_NOP(imm)
  <-> "c.nop" ^ spc() ^ hex_bits_signed_6(imm)
  when imm != zeros()

// *****************************************************************
union clause instruction = C_ADDI4SPN : (cregidx, bits(8))

$[wavedrom "C.ADDI4SPN _ _ _ _ dest C0"]
mapping clause encdec_compressed = C_ADDI4SPN(rd, nz96 @ nz54 @ nz3 @ nz2)
  <-> 0b000 @ nz54 : bits(2) @ nz96 : bits(4) @ nz2 : bits(1) @ nz3 : bits(1) @ encdec_creg(rd) @ 0b00
  when nz96 @ nz54 @ nz3 @ nz2 != 0b00000000 & currentlyEnabled(Ext_Zca)

// See https://github.com/rems-project/sail/issues/1540
//mapping clause encdec_compressed = C_ADDI4SPN(rd, nzimm)
//  <-> 0b000 @ nzimm[3..2] : bits(2) @ nzimm[7..4] : bits(4) @ nzimm[0] : bits(1) @ nzimm[1] : bits(1) @ encdec_creg(rd) @ 0b00
//  when (nzimm != 0b00000000) & currentlyEnabled(Ext_Zca)

function clause execute C_ADDI4SPN(rdc, nzimm) = {
  let imm : bits(12) = (0b00 @ nzimm @ 0b00);
  let rd = creg2reg_idx(rdc);
  execute(ITYPE(imm, sp, rd, ADDI))
}

mapping clause assembly = C_ADDI4SPN(rdc, nzimm)
  <-> "c.addi4spn" ^ spc() ^ creg_name(rdc) ^ sep() ^ sp_reg_name() ^ sep() ^ hex_bits_10(nzimm @ 0b00)
  when nzimm != 0b00000000

// *****************************************************************
union clause instruction = C_LW : (bits(5), cregidx, cregidx)

mapping clause encdec_compressed = C_LW(uimm, rs1, rd)
  <-> 0b010 @ uimm[3..1] : bits(3) @ encdec_creg(rs1) @ uimm[0] : bits(1) @ uimm[4] : bits(1) @ encdec_creg(rd) @ 0b00
  when currentlyEnabled(Ext_Zca)

function clause execute C_LW(uimm, rsc, rdc) = {
  let imm : bits(12) = zero_extend(uimm @ 0b00);
  let rd = creg2reg_idx(rdc);
  let rs = creg2reg_idx(rsc);
  execute(LOAD(imm, rs, rd, false, 4))
}

mapping clause assembly = C_LW(uimm, rsc, rdc)
  <-> "c.lw" ^ spc() ^ creg_name(rdc) ^ sep() ^ hex_bits_7(uimm @ 0b00) ^ "(" ^ creg_name(rsc) ^ ")"

// *****************************************************************
union clause instruction = C_LD : (bits(5), cregidx, cregidx)

mapping clause encdec_compressed = C_LD(uimm, rs1, rd)
  <-> 0b011 @ uimm[2..0] : bits(3) @ encdec_creg(rs1) @ uimm[4..3] : bits(2) @ encdec_creg(rd) @ 0b00
  when xlen == 64 & currentlyEnabled(Ext_Zca)

function clause execute C_LD(uimm, rsc, rdc) = {
  let imm : bits(12) = zero_extend(uimm @ 0b000);
  let rd = creg2reg_idx(rdc);
  let rs = creg2reg_idx(rsc);
  execute(LOAD(imm, rs, rd, false, 8))
}

mapping clause assembly = C_LD(uimm, rsc, rdc)
  <-> "c.ld" ^ spc() ^ creg_name(rdc) ^ sep() ^ hex_bits_8(uimm @ 0b000) ^ "(" ^ creg_name(rsc) ^ ")"
  when xlen == 64

// *****************************************************************
union clause instruction = C_SW : (bits(5), cregidx, cregidx)

mapping clause encdec_compressed = C_SW(uimm, rs1, rs2)
  <-> 0b110 @ uimm[3..1] : bits(3) @ encdec_creg(rs1) @ uimm[0] : bits(1) @ uimm[4] : bits(1) @ encdec_creg(rs2) @ 0b00
  when currentlyEnabled(Ext_Zca)

function clause execute C_SW(uimm, rsc1, rsc2) = {
  let imm : bits(12) = zero_extend(uimm @ 0b00);
  let rs1 = creg2reg_idx(rsc1);
  let rs2 = creg2reg_idx(rsc2);
  execute(STORE(imm, rs2, rs1, 4))
}

mapping clause assembly = C_SW(uimm, rsc1, rsc2)
  <-> "c.sw" ^ spc() ^ creg_name(rsc2) ^ sep() ^ hex_bits_7(uimm @ 0b00) ^ "(" ^ creg_name(rsc1) ^ ")"

// *****************************************************************
union clause instruction = C_SD : (bits(5), cregidx, cregidx)

mapping clause encdec_compressed = C_SD(uimm, rs1, rs2)
  <-> 0b111 @ uimm[2..0] : bits(3) @ encdec_creg(rs1) @ uimm[4..3] : bits(2) @ encdec_creg(rs2) @ 0b00
  when xlen == 64 & currentlyEnabled(Ext_Zca)

function clause execute C_SD(uimm, rsc1, rsc2) = {
  let imm : bits(12) = zero_extend(uimm @ 0b000);
  let rs1 = creg2reg_idx(rsc1);
  let rs2 = creg2reg_idx(rsc2);
  execute(STORE(imm, rs2, rs1, 8))
}

mapping clause assembly = C_SD(uimm, rsc1, rsc2)
  <-> "c.sd" ^ spc() ^ creg_name(rsc2) ^ sep() ^ hex_bits_8(uimm @ 0b000) ^ "(" ^ creg_name(rsc1) ^ ")"
  when xlen == 64

// *****************************************************************
union clause instruction = C_ADDI : (bits(6), regidx)

// Code points with rsd=x0 are c.nop.
// c.addi with imm=0 are hints.
mapping clause encdec_compressed = C_ADDI(imm, rsd)
  <-> 0b000 @ imm[5] : bits(1) @ encdec_reg(rsd) @ imm[4..0] : bits(5) @ 0b01
  when rsd != zreg & currentlyEnabled(Ext_Zca)

function clause execute C_ADDI(imm, rsd) = {
  let imm : bits(12) = sign_extend(imm);
  execute(ITYPE(imm, rsd, rsd, ADDI))
}

mapping clause assembly = C_ADDI(imm, rsd)
  <-> "c.addi" ^ spc() ^ reg_name(rsd) ^ sep() ^ hex_bits_signed_6(imm)
  when rsd != zreg

// *****************************************************************
union clause instruction = C_JAL : (bits(11))

mapping clause encdec_compressed = C_JAL(imm)
  <-> 0b001 @ imm[10] : bits(1) @ imm[3] : bits(1) @ imm[8..7] : bits(2) @ imm[9] : bits(1) @ imm[5] : bits(1) @ imm[6] : bits(1) @ imm[2..0] : bits(3) @ imm[4] : bits(1) @ 0b01
  when xlen == 32 & currentlyEnabled(Ext_Zca)

function clause execute C_JAL(imm) =
  execute(JAL(sign_extend(imm @ 0b0), ra))

mapping clause assembly = C_JAL(imm)
  <-> "c.jal" ^ spc() ^ hex_bits_signed_12(imm @ 0b0)
  when xlen == 32

// *****************************************************************
union clause instruction = C_ADDIW : (bits(6), regidx)

mapping clause encdec_compressed = C_ADDIW(imm, rsd)
  <-> 0b001 @ imm[5] : bits(1) @ encdec_reg(rsd) @ imm[4..0] : bits(5) @ 0b01
  when rsd != zreg & xlen == 64 & currentlyEnabled(Ext_Zca)

function clause execute C_ADDIW(imm, rsd) =
  execute(ADDIW(sign_extend(imm), rsd, rsd))

mapping clause assembly = C_ADDIW(imm, rsd)
  <-> "c.addiw" ^ spc() ^ reg_name(rsd) ^ sep() ^ hex_bits_signed_6(imm)
  when xlen == 64

// *****************************************************************
union clause instruction = C_LI : (bits(6), regidx)

// c.li with rd=x0 are hints.
mapping clause encdec_compressed = C_LI(imm, rd)
  <-> 0b010 @ imm[5] : bits(1) @ encdec_reg(rd) @ imm[4..0] : bits(5) @ 0b01
  when currentlyEnabled(Ext_Zca)

function clause execute C_LI(imm, rd) = {
  let imm : bits(12) = sign_extend(imm);
  execute(ITYPE(imm, zreg, rd, ADDI))
}

mapping clause assembly = C_LI(imm, rd)
  <-> "c.li" ^ spc() ^ reg_name(rd) ^ sep() ^ hex_bits_signed_6(imm)

// *****************************************************************
union clause instruction = C_ADDI16SP : (bits(6))

mapping clause encdec_compressed = C_ADDI16SP(nzi9 @ nzi87 @ nzi6 @ nzi5 @ nzi4)
  <-> 0b011 @ nzi9 : bits(1) @ /* x2 */ 0b00010 @ nzi4 : bits(1) @ nzi6 : bits(1) @ nzi87 : bits(2) @ nzi5 : bits(1) @ 0b01
  when nzi9 @ nzi87 @ nzi6 @ nzi5 @ nzi4 != 0b000000 & currentlyEnabled(Ext_Zca)

// See https://github.com/rems-project/sail/issues/1540
//mapping clause encdec_compressed = C_ADDI16SP(nzimm)
//  <-> 0b011 @ nzimm[5] : bits(1) @ /* x2 */ 0b00010 @ nzimm[0] : bits(1) @ nzimm[2] : bits(1) @ nzimm[4..3] : bits(2) @ nzimm[1] : bits(1) @ 0b01
//  when nzimm != 0b000000 & currentlyEnabled(Ext_Zca)

function clause execute C_ADDI16SP(imm) = {
  let imm : bits(12) = sign_extend(imm @ 0x0);
  execute(ITYPE(imm, sp, sp, ADDI))
}

mapping clause assembly = C_ADDI16SP(imm)
  <-> "c.addi16sp" ^ spc() ^ sp_reg_name() ^ sep() ^ hex_bits_signed_10(imm @ 0x0)
  when imm != 0b000000

// *****************************************************************
union clause instruction = C_LUI : (bits(6), regidx)

// c.lui with rd=x0 are hints.
// Code points with rd=x2 are c.addi16sp.
// Code points with imm=0 are reserved.
mapping clause encdec_compressed = C_LUI(imm17 @ imm1612, rd)
  <-> 0b011 @ imm17 : bits(1) @ encdec_reg(rd) @ imm1612 : bits(5) @ 0b01
  when rd != sp & imm17 @ imm1612 != 0b000000 & currentlyEnabled(Ext_Zca)

// See https://github.com/rems-project/sail/issues/1540
//mapping clause encdec_compressed = C_LUI(imm, rd)
//  <-> 0b011 @ imm[5] : bits(1) @ encdec_reg(rd) @ imm[4..0] : bits(5) @ 0b01
//  when rd != sp & imm != 0b000000 & currentlyEnabled(Ext_Zca)

function clause execute C_LUI(imm, rd) = {
  let res : bits(20) = sign_extend(imm);
  execute(UTYPE(res, rd, LUI))
}

mapping clause assembly = C_LUI(imm, rd)
  <-> "c.lui" ^ spc() ^ reg_name(rd) ^ sep() ^ hex_bits_signed_6(imm)
  when rd != sp & imm != 0b000000

// *****************************************************************
union clause instruction = C_SRLI : (bits(6), cregidx)

// c.srli with shamt=0 are hints.
mapping clause encdec_compressed = C_SRLI(shamt5 @ shamt40, rsd)
  <-> 0b100 @ shamt5 : bits(1) @ 0b00 @ encdec_creg(rsd) @ shamt40 : bits(5) @ 0b01
  when (xlen == 64 | shamt5 == 0b0) & currentlyEnabled(Ext_Zca)

// See https://github.com/rems-project/sail/issues/1540
//mapping clause encdec_compressed = C_SRLI(shamt, rsd)
//  <-> 0b100 @ shamt[5] : bits(1) @ 0b00 @ encdec_creg(rsd) @ shamt[4..0] : bits(5) @ 0b01
//  when (xlen == 64 | shamt[5] == 0b0) & currentlyEnabled(Ext_Zca)

function clause execute C_SRLI(shamt, rsd) = {
  let rsd = creg2reg_idx(rsd);
  execute(SHIFTIOP(shamt, rsd, rsd, SRLI))
}

mapping clause assembly = C_SRLI(shamt, rsd)
  <-> "c.srli" ^ spc() ^ creg_name(rsd) ^ sep() ^ hex_bits_6(shamt)

// *****************************************************************
union clause instruction = C_SRAI : (bits(6), cregidx)

// c.srai with shamt=0 are hints.
mapping clause encdec_compressed = C_SRAI(shamt5 @ shamt40, rsd)
  <-> 0b100 @ shamt5 : bits(1) @ 0b01 @ encdec_creg(rsd) @ shamt40 : bits(5) @ 0b01
  when (xlen == 64 | shamt5 == 0b0) & currentlyEnabled(Ext_Zca)

// See https://github.com/rems-project/sail/issues/1540
//mapping clause encdec_compressed = C_SRAI(shamt, rsd)
//  <-> 0b100 @ shamt[5] : bits(1) @ 0b01 @ encdec_creg(rsd) @ shamt[4..0] : bits(5) @ 0b01
//  when (xlen == 64 | shamt[5] == 0b0) & currentlyEnabled(Ext_Zca)

function clause execute C_SRAI(shamt, rsd) = {
  let rsd = creg2reg_idx(rsd);
  execute(SHIFTIOP(shamt, rsd, rsd, SRAI))
}

mapping clause assembly = C_SRAI(shamt, rsd)
  <-> "c.srai" ^ spc() ^ creg_name(rsd) ^ sep() ^ hex_bits_6(shamt)

// *****************************************************************
union clause instruction = C_ANDI : (bits(6), cregidx)

$[wavedrom "C.ANDI imm[5] C.ANDI dest imm[4:0] C1"]
mapping clause encdec_compressed = C_ANDI(imm, rsd)
  <-> 0b100 @ imm[5] : bits(1) @ 0b10 @ encdec_creg(rsd) @ imm[4..0] : bits(5) @ 0b01
  when currentlyEnabled(Ext_Zca)

function clause execute C_ANDI(imm, rsd) = {
  let rsd = creg2reg_idx(rsd);
  execute(ITYPE(sign_extend(imm), rsd, rsd, ANDI))
}

mapping clause assembly = C_ANDI(imm, rsd)
  <-> "c.andi" ^ spc() ^ creg_name(rsd) ^ sep() ^ hex_bits_signed_6(imm)

// *****************************************************************
union clause instruction = C_SUB : (cregidx, cregidx)

mapping clause encdec_compressed = C_SUB(rsd, rs2)
  <-> 0b100 @ 0b0 @ 0b11 @ encdec_creg(rsd) @ 0b00 @ encdec_creg(rs2) @ 0b01
  when currentlyEnabled(Ext_Zca)

function clause execute C_SUB(rsd, rs2) = {
  let rsd = creg2reg_idx(rsd);
  let rs2 = creg2reg_idx(rs2);
  execute(RTYPE(rs2, rsd, rsd, SUB))
}

mapping clause assembly = C_SUB(rsd, rs2)
  <-> "c.sub" ^ spc() ^ creg_name(rsd) ^ sep() ^ creg_name(rs2)

// *****************************************************************
union clause instruction = C_XOR : (cregidx, cregidx)

mapping clause encdec_compressed = C_XOR(rsd, rs2)
  <-> 0b100 @ 0b0 @ 0b11 @ encdec_creg(rsd) @ 0b01 @ encdec_creg(rs2) @ 0b01
  when currentlyEnabled(Ext_Zca)

function clause execute C_XOR(rsd, rs2) = {
  let rsd = creg2reg_idx(rsd);
  let rs2 = creg2reg_idx(rs2);
  execute(RTYPE(rs2, rsd, rsd, XOR))
}

mapping clause assembly = C_XOR(rsd, rs2)
  <-> "c.xor" ^ spc() ^ creg_name(rsd) ^ sep() ^ creg_name(rs2)

// *****************************************************************
union clause instruction = C_OR : (cregidx, cregidx)

mapping clause encdec_compressed = C_OR(rsd, rs2)
  <-> 0b100 @ 0b0 @ 0b11 @ encdec_creg(rsd) @ 0b10 @ encdec_creg(rs2) @ 0b01
  when currentlyEnabled(Ext_Zca)

function clause execute C_OR(rsd, rs2) = {
  let rsd = creg2reg_idx(rsd);
  let rs2 = creg2reg_idx(rs2);
  execute(RTYPE(rs2, rsd, rsd, OR))
}

mapping clause assembly = C_OR(rsd, rs2)
  <-> "c.or" ^ spc() ^ creg_name(rsd) ^ sep() ^ creg_name(rs2)

// *****************************************************************
union clause instruction = C_AND : (cregidx, cregidx)

mapping clause encdec_compressed = C_AND(rsd, rs2)
  <-> 0b100 @ 0b0 @ 0b11 @ encdec_creg(rsd) @ 0b11 @ encdec_creg(rs2) @ 0b01
  when currentlyEnabled(Ext_Zca)

function clause execute C_AND(rsd, rs2) = {
  let rsd = creg2reg_idx(rsd);
  let rs2 = creg2reg_idx(rs2);
  execute(RTYPE(rs2, rsd, rsd, AND))
}

mapping clause assembly = C_AND(rsd, rs2)
  <-> "c.and" ^ spc() ^ creg_name(rsd) ^ sep() ^ creg_name(rs2)

// *****************************************************************
union clause instruction = C_SUBW : (cregidx, cregidx)

mapping clause encdec_compressed = C_SUBW(rsd, rs2)
  <-> 0b100 @ 0b1 @ 0b11 @ encdec_creg(rsd) @ 0b00 @ encdec_creg(rs2) @ 0b01
  when xlen == 64 & currentlyEnabled(Ext_Zca)

function clause execute C_SUBW(rsd, rs2) = {
  let rsd = creg2reg_idx(rsd);
  let rs2 = creg2reg_idx(rs2);
  execute(RTYPEW(rs2, rsd, rsd, SUBW))
}

mapping clause assembly = C_SUBW(rsd, rs2)
  <-> "c.subw" ^ spc() ^ creg_name(rsd) ^ sep() ^ creg_name(rs2)
  when xlen == 64

// *****************************************************************
union clause instruction = C_ADDW : (cregidx, cregidx)

mapping clause encdec_compressed = C_ADDW(rsd, rs2)
  <-> 0b100 @ 0b1 @ 0b11 @ encdec_creg(rsd) @ 0b01 @ encdec_creg(rs2) @ 0b01
  when xlen == 64 & currentlyEnabled(Ext_Zca)

function clause execute C_ADDW(rsd, rs2) = {
  let rsd = creg2reg_idx(rsd);
  let rs2 = creg2reg_idx(rs2);
  execute(RTYPEW(rs2, rsd, rsd, ADDW))
}

mapping clause assembly = C_ADDW(rsd, rs2)
  <-> "c.addw" ^ spc() ^ creg_name(rsd) ^ sep() ^ creg_name(rs2)
  when xlen == 64

// *****************************************************************
union clause instruction = C_J : (bits(11))

mapping clause encdec_compressed = C_J(imm)
  <-> 0b101 @ imm[10] : bits(1) @ imm[3] : bits(1) @ imm[8..7] : bits(2) @ imm[9] : bits(1) @ imm[5] : bits(1) @ imm[6] : bits(1) @ imm[2..0] : bits(3) @ imm[4] : bits(1) @ 0b01
  when currentlyEnabled(Ext_Zca)

function clause execute C_J(imm) =
  execute(JAL(sign_extend(imm @ 0b0), zreg))

mapping clause assembly = C_J(imm)
  <-> "c.j" ^ spc() ^ hex_bits_signed_12(imm @ 0b0)

// *****************************************************************
union clause instruction = C_BEQZ : (bits(8), cregidx)

mapping clause encdec_compressed = C_BEQZ(imm, rs)
  <-> 0b110 @ imm[7] : bits(1) @ imm[3..2] : bits(2) @ encdec_creg(rs) @ imm[6..5] : bits(2) @ imm[1..0] : bits(2) @ imm[4] : bits(1) @ 0b01
  when currentlyEnabled(Ext_Zca)

function clause execute C_BEQZ(imm, rs) =
  execute(BTYPE(sign_extend(imm @ 0b0), zreg, creg2reg_idx(rs), BEQ))

mapping clause assembly = C_BEQZ(imm, rs)
  <-> "c.beqz" ^ spc() ^ creg_name(rs) ^ sep() ^ hex_bits_signed_9(imm @ 0b0)

// *****************************************************************
union clause instruction = C_BNEZ : (bits(8), cregidx)

mapping clause encdec_compressed = C_BNEZ(imm, rs)
  <-> 0b111 @ imm[7] : bits(1) @ imm[3..2] : bits(2) @ encdec_creg(rs) @ imm[6..5] : bits(2) @ imm[1..0] : bits(2) @ imm[4] : bits(1) @ 0b01
  when currentlyEnabled(Ext_Zca)

function clause execute C_BNEZ(imm, rs) =
  execute(BTYPE(sign_extend(imm @ 0b0), zreg, creg2reg_idx(rs), BNE))

mapping clause assembly = C_BNEZ(imm, rs)
  <-> "c.bnez" ^ spc() ^ creg_name(rs) ^ sep() ^ hex_bits_signed_9(imm @ 0b0)

// *****************************************************************
union clause instruction = C_SLLI : (bits(6), regidx)

// c.slli with shamt=0 or rsd=x0 are hints.
$[wavedrom "C.SLLI shamt[5] dest!=0 shamt[4:0] C2"]
mapping clause encdec_compressed = C_SLLI(shamt5 @ shamt40, rsd)
  <-> 0b000 @ shamt5 : bits(1) @ encdec_reg(rsd) @ shamt40 : bits(5) @ 0b10
  when (xlen == 64 | shamt5 == 0b0) & currentlyEnabled(Ext_Zca)

// See https://github.com/rems-project/sail/issues/1540
//mapping clause encdec_compressed = C_SLLI(shamt, rsd)
//  <-> 0b000 @ shamt[5] : bits(1) @ encdec_reg(rsd) @ shamt[4..0] : bits(5) @ 0b10
//  when (xlen == 64 | shamt[5] == 0b0) & currentlyEnabled(Ext_Zca)

function clause execute C_SLLI(shamt, rsd) =
  execute(SHIFTIOP(shamt, rsd, rsd, SLLI))

mapping clause assembly = C_SLLI(shamt, rsd)
  <-> "c.slli" ^ spc() ^ reg_name(rsd) ^ sep() ^ hex_bits_6(shamt)

// *****************************************************************
union clause instruction = C_LWSP : (bits(6), regidx)

mapping clause encdec_compressed = C_LWSP(uimm, rd)
  <-> 0b010 @ uimm[3] : bits(1) @ encdec_reg(rd) @ uimm[2..0] : bits(3) @ uimm[5..4] : bits(2) @ 0b10
  when rd != zreg & currentlyEnabled(Ext_Zca)

function clause execute C_LWSP(uimm, rd) = {
  let imm : bits(12) = zero_extend(uimm @ 0b00);
  execute(LOAD(imm, sp, rd, false, 4))
}

mapping clause assembly = C_LWSP(uimm, rd)
  <-> "c.lwsp" ^ spc() ^ reg_name(rd) ^ sep() ^ hex_bits_8(uimm @ 0b00) ^ "(" ^ sp_reg_name() ^ ")"
  when rd != zreg

// *****************************************************************
union clause instruction = C_LDSP : (bits(6), regidx)

mapping clause encdec_compressed = C_LDSP(uimm, rd)
  <-> 0b011 @ uimm[2] : bits(1) @ encdec_reg(rd) @ uimm[1..0] : bits(2) @ uimm[5..3] : bits(3) @ 0b10
  when rd != zreg & xlen == 64 & currentlyEnabled(Ext_Zca)

function clause execute C_LDSP(uimm, rd) = {
  let imm : bits(12) = zero_extend(uimm @ 0b000);
  execute(LOAD(imm, sp, rd, false, 8))
}

mapping clause assembly = C_LDSP(uimm, rd)
  <-> "c.ldsp" ^ spc() ^ reg_name(rd) ^ sep() ^ hex_bits_9(uimm @ 0b000) ^ "(" ^ sp_reg_name() ^ ")"
  when rd != zreg & xlen == 64

// *****************************************************************
union clause instruction = C_SWSP : (bits(6), regidx)

mapping clause encdec_compressed = C_SWSP(uimm, rs2)
  <-> 0b110 @ uimm[3..0] : bits(4) @ uimm[5..4] : bits(2) @ encdec_reg(rs2) @ 0b10
  when currentlyEnabled(Ext_Zca)

function clause execute C_SWSP(uimm, rs2) = {
  let imm : bits(12) = zero_extend(uimm @ 0b00);
  execute(STORE(imm, rs2, sp, 4))
}

mapping clause assembly = C_SWSP(uimm, rs2)
  <-> "c.swsp" ^ spc() ^ reg_name(rs2) ^ sep() ^ hex_bits_8(uimm @ 0b00) ^ "(" ^ sp_reg_name() ^ ")"

// *****************************************************************
union clause instruction = C_SDSP : (bits(6), regidx)

mapping clause encdec_compressed = C_SDSP(uimm, rs2)
  <-> 0b111 @ uimm[2..0] : bits(3) @ uimm[5..3] : bits(3) @ encdec_reg(rs2) @ 0b10
  when xlen == 64 & currentlyEnabled(Ext_Zca)

function clause execute C_SDSP(uimm, rs2) = {
  let imm : bits(12) = zero_extend(uimm @ 0b000);
  execute(STORE(imm, rs2, sp, 8))
}

mapping clause assembly = C_SDSP(uimm, rs2)
  <-> "c.sdsp" ^ spc() ^ reg_name(rs2) ^ sep() ^ hex_bits_9(uimm @ 0b000) ^ "(" ^ sp_reg_name() ^ ")"
  when xlen == 64

// *****************************************************************
union clause instruction = C_JR : (regidx)

mapping clause encdec_compressed = C_JR(rs1)
  <-> 0b100 @ 0b0 @ encdec_reg(rs1) @ 0b00000 @ 0b10
  when rs1 != zreg & currentlyEnabled(Ext_Zca)

function clause execute C_JR(rs1) =
  execute(JALR(zeros(), rs1, zreg))

mapping clause assembly = C_JR(rs1)
  <-> "c.jr" ^ spc() ^ reg_name(rs1)
  when rs1 != zreg

// *****************************************************************
union clause instruction = C_JALR : (regidx)

mapping clause encdec_compressed = C_JALR(rs1)
  <-> 0b100 @ 0b1 @ encdec_reg(rs1) @ 0b00000 @ 0b10
  when rs1 != zreg & currentlyEnabled(Ext_Zca)

function clause execute C_JALR(rs1) =
  execute(JALR(zeros(), rs1, ra))

mapping clause assembly = C_JALR(rs1)
  <-> "c.jalr" ^ spc() ^ reg_name(rs1)
  when rs1 != zreg

// *****************************************************************
union clause instruction = C_MV : (regidx, regidx)

// Code points with rs2=0 are c.jr.
// c.mv with rd=x0 are hints.
mapping clause encdec_compressed = C_MV(rd, rs2)
  <-> 0b100 @ 0b0 @ encdec_reg(rd) @ encdec_reg(rs2) @ 0b10
  when rs2 != zreg & currentlyEnabled(Ext_Zca)

function clause execute C_MV(rd, rs2) =
  execute(RTYPE(rs2, zreg, rd, ADD))

mapping clause assembly = C_MV(rd, rs2)
  <-> "c.mv" ^ spc() ^ reg_name(rd) ^ sep() ^ reg_name(rs2)
  when rs2 != zreg

// *****************************************************************
union clause instruction = C_EBREAK : unit

$[wavedrom "C.EBREAK 0 C2"]
mapping clause encdec_compressed = C_EBREAK()
  <-> 0b1001 @ 0b0000000000 @ 0b10
  when currentlyEnabled(Ext_Zca)

function clause execute C_EBREAK() =
  execute(EBREAK())

mapping clause assembly = C_EBREAK() <-> "c.ebreak"

// *****************************************************************
union clause instruction = C_ADD : (regidx, regidx)

// Code points with rs2=x0 are c.jalr/c.ebreak.
// c.add with rsd=x0 are hints.
mapping clause encdec_compressed = C_ADD(rsd, rs2)
  <-> 0b100 @ 0b1 @ encdec_reg(rsd) @ encdec_reg(rs2) @ 0b10
  when rs2 != zreg & currentlyEnabled(Ext_Zca)

function clause execute C_ADD(rsd, rs2) =
  execute(RTYPE(rs2, rsd, rsd, ADD))

mapping clause assembly = C_ADD(rsd, rs2)
  <-> "c.add" ^ spc() ^ reg_name(rsd) ^ sep() ^ reg_name(rs2)
  when rs2 != zreg
