// =======================================================================================
// This Sail RISC-V architecture model, comprising all files and
// directories except where otherwise noted is subject the BSD
// two-clause license in the LICENSE file.
//
// SPDX-License-Identifier: BSD-2-Clause
// =======================================================================================

// Reservation handling for LR/SC.
//
// The reservation state is maintained external to the model since the
// reservation behavior is platform-specific anyway and maintaining
// this state outside the model simplifies the concurrency analysis.
//
// These are externs are defined here in the system module since
// we currently perform reservation cancellation on privilege level
// transition.  Ideally, the platform should get more visibility into
// where cancellation can be performed.

val load_reservation = impure {interpreter: "Platform.load_reservation", cpp: "load_reservation", lem: "load_reservation"} : physaddrbits -> unit
val match_reservation = pure {interpreter: "Platform.match_reservation", lem: "match_reservation", cpp: "match_reservation"} : physaddrbits -> bool
val cancel_reservation = impure {interpreter: "Platform.cancel_reservation", cpp: "cancel_reservation", lem: "cancel_reservation"} : unit -> unit
val valid_reservation = pure {interpreter: "Platform.valid_reservation", cpp: "valid_reservation", lem: "valid_reservation"} : unit -> bool
