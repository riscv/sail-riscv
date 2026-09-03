// =======================================================================================
// This Sail RISC-V architecture model, comprising all files and
// directories except where otherwise noted is subject the BSD
// two-clause license in the LICENSE file.
//
// SPDX-License-Identifier: BSD-2-Clause
// =======================================================================================

bitfield Minterrupts : xlenbits = {
  LCOFI: 13, // Local counter-overflow interrupt
  SGEI : 12, // Supervisor guest external interrupt
  MEI  : 11, // Machine external interrupt
  VSEI : 10, // Virtual Supervisor external interrupt
  SEI  : 9,  // Supervisor external interrupt

  MTI  : 7,  // Timer interrupt
  VSTI : 6,  // Virtual supervisor timer interrupt
  STI  : 5,  // Supervisor timer interrupt

  MSI  : 3,  // Software interrupt
  VSSI : 2,  // Virtual supervisor software interrupt
  SSI  : 1,  // Supervisor software interrupt
}

// Interface to interrupt controllers.
//
// When interrupt controllers are isolated into their own Sail
// components, these calls will be plumbed through externally
// (e.g. through C++).

// Called whenever we want `mip`/`sip` with the external interrupts
// ORed in.  This is the case for a) reading `mip`/`sip`, and b)
// dispatching interrupts.  But it is NOT the case for reading
// `mip`/`sip` during a CSR read-modify-write update, therefore we
// can't just store them directly in the `mip` register.
val external_interrupts_pending : xlenbits -> Minterrupts

// Called to get whether a machine-level (i.e. M-mode) software
// interrupt is pending.  For systems with IMSICs, this interrupt
// may never be pending.
val machine_software_interrupt_pending : unit -> bits(1)

// Called to get whether a supervisor-level (i.e. S-mode) software
// interrupt is pending.
val supervisor_software_interrupt_pending : unit -> bits(1)

// Called whenever we want to get the value of the memory-mapped
// `mtime` and `mtimecmp` registers.  `mtime` is typically a single
// register for the platform, while `mtimecmp` is specific to the
// hart.
val get_mtime : unit -> bits(64)
val get_hart_mtimecmp : unit -> bits(64)

// Called to increment the platform clock.
val tick_clock : unit -> unit
