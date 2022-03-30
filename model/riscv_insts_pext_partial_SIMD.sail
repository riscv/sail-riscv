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
/* This file specifies the Partial-SIMD Data Processing Instructions added by the 'P' extension. */

/* Programming Langauge Lab, Department of Computer Science, National Tsing-Hua University, Taiwan */
/* Academia Sinica, Taiwan*/
/* Andes Technology Corporation*/

/* PEXT_PACK_16 AST */
union clause ast = PEXT_PACK_16 : (regidx, regidx, regidx, p_inst_pack_16)

mapping clause encdec = PEXT_PACK_16(rs2, rs1, rd, PKBB16) <->
  0b0000111 @ rs2 @ rs1 @ 0b001 @ rd @ 0b1110111
mapping clause encdec = PEXT_PACK_16(rs2, rs1, rd, PKBT16) <->
  0b0001111 @ rs2 @ rs1 @ 0b001 @ rd @ 0b1110111
mapping clause encdec = PEXT_PACK_16(rs2, rs1, rd, PKTT16) <->
  0b0010111 @ rs2 @ rs1 @ 0b001 @ rd @ 0b1110111
mapping clause encdec = PEXT_PACK_16(rs2, rs1, rd, PKTB16) <->
  0b0011111 @ rs2 @ rs1 @ 0b001 @ rd @ 0b1110111

function clause execute (PEXT_PACK_16(rs2, rs1, rd, op)) = {
  let rs1_val = X(rs1);
  let rs2_val = X(rs2);
  result : xlenbits = zeros();
  foreach (i from 0 to (sizeof(xlen) - 32) by 32) {
    let rs1_word_bottom =  slice(rs1_val, i, 16);
    let rs1_word_top =  slice(rs1_val, i+16, 16);   
    let rs2_word_bottom =  slice(rs2_val, i, 16);
    let rs2_word_top =  slice(rs2_val, i+16, 16);
    result[(i + 31)..i] = match op {
      PKBB16 => rs1_word_bottom @ rs2_word_bottom,
      PKBT16 => rs1_word_bottom @ rs2_word_top,
      PKTB16 => rs1_word_top @ rs2_word_bottom,
      PKTT16 => rs1_word_top @ rs2_word_top
    };
  };
  X(rd) = result;
  RETIRE_SUCCESS
}

mapping p_pack_16_mapping : p_inst_pack_16 <-> string = {
    PKBB16 <-> "PKBB16",
    PKTB16 <-> "PKTB16",
    PKBT16 <-> "PKBT16",
    PKTT16 <-> "PKTT16"
}

mapping clause assembly = PEXT_PACK_16(rs2, rs1, rd, p_inst)
  <-> p_pack_16_mapping(p_inst) ^ spc() ^ reg_name(rd) ^ sep() ^ reg_name(rs1) ^ sep() ^ reg_name(rs2)

/* PEXT_32_32_MUL_ADD AST */
union clause ast = PEXT_32_32_MUL_ADD : (regidx, regidx, regidx, p_inst_32_32_mul_add)

mapping clause encdec = PEXT_32_32_MUL_ADD(rs2, rs1, rd, SMMUL)    <->
  0b0100000 @ rs2 @ rs1 @ 0b001 @ rd @ 0b1110111
mapping clause encdec = PEXT_32_32_MUL_ADD(rs2, rs1, rd, SMMUL_U)  <->
  0b0101000 @ rs2 @ rs1 @ 0b001 @ rd @ 0b1110111
mapping clause encdec = PEXT_32_32_MUL_ADD(rs2, rs1, rd, KMMAC)    <->
  0b0110000 @ rs2 @ rs1 @ 0b001 @ rd @ 0b1110111
mapping clause encdec = PEXT_32_32_MUL_ADD(rs2, rs1, rd, KMMAC_U)  <->
  0b0111000 @ rs2 @ rs1 @ 0b001 @ rd @ 0b1110111
mapping clause encdec = PEXT_32_32_MUL_ADD(rs2, rs1, rd, KMMSB)    <->
  0b0100001 @ rs2 @ rs1 @ 0b001 @ rd @ 0b1110111
mapping clause encdec = PEXT_32_32_MUL_ADD(rs2, rs1, rd, KMMSB_U)  <->
  0b0101001 @ rs2 @ rs1 @ 0b001 @ rd @ 0b1110111
mapping clause encdec = PEXT_32_32_MUL_ADD(rs2, rs1, rd, KWMMUL)   <->
  0b0110001 @ rs2 @ rs1 @ 0b001 @ rd @ 0b1110111
mapping clause encdec = PEXT_32_32_MUL_ADD(rs2, rs1, rd, KWMMUL_U) <->
  0b0111001 @ rs2 @ rs1 @ 0b001 @ rd @ 0b1110111

/* SIMD MSW Signed Multiply Word */
val msb_smul :
  (bits(32), bits(32)) -> bits(32)
