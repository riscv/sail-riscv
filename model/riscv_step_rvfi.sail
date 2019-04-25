/* Step hooks for rvfi. */

function ext_fetch_hook(f : FetchResult) -> FetchResult = f

function ext_pre_step_hook()  -> unit = ()

function ext_post_step_hook() -> unit = {
  /* record the next pc */
  rvfi_exec->rvfi_pc_wdata() = PC
}

val ext_init : unit -> unit effect {wreg}
function ext_init() = {
  /* these are here so that the C backend doesn't prune them out. */
  rvfi_set_instr_packet(0x0000000000000000);
  print_bits("", rvfi_get_cmd());
  // let _ = rvfi_step(0);
  rvfi_zero_exec_packet();
  rvfi_halt_exec_packet();
  let _ = rvfi_get_exec_packet();
  ()
}
