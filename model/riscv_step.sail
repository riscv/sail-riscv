/* The emulator fetch-execute-interrupt dispatch loop. */

/* returns whether to increment the step count in the trace */
val step : int -> bool effect {barr, eamem, escape, exmem, rmem, rreg, wmv, wmvt, wreg}
function step(step_no) = {
  /* for step extensions */
  ext_pre_step_hook();

  minstret_written = false;     /* see note for minstret */
  let (retired, stepped) : (bool, bool) =
    match dispatchInterrupt(cur_privilege) {
      Some(intr, priv) => {
        print_bits("Handling interrupt: ", intr);
        handle_interrupt(intr, priv);
        (false, false)
      },
      None() => {
        /* the extension hook interposes on the fetch result */
        let f : FetchResult = ext_fetch_hook(fetch());
        match f {
          /* extension error */
          F_Ext_Error(e)   => {
            ext_handle_fetch_check_error(e);
            (false, false)
          },
          /* standard error */
          F_Error(e, addr) => {
            handle_mem_exception(addr, e);
            (false, false)
          },
          /* non-error cases: */
          F_RVC(h) => {
            let ast = decodeCompressed(h);
            print_instr("[" ^ string_of_int(step_no) ^ "] [" ^ cur_privilege ^ "]: " ^ BitStr(PC) ^ " (" ^ BitStr(h) ^ ") " ^ ast);
            /* check for RVC once here instead of every RVC execute clause. */
            if haveRVC() then {
              nextPC = PC + 2;
              (execute(ext_post_decode_hook(ast)), true)
             } else {
              handle_illegal();
              (false, true)
             }
          },
          F_Base(w) => {
            let ast = decode(w);
            print_instr("[" ^ string_of_int(step_no) ^ "] [" ^ cur_privilege ^ "]: " ^ BitStr(PC) ^ " (" ^ BitStr(w) ^ ") " ^ ast);
            nextPC = PC + 4;
            (execute(ext_post_decode_hook(ast)), true)
          }
        }
      }
    };
  tick_pc();
  if retired then retire_instruction();

  /* for step extensions */
  ext_post_step_hook();

  stepped
}

val loop : unit -> unit effect {barr, eamem, escape, exmem, rmem, rreg, wmv, wmvt, wreg}
function loop () = {
  let insns_per_tick = plat_insns_per_tick();
  i : int = 0;
  step_no : int = 0;
  while (~ (htif_done)) do {
    let stepped = step(step_no);
    if stepped then step_no = step_no + 1;

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

/* initialize model state */
function init_model () -> unit = {
  init_platform (); /* devices */
  init_sys ();      /* processor */
  init_vmem ();     /* virtual memory */

  /* initialize extensions last */
  ext_init_regs ();
}
