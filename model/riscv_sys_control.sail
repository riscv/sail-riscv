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

/* Machine-mode and supervisor-mode functionality. */

/* Reservation handling for LR/SC.
 *
 * The reservation state is maintained external to the model since the
 * reservation behavior is platform-specific anyway and maintaining
 * this state outside the model simplifies the concurrency analysis.
 *
 * These are externs are defined here in the system module since
 * we currently perform reservation cancellation on privilege level
 * transition.  Ideally, the platform should get more visibility into
 * where cancellation can be performed.
 */

val speculate_conditional = monadic {ocaml: "Platform.speculate_conditional", interpreter: "excl_res", c: "speculate_conditional", lem: "speculate_conditional_success"} : unit -> bool

val load_reservation = {ocaml: "Platform.load_reservation", interpreter: "Platform.load_reservation", c: "load_reservation", lem: "load_reservation"} : xlenbits -> unit
val match_reservation = {ocaml: "Platform.match_reservation", interpreter: "Platform.match_reservation", lem: "match_reservation", c: "match_reservation"} : xlenbits -> bool
val cancel_reservation = {ocaml: "Platform.cancel_reservation", interpreter: "Platform.cancel_reservation", c: "cancel_reservation", lem: "cancel_reservation"} : unit -> unit

/* Exception delegation: given an exception and the privilege/virtualization mode at which
 * it occured, returns the privilege/virtualization mode at which it should be handled.
 */
function exception_delegatee(e : ExceptionType, cur_p: Privilege, cur_v : Virtualization) -> (Privilege, Virtualization) = {
  /* Determine delegation privilege and virtualization mode based on xedeleg CSRs
   *
   * medeleg delegates to HS-mode
   * hedeleg delegates to VS-mode
   * sedeleg delegates to (V)U-mode
   */
  let idx = num_of_ExceptionType(e);
  let del_to_hs = bit_to_bool(medeleg.bits[idx]);
  let del_to_vs = bit_to_bool(hedeleg.bits[idx]);
  let del_to_u  = bit_to_bool(sedeleg.bits[idx]);
  let (del_p, del_v): (Privilege, Virtualization) = match cur_v {
    V0 => match (del_to_hs, del_to_u) {
      (false, _)    => (Machine, V0),
      (true, false) => (Supervisor, V0),
      (true, true)  => (User, V0)
    },
    V1 => match (del_to_hs, del_to_vs, del_to_u) {
      (false, _, _)       => (Machine, V0),
      (true, false, _)    => (Supervisor, V0),
      (true, true, false) => (Supervisor, V1),
      (true, true, true)  => (User, V1)
    }
  };
  /* Check if delegation privilege exists:
   *
   * if S-mode is absent, medeleg delegates directly to U-mode if 'N' is supported
   */
  let (del_p, del_v): (Privilege, Virtualization) = match del_p {
    Machine    => (Machine, V0),
    Supervisor => if haveSupMode() then (Supervisor, del_v)
                  else if haveNExt() then (User, cur_v) /* Use original virt mode when delegating directly to U-mode, otherwise a trap attempt from VU->HS would end up in U */
                  else (Machine, V0),
    User       => if haveUsrMode() then (User, del_v)
                  else if haveSupMode() then (Supervisor, del_v)
                  else (Machine, V0)
  };
  /* Check transition to less-privileged mode:
   *
   * trap delegation should never cause a transition to a lower privilege mode
   * trap delegation should never cause a transition to a more virtualized mode
   */
  if (privLevel_to_bits(del_p) >=_u privLevel_to_bits(cur_p)) & (virtMode_to_bits(del_v) <=_u virtMode_to_bits(cur_v))
  then (del_p, del_v)
  else (cur_p, cur_v)
}

/*!
 * Interrupts are prioritized in privilege order, and for each
 * privilege, in the order: external, software, timers.
 */
