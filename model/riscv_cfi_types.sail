/*=======================================================================================*/
/*  This Sail RISC-V architecture model, comprising all files and                        */
/*  directories except where otherwise noted is subject the BSD                          */
/*  two-clause license in the LICENSE file.                                              */
/*                                                                                       */
/*  SPDX-License-Identifier: BSD-2-Clause                                                */
/*=======================================================================================*/

// Landing pad label.
type lpl = bits(20)

enum Software_Check_Code = {
  SWC_NO_INFO,
  SWC_LANDING_PAD_FAULT,
}

function enc_software_check(c : Software_Check_Code) -> xlenbits =
  match c {
    SWC_NO_INFO => zeros(),
    SWC_LANDING_PAD_FAULT => zero_extend(0x2),
  }
