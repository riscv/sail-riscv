/*=======================================================================================*/
/*  This Sail RISC-V architecture model, comprising all files and                        */
/*  directories except where otherwise noted is subject the BSD                          */
/*  two-clause license in the LICENSE file.                                              */
/*                                                                                       */
/*  SPDX-License-Identifier: BSD-2-Clause                                                */
/*=======================================================================================*/

// When the symbolic execution is running a litmus test, it sets a
// different entry point for each thread in the compiled litmus test.

val get_entry_point : unit -> xlenbits

$ifdef SYMBOLIC

$include <elf.sail>

function get_entry_point() = to_bits(xlen, elf_entry())

$else

function get_entry_point() = zero_extend(0x1000)

$endif

function main() : unit -> unit = {
  // initialize extensions
  ext_init();

  PC = get_entry_point();
  print_bits("PC = ", PC);

  try {
    init_model();
    sail_end_cycle();
    loop()
  } catch {
    Error_not_implemented(s) => print_string("Error: Not implemented: ", s),
    Error_internal_error() => print("Error: internal error")
  }
}

// For symbolic execution using Isla, we need an entry point that
// allows us to execute a single instruction.
$ifdef SYMBOLIC

$include <isla.sail>

val isla_footprint_no_init : forall 'n, 'n in {16, 32}. bits('n) -> bool

function isla_footprint_no_init(opcode) = {
  try {
    isla_reset_registers();
    sail_end_cycle();

    let instr = if length(opcode) == 16 then {
      ext_decode_compressed(opcode)
    } else {
      ext_decode(opcode)
    };
    let _ = execute(instr);
    true
  } catch {
    _ => false
  }
}

val isla_footprint : forall 'n, 'n in {16, 32}. bits('n) -> bool

function isla_footprint(opcode) = {
  try {
    init_model();
    isla_footprint_no_init(opcode)
  } catch {
    _ => false
  }
}

$endif