function findPendingInterrupt(ip : xlenbits) -> option(InterruptType) = {
  let ip = Mk_Minterrupts(ip);
  if      ip[MEI] == 0b1 then Some(I_M_External)
  else if ip[MSI] == 0b1 then Some(I_M_Software)
  else if ip[MTI] == 0b1 then Some(I_M_Timer)
  else if ip[SEI] == 0b1 then Some(I_S_External)
  else if ip[SSI] == 0b1 then Some(I_S_Software)
  else if ip[STI] == 0b1 then Some(I_S_Timer)
  else if haveHExt() & ip[SGEI] == 0b1 then Some(I_G_External)
  else if haveHExt() & ip[VSEI] == 0b1 then Some(I_VS_External)
  else if haveHExt() & ip[VSSI] == 0b1 then Some(I_VS_Software)
  else if haveHExt() & ip[VSTI] == 0b1 then Some(I_VS_Timer)
  else if haveNExt() & ip[UEI] == 0b1 then Some(I_U_External)
  else if haveNExt() & ip[USI] == 0b1 then Some(I_U_Software)
  else if haveNExt() & ip[UTI] == 0b1 then Some(I_U_Timer)
  else None()
}

/*! Translate VS-level interrupts to their S-level counterpart */
function translateVSInterrupts(i : Minterrupts) -> Minterrupts = {
  let t = i;
  let t = [[t with SEI = i[VSEI]] with VSEI = 0b0];
  let t = [[t with SSI = i[VSSI]] with VSSI = 0b0];
  let t = [[t with STI = i[VSTI]] with VSTI = 0b0];
  // TODO: add hook for extensions to translate interrupts as well
  t
}

/*!
 * Process the pending interrupts xip at a privilege according to
 * the enabled flags xie and the delegation in xideleg. Return
 * either the set of pending interrupts, or the set of interrupts
 * delegated to the next lower privilege.
 */
union interrupt_set = {
  Ints_Pending   : xlenbits,
  Ints_Delegated : xlenbits,
  Ints_Empty     : unit
}
function processPending(xip : Minterrupts, xie : Minterrupts, xideleg : xlenbits,
                        priv_enabled : bool) -> interrupt_set = {
  /* interrupts that are enabled but not delegated are pending */
  let  effective_pend = xip.bits & xie.bits & (~ (xideleg));
  /* the others are delegated */
  let  effective_delg = xip.bits & xideleg;
  /* we have pending interrupts if this privilege is enabled */
  if      priv_enabled & (effective_pend != zero_extend(0b0))
  then    Ints_Pending(effective_pend)
  else if effective_delg != zero_extend(0b0)
  then    Ints_Delegated(effective_delg)
  else    Ints_Empty()
}

/*!
 * Given the current privilege and virtualization, iterate over privileges
 * to get a pending set for an enabled privilege.
 *
 * This is only called for M/U, M/S/U or M/HS/VS/U/VU systems.
 */
