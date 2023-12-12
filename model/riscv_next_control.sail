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

/* Functional specification for the 'N' user-level interrupts standard extension. */

function clause ext_is_CSR_defined(0x000, _) = haveUsrMode() & haveNExt() // ustatus
function clause ext_is_CSR_defined(0x004, _) = haveUsrMode() & haveNExt() // uie
function clause ext_is_CSR_defined(0x005, _) = haveUsrMode() & haveNExt() // utvec
function clause ext_is_CSR_defined(0x040, _) = haveUsrMode() & haveNExt() // uscratch
function clause ext_is_CSR_defined(0x041, _) = haveUsrMode() & haveNExt() // uepc
function clause ext_is_CSR_defined(0x042, _) = haveUsrMode() & haveNExt() // ucause
function clause ext_is_CSR_defined(0x043, _) = haveUsrMode() & haveNExt() // utval
function clause ext_is_CSR_defined(0x044, _) = haveUsrMode() & haveNExt() // uip

function clause ext_read_CSR(0x000) = Some(lower_sstatus(lower_mstatus(mstatus)).bits)
function clause ext_read_CSR(0x004) = Some(lower_sie(lower_mie(mie, mideleg), sideleg).bits)
function clause ext_read_CSR(0x005) = Some(get_utvec())
function clause ext_read_CSR(0x040) = Some(uscratch)
function clause ext_read_CSR(0x041) = Some(get_xret_target(User) & pc_alignment_mask())
function clause ext_read_CSR(0x042) = Some(ucause.bits)
function clause ext_read_CSR(0x043) = Some(utval)
function clause ext_read_CSR(0x044) = Some(lower_sip(lower_mip(mip, mideleg), sideleg).bits)

function clause ext_write_CSR(0x000, value) = { mstatus = legalize_ustatus(mstatus, value); Some(mstatus.bits) }
function clause ext_write_CSR(0x004, value) = { let sie = legalize_uie(lower_mie(mie, mideleg), sideleg, value);
                                                 mie = lift_sie(mie, mideleg, sie);
                                                 Some(mie.bits) }
function clause ext_write_CSR(0x005, value) = { Some(set_utvec(value)) }
function clause ext_write_CSR(0x040, value) = { uscratch = value; Some(uscratch) }
function clause ext_write_CSR(0x041, value) = { Some(set_xret_target(User, value)) }
function clause ext_write_CSR(0x042, value) = { ucause.bits = value; Some(ucause.bits) }
function clause ext_write_CSR(0x043, value) = { utval = value; Some(utval) }
function clause ext_write_CSR(0x044, value) = { let sip = legalize_uip(lower_mip(mip, mideleg), sideleg, value);
                                                 mip = lift_sip(mip, mideleg, sip);
                                                 Some(mip.bits) }
