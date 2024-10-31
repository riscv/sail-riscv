/*=======================================================================================*/
/*  This Sail RISC-V architecture model, comprising all files and                        */
/*  directories except where otherwise noted is subject the BSD                          */
/*  two-clause license in the LICENSE file.                                              */
/*                                                                                       */
/*  SPDX-License-Identifier: BSD-2-Clause                                                */
/*=======================================================================================*/

/* Machine-mode and supervisor-mode functionality. */

enum clause extension = Ext_Zkr
function clause extensionEnabled(Ext_Zkr) = true

/* CSR access control */

// TODO: These is_CSR_defined definitions should be moved to the files
// corresponding to their extensions rather than all be here.

/* machine mode: informational */
function clause is_CSR_defined(0xf11) = true // mvendorid
function clause is_CSR_defined(0xf12) = true // marchdid
function clause is_CSR_defined(0xf13) = true // mimpid
function clause is_CSR_defined(0xf14) = true // mhartid
function clause is_CSR_defined(0xf15) = true // mconfigptr
/* machine mode: trap setup */
function clause is_CSR_defined(0x300) = true // mstatus
function clause is_CSR_defined(0x301) = true // misa
function clause is_CSR_defined(0x302) = extensionEnabled(Ext_S) // medeleg
function clause is_CSR_defined(0x303) = extensionEnabled(Ext_S) // mideleg
function clause is_CSR_defined(0x304) = true // mie
function clause is_CSR_defined(0x305) = true // mtvec
function clause is_CSR_defined(0x306) = extensionEnabled(Ext_U) // mcounteren
function clause is_CSR_defined(0x30A) = extensionEnabled(Ext_U) // menvcfg
function clause is_CSR_defined(0x310) = xlen == 32 // mstatush
function clause is_CSR_defined(0x31A) = extensionEnabled(Ext_U) & (xlen == 32) // menvcfgh
function clause is_CSR_defined(0x320) = true // mcountinhibit


/* machine mode: trap handling */
function clause is_CSR_defined(0x340) = true // mscratch
function clause is_CSR_defined(0x341) = true // mepc
function clause is_CSR_defined(0x342) = true // mcause
function clause is_CSR_defined(0x343) = true // mtval
function clause is_CSR_defined(0x344) = true // mip

// pmpcfgN
function clause is_CSR_defined(0x3A) @ idx : bits(4) = sys_pmp_count() > unsigned(idx) & (idx[0] == bitzero | xlen == 32)

// pmpaddrN. Unfortunately the PMP index does not nicely align with the CSR index bits.
function clause is_CSR_defined(0x3B) @ idx : bits(4) = sys_pmp_count() > unsigned(0b00 @ idx)
function clause is_CSR_defined(0x3C) @ idx : bits(4) = sys_pmp_count() > unsigned(0b01 @ idx)
function clause is_CSR_defined(0x3D) @ idx : bits(4) = sys_pmp_count() > unsigned(0b10 @ idx)
function clause is_CSR_defined(0x3E) @ idx : bits(4) = sys_pmp_count() > unsigned(0b11 @ idx)

/* counters */
function clause is_CSR_defined(0b0011001 /* 0x320 */ @ index : bits(5) if unsigned(index) >= 3) = extensionEnabled(Ext_Zihpm) // mhpmevent3..31

function clause is_CSR_defined(0xB00) = true // mcycle
function clause is_CSR_defined(0xB02) = true // minstret

function clause is_CSR_defined(0b1011000 /* 0xB00 */ @ index : bits(5) if unsigned(index) >= 3) = extensionEnabled(Ext_Zihpm) // mhpmcounter3..31

function clause is_CSR_defined(0xB80) = xlen == 32 // mcycleh
function clause is_CSR_defined(0xB82) = xlen == 32 // minstreth

function clause is_CSR_defined(0b1011100 /* 0xB80 */ @ index : bits(5) if unsigned(index) >= 3) = extensionEnabled(Ext_Zihpm) & (xlen == 32) // mhpmcounterh3..31

/* disabled trigger/debug module */
function clause is_CSR_defined(0x7a0) = true

