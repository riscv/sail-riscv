Require Import Sail2_instr_kinds.
Require Import Sail2_values.
Require Import Sail2_operators_mwords.
Require Import Sail2_prompt_monad.
Require Import Sail2_prompt.

Definition write_ram {rv e a} wk (addr : mword a) size (v : mword (8 * size)) (meta : unit) : monad rv bool e := write_mem wk a addr size v.

Definition read_ram {rv e a} rk (addr : mword a) size (read_tag : bool) `{ArithFact (size >=? 0)} : monad rv (mword (8 * size) * unit) e :=
  read_mem rk a addr size >>= fun data =>
  returnm (data, tt).
