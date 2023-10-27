/*=======================================================================================*/
/*  This Sail RISC-V architecture model, comprising all files and                        */
/*  directories except where otherwise noted is subject the BSD                          */
/*  two-clause license in the LICENSE file.                                              */
/*                                                                                       */
/*  SPDX-License-Identifier: BSD-2-Clause                                                */
/*=======================================================================================*/

/* *********************************************************************** */
/* This file specifies the atomic instructions in the 'Zalasr' extension.  */

/* *********************************************************************** */

function clause extensionEnabled(Ext_Zalasr) = true

union clause ast = LOADAQ : (bool, bool, regidx, word_width, regidx)

mapping clause encdec = LOADAQ(aq, rl, rs1, size, rd)                                                 if extensionEnabled(Ext_Zalasr)
  <-> 0b00110 @ bool_bits(aq) @ bool_bits(rl) @ 0b00000 @ rs1 @ 0b0 @ size_enc(size) @ rd @ 0b0101111 if extensionEnabled(Ext_Zalasr)

function clause execute(LOADAQ(aq, rl, rs1, width, rd)) = {
  // load-acquire is required to have the acquire bit set
  if not(aq)
  then { handle_illegal(); RETIRE_FAIL }
  else {
    execute(LOAD(zeros(), rs1, rd, false, width, aq, rl))
  }
}

mapping clause assembly = LOADAQ(aq, rl, rs1, size, rd)
                      <-> "l" ^ size_mnemonic(size)
                          ^ maybe_aq(aq) ^ maybe_rl(rl)
                          ^ spc() ^ reg_name(rd)
                          ^ sep() ^ "(" ^ reg_name(rs1) ^ ")"

union clause ast = STORERL : (bool, bool, regidx, regidx, word_width)
mapping clause encdec = STORERL(aq, rl, rs2, rs1, size)                                                if extensionEnabled(Ext_Zalasr)
  <-> 0b00111 @ bool_bits(aq) @ bool_bits(rl) @ rs2 @ rs1 @ 0b0 @ size_enc(size) @ 0b00000 @ 0b0101111 if extensionEnabled(Ext_Zalasr)

function clause execute (STORERL(aq, rl, rs2, rs1, width)) = {
  // store-release is required to have the release bit set
  if not(rl)
  then { handle_illegal(); RETIRE_FAIL }
  else {
    execute(STORE(zeros(), rs2, rs1, width, aq, rl))
  }
}

mapping clause assembly = STORERL(aq, rl, rs2, rs1, size)
                      <-> "s" ^ size_mnemonic(size)
                          ^ maybe_aq(aq) ^ maybe_rl(rl)
                          ^ spc() ^ reg_name(rs2)
                          ^ sep() ^ "(" ^ reg_name(rs1) ^ ")"
