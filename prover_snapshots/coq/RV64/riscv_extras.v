Require Import Sail.Base.
Require Import String.
Require Import List.
Import List.ListNotations.
Open Scope Z.

Definition MEM_fence_rw_rw {rv e} (_:unit) : monad rv unit e := barrier (Barrier_RISCV_rw_rw tt).
Definition MEM_fence_r_rw  {rv e} (_:unit) : monad rv unit e := barrier (Barrier_RISCV_r_rw tt).
Definition MEM_fence_r_r   {rv e} (_:unit) : monad rv unit e := barrier (Barrier_RISCV_r_r tt).
Definition MEM_fence_rw_w  {rv e} (_:unit) : monad rv unit e := barrier (Barrier_RISCV_rw_w tt).
Definition MEM_fence_w_w   {rv e} (_:unit) : monad rv unit e := barrier (Barrier_RISCV_w_w tt).
Definition MEM_fence_w_rw  {rv e} (_:unit) : monad rv unit e := barrier (Barrier_RISCV_w_rw tt).
Definition MEM_fence_rw_r  {rv e} (_:unit) : monad rv unit e := barrier (Barrier_RISCV_rw_r tt).
Definition MEM_fence_r_w   {rv e} (_:unit) : monad rv unit e := barrier (Barrier_RISCV_r_w tt).
Definition MEM_fence_w_r   {rv e} (_:unit) : monad rv unit e := barrier (Barrier_RISCV_w_r tt).
Definition MEM_fence_tso   {rv e} (_:unit) : monad rv unit e := barrier (Barrier_RISCV_tso tt).
Definition MEM_fence_i     {rv e} (_:unit) : monad rv unit e := barrier (Barrier_RISCV_i tt).
(*
val MEMea                            : forall 'rv 'a 'e. Size 'a => bitvector 'a -> integer -> monad 'rv unit 'e
val MEMea_release                    : forall 'rv 'a 'e. Size 'a => bitvector 'a -> integer -> monad 'rv unit 'e
val MEMea_strong_release             : forall 'rv 'a 'e. Size 'a => bitvector 'a -> integer -> monad 'rv unit 'e
val MEMea_conditional                : forall 'rv 'a 'e. Size 'a => bitvector 'a -> integer -> monad 'rv unit 'e
val MEMea_conditional_release        : forall 'rv 'a 'e. Size 'a => bitvector 'a -> integer -> monad 'rv unit 'e
val MEMea_conditional_strong_release : forall 'rv 'a 'e. Size 'a => bitvector 'a -> integer -> monad 'rv unit 'e
*)
Definition MEMea {rv a e} addrsize (addr : mword a) size                     : monad rv unit e := write_mem_ea Write_plain addrsize addr size.
Definition MEMea_release {rv a e} addrsize (addr : mword a) size             : monad rv unit e := write_mem_ea Write_RISCV_release addrsize addr size.
Definition MEMea_strong_release {rv a e} addrsize (addr : mword a) size      : monad rv unit e := write_mem_ea Write_RISCV_strong_release addrsize addr size.
Definition MEMea_conditional {rv a e} addrsize (addr : mword a) size         : monad rv unit e := write_mem_ea Write_RISCV_conditional addrsize addr size.
Definition MEMea_conditional_release {rv a e} addrsize (addr : mword a) size : monad rv unit e := write_mem_ea Write_RISCV_conditional_release addrsize addr size.
Definition MEMea_conditional_strong_release {rv a e} addrsize (addr : mword a) size : monad rv unit e
                                          := write_mem_ea Write_RISCV_conditional_strong_release addrsize addr size.

(*
val MEMr                         : forall 'rv 'a 'b 'e. Size 'a, Size 'b => integer -> integer -> bitvector 'a -> bitvector 'a -> monad 'rv (bitvector 'b) 'e
val MEMr_acquire                 : forall 'rv 'a 'b 'e. Size 'a, Size 'b => integer -> integer -> bitvector 'a -> bitvector 'a -> monad 'rv (bitvector 'b) 'e
val MEMr_strong_acquire          : forall 'rv 'a 'b 'e. Size 'a, Size 'b => integer -> integer -> bitvector 'a -> bitvector 'a -> monad 'rv (bitvector 'b) 'e
val MEMr_reserved                : forall 'rv 'a 'b 'e. Size 'a, Size 'b => integer -> integer -> bitvector 'a -> bitvector 'a -> monad 'rv (bitvector 'b) 'e
val MEMr_reserved_acquire        : forall 'rv 'a 'b 'e. Size 'a, Size 'b => integer -> integer -> bitvector 'a -> bitvector 'a -> monad 'rv (bitvector 'b) 'e
val MEMr_reserved_strong_acquire : forall 'rv 'a 'b 'e. Size 'a, Size 'b => integer -> integer -> bitvector 'a -> bitvector 'a -> monad 'rv (bitvector 'b) 'e
*)

