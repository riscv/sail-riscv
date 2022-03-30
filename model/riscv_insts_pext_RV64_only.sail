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
/* This file specifies the RV64 Only Instructions added by the 'P' extension. */

/* Programming Langauge Lab, Department of Computer Science, National Tsing-Hua University, Taiwan */
/* Academia Sinica, Taiwan*/
/* Andes Technology Corporation*/
/* PEXT_64ONLY_ALU_CMP_32 AST */
union clause ast = PEXT_64ONLY_ALU_CMP_32 : (regidx, regidx, regidx, p_64_only_alu_op)

mapping clause encdec = PEXT_64ONLY_ALU_CMP_32(rs2, rs1, rd, ADD32) <->
  0b0100000 @ rs2 @ rs1 @ 0b010 @ rd @ 0b1110111
mapping clause encdec = PEXT_64ONLY_ALU_CMP_32(rs2, rs1, rd, KADD32) <->
  0b0001000 @ rs2 @ rs1 @ 0b010 @ rd @ 0b1110111
mapping clause encdec = PEXT_64ONLY_ALU_CMP_32(rs2, rs1, rd, RADD32) <->
  0b0000000 @ rs2 @ rs1 @ 0b010 @ rd @ 0b1110111
mapping clause encdec = PEXT_64ONLY_ALU_CMP_32(rs2, rs1, rd, UKADD32) <->
  0b0011000 @ rs2 @ rs1 @ 0b010 @ rd @ 0b1110111
mapping clause encdec = PEXT_64ONLY_ALU_CMP_32(rs2, rs1, rd, URADD32) <->
  0b0010000 @ rs2 @ rs1 @ 0b010 @ rd @ 0b1110111
mapping clause encdec = PEXT_64ONLY_ALU_CMP_32(rs2, rs1, rd, SUB32) <->
  0b0100001 @ rs2 @ rs1 @ 0b010 @ rd @ 0b1110111
mapping clause encdec = PEXT_64ONLY_ALU_CMP_32(rs2, rs1, rd, KSUB32) <->
  0b0001001 @ rs2 @ rs1 @ 0b010 @ rd @ 0b1110111
mapping clause encdec = PEXT_64ONLY_ALU_CMP_32(rs2, rs1, rd, RSUB32) <->
  0b0000001 @ rs2 @ rs1 @ 0b010 @ rd @ 0b1110111
mapping clause encdec = PEXT_64ONLY_ALU_CMP_32(rs2, rs1, rd, UKSUB32) <->
  0b0011001 @ rs2 @ rs1 @ 0b010 @ rd @ 0b1110111
mapping clause encdec = PEXT_64ONLY_ALU_CMP_32(rs2, rs1, rd, URSUB32) <->
  0b0010001 @ rs2 @ rs1 @ 0b010 @ rd @ 0b1110111
mapping clause encdec = PEXT_64ONLY_ALU_CMP_32(rs2, rs1, rd, SRA32) <->
  0b0101000 @ rs2 @ rs1 @ 0b010 @ rd @ 0b1110111
mapping clause encdec = PEXT_64ONLY_ALU_CMP_32(rs2, rs1, rd, SRA32_U) <->
  0b0110000 @ rs2 @ rs1 @ 0b010 @ rd @ 0b1110111
mapping clause encdec = PEXT_64ONLY_ALU_CMP_32(rs2, rs1, rd, SRL32) <->
  0b0101001 @ rs2 @ rs1 @ 0b010 @ rd @ 0b1110111
mapping clause encdec = PEXT_64ONLY_ALU_CMP_32(rs2, rs1, rd, SRL32_U) <->
  0b0110001 @ rs2 @ rs1 @ 0b010 @ rd @ 0b1110111
mapping clause encdec = PEXT_64ONLY_ALU_CMP_32(rs2, rs1, rd, SLL32) <->
  0b0101010 @ rs2 @ rs1 @ 0b010 @ rd @ 0b1110111
mapping clause encdec = PEXT_64ONLY_ALU_CMP_32(rs2, rs1, rd, KSLL32) <->
  0b0110010 @ rs2 @ rs1 @ 0b010 @ rd @ 0b1110111
mapping clause encdec = PEXT_64ONLY_ALU_CMP_32(rs2, rs1, rd, KSLRA32) <->
  0b0101011 @ rs2 @ rs1 @ 0b010 @ rd @ 0b1110111
mapping clause encdec = PEXT_64ONLY_ALU_CMP_32(rs2, rs1, rd, KSLRA32_U) <->
  0b0110011 @ rs2 @ rs1 @ 0b010 @ rd @ 0b1110111
