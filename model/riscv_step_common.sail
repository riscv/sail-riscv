/*=======================================================================================*/
/*  This Sail RISC-V architecture model, comprising all files and                        */
/*  directories except where otherwise noted is subject the BSD                          */
/*  two-clause license in the LICENSE file.                                              */
/*                                                                                       */
/*  SPDX-License-Identifier: BSD-2-Clause                                                */
/*=======================================================================================*/

// The current state of the emulator.
//
// The RISC-V hart could either be active (fetching and executing
// instructions) or waiting (e.g. for an interrupt).  The transition
// from `active` to `wait` occurs on instructions like WFI.  The
// transition from `wait` to `active` can occur if (i) the hart
// detects an interrupt, or (ii) if the external non-Sail emulator
// harness indicates that the waiting instruction should be retired
// (as a nop).

enum StepState = {STEP_ACTIVE, STEP_WAIT}

// The return type of the `step` function.
struct step_result = {
  state   : StepState,
  stepped : bool
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
