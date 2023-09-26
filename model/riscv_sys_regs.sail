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
/* whether zfinx was enabled at boot */
val sys_enable_zfinx = {c: "sys_enable_zfinx", ocaml: "Platform.enable_zfinx", _: "sys_enable_zfinx"} : unit -> bool
/* whether the N extension was enabled at boot */
val sys_enable_next = {c: "sys_enable_next", ocaml: "Platform.enable_next", _: "sys_enable_next"} : unit -> bool

/* This function allows an extension to veto a write to Misa
   if it would violate an alignment restriction on
   unsetting C. If it returns true the write will have no effect. */
val ext_veto_disable_C : unit -> bool

function legalize_misa(m : Misa, v : xlenbits) -> Misa = {
  let  v = Mk_Misa(v);
  /* Suppress updates to MISA if MISA is not writable or if by disabling C next PC would become misaligned or an extension vetoes */
  if   not(sys_enable_writable_misa()) | (v.C() == 0b0 & (nextPC[1] == bitone | ext_veto_disable_C()))
  then m
  else {
    /* Suppress enabling C if C was disabled at boot (i.e. not supported) */
    let m = if not(sys_enable_rvc()) then m else update_C(m, v.C());
    /* Suppress updates to misa.{f,d} if disabled at boot */
    if   not(sys_enable_fdext())
    then m
    else update_D(update_F(m, v.F()), v.D() & v.F())
  }
}

/* helpers to check support for various extensions. */
/* we currently don't model 'E', so always assume 'I'. */
function haveAtomics() -> bool = misa.A() == 0b1
function haveRVC()     -> bool = misa.C() == 0b1
function haveMulDiv()  -> bool = misa.M() == 0b1
function haveSupMode() -> bool = misa.S() == 0b1
function haveUsrMode() -> bool = misa.U() == 0b1
function haveNExt()    -> bool = misa.N() == 0b1
/* see below for F and D (and Z*inx counterparts) extension tests */

/* BitManip extension support. */
function haveZba()  -> bool = true
function haveZbb()  -> bool = true
function haveZbc()  -> bool = true
function haveZbs()  -> bool = true

/* Zfa (additional FP) extension */
function haveZfa()  -> bool = true

/* Scalar Cryptography extensions support. */
function haveZbkb() -> bool = true
function haveZbkc() -> bool = true
function haveZbkx() -> bool = true

/* Cryptography extension support. Note these will need updating once */
/* Sail can be dynamically configured with different extension support */
/* and have dynamic changes of XLEN via S/UXL */
function haveZkr()    -> bool = true
function haveZksh()   -> bool = true
function haveZksed()  -> bool = true
function haveZknh()   -> bool = true
function haveZkne()   -> bool = true
function haveZknd()   -> bool = true

function haveZmmul()  -> bool = true

/* Zicond extension support */
function haveZicond() -> bool = true

bitfield Mstatush : bits(32) = {
  MBE  : 5,
  SBE  : 4
}
register mstatush : Mstatush

bitfield Mstatus : xlenbits = {
  SD   : xlen - 1,

  // The MBE and SBE fields are in mstatus in RV64 and absent in RV32.
  // On RV32, they are in mstatush, which doesn't exist in RV64.  For now,
  // they are handled in an ad-hoc way.
  // MBE  : 37
  // SBE  : 36

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
  then privLevel_of_bits(m.MPP())
  else priv

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
  /*
   * Populate all defined fields using the bits of v, stripping anything
   * that does not have a matching bitfield entry. All bits above 32 are handled
   * explicitly later.
   */
  let m : Mstatus = Mk_Mstatus(zero_extend(v[22 .. 11] @ 0b00 @ v[8 .. 7] @ 0b0 @ v[5 .. 3] @ 0b0 @ v[1 .. 0]));

  /* We don't have any extension context yet. */
  let m = update_XS(m, extStatus_to_bits(Off));

  /* FS is WARL, and making FS writable can support the M-mode emulation of an FPU
   * to support code running in S/U-modes.  Spike does this, and for now, we match it,
   * but only if Zfinx isn't enabled.
   * FIXME: This should be made a platform parameter.
   */
  let m = if sys_enable_zfinx() then update_FS(m, extStatus_to_bits(Off)) else m;
  let dirty = extStatus_of_bits(m.FS()) == Dirty | extStatus_of_bits(m.XS()) == Dirty;
  let m = update_SD(m, bool_to_bits(dirty));

  /* We don't support dynamic changes to SXL and UXL. */
  let m = set_mstatus_SXL(m, get_mstatus_SXL(o));
  let m = set_mstatus_UXL(m, get_mstatus_UXL(o));

  /* We don't currently support changing MBE and SBE. */
  let m = if sizeof(xlen) == 64 then {
             Mk_Mstatus([m.bits() with 37 .. 36 = 0b00])
          } else m;

  /* Hardwired to zero in the absence of 'U' or 'N'. */
  let m = if not(haveNExt()) then {
             let m = update_UPIE(m, 0b0);
             let m = update_UIE(m, 0b0);
             m
          } else m;

  if not(haveUsrMode()) then {
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
    None()  => internal_error(__FILE__, __LINE__, "Invalid current architecture")
  }
}

