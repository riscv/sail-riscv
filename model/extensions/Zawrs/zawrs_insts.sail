/*=======================================================================================*/
/*  This Sail RISC-V architecture model, comprising all files and                        */
/*  directories except where otherwise noted is subject the BSD                          */
/*  two-clause license in the LICENSE file.                                              */
/*                                                                                       */
/*  SPDX-License-Identifier: BSD-2-Clause                                                */
/*=======================================================================================*/

/* This file specifies the instructions in the 'Zawrs' extension.  */

function clause currentlyEnabled(Ext_Zawrs) = hartSupports(Ext_Zawrs)

/* ****************************************************************** */

union clause instruction = WRS : (wrsop)
mapping encdec_wrsop : wrsop <-> bits(12) = {
  WRS_STO <-> 0b000000011101,
  WRS_NTO <-> 0b000000001101,
}

mapping clause encdec = WRS(op)
  <-> encdec_wrsop(op) @ 0b00000 @ 0b000 @ 0b00000 @ 0b1110011
  when currentlyEnabled(Ext_Zawrs)

function clause execute (WRS(WRS_STO)) =
  Enter_Wait(WAIT_WRS_STO)

function clause execute (WRS(WRS_NTO)) =
  Enter_Wait(WAIT_WRS_NTO)

mapping clause assembly = WRS(WRS_STO) <-> "wrs.sto"
mapping clause assembly = WRS(WRS_NTO) <-> "wrs.nto"
