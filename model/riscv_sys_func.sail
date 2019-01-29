/* Machine-mode and supervisor-mode functionality. */

/* CSR names */

val cast csr_name : csreg -> string
function csr_name(csr) = {
  match (csr) {
    /* user trap setup */
    0x000  => "ustatus",
    0x004  => "uie",
    0x005  => "utvec",
    /* user trap handling */
    0x040  => "uscratch",
    0x041  => "uepc",
    0x042  => "ucause",
    0x043  => "utval",
    0x044  => "uip",

    /* user floating-point context */
    0x001  => "fflags",
    0x002  => "frm",
    0x003  => "fcsr",
    /* counter/timers */
    0xC00  => "cycle",
    0xC01  => "time",
    0xC02  => "instret",
    0xC80  => "cycleh",
    0xC81  => "timeh",
    0xC82  => "instreth",
    /* TODO: other hpm counters */
    /* supervisor trap setup */
    0x100  => "sstatus",
    0x102  => "sedeleg",
    0x103  => "sideleg",
    0x104  => "sie",
    0x105  => "stvec",
    0x106  => "scounteren",
    /* supervisor trap handling */
    0x140  => "sscratch",
    0x141  => "sepc",
    0x142  => "scause",
    0x143  => "stval",
    0x144  => "sip",
    /* supervisor protection and translation */
    0x180  => "satp",
    /* machine information registers */
    0xF11  => "mvendorid",
    0xF12  => "marchid",
    0xF13  => "mimpid",
    0xF14  => "mhartid",
    /* machine trap setup */
    0x300  => "mstatus",
    0x301  => "misa",
    0x302  => "medeleg",
    0x303  => "mideleg",
    0x304  => "mie",
    0x305  => "mtvec",
    0x306  => "mcounteren",
    /* machine trap handling */
    0x340  => "mscratch",
    0x341  => "mepc",
    0x342  => "mcause",
    0x343  => "mtval",
    0x344  => "mip",

    0x3A0  => "pmpcfg0",
    0x3B0  => "pmpaddr0",
    /* TODO: machine protection and translation */
    /* machine counters/timers */
    0xB00  => "mcycle",
    0xB02  => "minstret",
    0xB80  => "mcycleh",
    0xB82  => "minstreth",
    /* TODO: other hpm counters and events */
    /* trigger/debug */
    0x7a0  => "tselect",
    _      => "UNKNOWN"
  }
}

