(*=======================================================================================*)
(*  This Sail RISC-V architecture model, comprising all files and                        *)
(*  directories except where otherwise noted is subject the BSD                          *)
(*  two-clause license in the LICENSE file.                                              *)
(*                                                                                       *)
(*  SPDX-License-Identifier: BSD-2-Clause                                                *)
(*=======================================================================================*)

Require Import SailStdpp.Base.
Open Scope Z.

Definition write_ram {rv e a} wk (addr : mword a) size (v : mword (8 * size)) (meta : unit) : monad rv bool e := write_mem wk a addr size v.

Definition read_ram {rv e a} rk (addr : mword a) size (read_tag : bool) : monad rv (mword (8 * size) * unit) e :=
  read_mem rk a addr size >>= fun data =>
  returnm (data, tt).
