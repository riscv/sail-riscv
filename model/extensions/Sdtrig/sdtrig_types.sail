// =======================================================================================
// This Sail RISC-V architecture model, comprising all files and
// directories except where otherwise noted is subject the BSD
// two-clause license in the LICENSE file.
//
// SPDX-License-Identifier: BSD-2-Clause
// =======================================================================================

// Trigger field types and encodings
enum Trig_Type = {
  TT_none,       // no trigger
  TT_legacy,
  TT_mcontrol,   // address/data match (deprecated)
  TT_icount,     // instruction count
  TT_itrigger,   // interrupt
  TT_etrigger,   // exception
  TT_mcontrol6,  // address/data match
  TT_exttrigger, // external
  TT_custom,
  TT_disabled,
  TT_reserved,
}

mapping trig_type : bits(4) <-> Trig_Type = {
  0b0000 <-> TT_none,
  0b0001 <-> TT_legacy,
  0b0010 <-> TT_mcontrol,
  0b0011 <-> TT_icount,
  0b0100 <-> TT_itrigger,
  0b0101 <-> TT_etrigger,
  0b0110 <-> TT_mcontrol6,
  0b0111 <-> TT_exttrigger,
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
  TT_none       <-> "none",
  TT_legacy     <-> "legacy",
  TT_mcontrol   <-> "mcontrol",
  TT_icount     <-> "icount",
  TT_itrigger   <-> "itrigger",
  TT_etrigger   <-> "etrigger",
  TT_mcontrol6  <-> "mcontrol6",
  TT_exttrigger <-> "exttrigger",
  TT_custom     <-> "custom",
  TT_disabled   <-> "disabled",
  TT_reserved   <-> "reserved",
}

function is_supported_trigger_type(tt : bits(4)) -> bool = {
  if not(trig_type_forwards_matches(tt)) then return false;
  let typ = trig_type(tt);
  (typ == TT_icount & sdtrig_has_icount) |
  (typ == TT_etrigger & sdtrig_has_etrigger) |
  (typ == TT_itrigger & sdtrig_has_itrigger)
}

function supported_triggers_info() -> bits(16) = {
  var info : bits(16) = zeros();
  let flag = zero_extend(16, 0b1);
  if sdtrig_has_icount
  then info = info | (flag << unsigned(trig_type(TT_icount)));
  if sdtrig_has_etrigger
  then info = info | (flag << unsigned(trig_type(TT_etrigger)));
  if sdtrig_has_itrigger
  then info = info | (flag << unsigned(trig_type(TT_itrigger)));
  info
}

enum Trig_Action = {
  TA_Breakpoint, TA_Enter_Debug, TA_Trace_On, TA_Trace_Off,
  TA_Trace_Notify, TA_Ext_Trigger_0, TA_Ext_Trigger_1,
}

