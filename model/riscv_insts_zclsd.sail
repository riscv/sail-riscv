/*=======================================================================================*/
/*  This Sail RISC-V architecture model, comprising all files and                        */
/*  directories except where otherwise noted is subject the BSD                          */
/*  two-clause license in the LICENSE file.                                              */
/*                                                                                       */
/*  SPDX-License-Identifier: BSD-2-Clause                                                */
/*=======================================================================================*/

function clause extensionEnabled(Ext_Zclsd) = true & extensionEnabled(Ext_Zilsd) & extensionEnabled(Ext_Zca) & not(extensionEnabled(Ext_Zcf)) & xlen == 32

/* ****************************************************************** */
union clause ast = C_LDSP_RV32 : (bits(9), regidx)

mapping clause encdec_compressed = C_LDSP_RV32(ui86 @ ui5 @ ui43 @ 0b000, rd) if extensionEnabled(Ext_Zclsd)
  <-> 0b011 @ ui5 : bits(1) @ rd @ ui43 : bits(2) @ ui86 : bits(3) @ 0b10     if extensionEnabled(Ext_Zclsd)

function clause execute (C_LDSP_RV32(imm, rd)) = {
  execute(LOAD_RV32(zero_extend(imm), sp, rd))
}

mapping clause assembly = C_LDSP_RV32(uimm, rd)
      if xlen == 32
  <-> "c.ldsp" ^ spc() ^ reg_name(rd) ^ sep() ^ hex_bits_9(uimm)
      if xlen == 32

/* ****************************************************************** */
union clause ast = C_SDSP_RV32 : (bits(9), regidx)

mapping clause encdec_compressed = C_SDSP_RV32(ui86 @ ui53 @ 0b000, rs2) if extensionEnabled(Ext_Zclsd)
  <-> 0b111 @ ui53 : bits(3) @ ui86 : bits(3) @ rs2 @ 0b10               if extensionEnabled(Ext_Zclsd)

function clause execute (C_SDSP_RV32(uimm, rs2)) = {
  execute(STORE_RV32(zero_extend(uimm), rs2, sp))
}

mapping clause assembly = C_SDSP_RV32(uimm, rs2)
      if xlen == 32
  <-> "c.sdsp" ^ spc() ^ reg_name(rs2) ^ sep() ^ hex_bits_9(uimm)
      if xlen == 32

/* ****************************************************************** */
union clause ast = C_LD_RV32 : (bits(8), cregidx, cregidx)

mapping clause encdec_compressed = C_LD_RV32(ui76 @ ui53 @ 0b000, rs1, rd) if extensionEnabled(Ext_Zclsd)
  <-> 0b011 @ ui53 : bits(3) @ rs1 @ ui76 : bits(2) @ rd @ 0b00            if extensionEnabled(Ext_Zclsd)

function clause execute (C_LD_RV32(uimm, rsc, rdc)) = {
  let rd = creg2reg_idx(rdc);
  let rs = creg2reg_idx(rsc);
  execute(LOAD_RV32(zero_extend(uimm), rs, rd))
}

mapping clause assembly = C_LD_RV32(uimm, rsc, rdc)
      if xlen == 32
  <-> "c.ld" ^ spc() ^ creg_name(rdc) ^ sep() ^ creg_name(rsc) ^ sep() ^ hex_bits_8(uimm)
      if xlen == 32

/* ****************************************************************** */
union clause ast = C_SD_RV32 : (bits(8), cregidx, cregidx)

mapping clause encdec_compressed = C_SD_RV32(ui76 @ ui53 @ 0b000, rs1, rs2) if extensionEnabled(Ext_Zclsd)
  <-> 0b111 @ ui53 : bits(3) @ rs1 @ ui76 : bits(2) @ rs2 @ 0b00            if extensionEnabled(Ext_Zclsd)

function clause execute (C_SD_RV32(uimm, rsc1, rsc2)) = {
  let rs1 = creg2reg_idx(rsc1);
  let rs2 = creg2reg_idx(rsc2);
  execute(STORE_RV32(zero_extend(uimm), rs2, rs1))
}

mapping clause assembly = C_SD_RV32(uimm, rsc1, rsc2)
      if xlen == 32
  <-> "c.sd" ^ spc() ^ creg_name(rsc1) ^ sep() ^ creg_name(rsc2) ^ sep() ^ hex_bits_8(uimm)
      if xlen == 32
