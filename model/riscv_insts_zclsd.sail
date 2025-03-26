/*=======================================================================================*/
/*  This Sail RISC-V architecture model, comprising all files and                        */
/*  directories except where otherwise noted is subject the BSD                          */
/*  two-clause license in the LICENSE file.                                              */
/*                                                                                       */
/*  SPDX-License-Identifier: BSD-2-Clause                                                */
/*=======================================================================================*/

function clause extensionEnabled(Ext_Zclsd) = true & extensionEnabled(Ext_Zilsd) & extensionEnabled(Ext_Zca) & not(extensionEnabled(Ext_Zcf)) & xlen == 32

/* ****************************************************************** */
union clause ast = ZCLSD_C_LDSP : (bits(9), regidx)

mapping clause encdec_compressed = ZCLSD_C_LDSP(ui86 @ ui5 @ ui43 @ 0b000, rd)        if extensionEnabled(Ext_Zclsd)
  <-> 0b011 @ ui5 : bits(1) @ encdec_reg(rd) @ ui43 : bits(2) @ ui86 : bits(3) @ 0b10 if extensionEnabled(Ext_Zclsd)

function clause execute (ZCLSD_C_LDSP(imm, rd)) = {
  execute(ZILSD_LD(zero_extend(imm), sp, rd))
}

mapping clause assembly = ZCLSD_C_LDSP(uimm, rd)
      if xlen == 32
  <-> "c.ldsp" ^ spc() ^ reg_name(rd) ^ sep() ^ hex_bits_9(uimm)
      if xlen == 32

/* ****************************************************************** */
union clause ast = ZCLSD_C_SDSP : (bits(9), regidx)

mapping clause encdec_compressed = ZCLSD_C_SDSP(ui86 @ ui53 @ 0b000, rs2) if extensionEnabled(Ext_Zclsd)
  <-> 0b111 @ ui53 : bits(3) @ ui86 : bits(3) @ encdec_reg(rs2) @ 0b10    if extensionEnabled(Ext_Zclsd)

function clause execute (ZCLSD_C_SDSP(uimm, rs2)) = {
  execute(ZILSD_SD(zero_extend(uimm), rs2, sp))
}

mapping clause assembly = ZCLSD_C_SDSP(uimm, rs2)
      if xlen == 32
  <-> "c.sdsp" ^ spc() ^ reg_name(rs2) ^ sep() ^ hex_bits_9(uimm)
      if xlen == 32

/* ****************************************************************** */
union clause ast = ZCLSD_C_LD : (bits(8), cregidx, cregidx)

mapping clause encdec_compressed = ZCLSD_C_LD(ui76 @ ui53 @ 0b000, rs1, rd)               if extensionEnabled(Ext_Zclsd)
  <-> 0b011 @ ui53 : bits(3) @ encdec_creg(rs1) @ ui76 : bits(2) @ encdec_creg(rd) @ 0b00 if extensionEnabled(Ext_Zclsd)

function clause execute (ZCLSD_C_LD(uimm, rsc, rdc)) = {
  let rd = creg2reg_idx(rdc);
  let rs = creg2reg_idx(rsc);
  execute(ZILSD_LD(zero_extend(uimm), rs, rd))
}

mapping clause assembly = ZCLSD_C_LD(uimm, rsc, rdc)
      if xlen == 32
  <-> "c.ld" ^ spc() ^ creg_name(rdc) ^ sep() ^ creg_name(rsc) ^ sep() ^ hex_bits_8(uimm)
      if xlen == 32

/* ****************************************************************** */
union clause ast = ZCLSD_C_SD : (bits(8), cregidx, cregidx)

mapping clause encdec_compressed = ZCLSD_C_SD(ui76 @ ui53 @ 0b000, rs1, rs2)               if extensionEnabled(Ext_Zclsd)
  <-> 0b111 @ ui53 : bits(3) @ encdec_creg(rs1) @ ui76 : bits(2) @ encdec_creg(rs2) @ 0b00 if extensionEnabled(Ext_Zclsd)

function clause execute (ZCLSD_C_SD(uimm, rsc1, rsc2)) = {
  let rs1 = creg2reg_idx(rsc1);
  let rs2 = creg2reg_idx(rsc2);
  execute(ZILSD_SD(zero_extend(uimm), rs2, rs1))
}

mapping clause assembly = ZCLSD_C_SD(uimm, rsc1, rsc2)
      if xlen == 32
  <-> "c.sd" ^ spc() ^ creg_name(rsc1) ^ sep() ^ creg_name(rsc2) ^ sep() ^ hex_bits_8(uimm)
      if xlen == 32
