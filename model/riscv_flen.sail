/*=======================================================================================*/
/*  This Sail RISC-V architecture model, comprising all files and                        */
/*  directories except where otherwise noted is subject the BSD                          */
/*  two-clause license in the LICENSE file.                                              */
/*                                                                                       */
/*  SPDX-License-Identifier: BSD-2-Clause                                                */
/*=======================================================================================*/

type flen_bytes : Int = config base.flen_bytes

constraint flen_bytes in {4, 8}

type flen       : Int = flen_bytes * 8
type flenbits         = bits(flen)

// Variable versions of the above types. Variables and types
// are disjoint in Sail so they are allowed to have the same name.
// This saves typing `sizeof()` everywhere.
let flen_bytes = sizeof(flen_bytes)
let flen = sizeof(flen)
