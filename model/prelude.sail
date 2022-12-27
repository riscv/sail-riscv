/*=======================================================================================*/
/*  RISCV Sail Model                                                                     */
/*                                                                                       */
/*  This Sail RISC-V architecture model, comprising all files and                        */
/*  directories except for the snapshots of the Lem and Sail libraries                   */
/*  in the prover_snapshots directory (which include copies of their                     */
/*  licences), is subject to the BSD two-clause licence below.                           */
/*                                                                                       */
/*  Copyright (c) 2017-2023                                                              */
/*    Prashanth Mundkur                                                                  */
/*    Rishiyur S. Nikhil and Bluespec, Inc.                                              */
/*    Jon French                                                                         */
/*    Brian Campbell                                                                     */
/*    Robert Norton-Wright                                                               */
/*    Alasdair Armstrong                                                                 */
/*    Thomas Bauereiss                                                                   */
/*    Shaked Flur                                                                        */
/*    Christopher Pulte                                                                  */
/*    Peter Sewell                                                                       */
/*    Alexander Richardson                                                               */
/*    Hesham Almatary                                                                    */
/*    Jessica Clarke                                                                     */
/*    Microsoft, for contributions by Robert Norton-Wright and Nathaniel Wesley Filardo  */
/*    Peter Rugg                                                                         */
/*    Aril Computer Corp., for contributions by Scott Johnson                            */
/*    Philipp Tomsich                                                                    */
/*    VRULL GmbH, for contributions by its employees                                     */
/*                                                                                       */
/*  All rights reserved.                                                                 */
/*                                                                                       */
/*  This software was developed by the above within the Rigorous                         */
/*  Engineering of Mainstream Systems (REMS) project, partly funded by                   */
/*  EPSRC grant EP/K008528/1, at the Universities of Cambridge and                       */
/*  Edinburgh.                                                                           */
/*                                                                                       */
/*  This software was developed by SRI International and the University of               */
/*  Cambridge Computer Laboratory (Department of Computer Science and                    */
/*  Technology) under DARPA/AFRL contract FA8650-18-C-7809 ("CIFV"), and                 */
/*  under DARPA contract HR0011-18-C-0016 ("ECATS") as part of the DARPA                 */
/*  SSITH research programme.                                                            */
/*                                                                                       */
/*  This project has received funding from the European Research Council                 */
/*  (ERC) under the European Union’s Horizon 2020 research and innovation                */
/*  programme (grant agreement 789108, ELVER).                                           */
/*                                                                                       */
/*                                                                                       */
/*  Redistribution and use in source and binary forms, with or without                   */
/*  modification, are permitted provided that the following conditions                   */
/*  are met:                                                                             */
/*  1. Redistributions of source code must retain the above copyright                    */
/*     notice, this list of conditions and the following disclaimer.                     */
/*  2. Redistributions in binary form must reproduce the above copyright                 */
/*     notice, this list of conditions and the following disclaimer in                   */
/*     the documentation and/or other materials provided with the                        */
/*     distribution.                                                                     */
/*                                                                                       */
/*  THIS SOFTWARE IS PROVIDED BY THE AUTHOR AND CONTRIBUTORS ``AS IS''                   */
/*  AND ANY EXPRESS OR IMPLIED WARRANTIES, INCLUDING, BUT NOT LIMITED                    */
/*  TO, THE IMPLIED WARRANTIES OF MERCHANTABILITY AND FITNESS FOR A                      */
/*  PARTICULAR PURPOSE ARE DISCLAIMED.  IN NO EVENT SHALL THE AUTHOR OR                  */
/*  CONTRIBUTORS BE LIABLE FOR ANY DIRECT, INDIRECT, INCIDENTAL,                         */
/*  SPECIAL, EXEMPLARY, OR CONSEQUENTIAL DAMAGES (INCLUDING, BUT NOT                     */
/*  LIMITED TO, PROCUREMENT OF SUBSTITUTE GOODS OR SERVICES; LOSS OF                     */
/*  USE, DATA, OR PROFITS; OR BUSINESS INTERRUPTION) HOWEVER CAUSED AND                  */
/*  ON ANY THEORY OF LIABILITY, WHETHER IN CONTRACT, STRICT LIABILITY,                   */
/*  OR TORT (INCLUDING NEGLIGENCE OR OTHERWISE) ARISING IN ANY WAY OUT                   */
/*  OF THE USE OF THIS SOFTWARE, EVEN IF ADVISED OF THE POSSIBILITY OF                   */
/*  SUCH DAMAGE.                                                                         */
/*=======================================================================================*/

