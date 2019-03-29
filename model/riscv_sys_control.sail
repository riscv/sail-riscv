/* Machine-mode and supervisor-mode functionality. */


/* CSR access control */

function csrAccess(csr : csreg) -> csrRW = csr[11..10]
function csrPriv(csr : csreg) -> priv_level = csr[9..8]

function is_CSR_defined (csr : bits(12), p : Privilege) -> bool =
  match (csr) {
    /* machine mode: informational */
    0xf11 => p == Machine, // mvendorid
    0xf12 => p == Machine, // marchdid
    0xf13 => p == Machine, // mimpid
    0xf14 => p == Machine, // mhartid
    /* machine mode: trap setup */
    0x300 => p == Machine, // mstatus
    0x301 => p == Machine, // misa
    0x302 => p == Machine, // medeleg
    0x303 => p == Machine, // mideleg
    0x304 => p == Machine, // mie
    0x305 => p == Machine, // mtvec
    0x306 => p == Machine, // mcounteren
    /* machine mode: trap handling */
    0x340 => p == Machine, // mscratch
    0x341 => p == Machine, // mepc
    0x342 => p == Machine, // mcause
    0x343 => p == Machine, // mtval
    0x344 => p == Machine, // mip

    0x3A0 => p == Machine, // pmpcfg0
    0x3B0 => p == Machine, // pmpaddr0

    /* counters */
    0xB00 => p == Machine, // mcycle
    0xB02 => p == Machine, // minstret

    0xB80 => p == Machine & (sizeof(xlen) == 32), // mcycleh
    0xB82 => p == Machine & (sizeof(xlen) == 32), // minstreth

    /* disabled trigger/debug module */
    0x7a0 => p == Machine,

    /* supervisor mode: trap setup */
    0x100 => haveSupMode() & (p == Machine | p == Supervisor), // sstatus
    0x102 => haveSupMode() & (p == Machine | p == Supervisor), // sedeleg
    0x103 => haveSupMode() & (p == Machine | p == Supervisor), // sideleg
    0x104 => haveSupMode() & (p == Machine | p == Supervisor), // sie
    0x105 => haveSupMode() & (p == Machine | p == Supervisor), // stvec
    0x106 => haveSupMode() & (p == Machine | p == Supervisor), // scounteren

    /* supervisor mode: trap handling */
    0x140 => haveSupMode() & (p == Machine | p == Supervisor), // sscratch
    0x141 => haveSupMode() & (p == Machine | p == Supervisor), // sepc
    0x142 => haveSupMode() & (p == Machine | p == Supervisor), // scause
    0x143 => haveSupMode() & (p == Machine | p == Supervisor), // stval
    0x144 => haveSupMode() & (p == Machine | p == Supervisor), // sip

    /* supervisor mode: address translation */
    0x180 => haveSupMode() & (p == Machine | p == Supervisor), // satp

    /* user mode: counters */
    0xC00 => p == User,    // cycle
    0xC01 => p == User,    // time
    0xC02 => p == User,    // instret

    0xC80 => p == User & (sizeof(xlen) == 32),     // cycleh
    0xC81 => p == User & (sizeof(xlen) == 32),     // timeh
    0xC82 => p == User & (sizeof(xlen) == 32),     // instreth

    /* check extensions */
    _     => is_UExt_CSR_defined(csr, p)   // 'N' extension
  }

val check_CSR_access : (csrRW, priv_level, Privilege, bool) -> bool
function check_CSR_access(csrrw, csrpr, p, isWrite) =
    (~ (isWrite == true & csrrw == 0b11))  /* read/write */
  & (privLevel_to_bits(p) >=_u csrpr)      /* privilege */

function check_TVM_SATP(csr : csreg, p : Privilege) -> bool =
  ~ (csr == 0x180 & p == Supervisor & mstatus.TVM() == true)

function check_Counteren(csr : csreg, p : Privilege) -> bool =
  match(csr, p) {
    (0xC00, Supervisor) => mcounteren.CY() == true,
    (0xC01, Supervisor) => mcounteren.TM() == true,
    (0xC02, Supervisor) => mcounteren.IR() == true,

    (0xC00, User) => mcounteren.CY() == true & ((~ (haveSupMode())) | scounteren.CY() == true),
    (0xC01, User) => mcounteren.TM() == true & ((~ (haveSupMode())) | scounteren.TM() == true),
    (0xC02, User) => mcounteren.IR() == true & ((~ (haveSupMode())) | scounteren.IR() == true),

    (_, _) => /* no HPM counters for now */
              if   0xC03 <=_u csr & csr <=_u 0xC1F
              then false
              else true
  }