function getPendingSet(priv : Privilege, virt: Virtualization) -> option((xlenbits, Privilege, Virtualization)) = {
  assert(haveUsrMode(), "no user mode: M/U, M/S/U or M/HS/VS/U/VU system required");
  if  (mip.bits & mie.bits) == zeros() then /* fast path */
    None()
  else if haveNExt() then { /* Interrupt delegation by the deprecated N-extension (User-level interrupts) */
    /* Higher privileges than the current one are implicitly enabled,
     * while lower privileges are blocked.  An unsupported privilege is
     * considered blocked.
     */
    let mIE = priv != Machine | (priv == Machine & mstatus[MIE] == 0b1);
    let sIE = haveSupMode() & (priv == User | (priv == Supervisor & mstatus[SIE] == 0b1));
    let uIE = haveNExt() & (priv == User & mstatus[UIE] == 0b1);
    match processPending(mip, mie, mideleg.bits, mIE) {
      Ints_Empty()      => None(),
      Ints_Pending(p)   => let r = (p, Machine, V0) in Some(r),
      Ints_Delegated(d) =>
        if not(haveSupMode()) then {
          if uIE then let r = (d, User, V0) in Some(r)
          else                             None()
        } else {
          /* the delegated bits are pending for S-mode */
          match processPending(Mk_Minterrupts(d), mie, sideleg.bits, sIE) {
            Ints_Empty()      => None(),
            Ints_Pending(p)   => let r = (p, Supervisor, V0) in Some(r),
            Ints_Delegated(d) => if   uIE
                                 then let r = (d, User, V0) in Some(r)
                                 else None()
          }
        }
    }
  } else {
    // Higher privileges than the current one are implicitly enabled, while lower privileges are blocked.
    let mIE  = priv != Machine | (priv == Machine & mstatus[MIE] == 0b1);
    let sIE  = haveSupMode() & (virt == V1 | priv == User | (priv == Supervisor & mstatus[SIE] == 0b1));
    let vsIE = haveHExt() & virt == V1 & (priv == User | (priv == Supervisor & vsstatus[SIE] == 0b1)); // Enabled H-ext implies presence of S-mode

    match processPending(mip, mie, mideleg.bits, mIE) {
      Ints_Empty()      => None(),
      Ints_Pending(p)   => Some(p, Machine, V0),
      Ints_Delegated(d) => match processPending(Mk_Minterrupts(d), mie, hideleg.bits, sIE) {
        Ints_Empty()      => None(),
        Ints_Pending(p)   => Some(p, Supervisor, V0),
        Ints_Delegated(d) => match processPending(Mk_Minterrupts(d), mie, zeros(), vsIE) {
          Ints_Empty()      => None(),
          Ints_Pending(p)   => Some(translateVSInterrupts(Mk_Minterrupts(p)).bits, Supervisor, V1),
          Ints_Delegated(d) => internal_error(__FILE__, __LINE__, "Delegate interrupts beyond VS-mode")
        }
      }
    }
  }
}

/* Examine the current interrupt state and return an interrupt to be *
 * handled (if any), and the privilege it should be handled at.
 */
function dispatchInterrupt(priv : Privilege, virt: Virtualization) -> option((InterruptType, Privilege, Virtualization)) = {
  /* If we don't have different privilege levels, we don't need to check delegation.
   * Absence of U-mode implies absence of S-mode.
   */
  if not(haveUsrMode()) | (not(haveSupMode()) & not(haveNExt())) then {
    assert(priv == Machine, "invalid current privilege");
    let enabled_pending = mip.bits & mie.bits;
    match findPendingInterrupt(enabled_pending) {
      Some(i) => let r = (i, Machine, V0) in Some(r),
      None()  => None()
    }
  } else {
    match getPendingSet(priv, virt) {
      None()      => None(),
      Some(ip, del_p, del_v) => match findPendingInterrupt(ip) {
                       None()  => None(),
                       Some(i) => let r = (i, del_p, del_v) in Some(r)
                     }
    }
  }
}

/* types of privilege transitions */

union ctl_result = {
  CTL_TRAP : (ExceptionType, ExceptionContext),
  CTL_SRET : unit,
  CTL_MRET : unit,
  CTL_URET : unit
}

/* Is it legal for mtinst or htinst to hold a tranformed instruction on a given fault */
function exc_causes_transformed_inst_in_xtinst(e : ExceptionType) -> bool =
  match e {
    E_Load_Addr_Align()   => true,
    E_Load_Access_Fault() => true,
    E_SAMO_Addr_Align()   => true,
    E_SAMO_Access_Fault() => true,
    E_Load_Page_Fault()   => true,
    E_SAMO_Page_Fault()   => true,
    E_Load_GPage_Fault()  => true,
    E_SAMO_GPage_Fault()  => true,
    _                     => false,
  }

val plat_xtinst_has_transformed_inst = {ocaml: "Platform.xtinst_has_transformed_inst",
                                        c: "plat_xtinst_has_transformed_inst",
                                        _: "plat_xtinst_has_transformed_inst"} : unit -> bool

$ifdef RVFI_DII
val rvfi_trap : unit -> unit
// TODO: record rvfi_trap_data
function rvfi_trap () =
  rvfi_inst_data[rvfi_trap] = 0x01
$else
val rvfi_trap : unit -> unit
function rvfi_trap () = ()
$endif

/* handle exceptional ctl flow by updating nextPC and operating privilege */

