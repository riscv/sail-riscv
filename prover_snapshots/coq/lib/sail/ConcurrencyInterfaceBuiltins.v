Require Import Sail.Real.
Require Import Sail.Base.
Require Import Sail.ConcurrencyInterfaceTypes.
Require Import Sail.ConcurrencyInterface.
Require Import stdpp.unstable.bitvector.

Import ListNotations.
Open Scope string.
Open Scope bool.
Open Scope Z.

Module Defs (A : Arch with Definition reg := string with Definition pa := mword 56) (I : InterfaceT A).

Definition monad A E := I.iMon unit (fun _ => E) A.
Definition returnm {A E} : A -> monad A E := I.Ret.

Definition monadR A R E := I.iMon unit (fun _ => (R + E)%type) A.
Definition returnR {A E} R : A -> monadR A R E := I.Ret.

Definition bind {A B E : Type} (m : monad A E) (f : A -> monad B E) : monad B E := I.iMon_bind m f.
Notation "m >>= f" := (bind m f) (at level 50, left associativity).
Definition bind0 {A E} (m : monad unit E) (n : monad A E) :=
  m >>= fun (_ : unit) => n.
Notation "m >> n" := (bind0 m n) (at level 50, left associativity).

Definition fail {A E} (msg : string) : monad A E :=
  I.Next (I.GenericFail msg) (fun f => match f with end).

Definition exit {A E} (_ : unit) : monad A E := fail "exit".

Definition choose_bool {E} (_descr : string) : monad bool E := I.Next (I.Choose ChooseBool) mret.
Definition choose_bit {E} (_descr : string) : monad bitU E := I.Next (I.Choose ChooseBit) mret.
Definition choose_int {E} (_descr : string) : monad Z E := I.Next (I.Choose ChooseInt) mret.
Definition choose_nat {E} (_descr : string) : monad Z E := I.Next (I.Choose ChooseNat) mret.
Definition choose_real {E} (_descr : string) : monad R E := I.Next (I.Choose ChooseReal) mret.
Definition choose_string {E} (_descr : string) : monad string E := I.Next (I.Choose ChooseString) mret.
Definition choose_range {E} (_descr : string) (lo hi : Z) : monad Z E := I.Next (I.Choose (ChooseRange lo hi)) mret.
Definition choose_bitvector {E} (_descr : string) (n : Z) : monad (mword n) E :=
  I.Next (I.Choose (ChooseBitvector n)) mret.
(* match n return monad (mword n) E with
 | Zneg _ => returnm (bv_0 0)
 | Z0 => returnm (bv_0 0)
 | Zpos p => I.Next (I.Choose (N.of_nat (Pos.to_nat p))) (fun bv => returnm bv)
 end.*)

Definition assert_exp {E} (exp :bool) msg : monad unit E :=
 if exp then returnm tt else fail msg.
Definition assert_exp' {E} (exp :bool) msg : monad (exp = true) E :=
 if exp return monad (exp = true) E then returnm eq_refl else fail msg.

Definition throw {A E} (e : E) : monad A E := I.Next (I.ExtraOutcome e) mret.

Fixpoint try_catch {A E1 E2} (m : monad A E1) (h : E1 -> monad A E2) : monad A E2 :=
  match m with
  | I.Ret r => I.Ret r
  | I.Next (I.ExtraOutcome e)                  _ => h e
  | I.Next (I.RegRead reg direct)              f => I.Next (I.RegRead reg direct) (fun t => try_catch (f t) h)
  | I.Next (I.RegWrite reg direct deps regval) f => I.Next (I.RegWrite reg direct deps regval) (fun t => try_catch (f t) h)
  | I.Next (I.MemRead n req)                   f => I.Next (I.MemRead n req) (fun t => try_catch (f t) h)
  | I.Next (I.MemWrite n req)                  f => I.Next (I.MemWrite n req) (fun t => try_catch (f t) h)
  | I.Next (I.InstrAnnounce opcode)            f => I.Next (I.InstrAnnounce opcode) (fun t => try_catch (f t) h)
  | I.Next (I.BranchAnnounce pa deps)          f => I.Next (I.BranchAnnounce pa deps) (fun t => try_catch (f t) h)
  | I.Next (I.Barrier barrier)                 f => I.Next (I.Barrier barrier) (fun t => try_catch (f t) h)
  | I.Next (I.CacheOp deps op)                 f => I.Next (I.CacheOp deps op) (fun t => try_catch (f t) h)
  | I.Next (I.TlbOp deps op)                   f => I.Next (I.TlbOp deps op) (fun t => try_catch (f t) h)
  | I.Next (I.TakeException fault)             f => I.Next (I.TakeException fault) (fun t => try_catch (f t) h)
  | I.Next (I.ReturnException pa)              f => I.Next (I.ReturnException pa) (fun t => try_catch (f t) h)
  | I.Next (I.GenericFail msg)                 f => I.Next (I.GenericFail msg) (fun t => try_catch (f t) h)
  | I.Next (I.Choose n)                        f => I.Next (I.Choose n) (fun t => try_catch (f t) h)
  | I.Next (I.Discard)                         f => I.Next (I.Discard) (fun t => try_catch (f t) h)
  end.