Definition MEMr {rv e} addrsize size (hexRAM addr : mword addrsize)                         `{ArithFact (size >=? 0)} : monad rv (mword (8 * size)) e := read_mem Read_plain addrsize addr size.
Definition MEMr_acquire {rv e} addrsize size (hexRAM addr : mword addrsize)                 `{ArithFact (size >=? 0)} : monad rv (mword (8 * size)) e := read_mem Read_RISCV_acquire addrsize addr size.
Definition MEMr_strong_acquire {rv e} addrsize size (hexRAM addr : mword addrsize)          `{ArithFact (size >=? 0)} : monad rv (mword (8 * size)) e := read_mem Read_RISCV_strong_acquire addrsize addr size.
Definition MEMr_reserved {rv e} addrsize size (hexRAM addr : mword addrsize)                `{ArithFact (size >=? 0)} : monad rv (mword (8 * size)) e := read_mem Read_RISCV_reserved addrsize addr size.
Definition MEMr_reserved_acquire {rv e} addrsize size (hexRAM addr : mword addrsize)        `{ArithFact (size >=? 0)} : monad rv (mword (8 * size)) e := read_mem Read_RISCV_reserved_acquire addrsize addr size.
Definition MEMr_reserved_strong_acquire {rv e} addrsize size (hexRAM addr : mword addrsize) `{ArithFact (size >=? 0)} : monad rv (mword (8 * size)) e := read_mem Read_RISCV_reserved_strong_acquire addrsize addr size.

(*
val MEMw                            : forall 'rv 'a 'b 'e. Size 'a, Size 'b => integer -> integer -> bitvector 'a -> bitvector 'a -> bitvector 'b -> monad 'rv bool 'e
val MEMw_release                    : forall 'rv 'a 'b 'e. Size 'a, Size 'b => integer -> integer -> bitvector 'a -> bitvector 'a -> bitvector 'b -> monad 'rv bool 'e
val MEMw_strong_release             : forall 'rv 'a 'b 'e. Size 'a, Size 'b => integer -> integer -> bitvector 'a -> bitvector 'a -> bitvector 'b -> monad 'rv bool 'e
val MEMw_conditional                : forall 'rv 'a 'b 'e. Size 'a, Size 'b => integer -> integer -> bitvector 'a -> bitvector 'a -> bitvector 'b -> monad 'rv bool 'e
val MEMw_conditional_release        : forall 'rv 'a 'b 'e. Size 'a, Size 'b => integer -> integer -> bitvector 'a -> bitvector 'a -> bitvector 'b -> monad 'rv bool 'e
val MEMw_conditional_strong_release : forall 'rv 'a 'b 'e. Size 'a, Size 'b => integer -> integer -> bitvector 'a -> bitvector 'a -> bitvector 'b -> monad 'rv bool 'e
*)

