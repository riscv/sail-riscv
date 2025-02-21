/*=======================================================================================*/
/*  This Sail RISC-V architecture model, comprising all files and                        */
/*  directories except where otherwise noted is subject the BSD                          */
/*  two-clause license in the LICENSE file.                                              */
/*                                                                                       */
/*  SPDX-License-Identifier: BSD-2-Clause                                                */
/*=======================================================================================*/

/* The emulator fetch-execute-interrupt dispatch loop. */

register step_state : StepState

function init_stepper() -> unit = {
  step_state = STEP_ACTIVE;
}

// Checks if the retire returned by the execution of an instruction
// counts as a step.
function does_executed_retire_step(r : Retired(Retire_Failure)) -> bool =
  match r {
    // do not step if a wait instruction executed.
    RETIRE_FAIL(Wait_For_Interrupt())  => false,

    // other standard retires
    RETIRE_SUCCESS()                   => true,
    RETIRE_FAIL(Illegal_Instruction()) => true,
    RETIRE_FAIL(Memory_Exception(_))   => true,
    RETIRE_FAIL(Trap(_))               => true,

    // retires from extensions
    RETIRE_FAIL(Ext_ControlAddr_Check_Failure(_)) => true,
    RETIRE_FAIL(Ext_DataAddr_Check_Failure(_))    => true,
    RETIRE_FAIL(Ext_CSR_Check_Failure())          => true,
    RETIRE_FAIL(Ext_XRET_Priv_Failure(_))         => true,
  }

// The `step` function is the main interface to the non-Sail
// harness.  It receives the current step number (which numbers the
// active or wait step), and whether it should exit a wait state.
// It returns whether the Sail emulator executed a step, and the
// stepper state at the end of the step.

union Step = {
  Exec                     : Retired(Retire_Failure),
  Ext_Fetch_Check_Failure  : ext_fetch_addr_error,
  Waiting                  : unit,
  Pending_Interrupt        : (InterruptType, Privilege)
}

function step(step_no : int, exit_wait : bool) -> step_result = {
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

  /* instruction bits for faulting instructions */
  var instbits : option(xlenbits) = None();

  let (step_val, stepped) : (Step, bool) =
    match (dispatchInterrupt(cur_privilege), step_state) {
      (Some(_, _), STEP_WAIT) => {
        if   get_config_print_instr()
        then print_instr("interrupt exit from WAIT state at PC " ^ BitStr(PC));

        step_state = STEP_ACTIVE;
        // The waiting instruction retires successfully.  The
        // pending interrupts will be handled in the next step, which
        // will match the next clause.
        (Exec(RETIRE_SUCCESS()), true)
      },
      (Some(intr, priv), STEP_ACTIVE) =>
        (Pending_Interrupt(intr, priv), false),
      (None(), STEP_WAIT) => {
        // There are no pending interrupts; transition out of the Wait
        // if instructed.
        if exit_wait then {
          if   get_config_print_instr()
          then print_instr("forced exit from WAIT state at PC " ^ BitStr(PC));

          step_state = STEP_ACTIVE;
          // "When TW=1, then if WFI is executed in any
          // less-privileged mode, and it does not complete within an
          // implementation-specific, bounded time limit, the WFI
          // instruction causes an illegal-instruction exception."
          if   (cur_privilege == Machine | mstatus[TW] == 0b0)
          then (Exec(RETIRE_SUCCESS()), true)
          else (Exec(RETIRE_FAIL(Illegal_Instruction())), true)
        } else {
          if   get_config_print_instr()
          then print_instr("remaining in WAIT state at PC " ^ BitStr(PC));
          (Waiting(), false)
        }
      },
      (None(), STEP_ACTIVE) => {
        /* the extension hook interposes on the fetch result */
        match ext_fetch_hook(fetch()) {
          /* extension error */
          F_Ext_Error(e)   => (Ext_Fetch_Check_Failure(e), false),
          /* standard error */
          F_Error(e, addr) => (Exec(RETIRE_FAIL(Memory_Exception(virtaddr(addr), e))), false),
          /* non-error cases: */
          F_RVC(h) => {
            sail_instr_announce(h);
            instbits = Some(zero_extend(h));
            let ast = ext_decode_compressed(h);
            if   get_config_print_instr()
            then {
              print_instr("[" ^ dec_str(step_no) ^ "] [" ^ to_str(cur_privilege) ^ "]: " ^ BitStr(PC) ^ " (" ^ BitStr(h) ^ ") " ^ to_str(ast));
            };
            /* check for RVC once here instead of every RVC execute clause. */
            if extensionEnabled(Ext_Zca) then {
              nextPC = PC + 2;
              let r = execute(ast);
              (Exec(r), does_executed_retire_step(r))
            } else {
              (Exec(RETIRE_FAIL(Illegal_Instruction())), true)
            }
          },
          F_Base(w) => {
            sail_instr_announce(w);
            instbits = Some(zero_extend(w));
            let ast = ext_decode(w);
            if   get_config_print_instr()
            then {
              print_instr("[" ^ dec_str(step_no) ^ "] [" ^ to_str(cur_privilege) ^ "]: " ^ BitStr(PC) ^ " (" ^ BitStr(w) ^ ") " ^ to_str(ast));
            };
            nextPC = PC + 4;
            let r = execute(ast);
            (Exec(r), does_executed_retire_step(r))
          }
        }
      }
    };

  match step_val {
    Pending_Interrupt(intr, priv) => {
      if   get_config_print_instr()
      then print_bits("Handling interrupt: ", interruptType_to_bits(intr));
      handle_interrupt(intr, priv)
    },
    Waiting() => {
      assert(step_state == STEP_WAIT, "cannot be Waiting in a non-wait state.")
    },
    Ext_Fetch_Check_Failure(e) => {
      ext_handle_fetch_check_error(e)
    },
    Exec(r) => match r {
      RETIRE_SUCCESS()  => {
        assert(step_state == STEP_ACTIVE);
        retire_instruction() // update minstret
      },
      RETIRE_FAIL(fail) => match fail {
        // standard failures
        Trap(priv, ctl, pc)           => set_next_pc(exception_handler(priv, ctl, pc)),
        Memory_Exception(vaddr, exc)  => handle_mem_exception(vaddr, exc),
        Illegal_Instruction() => match instbits {
            None()         => internal_error(__FILE__, __LINE__, "no instruction bits for illegal instruction"),
            Some(instbits) => handle_illegal(instbits)
        },
        Wait_For_Interrupt() => {
          // Transition into the wait state.
          if   get_config_print_instr()
          then print_instr("entering WAIT state at PC " ^ BitStr(PC));
          step_state = STEP_WAIT
        },

        // failures from extensions
        Ext_CSR_Check_Failure()          => ext_check_CSR_fail(),
        Ext_ControlAddr_Check_Failure(e) => ext_handle_control_check_error(e),
        Ext_DataAddr_Check_Failure(e)    => ext_handle_data_check_error(e),
        Ext_XRET_Priv_Failure()          => ext_fail_xret_priv()
      }
    }
  };

  if step_state != STEP_WAIT then {
    tick_pc();

    /* for step extensions */
    ext_post_step_hook();
  };
  struct { state = step_state, stepped }
}

function loop () : unit -> unit = {
  let insns_per_tick = plat_insns_per_tick();
  var i : int = 0;
  var step_no : int = 0;
  while not(htif_done) do {
    // This standalone loop always exits immediately out of waiting
    // states.
    let step_result = step(step_no, true);
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
  init_platform();
  init_stepper();
  reset();
}
