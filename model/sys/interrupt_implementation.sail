// =======================================================================================
// This Sail RISC-V architecture model, comprising all files and
// directories except where otherwise noted is subject the BSD
// two-clause license in the LICENSE file.
//
// SPDX-License-Identifier: BSD-2-Clause
// =======================================================================================

// This aggregates the information from the interrupts controllers in
// the system, which currently are the CLINT and the SIG.

function external_interrupts_pending(hgeie_val : xlenbits) -> Minterrupts =
  // The CLINT doesn't deal with external interrupts.
  if plat_have_sig then sig_external_interrupts_pending(hgeie_val) else Mk_Minterrupts(zeros())

function machine_software_interrupt_pending() -> bits(1) =
  (if plat_have_clint then clint_machine_software_interrupt_pending() else 0b0)
  | (if plat_have_sig then sig_machine_software_interrupt_pending() else 0b0)

function supervisor_software_interrupt_pending() -> bits(1) =
  if plat_have_sig then sig_supervisor_software_interrupt_pending() else 0b0

// The only source of time currently is the CLINT.

function get_mtime() -> bits(64) =
  if plat_have_clint then clint_get_mtime() else zeros()

function get_hart_mtimecmp() -> bits(64) =
  if plat_have_clint then clint_get_hart_mtimecmp() else zeros()

function tick_clock() -> unit =
  clint_tick_clock()
