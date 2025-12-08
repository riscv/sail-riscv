//=======================================================================================
//  This Sail RISC-V architecture model, comprising all files and
//  directories except where otherwise noted is subject the BSD
//  two-clause license in the LICENSE file.
//
//  SPDX-License-Identifier: BSD-2-Clause
//=======================================================================================

// Returns true if dcsr.step is set. Uses hartSupports() instead of currentlyEnabled()
// because the hart is resumed (not in debug mode) when single stepping.
function in_single_step() -> bool = hartSupports(Ext_Sdext) & bool_bits(dcsr[Step])

// Returns true if the hart is executing a debug abstract command.
function in_debug_abstract_command() -> bool = {
  match debug_state {
    Debug_Active(Debug_AbstractCommand(_)) => true,
    _                                      => false,
  }
}

// Returns true if the abstract command requires execution of the program buffer.
// AccessRegister executes program buffer when postexec=1, QuickAccess always does.
function should_execute_program_buffer(acmd : AbstractCommand) -> bool = {
  match acmd {
    AccessRegister(_, _, _, postexec, _) => postexec,
    QuickAccess()                        => true,
    _                                    => false,
  }
}

// Returns the currently executing abstract command.
function get_debug_abstract_command() -> AbstractCommand = {
  match debug_state {
    Debug_Active(Debug_AbstractCommand(rac)) => rac.acmd,
    _                                        => internal_error(__FILE__, __LINE__, "no abstract command active"),
  }
}

// Returns true if the current debug abstract command is a memory access
// with aamvirtual=1, indicating virtual address translation should be used.
function aamvirtual_set() -> bool = {
  if not(in_debug_abstract_command()) then false
  else match get_debug_abstract_command() {
    MemoryAccess(virtual, _, _, _) => virtual,
    _                              => false,
  }
}

// Enters debug mode. The spec refers to this as the hart "halting".
function enter_debug_mode(cause : debug_entry_cause, extcause : bits(3), pc : xlenbits) -> unit = {
  assert(not(in_debug_mode()), "enter_debug_mode: already in Debug mode");

  // Save hart state
  dpc  = pc;
  dcsr = [dcsr with
    Prv      = privLevel_to_bits(cur_privilege),
    Pelp     = elp,
    Cause    = debug_cause_bits(cause),
    ExtCause = extcause,
    // TODO: set V from virtualization mode when hypervisor is supported
  ];

  // Freeze time register
  dtime = mtime;

  // Switch to machine mode
  cur_privilege = Machine;

  // Disable landing pad
  reset_elp();

  // Reservation may be lost when entering debug mode
  cancel_reservation();

  debug_state = Debug_Active(Debug_Halted());
}

// Exits debug mode. The spec refers to this as the hart "resuming".
function exit_debug_mode() -> unit = {
  assert(in_debug_mode(), "exit_debug_mode: not in Debug mode");

  // Restore PC
  set_next_pc(dpc);
  tick_pc();

  // Restore landing pad state
  elp = if currentlyEnabled(Ext_Zicfilp)
        then dcsr[Pelp]
        else landing_pad_bits(NO_LP_EXPECTED);
  dcsr[Pelp] = landing_pad_bits(NO_LP_EXPECTED);

  // Restore privilege mode
  cur_privilege = privLevel_bits(dcsr[Prv], bitzero);
  // TODO: restore V from dcsr when hypervisor is supported

  // Clear MPRV when returning to less privileged mode
  if cur_privilege != Machine then {
    mstatus[MPRV] = 0b0;
    // TODO: clear mstatus.MDT if Smdbltrp is enabled
    // TODO: clear sstatus.SDT and vsstatus.SDT if Ssdbltrp is enabled
  };

  debug_state = Debug_Inactive();
}

// Starts execution of a debug abstract command.
function start_debug_abstract_command(acmd : AbstractCommand) -> unit = {
  assert(currentlyEnabled(Ext_Sdext), "start_debug_abstract_command: not in Debug mode");
  debug_state = Debug_Active(Debug_AbstractCommand(struct RunningAbstractCommand {
    acmd  = acmd,
    error = CMDERR_NONE,
  }));
}

// Ends execution of a debug abstract command with the given status.
function end_debug_abstract_command(status : AbstractCommandError) -> unit = {
  assert(currentlyEnabled(Ext_Sdext), "end_debug_abstract_command: not in Debug mode");
  debug_state = Debug_Active(Debug_Halted());
  complete_abstract_command(status);
}

// Resets debug CSRs to their initial values.
function reset_sdext() -> unit = dcsr = reset_Dcsr()

// Resets debug state. Called when the hart is reset from the debug module.
function reset_debug() -> unit = debug_state = Debug_Inactive()
