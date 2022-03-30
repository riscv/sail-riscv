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
/* This file specifies the SIMD Data Processing Instructions added by the 'P' extension. */

/* Programming Langauge Lab, Department of Computer Science, National Tsing-Hua University, Taiwan */
/* Academia Sinica, Taiwan*/
/* Andes Technology Corporation*/

/* PEXT_ALU_CMP_16 AST */

union clause ast = PEXT_ALU_CMP_16  : (regidx, regidx, regidx, p_alu_16_op)

mapping clause encdec = PEXT_ALU_CMP_16 (rs2, rs1, rd, RADD16) <->
  0b0000000 @ rs2 @ rs1 @ 0b000 @ rd @ 0b1110111
mapping clause encdec = PEXT_ALU_CMP_16 (rs2, rs1, rd, ADD16) <->
  0b0100000 @ rs2 @ rs1 @ 0b000 @ rd @ 0b1110111
mapping clause encdec = PEXT_ALU_CMP_16 (rs2, rs1, rd, KADD16) <->
  0b0001000 @ rs2 @ rs1 @ 0b000 @ rd @ 0b1110111
mapping clause encdec = PEXT_ALU_CMP_16 (rs2, rs1, rd, KSUB16) <->
  0b0001001 @ rs2 @ rs1 @ 0b000 @ rd @ 0b1110111
mapping clause encdec = PEXT_ALU_CMP_16 (rs2, rs1, rd, RSUB16) <->
  0b0000001 @ rs2 @ rs1 @ 0b000 @ rd @ 0b1110111
mapping clause encdec = PEXT_ALU_CMP_16 (rs2, rs1, rd, SUB16) <->
  0b0100001 @ rs2 @ rs1 @ 0b000 @ rd @ 0b1110111
mapping clause encdec = PEXT_ALU_CMP_16 (rs2, rs1, rd, UKADD16) <->
  0b0011000 @ rs2 @ rs1 @ 0b000 @ rd @ 0b1110111
mapping clause encdec = PEXT_ALU_CMP_16 (rs2, rs1, rd, UKSUB16) <->
  0b0011001 @ rs2 @ rs1 @ 0b000 @ rd @ 0b1110111
mapping clause encdec = PEXT_ALU_CMP_16 (rs2, rs1, rd, URADD16) <->
  0b0010000 @ rs2 @ rs1 @ 0b000 @ rd @ 0b1110111
mapping clause encdec = PEXT_ALU_CMP_16 (rs2, rs1, rd, URSUB16) <->
  0b0010001 @ rs2 @ rs1 @ 0b000 @ rd @ 0b1110111
mapping clause encdec = PEXT_ALU_CMP_16 (rs2, rs1, rd, CMPEQ16) <->
  0b0100110 @ rs2 @ rs1 @ 0b000 @ rd @ 0b1110111
mapping clause encdec = PEXT_ALU_CMP_16 (rs2, rs1, rd, KSLL16) <->
  0b0110010 @ rs2 @ rs1 @ 0b000 @ rd @ 0b1110111
mapping clause encdec = PEXT_ALU_CMP_16 (rs2, rs1, rd, KSLRA16) <->
  0b0101011 @ rs2 @ rs1 @ 0b000 @ rd @ 0b1110111
mapping clause encdec = PEXT_ALU_CMP_16 (rs2, rs1, rd, KSLRA16_U) <->
  0b0110011 @ rs2 @ rs1 @ 0b000 @ rd @ 0b1110111
mapping clause encdec = PEXT_ALU_CMP_16 (rs2, rs1, rd, SCMPLE16) <->
  0b0001110 @ rs2 @ rs1 @ 0b000 @ rd @ 0b1110111
mapping clause encdec = PEXT_ALU_CMP_16 (rs2, rs1, rd, SCMPLT16) <->
  0b0000110 @ rs2 @ rs1 @ 0b000 @ rd @ 0b1110111
mapping clause encdec = PEXT_ALU_CMP_16 (rs2, rs1, rd, SLL16) <->
  0b0101010 @ rs2 @ rs1 @ 0b000 @ rd @ 0b1110111
mapping clause encdec = PEXT_ALU_CMP_16 (rs2, rs1, rd, SMAX16) <->
  0b1000001 @ rs2 @ rs1 @ 0b000 @ rd @ 0b1110111
mapping clause encdec = PEXT_ALU_CMP_16 (rs2, rs1, rd, SMIN16) <->
  0b1000000 @ rs2 @ rs1 @ 0b000 @ rd @ 0b1110111
mapping clause encdec = PEXT_ALU_CMP_16 (rs2, rs1, rd, SRA16) <->
  0b0101000 @ rs2 @ rs1 @ 0b000 @ rd @ 0b1110111
mapping clause encdec = PEXT_ALU_CMP_16 (rs2, rs1, rd, SRA16_U) <->
  0b0110000 @ rs2 @ rs1 @ 0b000 @ rd @ 0b1110111
mapping clause encdec = PEXT_ALU_CMP_16 (rs2, rs1, rd, SRL16) <->
  0b0101001 @ rs2 @ rs1 @ 0b000 @ rd @ 0b1110111
mapping clause encdec = PEXT_ALU_CMP_16 (rs2, rs1, rd, SRL16_U) <->
  0b0110001 @ rs2 @ rs1 @ 0b000 @ rd @ 0b1110111
mapping clause encdec = PEXT_ALU_CMP_16 (rs2, rs1, rd, UCMPLE16) <->
  0b0011110 @ rs2 @ rs1 @ 0b000 @ rd @ 0b1110111
mapping clause encdec = PEXT_ALU_CMP_16 (rs2, rs1, rd, UCMPLT16) <->
  0b0010110 @ rs2 @ rs1 @ 0b000 @ rd @ 0b1110111
mapping clause encdec = PEXT_ALU_CMP_16 (rs2, rs1, rd, UMAX16) <->
  0b1001001 @ rs2 @ rs1 @ 0b000 @ rd @ 0b1110111
mapping clause encdec = PEXT_ALU_CMP_16 (rs2, rs1, rd, UMIN16) <->
  0b1001000 @ rs2 @ rs1 @ 0b000 @ rd @ 0b1110111