mapping clause encdec = PEXT_64ONLY_ALU_CMP_32(rs2, rs1, rd, SMAX32) <->
  0b1001001 @ rs2 @ rs1 @ 0b010 @ rd @ 0b1110111
mapping clause encdec = PEXT_64ONLY_ALU_CMP_32(rs2, rs1, rd, SMIN32) <->
  0b1001000 @ rs2 @ rs1 @ 0b010 @ rd @ 0b1110111
mapping clause encdec = PEXT_64ONLY_ALU_CMP_32(rs2, rs1, rd, UMAX32) <->
  0b1010001 @ rs2 @ rs1 @ 0b010 @ rd @ 0b1110111
mapping clause encdec = PEXT_64ONLY_ALU_CMP_32(rs2, rs1, rd, UMIN32) <->
  0b1010000 @ rs2 @ rs1 @ 0b010 @ rd @ 0b1110111

function clause execute (PEXT_64ONLY_ALU_CMP_32(rs2, rs1, rd, op)) = {
  let rs1_val = X(rs1);
  let rs2_val = X(rs2);
  result : bits(64) = zeros();
  foreach (i from 0 to (sizeof(xlen) - 32) by 32) {
    let rs1_word = slice(rs1_val, i, 32);
    let rs2_word = slice(rs2_val, i, 32);
    result[(i+31)..i] = match op {
      ADD32     => rs1_word + rs2_word,
      RADD32    => radd(rs1_word, rs2_word),
      KADD32    => kadd(rs1_word, rs2_word),
      URADD32   => uradd(rs1_word, rs2_word),
      UKADD32   => ukadd(rs1_word, rs2_word),
      SUB32     => rs1_word - rs2_word,
      RSUB32    => rsub(rs1_word, rs2_word),
      KSUB32    => ksub(rs1_word, rs2_word),
      URSUB32   => ursub(rs1_word, rs2_word),
      UKSUB32   => uksub(rs1_word, rs2_word),
      SRA32     => shift_right_arith(rs1_word, EXTZ(rs2_val[4..0])),
      SRA32_U   => shift_right_arith_u(rs1_word, EXTZ(rs2_val[4..0])),
      SRL32     => shift_right_logic(rs1_word, EXTZ(rs2_val[4..0])),
      SRL32_U   => shift_right_logic_u(rs1_word, EXTZ(rs2_val[4..0])),
      SLL32     => shift_left_logic(rs1_word, EXTZ(rs2_val[4..0])),
      KSLL32    => kshift_left_logic(rs1_word, EXTZ(rs2_val[4..0])),
      KSLRA32   => kslra(rs1_word, EXTS(rs2_val[5..0])),
      KSLRA32_U => kslra_u(rs1_word, EXTS(rs2_val[5..0])),
      SMIN32    => smin(rs1_word, rs2_word),
      SMAX32    => smax(rs1_word, rs2_word),
      UMIN32    => umin(rs1_word, rs2_word),
      UMAX32    => umax(rs1_word, rs2_word)
    };
  };
  X(rd) = result;
  RETIRE_SUCCESS
}

mapping p_64only_alu_cmp_32_mapping : p_64_only_alu_op <-> string = {
    ADD32     <-> "ADD32",
    RADD32    <-> "RADD32",
    URADD32   <-> "URADD32",
    KADD32    <-> "KADD32",
    UKADD32   <-> "UKADD32",
    SUB32     <-> "SUB32",
    RSUB32    <-> "RSUB32",
    URSUB32   <-> "URSUB32",
    KSUB32    <-> "KSUB32",
    UKSUB32   <-> "UKSUB32",
    SRA32     <-> "SRA32",
    SRA32_U   <-> "SRA32_U",
    SRL32     <-> "SRL32",
    SRL32_U   <-> "SRL32_U",
    SLL32     <-> "SLL32",
    KSLL32    <-> "KSLL32",
    KSLRA32   <-> "KSLRA32",
    KSLRA32_U <-> "KSLRA32_U",
    SMAX32    <-> "SMAX32",
    SMIN32    <-> "SMIN32",
    UMAX32    <-> "UMAX32",
    UMIN32    <-> "UMIN32"
}

mapping clause assembly = PEXT_64ONLY_ALU_CMP_32(rs2, rs1, rd, p_inst)
  <-> p_64only_alu_cmp_32_mapping(p_inst) ^ spc() ^ reg_name(rd) ^ sep() ^ reg_name(rs1) ^ sep() ^ reg_name(rs2)

/* PEXT_64ONLY_Q15 AST */
union clause ast = PEXT_64ONLY_Q15 : (regidx, regidx, regidx, p_64_only_q15_op)

mapping clause encdec = PEXT_64ONLY_Q15(rs2, rs1, rd, KHMBB16) <->
  0b1101110 @ rs2 @ rs1 @ 0b001 @ rd @ 0b1110111
