/*=======================================================================================*/
/*  This Sail RISC-V architecture model, comprising all files and                        */
/*  directories except where otherwise noted is subject the BSD                          */
/*  two-clause license in the LICENSE file.                                              */
/*                                                                                       */
/*  SPDX-License-Identifier: BSD-2-Clause                                                */
/*=======================================================================================*/

type xlen_bytes : Int = 2 ^ log2_xlen_bytes
type xlen       : Int = xlen_bytes * 8
type xlenbits         = bits(xlen)
