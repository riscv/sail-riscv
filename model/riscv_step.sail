/*=======================================================================================*/
/*  This Sail RISC-V architecture model, comprising all files and                        */
/*  directories except where otherwise noted is subject the BSD                          */
/*  two-clause license in the LICENSE file.                                              */
/*                                                                                       */
/*  SPDX-License-Identifier: BSD-2-Clause                                                */
/*=======================================================================================*/

/* The emulator fetch-execute-interrupt dispatch loop. */

register hart_state : HartState = HART_ACTIVE()

// Returns whether the retire result returned by the execution of an
// instruction counts as a step, where a step is said to occur when an
// instruction retires successfully or it raises an exception.
// Crucially, if an instruction returns a Wait retire result, it does
// not step.
function retires_or_traps(r : ExecutionResult(Retire_Failure)) -> bool =
  match r {
    Exec_Complete()                        => true,
    Exec_Incomplete(Illegal_Instruction()) => true,
    Exec_Incomplete(Memory_Exception(_))   => true,
    Exec_Incomplete(Trap(_))               => true,

    // Do not step if a wait instruction executed.  This gets
    // overridden in `try_step()` if these instructions are nops.
    Exec_Incomplete(Enter_Wait(_))         => false,

    // errors from extensions
    Exec_Incomplete(Ext_ControlAddr_Check_Failure(_)) => true,
    Exec_Incomplete(Ext_DataAddr_Check_Failure(_))    => true,
    Exec_Incomplete(Ext_CSR_Check_Failure())          => true,
    Exec_Incomplete(Ext_XRET_Priv_Failure(_))         => true,
}

union Step = {
  Step_Pending_Interrupt  : (InterruptType, Privilege),
  Step_Ext_Fetch_Failure  : ext_fetch_addr_error,
  Step_Fetch_Failure      : (virtaddr, ExceptionType),
  Step_Execute            : (ExecutionResult(Retire_Failure), instbits),
  Step_Waiting            : WaitReason,
}

function run_hart_waiting(step_no : int, wr: WaitReason, instbits : instbits, exit_wait : bool) -> (Step, bool) = {
  match (shouldWakeForInterrupt(), wr, valid_reservation(), exit_wait) {
    // successfully interrupted waits
    (true, _, _, _) => {
      if  get_config_print_instr()
      then print_instr("interrupt exit from " ^ wait_name(wr) ^ " state at PC " ^ BitStr(PC));

      // The waiting instruction retires successfully.  The
      // pending interrupts will be handled in the next step.
      hart_state = HART_ACTIVE();
      (Step_Execute(Exec_Complete(), instbits), true)
    },
    (_, WAIT_WRS_STO, false, _) => {
      if   get_config_print_instr()
      then print_instr("reservation invalid exit from " ^ wait_name(WAIT_WRS_STO) ^ " state at PC " ^ BitStr(PC));

      hart_state = HART_ACTIVE();
      (Step_Execute(Exec_Complete(), instbits), true)
    },
    (_, WAIT_WRS_NTO, false, _) => {
      if   get_config_print_instr()
      then print_instr("reservation invalid exit from " ^ wait_name(WAIT_WRS_NTO) ^ " state at PC " ^ BitStr(PC));

      hart_state = HART_ACTIVE();
      (Step_Execute(Exec_Complete(), instbits), true)
    },
    // Transition out of waiting states as instructed.
    (_, WAIT_WFI, _, true) => {
      if   get_config_print_instr()
      then print_instr("forced exit from " ^ wait_name(WAIT_WFI) ^ " state at PC " ^ BitStr(PC));

      hart_state = HART_ACTIVE();
      // "When TW=1, then if WFI is executed in any
      // less-privileged mode, and it does not complete within an
      // implementation-specific, bounded time limit, the WFI
      // instruction causes an illegal-instruction exception."
      if   (cur_privilege == Machine | mstatus[TW] == 0b0)
      then (Step_Execute(Exec_Complete(), instbits), true)
      else (Step_Execute(Exec_Incomplete(Illegal_Instruction()), instbits), true)
    },
    (_, WAIT_WRS_STO, _, true) => {
      if   get_config_print_instr()
      then print_instr("timed-out exit from " ^ wait_name(WAIT_WRS_STO) ^ " state at PC " ^ BitStr(PC));

      hart_state = HART_ACTIVE();
      (Step_Execute(Exec_Complete(), instbits), true)
    },
    (_, WAIT_WRS_NTO, _, true) => {
      if   get_config_print_instr()
      then print_instr("timed-out exit from " ^ wait_name(WAIT_WRS_NTO) ^ " state at PC " ^ BitStr(PC));

      hart_state = HART_ACTIVE();
      if   cur_privilege == Machine
      then (Step_Execute(Exec_Complete(), instbits), true)
      else if mstatus[TW] == 0b1
      then (Step_Execute(Exec_Incomplete(Illegal_Instruction()), instbits), true)
      else // TODO: handle VS/VU modes and hstatus.VTW
           (Step_Execute(Exec_Complete(), instbits), true)
    },
    // remain waiting
    (_, _, _, false) => {
      if   get_config_print_instr()
      then print_instr("remaining in " ^ wait_name(wr) ^ " state at PC " ^ BitStr(PC));
      (Step_Waiting(wr), false)
    }
  }
}