/* supervisor mode: trap setup */
function clause is_CSR_defined(0x100) = extensionEnabled(Ext_S) // sstatus
function clause is_CSR_defined(0x104) = extensionEnabled(Ext_S) // sie
function clause is_CSR_defined(0x105) = extensionEnabled(Ext_S) // stvec
function clause is_CSR_defined(0x106) = extensionEnabled(Ext_S) // scounteren
function clause is_CSR_defined(0x10A) = extensionEnabled(Ext_S) // senvcfg

/* supervisor mode: trap handling */
function clause is_CSR_defined(0x140) = extensionEnabled(Ext_S) // sscratch
function clause is_CSR_defined(0x141) = extensionEnabled(Ext_S) // sepc
function clause is_CSR_defined(0x142) = extensionEnabled(Ext_S) // scause
function clause is_CSR_defined(0x143) = extensionEnabled(Ext_S) // stval
function clause is_CSR_defined(0x144) = extensionEnabled(Ext_S) // sip

/* supervisor mode: address translation */
function clause is_CSR_defined(0x180) = extensionEnabled(Ext_S) // satp

/* user mode: counters */
function clause is_CSR_defined(0xC00) = extensionEnabled(Ext_U) // cycle
function clause is_CSR_defined(0xC01) = extensionEnabled(Ext_U) // time
function clause is_CSR_defined(0xC02) = extensionEnabled(Ext_U) // instret

function clause is_CSR_defined(0b1100000 /* 0xC00 */ @ index : bits(5) if unsigned(index) >= 3) = extensionEnabled(Ext_Zihpm) & extensionEnabled(Ext_U) // hpmcounter3..31

function clause is_CSR_defined(0xC80) = extensionEnabled(Ext_U) & (xlen == 32) // cycleh
function clause is_CSR_defined(0xC81) = extensionEnabled(Ext_U) & (xlen == 32) // timeh
function clause is_CSR_defined(0xC82) = extensionEnabled(Ext_U) & (xlen == 32) // instreth

function clause is_CSR_defined(0b1100100 /* 0xC80 */ @ index : bits(5) if unsigned(index) >= 3) = extensionEnabled(Ext_Zihpm) & extensionEnabled(Ext_U) & (xlen == 32) // hpmcounterh3..31

/* user mode: Zkr */
function clause is_CSR_defined(0x015) = extensionEnabled(Ext_Zkr)

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

val speculate_conditional = impure {interpreter: "excl_res", c: "speculate_conditional", lem: "speculate_conditional_success"} : unit -> bool

val load_reservation = impure {interpreter: "Platform.load_reservation", c: "load_reservation", lem: "load_reservation"} : xlenbits -> unit
val match_reservation = pure {interpreter: "Platform.match_reservation", lem: "match_reservation", c: "match_reservation"} : xlenbits -> bool
val cancel_reservation = impure {interpreter: "Platform.cancel_reservation", c: "cancel_reservation", lem: "cancel_reservation"} : unit -> unit

/* Exception delegation: given an exception and the privilege at which
 * it occured, returns the privilege at which it should be handled.
 */