Definition early_return {A R E} (r : R) : monadR A R E := throw (inl r).
Definition catch_early_return {A E} (m : monadR A A E) : monad A E :=
  try_catch m
    (fun r => match r with
      | inl a => returnm a
      | inr e => throw e
     end).

Definition pure_early_return_bind {A B E} (v : E + A) (f : A -> E + B) : E + B :=
  match v with
  | inl e => inl e
  | inr a => f a
  end.

Notation "m >>$= f" := (pure_early_return_bind m f) (at level 50, left associativity).
Notation "m >>$ n" := (m >>$= fun _ => n) (at level 50, left associativity).

Definition pure_early_return {A} (v : A + A) : A :=
  match v with
  | inl v' => v'
  | inr v' => v'
  end.

(* Lift to monad with early return by wrapping exceptions *)
Definition liftR {A R E} (m : monad A E) : monadR A R E :=
 try_catch m (fun e => throw (inr e)).

(* Catch exceptions in the presence : early returns *)
Definition try_catchR {A R E} (m : monadR A R E) (h : E -> monadR A R E) :=
  try_catch m
    (fun r => match r with
      | inl r => throw (inl r)
      | inr e => h e
     end).



Section Undef.

Definition undefined_unit {E} (_:unit) : monad unit E := returnm tt.
Definition undefined_bool {E} (_:unit) : monad bool E := choose_bool "undefined_bool".
Definition undefined_bit {E} (_:unit) : monad bitU E := choose_bool "undefined_bit" >>= fun b => returnm (bitU_of_bool b).
Definition undefined_string {E} (_:unit) : monad string E := choose_string "undefined_string".
 Definition undefined_int {E} (_:unit) : monad Z E := choose_int "undefined_int".
Definition undefined_nat {E} (_:unit) : monad Z E := choose_nat "undefined_nat".
Definition undefined_real {E} (_:unit) : monad _ E := choose_real "undefined_real".
Definition undefined_range {E} i j : monad Z E := choose_range "undefined_range" i j.
Definition undefined_bitvector {E} n : monad (mword n) E := choose_bitvector "undefined_bitvector" n.