function clause execute (PEXT_ALU_CMP_16 (rs2, rs1, rd, op)) = {
  let rs1_val = X(rs1);
  let rs2_val = X(rs2);
  result : xlenbits = zeros();
  foreach (i from 0 to (sizeof(xlen) - 16) by 16) {
    let rs1_half =  slice(rs1_val, i, 16);
    let rs2_half =  slice(rs2_val, i, 16);
    result[(i+15)..i] = match op {
      ADD16     => rs1_half + rs2_half,
      RADD16    => radd(rs1_half,rs2_half),
      URADD16   => uradd(rs1_half,rs2_half),
      KADD16    => kadd(rs1_half,rs2_half), 
      UKADD16   => ukadd(rs1_half,rs2_half),
      SUB16     => rs1_half - rs2_half,
      RSUB16    => rsub(rs1_half,rs2_half),
      URSUB16   => ursub(rs1_half,rs2_half),
      KSUB16    => ksub(rs1_half,rs2_half),
      UKSUB16   => uksub(rs1_half,rs2_half),
      SLL16     => shift_left_logic(rs1_half, 0x0 @ X(rs2)[3..0]),
      KSLL16    => kshift_left_logic(rs1_half, 0x0 @ X(rs2)[3..0]),
      KSLRA16   => kslra(rs1_half, EXTS(X(rs2)[4..0])),
      KSLRA16_U => kslra_u(rs1_half, EXTS(X(rs2)[4..0])),
      SRA16     => shift_right_arith(rs1_half, 0x0 @ X(rs2)[3..0]),
      SRA16_U   => shift_right_arith_u(rs1_half, 0x0 @ X(rs2)[3..0]),
      SRL16     => shift_right_logic(rs1_half, 0x0 @ X(rs2)[3..0]),
      SRL16_U   => shift_right_logic_u(rs1_half, 0x0 @ X(rs2)[3..0]),
      CMPEQ16   => cmpeq(rs1_half, rs2_half), 
      SCMPLT16  => scmplt(rs1_half, rs2_half),
      SCMPLE16  => scmple(rs1_half, rs2_half),
      UCMPLT16  => ucmplt(rs1_half, rs2_half),
      UCMPLE16  => ucmple(rs1_half, rs2_half),
      SMAX16    => smax(rs1_half, rs2_half),
      SMIN16    => smin(rs1_half, rs2_half),
      UMAX16    => umax(rs1_half, rs2_half),
      UMIN16    => umin(rs1_half, rs2_half)
    };
  };
  X(rd) = result;
  RETIRE_SUCCESS
}

mapping p_ALU16_mapping : p_alu_16_op <-> string = {
    ADD16     <-> "ADD16",
    RADD16    <-> "RADD16",
    URADD16   <-> "URADD16",
    KADD16    <-> "KADD16",
    UKADD16   <-> "UKADD16",
    SUB16     <-> "SUB16",
    RSUB16    <-> "RSUB16",
    URSUB16   <-> "URSUB16",
    KSUB16    <-> "KSUB16",
    UKSUB16   <-> "UKSUB16",
    SLL16     <-> "SLL16",
    KSLL16    <-> "KSLL16",
    KSLRA16   <-> "KSLRA16",
    KSLRA16_U <-> "KSLRA16_U",
    SRA16     <-> "SRA16",
    SRA16_U   <-> "SRA16_U",
    SRL16     <-> "SRL16",
    SRL16_U   <-> "SRL16_U",
    CMPEQ16   <-> "CMPEQ16",
    SCMPLT16  <-> "SCMPLT16",
    SCMPLE16  <-> "SCMPLE16",
    UCMPLT16  <-> "UCMPLT16",
    UCMPLE16  <-> "UCMPLE16",
    SMAX16    <-> "SMAX16",
    SMIN16    <-> "SMIN16",
    UMAX16    <-> "UMAX16",
    UMIN16    <-> "UMIN16"
}

mapping clause assembly = PEXT_ALU_CMP_16 (rs2, rs1, rd, p_inst)
  <-> p_ALU16_mapping(p_inst) ^ spc() ^ reg_name(rd) ^ sep() ^ reg_name(rs1) ^ sep() ^ reg_name(rs2)

/* PEXT_CROSS_16 AST */
union clause ast = PEXT_CROSS_16 : (regidx, regidx, regidx, p_cross_16_op)

mapping clause encdec = PEXT_CROSS_16(rs2, rs1, rd, CRAS16) <->
  0b0100010 @ rs2 @ rs1 @ 0b000 @ rd @ 0b1110111
mapping clause encdec = PEXT_CROSS_16(rs2, rs1, rd, CRSA16) <->
  0b0100011 @ rs2 @ rs1 @ 0b000 @ rd @ 0b1110111
mapping clause encdec = PEXT_CROSS_16(rs2, rs1, rd, KCRAS16) <->
  0b0001010 @ rs2 @ rs1 @ 0b000 @ rd @ 0b1110111
mapping clause encdec = PEXT_CROSS_16(rs2, rs1, rd, KCRSA16) <->
  0b0001011 @ rs2 @ rs1 @ 0b000 @ rd @ 0b1110111
mapping clause encdec = PEXT_CROSS_16(rs2, rs1, rd, KSTAS16) <->
  0b1100010 @ rs2 @ rs1 @ 0b010 @ rd @ 0b1110111
mapping clause encdec = PEXT_CROSS_16(rs2, rs1, rd, KSTSA16) <->
  0b1100011 @ rs2 @ rs1 @ 0b010 @ rd @ 0b1110111
mapping clause encdec = PEXT_CROSS_16(rs2, rs1, rd, RCRAS16) <->
  0b0000010 @ rs2 @ rs1 @ 0b000 @ rd @ 0b1110111
mapping clause encdec = PEXT_CROSS_16(rs2, rs1, rd, RCRSA16) <->
  0b0000011 @ rs2 @ rs1 @ 0b000 @ rd @ 0b1110111
mapping clause encdec = PEXT_CROSS_16(rs2, rs1, rd, RSTAS16) <->
  0b1011010 @ rs2 @ rs1 @ 0b010 @ rd @ 0b1110111
mapping clause encdec = PEXT_CROSS_16(rs2, rs1, rd, RSTSA16) <->
  0b1011011 @ rs2 @ rs1 @ 0b010 @ rd @ 0b1110111
mapping clause encdec = PEXT_CROSS_16(rs2, rs1, rd, STAS16) <->
  0b1111010 @ rs2 @ rs1 @ 0b010 @ rd @ 0b1110111
mapping clause encdec = PEXT_CROSS_16(rs2, rs1, rd, STSA16) <->
  0b1111011 @ rs2 @ rs1 @ 0b010 @ rd @ 0b1110111
mapping clause encdec = PEXT_CROSS_16(rs2, rs1, rd, UKCRAS16) <->
  0b0011010 @ rs2 @ rs1 @ 0b000 @ rd @ 0b1110111
mapping clause encdec = PEXT_CROSS_16(rs2, rs1, rd, UKCRSA16) <->
  0b0011011 @ rs2 @ rs1 @ 0b000 @ rd @ 0b1110111
mapping clause encdec = PEXT_CROSS_16(rs2, rs1, rd, UKSTAS16) <->
  0b1110010 @ rs2 @ rs1 @ 0b010 @ rd @ 0b1110111
mapping clause encdec = PEXT_CROSS_16(rs2, rs1, rd, UKSTSA16) <->
  0b1110011 @ rs2 @ rs1 @ 0b010 @ rd @ 0b1110111
mapping clause encdec = PEXT_CROSS_16(rs2, rs1, rd, URCRAS16) <->
  0b0010010 @ rs2 @ rs1 @ 0b000 @ rd @ 0b1110111
mapping clause encdec = PEXT_CROSS_16(rs2, rs1, rd, URCRSA16) <->
  0b0010011 @ rs2 @ rs1 @ 0b000 @ rd @ 0b1110111
mapping clause encdec = PEXT_CROSS_16(rs2, rs1, rd, URSTAS16) <->
  0b1101010 @ rs2 @ rs1 @ 0b010 @ rd @ 0b1110111
mapping clause encdec = PEXT_CROSS_16(rs2, rs1, rd, URSTSA16) <->
  0b1101011 @ rs2 @ rs1 @ 0b010 @ rd @ 0b1110111
