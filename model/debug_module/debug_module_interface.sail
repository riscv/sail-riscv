//=======================================================================================
//  This Sail RISC-V architecture model, comprising all files and
//  directories except where otherwise noted is subject the BSD
//  two-clause license in the LICENSE file.
//
//  SPDX-License-Identifier: BSD-2-Clause
//=======================================================================================

// The DMI read/write interfaces connect the Debug Transport Module to the Debug Module,
// bridging external debuggers like GDB (via OpenOCD) with internal components.
// These interfaces are just one of many options and can be replaced by simple handshake
// protocols or more complex bus protocols like AMBA to simulate hardware behavior.

// Debug module interface read
// Returns success status and 32-bit data read from the given 32-bit address
function dmi_read(address : nat) -> (bool, nat) = {
  let address = to_bits_truncate(8, address);
  let read = read_debug_module_reg(address);
  (true, unsigned(read))
}

// Debug module interface write
// Returns success status after writing 32-bit value to the given 32-bit address
function dmi_write(address : nat, value : nat) -> bool = {
  let address = to_bits_truncate(8, address);
  let value = to_bits_truncate(32, value);
  write_debug_module_reg(address, value);
  true
}
