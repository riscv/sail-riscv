/*=======================================================================================*/
/*  This Sail RISC-V architecture model, comprising all files and                        */
/*  directories except where otherwise noted is subject the BSD                          */
/*  two-clause license in the LICENSE file.                                              */
/*                                                                                       */
/*  SPDX-License-Identifier: BSD-2-Clause                                                */
/*=======================================================================================*/

/* ****************************************************************** */
/* This file specifies the 32-bit instructions in the 'M' extension   */
/* that are only available for 64-bit ISAs.                           */
/* ****************************************************************** */

/* ****************************************************************** */
union clause instruction = MULW : (regidx, regidx, regidx)

mapping clause encdec = MULW(rs2, rs1, rd)
  <-> 0b0000001 @ encdec_reg(rs2) @ encdec_reg(rs1) @ 0b000 @ encdec_reg(rd) @ 0b0111011
  when xlen == 64 & (currentlyEnabled(Ext_M) | currentlyEnabled(Ext_Zmmul))

function clause execute (MULW(rs2, rs1, rd)) = {
  let rs1_bits = X(rs1)[31..0];
  let rs2_bits = X(rs2)[31..0];
  let rs1_int = signed(rs1_bits);
  let rs2_int = signed(rs2_bits);

  let result32 : bits(32) = to_bits_truncate(rs1_int * rs2_int);
  X(rd) = sign_extend(result32);
  RETIRE_SUCCESS
}

mapping clause assembly = MULW(rs2, rs1, rd)
  <-> "mulw" ^ spc() ^ reg_name(rd) ^ sep() ^ reg_name(rs1) ^ sep() ^ reg_name(rs2)
  when xlen == 64

/* ****************************************************************** */
union clause instruction = DIVW : (regidx, regidx, regidx, bool)

mapping clause encdec = DIVW(rs2, rs1, rd, is_unsigned)
  <-> 0b0000001 @ encdec_reg(rs2) @ encdec_reg(rs1) @ 0b10 @ bool_bits(is_unsigned) @ encdec_reg(rd) @ 0b0111011
  when xlen == 64 & currentlyEnabled(Ext_M)

function clause execute (DIVW(rs2, rs1, rd, is_unsigned)) = {
  let rs1_bits = X(rs1)[31..0];
  let rs2_bits = X(rs2)[31..0];
  let rs1_int = if is_unsigned then unsigned(rs1_bits) else signed(rs1_bits);
  let rs2_int = if is_unsigned then unsigned(rs2_bits) else signed(rs2_bits);

  let quotient = if rs2_int == 0 then -1 else quot_round_zero(rs1_int, rs2_int);
  // Check for signed overflow.
  let quotient = if not(is_unsigned) & quotient >= 2 ^ 31 then negate(2 ^ 31) else quotient;
  X(rd) = sign_extend(to_bits_truncate(32, quotient));
  RETIRE_SUCCESS
}

mapping clause assembly = DIVW(rs2, rs1, rd, is_unsigned)
  <-> "div" ^ maybe_u(is_unsigned) ^ "w" ^ spc() ^ reg_name(rd) ^ sep() ^ reg_name(rs1) ^ sep() ^ reg_name(rs2)
  when xlen == 64

/* ****************************************************************** */
union clause instruction = REMW : (regidx, regidx, regidx, bool)

mapping clause encdec = REMW(rs2, rs1, rd, is_unsigned)
  <-> 0b0000001 @ encdec_reg(rs2) @ encdec_reg(rs1) @ 0b11 @ bool_bits(is_unsigned) @ encdec_reg(rd) @ 0b0111011
  when xlen == 64 & currentlyEnabled(Ext_M)

function clause execute (REMW(rs2, rs1, rd, is_unsigned)) = {
  let rs1_bits = X(rs1)[31..0];
  let rs2_bits = X(rs2)[31..0];
  let rs1_int = if is_unsigned then unsigned(rs1_bits) else signed(rs1_bits);
  let rs2_int = if is_unsigned then unsigned(rs2_bits) else signed(rs2_bits);

  let remainder = if rs2_int == 0 then rs1_int else rem_round_zero(rs1_int, rs2_int);
  // Signed overflow case returns zero naturally as required due to -1 divisor.
  X(rd) = sign_extend(to_bits_truncate(32, remainder));
  RETIRE_SUCCESS
}

mapping clause assembly = REMW(rs2, rs1, rd, is_unsigned)
  <-> "rem" ^ maybe_u(is_unsigned) ^ "w" ^ spc() ^ reg_name(rd) ^ sep() ^ reg_name(rs1) ^ sep() ^ reg_name(rs2)
  when xlen == 64