default Order dec

$include <smt.sail>
$include <option.sail>
$include <arith.sail>
$include <string.sail>
$include <vector_dec.sail>
$include <regfp.sail>

val string_startswith = "string_startswith" : (string, string) -> bool
val string_drop = "string_drop" : (string, nat) -> string
val string_take = "string_take" : (string, nat) -> string
val string_length = "string_length" : string -> nat
val string_append = {c: "concat_str", _: "string_append"} : (string, string) -> string

val eq_anything = {ocaml: "(fun (x, y) -> x = y)", interpreter: "eq_anything", lem: "eq", coq: "generic_eq", c: "eq_anything"} : forall ('a : Type). ('a, 'a) -> bool

overload operator == = {eq_string, eq_anything}

val "reg_deref" : forall ('a : Type). register('a) -> 'a
/* sneaky deref with no effect necessary for bitfield writes */
val _reg_deref = "reg_deref" : forall ('a : Type). register('a) -> 'a

val any_vector_update = {ocaml: "update", lem: "update_list_dec", coq: "vector_update"} : forall 'n ('a : Type).
  (vector('n, dec, 'a), int, 'a) -> vector('n, dec, 'a)

overload vector_update = {any_vector_update}

val update_subrange = {ocaml: "update_subrange", interpreter: "update_subrange", lem: "update_subrange_vec_dec", coq: "update_subrange_vec_dec"} : forall 'n 'm 'o.
  (bits('n), atom('m), atom('o), bits('m - ('o - 1))) -> bits('n)

val vector_concat = {ocaml: "append", lem: "append_list", coq: "vec_concat"} : forall ('n : Int) ('m : Int) ('a : Type).
  (vector('n, dec, 'a), vector('m, dec, 'a)) -> vector('n + 'm, dec, 'a)

overload append = {vector_concat}

val not_bit : bit -> bit

function not_bit(b) = if b == bitone then bitzero else bitone

overload ~ = {not_bool, not_vec, not_bit}

val not = pure {coq: "negb", _: "not"} : forall ('p : Bool). bool('p) -> bool(not('p))

val neq_vec = {lem: "neq"} : forall 'n. (bits('n), bits('n)) -> bool

function neq_vec (x, y) = not_bool(eq_bits(x, y))

val neq_anything = {lem: "neq", coq: "generic_neq"} : forall ('a : Type). ('a, 'a) -> bool

function neq_anything (x, y) = not_bool(x == y)

overload operator != = {neq_vec, neq_anything}

overload operator & = {and_vec}

overload operator | = {or_vec}

val string_of_int = {c: "string_of_int", ocaml: "string_of_int", interpreter: "string_of_int", lem: "stringFromInteger", coq: "string_of_int"} : int -> string

val "string_of_bits" : forall 'n. bits('n) -> string

function string_of_bit(b: bit) -> string =
  match b {
    bitzero => "0b0",
    bitone => "0b1"
  }

overload BitStr = {string_of_bits, string_of_bit}

val int_power = {ocaml: "int_power", interpreter: "int_power", lem: "pow", coq: "pow", c: "pow_int"} : (int, int) -> int

overload operator ^ = {xor_vec, int_power, concat_str}

val sub_vec = {c: "sub_bits", _: "sub_vec"} : forall 'n. (bits('n), bits('n)) -> bits('n)

val sub_vec_int = {c: "sub_bits_int", _: "sub_vec_int"} : forall 'n. (bits('n), int) -> bits('n)

overload operator - = {sub_vec, sub_vec_int}

val quot_round_zero = {ocaml: "quot_round_zero", interpreter: "quot_round_zero", lem: "hardware_quot", c: "tdiv_int", coq: "Z.quot"} : (int, int) -> int
val rem_round_zero = {ocaml: "rem_round_zero", interpreter: "rem_round_zero", lem: "hardware_mod", c: "tmod_int", coq: "Z.rem"} : (int, int) -> int

/* The following defines % as euclidean modulus */
overload operator % = {emod_int}

val min_int = {ocaml: "min_int", interpreter: "min_int", lem: "min", coq: "min_atom", c: "min_int"} : forall 'x 'y.
  (int('x), int('y)) -> {'z, ('x <= 'y & 'z == 'x) | ('x > 'y & 'z == 'y). int('z)}

val max_int = {ocaml: "max_int", interpreter: "max_int", lem: "max", coq: "max_atom", c: "max_int"} : forall 'x 'y.
  (int('x), int('y)) -> {'z, ('x >= 'y & 'z == 'x) | ('x < 'y & 'z == 'y). int('z)}

overload min = {min_int}

overload max = {max_int}

val pow2 = "pow2" : forall 'n. atom('n) -> atom(2 ^ 'n)

val print = "print_endline" : string -> unit
val print_string = "print_string" : (string, string) -> unit

val print_instr    = {ocaml: "Platform.print_instr", interpreter: "print_endline", c: "print_instr", lem: "print_dbg", _: "print_endline"} : string -> unit
val print_reg      = {ocaml: "Platform.print_reg", interpreter: "print_endline", c: "print_reg", lem: "print_dbg", _: "print_endline"} : string -> unit
val print_mem      = {ocaml: "Platform.print_mem_access", interpreter: "print_endline", c: "print_mem_access", lem: "print_dbg", _: "print_endline"} : string -> unit
val print_platform = {ocaml: "Platform.print_platform", interpreter: "print_endline", c: "print_platform", lem: "print_dbg", _: "print_endline"} : string -> unit

val get_config_print_instr = {ocaml: "Platform.get_config_print_instr", c:"get_config_print_instr"} : unit -> bool
val get_config_print_reg = {ocaml: "Platform.get_config_print_reg", c:"get_config_print_reg"} : unit -> bool
val get_config_print_mem = {ocaml: "Platform.get_config_print_mem", c:"get_config_print_mem"} : unit -> bool

val get_config_print_platform = {ocaml: "Platform.get_config_print_platform", c:"get_config_print_platform"} : unit -> bool
// defaults for other backends
function get_config_print_instr () = false
function get_config_print_reg () = false
function get_config_print_mem () = false
function get_config_print_platform () = false

val sign_extend : forall 'n 'm, 'm >= 'n. (implicit('m), bits('n)) -> bits('m)
val zero_extend : forall 'n 'm, 'm >= 'n. (implicit('m), bits('n)) -> bits('m)

function sign_extend(m, v) = sail_sign_extend(v, m)
function zero_extend(m, v) = sail_zero_extend(v, m)

val zeros_implicit : forall 'n, 'n >= 0 . implicit('n) -> bits('n)
function zeros_implicit (n) = sail_zeros(n)
overload zeros = {zeros_implicit}

val ones : forall 'n, 'n >= 0 . implicit('n) -> bits('n)
function ones (n) = sail_ones (n)

val bool_to_bit : bool -> bit
function bool_to_bit x = if x then bitone else bitzero

val bool_to_bits : bool -> bits(1)
function bool_to_bits x = [bool_to_bit(x)]

val bit_to_bool : bit -> bool
function bit_to_bool b = match b {
  bitone  => true,
  bitzero => false
}

val to_bits : forall 'l, 'l >= 0.(atom('l), int) -> bits('l)
function to_bits (l, n) = get_slice_int(l, n, 0)

infix 4 <_s
infix 4 >=_s
infix 4 <_u
infix 4 >=_u
infix 4 <=_u

val operator <_s  : forall 'n, 'n > 0. (bits('n), bits('n)) -> bool
val operator >=_s : forall 'n, 'n > 0. (bits('n), bits('n)) -> bool
val operator <_u  : forall 'n. (bits('n), bits('n)) -> bool
val operator >=_u : forall 'n. (bits('n), bits('n)) -> bool
val operator <=_u : forall 'n. (bits('n), bits('n)) -> bool

function operator <_s  (x, y) = signed(x) < signed(y)
function operator >=_s (x, y) = signed(x) >= signed(y)
function operator <_u  (x, y) = unsigned(x) < unsigned(y)
function operator >=_u (x, y) = unsigned(x) >= unsigned(y)
function operator <=_u (x, y) = unsigned(x) <= unsigned(y)

infix 7 >>
infix 7 <<

val "shift_bits_right" : forall 'n 'm. (bits('n), bits('m)) -> bits('n)
val "shift_bits_left"  : forall 'n 'm. (bits('n), bits('m)) -> bits('n)

val "shiftl" : forall 'm 'n, 'n >= 0. (bits('m), atom('n)) -> bits('m)
val "shiftr" : forall 'm 'n, 'n >= 0. (bits('m), atom('n)) -> bits('m)

overload operator >> = {shift_bits_right, shiftr}
overload operator << = {shift_bits_left, shiftl}

/* Ideally these would be sail builtin */

function shift_right_arith64 (v : bits(64), shift : bits(6)) -> bits(64) =
    let v128 : bits(128) = sign_extend(v) in
    (v128 >> shift)[63..0]

function shift_right_arith32 (v : bits(32), shift : bits(5)) -> bits(32) =
    let v64 : bits(64) = sign_extend(v) in
    (v64 >> shift)[31..0]

infix 7 >>>
infix 7 <<<

val rotate_bits_right : forall 'n 'm, 'm >= 0. (bits('n), bits('m)) -> bits('n)
function rotate_bits_right (v, n) =
    (v >> n) | (v << (to_bits(length(n), length(v)) - n))

val rotate_bits_left : forall 'n 'm, 'm >= 0. (bits('n), bits('m)) -> bits('n)
function rotate_bits_left (v, n) =
    (v << n) | (v >> (to_bits(length(n), length(v)) - n))

val rotater : forall 'm 'n, 'm >= 'n >= 0. (bits('m), atom('n)) -> bits('m)
function rotater (v, n) =
    (v >> n) | (v << (length(v) - n))

val rotatel : forall 'm 'n, 'm >= 'n >= 0. (bits('m), atom('n)) -> bits('m)
function rotatel (v, n) =
    (v << n) | (v >> (length(v) - n))

overload operator >>> = {rotate_bits_right, rotater}
overload operator <<< = {rotate_bits_left, rotatel}

function reverse_bits_in_byte (xs : bits(8)) -> bits(8) = {
  ys : bits(8) = zeros();
  foreach (i from 0 to 7)
    ys[i] = xs[7-i];
  ys
}

overload reverse = {reverse_bits_in_byte}

/* helpers for mappings */

val spc : unit <-> string
val opt_spc : unit <-> string
val def_spc : unit <-> string

val "decimal_string_of_bits" : forall 'n. bits('n) -> string
val hex_bits : forall 'n . (atom('n), bits('n)) <-> string

val n_leading_spaces : string -> nat
function n_leading_spaces s =
  match s {
    "" => 0,
    _ => match string_take(s, 1) {
      " " => 1 + n_leading_spaces(string_drop(s, 1)),
      _ => 0
    }
  }

val spc_forwards : unit -> string
function spc_forwards () = " "
val spc_backwards : string -> unit
function spc_backwards s = ()
val spc_matches_prefix : string -> option((unit, nat))
function spc_matches_prefix s = {
  let n = n_leading_spaces(s);
  match n {
    0 => None(),
    _ => Some((), n)
  }
}

val opt_spc_forwards : unit -> string
function opt_spc_forwards () = ""
val opt_spc_backwards : string -> unit
function opt_spc_backwards s = ()
val opt_spc_matches_prefix : string -> option((unit, nat))
function opt_spc_matches_prefix s =
  Some((), n_leading_spaces(s))

val def_spc_forwards : unit -> string
function def_spc_forwards () = " "
val def_spc_backwards : string -> unit
function def_spc_backwards s = ()
val def_spc_matches_prefix : string -> option((unit, nat))
function def_spc_matches_prefix s = opt_spc_matches_prefix(s)

overload operator / = {quot_round_zero}
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
