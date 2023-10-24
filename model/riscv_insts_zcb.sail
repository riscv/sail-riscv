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
/*    Nambi JU                                                                           */
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
/* This file specifies the instructions in the 'ZCEE' extension.      */
/* ****************************************************************** */

/* ------------------------------------------------------------------ */
/* Sail Model for the c.l and c.s encoding group                */
/* ------------------------------------------------------------------ */

/* ****************************************************************** */
union clause ast = C_LBU : (bits(2), cregidx, cregidx)

mapping clause encdec_compressed = C_LBU(ui65, rs1, rd)
  <-> 0b100 @ 0b000 @ rs1 : cregidx @ ui65 : bits(2) @ rd : cregidx @ 0b00

function clause execute (C_LBU(uimm, rsc, rdc)) = {
  let immext : xlenbits = zero_extend(uimm);
  let imm : bits(12) = zero_extend(uimm);

  let rd = creg2reg_idx(rdc);
  let rs = creg2reg_idx(rsc);
  execute(LOAD(imm, rs, rd, true, BYTE, false, false))
}

mapping clause assembly = C_LBU(uimm, rsc, rdc)
  <-> "c.lbu" ^ spc() ^ creg_name(rdc) ^ sep() ^ creg_name(rsc) ^ sep() ^ hex_bits_5(uimm @ 0b000)
/* ****************************************************************** */
union clause ast = C_LHU : (bits(1), cregidx, cregidx)

mapping clause encdec_compressed = C_LHU(ui5, rs1, rd)
  <-> 0b100 @ 0b001 @ rs1 : cregidx @ 0b0 @ ui5 : bits(1) @ rd : cregidx @ 0b00

function clause execute (C_LHU(uimm, rsc, rdc)) = {
  let immext : xlenbits = zero_extend(uimm);
  let imm : bits(12) = zero_extend(uimm);

  let rd = creg2reg_idx(rdc);
  let rs = creg2reg_idx(rsc);

  execute(LOAD(imm, rs, rd, true, HALF, false, false))
}

mapping clause assembly = C_LHU(uimm, rsc, rdc)
  <-> "c.lhu" ^ spc() ^ creg_name(rdc) ^ sep() ^ creg_name(rsc) ^ sep() ^ hex_bits_4(uimm @ 0b000)
/* ****************************************************************** */
union clause ast = C_LH : (bits(1), cregidx, cregidx)

mapping clause encdec_compressed = C_LH(ui5, rs1, rd)
  <-> 0b100 @ 0b001 @ rs1 : cregidx @ 0b1 @ ui5 : bits(1) @ rd : cregidx @ 0b00

function clause execute (C_LH(uimm, rsc, rdc)) = {
  let immext : xlenbits = zero_extend(uimm);
  let imm : bits(12) = zero_extend(uimm);

  let rd = creg2reg_idx(rdc);
  let rs = creg2reg_idx(rsc);

  let rsext = X(rs) + immext;
  X(rs) = rsext;
  execute(LOAD(imm, rs, rd, false, HALF, false, false))
}

mapping clause assembly = C_LH(uimm, rsc, rdc)
  <-> "c.lh" ^ spc() ^ creg_name(rdc) ^ sep() ^ creg_name(rsc) ^ sep() ^ hex_bits_4(uimm @ 0b000)
/* ****************************************************************** */

union clause ast = C_SB : (bits(2), cregidx, cregidx)

mapping clause encdec_compressed = C_SB(ui65, rs1, rs2)
  <-> 0b100 @ 0b010 @ rs1 : cregidx @ ui65 : bits(2) @ rs2 : cregidx @ 0b00

function clause execute (C_SB(uimm, rs1c, rs2c)) = {
  let immext : xlenbits = zero_extend(uimm);
  let imm : bits(12) = zero_extend(uimm);

  let rs1c = creg2reg_idx(rs1c);
  let rs2c = creg2reg_idx(rs2c);
  execute(STORE(imm, rs2c, rs1c, BYTE, false, false))
}

mapping clause assembly = C_SB(uimm, rs1, rs2)
  <-> "c.sb" ^ spc() ^ creg_name(rs2) ^ sep() ^ creg_name(rs1) ^ sep() ^ hex_bits_5(uimm @ 0b000)
/* ****************************************************************** */
union clause ast = C_SH : (bits(1), cregidx, cregidx)

mapping clause encdec_compressed = C_SH(ui5, rs1, rs2)
  <-> 0b100 @ 0b011 @ rs1 : cregidx @ 0b0 @ ui5 : bits(1) @ rs2 : cregidx @ 0b00

function clause execute (C_SH(uimm, rs1c, rs2c)) = {
  let immext : xlenbits = zero_extend(uimm);
  let imm : bits(12) = zero_extend(uimm);

  let rs2c = creg2reg_idx(rs2c);
  let rs1c = creg2reg_idx(rs1c);
  execute(STORE(imm, rs2c, rs1c, HALF, false, false))
}

mapping clause assembly = C_SH(uimm, rs1, rs2)
  <-> "c.sh" ^ spc() ^ creg_name(rs2) ^ sep() ^ creg_name(rs1) ^ sep() ^ hex_bits_4(uimm @ 0b000)
