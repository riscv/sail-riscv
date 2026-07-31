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

type physaddrbits_len : Int = if xlen == 32 then 34 else 64
// Maximum guest physical address width. The usable width comes from the
// hgatp mode, e.g. 41 bits for Sv39x4.
type gpalen : Int = if xlen == 32 then 34 else 64
// This is the maximum (ASIDMAX); designs can implement shorter ASIDLENs.
// The number of implemented ASID bits is configurable via `memory.asidlen`.
type asidmax    : Int = if xlen == 32 then 9 else 16
// TODO: Allow configuring shorter VMIDLENs.
type vmidlen    : Int = if xlen == 32 then 7 else 14
// GEILEN, the number of guest external interrupts. Bits GEILEN:1 of hgeip and
// hgeie are implemented, all other bit positions are read-only zero. The
// maximum is 31 for RV32 and 63 for RV64.
type geilen : Int = config extensions.H.geilen
constraint 0 <= geilen & geilen <= xlen - 1

// The number of implemented ASID bits (ASIDLEN), which may be less than
// `asidmax` (ASIDMAX), including zero. ASID bits above this value are
// read-only zero in the `Asid` field of `satp`. See the RISC-V privileged
// specification: "The number of ASID bits is UNSPECIFIED and may be zero."
type asidlen : Int = config memory.asidlen
constraint 0 <= asidlen & asidlen <= asidmax

// Variable versions of the above types. Variables and types
// are disjoint in Sail so they are allowed to have the same name.
// This saves typing `sizeof()` everywhere.
let log2_xlen = sizeof(log2_xlen)
let xlen_bytes = sizeof(xlen_bytes)
let xlen = sizeof(xlen)
let gpalen = sizeof(gpalen)
let asidmax = sizeof(asidmax)
let asidlen = sizeof(asidlen)
let vmidlen = sizeof(vmidlen)
let geilen = sizeof(geilen)

type xlenbits = bits(xlen)
type gpabits  = bits(gpalen)
type asidbits = bits(asidmax)
type vmidbits = bits(vmidlen)
