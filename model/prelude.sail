// =======================================================================================
// This Sail RISC-V architecture model, comprising all files and
// directories except where otherwise noted is subject the BSD
// two-clause license in the LICENSE file.
//
// SPDX-License-Identifier: BSD-2-Clause
// =======================================================================================

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

overload operator ^ = {xor_vec, concat_str}

val sub_vec = pure {cpp: "sub_bits", lean: "_lean_sub", _: "sub_vec"} : forall 'n. (bits('n), bits('n)) -> bits('n)

val sub_vec_int = pure {cpp: "sub_bits_int", lean: "BitVec.subInt", _: "sub_vec_int"} : forall 'n. (bits('n), int) -> bits('n)

overload operator - = {sub_vec, sub_vec_int}

val quot_positive_round_zero = pure {interpreter: "quot_round_zero", lem: "hardware_quot", lean: "Int.tdiv", cpp: "tdiv_int", coq: "Z.quot"} : forall 'n 'm, 'n >= 0 & 'm > 0. (int('n), int('m)) -> int(div('n, 'm))
val quot_round_zero = pure {interpreter: "quot_round_zero", lem: "hardware_quot", cpp: "tdiv_int", coq: "Z.quot", lean: "Int.tdiv"} : forall 'm, 'm != 0 . (int, int('m)) -> int

val rem_positive_round_zero = pure {interpreter: "rem_round_zero", lem: "hardware_mod", cpp: "tmod_int", coq: "Z.rem", lean: "Int.tmod"} : forall 'n 'm, 'n >= 0 & 'm > 0. (int('n), int('m)) -> int(mod('n, 'm))
val rem_round_zero = pure {interpreter: "rem_round_zero", lem: "hardware_mod", cpp: "tmod_int", coq: "Z.rem", lean: "Int.tmod"} : forall 'm, 'm != 0 . (int, int('m)) -> int

// For working with division / modulus we require the divisor to be >= 1.
// This type describes that.
type nat1 = {'n, 'n > 0. int('n)}

overload min = {min_int}
overload max = {max_int}

val print_string = pure "print_string" : (string, string) -> unit

// Print to the --trace log file.
val print_log = pure {interpreter: "print_endline", cpp: "print_log", lem: "print_dbg", _: "print_endline"} : string -> unit
// Print an instruction to the --trace log file. The second argument is PC which can be used for
// symbolization. This is only supported by the C backend so other backends just do a normal print.
val print_log_instr = pure {cpp: "print_log_instr"} : (string, bits(64)) -> unit
function print_log_instr(message, pc) = print_log(message)

val print_step = pure {cpp: "print_step"} : unit -> unit
function print_step() = ()

val get_config_print_instr = pure {cpp: "get_config_print_instr"} : unit -> bool
val get_config_print_platform = pure {cpp: "get_config_print_platform"} : unit -> bool
val get_config_rvfi = pure {cpp: "get_config_rvfi"} : unit -> bool
val get_config_use_abi_names = pure {cpp: "get_config_use_abi_names"} : unit -> bool
// defaults for other backends
function get_config_print_instr () = false
function get_config_print_platform () = false
function get_config_rvfi () = false
function get_config_use_abi_names () = false

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

// These aliases make the conversion direction a bit clearer.
function bool_to_bit(x : bool) -> bit = bool_bit(x)
function bit_to_bool(x : bit) -> bool = bool_bit(x)
function bool_to_bits(x : bool) -> bits(1) = bool_bits(x)
function bits_to_bool(x : bits(1)) -> bool = bool_bits(x)
function bit_to_bits(x : bit) -> bits(1) = bool_bits(bit_to_bool(x))
function bits_to_bit(x : bits(1)) -> bit = bool_to_bit(bits_to_bool(x))

// Convert an integer to bits. This requires that the integer is known to fit
// inside the resulting bit vector. Note this only admits non-negative numbers.
val to_bits : forall 'l 'x, 'l >= 0 & 0 <= 'x < 2 ^ 'l . (implicit('l), int('x)) -> bits('l)
function to_bits(l, n) = get_slice_int(l, n, 0)

// The same as to_bits() but the value is checked at runtime since we can't check
// it at compile-time. The number is assumed to be unsigned.
val to_bits_checked : forall 'l, 'l >= 0 . (implicit('l), int) -> bits('l)
function to_bits_checked(l, n) = {
  let bv = get_slice_int(l, n, 0);
  assert(unsigned(bv) == n, "Couldn't convert integer " ^ dec_str(n) ^ " to " ^ dec_str(l) ^ " bits without overflow.");
  bv
}

// This version allows any integer as input (including negative) but it will truncate the result.
val to_bits_truncate : forall 'l, 'l >= 0 . (implicit('l), int) -> bits('l)
function to_bits_truncate(l, n) = get_slice_int(l, n, 0)

// This version should never be used. It is only for migrating code from
// when there was no distinction between checked and truncating to_bits.
val to_bits_unsafe : forall 'l, 'l >= 0 . (implicit('l), int) -> bits('l)
function to_bits_unsafe(l, n) = get_slice_int(l, n, 0)

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

val rotater : forall 'm 'n, 'm >= 'n >= 0. (bits('m), int('n)) -> bits('m)
function rotater(value, shift) =
  (value >> shift) | (value << ('m - shift))

val rotatel : forall 'm 'n, 'm >= 'n >= 0. (bits('m), int('n)) -> bits('m)
function rotatel(value, shift) =
  (value << shift) | (value >> ('m - shift))

val rotate_bits_right : forall 'm 'n, 'n >= 0 & 'm >= 2 ^ 'n . (bits('m), bits('n)) -> bits('m)
function rotate_bits_right(value, shift) = rotater(value, unsigned(shift))

val rotate_bits_left : forall 'm 'n, 'n >= 0 & 'm >= 2 ^ 'n . (bits('m), bits('n)) -> bits('m)
function rotate_bits_left (value, shift) = rotatel(value, unsigned(shift))

overload operator >>> = {rotate_bits_right, rotater}
overload operator <<< = {rotate_bits_left, rotatel}

val reverse_bits : forall 'n, 'n > 0. bits('n) -> bits('n)
function reverse_bits (xs)  = {
  var ys : bits('n) = zeros();
  foreach (i from 0 to ('n - 1))
    ys[i] = xs['n - 1 - i];
  ys
}

overload operator * = {mult_atom, mult_int}
// quot_round_zero and rem_round_zero are deliberately not
// added to these overloads to avoid accidentally doing
// division or modulo with negative numbers which is almost
// always a mistake in this context.
overload operator / = {quot_positive_round_zero}
overload operator % = {rem_positive_round_zero}

// helper for vector extension
// 1. EEW between 8 and 64
// 2. EMUL in vmv<nr>r.v instructions between 1 and 8
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

// This is a slightly arbitrary limit on the maximum number of bytes
// in a memory access.  It helps to generate slightly better C code
// because it means width argument can be fast native integer. It
// would be even better if it could be <= 8 bytes so that data can
// also be a 64-bit int but CHERI needs 128-bit accesses for
// capabilities and SIMD / vector instructions will also need more.
//
// The specific value does not matter (if it is >8) since anything up
// to 2^64-1 will result in a native int being used for the width type.
//
// 4096 was chosen because it is a page size, and a reasonable maximum
// for cbo.zero.
type max_mem_access : Int = 4096

// Type used for memory access widths. Zero byte accesses are not allowed.
type mem_access_width = range(1, max_mem_access)

// Enable unratified extensions
val sys_enable_experimental_extensions = pure "sys_enable_experimental_extensions" : unit -> bool

// Print a bit vector in hex. If it is not a multiple of 4
// bits in length zero extend it so it is (bits_str() prints
// bit vectors that aren't a multiple of 4 bits in binary).
function hex_bits_str forall 'n, 'n >= 0 . (x : bits('n)) -> string =
  bits_str(zero_extend((3 - (('n + 3) % 4)) + 'n, x))
