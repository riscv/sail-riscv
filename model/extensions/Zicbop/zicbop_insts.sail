/*=======================================================================================*/
/*  This Sail RISC-V architecture model, comprising all files and                        */
/*  directories except where otherwise noted is subject the BSD                          */
/*  two-clause license in the LICENSE file.                                              */
/*                                                                                       */
/*  SPDX-License-Identifier: BSD-2-Clause                                                */
/*=======================================================================================*/

// Cache Block Operations - Prefetch

function clause currentlyEnabled(Ext_Zicbop) = hartSupports(Ext_Zicbop)

/* ****************************************************************** */
union clause instruction = ZICBOP : (cbop_zicbop, regidx, bits(12))

mapping encdec_cbop_zicbop : cbop_zicbop <-> bits(5) = {
  PREFETCH_I <-> 0b00000,
  PREFETCH_R <-> 0b00001,
  PREFETCH_W <-> 0b00011,
}

mapping clause encdec = ZICBOP(cbop, rs1, offset11_5 @ 0b00000)
  <-> offset11_5 @ encdec_cbop_zicbop(cbop) @ encdec_reg(rs1) @ 0b110 @ 0b00000 @ 0b0010011
  when currentlyEnabled(Ext_Zicbop)

mapping prefetch_mnemonic : cbop_zicbop <-> string = {
  PREFETCH_I <-> "prefetch.i",
  PREFETCH_R <-> "prefetch.r",
  PREFETCH_W <-> "prefetch.w"
}

mapping clause assembly = ZICBOP(cbop, rs1, offset)
  <-> prefetch_mnemonic(cbop) ^ spc() ^ hex_bits_12(offset) ^ "(" ^ opt_spc() ^ reg_name(rs1) ^ opt_spc() ^ ")"

function clause execute(ZICBOP(cbop, rs1, offset)) = RETIRE_SUCCESS
