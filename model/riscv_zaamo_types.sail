/*=======================================================================================*/
/*  This Sail RISC-V architecture model, comprising all files and                        */
/*  directories except where otherwise noted is subject the BSD                          */
/*  two-clause license in the LICENSE file.                                              */
/*                                                                                       */
/*  SPDX-License-Identifier: BSD-2-Clause                                                */
/*=======================================================================================*/

enum amoop = {AMOSWAP, AMOADD, AMOXOR, AMOAND, AMOOR,
              AMOMIN, AMOMAX, AMOMINU, AMOMAXU, AMOCAS}

mapping maybe_aqrl : (bool, bool) <-> string = {
  (true, true)   <-> ".aqrl",
  (true, false)  <-> ".aq",
  (false, true)  <-> ".rl",
  (false, false) <-> "",
}
