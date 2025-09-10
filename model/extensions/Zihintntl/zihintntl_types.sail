/*=======================================================================================*/
/*  This Sail RISC-V architecture model, comprising all files and                        */
/*  directories except where otherwise noted is subject the BSD                          */
/*  two-clause license in the LICENSE file.                                              */
/*                                                                                       */
/*  SPDX-License-Identifier: BSD-2-Clause                                                */
/*=======================================================================================*/

enum ntl_type = {NTL_P1, NTL_PALL, NTL_S1, NTL_ALL}

mapping ntl_name : ntl_type <-> string = {
  NTL_P1   <-> "p1",
  NTL_PALL <-> "pall",
  NTL_S1   <-> "s1",
  NTL_ALL  <-> "all",
}

mapping encdec_ntl : ntl_type <-> bits(5) = {
  NTL_P1   <-> 0b00010,
  NTL_PALL <-> 0b00011,
  NTL_S1   <-> 0b00100,
  NTL_ALL  <-> 0b00101,
}
