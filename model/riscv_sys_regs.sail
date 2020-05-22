/* Machine-mode and supervisor-mode state definitions. */

/* privilege level */

register cur_privilege : Privilege

/* current instruction bits, used for illegal instruction exceptions */

register cur_inst : xlenbits

/* State projections
 *
 * Some machine state is processed via projections from machine-mode views to
 * views from lower privilege levels.  So, for e.g. when mstatus is read from
 * lower privilege levels, we use 'lowering_' projections:
 *
 *   mstatus  ->  sstatus  ->  ustatus
 *
 * Similarly, when machine state is written from lower privileges, that state is
 * lifted into the appropriate value for the machine-mode state.
 *
 *   ustatus  ->  sstatus  ->  mstatus
 *
 * In addition, several fields in machine state registers are WARL or WLRL,
 * requiring that values written to the registers be legalized.  For each such
 * register, there will be an associated 'legalize_' function.  These functions
 * will need to be supplied externally, and will depend on the legal values
 * supported by a platform/implementation (or misa).  The legalize_ functions
 * generate a legal value from the current value and the written value.  In more
 * complex cases, they will also implicitly read the current values of misa,
 * mstatus, etc.
 *
 * Each register definition below is followed by custom projections
 * and choice of legalizations if needed.  For now, we typically
 * implement the simplest legalize_ alternatives.
 */


/* M-mode registers */

bitfield Misa : xlenbits = {
  MXL  : xlen - 1 .. xlen - 2,

  Z    : 25,
  Y    : 24,
  X    : 23,
  W    : 22,
  V    : 21,
  U    : 20,
  T    : 19,
  S    : 18,
  R    : 17,
  Q    : 16,
  P    : 15,
  O    : 14,
  N    : 13,
  M    : 12,
  L    : 11,
  K    : 10,
  J    : 9,
  I    : 8,
  H    : 7,
  G    : 6,
  F    : 5,
  E    : 4,
  D    : 3,
  C    : 2,
  B    : 1,
  A    : 0
}
register misa : Misa

/* whether misa is R/W */
val sys_enable_writable_misa = {c: "sys_enable_writable_misa", ocaml: "Platform.enable_writable_misa", _: "sys_enable_writable_misa"} : unit -> bool
/* whether misa.c was enabled at boot */
val sys_enable_rvc = {c: "sys_enable_rvc", ocaml: "Platform.enable_rvc", _: "sys_enable_rvc"} : unit -> bool
/* whether misa.{f,d} were enabled at boot */
val sys_enable_fdext = {c: "sys_enable_fdext", ocaml: "Platform.enable_fdext", _: "sys_enable_fdext"} : unit -> bool

/* This function allows an extension to veto a write to Misa
   if it would violate an alignment restriction on
   unsetting C. If it returns true the write will have no effect. */
val ext_veto_disable_C : unit -> bool effect {rreg}

/* We currently only support dynamic changes for the C extension. */
function legalize_misa(m : Misa, v : xlenbits) -> Misa = {
  if   sys_enable_writable_misa ()
  then { /* Handle modifications to C. */
         let  v = Mk_Misa(v);
         /* Suppress changing C if nextPC would become misaligned or an extension vetoes or C was disabled at boot (i.e. not supported). */
         let m =
           if   (v.C() == 0b0 & (nextPC[1] == bitone | ext_veto_disable_C())) | ~(sys_enable_rvc())
           then m
           else update_C(m, v.C());
         /* Handle updates for F/D. */
         if   ~(sys_enable_fdext()) | (v.D() == 0b1 & v.F() == 0b0)
         then m
         else update_D(update_F(m, v.F()), v.D())
       }
  else m
}

/* helpers to check support for various extensions. */
/* we currently don't model 'E', so always assume 'I'. */
function haveAtomics() -> bool = misa.A() == 0b1
function haveRVC()     -> bool = misa.C() == 0b1
function haveMulDiv()  -> bool = misa.M() == 0b1
function haveSupMode() -> bool = misa.S() == 0b1
function haveUsrMode() -> bool = misa.U() == 0b1
function haveNExt()    -> bool = misa.N() == 0b1
/* see below for F and D extension tests */

bitfield Mstatus : xlenbits = {
  SD   : xlen - 1,

  // The SXL and UXL fields don't exist on RV32, so they are modelled
  // via explicit getters and setters; see below.
  // SXL  : 35 .. 34,
  // UXL  : 33 .. 32,

  TSR  : 22,
  TW   : 21,
  TVM  : 20,
  MXR  : 19,
  SUM  : 18,
  MPRV : 17,

  XS   : 16 .. 15,
  FS   : 14 .. 13,

  MPP  : 12 .. 11,
  SPP  : 8,

  MPIE : 7,
  SPIE : 5,
  UPIE : 4,

  MIE  : 3,
  SIE  : 1,
  UIE  : 0
}
register mstatus : Mstatus