function msb_smul (v1, v2) =
  to_bits (64, signed(v1) * signed(v2))[63..32]

val msb_smul_u :
  (bits(32), bits(32)) -> bits(32)
function msb_smul_u (v1, v2) =
  add_bits(to_bits (64, signed(v1) * signed(v2))[63..31] , 0x00000000 @ 0b1)[32..1]

/* Most Significant Word mul add/sub auxiliary function */


function clause execute (PEXT_32_32_MUL_ADD(rs2, rs1, rd, op)) = {
  let rs1_val = X(rs1);
  let rs2_val = X(rs2);
  let rd_val  = X(rd);
  result : xlenbits = zeros();
  foreach (i from 0 to (sizeof(xlen) - 32) by 32) {
    let rs1_word =  slice(rs1_val, i, 32);
    let rs2_word =  slice(rs2_val, i, 32);
    let rd_word  =  slice(rd_val, i, 32);
    result[(i+31)..i] = match op {
      SMMUL    => msb_smul(rs1_word, rs2_word),
      SMMUL_U  => msb_smul_u(rs1_word, rs2_word),
      KMMAC    => {
        let res : bits(33) = add_bits(EXTS(msb_smul(rs1_word, rs2_word)), EXTS(rd_word));
        q31(res)
      },
      KMMAC_U  => {
        let res : bits(33) = add_bits(EXTS(msb_smul_u(rs1_word, rs2_word)), EXTS(rd_word));
        q31(res)
      },
      KMMSB    => {
        let res : bits(33) = sub_bits(EXTS(rd_word), EXTS(msb_smul(rs1_word, rs2_word)));
        q31(res)
      },
      KMMSB_U  => {
        let res : bits(33) = sub_bits(EXTS(rd_word), EXTS(msb_smul_u(rs1_word, rs2_word)));
        q31(res)
      },
      KWMMUL   => {
        if (rs1_word != 0x80000000) | (rs2_word != 0x80000000)
        then smul(rs1_word, rs2_word)[62..31]
        else { pext_write_OV (0b1); 0x7FFFFFFF }
      },
      KWMMUL_U => {
        if (rs1_word != 0x80000000) | (rs2_word != 0x80000000)
        then {
        let mres : bits(64) = smul(rs1_word, rs2_word);
        let round33 : bits(34) = add_bits(mres[63..30], EXTZ(0x1));
        round33[32..1]
        } else { 
          pext_write_OV (0b1); 
          0x7FFFFFFF 
        }
      }
    };
  };
  X(rd) = result;
  RETIRE_SUCCESS
}

/*
function clause execute (PEXT_32_32_MUL_ADD(rs2, rs1, rd, op)) = {
  let rs1_val = X(rs1);
  let rs2_val = X(rs2);
  let rd_val  = X(rd);
  result : xlenbits = zeros();
  foreach (i from 0 to (sizeof(xlen) - 32) by 32) {
    let rs1_word =  slice(rs1_val, i, 32);
    let rs2_word =  slice(rs2_val, i, 32);
    let rd_word  =  slice(rd_val, i, 32);
    result[(i+31)..i] = match op {
      SMMUL    => msb_smul(rs1_word, rs2_word),
      SMMUL_U  => msb_smul_u(rs1_word, rs2_word),
      KMMAC    => kmsbmac(rs1_word, rs2_word, rd_word),
      KMMAC_U  => kmsbmac_u(rs1_word, rs2_word, rd_word),
      KMMSB    => kmsbsb(rs1_word, rs2_word, rd_word),
      KMMSB_U  => kmsbsb_u(rs1_word, rs2_word, rd_word),
      KWMMUL   => kwmsbmul(rs1_word, rs2_word ),
      KWMMUL_U => kwmsbmul_u(rs1_word, rs2_word)
    };
  };
  X(rd) = result;
  RETIRE_SUCCESS
}
*/

mapping p_32_32_mul_add_mapping : p_inst_32_32_mul_add <-> string = {
    SMMUL    <-> "SMMUL",
    SMMUL_U  <-> "SMMUL_U",
    KMMAC    <-> "KMMAC",
    KMMAC_U  <-> "KMMAC_U",
    KMMSB    <-> "KMMSB",
    KMMSB_U  <-> "KMMSB_U",
    KWMMUL   <-> "KWMMUL",
    KWMMUL_U <-> "KWMMUL_U"
}

mapping clause assembly = PEXT_32_32_MUL_ADD(rs2, rs1, rd, p_inst)
  <-> p_32_32_mul_add_mapping(p_inst) ^ spc() ^ reg_name(rd) ^ sep() ^ reg_name(rs1) ^ sep() ^ reg_name(rs2)

/* PEXT_32_16_MUL_ADD AST */
union clause ast = PEXT_32_16_MUL_ADD : (regidx, regidx, regidx, p_inst_32_16_mul_add)