function run_hart_active(step_no: int, exit_wait : bool) -> (Step, bool) = {
  match dispatchInterrupt(cur_privilege) {
    Some(intr, priv) => (Step_Pending_Interrupt(intr, priv), false),
    None() => match ext_fetch_hook(fetch()) {
      /* extension error */
      F_Ext_Error(e)   => (Step_Ext_Fetch_Failure(e), false),
      /* standard error */
      F_Error(e, addr) => (Step_Fetch_Failure(Virtaddr(addr), e), false),
      /* non-error cases: */
      F_RVC(h) => {
        sail_instr_announce(h);
        let instbits : xlenbits = zero_extend(h);
        let ast = ext_decode_compressed(h);
        if   get_config_print_instr()
        then {
          print_instr("[" ^ dec_str(step_no) ^ "] [" ^ to_str(cur_privilege) ^ "]: " ^ BitStr(PC) ^ " (" ^ BitStr(h) ^ ") " ^ to_str(ast));
        };
        /* check for RVC once here instead of every RVC execute clause. */
        if currentlyEnabled(Ext_Zca) then {
          nextPC = PC + 2;
          let r = execute(ast);
          (Step_Execute(r, instbits), retires_or_traps(r))
        } else {
          (Step_Execute(Exec_Incomplete(Illegal_Instruction()), instbits), true)
        }
      },
      F_Base(w) => {
        sail_instr_announce(w);
        let instbits : instbits = zero_extend(w);
        let ast = ext_decode(w);
        if   get_config_print_instr()
        then {
          print_instr("[" ^ dec_str(step_no) ^ "] [" ^ to_str(cur_privilege) ^ "]: " ^ BitStr(PC) ^ " (" ^ BitStr(w) ^ ") " ^ to_str(ast));
        };
        nextPC = PC + 4;
        let r = execute(ast);
        (Step_Execute(r, instbits), retires_or_traps(r))
      }
    }
  }
}

function wfi_is_nop() -> bool = config platform.wfi_is_nop
function wrs_nto_is_nop() -> bool = config extensions.Zawrs.nto.is_nop
function wrs_sto_is_nop() -> bool = config extensions.Zawrs.sto.is_nop

// The `try_step` function is the main internal driver of the Sail
// model. It performs the fetch-decode-execute for an instruction. It
// is also the primary interface to the non-Sail execution harness.
// The harness calls this function with the current step number (which
// numbers the active or wait step), and whether it should exit a wait
// state. The `try_step` function returns whether the Sail emulator
// executed a step, and the stepper state at the end of the step.

