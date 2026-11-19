// =======================================================================================
// This Sail RISC-V architecture model, comprising all files and
// directories except where otherwise noted is subject the BSD
// two-clause license in the LICENSE file.
//
// SPDX-License-Identifier: BSD-2-Clause
// =======================================================================================

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

      // This is validated in `validate_config()`.
      let maskmax = sdtrig_mcontrol6_maskmax;
      assert(0 < maskmax & maskmax < xlen);

      let is_size_supported      = is_supported_match_size(v[size], select);
      let is_action_supported    = is_supported_action(zero_extend(act));
      let is_match_supported     = is_supported_match_val(v[t_match]);
      let is_compare_value_valid =
        is_match_supported &
        ((trig_match_val(v[t_match]) != TM_NAPOT & trig_match_val(v[t_match]) != TM_NOT_NAPOT)
         | is_valid_napot_compare_value(tdata2, maskmax));

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
      // This is validated in `validate_config()`.
      let maskmax = sdtrig_mcontrol6_maskmax;
      assert(0 < maskmax & maskmax < xlen);

      let legalized = if s.t_match == TM_NAPOT | s.t_match == TM_NOT_NAPOT
                      then legalize_napot_compare_value(tdata2, maskmax)
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