mapping clause encdec = PEXT_32_16_MUL_ADD(rs2, rs1, rd, SMMWB)     <->
  0b0100010 @ rs2 @ rs1 @ 0b001 @ rd @ 0b1110111
mapping clause encdec = PEXT_32_16_MUL_ADD(rs2, rs1, rd, SMMWB_U)   <->
  0b0101010 @ rs2 @ rs1 @ 0b001 @ rd @ 0b1110111
mapping clause encdec = PEXT_32_16_MUL_ADD(rs2, rs1, rd, SMMWT)     <->
  0b0110010 @ rs2 @ rs1 @ 0b001 @ rd @ 0b1110111
mapping clause encdec = PEXT_32_16_MUL_ADD(rs2, rs1, rd, SMMWT_U)   <->
  0b0111010 @ rs2 @ rs1 @ 0b001 @ rd @ 0b1110111
mapping clause encdec = PEXT_32_16_MUL_ADD(rs2, rs1, rd, KMMAWB)    <->
  0b0100011 @ rs2 @ rs1 @ 0b001 @ rd @ 0b1110111
mapping clause encdec = PEXT_32_16_MUL_ADD(rs2, rs1, rd, KMMAWB_U)  <->
  0b0101011 @ rs2 @ rs1 @ 0b001 @ rd @ 0b1110111
mapping clause encdec = PEXT_32_16_MUL_ADD(rs2, rs1, rd, KMMAWT)    <->
  0b0110011 @ rs2 @ rs1 @ 0b001 @ rd @ 0b1110111
mapping clause encdec = PEXT_32_16_MUL_ADD(rs2, rs1, rd, KMMAWT_U)  <->
  0b0111011 @ rs2 @ rs1 @ 0b001 @ rd @ 0b1110111
mapping clause encdec = PEXT_32_16_MUL_ADD(rs2, rs1, rd, KMMWB2)    <->
  0b1000111 @ rs2 @ rs1 @ 0b001 @ rd @ 0b1110111
mapping clause encdec = PEXT_32_16_MUL_ADD(rs2, rs1, rd, KMMWB2_U)  <->
  0b1001111 @ rs2 @ rs1 @ 0b001 @ rd @ 0b1110111
mapping clause encdec = PEXT_32_16_MUL_ADD(rs2, rs1, rd, KMMWT2)    <->
  0b1010111 @ rs2 @ rs1 @ 0b001 @ rd @ 0b1110111
mapping clause encdec = PEXT_32_16_MUL_ADD(rs2, rs1, rd, KMMWT2_U)  <->
  0b1011111 @ rs2 @ rs1 @ 0b001 @ rd @ 0b1110111
mapping clause encdec = PEXT_32_16_MUL_ADD(rs2, rs1, rd, KMMAWB2)   <->
  0b1100111 @ rs2 @ rs1 @ 0b001 @ rd @ 0b1110111
mapping clause encdec = PEXT_32_16_MUL_ADD(rs2, rs1, rd, KMMAWB2_U) <->
  0b1101111 @ rs2 @ rs1 @ 0b001 @ rd @ 0b1110111
mapping clause encdec = PEXT_32_16_MUL_ADD(rs2, rs1, rd, KMMAWT2)   <->
  0b1110111 @ rs2 @ rs1 @ 0b001 @ rd @ 0b1110111
mapping clause encdec = PEXT_32_16_MUL_ADD(rs2, rs1, rd, KMMAWT2_U) <->
  0b1111111 @ rs2 @ rs1 @ 0b001 @ rd @ 0b1110111

/* SIMD Most Significant Word Signed Multiply Word and Bottom Half */
val smmw :
  (bits(32), bits(16)) -> bits(32)
function smmw (v1, v2) =
  to_bits (48, signed(v1) * signed(v2))[47..16]

val smmw_u :
  (bits(32), bits(16)) -> bits(32)
function smmw_u (v1, v2) =
  add_bits(to_bits (48, signed(v1) * signed(v2))[47..15] , EXTZ(0x1))[32..1]

val kmmaw :
  (bits(32), bits(16), bits(32)) -> bits(32) effect {rreg,wreg}
function kmmaw (v1, v2, rd) = {
  let mres : bits(48) = to_bits(48, signed(v1) * signed(v2));
  let res : bits(33) = add_bits(EXTS(rd), EXTS(mres[47..16]));
  q31(res)
}
val kmmaw_u :
  (bits(32), bits(16), bits(32)) -> bits(32) effect {rreg,wreg}
function kmmaw_u (v1, v2, rd) = {
  let mres : bits(48) = to_bits(48, signed(v1) * signed(v2));
  let round33 : bits(33) = add_bits(mres[47..15], EXTS(0x1));
  let res : bits(33) = add_bits(EXTS(rd), EXTS(round33[32..1]));
  q31(res)
}
val kmmaw2 :
  (bits(32), bits(16), bits(32)) -> bits(32) effect {rreg,wreg}
