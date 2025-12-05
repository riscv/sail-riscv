//=======================================================================================
//  This Sail RISC-V architecture model, comprising all files and
//  directories except where otherwise noted is subject the BSD
//  two-clause license in the LICENSE file.
//
//  SPDX-License-Identifier: BSD-2-Clause
//=======================================================================================

type debug_module_reg = bits(8)

// Dxlen is supposed to be mxlen
type dxlen : Int = xlen

type log2_dxlen  : Int = if dxlen == 32 then 5 else 6
type dxlen_bytes : Int = if dxlen == 32 then 4 else 8

let log2_dxlen = sizeof(log2_dxlen)
let dxlen_bytes = sizeof(dxlen_bytes)
let dxlen = sizeof(dxlen)
type dxlenbits = bits(dxlen)

union AbstractCommand = {
  AccessRegister : (bool, bits(16), bits(3), bool, bool), // (write, regno, aarsize, postexec, transfer)
  QuickAccess    : unit,
  MemoryAccess   : (bool, bool, word_width, xlenbits),    // (virtual, write, width, addr)
}

union DebugRequest = {
  Resume : unit,
  Halt   : unit,
  Reset  : bool, // Halt on reset
  AbstractCommand : AbstractCommand,
}

function debug_request_to_string(request : DebugRequest) -> string = {
  match request {
    Resume()                 => "Resume()",
    Halt()                   => "Halt()",
    Reset(halt_on_reset)     => "Reset(haltonreset=" ^ (if halt_on_reset then "true" else "false") ^ ")",
    AbstractCommand(command) => {
      match command {
        AccessRegister(write, regno, aarsize, postexec, transfer) =>
          "RegisterAccess(write=" ^ (if write then "true" else "false") ^
          ", regno=" ^ bits_str(regno) ^
          ", aarsize=" ^ bits_str(aarsize)  ^
          ", postexec=" ^ (if postexec then "true" else "false") ^
          ", transfer=" ^ (if transfer then "true" else "false") ^ ")",
        QuickAccess() => "QuickAccess()",
        MemoryAccess(virtual, write, width, addr) =>
          "MemoryAccess(virtual=" ^ (if virtual then "true" else "false") ^
          ", write=" ^ (if write then "true" else "false") ^
          ", width=" ^ dec_str(width) ^
          ", addr="  ^ bits_str(addr) ^ ")",
      };
    },
  }
}


enum AbstractCommandError = {
  CMDERR_NONE,
  CMDERR_BUSY,
  CMDERR_NOT_SUPPORTED,
  CMDERR_EXCEPTION,
  CMDERR_HALT_RESUME,
  CMDERR_BUS,
  CMDERR_RESERVED,
  CMDERR_OTHER,
}

mapping abstract_command_error : bits(3) <-> AbstractCommandError = {
  0b000 <-> CMDERR_NONE,
  0b001 <-> CMDERR_BUSY,
  0b010 <-> CMDERR_NOT_SUPPORTED,
  0b011 <-> CMDERR_EXCEPTION,
  0b100 <-> CMDERR_HALT_RESUME,
  0b101 <-> CMDERR_BUS,
  0b110 <-> CMDERR_RESERVED,
  0b111 <-> CMDERR_OTHER
}

mapping abstract_command_error_name : AbstractCommandError <-> string = {
  CMDERR_NONE          <-> "NONE",
  CMDERR_BUSY          <-> "BUSY",
  CMDERR_NOT_SUPPORTED <-> "NOT_SUPPORTED",
  CMDERR_EXCEPTION     <-> "EXCEPTION",
  CMDERR_HALT_RESUME   <-> "HALT_RESUME",
  CMDERR_BUS           <-> "BUS",
  CMDERR_RESERVED      <-> "RESERVED",
  CMDERR_OTHER         <-> "OTHER",
}

function abstract_command_error_to_string(error : bits(3)) -> string = abstract_command_error_name(abstract_command_error(error))

// State of the Hart from the Debug Module's point of view
enum DebugHartState = {UNAVAILABLE, RUNNING, HALTED}

enum AbstractCommandType = {
  ACCESS_REGISTER,
  QUICK_ACCESS,
  ACCESS_MEMORY
}

mapping abstract_command_type : int <-> AbstractCommandType = {
  0 <-> ACCESS_REGISTER,
  1 <-> QUICK_ACCESS,
  2 <-> ACCESS_MEMORY,
}

let DM_VERSION : bits(4) = 0b0011
let SB_VERSION : bits(3) = 0b001

// Debug Module register number ranges
let DATA_REG_BASE : bits(8) = 0x04
let DATA_REG_END  : bits(8) = 0x0f
let PROGBUF_BASE  : bits(8) = 0x20
let PROGBUF_END   : bits(8) = 0x2f

// Register number ranges
let REGNO_CSR_MAX   : bits(16) = 0x0fff
let REGNO_GPR_BASE  : bits(16) = 0x1000
let REGNO_GPR_MAX   : bits(16) = 0x101f
let REGNO_FPR_BASE  : bits(16) = 0x1020
let REGNO_FPR_MAX   : bits(16) = 0x103f

