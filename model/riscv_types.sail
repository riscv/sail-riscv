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



enum p_inst_rs2_rs1_rd_op = {ADD8, ADD16, ADD64, AVE, BITREV, CMPEQ8, CMPEQ16, CRAS16, CRSA16, KADD8, KADD16, KADD64, KADDH, KADDW, KCRAS16, KCRSA16, KDMBB, KDMBT, KDMTT, KDMABB, KDMABT, KDMATT, KHM8, KHMX8, KHM16, KHMX16, KHMBB, KHMBT, KHMTT, KMABB, KMABT, KMATT, KMADA, KMAXDA, KMADS, KMADRS, KMAXDS, KMAR64, KMDA, KMXDA, KMMAC, KMMAC_U, KMMAWB, KMMAWB_U, KMMAWB2, KMMAWB2_U, KMMAWT, KMMAWT_U, KMMAWT2, KMMAWT2_U, KMMSB, KMMSB_U, KMMWB2, KMMWB2_U, KMMWT2, KMMWT2_U, KMSDA, KMSXDA, KMSR64, KSLLW, KSLL8, KSLL16, KSLRA8, KSLRA8_U, KSLRA16, KSLRA16_U, KSLRAW, KSLRAW_U, KSTAS16, KSTSA16, KSUB8, KSUB16, KSUB64, KSUBH, KSUBW, KWMMUL, KWMMUL_U, MADDR32, MAXW, MINW, MSUBR32, MULR64, MULSR64, PBSAD, PBSADA, PKBB16, PKBT16, PKTT16, PKTB16, RADD8, RADD16, RADD64, RADDW, RCRAS16, RCRSA16, RSTAS16, RSTSA16, RSUB8, RSUB16, RSUB64, RSUBW, SCMPLE8, SCMPLE16, SCMPLT8, SCMPLT16, SLL8, SLL16, SMAL, SMALBB, SMALBT, SMALTT, SMALDA, SMALXDA, SMALDS, SMALDRS, SMALXDS, SMAR64, SMAQA, SMAQA_SU, SMAX8, SMAX16, SMBB16, SMBT16, SMTT16, SMDS, SMDRS, SMXDS, SMIN8, SMIN16, SMMUL, SMMUL_U, SMMWB, SMMWB_U, SMMWT, SMMWT_U, SMSLDA, SMSLXDA, SMSR64, SMUL8, SMULX8, SMUL16, SMULX16, SRA_U, SRA8, SRA8_U, SRA16, SRA16_U, SRL8, SRL8_U, SRL16, SRL16_U, STAS16, STSA16, SUB8, SUB16, SUB64, UCMPLE8, UCMPLE16, UCMPLT8, UCMPLT16, UKADD8, UKADD16, UKADD64, UKADDH, UKADDW, UKCRAS16, UKCRSA16, UKMAR64, UKMSR64, UKSTAS16, UKSTSA16, UKSUB8, UKSUB16, UKSUB64, UKSUBH, UKSUBW, UMAR64, UMAQA, UMAX8, UMAX16, UMIN8, UMIN16, UMSR64, UMUL8, UMULX8, UMUL16, UMULX16, URADD8, URADD16, URADD64, URADDW, URCRAS16, URCRSA16, URSTAS16, URSTSA16, URSUB8, URSUB16, URSUB64, URSUBW, WEXT, ADD32, CRAS32, CRSA32, KADD32, KCRAS32, KCRSA32, KDMBB16, KDMBT16, KDMTT16, KDMABB16, KDMABT16, KDMATT16, KHMBB16, KHMBT16, KHMTT16, KMABB32, KMABT32, KMATT32, KMAXDA32, KMDA32, KMXDA32, KMADS32, KMADRS32, KMAXDS32, KMSDA32, KMSXDA32, KSLL32, KSLRA32, KSLRA32_U, KSTAS32, KSTSA32, KSUB32, PKBB32, PKBT32, PKTT32, PKTB32, RADD32, RCRAS32, RCRSA32, RSTAS32, RSTSA32, RSUB32, SLL32, SMAX32, SMBT32, SMTT32, SMDS32, SMDRS32, SMXDS32, SMIN32, SRA32, SRA32_U, SRL32, SRL32_U, STAS32, STSA32, SUB32, UKADD32, UKCRAS32, UKCRSA32, UKSTAS32, UKSTSA32, UKSUB32, UMAX32, UMIN32, URADD32, URCRAS32, URCRSA32, URSTAS32, URSTSA32, URSUB32}
enum p_inst_imm6_rs1_rd_op = {BITREVI, SRAI_U}
enum p_inst_rs3_rs2_rs1_rd_op = {BPICK}
enum p_inst_rs1_rd_op = {CLRS8, CLRS16, CLRS32, CLO8, CLO16, CLO32, CLZ8, CLZ16, CLZ32, KABS8, KABS16, KABSW, SUNPKD810, SUNPKD820, SUNPKD830, SUNPKD831, SUNPKD832, SWAP8, ZUNPKD810, ZUNPKD820, ZUNPKD830, ZUNPKD831, ZUNPKD832, KABS32}
enum p_inst_imm3_rs1_rd_op = {INSB, KSLLI8, SCLIP8, SLLI8, SRAI8, SRAI8_U, SRLI8, SRLI8_U, UCLIP8}
enum p_inst_imm5_rs1_rd_op = {KSLLIW, SCLIP32, UCLIP32, WEXTI, KSLLI32, SLLI32, SRAI32, SRAI32_U, SRAIW_U, SRLI32, SRLI32_U}
enum p_inst_imm4_rs1_rd_op = {KSLLI16, SCLIP16, SLLI16, SRAI16, SRAI16_U, SRLI16, SRLI16_U, UCLIP16}