/*=======================================================================================*/
/*  RISCV Sail Model                                                                     */
/*                                                                                       */
/*  This Sail RISC-V architecture model, comprising all files and                        */
/*  directories except for the snapshots of the Lem and Sail libraries                   */
/*  in the prover_snapshots directory (which include copies of their                     */
/*  licences), is subject to the BSD two-clause licence below.                           */
/*                                                                                       */
/*  Copyright (c) 2017-2021                                                              */
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

bitfield Extension : bits(26) = {
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
val ext_veto_disable_C : unit -> bool effect {rreg}

function set_misa(m : Misa, v : Misa) -> Misa = {
  if   sys_enable_writable_misa ()
  then { /* Handle modifications to C. */
         let  e = Mk_Extension(v.EXTENSIONS());
         /* Suppress changing C if nextPC would become misaligned or an extension vetoes or C was disabled at boot (i.e. not supported). */
         let m =
           if   (e.C() == 0b0 & (nextPC[1] == bitone | ext_veto_disable_C())) | ~(sys_enable_rvc())
           then m
           else {
               r =  Mk_Extension(m.EXTENSIONS());
               r = update_C(r, e.C());
               update_EXTENSIONS(m, r.bits())
           };
         /* Handle updates for F/D. */
         if   ~(sys_enable_fdext()) | (e.D() == 0b1 & e.F() == 0b0)
         then m
         else {
             r =  Mk_Extension(m.EXTENSIONS());
             r = update_D(update_F(r, e.F()), e.D());
             update_EXTENSIONS(m, r.bits())
         }
       }
  else m
}

/* helpers to check support for various extensions. */
/* we currently don't model 'E', so always assume 'I'. */
function haveAtomics() -> bool = misa.EXTENSIONS()[0] == bitone
function haveRVC()     -> bool = misa.EXTENSIONS()[2] == bitone
function haveMulDiv()  -> bool = misa.EXTENSIONS()[12] == bitone
function haveSupMode() -> bool = misa.EXTENSIONS()[18] == bitone
function haveUsrMode() -> bool = misa.EXTENSIONS()[20] == bitone
function haveNExt()    -> bool = misa.EXTENSIONS()[13] == bitone
/* see below for F and D (and Z*inx counterparts) extension tests */

/* Cryptography extension support. Note these will need updating once */
/* Sail can be dynamically configured with different extension support */
/* and have dynamic changes of XLEN via S/UXL */
function haveZkr()    -> bool = true
function haveZksh()   -> bool = true
function haveZksed()  -> bool = true
function haveZknh()   -> bool = true
function haveZkne()   -> bool = true
function haveZknd()   -> bool = true

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

function set_mstatus(o : Mstatus, v : Mstatus) -> Mstatus = {

  /* We don't have any extension context yet. */
  let m = update_XS(v, extStatus_to_bits(Off));

  /* FS is WARL, and making FS writable can support the M-mode emulation of an FPU
   * to support code running in S/U-modes.  Spike does this, and for now, we match it,
   * but only if Zfinx isn't enabled.
   * FIXME: This should be made a platform parameter.
   */
  let m = if sys_enable_zfinx() then update_FS(m, extStatus_to_bits(Off)) else m;
  let dirty = extStatus_of_bits(m.FS()) == Dirty | extStatus_of_bits(m.XS()) == Dirty;
  let m = update_SD(m, bool_to_bits(dirty));
  m
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
function haveFExt()    -> bool = (misa.EXTENSIONS()[5] == bitone) & (mstatus.FS() != 0b00)
function haveDExt()    -> bool = (misa.EXTENSIONS()[3] == bitone) & (mstatus.FS() != 0b00)

/* Zfinx and Zdinx extensions (TODO: gate FCSR access on [mhs]stateen0 bit 1 when implemented) */
function haveZfinx()   -> bool = sys_enable_zfinx()
function haveZdinx()   -> bool = sys_enable_zfinx() & sizeof(flen) >= 64
/* 
 * exception processing state
 * bitfield Mcause_value : xlenbits = {
 * SAMO_Page_Fault   : 15,
 * Load_Page_Fault   : 13,
 * Fetch_Page_Fault  : 12,
 * MEnvCall          : 10,
 * SEnvCall          : 9,
 * UEnvCall          : 8,
 * SAMO_Access_Fault : 7,
 * SAMO_Addr_Align   : 6,
 * Load_Access_Fault : 5,
 * Load_Addr_Align   : 4,
 * Breakpoint        : 3,
 * Illegal_Instr     : 2,
 * Fetch_Access_Fault: 1,
 * Fetch_Addr_Align  : 0
 * }
*/
/* registers for trap handling */

function tvec_addr(tvec : xlenbits, cause : xlenbits) -> option(xlenbits) = {
  let m : Mtvec = Mk_Mtvec(tvec);
  let c : Mcause = Mk_Mcause(cause);
  let base : xlenbits = m.BASE() @ 0b00;
  match (trapVectorMode_of_bits(m.MODE())) {
    TV_Direct => Some(base),
    TV_Vector => if   c.INTERRUPT() == 0b1
                 then Some(base + (EXTZ(c.EXCEPTION_CODE()) << 2))
                 else Some(base),
    TV_Reserved => None()
  }
}

/* The xepc legalization zeroes xepc[1:0] when misa.C is hardwired to 0.
 * When misa.C is writable, it zeroes only xepc[0].
 */
function legalize_xepc(v : xlenbits) -> xlenbits =
  /* allow writing xepc[1] only if misa.C is enabled or could be enabled 
     XXX specification says this legalization should be done on read */
  if   (sys_enable_writable_misa() & sys_enable_rvc()) | misa.EXTENSIONS()[2] == bitone
  then [v with 0 = bitzero]
  else v & EXTS(0b100)

/* masking for reads to xepc */
function pc_alignment_mask() -> xlenbits =
  ~(EXTZ(if misa.EXTENSIONS()[2] == bitone then 0b00 else 0b10))

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
register minstret_written : bool
register mtime : bits(64)
register mcycle : bits(64)
register minstret : bits(64)

function retire_instruction() -> unit = {
  if   minstret_written == true
  then minstret_written = false
  else if mcountinhibit[2] == bitzero
       then minstret = minstret + 1
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
  EXTZ(opst_code(ES16) @ reserved_bits @ custom_bits @ seed)
}

/* Writes to the seed CSR are ignored */
function write_seed_csr () -> option(xlenbits) = None()
