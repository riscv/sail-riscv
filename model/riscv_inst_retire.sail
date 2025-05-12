/*=======================================================================================*/
/*  This Sail RISC-V architecture model, comprising all files and                        */
/*  directories except where otherwise noted is subject the BSD                          */
/*  two-clause license in the LICENSE file.                                              */
/*                                                                                       */
/*  SPDX-License-Identifier: BSD-2-Clause                                                */
/*=======================================================================================*/

// Return value from `execute()` function.
union ExecutionResult = {
  // Successfully retired.
  Retire_Success                 : unit,

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
