// =======================================================================================
// This Sail RISC-V architecture model, comprising all files and
// directories except where otherwise noted is subject the BSD
// two-clause license in the LICENSE file.
//
// SPDX-License-Identifier: BSD-2-Clause
// =======================================================================================

private function make_etrigger_flag(e : ExceptionType) -> xlenbits =
  (zero_extend(0b1) : xlenbits) << (zero_extend(exceptionType_bits(e)) : xlenbits)

private function make_itrigger_flag(i : InterruptType) -> xlenbits =
  (zero_extend(0b1) : xlenbits) << (zero_extend(interruptType_bits(i)) : xlenbits)
