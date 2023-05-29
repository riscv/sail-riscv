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

/* ****************************************************************** */
union clause ast = RISCV_SLLIUW : (bits(6), regidx, regidx)

mapping clause encdec = RISCV_SLLIUW(shamt, rs1, rd) if haveZba() & sizeof(xlen) == 64
  <-> 0b000010 @ shamt @ rs1 @ 0b001 @ rd @ 0b0011011 if haveZba() & sizeof(xlen) == 64

mapping clause assembly = RISCV_SLLIUW(shamt, rs1, rd)
  <-> "slli.uw" ^ spc() ^ reg_name(rd) ^ sep() ^ reg_name(rs1) ^ sep() ^ hex_bits_6(shamt)

function clause execute (RISCV_SLLIUW(shamt, rs1, rd)) = {
  let rs1_val = X(rs1);
  let result : xlenbits = EXTZ(rs1_val[31..0]) << shamt;
  X(rd) = result;
  RETIRE_SUCCESS
}

/* ****************************************************************** */
union clause ast = ZBA_RTYPEUW : (regidx, regidx, regidx, bropw_zba)

mapping clause encdec = ZBA_RTYPEUW(rs2, rs1, rd, RISCV_ADDUW) if haveZba() & sizeof(xlen) == 64
  <-> 0b0000100 @ rs2 @ rs1 @ 0b000 @ rd @ 0b0111011 if haveZba() & sizeof(xlen) == 64

mapping clause encdec = ZBA_RTYPEUW(rs2, rs1, rd, RISCV_SH1ADDUW) if haveZba() & sizeof(xlen) == 64
  <-> 0b0010000 @ rs2 @ rs1 @ 0b010 @ rd @ 0b0111011 if haveZba() & sizeof(xlen) == 64

mapping clause encdec = ZBA_RTYPEUW(rs2, rs1, rd, RISCV_SH2ADDUW) if haveZba() & sizeof(xlen) == 64
  <-> 0b0010000 @ rs2 @ rs1 @ 0b100 @ rd @ 0b0111011 if haveZba() & sizeof(xlen) == 64

mapping clause encdec = ZBA_RTYPEUW(rs2, rs1, rd, RISCV_SH3ADDUW) if haveZba() & sizeof(xlen) == 64
  <-> 0b0010000 @ rs2 @ rs1 @ 0b110 @ rd @ 0b0111011 if haveZba() & sizeof(xlen) == 64

mapping zba_rtypeuw_mnemonic : bropw_zba <-> string = {
  RISCV_ADDUW    <-> "add.uw",
  RISCV_SH1ADDUW <-> "sh1add.uw",
  RISCV_SH2ADDUW <-> "sh2add.uw",
  RISCV_SH3ADDUW <-> "sh3add.uw"
}

mapping clause assembly = ZBA_RTYPEUW(rs2, rs1, rd, op)
  <-> zba_rtypeuw_mnemonic(op) ^ spc() ^ reg_name(rd) ^ sep() ^ reg_name(rs1) ^ sep() ^ reg_name(rs2)

function clause execute (ZBA_RTYPEUW(rs2, rs1, rd, op)) = {
  let rs1_val = X(rs1);
  let rs2_val = X(rs2);
  let shamt : bits(2) = match op {
    RISCV_ADDUW    => 0b00,
    RISCV_SH1ADDUW => 0b01,
    RISCV_SH2ADDUW => 0b10,
    RISCV_SH3ADDUW => 0b11
  };
  let result : xlenbits = (EXTZ(rs1_val[31..0]) << shamt) + rs2_val;
  X(rd) = result;
  RETIRE_SUCCESS
}

/* ****************************************************************** */
union clause ast = ZBA_RTYPE : (regidx, regidx, regidx, brop_zba)

mapping clause encdec = ZBA_RTYPE(rs2, rs1, rd, RISCV_SH1ADD) if haveZba()
  <-> 0b0010000 @ rs2 @ rs1 @ 0b010 @ rd @ 0b0110011 if haveZba()
mapping clause encdec = ZBA_RTYPE(rs2, rs1, rd, RISCV_SH2ADD) if haveZba()
  <-> 0b0010000 @ rs2 @ rs1 @ 0b100 @ rd @ 0b0110011 if haveZba()
mapping clause encdec = ZBA_RTYPE(rs2, rs1, rd, RISCV_SH3ADD) if haveZba()
  <-> 0b0010000 @ rs2 @ rs1 @ 0b110 @ rd @ 0b0110011 if haveZba()

mapping zba_rtype_mnemonic : brop_zba <-> string = {
  RISCV_SH1ADD <-> "sh1add",
  RISCV_SH2ADD <-> "sh2add",
  RISCV_SH3ADD <-> "sh3add"
}

mapping clause assembly = ZBA_RTYPE(rs2, rs1, rd, op)
  <-> zba_rtype_mnemonic(op) ^ spc() ^ reg_name(rd) ^ sep() ^ reg_name(rs1) ^ sep() ^ reg_name(rs2)

function clause execute (ZBA_RTYPE(rs2, rs1, rd, op)) = {
  let rs1_val = X(rs1);
  let rs2_val = X(rs2);
  let shamt : bits(2) = match op {
    RISCV_SH1ADD => 0b01,
    RISCV_SH2ADD => 0b10,
    RISCV_SH3ADD => 0b11
  };
  let result : xlenbits = (rs1_val << shamt) + rs2_val;
  X(rd) = result;
  RETIRE_SUCCESS
}
