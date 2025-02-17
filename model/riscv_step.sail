/*=======================================================================================*/
/*  This Sail RISC-V architecture model, comprising all files and                        */
/*  directories except where otherwise noted is subject the BSD                          */
/*  two-clause license in the LICENSE file.                                              */
/*                                                                                       */
/*  SPDX-License-Identifier: BSD-2-Clause                                                */
/*=======================================================================================*/

/* The emulator fetch-execute-interrupt dispatch loop. */

register step_state : StepState

// Checks if the retire status returned by the execution of an instruction
// counts as a step, where a step occurs when instruction retired
// successfully or it raised an exception.
function does_executed_retire_step(r : Retired(Retire_Failure)) -> bool =
  match r {
    RETIRE_OK()                        => true,
    RETIRE_FAIL(Illegal_Instruction()) => true,
    RETIRE_FAIL(Memory_Exception(_))   => true,
    RETIRE_FAIL(Trap(_))               => true,

    // do not step if a wait instruction executed.
    RETIRE_FAIL(Wait_For_Interrupt())  => false,

    // errors from extensions
    RETIRE_FAIL(Ext_ControlAddr_Check_Failure(_)) => true,
    RETIRE_FAIL(Ext_DataAddr_Check_Failure(_))    => true,
    RETIRE_FAIL(Ext_CSR_Check_Failure())          => true,
    RETIRE_FAIL(Ext_XRET_Priv_Failure(_))         => true,
}

union Step = {
  Step_Pending_Interrupt  : (InterruptType, Privilege),
  Step_Ext_Fetch_Failure  : ext_fetch_addr_error,
  Step_Execute            : Retired(Retire_Failure),
  Step_Waiting            : unit,
}

function step_wait_state(step_no : int, exit_wait : bool) -> (Step, bool) = {
  if shouldWakeForInterrupt() then {
    if   get_config_print_instr()
    then print_instr("interrupt exit from WAIT state at PC " ^ BitStr(PC));

    step_state = STEP_ACTIVE;
    // The waiting instruction retires successfully.  The
    // pending interrupts will be handled in the next step.
    (Step_Execute(RETIRE_OK()), true)
  } else if exit_wait then {
    // There are no pending interrupts; transition out of the Wait
    // as instructed.
    if   get_config_print_instr()
    then print_instr("forced exit from WAIT state at PC " ^ BitStr(PC));

    step_state = STEP_ACTIVE;
    // "When TW=1, then if WFI is executed in any
    // less-privileged mode, and it does not complete within an
    // implementation-specific, bounded time limit, the WFI
    // instruction causes an illegal-instruction exception."
    if   (cur_privilege == Machine | mstatus[TW] == 0b0)
    then (Step_Execute(RETIRE_OK()), true)
    else (Step_Execute(RETIRE_FAIL(Illegal_Instruction())), true)
  } else {
    if   get_config_print_instr()
    then print_instr("remaining in WAIT state at PC " ^ BitStr(PC));
    (Step_Waiting(), false)
  }
}

function step_active_state(step_no: int, exit_wait : bool) -> ((Step, bool), option(xlenbits)) = {
  match dispatchInterrupt(cur_privilege) {
    Some(intr, priv) => ((Step_Pending_Interrupt(intr, priv), false), None()),
    None() => match ext_fetch_hook(fetch()) {
      /* extension error */
      F_Ext_Error(e)   => ((Step_Ext_Fetch_Failure(e), false), None()),
      /* standard error */
      F_Error(e, addr) => (((Step_Execute(RETIRE_FAIL(Memory_Exception(virtaddr(addr), e)))), false), None()),
      /* non-error cases: */
      F_RVC(h) => {
        sail_instr_announce(h);
        let instbits : option(xlenbits) = Some(zero_extend(h));
        let ast = ext_decode_compressed(h);
        if   get_config_print_instr()
        then {
          print_instr("[" ^ dec_str(step_no) ^ "] [" ^ to_str(cur_privilege) ^ "]: " ^ BitStr(PC) ^ " (" ^ BitStr(h) ^ ") " ^ to_str(ast));
        };
        /* check for RVC once here instead of every RVC execute clause. */
        if extensionEnabled(Ext_Zca) then {
          nextPC = PC + 2;
          let r = execute(ast);
          ((Step_Execute(r), does_executed_retire_step(r)), instbits)
        } else {
          ((Step_Execute(RETIRE_FAIL(Illegal_Instruction())), true), instbits)
        }
      },
      F_Base(w) => {
        sail_instr_announce(w);
        let instbits : option(xlenbits) = Some(zero_extend(w));
        let ast = ext_decode(w);
        if   get_config_print_instr()
        then {
          print_instr("[" ^ dec_str(step_no) ^ "] [" ^ to_str(cur_privilege) ^ "]: " ^ BitStr(PC) ^ " (" ^ BitStr(w) ^ ") " ^ to_str(ast));
        };
        nextPC = PC + 4;
        let r = execute(ast);
        ((Step_Execute(r), does_executed_retire_step(r)), instbits)
      }
    }
  }
}

