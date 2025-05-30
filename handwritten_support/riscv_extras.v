(*=======================================================================================*)
(*  RISCV Sail Model                                                                     *)
(*                                                                                       *)
(*  This Sail RISC-V architecture model, comprising all files and                        *)
(*  directories except for the snapshots of the Lem and Sail libraries                   *)
(*  in the prover_snapshots directory (which include copies of their                     *)
(*  licences), is subject to the BSD two-clause licence below.                           *)
(*                                                                                       *)
(*  Copyright (c) 2017-2023                                                              *)
(*    Prashanth Mundkur                                                                  *)
(*    Rishiyur S. Nikhil and Bluespec, Inc.                                              *)
(*    Jon French                                                                         *)
(*    Brian Campbell                                                                     *)
(*    Robert Norton-Wright                                                               *)
(*    Alasdair Armstrong                                                                 *)
(*    Thomas Bauereiss                                                                   *)
(*    Shaked Flur                                                                        *)
(*    Christopher Pulte                                                                  *)
(*    Peter Sewell                                                                       *)
(*    Alexander Richardson                                                               *)
(*    Hesham Almatary                                                                    *)
(*    Jessica Clarke                                                                     *)
(*    Microsoft, for contributions by Robert Norton-Wright and Nathaniel Wesley Filardo  *)
(*    Peter Rugg                                                                         *)
(*    Aril Computer Corp., for contributions by Scott Johnson                            *)
(*    Philipp Tomsich                                                                    *)
(*    VRULL GmbH, for contributions by its employees                                     *)
(*                                                                                       *)
(*  All rights reserved.                                                                 *)
(*                                                                                       *)
(*  This software was developed by the above within the Rigorous                         *)
(*  Engineering of Mainstream Systems (REMS) project, partly funded by                   *)
(*  EPSRC grant EP/K008528/1, at the Universities of Cambridge and                       *)
(*  Edinburgh.                                                                           *)
(*                                                                                       *)
(*  This software was developed by SRI International and the University of               *)
(*  Cambridge Computer Laboratory (Department of Computer Science and                    *)
(*  Technology) under DARPA/AFRL contract FA8650-18-C-7809 ("CIFV"), and                 *)
(*  under DARPA contract HR0011-18-C-0016 ("ECATS") as part of the DARPA                 *)
(*  SSITH research programme.                                                            *)
(*                                                                                       *)
(*  This project has received funding from the European Research Council                 *)
(*  (ERC) under the European Union’s Horizon 2020 research and innovation                *)
(*  programme (grant agreement 789108, ELVER).                                           *)
(*                                                                                       *)
(*                                                                                       *)
(*  Redistribution and use in source and binary forms, with or without                   *)
(*  modification, are permitted provided that the following conditions                   *)
(*  are met:                                                                             *)
(*  1. Redistributions of source code must retain the above copyright                    *)
(*     notice, this list of conditions and the following disclaimer.                     *)
(*  2. Redistributions in binary form must reproduce the above copyright                 *)
(*     notice, this list of conditions and the following disclaimer in                   *)
(*     the documentation and/or other materials provided with the                        *)
(*     distribution.                                                                     *)
(*                                                                                       *)
(*  THIS SOFTWARE IS PROVIDED BY THE AUTHOR AND CONTRIBUTORS ``AS IS''                   *)
(*  AND ANY EXPRESS OR IMPLIED WARRANTIES, INCLUDING, BUT NOT LIMITED                    *)
(*  TO, THE IMPLIED WARRANTIES OF MERCHANTABILITY AND FITNESS FOR A                      *)
(*  PARTICULAR PURPOSE ARE DISCLAIMED.  IN NO EVENT SHALL THE AUTHOR OR                  *)
(*  CONTRIBUTORS BE LIABLE FOR ANY DIRECT, INDIRECT, INCIDENTAL,                         *)
(*  SPECIAL, EXEMPLARY, OR CONSEQUENTIAL DAMAGES (INCLUDING, BUT NOT                     *)
(*  LIMITED TO, PROCUREMENT OF SUBSTITUTE GOODS OR SERVICES; LOSS OF                     *)
(*  USE, DATA, OR PROFITS; OR BUSINESS INTERRUPTION) HOWEVER CAUSED AND                  *)
(*  ON ANY THEORY OF LIABILITY, WHETHER IN CONTRACT, STRICT LIABILITY,                   *)
(*  OR TORT (INCLUDING NEGLIGENCE OR OTHERWISE) ARISING IN ANY WAY OUT                   *)
(*  OF THE USE OF THIS SOFTWARE, EVEN IF ADVISED OF THE POSSIBILITY OF                   *)
(*  SUCH DAMAGE.                                                                         *)
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

(*val elf_entry : unit -> integer*)
Definition elf_entry (_:unit) : Z := 0.
(*declare ocaml target_rep function elf_entry := `Elf_loader.elf_entry`*)

(*val get_time_ns : unit -> integer*)
Definition get_time_ns (_:unit) : Z := 0.
(*declare ocaml target_rep function get_time_ns := `(fun () -> Big_int.of_int (int_of_float (1e9 *. Unix.gettimeofday ())))`*)

(* Override the more general version *)

Definition mults_vec {n} (l : mword n) (r : mword n) : mword (2 * n) := mults_vec l r.
Definition mult_vec {n} (l : mword n) (r : mword n) : mword (2 * n) := mult_vec l r.
Definition print_string (_ _:string) : unit := tt.
Definition plat_enable_htif (_:unit) : bool := false.
