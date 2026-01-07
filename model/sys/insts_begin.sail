// =======================================================================================
// This Sail RISC-V architecture model, comprising all files and
// directories except where otherwise noted is subject the BSD
// two-clause license in the LICENSE file.
//
// SPDX-License-Identifier: BSD-2-Clause
// =======================================================================================

// Instruction declarations.
//
// This includes scattered declarations for decoding, execution, and assembly parsing and printing.
// This file also defines the execution result, i.e. the return value from the `execute()` function.

scattered union instruction

union ExecutionResult = {
  // Successfully retired.
  Retire_Success                 : unit,

  // The instruction is a compressed instruction, and should be
  // executed as an uncompressed instruction.
  ExecuteAs                      : instruction,

  // An instruction such as WFI, WRS.{STO,NTO}
  // entered a wait state, which may or may not
  // retire depending on the configuration.
  Enter_Wait                     : WaitReason,

  // Did not retire for a standard reason.
  Illegal_Instruction            : unit,
  Trap                           : (Privilege, ctl_result, xlenbits),
  Memory_Exception               : (ExceptionType, ExceptionContext),

  // Did not retire for custom reason.
  Ext_CSR_Check_Failure          : unit,
  Ext_ControlAddr_Check_Failure  : ext_control_addr_error,
  Ext_DataAddr_Check_Failure     : ext_data_addr_error,
  Ext_XRET_Priv_Failure          : unit,
}

function memory_exception(vaddr : virtaddr, e : ExceptionType) -> ExecutionResult =
  Memory_Exception(e, struct {
    excinfo     = Some(bits_of(vaddr)),
    info_is_gva = false,
    excinfo2    = None(),
    excinst     = None(),
    ext         = None(),
  })

// To ease the introduction of `ExecutionResult`, this global
// definition is temporarily used instead of the previous
// RETIRE_SUCCESS enum value so that we don't have to immediately
// update all the places RETIRE_SUCCESS was used.

let RETIRE_SUCCESS : ExecutionResult = Retire_Success()


// returns whether an instruction was retired, used for computing minstret
val execute : instruction -> ExecutionResult
scattered function execute

val assembly : instruction <-> string
scattered mapping assembly

val encdec : instruction <-> bits(32)
scattered mapping encdec

val encdec_compressed : instruction <-> bits(16)
scattered mapping encdec_compressed

// We declare the ILLEGAL/C_ILLEGAL instruction clauses here instead of in
// insts_end, so that model extensions can make use of them.
// However, the encdec mapping must come last to ensure that all
// unmatched encodings decode to an illegal instruction.
union clause instruction = ILLEGAL : word
union clause instruction = C_ILLEGAL : half
