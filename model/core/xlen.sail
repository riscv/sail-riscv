// =======================================================================================
// This Sail RISC-V architecture model, comprising all files and
// directories except where otherwise noted is subject the BSD
// two-clause license in the LICENSE file.
//
// SPDX-License-Identifier: BSD-2-Clause
// =======================================================================================

// Define the XLEN value for the architecture.
// This is done using the smallest/most logarithmic possible value since Sail's
// type system works well for multiply and 2^ but not divide and log2.

type xlen : Int = config base.xlen
constraint xlen in {32, 64}

type log2_xlen  : Int = if xlen == 32 then 5 else 6
type xlen_bytes : Int = if xlen == 32 then 4 else 8

// TODO: Allow configuring a lower number of physical address bits.
// For example it is unlikely that serious RV64 implementations really
// have 64 physical address bits.
type physaddrbits_len : Int = if xlen == 32 then 34 else 64

// This is the maximum; designs can implement shorter ASIDLENs.
// TODO: Allow configuring shorter ASIDLENs.
type asidlen    : Int = if xlen == 32 then 9 else 16

// Variable versions of the above types. Variables and types
// are disjoint in Sail so they are allowed to have the same name.
// This saves typing `sizeof()` everywhere.
let log2_xlen = sizeof(log2_xlen)
let xlen_bytes = sizeof(xlen_bytes)
let xlen = sizeof(xlen)
let asidlen = sizeof(asidlen)

type xlenbits = bits(xlen)
type asidbits = bits(asidlen)
