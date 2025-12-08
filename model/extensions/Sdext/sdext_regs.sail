//=======================================================================================
//  This Sail RISC-V architecture model, comprising all files and
//  directories except where otherwise noted is subject the BSD
//  two-clause license in the LICENSE file.
//
//  SPDX-License-Identifier: BSD-2-Clause
//=======================================================================================

register debug_state : DebugState = Debug_Inactive()

function in_debug_mode() -> bool = {
  match debug_state {
    Debug_Active(_) => true,
    Debug_Inactive() => false,
  }
}

function clause currentlyEnabled(Ext_Sdext) = hartSupports(Ext_Sdext) & currentlyEnabled(Ext_Zicsr) & in_debug_mode()

// Other configuration elements.
let dcsr_stepie_writable          : bool = hartSupports(Ext_Sdext) & config extensions.Sdext.writable_stepie
let dcsr_stopcount_preset_enabled : bool = hartSupports(Ext_Sdext) & config extensions.Sdext.stopcount.preset_value
let dcsr_stopcount_writable       : bool = hartSupports(Ext_Sdext) & config extensions.Sdext.stopcount.writable
let dcsr_mprven_preset_enabled    : bool = hartSupports(Ext_Sdext) & config extensions.Sdext.mprven.preset_value
let dcsr_mprven_writable          : bool = hartSupports(Ext_Sdext) & config extensions.Sdext.mprven.writable

mapping clause csr_name_map = 0x7b0  <-> "dcsr"
mapping clause csr_name_map = 0x7b1  <-> "dpc"
mapping clause csr_name_map = 0x7b2  <-> "dscratch0"
mapping clause csr_name_map = 0x7b3  <-> "dscratch1"

bitfield Dcsr : bits(32) = {
  Debugver  : 31 .. 28,
  ExtCause  : 26 .. 24,
  CETrig    : 19,
  Pelp      : 18,
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
    Pelp      = 0b0,
    EBreakVS  = 0b0,
    EBreakVU  = 0b0,
    EBreakM   = 0b0,
    EBreakS   = 0b0,
    EBreakU   = 0b0,
    StepIE    = 0b0,
    StopCount = bool_bits(dcsr_stopcount_preset_enabled),
    StopTime  = 0b0, // TODO: add config for this
    Cause     = debug_cause_bits(DBGEntry_None),
    V         = 0b0,
    MPRVEn    = bool_bits(dcsr_mprven_preset_enabled),
    NMIP      = 0b0,
    Step      = 0b0,
    Prv       = privLevel_to_bits(Machine),
  ]
}

register dcsr : Dcsr
register dpc       : dxlenbits
register dscratch0 : dxlenbits
register dscratch1 : dxlenbits

register dtime : bits(64)

function clause is_CSR_accessible(0x7b0, _, _) = currentlyEnabled(Ext_Sdext)
function clause is_CSR_accessible(0x7b1, _, _) = currentlyEnabled(Ext_Sdext)
function clause is_CSR_accessible(0x7b2, _, _) = currentlyEnabled(Ext_Sdext)
function clause is_CSR_accessible(0x7b3, _, _) = currentlyEnabled(Ext_Sdext)

function clause read_CSR(0x7b0) = zero_extend(dcsr.bits)
function clause read_CSR(0x7b1) = dpc
function clause read_CSR(0x7b2) = dscratch0
function clause read_CSR(0x7b3) = dscratch1

function legalize_dcsr(d : Dcsr, v : xlenbits) -> Dcsr = {
 let v = Mk_Dcsr(v[31 .. 0]);
 [d with
   Pelp      = if hartSupports(Ext_Zicfilp) then v[Pelp] else 0b0,
   EBreakM   = v[EBreakM],
   EBreakS   = if hartSupports(Ext_S) then v[EBreakS] else 0b0,
   EBreakU   = if hartSupports(Ext_U) then v[EBreakU] else 0b0,
   StepIE    = if dcsr_stepie_writable then v[StepIE] else d[StepIE],
   StopCount = if dcsr_stopcount_writable then v[StopCount] else d[StopCount],
   MPRVEn    = if dcsr_mprven_writable then v[MPRVEn] else d[MPRVEn],
   Step      = v[Step],
   Prv       = if have_nominal_privLevel(v[Prv]) then v[Prv] else d[Prv],
  ]
}

function clause write_CSR(0x7b0, value) = { dcsr = legalize_dcsr(dcsr, value); Ok(zero_extend(dcsr.bits)) }
function clause write_CSR(0x7b1, value) = { dpc = legalize_xepc(value); Ok(dpc) }
function clause write_CSR(0x7b2, value) = { dscratch0 = value; Ok(dscratch0) }
function clause write_CSR(0x7b3, value) = { dscratch1 = value; Ok(dscratch1) }