Definition MEMw {rv e} addrsize size (hexRAM addr : mword addrsize) (v : mword (8 * size))                            : monad rv bool e := write_mem Write_plain addrsize addr size v.
Definition MEMw_release {rv e} addrsize size (hexRAM addr : mword addrsize) (v : mword (8 * size))                    : monad rv bool e := write_mem Write_RISCV_release addrsize addr size v.
Definition MEMw_strong_release {rv e} addrsize size (hexRAM addr : mword addrsize) (v : mword (8 * size))             : monad rv bool e := write_mem Write_RISCV_strong_release addrsize addr size v.
Definition MEMw_conditional {rv e} addrsize size (hexRAM addr : mword addrsize) (v : mword (8 * size))                : monad rv bool e := write_mem Write_RISCV_conditional addrsize addr size v.
Definition MEMw_conditional_release {rv e} addrsize size (hexRAM addr : mword addrsize) (v : mword (8 * size))        : monad rv bool e := write_mem Write_RISCV_conditional_release addrsize addr size v.
Definition MEMw_conditional_strong_release {rv e} addrsize size (hexRAM addr : mword addrsize) (v : mword (8 * size)) : monad rv bool e := write_mem Write_RISCV_conditional_strong_release addrsize addr size v.

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
Definition undefined_string {rv e} (_:unit) : monad rv string e := returnm ""%string.
Definition undefined_unit {rv e} (_:unit) : monad rv unit e := returnm tt.
Definition undefined_int {rv e} (_:unit) : monad rv Z e := returnm (0:ii).
(*val undefined_vector : forall 'rv 'a 'e. integer -> 'a -> monad 'rv (list 'a) 'e*)
Definition undefined_vector {rv a e} len (u : a) `{ArithFact (len >=? 0)} : monad rv (vec a len) e := returnm (vec_init u len).
(*val undefined_bitvector : forall 'rv 'a 'e. Bitvector 'a => integer -> monad 'rv 'a 'e*)
Definition undefined_bitvector {rv e} len `{ArithFact (len >=? 0)} : monad rv (mword len) e := returnm (mword_of_int 0).
(*val undefined_bits : forall 'rv 'a 'e. Bitvector 'a => integer -> monad 'rv 'a 'e*)
Definition undefined_bits {rv e} := @undefined_bitvector rv e.
Definition undefined_bit {rv e} (_:unit) : monad rv bitU e := returnm BU.
(*Definition undefined_real {rv e} (_:unit) : monad rv real e := returnm (realFromFrac 0 1).*)
Definition undefined_range {rv e} i j `{ArithFact (i <=? j)} : monad rv {z : Z & ArithFact (i <=? z <=? j)} e := returnm (build_ex i).
Definition undefined_atom {rv e} i : monad rv Z e := returnm i.
Definition undefined_nat {rv e} (_:unit) : monad rv Z e := returnm (0:ii).

Definition skip {rv e} (_:unit) : monad rv unit e := returnm tt.

(*val elf_entry : unit -> integer*)
Definition elf_entry (_:unit) : Z := 0.
(*declare ocaml target_rep function elf_entry := `Elf_loader.elf_entry`*)

Definition print_bits {n} msg (bs : mword n) := prerr_endline (msg ++ (string_of_bits bs)).

(*val get_time_ns : unit -> integer*)
Definition get_time_ns (_:unit) : Z := 0.
(*declare ocaml target_rep function get_time_ns := `(fun () -> Big_int.of_int (int_of_float (1e9 *. Unix.gettimeofday ())))`*)

Definition eq_bit (x : bitU) (y : bitU) : bool :=
  match x, y with
  | B0, B0 => true
  | B1, B1 => true
  | BU, BU => true
  | _,_ => false
  end.

Require Import Zeuclid.
Definition euclid_modulo (m n : Z) `{ArithFact (n >? 0)} : {z : Z & ArithFact (0 <=? z <=? n-1)}.
apply existT with (x := ZEuclid.modulo m n).
constructor.
destruct H.
unbool_comparisons.
unbool_comparisons_goal.
assert (Z.abs n = n). { rewrite Z.abs_eq; auto with zarith. }
rewrite <- H at 3.
lapply (ZEuclid.mod_always_pos m n); omega.
Qed.

(* Override the more general version *)

Definition mults_vec {n} (l : mword n) (r : mword n) : mword (2 * n) := mults_vec l r.
Definition mult_vec {n} (l : mword n) (r : mword n) : mword (2 * n) := mult_vec l r.


Definition print_endline (_:string) : unit := tt.
Definition prerr_endline (_:string) : unit := tt.
Definition prerr_string (_:string) : unit := tt.
Definition putchar {T} (_:T) : unit := tt.
Require DecimalString.
Definition string_of_int z := DecimalString.NilZero.string_of_int (Z.to_int z).

Axiom sys_enable_writable_misa : unit -> bool.
Axiom sys_enable_rvc : unit -> bool.
Axiom sys_enable_fdext : unit -> bool.
Axiom sys_enable_next : unit -> bool.

(* The constraint solver can do this itself, but a Coq bug puts
   anonymous_subproof into the term instead of an actual subproof. *)
Lemma n_leading_spaces_fact {w__0} :
  w__0 >= 0 -> exists ex17629_ : Z, 1 + w__0 = 1 + ex17629_ /\ 0 <= ex17629_.
intro.
exists w__0.
omega.
Qed.
Hint Resolve n_leading_spaces_fact : sail.
