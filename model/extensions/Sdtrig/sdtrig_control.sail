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
    Use_tcontrol => priv == Machine & tcontrol[mte] == 0b0,
    Use_interrupt_enables => match priv {
      Machine            => mstatus[MIE] == 0b0,
      Supervisor         => medeleg[Breakpoint] == 0b1 & read_real_sstatus()[SIE] == 0b0,
      VirtualSupervisor  => medeleg[Breakpoint] == 0b1 & hedeleg[Breakpoint] == 0b1 & vsstatus[SIE] == 0b0,
      VirtualUser        => false,
      User               => false,
    },
    No_reentrancy_support => false,
  }
}

// icount triggers

function icount_priv_check(t : ICount, priv : Privilege, act : Trig_Action) -> bool = {
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
      T_icount(t) => {
        if icount_priv_check(t, priv, t.action) then {
          let new_t =
            // When count is 0, it stays at 0 until explicitly written.
            if t.count == zeros()
            then t
            else
              // As implemented, this trigger cannot match for
              // multiple events during a single instruction.
              if t.count != zero_extend(0b1)
              then {t with count = t.count - 1}
              else {t with
                     count = if icount_count_is_hardwired_one then t.count else zeros(),
                     pending = true};
          triggers[i] = T_icount(new_t);

          if get_config_print_trigger()
          then print_log("Matched icount at index #" ^ dec_str(i) ^ " with action " ^ trigger_action_name(t.action));
          trigger_match_callback(i);
        }
      },
      _ => (),
    }
  }
}

// itrigger

// TODO: handle NMI interrupts.

function itrigger_priv_check(t : ITrigger, priv : Privilege, intr : InterruptType) -> bool = {
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
        if itrigger_priv_check(t, priv, intr) then {
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

private function etrigger_priv_check(t : ETrigger, priv : Privilege, e : ExceptionType) -> bool = {
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
        if etrigger_priv_check(t, priv, exc) then {
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

// Finds and fires the highest priority pending triggers.  This
// currently covers etrigger, icount and itrigger triggers (which are
// all of the same priority).  It returns the index and `tval` for the
// last one, regardless of action. For the `TA_Enter_Debug` action,
// the `tval` should not be used.

type pending_trigger_info = (Trig_Action, trigger_index, xlenbits)

function find_highest_priority_pending_trigger(priv : Privilege) -> option(pending_trigger_info) = {
  if not(currentlyEnabled(Ext_Sdtrig)) then return None();
  // TODO: Triggers do not fire while in Debug Mode.
  // if (currentlyEnabled(Ext_Sdext)) then return None();

  // TODO: Cover mcontrol6 `after (previous instruction)`
  // when mcontrol6 is added.
  // TODO: When TA_Enter_Debug when Sdext is supported and TA_Enter_Debug
  // and TA_Breakpoint actions are both pending, make both actions
  // take place.

  var trig_info : option(pending_trigger_info) = None();

  foreach (i from 0 to num_triggers - 1) {
    match triggers[i] {
      T_disabled(_) => (),
      T_icount(t) =>
        // icount triggers fire in a mode where the trigger is enabled.
        if t.pending & icount_priv_check(t, priv, t.action) then {
          trig_info = Some(t.action, i, zeros());
          fire_trigger(i);
        },
      T_itrigger(t) =>
        if t.hit & is_some(t.match_val) & not(prevent_reentrance(t.action, priv)) then {
          trig_info = Some(t.action, i, zeros());
          fire_trigger(i);
        },
      T_etrigger(t) =>
        if t.hit & is_some(t.match_val) & not(prevent_reentrance(t.action, priv)) then {
          trig_info = Some(t.action, i, zeros());
          fire_trigger(i);
        },
    }
  };

  trig_info
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
