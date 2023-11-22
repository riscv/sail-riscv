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
/* This file specifies the instructions in the Zimop extension.       */
/* mop.r.0-31: 1-00--0111--sssss100ddddd1110011                       */
/* mop.rr.0-7: 1-00--1tttttsssss100ddddd1110011                       */
union clause ast = ZIMOP_MOP_R : (bits(5), regidx, regidx)
union clause ast = ZIMOP_MOP_RR : (bits(3), regidx, regidx, regidx)

mapping clause encdec = ZIMOP_MOP_R(mop_30 @ mop_27_26 @ mop_21_20, rs1, rd) if haveZimop()
  <-> 0b1 @ mop_30 : bits(1) @ 0b00 @ mop_27_26 : bits(2) @ 0b0111 @ mop_21_20 : bits(2) @ rs1 @ 0b100 @ rd @ 0b1110011 if haveZimop()

mapping clause encdec = ZIMOP_MOP_RR(mop_30 @ mop_27_26, rs2, rs1, rd) if haveZimop()
  <-> 0b1 @ mop_30 : bits(1) @ 0b00 @ mop_27_26 : bits(2) @ 0b1 @ rs2 @ rs1 @ 0b100 @ rd @ 0b1110011 if haveZimop()

mapping zimop_r_mnemonic : bits(5) <-> string = {
  0b00000 <-> "mop.r.0",
  0b00001 <-> "mop.r.1",
  0b00010 <-> "mop.r.2",
  0b00011 <-> "mop.r.3",
  0b00100 <-> "mop.r.4",
  0b00101 <-> "mop.r.5",
  0b00110 <-> "mop.r.6",
  0b00111 <-> "mop.r.7",
  0b01000 <-> "mop.r.8",
  0b01001 <-> "mop.r.9",
  0b01010 <-> "mop.r.10",
  0b01011 <-> "mop.r.11",
  0b01100 <-> "mop.r.12",
  0b01101 <-> "mop.r.13",
  0b01110 <-> "mop.r.14",
  0b01111 <-> "mop.r.15",
  0b10000 <-> "mop.r.16",
  0b10001 <-> "mop.r.17",
  0b10010 <-> "mop.r.18",
  0b10011 <-> "mop.r.19",
  0b10100 <-> "mop.r.20",
  0b10101 <-> "mop.r.21",
  0b10110 <-> "mop.r.22",
  0b10111 <-> "mop.r.23",
  0b11000 <-> "mop.r.24",
  0b11001 <-> "mop.r.25",
  0b11010 <-> "mop.r.26",
  0b11011 <-> "mop.r.27",
  0b11100 <-> "mop.r.28",
  0b11101 <-> "mop.r.29",
  0b11110 <-> "mop.r.30",
  0b11111 <-> "mop.r.31"
}

mapping zimop_rr_mnemonic : bits(3) <-> string = {
  0b000 <-> "mop.rr.0",
  0b001 <-> "mop.rr.1",
  0b010 <-> "mop.rr.2",
  0b011 <-> "mop.rr.3",
  0b100 <-> "mop.rr.4",
  0b101 <-> "mop.rr.5",
  0b110 <-> "mop.rr.6",
  0b111 <-> "mop.rr.7"
}

mapping clause assembly = ZIMOP_MOP_R(mop, rs1, rd)
  <-> zimop_r_mnemonic(mop) ^ spc() ^ reg_name(rd) ^ sep() ^ reg_name(rs1)

mapping clause assembly = ZIMOP_MOP_RR(mop, rs2, rs1, rd)
  <-> zimop_rr_mnemonic(mop) ^ spc() ^ reg_name(rd) ^ sep() ^ reg_name(rs1) ^ sep() ^ reg_name(rs2)

/* Zicfiss:
 * When active, mop.r.28 rd=x0,  rs1=x1/x5 => sspopchk rs1
 * When active, mop.r.28 rd!=x0, rs1=x0    => ssrdp    rd
 */
val sspush   : (regidx) -> Retired
val sspopchk : (regidx) -> Retired
val ssrdp    : (regidx) -> Retired
function clause execute ZIMOP_MOP_R(mop, rs1, rd) = {
  match (mop, rs1, rd) {
    (0b11011, 0b00001, 0b00000) => {sspopchk(rs1);   RETIRE_SUCCESS},
    (0b11011, 0b00101, 0b00000) => {sspopchk(rs1);   RETIRE_SUCCESS},
    (0b11011, 0b00000, 0b00000) => {X(rd) = zeros(); RETIRE_SUCCESS},
    (0b11011, 0b00000,       _) => {ssrdp(rd);       RETIRE_SUCCESS},
    (_, _, _, _)                => {X(rd) = zeros(); RETIRE_SUCCESS}
  }
}
/* Zicfiss:
 * When active, mop.rr.7 rd=x0, rs2=x1/x5, rs1=x0 => sspush rs2
 */
function clause execute ZIMOP_MOP_RR(mop, rs2, rs1, rd) = {
    match (mop, rs2, rs1, rd) {
      (0b111, 0b00001, 0b00000, 0b00000) => {sspush(rs2);     RETIRE_SUCCESS},
      (0b111, 0b00101, 0b00000, 0b00000) => {sspush(rs2);     RETIRE_SUCCESS},
      (_, _, _, _)                       => {X(rd) = zeros(); RETIRE_SUCCESS}
    }
  }
}