function kmmaw2 (v1, v2, rd) = {
  let addop : bits(32) =
  if (v1 != 0x80000000) | (v2 != 0x8000)
  then to_bits(48, signed(v1) * signed(v2))[46..15]
  else {pext_write_OV (0b1); 0x7FFFFFFF};
  let res : bits(33) = add_bits(EXTS(rd), EXTS(addop));
  q31(res)
}
val kmmaw2_u :
  (bits(32), bits(16), bits(32)) -> bits(32) effect {rreg,wreg}
function kmmaw2_u (v1, v2, rd) = {
  let round34 : bits(34) = add_bits(to_bits(48, signed(v1) * signed(v2))[47..14], EXTS(0x1));
  let addop : bits(32) =
  if (v1 != 0x80000000) | (v2 != 0x8000)
  then round34[32..1]
  else {pext_write_OV (0b1); 0x7FFFFFFF};
  let res : bits(33) = add_bits(EXTS(rd), EXTS(addop));
  q31(res)
}
val kmmw2 :
  (bits(32), bits(16)) -> bits(32) effect {rreg,wreg}
function kmmw2 (v1, v2) = {
  if (v1 == 0x80000000) & (v2 == 0x8000)
  then { pext_write_OV (0b1); 0x7FFFFFFF }
  else to_bits(48, signed(v1) * signed(v2))[46..15]
}
val kmmw2_u :
  (bits(32), bits(16)) -> bits(32) effect {rreg,wreg}
function kmmw2_u (v1, v2) = {
  if (v1 == 0x80000000) & (v2 == 0x8000)
  then { pext_write_OV (0b1); 0x7FFFFFFF }
  else {
  let round : bits(33) = add_bits( to_bits(48, signed(v1) * signed(v2))[46..14], EXTS(0x1));
  round[32..1]
  }
  
}
function clause execute (PEXT_32_16_MUL_ADD(rs2, rs1, rd, op)) = {
  let rs1_val = X(rs1);
  let rs2_val = X(rs2);
  let rd_val  = X(rd);
  result : xlenbits = zeros();
  foreach (i from 0 to (sizeof(xlen) - 32) by 32) {
    let rs1_word =  slice(rs1_val, i, 32);
    let rs2_word =  slice(rs2_val, i, 32);
    let rd_word  =  slice(rd_val, i, 32);
    result[(i+31)..i] = match op {
      SMMWB     => smmw(rs1_word, slice(rs2_word, 0, 16)),
      SMMWB_U   => smmw_u(rs1_word, slice(rs2_word, 0, 16)),
      SMMWT     => smmw(rs1_word, slice(rs2_word, 16, 16)),
      SMMWT_U   => smmw_u(rs1_word, slice(rs2_word, 16, 16)),
      KMMAWB    => kmmaw(rs1_word, slice(rs2_word, 0, 16), rd_word),
      KMMAWB_U  => kmmaw_u(rs1_word, slice(rs2_word, 0, 16), rd_word),
      KMMAWT    => kmmaw(rs1_word, slice(rs2_word, 16, 16), rd_word),
      KMMAWT_U  => kmmaw_u(rs1_word, slice(rs2_word, 16, 16), rd_word),
      KMMWB2    => kmmw2(rs1_word, slice(rs2_word, 0, 16)),
      KMMWB2_U  => kmmw2_u(rs1_word, slice(rs2_word, 0, 16)),
      KMMWT2    => kmmw2(rs1_word, slice(rs2_word, 16, 16)),
      KMMWT2_U  => kmmw2_u(rs1_word, slice(rs2_word, 16, 16)),
      KMMAWB2   => kmmaw2(rs1_word, slice(rs2_word, 0, 16), rd_word),
      KMMAWB2_U => kmmaw2_u(rs1_word, slice(rs2_word, 0, 16), rd_word),
      KMMAWT2   => kmmaw2(rs1_word, slice(rs2_word, 16, 16), rd_word),
      KMMAWT2_U => kmmaw2_u(rs1_word, slice(rs2_word, 16, 16), rd_word)
    };
  };
  X(rd) = result;
  RETIRE_SUCCESS
}

mapping p_32_16_muladd_mapping : p_inst_32_16_mul_add <-> string = {
    SMMWB     <-> "SMMWB",
    SMMWB_U   <-> "SMMWB_U",
    SMMWT     <-> "SMMWT",
    SMMWT_U   <-> "SMMWT_U",
    KMMAWB    <-> "KMMAWB",
    KMMAWB_U  <-> "KMMAWB_U",
    KMMAWT    <-> "KMMAWT",
    KMMAWT_U  <-> "KMMAWT_U",
    KMMWB2    <-> "KMMWB2",
    KMMWB2_U  <-> "KMMWB2_U",
    KMMWT2    <-> "KMMWT2",
    KMMWT2_U  <-> "KMMWT2_U",
    KMMAWB2   <-> "KMMAWB2",
    KMMAWB2_U <-> "KMMAWB2_U",
    KMMAWT2   <-> "KMMAWT2",
    KMMAWT2_U <-> "KMMAWT2_U"
}

