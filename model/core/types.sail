// =======================================================================================
// This Sail RISC-V architecture model, comprising all files and
// directories except where otherwise noted is subject the BSD
// two-clause license in the LICENSE file.
//
// SPDX-License-Identifier: BSD-2-Clause
// =======================================================================================

// Basic type and function definitions used pervasively in the model.

type half = bits(16)
type word = bits(32)

// Bit-vector of an uncompressed instruction.
type instbits = bits(32)

type pagesize_bits : Int = 12
let  pagesize_bits = sizeof(pagesize_bits)

// RV32E and RV64E Base Integer Instruction Sets. If this enabled then
// the model will only support E (16 integer registers). It is allowed
// to have a design where `misa[I]` is writable to turn E on and off,
// but this model does not support that.
type base_E_enabled : Bool = config base.E
let base_E_enabled = constraint(base_E_enabled)

// register identifiers

type regidx_bit_width = if base_E_enabled then 4 else 5
let regidx_bit_width = sizeof(regidx_bit_width)

newtype regidx = Regidx : bits(regidx_bit_width)  // uncompressed register identifiers
newtype cregidx = Cregidx : bits(3) // identifiers in RVC instructions
type csreg = bits(12)  // CSR addressing

function regidx_offset(Regidx(r) : regidx, o : bits(regidx_bit_width)) -> regidx = Regidx(r + o)
function regidx_offset_range(Regidx(r) : regidx, o : range(0, 31)) -> regidx = Regidx(r + o)
function regidx_bits(Regidx(b) : regidx) -> bits(regidx_bit_width) = b
overload operator + = { regidx_offset, regidx_offset_range }
// register file indexing

newtype regno = Regno : range(0, 2 ^ regidx_bit_width - 1)

// mapping RVC register indices into normal indices
function creg2reg_idx(Cregidx(i) : cregidx) -> regidx = Regidx(zero_extend(0b1 @ i))

// some architecture and ABI relevant register identifiers
let zreg : regidx = Regidx(zero_extend(0b00)) // x0, zero register
let ra   : regidx = Regidx(zero_extend(0b01)) // x1, return address
let sp   : regidx = Regidx(zero_extend(0b10)) // x2, stack pointer

// base architecture definitions

enum Architecture = {RV32, RV64, RV128}
type arch_xlen = bits(2)

mapping architecture : Architecture <-> arch_xlen = {
  RV32  <-> 0b01,
  RV64  <-> 0b10,
  RV128 <-> 0b11,
  backwards 0b00 => internal_error(__FILE__, __LINE__, "architecture(0b00) is invalid")
}

// nominal privilege levels
type nom_priv_bits = bits(2)

// virtualization modes
type virt_mode_bit = bit

enum Privilege  = {User, VirtualUser, Supervisor, VirtualSupervisor, Machine}

mapping privLevel_bits : (nom_priv_bits, virt_mode_bit) <-> Privilege = {
  (0b00, bitzero) <-> User,
  (0b00, bitone ) <-> VirtualUser,
  (0b01, bitzero) <-> Supervisor,
  (0b01, bitone ) <-> VirtualSupervisor,
  (0b11, bitzero) <-> Machine,
  forwards _       => internal_error(__FILE__, __LINE__, "Invalid privilege level or virtual mode"),
}

function privLevel_to_bits(p : Privilege) -> nom_priv_bits = { let (p, _) = privLevel_bits(p); p }

function privLevel_to_str (p : Privilege) -> string =
  match (p) {
    User              => "U",
    VirtualUser       => "VU",
    Supervisor        => if currentlyEnabled(Ext_H) then "HS" else "S",
    VirtualSupervisor => "VS",
    Machine           => "M"
  }

overload to_str = {privLevel_to_str}

// memory access types

union AccessType ('a : Type) = {
  Read      : 'a,
  Write     : 'a,
  ReadWrite : ('a, 'a),
  InstructionFetch : unit
}

// Some features only affect loads/stores; not instruction fetch.
function is_load_store forall ('a : Type) . (ac : AccessType('a)) -> bool =
  match ac {
    Read(_) => true,
    Write(_) => true,
    ReadWrite(_) => true,
    InstructionFetch(_) => false,
  }

type is_mem_width('w) = 'w in {1, 2, 4, 8}

// architectural interrupt definitions

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

mapping interruptType_bits : InterruptType <-> exc_code = {
  I_U_Software <-> 0b000000, // 0
  I_S_Software <-> 0b000001, // 1
  I_M_Software <-> 0b000011, // 3
  I_U_Timer    <-> 0b000100, // 4
  I_S_Timer    <-> 0b000101, // 5
  I_M_Timer    <-> 0b000111, // 7
  I_U_External <-> 0b001000, // 8
  I_S_External <-> 0b001001, // 9
  I_M_External <-> 0b001011, // 11
}

// architectural exception definitions

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

  // extensions
  E_Extension          : ext_exc_type
}