function effectivePrivilege(t : AccessType(ext_access_type), m : Mstatus, priv : Privilege) -> Privilege =
  if   t != Execute() & m.MPRV() == 0b1
  then privLevel_of_bits(mstatus.MPP())
  else cur_privilege

function get_mstatus_SXL(m : Mstatus) -> arch_xlen = {
  if   sizeof(xlen) == 32
  then arch_to_bits(RV32)
  else m.bits()[35 .. 34]
}

function set_mstatus_SXL(m : Mstatus, a : arch_xlen) -> Mstatus = {
  if   sizeof(xlen) == 32
  then m
  else {
    let m = vector_update_subrange(m.bits(), 35, 34,  a);
    Mk_Mstatus(m)
  }
}

function get_mstatus_UXL(m : Mstatus) -> arch_xlen = {
  if   sizeof(xlen) == 32
  then arch_to_bits(RV32)
  else m.bits()[33 .. 32]
}

function set_mstatus_UXL(m : Mstatus, a : arch_xlen) -> Mstatus = {
  if   sizeof(xlen) == 32
  then m
  else {
    let m = vector_update_subrange(m.bits(), 33, 32,  a);
    Mk_Mstatus(m)
  }
}

function legalize_mstatus(o : Mstatus, v : xlenbits) -> Mstatus = {
  let m : Mstatus = Mk_Mstatus(v);

  /* We don't have any extension context yet. */
  let m = update_XS(m, extStatus_to_bits(Off));
  /* FS is WARL, and making FS writable can support the M-mode emulation of an FPU
   * to support code running in S/U-modes.  Spike does this, and for now, we match it.
   * FIXME: This should be made a platform parameter.
   */

  let dirty = extStatus_of_bits(m.FS()) == Dirty | extStatus_of_bits(m.XS()) == Dirty;
  let m = update_SD(m, bool_to_bits(dirty));

  /* We don't support dynamic changes to SXL and UXL. */
  let m = set_mstatus_SXL(m, get_mstatus_SXL(o));
  let m = set_mstatus_UXL(m, get_mstatus_UXL(o));

  /* Hardwired to zero in the absence of 'U' or 'N'. */
  let m = if (~ (haveNExt())) then {
             let m = update_UPIE(m, 0b0);
             let m = update_UIE(m, 0b0);
             m
          } else m;

  if (~ (haveUsrMode())) then {
    let m = update_MPRV(m, 0b0);
    m
  } else m
}

/* architecture and extension checks */

function cur_Architecture() -> Architecture = {
  let a : arch_xlen =
    match (cur_privilege) {
      Machine    => misa.MXL(),
      Supervisor => get_mstatus_SXL(mstatus),
      User       => get_mstatus_UXL(mstatus)
    };
  match architecture(a) {
    Some(a) => a,
    None()  => internal_error("Invalid current architecture")
  }
}

function in32BitMode() -> bool = {
  cur_Architecture() == RV32
}

/* F and D extensions have to enabled both via misa.{FD} as well as mstatus.FS */
function haveFExt()    -> bool = (misa.F() == 0b1) & (mstatus.FS() != 0b00)
function haveDExt()    -> bool = (misa.D() == 0b1) & (mstatus.FS() != 0b00)

/* interrupt processing state */

bitfield Minterrupts : xlenbits = {
  MEI : 11, /* external interrupts */
  SEI : 9,
  UEI : 8,

  MTI : 7,  /* timers interrupts */
  STI : 5,
  UTI : 4,

  MSI : 3,  /* software interrupts */
  SSI : 1,
  USI : 0,
}
register mip     : Minterrupts /* Pending */
register mie     : Minterrupts /* Enabled */
register mideleg : Minterrupts /* Delegation to S-mode */

function legalize_mip(o : Minterrupts, v : xlenbits) -> Minterrupts = {
  /* The only writable bits are the S-mode bits, and with the 'N'
   * extension, the U-mode bits. */
  let v = Mk_Minterrupts(v);
  let m = update_SEI(o, v.SEI());
  let m = update_STI(m, v.STI());
  let m = update_SSI(m, v.SSI());
  if haveUsrMode() & haveNExt() then {
    let m = update_UEI(m, v.UEI());
    let m = update_UTI(m, v.UTI());
    let m = update_USI(m, v.USI());
    m
  } else m
}