mapping clause assembly = PEXT_32_16_MUL_ADD(rs2, rs1, rd, p_inst)
  <-> p_32_16_muladd_mapping(p_inst) ^ spc() ^ reg_name(rd) ^ sep() ^ reg_name(rs1) ^ sep() ^ reg_name(rs2)

/* PEXT_16_32_MUL_ADD AST */
union clause ast = PEXT_16_32_MUL_ADD : (regidx, regidx, regidx, p_inst_16_32_mul_add)

mapping clause encdec = PEXT_16_32_MUL_ADD(rs2, rs1, rd, SMBB16) <->
  0b0000100 @ rs2 @ rs1 @ 0b001 @ rd @ 0b1110111
mapping clause encdec = PEXT_16_32_MUL_ADD(rs2, rs1, rd, SMBT16) <->
  0b0001100 @ rs2 @ rs1 @ 0b001 @ rd @ 0b1110111
mapping clause encdec = PEXT_16_32_MUL_ADD(rs2, rs1, rd, SMTT16) <->
  0b0010100 @ rs2 @ rs1 @ 0b001 @ rd @ 0b1110111
mapping clause encdec = PEXT_16_32_MUL_ADD(rs2, rs1, rd, KMDA)   <->
  0b0011100 @ rs2 @ rs1 @ 0b001 @ rd @ 0b1110111
mapping clause encdec = PEXT_16_32_MUL_ADD(rs2, rs1, rd, KMXDA)  <->
  0b0011101 @ rs2 @ rs1 @ 0b001 @ rd @ 0b1110111
mapping clause encdec = PEXT_16_32_MUL_ADD(rs2, rs1, rd, SMDS)   <->
  0b0101100 @ rs2 @ rs1 @ 0b001 @ rd @ 0b1110111
mapping clause encdec = PEXT_16_32_MUL_ADD(rs2, rs1, rd, SMDRS)  <->
  0b0110100 @ rs2 @ rs1 @ 0b001 @ rd @ 0b1110111
mapping clause encdec = PEXT_16_32_MUL_ADD(rs2, rs1, rd, SMXDS)  <->
  0b0111100 @ rs2 @ rs1 @ 0b001 @ rd @ 0b1110111
mapping clause encdec = PEXT_16_32_MUL_ADD(rs2, rs1, rd, KMABB)  <->
  0b0101101 @ rs2 @ rs1 @ 0b001 @ rd @ 0b1110111
mapping clause encdec = PEXT_16_32_MUL_ADD(rs2, rs1, rd, KMABT)  <->
  0b0110101 @ rs2 @ rs1 @ 0b001 @ rd @ 0b1110111
mapping clause encdec = PEXT_16_32_MUL_ADD(rs2, rs1, rd, KMATT)  <->
  0b0111101 @ rs2 @ rs1 @ 0b001 @ rd @ 0b1110111
mapping clause encdec = PEXT_16_32_MUL_ADD(rs2, rs1, rd, KMADA)  <->
  0b0100100 @ rs2 @ rs1 @ 0b001 @ rd @ 0b1110111
mapping clause encdec = PEXT_16_32_MUL_ADD(rs2, rs1, rd, KMAXDA) <->
  0b0100101 @ rs2 @ rs1 @ 0b001 @ rd @ 0b1110111
mapping clause encdec = PEXT_16_32_MUL_ADD(rs2, rs1, rd, KMADS)  <->
  0b0101110 @ rs2 @ rs1 @ 0b001 @ rd @ 0b1110111
mapping clause encdec = PEXT_16_32_MUL_ADD(rs2, rs1, rd, KMADRS) <->
  0b0110110 @ rs2 @ rs1 @ 0b001 @ rd @ 0b1110111
mapping clause encdec = PEXT_16_32_MUL_ADD(rs2, rs1, rd, KMAXDS) <->
  0b0111110 @ rs2 @ rs1 @ 0b001 @ rd @ 0b1110111
mapping clause encdec = PEXT_16_32_MUL_ADD(rs2, rs1, rd, KMSDA)  <->
  0b0100110 @ rs2 @ rs1 @ 0b001 @ rd @ 0b1110111
mapping clause encdec = PEXT_16_32_MUL_ADD(rs2, rs1, rd, KMSXDA) <->
  0b0100111 @ rs2 @ rs1 @ 0b001 @ rd @ 0b1110111