Definition undefined_vector {E T} n `{TypeCasts.Inhabited T} (a:T) : monad (vec T n) E := returnm (vec_init a n).

End Undef.

(* ---- Prompt_monad *)

Definition read_reg {s a e} (reg : register_ref s A.reg_type a) : monad a e :=
  let k v :=
    match reg.(of_regval) v with
      | Some v => I.Ret v
      | None =>   I.Next (I.GenericFail "read_reg: unrecognised value") (fun f => match f with end)
    end
  in
  I.Next (I.RegRead reg.(name) (*???*) true) k.

Definition reg_deref {s a e} := @read_reg s a e.

Definition write_reg {s a e} (reg : register_ref s A.reg_type a) (v : a) : monad unit e :=
 I.Next (I.RegWrite reg.(name) (* ??? *) true tt (reg.(regval_of) v)) I.Ret.

(* ---- Prompt *)

Fixpoint foreachM {a e Vars} (l : list a) (vars : Vars) (body : a -> Vars -> monad Vars e) : monad Vars e :=
match l with
| [] => returnm vars
| (x :: xs) =>
  body x vars >>= fun vars =>
  foreachM xs vars body
end.

Fixpoint foreachE {a Vars e} (l : list a) (vars : Vars) (body : a -> Vars -> e + Vars) : e + Vars :=
match l with
| [] => inr vars
| (x :: xs) =>
  body x vars >>$= fun vars =>
  foreachE xs vars body
end.

Fixpoint foreach_ZM_up' {E Vars} (from to step off : Z) (n : nat) (* 0 <? step *) (* 0 <=? off *) (vars : Vars) (body : forall (z : Z) (* from <=? z <=? to *), Vars -> monad Vars E) {struct n} : monad Vars E :=
  if sumbool_of_bool (from + off <=? to) then
    match n with
    | O => returnm vars
    | S n => body (from + off) vars >>= fun vars => foreach_ZM_up' from to step (off + step) n vars body
    end
  else returnm vars.

Fixpoint foreach_ZE_up' {e Vars} (from to step off : Z) (n : nat) (* 0 <? step *) (* 0 <=? off *) (vars : Vars) (body : forall (z : Z) (* from <=? z <=? to *), Vars -> e + Vars) {struct n} : e + Vars :=
  if sumbool_of_bool (from + off <=? to) then
    match n with
    | O => inr vars
    | S n => body (from + off) vars >>$= fun vars => foreach_ZE_up' from to step (off + step) n vars body
    end
  else inr vars.

Fixpoint foreach_ZM_down' {E Vars} (from to step off : Z) (n : nat) (* 0 <? step *) (* off <=? 0 *) (vars : Vars) (body : forall (z : Z) (* to <=? z <=? from *), Vars -> monad Vars E) {struct n} : monad Vars E :=
  if sumbool_of_bool (to <=? from + off) then
    match n with
    | O => returnm vars
    | S n => body (from + off) vars >>= fun vars => foreach_ZM_down' from to step (off - step) n vars body
    end
  else returnm vars.

Fixpoint foreach_ZE_down' {e Vars} (from to step off : Z) (n : nat) (* 0 <? step *) (* off <=? 0 *) (vars : Vars) (body : forall (z : Z) (* to <=? z <=? from *), Vars -> e + Vars) {struct n} : e + Vars :=
  if sumbool_of_bool (to <=? from + off) then
    match n with
    | O => inr vars
    | S n => body (from + off) vars >>$= fun vars => foreach_ZE_down' from to step (off - step) n vars body
    end
  else inr vars.

Definition foreach_ZM_up {E Vars} from to step vars body (* 0 <? step *) :=
    foreach_ZM_up' (E := E) (Vars := Vars) from to step 0 (S (Z.abs_nat (from - to))) vars body.
Definition foreach_ZM_down {E Vars} from to step vars body (* 0 <? step *) :=
    foreach_ZM_down' (E := E) (Vars := Vars) from to step 0 (S (Z.abs_nat (from - to))) vars body.

Definition foreach_ZE_up {e Vars} from to step vars body (* 0 <? step *) :=
    foreach_ZE_up' (e := e) (Vars := Vars) from to step 0 (S (Z.abs_nat (from - to))) vars body.
Definition foreach_ZE_down {e Vars} from to step vars body (* 0 <? step *) :=
    foreach_ZE_down' (e := e) (Vars := Vars) from to step 0 (S (Z.abs_nat (from - to))) vars body.

Definition genlistM {A E} (f : nat -> monad A E) (n : nat) : monad (list A) E :=
  let indices := List.seq 0 n in
  foreachM indices [] (fun n xs => (f n >>= (fun x => returnm (xs ++ [x])%list))).

Definition and_boolM {E} (l : monad bool E) (r : monad bool E) : monad bool E :=
 l >>= (fun l => if l then r else returnm false).

Definition or_boolM {E} (l : monad bool E) (r : monad bool E) : monad bool E :=
 l >>= (fun l => if l then returnm true else r).


(* For termination of recursive functions.  We don't name assertions, so use
   the type class mechanism to find it. *)
Definition _limit_reduces {_limit} (_acc:Acc (Zwf 0) _limit) `{ArithFact (_limit >=? 0)} : Acc (Zwf 0) (_limit - 1).
refine (Acc_inv _acc _).
destruct H.
unbool_comparisons.
red.
Lia.lia.
Defined.

