/*=======================================================================================*/
/*  This Sail RISC-V architecture model, comprising all files and                        */
/*  directories except where otherwise noted is subject the BSD                          */
/*  two-clause license in the LICENSE file.                                              */
/*                                                                                       */
/*  SPDX-License-Identifier: BSD-2-Clause                                                */
/*=======================================================================================*/

function clause currentlyEnabled(Ext_B) = hartSupports(Ext_B) & misa[B] == 0b1
function clause currentlyEnabled(Ext_Zba) = hartSupports(Ext_Zba) | currentlyEnabled(Ext_B)

/* ****************************************************************** */
union clause instruction = SLLIUW : (bits(6), regidx, regidx)

mapping clause encdec = SLLIUW(shamt, rs1, rd)
  <-> 0b000010 @ shamt @ encdec_reg(rs1) @ 0b001 @ encdec_reg(rd) @ 0b0011011
  when currentlyEnabled(Ext_Zba) & xlen == 64

mapping clause assembly = SLLIUW(shamt, rs1, rd)
  <-> "slli.uw" ^ spc() ^ reg_name(rd) ^ sep() ^ reg_name(rs1) ^ sep() ^ hex_bits_6(shamt)

function clause execute (SLLIUW(shamt, rs1, rd)) = {
  X(rd) = zero_extend(X(rs1)[31..0]) << shamt;
  RETIRE_SUCCESS
}

/* ****************************************************************** */
union clause instruction = ZBA_RTYPEUW : (regidx, regidx, regidx, shamt_zba)

// add.uw
mapping clause encdec = ZBA_RTYPEUW(rs2, rs1, rd, 0b00)
  <-> 0b0000100 @ encdec_reg(rs2) @ encdec_reg(rs1) @ 0b00 @ 0b0 @ encdec_reg(rd) @ 0b0111011
  when currentlyEnabled(Ext_Zba) & xlen == 64

// sh#add.uw
mapping clause encdec = ZBA_RTYPEUW(rs2, rs1, rd, shamt)
  <-> 0b0010000 @ encdec_reg(rs2) @ encdec_reg(rs1) @ shamt @ 0b0 @ encdec_reg(rd) @ 0b0111011
  when currentlyEnabled(Ext_Zba) & xlen == 64

mapping zba_rtypeuw_mnemonic : shamt_zba <-> string = {
  0b00 <-> "add.uw",
  0b01 <-> "sh1add.uw",
  0b10 <-> "sh2add.uw",
  0b11 <-> "sh3add.uw",
}

mapping clause assembly = ZBA_RTYPEUW(rs2, rs1, rd, shamt)
  <-> zba_rtypeuw_mnemonic(shamt) ^ spc() ^ reg_name(rd) ^ sep() ^ reg_name(rs1) ^ sep() ^ reg_name(rs2)

function clause execute (ZBA_RTYPEUW(rs2, rs1, rd, shamt)) = {
  X(rd) = (zero_extend(X(rs1)[31..0]) << shamt) + X(rs2);
  RETIRE_SUCCESS
}

/* ****************************************************************** */
union clause instruction = ZBA_RTYPE : (regidx, regidx, regidx, shamt_zba)

mapping clause encdec = ZBA_RTYPE(rs2, rs1, rd, shamt)
  <-> 0b0010000 @ encdec_reg(rs2) @ encdec_reg(rs1) @ shamt @ 0b0 @ encdec_reg(rd) @ 0b0110011
  when shamt != 0b00 & currentlyEnabled(Ext_Zba)

mapping zba_rtype_mnemonic : shamt_zba <-> string = {
  0b01 <-> "sh1add",
  0b10 <-> "sh2add",
  0b11 <-> "sh3add",
}

mapping clause assembly = ZBA_RTYPE(rs2, rs1, rd, shamt)
  <-> zba_rtype_mnemonic(shamt) ^ spc() ^ reg_name(rd) ^ sep() ^ reg_name(rs1) ^ sep() ^ reg_name(rs2)

function clause execute (ZBA_RTYPE(rs2, rs1, rd, shamt)) = {
  X(rd) = (X(rs1) << shamt) + X(rs2);
  RETIRE_SUCCESS
}
