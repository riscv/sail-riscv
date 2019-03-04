/* Basic type and function definitions used pervasively in the model. */

let xlen = 64
type xlenbits = bits(64)

let xlen_max_unsigned = 2 ^ xlen - 1
let xlen_max_signed = 2 ^ (xlen - 1) - 1
let xlen_min_signed = 0 - 2 ^ (xlen - 1)

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

/* program counter */

register PC       : xlenbits
register nextPC   : xlenbits

/* internal state to hold instruction bits for faulting instructions */
register instbits : xlenbits

/* register file and accessors */

/* register Xs : vector(32, dec, xlenbits) */

register PCC : Capability
register nextPCC : Capability
register DDC : Capability

register UTCC      : Capability
register UScratchC : Capability
register UEPCC     : Capability
register STCC      : Capability
register SScratchC : Capability
register SEPCC     : Capability
register MTCC      : Capability
register MScratchC : Capability
register MEPCC     : Capability

register x1  : Capability
register x2  : Capability
register x3  : Capability
register x4  : Capability
register x5  : Capability
register x6  : Capability
register x7  : Capability
register x8  : Capability
register x9  : Capability
register x10 : Capability
register x11 : Capability
register x12 : Capability
register x13 : Capability
register x14 : Capability
register x15 : Capability
register x16 : Capability
register x17 : Capability
register x18 : Capability
register x19 : Capability
register x20 : Capability
register x21 : Capability
register x22 : Capability
register x23 : Capability
register x24 : Capability
register x25 : Capability
register x26 : Capability
register x27 : Capability
register x28 : Capability
register x29 : Capability
register x30 : Capability
register x31 : Capability

let CapRegs : vector(32, dec, register(Capability)) = [
  ref x31,
  ref x30,
  ref x29,
  ref x28,
  ref x27,
  ref x26,
  ref x25,
  ref x24,
  ref x23,
  ref x22,
  ref x21,
  ref x20,
  ref x19,
  ref x18,
  ref x17,
  ref x16,
  ref x15,
  ref x14,
  ref x13,
  ref x12,
  ref x11,
  ref x10,
  ref x9 ,
  ref x8 ,
  ref x7 ,
  ref x6 ,
  ref x5 ,
  ref x4 ,
  ref x3 ,
  ref x2 ,
  ref x1 ,
  ref DDC
]