mapping clause encdec = PEXT_64ONLY_Q15(rs2, rs1, rd, KHMBT16) <->
  0b1110110 @ rs2 @ rs1 @ 0b001 @ rd @ 0b1110111
mapping clause encdec = PEXT_64ONLY_Q15(rs2, rs1, rd, KHMTT16) <->
  0b1111110 @ rs2 @ rs1 @ 0b001 @ rd @ 0b1110111
mapping clause encdec = PEXT_64ONLY_Q15(rs2, rs1, rd, KDMBB16) <->
  0b1101101 @ rs2 @ rs1 @ 0b001 @ rd @ 0b1110111
mapping clause encdec = PEXT_64ONLY_Q15(rs2, rs1, rd, KDMBT16) <->
  0b1110101 @ rs2 @ rs1 @ 0b001 @ rd @ 0b1110111
mapping clause encdec = PEXT_64ONLY_Q15(rs2, rs1, rd, KDMTT16) <->
  0b1111101 @ rs2 @ rs1 @ 0b001 @ rd @ 0b1110111
mapping clause encdec = PEXT_64ONLY_Q15(rs2, rs1, rd, KDMABB16) <->
  0b1101100 @ rs2 @ rs1 @ 0b001 @ rd @ 0b1110111
mapping clause encdec = PEXT_64ONLY_Q15(rs2, rs1, rd, KDMABT16) <->
  0b1110100 @ rs2 @ rs1 @ 0b001 @ rd @ 0b1110111
mapping clause encdec = PEXT_64ONLY_Q15(rs2, rs1, rd, KDMATT16) <->
  0b1111100 @ rs2 @ rs1 @ 0b001 @ rd @ 0b1110111

function clause execute (PEXT_64ONLY_Q15(rs2, rs1, rd, op)) = {
  let rs1_val = X(rs1);
  let rs2_val = X(rs2);
  let rd_val = X(rd);
  result : bits(64) = zeros();
  foreach (i from 0 to (sizeof(xlen) - 32) by 32) {
  let rs1_half_top = slice(rs1_val, i+16, 16);
  let rs1_half_bottom = slice(rs1_val, i, 16);
  let rs2_half_top = slice(rs2_val, i+16, 16);
  let rs2_half_bottom = slice(rs2_val, i, 16);
  let rd_word = slice(rd_val, i, 32);
    result[(i+31)..i] = match op{
      KHMBB16  => EXTS(signed_saturating_mul_16(rs1_half_bottom, rs2_half_bottom)),
      KHMBT16  => EXTS(signed_saturating_mul_16(rs1_half_bottom, rs2_half_top)),
      KHMTT16  => EXTS(signed_saturating_mul_16(rs1_half_top, rs2_half_top)),
      KDMBB16  => kdm(rs1_half_bottom, rs2_half_bottom),
      KDMBT16  => kdm(rs1_half_bottom, rs2_half_top),
      KDMTT16  => kdm(rs1_half_top, rs2_half_top),
      KDMABB16 => kdmaw(rs1_half_bottom, rs2_half_bottom, rd_word),
      KDMABT16 => kdmaw(rs1_half_bottom, rs2_half_top, rd_word),
      KDMATT16 => kdmaw(rs1_half_top, rs2_half_top, rd_word)
    };
  };
  X(rd) = result;
  RETIRE_SUCCESS
}  

mapping p_64only_q15_mapping : p_64_only_q15_op <-> string = {
    KHMBB16  <-> "KHMBB16",
    KHMBT16  <-> "KHMBT16",
    KHMTT16  <-> "KHMTT16",
    KDMBB16  <-> "KDMBB16",
    KDMBT16  <-> "KDMBT16",
    KDMTT16  <-> "KDMTT16",
    KDMABB16 <-> "KDMABB16",
    KDMABT16 <-> "KDMABT16",
    KDMATT16 <-> "KDMATT16"
}

mapping clause assembly = PEXT_64ONLY_Q15(rs2, rs1, rd, p_inst)
  <-> p_64only_q15_mapping(p_inst) ^ spc() ^ reg_name(rd) ^ sep() ^ reg_name(rs1) ^ sep() ^ reg_name(rs2)

/* PEXT_64ONLY_32BITS_MUL AST */
union clause ast = PEXT_64ONLY_32BITS_MUL : (regidx, regidx, regidx, p_64_only_32_mul_op)

mapping clause encdec = PEXT_64ONLY_32BITS_MUL(rs2, rs1, rd, SMBT32) <->
  0b0001100 @ rs2 @ rs1 @ 0b010 @ rd @ 0b1110111
