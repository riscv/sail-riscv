/*=======================================================================================*/
/*  RISCV Sail Model                                                                     */
/*                                                                                       */
/*  This Sail RISC-V architecture model, comprising all files and                        */
/*  directories except for the snapshots of the Lem and Sail libraries                   */
/*  in the prover_snapshots directory (which include copies of their                     */
/*  licences), is subject to the BSD two-clause licence below.                           */
/*                                                                                       */
/*  Copyright (c) 2017-2021                                                              */
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

/* *****************************************************************/
/* This file specifies the 64-bit Data Computation Instructions added by the 'P' extension. */

/* Programming Langauge Lab, Department of Computer Science, National Tsing-Hua University, Taiwan */
/* Academia Sinica, Taiwan*/
/* Andes Technology Corporation*/

/* PEXT_64BITS_ADD_SUB AST */
union clause ast = PEXT_64BITS_ADD_SUB : (regidx, regidx, regidx, p_inst_64bits_add_sub)

mapping clause encdec = PEXT_64BITS_ADD_SUB(rs2, rs1, rd, ADD64) <->
  0b1100000 @ rs2 @ rs1 @ 0b001 @ rd @ 0b1110111
mapping clause encdec = PEXT_64BITS_ADD_SUB(rs2, rs1, rd, KADD64) <->
  0b1001000 @ rs2 @ rs1 @ 0b001 @ rd @ 0b1110111
mapping clause encdec = PEXT_64BITS_ADD_SUB(rs2, rs1, rd, RADD64) <->
  0b1000000 @ rs2 @ rs1 @ 0b001 @ rd @ 0b1110111
mapping clause encdec = PEXT_64BITS_ADD_SUB(rs2, rs1, rd, UKADD64) <->
  0b1011000 @ rs2 @ rs1 @ 0b001 @ rd @ 0b1110111
mapping clause encdec = PEXT_64BITS_ADD_SUB(rs2, rs1, rd, URADD64) <->
  0b1010000 @ rs2 @ rs1 @ 0b001 @ rd @ 0b1110111
mapping clause encdec = PEXT_64BITS_ADD_SUB(rs2, rs1, rd, SUB64) <->
  0b1100001 @ rs2 @ rs1 @ 0b001 @ rd @ 0b1110111
mapping clause encdec = PEXT_64BITS_ADD_SUB(rs2, rs1, rd, KSUB64) <->
  0b1001001 @ rs2 @ rs1 @ 0b001 @ rd @ 0b1110111
mapping clause encdec = PEXT_64BITS_ADD_SUB(rs2, rs1, rd, RSUB64) <->
  0b1000001 @ rs2 @ rs1 @ 0b001 @ rd @ 0b1110111
mapping clause encdec = PEXT_64BITS_ADD_SUB(rs2, rs1, rd, UKSUB64) <->
  0b1011001 @ rs2 @ rs1 @ 0b001 @ rd @ 0b1110111
mapping clause encdec = PEXT_64BITS_ADD_SUB(rs2, rs1, rd, URSUB64) <->
  0b1010001 @ rs2 @ rs1 @ 0b001 @ rd @ 0b1110111

function clause execute (PEXT_64BITS_ADD_SUB(rs2, rs1, rd, op)) = {
  results : bits(64) = zeros();
  rs1_val : bits(64) = zeros();
  rs2_val : bits(64) = zeros();
  if sizeof(xlen) == 32
  then {
    rs1_val = X(rs1 | 0b00001) @ X(rs1 & 0b11110);
    rs2_val = X(rs2 | 0b00001) @ X(rs2 & 0b11110);
  }  
  else {
    rs1_val = X(rs1);
    rs2_val = X(rs2);
  }; 
  results = match op {
    ADD64   => rs1_val + rs2_val,
    KADD64  => kadd(rs1_val, rs2_val),
    RADD64  => radd(rs1_val, rs2_val),
    UKADD64 => ukadd(rs1_val, rs2_val),
    URADD64 => uradd(rs1_val, rs2_val),
    SUB64   => rs1_val - rs2_val,
    KSUB64  => ksub(rs1_val, rs2_val),
    RSUB64  => rsub(rs1_val, rs2_val),
    UKSUB64 => uksub(rs1_val, rs2_val),
    URSUB64 => ursub(rs1_val, rs2_val)
  };
  if sizeof(xlen) == 32
  then {
    X(rd | 0b00001) = results[63..32];
    X(rd & 0b11110) = results[31..0];
  }  
  else X(rd) = results;
  RETIRE_SUCCESS
}