/*!
THIS reads a given capability register or,
the null capabiility if the argument is zero.
*/
val readCapReg : forall 'n, 0 <= 'n < 32 . regno('n) -> Capability effect {rreg}
function readCapReg(n) =
  if (n == 0) then
    null_cap
  else
    reg_deref(CapRegs[n])

/*!
As per [readCapReg] but reads DDC instead of null when argument is zero.
 */
val readCapRegDDC : forall 'n, 0 <= 'n < 32 . regno('n) -> Capability effect {rreg}
function readCapRegDDC(n) =
  reg_deref(CapRegs[n]) /* NB CapRegs[0] points to DDC */


$ifdef RVFI_DII
val rvfi_wX : forall 'n, 0 <= 'n < 32. (regno('n), xlenbits) -> unit effect {wreg}
function rvfi_wX (r,v) = {
  rvfi_exec->rvfi_rd_wdata() = v;
  rvfi_exec->rvfi_rd_addr() = to_bits(8,r);
}
$else
val rvfi_wX : forall 'n, 0 <= 'n < 32. (regno('n), xlenbits) -> unit
function rvfi_wX (r,v) = ()
$endif

/*!
THIS`(cd, cap_val)` writes capability, `cap_val` capability register `cd`. Writes to register zero are ignored.
 */
val writeCapReg : forall 'n, 0 <= 'n < 32. (regno('n), Capability) -> unit effect {wreg}
function writeCapReg(n, cap) = {
  if (n != 0) then {
    rvfi_wX(n,cap.address);
    (*CapRegs[n]) = cap
  }
}

val init_regs : unit->unit effect{wreg}
function init_regs () = {
  PCC = default_cap;
  DDC = default_cap;
  nextPCC = default_cap;
  UTCC = default_cap;
  UScratchC = null_cap;
  UEPCC = null_cap;
  STCC = default_cap;
  SScratchC = null_cap;
  SEPCC = null_cap;
  MTCC = default_cap;
  MScratchC = null_cap;
  MEPCC = null_cap;
  foreach(i from 1 to 31) {
    (*CapRegs[i]) = null_cap
  }
}

val rX : forall 'n, 0 <= 'n < 32. regno('n) -> xlenbits effect {rreg}
/*function rX 0 = 0x0000000000000000
and rX (r if r > 0) = Xs[r]*/
function rX r =
  let cap_val = readCapReg(r) in
  cap_val.address

val wX : forall 'n, 0 <= 'n < 32. (regno('n), xlenbits) -> unit effect {wreg}
function wX (r, v) = {
  writeCapReg(r, {null_cap with address=v});
  if (r != 0) then {
     // Xs[r] = v;
     print_reg("x" ^ string_of_int(r) ^ " <- " ^ BitStr(v));
  }
}

/* XXX rename these in cheri_insts */
overload rGPR = {rX}
overload wGPR = {wX}

overload X = {rX, wX}

/* register names */

val cast reg_name_abi : regbits -> string

function reg_name_abi(r) = {
  match (r) {
    0b00000 => "zero",
    0b00001 => "ra",
    0b00010 => "sp",
    0b00011 => "gp",
    0b00100 => "tp",
    0b00101 => "t0",
    0b00110 => "t1",
    0b00111 => "t2",
    0b01000 => "fp",
    0b01001 => "s1",
    0b01010 => "a0",
    0b01011 => "a1",
    0b01100 => "a2",
    0b01101 => "a3",
    0b01110 => "a4",
    0b01111 => "a5",
    0b10000 => "a6",
    0b10001 => "a7",
    0b10010 => "s2",
    0b10011 => "s3",
    0b10100 => "s4",
    0b10101 => "s5",
    0b10110 => "s6",
    0b10111 => "s7",
    0b11000 => "s8",
    0b11001 => "s9",
    0b11010 => "s10",
    0b11011 => "s11",
    0b11100 => "t3",
    0b11101 => "t4",
    0b11110 => "t5",
    0b11111 => "t6"
  }
}

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
    E_CHERI              => 0x20
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
enum SATPMode = {Sbare, Sv32, Sv39}

function satpMode_of_bits(a : Architecture, m : satp_mode) -> option(SATPMode) =
  match (a, m) {
    (_,    0x0) => Some(Sbare),
    (RV32, 0x1) => Some(Sv32),
    (RV64, 0x8) => Some(Sv39),
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

/* mappings for assembly */

val reg_name : bits(5) <-> string
mapping reg_name = {
    0b00000 <-> "zero",
    0b00001 <-> "ra",
    0b00010 <-> "sp",
    0b00011 <-> "gp",
    0b00100 <-> "tp",
    0b00101 <-> "t0",
    0b00110 <-> "t1",
    0b00111 <-> "t2",
    0b01000 <-> "fp",
    0b01001 <-> "s1",
    0b01010 <-> "a0",
    0b01011 <-> "a1",
    0b01100 <-> "a2",
    0b01101 <-> "a3",
    0b01110 <-> "a4",
    0b01111 <-> "a5",
    0b10000 <-> "a6",
    0b10001 <-> "a7",
    0b10010 <-> "s2",
    0b10011 <-> "s3",
    0b10100 <-> "s4",
    0b10101 <-> "s5",
    0b10110 <-> "s6",
    0b10111 <-> "s7",
    0b11000 <-> "s8",
    0b11001 <-> "s9",
    0b11010 <-> "s10",
    0b11011 <-> "s11",
    0b11100 <-> "t3",
    0b11101 <-> "t4",
    0b11110 <-> "t5",
    0b11111 <-> "t6"
}

mapping creg_name : bits(3) <-> string = {
  0b000 <-> "s0",
  0b001 <-> "s1",
  0b010 <-> "a0",
  0b011 <-> "a1",
  0b100 <-> "a2",
  0b101 <-> "a3",
  0b110 <-> "a4",
  0b111 <-> "a5"
}

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

val word_width_bytes : word_width -> {'s, 's == 1 | 's == 2 | 's == 4 | 's == 8 . atom('s)}
function word_width_bytes width = match width {
  BYTE   => 1,
  HALF   => 2,
  WORD   => 4,
  DOUBLE => 8
}

mapping size_mnemonic : word_width <-> string = {
  BYTE   <-> "b",
  HALF   <-> "h",
  WORD   <-> "w",
  DOUBLE <-> "d"
}

union DDC_Result = {
  DDC_Address : xlenbits,
  DDC_Failure : CapEx
}

val translateDDC : (xlenbits, AccessType, word_width) -> DDC_Result effect {rreg, escape}
function translateDDC (addr, at, width) = {
  let ddc = DDC;
  let have_rqd_load_perm : bool = match at {
    Read       => ddc.permit_load,
    Write      => true,
    ReadWrite  => ddc.permit_load,
    Execute    => false /* DDC should only be for load/store */
  };
  let have_rqd_store_perm : bool = match at {
    Read       => true,
    Write      => ddc.permit_store,
    ReadWrite  => ddc.permit_store,
    Execute    => false /* DDC should only be for load/store */
  };
  let newAddr = (getCapCursor(ddc) + unsigned(addr)) % pow2(xlen);
  let size  = word_width_bytes(width);
  let (base, top) = getCapBounds(ddc);

  if not(ddc.tag) then
    DDC_Failure(CapEx_TagViolation)
  else if ddc.sealed then
    DDC_Failure(CapEx_SealViolation)
  else if not(have_rqd_load_perm) then
    DDC_Failure(CapEx_PermitLoadViolation)
  else if not(have_rqd_store_perm) then
    DDC_Failure(CapEx_PermitStoreViolation)
  else if (newAddr + size) > top then
    DDC_Failure(CapEx_LengthViolation)
  else if newAddr < base then
    DDC_Failure(CapEx_LengthViolation)
  else
    DDC_Address(to_bits(64, newAddr))
}

val raise_c2_exception6 : (CapEx, bits(6)) -> bool effect {escape, rreg, wreg}

