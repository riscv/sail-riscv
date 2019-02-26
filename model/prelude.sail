default Order dec

$include <option.sail>
$include <arith.sail>
$include <string.sail>
$include <vector_dec.sail>

val string_startswith = "string_startswith" : (string, string) -> bool
val string_drop = "string_drop" : (string, nat) -> string
val string_take = "string_take" : (string, nat) -> string
val string_length = "string_length" : string -> nat
val string_append = {c: "concat_str", _: "string_append"} : (string, string) -> string

val eq_string = {c: "eq_string", ocaml: "eq_string", lem: "eq", coq: "generic_eq"} : (string, string) -> bool

val eq_anything = {ocaml: "(fun (x, y) -> x = y)", lem: "eq", coq: "generic_eq"} : forall ('a : Type). ('a, 'a) -> bool

overload operator == = {eq_string, eq_anything}

val "reg_deref" : forall ('a : Type). register('a) -> 'a effect {rreg}
/* sneaky deref with no effect necessary for bitfield writes */
val _reg_deref = "reg_deref" : forall ('a : Type). register('a) -> 'a

val any_vector_update = {ocaml: "update", lem: "update_list_dec", coq: "vector_update"} : forall 'n ('a : Type).
  (vector('n, dec, 'a), int, 'a) -> vector('n, dec, 'a)

overload vector_update = {any_vector_update}

val update_subrange = {ocaml: "update_subrange", lem: "update_subrange_vec_dec", coq: "update_subrange_vec_dec"} : forall 'n 'm 'o.
  (bits('n), atom('m), atom('o), bits('m - ('o - 1))) -> bits('n)

val vector_concat = {ocaml: "append", lem: "append_list"} : forall ('n : Int) ('m : Int) ('a : Type).
  (vector('n, dec, 'a), vector('m, dec, 'a)) -> vector('n + 'm, dec, 'a)

overload append = {vector_concat}

val not_vec = {c: "not_bits", _: "not_vec"} : forall 'n. bits('n) -> bits('n)

overload ~ = {not_bool, not_vec}

val neq_vec = {lem: "neq"} : forall 'n. (bits('n), bits('n)) -> bool

function neq_vec (x, y) = not_bool(eq_bits(x, y))

val neq_anything = {lem: "neq", coq: "generic_neq"} : forall ('a : Type). ('a, 'a) -> bool

function neq_anything (x, y) = not_bool(x == y)

overload operator != = {neq_vec, neq_anything}

val and_vec = {lem: "and_vec", c: "and_bits", coq: "and_vec", ocaml: "and_vec"} : forall 'n. (bits('n), bits('n)) -> bits('n)

overload operator & = {and_vec}

val or_vec = {lem: "or_vec", c: "or_bits", coq: "or_vec", ocaml: "or_vec"} : forall 'n. (bits('n), bits('n)) -> bits('n)

overload operator | = {or_vec}

val "shiftl" : forall 'm. (bits('m), int) -> bits('m)
val "shiftr" : forall 'm. (bits('m), int) -> bits('m)

val cast cast_unit_vec : bit -> bits(1)

function cast_unit_vec b = match b {
  bitzero => 0b0,
  bitone  => 0b1
}

val string_of_int = {c: "string_of_int", ocaml: "string_of_int", lem: "stringFromInteger", coq: "string_of_int"} : int -> string

val BitStr = "string_of_bits" : forall 'n. bits('n) -> string

val xor_vec = {c: "xor_bits", _: "xor_vec"} : forall 'n. (bits('n), bits('n)) -> bits('n)

val int_power = {ocaml: "int_power", lem: "pow", coq: "pow", c: "pow_int"} : (int, int) -> int

overload operator ^ = {xor_vec, int_power, concat_str}

val sub_vec = {c: "sub_bits", _: "sub_vec"} : forall 'n. (bits('n), bits('n)) -> bits('n)

val sub_vec_int = {c: "sub_bits_int", _: "sub_vec_int"} : forall 'n. (bits('n), int) -> bits('n)

overload operator - = {sub_vec, sub_vec_int}

val quot_round_zero = {ocaml: "quot_round_zero", lem: "hardware_quot", c: "tdiv_int"} : (int, int) -> int
val rem_round_zero = {ocaml: "rem_round_zero", lem: "hardware_mod", c: "tmod_int"} : (int, int) -> int

val modulus = {lem: "hardware_mod"} : (int, int) -> int

overload operator % = {modulus}

val min_nat = {ocaml: "min_int", lem: "min", coq: "min_nat", c: "min_int"} : (nat, nat) -> nat

val min_int = {ocaml: "min_int", lem: "min", coq: "Z.min", c: "min_int"} : (int, int) -> int

val max_nat = {ocaml: "max_int", lem: "max", coq: "max_nat", c: "max_int"} : (nat, nat) -> nat

val max_int = {ocaml: "max_int", lem: "max", coq: "Z.max", c: "max_int"} : (int, int) -> int

overload min = {min_nat, min_int}

overload max = {max_nat, max_int}

val replicate_bits = "replicate_bits" : forall 'n 'm, 'm >= 0. (bits('n), atom('m)) -> bits('n * 'm)

val pow2 = "pow2" : forall 'n. atom('n) -> atom(2 ^ 'n)

val print = "print_endline" : string -> unit
val print_string = "print_string" : (string, string) -> unit

val print_instr    = {ocaml: "Platform.print_instr", c: "print_instr", _: "print_endline"} : string -> unit
val print_reg      = {ocaml: "Platform.print_reg",   c: "print_reg", _: "print_endline"} : string -> unit
val print_mem      = {ocaml: "Platform.print_mem_access", c: "print_mem_access", _: "print_endline"} : string -> unit
val print_platform = {ocaml: "Platform.print_platform", c: "print_platform", _: "print_endline"} : string -> unit

$ifndef FEATURE_IMPLICITS
val EXTS : forall 'n 'm , 'm >= 'n . bits('n) -> bits('m)
val EXTZ : forall 'n 'm , 'm >= 'n . bits('n) -> bits('m)

function EXTS v = sail_sign_extend(v, sizeof('m))
function EXTZ v = sail_zero_extend(v, sizeof('m))
$else
val EXTS : forall 'n 'm, 'm >= 'n. (implicit('m), bits('n)) -> bits('m)
val EXTZ : forall 'n 'm, 'm >= 'n. (implicit('m), bits('n)) -> bits('m)

function EXTS(m, v) = sail_sign_extend(v, m)
function EXTZ(m, v) = sail_zero_extend(v, m)
$endif

val cast bool_to_bits : bool -> bits(1)
function bool_to_bits x = if x then 0b1 else 0b0

val cast bit_to_bool : bit -> bool
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

val operator >> = "shift_bits_right" : forall 'n 'm. (bits('n), bits('m)) -> bits('n)
val operator << = "shift_bits_left" : forall 'n 'm. (bits('n), bits('m)) -> bits('n)

/* Ideally these would be sail builtin */

function shift_right_arith64 (v : bits(64), shift : bits(6)) -> bits(64) =
    let v128 : bits(128) = EXTS(v) in
    (v128 >> shift)[63..0]

function shift_right_arith32 (v : bits(32), shift : bits(5)) -> bits(32) =
    let v64 : bits(64) = EXTS(v) in
    (v64 >> shift)[31..0]

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
