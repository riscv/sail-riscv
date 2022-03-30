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

val privLevel_of_bits : priv_level -> Privilege
function privLevel_of_bits (p) =
  match (p) {
    0b00 => User,
    0b01 => Supervisor,
    0b11 => Machine
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

enum word_width = {BYTE, HALF, WORD, DOUBLE}

/* architectural interrupt definitions */

enum InterruptType = {
  I_U_Software,
  I_S_Software,
  I_M_Software,
  I_U_Timer,
  I_S_Timer,
  I_M_Timer,
  I_U_External,
  I_S_External,
  I_M_External
}

val interruptType_to_bits : InterruptType -> exc_code
function interruptType_to_bits (i) =
  match (i) {
    I_U_Software => 0x00,
    I_S_Software => 0x01,
    I_M_Software => 0x03,
    I_U_Timer    => 0x04,
    I_S_Timer    => 0x05,
    I_M_Timer    => 0x07,
    I_U_External => 0x08,
    I_S_External => 0x09,
    I_M_External => 0x0b
  }

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
 E_Reserved_10        : unit,
 E_M_EnvCall          : unit,
 E_Fetch_Page_Fault   : unit,
 E_Load_Page_Fault    : unit,
 E_Reserved_14        : unit,
 E_SAMO_Page_Fault    : unit,

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
    E_Reserved_10()        => 0x0a,
    E_M_EnvCall()          => 0x0b,
    E_Fetch_Page_Fault()   => 0x0c,
    E_Load_Page_Fault()    => 0x0d,
    E_Reserved_14()        => 0x0e,
    E_SAMO_Page_Fault()    => 0x0f,

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
    E_Reserved_10()        => 10,
    E_M_EnvCall()          => 11,
    E_Fetch_Page_Fault()   => 12,
    E_Load_Page_Fault()    => 13,
    E_Reserved_14()        => 14,
    E_SAMO_Page_Fault()    => 15,

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
    E_Reserved_10()        => "reserved-0",
    E_M_EnvCall()          => "m-call",
    E_Fetch_Page_Fault()   => "fetch-page-fault",
    E_Load_Page_Fault()    => "load-page-fault",
    E_Reserved_14()        => "reserved-1",
    E_SAMO_Page_Fault()    => "store/amo-page-fault",

    /* extensions */
    E_Extension(e)         => ext_exc_type_to_str(e)
  }

overload to_str = {exceptionType_to_str}

/* model-internal exceptions */

union exception = {
  Error_not_implemented : string,
  Error_internal_error  : unit
}

