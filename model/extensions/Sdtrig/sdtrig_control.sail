// =======================================================================================
// This Sail RISC-V architecture model, comprising all files and
// directories except where otherwise noted is subject the BSD
// two-clause license in the LICENSE file.
//
// SPDX-License-Identifier: BSD-2-Clause
// =======================================================================================

// Trigger matching and processing

// The specification says:
//
//   A trigger matches when the conditions that it specifies .. are
//   met. A trigger fires when a trigger that matches performs the
//   action configured for that trigger.  Triggers do not fire in
//   Debug Mode.
//
// The trigger matching logic below is performed even if the hart is
// in Debug Mode.

// The reentrancy control function returns whether triggers match
// and/or fire.
function get_reentrancy_control(act: Trig_Action, priv : Privilege) -> bool = {
  // Reentrancy controls only apply for Breakpoint actions.
  if act != TA_Breakpoint then return true;

  match sdtrig_breakpoint_reentrancy {
    Use_tcontrol =>
      if priv == Machine then bool_bit(tcontrol[mte]) else true,
    Use_interrupt_enables => {
      if priv == Machine & mstatus[MIE] == 0b0 then return false;
      if medeleg[Breakpoint] == 0b1 then {
        if priv == Supervisor & read_sstatus()[SIE] == 0b0 then return false;
        // TODO: handle VirtualSupervisor similarly with hedeleg and vsstatus.SIE
      };
      true
    },
    No_reentrancy_support => true,
  }
}

// icount triggers

function priv_match_icount(t : ICount, priv : Privilege, act : Trig_Action) -> bool = {
  get_reentrancy_control(act, priv) & (match priv {
    Machine           => t.m,
    Supervisor        => t.s,
    User              => t.u,
    VirtualSupervisor => t.vs,
    VirtualUser       => t.vu,
  })
}

function match_icount_triggers(priv : Privilege) -> unit = {
  if not(currentlyEnabled(Ext_Sdtrig)) then return ();

  foreach (i from 0 to (sizeof(num_triggers) - 1)) {
    match triggers[i] {
      T_icount(t) => {
        if priv_match_icount(t, priv, t.action) then {
          let new_t =
            // When count is 0, it stays at 0 until explicitly written.
            if t.count == zeros()
            then t
            else
              // As implemented, (i) this trigger cannot fire for
              // multiple events during a single instruction, and (ii)
              // it cannot fire for an instruction that writes to this
              // trigger to update `t.count` (since only disabled
              // triggers can be written to).
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

function priv_match_itrigger(t : ITrigger, priv : Privilege, intr : InterruptType) -> bool = {
  let priv_match : bool = get_reentrancy_control(t.action, priv) & (match priv {
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

  foreach (i from 0 to (sizeof(num_triggers) - 1)) {
    match triggers[i] {
      T_itrigger(t) =>
        if priv_match_itrigger(t, priv, intr) then {
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

private function priv_match_etrigger(t : ETrigger, priv : Privilege, e : ExceptionType) -> bool = {
  let priv_match : bool = get_reentrancy_control(t.action, priv) & (match priv {
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

  foreach (i from 0 to (sizeof(num_triggers) - 1)) {
    match triggers[i] {
      T_etrigger(t) =>
        if priv_match_etrigger(t, priv, exc) then {
          triggers[i] = T_etrigger({t with hit = true, match_val = Some(exc)});

          if get_config_print_trigger()
          then print_log("Matched etrigger at index #" ^ dec_str(i) ^ " with action " ^ trigger_action_name(t.action));
          trigger_match_callback(i);
        },
      _ => (),
    }
  }
}

// Finds highest priority pending trigger.  This covers etrigger,
// icount and itrigger triggers.  Since these are all of the same
// priority, it uses the first one found.  It returns the index of the trigger,
// the trigger action, and the tval to use for the TA_Breakpoint action.

// TODO: Cover mcontrol6 `after (previous instruction)`
// when mcontrol6 is added.
// TODO: When TA_Enter_Debug when Sdext is supported and TA_Enter_Debug
// and TA_Breakpoint actions are both pending, handle having both actions
// taking place.

function find_highest_priority_pending_trigger(priv : Privilege) -> option((Trig_Action, trigger_index, xlenbits)) = {
  if not(currentlyEnabled(Ext_Sdtrig)) then return None();

  foreach (i from 0 to (sizeof(trigger_vector_length) - 1)) {
    match triggers[i] {
      T_disabled(_) => (),
      T_icount(t) =>
        // icount triggers fire in a mode where the trigger is enabled.
        if t.pending & t.hit & priv_match_icount(t, priv, t.action) then return Some(t.action, i, zeros()),
      T_itrigger(t) =>
        if t.hit & is_some(t.match_val) & get_reentrancy_control(t.action, priv) then return Some(t.action, i, zeros()),
      T_etrigger(t) =>
        if t.hit & is_some(t.match_val) & get_reentrancy_control(t.action, priv) then return Some(t.action, i, zeros()),
    }
  };
  None()
}

// firing

function fire_trigger(idx : trigger_index) -> unit = {
  let (t, action) : (Trigger, Trig_Action) = match triggers[idx] {
    T_icount(t) => {
      let t = if icount_count_is_hardwired_one
               then {t with m = false, s = false, u = false, vs = false, vu = false}
               else t;
      (T_icount({t with pending = false}), t.action)
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