mapping p_64bits_add_sub_mapping : p_inst_64bits_add_sub <-> string = {
    ADD64   <-> "ADD64",
    RADD64  <-> "RADD64",
    URADD64 <-> "URADD64",
    KADD64  <-> "KADD64",
    UKADD64 <-> "UKADD64",
    SUB64   <-> "SUB64",
    RSUB64  <-> "RSUB64",
    URSUB64 <-> "URSUB64",
    KSUB64  <-> "KSUB64",
    UKSUB64 <-> "UKSUB64"
}

mapping clause assembly = PEXT_64BITS_ADD_SUB(rs2, rs1, rd, p_inst)
  <-> p_64bits_add_sub_mapping(p_inst) ^ spc() ^ reg_name(rd) ^ sep() ^ reg_name(rs1) ^ sep() ^ reg_name(rs2)

/* 64bits profile 32 bits mul with 64bits add/sub instructions */
union clause ast = PEXT_32_MUL_64_ADD_SUB : (regidx, regidx, regidx, p_inst_32_mul_64_add_sub)

mapping clause encdec = PEXT_32_MUL_64_ADD_SUB(rs2, rs1, rd, SMAR64) <->
  0b1000010 @ rs2 @ rs1 @ 0b001 @ rd @ 0b1110111
mapping clause encdec = PEXT_32_MUL_64_ADD_SUB(rs2, rs1, rd, SMSR64) <->
  0b1000011 @ rs2 @ rs1 @ 0b001 @ rd @ 0b1110111
mapping clause encdec = PEXT_32_MUL_64_ADD_SUB(rs2, rs1, rd, UMAR64) <->
  0b1010010 @ rs2 @ rs1 @ 0b001 @ rd @ 0b1110111
mapping clause encdec = PEXT_32_MUL_64_ADD_SUB(rs2, rs1, rd, UMSR64) <->
  0b1010011 @ rs2 @ rs1 @ 0b001 @ rd @ 0b1110111
mapping clause encdec = PEXT_32_MUL_64_ADD_SUB(rs2, rs1, rd, KMAR64) <->
  0b1001010 @ rs2 @ rs1 @ 0b001 @ rd @ 0b1110111
mapping clause encdec = PEXT_32_MUL_64_ADD_SUB(rs2, rs1, rd, KMSR64) <->
  0b1001011 @ rs2 @ rs1 @ 0b001 @ rd @ 0b1110111
mapping clause encdec = PEXT_32_MUL_64_ADD_SUB(rs2, rs1, rd, UKMAR64) <->
  0b1011010 @ rs2 @ rs1 @ 0b001 @ rd @ 0b1110111
mapping clause encdec = PEXT_32_MUL_64_ADD_SUB(rs2, rs1, rd, UKMSR64) <->
  0b1011011 @ rs2 @ rs1 @ 0b001 @ rd @ 0b1110111

