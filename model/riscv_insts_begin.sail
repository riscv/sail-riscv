/*=======================================================================================*/
/*  This Sail RISC-V architecture model, comprising all files and                        */
/*  directories except where otherwise noted is subject the BSD                          */
/*  two-clause license in the LICENSE file.                                              */
/*                                                                                       */
/*  SPDX-License-Identifier: BSD-2-Clause                                                */
/*=======================================================================================*/

/* Instruction definitions.
 *
 * This includes decoding, execution, and assembly parsing and printing.
 */

scattered union ast

// Return value from `execute()` function.
union ExecutionResult = {
  // Successfully retired.
  Retire_Success                 : unit,

  // The instruction is a compressed instruction, and should be executed
  // as an uncompressed instruction.
  Decompress                     : ast,

  // WFI executed, which may or may not retire
  // depending on the configuration.
  Wait_For_Interrupt             : unit,

  // Did not retire for a standard reason.
  Illegal_Instruction            : unit,
  Trap                           : (Privilege, ctl_result, xlenbits),
  Memory_Exception               : (virtaddr, ExceptionType),

  // Did not retire for custom reason.
  Ext_CSR_Check_Failure          : unit,
  Ext_ControlAddr_Check_Failure  : ext_control_addr_error,
  Ext_DataAddr_Check_Failure     : ext_data_addr_error,
  Ext_XRET_Priv_Failure          : unit,
}

// To ease the introduction of `Retire_Failure`, this global
// definition is temporarily used instead of the previous
// RETIRE_SUCCESS enum value so that we don't have to immediately
// update all the places RETIRE_SUCCESS was used.

let RETIRE_SUCCESS : ExecutionResult = Retire_Success()

/* returns whether an instruction was retired, used for computing minstret */
val execute : ast -> ExecutionResult
scattered function execute

val assembly : ast <-> string
scattered mapping assembly

val encdec : ast <-> bits(32)
scattered mapping encdec

val encdec_compressed : ast <-> bits(16)
scattered mapping encdec_compressed

/*
 * We declare the ILLEGAL/C_ILLEGAL ast clauses here instead of in
 * riscv_insts_end, so that model extensions can make use of them.
 * However, the encdec mapping must come last to ensure that all
 * unmatched encodings decode to an illegal instruction.
 */
union clause ast = ILLEGAL : word
union clause ast = C_ILLEGAL : half
