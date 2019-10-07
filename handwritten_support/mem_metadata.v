Require Import Sail2_instr_kinds.
Require Import Sail2_values.
Require Import Sail2_operators_mwords.
Require Import Sail2_prompt_monad.
Require Import Sail2_prompt.

Definition write_ram {rv e} wk (addr : mword 64) size (v : mword (8 * size)) (meta : unit) : monad rv bool e := write_mem wk 64 addr size v.

Definition read_ram {rv e} rk (addr : mword 64) size (read_tag : bool) `{ArithFact (size >= 0)} : monad rv (mword (8 * size) * unit) e :=
  read_mem rk 64 addr size >>= fun data =>
  returnm (data, tt).