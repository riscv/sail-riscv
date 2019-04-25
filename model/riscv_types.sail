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

type regbits  = bits(5)
type cregbits = bits(3)    /* identifiers in RVC instructions */
type csreg    = bits(12)   /* CSR addressing */

/* register file indexing */

type regno ('n : Int), 0 <= 'n < 32 = atom('n)

val cast regbits_to_regno : bits(5) -> {'n, 0 <= 'n < 32. regno('n)}
function regbits_to_regno b = let 'r = unsigned(b) in r

/* mapping RVC register indices into normal indices */
val creg2reg_bits : cregbits -> regbits
function creg2reg_bits(creg) = 0b01 @ creg

/* some architecture and ABI relevant register identifiers */
let zreg : regbits = 0b00000  /* x0, zero register  */
let ra   : regbits = 0b00001  /* x1, return address */
let sp   : regbits = 0b00010  /* x2, stack pointer  */

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

val cast privLevel_to_bits : Privilege -> priv_level
function privLevel_to_bits (p) =
  match (p) {
    User       => 0b00,
    Supervisor => 0b01,
    Machine    => 0b11
  }

val cast privLevel_of_bits : priv_level -> Privilege
function privLevel_of_bits (p) =
  match (p) {
    0b00 => User,
    0b01 => Supervisor,
    0b11 => Machine
  }

val cast privLevel_to_str : Privilege -> string
function privLevel_to_str (p) =
  match (p) {
    User       => "U",
    Supervisor => "S",
    Machine    => "M"
  }

/* memory access types */

enum AccessType = {Read, Write, ReadWrite, Execute}

val cast accessType_to_str : AccessType -> string
function accessType_to_str (a) =
  match (a) {
    Read      => "R",
    Write     => "W",
    ReadWrite => "RW",
    Execute   => "X"
  }

enum ReadType   = {Instruction, Data}

val cast readType_to_str : ReadType -> string
function readType_to_str (r) =
  match (r) {
    Instruction => "I",
    Data        => "D"
  }

enum word_width = {BYTE, HALF, WORD, DOUBLE}

/* architectural interrupt definitions */

type exc_code = bits(8)

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

val cast interruptType_to_bits : InterruptType -> exc_code
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

enum ExceptionType = {
 E_Fetch_Addr_Align,
 E_Fetch_Access_Fault,
 E_Illegal_Instr,
 E_Breakpoint,
 E_Load_Addr_Align,
 E_Load_Access_Fault,
 E_SAMO_Addr_Align,
 E_SAMO_Access_Fault,
 E_U_EnvCall,
 E_S_EnvCall,
 E_Reserved_10,
 E_M_EnvCall,
 E_Fetch_Page_Fault,
 E_Load_Page_Fault,
 E_Reserved_14,
 E_SAMO_Page_Fault,

 /* extensions */
 E_CHERI
}

val cast exceptionType_to_bits : ExceptionType -> exc_code
function exceptionType_to_bits(e) =
  match (e) {
    E_Fetch_Addr_Align   => 0x00,
    E_Fetch_Access_Fault => 0x01,
    E_Illegal_Instr      => 0x02,
    E_Breakpoint         => 0x03,
    E_Load_Addr_Align    => 0x04,
    E_Load_Access_Fault  => 0x05,
    E_SAMO_Addr_Align    => 0x06,
    E_SAMO_Access_Fault  => 0x07,
    E_U_EnvCall          => 0x08,
    E_S_EnvCall          => 0x09,
    E_Reserved_10        => 0x0a,
    E_M_EnvCall          => 0x0b,
    E_Fetch_Page_Fault   => 0x0c,
    E_Load_Page_Fault    => 0x0d,
    E_Reserved_14        => 0x0e,
    E_SAMO_Page_Fault    => 0x0f,

    /* extensions */
    E_CHERI              => 0x20    /* FIXME: this is reserved for a future standard */
  }

val cast exceptionType_to_str : ExceptionType -> string
function exceptionType_to_str(e) =
  match (e) {
    E_Fetch_Addr_Align   => "misaligned-fetch",
    E_Fetch_Access_Fault => "fetch-access-fault",
    E_Illegal_Instr      => "illegal-instruction",
    E_Breakpoint         => "breakpoint",
    E_Load_Addr_Align    => "misaligned-load",
    E_Load_Access_Fault  => "load-access-fault",
    E_SAMO_Addr_Align    => "misaliged-store/amo",
    E_SAMO_Access_Fault  => "store/amo-access-fault",
    E_U_EnvCall          => "u-call",
    E_S_EnvCall          => "s-call",
    E_Reserved_10        => "reserved-0",
    E_M_EnvCall          => "m-call",
    E_Fetch_Page_Fault   => "fetch-page-fault",
    E_Load_Page_Fault    => "load-page-fault",
    E_Reserved_14        => "reserved-1",
    E_SAMO_Page_Fault    => "store/amo-page-fault",

    /* extensions */
    E_CHERI              => "CHERI"
  }

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

val cast trapVectorMode_of_bits : tv_mode -> TrapVectorMode
function trapVectorMode_of_bits (m) =
  match (m) {
    0b00 => TV_Direct,
    0b01 => TV_Vector,
    _    => TV_Reserved
  }

/* extension context status */

type ext_status = bits(2)
enum ExtStatus = {Off, Initial, Clean, Dirty}

val cast extStatus_to_bits : ExtStatus -> ext_status
function extStatus_to_bits(e) =
  match (e) {
    Off     => 0b00,
    Initial => 0b01,
    Clean   => 0b10,
    Dirty   => 0b11
  }

val cast extStatus_of_bits : ext_status -> ExtStatus
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