function in32BitMode() -> bool = {
  cur_Architecture() == RV32
}

/* F and D extensions have to enabled both via misa.{FD} as well as mstatus.FS */
function haveFExt()    -> bool = (misa.F() == 0b1) & (mstatus.FS() != 0b00)
function haveDExt()    -> bool = (misa.D() == 0b1) & (mstatus.FS() != 0b00)
/* Zfh (half-precision) extension depends on misa.F and mstatus.FS */
function haveZfh()     -> bool = (misa.F() == 0b1) & (mstatus.FS() != 0b00)

/* Zhinx, Zfinx and Zdinx extensions (TODO: gate FCSR access on [mhs]stateen0 bit 1 when implemented) */
function haveZhinx()   -> bool = sys_enable_zfinx()
function haveZfinx()   -> bool = sys_enable_zfinx()
function haveZdinx()   -> bool = sys_enable_zfinx() & sizeof(flen) >= 64

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
                 then Some(base + (zero_extend(c.Cause()) << 2))
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
  else v & sign_extend(0b100)

/* masking for reads to xepc */
function pc_alignment_mask() -> xlenbits =
  ~(zero_extend(if misa.C() == 0b1 then 0b00 else 0b10))

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
 * written to, we track whether it should increment in a separate
 * model-internal register.
 */
register minstret : bits(64)

/* Should minstret be incremented when the instruction is retired. */
register minstret_increment : bool

function retire_instruction() -> unit = {
  if minstret_increment then minstret = minstret + 1;
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
  let s = Mk_Sstatus(zero_extend(0b0));
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
  legalize_mstatus(m, lift_sstatus(m, Mk_Sstatus(v)).bits())
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
  Mk_Sedeleg(zero_extend(v[8..0]))
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
  let s : Sinterrupts = Mk_Sinterrupts(zero_extend(0b0));
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
  let s : Sinterrupts = Mk_Sinterrupts(zero_extend(0b0));
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
  let m = if d.SSI() == 0b1 then update_SSI(m, s.SSI()) else m;
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

/*
 * The seed CSR (entropy source)
 * ------------------------------------------------------------
 */

/* Valid return states for reading the seed CSR. */
enum seed_opst = {
  BIST, // Built-in-self-test. No randomness sampled.
  ES16, // Entropy-sample-16. Valid 16-bits of randomness sampled.
  WAIT, // Device still gathering entropy.
  DEAD  // Fatal device compromise. No randomness sampled.
}

/* Mapping of status codes and their actual encodings. */
mapping opst_code : seed_opst <-> bits(2) = {
  BIST <-> 0b00,
  WAIT <-> 0b01,
  ES16 <-> 0b10,
  DEAD <-> 0b11
}

/*
 * Entropy Source - Platform access to random bits.
 * WARNING: This function currently lacks a proper side-effect annotation.
 *          If you are using theorem prover tool flows, you
 *          may need to modify or stub out this function for now.
 * NOTE: This would be better placed in riscv_platform.sail, but that file
 *       appears _after_ this one in the compile order meaning the valspec
 *       for this function is unavailable when it's first encountered in
 *       read_seed_csr. Hence it appears here.
 */
val get_16_random_bits = {
    ocaml: "Platform.get_16_random_bits",
    interpreter: "Platform.get_16_random_bits",
    c: "plat_get_16_random_bits",
    lem: "plat_get_16_random_bits"
} : unit -> bits(16)

/* Entropy source spec requires an Illegal opcode exception be raised if the
 * seed register is read without also being written. This function is only
 * called once we know the CSR is being written, and all other access control
 * checks have been done.
 */
function read_seed_csr() -> xlenbits = {
  let reserved_bits : bits(6) = 0b000000;
  let custom_bits : bits(8) = 0x00;
  let seed : bits(16) = get_16_random_bits();
  zero_extend(opst_code(ES16) @ reserved_bits @ custom_bits @ seed)
}

/* Writes to the seed CSR are ignored */
function write_seed_csr () -> option(xlenbits) = None()
