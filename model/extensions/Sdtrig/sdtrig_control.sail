// =======================================================================================
// This Sail RISC-V architecture model, comprising all files and
// directories except where otherwise noted is subject the BSD
// two-clause license in the LICENSE file.
//
// SPDX-License-Identifier: BSD-2-Clause
// =======================================================================================

// Trigger matching and processing

// This function returns true when triggers are prevented from
// matching or firing due to reentrancy protection.
function prevent_reentrance(act: Trig_Action, priv : Privilege) -> bool = {
  // Reentrancy controls only apply for Breakpoint actions.
  if act != TA_Breakpoint then return false;

  match sdtrig_breakpoint_reentrancy {
    Use_tcontrol          => priv == Machine & tcontrol[mte] == 0b0,
    Use_interrupt_enables => match priv {
      Machine             => mstatus[MIE] == 0b0,
      Supervisor          => medeleg[Breakpoint] == 0b1 & mstatus[SIE] == 0b0,
      VirtualSupervisor   => medeleg[Breakpoint] == 0b1 & hedeleg[Breakpoint] == 0b1 & vsstatus[SIE] == 0b0,
      VirtualUser         => false,
      User                => false,
    },
    No_reentrancy_support => false,
  }
}

// icount triggers

function icount_match(t : ICount, priv : Privilege, act : Trig_Action) -> bool = {
  not(prevent_reentrance(act, priv)) & (match priv {
    Machine           => t.m,
    Supervisor        => t.s,
    User              => t.u,
    VirtualSupervisor => t.vs,
    VirtualUser       => t.vu,
  })
}

function match_icount_triggers(priv : Privilege) -> unit = {
  if not(currentlyEnabled(Ext_Sdtrig)) then return ();

  foreach (i from 0 to num_triggers - 1) {
    match triggers[i] {
      T_icount(t) =>
        if icount_match(t, priv, t.action) then {
          // As implemented, this trigger cannot match for multiple
          // events during a single instruction.
          let new_t : ICount = match unsigned(t.count) {
            // When count is 0, it stays at 0 until explicitly written.
            0 => t,
            1 => {t with
                   count = if icount_count_is_hardwired_one then t.count else zeros(),
                   pending = true},
            _ => {t with count = t.count - 1},
          };
          triggers[i] = T_icount(new_t);

          if get_config_print_trigger()
          then print_log("Matched icount at index #" ^ dec_str(i) ^ " with action " ^ trigger_action_name(t.action));
          trigger_match_callback(i);
        },
      _ => (),
    }
  }
}

// itrigger

// TODO: handle NMI interrupts.

function itrigger_match(t : ITrigger, priv : Privilege, intr : InterruptType) -> bool = {
  let priv_match : bool = not(prevent_reentrance(t.action, priv)) & (match priv {
    Machine           => t.m,
    Supervisor        => t.s,
    User              => t.u,
    VirtualSupervisor => t.vs,
    VirtualUser       => t.vu,
  });

  priv_match & ((t.tdata2 & make_itrigger_flag(intr)) != zeros())
}

function match_itrigger_triggers(priv : Privilege, intr : InterruptType) -> unit = {
  if not(currentlyEnabled(Ext_Sdtrig)) then return ();

  foreach (i from 0 to num_triggers - 1) {
    match triggers[i] {
      T_itrigger(t) =>
        if itrigger_match(t, priv, intr) then {
          triggers[i] = T_itrigger({t with hit = true, match_val = Some(intr)});

          if get_config_print_trigger()
          then print_log("Matched itrigger at index #" ^ dec_str(i) ^ " with action " ^ trigger_action_name(t.action));
          trigger_match_callback(i);
        },
      _ => (),
    }
  }
}

// etrigger

private function etrigger_match(t : ETrigger, priv : Privilege, e : ExceptionType) -> bool = {
  let priv_match : bool = not(prevent_reentrance(t.action, priv)) & (match priv {
    Machine           => t.m,
    Supervisor        => t.s,
    User              => t.u,
    VirtualSupervisor => t.vs,
    VirtualUser       => t.vu,
  });

  priv_match & ((t.tdata2 & make_etrigger_flag(e)) != zeros())
}

