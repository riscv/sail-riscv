/*=======================================================================================*/
/*  This Sail RISC-V architecture model, comprising all files and                        */
/*  directories except where otherwise noted is subject the BSD                          */
/*  two-clause license in the LICENSE file.                                              */
/*                                                                                       */
/*  SPDX-License-Identifier: BSD-2-Clause                                                */
/*=======================================================================================*/

/* The emulator fetch-execute-interrupt dispatch loop. */

register hart_state : HartState = HART_ACTIVE()

union Step = {
  Step_Pending_Interrupt  : (InterruptType, Privilege),
  Step_Ext_Fetch_Failure  : ext_fetch_addr_error,
  Step_Fetch_Failure      : (virtaddr, ExceptionType),
  Step_Execute            : (ExecutionResult, instbits),
  Step_Waiting            : unit,
}

function run_hart_waiting(step_no : nat, exit_wait : bool, instbits : instbits) -> Step = {
  if shouldWakeForInterrupt() then {
    if   get_config_print_instr()
    then print_instr("interrupt exit from WAIT state at PC " ^ BitStr(PC));

    hart_state = HART_ACTIVE();
    // The waiting instruction retires successfully.  The
    // pending interrupts will be handled in the next step.
    Step_Execute(Retire_Success(), instbits)
  } else if exit_wait then {
    // There are no pending interrupts; transition out of the Wait
    // as instructed.
    if   get_config_print_instr()
    then print_instr("forced exit from WAIT state at PC " ^ BitStr(PC));

    hart_state = HART_ACTIVE();
    // "When TW=1, then if WFI is executed in any
    // less-privileged mode, and it does not complete within an
    // implementation-specific, bounded time limit, the WFI
    // instruction causes an illegal-instruction exception."
    if   (cur_privilege == Machine | mstatus[TW] == 0b0)
    then Step_Execute(Retire_Success(), instbits)
    else Step_Execute(Illegal_Instruction(), instbits)
  } else {
    if   get_config_print_instr()
    then print_instr("remaining in WAIT state at PC " ^ BitStr(PC));
    Step_Waiting()
  }
}

