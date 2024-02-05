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

/* Basic type and function definitions used pervasively in the model. */

/* this value is only defined for the runtime platform for ELF loading
 * checks, and not used in the model.
 */
let xlen_val = sizeof(xlen)

let xlen_max_unsigned = 2 ^ sizeof(xlen) - 1
let xlen_max_signed = 2 ^ (sizeof(xlen) - 1) - 1
let xlen_min_signed = 0 - 2 ^ (sizeof(xlen) - 1)

type half = bits(16)
type word = bits(32)

/* max instruction length */
type ilenbits = bits(32)

/* register identifiers */

type regidx  = bits(5)
type cregidx = bits(3)    /* identifiers in RVC instructions */
type csreg   = bits(12)   /* CSR addressing */

/* register file indexing */

type regno ('n : Int), 0 <= 'n < 32 = atom('n)

val regidx_to_regno : bits(5) -> {'n, 0 <= 'n < 32. regno('n)}
function regidx_to_regno b = let 'r = unsigned(b) in r

/* mapping RVC register indices into normal indices */
val creg2reg_idx : cregidx -> regidx
function creg2reg_idx(creg) = 0b01 @ creg

/* some architecture and ABI relevant register identifiers */
let zreg : regidx = 0b00000  /* x0, zero register  */
let ra   : regidx = 0b00001  /* x1, return address */
let sp   : regidx = 0b00010  /* x2, stack pointer  */

/* instruction fields */

type opcode = bits(7)
type imm12  = bits(12)
type imm20  = bits(20)
type amo    = bits(1)  /* amo opcode flags */

/* base architecture definitions */

enum Architecture = {RV32, RV64, RV128}
type arch_xlen = bits(2)
function architecture(a : arch_xlen) -> option(Architecture) =
  match (a) {
    0b01 => Some(RV32),
    0b10 => Some(RV64),
    0b11 => Some(RV128),
    _    => None()
  }

function arch_to_bits(a : Architecture) -> arch_xlen =
  match (a) {
    RV32  => 0b01,
    RV64  => 0b10,
    RV128 => 0b11
  }


/* model-internal exceptions */

union exception = {
  Error_not_implemented : string,
  Error_internal_error  : unit
}

val not_implemented : forall ('a : Type). string -> 'a
function not_implemented message = throw(Error_not_implemented(message))

val internal_error : forall ('a : Type). (string, int, string) -> 'a
function internal_error(file, line, s) = {
    assert (false, file ^ ":" ^ string_of_int(line) ^ ": " ^ s);
    throw Error_internal_error()
}

/* privilege levels */

type priv_level = bits(2)
enum Privilege  = {User, Supervisor, Machine}

val privLevel_to_bits : Privilege -> priv_level
function privLevel_to_bits (p) =
  match (p) {
    User       => 0b00,
    Supervisor => 0b01,
    Machine    => 0b11
  }

/*!
 * Converts the given 2-bit privilege level code to the [Privilege] enum.
 * Calling with a reserved code will result in an internal error.
 */
val privLevel_of_bits : priv_level -> Privilege
function privLevel_of_bits (p) =
  match (p) {
    0b00 => User,
    0b01 => Supervisor,
    0b11 => Machine,
    0b10 => internal_error(__FILE__, __LINE__, "Invalid privilege level: " ^ BitStr(p))
  }

val privLevel_to_str : Privilege -> string
function privLevel_to_str (p) =
  match (p) {
    User       => "U",
    Supervisor => "S",
    Machine    => "M"
  }

overload to_str = {privLevel_to_str}

/* enum denoting whether an executed instruction retires */

enum Retired = {RETIRE_SUCCESS, RETIRE_FAIL}

/* memory access types */

union AccessType ('a : Type) = {
  Read      : 'a,
  Write     : 'a,
  ReadWrite : ('a, 'a),
  Execute   : unit
}

val AccessType_to_str : AccessType(ext_access_type) -> string
function AccessType_to_str(ac) =
  match ac {
    Read(_)      => "R",
    Write(_)     => "W",
    ReadWrite(_) => "RW",
    Execute(_)   => "E",
  }

overload to_str = {AccessType_to_str}

enum word_width = {BYTE, HALF, WORD, DOUBLE}

/* architectural interrupt definitions */

enum InterruptType = {
  I_U_Software,
  I_S_Software,
  I_VS_Software,
  I_M_Software,
  I_U_Timer,
  I_S_Timer,
  I_VS_Timer,
  I_M_Timer,
  I_U_External,
  I_S_External,
  I_VS_External,
  I_M_External,
  I_G_External
}

val interruptType_to_bits : InterruptType -> exc_code
function interruptType_to_bits (i) =
  match (i) {
    I_U_Software  => 0x00,
    I_S_Software  => 0x01,
    I_VS_Software => 0x02,
    I_M_Software  => 0x03,
    I_U_Timer     => 0x04,
    I_S_Timer     => 0x05,
    I_VS_Timer    => 0x06,
    I_M_Timer     => 0x07,
    I_U_External  => 0x08,
    I_S_External  => 0x09,
    I_VS_External => 0x0a,
    I_M_External  => 0x0b,
    I_G_External  => 0x0c
  }

val interruptType_to_str : InterruptType -> string
function interruptType_to_str (i) =
  match (i) {
    I_U_Software  => "user-software-interrupt",
    I_S_Software  => "supervisor-software-interrupt",
    I_VS_Software => "virtual-supervisor-software-interrupt",
    I_M_Software  => "machine-software-interrupt",
    I_U_Timer     => "user-timer-interrupt",
    I_S_Timer     => "supervisor-timer-interrupt",
    I_VS_Timer    => "virtual-supervisor-timer-interrupt",
    I_M_Timer     => "machine-timer-interrupt",
    I_U_External  => "user-external-interrupt",
    I_S_External  => "supervisor-external-interrupt",
    I_VS_External => "virtual-supervisor-external-interrupt",
    I_M_External  => "machine-external-interrupt",
    I_G_External  => "guest-external-interrupt"
  }

overload to_str = {interruptType_to_str}

/* architectural exception definitions */

union ExceptionType = {
 E_Fetch_Addr_Align   : unit,
 E_Fetch_Access_Fault : unit,
 E_Illegal_Instr      : unit,
 E_Breakpoint         : unit,
 E_Load_Addr_Align    : unit,
 E_Load_Access_Fault  : unit,
 E_SAMO_Addr_Align    : unit,
 E_SAMO_Access_Fault  : unit,
 E_U_EnvCall          : unit,
 E_S_EnvCall          : unit,
 E_VS_EnvCall         : unit,
 E_M_EnvCall          : unit,
 E_Fetch_Page_Fault   : unit,
 E_Load_Page_Fault    : unit,
 E_Reserved_14        : unit,
 E_SAMO_Page_Fault    : unit,
 E_Reserved_16        : unit,
 E_Reserved_17        : unit,
 E_Reserved_18        : unit,
 E_Reserved_19        : unit,
 E_Fetch_GPage_Fault  : unit,
 E_Load_GPage_Fault   : unit,
 E_Virtual_Instr      : unit,
 E_SAMO_GPage_Fault   : unit,

 /* extensions */
 E_Extension          : ext_exc_type
}

val exceptionType_to_bits : ExceptionType -> exc_code
function exceptionType_to_bits(e) =
  match (e) {
    E_Fetch_Addr_Align()   => 0x00,
    E_Fetch_Access_Fault() => 0x01,
    E_Illegal_Instr()      => 0x02,
    E_Breakpoint()         => 0x03,
    E_Load_Addr_Align()    => 0x04,
    E_Load_Access_Fault()  => 0x05,
    E_SAMO_Addr_Align()    => 0x06,
    E_SAMO_Access_Fault()  => 0x07,
    E_U_EnvCall()          => 0x08,
    E_S_EnvCall()          => 0x09,
    E_VS_EnvCall()         => 0x0a,
    E_M_EnvCall()          => 0x0b,
    E_Fetch_Page_Fault()   => 0x0c,
    E_Load_Page_Fault()    => 0x0d,
    E_Reserved_14()        => 0x0e,
    E_SAMO_Page_Fault()    => 0x0f,
    E_Reserved_16()        => 0x10,
    E_Reserved_17()        => 0x11,
    E_Reserved_18()        => 0x12,
    E_Reserved_19()        => 0x13,
    E_Fetch_GPage_Fault()  => 0x14,
    E_Load_GPage_Fault()   => 0x15,
    E_Virtual_Instr()      => 0x16,
    E_SAMO_GPage_Fault()   => 0x17,

    /* extensions */
    E_Extension(e)         => ext_exc_type_to_bits(e)
  }

val num_of_ExceptionType : ExceptionType -> {'n, (0 <= 'n < xlen). int('n)}
function num_of_ExceptionType(e) =
  match (e) {
    E_Fetch_Addr_Align()   => 0,
    E_Fetch_Access_Fault() => 1,
    E_Illegal_Instr()      => 2,
    E_Breakpoint()         => 3,
    E_Load_Addr_Align()    => 4,
    E_Load_Access_Fault()  => 5,
    E_SAMO_Addr_Align()    => 6,
    E_SAMO_Access_Fault()  => 7,
    E_U_EnvCall()          => 8,
    E_S_EnvCall()          => 9,
    E_VS_EnvCall()         => 10,
    E_M_EnvCall()          => 11,
    E_Fetch_Page_Fault()   => 12,
    E_Load_Page_Fault()    => 13,
    E_Reserved_14()        => 14,
    E_SAMO_Page_Fault()    => 15,
    E_Reserved_16()        => 16,
    E_Reserved_17()        => 17,
    E_Reserved_18()        => 18,
    E_Reserved_19()        => 19,
    E_Fetch_GPage_Fault()  => 20,
    E_Load_GPage_Fault()   => 21,
    E_Virtual_Instr()      => 22,
    E_SAMO_GPage_Fault()   => 23,

    /* extensions */
    E_Extension(e)         => num_of_ext_exc_type(e)

  }

val exceptionType_to_str : ExceptionType -> string
function exceptionType_to_str(e) =
  match (e) {
    E_Fetch_Addr_Align()   => "misaligned-fetch",
    E_Fetch_Access_Fault() => "fetch-access-fault",
    E_Illegal_Instr()      => "illegal-instruction",
    E_Breakpoint()         => "breakpoint",
    E_Load_Addr_Align()    => "misaligned-load",
    E_Load_Access_Fault()  => "load-access-fault",
    E_SAMO_Addr_Align()    => "misaliged-store/amo",
    E_SAMO_Access_Fault()  => "store/amo-access-fault",
    E_U_EnvCall()          => "u-call",
    E_S_EnvCall()          => "s-call",
    E_VS_EnvCall()         => "vs-call",
    E_M_EnvCall()          => "m-call",
    E_Fetch_Page_Fault()   => "fetch-page-fault",
    E_Load_Page_Fault()    => "load-page-fault",
    E_Reserved_14()        => "reserved-14",
    E_SAMO_Page_Fault()    => "store/amo-page-fault",
    E_Reserved_16()        => "reserved-16",
    E_Reserved_17()        => "reserved-17",
    E_Reserved_18()        => "reserved-18",
    E_Reserved_19()        => "reserved-19",
    E_Fetch_GPage_Fault()  => "fetch-guest-page-fault",
    E_Load_GPage_Fault()   => "load-guest-page-fault",
    E_Virtual_Instr()      => "virtual-instruction",
    E_SAMO_GPage_Fault()   => "store/amo-guest-page-fault",

    /* extensions */
    E_Extension(e)         => ext_exc_type_to_str(e)
  }

overload to_str = {exceptionType_to_str}

/*
 * Update exception type with a given memory access type.
 *
 * Note: could probably be modeled in a nicer, more intuitive manner
 */

function E_Addr_Align_of_AccessType(a: AccessType(ext_access_type)) -> ExceptionType =
  match a {
    Read(_)      => E_Load_Addr_Align(),
    Write(_)     => E_SAMO_Addr_Align(),
    ReadWrite(_) => E_SAMO_Addr_Align(),
    Execute(_)   => E_Fetch_Addr_Align(),
  }

function E_Access_Fault_of_AccessType(a: AccessType(ext_access_type)) -> ExceptionType =
  match a {
    Read(_)      => E_Load_Access_Fault(),
    Write(_)     => E_SAMO_Access_Fault(),
    ReadWrite(_) => E_SAMO_Access_Fault(),
    Execute(_)   => E_Fetch_Access_Fault(),
  }

function E_Page_Fault_of_AccessType(a: AccessType(ext_access_type)) -> ExceptionType =
  match a {
    Read(_)      => E_Load_Page_Fault(),
    Write(_)     => E_SAMO_Page_Fault(),
    ReadWrite(_) => E_SAMO_Page_Fault(),
    Execute(_)   => E_Fetch_Page_Fault(),
  }

function E_GPage_Fault_of_AccessType(a: AccessType(ext_access_type)) -> ExceptionType =
  match a {
    Read(_)      => E_Load_GPage_Fault(),
    Write(_)     => E_SAMO_GPage_Fault(),
    ReadWrite(_) => E_SAMO_GPage_Fault(),
    Execute(_)   => E_Fetch_GPage_Fault(),
  }

val exceptionType_update_AccessType : (ExceptionType, AccessType(ext_access_type)) -> ExceptionType
function exceptionType_update_AccessType(e, a) =
match(e) {
  E_Fetch_Addr_Align()   => E_Addr_Align_of_AccessType(a),
  E_Load_Addr_Align()    => E_Addr_Align_of_AccessType(a),
  E_SAMO_Addr_Align()    => E_Addr_Align_of_AccessType(a),
  E_Fetch_Access_Fault() => E_Access_Fault_of_AccessType(a),
  E_Load_Access_Fault()  => E_Access_Fault_of_AccessType(a),
  E_SAMO_Access_Fault()  => E_Access_Fault_of_AccessType(a),
  E_Fetch_Page_Fault()   => E_Page_Fault_of_AccessType(a),
  E_Load_Page_Fault()    => E_Page_Fault_of_AccessType(a),
  E_SAMO_Page_Fault()    => E_Page_Fault_of_AccessType(a),
  E_Fetch_GPage_Fault()  => E_GPage_Fault_of_AccessType(a),
  E_Load_GPage_Fault()   => E_GPage_Fault_of_AccessType(a),
  E_SAMO_GPage_Fault()   => E_GPage_Fault_of_AccessType(a),
  _ => e /* Other exceptions are not access type specific */
}

/* Possible trap causes: either a synchronous exception or asynchronous interrupt */

union TrapCause = {
  I : InterruptType,
  E : ExceptionType,
}

val trapCause_to_bits : TrapCause -> exc_code
function trapCause_to_bits(t) = match t {
  I(i) => interruptType_to_bits(i),
  E(e) => exceptionType_to_bits(e),
}

val trapCause_is_interrupt : TrapCause -> bool
function trapCause_is_interrupt(t) = match t {
  I(_) => true,
  _    => false,
}

val trapCause_to_str : TrapCause -> string
function trapCause_to_str(t) = match t {
  I(i) => interruptType_to_str(i),
  E(e) => exceptionType_to_str(e),
}

overload to_str = {trapCause_to_str}

/* trap modes */

type tv_mode = bits(2)
enum TrapVectorMode = {TV_Direct, TV_Vector, TV_Reserved}

val trapVectorMode_of_bits : tv_mode -> TrapVectorMode
function trapVectorMode_of_bits (m) =
  match (m) {
    0b00 => TV_Direct,
    0b01 => TV_Vector,
    _    => TV_Reserved
  }

/* extension context status */

type ext_status = bits(2)
enum ExtStatus = {Off, Initial, Clean, Dirty}

val extStatus_to_bits : ExtStatus -> ext_status
function extStatus_to_bits(e) =
  match (e) {
    Off     => 0b00,
    Initial => 0b01,
    Clean   => 0b10,
    Dirty   => 0b11
  }

val extStatus_of_bits : ext_status -> ExtStatus
function extStatus_of_bits(e) =
  match (e) {
    0b00 => Off,
    0b01 => Initial,
    0b10 => Clean,
    0b11 => Dirty
  }

/* address translation stages & modes */

/*
 * We model 3 stages:
 *   - S:  va --> pa  (V=0)
 *   - VS: va --> gpa (V=1)
 *   - G:  gpa -> spa (V=1)
 */
enum AddressTranslationStage = {S, VS, G}

function AddressTranslationStage_to_str(s : AddressTranslationStage) -> string =
  match s {
    S  => "S",
    VS => "VS",
    G  => "G"
  }
overload to_str = {AddressTranslationStage_to_str}

enum AddressTranslationMode = {Bare, Sv32, Sv39, Sv48, Sv57, Sv32x4, Sv39x4, Sv48x4, Sv57x4}

type atp64_mode = bits(4)

function satp64Mode_of_bits(a : Architecture, m : atp64_mode) -> option(AddressTranslationMode) =
  match (a, m) {
    (_,    0x0) => Some(Bare),
    (RV32, 0x1) => Some(Sv32),
    (RV64, 0x8) => Some(Sv39),
    (RV64, 0x9) => Some(Sv48),
    (RV64, 0xa) => Some(Sv57),
    (_, _)      => None()
  }

function hgatp64Mode_of_bits(a : Architecture, m : atp64_mode) -> option(AddressTranslationMode) =
  match (a, m) {
    (_,    0x0) => Some(Bare),
    (RV32, 0x1) => Some(Sv32x4),
    (RV64, 0x8) => Some(Sv39x4),
    (RV64, 0x9) => Some(Sv48x4),
    (RV64, 0xa) => Some(Sv57x4),
    (_, _)      => None()
  }

function AddressTranslationMode_to_str(atm: AddressTranslationMode) -> string = match atm {
  Bare => "Bare",
  Sv32 => "Sv32",
  Sv39 => "Sv39",
  Sv48 => "Sv48",
  Sv57 => "Sv57",
  Sv32x4 => "Sv32x4",
  Sv39x4 => "Sv39x4",
  Sv48x4 => "Sv48x4",
  Sv57x4 => "Sv57x4"
}

overload to_str = {AddressTranslationMode_to_str}

/* CSR access control bits (from CSR addresses) */

type csrRW = bits(2)  /* read/write */

/* instruction opcode grouping */
enum uop = {RISCV_LUI, RISCV_AUIPC}               /* upper immediate ops */
enum bop = {RISCV_BEQ, RISCV_BNE, RISCV_BLT,
            RISCV_BGE, RISCV_BLTU, RISCV_BGEU}    /* branch ops */
enum iop = {RISCV_ADDI, RISCV_SLTI, RISCV_SLTIU,
            RISCV_XORI, RISCV_ORI, RISCV_ANDI}    /* immediate ops */
enum sop = {RISCV_SLLI, RISCV_SRLI, RISCV_SRAI}   /* shift ops */
enum rop = {RISCV_ADD, RISCV_SUB, RISCV_SLL, RISCV_SLT,
            RISCV_SLTU, RISCV_XOR, RISCV_SRL, RISCV_SRA,
            RISCV_OR, RISCV_AND}                  /* reg-reg ops */

enum ropw  = {RISCV_ADDW, RISCV_SUBW, RISCV_SLLW,
              RISCV_SRLW, RISCV_SRAW}             /* reg-reg 32-bit ops */
enum sopw = {RISCV_SLLIW, RISCV_SRLIW,
             RISCV_SRAIW}                         /* RV64-only shift ops */
enum amoop = {AMOSWAP, AMOADD, AMOXOR, AMOAND, AMOOR,
              AMOMIN, AMOMAX, AMOMINU, AMOMAXU}   /* AMO ops */
enum csrop = {CSRRW, CSRRS, CSRRC}                /* CSR ops */

enum brop_zba = {RISCV_SH1ADD, RISCV_SH2ADD, RISCV_SH3ADD}

enum brop_zbb = {RISCV_ANDN, RISCV_ORN, RISCV_XNOR, RISCV_MAX,
                 RISCV_MAXU, RISCV_MIN, RISCV_MINU, RISCV_ROL,
                 RISCV_ROR}

enum brop_zbkb = {RISCV_PACK, RISCV_PACKH}

enum brop_zbs = {RISCV_BCLR, RISCV_BEXT, RISCV_BINV, RISCV_BSET}

enum bropw_zba = {RISCV_ADDUW, RISCV_SH1ADDUW, RISCV_SH2ADDUW,
                  RISCV_SH3ADDUW}

enum bropw_zbb = {RISCV_ROLW, RISCV_RORW}

enum biop_zbs = {RISCV_BCLRI, RISCV_BEXTI, RISCV_BINVI, RISCV_BSETI}

enum extop_zbb = {RISCV_SEXTB, RISCV_SEXTH, RISCV_ZEXTH}

enum zicondop = {RISCV_CZERO_EQZ, RISCV_CZERO_NEZ}

mapping bool_bits : bool <-> bits(1) = {
  true   <-> 0b1,
  false  <-> 0b0
}

mapping bool_not_bits : bool <-> bits(1) = {
  true   <-> 0b0,
  false  <-> 0b1
}

mapping size_bits : word_width <-> bits(2) = {
  BYTE   <-> 0b00,
  HALF   <-> 0b01,
  WORD   <-> 0b10,
  DOUBLE <-> 0b11
}

mapping size_mnemonic : word_width <-> string = {
  BYTE   <-> "b",
  HALF   <-> "h",
  WORD   <-> "w",
  DOUBLE <-> "d"
}

val word_width_bytes : word_width -> {'s, 's == 1 | 's == 2 | 's == 4 | 's == 8 . atom('s)}
function word_width_bytes width = match width {
  BYTE   => 1,
  HALF   => 2,
  WORD   => 4,
  DOUBLE => 8
}

/*!
 * Raise an internal error reporting that width w is invalid for access kind, k,
 * and current xlen. The file name and line number should be passed in as the
 * first two arguments using the __FILE__ and __LINE__ built-in macros.
 * This is mainly used to supress Sail warnings about incomplete matches and
 * should be unreachable. See https://github.com/riscv/sail-riscv/issues/194
 * and https://github.com/riscv/sail-riscv/pull/197 .
 */
val report_invalid_width : forall ('a : Type). (string, int, word_width, string) -> 'a
function report_invalid_width(f , l, w, k) -> 'a = {
  /*
   * Ideally we would call internal_error here but this triggers a Sail bug,
   * https://github.com/rems-project/sail/issues/203 in versions < 0.15.1, so
   * we work around this by manually inlining.
   * TODO when we are happy to require Sail >= 0.15.1 uncomment the following
   * and remove the rest of the function.
   */
  // internal_error(f, l, "Invalid width, " ^ size_mnemonic(w) ^ ", for " ^ k ^
  //   " with xlen=" ^ string_of_int(sizeof(xlen)));
  assert (false, f ^ ":" ^ string_of_int(l) ^ ": " ^ "Invalid width, "
    ^ size_mnemonic(w) ^ ", for " ^ k ^ " with xlen="
    ^ string_of_int(sizeof(xlen)));
  throw Error_internal_error()
}
