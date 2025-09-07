(*=======================================================================================*)
(*  This Sail RISC-V architecture model, comprising all files and                        *)
(*  directories except where otherwise noted is subject the BSD                          *)
(*  two-clause license in the LICENSE file.                                              *)
(*                                                                                       *)
(*  SPDX-License-Identifier: BSD-2-Clause                                                *)
(*=======================================================================================*)

Require Import SailStdpp.Base.
Require Import List.
Require Import Lia.
Import List.ListNotations.
Open Scope Z.

Definition shift_bits_left {a b} (v : mword a) (n : mword b) : mword a :=
  shiftl v (int_of_mword false n).

Definition shift_bits_right {a b} (v : mword a) (n : mword b) : mword a :=
  shiftr v (int_of_mword false n).

Definition shift_bits_right_arith {a b} (v : mword a) (n : mword b) : mword a :=
  arith_shiftr v (int_of_mword false n).

(* Use constants for undefined values for now *)
Definition internal_pick {rv a e} (vs : list a) : monad rv a e :=
match vs with
| (h::_) => returnm h
| _ => Fail "empty list in internal_pick"
end.

(*val get_time_ns : unit -> integer*)
Definition get_time_ns (_:unit) : Z := 0.
(*declare ocaml target_rep function get_time_ns := `(fun () -> Big_int.of_int (int_of_float (1e9 *. Unix.gettimeofday ())))`*)

(* Override the more general version *)

Definition mults_vec {n} (l : mword n) (r : mword n) : mword (2 * n) := mults_vec l r.
Definition mult_vec {n} (l : mword n) (r : mword n) : mword (2 * n) := mult_vec l r.
Definition print_string (_ _:string) : unit := tt.