mapping exceptionType_bits : ExceptionType <-> exc_code = {
  E_Fetch_Addr_Align()   <-> 0b000000, // 0
  E_Fetch_Access_Fault() <-> 0b000001, // 1
  E_Illegal_Instr()      <-> 0b000010, // 2
  E_Breakpoint()         <-> 0b000011, // 3
  E_Load_Addr_Align()    <-> 0b000100, // 4
  E_Load_Access_Fault()  <-> 0b000101, // 5
  E_SAMO_Addr_Align()    <-> 0b000110, // 6
  E_SAMO_Access_Fault()  <-> 0b000111, // 7
  E_U_EnvCall()          <-> 0b001000, // 8
  E_S_EnvCall()          <-> 0b001001, // 9
  E_Reserved_10()        <-> 0b001010, // 10
  E_M_EnvCall()          <-> 0b001011, // 11
  E_Fetch_Page_Fault()   <-> 0b001100, // 12
  E_Load_Page_Fault()    <-> 0b001101, // 13
  E_Reserved_14()        <-> 0b001110, // 14
  E_SAMO_Page_Fault()    <-> 0b001111, // 15

  // extensions
  E_Extension(e)         <-> ext_exc_type_bits(e)
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
    E_SAMO_Addr_Align()    => "misaligned-store/amo",
    E_SAMO_Access_Fault()  => "store/amo-access-fault",
    E_U_EnvCall()          => "u-call",
    E_S_EnvCall()          => "s-call",
    E_Reserved_10()        => "reserved-0",
    E_M_EnvCall()          => "m-call",
    E_Fetch_Page_Fault()   => "fetch-page-fault",
    E_Load_Page_Fault()    => "load-page-fault",
    E_Reserved_14()        => "reserved-1",
    E_SAMO_Page_Fault()    => "store/amo-page-fault",

    // extensions
    E_Extension(e)         => ext_exc_type_to_str(e)
  }

overload to_str = {exceptionType_to_str}

// trap modes

type tv_mode = bits(2)
enum TrapVectorMode = {TV_Direct, TV_Vector, TV_Reserved}

val trapVectorMode_of_bits : tv_mode -> TrapVectorMode
function trapVectorMode_of_bits (m) =
  match (m) {
    0b00 => TV_Direct,
    0b01 => TV_Vector,
    _    => TV_Reserved
  }

// extension context status

type ext_status = bits(2)
enum ExtStatus = {Off, Initial, Clean, Dirty}

mapping extStatus_bits : ExtStatus <-> ext_status = {
  Off     <-> 0b00,
  Initial <-> 0b01,
  Clean   <-> 0b10,
  Dirty   <-> 0b11
}

function extStatus_to_bits(e : ExtStatus) -> ext_status = extStatus_bits(e)
function extStatus_of_bits(b : ext_status) -> ExtStatus = extStatus_bits(b)

// supervisor-level address translation modes

type satp_mode = bits(4)
enum SATPMode = {Bare, Sv32, Sv39, Sv48, Sv57}

function satpMode_of_bits(a : Architecture, m : satp_mode) -> option(SATPMode) =
  match (a, m) {
    (_,    0x0) => Some(Bare),
    (RV32, 0x1) => Some(Sv32),
    (RV64, 0x8) => Some(Sv39),
    (RV64, 0x9) => Some(Sv48),
    (RV64, 0xA) => Some(Sv57),
    (_, _)      => None()
  }

// CSR access control bits (from CSR addresses)

type csrRW = bits(2)  // read/write

// Wait state reasons

enum WaitReason = {WAIT_WFI, WAIT_WRS_STO, WAIT_WRS_NTO}
mapping wait_name : WaitReason <-> string = {
  WAIT_WFI     <-> "WAIT-WFI",
  WAIT_WRS_STO <-> "WAIT-WRS-STO",
  WAIT_WRS_NTO <-> "WAIT-WRS-NTO",
}

overload to_str = {wait_name}

// Width of access for most instructions (load/store, etc.).
type word_width = {1, 2, 4, 8}
// Some instructions allow 128-bit accesses.
type word_width_wide = {1, 2, 4, 8, 16}

// Get the bit encoding of word_width.
mapping width_enc : word_width <-> bits(2) = {
  1 <-> 0b00,
  2 <-> 0b01,
  4 <-> 0b10,
  8 <-> 0b11,
}

mapping width_mnemonic : word_width <-> string = {
  1 <-> "b",
  2 <-> "h",
  4 <-> "w",
  8 <-> "d",
}

// Get the bit encoding of word_width.
mapping width_enc_wide : word_width_wide <-> bits(3) = {
  1  <-> 0b000,
  2  <-> 0b001,
  4  <-> 0b010,
  8  <-> 0b011,
  16 <-> 0b100,
}

mapping width_mnemonic_wide : word_width_wide <-> string = {
  1  <-> "b",
  2  <-> "h",
  4  <-> "w",
  8  <-> "d",
  16 <-> "q",
}