function legalize_mie(o : Minterrupts, v : xlenbits) -> Minterrupts = {
  let v = Mk_Minterrupts(v);
  let m = update_MEI(o, v.MEI());
  let m = update_MTI(m, v.MTI());
  let m = update_MSI(m, v.MSI());
  let m = update_SEI(m, v.SEI());
  let m = update_STI(m, v.STI());
  let m = update_SSI(m, v.SSI());
  /* The U-mode bits will be modified if we have the 'N' extension. */
  if haveUsrMode() & haveNExt() then {
    let m = update_UEI(m, v.UEI());
    let m = update_UTI(m, v.UTI());
    let m = update_USI(m, v.USI());
    m
  } else m
}

function legalize_mideleg(o : Minterrupts, v : xlenbits) -> Minterrupts = {
  /* M-mode interrupt delegation bits "should" be hardwired to 0. */
  /* FIXME: needs verification against eventual spec language. */
  let m = Mk_Minterrupts(v);
  let m = update_MEI(m, 0b0);
  let m = update_MTI(m, 0b0);
  let m = update_MSI(m, 0b0);
  m
}

/* exception processing state */

bitfield Medeleg : xlenbits = {
  SAMO_Page_Fault   : 15,
  Load_Page_Fault   : 13,
  Fetch_Page_Fault  : 12,
  MEnvCall          : 10,
  SEnvCall          : 9,
  UEnvCall          : 8,
  SAMO_Access_Fault : 7,
  SAMO_Addr_Align   : 6,
  Load_Access_Fault : 5,
  Load_Addr_Align   : 4,
  Breakpoint        : 3,
  Illegal_Instr     : 2,
  Fetch_Access_Fault: 1,
  Fetch_Addr_Align  : 0
}
register medeleg : Medeleg  /* Delegation to S-mode */

function legalize_medeleg(o : Medeleg, v : xlenbits) -> Medeleg = {
  let m = Mk_Medeleg(v);
  /* M-EnvCalls delegation is not supported */
  let m = update_MEnvCall(m, 0b0);
  m
}

/* registers for trap handling */

bitfield Mtvec : xlenbits = {
  Base : xlen - 1 .. 2,
  Mode : 1 .. 0
}
register mtvec : Mtvec  /* Trap Vector */

function legalize_tvec(o : Mtvec, v : xlenbits) -> Mtvec = {
 let v = Mk_Mtvec(v);
 match (trapVectorMode_of_bits(v.Mode())) {
   TV_Direct => v,
   TV_Vector => v,
   _         => update_Mode(v, o.Mode())
 }
}

bitfield Mcause : xlenbits = {
  IsInterrupt : xlen - 1,
  Cause       : xlen - 2 .. 0
}
register mcause : Mcause

/* Interpreting the trap-vector address */
function tvec_addr(m : Mtvec, c : Mcause) -> option(xlenbits) = {
  let base : xlenbits = m.Base() @ 0b00;
  match (trapVectorMode_of_bits(m.Mode())) {
    TV_Direct => Some(base),
    TV_Vector => if   c.IsInterrupt() == 0b1
                 then Some(base + (EXTZ(c.Cause()) << 2))
                 else Some(base),
    TV_Reserved => None()
  }
}

/* Exception PC */

register mepc : xlenbits

/* The xepc legalization zeroes xepc[1:0] when misa.C is hardwired to 0.
 * When misa.C is writable, it zeroes only xepc[0].
 */
function legalize_xepc(v : xlenbits) -> xlenbits =
  /* allow writing xepc[1] only if misa.C is enabled or could be enabled 
     XXX specification says this legalization should be done on read */
  if   (sys_enable_writable_misa() & sys_enable_rvc()) | misa.C() == 0b1
  then [v with 0 = bitzero]
  else v & EXTS(0b100)

/* masking for reads to xepc */
function pc_alignment_mask() -> xlenbits =
  ~(EXTZ(if misa.C() == 0b1 then 0b00 else 0b10))

/* auxiliary exception registers */

register mtval    : xlenbits
register mscratch : xlenbits

/* counters */

bitfield Counteren : bits(32) = {
  HPM  : 31 .. 3,
  IR   : 2,
  TM   : 1,
  CY   : 0
}

register mcounteren : Counteren
register scounteren : Counteren

function legalize_mcounteren(c : Counteren, v : xlenbits) -> Counteren = {
  /* no HPM counters yet */
  let c = update_IR(c, [v[2]]);
  let c = update_TM(c, [v[1]]);
  let c = update_CY(c, [v[0]]);
  c
}

