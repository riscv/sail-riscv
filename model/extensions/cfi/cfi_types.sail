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
  SWC_SHADOW_STACK_FAULT,
  SWC_MEM_TAG_FAULT,
}

mapping software_check_cause : Software_Check_Code <-> bits(3) = {
  SWC_NO_INFO            <-> 0b000,
  SWC_LANDING_PAD_FAULT  <-> 0b010,
  SWC_SHADOW_STACK_FAULT <-> 0b011,
  // Memory tagging (Zimt, v0.2 DRAFT) tag mismatch
  SWC_MEM_TAG_FAULT      <-> 0b100,
}
