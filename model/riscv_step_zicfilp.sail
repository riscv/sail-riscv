/*=======================================================================================*/
/*  RISCV Sail Model                                                                     */
/*                                                                                       */
/*  This Sail RISC-V architecture model, comprising all files and                        */
/*  directories except for the snapshots of the Lem and Sail libraries                   */
/*  in the prover_snapshots directory (which include copies of their                     */
/*  licences), is subject to the BSD two-clause licence below.                           */
/*                                                                                       */
/*  Copyright (c) 2017-2023                                                              */
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
/* This file specifies the fetch extension in the 'Zicfilp' extension.*/
/* ****************************************************************** */
/* Forward-edge CFI: Landing pads */
val zicfilp_xLPE : (unit) -> bool
function zicfilp_check_if_lpad(f : FetchResult) -> FetchResult = {
   if   not(zicfilp_xLPE())
   then f
   else {
     /* landing pad is a AUIPC with rd=x0 */
     /* When ELP is set to LP_EXPECTED, if the next instruction in
      * the instruction stream is not 4-byte aligned, or is not LPAD, or
      * if the landing pad label encoded in LPAD is not zero and does not
      * match the expected landing pad label in bits 31:12 of the x7
      * register, then a software-check exception (cause=18) with xtval
      * set to "landing pad fault (code=2)" is raised else the ELP is
      * updated to NO_LP_EXPECTED. The label check is performed in
      * riscv_insts_zicfilp:zicfilp_lpad
      */
     match f {
       F_Base(f) => {
         let inst    : word    = zero_extend(f);
         let lpad_op : bits(7) = inst[6 .. 0];
         let rd_reg  : regidx  = inst[11.. 7];
         if   elp != ElpState_to_bits(LP_EXPECTED)
         then F_Base(f)
         else if PC[1 .. 0] != 0b00
         then F_Error(E_SW_Check_Fault(), zero_extend(sw_check_code_to_bits(LANDING_PAD_FAULT)))
         else if ((lpad_op != 0b0010111) | (rd_reg != 0b00000))
         then F_Error(E_SW_Check_Fault(), zero_extend(sw_check_code_to_bits(LANDING_PAD_FAULT)))
         else F_Base(f)
       },
       F_RVC(f) => {
         if   (elp != ElpState_to_bits(LP_EXPECTED))
         then F_RVC(f)
         else F_Error(E_SW_Check_Fault(), zero_extend(sw_check_code_to_bits(LANDING_PAD_FAULT)))
       },
       F_Ext_Error(e)   => {
         f
       },
       F_Error(e, addr) => {
         f
       }
     }
   }
}