function clause execute (PEXT_32_MUL_64_ADD_SUB(rs2, rs1, rd, op)) = {
  let rs1_val = X(rs1);
  let rs2_val = X(rs2);
  result : bits(64) = zeros();
  if sizeof(xlen) == 32
  then {
      let rs1_word = slice(rs1_val, 0, 32);
      let rs2_word = slice(rs2_val, 0, 32);
      result = match op {
      SMAR64  => (X(rd | 0b00001) @ X(rd & 0b11110)) + smul(rs1_word, rs2_word),
      SMSR64  => (X(rd | 0b00001) @ X(rd & 0b11110)) - smul(rs1_word, rs2_word),
      UMAR64  => (X(rd | 0b00001) @ X(rd & 0b11110)) + umul(rs1_word, rs2_word),
      UMSR64  => (X(rd | 0b00001) @ X(rd & 0b11110)) - umul(rs1_word, rs2_word),
      KMAR64  => kadd((X(rd | 0b00001) @ X(rd & 0b11110)), smul(rs1_word, rs2_word)),
      KMSR64  => ksub((X(rd | 0b00001) @ X(rd & 0b11110)), smul(rs1_word, rs2_word)),
      UKMAR64 => ukadd((X(rd | 0b00001) @ X(rd & 0b11110)), umul(rs1_word, rs2_word)),
      UKMSR64 => uksub((X(rd | 0b00001) @ X(rd & 0b11110)), umul(rs1_word, rs2_word))
    };
    X(rd | 0b00001) = result[63..32];
    X(rd & 0b11110) = result[31..0];
  }
  else {
      let rs1_word_bottom = slice(rs1_val, 0, 32);
      let rs1_word_top = slice(rs1_val, 32, 32);
      let rs2_word_bottom = slice(rs2_val, 0, 32);
      let rs2_word_top = slice(rs2_val, 32, 32);
      result = match op {
      SMAR64  => X(rd) + (smul(rs1_word_bottom, rs2_word_bottom) + smul(rs1_word_top, rs2_word_top)),
      SMSR64  => X(rd) - (smul(rs1_word_bottom, rs2_word_bottom) + smul(rs1_word_top, rs2_word_top)),
      UMAR64  => X(rd) + (umul(rs1_word_bottom, rs2_word_bottom) + umul(rs1_word_top, rs2_word_top)),
      UMSR64  => X(rd) - (umul(rs1_word_bottom, rs2_word_bottom) + umul(rs1_word_top, rs2_word_top)),
      KMAR64  => kadd(X(rd), (smul(rs1_word_bottom, rs2_word_bottom) + smul(rs1_word_top, rs2_word_top))),
      KMSR64  => ksub(X(rd), (smul(rs1_word_bottom, rs2_word_bottom) + smul(rs1_word_top, rs2_word_top))),
      UKMAR64 => {
        let tmp_val : bits(64) = ukadd (umul(rs1_word_bottom, rs2_word_bottom) , umul(rs1_word_top, rs2_word_top));
        ukadd(X(rd), tmp_val)
      },
      UKMSR64 => {
        let tmp_val : bits(64) = ukadd (umul(rs1_word_bottom, rs2_word_bottom) , umul(rs1_word_top, rs2_word_top));
        uksub(X(rd), tmp_val)
      }
    };
    X(rd) = result;
  };
  RETIRE_SUCCESS
}

mapping p_32_mul_64_add_sub_mapping : p_inst_32_mul_64_add_sub <-> string = {
    SMAR64  <-> "SMAR64",
    SMSR64  <-> "SMSR64",
    UMAR64  <-> "UMAR64",
    UMSR64  <-> "UMSR64",
    KMAR64  <-> "KMAR64",
    KMSR64  <-> "KMSR64",
    UKMAR64 <-> "UKMAR64",
    UKMSR64 <-> "UKMSR64"
}

mapping clause assembly = PEXT_32_MUL_64_ADD_SUB(rs2, rs1, rd, p_inst)
  <-> p_32_mul_64_add_sub_mapping(p_inst) ^ spc() ^ reg_name(rd) ^ sep() ^ reg_name(rs1) ^ sep() ^ reg_name(rs2)

/* 64bits profile 16 bits mul with 64bits add/sub instructions */
union clause ast = PEXT_16_MUL_64_ADD_SUB : (regidx, regidx, regidx, p_inst_16_mul_64_add_sub)

mapping clause encdec = PEXT_16_MUL_64_ADD_SUB(rs2, rs1, rd, SMALBB) <->
  0b1000100 @ rs2 @ rs1 @ 0b001 @ rd @ 0b1110111
mapping clause encdec = PEXT_16_MUL_64_ADD_SUB(rs2, rs1, rd, SMALBT) <->
  0b1001100 @ rs2 @ rs1 @ 0b001 @ rd @ 0b1110111
mapping clause encdec = PEXT_16_MUL_64_ADD_SUB(rs2, rs1, rd, SMALTT) <->
  0b1010100 @ rs2 @ rs1 @ 0b001 @ rd @ 0b1110111
mapping clause encdec = PEXT_16_MUL_64_ADD_SUB(rs2, rs1, rd, SMALDA) <->
  0b1000110 @ rs2 @ rs1 @ 0b001 @ rd @ 0b1110111
mapping clause encdec = PEXT_16_MUL_64_ADD_SUB(rs2, rs1, rd, SMALXDA) <->
  0b1001110 @ rs2 @ rs1 @ 0b001 @ rd @ 0b1110111