function trap_handler(del_priv : Privilege, del_virt : Virtualization, pc : xlenbits, cause : TrapCause, context : ExceptionContext)
                     -> xlenbits = {
  rvfi_trap();

  if   get_config_print_platform()
  then print_platform("handling " ^ trapCause_to_str(cause)
                      ^ " at priv " ^ to_str(del_priv, del_virt)
                      ^ " with tval " ^ BitStr(some_or_zero(context.excinfo))
                      ^ " and tinst " ^ BitStr(some_or_zero(context.excinst)));

  cancel_reservation();

  match (del_priv) {
    Machine => {
      mcause->IsInterrupt() = bool_to_bits(trapCause_is_interrupt(cause));
      mcause->Cause()       = zero_extend(trapCause_to_bits(cause));

      mepc = pc;

      mstatus->MPIE() = mstatus[MIE];
      mstatus->MIE()  = 0b0;
      mstatus->MPP()  = privLevel_to_bits(cur_privilege);
      if sizeof(xlen) == 32
      then mstatush = set_mstatush_MPV(mstatush, virtMode_to_bits(cur_virtualization))
      else mstatus = set_mstatus_MPV(mstatus, virtMode_to_bits(cur_virtualization));

      /* Set mstatus(h).GVA when a guest virtual address is written to mtval */
      match architecture(misa[MXL]) {
        Some(RV32) => mstatush = set_mstatush_GVA(mstatush, if context.info_is_gva then 0b1 else 0b0),
        Some(_)    => mstatus = set_mstatus_GVA(mstatus, if context.info_is_gva then 0b1 else 0b0),
        None()     => internal_error(__FILE__, __LINE__, "Invalid architecture in misa")
      };

      mtval           = some_or_zero(context.excinfo);
      mtval2          = some_or_zero(context.excinfo2);
      mtinst          = some_or_zero(context.excinst);

      cur_privilege   = del_priv;
      cur_virtualization = del_virt;

      handle_trap_extension(del_priv, pc, context.ext);

      if   get_config_print_reg()
      then print_reg("CSR mstatus <- " ^ BitStr(mstatus.bits));
      if (sizeof(xlen) == 32) & get_config_print_reg()
      then print_reg("CSR mstatush <- " ^ BitStr(mstatush.bits));

      prepare_trap_vector(del_priv, del_virt, mcause)
    },
    Supervisor => match (del_virt) {
      V0 => {
        assert (haveSupMode(), "no supervisor mode present for delegation");

        scause->IsInterrupt() = bool_to_bits(trapCause_is_interrupt(cause));
        scause->Cause()       = zero_extend(trapCause_to_bits(cause));

        sepc = pc;

        mstatus->SPIE() = mstatus[SIE];
        mstatus->SIE()  = 0b0;
        mstatus->SPP()  = match cur_privilege {
          User => 0b0,
          Supervisor => 0b1,
          Machine => internal_error(__FILE__, __LINE__, "invalid privilege for s-mode trap")
        };

        hstatus->SPV() = virtMode_to_bits(cur_virtualization);
        hstatus->GVA() = bool_to_bits(context.info_is_gva);
        if cur_virtualization == V1 then hstatus->SPVP() = mstatus[SPP];

        stval           = some_or_zero(context.excinfo);
        htval           = some_or_zero(context.excinfo2);
        htinst          = some_or_zero(context.excinst);

        cur_privilege   = del_priv;
        cur_virtualization = del_virt;

        handle_trap_extension(del_priv, pc, context.ext);

        if   get_config_print_reg()
        then print_reg("CSR mstatus <- " ^ BitStr(mstatus.bits));

        prepare_trap_vector(del_priv, del_virt, scause)
      },
      V1 => {
        assert (haveSupMode() & haveHExt(), "no virtual supervisor mode present for delegation");

        vscause->IsInterrupt() = bool_to_bits(trapCause_is_interrupt(cause));
        vscause->Cause()       = zero_extend(trapCause_to_bits(cause));

        vsepc = pc;

        vsstatus->SPIE() = mstatus[SIE];
        vsstatus->SIE()  = 0b0;
        vsstatus->SPP()  = match cur_privilege {
          User => 0b0,
          Supervisor => 0b1,
          Machine => internal_error(__FILE__, __LINE__, "invalid privilege for vs-mode trap")
        };
        vstval = some_or_zero(context.excinfo);

        cur_privilege   = del_priv;
        cur_virtualization = del_virt;

        handle_trap_extension(del_priv, pc, context.ext);

        if   get_config_print_reg()
        then print_reg("CSR vsstatus <- " ^ BitStr(vsstatus.bits));

        prepare_trap_vector(del_priv, del_virt, vscause)
      }
    },
    User => {
       assert(haveUsrMode(), "no user mode present for delegation");

       ucause->IsInterrupt() = bool_to_bits(trapCause_is_interrupt(cause));
       ucause->Cause()       = zero_extend(trapCause_to_bits(cause));

       uepc = pc;

       mstatus->UPIE() = mstatus[UIE];
       mstatus->UIE()  = 0b0;

       utval = some_or_zero(context.excinfo);

       cur_privilege   = del_priv;
       cur_virtualization = del_virt;

       handle_trap_extension(del_priv, pc, context.ext);

       if   get_config_print_reg()
       then print_reg("CSR mstatus <- " ^ BitStr(mstatus.bits));

       prepare_trap_vector(del_priv, del_virt, ucause)
    }
  };
}