mapping clause encdec = PEXT_CROSS_16(rs2, rs1, rd, KHM16) <->
  0b1000011 @ rs2 @ rs1 @ 0b000 @ rd @ 0b1110111
mapping clause encdec = PEXT_CROSS_16(rs2, rs1, rd, KHMX16) <->
  0b1001011 @ rs2 @ rs1 @ 0b000 @ rd @ 0b1110111

function clause execute (PEXT_CROSS_16(rs2, rs1, rd, op)) = {
  let rs1_val = X(rs1);
  let rs2_val = X(rs2);
  result : xlenbits = zeros();
  foreach (i from 0 to (sizeof(xlen) - 32) by 32) {
    let rs1_half_bottom =  slice(rs1_val, i, 16);
    let rs1_half_top =  slice(rs1_val, i+16, 16);   
    let rs2_half_bottom =  slice(rs2_val, i, 16);
    let rs2_half_top =  slice(rs2_val, i+16, 16);
    result[(i+31)..i] = match op {
      CRAS16   => rs1_half_top + rs2_half_bottom @ rs1_half_bottom - rs2_half_top,
      RCRAS16  => radd(rs1_half_top,rs2_half_bottom) @ rsub(rs1_half_bottom, rs2_half_top),
      URCRAS16 => uradd(rs1_half_top,rs2_half_bottom) @ ursub(rs1_half_bottom, rs2_half_top),
      KCRAS16  => kadd(rs1_half_top,rs2_half_bottom) @ ksub(rs1_half_bottom, rs2_half_top),
      UKCRAS16 => ukadd(rs1_half_top,rs2_half_bottom) @ uksub(rs1_half_bottom, rs2_half_top),
      CRSA16   => rs1_half_top - rs2_half_bottom @ rs1_half_bottom + rs2_half_top,
      RCRSA16  => rsub(rs1_half_top,rs2_half_bottom) @ radd(rs1_half_bottom, rs2_half_top),
      URCRSA16 => ursub(rs1_half_top,rs2_half_bottom) @ uradd(rs1_half_bottom, rs2_half_top),
      KCRSA16  => ksub(rs1_half_top,rs2_half_bottom) @ kadd(rs1_half_bottom, rs2_half_top),
      UKCRSA16 => uksub(rs1_half_top,rs2_half_bottom) @ ukadd(rs1_half_bottom, rs2_half_top),
      STAS16   => rs1_half_top + rs2_half_top @ rs1_half_bottom - rs2_half_bottom,
      RSTAS16  => radd(rs1_half_top, rs2_half_top) @ rsub(rs1_half_bottom, rs2_half_bottom),
      URSTAS16 => uradd(rs1_half_top, rs2_half_top) @ ursub(rs1_half_bottom, rs2_half_bottom),
      KSTAS16  => kadd(rs1_half_top, rs2_half_top) @ ksub(rs1_half_bottom, rs2_half_bottom),
      UKSTAS16 => ukadd(rs1_half_top, rs2_half_top) @ uksub(rs1_half_bottom, rs2_half_bottom),
      STSA16   => rs1_half_top - rs2_half_top   @ rs1_half_bottom + rs2_half_bottom,
      RSTSA16  => rsub(rs1_half_top, rs2_half_top) @ radd(rs1_half_bottom, rs2_half_bottom),
      URSTSA16 => ursub(rs1_half_top, rs2_half_top) @ uradd(rs1_half_bottom, rs2_half_bottom),
      KSTSA16  => ksub(rs1_half_top, rs2_half_top) @ kadd(rs1_half_bottom, rs2_half_bottom),
      UKSTSA16 => uksub(rs1_half_top, rs2_half_top) @ ukadd(rs1_half_bottom, rs2_half_bottom),
      KHM16    => khm (rs1_half_top, rs2_half_top) @ khm (rs1_half_bottom, rs2_half_bottom), 
      KHMX16   => khm (rs1_half_top, rs2_half_bottom) @ khm (rs1_half_bottom, rs2_half_top)
    };
  };
  X(rd) = result;
  RETIRE_SUCCESS
}

mapping p_CROSS_16_mapping : p_cross_16_op <-> string = {
    CRAS16   <-> "CRAS16",
    RCRAS16  <-> "RCRAS16",
    URCRAS16 <-> "URCRAS16",
    KCRAS16  <-> "KCRAS16",
    UKCRAS16 <-> "UKCRAS16",
    CRSA16   <-> "CRSA16",
    RCRSA16  <-> "RCRSA16",
    URCRSA16 <-> "URCRSA16",
    KCRSA16  <-> "KCRSA16",
    UKCRSA16 <-> "UKCRSA16",
    STAS16   <-> "STAS16",
    RSTAS16  <-> "RSTAS16",
    URSTAS16 <-> "URSTAS16",
    KSTAS16  <-> "KSTAS16",
    UKSTAS16 <-> "UKSTAS16",
    STSA16   <-> "STSA16",
    RSTSA16  <-> "RSTSA16",
    URSTSA16 <-> "URSTSA16",
    KSTSA16  <-> "KSTSA16",
    UKSTSA16 <-> "UKSTSA16",
    KHM16    <-> "KHM16",
    KHMX16   <-> "KHMX16"
}

mapping clause assembly = PEXT_CROSS_16(rs2, rs1, rd, p_inst)
  <-> p_CROSS_16_mapping(p_inst) ^ spc() ^ reg_name(rd) ^ sep() ^ reg_name(rs1) ^ sep() ^ reg_name(rs2)

/* PEXT_MUL_16 */

union clause ast = PEXT_MUL_16 : (regidx, regidx, regidx, p_mul_16_op)

mapping clause encdec = PEXT_MUL_16(rs2, rs1, rd, SMUL16) <->
  0b1010000 @ rs2 @ rs1 @ 0b000 @ rd @ 0b1110111
mapping clause encdec = PEXT_MUL_16(rs2, rs1, rd, SMULX16) <->
  0b1010001 @ rs2 @ rs1 @ 0b000 @ rd @ 0b1110111
mapping clause encdec = PEXT_MUL_16(rs2, rs1, rd, UMUL16) <->
  0b1011000 @ rs2 @ rs1 @ 0b000 @ rd @ 0b1110111
mapping clause encdec = PEXT_MUL_16(rs2, rs1, rd, UMULX16) <->
  0b1011001 @ rs2 @ rs1 @ 0b000 @ rd @ 0b1110111

