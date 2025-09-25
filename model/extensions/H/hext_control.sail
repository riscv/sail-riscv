// =======================================================================================
// This Sail RISC-V architecture model, comprising all files and
// directories except where otherwise noted is subject the BSD
// two-clause license in the LICENSE file.
//
// SPDX-License-Identifier: BSD-2-Clause
// =======================================================================================

function is_trap_write_GVA(c: exc_code) -> bool = match c {
  // These exceptions write a GVA
  0b000011  => true, // Breakpoint
  0b000000  => true, // Fetch Misaligned
  0b000100  => true, // Load Misaligned
  0b000110  => true, // Store/AMO Misaligned
  0b000001  => true, // Fetch Access Fault
  0b000101  => true, // Load Access Fault
  0b000111  => true, // Store/AMO Access Fault
  0b001100  => true, // Fetch Page Fault
  0b001101  => true, // Load Page Fault
  0b001111  => true, // Store/AMO Page Fault
  // All other exceptions do not
  _                           => false
}
