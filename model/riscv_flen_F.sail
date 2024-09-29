/*=======================================================================================*/
/*  This Sail RISC-V architecture model, comprising all files and                        */
/*  directories except where otherwise noted is subject the BSD                          */
/*  two-clause license in the LICENSE file.                                              */
/*                                                                                       */
/*  SPDX-License-Identifier: BSD-2-Clause                                                */
/*=======================================================================================*/

/* Define the FLEN value for the 'F' extension. */

type flen       : Int = 32
type flenbits         = bits(flen)

// Variable versions of the above types. Variables and types
// are disjoint in Sail so they are allowed to have the same name.
// This saves typing `sizeof()` everywhere.
let flen = sizeof(flen)
