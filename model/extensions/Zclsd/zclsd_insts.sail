/*=======================================================================================*/
/*  This Sail RISC-V architecture model, comprising all files and                        */
/*  directories except where otherwise noted is subject the BSD                          */
/*  two-clause license in the LICENSE file.                                              */
/*                                                                                       */
/*  SPDX-License-Identifier: BSD-2-Clause                                                */
/*=======================================================================================*/

function clause currentlyEnabled(Ext_Zclsd) = hartSupports(Ext_Zilsd) & currentlyEnabled(Ext_Zca) & not(currentlyEnabled(Ext_Zcf)) & xlen == 32

// RV32Zclsd requires even register pairs
function validZclsdReg(reg : regidx) -> bool = {
  if encdec_reg(reg)[0] == 0b1
  then match rv32load_store_pair_odd_register_reserved_behavior {
    LoadStorePair_Fatal   => reserved_behavior("Zclsd used odd-numbered register " ^ dec_str(unsigned(encdec_reg(reg)))),
    LoadStorePair_Illegal => return false,
  };
  true
}
function validZclsdCReg(reg : cregidx) -> bool = {
  if encdec_creg(reg)[0] == 0b1
  then match rv32load_store_pair_odd_register_reserved_behavior {
    LoadStorePair_Fatal   => reserved_behavior("Zclsd used odd-numbered register " ^ dec_str(unsigned(encdec_creg(reg)))),
    LoadStorePair_Illegal => return false,
  };
  true
}

/* ****************************************************************** */
union clause instruction = ZCLSD_C_LDSP : (bits(9), regidx)

$[wavedrom "C.LDSP offset[5] dest offset[4:3|8:6] C2"]
mapping clause encdec_compressed = ZCLSD_C_LDSP(ui86 @ ui5 @ ui43 @ 0b000, rd)
  <-> 0b011 @ ui5 : bits(1) @ encdec_reg(rd) @ ui43 : bits(2) @ ui86 : bits(3) @ 0b10
  when currentlyEnabled(Ext_Zclsd) & validZclsdReg(rd) & rd != zreg

function clause execute (ZCLSD_C_LDSP(imm, rd)) = {
  ExecuteAs(ZILSD_LD(zero_extend(imm), sp, rd))
}

mapping clause assembly = ZCLSD_C_LDSP(uimm, rd)
  <-> "c.ldsp" ^ spc() ^ reg_name(rd) ^ sep() ^ hex_bits_9(uimm)
  when rd != zreg

/* ****************************************************************** */
union clause instruction = ZCLSD_C_SDSP : (bits(9), regidx)

$[wavedrom "C.SDSP offset[5:3|8:6] src C2"]
mapping clause encdec_compressed = ZCLSD_C_SDSP(ui86 @ ui53 @ 0b000, rs2)
  <-> 0b111 @ ui53 : bits(3) @ ui86 : bits(3) @ encdec_reg(rs2) @ 0b10
  when currentlyEnabled(Ext_Zclsd) & validZclsdReg(rs2)

function clause execute (ZCLSD_C_SDSP(uimm, rs2)) = {
  ExecuteAs(ZILSD_SD(zero_extend(uimm), rs2, sp))
}

mapping clause assembly = ZCLSD_C_SDSP(uimm, rs2)
  <-> "c.sdsp" ^ spc() ^ reg_name(rs2) ^ sep() ^ hex_bits_9(uimm)

/* ****************************************************************** */
union clause instruction = ZCLSD_C_LD : (bits(8), cregidx, cregidx)

$[wavedrom "C.LD offset[5:3] base offset[7:6] dest C0"]
mapping clause encdec_compressed = ZCLSD_C_LD(ui76 @ ui53 @ 0b000, rs1, rd)
  <-> 0b011 @ ui53 : bits(3) @ encdec_creg(rs1) @ ui76 : bits(2) @ encdec_creg(rd) @ 0b00
  when currentlyEnabled(Ext_Zclsd) & validZclsdCReg(rd)

function clause execute (ZCLSD_C_LD(uimm, rsc, rdc)) = {
  let rd = creg2reg_idx(rdc);
  let rs = creg2reg_idx(rsc);
  ExecuteAs(ZILSD_LD(zero_extend(uimm), rs, rd))
}

mapping clause assembly = ZCLSD_C_LD(uimm, rsc, rdc)
  <-> "c.ld" ^ spc() ^ creg_name(rdc) ^ sep() ^ creg_name(rsc) ^ sep() ^ hex_bits_8(uimm)

/* ****************************************************************** */
union clause instruction = ZCLSD_C_SD : (bits(8), cregidx, cregidx)

$[wavedrom "C.SD offset[5:3] base offset[7:6] src C0"]
mapping clause encdec_compressed = ZCLSD_C_SD(ui76 @ ui53 @ 0b000, rs1, rs2)
  <-> 0b111 @ ui53 : bits(3) @ encdec_creg(rs1) @ ui76 : bits(2) @ encdec_creg(rs2) @ 0b00
  when currentlyEnabled(Ext_Zclsd) & validZclsdCReg(rs2)

function clause execute (ZCLSD_C_SD(uimm, rsc1, rsc2)) = {
  let rs1 = creg2reg_idx(rsc1);
  let rs2 = creg2reg_idx(rsc2);
  ExecuteAs(ZILSD_SD(zero_extend(uimm), rs2, rs1))
}

mapping clause assembly = ZCLSD_C_SD(uimm, rsc1, rsc2)
  <-> "c.sd" ^ spc() ^ creg_name(rsc1) ^ sep() ^ creg_name(rsc2) ^ sep() ^ hex_bits_8(uimm)
