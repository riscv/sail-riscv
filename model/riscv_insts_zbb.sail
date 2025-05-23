/*=======================================================================================*/
/*  This Sail RISC-V architecture model, comprising all files and                        */
/*  directories except where otherwise noted is subject the BSD                          */
/*  two-clause license in the LICENSE file.                                              */
/*                                                                                       */
/*  SPDX-License-Identifier: BSD-2-Clause                                                */
/*=======================================================================================*/

function clause currentlyEnabled(Ext_Zbb) = hartSupports(Ext_Zbb) | currentlyEnabled(Ext_B)
function clause currentlyEnabled(Ext_Zbkb) = hartSupports(Ext_Zbkb)

/* ****************************************************************** */
union clause ast = RORIW : (bits(5), regidx, regidx)

mapping clause encdec = RORIW(shamt, rs1, rd)
  <-> 0b0110000 @ shamt @ encdec_reg(rs1) @ 0b101 @ encdec_reg(rd) @ 0b0011011
  when (currentlyEnabled(Ext_Zbb) | currentlyEnabled(Ext_Zbkb)) & xlen == 64

mapping clause assembly = RORIW(shamt, rs1, rd)
  <-> "roriw" ^ spc() ^ reg_name(rd) ^ sep() ^ reg_name(rs1) ^ sep() ^ hex_bits_5(shamt)

function clause execute (RORIW(shamt, rs1, rd)) = {
  let rs1_val = (X(rs1))[31..0];
  let result : xlenbits = sign_extend(rs1_val >>> shamt);
  X(rd) = result;
  RETIRE_SUCCESS
}

/* ****************************************************************** */
union clause ast = RORI : (bits(6), regidx, regidx)

mapping clause encdec = RORI(shamt, rs1, rd)
  <-> 0b011000 @ shamt @ encdec_reg(rs1) @ 0b101 @ encdec_reg(rd) @ 0b0010011
  when (currentlyEnabled(Ext_Zbb) | currentlyEnabled(Ext_Zbkb)) & (xlen == 64 | shamt[5] == bitzero)

mapping clause assembly = RORI(shamt, rs1, rd)
  <-> "rori" ^ spc() ^ reg_name(rd) ^ sep() ^ reg_name(rs1) ^ sep() ^ hex_bits_6(shamt)

function clause execute (RORI(shamt, rs1, rd)) = {
  let rs1_val = X(rs1);
  let result : xlenbits = if xlen == 32
                          then rs1_val >>> shamt[4..0]
                          else rs1_val >>> shamt;
  X(rd) = result;
  RETIRE_SUCCESS
}

/* ****************************************************************** */
union clause ast = ZBB_RTYPEW : (regidx, regidx, regidx, bropw_zbb)

mapping clause encdec = ZBB_RTYPEW(rs2, rs1, rd, ROLW)
  <-> 0b0110000 @ encdec_reg(rs2) @ encdec_reg(rs1) @ 0b001 @ encdec_reg(rd) @ 0b0111011
  when (currentlyEnabled(Ext_Zbb) | currentlyEnabled(Ext_Zbkb)) & xlen == 64

mapping clause encdec = ZBB_RTYPEW(rs2, rs1, rd, RORW)
  <-> 0b0110000 @ encdec_reg(rs2) @ encdec_reg(rs1) @ 0b101 @ encdec_reg(rd) @ 0b0111011
  when (currentlyEnabled(Ext_Zbb) | currentlyEnabled(Ext_Zbkb)) & xlen == 64

mapping zbb_rtypew_mnemonic : bropw_zbb <-> string = {
  ROLW <-> "rolw",
  RORW <-> "rorw"
}

mapping clause assembly = ZBB_RTYPEW(rs2, rs1, rd, op)
  <-> zbb_rtypew_mnemonic(op) ^ spc() ^ reg_name(rd) ^ sep() ^ reg_name(rs1) ^ sep() ^ reg_name(rs2)

function clause execute (ZBB_RTYPEW(rs2, rs1, rd, op)) = {
  let rs1_val = (X(rs1))[31..0];
  let shamt = (X(rs2))[4..0];
  let result : bits(32) = match op {
    ROLW => rs1_val <<< shamt,
    RORW => rs1_val >>> shamt
  };
  X(rd) = sign_extend(result);
  RETIRE_SUCCESS
}