function exception_handler(cur_priv : Privilege,
                           cur_virt: Virtualization,
                           ctl : ctl_result,
                           pc: xlenbits) -> xlenbits = {
  match (cur_priv, ctl) {
    (_, CTL_TRAP(e, c)) => {
      let (del_priv, del_virt) = exception_delegatee(e, cur_privilege, cur_virtualization);
      if   get_config_print_platform()
      then print_platform("trapping from " ^ to_str(cur_priv, cur_virtualization) ^
                          " to " ^ to_str(del_priv, del_virt) ^
                          " to handle " ^ to_str(e));
      trap_handler(del_priv, del_virt, pc, E(e), c)
    },
    (_, CTL_MRET())  => {
      let prev_priv   = cur_privilege;
      let prev_virt   = cur_virtualization;

      mstatus->MIE()  = mstatus[MPIE];
      mstatus->MPIE() = 0b1;

      cur_privilege   = privLevel_of_bits(mstatus[MPP]);
      mstatus->MPP()  = privLevel_to_bits(if haveUsrMode() then User else Machine);
      if   cur_privilege != Machine
      then mstatus[MPRV] = 0b0;

      cur_virtualization = virtMode_of_bits(get_mstatus_MPV(mstatus, mstatush));
      if sizeof(xlen) == 32
      then mstatush = set_mstatush_MPV(mstatush, 0b0)
      else mstatus = set_mstatus_MPV(mstatus, 0b0);

      if   get_config_print_reg()
      then print_reg("CSR mstatus <- " ^ BitStr(mstatus.bits));
      if (sizeof(xlen) == 32) & get_config_print_reg()
      then print_reg("CSR mstatush <- " ^ BitStr(mstatush.bits));
      if   get_config_print_platform()
      then print_platform("ret-ing from " ^ to_str(prev_priv) ^ " (" ^ to_str(prev_virt) ^ ") to " ^ to_str(cur_privilege) ^ " (" ^ to_str(cur_virtualization) ^ ")");

      cancel_reservation();
      prepare_xret_target(Machine, prev_virt) & pc_alignment_mask()
    },
    (_, CTL_SRET())  => {
      let prev_priv   = cur_privilege;
      let prev_virt   = cur_virtualization;

      match prev_virt {
        V0 => {
          mstatus->SIE()  = mstatus[SPIE];
          mstatus->SPIE() = 0b1;

          cur_privilege   = if mstatus[SPP] == 0b1 then Supervisor else User;
          mstatus->SPP()  = 0b0;
          if   cur_privilege != Machine
          then mstatus->MPRV() = 0b0;

          cur_virtualization = virtMode_of_bits(hstatus[SPV]);
          hstatus->SPV() = 0b0;
        },
        V1 => {
          vsstatus->SIE()  = vsstatus[SPIE];
          vsstatus->SPIE() = 0b1;

          cur_privilege    = if vsstatus[SPP] == 0b1 then Supervisor else User;
          vsstatus->SPP()  = 0b0;
          if   cur_privilege != Machine
          then mstatus->MPRV() = 0b0;

          cur_virtualization = V1;
        }
      };
      if get_config_print_reg() then {
        print_reg("CSR mstatus <- " ^ BitStr(mstatus.bits));
        print_reg("CSR hstatus <- " ^ BitStr(hstatus.bits));
      };
      if   get_config_print_platform()
      then print_platform("ret-ing from " ^ to_str(prev_priv) ^" (" ^ to_str(prev_virt) ^ ") to "
                            ^ to_str(cur_privilege) ^ " (" ^ to_str(cur_virtualization) ^ ")");

      cancel_reservation();
      prepare_xret_target(Supervisor, prev_virt) & pc_alignment_mask()
    },
    (_, CTL_URET())  => {
      let prev_priv   = cur_privilege;
      let prev_virt   = cur_virtualization;
      mstatus->UIE()  = mstatus[UPIE];
      mstatus->UPIE() = 0b1;
      cur_privilege   = User;

      if   get_config_print_reg()
      then print_reg("CSR mstatus <- " ^ BitStr(mstatus.bits));
      if   get_config_print_platform()
      then print_platform("ret-ing from " ^ to_str(prev_priv) ^" (" ^ to_str(prev_virt) ^ ") to "
                            ^ to_str(cur_privilege) ^ " (" ^ to_str(cur_virtualization) ^ ")");

      cancel_reservation();
      prepare_xret_target(User, prev_virt) & pc_alignment_mask()
    }
  }
}