function clause execute (PEXT_16_32_MUL_ADD(rs2, rs1, rd, op)) = {
  let rs1_val = X(rs1);
  let rs2_val = X(rs2);
  let rd_val  = X(rd);
  result : xlenbits = zeros();
  foreach (i from 0 to (sizeof(xlen) - 32) by 32) {
    let rs1_word =  slice(rs1_val, i, 32);
    let rs2_word =  slice(rs2_val, i, 32);
    let rd_word  =  slice(rd_val, i, 32);
    result[(i+31)..i] = match op {
      SMBB16 => smul(slice(rs1_word, 0, 16), slice(rs2_word, 0, 16)),
      SMBT16 => smul(slice(rs1_word, 0, 16), slice(rs2_word, 16, 16)),
      SMTT16 => smul(slice(rs1_word, 16, 16), slice(rs2_word, 16, 16)),
      KMDA   => signed_mul_two_half_and_add(slice(rs1_word, 16, 16), slice(rs2_word, 16, 16), slice(rs1_word, 0, 16), slice(rs2_word, 0, 16)),
      KMXDA  => signed_mul_two_half_and_add(slice(rs1_word, 16, 16), slice(rs2_word, 0, 16), slice(rs1_word, 0, 16), slice(rs2_word, 16, 16)),
      SMDS   => smul(slice(rs1_word, 16, 16), slice(rs2_word, 16, 16)) - smul(slice(rs1_word, 0, 16), slice(rs2_word, 0, 16)),
      SMDRS  => smul(slice(rs1_word, 0, 16), slice(rs2_word, 0, 16)) - smul(slice(rs1_word, 16, 16), slice(rs2_word, 16, 16)),
      SMXDS  => smul(slice(rs1_word, 16, 16), slice(rs2_word, 0, 16)) - smul(slice(rs1_word, 0, 16), slice(rs2_word, 16, 16)),
      KMABB  => kadd(smul(slice(rs1_word, 0, 16), slice(rs2_word, 0, 16)), rd_word),
      KMABT  => kadd(smul(slice(rs1_word, 0, 16), slice(rs2_word, 16, 16)), rd_word),
      KMATT  => kadd(smul(slice(rs1_word, 16, 16), slice(rs2_word, 16, 16)), rd_word), 
      KMADA  => saturating_signed_mul_two_words_and_two_adds(rd_word, slice(rs1_word, 16, 16), slice(rs2_word, 16, 16), slice(rs1_word, 0, 16), slice(rs2_word, 0, 16)),
      KMAXDA => saturating_signed_mul_two_words_and_two_adds(rd_word, slice(rs1_word, 16, 16), slice(rs2_word, 0, 16), slice(rs1_word, 0, 16), slice(rs2_word, 16, 16)),
      KMADS  => saturating_signed_mul_two_words_and_sub(rd_word, slice(rs1_word, 16, 16), slice(rs2_word, 16, 16), slice(rs1_word, 0, 16), slice(rs2_word, 0, 16)),
      KMADRS => saturating_signed_mul_two_words_and_sub(rd_word, slice(rs1_word, 0, 16), slice(rs2_word, 0, 16), slice(rs1_word, 16, 16), slice(rs2_word, 16, 16)),
      KMAXDS => saturating_signed_mul_two_words_and_sub(rd_word, slice(rs1_word, 16, 16), slice(rs2_word, 0, 16), slice(rs1_word, 0, 16), slice(rs2_word, 16, 16)),
      KMSDA  => saturating_signed_mul_two_halfs_and_add_and_sub(rd_word, slice(rs1_word, 16, 16), slice(rs2_word, 16, 16), slice(rs1_word, 0, 16), slice(rs2_word, 0, 16)),
      KMSXDA => saturating_signed_mul_two_halfs_and_add_and_sub(rd_word, slice(rs1_word, 16, 16), slice(rs2_word, 0, 16), slice(rs1_word, 0, 16), slice(rs2_word, 16, 16))
    };
  };
  X(rd) = result;
  RETIRE_SUCCESS
}

mapping p_16_32_muladd_mapping : p_inst_16_32_mul_add <-> string = {
    SMBB16 <-> "SMBB16",
    SMBT16 <-> "SMBT16",
    SMTT16 <-> "SMTT16",
    KMDA   <-> "KMDA",
    KMXDA  <-> "KMXDA",
    SMDS   <-> "SMDS",
    SMDRS  <-> "SMDRS",
    SMXDS  <-> "SMXDS",
    KMABB  <-> "KMABB",
    KMABT  <-> "KMABT",
    KMATT  <-> "KMATT",
    KMADA  <-> "KMADA",
    KMAXDA <-> "KMAXDA",
    KMADS  <-> "KMADS",
    KMADRS <-> "KMADRS",
    KMAXDS <-> "KMAXDS",
    KMSDA  <-> "KMSDA",
    KMSXDA <-> "KMSXDA"
}

