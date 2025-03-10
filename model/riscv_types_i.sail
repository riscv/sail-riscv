/*=======================================================================================*/
/*  This Sail RISC-V architecture model, comprising all files and                        */
/*  directories except where otherwise noted is subject the BSD                          */
/*  two-clause license in the LICENSE file.                                              */
/*                                                                                       */
/*  SPDX-License-Identifier: BSD-2-Clause                                                */
/*=======================================================================================*/

newtype regidx = Regidx : bits(5)  /* uncompressed register identifiers */

newtype regno = Regno : range(0, 31)
function regidx_to_regno (Regidx(b) : regidx) -> regno = Regno(unsigned(b))
function regidx_offset(Regidx(r) : regidx, o : bits(5)) -> regidx = Regidx(r + o)
function regidx_bits(Regidx(r) : regidx) -> bits(5) = r
