/*=======================================================================================*/
/*  This Sail RISC-V architecture model, comprising all files and                        */
/*  directories except where otherwise noted is subject the BSD                          */
/*  two-clause license in the LICENSE file.                                              */
/*                                                                                       */
/*  SPDX-License-Identifier: BSD-2-Clause                                                */
/*=======================================================================================*/

function clause currentlyEnabled(Ext_Zcmop) = true & currentlyEnabled(Ext_Zca) // TODO: add configuration

union clause ast = ZCMOP : (bits(3))

mapping clause encdec_compressed = ZCMOP(mop)
  <-> 0b01100 @ mop : bits(3) @ 0b100000 @ 0b01
  when currentlyEnabled(Ext_Zcmop)

mapping clause assembly = ZCMOP(mop)
  <-> "c.mop." ^ dec_bits_4(mop @ 0b1)

function clause execute ZCMOP(mop) = {
  RETIRE_SUCCESS
}
