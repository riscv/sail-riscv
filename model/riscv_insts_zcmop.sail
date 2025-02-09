/*=======================================================================================*/
/*  This Sail RISC-V architecture model, comprising all files and                        */
/*  directories except where otherwise noted is subject the BSD                          */
/*  two-clause license in the LICENSE file.                                              */
/*                                                                                       */
/*  SPDX-License-Identifier: BSD-2-Clause                                                */
/*=======================================================================================*/

function clause extensionEnabled(Ext_Zcmop) = true & extensionEnabled(Ext_Zca) // TODO: add configuration

union clause ast = ZCMOP : (bits(3))

mapping clause encdec_compressed = ZCMOP(mop) if extensionEnabled(Ext_Zcmop)
  <-> 0b01100 @ mop : bits(3) @ 0b100000 @ 0b01 if extensionEnabled(Ext_Zcmop)

mapping zcmop_mnemonic : bits(3) <-> string = {
  0b000 <-> "c.mop.1",
  0b001 <-> "c.mop.3",
  0b010 <-> "c.mop.5",
  0b011 <-> "c.mop.7",
  0b100 <-> "c.mop.9",
  0b101 <-> "c.mop.11",
  0b110 <-> "c.mop.13",
  0b111 <-> "c.mop.15"
}

mapping clause assembly = ZCMOP(mop)
  <-> zcmop_mnemonic(mop)

function clause execute ZCMOP(mop) = {
  RETIRE_SUCCESS
}