// The `step` function is the main interface to the non-Sail
// harness.  It receives the current step number (which numbers the
// active or wait step), and whether it should exit a wait state.
// It returns whether the Sail emulator executed a step, and the
// stepper state at the end of the step.

function step(step_no : int, wait_is_nop : bool, exit_wait : bool) -> step_result = {
  /* for step extensions */
  ext_pre_step_hook();

  /*
   * This records whether or not minstret should be incremented when
   * the instruction is retired. Since retirement occurs before CSR
   * writes we initialise it based on mcountinhibit here, before
   * mcountinhibit is potentially changed. We also mark minstret(h) as not
   * having been explicitly written yet.
   */
  minstret_increment = should_inc_minstret(cur_privilege);
  minstret_write = None();
  minstreth_write = None();

  let ((step_val, did_step), instbits) : ((Step, bool), option(xlenbits)) =
    match step_state {
      STEP_WAIT   => (step_wait_state(step_no, exit_wait), None()),
      STEP_ACTIVE => step_active_state(step_no, exit_wait)
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
    Step_Waiting() => {
      assert(~(wait_is_nop));
      assert(step_state == STEP_WAIT, "cannot be Waiting in a non-Wait state");
    },
    Step_Execute(RETIRE_OK()) => {
      assert(step_state == STEP_ACTIVE);
      // default handling of minstret
      ()
    },
    Step_Execute(RETIRE_FAIL(failure)) => match failure {
      // standard failures
      Trap(priv, ctl, pc)           => {
        minstret_increment = false;
        set_next_pc(exception_handler(priv, ctl, pc))
      },
      Memory_Exception(vaddr, exc)  => {
        minstret_increment = false;
        handle_mem_exception(vaddr, exc)
      },
      Illegal_Instruction() => {
        minstret_increment = false;
        match instbits {
          None()         => internal_error(__FILE__, __LINE__, "no instruction bits for illegal instruction"),
          Some(instbits) => handle_illegal(instbits)
        }
      },
      Wait_For_Interrupt() => {
        if wait_is_nop then {
          // This is the same as RETIRE_OK.
          assert(step_state == STEP_ACTIVE);
          // Override the default step for WFI.
          stepped = true;
          ()
        } else {
          // Transition into the wait state.
          if   get_config_print_instr()
          then print_instr("entering WAIT state at PC " ^ BitStr(PC));
          step_state = STEP_WAIT
        }
      },
      // failures from extensions
      Ext_CSR_Check_Failure()          => { minstret_increment = false; ext_check_CSR_fail() },
      Ext_ControlAddr_Check_Failure(e) => { minstret_increment = false; ext_handle_control_check_error(e) },
      Ext_DataAddr_Check_Failure(e)    => { minstret_increment = false; ext_handle_data_check_error(e) },
      Ext_XRET_Priv_Failure()          => { minstret_increment = false; ext_fail_xret_priv () }
    }
  };

  // Any execution that results in a STEP_WAIT should not have updated
  // minstret[h]_write.  Assert this, since the next entry into this function
  // will clear that write state above, leading to a silent loss of
  // that state.
  match step_state {
    STEP_WAIT => {
      assert(~(wait_is_nop));
      assert(minstret_write  == None());
      assert(minstreth_write == None());
    },
    STEP_ACTIVE => {
      tick_pc();
      update_minstret();
      /* for step extensions */
      ext_post_step_hook();
    }
  };

  struct { state = step_state, stepped }
}

function loop () : unit -> unit = {
  let insns_per_tick = plat_insns_per_tick();
  var i : int = 0;
  var step_no : int = 0;
  while not(htif_done) do {
    // This standalone loop treats instructions that wait as NOPs.
    let step_result = step(step_no, true, true);
    if step_result.stepped then {
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
  step_state = STEP_ACTIVE;
  init_platform();
  reset();
}