function check_CSR(csr : csreg, p : Privilege, isWrite : bool) -> bool =
    is_CSR_defined(csr, p)
  & check_CSR_access(csrAccess(csr), csrPriv(csr), p, isWrite)
  & check_TVM_SATP(csr, p)
  & check_Counteren(csr, p)

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

val speculate_conditional = {ocaml: "Platform.speculate_conditional", c: "speculate_conditional", lem: "speculate_conditional_success"} : unit -> bool effect {exmem}

val load_reservation = {ocaml: "Platform.load_reservation", c: "load_reservation", lem: "load_reservation"} : xlenbits -> unit

val match_reservation = {ocaml: "Platform.match_reservation", lem: "match_reservation", c: "match_reservation"} : xlenbits -> bool

val cancel_reservation = {ocaml: "Platform.cancel_reservation", c: "cancel_reservation", lem: "cancel_reservation"} : unit -> unit

/* Exception delegation: given an exception and the privilege at which
 * it occured, returns the privilege at which it should be handled.
 */
function exception_delegatee(e : ExceptionType, p : Privilege) -> Privilege = {
  let idx   = num_of_ExceptionType(e);
  let super = medeleg.bits()[idx];
  /* if S-mode is absent, medeleg delegates to U-mode if 'N' is supported. */
  let user  = if   haveSupMode()
              then super & haveNExt() & sedeleg.bits()[idx]
              else super & haveNExt();
  let deleg = if      haveUsrMode() & user  then User
              else if haveSupMode() & super then Supervisor
              else                               Machine;
  /* We cannot transition to a less-privileged mode. */
  if   privLevel_to_bits(deleg) <_u privLevel_to_bits(p)
  then p else deleg
}

/* Interrupts are prioritized in privilege order, and for each
 * privilege, in the order: external, software, timers.
 */
function findPendingInterrupt(ip : xlenbits) -> option(InterruptType) = {
  let ip = Mk_Minterrupts(ip);
  if      ip.MEI() == true then Some(I_M_External)
  else if ip.MSI() == true then Some(I_M_Software)
  else if ip.MTI() == true then Some(I_M_Timer)
  else if ip.SEI() == true then Some(I_S_External)
  else if ip.SSI() == true then Some(I_S_Software)
  else if ip.STI() == true then Some(I_S_Timer)
  else if ip.UEI() == true then Some(I_U_External)
  else if ip.USI() == true then Some(I_U_Software)
  else if ip.UTI() == true then Some(I_U_Timer)
  else                          None()
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
  let  effective_pend = xip.bits() & xie.bits() & (~ (xideleg));
  /* the others are delegated */
  let  effective_delg = xip.bits() & xideleg;
  /* we have pending interrupts if this privilege is enabled */
  if      priv_enabled & (effective_pend != EXTZ(0b0))
  then    Ints_Pending(effective_pend)
  else if effective_delg != EXTZ(0b0)
  then    Ints_Delegated(effective_delg)
  else    Ints_Empty()
}

/* Given the current privilege level, iterate over privileges to get a
 * pending set for an enabled privilege. This is only called for M/U or
 * M/S/U systems.
 *
 * We don't use the lowered views of {xie,xip} here, since the spec
 * allows for example the M_Timer to be delegated to the U-mode.
 */
function getPendingSet(priv : Privilege) -> option((xlenbits, Privilege)) = {
  //assert(haveUsrMode());
  let effective_pending = mip.bits() & mie.bits();
  if  effective_pending == EXTZ(0b0) then None() /* fast path */
  else {
    /* Higher privileges than the current one are implicitly enabled,
     * while lower privileges are blocked.  An unsupported privilege is
     * considered blocked.
     */
    let mIE = priv != Machine | (priv == Machine & mstatus.MIE() == true);
    let sIE = haveSupMode() & (priv == User | (priv == Supervisor & mstatus.SIE() == true));
    let uIE = haveNExt() & (priv == User & mstatus.UIE() == true);
    match processPending(mip, mie, mideleg.bits(), mIE) {
      Ints_Empty()      => None(),
      Ints_Pending(p)   => let r = (p, Machine) in Some(r),
      Ints_Delegated(d) =>
        if (~ (haveSupMode())) then {
          if uIE then let r = (d, User) in Some(r)
          else                             None()
        } else {
          /* the delegated bits are pending for S-mode */
          match processPending(Mk_Minterrupts(d), mie, sideleg.bits(), sIE) {
            Ints_Empty()      => None(),
            Ints_Pending(p)   => let r = (p, Supervisor) in Some(r),
            Ints_Delegated(d) => if   uIE
                                 then let r = (d, User) in Some(r)
                                 else None()
          }
        }
    }
  }
}