function try_step(step_no : int, exit_wait : bool) -> bool = {
  /* for step extensions */
  ext_pre_step_hook();

  /*
   * This records whether or not minstret should be incremented when
   * the instruction is retired. Since retirement occurs before CSR
   * writes we initialise it based on mcountinhibit here, before it is
   * potentially changed. This is also set to false if minstret is
   * written.  See the note near the minstret declaration for more
   * information.
   */
  minstret_increment = should_inc_minstret(cur_privilege);

  let (step_val, did_step) : (Step, bool) = match hart_state {
      HART_WAITING(wr, inst) => run_hart_waiting(step_no, wr, inst, exit_wait),
      HART_ACTIVE()          => run_hart_active(step_no, exit_wait),
    };

  var stepped : bool = did_step;

  match step_val {
    Step_Pending_Interrupt(intr, priv) => {
      if   get_config_print_instr()
      then print_bits("Handling interrupt: ", interruptType_to_bits(intr));
      minstret_increment = false;
      handle_interrupt(intr, priv)
    },
    Step_Ext_Fetch_Failure(e) => {
      minstret_increment = false;
      ext_handle_fetch_check_error(e)
    },
    Step_Fetch_Failure(vaddr, e) => {
      minstret_increment = false;
      handle_mem_exception(vaddr, e)
    },
    Step_Waiting(wr) => {
      assert(hart_is_waiting(hart_state), "cannot be Waiting in a non-Wait state")
    },
    Step_Execute(Exec_Complete(), _) => {
      assert(hart_is_active(hart_state))
    },
    // standard errors
    Step_Execute(Exec_Incomplete(Trap(priv, ctl, pc)), _) => {
      minstret_increment = false;
      set_next_pc(exception_handler(priv, ctl, pc))
    },
    Step_Execute(Exec_Incomplete(Memory_Exception(vaddr, e)), _) => {
      minstret_increment = false;
      handle_mem_exception(vaddr, e)
    },
    Step_Execute(Exec_Incomplete(Illegal_Instruction()), instbits) => {
      minstret_increment = false;
      handle_illegal(instbits)
    },
    Step_Execute(Exec_Incomplete(Enter_Wait(wr)), instbits) => {
      let wait_is_nop : bool = match wr {
        WAIT_WFI     => wfi_is_nop(),
        WAIT_WRS_STO => wrs_sto_is_nop(),
        WAIT_WRS_NTO => wrs_nto_is_nop(),
      };
      if wait_is_nop then {
        // This is the same as the Exec_Complete case.
        assert(hart_is_active(hart_state));
        // Override the default step for the wait.
        stepped = true;
      } else {
        // Transition into the wait state.
        if   get_config_print_instr()
        then print_instr("entering " ^ wait_name(wr) ^ " state at PC " ^ BitStr(PC));

        hart_state = HART_WAITING(wr, instbits);
      }
    },
    // errors from extensions
    Step_Execute(Exec_Incomplete(Ext_CSR_Check_Failure()), _) => {
      minstret_increment = false;
      ext_check_CSR_fail()
    },
    Step_Execute(Exec_Incomplete(Ext_ControlAddr_Check_Failure(e)), _) => {
      minstret_increment = false;
      ext_handle_control_check_error(e)
    },
    Step_Execute(Exec_Incomplete(Ext_DataAddr_Check_Failure(e)), _) => {
      minstret_increment = false;
      ext_handle_data_check_error(e)
    },
    Step_Execute(Exec_Incomplete(Ext_XRET_Priv_Failure()), _) => {
      minstret_increment = false;
      ext_fail_xret_priv ()
    },
  };

  match hart_state {
    HART_WAITING(_) => (),
    HART_ACTIVE() => {
      tick_pc();
      update_minstret();
      /* for step extensions */
      ext_post_step_hook();
    }
  };

  stepped
}

function loop () : unit -> unit = {
  let insns_per_tick = plat_insns_per_tick();
  var i : int = 0;
  var step_no : int = 0;
  while not(htif_done) do {
    // This standalone loop always exits immediately out of waiting
    // states.
    let stepped = try_step(step_no, true);
    if stepped then {
      step_no = step_no + 1;
      if get_config_print_instr() then {
        print_step()
      };
      sail_end_cycle()
    };

    /* check htif exit */
    if htif_done then {
      let exit_val = unsigned(htif_exit_code);
      if exit_val == 0 then print("SUCCESS")
      else print_int("FAILURE: ", exit_val);
    } else {
      /* update time */
      i = i + 1;
      if i == insns_per_tick then {
        tick_clock();
        /* for now, we drive the platform i/o at every clock tick. */
        tick_platform();
        i = 0;
      }
    }
  }
}

// Chip reset. This only does the minimum resets required by the RISC-V spec.
function reset() -> unit = {
  reset_sys();
  reset_vmem();

  // To allow model extensions (code outside this repo) to perform additional reset.
  ext_reset();
}

// Initialize model state. This is only called once; not for every chip reset.
function init_model() -> unit = {
  hart_state = HART_ACTIVE();
  init_platform();
  reset();
}
