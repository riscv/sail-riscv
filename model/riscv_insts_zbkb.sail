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
union clause ast = ZBKB_RTYPE : (regidx, regidx, regidx, brop_zbkb)

mapping clause encdec = ZBKB_RTYPE(rs2, rs1, rd, RISCV_PACK) if haveZbkb()
  <-> 0b0000100 @ rs2 @ rs1 @ 0b100 @ rd @ 0b0110011 if haveZbkb()

mapping clause encdec = ZBKB_RTYPE(rs2, rs1, rd, RISCV_PACKH) if haveZbkb()
  <-> 0b0000100 @ rs2 @ rs1 @ 0b111 @ rd @ 0b0110011 if haveZbkb()

mapping zbkb_rtype_mnemonic : brop_zbkb <-> string = {
  RISCV_PACK  <-> "pack",
  RISCV_PACKH <-> "packh"
}

mapping clause assembly = ZBKB_RTYPE(rs2, rs1, rd, op)
  <-> zbkb_rtype_mnemonic(op) ^ spc() ^ reg_name(rd) ^ sep() ^ reg_name(rs1) ^ sep() ^ reg_name(rs2)

function clause execute (ZBKB_RTYPE(rs2, rs1, rd, op)) = {
  let rs1_val = X(rs1);
  let rs2_val = X(rs2);
  let result : xlenbits = match op {
    RISCV_PACK  => rs2_val[(sizeof(xlen_bytes)*4 - 1)..0] @ rs1_val[(sizeof(xlen_bytes)*4 - 1)..0],
    RISCV_PACKH => zero_extend(rs2_val[7..0] @ rs1_val[7..0])
  };
  X(rd) = result;
  RETIRE_SUCCESS
}

/* ****************************************************************** */
union clause ast = ZBKB_PACKW : (regidx, regidx, regidx)

mapping clause encdec = ZBKB_PACKW(rs2, rs1, rd) if haveZbkb() & sizeof(xlen) == 64
  <-> 0b0000100 @ rs2 @ rs1 @ 0b100 @ rd @ 0b0111011 if haveZbkb() & sizeof(xlen) == 64

mapping clause assembly = ZBKB_PACKW(rs2, rs1, rd)
  <-> "packw" ^ spc() ^ reg_name(rd) ^ sep() ^ reg_name(rs1) ^ sep() ^ reg_name(rs2)

function clause execute (ZBKB_PACKW(rs2, rs1, rd)) = {
  assert(sizeof(xlen) == 64);
  let rs1_val = X(rs1);
  let rs2_val = X(rs2);
  let result : bits(32) = rs2_val[15..0] @ rs1_val[15..0];
  X(rd) = sign_extend(result);
  RETIRE_SUCCESS
}

/* ****************************************************************** */
union clause ast = RISCV_ZIP : (regidx, regidx)

mapping clause encdec = RISCV_ZIP(rs1, rd) if haveZbkb() & sizeof(xlen) == 32
  <-> 0b000010001111 @ rs1 @ 0b001 @ rd @ 0b0010011 if haveZbkb() & sizeof(xlen) == 32

mapping clause assembly = RISCV_ZIP(rs1, rd)
  <-> "zip" ^ spc() ^ reg_name(rd) ^ sep() ^ reg_name(rs1)

function clause execute (RISCV_ZIP(rs1, rd)) = {
  assert(sizeof(xlen) == 32);
  let rs1_val = X(rs1);
  result : xlenbits = zeros();
  foreach (i from 0 to (sizeof(xlen_bytes)*4 - 1)) {
    result[i*2] = rs1_val[i];
    result[i*2 + 1] = rs1_val[i + sizeof(xlen_bytes)*4];
  };
  X(rd) = result;
  RETIRE_SUCCESS
}

/* ****************************************************************** */
union clause ast = RISCV_UNZIP : (regidx, regidx)

mapping clause encdec = RISCV_UNZIP(rs1, rd) if haveZbkb() & sizeof(xlen) == 32
  <-> 0b000010001111 @ rs1 @ 0b101 @ rd @ 0b0010011 if haveZbkb() & sizeof(xlen) == 32

mapping clause assembly = RISCV_UNZIP(rs1, rd)
  <-> "unzip" ^ spc() ^ reg_name(rd) ^ sep() ^ reg_name(rs1)

function clause execute (RISCV_UNZIP(rs1, rd)) = {
  assert(sizeof(xlen) == 32);
  let rs1_val = X(rs1);
  result : xlenbits = zeros();
  foreach (i from 0 to (sizeof(xlen_bytes)*4 - 1)) {
    result[i] = rs1_val[i*2];
    result[i + sizeof(xlen_bytes)*4] = rs1_val[i*2 + 1];
  };
  X(rd) = result;
  RETIRE_SUCCESS
}

/* ****************************************************************** */
union clause ast = RISCV_BREV8 : (regidx, regidx)

mapping clause encdec = RISCV_BREV8(rs1, rd) if haveZbkb()
  <-> 0b011010000111 @ rs1 @ 0b101 @ rd @ 0b0010011 if haveZbkb()

mapping clause assembly = RISCV_BREV8(rs1, rd)
  <-> "brev8" ^ spc() ^ reg_name(rd) ^ sep() ^ reg_name(rs1)

function clause execute (RISCV_BREV8(rs1, rd)) = {
  let rs1_val = X(rs1);
  result : xlenbits = zeros();
  foreach (i from 0 to (sizeof(xlen) - 8) by 8)
    result[i+7..i] = reverse(rs1_val[i+7..i]);
  X(rd) = result;
  RETIRE_SUCCESS
}