(* A version of well-foundedness of measures with a guard to ensure that
   definitions can be reduced without inspecting proofs, based on a coq-club
   thread featuring Barras, Gonthier and Gregoire, see
     https://sympa.inria.fr/sympa/arc/coq-club/2007-07/msg00014.html *)

Fixpoint pos_guard_wf {A:Type} {R:A -> A -> Prop} (p:positive) : well_founded R -> well_founded R :=
 match p with
 | xH => fun wfR x => Acc_intro x (fun y _ => wfR y)
 | xO p' => fun wfR x => let F := pos_guard_wf p' in Acc_intro x (fun y _ => F (F 
wfR) y)
 | xI p' => fun wfR x => let F := pos_guard_wf p' in Acc_intro x (fun y _ => F (F 
wfR) y)
 end.

Definition Zwf_guarded (z:Z) : Acc (Zwf 0) z :=
  Acc_intro _ (fun y H => match z with
  | Zpos p => pos_guard_wf p (Zwf_well_founded _) _
  | Zneg p => pos_guard_wf p (Zwf_well_founded _) _
  | Z0 => Zwf_well_founded _ _
  end).

(*val whileM : forall 'rv 'vars 'e. 'vars -> ('vars -> monad 'rv bool 'e) ->
                ('vars -> monad 'rv 'vars 'e) -> monad 'rv 'vars 'e*)
Fixpoint whileMT' {E Vars} limit (vars : Vars) (cond : Vars -> monad bool E) (body : Vars -> monad Vars E) (acc : Acc (Zwf 0) limit) : monad Vars E.
exact (
  if Z_ge_dec limit 0 then
    cond vars >>= fun cond_val =>
    if cond_val then
      body vars >>= fun vars => whileMT' _ _ (limit - 1) vars cond body (_limit_reduces acc)
    else returnm vars
  else fail "Termination limit reached").
Defined.

Definition whileMT {E Vars} (vars : Vars) (measure : Vars -> Z) (cond : Vars -> monad bool E) (body : Vars -> monad Vars E) : monad Vars E :=
  let limit := measure vars in
  whileMT' limit vars cond body (Zwf_guarded limit).

Fixpoint untilMT' {E Vars} limit (vars : Vars) (cond : Vars -> monad bool E) (body : Vars -> monad Vars E) (acc : Acc (Zwf 0) limit) : monad Vars E.
exact (
  if Z_ge_dec limit 0 then
    body vars >>= fun vars =>
    cond vars >>= fun cond_val =>
    if cond_val then returnm vars else untilMT' _ _ (limit - 1) vars cond body (_limit_reduces acc)
  else fail "Termination limit reached").
Defined.

Definition untilMT {E Vars} (vars : Vars) (measure : Vars -> Z) (cond : Vars -> monad bool E) (body : Vars -> monad Vars E) : monad Vars E :=
  let limit := measure vars in
  untilMT' limit vars cond body (Zwf_guarded limit).

Section Choose.

Definition choose_from_list {A E} (descr : string) (xs : list A) : monad A E :=
  (* Use sufficiently many nondeterministically chosen bits and convert into an
     index into the list *)
  choose_range descr 0 (Z.of_nat (List.length xs) - 1) >>= fun idx =>
  match List.nth_error xs (Z.to_nat idx) with
    | Some x => returnm x
    | None => fail ("choose " ++ descr)
  end.

Definition internal_pick {a e} (xs : list a) : monad a e :=
  choose_from_list "internal_pick" xs.

End Choose.

(* --- Operators_mwords.v *)

Definition autocast_m {e m n} (x : monad (mword m) e) : monad (mword n) e := x >>= fun x => returnm (autocast x).

(* --- should probably define generic versions of these, parametrised by Arch *)

Definition sail_barrier {e} (b : A.barrier) : monad unit e :=
  I.Next (I.Barrier b) I.Ret.

Definition sail_take_exception {e} (f : A.fault unit) : monad unit e :=
  I.Next (I.TakeException f) I.Ret.

Definition sail_return_exception {e} pa : monad unit e :=
  I.Next (I.ReturnException pa) I.Ret.

Definition sail_cache_op {e} (op : A.cache_op) : monad unit e :=
  I.Next (I.CacheOp tt op) I.Ret.

Definition sail_tlbi {e} (op : A.tlb_op) : monad unit e :=
  I.Next (I.TlbOp tt op) I.Ret.

Definition branch_announce {e} sz (addr : mword sz) : monad unit e :=
  (* TODO: branch_announce seems rather odd *)
  let addr : A.pa := vector_truncate addr _ in
  I.Next (I.BranchAnnounce addr tt) I.Ret.

Definition instr_announce {e sz} (opcode : mword sz) : monad unit e :=
  I.Next (I.InstrAnnounce (bitvector.bv_to_bvn (get_word opcode))) I.Ret.

Definition cast_N  {T : N -> Type} {m n} : forall (x : T m) (eq : m = n), T n.
refine (match m,n with
| N0, N0 => fun x _ => x
| Npos p1, Npos p2 => fun x e => cast_positive (fun p => T (Npos p)) p1 p2 x _
| _,_ => _
end); congruence.
Defined.

Definition sail_mem_read {e n} (req : Mem_read_request n (Z.of_N A.va_size) A.pa A.translation A.arch_ak) : monad (result (mword (8 * n) * option bool) A.abort) e.
refine (
  let n' := Z.to_N n in
  let va : option (bv A.va_size) :=
    match req.(Mem_read_request_va) with
    | None => None
    | Some va =>
        Some (match A.va_size as x return mword (Z.of_N x) -> bv x with
        | N0 => fun y => y
        | Npos _ => fun y => cast_N y _
        end va)
    end
  in
  let req' := I.ReadReq.make unit n' req.(Mem_read_request_pa) req.(Mem_read_request_access_kind) va req.(Mem_read_request_translation) req.(Mem_read_request_tag) tt in
  let k r :=
    match r with
    | inl (x,y) =>
        let x' := cast_N (m := 8 * Z.to_N n) (n := N.of_nat (Z.to_nat (8 * n))) x _ in
        let x'' : mword (8 * n) :=
          match n return bitvector.bv (N.of_nat (Z.to_nat (8 * n))) -> mword (8 * n) with
          | Zneg _ => fun x => x
          | Z0 => fun x => x
          | Zpos _ => fun x => x
          end x'
        in
        I.Ret (Ok (x'', y))
    | inr abort => I.Ret (Err abort)
    end
  in
  I.Next (I.MemRead n' req') k
).
Lia.lia.
Unshelve.
Lia.lia.
Defined.

Definition sail_mem_write {e n} (req : Mem_write_request n (Z.of_N A.va_size) A.pa A.translation A.arch_ak) : monad (result (option bool) A.abort) e.
refine (
  let n' := Z.to_N n in
  match req.(Mem_write_request_value) with
  | None => I.Ret (Ok None) (* TODO: ought to support tag-only writes *)
  | Some value =>
      let va : option (bv A.va_size) :=
        match req.(Mem_write_request_va) with
        | None => None
        | Some va =>
            Some (match A.va_size as x return mword (Z.of_N x) -> bv x with
                  | N0 => fun y => y
                  | Npos _ => fun y => cast_N y _
                  end va)
        end
      in
      let value :=
        match n return mword (8 * n) -> bitvector.bv (N.of_nat (Z.to_nat (8 * n))) with
        | Zneg _ => fun x => x
        | Z0 => fun x => x
        | Zpos _ => fun x => x
        end value
      in
      let value := cast_N value _ in
      let tag := match req.(Mem_write_request_tag) with None => false | Some b => b end in
      let req' := I.WriteReq.make unit n' req.(Mem_write_request_pa) req.(Mem_write_request_access_kind) value va req.(Mem_write_request_translation) tag tt tt in
      let k x :=
        match x with
        | inl y => I.Ret (Ok y)
        | inr y => I.Ret (Err y)
        end
      in
      I.Next (I.MemWrite n' req') k
  end
).
Lia.lia.
Unshelve.
Lia.lia.
Defined.

(* ----------- *)

End Defs.
