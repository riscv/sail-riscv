// =======================================================================================
// This Sail RISC-V architecture model, comprising all files and
// directories except where otherwise noted is subject the BSD
// two-clause license in the LICENSE file.
//
// SPDX-License-Identifier: BSD-2-Clause
// =======================================================================================

// model-internal exceptions

union exception = {
  Error_not_implemented : string,
  Error_internal_error  : unit,
  Error_reserved_behavior : string,
}

val not_implemented : forall ('a : Type). string -> 'a
function not_implemented message = throw(Error_not_implemented(message))

val internal_error : forall ('a : Type). (string, int, string) -> 'a
function internal_error(file, line, s) = {
    assert (false, file ^ ":" ^ dec_str(line) ^ ": " ^ s);
    throw Error_internal_error()
}

val reserved_behavior : forall ('a : Type). string -> 'a
function reserved_behavior(message) =
  throw(Error_reserved_behavior(message))

function print_exception(e : exception) -> unit =
  match e {
    Error_not_implemented(s)   => print_endline("Not implemented error: " ^ s),
    Error_internal_error()     => print_endline("Internal error."),
    Error_reserved_behavior(s) => print_endline("Reserved behavior error: " ^ s),
  }