mapping clause assembly = PEXT_16_32_MUL_ADD(rs2, rs1, rd, p_inst)
  <-> p_16_32_muladd_mapping(p_inst) ^ spc() ^ reg_name(rd) ^ sep() ^ reg_name(rs1) ^ sep() ^ reg_name(rs2)

/* PEXT_MISC_32 */
union clause ast = PEXT_MISC_32 : (bits(5), regidx, regidx, p_inst_misc_32)

mapping clause encdec = PEXT_MISC_32(imm5, rs1, rd, SCLIP32) <->
  0b1110010 @ imm5 @ rs1 @ 0b000 @ rd @ 0b1110111
mapping clause encdec = PEXT_MISC_32(imm5, rs1, rd, UCLIP32) <->
  0b1111010 @ imm5 @ rs1 @ 0b000 @ rd @ 0b1110111

function clause execute (PEXT_MISC_32(imm5, rs1, rd, op)) = {
  let rs1_val = X(rs1);
  let u_imm5 : bits(8) = EXTZ(imm5);
  result : xlenbits = zeros();
  foreach (i from 0 to (sizeof(xlen) - 32) by 32) {
    let rs1_word = slice(rs1_val, i, 32);
    result[(i+31)..i] = match op {
      SCLIP32   =>  sclip(rs1_word, u_imm5),
      UCLIP32   =>  uclip(rs1_word, u_imm5)
    };
  };
  X(rd) = result;
  RETIRE_SUCCESS
}

mapping p_misc_32_mapping : p_inst_misc_32 <-> string = {
  SCLIP32  <->  "SCLIP32",
  UCLIP32  <->  "UCLIP32"
}

mapping clause assembly = PEXT_MISC_32(imm5, rs1, rd, p_inst)
  <-> p_misc_32_mapping(p_inst) ^ spc() ^ reg_name(rd) ^ sep() ^ reg_name(rs1) ^ sep() ^ hex_bits_5(imm5)

/* PEXT_8_32_MUL_ADD AST */
union clause ast = PEXT_8_32_MUL_ADD : (regidx, regidx, regidx, p_inst_8_32_mul_add)

mapping clause encdec = PEXT_8_32_MUL_ADD(rs2, rs1, rd, SMAQA) <->
  0b1100100 @ rs2 @ rs1 @ 0b000 @ rd @ 0b1110111
mapping clause encdec = PEXT_8_32_MUL_ADD(rs2, rs1, rd, SMAQA_SU) <->
  0b1100101 @ rs2 @ rs1 @ 0b000 @ rd @ 0b1110111
mapping clause encdec = PEXT_8_32_MUL_ADD(rs2, rs1, rd, UMAQA) <->
  0b1100110 @ rs2 @ rs1 @ 0b000 @ rd @ 0b1110111

function clause execute (PEXT_8_32_MUL_ADD(rs2, rs1, rd, op)) = {
  let rs1_val = X(rs1);
  let rs2_val = X(rs2);
  let rd_val  = X(rd);
  result : xlenbits = zeros();
  tmp_value : bits(32) = zeros();
  foreach (i from 0 to (sizeof(xlen) - 8) by 8) {
    let rs1_byte =  slice(rs1_val, i, 8);
    let rs2_byte =  slice(rs2_val, i, 8);  
    tmp_value = match op {
      SMAQA    => tmp_value + EXTS(smul(rs1_byte,rs2_byte)),
      UMAQA    => tmp_value + EXTZ(umul(rs1_byte,rs2_byte)),
      SMAQA_SU => tmp_value + EXTS(sumul(rs1_byte,rs2_byte))
    };
    if( i==24 | i==56)
    then {
      let rd_word  =  slice(rd_val, (i + 8 - 32), 32);
      result[(i + 7)..(i - 24)] = rd_word + tmp_value;
      tmp_value = zeros();
    }
  };
  X(rd) = result;
  RETIRE_SUCCESS
}

mapping p_8_32_mul_add_mapping : p_inst_8_32_mul_add <-> string = {
    SMAQA    <-> "SMAQA",
    UMAQA    <-> "UMAQA",
    SMAQA_SU <-> "SMAQA_SU"
}

mapping clause assembly = PEXT_8_32_MUL_ADD(rs2, rs1, rd, p_inst)
  <-> p_8_32_mul_add_mapping(p_inst) ^ spc() ^ reg_name(rd) ^ sep() ^ reg_name(rs1) ^ sep() ^ reg_name(rs2)

/* PEXT_ONE_REGISTER_32 AST */
union clause ast = PEXT_ONE_REGISTER_32 : (regidx, regidx, p_inst_one_register_32)

mapping clause encdec = PEXT_ONE_REGISTER_32(rs1, rd, CLRS32) <->
  0b1010111 @ 0b11000 @ rs1 @ 0b000 @ rd @ 0b1110111
