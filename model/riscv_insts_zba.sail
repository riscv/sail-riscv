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
union clause ast = SLLIUW : (bits(6), regidx, regidx)

mapping clause encdec = SLLIUW(shamt, rs1, rd)
  <-> 0b000010 @ shamt @ encdec_reg(rs1) @ 0b001 @ encdec_reg(rd) @ 0b0011011
  when currentlyEnabled(Ext_Zba) & xlen == 64

mapping clause assembly = SLLIUW(shamt, rs1, rd)
  <-> "slli.uw" ^ spc() ^ reg_name(rd) ^ sep() ^ reg_name(rs1) ^ sep() ^ hex_bits_6(shamt)

function clause execute (SLLIUW(shamt, rs1, rd)) = {
  let rs1_val = X(rs1);
  let result : xlenbits = zero_extend(rs1_val[31..0]) << shamt;
  X(rd) = result;
  RETIRE_SUCCESS
}

/* ****************************************************************** */
union clause ast = ZBA_RTYPEUW : (regidx, regidx, regidx, bropw_zba)

mapping clause encdec = ZBA_RTYPEUW(rs2, rs1, rd, ADDUW)
  <-> 0b0000100 @ encdec_reg(rs2) @ encdec_reg(rs1) @ 0b000 @ encdec_reg(rd) @ 0b0111011
  when currentlyEnabled(Ext_Zba) & xlen == 64

mapping clause encdec = ZBA_RTYPEUW(rs2, rs1, rd, SH1ADDUW)
  <-> 0b0010000 @ encdec_reg(rs2) @ encdec_reg(rs1) @ 0b010 @ encdec_reg(rd) @ 0b0111011
  when currentlyEnabled(Ext_Zba) & xlen == 64

mapping clause encdec = ZBA_RTYPEUW(rs2, rs1, rd, SH2ADDUW)
  <-> 0b0010000 @ encdec_reg(rs2) @ encdec_reg(rs1) @ 0b100 @ encdec_reg(rd) @ 0b0111011
  when currentlyEnabled(Ext_Zba) & xlen == 64

mapping clause encdec = ZBA_RTYPEUW(rs2, rs1, rd, SH3ADDUW)
  <-> 0b0010000 @ encdec_reg(rs2) @ encdec_reg(rs1) @ 0b110 @ encdec_reg(rd) @ 0b0111011
  when currentlyEnabled(Ext_Zba) & xlen == 64

mapping zba_rtypeuw_mnemonic : bropw_zba <-> string = {
  ADDUW    <-> "add.uw",
  SH1ADDUW <-> "sh1add.uw",
  SH2ADDUW <-> "sh2add.uw",
  SH3ADDUW <-> "sh3add.uw"
}

mapping clause assembly = ZBA_RTYPEUW(rs2, rs1, rd, op)
  <-> zba_rtypeuw_mnemonic(op) ^ spc() ^ reg_name(rd) ^ sep() ^ reg_name(rs1) ^ sep() ^ reg_name(rs2)

function clause execute (ZBA_RTYPEUW(rs2, rs1, rd, op)) = {
  let rs1_val = X(rs1);
  let rs2_val = X(rs2);
  let shamt : bits(2) = match op {
    ADDUW    => 0b00,
    SH1ADDUW => 0b01,
    SH2ADDUW => 0b10,
    SH3ADDUW => 0b11
  };
  let result : xlenbits = (zero_extend(rs1_val[31..0]) << shamt) + rs2_val;
  X(rd) = result;
  RETIRE_SUCCESS
}

/* ****************************************************************** */
union clause ast = ZBA_RTYPE : (regidx, regidx, regidx, brop_zba)

mapping clause encdec = ZBA_RTYPE(rs2, rs1, rd, SH1ADD)
  <-> 0b0010000 @ encdec_reg(rs2) @ encdec_reg(rs1) @ 0b010 @ encdec_reg(rd) @ 0b0110011
  when currentlyEnabled(Ext_Zba)
mapping clause encdec = ZBA_RTYPE(rs2, rs1, rd, SH2ADD)
  <-> 0b0010000 @ encdec_reg(rs2) @ encdec_reg(rs1) @ 0b100 @ encdec_reg(rd) @ 0b0110011
  when currentlyEnabled(Ext_Zba)
mapping clause encdec = ZBA_RTYPE(rs2, rs1, rd, SH3ADD)
  <-> 0b0010000 @ encdec_reg(rs2) @ encdec_reg(rs1) @ 0b110 @ encdec_reg(rd) @ 0b0110011
  when currentlyEnabled(Ext_Zba)

mapping zba_rtype_mnemonic : brop_zba <-> string = {
  SH1ADD <-> "sh1add",
  SH2ADD <-> "sh2add",
  SH3ADD <-> "sh3add"
}

mapping clause assembly = ZBA_RTYPE(rs2, rs1, rd, op)
  <-> zba_rtype_mnemonic(op) ^ spc() ^ reg_name(rd) ^ sep() ^ reg_name(rs1) ^ sep() ^ reg_name(rs2)

function clause execute (ZBA_RTYPE(rs2, rs1, rd, op)) = {
  let rs1_val = X(rs1);
  let rs2_val = X(rs2);
  let shamt : bits(2) = match op {
    SH1ADD => 0b01,
    SH2ADD => 0b10,
    SH3ADD => 0b11
  };
  let result : xlenbits = (rs1_val << shamt) + rs2_val;
  X(rd) = result;
  RETIRE_SUCCESS
}
