// =======================================================================================
// This Sail RISC-V architecture model, comprising all files and
// directories except where otherwise noted is subject the BSD
// two-clause license in the LICENSE file.
//
// SPDX-License-Identifier: BSD-2-Clause
// =======================================================================================

// If Sdtrig is implemented, at least one trigger is supported.
// Config validation ensures `num_triggers` > zero in that case,
// while schema validation ensures `num_triggers` is non-negative.

// If `num_triggers` is zero, there is no valid index.
type trigger_index = range(0, num_triggers - 1)

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

let data_access_size_supports_8bits   : bool = config extensions.Sdtrig.mcontrol6.supported_data_access_sizes.bits8
let data_access_size_supports_16bits  : bool = config extensions.Sdtrig.mcontrol6.supported_data_access_sizes.bits16
let data_access_size_supports_32bits  : bool = config extensions.Sdtrig.mcontrol6.supported_data_access_sizes.bits32
let data_access_size_supports_48bits  : bool = config extensions.Sdtrig.mcontrol6.supported_data_access_sizes.bits48
let data_access_size_supports_64bits  : bool = config extensions.Sdtrig.mcontrol6.supported_data_access_sizes.bits64

let address_access_size_supports_8bits   : bool = config extensions.Sdtrig.mcontrol6.supported_address_access_sizes.bits8
let address_access_size_supports_16bits  : bool = config extensions.Sdtrig.mcontrol6.supported_address_access_sizes.bits16
let address_access_size_supports_32bits  : bool = config extensions.Sdtrig.mcontrol6.supported_address_access_sizes.bits32
let address_access_size_supports_48bits  : bool = config extensions.Sdtrig.mcontrol6.supported_address_access_sizes.bits48
let address_access_size_supports_64bits  : bool = config extensions.Sdtrig.mcontrol6.supported_address_access_sizes.bits64
let address_access_size_supports_128bits : bool = config extensions.Sdtrig.mcontrol6.supported_address_access_sizes.bits128