mapping clause encdec = PEXT_ONE_REGISTER_32(rs1, rd, CLO32)  <->
  0b1010111 @ 0b11011 @ rs1 @ 0b000 @ rd @ 0b1110111
mapping clause encdec = PEXT_ONE_REGISTER_32(rs1, rd, CLZ32)  <->
  0b1010111 @ 0b11001 @ rs1 @ 0b000 @ rd @ 0b1110111

function clause execute (PEXT_ONE_REGISTER_32(rs1, rd, op)) = {
  let rs1_val = X(rs1);
  result : xlenbits = zeros();
  foreach (i from 0 to (sizeof(xlen) - 32) by 32) {
    let rs1_word = slice(rs1_val, i, 32);
    result[(i + 31)..i] = match op {
      CLRS32 => clrs(rs1_word),
      CLO32  => clo(rs1_word),
      CLZ32  => clz(rs1_word)
    }
  };
  X(rd) = result;
  RETIRE_SUCCESS
}

mapping p_one_register_32_mapping : p_inst_one_register_32 <-> string = {
    CLRS32 <-> "CLRS32",
    CLO32  <-> "CLO32",
    CLZ32  <-> "CLZ32"
}

mapping clause assembly = PEXT_ONE_REGISTER_32(rs1, rd, p_inst)
  <-> p_one_register_32_mapping(p_inst) ^ spc() ^ reg_name(rd) ^ sep() ^ reg_name(rs1)

/* PEXT_PBSAD AST */
union clause ast = PEXT_PBSAD : (regidx, regidx, regidx, p_inst_pbsad)

mapping clause encdec = PEXT_PBSAD(rs2, rs1, rd, PBSAD)  <->
  0b1111110 @ rs2 @ rs1 @ 0b000 @ rd @ 0b1110111
mapping clause encdec = PEXT_PBSAD(rs2, rs1, rd, PBSADA) <->
  0b1111111 @ rs2 @ rs1 @ 0b000 @ rd @ 0b1110111

function clause execute (PEXT_PBSAD(rs2, rs1, rd, op)) = {
  let rs1_val = X(rs1);
  let rs2_val = X(rs2);
  result : xlenbits = zeros();
  foreach (i from 0 to (sizeof(xlen) - 8) by 8) {
    let rs1_byte = slice(rs1_val, i, 8);
    let rs2_byte = slice(rs2_val, i, 8);
    tmp : xlenbits = zeros();
    tmp = { 
      let v1ext : bits(9) = EXTZ(rs1_byte) ;
      let v2ext : bits(9) = EXTZ(rs2_byte) ;
      let pos : xlenbits = EXTS (v1ext - v2ext) ;
      xlen_zeros : xlenbits = zeros();
      if pos <_s xlen_zeros then not_vec(pos) + 1 else pos
    };
    result = result + tmp ;
  };
  result = match op {
    PBSAD  => result,
    PBSADA => X(rd) + result
  };
  X(rd) = result;
  RETIRE_SUCCESS
}

mapping p_inst_pbsad_mapping : p_inst_pbsad <-> string = {
  PBSAD  <-> "PBSAD",
  PBSADA <-> "PBSADA"
}

mapping clause assembly = PEXT_PBSAD(rs2, rs1, rd, p_inst)
  <-> p_inst_pbsad_mapping(p_inst) ^ spc() ^ reg_name(rd) ^ sep() ^ reg_name(rs1) ^ sep() ^ reg_name(rs2)

/* PEXT_SMAL AST */
union clause ast = PEXT_SMAL : (regidx, regidx, regidx)

mapping clause encdec = PEXT_SMAL(rs2, rs1, rd) <->
  0b0101111 @ rs2 @ rs1 @ 0b001 @ rd @ 0b1110111

function clause execute (PEXT_SMAL(rs2, rs1, rd)) = {
    let rs1_val = X(rs1);
    let rs2_val = X(rs2);
    if sizeof(xlen) == 32
    then {
        let rs10 = (rs1 >> 1) << 1 ;
        let rs11 = rs10 + 1 ;
        let rd0 = (rd >> 1) << 1 ;
        let rd1 = rd0 + 1 ;
        let result : bits(64) = (X(rs11) @ X(rs10)) + EXTS(smul(slice(rs2_val, 16, 16), slice(rs2_val, 0, 16))); 
        X(rd1) = result[63..32];
        X(rd0) = result[31..0];
    } else
        X(rd)  = rs1_val + EXTS(smul(slice(rs2_val, 48, 16), slice(rs2_val, 32, 16))) + EXTS(smul(slice(rs2_val, 16, 16), slice(rs2_val, 0, 16)));
    RETIRE_SUCCESS
}

mapping clause assembly = PEXT_SMAL(rs2, rs1, rd)
  <-> "SMAL" ^ spc() ^ reg_name(rd) ^ sep() ^ reg_name(rs1) ^ sep() ^ reg_name(rs2)
