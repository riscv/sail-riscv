/*=======================================================================================*/
/*  This Sail RISC-V architecture model, comprising all files and                        */
/*  directories except where otherwise noted is subject the BSD                          */
/*  two-clause license in the LICENSE file.                                              */
/*                                                                                       */
/*  SPDX-License-Identifier: BSD-2-Clause                                                */
/*=======================================================================================*/

default Order dec

$include <smt.sail>
$include <option.sail>
$include <arith.sail>
$include <string.sail>
$include <mapping.sail>
$include <vector_dec.sail>
$include <generic_equality.sail>
$include <hex_bits.sail>
$include <hex_bits_signed.sail>
$include <dec_bits.sail>

val not_bit : bit -> bit
function not_bit(b) = if b == bitone then bitzero else bitone

overload ~ = {not_bool, not_vec, not_bit}

// not_bool alias.
val not : forall ('p : Bool). bool('p) -> bool(not('p))
function not(b) = not_bool(b)

overload operator & = {and_vec}

overload operator | = {or_vec}

function bit_str(b: bit) -> string =
  match b {
    bitzero => "0b0",
    bitone => "0b1"
  }

overload BitStr = {bits_str, bit_str}

overload operator ^ = {xor_vec, concat_str}

val sub_vec = pure {c: "sub_bits", lean: "_lean_sub", _: "sub_vec"} : forall 'n. (bits('n), bits('n)) -> bits('n)

val sub_vec_int = pure {c: "sub_bits_int", lean: "BitVec.subInt", _: "sub_vec_int"} : forall 'n. (bits('n), int) -> bits('n)

overload operator - = {sub_vec, sub_vec_int}

val quot_positive_round_zero = pure {interpreter: "quot_round_zero", lem: "hardware_quot", lean: "Int.tdiv", c: "tdiv_int", coq: "Z.quot"} : forall 'n 'm, 'n >= 0 & 'm > 0. (int('n), int('m)) -> int(div('n, 'm))

val quot_round_zero = pure {interpreter: "quot_round_zero", lem: "hardware_quot", c: "tdiv_int", coq: "Z.quot", lean: "Int.tdiv"} : (int, int) -> int
val rem_round_zero = pure {interpreter: "rem_round_zero", lem: "hardware_mod", c: "tmod_int", coq: "Z.rem", lean: "Int.tmod"} : (int, int) -> int

/* The following defines % as euclidean modulus */
overload operator % = {emod_int}

overload min = {min_int}
overload max = {max_int}

val print_string = pure "print_string" : (string, string) -> unit

val print_instr    = pure {interpreter: "print_endline", c: "print_instr", lem: "print_dbg", _: "print_endline"} : string -> unit
val print_platform = pure {interpreter: "print_endline", c: "print_platform", lem: "print_dbg", _: "print_endline"} : string -> unit

val print_step = pure {c: "print_step"} : unit -> unit
function print_step() = ()

val get_config_print_instr = pure {c:"get_config_print_instr"} : unit -> bool
val get_config_print_platform = pure {c:"get_config_print_platform"} : unit -> bool
val get_config_rvfi = pure {c:"get_config_rvfi"} : unit -> bool
// defaults for other backends
function get_config_print_instr () = false
function get_config_print_platform () = false
function get_config_rvfi () = false

val sign_extend : forall 'n 'm, 'm >= 'n. (implicit('m), bits('n)) -> bits('m)
val zero_extend : forall 'n 'm, 'm >= 'n. (implicit('m), bits('n)) -> bits('m)

function sign_extend(m, v) = sail_sign_extend(v, m)
function zero_extend(m, v) = sail_zero_extend(v, m)

val zeros : forall 'n, 'n >= 0 . implicit('n) -> bits('n)
function zeros (n) = sail_zeros(n)

val ones : forall 'n, 'n >= 0 . implicit('n) -> bits('n)
function ones (n) = sail_ones(n)

// Implicit version of truncate. Unfortunately the non-implicit version
// isn't called `sail_truncate()` by Sail so we can't name this `truncate()`.
val trunc : forall 'm 'n, 'm >= 0 & 'm <= 'n. (implicit('m), bits('n)) -> bits('m)
function trunc(m, v) = truncate(v, m)

mapping bool_bit : bool <-> bit = {
  true <-> bitone,
  false <-> bitzero,
}

mapping bool_bits : bool <-> bits(1) = {
  true   <-> 0b1,
  false  <-> 0b0,
}

mapping bool_not_bits : bool <-> bits(1) = {
  true   <-> 0b0,
  false  <-> 0b1,
}

// These aliases make the conversion direction a bit clearer.
function bool_to_bit(x : bool) -> bit = bool_bit(x)
function bit_to_bool(x : bit) -> bool = bool_bit(x)
function bool_to_bits(x : bool) -> bits(1) = bool_bits(x)
function bits_to_bool(x : bits(1)) -> bool = bool_bits(x)


val to_bits : forall 'l, 'l >= 0.(int('l), int) -> bits('l)
function to_bits (l, n) = get_slice_int(l, n, 0)

infix 4 <_s
infix 4 >_s
infix 4 <=_s
infix 4 >=_s
infix 4 <_u
infix 4 >_u
infix 4 <=_u
infix 4 >=_u

val operator <_s  : forall 'n, 'n > 0. (bits('n), bits('n)) -> bool
val operator >_s  : forall 'n, 'n > 0. (bits('n), bits('n)) -> bool
val operator <=_s : forall 'n, 'n > 0. (bits('n), bits('n)) -> bool
val operator >=_s : forall 'n, 'n > 0. (bits('n), bits('n)) -> bool
val operator <_u  : forall 'n. (bits('n), bits('n)) -> bool
val operator >_u  : forall 'n. (bits('n), bits('n)) -> bool
val operator <=_u : forall 'n. (bits('n), bits('n)) -> bool
val operator >=_u : forall 'n. (bits('n), bits('n)) -> bool

function operator <_s  (x, y) = signed(x) < signed(y)
function operator >_s  (x, y) = signed(x) > signed(y)
function operator <=_s (x, y) = signed(x) <= signed(y)
function operator >=_s (x, y) = signed(x) >= signed(y)
function operator <_u  (x, y) = unsigned(x) < unsigned(y)
function operator >_u  (x, y) = unsigned(x) > unsigned(y)
function operator <=_u (x, y) = unsigned(x) <= unsigned(y)
function operator >=_u (x, y) = unsigned(x) >= unsigned(y)

infix 7 >>
infix 7 <<

val "shift_bits_right" : forall 'n 'm. (bits('n), bits('m)) -> bits('n)
val "shift_bits_left"  : forall 'n 'm. (bits('n), bits('m)) -> bits('n)

val "shiftl" : forall 'm 'n, 'n >= 0. (bits('m), int('n)) -> bits('m)
val "shiftr" : forall 'm 'n, 'n >= 0. (bits('m), int('n)) -> bits('m)

overload operator >> = {shift_bits_right, shiftr}
overload operator << = {shift_bits_left, shiftl}

// Ideally this would be sail builtin. This implementation is not efficient for large shifts.

// 'n >= 1 is required due to https://github.com/rems-project/sail/issues/471
val shift_right_arith : forall 'm 'n, 'n >= 1 & 'm >= 0 . (bits('n), int('m)) -> bits('n)
function shift_right_arith(value, shift) =
  sign_extend('n + shift, value)[('n - 1 + shift) .. shift]

val shift_bits_right_arith : forall 'm 'n, 'n >= 1 . (bits('n), bits('m)) -> bits('n)
function shift_bits_right_arith(value, shift) =
  shift_right_arith(value, unsigned(shift))

infix 7 >>>
infix 7 <<<

val rotate_bits_right : forall 'n 'm, 'm >= 0. (bits('n), bits('m)) -> bits('n)
function rotate_bits_right (v, n) =
    (v >> n) | (v << (to_bits(length(n), length(v)) - n))

val rotate_bits_left : forall 'n 'm, 'm >= 0. (bits('n), bits('m)) -> bits('n)
function rotate_bits_left (v, n) =
    (v << n) | (v >> (to_bits(length(n), length(v)) - n))