mapping csr_name_map : csreg <-> string = {
    /* user trap setup */
    0x000  <-> "ustatus",
    0x004  <-> "uie",
    0x005  <-> "utvec",
    /* user trap handling */
    0x040  <-> "uscratch",
    0x041  <-> "uepc",
    0x042  <-> "ucause",
    0x043  <-> "utval",
    0x044  <-> "uip",
    /* user floating-point context */
    0x001  <-> "fflags",
    0x002  <-> "frm",
    0x003  <-> "fcsr",
    /* counter/timers */
    0xC00  <-> "cycle",
    0xC01  <-> "time",
    0xC02  <-> "instret",
    0xC80  <-> "cycleh",
    0xC81  <-> "timeh",
    0xC82  <-> "instreth",
    /* TODO: other hpm counters */
    /* supervisor trap setup */
    0x100  <-> "sstatus",
    0x102  <-> "sedeleg",
    0x103  <-> "sideleg",
    0x104  <-> "sie",
    0x105  <-> "stvec",
    0x106  <-> "scounteren",
    /* supervisor trap handling */
    0x140  <-> "sscratch",
    0x141  <-> "sepc",
    0x142  <-> "scause",
    0x143  <-> "stval",
    0x144  <-> "sip",
    /* supervisor protection and translation */
    0x180  <-> "satp",
    /* machine information registers */
    0xF11  <-> "mvendorid",
    0xF12  <-> "marchid",
    0xF13  <-> "mimpid",
    0xF14  <-> "mhartid",
    /* machine trap setup */
    0x300  <-> "mstatus",
    0x301  <-> "misa",
    0x302  <-> "medeleg",
    0x303  <-> "mideleg",
    0x304  <-> "mie",
    0x305  <-> "mtvec",
    0x306  <-> "mcounteren",
    /* machine trap handling */
    0x340  <-> "mscratch",
    0x341  <-> "mepc",
    0x342  <-> "mcause",
    0x343  <-> "mtval",
    0x344  <-> "mip",
    /* machine protection and translation */
    0x3A0  <-> "pmpcfg0",
    0x3A1  <-> "pmpcfg1",
    0x3A2  <-> "pmpcfg2",
    0x3A3  <-> "pmpcfg3",
    0x3B0  <-> "pmpaddr0",
    0x3B1  <-> "pmpaddr1",
    0x3B2  <-> "pmpaddr2",
    0x3B3  <-> "pmpaddr3",
    0x3B4  <-> "pmpaddr4",
    0x3B5  <-> "pmpaddr5",
    0x3B6  <-> "pmpaddr6",
    0x3B7  <-> "pmpaddr7",
    0x3B8  <-> "pmpaddr8",
    0x3B9  <-> "pmpaddr9",
    0x3BA  <-> "pmpaddr10",
    0x3BB  <-> "pmpaddr11",
    0x3BC  <-> "pmpaddr12",
    0x3BD  <-> "pmpaddr13",
    0x3BE  <-> "pmpaddr14",
    0x3BF  <-> "pmpaddr15",
    /* machine counters/timers */
    0xB00  <-> "mcycle",
    0xB02  <-> "minstret",
    0xB80  <-> "mcycleh",
    0xB82  <-> "minstreth",
    /* TODO: other hpm counters and events */
    /* trigger/debug */
    0x7a0  <-> "tselect",
    0x7a1  <-> "tdata1",
    0x7a2  <-> "tdata2",
    0x7a3  <-> "tdata3"

    /* numeric fallback */
    /* reg    <-> hex_bits_12(reg) */
 }


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
    0x3B0 => false, // (Disabled for Spike compatibility)
//  0x3B0 => p == Machine, // pmpaddr0

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

    /* disabled trigger/debug module */
    0x7a0 => p == Machine,

    /* user-mode: 'N' extension */
    0x000 => haveUsrMode(),                  // ustatus
    0x004 => haveUsrMode(),                  // uie
    0x005 => haveUsrMode(),                  // utvec
    0x040 => haveUsrMode(),                  // uscratch
    0x041 => haveUsrMode(),                  // uepc
    0x042 => haveUsrMode(),                  // ucause
    0x043 => haveUsrMode(),                  // utval
    0x044 => haveUsrMode(),                  // uip

    _     => false
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

    (0xC00, User) => scounteren.CY() == true,
    (0xC01, User) => scounteren.TM() == true,
    (0xC02, User) => scounteren.IR() == true,

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
  let user  = sedeleg.bits()[idx];
  let deleg = /* if      misa.N() == true & user  then User
                 else */
              if misa.S() == true & super then Supervisor
              else Machine;
  /* Ensure there is no transition to a less-privileged mode. */
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
  else None()
}

/* Examines current M-mode interrupt state and returns an interrupt to be
 * handled, and the privilege it should be handled at.  Interrupts are
 * dispatched in order of decreasing privilege, while ensuring that the
 * resulting privilege level is not reduced; i.e. delegated interrupts to
 * lower privileges are effectively masked until control returns to them.
 *
 * For now, it assumes 'S' and no 'N' extension, which is the common case.
 */
