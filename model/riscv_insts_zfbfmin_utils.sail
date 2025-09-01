/*=======================================================================================*/
/*  This Sail RISC-V architecture model, comprising all files and                        */
/*  directories except where otherwise noted is subject the BSD                          */
/*  two-clause license in the LICENSE file.                                              */
/*                                                                                       */
/*  SPDX-License-Identifier: BSD-2-Clause                                                */
/*=======================================================================================*/

function split_BF16 (v : bits(16)) -> (bits(1), bits(8), bits(7)) = (v[15..15], v[14..7], v[6..0])

function bf16_to_f32 (v : bits(16)) -> bits(32) = {
  let (sign, exp, mant) = split_BF16(v);
  let is_nan = exp == 0xFF & mant != 0b0000000;
  let is_inf = exp == 0xFF & mant == 0b0000000;

  if is_nan then {
    if mant[6] == bitzero then accrue_fflags(nvFlag());
    // 32-Bit Floating-Point NaN
    canonical_NaN_S()
  } else if is_inf then {
    // Infinity
    sign @ 0xFF @ zeros(23)
  } else {
    // Normal/Subnormal
    sign @ exp @ mant @ zeros(16)
  }
}
