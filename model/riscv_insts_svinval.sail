/*=======================================================================================*/
/*  This Sail RISC-V architecture model, comprising all files and                        */
/*  directories except where otherwise noted is subject the BSD                          */
/*  two-clause license in the LICENSE file.                                              */
/*                                                                                       */
/*  SPDX-License-Identifier: BSD-2-Clause                                                */
/*=======================================================================================*/

function clause extensionEnabled(Ext_Svinval) = sys_enable_svinval()

union clause ast = SINVAL_VMA : (regidx, regidx)

mapping clause encdec =
      SINVAL_VMA(rs1, rs2)                                                  if extensionEnabled(Ext_Svinval)
  <-> 0b0001011 @ rs2 : regidx @ rs1 : regidx @ 0b000 @ 0b00000 @ 0b1110011 if extensionEnabled(Ext_Svinval)

function clause execute SINVAL_VMA(rs1, rs2) = {
  execute(SFENCE_VMA(rs1, rs2))
}

mapping clause assembly = SINVAL_VMA(rs1, rs2)
  <-> "sinval.vma" ^ spc() ^ reg_name(rs1) ^ sep() ^ reg_name(rs2)

/* ****************************************************************** */

union clause ast = SFENCE_W_INVAL : unit

mapping clause encdec =
      SFENCE_W_INVAL()                                            if extensionEnabled(Ext_Svinval)
  <-> 0b0001100 @ 0b00000 @ 0b00000 @ 0b000 @ 0b00000 @ 0b1110011 if extensionEnabled(Ext_Svinval)

function clause execute SFENCE_W_INVAL() = {
  if cur_privilege == User
  then { handle_illegal(); RETIRE_FAIL }
  else { RETIRE_SUCCESS } // Implemented as no-op as all memory operations are visible immediately the current Sail model
}

mapping clause assembly = SFENCE_W_INVAL() <-> "sfence.w.inval"

/* ****************************************************************** */

union clause ast = SFENCE_INVAL_IR : unit

mapping clause encdec =
      SFENCE_INVAL_IR()                                           if extensionEnabled(Ext_Svinval)
  <-> 0b0001100 @ 0b00001 @ 0b00000 @ 0b000 @ 0b00000 @ 0b1110011 if extensionEnabled(Ext_Svinval)

function clause execute SFENCE_INVAL_IR() = {
  if cur_privilege == User
  then { handle_illegal(); RETIRE_FAIL }
  else { RETIRE_SUCCESS } // Implemented as no-op as all memory operations are visible immediately in current Sail model
}

mapping clause assembly = SFENCE_INVAL_IR() <-> "sfence.inval.ir"
