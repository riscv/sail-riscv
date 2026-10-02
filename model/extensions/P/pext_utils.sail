// =======================================================================================
// This Sail RISC-V architecture model, comprising all files and
// directories except where otherwise noted is subject the BSD
// two-clause license in the LICENSE file.
//
// SPDX-License-Identifier: BSD-2-Clause
// =======================================================================================

// The saturating helpers below record overflow in the vxsat CSR (shared with
// the vector extension), as required by the in-progress P specification.

val neg : forall 'n, 'n == 8 | 'n == 16 | 'n == 32 | 'n == 64.
  (bits ('n)) -> bits ('n)
function neg (v) = not_vec(v) + 1

val count_leading_sign_bits : forall 'n, 'n == 32 | 'n == 64. (bits('n)) -> range(0, 'n)
function count_leading_sign_bits(x) = {
  var count : range(0, 'n) = 0;
  var counting : bool = true;
  let msb : bit = x['n - 1];

  foreach (i from ('n - 2) downto 0) {
    if x[i] == msb & counting then {
      let new_count = count + 1;
      assert(new_count <= 'n);
      count = new_count;
    } else {
      counting = false;
    }
  };
  count
}

val abs : forall 'n, 'n == 8 | 'n == 16 | 'n == 32 | 'n == 64. (bits('n)) -> (bits('n))
function abs(x) = {
  var res : bits('n) = x;

  if res['n - 1] == bitone then {
    res = ~(res) + zero_extend(0b1);
  };

  res
}

val sabs : forall 'n, 'n == 8 | 'n == 16 | 'n == 32.
  (bits('n)) -> bits('n)
function sabs (v) =
  let lb : bits('n) = not_vec(ones('n) >> 1) in
  // Only the most negative value saturates (and sets vxsat); the plain
  // absolute value of any other negative input is exact.
  if v == lb then { write_vxsat(0b1); not_vec(lb) }
  else if v <_s zeros('n) then neg(v)
  else v

val shift_left_arith : forall 'm, ('m == 8 | 'm == 16 | 'm == 32 | 'm == 64).
  (bits ('m), nat) -> bits ('m)
function shift_left_arith (value, shift) =
  // A plain (wrapping) shift left; the saturating variant is sat_shift_left_arith.
  let vext : bits(xlen + 256) = sign_extend(value) in
  slice(vext << shift, 0, 'm)

val sat_shift_left_arith : forall 'm, ('m == 8 | 'm == 16 | 'm == 32 | 'm == 64).
  (bits ('m), nat) -> bits ('m)
function sat_shift_left_arith (value, shift) =
  let ub : bits(xlen + 256) = sign_extend(ones('m) >> 1) in
  let lb : bits(xlen + 256) = not_vec(ub) in
  let vext : bits(xlen + 256) = sign_extend(value) in
  let shiftext : bits(xlen + 256) = vext << shift in
  if shiftext <_s lb then { write_vxsat(0b1); not_vec(ones('m) >> 1) }
  else if ub <_s shiftext then { write_vxsat(0b1); ones('m) >> 1 }
  else slice(shiftext, 0, 'm)

val sat_shift_left_logic : forall 'm, ('m == 8 | 'm == 16 | 'm == 32 | 'm == 64).
  (bits ('m), nat) -> bits ('m)
function sat_shift_left_logic (value, shift) =
  let ub : bits(xlen + 256) = zero_extend(ones('m)) in
  let vext : bits(xlen + 256) = zero_extend(value) in
  let shiftext : bits(xlen + 256) = vext << shift in
  if ub <_s shiftext then { write_vxsat(0b1); ones('m) }
  else slice(shiftext, 0, 'm)

// Arithmetic right shift by an integer amount. This lived in the model prelude
// until upstream #1559 moved integer-amount shifts to the Sail standard library
// and dropped it; the P helpers still need the integer-amount form, so keep a
// self-contained copy here.
val shift_right_arith : forall 'm 'n, 'n >= 1 & 'm >= 0 . (bits('n), int('m)) -> bits('n)
function shift_right_arith(value, shift) =
  sign_extend('n + shift, value)[('n - 1 + shift) .. shift]

val shift_right_arith_rounding : forall 'n, 'n == 8 | 'n == 16 | 'n == 32 | 'n == 64 | 'n == 128.
  (bits ('n), nat) -> bits ('n)
function shift_right_arith_rounding (value, shift) =
  if shift == 0 then value
  else let res : bits(257) = add_bits(sign_extend(shift_right_arith(value @ 0b0, shift)), zero_extend(0b1)) in
  slice(res, 1, 'n)

val shift_right_logic_rounding : forall 'n, 'n == 8 | 'n == 16 | 'n == 32 | 'n == 64 | 'n == 128.
  (bits ('n), nat) -> bits ('n)
function shift_right_logic_rounding (value, shift) =
  if shift == 0 then value
  else let res : bits(257) = add_bits(zero_extend((value @ 0b0) >> shift), zero_extend(0b1)) in
  slice(res, 1, 'n)

val ssha : forall 'n, 'n == 8 | 'n == 16 | 'n == 32 | 'n == 64.
  (bits ('n), int) -> bits ('n)
function ssha (value, shift) =
  if shift < 0 then shift_right_arith(value, abs_int(shift))
  else sat_shift_left_arith(value, shift)

val sshar : forall 'n, 'n == 8 | 'n == 16 | 'n == 32 | 'n == 64.
  (bits ('n), int) -> bits ('n)
function sshar (value, shift) =
  if shift < 0 then shift_right_arith_rounding(value, abs_int(shift))
  else sat_shift_left_arith(value, shift)

val sshl : forall 'n, 'n == 8 | 'n == 16 | 'n == 32 | 'n == 64.
  (bits ('n), int) -> bits ('n)
function sshl (value, shift) =
  if shift < 0 then value >> abs_int(shift)
  else sat_shift_left_logic(value, shift)

val sshlr : forall 'n, 'n == 8 | 'n == 16 | 'n == 32 | 'n == 64.
  (bits ('n), int) -> bits ('n)
function sshlr (value, shift) =
  if shift < 0 then shift_right_logic_rounding(value, abs_int(shift))
  else sat_shift_left_logic(value, shift)

val sha : forall 'n, 'n == 8 | 'n == 16 | 'n == 32 | 'n == 64.
  (bits ('n), int) -> bits ('n)
function sha (value, shift) =
  if shift < 0 then shift_right_arith(value, abs_int(shift))
  else shift_left_arith(value, shift)

val shar : forall 'n, 'n == 8 | 'n == 16 | 'n == 32 | 'n == 64.
  (bits ('n), int) -> bits ('n)
function shar (value, shift) =
  if shift < 0 then shift_right_arith_rounding(value, abs_int(shift))
  else shift_left_arith(value, shift)

val shl : forall 'n, 'n == 8 | 'n == 16 | 'n == 32 | 'n == 64.
  (bits ('n), int) -> bits ('n)
function shl (value, shift) =
  if shift < 0 then value >> abs_int(shift)
  else value << shift

val shlr : forall 'n, 'n == 8 | 'n == 16 | 'n == 32 | 'n == 64.
  (bits ('n), int) -> bits ('n)
function shlr (value, shift) =
  if shift < 0 then shift_right_logic_rounding(value, abs_int(shift))
  else value << shift

val sadd : forall 'n, 'n == 8 | 'n == 16 | 'n == 32 | 'n == 64.
  (bits('n), bits('n)) -> bits('n)
function sadd (v1, v2) =
  let ub : bits(66) = sign_extend(ones('n) >> 1) in
  let lb : bits(66) = not_vec (ub) in
  let v1ext : bits(66) = sign_extend(v1) in
  let v2ext : bits(66) = sign_extend(v2) in
  let sumext = v1ext + v2ext in
  if sumext <_s lb then { write_vxsat(0b1); not_vec (ones ('n) >> 1) }
  else if ub <_s sumext then { write_vxsat(0b1); ones ('n) >> 1 }
  else { slice (sumext, 0, 'n) }

val saddu : forall 'n, 'n == 8 | 'n == 16 | 'n == 32 | 'n == 64.
  (bits('n), bits('n)) -> bits('n)
function saddu (v1, v2) =
  let ub : bits(66) = zero_extend(ones('n)) in
  let v1ext : bits(66) = zero_extend(v1) in
  let v2ext : bits(66) = zero_extend(v2) in
  let sumext = v1ext + v2ext in
  if ub <_u sumext then { write_vxsat(0b1); ones('n) }
  else { slice (sumext, 0, 'n) }

val aadd : forall 'n, 'n == 8 | 'n == 16 | 'n == 32 | 'n == 64.
  (bits('n), bits('n)) -> bits('n)
function aadd (v1, v2) =
  let v1ext : bits(66) = sign_extend(v1) in
  let v2ext : bits(66) = sign_extend(v2) in
  slice ((v1ext + v2ext) >> 1, 0, 'n)

val aaddu : forall 'n, 'n == 8 | 'n == 16 | 'n == 32 | 'n == 64.
  (bits('n), bits('n)) -> bits('n)
function aaddu (v1, v2) =
  let v1ext : bits(66) = zero_extend(v1) in
  let v2ext : bits(66) = zero_extend(v2) in
  slice ((v1ext + v2ext) >> 1, 0, 'n)

val ssub : forall 'n, 'n == 8 | 'n == 16 | 'n == 32 | 'n == 64.
  (bits('n), bits('n)) -> bits('n)
function ssub (v1, v2) =
  let ub : bits(66) = sign_extend(ones('n) >> 1) in
  let lb : bits(66) = not_vec (ub) in
  let v1ext : bits(66) = sign_extend(v1) in
  let v2ext : bits(66) = sign_extend(v2) in
  let diffext = v1ext - v2ext in
  if diffext <_s lb then { write_vxsat(0b1); not_vec (ones ('n) >> 1) }
  else if ub <_s diffext then { write_vxsat(0b1); ones ('n) >> 1 }
  else { slice (diffext, 0, 'n) }

val asub : forall 'n, 'n == 8 | 'n == 16 | 'n == 32 | 'n == 64.
  (bits('n), bits('n)) -> bits('n)
function asub (v1, v2) =
  let v1ext : bits(66) = sign_extend(v1) in
  let v2ext : bits(66) = sign_extend(v2) in
  slice ((v1ext - v2ext) >> 1, 0, 'n)

// Unsigned saturating subtract: saturates to zero (and sets vxsat) on underflow.
val ssubu : forall 'n, 'n == 8 | 'n == 16 | 'n == 32 | 'n == 64.
  (bits('n), bits('n)) -> bits('n)
function ssubu (v1, v2) =
  let v1ext : bits(66) = zero_extend(v1) in
  let v2ext : bits(66) = zero_extend(v2) in
  let diffext = v1ext - v2ext in
  if diffext <_s zeros(66) then { write_vxsat(0b1); zeros('n) }
  else { slice (diffext, 0, 'n) }

val asubu : forall 'n, 'n == 8 | 'n == 16 | 'n == 32 | 'n == 64.
  (bits('n), bits('n)) -> bits('n)
function asubu (v1, v2) =
  let v1ext : bits(66) = zero_extend(v1) in
  let v2ext : bits(66) = zero_extend(v2) in
  slice ((v1ext - v2ext) >> 1, 0, 'n)

val muls : forall 'n, 'n == 8 | 'n == 16 | 'n == 32 | 'n == 64.
  (bits('n), bits('n)) -> bits(2 * 'n)
function muls (v1, v2) =
  to_bits_truncate (2 * 'n, signed(v1) * signed(v2))

val mulu : forall 'n, 'n == 8 | 'n == 16 | 'n == 32 | 'n == 64.
  (bits('n), bits('n)) -> bits(2 * 'n)
function mulu (v1, v2) =
  to_bits_truncate (2 * 'n, unsigned(v1) * unsigned(v2))

val mulsu : forall 'n, 'n == 8 | 'n == 16 | 'n == 32 | 'n == 64.
  (bits('n), bits('n)) -> bits(2 * 'n)
function mulsu (v1, v2) =
 to_bits_truncate (2 * 'n, signed(v1) * unsigned(v2))

val mulh : forall 'n, 'n == 8 | 'n == 16 | 'n == 32 | 'n == 64.
  (bits('n), bits('n)) -> bits('n)
function mulh (v1, v2) =
  slice(shift_right_arith(muls(v1, v2), 'n), 0, 'n)

val mulhu : forall 'n, 'n == 8 | 'n == 16 | 'n == 32 | 'n == 64.
  (bits('n), bits('n)) -> bits('n)
function mulhu (v1, v2) =
  slice(mulu(v1, v2) >> 'n, 0, 'n)

val mulhr : forall 'n, 'n == 8 | 'n == 16 | 'n == 32 | 'n == 64.
  (bits('n), bits('n)) -> bits('n)
function mulhr (v1, v2) =
  slice(shift_right_arith_rounding(muls(v1, v2), 'n), 0, 'n)

val mulhru : forall 'n, 'n == 8 | 'n == 16 | 'n == 32 | 'n == 64.
  (bits('n), bits('n)) -> bits('n)
function mulhru (v1, v2) =
  slice(shift_right_logic_rounding(mulu(v1, v2), 'n), 0, 'n)

val mulhsu : forall 'n, 'n == 8 | 'n == 16 | 'n == 32 | 'n == 64.
  (bits('n), bits('n)) -> bits('n)
function mulhsu (v1, v2) =
  slice(shift_right_arith(mulsu(v1, v2), 'n), 0, 'n)

// Mixed-width high-half products, as the spec writes them: the (n+m)-bit
// product of an n-bit and an m-bit operand, keeping bits [n+m-1 .. m]
// (e.g. to_bits(24, s1_h * s2_b)[23..8] for a halfword x byte product).
val mulh_mixed : forall 'n 'm, ('n == 16 | 'n == 32) & ('m == 8 | 'm == 16).
  (bits('n), bits('m)) -> bits('n)
function mulh_mixed (v1, v2) =
  get_slice_int('n, signed(v1) * signed(v2), 'm)

val mulhsu_mixed : forall 'n 'm, ('n == 16 | 'n == 32) & ('m == 8 | 'm == 16).
  (bits('n), bits('m)) -> bits('n)
function mulhsu_mixed (v1, v2) =
  get_slice_int('n, signed(v1) * unsigned(v2), 'm)

val mulhrsu : forall 'n, 'n == 8 | 'n == 16 | 'n == 32 | 'n == 64.
  (bits('n), bits('n)) -> bits('n)
function mulhrsu (v1, v2) =
  slice(shift_right_logic_rounding(mulsu(v1, v2), 'n), 0, 'n)

val mulq : forall 'n, 'n == 8 | 'n == 16 | 'n == 32.
  (bits('n), bits('n)) -> bits(2 * 'n)
function mulq (v1, v2) =
  shift_right_arith(muls(v1, v2), 'n - 1)

val mulq_sat : forall 'n, 'n == 8 | 'n == 16 | 'n == 32.
  (bits('n), bits('n)) -> bits(2 * 'n)
function mulq_sat (v1, v2) =
  let lb : bits(66) = not_vec(sign_extend(ones ('n) >> 1)) in
  if (sign_extend(v1) == lb) & (sign_extend(v2) == lb) then { write_vxsat(0b1); sign_extend(ones ('n) >> 1) }
  else shift_right_arith(muls(v1, v2), 'n - 1)

val mulqr : forall 'n, 'n == 8 | 'n == 16 | 'n == 32.
  (bits('n), bits('n)) -> bits(2 * 'n)
function mulqr (v1, v2) =
  shift_right_arith_rounding(muls(v1, v2), 'n - 1)

val mulqr_sat : forall 'n, 'n == 8 | 'n == 16 | 'n == 32.
  (bits('n), bits('n)) -> bits(2 * 'n)
function mulqr_sat (v1, v2) =
  let lb : bits(66) = not_vec(sign_extend(ones ('n) >> 1)) in
  if (sign_extend(v1) == lb) & (sign_extend(v2) == lb) then { write_vxsat(0b1); sign_extend(ones ('n) >> 1) }
  else shift_right_arith_rounding(muls(v1, v2), 'n - 1)

val mseq : forall 'n, 'n == 8 | 'n == 16 | 'n == 32.
  (bits('n), bits('n)) -> bits('n)
function mseq (v1, v2) =
  if v1 == v2 then ones() else zeros()

val mslt : forall 'n, 'n == 8 | 'n == 16 | 'n == 32.
  (bits('n), bits('n)) -> bits('n)
function mslt (v1, v2) =
  if v1 <_s v2 then ones() else zeros()

val msltu : forall 'n, 'n == 8 | 'n == 16 | 'n == 32.
  (bits('n), bits('n)) -> bits('n)
function msltu (v1, v2) =
  if v1 <_u v2 then ones() else zeros()

val mins : forall 'n, 'n == 8 | 'n == 16 | 'n == 32.
  (bits('n), bits('n)) -> bits('n)
function mins (v1, v2) =
  if v1 <_s v2 then v1 else v2

val minu : forall 'n, 'n == 8 | 'n == 16 | 'n == 32.
  (bits('n), bits('n)) -> bits('n)
function minu (v1, v2) =
  if v1 <_u v2 then v1 else v2

val maxs : forall 'n, 'n == 8 | 'n == 16 | 'n == 32.
  (bits('n), bits('n)) -> bits('n)
function maxs (v1, v2) =
  if v1 >_s v2 then v1 else v2

val maxu : forall 'n, 'n == 8 | 'n == 16 | 'n == 32.
  (bits('n), bits('n)) -> bits('n)
function maxu (v1, v2) =
  if v1 >_u v2 then v1 else v2

val nclips : forall 'n 'm, ('n == 8 | 'n == 16 | 'n == 32 | 'n == 64) & 'n == 'm * 2.
  (implicit('m), bits('n), nat) -> bits('m)
function nclips (m, value, shift) =
  let ub : bits('n) = sign_extend(ones ('m) >> 1) in
  let lb : bits('n) = not_vec (ub) in
  let shiftext : bits('n) = shift_right_arith(value, shift) in
  if shiftext <_s lb then { write_vxsat(0b1); lb[('m - 1)..0] }
  else if ub <_s shiftext then { write_vxsat(0b1); ub[('m - 1)..0] }
  else shiftext[('m - 1)..0]

val nclipu : forall 'n 'm, ('n == 8 | 'n == 16 | 'n == 32 | 'n == 64) & 'n == 'm * 2.
  (implicit('m), bits('n), nat) -> bits('m)
function nclipu (m, value, shift) =
  let ub : bits('n) = zero_extend(ones ('m)) in
  let shiftext : bits('n) = value >> shift in
  if ub <_u shiftext then { write_vxsat(0b1); ub[('m - 1)..0] }
  else shiftext[('m - 1)..0]

val ncliprs : forall 'n 'm, ('n == 8 | 'n == 16 | 'n == 32 | 'n == 64) & 'n == 'm * 2.
  (implicit('m), bits('n), nat) -> bits('m)
function ncliprs (m, value, shift) =
  let ub : bits('n) = sign_extend(ones ('m) >> 1) in
  let lb : bits('n) = not_vec (ub) in
  let shiftext : bits('n) = shift_right_arith_rounding(value, shift) in
  if shiftext <_s lb then { write_vxsat(0b1); slice (lb, 0, 'm) }
  else if ub <_s shiftext then { write_vxsat(0b1); slice (ub, 0, 'm) }
  else slice (shiftext, 0, 'm)

val nclipru : forall 'n 'm, ('n == 8 | 'n == 16 | 'n == 32 | 'n == 64) & 'n == 'm * 2.
  (implicit('m), bits('n), nat) -> bits('m)
function nclipru (m, value, shift) =
  let ub : bits('n) = zero_extend(ones ('m)) in
  let shiftext : bits('n) = shift_right_logic_rounding(value, shift) in
  if ub <_u shiftext then { write_vxsat(0b1); slice (ub, 0, 'm) }
  else slice (shiftext, 0, 'm)