/* ****************************************************************** */
union clause ast = ZBB_RTYPE : (regidx, regidx, regidx, brop_zbb)

mapping clause encdec = ZBB_RTYPE(rs2, rs1, rd, ANDN)
  <-> 0b0100000 @ encdec_reg(rs2) @ encdec_reg(rs1) @ 0b111 @ encdec_reg(rd) @ 0b0110011
  when currentlyEnabled(Ext_Zbb) | currentlyEnabled(Ext_Zbkb)

mapping clause encdec = ZBB_RTYPE(rs2, rs1, rd, ORN)
  <-> 0b0100000 @ encdec_reg(rs2) @ encdec_reg(rs1) @ 0b110 @ encdec_reg(rd) @ 0b0110011
  when currentlyEnabled(Ext_Zbb) | currentlyEnabled(Ext_Zbkb)

mapping clause encdec = ZBB_RTYPE(rs2, rs1, rd, XNOR)
  <-> 0b0100000 @ encdec_reg(rs2) @ encdec_reg(rs1) @ 0b100 @ encdec_reg(rd) @ 0b0110011
  when currentlyEnabled(Ext_Zbb) | currentlyEnabled(Ext_Zbkb)

mapping clause encdec = ZBB_RTYPE(rs2, rs1, rd, MAX)
  <-> 0b0000101 @ encdec_reg(rs2) @ encdec_reg(rs1) @ 0b110 @ encdec_reg(rd) @ 0b0110011
  when currentlyEnabled(Ext_Zbb)

mapping clause encdec = ZBB_RTYPE(rs2, rs1, rd, MAXU)
  <-> 0b0000101 @ encdec_reg(rs2) @ encdec_reg(rs1) @ 0b111 @ encdec_reg(rd) @ 0b0110011
  when currentlyEnabled(Ext_Zbb)

mapping clause encdec = ZBB_RTYPE(rs2, rs1, rd, MIN)
  <-> 0b0000101 @ encdec_reg(rs2) @ encdec_reg(rs1) @ 0b100 @ encdec_reg(rd) @ 0b0110011
  when currentlyEnabled(Ext_Zbb)

mapping clause encdec = ZBB_RTYPE(rs2, rs1, rd, MINU)
  <-> 0b0000101 @ encdec_reg(rs2) @ encdec_reg(rs1) @ 0b101 @ encdec_reg(rd) @ 0b0110011
  when currentlyEnabled(Ext_Zbb)

mapping clause encdec = ZBB_RTYPE(rs2, rs1, rd, ROL)
  <-> 0b0110000 @ encdec_reg(rs2) @ encdec_reg(rs1) @ 0b001 @ encdec_reg(rd) @ 0b0110011
  when currentlyEnabled(Ext_Zbb) | currentlyEnabled(Ext_Zbkb)

mapping clause encdec = ZBB_RTYPE(rs2, rs1, rd, ROR)
  <-> 0b0110000 @ encdec_reg(rs2) @ encdec_reg(rs1) @ 0b101 @ encdec_reg(rd) @ 0b0110011
  when currentlyEnabled(Ext_Zbb) | currentlyEnabled(Ext_Zbkb)

mapping zbb_rtype_mnemonic : brop_zbb <-> string = {
  ANDN <-> "andn",
  ORN  <-> "orn",
  XNOR <-> "xnor",
  MAX  <-> "max",
  MAXU <-> "maxu",
  MIN  <-> "min",
  MINU <-> "minu",
  ROL  <-> "rol",
  ROR  <-> "ror"
}

mapping clause assembly = ZBB_RTYPE(rs2, rs1, rd, op)
  <-> zbb_rtype_mnemonic(op) ^ spc() ^ reg_name(rd) ^ sep() ^ reg_name(rs1) ^ sep() ^ reg_name(rs2)

function clause execute (ZBB_RTYPE(rs2, rs1, rd, op)) = {
  let rs1_val = X(rs1);
  let rs2_val = X(rs2);
  let result : xlenbits = match op {
    ANDN => rs1_val & ~(rs2_val),
    ORN  => rs1_val | ~(rs2_val),
    XNOR => ~(rs1_val ^ rs2_val),
    MAX  => if rs1_val >_s rs2_val then rs1_val else rs2_val,
    MAXU => if rs1_val >_u rs2_val then rs1_val else rs2_val,
    MIN  => if rs1_val <_s rs2_val then rs1_val else rs2_val,
    MINU => if rs1_val <_u rs2_val then rs1_val else rs2_val,
    ROL  => if xlen == 32
                  then rs1_val <<< rs2_val[4..0]
                  else rs1_val <<< rs2_val[5..0],
    ROR  => if xlen == 32
                  then rs1_val >>> rs2_val[4..0]
                  else rs1_val >>> rs2_val[5..0]
  };
  X(rd) = result;
  RETIRE_SUCCESS
}

