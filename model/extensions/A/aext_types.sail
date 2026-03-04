// =======================================================================================
// This Sail RISC-V architecture model, comprising all files and
// directories except where otherwise noted is subject the BSD
// two-clause license in the LICENSE file.
//
// SPDX-License-Identifier: BSD-2-Clause
// =======================================================================================

// These enums are arranged according to the level of PMA support they require:
// AMOSwap < AMOLogical < AMOArithmetic < AMOCASW < AMOCASD < AMOCASQ
enum amoop = {
  AMOSWAP,
  AMOAND, AMOOR, AMOXOR,
  AMOADD, AMOMIN, AMOMAX, AMOMINU, AMOMAXU,
  AMOCAS
}

mapping amo_mnemonic : amoop <-> string = {
  AMOSWAP <-> "amoswap",
  AMOAND  <-> "amoand",
  AMOOR   <-> "amoor",
  AMOXOR  <-> "amoxor",
  AMOADD  <-> "amoadd",
  AMOMIN  <-> "amomin",
  AMOMAX  <-> "amomax",
  AMOMINU <-> "amominu",
  AMOMAXU <-> "amomaxu",
  AMOCAS  <-> "amocas",
}

mapping maybe_aqrl : (bool, bool) <-> string = {
  (true, true)   <-> ".aqrl",
  (true, false)  <-> ".aq",
  (false, true)  <-> ".rl",
  (false, false) <-> "",
}