mapping trig_action : bits(4) <-> Trig_Action = {
  0b0000 <-> TA_Breakpoint,
  0b0001 <-> TA_Enter_Debug,
  0b0010 <-> TA_Trace_On,
  0b0011 <-> TA_Trace_Off,
  0b0100 <-> TA_Trace_Notify,
  0b1000 <-> TA_Ext_Trigger_0,
  0b1001 <-> TA_Ext_Trigger_1,
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

function is_supported_action(a : bits(4)) -> bool = {
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

// Trigger types and their layouts.
//
// Each trigger has an associated struct and a bitfield.  The struct
// is used for efficient trigger matching and action handling, while
// the bitfield is used for the serialization and deserialization needed
// to handle reads and writes to the tdatax registers.  The expectation
// is that the former happens much more often than the latter.
struct TDisabled = {
  dmode  : bool,
  data   : bits(xlen - 5),
  tdata2 : xlenbits,
  tdata3 : xlenbits,
}

bitfield TDisabled_bits : xlenbits = {
  trig_type : xlen - 1 .. xlen - 4,
  dmode     : xlen - 5,
  data      : xlen - 6 .. 0,
}

function TDisabled_to_bits(t : TDisabled) -> TDisabled_bits =
  [Mk_TDisabled_bits(zeros()) with
    trig_type = trig_type(TT_disabled),
    dmode = bool_bit(t.dmode),
    data  = t.data
  ]

struct MControl6 = {
  dmode      : bool,
  uncertain  : bool,
  hit        : Hit,
  vs         : bool,
  vu         : bool,
  select     : bool,
  size       : Trig_Match_Size,
  action     : Trig_Action,
  chain      : bool,
  t_match    : Trig_Match,
  m          : bool,
  uncertainm : bool,
  s          : bool,
  u          : bool,
  execute    : bool,
  store      : bool,
  load       : bool,
  tdata2     : xlenbits,
  tdata3     : xlenbits,
}

bitfield MControl6_bits : xlenbits = {
  trig_type     : xlen - 1 .. xlen - 4,
  dmode         : xlen - 5,
  uncertain     : 26,
  hit1          : 25,
  vs            : 24,
  vu            : 23,
  hit0          : 22,
  select        : 21,
  size          : 18 .. 16,
  action        : 15 .. 12,
  chain         : 11,
  t_match       : 10 .. 7,
  m             : 6,
  uncertainm    : 5,
  s             : 4,
  u             : 3,
  execute       : 2,
  store         : 1,
  load          : 0,
}

function MControl6_to_bits(t : MControl6) -> MControl6_bits =
  let hit = hit_bits(t.hit) in
  [Mk_MControl6_bits(zeros()) with
    trig_type  = trig_type(TT_mcontrol6),
    dmode      = bool_bit(t.dmode),
    uncertain  = bool_bit(t.uncertain),
    hit1       = [hit[1]],
    vs         = bool_bit(t.vs),
    vu         = bool_bit(t.vu),
    hit0       = [hit[0]],
    select     = bool_bit(t.select),
    size       = trig_match_size(t.size),
    action     = trig_action(t.action),
    chain      = bool_bit(t.chain),
    t_match    = trig_match_val(t.t_match),
    m          = bool_bit(t.m),
    uncertainm = bool_bit(t.uncertainm),
    s          = bool_bit(t.s),
    u          = bool_bit(t.u),
    execute    = bool_bit(t.execute),
    store      = bool_bit(t.store),
    load       = bool_bit(t.load),
  ]

let icount_count_is_hardwired_one : bool = config extensions.Sdtrig.icount.count_hardwired_one

struct ICount = {
  dmode      : bool,
  vs         : bool,
  vu         : bool,
  hit        : bool,
  count      : bits(14),
  m          : bool,
  pending    : bool,
  s          : bool,
  u          : bool,
  action     : Trig_Action,
  tdata2     : xlenbits,
  tdata3     : xlenbits,
}

bitfield ICount_bits : xlenbits = {
  trig_type : xlen - 1 .. xlen - 4,
  dmode     : xlen - 5,
  vs        : 26,
  vu        : 25,
  hit       : 24,
  count     : 23 .. 10,
  m         : 9,
  pending   : 8,
  s         : 7,
  u         : 6,
  action    : 5 .. 0,
}

function ICount_to_bits(t : ICount) -> ICount_bits =
  [Mk_ICount_bits(zeros()) with
    trig_type = trig_type(TT_icount),
    dmode     = bool_bit(t.dmode),
    vs        = bool_bit(t.vs),
    vu        = bool_bit(t.vu),
    hit       = bool_bit(t.hit),
    count     = t.count,
    m         = bool_bit(t.m),
    pending   = bool_bit(t.pending),
    s         = bool_bit(t.s),
    u         = bool_bit(t.u),
    action    = zero_extend(trig_action(t.action)),
  ]

struct ITrigger = {
  dmode      : bool,
  hit        : bool,
  vs         : bool,
  vu         : bool,
  nmi        : bool,
  m          : bool,
  s          : bool,
  u          : bool,
  action     : Trig_Action,
  tdata2     : xlenbits,
  tdata3     : xlenbits,
  match_val  : option(InterruptType),
}

struct ETrigger = {
  dmode      : bool,
  hit        : bool,
  vs         : bool,
  vu         : bool,
  m          : bool,
  s          : bool,
  u          : bool,
  action     : Trig_Action,
  tdata2     : xlenbits,
  tdata3     : xlenbits,
  match_val  : option(ExceptionType),
}

bitfield IETrigger_bits : xlenbits = {
  trig_type : xlen - 1 .. xlen - 4,
  dmode     : xlen - 5,
  hit       : xlen - 6,
  vs        : 12,
  vu        : 11,
  nmi       : 10, // zeroed in etrigger
  m         : 9,
  s         : 7,
  u         : 6,
  action    : 5 .. 0,
}

function ITrigger_to_bits(t : ITrigger) -> IETrigger_bits =
 [Mk_IETrigger_bits(zeros()) with
   trig_type = trig_type(TT_itrigger),
   dmode     = bool_bit(t.dmode),
   hit       = bool_bit(t.hit),
   vs        = bool_bit(t.vs),
   vu        = bool_bit(t.vu),
   nmi       = bool_bit(t.nmi),
   m         = bool_bit(t.m),
   s         = bool_bit(t.s),
   u         = bool_bit(t.u),
   action    = zero_extend(trig_action(t.action)),
 ]

function ETrigger_to_bits(t : ETrigger) -> IETrigger_bits =
 [Mk_IETrigger_bits(zeros()) with
   trig_type = trig_type(TT_etrigger),
   dmode     = bool_bit(t.dmode),
   hit       = bool_bit(t.hit),
   vs        = bool_bit(t.vs),
   vu        = bool_bit(t.vu),
   nmi       = 0b0,
   m         = bool_bit(t.m),
   s         = bool_bit(t.s),
   u         = bool_bit(t.u),
   action    = zero_extend(trig_action(t.action)),
 ]

union Trigger = {
  T_disabled  : TDisabled,
  T_icount    : ICount,
  T_itrigger  : ITrigger,
  T_etrigger  : ETrigger,
  // other types (mcontrol6, tmexttrigger) not yet implemented
}

function trigger_name(t : Trigger) -> string =
  match t {
    T_disabled(_) => "disabled",
    T_icount(_)   => "icount",
    T_itrigger(_) => "itrigger",
    T_etrigger(_) => "etrigger",
  }

let trig_reset_val : Trigger =
  T_disabled(struct { dmode = false, data = zeros(), tdata2 = zeros(), tdata3 = zeros() })

function tdata1_of_trigger(t : Trigger) -> xlenbits =
  match t {
    T_disabled(s)  => TDisabled_to_bits(s).bits,
    T_icount(s)    => ICount_to_bits(s).bits,
    T_itrigger(s)  => ITrigger_to_bits(s).bits,
    T_etrigger(s)  => ETrigger_to_bits(s).bits,
  }

function tdata2_of_trigger(t : Trigger) -> xlenbits =
  match t {
    T_disabled(s)  => s.tdata2,
    T_icount(s)    => s.tdata2,
    T_itrigger(s)  => s.tdata2,
    T_etrigger(s)  => s.tdata2,
  }

function tdata3_of_trigger(t : Trigger) -> xlenbits =
  match t {
    T_disabled(s)  => s.tdata3,
    T_icount(s)    => s.tdata3,
    T_itrigger(s)  => s.tdata3,
    T_etrigger(s)  => s.tdata3,
  }

// For now, every trigger supports each supported type.
function info_of_trigger(_t : Trigger) -> bits(16) =
  supported_triggers_info()

bitfield TInfo : xlenbits = {
  version : 31 .. 24,
  info    : 15 .. 0,
}

function tinfo_of_trigger(t : Trigger) -> TInfo =
  [Mk_TInfo(zeros()) with
    version = 0x01, // Only support ratified version 1.0 for now.
    info = info_of_trigger(t)]

// Other register layouts

bitfield TData1 : xlenbits = {
  trig_type : xlen - 1 .. xlen - 4,
  dmode     : xlen - 5,
  data      : xlen - 6 .. 0,
}

bitfield TControl : xlenbits = {
  mpte : 7,
  mte  : 3,
}

bitfield SContext : xlenbits = {
  data : 31 .. 0,
}

bitfield MContext : xlenbits = {
  hcontext : 13 .. 0,
}

bitfield External_Trigger : xlenbits = {
  trig_type : xlen - 1 .. xlen - 4,
  dmode     : xlen - 5,
  hit       : xlen - 6,
  intctl    : 22,
  select    : 16,
  action    : 6,
}

bitfield Trigger_Extra_RV32 : bits(32) = {
  mhvalue   : 31 .. 26,
  mhselect  : 25 .. 23,
  sbytemask : 19 .. 18,
  svalue    : 17 .. 2,
  sselect   : 1 .. 0,
}

bitfield Trigger_Extra_RV64 : bits(64) = {
  mhvalue   : 63 .. 51,
  mhselect  : 50 .. 48,
  sbytemask : 39 .. 36,
  svalue    : 33 .. 2,
  sselect   : 1 .. 0,
}

// Retain the new bits in the ignored fields.
function make_disabled_trigger(tdata1 : TData1, tdata2 : xlenbits, tdata3 : xlenbits) -> Trigger =
  T_disabled(struct { dmode  = false,
                      data   = tdata1[data],
                      tdata2 = tdata2,
                      tdata3 = tdata3 })

// TODO: support enabling tdata1.dmode when Debug Mode is supported with Sdext.
function make_trigger(tdata1 : TData1, tdata2 : xlenbits, tdata3 : xlenbits) -> Trigger = {
  let tt = tdata1[trig_type];
  if   not(is_supported_trigger_type(tt))
  then return make_disabled_trigger(tdata1, tdata2, tdata3);
  match trig_type(tt) {
    TT_icount => {
      let v = Mk_ICount_bits(tdata1.bits);
      let act = v[action][3..0];
      if is_supported_action(act) then {
        T_icount(struct {
          dmode = false,
          vs = if currentlyEnabled(Ext_H) then bool_bit(v[vs]) else false,
          vu = if currentlyEnabled(Ext_H) then bool_bit(v[vu]) else false,
          hit = bool_bit(v[hit]),
          count = if icount_count_is_hardwired_one then zero_extend(0x1) else v[count],
          m = bool_bit(v[m]),
          pending = bool_bit(v[pending]),
          s = if currentlyEnabled(Ext_S) then bool_bit(v[s]) else false,
          u = if currentlyEnabled(Ext_U) then bool_bit(v[u]) else false,
          action = trig_action(act),
          tdata2 = tdata2,
          tdata3 = tdata3,
        })
      } else {
        make_disabled_trigger(tdata1, tdata2, tdata3)
      }
    },
    TT_itrigger => {
      let v = Mk_IETrigger_bits(tdata1.bits);
      let act = v[action][3..0];
      if is_supported_action(act) then {
        T_itrigger(struct {
          dmode = false,
          hit = bool_bit(v[hit]),
          vs = if currentlyEnabled(Ext_H) then bool_bit(v[vs]) else false,
          vu = if currentlyEnabled(Ext_H) then bool_bit(v[vu]) else false,
          nmi = bool_bit(v[nmi]),
          m = bool_bit(v[m]),
          s = if currentlyEnabled(Ext_S) then bool_bit(v[s]) else false,
          u = if currentlyEnabled(Ext_U) then bool_bit(v[u]) else false,
          action = trig_action(act),
          tdata2 = tdata2 & supported_itrigger_mask,
          tdata3 = tdata3,
          match_val = None(),
        })
      } else {
        make_disabled_trigger(tdata1, tdata2, tdata3)
      }
    },
    TT_etrigger => {
      let v = Mk_IETrigger_bits(tdata1.bits);
      let act = v[action][3..0];
      if is_supported_action(act) then {
        T_etrigger(struct {
          dmode = false,
          hit = bool_bit(v[hit]),
          vs = if currentlyEnabled(Ext_H) then bool_bit(v[vs]) else false,
          vu = if currentlyEnabled(Ext_H) then bool_bit(v[vu]) else false,
          m = bool_bit(v[m]),
          s = if currentlyEnabled(Ext_S) then bool_bit(v[s]) else false,
          u = if currentlyEnabled(Ext_U) then bool_bit(v[u]) else false,
          action = trig_action(act),
          tdata2 = tdata2 & supported_etrigger_mask,
          tdata3 = tdata3,
          match_val = None(),
        })
      } else {
        make_disabled_trigger(tdata1, tdata2, tdata3)
      }
    },
    // TODO: other trigger types, especially mcontrol6
    _ =>
      make_disabled_trigger(tdata1, tdata2, tdata3)
  }
}

// Handle a minimal set of writes to tdata1 registers: disabling via
// 0-writes, and updates of the `hit` field.  Since all fields are WARL,
// this is a legal implementation.
function trigger_write_tdata1(t : Trigger, tdata1 : xlenbits) -> Trigger = {
  let disable = tdata1 == zeros();
  match t {
    T_disabled(s) =>
      make_trigger(Mk_TData1(tdata1), s.tdata2, s.tdata3),
    T_icount(s) =>
      if disable
      then make_disabled_trigger(Mk_TData1(tdata1), s.tdata2, s.tdata3)
      else {
        let data = Mk_ICount_bits(tdata1);
        T_icount({s with hit = bool_bit(data[hit])})
      },
    T_itrigger(s) =>
      if disable
      then make_disabled_trigger(Mk_TData1(tdata1), s.tdata2, s.tdata3)
      else {
        let data = Mk_IETrigger_bits(tdata1);
        T_itrigger({s with hit = bool_bit(data[hit])})
      },
    T_etrigger(s) =>
      if disable
      then make_disabled_trigger(Mk_TData1(tdata1), s.tdata2, s.tdata3)
      else {
        let data = Mk_IETrigger_bits(tdata1);
        T_etrigger({s with hit = bool_bit(data[hit])})
      }
  }
}

// For now, ignore all writes to `tdata2` and `tdata3` of non-disabled
// triggers.
function trigger_write_tdata2(t : Trigger, tdata2 : xlenbits) -> Trigger =
  match t {
    T_disabled(s) => T_disabled({s with tdata2 = tdata2}),
    _ => t,
  }

// For now, ignore all tdata3 configuration.
function trigger_write_tdata3(t : Trigger, _tdata3 : xlenbits) -> Trigger =
  match t {
    T_disabled(s) => T_disabled({s with tdata3 = zeros()}),
    _ => t,
  }