mapping clause encdec = PEXT_16_MUL_64_ADD_SUB(rs2, rs1, rd, SMALDS) <->
  0b1000101 @ rs2 @ rs1 @ 0b001 @ rd @ 0b1110111
mapping clause encdec = PEXT_16_MUL_64_ADD_SUB(rs2, rs1, rd, SMALDRS) <->
  0b1001101 @ rs2 @ rs1 @ 0b001 @ rd @ 0b1110111
mapping clause encdec = PEXT_16_MUL_64_ADD_SUB(rs2, rs1, rd, SMALXDS) <->
  0b1010101 @ rs2 @ rs1 @ 0b001 @ rd @ 0b1110111 
mapping clause encdec = PEXT_16_MUL_64_ADD_SUB(rs2, rs1, rd, SMSLDA) <->
  0b1010110 @ rs2 @ rs1 @ 0b001 @ rd @ 0b1110111
mapping clause encdec = PEXT_16_MUL_64_ADD_SUB(rs2, rs1, rd, SMSLXDA) <->
  0b1011110 @ rs2 @ rs1 @ 0b001 @ rd @ 0b1110111
function clause execute (PEXT_16_MUL_64_ADD_SUB(rs2, rs1, rd, op)) = {
  let rs1_val = X(rs1);
  let rs2_val = X(rs2);
  result : bits(64) = zeros();
  foreach (i from 0 to (sizeof(xlen) - 32) by 32) {
    let rs1_half_top = slice(rs1_val, i+16, 16);
    let rs1_half_bottom = slice(rs1_val, i, 16);
    let rs2_half_top = slice(rs2_val, i+16, 16);
    let rs2_half_bottom = slice(rs2_val, i, 16);
    result = match op {
      SMALBB  => result + EXTS(smul(rs1_half_bottom, rs2_half_bottom)),
      SMALBT  => result + EXTS(smul(rs1_half_bottom, rs2_half_top)),
      SMALTT  => result + EXTS(smul(rs1_half_top, rs2_half_top)),
      SMALDA  => result + EXTS(smul(rs1_half_top, rs2_half_top)) + EXTS(smul(rs1_half_bottom, rs2_half_bottom)),
      SMALXDA => result + EXTS(smul(rs1_half_top, rs2_half_bottom)) + EXTS(smul(rs1_half_bottom, rs2_half_top)),
      SMALDS  => result + EXTS(smul(rs1_half_top, rs2_half_top)) - EXTS(smul(rs1_half_bottom, rs2_half_bottom)),
      SMALDRS => result + EXTS(smul(rs1_half_bottom, rs2_half_bottom)) - EXTS(smul(rs1_half_top, rs2_half_top)),
      SMALXDS => result + EXTS(smul(rs1_half_top, rs2_half_bottom)) - EXTS(smul(rs1_half_bottom, rs2_half_top)),
      SMSLDA  => result - EXTS(smul(rs1_half_top, rs2_half_top)) - EXTS(smul(rs1_half_bottom, rs2_half_bottom)),
      SMSLXDA => result - EXTS(smul(rs1_half_top, rs2_half_bottom)) - EXTS(smul(rs1_half_bottom, rs2_half_top))
    };
  };
  if sizeof(xlen) == 32
  then {
    result = result + (X(rd | 0b00001) @ X(rd & 0b11110));
    X(rd | 0b00001) = result[63..32];
    X(rd & 0b11110) = result[31..0];
  }
  else {
    X(rd) = X(rd) + result;
  };
  RETIRE_SUCCESS
}

mapping p_16_mul_64_add_sub_mapping : p_inst_16_mul_64_add_sub <-> string = {
    SMALBB  <-> "SMALBB",
    SMALBT  <-> "SMALBT",
    SMALTT  <-> "SMALTT",
    SMALDA  <-> "SMALDA",
    SMALXDA <-> "SMALXDA",
    SMALDS  <-> "SMALDS",
    SMALDRS <-> "SMALDRS",
    SMALXDS <-> "SMALXDS",
    SMSLDA  <-> "SMSLDA",
    SMSLXDA <-> "SMSLXDA"
}

mapping clause assembly = PEXT_16_MUL_64_ADD_SUB(rs2, rs1, rd, p_inst)
  <-> p_16_mul_64_add_sub_mapping(p_inst) ^ spc() ^ reg_name(rd) ^ sep() ^ reg_name(rs1) ^ sep() ^ reg_name(rs2)