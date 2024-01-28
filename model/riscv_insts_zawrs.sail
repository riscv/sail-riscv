/*=======================================================================================*/
/*  This Sail RISC-V architecture model, comprising all files and                        */
/*  directories except where otherwise noted is subject the BSD                          */
/*  two-clause license in the LICENSE file.                                              */
/*                                                                                       */
/*  SPDX-License-Identifier: BSD-2-Clause                                                */
/*=======================================================================================*/

/* ****************************************************************** */
/* This file specifies the instructions in the 'Zawrs' extension.  */

val reservation_set_valid = {
  ocaml:       "Platform.reservation_set_valid",
  interpreter: "Platform.reservation_set_valid",
  c:           "reservation_set_valid",
  lem:         "reservation_set_valid"
  } : unit -> bool

/* ****************************************************************** */
union clause ast = WRS : (wrsop)

mapping clause encdec = WRS(WRS_STO) if haveZawrs()
  <-> 0b000000011101 @ 0b00000 @ 0b000 @ 0b00000 @ 0b1110011 if haveZawrs()

mapping clause encdec = WRS(WRS_NTO) if haveZawrs()
  <-> 0b000000001101 @ 0b00000 @ 0b000 @ 0b00000 @ 0b1110011 if haveZawrs()

/* Hart must resume if a locally enabled interrupt becomes pending, even if delegated */
function interrupts_pending() -> bool = ((mip.bits() & mie.bits()) != zero_extend(0b0))

function clause execute (WRS(op)) = {

  platform_start_wrs_timeout((op == WRS_STO));

  while reservation_set_valid() & not(interrupts_pending()) & not(platform_is_wrs_timed_out()) do ();

  platform_stop_wrs_timeout();

  let timed_out = reservation_set_valid() & not(interrupts_pending());

  match (op, timed_out) {
    (_,       false) => RETIRE_SUCCESS,
    (WRS_STO, true)  => RETIRE_SUCCESS,
    (WRS_NTO, true)  => match cur_privilege {
      Machine => { RETIRE_SUCCESS },
      _       => if mstatus.TW() == 0b1
                 then { handle_illegal(); RETIRE_FAIL }
                 else { RETIRE_SUCCESS }
      }
   }
}

mapping wrs_mnemonic : wrsop <-> string = {
  WRS_STO <-> "wrs.sto",
  WRS_NTO <-> "wrs.nto",
}
mapping clause assembly = WRS(op) <-> wrs_mnemonic(op)