function clause execute (PEXT_MUL_16(rs2, rs1, rd, op)) = {
  let rs1_val = X(rs1);
  let rs2_val = X(rs2);
  let rs1_half_bottom =  slice(rs1_val, 0, 16);
  let rs1_half_top =  slice(rs1_val, 16, 16);
  let rs2_half_bottom =  slice(rs2_val, 0, 16);
  let rs2_half_top =  slice(rs2_val, 16, 16);
  if sizeof(xlen) == 32 
  then {
    let rd0 = (rd >> 1) << 1 ;
    let rd1 = rd0 + 1 ;
    result : xlenbits = zeros();
    result1 : xlenbits = zeros();
    Zero : xlenbits = zeros();
    match (op) {
      SMUL16  => {
        result  =  smul (rs1_half_bottom, rs2_half_bottom);
        result1 =  smul (rs1_half_top, rs2_half_top)
      },
      SMULX16 => {
        result  =  smul (rs1_half_bottom, rs2_half_top);
        result1 =  smul (rs1_half_top, rs2_half_bottom)
        },
      UMUL16  => {
        result  =  umul (rs1_half_bottom, rs2_half_bottom);
        result1 =  umul (rs1_half_top, rs2_half_top)
        },
      UMULX16 => {
        result  =  umul (rs1_half_bottom, rs2_half_top);
        result1 =  umul (rs1_half_top, rs2_half_bottom)
        }
      };
    X(rd0) = result;
    X(rd1) = result1;
    RETIRE_SUCCESS
  }
  else  {
    result : xlenbits = zeros();
    result = match (op) {
      SMUL16  => smul(rs1_half_top, rs2_half_top) @ smul(rs1_half_bottom, rs2_half_bottom),
      SMULX16 => smul(rs1_half_top, rs2_half_bottom) @ smul(rs1_half_bottom, rs2_half_top),
      UMUL16  => umul(rs1_half_top, rs2_half_top) @ umul(rs1_half_bottom, rs2_half_bottom),
      UMULX16 => umul(rs1_half_top, rs2_half_bottom) @ umul(rs1_half_bottom, rs2_half_top)
    };
    X(rd) = result;
    RETIRE_SUCCESS
  }
}

mapping p_MUL_16_mapping : p_mul_16_op <-> string = {
    SMUL16   <-> "SMUL16",
    SMULX16  <-> "SMULX16",
    UMUL16   <-> "UMUL16",
    UMULX16  <-> "UMULX16"
}

mapping clause assembly = PEXT_MUL_16(rs2, rs1, rd, p_inst)
  <-> p_MUL_16_mapping(p_inst) ^ spc() ^ reg_name(rd) ^ sep() ^ reg_name(rs1) ^ sep() ^ reg_name(rs2)

/* PEXT_ONE_REGISTER_16 AST */
union clause ast = PEXT_ONE_REGISTER_16  : (regidx, regidx, p_one_register_16_op)

mapping clause encdec = PEXT_ONE_REGISTER_16 (rs1, rd, CLRS16) <->
  0b1010111 @ 0b01000 @ rs1 @ 0b000 @ rd @ 0b1110111
mapping clause encdec = PEXT_ONE_REGISTER_16 (rs1, rd, CLO16) <->
  0b1010111 @ 0b01011 @ rs1 @ 0b000 @ rd @ 0b1110111
mapping clause encdec = PEXT_ONE_REGISTER_16 (rs1, rd, CLZ16) <->
  0b1010111 @ 0b01001 @ rs1 @ 0b000 @ rd @ 0b1110111
mapping clause encdec = PEXT_ONE_REGISTER_16 (rs1, rd, KABS16) <->
  0b1010110 @ 0b10001 @ rs1 @ 0b000 @ rd @ 0b1110111

function clause execute (PEXT_ONE_REGISTER_16 (rs1, rd, op)) = {
  let rs1_val = X(rs1);
  result : xlenbits = zeros();
  foreach (i from 0 to (sizeof(xlen) - 16) by 16) {
    let rs1_half = slice(rs1_val, i, 16);
    result[(i+15)..i] = match op {
      CLRS16 => clrs(rs1_half),
      CLO16  => clo(rs1_half),
      CLZ16  => clz(rs1_half),
      KABS16 => kabs(rs1_half)
    };
  };
  X(rd) = result;
  RETIRE_SUCCESS
}

mapping p_inst_rs1_rd_16_mapping : p_one_register_16_op <-> string = {
  CLRS16 <-> "CLRS16",
  CLO16  <-> "CLO16",
  CLZ16  <-> "CLZ16",
  KABS16 <-> "KABS16"
}

mapping clause assembly = PEXT_ONE_REGISTER_16 (rs1, rd, p_inst)
  <-> p_inst_rs1_rd_16_mapping(p_inst) ^ spc() ^ reg_name(rd) ^ sep() ^ reg_name(rs1)


/* PEXT_IMM4 AST */
union clause ast = PEXT_IMM4  : (bits(4), regidx, regidx, p_imm4_op)

mapping clause encdec = PEXT_IMM4 (imm4, rs1, rd, KSLLI16) <->
  0b0111010 @ 0b1 @ imm4 @ rs1 @ 0b000 @ rd @ 0b1110111
mapping clause encdec = PEXT_IMM4 (imm4, rs1, rd, SCLIP16) <->
  0b1000010 @ 0b0 @ imm4 @ rs1 @ 0b000 @ rd @ 0b1110111
mapping clause encdec = PEXT_IMM4 (imm4, rs1, rd, SLLI16) <->
  0b0111010 @ 0b0 @ imm4 @ rs1 @ 0b000 @ rd @ 0b1110111
mapping clause encdec = PEXT_IMM4 (imm4, rs1, rd, SRAI16) <->
  0b0111000 @ 0b0 @ imm4 @ rs1 @ 0b000 @ rd @ 0b1110111
mapping clause encdec = PEXT_IMM4 (imm4, rs1, rd, SRAI16_U) <->
  0b0111000 @ 0b1 @ imm4 @ rs1 @ 0b000 @ rd @ 0b1110111
mapping clause encdec = PEXT_IMM4 (imm4, rs1, rd, SRLI16) <->
  0b0111001 @ 0b0 @ imm4 @ rs1 @ 0b000 @ rd @ 0b1110111
mapping clause encdec = PEXT_IMM4 (imm4, rs1, rd, SRLI16_U) <->
  0b0111001 @ 0b1 @ imm4 @ rs1 @ 0b000 @ rd @ 0b1110111
mapping clause encdec = PEXT_IMM4 (imm4, rs1, rd, UCLIP16) <->
  0b1000010 @ 0b1 @ imm4 @ rs1 @ 0b000 @ rd @ 0b1110111

function clause execute (PEXT_IMM4 (imm4, rs1, rd, op)) = {
  let rs1_val = X(rs1);
  let sa : bits(8) = EXTZ(imm4);
  result : xlenbits = zeros();
  foreach (i from 0 to (sizeof(xlen) - 16) by 16) {
    let rs1_half =  slice(rs1_val, i, 16);
    result[(i+15)..i] = match op {
      KSLLI16  =>  kshift_left_logic(rs1_half, sa),
      SCLIP16  =>  sclip(rs1_half, sa),
      SLLI16   =>  shift_left_logic(rs1_half, sa),
      SRAI16   =>  shift_right_arith(rs1_half, sa),
      SRAI16_U =>  shift_right_arith_u(rs1_half, sa),
      SRLI16   =>  shift_right_logic(rs1_half, sa),
      SRLI16_U =>  shift_right_logic_u(rs1_half, sa),
      UCLIP16  =>  uclip(rs1_half, sa)
    };
  };
  X(rd) = result;
  RETIRE_SUCCESS
}

