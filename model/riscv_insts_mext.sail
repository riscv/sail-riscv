/*=======================================================================================*/
/*  This Sail RISC-V architecture model, comprising all files and                        */
/*  directories except where otherwise noted is subject the BSD                          */
/*  two-clause license in the LICENSE file.                                              */
/*                                                                                       */
/*  SPDX-License-Identifier: BSD-2-Clause                                                */
/*=======================================================================================*/

/* ****************************************************************** */
/* This file specifies the instructions in the 'M' extension.         */

/* ****************************************************************** */

function clause extensionEnabled(Ext_M) = misa[M] == 0b1
function clause extensionEnabled(Ext_Zmmul) = true


union clause ast = MUL : (regidx, regidx, regidx, mul_op)

mapping encdec_mul_op : mul_op <-> bits(3) = {
  struct { high = false, signed_rs1 = true,  signed_rs2 = true  } <-> 0b000,
  struct { high = true,  signed_rs1 = true,  signed_rs2 = true  } <-> 0b001,
  struct { high = true,  signed_rs1 = true,  signed_rs2 = false } <-> 0b010,
  struct { high = true,  signed_rs1 = false, signed_rs2 = false } <-> 0b011
}

mapping clause encdec = MUL(rs2, rs1, rd, mul_op)                    if extensionEnabled(Ext_M) | extensionEnabled(Ext_Zmmul)
  <-> 0b0000001 @ rs2 @ rs1 @ encdec_mul_op(mul_op) @ rd @ 0b0110011 if extensionEnabled(Ext_M) | extensionEnabled(Ext_Zmmul)

function clause execute (MUL(rs2, rs1, rd, mul_op)) = {
  let rs1_val = X(rs1);
  let rs2_val = X(rs2);
  let rs1_int : int = if mul_op.signed_rs1 then signed(rs1_val) else unsigned(rs1_val);
  let rs2_int : int = if mul_op.signed_rs2 then signed(rs2_val) else unsigned(rs2_val);
  let result_wide = to_bits(2 * xlen, rs1_int * rs2_int);
  let result = if   mul_op.high
               then result_wide[(2 * xlen - 1) .. xlen]
               else result_wide[(xlen - 1) .. 0];
  X(rd) = result;
  RETIRE_SUCCESS
}

mapping mul_mnemonic : mul_op <-> string = {
  struct { high = false, signed_rs1 = true,  signed_rs2 = true  } <-> "mul",
  struct { high = true,  signed_rs1 = true,  signed_rs2 = true  } <-> "mulh",
  struct { high = true,  signed_rs1 = true,  signed_rs2 = false } <-> "mulhsu",
  struct { high = true,  signed_rs1 = false, signed_rs2 = false } <-> "mulhu"
}

mapping clause assembly = MUL(rs2, rs1, rd, mul_op)
  <-> mul_mnemonic(mul_op) ^ spc() ^ reg_name(rd) ^ sep() ^ reg_name(rs1) ^ sep() ^ reg_name(rs2)

/* ****************************************************************** */
union clause ast = DIV : (regidx, regidx, regidx, bool)

mapping clause encdec = DIV(rs2, rs1, rd, s)                           if extensionEnabled(Ext_M)
  <-> 0b0000001 @ rs2 @ rs1 @ 0b10 @ bool_not_bits(s) @ rd @ 0b0110011 if extensionEnabled(Ext_M)