// Abstract command argument indices
let ARG0 : range(0, 2) = 0
let ARG1 : range(0, 2) = 1
let ARG2 : range(0, 2) = 2

let EBREAK_INSTRUCTION   : bits(32) = 0x00100073
let C_EBREAK_INSTRUCTION : bits(16) = 0x9002

// Platform configuration
let MAX_DATA_SIZE    : bits(4) = to_bits_truncate(config platform.debug_module.num_data_reg : int)
let MAX_PROGBUF_SIZE : bits(5) = to_bits_truncate(config platform.debug_module.num_prog_reg : int)

struct debug_module_hart_status = {
  running  : bool,
  halted   : bool,
  havereset: bool,
}

bitfield Dmstatus : bits(32) = {
  ndmresetpending: 24,
  stickyunavail:   23,
  impebreak:       22,
  allhavereset:    19,
  anyhavereset:    18,
  allresumeack:    17,
  anyresumeack:    16,
  allnonexistent:  15,
  anynonexistent:  14,
  allunavail:      13,
  anyunavail:      12,
  allrunning:      11,
  anyrunning:      10,
  allhalted:        9,
  anyhalted:        8,
  authenticated:    7,
  authbusy:         6,
  hasresethaltreq:  5,
  confstrptrvalid:  4,
  version:          3 .. 0
}

bitfield Abstractcs : bits(32) = {
  progbufsize : 28 .. 24,
  busy :        12,
  relaxedpriv:  11,
  cmderr:       10 .. 8,
  datacount:     3 .. 0
}

bitfield Command : bits(32) = {
  cmdtype: 31 .. 24,
  control: 23 .. 0
}

bitfield Abstractauto : bits(32) = {
  autoexecprogbuf: 31 .. 16,
  autoexecdata:    11 ..  0,
}

bitfield Dmcontrol : bits(32) = {
  haltreq :        31,
  resumereq:       30,
  hartreset:       29,
  ackhavereset:    28,
  ackunavail:      27,
  hasel:           26,
  hartsello:       25 .. 16,
  hartselhi:       15 ..  6,
  setkeepalive:    5,
  clrkeepalive:    4,
  setresethaltreq: 3,
  clrresethaltreq: 2,
  ndmreset:        1,
  dmactive:        0
}

bitfield Hartinfo : bits(32) = {
  nscratch:   23 .. 20,
  dataaccess: 16,
  datasize:   15 .. 12,
  dataaddr:   11 .. 0
}

bitfield Haltsum0 : bits(32) = {
  haltsum0: 31 .. 0
}

bitfield Haltsum1 : bits(32) = {
  haltsum1: 31 .. 0
}

bitfield Haltsum2 : bits(32) = {
  haltsum2: 31 .. 0
}

bitfield Haltsum3 : bits(32) = {
  haltsum3: 31 .. 0
}

bitfield Hawindowsel : bits(32) = {
  hawindowsel : 14 .. 0,
}

bitfield Hawindow : bits(32) = {
  maskdata : 31 .. 0,
}

bitfield Confstrptr0 : bits(32) = {
  addr : 31 .. 0
}

bitfield Confstrptr1 : bits(32) = {
  addr: 31 .. 0
}

bitfield Confstrptr2 : bits(32) = {
  addr: 31 .. 0
}

bitfield Confstrptr3 : bits(32) = {
  addr: 31 .. 0
}

bitfield Nextdm : bits(32) = {
  addr: 31 .. 0
}

bitfield Authdata : bits(32) = {
  data: 31 .. 0
}

bitfield Dmcs2 : bits(32) = {
  grouptype:    11,
  dmexttrigger: 10 .. 7,
  group:        6  .. 2,
  hgwrite:      1,
  hgselect:     0
}

bitfield Sbcs : bits(32) = {
  sbversion:       31 .. 29,
  sbbusyerror:     22,
  sbbusy:          21,
  sbreadonaddr:    20,
  sbaccess:        19 .. 17,
  sbautoincrement: 16,
  sbreadondata:    15,
  sberror:         14 .. 12,
  sbasize:         11 .. 5,
  sbaccess128:     4,
  sbaccess64:      3,
  sbaccess32:      2,
  sbaccess16:      1,
  sbaccess8 :      0
}

bitfield Sbaddress0 : bits(32) = {
  address: 31 .. 0
}

bitfield Sbaddress1 : bits(32) = {
  address: 31 .. 0
}

bitfield Sbaddress2 : bits(32) = {
  address: 31 .. 0
}

bitfield Sbaddress3 : bits(32) = {
  address: 31 .. 0
}

bitfield Sbdata0 : bits(32) = {
  data: 31 .. 0
}

bitfield Sbdata1 : bits(32) = {
  data: 31 .. 0
}

bitfield Sbdata2 : bits(32) = {
  data: 31 .. 0
}

bitfield Sbdata3 : bits(32) = {
  data: 31 .. 0
}
