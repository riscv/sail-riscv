//=======================================================================================
//  This Sail RISC-V architecture model, comprising all files and
//  directories except where otherwise noted is subject the BSD
//  two-clause license in the LICENSE file.
//
//  SPDX-License-Identifier: BSD-2-Clause
//=======================================================================================

// Conceptual bits of hart state
register haltonreset : bool = false

// Pending debug request to be processed
register pending_debug_request : option(DebugRequest) = None()

// Program buffer execution active
register progbuf_active : bool = false

register pending_cmderr_busy : bool = false

// Debug Module Registers

function initialize_dmstatus() -> Dmstatus = {
  [Mk_Dmstatus(zeros()) with
    impebreak = if unsigned(MAX_PROGBUF_SIZE) == 1 | (config platform.debug_module.impebreak : bool) then 0b1 else 0b0,
    // NOTE: OpenOCD expects the hart to be in a defined state (running or halted).
    allrunning = 0b1,
    anyrunning = 0b1,
    // NOTE: This needs to be enabled because otherwise
    // OpenOCD will not continue after failed authentication
    // TODO: Make this optional
    authenticated   = 0b1,
    // TODO: Make this optional
    hasresethaltreq = 0b1,
    // Version 1.0
    version         = DM_VERSION
  ]
}

register dmstatus     : Dmstatus = initialize_dmstatus()

function initialize_abstractcs() -> Abstractcs = {
  [Mk_Abstractcs(zeros()) with
    progbufsize = MAX_PROGBUF_SIZE,
    // TODO: Add support for relaxed permission check
    relaxedpriv = 0b0,
    datacount   = MAX_DATA_SIZE,
  ]
}

register abstractcs   : Abstractcs   = initialize_abstractcs()
register command      : Command      = Mk_Command(zeros())
register abstractauto : Abstractauto = Mk_Abstractauto(zeros())
register dmcontrol    : Dmcontrol    = Mk_Dmcontrol(zeros())

register data_regs    : vector(12, bits(32)) = vector_init(zeros())
register progbuf_regs : vector(16, bits(32)) = vector_init(EBREAK_INSTRUCTION)

register hartinfo     : Hartinfo     = Mk_Hartinfo(zeros())

register haltsum0     : Haltsum0     = Mk_Haltsum0(zeros())
register haltsum1     : Haltsum1     = Mk_Haltsum1(zeros())
register haltsum2     : Haltsum2     = Mk_Haltsum2(zeros())
register haltsum3     : Haltsum3     = Mk_Haltsum3(zeros())

register hawindowsel  : Hawindowsel  = Mk_Hawindowsel(zeros())
register hawindow     : Hawindow     = Mk_Hawindow(zeros())

register confstrptr0  : Confstrptr0  = Mk_Confstrptr0(zeros())
register confstrptr1  : Confstrptr1  = Mk_Confstrptr1(zeros())
register confstrptr2  : Confstrptr2  = Mk_Confstrptr2(zeros())
register confstrptr3  : Confstrptr3  = Mk_Confstrptr3(zeros())

register nextdm       : Nextdm       = Mk_Nextdm(zeros())

register authdata     : Authdata     = Mk_Authdata(zeros())
register dmcs2        : Dmcs2        = Mk_Dmcs2(zeros())

function initialize_Sbcs() -> Sbcs = {
  [Mk_Sbcs(zeros()) with
    sbversion = SB_VERSION,
    sbaccess = 0b010,
    sbasize = zeros(),
  ]
}

register sbcs         : Sbcs         = initialize_Sbcs()
register sbaddress0   : Sbaddress0   = Mk_Sbaddress0(zeros())
register sbaddress1   : Sbaddress1   = Mk_Sbaddress1(zeros())
register sbaddress2   : Sbaddress2   = Mk_Sbaddress2(zeros())
register sbaddress3   : Sbaddress3   = Mk_Sbaddress3(zeros())
register sbdata0      : Sbdata0      = Mk_Sbdata0(zeros())
register sbdata1      : Sbdata1      = Mk_Sbdata1(zeros())
register sbdata2      : Sbdata2      = Mk_Sbdata2(zeros())
register sbdata3      : Sbdata3      = Mk_Sbdata3(zeros())

// Forward declaration so the implementation can be defined after all registers
val reset_debug_module : unit -> unit

// Mapping of Debug Module Register addresses to their names
val debug_module_reg_name_map : debug_module_reg <-> string
scattered mapping debug_module_reg_name_map

val debug_module_reg_name : debug_module_reg -> string
function debug_module_reg_name(addr) = debug_module_reg_name_map(addr)

overload to_str = {debug_module_reg_name}

// Returns whether a Debug Module Register exists
val is_debug_module_reg_defined : (debug_module_reg) -> bool
scattered function is_debug_module_reg_defined

// Returns the value of the Debug Module Register if it is defined
val read_debug_module_reg : debug_module_reg -> bits(32)
scattered function read_debug_module_reg

// If the Debug Module Register is defined, writes the legalized value to it
val write_debug_module_reg : (debug_module_reg, bits(32)) -> unit
scattered function write_debug_module_reg
