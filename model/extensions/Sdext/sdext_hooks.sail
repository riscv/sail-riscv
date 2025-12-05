//=======================================================================================
//  This Sail RISC-V architecture model, comprising all files and
//  directories except where otherwise noted is subject the BSD
//  two-clause license in the LICENSE file.
//
//  SPDX-License-Identifier: BSD-2-Clause
//=======================================================================================

// When executing abstract commands, most instructions that change the
// privilege mode have UNSPECIFIED behavior.  The below functions provide
// hooks to be configured to a concrete behavior.  The ones below behave
// as nops; _importantly_, they do _not_ change the privilege.

// Note that the (currently unratified) Sdsec extension requires these
// instructions to either act as a NOP (as below) or to raise an exception
// (i.e. cause the abstract command to fail with an error).

function debug_mode_ecall_hook() -> ExecutionResult =
  RETIRE_SUCCESS

function debug_mode_mret_hook() -> ExecutionResult =
  RETIRE_SUCCESS

function debug_mode_sret_hook() -> ExecutionResult =
  RETIRE_SUCCESS

// Configuration for the debugger's memory.

// This checks whether a control transfer destination is a legal
// target when executing an abstract command.  This applies to all
// control transfer instructions.
function debug_is_legal_ct_target(dest : xlenbits) -> bool =
  false

// This checks whether an instruction depending on the value of PC
// acts as an illegal instruction.  When actually used for real, this
// could be given an argument specifying the actual instruction
// opcode.  As of now, this is only used for AUIPC.
function debug_is_pc_instr_legal() -> bool =
  false
