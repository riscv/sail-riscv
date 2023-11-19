/*=======================================================================================*/
/*  RISCV Sail Model                                                                     */
/*                                                                                       */
/*  This Sail RISC-V architecture model, comprising all files and                        */
/*  directories except for the snapshots of the Lem and Sail libraries                   */
/*  in the prover_snapshots directory (which include copies of their                     */
/*  licences), is subject to the BSD two-clause licence below.                           */
/*                                                                                       */
/*  Copyright (c) 2017-2023                                                              */
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
/*    Ved Shanbhogue                                                                     */
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
/* This file specifies the instructions in the 'Zicfilp' extension.   */
/* ****************************************************************** */
/* Forward-edge CFI: Landing pads */
/* Sail does not yet support H extension - this needs to be updated to
   support henvcfg for VS when H extension support is included        */
function zicfilp_xLPE() -> bool = {
  /* When S-mode is implemented
   *   Priv      xLPE
   *   M         mseccfg.MLPE
   *   S/HS      menvcfg.LPE
   *   VS        henvcfg.LPE
   *   U/VU      senvcfg.LPE
   * When S-mode is not implemented
   *   Priv      xLPE
   *   M         mseccfg.MLPE
   *   U         menvcfg.LPE
   */
  if   not(haveZicfilp())
  then false
  else if cur_privilege == Machine 
  then mseccfg.MLPE() == 0b1
  else if cur_privilege == Supervisor
  then menvcfg.LPE() == 0b1
  else if not(haveSupMode())
  then menvcfg.LPE() == 0b1
  else senvcfg.LPE() == 0b1
}
/* extension to jalr */
function zicfilp_update_elp(rs1_reg : regidx, rd_reg : regidx) -> unit = {
  /* 
   * An indirect branch using JALR, C.JALR, or C.JR with rs1 as x7 is termed
   * a software guarded branch. Such branches do not need to land on a LPAD
   * instruction and thus do not set ELP to LP_EXPECTED. JALR/C.JR/C.JALR
   * using x1/x5 as source are returns; they do not set ELP to LP_EXPECTED.
   *
   * is_lp_expected = ( (JALR || C.JR || C.JALR) &&
   *                    (rs1 != x1) && (rs1 != x5) && (rs1 != x7) ) ? 1 : 0;
   */
  let is_lp_expected : bool = ((rs1_reg != 0b00001) & (rs1_reg != 0b00101) & 
                               (rs1_reg != 0b00111));
  if is_lp_expected == true & zicfilp_xLPE()
  then elp = ElpState_to_bits(LP_EXPECTED);

}
/* AUIPC with rd=x0 is a lpad instruction when zicfilp is active else a no-op */
function zicfilp_lpad( lpl : bits(20) ) -> Retired = {
   /* expected label is in x7 bits 31:12 */
   let  exp_lbl : bits(20) = x7[31..12];

   if  zicfilp_xLPE() & (elp == ElpState_to_bits(LP_EXPECTED)) then {
       if ( (lpl != exp_lbl) & (lpl != 0b00000000000000000000) )
       then { handle_sw_check_exception(LANDING_PAD_FAULT); RETIRE_FAIL }
       else {elp = ElpState_to_bits(NO_LP_EXPECTED); RETIRE_SUCCESS };
   } else {
     RETIRE_SUCCESS
   }
}
/* trap delivery extension */
function zicfilp_trap_extension(del_priv : Privilege) -> unit = {
  /* When a trap is taken into privilege mode x, the xPELP is set
     to ELP and ELP is set to NO_LP_EXPECTED. */
  /* Sail does not have support for Debug mode - this needs to be
     updated when Debug mode support is added */
  if haveZicfilp() then {
    match (del_priv, sizeof(xlen)) {
      (Machine, 32 ) => {mstatush = update_MPELP(mstatush, elp)},
      (Machine, _  ) => {mstatus  = update_mstatus_MPELP(mstatus, elp)},
      (      _, _  ) => {mstatus  = update_SPELP(mstatus, elp)},
    };
    elp = ElpState_to_bits(NO_LP_EXPECTED);
  }
}
/* extension to MRET */
function zicfilp_set_elp_to_mpelp() -> unit = {
  /* An MRET or SRET instruction is used to return from a trap in M-mode
   * or S-mode, respectively. When executing an xRET instruction, if xPP
   * holds the value y, then ELP is set to the value of xPELP if yLPE is
   * 1; otherwise, it is set to NO_LP_EXPECTED; xPELP is set to
   * NO_LP_EXPECTED.
   */
  if haveZicfilp() then {
    match zicfilp_xLPE() {
      true  => { elp = get_MPELP() },
      false => { elp = ElpState_to_bits(NO_LP_EXPECTED) }
    };
    match (sizeof(xlen)) {
      32 => {mstatush = update_MPELP(mstatush, ElpState_to_bits(NO_LP_EXPECTED))},
       _ => {mstatus  = update_mstatus_MPELP(mstatus, ElpState_to_bits(NO_LP_EXPECTED))}
    };
  }
}
/* extension to SRET */
function zicfilp_set_elp_to_spelp() -> unit = {
  /* An MRET or SRET instruction is used to return from a trap in M-mode
   * or S-mode, respectively. When executing an xRET instruction, if xPP
   * holds the value y, then ELP is set to the value of xPELP if yLPE is
   * 1; otherwise, it is set to NO_LP_EXPECTED; xPELP is set to
   * NO_LP_EXPECTED.
   */
  if haveZicfilp() then {
    match zicfilp_xLPE() {
      true  => { elp = mstatus.SPELP() },
      false => { elp = ElpState_to_bits(NO_LP_EXPECTED) }
    };
    mstatus = update_SPELP(mstatus, ElpState_to_bits(NO_LP_EXPECTED));
  }
}
