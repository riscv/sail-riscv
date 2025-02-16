/*=======================================================================================*/
/*  This Sail RISC-V architecture model, comprising all files and                        */
/*  directories except where otherwise noted is subject the BSD                          */
/*  two-clause license in the LICENSE file.                                              */
/*                                                                                       */
/*  SPDX-License-Identifier: BSD-2-Clause                                                */
/*=======================================================================================*/

/* The emulator fetch-execute-interrupt dispatch loop. */

/* returns whether to increment the step count in the trace */
function step(step_no : int) -> bool = {
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

  let (retired, stepped) : (Retired(Retire_Failure), bool) =
    match dispatchInterrupt(cur_privilege) {
      Some(intr, priv) => (RETIRE_FAIL(Pending_Interrupt(intr, priv)), false),
      None() => {
        /* the extension hook interposes on the fetch result */
        match ext_fetch_hook(fetch()) {
          /* extension error */
          F_Ext_Error(e)   => (RETIRE_FAIL(Ext_Fetch_Check_Failure(e)), false),
          /* standard error */
          F_Error(e, addr) => (RETIRE_FAIL(Memory_Exception(virtaddr(addr), e)), false),
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
              (execute(ast), true)
            } else {
              (RETIRE_FAIL(Illegal_Instruction()), true)
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
            (execute(ast), true)
          }
        }
      }
    };

  match retired {
    RETIRE_SUCCESS()  => retire_instruction(), // update minstret
    RETIRE_FAIL(fail) => match fail {
      // standard failures
      Trap(priv, ctl, pc)           => set_next_pc(exception_handler(priv, ctl, pc)),
      Memory_Exception(vaddr, exc)  => handle_mem_exception(vaddr, exc),
      Pending_Interrupt(intr, priv) => {
        if   get_config_print_instr()
        then print_bits("Handling interrupt: ", interruptType_to_bits(intr));
        handle_interrupt(intr, priv)
      },
      Illegal_Instruction() => match instbits {
          None()         => internal_error(__FILE__, __LINE__, "no instruction bits for illegal instruction"),
          Some(instbits) => handle_illegal(instbits)
        },
      Wait_For_Interrupt() => {
        // This is currently treated as a nop that retires
        // successfully.
        platform_wfi();
        retire_instruction()
      },

      // failures from extensions
      Ext_Fetch_Check_Failure(e)       => ext_handle_fetch_check_error(e),
      Ext_CSR_Check_Failure()          => ext_check_CSR_fail(),
      Ext_ControlAddr_Check_Failure(e) => ext_handle_control_check_error(e),
      Ext_DataAddr_Check_Failure(e)    => ext_handle_data_check_error(e),
      Ext_XRET_Priv_Failure()          => ext_fail_xret_priv ()
    }
  };

  tick_pc();

  /* for step extensions */
  ext_post_step_hook();

  stepped
}

function loop () : unit -> unit = {
  let insns_per_tick = plat_insns_per_tick();
  var i : int = 0;
  var step_no : int = 0;
  while not(htif_done) do {
    let stepped = step(step_no);
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
  init_platform();
  reset();
}
