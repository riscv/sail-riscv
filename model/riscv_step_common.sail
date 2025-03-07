/*=======================================================================================*/
/*  This Sail RISC-V architecture model, comprising all files and                        */
/*  directories except where otherwise noted is subject the BSD                          */
/*  two-clause license in the LICENSE file.                                              */
/*                                                                                       */
/*  SPDX-License-Identifier: BSD-2-Clause                                                */
/*=======================================================================================*/

// The state of the emulator.
//
// The RISC-V hart could either be active (fetching and executing
// instructions) or waiting (e.g. for an interrupt).  The transition
// from `active` to `wait` occurs on instructions like WFI.  The
// transition from `wait` to `active` can occur if (i) the hart
// detects an interrupt, or (ii) if the external non-Sail emulator
// harness indicates that the waiting instruction should be retired
// (as a nop).

enum WaitReason = {WAIT_WFI, WAIT_WRS_STO, WAIT_WRS_NTO}
union StepState = {
  Step_Active : unit,
  Step_Wait   : WaitReason
}

// The return type of the `step` function.  This is communicated to
// the C emulator.
enum StepResult = {STEP_ACTIVE, STEP_WAIT_TIMEOUT, STEP_WAIT_NOTIMEOUT}
struct step_result = {
  state   : StepResult,
  stepped : bool
}

function step_result_of(state: StepState) -> StepResult = match state {
  Step_Active()           => STEP_ACTIVE,
  Step_Wait(WAIT_WFI)     => STEP_WAIT_NOTIMEOUT,
  Step_Wait(WAIT_WRS_NTO) => STEP_WAIT_NOTIMEOUT,
  Step_Wait(WAIT_WRS_STO) => STEP_WAIT_TIMEOUT,
}

/* The result of a fetch, which includes any possible error
 * from an extension that interposes on the fetch operation.
 */

union FetchResult = {
  F_Ext_Error : ext_fetch_addr_error,      /* For extensions */
  F_Base      : word,                      /* Base ISA */
  F_RVC       : half,                      /* Compressed ISA */
  F_Error     : (ExceptionType, xlenbits)  /* standard exception and PC */
}
