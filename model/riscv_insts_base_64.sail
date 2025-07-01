/*=======================================================================================*/
/*  This Sail RISC-V architecture model, comprising all files and                        */
/*  directories except where otherwise noted is subject the BSD                          */
/*  two-clause license in the LICENSE file.                                              */
/*                                                                                       */
/*  SPDX-License-Identifier: BSD-2-Clause                                                */
/*=======================================================================================*/

/* *******************************************************************************/
/* This file specifies the 32-bit instructions of the base integer set that are
 * only present on 64-bit ISAs */

/* ****************************************************************** */
union clause instruction = ADDIW : (bits(12), regidx, regidx)

mapping clause encdec = ADDIW(imm, rs1, rd)
  <-> imm @ encdec_reg(rs1) @ 0b000 @ encdec_reg(rd) @ 0b0011011
  when xlen == 64

function clause execute (ADDIW(imm, rs1, rd)) = {
  let result = X(rs1) + sign_extend(imm);
  X(rd) = sign_extend(result[31..0]);
  RETIRE_SUCCESS
}

mapping clause assembly = ADDIW(imm, rs1, rd)
  <-> "addiw" ^ spc() ^ reg_name(rd) ^ sep() ^ reg_name(rs1) ^ sep() ^ hex_bits_signed_12(imm)
  when xlen == 64

/* ****************************************************************** */
union clause instruction = RTYPEW : (regidx, regidx, regidx, ropw)

mapping clause encdec = RTYPEW(rs2, rs1, rd, ADDW)
  <-> 0b0000000 @ encdec_reg(rs2) @ encdec_reg(rs1) @ 0b000 @ encdec_reg(rd) @ 0b0111011
  when xlen == 64
mapping clause encdec = RTYPEW(rs2, rs1, rd, SUBW)
  <-> 0b0100000 @ encdec_reg(rs2) @ encdec_reg(rs1) @ 0b000 @ encdec_reg(rd) @ 0b0111011
  when xlen == 64
mapping clause encdec = RTYPEW(rs2, rs1, rd, SLLW)
  <-> 0b0000000 @ encdec_reg(rs2) @ encdec_reg(rs1) @ 0b001 @ encdec_reg(rd) @ 0b0111011
  when xlen == 64
mapping clause encdec = RTYPEW(rs2, rs1, rd, SRLW)
  <-> 0b0000000 @ encdec_reg(rs2) @ encdec_reg(rs1) @ 0b101 @ encdec_reg(rd) @ 0b0111011
  when xlen == 64
mapping clause encdec = RTYPEW(rs2, rs1, rd, SRAW)
  <-> 0b0100000 @ encdec_reg(rs2) @ encdec_reg(rs1) @ 0b101 @ encdec_reg(rd) @ 0b0111011
  when xlen == 64

function clause execute (RTYPEW(rs2, rs1, rd, op)) = {
  let rs1_val = X(rs1)[31..0];
  let rs2_val = X(rs2)[31..0];
  let result : bits(32) = match op {
    ADDW => rs1_val + rs2_val,
    SUBW => rs1_val - rs2_val,
    SLLW => rs1_val << rs2_val[4..0],
    SRLW => rs1_val >> rs2_val[4..0],
    SRAW => shift_bits_right_arith(rs1_val, rs2_val[4..0]),
  };
  X(rd) = sign_extend(result);
  RETIRE_SUCCESS
}

mapping rtypew_mnemonic : ropw <-> string = {
  ADDW <-> "addw",
  SUBW <-> "subw",
  SLLW <-> "sllw",
  SRLW <-> "srlw",
  SRAW <-> "sraw"
}

mapping clause assembly = RTYPEW(rs2, rs1, rd, op)
  <-> rtypew_mnemonic(op) ^ spc() ^ reg_name(rd) ^ sep() ^ reg_name(rs1) ^ sep() ^ reg_name(rs2)
  when xlen == 64

/* ****************************************************************** */
union clause instruction = SHIFTIWOP : (bits(5), regidx, regidx, sopw)

mapping clause encdec = SHIFTIWOP(shamt, rs1, rd, SLLIW)
  <-> 0b0000000 @ shamt @ encdec_reg(rs1) @ 0b001 @ encdec_reg(rd) @ 0b0011011
  when xlen == 64
mapping clause encdec = SHIFTIWOP(shamt, rs1, rd, SRLIW)
  <-> 0b0000000 @ shamt @ encdec_reg(rs1) @ 0b101 @ encdec_reg(rd) @ 0b0011011
  when xlen == 64
mapping clause encdec = SHIFTIWOP(shamt, rs1, rd, SRAIW)
  <-> 0b0100000 @ shamt @ encdec_reg(rs1) @ 0b101 @ encdec_reg(rd) @ 0b0011011
  when xlen == 64

function clause execute (SHIFTIWOP(shamt, rs1, rd, op)) = {
  let rs1_val = X(rs1)[31..0];
  let result : bits(32) = match op {
    SLLIW => rs1_val << shamt,
    SRLIW => rs1_val >> shamt,
    SRAIW => shift_bits_right_arith(rs1_val, shamt),
  };
  X(rd) = sign_extend(result);
  RETIRE_SUCCESS
}

mapping shiftiwop_mnemonic : sopw <-> string = {
  SLLIW <-> "slliw",
  SRLIW <-> "srliw",
  SRAIW <-> "sraiw"
}

mapping clause assembly = SHIFTIWOP(shamt, rs1, rd, op)
  <-> shiftiwop_mnemonic(op) ^ spc() ^ reg_name(rd) ^ sep() ^ reg_name(rs1) ^ sep() ^ hex_bits_5(shamt)
  when xlen == 64