mapping clause encdec = PEXT_64ONLY_32BITS_MUL(rs2, rs1, rd, SMTT32) <->
  0b0010100 @ rs2 @ rs1 @ 0b010 @ rd @ 0b1110111
mapping clause encdec = PEXT_64ONLY_32BITS_MUL(rs2, rs1, rd, KMABB32) <->
  0b0101101 @ rs2 @ rs1 @ 0b010 @ rd @ 0b1110111
mapping clause encdec = PEXT_64ONLY_32BITS_MUL(rs2, rs1, rd, KMABT32) <->
  0b0110101 @ rs2 @ rs1 @ 0b010 @ rd @ 0b1110111
mapping clause encdec = PEXT_64ONLY_32BITS_MUL(rs2, rs1, rd, KMATT32) <->
  0b0111101 @ rs2 @ rs1 @ 0b010 @ rd @ 0b1110111
mapping clause encdec = PEXT_64ONLY_32BITS_MUL(rs2, rs1, rd, KMDA32) <->
  0b0011100 @ rs2 @ rs1 @ 0b010 @ rd @ 0b1110111
mapping clause encdec = PEXT_64ONLY_32BITS_MUL(rs2, rs1, rd, KMXDA32) <->
  0b0011101 @ rs2 @ rs1 @ 0b010 @ rd @ 0b1110111
mapping clause encdec = PEXT_64ONLY_32BITS_MUL(rs2, rs1, rd, KMAXDA32) <->
  0b0100101 @ rs2 @ rs1 @ 0b010 @ rd @ 0b1110111
mapping clause encdec = PEXT_64ONLY_32BITS_MUL(rs2, rs1, rd, KMADS32) <->
  0b0101110 @ rs2 @ rs1 @ 0b010 @ rd @ 0b1110111
mapping clause encdec = PEXT_64ONLY_32BITS_MUL(rs2, rs1, rd, KMADRS32) <->
  0b0110110 @ rs2 @ rs1 @ 0b010 @ rd @ 0b1110111
mapping clause encdec = PEXT_64ONLY_32BITS_MUL(rs2, rs1, rd, KMAXDS32) <->
  0b0111110 @ rs2 @ rs1 @ 0b010 @ rd @ 0b1110111
mapping clause encdec = PEXT_64ONLY_32BITS_MUL(rs2, rs1, rd, KMSDA32) <->
  0b0100110 @ rs2 @ rs1 @ 0b010 @ rd @ 0b1110111
mapping clause encdec = PEXT_64ONLY_32BITS_MUL(rs2, rs1, rd, KMSXDA32) <->
  0b0100111 @ rs2 @ rs1 @ 0b010 @ rd @ 0b1110111
mapping clause encdec = PEXT_64ONLY_32BITS_MUL(rs2, rs1, rd, SMDS32) <->
  0b0101100 @ rs2 @ rs1 @ 0b010 @ rd @ 0b1110111
mapping clause encdec = PEXT_64ONLY_32BITS_MUL(rs2, rs1, rd, SMDRS32) <->
  0b0110100 @ rs2 @ rs1 @ 0b010 @ rd @ 0b1110111
mapping clause encdec = PEXT_64ONLY_32BITS_MUL(rs2, rs1, rd, SMXDS32) <->
  0b0111100 @ rs2 @ rs1 @ 0b010 @ rd @ 0b1110111

function clause execute (PEXT_64ONLY_32BITS_MUL(rs2, rs1, rd, op)) = {
  let rs1_val = X(rs1);
  let rs2_val = X(rs2);
  let rs1_word_bottom = slice(rs1_val, 0, 32);
  let rs1_word_top = slice(rs1_val, 32, 32);
  let rs2_word_bottom = slice(rs2_val, 0, 32);
  let rs2_word_top = slice(rs2_val, 32, 32);
  result : bits(64) = match op {
    SMBT32   => smul(rs1_word_bottom, rs2_word_top),
    SMTT32   => smul(rs1_word_top, rs2_word_top),
    KMABB32  => kadd(X(rd), smul(rs1_word_bottom, rs2_word_bottom)),
    KMABT32  => kadd(X(rd), smul(rs1_word_bottom, rs2_word_top)), 
    KMATT32  => kadd(X(rd), smul(rs1_word_top, rs2_word_top)),
    KMDA32   => signed_mul_two_half_and_add(rs1_word_top, rs2_word_top, rs1_word_bottom, rs2_word_bottom),
    KMXDA32  => signed_mul_two_half_and_add(rs1_word_top, rs2_word_bottom, rs1_word_bottom, rs2_word_top),
    KMAXDA32 => saturating_signed_mul_two_words_and_two_adds(X(rd), rs1_word_top, rs2_word_bottom, rs1_word_bottom, rs2_word_top),
    KMADS32  => kmads(X(rd), rs1_word_top, rs2_word_top, rs1_word_bottom, rs2_word_bottom),
    KMAXDS32 => kmads(X(rd), rs1_word_top, rs2_word_bottom, rs1_word_bottom, rs2_word_top),
    KMADRS32 => kmads(X(rd), rs1_word_bottom, rs2_word_bottom, rs1_word_top, rs2_word_top),
    KMSDA32  => kmsda(X(rd), rs1_word_top, rs2_word_top, rs1_word_bottom, rs2_word_bottom),
    KMSXDA32 => kmsda(X(rd), rs1_word_top, rs2_word_bottom, rs1_word_bottom, rs2_word_top),
    SMDS32   => smul(rs1_word_top, rs2_word_top) - smul(rs1_word_bottom, rs2_word_bottom),
    SMDRS32  => smul(rs1_word_bottom, rs2_word_bottom) - smul(rs1_word_top, rs2_word_top),
    SMXDS32  => smul(rs1_word_top, rs2_word_bottom) - smul(rs1_word_bottom, rs2_word_top)
  };
  X(rd) = result;
  RETIRE_SUCCESS
}  