mapping p_inst_imm4_rs1_rd_mapping : p_imm4_op <-> string = {
  KSLLI16  <-> "KSLLI16",
  SCLIP16  <-> "SCLIP16",
  SLLI16   <-> "SLLI16",
  SRAI16   <-> "SRAI16",
  SRAI16_U <-> "SRAI16_U",
  SRLI16   <-> "SRLI16",
  SRLI16_U <-> "SRLI16_U",
  UCLIP16  <-> "UCLIP16"
}

mapping clause assembly = PEXT_IMM4 (imm4, rs1, rd, p_inst)
  <-> p_inst_imm4_rs1_rd_mapping(p_inst) ^ spc() ^ reg_name(rd) ^ sep() ^ reg_name(rs1) ^ sep() ^ hex_bits_4(imm4)

/* PEXT_ALU_CMP_8 AST */
union clause ast = PEXT_ALU_CMP_8 : (regidx, regidx, regidx, p_alu_8_op)

mapping clause encdec = PEXT_ALU_CMP_8(rs2, rs1, rd, ADD8) <->
  0b0100100 @ rs2 @ rs1 @ 0b000 @ rd @ 0b1110111
mapping clause encdec = PEXT_ALU_CMP_8(rs2, rs1, rd, KADD8) <->
  0b0001100 @ rs2 @ rs1 @ 0b000 @ rd @ 0b1110111
mapping clause encdec = PEXT_ALU_CMP_8(rs2, rs1, rd, RADD8) <->
  0b0000100 @ rs2 @ rs1 @ 0b000 @ rd @ 0b1110111
mapping clause encdec = PEXT_ALU_CMP_8(rs2, rs1, rd, UKADD8) <->
  0b0011100 @ rs2 @ rs1 @ 0b000 @ rd @ 0b1110111
mapping clause encdec = PEXT_ALU_CMP_8(rs2, rs1, rd, URADD8) <->
  0b0010100 @ rs2 @ rs1 @ 0b000 @ rd @ 0b1110111
mapping clause encdec = PEXT_ALU_CMP_8(rs2, rs1, rd, SUB8) <->
  0b0100101 @ rs2 @ rs1 @ 0b000 @ rd @ 0b1110111
mapping clause encdec = PEXT_ALU_CMP_8(rs2, rs1, rd, KSUB8) <->
  0b0001101 @ rs2 @ rs1 @ 0b000 @ rd @ 0b1110111
mapping clause encdec = PEXT_ALU_CMP_8(rs2, rs1, rd, RSUB8) <->
  0b0000101 @ rs2 @ rs1 @ 0b000 @ rd @ 0b1110111
mapping clause encdec = PEXT_ALU_CMP_8(rs2, rs1, rd, UKSUB8) <->
  0b0011101 @ rs2 @ rs1 @ 0b000 @ rd @ 0b1110111
mapping clause encdec = PEXT_ALU_CMP_8(rs2, rs1, rd, URSUB8) <->
  0b0010101 @ rs2 @ rs1 @ 0b000 @ rd @ 0b1110111
mapping clause encdec = PEXT_ALU_CMP_8(rs2, rs1, rd, CMPEQ8) <->
  0b0100111 @ rs2 @ rs1 @ 0b000 @ rd @ 0b1110111
mapping clause encdec = PEXT_ALU_CMP_8(rs2, rs1, rd, SCMPLE8) <->
  0b0001111 @ rs2 @ rs1 @ 0b000 @ rd @ 0b1110111
mapping clause encdec = PEXT_ALU_CMP_8(rs2, rs1, rd, SCMPLT8) <->
  0b0000111 @ rs2 @ rs1 @ 0b000 @ rd @ 0b1110111
mapping clause encdec = PEXT_ALU_CMP_8(rs2, rs1, rd, SMAX8) <->
  0b1000101 @ rs2 @ rs1 @ 0b000 @ rd @ 0b1110111
mapping clause encdec = PEXT_ALU_CMP_8(rs2, rs1, rd, SMIN8) <->
  0b1000100 @ rs2 @ rs1 @ 0b000 @ rd @ 0b1110111
mapping clause encdec = PEXT_ALU_CMP_8(rs2, rs1, rd, UCMPLE8) <->
  0b0011111 @ rs2 @ rs1 @ 0b000 @ rd @ 0b1110111
mapping clause encdec = PEXT_ALU_CMP_8(rs2, rs1, rd, UCMPLT8) <->
  0b0010111 @ rs2 @ rs1 @ 0b000 @ rd @ 0b1110111
mapping clause encdec = PEXT_ALU_CMP_8(rs2, rs1, rd, UMAX8) <->
  0b1001101 @ rs2 @ rs1 @ 0b000 @ rd @ 0b1110111
mapping clause encdec = PEXT_ALU_CMP_8(rs2, rs1, rd, UMIN8) <->
  0b1001100 @ rs2 @ rs1 @ 0b000 @ rd @ 0b1110111
mapping clause encdec = PEXT_ALU_CMP_8(rs2, rs1, rd, SRA8) <->
  0b0101100 @ rs2 @ rs1 @ 0b000 @ rd @ 0b1110111
mapping clause encdec = PEXT_ALU_CMP_8(rs2, rs1, rd, SRA8_U) <->
  0b0110100 @ rs2 @ rs1 @ 0b000 @ rd @ 0b1110111
mapping clause encdec = PEXT_ALU_CMP_8(rs2, rs1, rd, SRL8) <->
  0b0101101 @ rs2 @ rs1 @ 0b000 @ rd @ 0b1110111
mapping clause encdec = PEXT_ALU_CMP_8(rs2, rs1, rd, SRL8_U) <->
  0b0110101 @ rs2 @ rs1 @ 0b000 @ rd @ 0b1110111
mapping clause encdec = PEXT_ALU_CMP_8(rs2, rs1, rd, SLL8) <->
  0b0101110 @ rs2 @ rs1 @ 0b000 @ rd @ 0b1110111
mapping clause encdec = PEXT_ALU_CMP_8(rs2, rs1, rd, KSLL8) <->
  0b0110110 @ rs2 @ rs1 @ 0b000 @ rd @ 0b1110111
mapping clause encdec = PEXT_ALU_CMP_8(rs2, rs1, rd, KSLRA8) <->
  0b0101111 @ rs2 @ rs1 @ 0b000 @ rd @ 0b1110111
mapping clause encdec = PEXT_ALU_CMP_8(rs2, rs1, rd, KSLRA8_U) <->
  0b0110111 @ rs2 @ rs1 @ 0b000 @ rd @ 0b1110111

