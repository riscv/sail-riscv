// =======================================================================================
// This Sail RISC-V architecture model, comprising all files and
// directories except where otherwise noted is subject the BSD
// two-clause license in the LICENSE file.
//
// SPDX-License-Identifier: BSD-2-Clause
// =======================================================================================

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

// Pending debug request to be processed
register pending_debug_request : option(DebugRequest) = None()

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
