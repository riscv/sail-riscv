/*=======================================================================================*/
/*  This Sail RISC-V architecture model, comprising all files and                        */
/*  directories except where otherwise noted is subject the BSD                          */
/*  two-clause license in the LICENSE file.                                              */
/*                                                                                       */
/*  SPDX-License-Identifier: BSD-2-Clause                                                */
/*=======================================================================================*/

newtype regidx = regidx : bits(5)  /* uncompressed register identifiers */

newtype regno = regno : range(0, 31)
function regidx_to_regno (regidx(b) : regidx) -> regno = regno(unsigned(b))
function regidx_offset(regidx(r) : regidx, o : bits(5)) -> regidx = regidx(r + o)
