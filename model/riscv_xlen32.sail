/*=======================================================================================*/
/*  This Sail RISC-V architecture model, comprising all files and                        */
/*  directories except where otherwise noted is subject the BSD                          */
/*  two-clause license in the LICENSE file.                                              */
/*                                                                                       */
/*  SPDX-License-Identifier: BSD-2-Clause                                                */
/*=======================================================================================*/

/* Define the XLEN value for the architecture. */

type xlen       : Int = 32
type xlen_double : Int = 64
type xlen_bytes : Int = 4
type xlen_bytes_double : Int = 8
type xlenbits         = bits(xlen)
type xlenbits_double = bits(xlen * 2)