mapping p_64only_32bits_mul_mapping : p_64_only_32_mul_op <-> string = {
    SMBT32    <->  "SMBT32",
    SMTT32    <->  "SMTT32",
    KMABB32   <->  "KMABB32",
    KMABT32   <->  "KMABBT32",
    KMATT32   <->  "KMATT32",
    KMDA32    <->  "KMDA32",
    KMXDA32   <->  "KMXDA32",
    KMAXDA32  <->  "KMAXDA32",
    KMADS32   <->  "KMADS32",
    KMAXDS32  <->  "KMAXDS32",
    KMADRS32  <->  "KMADRS32",
    KMSDA32   <->  "KMSDA32",
    KMSXDA32  <->  "KMSXDA32",
    SMDS32    <->  "SMDS32",
    SMDRS32   <->  "SMDRS32",
    SMXDS32   <->  "SMXDS32"
}

mapping clause assembly = PEXT_64ONLY_32BITS_MUL(rs2, rs1, rd, p_inst)
  <-> p_64only_32bits_mul_mapping(p_inst) ^ spc() ^ reg_name(rd) ^ sep() ^ reg_name(rs1) ^ sep() ^ reg_name(rs2)

/* PEXT_64ONLY_32BITS_PACK AST */
union clause ast = PEXT_64ONLY_32BITS_PACK : (regidx, regidx, regidx, p_64_only_pack_op)

mapping clause encdec = PEXT_64ONLY_32BITS_PACK(rs2, rs1, rd, PKBB32) <->
  0b0000111 @ rs2 @ rs1 @ 0b010 @ rd @ 0b1110111
mapping clause encdec = PEXT_64ONLY_32BITS_PACK(rs2, rs1, rd, PKBT32) <->
  0b0001111 @ rs2 @ rs1 @ 0b010 @ rd @ 0b1110111
mapping clause encdec = PEXT_64ONLY_32BITS_PACK(rs2, rs1, rd, PKTT32) <->
  0b0010111 @ rs2 @ rs1 @ 0b010 @ rd @ 0b1110111
mapping clause encdec = PEXT_64ONLY_32BITS_PACK(rs2, rs1, rd, PKTB32) <->
  0b0011111 @ rs2 @ rs1 @ 0b010 @ rd @ 0b1110111

function clause execute (PEXT_64ONLY_32BITS_PACK(rs2, rs1, rd, op)) = {
  let rs1_val = X(rs1);
  let rs2_val = X(rs2);
  let rs1_word_bottom = slice(rs1_val, 0, 32);
  let rs1_word_top = slice(rs1_val, 32, 32);
  let rs2_word_bottom = slice(rs2_val, 0, 32);
  let rs2_word_top = slice(rs2_val, 32, 32);
  let result : bits(64) = match op {
    PKBB32  =>  rs1_word_bottom @ rs2_word_bottom,
    PKBT32  =>  rs1_word_bottom @ rs2_word_top,
    PKTB32  =>  rs1_word_top @ rs2_word_bottom,
    PKTT32  =>  rs1_word_top @ rs2_word_top
  };
  X(rd) = result;
  RETIRE_SUCCESS
}

mapping p_64only_32bits_pack_mapping : p_64_only_pack_op <-> string = {
  PKBB32  <->  "PKBB32",
  PKBT32  <->  "PKBT32",
  PKTB32  <->  "PKTB32",
  PKTT32  <->  "PKTT32"
}