function curInterrupt(priv : Privilege, pend : Minterrupts, enbl : Minterrupts, delg : Minterrupts)
                     -> option((InterruptType, Privilege)) = {
  let en_mip : xlenbits = pend.bits() & enbl.bits();
  if en_mip == EXTZ(0b0) then None() /* fast path */
  else {
    /* check implicit enabling when in lower privileges */
    let eff_mie = priv != Machine | (priv == Machine & mstatus.MIE() == true);
    let eff_sie = priv == User | (priv == Supervisor & mstatus.SIE() == true);
    /* handle delegation */
    let eff_mip = en_mip & (~ (delg.bits())); /* retained at M-mode */
    let eff_sip = en_mip & delg.bits();       /* delegated to S-mode */

    if eff_mie & eff_mip != EXTZ(0b0)
    then match findPendingInterrupt(eff_mip) {
           Some(i) => let r = (i, Machine) in Some(r),
           None()  => { internal_error("non-zero eff_mip=" ^ BitStr(eff_mip) ^ ", but nothing pending") }
         }
    else if eff_sie & eff_sip != EXTZ(0b0)
    then match findPendingInterrupt(eff_sip) {
           Some(i) => let r = (i, Supervisor) in Some(r),
           None()  => { internal_error("non-zero eff_sip=" ^ BitStr(eff_sip) ^ ", but nothing pending") }
         }
    else {
      let p = if pend.MTI() == true then "1" else "0";
      let e = if enbl.MTI() == true then "1" else "0";
      let d = if delg.MTI() == true then "1" else "0";
      print_platform(" MTI: pend=" ^ p ^ " enbl=" ^ e ^ " delg=" ^ d);
      let eff_mip = en_mip & (~ (delg.bits())); /* retained at M-mode */
      let eff_sip = en_mip & delg.bits();       /* delegated to S-mode */
      print_platform("mstatus=" ^ BitStr(mstatus.bits())
                     ^ " mie,sie=" ^ BitStr(mstatus.MIE()) ^ "," ^ BitStr(mstatus.SIE())
                     ^ " en_mip=" ^ BitStr(en_mip)
                     ^ " eff_mip=" ^ BitStr(eff_mip)
                     ^ " eff_sip=" ^ BitStr(eff_sip));
      None()
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
  CTL_MRET : unit
/* TODO: CTL_URET */
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

       print_reg("CSR mstatus <- " ^ BitStr(mstatus.bits()) ^ " (input: " ^ BitStr(mstatus.bits()) ^ ")");

       cancel_reservation();

       match tvec_addr(mtvec, mcause) {
         Some(epc) => epc,
         None()    => internal_error("Invalid mtvec mode")
       }
    },
    Supervisor => {
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

       print_reg("CSR mstatus <- " ^ BitStr(mstatus.bits()) ^ " (input: " ^ BitStr(mstatus.bits()) ^ ")");

       cancel_reservation();

       match tvec_addr(stvec, scause) {
         Some(epc) => epc,
         None()    => internal_error("Invalid stvec mode")
       }

    },
    User => internal_error("the N extension is currently unsupported")
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

      print_reg("CSR mstatus <- " ^ BitStr(mstatus.bits()) ^ " (input: " ^ BitStr(mstatus.bits()) ^ ")");
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

      print_reg("CSR mstatus <- " ^ BitStr(mstatus.bits()) ^ " (input: " ^ BitStr(mstatus.bits()) ^ ")");
      print_platform("ret-ing from " ^ prev_priv ^ " to " ^ cur_privilege);

      cancel_reservation();
      sepc & pc_alignment_mask()
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

function init_sys() -> unit = {
  cur_privilege = Machine;

  mhartid     = EXTZ(0b0);

  misa->MXL() = arch_to_bits(RV64);
  misa->A()   = true; /* atomics */
  misa->C()   = true; /* RVC */
  misa->I()   = true; /* base integer ISA */
  misa->M()   = true; /* integer multiply/divide */
  misa->U()   = true; /* user-mode */
  misa->S()   = true; /* supervisor-mode */

  /* 64-bit only mode with no extensions */
  mstatus->SXL()  = misa.MXL();
  mstatus->UXL()  = misa.MXL();
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