/* ****************************************************************** */

/* ------------------------------------------------------------------ */
/* Sail Model for the c.zext and c.sext encoding group                */
/* ------------------------------------------------------------------ */
/* ****************************************************************** */
union clause ast = C_ZEXT_B : (cregidx)

mapping clause encdec_compressed = C_ZEXT_B(rsd)
  <-> 0b100 @ 0b111 @ rsd : cregidx @ 0b11 @ 0b000 @ 0b01

function clause execute (C_ZEXT_B(rsd)) = {
  let rsdc = creg2reg_idx(rsd);

  X(rsdc) = zero_extend(X(rsdc)[7..0]);
  RETIRE_SUCCESS
}

mapping clause assembly = C_ZEXT_B(rsd)
  <-> "c.zext.b" ^ spc() ^ creg_name(rsd)

/* ****************************************************************** */
union clause ast = C_SEXT_B : (cregidx)

mapping clause encdec_compressed = C_SEXT_B(rsd)
  <-> 0b100 @ 0b111 @ rsd : cregidx @ 0b11 @ 0b001 @ 0b01

function clause execute (C_SEXT_B(rsd)) = {
  let rsdc = creg2reg_idx(rsd);

  execute(ZBB_EXTOP(rsdc, rsdc, RISCV_SEXTB))
}

mapping clause assembly = C_SEXT_B(rsd)
  <-> "c.sext.b" ^ spc() ^ creg_name(rsd)
/* ****************************************************************** */
union clause ast = C_ZEXT_H : (cregidx)

mapping clause encdec_compressed = C_ZEXT_H(rsd)
  <-> 0b100 @ 0b111 @ rsd : cregidx @ 0b11 @ 0b010 @ 0b01

function clause execute (C_ZEXT_H(rsd)) = {
  let rsdc = creg2reg_idx(rsd);

  execute(ZBB_EXTOP(rsdc, rsdc, RISCV_ZEXTH))
}

mapping clause assembly = C_ZEXT_H(rsd)
  <-> "c.zext.h" ^ spc() ^ creg_name(rsd)

/* ****************************************************************** */
union clause ast = C_SEXT_H : (cregidx)

mapping clause encdec_compressed = C_SEXT_H(rsd)
  <-> 0b100 @ 0b111 @ rsd : cregidx @ 0b11 @ 0b011 @ 0b01

function clause execute (C_SEXT_H(rsd)) = {
  let rsdc = creg2reg_idx(rsd);

  execute(ZBB_EXTOP(rsdc, rsdc,  RISCV_SEXTH))
}

mapping clause assembly = C_SEXT_H(rsd)
  <-> "c.sext.h" ^ spc() ^ creg_name(rsd)
/* ****************************************************************** */
union clause ast = C_ZEXT_W : (cregidx)

mapping clause encdec_compressed = C_ZEXT_W(rsd)
  <-> 0b100 @ 0b111 @ rsd : cregidx @ 0b11 @ 0b100 @ 0b01

function clause execute (C_ZEXT_W(rsd)) = {
  let rsdc = creg2reg_idx(rsd);

  X(rsdc) = zero_extend(X(rsdc)[31..0]);
  RETIRE_SUCCESS
}

mapping clause assembly = C_ZEXT_W(rsd)
  <-> "c.zext.w" ^ spc() ^ creg_name(rsd)

/* ****************************************************************** */

/* ------------------------------------------------------------------ */
/* Sail Model for the c.mul encoding group                            */
/* ------------------------------------------------------------------ */

/* the assembly abstract syntax tree (AST) clause for the CMUL instructions */
union clause ast = C_MUL : (cregidx,cregidx)

/* the encode/decode mapping between AST elements and 16-bit half words */

mapping clause encdec_compressed = C_MUL(rsd, rs2)
  <-> 0b100 @ 0b111 @ rsd : cregidx @ 0b00 @ rs2 : cregidx @ 0b01

function clause execute (C_MUL(rsd,rs2)) = {
  let rd = creg2reg_idx(rsd);
  let rs = creg2reg_idx(rs2);

  execute(MUL((rs, rd, rd, false, true, true))
}

mapping clause assembly = C_MUL(rsd, rs2) <->
  "c.mul" ^ spc() ^ creg_name(rsd) ^ spc() ^ creg_name(rs2)

/* ------------------------------------------------------------------ */
/* Sail Model for the c.not encoding group                            */
/* ------------------------------------------------------------------ */

/* the assembly abstract syntax tree (AST) clause for the CNOT instructions */

union clause ast = C_NOT : (cregidx)

/* the encode/decode mapping between AST elements and 16-bit half words */

mapping clause encdec_compressed = C_NOT(rsd)
  <-> 0b100 @ 0b111 @ rsd : cregidx @ 0b11 @ 0b101 @ 0b01

function clause execute (C_NOT(rsd)) = {
  let rsd = creg2reg_idx(rsd);
  X(rsd) = ~(X(rsd));
  RETIRE_SUCCESS
}

mapping clause assembly = C_NOT(rsd) <->
  "c.not" ^ spc() ^ creg_name(rsd)
