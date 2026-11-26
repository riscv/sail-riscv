// =======================================================================================
// This Sail RISC-V architecture model, comprising all files and
// directories except where otherwise noted is subject the BSD
// two-clause license in the LICENSE file.
//
// SPDX-License-Identifier: BSD-2-Clause
// =======================================================================================

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

struct TExtra = {
  mhvalue   : bits(13),
  mhselect  : bits(3),
  sbytemask : bits(4),
  svalue    : bits(32),
  sselect   : bits(2),
}

// The number of implemented mhvalue and svalue bits.
let sdtrig_mhvalue_len : range(0, 13) = config extensions.Sdtrig.textra.mhvalue_len
let sdtrig_svalue_len  : range(0, 32) = config extensions.Sdtrig.textra.svalue_len
// The corresponding masks for their values.
let mhvalue_mask : bits(13) = zero_extend(ones(sdtrig_mhvalue_len))
let svalue_mask  : bits(32) = zero_extend(ones(sdtrig_svalue_len))

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

function legalize_mhselect(cfg : mhselect_config, mhselect : bits(3)) -> bits(3) = {
  match mhselect {
    0b000 => mhselect,                                                                  // 0
    0b001 => if hartSupports(Ext_H) & cfg.mcontext_match then mhselect else 0b000,      // 1
    0b010 => if cfg.vmid_match then mhselect else 0b000,                                // 2
    0b011 => 0b000,                                                                     // 3
    0b100 => if cfg.mcontext_match then mhselect else 0b000,                            // 4
    0b101 => if hartSupports(Ext_H) & cfg.mcontext_match then mhselect else 0b000,      // 5
    0b110 => if cfg.vmid_match then mhselect else 0b000,                                // 6
    0b111 => 0b000,                                                                     // 7
  }
}

function legalize_sselect(cfg : sselect_config, sselect : bits(2)) -> bits(2) = {
  match sselect {
    0b00 => sselect,                                          // 0
    0b01 => if cfg.scontext_match then sselect else 0b00,     // 1
    0b10 => if cfg.asid_match then sselect else 0b00,         // 2
    0b11 => 0b00,                                             // 3
  }
}

function make_trigger_textra(cfg : textra_config, v : xlenbits) -> TExtra = {
  if xlen == 32 then {
    let data = Mk_Trigger_Extra_RV32(v);
    struct {
      mhvalue   = zero_extend(data[mhvalue]) & mhvalue_mask,
      mhselect  = legalize_mhselect(cfg.mhselect, data[mhselect]),
      sbytemask = if cfg.sselect.scontext_match then zero_extend(data[sbytemask]) else zeros(),
      svalue    = if hartSupports(Ext_S) then zero_extend(data[svalue]) & svalue_mask else zeros(),
      sselect   = legalize_sselect(cfg.sselect, data[sselect]),
    }
  } else {
    let data = Mk_Trigger_Extra_RV64(v);
    struct {
      mhvalue   = data[mhvalue] & mhvalue_mask,
      mhselect  = legalize_mhselect(cfg.mhselect, data[mhselect]),
      sbytemask = if cfg.sselect.scontext_match then data[sbytemask] else zeros(),
      svalue    = if hartSupports(Ext_S) then data[svalue] & svalue_mask else zeros(),
      sselect   = legalize_sselect(cfg.sselect, data[sselect]),
    }
  }
}

// The underlying trigger for which this applies is not known, so accept the maximal
// value.
let disabled_textra_config : textra_config = struct {
  mhselect = struct {
    mcontext_match = true,
    vmid_match     = true,
  },
  sselect = struct {
    scontext_match  = true,
    asid_match      = true,
  },
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

type pending_trigger_info = (Trig_Action, trigger_index, /* tval */ xlenbits, /* is_gva */ bool)

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
  cfg         : mcontrol6_config,
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
  match_info  : option((/* tval */ xlenbits, /* is_gva */ bool, Hit)),
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

struct ICount = {
  cfg        : icount_config,
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
  cfg        : itrigger_config,
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
  cfg        : etrigger_config,
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
  T_disabled(struct { dmode = false, data = zeros(), tdata2 = zeros(), textra = make_trigger_textra(disabled_textra_config, zeros()) })

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

bitfield TInfo : xlenbits = {
  version : 31 .. 24,
  info    : 15 .. 0,
}

function tinfo_at_idx(idx : trigger_index) -> TInfo =
  [Mk_TInfo(zeros()) with
    version = 0x01, // Only support ratified version 1.0 for now.
    info = info_at_index(idx, configured_triggers)]

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
