/*=======================================================================================*/
/*  This Sail RISC-V architecture model, comprising all files and                        */
/*  directories except where otherwise noted is subject the BSD                          */
/*  two-clause license in the LICENSE file.                                              */
/*                                                                                       */
/*  SPDX-License-Identifier: BSD-2-Clause                                                */
/*=======================================================================================*/

/* This file specifies the instructions in the 'Zawrs' extension.  */

function clause extensionEnabled(Ext_Zawrs) = true

/* ****************************************************************** */
union clause ast = WRS : (wrsop)

mapping clause encdec = WRS(WRS_STO)                         if extensionEnabled(Ext_Zawrs)
  <-> 0b000000011101 @ 0b00000 @ 0b000 @ 0b00000 @ 0b1110011 if extensionEnabled(Ext_Zawrs)

mapping clause encdec = WRS(WRS_NTO)                         if extensionEnabled(Ext_Zawrs)
  <-> 0b000000001101 @ 0b00000 @ 0b000 @ 0b00000 @ 0b1110011 if extensionEnabled(Ext_Zawrs)

function clause execute (WRS(op)) =
  return RETIRE_FAIL(Wait_For_Reservation_Set(op))