/* Examine the current interrupt state and return an interrupt to be *
 * handled (if any), and the privilege it should be handled at.
 */
function dispatchInterrupt(priv : Privilege) -> option((InterruptType, Privilege)) = {
  /* If we don't have different privilege levels, we don't need to check delegation.
   * Absence of U-mode implies absence of S-mode.
   */
  if (~ (haveUsrMode())) | ((~ (haveSupMode())) & (~ (haveNExt()))) then {
    //assert(priv == Machine);
    let enabled_pending = mip.bits() & mie.bits();
    match findPendingInterrupt(enabled_pending) {
      Some(i) => let r = (i, Machine) in Some(r),
      None()  => None()
    }
  } else {
    match getPendingSet(priv) {
      None()      => None(),
      Some(ip, p) => match findPendingInterrupt(ip) {
                       None()  => None(),
                       Some(i) => let r = (i, p) in Some(r)
                     }
    }
  }
}

/* privilege transitions due to exceptions and interrupts */

struct sync_exception = {
  trap    : ExceptionType,
  excinfo : option(xlenbits)
}

function tval(excinfo : option(xlenbits)) -> xlenbits = {
  match (excinfo) {
    Some(e) => e,
    None()  => EXTZ(0b0)
  }
}

union ctl_result = {
  CTL_TRAP : sync_exception,
  CTL_SRET : unit,
  CTL_MRET : unit,
  CTL_URET : unit
}

$ifdef RVFI_DII
val rvfi_trap : unit -> unit effect {wreg}
function rvfi_trap () =
  rvfi_exec->rvfi_trap() = 0x01
$else
val rvfi_trap : unit -> unit
function rvfi_trap () = ()
$endif

/* handle exceptional ctl flow by updating nextPC and operating privilege */

function handle_trap(del_priv : Privilege, intr : bool, c : exc_code, pc : xlenbits, info : option(xlenbits))
                    -> xlenbits = {
  rvfi_trap();
  print_platform("handling " ^ (if intr then "int#" else "exc#")
                 ^ BitStr(c) ^ " at priv " ^ del_priv ^ " with tval " ^ BitStr(tval(info)));

  cancel_reservation();

  match (del_priv) {
    Machine => {
       mcause->IsInterrupt() = intr;
       mcause->Cause()       = EXTZ(c);

       mstatus->MPIE() = mstatus.MIE();
       mstatus->MIE()  = false;
       mstatus->MPP()  = privLevel_to_bits(cur_privilege);
       mtval           = tval(info);
       mepc            = pc;

       cur_privilege   = del_priv;

       print_reg("CSR mstatus <- " ^ BitStr(mstatus.bits()));

       match tvec_addr(mtvec, mcause) {
         Some(epc) => epc,
         None()    => internal_error("Invalid mtvec mode")
       }
    },
    Supervisor => {
       //assert (haveSupMode());

       scause->IsInterrupt() = intr;
       scause->Cause()       = EXTZ(c);

       mstatus->SPIE() = mstatus.SIE();
       mstatus->SIE()  = false;
       mstatus->SPP()  = match (cur_privilege) {
                           User => false,
                           Supervisor => true,
                           Machine => internal_error("invalid privilege for s-mode trap")
                         };
       stval           = tval(info);
       sepc            = pc;

       cur_privilege   = del_priv;

       print_reg("CSR mstatus <- " ^ BitStr(mstatus.bits()));

       match tvec_addr(stvec, scause) {
         Some(epc) => epc,
         None()    => internal_error("Invalid stvec mode")
       }

    },
    User => {
       //assert(haveUsrMode());

       ucause->IsInterrupt() = intr;
       ucause->Cause()       = EXTZ(c);

       mstatus->UPIE() = mstatus.UIE();
       mstatus->UIE()  = false;
       utval           = tval(info);
       uepc            = pc;

       cur_privilege   = del_priv;

       print_reg("CSR mstatus <- " ^ BitStr(mstatus.bits()));

       match tvec_addr(utvec, ucause) {
         Some(epc) => epc,
         None()    => internal_error("Invalid utvec mode")
       }
    }
  };
}

