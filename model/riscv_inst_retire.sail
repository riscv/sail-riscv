/*=======================================================================================*/
/*  This Sail RISC-V architecture model, comprising all files and                        */
/*  directories except where otherwise noted is subject the BSD                          */
/*  two-clause license in the LICENSE file.                                              */
/*                                                                                       */
/*  SPDX-License-Identifier: BSD-2-Clause                                                */
/*=======================================================================================*/

/* Reasons an instruction retire might fail or be incomplete. */

union Retire_Failure = {
  // standard reasons
  Illegal_Instruction            : unit,
  Trap                           : (Privilege, ctl_result, xlenbits),
  Memory_Exception               : (virtaddr, ExceptionType),
  Wait_For_Interrupt             : unit,
  Wait_For_Reservation_Set       : wrsop,

  // reasons from external extensions
  Ext_CSR_Check_Failure          : unit,
  Ext_ControlAddr_Check_Failure  : ext_control_addr_error,
  Ext_DataAddr_Check_Failure     : ext_data_addr_error,
  Ext_XRET_Priv_Failure          : unit,
}

// For backwards compatibility, this global definition is used
// instead of the previous RETIRE_SUCCESS enum value.

let RETIRE_SUCCESS : Retired(Retire_Failure) = RETIRE_OK()