function clause execute (DIV(rs2, rs1, rd, s)) = {
  let rs1_val = X(rs1);
  let rs2_val = X(rs2);
  let rs1_int : int = if s then signed(rs1_val) else unsigned(rs1_val);
  let rs2_int : int = if s then signed(rs2_val) else unsigned(rs2_val);
  let q : int = if rs2_int == 0 then -1 else quot_round_zero(rs1_int, rs2_int);
  /* check for signed overflow */
  let q': int = if s & q > xlen_max_signed then xlen_min_signed else q;
  X(rd) = to_bits(xlen, q');
  RETIRE_SUCCESS
}

mapping maybe_not_u : bool <-> string = {
  false <-> "u",
  true  <-> ""
}

mapping clause assembly = DIV(rs2, rs1, rd, s)
  <-> "div" ^ maybe_not_u(s) ^ spc() ^ reg_name(rd) ^ sep() ^ reg_name(rs1) ^ sep() ^ reg_name(rs2)

/* ****************************************************************** */
union clause ast = REM : (regidx, regidx, regidx, bool)

mapping clause encdec = REM(rs2, rs1, rd, s)                           if extensionEnabled(Ext_M)
  <-> 0b0000001 @ rs2 @ rs1 @ 0b11 @ bool_not_bits(s) @ rd @ 0b0110011 if extensionEnabled(Ext_M)

function clause execute (REM(rs2, rs1, rd, s)) = {
  let rs1_val = X(rs1);
  let rs2_val = X(rs2);
  let rs1_int : int = if s then signed(rs1_val) else unsigned(rs1_val);
  let rs2_int : int = if s then signed(rs2_val) else unsigned(rs2_val);
  let r : int = if rs2_int == 0 then rs1_int else rem_round_zero(rs1_int, rs2_int);
  /* signed overflow case returns zero naturally as required due to -1 divisor */
  X(rd) = to_bits(xlen, r);
  RETIRE_SUCCESS
}

mapping clause assembly = REM(rs2, rs1, rd, s)
  <-> "rem" ^ maybe_not_u(s) ^ spc() ^ reg_name(rd) ^ sep() ^ reg_name(rs1) ^ sep() ^ reg_name(rs2)

/* ****************************************************************** */
union clause ast = MULW : (regidx, regidx, regidx)

mapping clause encdec = MULW(rs2, rs1, rd)
      if xlen == 64 & (extensionEnabled(Ext_M) | extensionEnabled(Ext_Zmmul))
  <-> 0b0000001 @ rs2 @ rs1 @ 0b000 @ rd @ 0b0111011
      if xlen == 64 & (extensionEnabled(Ext_M) | extensionEnabled(Ext_Zmmul))

function clause execute (MULW(rs2, rs1, rd)) = {
  let rs1_val = X(rs1)[31..0];
  let rs2_val = X(rs2)[31..0];
  let rs1_int : int = signed(rs1_val);
  let rs2_int : int = signed(rs2_val);
  /* to_bits requires expansion to 64 bits followed by truncation */
  let result32 = to_bits(64, rs1_int * rs2_int)[31..0];
  let result : xlenbits = sign_extend(result32);
  X(rd) = result;
  RETIRE_SUCCESS
}

mapping clause assembly = MULW(rs2, rs1, rd)
      if xlen == 64
  <-> "mulw" ^ spc() ^ reg_name(rd) ^ sep() ^ reg_name(rs1) ^ sep() ^ reg_name(rs2)
      if xlen == 64

/* ****************************************************************** */
union clause ast = DIVW : (regidx, regidx, regidx, bool)

mapping clause encdec = DIVW(rs2, rs1, rd, s)
      if xlen == 64 & extensionEnabled(Ext_M)
  <-> 0b0000001 @ rs2 @ rs1 @ 0b10 @ bool_not_bits(s) @ rd @ 0b0111011
      if xlen == 64 & extensionEnabled(Ext_M)

function clause execute (DIVW(rs2, rs1, rd, s)) = {
  let rs1_val = X(rs1)[31..0];
  let rs2_val = X(rs2)[31..0];
  let rs1_int : int = if s then signed(rs1_val) else unsigned(rs1_val);
  let rs2_int : int = if s then signed(rs2_val) else unsigned(rs2_val);
  let q : int = if rs2_int == 0 then -1 else quot_round_zero(rs1_int, rs2_int);
  /* check for signed overflow */
  let q': int = if s & q > (2 ^ 31 - 1) then  (0 - (2 ^ 31)) else q;
  X(rd) = sign_extend(to_bits(32, q'));
  RETIRE_SUCCESS
}

mapping clause assembly = DIVW(rs2, rs1, rd, s)
      if xlen == 64
  <-> "div" ^ maybe_not_u(s) ^ "w" ^ spc() ^ reg_name(rd) ^ sep() ^ reg_name(rs1) ^ sep() ^ reg_name(rs2)
      if xlen == 64

/* ****************************************************************** */
union clause ast = REMW : (regidx, regidx, regidx, bool)

mapping clause encdec = REMW(rs2, rs1, rd, s)
      if xlen == 64 & extensionEnabled(Ext_M)
  <-> 0b0000001 @ rs2 @ rs1 @ 0b11 @ bool_not_bits(s) @ rd @ 0b0111011
      if xlen == 64 & extensionEnabled(Ext_M)

function clause execute (REMW(rs2, rs1, rd, s)) = {
  let rs1_val = X(rs1)[31..0];
  let rs2_val = X(rs2)[31..0];
  let rs1_int : int = if s then signed(rs1_val) else unsigned(rs1_val);
  let rs2_int : int = if s then signed(rs2_val) else unsigned(rs2_val);
  let r : int = if rs2_int == 0 then rs1_int else rem_round_zero(rs1_int, rs2_int);
  /* signed overflow case returns zero naturally as required due to -1 divisor */
  X(rd) = sign_extend(to_bits(32, r));
  RETIRE_SUCCESS
}

mapping clause assembly = REMW(rs2, rs1, rd, s)
      if xlen == 64
  <-> "rem" ^ maybe_not_u(s) ^ "w" ^ spc() ^ reg_name(rd) ^ sep() ^ reg_name(rs1) ^ sep() ^ reg_name(rs2)
      if xlen == 64
