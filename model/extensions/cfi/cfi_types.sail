// =======================================================================================
// This Sail RISC-V architecture model, comprising all files and
// directories except where otherwise noted is subject the BSD
// two-clause license in the LICENSE file.
//
// SPDX-License-Identifier: BSD-2-Clause
// =======================================================================================

type landing_pad_label = bits(20)

enum Software_Check_Code = {
  SWC_NO_INFO,
  SWC_LANDING_PAD_FAULT,
}

mapping software_check_cause : Software_Check_Code <-> bits(2) = {
  SWC_NO_INFO           <-> 0b00,
  SWC_LANDING_PAD_FAULT <-> 0b10,
}
