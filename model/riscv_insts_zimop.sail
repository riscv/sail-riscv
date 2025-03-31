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

mapping clause encdec = ZIMOP_MOP_R(mop_30 @ mop_27_26 @ mop_21_20, rs1, rd)
  <-> 0b1 @ mop_30 : bits(1) @ 0b00 @ mop_27_26 : bits(2) @ 0b0111 @ mop_21_20 : bits(2) @ encdec_reg(rs1) @ 0b100 @ encdec_reg(rd) @ 0b1110011
  when extensionEnabled(Ext_Zimop)

mapping clause encdec = ZIMOP_MOP_RR(mop_30 @ mop_27_26, rs2, rs1, rd)
  <-> 0b1 @ mop_30 : bits(1) @ 0b00 @ mop_27_26 : bits(2) @ 0b1 @ encdec_reg(rs2) @ encdec_reg(rs1) @ 0b100 @ encdec_reg(rd) @ 0b1110011
  when extensionEnabled(Ext_Zimop)

mapping clause assembly = ZIMOP_MOP_R(mop, rs1, rd)
  <->  "mop.r." ^ dec_bits_5(mop) ^ spc() ^ reg_name(rd) ^ sep() ^ reg_name(rs1)

mapping clause assembly = ZIMOP_MOP_RR(mop, rs2, rs1, rd)
  <-> "mop.rr." ^ dec_bits_3(mop) ^ spc() ^ reg_name(rd) ^ sep() ^ reg_name(rs1) ^ sep() ^ reg_name(rs2)

function clause execute ZIMOP_MOP_R(mop, rs1, rd) = {
  X(rd) = zeros();
  RETIRE_SUCCESS
}

function clause execute ZIMOP_MOP_RR(mop, rs2, rs1, rd) = {
  X(rd) = zeros();
  RETIRE_SUCCESS
}
