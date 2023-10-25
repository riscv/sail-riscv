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
/* This file enables handling (ignoring) various hint instructions    */
/* that are not already implicitly handled.                           */

/* ****************************************************************** */
union clause ast = C_NOP_HINT : (bits(6))

mapping clause encdec_compressed = C_NOP_HINT(im5 @ im40)
      if im5 @ im40 != 0b000000
  <-> 0b000 @ im5 : bits(1) @ 0b00000 @ im40 : bits(5) @ 0b01
      if im5 @ im40 != 0b000000

function clause execute C_NOP_HINT(imm) = RETIRE_SUCCESS

mapping clause assembly = C_NOP_HINT(imm) <-> "c.nop.hint." ^ spc() ^ hex_bits_6(imm)

/* ****************************************************************** */
union clause ast = C_ADDI_HINT : (regidx)

mapping clause encdec_compressed = C_ADDI_HINT(rsd)
      if rsd != zreg
  <-> 0b000 @ 0b0 @ rsd : regidx @ 0b00000 @ 0b01
      if rsd != zreg

function clause execute (C_ADDI_HINT(rsd)) = RETIRE_SUCCESS

mapping clause assembly = C_ADDI_HINT(rsd)
      if rsd != zreg
  <-> "c.addi.hint." ^ spc() ^ reg_name(rsd)
      if rsd != zreg

/* ****************************************************************** */
union clause ast = C_LI_HINT : (bits(6))

mapping clause encdec_compressed = C_LI_HINT(imm5 @ imm40)
  <-> 0b010 @ imm5 : bits(1) @ 0b00000 @ imm40 : bits(5) @ 0b01

function clause execute (C_LI_HINT(imm)) = RETIRE_SUCCESS

mapping clause assembly = C_LI_HINT(imm)
  <-> "c.li.hint." ^ spc() ^ hex_bits_6(imm)

/* ****************************************************************** */
union clause ast = C_LUI_HINT : (bits(6))

mapping clause encdec_compressed = C_LUI_HINT(imm17 @ imm1612)
      if imm17 @ imm1612 != 0b000000
  <-> 0b011 @ imm17 : bits(1) @ 0b00000 @ imm1612 : bits(5) @ 0b01
      if imm17 @ imm1612 != 0b000000

function clause execute (C_LUI_HINT(imm)) = RETIRE_SUCCESS

mapping clause assembly = C_LUI_HINT(imm)
      if imm != 0b000000
  <-> "c.lui.hint." ^ spc() ^ hex_bits_6(imm)
      if imm != 0b000000

/* ****************************************************************** */
union clause ast = C_MV_HINT : (regidx)

mapping clause encdec_compressed = C_MV_HINT(rs2)
      if rs2 != zreg
  <-> 0b100 @ 0b0 @ 0b00000 @ rs2 : regidx @ 0b10
      if rs2 != zreg

function clause execute (C_MV_HINT(rs2)) = RETIRE_SUCCESS

mapping clause assembly = C_MV_HINT(rs2)
      if rs2 != zreg
  <-> "c.mv.hint." ^ spc() ^ reg_name(rs2)
      if rs2 != zreg

/* ****************************************************************** */
union clause ast = C_ADD_HINT : (regidx)

mapping clause encdec_compressed = C_ADD_HINT(rs2)
      if rs2 != zreg
  <-> 0b100 @ 0b1 @ 0b00000 @ rs2 : regidx @ 0b10
      if rs2 != zreg

function clause execute (C_ADD_HINT(rs2)) = RETIRE_SUCCESS

mapping clause assembly = C_ADD_HINT(rs2)
      if rs2 != zreg
  <-> "c.add.hint." ^ spc() ^ reg_name(rs2)
      if rs2 != zreg

/* ****************************************************************** */
union clause ast = C_SLLI_HINT : (bits(6), regidx)

