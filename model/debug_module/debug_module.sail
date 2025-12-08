// =======================================================================================
// This Sail RISC-V architecture model, comprising all files and
// directories except where otherwise noted is subject the BSD
// two-clause license in the LICENSE file.
//
// SPDX-License-Identifier: BSD-2-Clause
// =======================================================================================

// Hart Status Callback

struct debug_module_hart_status = {
  running  : bool,
  halted   : bool,
  havereset: bool,
}

// Called by hart to signal the completion of an abstract command
function complete_abstract_command(status : AbstractCommandError) -> unit = {
  // TODO: Implementation comes with Debug Module
  ()
}

function send_hart_status(status : debug_module_hart_status) -> unit = {
  // TODO: Implementation comes with Debug Module
  ()
}

// TODO: Implementation comes with Debug Module
val read_arg : forall 'n, 'n in {32, 64, 128}. (range(0, 2), int('n)) -> bits('n)
function read_arg(arg_num, argument_width) = zeros('n)

// TODO: Implementation comes with Debug Module
val write_arg : forall 'n, 'n in {32, 64, 128}. (range(0, 2), int('n), bits('n)) -> unit
function write_arg(arg_num, argument_width, value) = ()