function clause execute (PEXT_ALU_CMP_8(rs2, rs1, rd, op)) = {
  let rs1_val = X(rs1);
  let rs2_val = X(rs2);
  result : xlenbits = zeros();
  foreach (i from 0 to (sizeof(xlen) - 8) by 8) {
    let rs1_byte = slice(rs1_val, i, 8);
    let rs2_byte = slice(rs2_val, i, 8);
    result[(i+7)..i] = match op {
      ADD8     => rs1_byte + rs2_byte,
      RADD8    => radd(rs1_byte, rs2_byte),
      URADD8   => uradd(rs1_byte, rs2_byte),
      KADD8    => kadd(rs1_byte, rs2_byte),
      UKADD8   => ukadd(rs1_byte, rs2_byte),
      SUB8     => rs1_byte - rs2_byte,
      RSUB8    => rsub(rs1_byte, rs2_byte),
      URSUB8   => ursub(rs1_byte, rs2_byte),
      KSUB8    => ksub(rs1_byte, rs2_byte),
      UKSUB8   => uksub(rs1_byte, rs2_byte),
      CMPEQ8   => cmpeq(rs1_byte, rs2_byte),
      SCMPLE8  => scmple(rs1_byte, rs2_byte),
      SCMPLT8  => scmplt(rs1_byte, rs2_byte),
      UCMPLE8  => ucmple(rs1_byte, rs2_byte),
      UCMPLT8  => ucmplt(rs1_byte, rs2_byte),
      SMIN8    => smin(rs1_byte, rs2_byte),
      SMAX8    => smax(rs1_byte, rs2_byte),
      UMIN8    => umin(rs1_byte, rs2_byte),
      UMAX8    => umax(rs1_byte, rs2_byte),
      SRA8     => shift_right_arith(rs1_byte, EXTZ(rs2_val[2..0])),
      SRA8_U   => shift_right_arith_u(rs1_byte, EXTZ(rs2_val[2..0])),
      SRL8     => shift_right_logic(rs1_byte, EXTZ(rs2_val[2..0])),
      SRL8_U   => shift_right_logic_u(rs1_byte, EXTZ(rs2_val[2..0])),
      SLL8     => shift_left_logic(rs1_byte, EXTZ(rs2_val[2..0])),
      KSLL8    => kshift_left_logic(rs1_byte, EXTZ(rs2_val[2..0])),
      KSLRA8   => kslra(rs1_byte, EXTS(rs2_val[3..0])),
      KSLRA8_U => kslra_u(rs1_byte, EXTS(rs2_val[3..0]))
    };
  };
  X(rd) = result;
  RETIRE_SUCCESS
}

mapping p_ALU8_mapping : p_alu_8_op <-> string = {
    ADD8     <-> "ADD8",
    RADD8    <-> "RADD8",
    URADD8   <-> "URADD8",
    KADD8    <-> "KADD8",
    UKADD8   <-> "UKADD8",
    SUB8     <-> "SUB8",
    RSUB8    <-> "RSUB8",
    URSUB8   <-> "URSUB8",
    KSUB8    <-> "KSUB8",
    UKSUB8   <-> "UKSUB8",
    CMPEQ8   <-> "CMPEQ8",
    SCMPLE8  <-> "SCMPLE8",
    SCMPLT8  <-> "SCMPLT8",
    UCMPLE8  <-> "UCMPLE8",
    UCMPLT8  <-> "UCMPLT8",
    SMIN8    <-> "SMIN8",
    SMAX8    <-> "SMAX8",
    UMIN8    <-> "UMIN8",
    UMAX8    <-> "UMAX8",
    SRA8     <-> "SRA8",
    SRA8_U   <-> "SRA8_U",
    SRL8     <-> "SRL8",
    SRL8_U   <-> "SRL8_U",
    SLL8     <-> "SLL8",
    KSLL8    <-> "KSLL8",
    KSLRA8   <-> "KSLRA8",
    KSLRA8_U <-> "KSLRA8_U"
}

mapping clause assembly = PEXT_ALU_CMP_8(rs2, rs1, rd, p_inst)
  <-> p_ALU8_mapping(p_inst) ^ spc() ^ reg_name(rd) ^ sep() ^ reg_name(rs1) ^ sep() ^ reg_name(rs2)

/* PEXT_MUL_8 AST */
union clause ast = PEXT_MUL_8 : (regidx, regidx, regidx, p_mul_8_op)

mapping clause encdec = PEXT_MUL_8(rs2, rs1, rd, SMUL8)  <->
  0b1010100 @ rs2 @ rs1 @ 0b000 @ rd @ 0b1110111
mapping clause encdec = PEXT_MUL_8(rs2, rs1, rd, SMULX8) <->
  0b1010101 @ rs2 @ rs1 @ 0b000 @ rd @ 0b1110111
mapping clause encdec = PEXT_MUL_8(rs2, rs1, rd, UMUL8)  <->
  0b1011100 @ rs2 @ rs1 @ 0b000 @ rd @ 0b1110111
mapping clause encdec = PEXT_MUL_8(rs2, rs1, rd, UMULX8) <->
  0b1011101 @ rs2 @ rs1 @ 0b000 @ rd @ 0b1110111

function clause execute (PEXT_MUL_8(rs2, rs1, rd, op)) = {
  let rs1_val = X(rs1);
  let rs2_val = X(rs2);
  let rs1_byte0 = slice(rs1_val, 0, 8);
  let rs1_byte1 = slice(rs1_val, 8, 8);
  let rs1_byte2 = slice(rs1_val, 16, 8);
  let rs1_byte3 = slice(rs1_val, 24, 8); 
  let rs2_byte0 = slice(rs2_val, 0, 8);
  let rs2_byte1 = slice(rs2_val, 8, 8);
  let rs2_byte2 = slice(rs2_val, 16, 8);
  let rs2_byte3 = slice(rs2_val, 24, 8);
  if sizeof(xlen) == 32
  then {
    let rd0 = (rd >> 1) << 1 ;
    let rd1 = rd0 + 1 ;
    result : xlenbits = zeros();
    result1 : xlenbits = zeros();
    match op {  
      SMUL8  => {
        result1 = smul(rs1_byte3, rs2_byte3) @ smul(rs1_byte2, rs2_byte2);
        result  = smul(rs1_byte1, rs2_byte1) @ smul(rs1_byte0, rs2_byte0)
        },
      SMULX8 => {
        result1 = smul(rs1_byte3, rs2_byte2) @ smul(rs1_byte2, rs2_byte3);
        result  = smul(rs1_byte1, rs2_byte0) @ smul(rs1_byte0, rs2_byte1)
        },
      UMUL8  => {
        result1 = umul(rs1_byte3, rs2_byte3) @ umul(rs1_byte2, rs2_byte2);
        result  = umul(rs1_byte1, rs2_byte1) @ umul(rs1_byte0, rs2_byte0)
        },
      UMULX8 => {
        result1 = umul(rs1_byte3, rs2_byte2) @ umul(rs1_byte2, rs2_byte3);
        result  = umul(rs1_byte1, rs2_byte0) @ umul(rs1_byte0, rs2_byte1)
        }
    }; 
    X(rd0) = result;
    X(rd1) = result1;
  }
  else {
    result : xlenbits = zeros();
    match op {  
      SMUL8  => {
        result = smul(rs1_byte3, rs2_byte3) @ smul(rs1_byte2, rs2_byte2) @
                 smul(rs1_byte1, rs2_byte1) @ smul(rs1_byte0, rs2_byte0)
        },
      SMULX8 => {
        result = smul(rs1_byte3, rs2_byte2) @ smul(rs1_byte2, rs2_byte3) @
                 smul(rs1_byte1, rs2_byte0) @ smul(rs1_byte0, rs2_byte1)
        },
      UMUL8  => {
        result = umul(rs1_byte3, rs2_byte3) @ umul(rs1_byte2, rs2_byte2) @
                 umul(rs1_byte1, rs2_byte1) @ umul(rs1_byte0, rs2_byte0)
       },
      UMULX8 => {
        result = umul(rs1_byte3, rs2_byte2) @ umul(rs1_byte2, rs2_byte3) @
                 umul(rs1_byte1, rs2_byte0) @ umul(rs1_byte0, rs2_byte1)
        }
    }; 
    X(rd) = result;
  };
  RETIRE_SUCCESS 
}