/* ****************************************************************** */
union clause ast = ZBB_EXTOP : (regidx, regidx, extop_zbb)

mapping clause encdec = ZBB_EXTOP(rs1, rd, SEXTB)
  <-> 0b0110000 @ 0b00100 @ encdec_reg(rs1) @ 0b001 @ encdec_reg(rd) @ 0b0010011
  when currentlyEnabled(Ext_Zbb)

mapping clause encdec = ZBB_EXTOP(rs1, rd, SEXTH)
  <-> 0b0110000 @ 0b00101 @ encdec_reg(rs1) @ 0b001 @ encdec_reg(rd) @ 0b0010011
  when currentlyEnabled(Ext_Zbb)

mapping clause encdec = ZBB_EXTOP(rs1, rd, ZEXTH)
  <-> 0b0000100 @ 0b00000 @ encdec_reg(rs1) @ 0b100 @ encdec_reg(rd) @ 0b0110011
  when currentlyEnabled(Ext_Zbb) & xlen == 32

mapping clause encdec = ZBB_EXTOP(rs1, rd, ZEXTH)
  <-> 0b0000100 @ 0b00000 @ encdec_reg(rs1) @ 0b100 @ encdec_reg(rd) @ 0b0111011
  when currentlyEnabled(Ext_Zbb) & xlen == 64

mapping zbb_extop_mnemonic : extop_zbb <-> string = {
  SEXTB <-> "sext.b",
  SEXTH <-> "sext.h",
  ZEXTH <-> "zext.h"
}

mapping clause assembly = ZBB_EXTOP(rs1, rd, op)
  <-> zbb_extop_mnemonic(op) ^ spc() ^ reg_name(rd) ^ sep() ^ reg_name(rs1)

function clause execute (ZBB_EXTOP(rs1, rd, op)) = {
  let rs1_val = X(rs1);
  let result : xlenbits = match op {
    SEXTB => sign_extend(rs1_val[7..0]),
    SEXTH => sign_extend(rs1_val[15..0]),
    ZEXTH => zero_extend(rs1_val[15..0])
  };
  X(rd) = result;
  RETIRE_SUCCESS
}

/* ****************************************************************** */
union clause ast = REV8 : (regidx, regidx)

mapping clause encdec = REV8(rs1, rd)
  <-> 0b011010011000 @ encdec_reg(rs1) @ 0b101 @ encdec_reg(rd) @ 0b0010011
  when (currentlyEnabled(Ext_Zbb) | currentlyEnabled(Ext_Zbkb)) & xlen == 32

mapping clause encdec = REV8(rs1, rd)
  <-> 0b011010111000 @ encdec_reg(rs1) @ 0b101 @ encdec_reg(rd) @ 0b0010011
  when (currentlyEnabled(Ext_Zbb) | currentlyEnabled(Ext_Zbkb)) & xlen == 64

mapping clause assembly = REV8(rs1, rd)
  <-> "rev8" ^ spc() ^ reg_name(rd) ^ sep() ^ reg_name(rs1)

function clause execute (REV8(rs1, rd)) = {
  let rs1_val = X(rs1);
  var result : xlenbits = zeros();
  foreach (i from 0 to (xlen - 8) by 8)
    result[(i + 7) .. i] = rs1_val[(xlen - i - 1) .. (xlen - i - 8)];
  X(rd) = result;
  RETIRE_SUCCESS
}

/* ****************************************************************** */
union clause ast = ORCB : (regidx, regidx)

mapping clause encdec = ORCB(rs1, rd)
  <-> 0b001010000111 @ encdec_reg(rs1) @ 0b101 @ encdec_reg(rd) @ 0b0010011
  when currentlyEnabled(Ext_Zbb)

mapping clause assembly = ORCB(rs1, rd)
  <-> "orc.b" ^ spc() ^ reg_name(rd) ^ sep() ^ reg_name(rs1)

