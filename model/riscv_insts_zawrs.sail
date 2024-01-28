/*=======================================================================================*/
/*  RISCV Sail Model                                                                     */
/*                                                                                       */
/*  This Sail RISC-V architecture model, comprising all files and                        */
/*  directories except for the snapshots of the Lem and Sail libraries                   */
/*  in the prover_snapshots directory (which include copies of their                     */
/*  licences), is subject to the BSD two-clause licence below.                           */
/*                                                                                       */
/*  Copyright (c) 2017-2024                                                              */
/*    Ved Shanbhogue                                                                     */
/*    Prashanth Mundkur                                                                  */
/*    Rishiyur S. Nikhil and Bluespec, Inc.                                              */
/*    Jon French                                                                         */
/*    Brian Campbell                                                                     */
/*    Robert Norton-Wright                                                               */
/*    Alasdair Armstrong                                                                 */
/*    Thomas Bauereiss                                                                   */
/*    Shaked Flur                                                                        */
/*    Christopher Pulte                                                                  */
/*    Peter Sewell                                                                       */
/*    Alexander Richardson                                                               */
/*    Hesham Almatary                                                                    */
/*    Jessica Clarke                                                                     */
/*    Microsoft, for contributions by Robert Norton-Wright and Nathaniel Wesley Filardo  */
/*    Peter Rugg                                                                         */
/*    Aril Computer Corp., for contributions by Scott Johnson                            */
/*    Philipp Tomsich                                                                    */
/*    VRULL GmbH, for contributions by its employees                                     */
/*                                                                                       */
/*  All rights reserved.                                                                 */
/*                                                                                       */
/*  This software was developed by the above within the Rigorous                         */
/*  Engineering of Mainstream Systems (REMS) project, partly funded by                   */
/*  EPSRC grant EP/K008528/1, at the Universities of Cambridge and                       */
/*  Edinburgh.                                                                           */
/*                                                                                       */
/*  This software was developed by SRI International and the University of               */
/*  Cambridge Computer Laboratory (Department of Computer Science and                    */
/*  Technology) under DARPA/AFRL contract FA8650-18-C-7809 ("CIFV"), and                 */
/*  under DARPA contract HR0011-18-C-0016 ("ECATS") as part of the DARPA                 */
/*  SSITH research programme.                                                            */
/*                                                                                       */
/*  This project has received funding from the European Research Council                 */
/*  (ERC) under the European Union’s Horizon 2020 research and innovation                */
/*  programme (grant agreement 789108, ELVER).                                           */
/*                                                                                       */
/*                                                                                       */
/*  Redistribution and use in source and binary forms, with or without                   */
/*  modification, are permitted provided that the following conditions                   */
/*  are met:                                                                             */
/*  1. Redistributions of source code must retain the above copyright                    */
/*     notice, this list of conditions and the following disclaimer.                     */
/*  2. Redistributions in binary form must reproduce the above copyright                 */
/*     notice, this list of conditions and the following disclaimer in                   */
/*     the documentation and/or other materials provided with the                        */
/*     distribution.                                                                     */
/*                                                                                       */
/*  THIS SOFTWARE IS PROVIDED BY THE AUTHOR AND CONTRIBUTORS ``AS IS''                   */
/*  AND ANY EXPRESS OR IMPLIED WARRANTIES, INCLUDING, BUT NOT LIMITED                    */
/*  TO, THE IMPLIED WARRANTIES OF MERCHANTABILITY AND FITNESS FOR A                      */
/*  PARTICULAR PURPOSE ARE DISCLAIMED.  IN NO EVENT SHALL THE AUTHOR OR                  */
/*  CONTRIBUTORS BE LIABLE FOR ANY DIRECT, INDIRECT, INCIDENTAL,                         */
/*  SPECIAL, EXEMPLARY, OR CONSEQUENTIAL DAMAGES (INCLUDING, BUT NOT                     */
/*  LIMITED TO, PROCUREMENT OF SUBSTITUTE GOODS OR SERVICES; LOSS OF                     */
/*  USE, DATA, OR PROFITS; OR BUSINESS INTERRUPTION) HOWEVER CAUSED AND                  */
/*  ON ANY THEORY OF LIABILITY, WHETHER IN CONTRACT, STRICT LIABILITY,                   */
/*  OR TORT (INCLUDING NEGLIGENCE OR OTHERWISE) ARISING IN ANY WAY OUT                   */
/*  OF THE USE OF THIS SOFTWARE, EVEN IF ADVISED OF THE POSSIBILITY OF                   */
/*  SUCH DAMAGE.                                                                         */
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

  platform_start_wrs_timeout(if op == WRS_STO then true else false);

  while reservation_set_valid() & not(interrupts_pending()) & not(platform_is_wrs_timed_out()) do ();

  platform_stop_wrs_timeout();

  let timed_out : bool = if not(reservation_set_valid()) | interrupts_pending() then false else true;

  match (op, timed_out) {
    (_,       false) => RETIRE_SUCCESS,
    (WRS_STO, true)  => RETIRE_SUCCESS,
    (WRS_NTO, true)  => match cur_privilege {
      Machine => { RETIRE_SUCCESS },
      _       => if mstatus.TW() == 0b1 then { handle_illegal(); RETIRE_FAIL } else { RETIRE_SUCCESS }
      }
   }
}

mapping wrs_mnemonic : wrsop <-> string = {
  WRS_STO <-> "wrs.sto",
  WRS_NTO <-> "wrs.nto",
}
mapping clause assembly = WRS(op) <-> wrs_mnemonic(op)