function is_supported_match_size(s : bits(3), select : Compare_Selection) -> bool = {
  if not(trig_match_size_forwards_matches(s)) then return false;
  match select {
    // data compares are limited by the size of `tdata2`,
    // which is validated in `validate_config`.
    Compare_Data    => match trig_match_size(s) {
      0   => true,
      8   => data_access_size_supports_8bits,
      16  => data_access_size_supports_16bits,
      32  => data_access_size_supports_32bits,
      48  => data_access_size_supports_48bits,
      64  => data_access_size_supports_64bits,
      128 => false,
    },
    Compare_Address => match trig_match_size(s) {
      0   => true,
      8   => address_access_size_supports_8bits,
      16  => address_access_size_supports_16bits,
      32  => address_access_size_supports_32bits,
      48  => address_access_size_supports_48bits,
      64  => address_access_size_supports_64bits,
      128 => address_access_size_supports_128bits,
    },
  }
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

let mhselect_mcontext_match : bool = config extensions.Sdtrig.textra.mhselect.mcontext_match
let mhselect_vmid_match : bool = config extensions.Sdtrig.textra.mhselect.vmid_match

let sselect_scontext_match : bool = config extensions.Sdtrig.textra.sselect.scontext_match
let sselect_asid_match : bool = config extensions.Sdtrig.textra.sselect.asid_match

struct TExtra = {
  mhvalue   : bits(13),
  mhselect  : bits(3),
  sbytemask : bits(4),
  svalue    : bits(32),
  sselect   : bits(2),
}

// The number of implemented mhvalue and svalue bits.
let sdtrig_mhvalue_len : range(0, 13) = config extensions.Sdtrig.textra.mhvalue_len
let sdtrig_svalue_len : range(0, 32) = config extensions.Sdtrig.textra.svalue_len

function TExtra_to_bits(t : TExtra) -> xlenbits = {
  if xlen == 32 then {
    [Mk_Trigger_Extra_RV32(zeros()) with
      mhvalue   = trunc(t.mhvalue),
      mhselect  = t.mhselect,
      sbytemask = trunc(t.sbytemask),
      svalue    = trunc(t.svalue),
      sselect   = t.sselect,
    ].bits
  } else {
    [Mk_Trigger_Extra_RV64(zeros()) with
      mhvalue   = t.mhvalue,
      mhselect  = t.mhselect,
      sbytemask = t.sbytemask,
      svalue    = t.svalue,
      sselect   = t.sselect,
    ].bits
  }
}

function legalize_mhselect(mhselect : bits(3)) -> bits(3) = {
  match mhselect {
    0b000 => mhselect,                                                                  // 0
    0b001 => if hartSupports(Ext_H) & mhselect_mcontext_match then mhselect else 0b000, // 1
    0b010 => if mhselect_vmid_match then mhselect else 0b000,                           // 2
    0b011 => 0b000,                                                                     // 3
    0b100 => if mhselect_mcontext_match then mhselect else 0b000,                       // 4
    0b101 => if hartSupports(Ext_H) & mhselect_mcontext_match then mhselect else 0b000, // 5
    0b110 => if mhselect_vmid_match then mhselect else 0b000,                           // 6
    0b111 => 0b000,                                                                     // 7
  }
}

function legalize_sselect(sselect : bits(2)) -> bits(2) = {
  match sselect {
    0b00 => sselect,                                          // 0
    0b01 => if sselect_scontext_match then sselect else 0b00, // 1
    0b10 => if sselect_asid_match then sselect else 0b00,     // 2
    0b11 => 0b00,                                             // 3
  }
}

function make_textra(v : xlenbits) -> TExtra = {
  let mhvalue_mask : bits(13) = zero_extend(ones(sdtrig_mhvalue_len));
  let svalue_mask : bits(32) = zero_extend(ones(sdtrig_svalue_len));
  if xlen == 32 then {
    let data = Mk_Trigger_Extra_RV32(v);
    struct {
      mhvalue   = zero_extend(data[mhvalue]) & mhvalue_mask,
      mhselect  = legalize_mhselect(data[mhselect]),
      sbytemask = if sselect_scontext_match then zero_extend(data[sbytemask]) else zeros(),
      svalue    = if hartSupports(Ext_S) then zero_extend(data[svalue]) & svalue_mask else zeros(),
      sselect   = legalize_sselect(data[sselect]),
    }
  } else {
    let data = Mk_Trigger_Extra_RV64(v);
    struct {
      mhvalue   = data[mhvalue] & mhvalue_mask,
      mhselect  = legalize_mhselect(data[mhselect]),
      sbytemask = if sselect_scontext_match then data[sbytemask] else zeros(),
      svalue    = if hartSupports(Ext_S) then data[svalue] & svalue_mask else zeros(),
      sselect   = legalize_sselect(data[sselect]),
    }
  }
}

// Internal types.

enum trigger_addr_type = {TriggerAddress_Load, TriggerAddress_Store, TriggerAddress_AMO}

union MemoryTriggerPayload = {
  TriggerFetchAddr   : xlenbits,
  TriggerFetchInstr  : {('width : Int), is_mem_width('width).         (xlenbits, bits(8 * 'width), int('width))},
  TriggerAddress     : {('width : Int), 0 < 'width <= max_mem_access. (trigger_addr_type, xlenbits, int('width))},
  TriggerStore       : {('width : Int), is_mem_width_wide('width).    (xlenbits, bits(8 * 'width), int('width))},
  TriggerLoadData    : {('width : Int), is_mem_width_wide('width).    (xlenbits, bits(8 * 'width), int('width))},
  TriggerAMOData     : {('width : Int), is_mem_width_wide('width).    (xlenbits, /*load*/ bits(8 * 'width), /*store*/ bits(8 * 'width), int('width))},
}

type pending_trigger_info = (Trig_Action, trigger_index, xlenbits)

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
  textra : TExtra,
}

bitfield TDisabled_bits : xlenbits = {
  trig_type : xlen - 1 .. xlen - 4,
  dmode     : xlen - 5,
  data      : xlen - 6 .. 0,
}

function TDisabled_to_bits(t : TDisabled) -> TDisabled_bits =
  [Mk_TDisabled_bits(zeros()) with
    trig_type = trig_type_bits(TT_disabled),
    dmode = bool_bit(t.dmode),
    data  = t.data
  ]

struct MControl6 = {
  dmode       : bool,
  uncertain   : bool,
  hit         : Hit,
  vs          : bool,
  vu          : bool,
  select      : Compare_Selection,
  size        : Trig_Match_Size,
  action      : Trig_Action,
  chain       : bool,
  t_match     : Trig_Match,
  m           : bool,
  uncertainen : bool,
  s           : bool,
  u           : bool,
  execute     : bool,
  store       : bool,
  load        : bool,
  tdata2      : xlenbits,
  textra      : TExtra,
  // Set when this trigger matches.
  match_info  : option((xlenbits, Hit)),
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
  uncertainen   : 5,
  s             : 4,
  u             : 3,
  execute       : 2,
  store         : 1,
  load          : 0,
}

function MControl6_to_bits(t : MControl6) -> MControl6_bits =
  let hit = hit_bits(t.hit) in
  [Mk_MControl6_bits(zeros()) with
    trig_type   = trig_type_bits(TT_mcontrol6),
    dmode       = bool_bit(t.dmode),
    uncertain   = bool_bit(t.uncertain),
    hit1        = [hit[1]],
    vs          = bool_bit(t.vs),
    vu          = bool_bit(t.vu),
    hit0        = [hit[0]],
    select      = compare_select_bits(t.select),
    size        = trig_match_size(t.size),
    action      = trig_action(t.action)[3..0],
    chain       = bool_bit(t.chain),
    t_match     = trig_match_val(t.t_match),
    m           = bool_bit(t.m),
    uncertainen = bool_bit(t.uncertainen),
    s           = bool_bit(t.s),
    u           = bool_bit(t.u),
    execute     = bool_bit(t.execute),
    store       = bool_bit(t.store),
    load        = bool_bit(t.load),
  ]

let icount_count_is_hardwired_one : bool = config extensions.Sdtrig.icount.count_hardwired_one
let icount_self_write_sets_pending : bool = config extensions.Sdtrig.icount.self_write_sets_pending

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
  // When the trigger matches on a write to the trigger that sets the
  // count, the match uses the existing count, but the trigger
  // contains the newly written count after the match. This field
  // contains a newly written count.
  new_count  : option(bits(14)),
  action     : Trig_Action,
  // The trigger can only match if it was enabled when an instruction
  // was fetched, and cannot match the instruction that created it
  // since it did not exist when the instruction was fetched.  The
  // trigger becomes active once the instruction that created it
  // retires.
  active     : bool,
  tdata2     : xlenbits,
  textra     : TExtra,
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
    trig_type = trig_type_bits(TT_icount),
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
  textra     : TExtra,
  pending    : bool,
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
  textra     : TExtra,
  pending    : bool,
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
   trig_type = trig_type_bits(TT_itrigger),
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
   trig_type = trig_type_bits(TT_etrigger),
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
  T_mcontrol6 : MControl6,
  // other types (e.g. tmexttrigger) not yet implemented
}

function trigger_name(t : Trigger) -> string =
  match t {
    T_disabled(_)  => "disabled",
    T_icount(_)    => "icount",
    T_itrigger(_)  => "itrigger",
    T_etrigger(_)  => "etrigger",
    T_mcontrol6(s) => "mcontrol6 (chain=" ^ bits_str(bool_bit(s.chain)) ^ ")",
  }

let trig_reset_val : Trigger =
  T_disabled(struct { dmode = false, data = zeros(), tdata2 = zeros(), textra = make_textra(zeros()) })

function tdata1_of_trigger(t : Trigger) -> xlenbits =
  match t {
    T_disabled(s)  => TDisabled_to_bits(s).bits,
    T_icount(s)    => ICount_to_bits(s).bits,
    T_itrigger(s)  => ITrigger_to_bits(s).bits,
    T_etrigger(s)  => ETrigger_to_bits(s).bits,
    T_mcontrol6(s) => MControl6_to_bits(s).bits,
  }

function tdata2_of_trigger(t : Trigger) -> xlenbits =
  match t {
    T_disabled(s)  => s.tdata2,
    T_icount(s)    => s.tdata2,
    T_itrigger(s)  => s.tdata2,
    T_etrigger(s)  => s.tdata2,
    T_mcontrol6(s) => s.tdata2,
  }

function textra_of_trigger(t : Trigger) -> TExtra =
  match t {
    T_disabled(s)  => s.textra,
    T_icount(s)    => s.textra,
    T_itrigger(s)  => s.textra,
    T_etrigger(s)  => s.textra,
    T_mcontrol6(s) => s.textra,
  }

function tdata3_of_trigger(t : Trigger) -> xlenbits =
  TExtra_to_bits(textra_of_trigger(t))

function trigger_is_in_chain(t : Trigger) -> bool =
  match t {
    T_mcontrol6(s) => s.chain,
    _              => false,
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
  data : sdtrig_scontext_width - 1 .. 0,
}

bitfield MContext : xlenbits = {
  hcontext : sdtrig_hcontext_width - 1 .. 0,
}

bitfield External_Trigger : xlenbits = {
  trig_type : xlen - 1 .. xlen - 4,
  dmode     : xlen - 5,
  hit       : xlen - 6,
  intctl    : 22,
  select    : 16,
  action    : 6,
}

// Retain the new bits in the ignored fields.
function make_disabled_trigger(tdata1 : TData1, tdata2 : xlenbits, textra : TExtra) -> Trigger =
  T_disabled(struct { dmode  = false,
                      data   = tdata1[data],
                      tdata2 = tdata2,
                      textra })

let supported_etrigger_mask : xlenbits = config extensions.Sdtrig.etrigger.supported_exceptions
let supported_itrigger_mask : xlenbits = config extensions.Sdtrig.itrigger.supported_interrupts

// Forward declaration.
val allow_chain_at : (trigger_index) -> bool

// TODO: support enabling tdata1.dmode when Debug Mode is supported with Sdext.
function make_trigger(idx : trigger_index, tdata1 : TData1, tdata2 : xlenbits, textra : TExtra) -> Trigger = {
  let tt = tdata1[trig_type];
  if   not(is_supported_trigger_type(tt))
  then {
    if get_config_print_trigger()
    then print_log("Cannot create unsupported trigger type " ^ bits_str(tt) ^ ".");
    return make_disabled_trigger(tdata1, tdata2, textra)
  };
  let tt = trig_type_bits(tt);
  match tt {
    TT_icount => {
      let v = Mk_ICount_bits(tdata1.bits);
      let act = v[action];
      let count = if icount_count_is_hardwired_one then zero_extend(0x1) else v[count];
      if is_supported_action(act) then {
        T_icount(struct {
          dmode = false,
          vs = if currentlyEnabled(Ext_H) then bool_bit(v[vs]) else false,
          vu = if currentlyEnabled(Ext_H) then bool_bit(v[vu]) else false,
          hit = bool_bit(v[hit]),
          count,
          new_count = Some(count),
          m = bool_bit(v[m]),
          pending = bool_bit(v[pending]),
          s = if currentlyEnabled(Ext_S) then bool_bit(v[s]) else false,
          u = if currentlyEnabled(Ext_U) then bool_bit(v[u]) else false,
          action = trig_action(act),
          active = false,
          tdata2,
          textra,
        })
      } else {
        if get_config_print_trigger()
        then print_log("Cannot create trigger type " ^ trig_type_name(tt) ^ " with unsupported action " ^ bits_str(act) ^ ".");
        make_disabled_trigger(tdata1, tdata2, textra)
      }
    },
    TT_itrigger => {
      let v = Mk_IETrigger_bits(tdata1.bits);
      let act = v[action];

      let is_action_supported     = is_supported_action(act);
      let is_interrupts_supported = (tdata2 & supported_itrigger_mask) == tdata2;
      let is_valid_config         = is_action_supported & is_interrupts_supported;

      if is_valid_config then {
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
          textra,
          pending = false,
        })
      } else {
        if get_config_print_trigger() then {
          if not(is_action_supported)
          then print_log("Cannot create trigger type " ^ trig_type_name(tt) ^ " with unsupported action " ^ bits_str(act) ^ ".");
          if not(is_interrupts_supported)
          then print_log("Cannot create trigger type " ^ trig_type_name(tt) ^ " with unsupported interrupts " ^ bits_str(tdata2) ^ " (supported = " ^ bits_str(supported_itrigger_mask) ^ ").");
        };
        make_disabled_trigger(tdata1, tdata2, textra)
      }
    },
    TT_etrigger => {
      let v = Mk_IETrigger_bits(tdata1.bits);
      let act = v[action];

      let is_action_supported     = is_supported_action(act);
      let is_exceptions_supported = (tdata2 & supported_etrigger_mask) == tdata2;
      let is_valid_config         = is_action_supported & is_exceptions_supported;

      if is_valid_config then {
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
          textra,
          pending = false,
        })
      } else {
        if get_config_print_trigger() then {
          if not(is_action_supported)
          then print_log("Cannot create trigger type " ^ trig_type_name(tt) ^ " with unsupported action " ^ bits_str(act) ^ ".");
          if not(is_exceptions_supported)
          then print_log("Cannot create trigger type " ^ trig_type_name(tt) ^ " with unsupported exceptions " ^ bits_str(tdata2) ^ " (supported = " ^ bits_str(supported_etrigger_mask) ^ ").");
        };
        make_disabled_trigger(tdata1, tdata2, textra)
      }
    },
    TT_mcontrol6 => {
      let v = Mk_MControl6_bits(tdata1.bits);
      let act = v[action];
      let select = compare_select_bits(v[select]);

      let is_size_supported      = is_supported_match_size(v[size], select);
      let is_action_supported    = is_supported_action(zero_extend(act));
      let is_match_supported     = is_supported_match_val(v[t_match]);
      let is_compare_value_valid =
        is_match_supported &
        ((trig_match_val(v[t_match]) != TM_NAPOT & trig_match_val(v[t_match]) != TM_NOT_NAPOT)
         | is_valid_napot_compare_value(tdata2));

      let allow_chain = if bool_bit(v[chain]) then allow_chain_at(idx) else false;

      let is_valid_config = is_size_supported & is_action_supported &
                            is_match_supported & is_compare_value_valid;

      if is_valid_config then {
        T_mcontrol6(struct {
          dmode = false,
          // Always match perfectly.
          uncertain = false,
          // A new trigger hasn't yet fired.
          hit = Hit_false,
          vs = if currentlyEnabled(Ext_H) then bool_bit(v[vs]) else false,
          vu = if currentlyEnabled(Ext_H) then bool_bit(v[vu]) else false,
          select,
          size = trig_match_size(v[size]),
          action = trig_action(zero_extend(act)),
          chain = allow_chain,
          t_match = trig_match_val(v[t_match]),
          m = bool_bit(v[m]),
          // Always match perfectly.
          uncertainen = false,
          s = if currentlyEnabled(Ext_S) then bool_bit(v[s]) else false,
          u = if currentlyEnabled(Ext_U) then bool_bit(v[u]) else false,
          execute = bool_bit(v[execute]),
          store = bool_bit(v[store]),
          load = bool_bit(v[load]),
          tdata2,
          textra,
          match_info = None(),
        })
      } else {
        if get_config_print_trigger() then {
          if not(is_action_supported)
          then print_log("Cannot create trigger type " ^ trig_type_name(tt) ^ " with unsupported action " ^ bits_str(act) ^ ".");
          if not(is_size_supported)
          then print_log("Cannot create trigger type " ^ trig_type_name(tt) ^ " with unsupported match size " ^ bits_str(v[size]) ^ ".");
          if not(is_match_supported)
          then print_log("Cannot create trigger type " ^ trig_type_name(tt) ^ " with unsupported match " ^ bits_str(v[t_match]) ^ ".");
          if is_match_supported & not(is_size_supported)
          then print_log("Cannot create trigger type " ^ trig_type_name(tt) ^ " with invalid NAPOT compare value " ^ bits_str(tdata2) ^ ".");
        };
        make_disabled_trigger(tdata1, tdata2, textra)
      }
    },
    // TODO: other trigger types.
    _ => {
      if get_config_print_trigger()
      then print_log("Creating disabled trigger for type '" ^ trig_type_name(tt) ^ "'.");
      make_disabled_trigger(tdata1, tdata2, textra)
    },
  }
}

// Handle a minimal set of writes to tdata1 registers.
function trigger_write_tdata1(idx : trigger_index, t : Trigger, tdata1 : xlenbits) -> Trigger = {
  let tdata1_bitfield = Mk_TData1(tdata1);

  let disable = tdata1 == zeros() | tdata1_bitfield[trig_type] == trig_type_bits(TT_disabled);
  if disable then {
    let newt = make_disabled_trigger(tdata1_bitfield, tdata2_of_trigger(t), textra_of_trigger(t));
    if get_config_print_trigger()
    then print_log(trigger_name(newt) ^ " trigger #" ^ dec_str(idx) ^ " (was " ^ trigger_name(t) ^ ").");
    return newt
  };

  match t {
    T_disabled(s) => {
      let newt = make_trigger(idx, tdata1_bitfield, s.tdata2, s.textra);
      if get_config_print_trigger()
      then print_log(trigger_name(newt) ^ " trigger #" ^ dec_str(idx) ^ ": enabled (was " ^ trigger_name(t) ^ ").");
      newt
    },
    T_icount(s) => {
      let data = Mk_ICount_bits(tdata1);
      let hit = data[hit];
      let pending = data[pending];
      let count = if icount_count_is_hardwired_one then zero_extend(0x1) else data[count];
      if get_config_print_trigger()
      then print_log(trigger_name(t) ^ " trigger #" ^ dec_str(idx) ^ ": hit <- " ^ bits_str(hit) ^ ", count <- " ^ bits_str(count));
      T_icount({s with hit = bool_bit(hit), pending = bool_bit(pending), new_count = Some(count)})
    },
    T_itrigger(s) => {
      let data = Mk_IETrigger_bits(tdata1);
      let hit = data[hit];
      if get_config_print_trigger()
      then print_log(trigger_name(t) ^ " trigger #" ^ dec_str(idx) ^ ": hit <- " ^ bits_str(hit));
      T_itrigger({s with hit = bool_bit(hit)})
    },
    T_etrigger(s) => {
      let data = Mk_IETrigger_bits(tdata1);
      let hit = data[hit];
      if get_config_print_trigger()
      then print_log(trigger_name(t) ^ " trigger #" ^ dec_str(idx) ^ ": hit <- " ^ bits_str(hit));
      T_etrigger({s with hit = bool_bit(hit)})
    },
    T_mcontrol6(s) => {
      let data = Mk_MControl6_bits(tdata1);
      let hit = hit_bits(data[hit1] @ data[hit0]);
      if get_config_print_trigger()
      then print_log(trigger_name(t) ^ " trigger #" ^ dec_str(idx) ^ ": hit <- " ^ hit_name(hit));
      T_mcontrol6({s with hit = hit})
    },
  }
}

// For now, ignore most writes to `tdata2` of non-disabled triggers.
function trigger_write_tdata2(idx : trigger_index, t : Trigger, tdata2 : xlenbits) -> Trigger =
  match t {
    T_disabled(s) => {
      if get_config_print_trigger()
      then print_log(trigger_name(t) ^ " trigger #" ^ dec_str(idx) ^ ": tdata2 <- " ^ bits_str(tdata2));
      T_disabled({s with tdata2 = tdata2})
    },
    T_mcontrol6(s) => {
      let legalized = if s.t_match == TM_NAPOT | s.t_match == TM_NOT_NAPOT
                      then legalize_napot_compare_value(tdata2)
                      else tdata2;
      if get_config_print_trigger()
      then print_log(trigger_name(t) ^ " trigger #" ^ dec_str(idx) ^ ": tdata2 <- " ^ bits_str(legalized) ^ " (write=" ^ bits_str(tdata2) ^ ")");
      T_mcontrol6({s with tdata2 = legalized})
    },
    T_itrigger(s) => {
      let legalized = tdata2 & supported_itrigger_mask;
      if get_config_print_trigger()
      then print_log(trigger_name(t) ^ " trigger #" ^ dec_str(idx) ^ ": tdata2 <- " ^ bits_str(legalized) ^ " (write=" ^ bits_str(tdata2) ^ ")");
      T_itrigger({s with tdata2 = legalized})
    },
    T_etrigger(s) => {
      let legalized = tdata2 & supported_etrigger_mask;
      if get_config_print_trigger()
      then print_log(trigger_name(t) ^ " trigger #" ^ dec_str(idx) ^ ": tdata2 <- " ^ bits_str(legalized) ^ " (write=" ^ bits_str(tdata2) ^ ")");
      T_etrigger({s with tdata2 = legalized})
    },
    _ => {
      if get_config_print_trigger()
      then print_log(trigger_name(t) ^ " trigger #" ^ dec_str(idx) ^ ": ignoring write to tdata2 of " ^ bits_str(tdata2));
      t
    },
  }

function trigger_write_tdata3(idx : trigger_index, t : Trigger, tdata3 : xlenbits) -> Trigger = {
  let textra = make_textra(tdata3);
  if get_config_print_trigger()
  then print_log(trigger_name(t) ^ " trigger #" ^ dec_str(idx) ^ ": tdata3 <- " ^ bits_str(TExtra_to_bits(textra)) ^ " (write=" ^ bits_str(tdata3) ^ ")");
  match t {
    T_disabled(s)  => T_disabled({s with textra}),
    T_icount(s)    => T_icount({s with textra}),
    T_itrigger(s)  => T_itrigger({s with textra}),
    T_etrigger(s)  => T_etrigger({s with textra}),
    T_mcontrol6(s) => T_mcontrol6({s with textra}),
  }
}
