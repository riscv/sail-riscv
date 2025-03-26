/*=======================================================================================*/
/*  This Sail RISC-V architecture model, comprising all files and                        */
/*  directories except where otherwise noted is subject the BSD                          */
/*  two-clause license in the LICENSE file.                                              */
/*                                                                                       */
/*  SPDX-License-Identifier: BSD-2-Clause                                                */
/*=======================================================================================*/

function clause extensionEnabled(Ext_Zilsd) = true & xlen == 32

/* ****************************************************************** */
union clause ast = ZILSD_LD : (bits(12), regidx, regidx)

mapping clause encdec = ZILSD_LD(imm, rs1, rd)                   if extensionEnabled(Ext_Zilsd) & not(bit_to_bool(encdec_reg(rd)[0]))
  <-> imm @ encdec_reg(rs1) @ 0b011 @ encdec_reg(rd) @ 0b0000011 if extensionEnabled(Ext_Zilsd) & not(bit_to_bool(encdec_reg(rd)[0]))

function clause execute ZILSD_LD(imm, rs1, rd) = {
  let _ = execute(LOAD(imm, rs1, rd, false, WORD, false, false));
  execute(LOAD(imm+4, rs1, rd+1, false, WORD, false, false))
}

mapping clause assembly = ZILSD_LD(imm, rs1, rd) <-> "ld" ^ spc() ^ reg_name(rd) ^ sep() ^ hex_bits_signed_12(imm) ^ "(" ^ reg_name(rs1) ^ ")"

/* ****************************************************************** */
union clause ast = ZILSD_SD : (bits(12), regidx, regidx)

mapping clause encdec = ZILSD_SD(imm7 @ imm5, rs2, rs1)                                       if extensionEnabled(Ext_Zilsd) & not(bit_to_bool(encdec_reg(rs2)[0]))
  <-> imm7 : bits(7) @ encdec_reg(rs2) @ encdec_reg(rs1) @ 0b011 @ imm5 : bits(5) @ 0b0100011 if extensionEnabled(Ext_Zilsd) & not(bit_to_bool(encdec_reg(rs2)[0]))

function clause execute ZILSD_SD(imm, rs2, rs1) = {
  let _ = execute(STORE(imm, rs2, rs1, WORD, false, false));
  execute(STORE(imm+4, rs2+1, rs1, WORD, false, false))
}

mapping clause assembly = ZILSD_SD(offset, rs2, rs1) <-> "sd" ^ spc() ^ reg_name(rs2) ^ sep() ^ hex_bits_signed_12(offset) ^ "(" ^ reg_name(rs1) ^ ")"