val rotater : forall 'm 'n, 'm >= 'n >= 0. (bits('m), int('n)) -> bits('m)
function rotater (v, n) =
    (v >> n) | (v << (length(v) - n))

val rotatel : forall 'm 'n, 'm >= 'n >= 0. (bits('m), int('n)) -> bits('m)
function rotatel (v, n) =
    (v << n) | (v >> (length(v) - n))

overload operator >>> = {rotate_bits_right, rotater}
overload operator <<< = {rotate_bits_left, rotatel}

val reverse_bits : forall 'n, 'n > 0. bits('n) -> bits('n)
function reverse_bits (xs)  = {
  var ys : bits('n) = zeros();
  foreach (i from 0 to ('n - 1))
    ys[i] = xs['n - 1 - i];
  ys
}

overload operator / = {quot_positive_round_zero, quot_round_zero}
overload operator * = {mult_atom, mult_int}

/* helper for vector extension
 * 1. EEW between 8 and 64
 * 2. EMUL in vmv<nr>r.v instructions between 1 and 8
 */
val log2 : forall 'n, 'n in {1, 2, 4, 8, 16, 32, 64}. int('n) -> int
function log2(n) = {
  let result : int = match n {
    1    => 0,
    2    => 1,
    4    => 2,
    8    => 3,
    16   => 4,
    32   => 5,
    64   => 6
  };
  result
}

/* This is a slightly arbitrary limit on the maximum number of bytes
   in a memory access.  It helps to generate slightly better C code
   because it means width argument can be fast native integer. It
   would be even better if it could be <= 8 bytes so that data can
   also be a 64-bit int but CHERI needs 128-bit accesses for
   capabilities and SIMD / vector instructions will also need more.

   The specific value does not matter (if it is >8) since anything up
   to 2^64-1 will result in a native int being used for the width type.

   4096 was chosen because it is a page size, and a reasonable maximum
   for cbo.zero.
   */
type max_mem_access : Int = 4096

// Type used for memory access widths. Zero byte accesses are not allowed.
type mem_access_width = range(1, max_mem_access)

// Function to reverse endianness.
// Currently, not able to import reverse_endianness.sail library because of type compatibility issue.
val reverse_endianness = pure {c: "reverse_endianness"} : forall 'n . bits(8 * 'n) -> bits(8 * 'n)

// Enable unratified extensions
val sys_enable_experimental_extensions = pure "sys_enable_experimental_extensions" : unit -> bool

// Print a bit vector in hex. If it is not a multiple of 4
// bits in length zero extend it so it is (bits_str() prints
// bit vectors that aren't a multiple of 4 bits in binary).
function hex_bits_str forall 'n . (x : bits('n)) -> string =
  bits_str(zero_extend((3 - (('n + 3) % 4)) + 'n, x))
