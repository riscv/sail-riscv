/*=======================================================================================*/
/*  This Sail RISC-V architecture model, comprising all files and                        */
/*  directories except where otherwise noted is subject the BSD                          */
/*  two-clause license in the LICENSE file.                                              */
/*                                                                                       */
/*  SPDX-License-Identifier: BSD-2-Clause                                                */
/*=======================================================================================*/

/* Debug mode extension Sdext: control */

// The specification denotes a hart's entry into Debug mode as the hart "halting".
function enter_debug_mode(cause : debug_entry_cause, extcause : bits(3), pc : xlenbits) -> unit = {
  assert(not(debug_mode_active), "enter_debug_mode: already in Debug mode.");
  dpc = pc;
  dcsr = [dcsr with
           Prv = privLevel_bits(cur_privilege),
           // TODO: V from hypervisor mode, ELP from Zicfilp
           // TODO: intra-instruction interruption, e.g. vstart for vector instructions
           Cause    = debug_cause_bits(cause),
           ExtCause = extcause,
         ];
  cur_privilege = Machine;
  cancel_reservation(); // TODO: Make this configurable?

  // Store the time of entry into Debug mode.
  dtime = mtime;

  debug_mode_active = true;
  debug_entry_callback();

  if   get_config_print_platform()
  then print_log("entering Debug mode from " ^ to_str(privLevel_of_bits(dcsr[Prv])));
}

// The specification denotes a hart's exit from Debug mode as the hart "resuming".
function exit_debug_mode() -> unit = {
  assert(debug_mode_active, "exit_debug_mode: not in Debug mode.");
  set_next_pc(dpc);
  tick_pc();
  cur_privilege = privLevel_of_bits(dcsr[Prv]);
  if cur_privilege != Machine then {
    mstatus = [mstatus with MPRV = 0b0];
    // TODO: If Smdbltrp is enabled, clear mstatus.MDT
    // and adjust sstatus.SDT and (for hypervisor) vsstatus.SDT.
  };
  // TODO: V from hypervisor mode, ELP from Zicfilp

  debug_mode_active = false;
  debug_exit_callback();

  if   get_config_print_platform()
  then print_log("exiting Debug mode to " ^ to_str(cur_privilege));
}

// This function must be called by the debugger/external-harness
// before executing any instructions from a Debug program buffer.
function start_debug_abstract_command() -> unit = {
  assert(currentlyEnabled(Ext_Sdext), "Cannot start Debug abstract command: Sdext is not currently enabled");
  debug_abstract_command_active = true
}

function end_debug_abstract_command() -> unit = {
  assert(currentlyEnabled(Ext_Sdext), "Cannot end Debug abstract command: Sdext is not currently enabled");
  debug_abstract_command_active = false
}

// This is called internally.
function set_debug_abstract_command_error() -> unit = {
  assert(currentlyEnabled(Ext_Sdext), "Cannot set Debug abstract command error: Sdext is not currently enabled");
  debug_abstract_command_error = true
}

// This is called from the external harness, so there is no assert.
function clear_debug_abstract_command_error() -> unit = {
  debug_abstract_command_error = false
}

function reset_sdext() -> unit = {
  init_sdext();
  dcsr = reset_Dcsr();
}