mapping p_MUL8_mapping : p_mul_8_op <-> string = {
    SMUL8  <-> "SMUL8",
    SMULX8 <-> "SMULX8",
    UMUL8  <-> "UMUL8",
    UMULX8 <-> "UMULX8"
}

mapping clause assembly = PEXT_MUL_8(rs2, rs1, rd, p_inst)
  <-> p_MUL8_mapping(p_inst) ^ spc() ^ reg_name(rd) ^ sep() ^ reg_name(rs1) ^ sep() ^ reg_name(rs2)

/* PEXT_ONE_REGISTER_8 AST */
union clause ast = PEXT_ONE_REGISTER_8 : (regidx, regidx, p_one_register_8_op)

mapping clause encdec = PEXT_ONE_REGISTER_8(rs1, rd, CLRS8) <->
  0b1010111 @ 0b00000 @ rs1 @ 0b000 @ rd @ 0b1110111
mapping clause encdec = PEXT_ONE_REGISTER_8(rs1, rd, CLO8) <->
  0b1010111 @ 0b00011 @ rs1 @ 0b000 @ rd @ 0b1110111
mapping clause encdec = PEXT_ONE_REGISTER_8(rs1, rd, CLZ8) <->
  0b1010111 @ 0b00001 @ rs1 @ 0b000 @ rd @ 0b1110111
mapping clause encdec = PEXT_ONE_REGISTER_8(rs1, rd, KABS8) <->
  0b1010110 @ 0b10000 @ rs1 @ 0b000 @ rd @ 0b1110111

function clause execute (PEXT_ONE_REGISTER_8(rs1, rd, op)) = {
  let rs1_val = X(rs1);
  result : xlenbits = zeros();
  foreach (i from 0 to (sizeof(xlen) - 8) by 8) {
    let rs1_byte = slice(rs1_val, i, 8);
    result[(i+7)..i] = match op {
      CLRS8 => clrs(rs1_byte),
      CLO8  => clo(rs1_byte),
      CLZ8  => clz(rs1_byte),
      KABS8 => kabs(rs1_byte)
    };
  };
  X(rd) = result;
  RETIRE_SUCCESS
}

mapping p_inst_rs1_rd_mapping : p_one_register_8_op <-> string = {
  CLRS8 <-> "CLRS8",
  CLO8  <-> "CLO8",
  CLZ8  <-> "CLZ8",
  KABS8 <-> "KABS8"
}

mapping clause assembly = PEXT_ONE_REGISTER_8(rs1, rd, p_inst)
  <-> p_inst_rs1_rd_mapping(p_inst) ^ spc() ^ reg_name(rd) ^ sep() ^ reg_name(rs1)


/* PEXT_KHM_8 AST */
union clause ast = PEXT_KHM_8 : (regidx, regidx, regidx, p_khm8_op)

mapping clause encdec = PEXT_KHM_8(rs2, rs1, rd, KHM8) <->
  0b1000111 @ rs2 @ rs1 @ 0b000 @ rd @ 0b1110111
mapping clause encdec = PEXT_KHM_8(rs2, rs1, rd, KHMX8) <->
  0b1001111 @ rs2 @ rs1 @ 0b000 @ rd @ 0b1110111

function clause execute (PEXT_KHM_8(rs2 ,rs1, rd, op)) = {
  let rs1_val = X(rs1);
  let rs2_val = X(rs2);
  result : xlenbits = zeros();
  foreach (i from 0 to (sizeof(xlen) - 16) by 16) {
    let rs1_byte_bottom = slice(rs1_val, i, 8);
    let rs1_byte_top = slice(rs1_val, i + 8, 8);
    let rs2_byte_bottom = slice(rs2_val, i, 8);
    let rs2_byte_top = slice(rs2_val, i + 8, 8);
    result[(i+15)..i] = match op {
      KHM8  => khm(rs1_byte_top, rs2_byte_top) @ khm(rs1_byte_bottom, rs2_byte_bottom),
      KHMX8 => khm(rs1_byte_top, rs2_byte_bottom) @ khm(rs1_byte_bottom, rs2_byte_top)
    };
  };
  X(rd) = result;
  RETIRE_SUCCESS
} 

mapping p_khm_8_mapping : p_khm8_op <-> string = {
    KHM8  <-> "KHM8",
    KHMX8 <-> "KHMX8"
}

mapping clause assembly = PEXT_KHM_8(rs2, rs1, rd, p_inst)
  <-> p_khm_8_mapping(p_inst) ^ spc() ^ reg_name(rd) ^ sep() ^ reg_name(rs1) ^ sep() ^ reg_name(rs2)

/* PEXT_IMM3 AST */
union clause ast = PEXT_IMM3 : (bits(3), regidx, regidx, p_imm3_op)

mapping clause encdec = PEXT_IMM3(imm3, rs1, rd, KSLLI8) <->
  0b0111110 @ 0b01 @ imm3 @ rs1 @ 0b000 @ rd @ 0b1110111
mapping clause encdec = PEXT_IMM3(imm3, rs1, rd, SCLIP8) <->
  0b1000110 @ 0b00 @ imm3 @ rs1 @ 0b000 @ rd @ 0b1110111
mapping clause encdec = PEXT_IMM3(imm3, rs1, rd, SLLI8) <->
  0b0111110 @ 0b00 @ imm3 @ rs1 @ 0b000 @ rd @ 0b1110111
mapping clause encdec = PEXT_IMM3(imm3, rs1, rd, SRAI8) <->
  0b0111100 @ 0b00 @ imm3 @ rs1 @ 0b000 @ rd @ 0b1110111
mapping clause encdec = PEXT_IMM3(imm3, rs1, rd, SRAI8_U) <->
  0b0111100 @ 0b01 @ imm3 @ rs1 @ 0b000 @ rd @ 0b1110111
mapping clause encdec = PEXT_IMM3(imm3, rs1, rd, SRLI8) <->
  0b0111101 @ 0b00 @ imm3 @ rs1 @ 0b000 @ rd @ 0b1110111
mapping clause encdec = PEXT_IMM3(imm3, rs1, rd, SRLI8_U) <->
  0b0111101 @ 0b01 @ imm3 @ rs1 @ 0b000 @ rd @ 0b1110111
mapping clause encdec = PEXT_IMM3(imm3, rs1, rd, UCLIP8) <->
  0b1000110 @ 0b10 @ imm3 @ rs1 @ 0b000 @ rd @ 0b1110111

