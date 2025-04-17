/*=======================================================================================*/
/*  This Sail RISC-V architecture model, comprising all files and                        */
/*  directories except where otherwise noted is subject the BSD                          */
/*  two-clause license in the LICENSE file.                                              */
/*                                                                                       */
/*  SPDX-License-Identifier: BSD-2-Clause                                                */
/*=======================================================================================*/

// Define the XLEN value for the architecture.
// This is done using the smallest/most logarithmic possible value since Sail's
// type system works well for multiply and 2^ but not divide and log2.

// TODO: Probably change to xlen and just use `log2_xlen_bytes = if xlen == 32 then 2 else 3` or something.
type log2_xlen_bytes : Int = config base.log2_xlen_bytes

constraint log2_xlen_bytes in {2, 3}

// TODO: Allow configuring a lower number of physical address bits.
// For example it is unlikely that serious RV64 implementations really
// have 64 physical address bits.
type physaddrbits_len : Int = if log2_xlen_bytes == 2 then 34 else 64

// This is the maximum; designs can implement shorter ASIDLENs.
// TODO: Allow configuring shorter ASIDLENs.
type asidlen    : Int = if log2_xlen_bytes == 2 then 9 else 16

type log2_xlen  : Int = log2_xlen_bytes + 3
type xlen_bytes : Int = 2 ^ log2_xlen_bytes
type xlen       : Int = xlen_bytes * 8
type xlenbits         = bits(xlen)

// Variable versions of the above types. Variables and types
// are disjoint in Sail so they are allowed to have the same name.
// This saves typing `sizeof()` everywhere.
let log2_xlen = sizeof(log2_xlen)
let log2_xlen_bytes = sizeof(log2_xlen_bytes)
let xlen_bytes = sizeof(xlen_bytes)
let xlen = sizeof(xlen)

let  asidlen          = sizeof(asidlen)
type asidbits         = bits(asidlen)