mapping clause encdec_compressed = C_SLLI_HINT(nzui5 @ nzui40, rsd)
      if (nzui5 @ nzui40 == 0b000000 | rsd == zreg) & (sizeof(xlen) == 64 | nzui5 == 0b0)
  <-> 0b000 @ nzui5 : bits(1) @ rsd : regidx @ nzui40 : bits(5) @ 0b10
      if (nzui5 @ nzui40 == 0b000000 | rsd == zreg) & (sizeof(xlen) == 64 | nzui5 == 0b0)

function clause execute (C_SLLI_HINT(shamt, rsd)) = RETIRE_SUCCESS

mapping clause assembly = C_SLLI_HINT(shamt, rsd)
      if shamt == 0b000000 | rsd == zreg
  <-> "c.slli.hint." ^ spc() ^ reg_name(rsd) ^ "." ^ hex_bits_6(shamt)
      if shamt == 0b000000 | rsd == zreg

/* ****************************************************************** */
union clause ast = C_SRLI_HINT : (cregidx)

mapping clause encdec_compressed = C_SRLI_HINT(rsd)
  <-> 0b100 @ 0b0 @ 0b00 @ rsd : cregidx @ 0b00000 @ 0b01

function clause execute (C_SRLI_HINT(rsd)) = RETIRE_SUCCESS

mapping clause assembly = C_SRLI_HINT(rsd)
  <-> "c.srli.hint." ^ spc() ^ creg_name(rsd)

/* ****************************************************************** */
union clause ast = C_SRAI_HINT : (cregidx)

mapping clause encdec_compressed = C_SRAI_HINT(rsd)
  <-> 0b100 @ 0b0 @ 0b01 @ rsd : cregidx @ 0b00000 @ 0b01

function clause execute (C_SRAI_HINT(rsd)) = RETIRE_SUCCESS

mapping clause assembly = C_SRAI_HINT(rsd)
  <-> "c.srai.hint." ^ spc() ^ creg_name(rsd)

/* ****************************************************************** */
/* The reserved fences are not really hints, but for now they
 * are in this file to be also treated as nops to avoid trapping.
 */

union clause ast = FENCE_RESERVED : (bits(4), bits(4), bits(4), regidx, regidx)

mapping clause encdec = FENCE_RESERVED(fm, pred, succ, rs, rd)
      if (fm != 0b0000 & fm != 0b1000) | rs != 0b00000 | rd != 0b00000
  <-> fm : bits(4) @ pred : bits(4) @ succ : bits(4) @ rs : regidx @ 0b000 @ rd : regidx @ 0b0001111
      if (fm != 0b0000 & fm != 0b1000) | rs != 0b00000 | rd != 0b00000

function clause execute (FENCE_RESERVED(fm, pred, succ, rs, rd)) = RETIRE_SUCCESS

mapping clause assembly = FENCE_RESERVED(fm, pred, succ, rs, rd)
      if (fm != 0b0000 & fm != 0b1000) | rs != 0b00000 | rd != 0b00000
  <-> "fence.reserved." ^ fence_bits(pred) ^ "." ^ fence_bits(succ) ^ "."
      ^ reg_name(rs) ^ "." ^ reg_name(rd) ^ "." ^ hex_bits_4(fm)
      if (fm != 0b0000 & fm != 0b1000) | rs != 0b00000 | rd != 0b00000

/* ****************************************************************** */
union clause ast = FENCEI_RESERVED : (bits(12), regidx, regidx)

mapping clause encdec = FENCEI_RESERVED(imm, rs, rd)
      if imm != 0b000000000000 | rs != zreg | rd != zreg
  <-> imm : bits(12) @ rs : regidx @ 0b001 @ rd : regidx @ 0b0001111
      if imm != 0b000000000000 | rs != zreg | rd != zreg

function clause execute FENCEI_RESERVED(imm, rs, rd) = RETIRE_SUCCESS

mapping clause assembly = FENCEI_RESERVED(imm, rs, rd)
      if imm != 0b000000000000 | rs != zreg | rd != zreg
  <-> "fence.i.reserved." ^ reg_name(rd) ^ "." ^ reg_name(rs) ^ "." ^ hex_bits_12(imm)
      if imm != 0b000000000000 | rs != zreg | rd != zreg