function handle_exception(e: ExceptionType, c: ExceptionContext) -> unit = {
  // If excinst is None, check if transformed inst should be written
  let c = {c with excinst = if c.excinst != None()
                            then c.excinst
                            else if (plat_xtinst_has_transformed_inst() & exc_causes_transformed_inst_in_xtinst(e))
                            then Some(zero_extend(instbits_transformed))
                            else None()} in
  set_next_pc(exception_handler(cur_privilege, cur_virtualization, CTL_TRAP(e, c), PC))
}

function handle_mem_exception(addr : xlenbits, e : ExceptionType) -> unit = {
  /* handle_mem_exception only supports the following exception causes */
  assert(match e {
          E_Breakpoint()         => true,
          E_Fetch_Addr_Align()   => true,
          E_Load_Addr_Align()    => true,
          E_SAMO_Addr_Align()    => true,
          E_Fetch_Access_Fault() => true,
          E_Load_Access_Fault()  => true,
          E_SAMO_Access_Fault()  => true,
          _                      => false
        }, "exception not supported by current handler");
  handle_exception(e, mem_exception_context(addr, cur_virtualization == V1))
}

function handle_interrupt(i : InterruptType, del_priv : Privilege, del_virt: Virtualization) -> unit =
  set_next_pc(trap_handler(del_priv, del_virt, PC, I(i), empty_exception_context()))

/*!
 * Return whether or not FIOM is currently active, based on the current
 * privilege and the menvcfg/senvcfg settings. This means that I/O fences
 * imply memory fence.
 */
function is_fiom_active() -> bool = {
  match (cur_privilege, cur_virtualization) {
    (Machine, _) => false,
    (Supervisor, V0) => menvcfg[FIOM] == 0b1,
    (Supervisor, V1) => (menvcfg[FIOM] | henvcfg[FIOM]) == 0b1,
    (User, V0) => (menvcfg[FIOM] | senvcfg[FIOM]) == 0b1,
    (User, V1) => (menvcfg[FIOM] | henvcfg[FIOM] | senvcfg[FIOM]) == 0b1,
  }
}

/* state state initialization */