function run_hart_active(step_no: nat) -> Step = {
  match dispatchInterrupt(cur_privilege) {
    Some(intr, priv) => Step_Pending_Interrupt(intr, priv),
    None() => match ext_fetch_hook(fetch()) {
      /* extension error */
      F_Ext_Error(e)   => Step_Ext_Fetch_Failure(e),
      /* standard error */
      F_Error(e, addr) => Step_Fetch_Failure(Virtaddr(addr), e),
      /* non-error cases: */
      F_RVC(h) => {
        sail_instr_announce(h);
        let instbits : instbits = zero_extend(h);
        let ast = ext_decode_compressed(h);
        if   get_config_print_instr()
        then {
          print_instr("[" ^ dec_str(step_no) ^ "] [" ^ to_str(cur_privilege) ^ "]: " ^ BitStr(PC) ^ " (" ^ BitStr(h) ^ ") " ^ to_str(ast));
        };
        /* check for RVC once here instead of every RVC execute clause. */
        if currentlyEnabled(Ext_Zca) then {
          nextPC = PC + 2;
          let r = execute(ast);
          Step_Execute(r, instbits)
        } else {
          Step_Execute(Illegal_Instruction(), instbits)
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
        Step_Execute(r, instbits)
      }
    }
  }
}

function wfi_is_nop() -> bool = config platform.wfi_is_nop

// The `try_step` function is the main internal driver of the Sail
// model. It performs the fetch-decode-execute for an instruction. It
// is also the primary interface to the non-Sail execution harness.
//
// A "step" is a full execution of an instruction, resulting either
// in its retirement or a trap. WFI and WRS instructions can cause
// the model to wait (hart_state is HART_WAITING), in which case
// a step has not happened and `try_step()` returns false. Otherwise
// it returns true. Equivalently, it returns whether the model is now
// in an active state (HART_ACTIVE).
//
// * step_no: the current step number; this is maintained by by the
//            non-Sail harness and is incremented when `try_step()`
//            returns true.
// * exit_wait: if true, and the model is waiting (HART_WAITING)
//              then it will wake up (switch to HART_ACTIVE) and
//              complete the WFI/WRS instruction, either successfully
//              retiring it or causing an illegal instruction
//              exception depending on mstatus[TW]. `exit_wait`
//              only affects the behaviour if the model is already
//              waiting from a previous WFI/WRS. It doesn't affect
//              WFI/WRS instructions executed in the same call of
//              `try_step()` (but see `wfi_is_nop()`).
//
function try_step(step_no : nat, exit_wait : bool) -> bool = {
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

  let step_val : Step = match hart_state {
      HART_WAITING(instbits) => run_hart_waiting(step_no, exit_wait, instbits),
      HART_ACTIVE()          => run_hart_active(step_no),
    };

  match step_val {
    Step_Pending_Interrupt(intr, priv) => {
      if   get_config_print_instr()
      then print_bits("Handling interrupt: ", interruptType_to_bits(intr));
      handle_interrupt(intr, priv)
    },
    Step_Ext_Fetch_Failure(e) => ext_handle_fetch_check_error(e),
    Step_Fetch_Failure(vaddr, e) => handle_mem_exception(vaddr, e),
    Step_Waiting() => assert(hart_is_waiting(hart_state), "cannot be Waiting in a non-Wait state"),
    Step_Execute(Retire_Success(), _) => assert(hart_is_active(hart_state)),
    // standard errors
    Step_Execute(Trap(priv, ctl, pc), _) => set_next_pc(exception_handler(priv, ctl, pc)),
    Step_Execute(Memory_Exception(vaddr, e), _) => handle_mem_exception(vaddr, e),
    Step_Execute(Illegal_Instruction(), instbits) => handle_illegal(instbits),
    Step_Execute(Wait_For_Interrupt(), instbits) =>
      if wfi_is_nop() then {
        // This is the same as the RETIRE_OK case.
        assert(hart_is_active(hart_state));
      } else {
        // Transition into the wait state.
        if   get_config_print_instr()
        then print_instr("entering WAIT state at PC " ^ BitStr(PC));
        hart_state = HART_WAITING(instbits);
      },
    // errors from extensions
    Step_Execute(Ext_CSR_Check_Failure(), _) => ext_check_CSR_fail(),
    Step_Execute(Ext_ControlAddr_Check_Failure(e), _) => ext_handle_control_check_error(e),
    Step_Execute(Ext_DataAddr_Check_Failure(e), _) => ext_handle_data_check_error(e),
    Step_Execute(Ext_XRET_Priv_Failure(), _) => ext_fail_xret_priv(),
  };

  match hart_state {
    HART_WAITING(_) => false,
    HART_ACTIVE() => {
      tick_pc();

      let retired : bool = match step_val {
        Step_Execute(Retire_Success(), _) => true,
        // WFI retires immediately if the model is configured to treat it as a nop.
        // Otherwise it always waits for at least one call of `try_step()`.
        Step_Execute(Wait_For_Interrupt(), _) if wfi_is_nop() => true,
        _ => false,
      };

      // Increment minstret if we retired an instruction and the
      // update wasn't suppressed by writing to it explicitly or
      // mcountinhibit[IR] or minstretcfg.
      if retired & minstret_increment then minstret = minstret + 1;

      // Record the next PC for RVFI.
      // TODO: Remove this and implement it in C.
      if get_config_rvfi() then {
        rvfi_pc_data[rvfi_pc_wdata] = zero_extend(get_arch_pc())
      };

      // For step extensions
      ext_post_step_hook();
      // Return that we have stepped and are active.
      true
    }
  }
}

function loop () : unit -> unit = {
  let insns_per_tick = plat_insns_per_tick();
  var i : nat = 0;
  var step_no : nat = 0;
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
