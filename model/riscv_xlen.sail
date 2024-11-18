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

// Variable versions of the above types. Variables and types
// are disjoint in Sail so they are allowed to have the same name.
// This saves typing `sizeof()` everywhere.
let xlen_bytes = sizeof(xlen_bytes)
let xlen = sizeof(xlen)
