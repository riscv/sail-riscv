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

/* ********************************************************************* */
/* This file specifies the compressed floating-point instructions.
 *
 * These instructions are only legal if misa[C] and misa[D]
 * are set.
 */

/* ****************************************************************** */
union clause ast = C_FLDSP : (bits(6), regidx)

mapping clause encdec_compressed = C_FLDSP(ui86 @ ui5 @ ui43, rd)
      if (sizeof(xlen) == 32 | sizeof(xlen) == 64) & haveRVC() & haveDExt()
  <-> 0b001 @ ui5 : bits(1) @ rd : regidx @ ui43 : bits(2) @ ui86 : bits(3) @ 0b10
      if (sizeof(xlen) == 32 | sizeof(xlen) == 64) & haveRVC() & haveDExt()

function clause execute (C_FLDSP(uimm, rd)) = {
  let imm : bits(12) = zero_extend(uimm @ 0b000);
  execute(LOAD_FP(imm, sp, rd, DOUBLE))
}

mapping clause assembly = C_FLDSP(uimm, rd)
      if (sizeof(xlen) == 32 | sizeof(xlen) == 64)
  <-> "c.fldsp" ^ spc() ^ reg_name(rd) ^ sep() ^ hex_bits_6(uimm)
      if (sizeof(xlen) == 32 | sizeof(xlen) == 64)

/* ****************************************************************** */
union clause ast = C_FSDSP : (bits(6), regidx)

mapping clause encdec_compressed = C_FSDSP(ui86 @ ui53, rs2)
      if (sizeof(xlen) == 32 | sizeof(xlen) == 64) & haveRVC() & haveDExt()
  <-> 0b101 @ ui53 : bits(3) @ ui86 : bits(3) @ rs2 : regidx @ 0b10
      if (sizeof(xlen) == 32 | sizeof(xlen) == 64) & haveRVC() & haveDExt()

function clause execute (C_FSDSP(uimm, rs2)) = {
  let imm : bits(12) = zero_extend(uimm @ 0b000);
  execute(STORE_FP(imm, rs2, sp, DOUBLE))
}

mapping clause assembly = C_FSDSP(uimm, rs2)
      if (sizeof(xlen) == 32 | sizeof(xlen) == 64)
  <-> "c.fsdsp" ^ spc() ^ reg_name(rs2) ^ sep() ^ hex_bits_6(uimm)
      if (sizeof(xlen) == 32 | sizeof(xlen) == 64)

/* ****************************************************************** */
union clause ast = C_FLD : (bits(5), cregidx, cregidx)

mapping clause encdec_compressed = C_FLD(ui76 @ ui53, rs1, rd)
      if (sizeof(xlen) == 32 | sizeof(xlen) == 64) & haveRVC() & haveDExt()
  <-> 0b001 @ ui53 : bits(3) @ rs1 : cregidx @ ui76 : bits(2) @ rd : cregidx @ 0b00
      if (sizeof(xlen) == 32 | sizeof(xlen) == 64) & haveRVC() & haveDExt()

function clause execute (C_FLD(uimm, rsc, rdc)) = {
  let imm : bits(12) = zero_extend(uimm @ 0b000);
  let rd = creg2reg_idx(rdc);
  let rs = creg2reg_idx(rsc);
  execute(LOAD_FP(imm, rs, rd, DOUBLE))
}

mapping clause assembly = C_FLD(uimm, rsc, rdc)
      if (sizeof(xlen) == 32 | sizeof(xlen) == 64)
  <-> "c.fld" ^ spc() ^ creg_name(rdc) ^ sep() ^ creg_name(rsc) ^ sep() ^ hex_bits_8(uimm @ 0b000)
      if (sizeof(xlen) == 32 | sizeof(xlen) == 64)

/* ****************************************************************** */
union clause ast = C_FSD : (bits(5), cregidx, cregidx)

mapping clause encdec_compressed = C_FSD(ui76 @ ui53, rs1, rs2)
      if (sizeof(xlen) == 32 | sizeof(xlen) == 64) & haveRVC() & haveDExt()
  <-> 0b101 @ ui53 : bits(3) @ rs1 : bits(3) @ ui76 : bits(2) @ rs2 : bits(3) @ 0b00
      if (sizeof(xlen) == 32 | sizeof(xlen) == 64) & haveRVC() & haveDExt()

function clause execute (C_FSD(uimm, rsc1, rsc2)) = {
  let imm : bits(12) = zero_extend(uimm @ 0b000);
  let rs1 = creg2reg_idx(rsc1);
  let rs2 = creg2reg_idx(rsc2);
  execute(STORE_FP(imm, rs2, rs1, DOUBLE))
}

mapping clause assembly = C_FSD(uimm, rsc1, rsc2)
      if (sizeof(xlen) == 32 | sizeof(xlen) == 64)
  <-> "c.fsd" ^ spc() ^ creg_name(rsc1) ^ sep() ^ creg_name(rsc2) ^ sep() ^ hex_bits_8(uimm @ 0b000)
      if (sizeof(xlen) == 32 | sizeof(xlen) == 64)