function handle_exception(cur_priv : Privilege, ctl : ctl_result,
                          pc: xlenbits) -> xlenbits = {
  match (cur_priv, ctl) {
    (_, CTL_TRAP(e)) => {
      let del_priv = exception_delegatee(e.trap, cur_priv);
      print_platform("trapping from " ^ cur_priv ^ " to " ^ del_priv
                     ^ " to handle " ^ e.trap);
      handle_trap(del_priv, false, e.trap, pc, e.excinfo)
    },
    (_, CTL_MRET())  => {
      let prev_priv   = cur_privilege;
      mstatus->MIE()  = mstatus.MPIE();
      mstatus->MPIE() = true;
      cur_privilege   = privLevel_of_bits(mstatus.MPP());
      mstatus->MPP()  = privLevel_to_bits(if haveUsrMode() then User else Machine);

      print_reg("CSR mstatus <- " ^ BitStr(mstatus.bits()));
      print_platform("ret-ing from " ^ prev_priv ^ " to " ^ cur_privilege);

      cancel_reservation();
      mepc & pc_alignment_mask()
    },
    (_, CTL_SRET())  => {
      let prev_priv   = cur_privilege;
      mstatus->SIE()  = mstatus.SPIE();
      mstatus->SPIE() = true;
      cur_privilege   = if mstatus.SPP() == true then Supervisor else User;
      /* S-mode implies that U-mode is supported (issue #331 on riscv-isa-manual). */
      mstatus->SPP()  = false;

      print_reg("CSR mstatus <- " ^ BitStr(mstatus.bits()));
      print_platform("ret-ing from " ^ prev_priv ^ " to " ^ cur_privilege);

      cancel_reservation();
      sepc & pc_alignment_mask()
    },
    (_, CTL_URET())  => {
      let prev_priv   = cur_privilege;
      mstatus->UIE()  = mstatus.UPIE();
      mstatus->UPIE() = true;
      cur_privilege   = User;

      print_reg("CSR mstatus <- " ^ BitStr(mstatus.bits()));
      print_platform("ret-ing from " ^ prev_priv ^ " to " ^ cur_privilege);

      cancel_reservation();
      uepc & pc_alignment_mask()
    }
  }
}

function handle_mem_exception(addr : xlenbits, e : ExceptionType) -> unit = {
  let t : sync_exception = struct { trap    = e,
                                    excinfo = Some(addr) } in
  nextPC = handle_exception(cur_privilege, CTL_TRAP(t), PC)
}

function handle_interrupt(i : InterruptType, del_priv : Privilege) -> unit =
  nextPC = handle_trap(del_priv, true, i, PC, None())

/* state state initialization */

val sys_enable_rvc = {c: "sys_enable_rvc", ocaml: "Platform.enable_rvc", _: "sys_enable_rvc"} : unit -> bool
function init_sys() -> unit = {
  cur_privilege = Machine;

  mhartid     = EXTZ(0b0);

  misa->MXL() = arch_to_bits(if sizeof(xlen) == 32 then RV32 else RV64);
  misa->A()   = true;               /* atomics */
  misa->C()   = sys_enable_rvc ();  /* RVC */
  misa->I()   = true;               /* base integer ISA */
  misa->M()   = true;               /* integer multiply/divide */
  misa->U()   = true;               /* user-mode */
  misa->S()   = true;               /* supervisor-mode */

  mstatus = set_mstatus_SXL(mstatus, misa.MXL());
  mstatus = set_mstatus_UXL(mstatus, misa.MXL());
  mstatus->SD()   = false;

  mip->bits()     = EXTZ(0b0);
  mie->bits()     = EXTZ(0b0);
  mideleg->bits() = EXTZ(0b0);
  medeleg->bits() = EXTZ(0b0);
  mtvec->bits()   = EXTZ(0b0);
  mcause->bits()  = EXTZ(0b0);
  mepc            = EXTZ(0b0);
  mtval           = EXTZ(0b0);
  mscratch        = EXTZ(0b0);

  mcycle          = EXTZ(0b0);
  mtime           = EXTZ(0b0);

  mcounteren->bits() = EXTZ(0b0);

  minstret           = EXTZ(0b0);
  minstret_written   = false;

  // log compatibility with spike
  print_reg("CSR mstatus <- " ^ BitStr(mstatus.bits()) ^ " (input: " ^ BitStr(EXTZ(0b0) : xlenbits) ^ ")")
}

/* memory access exceptions, defined here for use by the platform model. */

union MemoryOpResult ('a : Type) = {
  MemValue     : 'a,
  MemException : ExceptionType
}
