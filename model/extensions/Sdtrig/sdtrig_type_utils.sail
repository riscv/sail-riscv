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

private function is_valid_napot_compare_value(tdata2 : xlenbits) -> bool =
  match least_significant_zero(tdata2) {
    None()  => false,
    Some(i) => i < sdtrig_mcontrol6_maskmax,
  }

private function legalize_napot_compare_value(tdata2 : xlenbits) -> xlenbits =
  match least_significant_zero(tdata2) {
    None()  => [tdata2 with (sdtrig_mcontrol6_maskmax - 1) = 0b0],
    Some(i) => if i >= sdtrig_mcontrol6_maskmax
               then [tdata2 with (sdtrig_mcontrol6_maskmax - 1) = 0b0]
               else tdata2,
  }
