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
// from `active` to `wait` occurs on instructions such as WFI and
// WRS.{NTO,STO}. The transition from `wait` to `active` can occur
// if (i) the hart detects an interrupt or (in the case of
// WRS.{NTO,STO}) a reservation set is invalidated, or (ii) if the
// external non-Sail emulator harness indicates that the waiting
// instruction should finish execution.  Note that in the latter
// case, the platform can decide to end the stall for any reason,
// even if there are no interrupts or invalidated reservation set.
union HartState = {
  HART_ACTIVE  : unit,
  // The instruction that caused the wait. This is needed
  // because WFI and WRS can time out and cause an illegal
  // instruction exception so we need to know what to write
  // to mtval.
  HART_WAITING : instbits,
}

// utility predicates

function hart_is_active(s : HartState) -> bool =
  match s {
    HART_ACTIVE()   => true,
    HART_WAITING(_) => false,
  }

function hart_is_waiting(s : HartState) -> bool =
  match s {
    HART_ACTIVE()   => false,
    HART_WAITING(_) => true,
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