function legalize_scounteren(c : Counteren, v : xlenbits) -> Counteren = {
  /* no HPM counters yet */
  let c = update_IR(c, [v[2]]);
  let c = update_TM(c, [v[1]]);
  let c = update_CY(c, [v[0]]);
  c
}

bitfield Counterin : bits(32) = {
  /* no HPM counters yet */
  IR : 2,
  CY : 0
}
register mcountinhibit : Counterin

function legalize_mcountinhibit(c : Counterin, v : xlenbits) -> Counterin = {
  let c = update_IR(c, [v[2]]);
  let c = update_CY(c, [v[0]]);
  c
}

register mcycle : bits(64)
register mtime : bits(64)

/* minstret
 *
 * minstret is an architectural register, and can be written to.  The
 * spec says that minstret increments on instruction retires need to
 * occur before any explicit writes to instret.  However, in our
 * simulation loop, we need to execute an instruction to find out
 * whether it retired, and hence can only increment instret after
 * execution.  To avoid doing this in the case minstret was explicitly
 * written to, we track writes to it in a separate model-internal
 * register.
 */
register minstret : bits(64)
register minstret_written : bool

function retire_instruction() -> unit = {
  if   minstret_written == true
  then minstret_written = false
  else minstret = minstret + 1
}

/* informational registers */
register mvendorid : bits(32)
register mimpid : xlenbits
register marchid : xlenbits
/* TODO: this should be readonly, and always 0 for now */
register mhartid : xlenbits

/* S-mode registers */

/* sstatus reveals a subset of mstatus */
bitfield Sstatus : xlenbits = {
  SD   : xlen - 1,
  // The UXL field does not exist on RV32, so we define an explicit
  // getter and setter below.
  // UXL  : 30 .. 29,
  MXR  : 19,
  SUM  : 18,
  XS   : 16 .. 15,
  FS   : 14 .. 13,
  SPP  : 8,
  SPIE : 5,
  UPIE : 4,
  SIE  : 1,
  UIE  : 0
}
/* sstatus is a view of mstatus, so there is no register defined. */

function get_sstatus_UXL(s : Sstatus) -> arch_xlen = {
  let m = Mk_Mstatus(s.bits());
  get_mstatus_UXL(m)
}

function set_sstatus_UXL(s : Sstatus, a : arch_xlen) -> Sstatus = {
  let m = Mk_Mstatus(s.bits());
  let m = set_mstatus_UXL(m, a);
  Mk_Sstatus(m.bits())
}

function lower_mstatus(m : Mstatus) -> Sstatus = {
  let s = Mk_Sstatus(EXTZ(0b0));
  let s = update_SD(s, m.SD());
  let s = set_sstatus_UXL(s, get_mstatus_UXL(m));
  let s = update_MXR(s, m.MXR());
  let s = update_SUM(s, m.SUM());
  let s = update_XS(s, m.XS());
  let s = update_FS(s, m.FS());
  let s = update_SPP(s, m.SPP());
  let s = update_SPIE(s, m.SPIE());
  let s = update_UPIE(s, m.UPIE());
  let s = update_SIE(s, m.SIE());
  let s = update_UIE(s, m.UIE());
  s
}

function lift_sstatus(m : Mstatus, s : Sstatus) -> Mstatus = {
  let m = update_MXR(m, s.MXR());
  let m = update_SUM(m, s.SUM());

  let m = update_XS(m, s.XS());
  // See comment for mstatus.FS.
  let m = update_FS(m, s.FS());
  let dirty = extStatus_of_bits(m.FS()) == Dirty | extStatus_of_bits(m.XS()) == Dirty;
  let m = update_SD(m, bool_to_bits(dirty));

  let m = update_SPP(m, s.SPP());
  let m = update_SPIE(m, s.SPIE());
  let m = update_UPIE(m, s.UPIE());
  let m = update_SIE(m, s.SIE());
  let m = update_UIE(m, s.UIE());
  m
}

function legalize_sstatus(m : Mstatus, v : xlenbits) -> Mstatus = {
  lift_sstatus(m, Mk_Sstatus(v))
}

bitfield Sedeleg : xlenbits = {
  UEnvCall          : 8,
  SAMO_Access_Fault : 7,
  SAMO_Addr_Align   : 6,
  Load_Access_Fault : 5,
  Load_Addr_Align   : 4,
  Breakpoint        : 3,
  Illegal_Instr     : 2,
  Fetch_Access_Fault: 1,
  Fetch_Addr_Align  : 0
}
register sedeleg : Sedeleg

function legalize_sedeleg(s : Sedeleg, v : xlenbits) -> Sedeleg = {
  Mk_Sedeleg(EXTZ(v[8..0]))
}

