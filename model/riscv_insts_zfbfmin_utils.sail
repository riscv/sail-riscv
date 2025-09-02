/*=======================================================================================*/
/*  This Sail RISC-V architecture model, comprising all files and                        */
/*  directories except where otherwise noted is subject the BSD                          */
/*  two-clause license in the LICENSE file.                                              */
/*                                                                                       */
/*  SPDX-License-Identifier: BSD-2-Clause                                                */
/*=======================================================================================*/

function fsplit_BF16 (v : bits(16)) -> (bits(1), bits(8), bits(7)) = (v[15..15], v[14..7], v[6..0])

function fmake_BF16 (sign : bits(1), exp : bits(8), mant : bits(7)) -> (bits(16)) = (sign @ exp @ mant)

function bf16_to_f32 (v : bits(16)) -> bits(32) = {
  let (sign, exp, mant) = fsplit_BF16(v);
  let is_nan = exp == ones() & mant != zeros();
  let is_inf = exp == ones() & mant == zeros();

  if is_nan then {
    if signed(mant) >= 0 then accrue_fflags(nvFlag());
    // 32-Bit Floating-Point NaN
    canonical_NaN_S()
  } else if is_inf then {
    // Infinity
    fmake_S(sign, ones(), zeros())
  } else {
    // Normal/Subnormal
    fmake_S(sign, exp, mant @ zeros(16))
  }
}