val not_implemented : forall ('a : Type). string -> 'a effect {escape}
function not_implemented message = throw(Error_not_implemented(message))

val internal_error : forall ('a : Type). string -> 'a effect {escape}
function internal_error(s) = {
    assert (false, s);
    throw Error_internal_error()
}

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

/* supervisor-level address translation modes */

type satp_mode = bits(4)
enum SATPMode = {Sbare, Sv32, Sv39, Sv48}

function satp64Mode_of_bits(a : Architecture, m : satp_mode) -> option(SATPMode) =
  match (a, m) {
    (_,    0x0) => Some(Sbare),
    (RV32, 0x1) => Some(Sv32),
    (RV64, 0x8) => Some(Sv39),
    (RV64, 0x9) => Some(Sv48),
    (_, _)      => None()
  }

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

val sep : unit <-> string
mapping sep : unit <-> string = {
  ()     <-> opt_spc() ^ "," ^ def_spc()
}

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



/* P extension SIMD instructions */
enum p_alu_16_op   = {ADD16, RADD16, URADD16, KADD16, UKADD16, SUB16, RSUB16, URSUB16, KSUB16, UKSUB16, CMPEQ16, KSLL16, KSLRA16, KSLRA16_U,
                       SCMPLE16, SCMPLT16, SLL16, SMAX16, SMIN16, SRA16, SRA16_U, SRL16, SRL16_U, UCMPLE16, UCMPLT16, UMAX16, UMIN16}
enum p_cross_16_op = {CRAS16, RCRAS16, URCRAS16, KCRAS16, UKCRAS16, CRSA16, RCRSA16, URCRSA16, KCRSA16, UKCRSA16,
                       STAS16, RSTAS16, URSTAS16, KSTAS16, UKSTAS16, STSA16, RSTSA16, URSTSA16, KSTSA16, UKSTSA16, KHM16, KHMX16}
enum p_mul_16_op   = {SMUL16, SMULX16, UMUL16, UMULX16}
enum p_one_register_16_op = {CLRS16, CLO16, CLZ16, KABS16}
enum p_alu_8_op = {ADD8, RADD8, URADD8, KADD8, UKADD8, SUB8, RSUB8, URSUB8, KSUB8, UKSUB8, CMPEQ8, KSLL8, KSLRA8, KSLRA8_U,
                   SCMPLE8, SCMPLT8, SLL8, SMAX8, SMIN8, SRA8, SRA8_U, SRL8, SRL8_U, UCMPLE8, UCMPLT8, UMAX8, UMIN8}
enum p_mul_8_op   = {SMUL8, SMULX8, UMUL8, UMULX8}
enum p_one_register_8_op = {CLRS8, CLO8, CLZ8, KABS8}
enum p_khm8_op = {KHM8, KHMX8}
enum p_imm3_op = {KSLLI8, SCLIP8, SLLI8, SRAI8, SRAI8_U, SRLI8, SRLI8_U, UCLIP8}
enum p_imm4_op = {KSLLI16, SCLIP16, SLLI16, SRAI16, SRAI16_U, SRLI16, SRLI16_U, UCLIP16}
enum p_unpack_swap_op = {SUNPKD810, SUNPKD820, SUNPKD830, SUNPKD831, SUNPKD832, SWAP8, ZUNPKD810, ZUNPKD820, ZUNPKD830, ZUNPKD831, ZUNPKD832}

/* P extension partial SIMD instructions */
enum p_inst_pack_16 = {PKBB16, PKBT16, PKTB16, PKTT16}
enum p_inst_32_32_mul_add = {SMMUL, SMMUL_U, KMMAC, KMMAC_U, KMMSB, KMMSB_U, KWMMUL, KWMMUL_U}
enum p_inst_32_16_mul_add = {SMMWB, SMMWB_U, SMMWT, SMMWT_U, KMMAWB, KMMAWB_U, KMMAWT, KMMAWT_U, KMMWB2, KMMWB2_U, KMMWT2, KMMWT2_U, KMMAWB2, KMMAWB2_U, KMMAWT2, KMMAWT2_U}
enum p_inst_16_32_mul_add = {SMBB16, SMBT16, SMTT16, KMDA, KMXDA, SMDS, SMDRS, SMXDS, KMADA, KMAXDA, KMABB, KMABT, KMATT, KMSDA, KMSXDA, KMADS, KMADRS, KMAXDS}
enum p_inst_8_32_mul_add = {SMAQA, UMAQA, SMAQA_SU}
enum p_inst_misc_32 = {SCLIP32, UCLIP32}
enum p_inst_one_register_32 = {CLO32, CLZ32, CLRS32}
enum p_inst_pbsad = {PBSAD, PBSADA}

/* P extension 64-bit data computation instructions */
enum p_inst_64bits_add_sub = {ADD64, RADD64, KADD64, URADD64, UKADD64, SUB64, RSUB64, KSUB64, URSUB64, UKSUB64}
enum p_inst_32_mul_64_add_sub = {SMAR64, SMSR64, UMAR64, UMSR64, KMAR64, KMSR64, UKMAR64, UKMSR64}
enum p_inst_16_mul_64_add_sub = {SMALBB, SMALBT, SMALTT, SMALDA, SMALXDA, SMALDS, SMALDRS, SMALXDS, SMSLDA, SMSLXDA}

/* P extension Non-SIMD instructions */
enum p_inst_q15 = {KADDH, KSUBH, KHMBB, KHMBT, KHMTT, UKADDH, UKSUBH}
enum p_inst_q31 = {KADDW, KSUBW, UKADDW, UKSUBW, KSLRAW, KSLRAW_U, KSLLW, KDMBB, KDMBT, KDMTT, KDMABB, KDMABT, KDMATT}
enum p_inst_32_compute = {RADDW, RSUBW, URADDW, URSUBW, MAXW, MINW}
enum p_inst_32_pair_rd_compute = {MULR64, MULSR64}
enum p_inst_nonsimd_misc = {AVE, SRA_U, BITREV, MADDR32, MSUBR32}
enum p_inst_imm6 = {BITREVI, SRAI_U}

/* P extension 64-only instructions */
enum p_64_only_alu_op = {ADD32, RADD32, URADD32, KADD32, UKADD32, SUB32, RSUB32, URSUB32, KSUB32, UKSUB32, SRA32, SRA32_U, SRL32, SRL32_U, SLL32, 
                         KSLL32, KSLRA32, KSLRA32_U, SMAX32, SMIN32, UMAX32, UMIN32}
enum p_64_only_q15_op = {KHMBB16, KHMBT16, KHMTT16, KDMBB16, KDMBT16, KDMTT16, KDMABB16, KDMABT16, KDMATT16}
enum p_64_only_32_mul_op = {SMBT32, SMTT32, KMABB32, KMABT32, KMATT32, KMDA32, KMXDA32, KMAXDA32, 
                            KMADS32, KMADRS32, KMAXDS32, KMSDA32, KMSXDA32, SMDS32, SMDRS32, SMXDS32}
enum p_64_only_pack_op = {PKBB32, PKBT32, PKTB32, PKTT32}
enum p_64_only_imm5_op = {KSLLI32, SLLI32, SRAI32, SRAI32_U, SRLI32, SRLI32_U}
enum p_64_only_cross_32_op = {CRAS32, RCRAS32, URCRAS32, KCRAS32, UKCRAS32, CRSA32, RCRSA32, URCRSA32, KCRSA32, UKCRSA32, 
                              STAS32, RSTAS32, URSTAS32, KSTAS32, UKSTAS32, STSA32, RSTSA32, URSTSA32, KSTSA32, UKSTSA32}