mapping clause assembly = PEXT_64ONLY_32BITS_PACK(rs2, rs1, rd, p_inst)
  <-> p_64only_32bits_pack_mapping(p_inst) ^ spc() ^ reg_name(rd) ^ sep() ^ reg_name(rs1) ^ sep() ^ reg_name(rs2)

/* PEXT_64ONLY_IMM5 AST */
union clause ast = PEXT_64ONLY_IMM5 : (bits(5), regidx, regidx, p_64_only_imm5_op)

mapping clause encdec = PEXT_64ONLY_IMM5(imm5, rs1, rd, KSLLI32) <->
  0b1000010 @ imm5 @ rs1 @ 0b010 @ rd @ 0b1110111
mapping clause encdec = PEXT_64ONLY_IMM5(imm5, rs1, rd, SLLI32) <->
  0b0111010 @ imm5 @ rs1 @ 0b010 @ rd @ 0b1110111
mapping clause encdec = PEXT_64ONLY_IMM5(imm5, rs1, rd, SRAI32) <->
  0b0111000 @ imm5 @ rs1 @ 0b010 @ rd @ 0b1110111
mapping clause encdec = PEXT_64ONLY_IMM5(imm5, rs1, rd, SRAI32_U) <->
  0b1000000 @ imm5 @ rs1 @ 0b010 @ rd @ 0b1110111
mapping clause encdec = PEXT_64ONLY_IMM5(imm5, rs1, rd, SRLI32) <->
  0b0111001 @ imm5 @ rs1 @ 0b010 @ rd @ 0b1110111
mapping clause encdec = PEXT_64ONLY_IMM5(imm5, rs1, rd, SRLI32_U) <->
  0b1000001 @ imm5 @ rs1 @ 0b010 @ rd @ 0b1110111

function clause execute (PEXT_64ONLY_IMM5(imm5, rs1, rd, op)) = {
  let rs1_val = X(rs1);
  let sa : bits(8) = EXTZ(imm5);
  result : bits(64) = zeros();
  foreach (i from 0 to (sizeof(xlen) - 32) by 32) {
    let rs1_word = slice(rs1_val, i, 32);
    result[(i+31)..i] = match op {
      KSLLI32  => kshift_left_logic(rs1_word, sa),
      SLLI32   => shift_left_logic(rs1_word, sa),
      SRAI32   => shift_right_arith(rs1_word, sa),
      SRAI32_U => shift_right_arith_u(rs1_word, sa),
      SRLI32   => shift_right_logic(rs1_word, sa),
      SRLI32_U => shift_right_logic_u(rs1_word, sa)
    };
  };
  X(rd) = result;
  RETIRE_SUCCESS
}

mapping p_64only_shift_imm_mapping : p_64_only_imm5_op <-> string = {
  KSLLI32  <-> "KSLLI32",
  SLLI32   <-> "SLLI32",
  SRAI32   <-> "SRAI32",
  SRAI32_U <-> "SRAI32_U",
  SRLI32   <-> "SRLI32",
  SRLI32_U <-> "SRLI32_U"
}

mapping clause assembly = PEXT_64ONLY_IMM5(imm5, rs1, rd, p_inst)
  <-> p_64only_shift_imm_mapping(p_inst) ^ spc() ^ reg_name(rd) ^ sep() ^ reg_name(rs1) ^ sep() ^ hex_bits_5(imm5)

/* PEXT_64ONLY_SRAIW_U AST */
union clause ast = PEXT_64ONLY_SRAIW_U : (bits(5), regidx, regidx)

mapping clause encdec = PEXT_64ONLY_SRAIW_U(imm5, rs1, rd) <->
  0b0011010 @ imm5 @ rs1 @ 0b001 @ rd @ 0b1110111

function clause execute (PEXT_64ONLY_SRAIW_U(imm5, rs1, rd)) = {
  let rs1_word_bottom = slice(X(rs1), 0, 32);
  let sa : bits(8) = EXTZ(imm5);
  X(rd) = EXTS(shift_right_arith_u(rs1_word_bottom, sa));
  RETIRE_SUCCESS
}

mapping clause assembly = PEXT_64ONLY_SRAIW_U(imm5, rs1, rd)
  <-> "SRAIW_U" ^ spc() ^ reg_name(rd) ^ sep() ^ reg_name(rs1) ^ sep() ^ hex_bits_5(imm5)

/* PEXT_64ONLY_KABS32 AST */
union clause ast = PEXT_INST_64ONLY_KABS32 : (regidx, regidx)

mapping clause encdec = PEXT_INST_64ONLY_KABS32(rs1, rd) <->
  0b1010110 @ 0b10010 @ rs1 @ 0b000 @ rd @ 0b1110111

