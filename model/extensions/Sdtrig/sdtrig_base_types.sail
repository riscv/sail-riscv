// =======================================================================================
// This Sail RISC-V architecture model, comprising all files and
// directories except where otherwise noted is subject the BSD
// two-clause license in the LICENSE file.
//
// SPDX-License-Identifier: BSD-2-Clause
// =======================================================================================

// Trigger field types and encodings

enum Trig_Type = {
  TT_none,         // no trigger
  TT_legacy,
  TT_mcontrol,     // address/data match (deprecated)
  TT_icount,       // instruction count
  TT_itrigger,     // interrupt
  TT_etrigger,     // exception
  TT_mcontrol6,    // address/data match
  TT_tmexttrigger, // external
  TT_custom,
  TT_disabled,
  TT_reserved,
}

mapping trig_type_bits : bits(4) <-> Trig_Type = {
  0b0000 <-> TT_none,
  0b0001 <-> TT_legacy,
  0b0010 <-> TT_mcontrol,
  0b0011 <-> TT_icount,
  0b0100 <-> TT_itrigger,
  0b0101 <-> TT_etrigger,
  0b0110 <-> TT_mcontrol6,
  0b0111 <-> TT_tmexttrigger,
  0b1111 <-> TT_disabled,
  forwards 0b1100 => TT_custom,
  forwards 0b1101 => TT_custom,
  forwards 0b1110 => TT_custom,
  forwards 0b1000 => TT_reserved,
  forwards 0b1001 => TT_reserved,
  forwards 0b1010 => TT_reserved,
  forwards 0b1011 => TT_reserved,
}

mapping trig_type_name : Trig_Type <-> string = {
  TT_none         <-> "none",
  TT_legacy       <-> "legacy",
  TT_mcontrol     <-> "mcontrol",
  TT_icount       <-> "icount",
  TT_itrigger     <-> "itrigger",
  TT_etrigger     <-> "etrigger",
  TT_mcontrol6    <-> "mcontrol6",
  TT_tmexttrigger <-> "tmexttrigger",
  TT_custom       <-> "custom",
  TT_disabled     <-> "disabled",
  TT_reserved     <-> "reserved",
}

function is_supported_trigger_type(tt : bits(4)) -> bool = {
  if not(trig_type_bits_forwards_matches(tt)) then return false;
  let typ = trig_type_bits(tt);
  (typ == TT_none) | (typ == TT_disabled) |
  (typ == TT_icount & sdtrig_has_icount) |
  (typ == TT_etrigger & sdtrig_has_etrigger) |
  (typ == TT_itrigger & sdtrig_has_itrigger) |
  (typ == TT_mcontrol6 & sdtrig_has_mcontrol6)
}

function supported_triggers_info() -> bits(16) = {
  let flag = zero_extend(16, 0b1);
  // the model disables triggers via type 15, so it is always supported
  var info : bits(16) = flag << unsigned(trig_type_bits(TT_disabled));
  if sdtrig_has_icount
  then info = info | (flag << unsigned(trig_type_bits(TT_icount)));
  if sdtrig_has_etrigger
  then info = info | (flag << unsigned(trig_type_bits(TT_etrigger)));
  if sdtrig_has_itrigger
  then info = info | (flag << unsigned(trig_type_bits(TT_itrigger)));
  if sdtrig_has_mcontrol6
  then info = info | (flag << unsigned(trig_type_bits(TT_mcontrol6)));
  info
}

enum Trig_Action = {
  TA_Breakpoint, TA_Enter_Debug, TA_Trace_On, TA_Trace_Off,
  TA_Trace_Notify, TA_Ext_Trigger_0, TA_Ext_Trigger_1,
}

// The `action` fields are 4 bits in `mcontrol` (deprecated) and
// `mcontrol6`, and 6 bits in `icount`, `itrigger`, `etrigger`, and
// `tmexttrigger`.  The mapping uses the wider 6 bits to ensure that
// reserved 6-bit values don't alias into defined 4-bit values.
mapping trig_action : bits(6) <-> Trig_Action = {
  0b000000 <-> TA_Breakpoint,
  0b000001 <-> TA_Enter_Debug,
  0b000010 <-> TA_Trace_On,
  0b000011 <-> TA_Trace_Off,
  0b000100 <-> TA_Trace_Notify,
  0b001000 <-> TA_Ext_Trigger_0,
  0b001001 <-> TA_Ext_Trigger_1,
}

mapping trigger_action_name : Trig_Action <-> string = {
  TA_Breakpoint    <-> "Breakpoint",
  TA_Enter_Debug   <-> "Enter Debug",
  TA_Trace_On      <-> "Trace On",
  TA_Trace_Off     <-> "Trace Off",
  TA_Trace_Notify  <-> "Trace Notify",
  TA_Ext_Trigger_0 <-> "External Trigger Output 0",
  TA_Ext_Trigger_1 <-> "External Trigger Output 1",
}

function is_supported_action(a : bits(6)) -> bool = {
  if not(trig_action_forwards_matches(a)) then return false;
  let act = trig_action(a) in
  act == TA_Breakpoint // | (currentlyEnabled(Ext_Sdext) & (act == TA_Enter_Debug))
}

enum Hit = {Hit_false, Hit_before, Hit_after, Hit_imm_after}

mapping hit_bits : bits(2) <-> Hit = {
  0b00 <-> Hit_false,
  0b01 <-> Hit_before,
  0b10 <-> Hit_after,
  0b11 <-> Hit_imm_after,
}

mapping hit_name : Hit <-> string = {
  Hit_false     <-> "not-hit",
  Hit_before    <-> "hit-before",
  Hit_after     <-> "hit-after",
  Hit_imm_after <-> "hit-imm-after",
}

enum Compare_Selection = {Compare_Address, Compare_Data}

mapping compare_select_bits : bits(1) <-> Compare_Selection = {
  0b0 <-> Compare_Address,
  0b1 <-> Compare_Data,
}

type Trig_Match_Size = {0, 8, 16, 32, 48, 64, 128}

mapping trig_match_size : bits(3) <-> Trig_Match_Size = {
  0b000 <-> 0,
  0b001 <-> 8,
  0b010 <-> 16,
  0b011 <-> 32,
  0b100 <-> 48,
  0b101 <-> 64,
  0b110 <-> 128,
}

enum Trig_Match = {
  TM_EQ, TM_NAPOT, TM_GE, TM_LT, TM_MASK_LO, TM_MASK_HI,
  TM_NEQ, TM_NOT_NAPOT, TM_NOT_MASK_LO, TM_NOT_MASK_HI,
}

mapping trig_match_val : bits(4) <-> Trig_Match = {
  0b0000 <-> TM_EQ,
  0b0001 <-> TM_NAPOT,
  0b0010 <-> TM_GE,
  0b0011 <-> TM_LT,
  0b0100 <-> TM_MASK_LO,
  0b0101 <-> TM_MASK_HI,
  0b1000 <-> TM_NEQ,
  0b1001 <-> TM_NOT_NAPOT,
  0b1100 <-> TM_NOT_MASK_LO,
  0b1101 <-> TM_NOT_MASK_HI,
}

function is_supported_match_val(m : bits(4)) -> bool =
  // TODO: config options
  trig_match_val_forwards_matches(m)

// If `num_triggers` is zero, there is no valid index.
type trigger_index = range(0, num_triggers - 1)
