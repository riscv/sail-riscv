/*=======================================================================================*/
/*  This Sail RISC-V architecture model, comprising all files and                        */
/*  directories except where otherwise noted is subject the BSD                          */
/*  two-clause license in the LICENSE file.                                              */
/*                                                                                       */
/*  SPDX-License-Identifier: BSD-2-Clause                                                */
/*=======================================================================================*/

function clause extensionEnabled(Ext_Zimop) = true // TODO: add configuration

union clause ast = ZIMOP_MOP_R : (bits(5), regidx, regidx)
union clause ast = ZIMOP_MOP_RR : (bits(3), regidx, regidx, regidx)

mapping clause encdec = ZIMOP_MOP_R(mop_30 @ mop_27_26 @ mop_21_20, rs1, rd) if extensionEnabled(Ext_Zimop)
  <-> 0b1 @ mop_30 : bits(1) @ 0b00 @ mop_27_26 : bits(2) @ 0b0111 @ mop_21_20 : bits(2) @ rs1 @ 0b100 @ rd @ 0b1110011 if extensionEnabled(Ext_Zimop)

mapping clause encdec = ZIMOP_MOP_RR(mop_30 @ mop_27_26, rs2, rs1, rd) if extensionEnabled(Ext_Zimop)
  <-> 0b1 @ mop_30 : bits(1) @ 0b00 @ mop_27_26 : bits(2) @ 0b1 @ rs2 @ rs1 @ 0b100 @ rd @ 0b1110011 if extensionEnabled(Ext_Zimop)

mapping zimop_r_mnemonic : bits(5) <-> string = {
  0b00000 <-> "mop.r.0",
  0b00001 <-> "mop.r.1",
  0b00010 <-> "mop.r.2",
  0b00011 <-> "mop.r.3",
  0b00100 <-> "mop.r.4",
  0b00101 <-> "mop.r.5",
  0b00110 <-> "mop.r.6",
  0b00111 <-> "mop.r.7",
  0b01000 <-> "mop.r.8",
  0b01001 <-> "mop.r.9",
  0b01010 <-> "mop.r.10",
  0b01011 <-> "mop.r.11",
  0b01100 <-> "mop.r.12",
  0b01101 <-> "mop.r.13",
  0b01110 <-> "mop.r.14",
  0b01111 <-> "mop.r.15",
  0b10000 <-> "mop.r.16",
  0b10001 <-> "mop.r.17",
  0b10010 <-> "mop.r.18",
  0b10011 <-> "mop.r.19",
  0b10100 <-> "mop.r.20",
  0b10101 <-> "mop.r.21",
  0b10110 <-> "mop.r.22",
  0b10111 <-> "mop.r.23",
  0b11000 <-> "mop.r.24",
  0b11001 <-> "mop.r.25",
  0b11010 <-> "mop.r.26",
  0b11011 <-> "mop.r.27",
  0b11100 <-> "mop.r.28",
  0b11101 <-> "mop.r.29",
  0b11110 <-> "mop.r.30",
  0b11111 <-> "mop.r.31",
}

mapping zimop_rr_mnemonic : bits(3) <-> string = {
  0b000 <-> "mop.rr.0",
  0b001 <-> "mop.rr.1",
  0b010 <-> "mop.rr.2",
  0b011 <-> "mop.rr.3",
  0b100 <-> "mop.rr.4",
  0b101 <-> "mop.rr.5",
  0b110 <-> "mop.rr.6",
  0b111 <-> "mop.rr.7",
}

mapping clause assembly = ZIMOP_MOP_R(mop, rs1, rd)
  <->  zimop_r_mnemonic(mop) ^ spc() ^ reg_name(rd) ^ sep() ^ reg_name(rs1)

mapping clause assembly = ZIMOP_MOP_RR(mop, rs2, rs1, rd)
  <-> zimop_rr_mnemonic(mop) ^ spc() ^ reg_name(rd) ^ sep() ^ reg_name(rs1) ^ sep() ^ reg_name(rs2)

function clause execute ZIMOP_MOP_R(mop, rs1, rd) = {
  X(rd) = zeros();
  RETIRE_SUCCESS
}

function clause execute ZIMOP_MOP_RR(mop, rs2, rs1, rd) = {
  X(rd) = zeros();
  RETIRE_SUCCESS
}