function clause execute (PEXT_INST_64ONLY_KABS32(rs1, rd)) = {
  let rs1_val = X(rs1);
  result : bits(64) = zeros();
  foreach (i from 0 to (sizeof(xlen) - 32) by 32) {
    let rs1_word = slice(rs1_val, i, 32);
    result[(i+31)..i] = kabs(rs1_word);
  };
  X(rd) = result;
  RETIRE_SUCCESS
}

mapping clause assembly = PEXT_INST_64ONLY_KABS32(rs1, rd)
  <-> "KABS32" ^ spc() ^ reg_name(rd) ^ sep() ^ reg_name(rs1)

/* PEXT_64ONLY_CROSS_32 AST */
union clause ast = PEXT_64ONLY_CROSS_32 : (regidx, regidx, regidx, p_64_only_cross_32_op)

mapping clause encdec = PEXT_64ONLY_CROSS_32(rs2, rs1, rd, CRAS32) <->
  0b0100010 @ rs2 @ rs1 @ 0b010 @ rd @ 0b1110111
mapping clause encdec = PEXT_64ONLY_CROSS_32(rs2, rs1, rd, CRSA32) <->
  0b0100011 @ rs2 @ rs1 @ 0b010 @ rd @ 0b1110111
mapping clause encdec = PEXT_64ONLY_CROSS_32(rs2, rs1, rd, RCRAS32) <->
  0b0000010 @ rs2 @ rs1 @ 0b010 @ rd @ 0b1110111
mapping clause encdec = PEXT_64ONLY_CROSS_32(rs2, rs1, rd, RCRSA32) <->
  0b0000011 @ rs2 @ rs1 @ 0b010 @ rd @ 0b1110111
mapping clause encdec = PEXT_64ONLY_CROSS_32(rs2, rs1, rd, KCRAS32) <->
  0b0001010 @ rs2 @ rs1 @ 0b010 @ rd @ 0b1110111
mapping clause encdec = PEXT_64ONLY_CROSS_32(rs2, rs1, rd, KCRSA32) <->
  0b0001011 @ rs2 @ rs1 @ 0b010 @ rd @ 0b1110111
mapping clause encdec = PEXT_64ONLY_CROSS_32(rs2, rs1, rd, URCRAS32) <->
  0b0010010 @ rs2 @ rs1 @ 0b010 @ rd @ 0b1110111
mapping clause encdec = PEXT_64ONLY_CROSS_32(rs2, rs1, rd, URCRSA32) <->
  0b0010011 @ rs2 @ rs1 @ 0b010 @ rd @ 0b1110111
mapping clause encdec = PEXT_64ONLY_CROSS_32(rs2, rs1, rd, UKCRAS32) <->
  0b0011010 @ rs2 @ rs1 @ 0b010 @ rd @ 0b1110111
mapping clause encdec = PEXT_64ONLY_CROSS_32(rs2, rs1, rd, UKCRSA32) <->
  0b0011011 @ rs2 @ rs1 @ 0b010 @ rd @ 0b1110111
mapping clause encdec = PEXT_64ONLY_CROSS_32(rs2, rs1, rd, STAS32) <->
  0b1111000 @ rs2 @ rs1 @ 0b010 @ rd @ 0b1110111
mapping clause encdec = PEXT_64ONLY_CROSS_32(rs2, rs1, rd, STSA32) <->
  0b1111001 @ rs2 @ rs1 @ 0b010 @ rd @ 0b1110111
mapping clause encdec = PEXT_64ONLY_CROSS_32(rs2, rs1, rd, RSTAS32) <->
  0b1011000 @ rs2 @ rs1 @ 0b010 @ rd @ 0b1110111
mapping clause encdec = PEXT_64ONLY_CROSS_32(rs2, rs1, rd, RSTSA32) <->
  0b1011001 @ rs2 @ rs1 @ 0b010 @ rd @ 0b1110111
mapping clause encdec = PEXT_64ONLY_CROSS_32(rs2, rs1, rd, KSTAS32) <->
  0b1100000 @ rs2 @ rs1 @ 0b010 @ rd @ 0b1110111
mapping clause encdec = PEXT_64ONLY_CROSS_32(rs2, rs1, rd, KSTSA32) <->
  0b1100001 @ rs2 @ rs1 @ 0b010 @ rd @ 0b1110111
mapping clause encdec = PEXT_64ONLY_CROSS_32(rs2, rs1, rd, URSTAS32) <->
  0b1101000 @ rs2 @ rs1 @ 0b010 @ rd @ 0b1110111
mapping clause encdec = PEXT_64ONLY_CROSS_32(rs2, rs1, rd, URSTSA32) <->
  0b1101001 @ rs2 @ rs1 @ 0b010 @ rd @ 0b1110111