function clause execute (PEXT_IMM3(imm3, rs1, rd, op)) = {
  let rs1_val = X(rs1);
  let sa : bits(8) = EXTZ(imm3);
  result : xlenbits = zeros();
  foreach (i from 0 to (sizeof(xlen) - 8) by 8) {
    let rs1_byte = slice(rs1_val, i, 8);
    result[(i+7)..i] = match op {
      SRAI8   => shift_right_arith(rs1_byte, sa),
      SRAI8_U => shift_right_arith_u(rs1_byte, sa),
      SRLI8   => shift_right_logic(rs1_byte, sa),
      SRLI8_U => shift_right_logic_u(rs1_byte, sa),
      SLLI8   => shift_left_logic(rs1_byte, sa),
      KSLLI8  => kshift_left_logic(rs1_byte, sa),
      SCLIP8  => sclip(rs1_byte, sa),
      UCLIP8  => uclip(rs1_byte, sa)
    };
  };
  X(rd) = result;
  RETIRE_SUCCESS
}

mapping p_inst_imm3_rs1_rd_mapping : p_imm3_op <-> string = {
  KSLLI8  <-> "KSLLI8",
  SLLI8   <-> "SLLI8",
  SRAI8   <-> "SRAI8",
  SRAI8_U <-> "SRAI8_U",
  SRLI8   <-> "SRLI8",
  SRLI8_U <-> "SRLI8_U",
  SCLIP8  <-> "SCLIP8",
  UCLIP8  <-> "UCLIP8"
}

mapping clause assembly = PEXT_IMM3(imm3, rs1, rd, p_inst)
  <-> p_inst_imm3_rs1_rd_mapping(p_inst) ^ spc() ^ reg_name(rd) ^ sep() ^ reg_name(rs1) ^ sep() ^ hex_bits_3(imm3)

/* PEXT_UNPACK_SWAP AST */
union clause ast = PEXT_UNPACK_SWAP : (regidx, regidx, p_unpack_swap_op)

mapping clause encdec = PEXT_UNPACK_SWAP(rs1, rd, SUNPKD810) <->
  0b1010110 @ 0b01000 @ rs1 @ 0b000 @ rd @ 0b1110111
mapping clause encdec = PEXT_UNPACK_SWAP(rs1, rd, SUNPKD820) <->
  0b1010110 @ 0b01001 @ rs1 @ 0b000 @ rd @ 0b1110111
mapping clause encdec = PEXT_UNPACK_SWAP(rs1, rd, SUNPKD830) <->
  0b1010110 @ 0b01010 @ rs1 @ 0b000 @ rd @ 0b1110111
mapping clause encdec = PEXT_UNPACK_SWAP(rs1, rd, SUNPKD831) <->
  0b1010110 @ 0b01011 @ rs1 @ 0b000 @ rd @ 0b1110111
mapping clause encdec = PEXT_UNPACK_SWAP(rs1, rd, SUNPKD832) <->
  0b1010110 @ 0b10011 @ rs1 @ 0b000 @ rd @ 0b1110111
mapping clause encdec = PEXT_UNPACK_SWAP(rs1, rd, SWAP8) <->
  0b1010110 @ 0b11000 @ rs1 @ 0b000 @ rd @ 0b1110111
mapping clause encdec = PEXT_UNPACK_SWAP(rs1, rd, ZUNPKD810) <->
  0b1010110 @ 0b01100 @ rs1 @ 0b000 @ rd @ 0b1110111
mapping clause encdec = PEXT_UNPACK_SWAP(rs1, rd, ZUNPKD820) <->
  0b1010110 @ 0b01101 @ rs1 @ 0b000 @ rd @ 0b1110111
mapping clause encdec = PEXT_UNPACK_SWAP(rs1, rd, ZUNPKD830) <->
  0b1010110 @ 0b01110 @ rs1 @ 0b000 @ rd @ 0b1110111
mapping clause encdec = PEXT_UNPACK_SWAP(rs1, rd, ZUNPKD831) <->
  0b1010110 @ 0b01111 @ rs1 @ 0b000 @ rd @ 0b1110111
mapping clause encdec = PEXT_UNPACK_SWAP(rs1, rd, ZUNPKD832) <->
  0b1010110 @ 0b10111 @ rs1 @ 0b000 @ rd @ 0b1110111

function clause execute (PEXT_UNPACK_SWAP(rs1, rd, op)) = {
  let rs1_val = X(rs1);
  result : xlenbits = zeros();
  resultH : bits(16) = zeros();
  resultL : bits(16) = zeros();
  foreach (i from 0 to (sizeof(xlen) - 32) by 32) {
    let rs1_byte0 = slice(rs1_val, i, 8);
    let rs1_byte1 = slice(rs1_val, i+8, 8);
    let rs1_byte2 = slice(rs1_val, i+16, 8);
    let rs1_byte3 = slice(rs1_val, i+24, 8);
    result[(i+31)..i] = match op {
      SWAP8     => rs1_byte2 @ rs1_byte3 @ rs1_byte0 @ rs1_byte1,
      SUNPKD810 => {
        resultH = EXTS(rs1_byte1); 
        resultL = EXTS(rs1_byte0);
        resultH @ resultL},
      SUNPKD820 => {
        resultH = EXTS(rs1_byte2); 
        resultL = EXTS(rs1_byte0);
        resultH @ resultL
        },
      SUNPKD830 => { 
        resultH = EXTS(rs1_byte3); 
        resultL = EXTS(rs1_byte0);
        resultH @ resultL
        },
      SUNPKD831 => {
        resultH = EXTS(rs1_byte3); 
        resultL = EXTS(rs1_byte1);
        resultH @ resultL
        },
      SUNPKD832 => {
        resultH = EXTS(rs1_byte3); 
        resultL = EXTS(rs1_byte2);
        resultH @ resultL
        },
      ZUNPKD810 => {
        resultH = EXTZ(rs1_byte1); 
        resultL = EXTZ(rs1_byte0);
        resultH @ resultL
        },
      ZUNPKD820 => {
        resultH = EXTZ(rs1_byte2); 
        resultL = EXTZ(rs1_byte0);
        resultH @ resultL
        },
      ZUNPKD830 => {
        resultH = EXTZ(rs1_byte3); 
        resultL = EXTZ(rs1_byte0);
        resultH @ resultL
        },
      ZUNPKD831 => {
        resultH = EXTZ(rs1_byte3); 
        resultL = EXTZ(rs1_byte1);
        resultH @ resultL
        },
      ZUNPKD832 => {
        resultH = EXTZ(rs1_byte3); 
        resultL = EXTZ(rs1_byte2);
        resultH @ resultL
        }
    }
  };
  X(rd) = result;
  RETIRE_SUCCESS
}

mapping p_inst_swap_unpack_mapping : p_unpack_swap_op <-> string = {
  SWAP8     <-> "SWAP8",
  SUNPKD810 <-> "SUNPKD810",
  SUNPKD820 <-> "SUNPKD820",
  SUNPKD830 <-> "SUNPKD830",
  SUNPKD831 <-> "SUNPKD831",
  SUNPKD832 <-> "SUNPKD832",
  ZUNPKD810 <-> "ZUNPKD810",
  ZUNPKD820 <-> "ZUNPKD820",
  ZUNPKD830 <-> "ZUNPKD830",
  ZUNPKD831 <-> "ZUNPKD831",
  ZUNPKD832 <-> "ZUNPKD832"
}

mapping clause assembly = PEXT_UNPACK_SWAP(rs1, rd, p_inst)
  <-> p_inst_swap_unpack_mapping(p_inst) ^ spc() ^ reg_name(rd) ^ sep() ^ reg_name(rs1)
  