function match_etrigger_triggers(priv : Privilege, exc : ExceptionType) -> unit = {
  if not(currentlyEnabled(Ext_Sdtrig)) then return ();

  foreach (i from 0 to num_triggers - 1) {
    match triggers[i] {
      T_etrigger(t) =>
        if etrigger_match(t, priv, exc) then {
          triggers[i] = T_etrigger({t with hit = true, match_val = Some(exc)});

          if get_config_print_trigger()
          then print_log("Matched etrigger at index #" ^ dec_str(i) ^ " with action " ^ trigger_action_name(t.action));
          trigger_match_callback(i);
        },
      _ => (),
    }
  }
}

// firing

function fire_trigger(idx : trigger_index) -> unit = {
  let (t, action) : (Trigger, Trig_Action) = match triggers[idx] {
    T_icount(t) => {
      let t = if icount_count_is_hardwired_one
              then {t with m = false, s = false, u = false, vs = false, vu = false}
              else t;
      (T_icount({t with pending = false, hit = true}), t.action)
    },
    T_itrigger(t) => {
      (T_itrigger({t with match_val = None()}), t.action)
    },
    T_etrigger(t) => {
      (T_etrigger({t with match_val = None()}), t.action)
    },
    T_disabled(_) => internal_error(__FILE__, __LINE__, "Disabled triggers cannot fire."),
  };
  triggers[idx] = t;

  if get_config_print_trigger()
  then print_log("Fired " ^ trigger_name(t) ^ " at index #" ^ dec_str(idx) ^ " with action " ^ trigger_action_name(action));
  trigger_fire_callback(idx);
}

// Find and fire the highest priority pending triggers, and return the
// selected action, trigger index and `tval`.  If the selected action is
// not `TA_Breakpoint`, then the `tval` should not be used.

type pending_trigger_info = (Trig_Action, trigger_index, xlenbits)

function find_highest_priority_pending_trigger(priv : Privilege) -> option(pending_trigger_info) = {
  if not(currentlyEnabled(Ext_Sdtrig)) then return None();
  // TODO: Triggers do not fire while in Debug Mode.

  assert(num_triggers > 0);

  // TODO: Cover mcontrol6 `after (previous instruction)`
  // when mcontrol6 is added.
  // TODO: When TA_Enter_Debug when Sdext is supported and TA_Enter_Debug
  // and TA_Breakpoint actions are both pending, make both actions
  // take place.

  // Currently, all triggers are at the same priority.
  //
  // "If more than one of these triggers has action=0 (TA_Breakpoint),
  // then tval is updated in accordance with one of them, but which
  // one is unspecified."
  //
  // Here, we pick `tval` from the last fired trigger with an action
  // of `TA_Breakpoint`.

  var found_pending : bool = false;
  var pending_index : trigger_index = 0;
  var pending_action : Trig_Action = TA_Breakpoint;
  var pending_tval : xlenbits = zeros();

  foreach (i from 0 to num_triggers - 1) {
    match triggers[i] {
      T_disabled(_) => (),
      T_icount(t) =>
        // icount triggers fire in a mode where the trigger is enabled.
        if t.pending & icount_match(t, priv, t.action) then {
          found_pending = true;
          pending_index  = i;
          pending_action = t.action;
          if pending_action == TA_Breakpoint then pending_tval = zeros();
          fire_trigger(i);
        },
      T_itrigger(t) =>
        if t.hit & is_some(t.match_val) & not(prevent_reentrance(t.action, priv)) then {
          found_pending = true;
          pending_index  = i;
          pending_action = t.action;
          if pending_action == TA_Breakpoint then pending_tval = zeros();
          fire_trigger(i);
        },
      T_etrigger(t) =>
        if t.hit & is_some(t.match_val) & not(prevent_reentrance(t.action, priv)) then {
          found_pending = true;
          pending_index  = i;
          pending_action = t.action;
          if pending_action == TA_Breakpoint then pending_tval = zeros();
          fire_trigger(i);
        },
    }
  };

  if found_pending then Some(pending_action, pending_index, pending_tval)
  else None()
}

// update at the end of a step

function update_triggers() -> unit = {
  match written_trigger_idx {
    None()    => (),
    Some(idx) => match triggers[idx] {
      T_icount(t) => match t.new_count {
        Some(c) => triggers[idx] = T_icount({t with count = c, new_count = None()}),
        None()  => (),
      },
      _ => (),
    }
  }
}
