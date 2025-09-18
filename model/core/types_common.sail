// =======================================================================================
// This Sail RISC-V architecture model, comprising all files and
// directories except where otherwise noted is subject the BSD
// two-clause license in the LICENSE file.
//
// SPDX-License-Identifier: BSD-2-Clause
// =======================================================================================

// Exception codes above 64 are reserved, and there
// isn't space for them medeleg[h] so it is unclear
// how they would work anyway.
//
// Note this type is currently used for exceptions
// and interrupts, which is unfortunate because
// exceptions are always <64, but interrupts are <xlen
// (except with AIA when they are also <64).
type exc_code = bits(6)
