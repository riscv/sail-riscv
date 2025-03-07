/*=======================================================================================*/
/*  This Sail RISC-V architecture model, comprising all files and                        */
/*  directories except where otherwise noted is subject the BSD                          */
/*  two-clause license in the LICENSE file.                                              */
/*                                                                                       */
/*  SPDX-License-Identifier: BSD-2-Clause                                                */
/*=======================================================================================*/

function clause extensionEnabled(Ext_Zilsd) = true & xlen == 32

/* ****************************************************************** */
union clause ast = LOAD_RV32 : (bits(12), regidx, regidx)

mapping clause encdec = LOAD_RV32(imm, rs1, rd) if extensionEnabled(Ext_Zilsd)
  <-> imm @ rs1 @ 0b011 @ rd @ 0b0000011        if extensionEnabled(Ext_Zilsd)

function clause execute LOAD_RV32(imm, rs1, rd) = {
  // Use of misaligned (odd-numbered) registers is reserved.
  assert(regidx_to_regno(rd) % 2 == 0);
  let _ = execute(LOAD(imm, rs1, rd, false, WORD, false, false));
  execute(LOAD(imm+4, rs1, rd+1, false, WORD, false, false))
}

mapping clause assembly = LOAD_RV32(imm, rs1, rd) <-> "ld" ^ spc() ^ reg_name(rd) ^ sep() ^ hex_bits_signed_12(imm) ^ "(" ^ reg_name(rs1) ^ ")"

/* ****************************************************************** */
union clause ast = STORE_RV32 : (bits(12), regidx, regidx)

mapping clause encdec = STORE_RV32(imm7 @ imm5, rs2, rs1)             if extensionEnabled(Ext_Zilsd)
  <-> imm7 : bits(7) @ rs2 @ rs1 @ 0b011 @ imm5 : bits(5) @ 0b0100011 if extensionEnabled(Ext_Zilsd)

function clause execute STORE_RV32(imm, rs2, rs1) = {
  // Use of misaligned (odd-numbered) registers is reserved.
  assert(regidx_to_regno(rs2) % 2 == 0);
  let _ = execute(STORE(imm, rs2, rs1, WORD, false, false));
  execute(STORE(imm+4, rs2+1, rs1, WORD, false, false))
}

mapping clause assembly = STORE_RV32(offset, rs2, rs1) <-> "sd" ^ spc() ^ reg_name(rs2) ^ sep() ^ hex_bits_signed_12(offset) ^ "(" ^ reg_name(rs1) ^ ")"