function clause execute (ORCB(rs1, rd)) = {
  let rs1_val = X(rs1);
  var result : xlenbits = zeros();
  foreach (i from 0 to (xlen - 8) by 8)
    result[(i + 7) .. i] = if rs1_val[(i + 7) .. i] == zeros()
                           then 0x00
                           else 0xFF;
  X(rd) = result;
  RETIRE_SUCCESS
}

/* ****************************************************************** */
union clause ast = CPOP : (regidx, regidx)

mapping clause encdec = CPOP(rs1, rd)
  <-> 0b011000000010 @ encdec_reg(rs1) @ 0b001 @ encdec_reg(rd) @ 0b0010011
  when currentlyEnabled(Ext_Zbb)

mapping clause assembly = CPOP(rs1, rd)
  <-> "cpop" ^ spc() ^ reg_name(rd) ^ sep() ^ reg_name(rs1)

function clause execute (CPOP(rs1, rd)) = {
  X(rd) = to_bits(count_ones(X(rs1)));
  RETIRE_SUCCESS
}

/* ****************************************************************** */
union clause ast = CPOPW : (regidx, regidx)

mapping clause encdec = CPOPW(rs1, rd)
  <-> 0b011000000010 @ encdec_reg(rs1) @ 0b001 @ encdec_reg(rd) @ 0b0011011
  when currentlyEnabled(Ext_Zbb) & xlen == 64

mapping clause assembly = CPOPW(rs1, rd)
  <-> "cpopw" ^ spc() ^ reg_name(rd) ^ sep() ^ reg_name(rs1)

function clause execute (CPOPW(rs1, rd)) = {
  X(rd) = to_bits(count_ones(X(rs1)[31 .. 0]));
  RETIRE_SUCCESS
}

/* ****************************************************************** */
union clause ast = CLZ : (regidx, regidx)

mapping clause encdec = CLZ(rs1, rd)
  <-> 0b011000000000 @ encdec_reg(rs1) @ 0b001 @ encdec_reg(rd) @ 0b0010011
  when currentlyEnabled(Ext_Zbb)

mapping clause assembly = CLZ(rs1, rd)
  <-> "clz" ^ spc() ^ reg_name(rd) ^ sep() ^ reg_name(rs1)

function clause execute (CLZ(rs1, rd)) = {
  X(rd) = to_bits(count_leading_zeros(X(rs1)));
  RETIRE_SUCCESS
}

/* ****************************************************************** */
union clause ast = CLZW : (regidx, regidx)

mapping clause encdec = CLZW(rs1, rd)
  <-> 0b011000000000 @ encdec_reg(rs1) @ 0b001 @ encdec_reg(rd) @ 0b0011011
  when currentlyEnabled(Ext_Zbb) & xlen == 64

mapping clause assembly = CLZW(rs1, rd)
  <-> "clzw" ^ spc() ^ reg_name(rd) ^ sep() ^ reg_name(rs1)

function clause execute (CLZW(rs1, rd)) = {
  X(rd) = to_bits(count_leading_zeros(X(rs1)[31 .. 0]));
  RETIRE_SUCCESS
}

/* ****************************************************************** */
union clause ast = CTZ : (regidx, regidx)

mapping clause encdec = CTZ(rs1, rd)
  <-> 0b011000000001 @ encdec_reg(rs1) @ 0b001 @ encdec_reg(rd) @ 0b0010011
  when currentlyEnabled(Ext_Zbb)

mapping clause assembly = CTZ(rs1, rd)
  <-> "ctz" ^ spc() ^ reg_name(rd) ^ sep() ^ reg_name(rs1)

function clause execute (CTZ(rs1, rd)) = {
  X(rd) = to_bits(count_trailing_zeros(X(rs1)));
  RETIRE_SUCCESS
}

/* ****************************************************************** */
union clause ast = CTZW : (regidx, regidx)

mapping clause encdec = CTZW(rs1, rd)
  <-> 0b011000000001 @ encdec_reg(rs1) @ 0b001 @ encdec_reg(rd) @ 0b0011011
  when currentlyEnabled(Ext_Zbb) & xlen == 64

mapping clause assembly = CTZW(rs1, rd)
  <-> "ctzw" ^ spc() ^ reg_name(rd) ^ sep() ^ reg_name(rs1)

function clause execute (CTZW(rs1, rd)) = {
  X(rd) = to_bits(count_trailing_zeros(X(rs1)[31 .. 0]));
  RETIRE_SUCCESS
}