bitfield Sinterrupts : xlenbits = {
  SEI : 9,  /* external interrupts */
  UEI : 8,

  STI : 5,  /* timers interrupts */
  UTI : 4,

  SSI : 1,  /* software interrupts */
  USI : 0
}

/* Provides the sip read view of mip (m) as delegated by mideleg (d). */
function lower_mip(m : Minterrupts, d : Minterrupts) -> Sinterrupts = {
  let s : Sinterrupts = Mk_Sinterrupts(EXTZ(0b0));
  let s = update_SEI(s, m.SEI() & d.SEI());
  let s = update_STI(s, m.STI() & d.STI());
  let s = update_SSI(s, m.SSI() & d.SSI());

  let s = update_UEI(s, m.UEI() & d.UEI());
  let s = update_UTI(s, m.UTI() & d.UTI());
  let s = update_USI(s, m.USI() & d.USI());
  s
}

/* Provides the sie read view of mie (m) as delegated by mideleg (d). */
function lower_mie(m : Minterrupts, d : Minterrupts) -> Sinterrupts = {
  let s : Sinterrupts = Mk_Sinterrupts(EXTZ(0b0));
  let s = update_SEI(s, m.SEI() & d.SEI());
  let s = update_STI(s, m.STI() & d.STI());
  let s = update_SSI(s, m.SSI() & d.SSI());
  let s = update_UEI(s, m.UEI() & d.UEI());
  let s = update_UTI(s, m.UTI() & d.UTI());
  let s = update_USI(s, m.USI() & d.USI());
  s
}

/* Returns the new value of mip from the previous mip (o) and the written sip (s) as delegated by mideleg (d). */
function lift_sip(o : Minterrupts, d : Minterrupts, s : Sinterrupts) -> Minterrupts = {
  let m : Minterrupts = o;
  let m = update_SSI(m, s.SSI() & d.SSI());
  if haveNExt() then {
    let m = if d.UEI() == 0b1 then update_UEI(m, s.UEI()) else m;
    let m = if d.USI() == 0b1 then update_USI(m, s.USI()) else m;
    m
  } else m
}

function legalize_sip(m : Minterrupts, d : Minterrupts, v : xlenbits) -> Minterrupts = {
  lift_sip(m, d, Mk_Sinterrupts(v))
}

/* Returns the new value of mie from the previous mie (o) and the written sie (s) as delegated by mideleg (d). */
function lift_sie(o : Minterrupts, d : Minterrupts, s : Sinterrupts) -> Minterrupts = {
  let m : Minterrupts = o;
  let m = if d.SEI() == 0b1 then update_SEI(m, s.SEI()) else m;
  let m = if d.STI() == 0b1 then update_STI(m, s.STI()) else m;
  let m = if d.SSI() == 0b1 then update_SSI(m, s.SSI()) else m;
  if haveNExt() then {
    let m = if d.UEI() == 0b1 then update_UEI(m, s.UEI()) else m;
    let m = if d.UTI() == 0b1 then update_UTI(m, s.UTI()) else m;
    let m = if d.USI() == 0b1 then update_USI(m, s.USI()) else m;
    m
  } else m
}

function legalize_sie(m : Minterrupts, d : Minterrupts, v : xlenbits) -> Minterrupts = {
  lift_sie(m, d, Mk_Sinterrupts(v))
}

register sideleg : Sinterrupts

/* other non-VM related supervisor state */
register stvec    : Mtvec
register sscratch : xlenbits
register sepc     : xlenbits
register scause   : Mcause
register stval    : xlenbits

/*
 * S-mode address translation and protection (satp) layout.
 * The actual satp register is defined in an architecture-specific file.
 */

bitfield Satp64 : bits(64) = {
  Mode : 63 .. 60,
  Asid : 59 .. 44,
  PPN  : 43 .. 0
}

function legalize_satp64(a : Architecture, o : bits(64), v : bits(64)) -> bits(64) = {
  let s = Mk_Satp64(v);
  match satp64Mode_of_bits(a, s.Mode()) {
    None()     => o,
    Some(Sv32) => o,  /* Sv32 is unsupported for now */
    Some(_)    => s.bits()
  }
}

bitfield Satp32 : bits(32) = {
  Mode : 31,
  Asid : 30 .. 22,
  PPN  : 21 .. 0
}

function legalize_satp32(a : Architecture, o : bits(32), v : bits(32)) -> bits(32) = {
  /* all 32-bit satp modes are valid */
  v
}

/* disabled trigger/debug module */
register tselect : xlenbits
