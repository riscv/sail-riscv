/*=======================================================================================*/
/*  This Sail RISC-V architecture model, comprising all files and                        */
/*  directories except where otherwise noted is subject the BSD                          */
/*  two-clause license in the LICENSE file.                                              */
/*                                                                                       */
/*  SPDX-License-Identifier: BSD-2-Clause                                                */
/*=======================================================================================*/

function clause currentlyEnabled(Ext_Zihintpause) = hartSupports(Ext_Zihintpause)

union clause instruction = PAUSE : unit

// PAUSE is encoded as a FENCE
mapping clause encdec = PAUSE()
  <-> 0b0000 @ 0b0001 @ 0b0000 @ 0b00000 @ 0b000 @ 0b00000 @ 0b0001111
  when currentlyEnabled(Ext_Zihintpause)

// PAUSE is a hint
function clause execute PAUSE() = RETIRE_SUCCESS

mapping clause assembly = PAUSE() <-> "pause"
