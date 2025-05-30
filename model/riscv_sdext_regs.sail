/*=======================================================================================*/
/*  This Sail RISC-V architecture model, comprising all files and                        */
/*  directories except where otherwise noted is subject the BSD                          */
/*  two-clause license in the LICENSE file.                                              */
/*                                                                                       */
/*  SPDX-License-Identifier: BSD-2-Clause                                                */
/*=======================================================================================*/

/* Debug mode extension Sdext: registers */

/* Sdext : Debug mode */

/* model-internal state */
register debug_mode_active : bool = false
register debug_abstract_command_active : bool = false
register debug_abstract_command_error  : bool = false

function clause currentlyEnabled(Ext_Sdext) = hartSupports(Ext_Sdext) & debug_mode_active

// Defined with type `xlenbits` since it needs to be a return value of `trap_handler`.
register debug_mem_base : physaddrbits = zeros()

let debug_mem_size : nat =
  if   hartSupports(Ext_Sdext)
  then config extensions.Sdext.mem_size
  else 0

// When traps occur when executing an abstract command, control transfers to this
// address in the debugger's memory.  It has type xlenbits to be compatible with
// the return type of `trap_handler()`.
register debug_trap_vector : xlenbits = zeros()

// Checked conversions are not pure and cannot be used to initialize top-level
// values; hence, registers are used for these values, with initialization
// effected through this function.
function init_sdext() -> unit =
  if hartSupports(Ext_Sdext) then {
    debug_mem_base = to_bits_checked(config extensions.Sdext.mem_base : nat);
    debug_trap_vector = to_bits_checked(config extensions.Sdext.trap_vector : int);
  }

// Other configuration elements.
let writable_dcsr_stepie : bool =
  if   hartSupports(Ext_Sdext)
  then config extensions.Sdext.writable_stepie
  else false
let preset_dcsr_stopcount : bool =
  if   hartSupports(Ext_Sdext)
  then config extensions.Sdext.stopcount.preset_value
  else false
let writable_dcsr_stopcount : bool =
  if   hartSupports(Ext_Sdext)
  then config extensions.Sdext.stopcount.writable
  else false
let preset_dcsr_mprven : bool =
  if   hartSupports(Ext_Sdext)
  then config extensions.Sdext.mprven.preset_value
  else false
let writable_dcsr_mprven : bool =
  if   hartSupports(Ext_Sdext)
  then config extensions.Sdext.mprven.writable
  else false


mapping clause csr_name_map = 0x7b0  <-> "dcsr"
mapping clause csr_name_map = 0x7b1  <-> "dpc"
mapping clause csr_name_map = 0x7b2  <-> "dscratch0"
mapping clause csr_name_map = 0x7b3  <-> "dscratch1"

bitfield Dcsr : bits(32) = {
  Debugver  : 31 .. 28,
  ExtCause  : 26 .. 24,
  CETrig    : 19,
  PELP      : 18,
  EBreakVS  : 17,
  EBreakVU  : 16,
  EBreakM   : 15,
  EBreakS   : 13,
  EBreakU   : 12,
  StepIE    : 11,
  StopCount : 10,
  StopTime  : 9,
  Cause     : 8 .. 6,
  V         : 5,
  MPRVEn    : 4,
  NMIP      : 3,
  Step      : 2,
  Prv       : 1 .. 0,
}

function reset_Dcsr() -> Dcsr = {
  [ Mk_Dcsr(zeros()) with
    Debugver  = 0b0100,  // Sdext as per Debug Spec v1.0
    ExtCause  = zeros(),
    CETrig    = 0b0,
    PELP      = 0b0,
    EBreakVS  = 0b0,
    EBreakVU  = 0b0,
    EBreakM   = 0b0,
    EBreakS   = 0b0,
    EBreakU   = 0b0,
    StepIE    = 0b0,
    StopCount = bool_bits(preset_dcsr_stopcount),
    StopTime  = 0b0, // TODO: add config for this
    Cause     = debug_cause_bits(DBGEntry_None),
    V         = 0b0,
    MPRVEn    = bool_bits(preset_dcsr_mprven),
    NMIP      = 0b0,
    Step      = 0b0,
    Prv       = privLevel_bits(Machine),
  ]
}

register dcsr : Dcsr = reset_Dcsr()

// The below three registers are specified to be DXLEN bits wide,
// which is the widest XLEN supported by a hart, ignoring misa[MXL].
// For now, these just use xlenbits.  These registers do not have
// specified reset values.
register dpc       : xlenbits
register dscratch0 : xlenbits
register dscratch1 : xlenbits

// Internal register tracking the mtime when Debug Mode was entered.
register dtime : bits(64) = zeros()

function clause is_CSR_defined(0x7b0) = currentlyEnabled(Ext_Sdext)
function clause is_CSR_defined(0x7b1) = currentlyEnabled(Ext_Sdext)
function clause is_CSR_defined(0x7b2) = currentlyEnabled(Ext_Sdext)
function clause is_CSR_defined(0x7b3) = currentlyEnabled(Ext_Sdext)

function clause read_CSR(0x7b0) = zero_extend(dcsr.bits)
function clause read_CSR(0x7b1) = dpc
function clause read_CSR(0x7b2) = dscratch0
function clause read_CSR(0x7b3) = dscratch1

function legalize_dcsr(d : Dcsr, v : xlenbits) -> Dcsr = {
 let v = Mk_Dcsr(v[31 .. 0]);
 [d with
   // CETrig   = if hartSupports(Ext_Smdbltrp) then v[CETrig] else 0b0,
   // PELP     = if hartSupports(Ext_Zicfilp)  then v[PELP]   else 0b0,
   // EBreakVS = ...
   // EBreakVU = ...
   EBreakM   = v[EBreakM],
   EBreakS   = if hartSupports(Ext_S) then v[EBreakS] else 0b0,
   EBreakU   = if hartSupports(Ext_U) then v[EBreakU] else 0b0,
   StepIE    = if writable_dcsr_stepie then v[StepIE] else d[StepIE],
   StopCount = if writable_dcsr_stopcount then v[StopCount] else d[StopCount],
   // V = ...
   MPRVEn    = if writable_dcsr_mprven then v[MPRVEn] else d[MPRVEn],
   Step      = v[Step],
   Prv       = if have_privLevel(v[Prv]) then v[Prv] else d[Prv],
  ]
}

function clause write_CSR(0x7b0, value) = { dcsr = legalize_dcsr(dcsr, value); zero_extend(dcsr.bits) }
function clause write_CSR(0x7b1, value) = { dpc = legalize_xepc(value); dpc }
function clause write_CSR(0x7b2, value) = { dscratch0 = value; dscratch0 }
function clause write_CSR(0x7b3, value) = { dscratch1 = value; dscratch1 }

function in_debug_abstract_command() -> bool =
  currentlyEnabled(Ext_Sdext) & debug_abstract_command_active

// The hart is resumed when single stepping, so debug_mode_active is false.
// This function hence uses hartSupports() instead of currentlyEnabled().
function in_single_step() -> bool =
  hartSupports(Ext_Sdext) & bool_bits(dcsr[Step])