function exception_delegatee(e : ExceptionType, cur_p : Privilege, cur_v : Virtualization) -> (Privilege, Virtualization) = {
  /* Determine delegation privilege and virtualization mode based on xedeleg CSRs
   *
   * medeleg delegates to HS-mode
   * hedeleg delegates to VS-mode
   */
  let idx       = num_of_ExceptionType(e);
  let del_to_hs = bit_to_bool(medeleg.bits[idx]);
  let del_to_vs = bit_to_bool(hedeleg.bits[idx]);
  let (del_p, del_v): (Privilege, Virtualization) = match (del_to_hs, del_to_vs) {
      (false, _,)   => (Machine, V0),
      (true, false) => (Supervisor, V0),
      (true, true)  => (Supervisor, V1),
  };

  /* Check if delegation privilege exists:
   *
   * delegation to M-mode is unconditionally possible
   * delegation to HS-mode is only possible if supervisor mode is implemented
   * delegation to VS-mode is only possible if hypervisor extension is present (its presence implies supervisor mode implemented)
   */
  let (del_p, del_v): (Privilege, Virtualization) = match (del_p, del_v) {
    (Machine, _)     => (Machine, V0),
    (Supervisor, V0) => if extensionEnabled(Ext_S) then (Supervisor, V0)
                        else (Machine, V0),
    (Supervisor, V1) => if extensionEnabled(Ext_H) then (Supervisor, V1)
                        else if extensionEnabled(Ext_S) then (Supervisor, V0)
                        else (Machine, V0),
    (User, _)        => internal_error(__FILE__, __LINE__, "Unreachable: illegal delegation privilege")
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

/* Interrupts are prioritized in privilege order, and for each
 * privilege, in the order: external, software, timers.
 */
function findPendingInterrupt(ip : xlenbits) -> option(InterruptType) = {
  let ip = Mk_Minterrupts(ip);
  if      ip[MEI]  == 0b1 then Some(I_M_External)
  else if ip[MSI]  == 0b1 then Some(I_M_Software)
  else if ip[MTI]  == 0b1 then Some(I_M_Timer)
  else if ip[SEI]  == 0b1 then Some(I_S_External)
  else if ip[SSI]  == 0b1 then Some(I_S_Software)
  else if ip[STI]  == 0b1 then Some(I_S_Timer)
  else if ip[SGEI] == 0b1 then Some(I_G_External)
  else if ip[VSEI] == 0b1 then Some(I_VS_External)
  else if ip[VSSI] == 0b1 then Some(I_VS_Software)
  else if ip[VSTI] == 0b1 then Some(I_VS_Timer)
  else if ip[UEI]  == 0b1 then Some(I_U_External)
  else if ip[USI]  == 0b1 then Some(I_U_Software)
  else if ip[UTI]  == 0b1 then Some(I_U_Timer)
  else                        None()
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

/* Process the pending interrupts xip at a privilege according to
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
  let  effective_pend = xip.bits & xie.bits & ~(xideleg);
  /* the others are delegated */
  let  effective_delg = xip.bits & xideleg;
  /* we have pending interrupts if this privilege is enabled */
  if      priv_enabled & (effective_pend != zeros())
  then    Ints_Pending(effective_pend)
  else if effective_delg != zeros()
  then    Ints_Delegated(effective_delg)
  else    Ints_Empty()
}

/* Given the current privilege level, iterate over privileges to get a
 * pending set for an enabled privilege.
 *
 * We don't use the lowered views of {xie,xip} here, since the spec
 * allows for example the M_Timer to be delegated to the S-mode.
 */
function getPendingSet(priv : Privilege, virt : Virtualization) -> option((xlenbits, Privilege, Virtualization)) = {
  let effective_pending = mip.bits & mie.bits;
  if  effective_pending == zeros() then None() /* fast path */
  else {
    /* Higher privileges than the current one are implicitly enabled,
     * while lower privileges are blocked.  An unsupported privilege is
     * considered blocked.
     */
    let mIE = priv != Machine | (priv == Machine & mstatus[MIE] == 0b1);
    let sIE = extensionEnabled(Ext_S) & (priv == User | (priv == Supervisor & mstatus[SIE] == 0b1));
    let vsIE = extensionEnabled(Ext_H) & virt == V1 & (priv == User | (priv == Supervisor & vsstatus[SIE] == 0b1)); // Enabled H-ext implies presence of S-mode

    match processPending(mip, mie, mideleg.bits, mIE) {
      Ints_Empty()      => None(),
      Ints_Pending(p)   => Some((p, Machine, V0)),
      Ints_Delegated(d) => match processPending(Mk_Minterrupts(d), mie, hideleg.bits, sIE) {
        Ints_Empty()      => None(),
        Ints_Pending(p)   => Some((p, Supervisor, V0)),
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
function dispatchInterrupt(priv : Privilege, virt : Virtualization) -> option((InterruptType, Privilege, Virtualization)) = {
  match getPendingSet(priv, virt) {
    None()       => None(),
    Some(ip, p, v)  => match findPendingInterrupt(ip) {
                      None()  => None(),
                      Some(i) => Some((i, p, v)),
                    }
  }
}

/* types of privilege transitions */

union ctl_result = {
  CTL_TRAP : (ExceptionType, ExceptionContext),
  CTL_SRET : unit,
  CTL_MRET : unit,
}

/* trap value */

function tval(excinfo : option(xlenbits)) -> xlenbits = {
  match (excinfo) {
    Some(e) => e,
    None()  => zeros()
  }
}

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
  then print_platform("handling " ^ (if trapCause_is_interrupt(cause) then "int#" else "exc#")
                      ^ BitStr(trapCause_to_bits(cause)) ^ " at priv " ^ to_str(del_priv, del_virt)
                      ^ " with tval " ^ BitStr(some_or_zero(context.excinfo))
                      ^ " and tinst " ^ BitStr(some_or_zero(context.excinst)));

  match (del_priv) {
    Machine => {
       mcause[IsInterrupt] = bool_to_bits(trapCause_is_interrupt(cause));
       mcause[Cause]       = zero_extend(trapCause_to_bits(cause));

       mstatus[MPIE] = mstatus[MIE];
       mstatus[MIE]  = 0b0;
       mstatus[MPP]  = privLevel_to_bits(cur_privilege);
       mstatus[MPV]  = virtMode_to_bits(cur_virtualization);
       mstatus[GVA]  = if context.info_is_gva then 0b1 else 0b0;
       mepc            = pc;
       mtval           = some_or_zero(context.excinfo);
       mtval2          = some_or_zero(context.excinfo2);
       mtinst          = some_or_zero(context.excinst);

       cur_privilege      = del_priv;
       cur_virtualization = del_virt;

       handle_trap_extension(del_priv, del_virt, pc, context.ext);

       if   get_config_print_reg()
       then print_reg("CSR mstatus <- " ^ BitStr(mstatus.bits));

       prepare_trap_vector(del_priv, del_virt, mcause)
    },
    Supervisor => match (del_virt) {
      V0 => {
        assert (extensionEnabled(Ext_S), "no supervisor mode present for delegation");

        scause[IsInterrupt] = bool_to_bits(trapCause_is_interrupt(cause));
        scause[Cause]       = zero_extend(trapCause_to_bits(cause));

        mstatus[SPIE] = mstatus[SIE];
        mstatus[SIE]  = 0b0;
        mstatus[SPP]  = match cur_privilege {
                            User => 0b0,
                            Supervisor => 0b1,
                            Machine => internal_error(__FILE__, __LINE__, "invalid privilege for s-mode trap")
                          };
        hstatus[SPV]  = virtMode_to_bits(cur_virtualization);
        hstatus[GVA]  = bool_to_bits(context.info_is_gva);
        if cur_virtualization == V1 then hstatus[SPVP] = mstatus[SPP];
        sepc            = pc;
        stval           = some_or_zero(context.excinfo);
        htval           = some_or_zero(context.excinfo2);
        htinst          = some_or_zero(context.excinst);

        cur_privilege      = del_priv;
        cur_virtualization = del_virt;

        handle_trap_extension(del_priv, del_virt, pc, context.ext);

        if   get_config_print_reg()
        then print_reg("CSR mstatus <- " ^ BitStr(mstatus.bits));

        prepare_trap_vector(del_priv, del_virt, scause)
      },
      V1 => {
        assert (extensionEnabled(Ext_S) & extensionEnabled(Ext_H), "no virtual supervisor mode present for delegation");

        vscause[IsInterrupt] = bool_to_bits(trapCause_is_interrupt(cause));
        vscause[Cause]       = zero_extend(trapCause_to_bits(cause));

        vsstatus[SPIE] = mstatus[SIE];
        vsstatus[SIE]  = 0b0;
        vsstatus[SPP]  = match cur_privilege {
                             User => 0b0,
                             Supervisor => 0b1,
                             Machine => internal_error(__FILE__, __LINE__, "invalid privilege for vs-mode trap")
                           };
        vsepc  = pc;
        vstval = some_or_zero(context.excinfo);

        cur_privilege      = del_priv;
        cur_virtualization = del_virt;

        handle_trap_extension(del_priv, del_virt, pc, context.ext);

        if   get_config_print_reg()
        then print_reg("CSR vsstatus <- " ^ BitStr(vsstatus.bits));

        prepare_trap_vector(del_priv, del_virt, vscause)
      }
    },
    User => internal_error(__FILE__, __LINE__, "Invalid privilege level"),
  };
}

function exception_handler(cur_priv : Privilege,
                           cur_virt: Virtualization,
                           ctl : ctl_result,
                           pc: xlenbits) -> xlenbits = {
  match (cur_priv, cur_virt, ctl) {
    (_, _, CTL_TRAP(e, c)) => {
      let (del_priv, del_virt) = exception_delegatee(e, cur_priv, cur_virt);
      if   get_config_print_platform()
      then print_platform("trapping from " ^ to_str(cur_priv, cur_virt) ^ " to " ^ to_str(del_priv, del_virt)
                          ^ " to handle " ^ to_str(e));
      trap_handler(del_priv, del_virt, pc, E(e), c)
    },
    (_, _, CTL_MRET())  => {
      let prev_priv   = cur_privilege;
      let prev_virt   = cur_virtualization;

      mstatus[MIE]  = mstatus[MPIE];
      mstatus[MPIE] = 0b1;

      cur_privilege   = privLevel_of_bits(mstatus[MPP]);
      mstatus[MPP]  = privLevel_to_bits(if extensionEnabled(Ext_U) then User else Machine);
      if   cur_privilege != Machine
      then mstatus[MPRV] = 0b0;

      cur_virtualization = virtMode_of_bits(mstatus[MPV]);
      mstatus[MPV]       = virtMode_to_bits(V0);

      if   get_config_print_reg()
      then print_reg("CSR mstatus <- " ^ BitStr(mstatus.bits));
      if   get_config_print_platform()
      then print_platform("ret-ing from " ^ to_str(prev_priv, prev_virt) ^ " to " ^ to_str(cur_privilege, cur_virtualization));

      prepare_xret_target(Machine, prev_virt) & pc_alignment_mask()
    },
    (_, V0, CTL_SRET())  => {
      let prev_priv   = cur_privilege;
      let prev_virt   = cur_virtualization;

      mstatus[SIE]  = mstatus[SPIE];
      mstatus[SPIE] = 0b1;

      cur_privilege   = if mstatus[SPP] == 0b1 then Supervisor else User;
      mstatus[SPP]    = 0b0;

      cur_virtualization = virtMode_of_bits(hstatus[SPV]);
      hstatus[SPV]       = virtMode_to_bits(V0);

      if get_config_print_reg() then {
        print_reg("CSR mstatus <- " ^ BitStr(mstatus.bits));
        print_reg("CSR hstatus <- " ^ BitStr(hstatus.bits));
      };
      if   get_config_print_platform()
      then print_platform("ret-ing from " ^ to_str(prev_priv, prev_virt)
                          ^ " to " ^ to_str(cur_privilege, cur_virtualization));

      prepare_xret_target(Supervisor, prev_virt) & pc_alignment_mask()
    },
    (_, V1, CTL_SRET())  => {
      let prev_priv   = cur_privilege;
      let prev_virt   = cur_virtualization;

      vsstatus[SIE]  = vsstatus[SPIE];
      vsstatus[SPIE] = 0b1;

      cur_privilege    = if vsstatus[SPP] == 0b1 then Supervisor else User;
      vsstatus[SPP]    = 0b0;

      cur_virtualization = V1;

      if get_config_print_reg() then {
        print_reg("CSR mstatus <- " ^ BitStr(mstatus.bits));
        print_reg("CSR hstatus <- " ^ BitStr(hstatus.bits));
      };
      if   get_config_print_platform()
      then print_platform("ret-ing from " ^ to_str(prev_priv, prev_virt)
                          ^ " to " ^ to_str(cur_privilege, cur_virtualization));

      prepare_xret_target(Supervisor, prev_virt) & pc_alignment_mask()
    },
  }
}

function handle_exception(e: ExceptionType, c: ExceptionContext) -> unit = {
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
        }, "exception not supported by current handler: " ^ to_str(e));
  handle_exception(e, mem_exception_context(addr, cur_virtualization == V1))
}

function handle_interrupt(i : InterruptType, del_priv : Privilege, del_virt: Virtualization) -> unit =
  set_next_pc(trap_handler(del_priv, del_virt, PC, I(i), empty_exception_context()))

/* state state initialization */

function init_sys() -> unit = {
  cur_privilege = Machine;

  mhartid     = zeros();
  mconfigptr  = zeros();

  misa[MXL] = arch_to_bits(if xlen == 32 then RV32 else RV64);
  misa[A]   = 0b1;                             /* atomics */
  misa[C]   = bool_to_bits(sys_enable_rvc());  /* RVC */
  misa[B]   = bool_to_bits(sys_enable_bext()); /* Bit-manipulation */
  misa[I]   = 0b1;                             /* base integer ISA */
  misa[M]   = 0b1;                             /* integer multiply/divide */
  misa[U]   = 0b1;                             /* user-mode */
  misa[S]   = 0b1;                             /* supervisor-mode */
  misa[V]   = bool_to_bits(sys_enable_vext()); /* vector extension */
  misa[H]   = bool_to_bits(sys_enable_hext()); /* hypervisor extension */

  if   sys_enable_fdext() & sys_enable_zfinx()
  then internal_error(__FILE__, __LINE__, "F and Zfinx cannot both be enabled!");

  if   sys_enable_next() & sys_enable_hext()
  then internal_error(__FILE__, __LINE__, "The hypervisor extension currently does not consider the possibility of user-mode interrupts");

  /* We currently support both F and D */
  misa[F]   = bool_to_bits(sys_enable_fdext());      /* single-precision */
  misa[D]   = if   flen >= 64
                then bool_to_bits(sys_enable_fdext())  /* double-precision */
                else 0b0;

  mstatus = set_mstatus_SXL(mstatus, misa[MXL]);
  mstatus = set_mstatus_UXL(mstatus, misa[MXL]);
  mstatus[SD]   = 0b0;
  mstatus[MPP] = privLevel_to_bits(lowest_supported_privLevel());

  /* set to little-endian mode */
  mstatus[MBE] = 0b0;
  mstatus[SBE] = 0b0;

  mip.bits     = zeros();
  mie.bits     = zeros();
  mideleg.bits = zeros();
  medeleg.bits = zeros();
  mtvec.bits   = zeros();
  mcause.bits  = zeros();
  mepc            = zeros();
  mtval           = zeros();
  mscratch        = zeros();

  mcycle          = zeros();
  mtime           = zeros();

  mcounteren.bits = zeros();

  minstret           = zeros();
  minstret_increment = true;

  menvcfg.bits = zeros();
  senvcfg.bits = zeros();
  /* initialize vector csrs */
  vlenb              = to_bits(xlen, 2 ^ (get_vlen_pow() - 3)); /* vlenb holds the constant value VLEN/8 */
  /* VLEN value needs to be manually changed currently.
   * See riscv_vlen.sail for details.
   */
  vstart             = zeros();
  vl                 = zeros();
  vcsr[vxrm]       = 0b00;
  vcsr[vxsat]      = 0b0;
  vtype[vill]      = 0b1;
  vtype[reserved]  = zeros();
  vtype[vma]       = 0b0;
  vtype[vta]       = 0b0;
  vtype[vsew]      = 0b000;
  vtype[vlmul]     = 0b000;

  // PMP's L and A fields are set to 0 on reset.
  init_pmp();

  if extensionEnabled(Ext_H) then init_hext() else cur_virtualization = V0;

  // log compatibility with spike
  if   get_config_print_reg()
  then print_reg("CSR mstatus <- " ^ BitStr(mstatus.bits) ^ " (input: " ^ BitStr(zeros() : xlenbits) ^ ")")
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