function init_sys() -> unit = {
  cur_privilege = Machine;

  mhartid     = zero_extend(0b0);

  misa->MXL() = arch_to_bits(if sizeof(xlen) == 32 then RV32 else RV64);
  misa->A()   = 0b1;                             /* atomics */
  misa->C()   = bool_to_bits(sys_enable_rvc());  /* RVC */
  misa->I()   = 0b1;                             /* base integer ISA */
  misa->M()   = 0b1;                             /* integer multiply/divide */
  misa->U()   = 0b1;                             /* user-mode */
  misa->S()   = 0b1;                             /* supervisor-mode */
  misa->H()   = bool_to_bits(sys_enable_hext()); /* hypervisor extension */
  misa->V()   = bool_to_bits(sys_enable_vext()); /* vector extension */
  /* We currently support both F and D */
  misa[F]   = bool_to_bits(sys_enable_fdext());      /* single-precision */
  misa[D]   = if   sizeof(flen) >= 64
                then bool_to_bits(sys_enable_fdext())  /* double-precision */
                else 0b0;

  if   sys_enable_fdext() & sys_enable_zfinx()
  then internal_error(__FILE__, __LINE__, "F and Zfinx cannot both be enabled!");

  if   sys_enable_next() & sys_enable_hext()
  then internal_error(__FILE__, __LINE__, "The hypervisor extension currently does not consider the possibility of user-mode interrupts");

  mstatus = set_mstatus_SXL(mstatus, misa[MXL]);
  mstatus = set_mstatus_UXL(mstatus, misa[MXL]);
  mstatus->SD()   = 0b0;

  /* set to little-endian mode */
  if sizeof(xlen) == 64 then {
    mstatus = Mk_Mstatus([mstatus.bits with 37 .. 36 = 0b00])
  };
  mstatush.bits = zero_extend(0b0);

  mip.bits     = zero_extend(0b0);
  mie.bits     = zero_extend(0b0);
  mideleg.bits = zero_extend(0b0);
  medeleg.bits = zero_extend(0b0);
  mtvec.bits   = zero_extend(0b0);
  mcause.bits  = zero_extend(0b0);
  mepc            = zero_extend(0b0);
  mtval           = zero_extend(0b0);
  mscratch        = zero_extend(0b0);

  mcycle          = zero_extend(0b0);
  mtime           = zero_extend(0b0);

  mcounteren.bits = zero_extend(0b0);

  minstret           = zero_extend(0b0);
  minstret_increment = true;

  menvcfg.bits = zero_extend(0b0);
  senvcfg.bits = zero_extend(0b0);
  /* initialize vector csrs */
  elen               = 0b1; /* ELEN=64 as the common case */
  vlen               = 0b0100; /* VLEN=512 as a default value */
  vlenb              = to_bits(sizeof(xlen), 2 ^ (get_vlen_pow() - 3)); /* vlenb holds the constant value VLEN/8 */
  /* VLEN value needs to be manually changed currently.
   * See riscv_vlen.sail for details.
   */
  vstart             = zero_extend(0b0);
  vxsat              = 0b0;
  vxrm               = 0b00;
  vcsr[vxrm]       = vxrm;
  vcsr[vxsat]      = vxsat;
  vl                 = zero_extend(0b0);
  vtype[vill]      = 0b1;
  vtype[reserved]  = zero_extend(0b0);
  vtype[vma]       = 0b0;
  vtype[vta]       = 0b0;
  vtype[vsew]      = 0b000;
  vtype[vlmul]     = 0b000;

  init_pmp();
  if(sys_enable_hext())
  then init_hext();

  // log compatibility with spike
  if   get_config_print_reg()
  then print_reg("CSR mstatus <- " ^ BitStr(mstatus.bits) ^ " (input: " ^ BitStr(zero_extend(0b0) : xlenbits) ^ ")")
}

/* memory access exceptions, defined here for use by the platform model. */

union MemoryOpResult ('a : Type) = {
  MemValue     : 'a,
  MemException : ExceptionType
}

val MemoryOpResult_add_meta : forall ('t : Type). (MemoryOpResult('t), mem_meta) -> MemoryOpResult(('t, mem_meta))
function MemoryOpResult_add_meta(r, m) = match r {
  MemValue(v)     => MemValue(v, m),
  MemException(e) => MemException(e)
}

val MemoryOpResult_drop_meta : forall ('t : Type). MemoryOpResult(('t, mem_meta)) -> MemoryOpResult('t)
function MemoryOpResult_drop_meta(r) = match r {
  MemValue(v, m)  => MemValue(v),
  MemException(e) => MemException(e)
}