mapping clause encdec = PEXT_64ONLY_CROSS_32(rs2, rs1, rd, UKSTAS32) <->
  0b1110000 @ rs2 @ rs1 @ 0b010 @ rd @ 0b1110111
mapping clause encdec = PEXT_64ONLY_CROSS_32(rs2, rs1, rd, UKSTSA32) <->
  0b1110001 @ rs2 @ rs1 @ 0b010 @ rd @ 0b1110111

function clause execute (PEXT_64ONLY_CROSS_32(rs2, rs1, rd, op)) = {
  let rs1_word1 = X(rs1)[63..32];
  let rs1_word0 = X(rs1)[31..0];
  let rs2_word1 = X(rs2)[63..32];
  let rs2_word0 = X(rs2)[31..0];  
  X(rd) = match op {
    CRAS32   => (rs1_word1 + rs2_word0) @ (rs1_word0 - rs2_word1),
    CRSA32   => (rs1_word1 - rs2_word0) @ (rs1_word0 + rs2_word1),
    RCRAS32  => radd(rs1_word1, rs2_word0) @ rsub(rs1_word0, rs2_word1),
    RCRSA32  => rsub(rs1_word1, rs2_word0) @ radd(rs1_word0, rs2_word1),
    KCRAS32  => kadd(rs1_word1, rs2_word0) @ ksub(rs1_word0, rs2_word1),
    KCRSA32  => ksub(rs1_word1, rs2_word0) @ kadd(rs1_word0, rs2_word1),
    URCRAS32 => uradd(rs1_word1, rs2_word0) @ ursub(rs1_word0, rs2_word1),
    URCRSA32 => ursub(rs1_word1, rs2_word0) @ uradd(rs1_word0, rs2_word1),
    UKCRAS32 => ukadd(rs1_word1, rs2_word0) @ uksub(rs1_word0, rs2_word1),
    UKCRSA32 => uksub(rs1_word1, rs2_word0) @ ukadd(rs1_word0, rs2_word1),
    STAS32   => (rs1_word1 + rs2_word1) @ (rs1_word0 - rs2_word0),
    STSA32   => (rs1_word1 - rs2_word1) @ (rs1_word0 + rs2_word0),
    RSTAS32  => radd(rs1_word1, rs2_word1) @ rsub(rs1_word0, rs2_word0),
    RSTSA32  => rsub(rs1_word1, rs2_word1) @ radd(rs1_word0, rs2_word0),
    KSTAS32  => kadd(rs1_word1, rs2_word1) @ ksub(rs1_word0, rs2_word0),
    KSTSA32  => ksub(rs1_word1, rs2_word1) @ kadd(rs1_word0, rs2_word0),
    URSTAS32 => uradd(rs1_word1, rs2_word1) @ ursub(rs1_word0, rs2_word0),
    URSTSA32 => ursub(rs1_word1, rs2_word1) @ uradd(rs1_word0, rs2_word0),
    UKSTAS32 => ukadd(rs1_word1, rs2_word1) @ uksub(rs1_word0, rs2_word0),
    UKSTSA32 => uksub(rs1_word1, rs2_word1) @ ukadd(rs1_word0, rs2_word0)
  };
  RETIRE_SUCCESS
}

mapping p_64only_cross32_mapping : p_64_only_cross_32_op <-> string = {
  CRAS32   <-> "CRAS32", 
  CRSA32   <-> "CRSA32",
  RCRAS32  <-> "RCRAS32", 
  RCRSA32  <-> "RCRSA32",
  KCRAS32  <-> "KCRAS32", 
  KCRSA32  <-> "KCRSA32",
  URCRAS32 <-> "URCRAS32", 
  URCRSA32 <-> "URCRSA32",
  UKCRAS32 <-> "UKCRAS32", 
  UKCRSA32 <-> "UKCRSA32",
  STAS32   <-> "STAS32",
  STSA32   <-> "STSA32",
  RSTAS32  <-> "RSTAS32",
  RSTSA32  <-> "RSTSA32",
  KSTAS32  <-> "KSTAS32",
  KSTSA32  <-> "KSTSA32",
  URSTAS32 <-> "URSTAS32",
  URSTSA32 <-> "URSTSA32",
  UKSTAS32 <-> "UKSTAS32",
  UKSTSA32 <-> "UKSTSA32"
}

mapping clause assembly = PEXT_64ONLY_CROSS_32(rs2, rs1, rd, p_inst)
  <-> p_64only_cross32_mapping(p_inst) ^ spc() ^ reg_name(rd) ^ sep() ^ reg_name(rs1) ^ sep() ^ reg_name(rs2)
