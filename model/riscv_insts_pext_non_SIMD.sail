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
/* This file specifies the Non-SIMD Instructions added by the 'P' extension. */

/* Programming Langauge Lab, Department of Computer Science, National Tsing-Hua University, Taiwan */
/* Academia Sinica, Taiwan*/
/* Andes Technology Corporation*/

/* PEXT_Q15 AST */
union clause ast = PEXT_Q15 : (regidx, regidx, regidx, p_inst_q15)

mapping clause encdec = PEXT_Q15(rs2, rs1, rd, KADDH)  <->
  0b0000010 @ rs2 @ rs1 @ 0b001 @ rd @ 0b1110111
mapping clause encdec = PEXT_Q15(rs2, rs1, rd, KSUBH)  <->
  0b0000011 @ rs2 @ rs1 @ 0b001 @ rd @ 0b1110111
mapping clause encdec = PEXT_Q15(rs2, rs1, rd, KHMBB)  <->
  0b0000110 @ rs2 @ rs1 @ 0b001 @ rd @ 0b1110111
mapping clause encdec = PEXT_Q15(rs2, rs1, rd, KHMBT)  <->
  0b0001110 @ rs2 @ rs1 @ 0b001 @ rd @ 0b1110111
mapping clause encdec = PEXT_Q15(rs2, rs1, rd, KHMTT)  <->
  0b0010110 @ rs2 @ rs1 @ 0b001 @ rd @ 0b1110111
mapping clause encdec = PEXT_Q15(rs2, rs1, rd, UKADDH) <->
  0b0001010 @ rs2 @ rs1 @ 0b001 @ rd @ 0b1110111
mapping clause encdec = PEXT_Q15(rs2, rs1, rd, UKSUBH) <->
  0b0001011 @ rs2 @ rs1 @ 0b001 @ rd @ 0b1110111

function clause execute (PEXT_Q15(rs2, rs1, rd, op)) = {
  let rs1_val = X(rs1);
  let rs2_val = X(rs2);
  result : xlenbits = zeros();
  tmp : bits(33) = zeros();
  result = match op {
      KADDH  => {
        tmp = add_bits(EXTS(slice(rs1_val,0,32)), EXTS(slice(rs2_val,0,32)));
        EXTS(q15(tmp)) 
      }, 
      KSUBH  => { 
        tmp = sub_bits(EXTS(slice(rs1_val,0,32)), EXTS(slice(rs2_val,0,32)));
        EXTS(q15(tmp))
      }, 
      KHMBB  => EXTS(signed_saturating_mul_16(slice(rs1_val,0,16), slice(rs2_val,0,16))),
      KHMBT  => EXTS(signed_saturating_mul_16(slice(rs1_val,0,16), slice(rs2_val,16,16))),
      KHMTT  => EXTS(signed_saturating_mul_16(slice(rs1_val,16,16), slice(rs2_val,16,16))),
      UKADDH => { 
        tmp = add_bits(EXTZ(slice(rs1_val,0,32)), EXTZ(slice(rs2_val,0,32))); 
        EXTS(q15_l_u(tmp))
        }, 
      UKSUBH => { 
        tmp = sub_bits(EXTZ(slice(rs1_val,0,32)), EXTZ(slice(rs2_val,0,32))) ;
        EXTS(q15_s_u(tmp))
      }
  };
  X(rd) = result;
  RETIRE_SUCCESS
}

mapping p_q15_mapping : p_inst_q15 <-> string = {
    KADDH  <-> "KADDH ",
    KSUBH  <-> "KSUBH ",
    KHMBB  <-> "KHMBB ",
    KHMBT  <-> "KHMBT ",
    KHMTT  <-> "KHMTT ",
    UKADDH <-> "UKADDH ",
    UKSUBH <-> "UKSUBH "
}

mapping clause assembly = PEXT_Q15(rs2, rs1, rd, p_inst)
  <-> p_q15_mapping(p_inst) ^ spc() ^ reg_name(rd) ^ sep() ^ reg_name(rs1) ^ sep() ^ reg_name(rs2)

/* PEXT_Q31 AST */
union clause ast = PEXT_Q31 : (regidx, regidx, regidx, p_inst_q31)

mapping clause encdec = PEXT_Q31(rs2, rs1, rd, KADDW) <->
  0b0000000 @ rs2 @ rs1 @ 0b001 @ rd @ 0b1110111
mapping clause encdec = PEXT_Q31(rs2, rs1, rd, UKADDW) <->
  0b0001000 @ rs2 @ rs1 @ 0b001 @ rd @ 0b1110111
mapping clause encdec = PEXT_Q31(rs2, rs1, rd, KSUBW) <->
  0b0000001 @ rs2 @ rs1 @ 0b001 @ rd @ 0b1110111
mapping clause encdec = PEXT_Q31(rs2, rs1, rd, UKSUBW) <->
  0b0001001 @ rs2 @ rs1 @ 0b001 @ rd @ 0b1110111
mapping clause encdec = PEXT_Q31(rs2, rs1, rd, KDMBB) <->
  0b0000101 @ rs2 @ rs1 @ 0b001 @ rd @ 0b1110111
mapping clause encdec = PEXT_Q31(rs2, rs1, rd, KDMBT) <->
  0b0001101 @ rs2 @ rs1 @ 0b001 @ rd @ 0b1110111
mapping clause encdec = PEXT_Q31(rs2, rs1, rd, KDMTT) <->
  0b0010101 @ rs2 @ rs1 @ 0b001 @ rd @ 0b1110111
mapping clause encdec = PEXT_Q31(rs2, rs1, rd, KSLRAW) <->
  0b0110111 @ rs2 @ rs1 @ 0b001 @ rd @ 0b1110111
mapping clause encdec = PEXT_Q31(rs2, rs1, rd, KSLRAW_U) <->
  0b0111111 @ rs2 @ rs1 @ 0b001 @ rd @ 0b1110111
mapping clause encdec = PEXT_Q31(rs2, rs1, rd, KSLLW) <->
  0b0010011 @ rs2 @ rs1 @ 0b001 @ rd @ 0b1110111
mapping clause encdec = PEXT_Q31(rs2, rs1, rd, KDMABB) <->
  0b1101001 @ rs2 @ rs1 @ 0b001 @ rd @ 0b1110111
mapping clause encdec = PEXT_Q31(rs2, rs1, rd, KDMABT) <->
  0b1110001 @ rs2 @ rs1 @ 0b001 @ rd @ 0b1110111
mapping clause encdec = PEXT_Q31(rs2, rs1, rd, KDMATT) <->
  0b1111001 @ rs2 @ rs1 @ 0b001 @ rd @ 0b1110111

function clause execute (PEXT_Q31(rs2, rs1, rd, op)) = {
  let rs1_val = X(rs1);
  let rs2_val = X(rs2);
  let rd_val  = X(rd);
  result : bits(32) = zeros();
  result = match op {
      KADDW    => kadd(slice(rs1_val,0,32), slice(rs2_val,0,32)),
      UKADDW   => ukadd(slice(rs1_val,0,32), slice(rs2_val,0,32)),
      KSUBW    => ksub(slice(rs1_val,0,32), slice(rs2_val,0,32)),
      UKSUBW   => uksub(slice(rs1_val,0,32), slice(rs2_val,0,32)),
      KDMBB    => kdm(slice(rs1_val, 0, 16), slice(rs2_val, 0, 16)),
      KDMBT    => kdm(slice(rs1_val, 0, 16), slice(rs2_val, 16, 16)),
      KDMTT    => kdm(slice(rs1_val, 16, 16), slice(rs2_val, 16, 16)),
      KSLRAW   => {
        let sa : bits(8) = EXTS(X(rs2)[5..0]);
        kslra (slice(rs1_val, 0, 32), sa)
      },
      KSLRAW_U => {
        let sa : bits(8) = EXTS(X(rs2)[5..0]);
        kslra_u (slice(rs1_val, 0, 32), sa)
      },
      KSLLW    => { 
        let sa : bits(8) = EXTZ(X(rs2)[4..0]); 
        kshift_left_logic (slice(rs1_val, 0, 32), sa)
      },
      KDMABB   => kdmaw(slice(rs1_val, 0, 16), slice(rs2_val, 0, 16), slice(rd_val, 0, 32)),
      KDMABT   => kdmaw(slice(rs1_val, 0, 16), slice(rs2_val, 16, 16), slice(rd_val, 0, 32)),
      KDMATT   => kdmaw(slice(rs1_val, 16, 16), slice(rs2_val, 16, 16), slice(rd_val, 0, 32))
  };
  if sizeof(xlen) == 32
  then {
      X(rd) = result;
      RETIRE_SUCCESS
  }
  else {
      X(rd) = EXTS(result);
      RETIRE_SUCCESS
  }
}

mapping p_q31_mapping : p_inst_q31 <-> string = {
    KADDW    <-> "KADDW ",
    UKADDW   <-> "UKADDW",
    KSUBW    <-> "KSUBW ",
    UKSUBW   <-> "UKSUBW ",
    KDMBB    <-> "KDMBB ",
    KDMBT    <-> "KDMBT ",
    KDMTT    <-> "KDMTT ",
    KSLRAW   <-> "KSLRAW ",
    KSLRAW_U <-> "KSLRAW_U ",
    KSLLW    <-> "KSLLW ",
    KDMABB   <-> "KDMABB ",
    KDMABT   <-> "KDMABT ",
    KDMATT   <-> "KDMATT "
}

mapping clause assembly = PEXT_Q31(rs2, rs1, rd, p_inst)
  <-> p_q31_mapping(p_inst) ^ spc() ^ reg_name(rd) ^ sep() ^ reg_name(rs1) ^ sep() ^ reg_name(rs2)

/* PEXT_32_COMPUTE AST */
union clause ast = PEXT_32_COMPUTE : (regidx, regidx, regidx, p_inst_32_compute)

mapping clause encdec = PEXT_32_COMPUTE(rs2, rs1, rd, RADDW) <->
  0b0010000 @ rs2 @ rs1 @ 0b001 @ rd @ 0b1110111
mapping clause encdec = PEXT_32_COMPUTE(rs2, rs1, rd, URADDW) <->
  0b0011000 @ rs2 @ rs1 @ 0b001 @ rd @ 0b1110111
mapping clause encdec = PEXT_32_COMPUTE(rs2, rs1, rd, RSUBW) <->
  0b0010001 @ rs2 @ rs1 @ 0b001 @ rd @ 0b1110111
mapping clause encdec = PEXT_32_COMPUTE(rs2, rs1, rd, URSUBW) <->
  0b0011001 @ rs2 @ rs1 @ 0b001 @ rd @ 0b1110111
mapping clause encdec = PEXT_32_COMPUTE(rs2, rs1, rd, MAXW) <->
  0b1111001 @ rs2 @ rs1 @ 0b000 @ rd @ 0b1110111
mapping clause encdec = PEXT_32_COMPUTE(rs2, rs1, rd, MINW) <->
  0b1111000 @ rs2 @ rs1 @ 0b000 @ rd @ 0b1110111

function clause execute (PEXT_32_COMPUTE(rs2, rs1, rd, op)) = {
  let rs1_val = X(rs1);
  let rs2_val = X(rs2);
  let rs1_word  = slice(rs1_val, 0, 32);
  let rs2_word  = slice(rs2_val, 0, 32);
  result : bits(32) = zeros();
  result = match op {
    MAXW    => smax(rs1_word, rs2_word),
    MINW    => smin(rs1_word, rs2_word),
    RADDW   => { 
      let res : bits(33) = add_bits(EXTS(rs1_word), EXTS(rs2_word)); 
      slice (res, 1, 32) 
    },
    RSUBW   => { 
      let res : bits(33) = sub_bits(EXTS(rs1_word), EXTS(rs2_word));
      slice (res, 1, 32)
    },
    URADDW  => { let res : bits(33) = add_bits(EXTZ(rs1_word), EXTZ(rs2_word));
    slice (res, 1, 32) 
    },
    URRSUBW => {
      let res : bits(33) = sub_bits(EXTZ(rs1_word), EXTZ(rs2_word));
      slice (res, 1, 32)
    }
  };  
  if sizeof(xlen) == 32 then X(rd) = result else X(rd) = EXTS(result);
  RETIRE_SUCCESS
}

mapping p_32_compute_mapping : p_inst_32_compute <-> string = {
    RADDW  <-> "RADDW",
    URADDW <-> "URADDW",
    RSUBW  <-> "RSUBW",
    URSUBW <-> "URSUBW",
    MAXW   <-> "MAXW",
    MINW   <-> "MINW"
}

mapping clause assembly = PEXT_32_COMPUTE(rs2, rs1, rd, p_inst)
  <-> p_32_compute_mapping(p_inst) ^ spc() ^ reg_name(rd) ^ sep() ^ reg_name(rs1) ^ sep() ^ reg_name(rs2)

/* PEXT_32_PAIR_RD_COMPUTE */
union clause ast = PEXT_32_PAIR_RD_COMPUTE : (regidx, regidx, regidx, p_inst_32_pair_rd_compute)

mapping clause encdec = PEXT_32_PAIR_RD_COMPUTE(rs2, rs1, rd, MULR64) <->
  0b1111000 @ rs2 @ rs1 @ 0b001 @ rd @ 0b1110111
mapping clause encdec = PEXT_32_PAIR_RD_COMPUTE(rs2, rs1, rd, MULSR64) <->
  0b1110000 @ rs2 @ rs1 @ 0b001 @ rd @ 0b1110111

function clause execute (PEXT_32_PAIR_RD_COMPUTE(rs2, rs1, rd, op)) = {
  let rs1_val = X(rs1);
  let rs2_val = X(rs2);
  let rs1_word = slice(rs1_val, 0, 32);
  let rs2_word = slice(rs2_val, 0, 32);
  result : bits(64) = zeros();
  result = match op {
      MULR64  => umul(rs1_word, rs2_word),
      MULSR64 => smul(rs1_word, rs2_word)
    };

  if sizeof(xlen) == 32
  then {
    let rd0 = (rd >> 1) << 1;
    let rd1 = rd0 + 1;
    X(rd0) = result[31..0]; 
    X(rd1) = result[63..32];
  }
  else X(rd) = result;
  RETIRE_SUCCESS
}

mapping p_32_pair_compute_mapping : p_inst_32_pair_rd_compute <-> string = {
    MULR64  <-> "MULR64 ",
    MULSR64 <-> "MULSR64 "
}

mapping clause assembly = PEXT_32_PAIR_RD_COMPUTE(rs2, rs1, rd, p_inst)
  <-> p_32_pair_compute_mapping(p_inst) ^ spc() ^ reg_name(rd) ^ sep() ^ reg_name(rs1) ^ sep() ^ reg_name(rs2)

/* PEXT_NONSIMD_MISC */
union clause ast = PEXT_NONSIMD_MISC : (regidx, regidx, regidx, p_inst_nonsimd_misc)

mapping clause encdec = PEXT_NONSIMD_MISC(rs2, rs1, rd, AVE) <->
  0b1110000 @ rs2 @ rs1 @ 0b000 @ rd @ 0b1110111
mapping clause encdec = PEXT_NONSIMD_MISC(rs2, rs1, rd, SRA_U) <->
  0b0010010 @ rs2 @ rs1 @ 0b001 @ rd @ 0b1110111
mapping clause encdec = PEXT_NONSIMD_MISC(rs2, rs1, rd, BITREV) <->
  0b1110011 @ rs2 @ rs1 @ 0b000 @ rd @ 0b1110111
mapping clause encdec = PEXT_NONSIMD_MISC(rs2, rs1, rd, MADDR32) <->
  0b1100010 @ rs2 @ rs1 @ 0b001 @ rd @ 0b1110111
mapping clause encdec = PEXT_NONSIMD_MISC(rs2, rs1, rd, MSUBR32) <->
  0b1100011 @ rs2 @ rs1 @ 0b001 @ rd @ 0b1110111

/* bit reverse auxiliary functions */
val bitrev32 :
  (bits(32)) -> bits(32)
function bitrev32 (v) = {
  var tmp : bits(64) = 0x0000 @ v @ 0x0000;
  tmp = 0x0000 @ ((tmp[48..17] & 0x55555555) | (tmp[46..15] & 0xAAAAAAAA)) @ 0x0000;
  tmp = 0x0000 @ ((tmp[49..18] & 0x33333333) | (tmp[45..14] & 0xCCCCCCCC)) @ 0x0000;
  tmp = 0x0000 @ ((tmp[51..20] & 0x0F0F0F0F) | (tmp[43..12] & 0xF0F0F0F0)) @ 0x0000;
  tmp = 0x0000 @ ((tmp[55..24] & 0x00FF00FF) | (tmp[39..8]  & 0xFF00FF00)) @ 0x0000;
  ((tmp[63..32] & 0x0000FFFF) | (tmp[31..0]  & 0xFFFF0000))
}

val bitrev64 :
  (bits(64)) -> bits(64)
function bitrev64 (v) = {
  var tmp : bits(128) = 0x00000000 @ v @ 0x00000000;
  tmp = 0x00000000 @ ((tmp[96..33]  & 0x5555555555555555) | (tmp[94..31] & 0xAAAAAAAAAAAAAAAA)) @ 0x00000000;
  tmp = 0x00000000 @ ((tmp[97..34]  & 0x3333333333333333) | (tmp[93..30] & 0xCCCCCCCCCCCCCCCC)) @ 0x00000000;
  tmp = 0x00000000 @ ((tmp[99..36]  & 0x0F0F0F0F0F0F0F0F) | (tmp[91..28] & 0xF0F0F0F0F0F0F0F0)) @ 0x00000000;
  tmp = 0x00000000 @ ((tmp[103..40] & 0x00FF00FF00FF00FF) | (tmp[87..24] & 0xFF00FF00FF00FF00)) @ 0x00000000;
  tmp = 0x00000000 @ ((tmp[111..48] & 0x0000FFFF0000FFFF) | (tmp[79..16] & 0xFFFF0000FFFF0000)) @ 0x00000000;
  ((tmp[127..64] & 0x00000000FFFFFFFF) | (tmp[63..0]  & 0xFFFFFFFF00000000))
}

function clause execute (PEXT_NONSIMD_MISC(rs2, rs1, rd, op)) = {
  let rs1_val = X(rs1);
  let rs2_val = X(rs2);
  let rd_val = X(rd);
  let rs1_word = slice(rs1_val, 0, 32);
  let rs2_word = slice(rs2_val, 0, 32);
  let rd_word = slice(rd_val, 0, 32);
  result : xlenbits = zeros();  

  if sizeof(xlen) == 32
  then {
       result = match op {
          AVE     => { let tmp : bits(xlen + 1) = EXTS(rs1_val) + EXTS(rs2_val) + EXTS(0x1); tmp[32..1] },
          SRA_U   => { let sa : bits(8)  = EXTZ(X(rs2)[4..0]) ; shift_right_arith_u (rs1_val, sa)},
          BITREV  => { let msb : bits(8) = EXTZ(rs2_val[4..0]) ; shift_right_logic(bitrev32(rs1_val), 0x1F - msb)},
          MADDR32 =>  X(rd) + smul(rs1_word, rs2_word)[31..0],
          MSUBR32 =>  X(rd) - smul(rs1_word, rs2_word)[31..0]
        };
    }
   else {
       result = match op {
          AVE     => { let tmp : bits(xlen + 1) = EXTS(rs1_val) + EXTS(rs2_val) + EXTS(0x1); tmp[64..1] },
          SRA_U   => { let sa  : bits(8)  = EXTZ(X(rs2)[5..0]) ; shift_right_arith_u (rs1_val, sa)},
          BITREV  => { let msb : bits(8) = EXTZ(rs2_val[5..0]) ; shift_right_logic(bitrev64(rs1_val), 0x3F - msb)},
          MADDR32 =>  EXTS(rd_word + smul(rs1_word, rs2_word)[31..0]),
          MSUBR32 =>  EXTS(rd_word - smul(rs1_word, rs2_word)[31..0])
       }
   };
   X(rd) = result;
   RETIRE_SUCCESS    
}

mapping p_nonsimd_misc_mapping : p_inst_nonsimd_misc <-> string = {
    AVE     <-> "AVE ",
    SRA_U   <-> "SRA_U ",
    BITREV  <-> "BITREV ",
    MADDR32 <-> "MADDR32 ",
    MSUBR32 <-> "MSUBR32 "
}

mapping clause assembly = PEXT_NONSIMD_MISC(rs2, rs1, rd, p_inst)
  <-> p_nonsimd_misc_mapping(p_inst) ^ spc() ^ reg_name(rd) ^ sep() ^ reg_name(rs1) ^ sep() ^ reg_name(rs2)

/* PEXT_IMM6 AST */
union clause ast = PEXT_IMM6 : (bits(6), regidx, regidx, p_inst_imm6)

mapping clause encdec = PEXT_IMM6(imm6, rs1, rd, BITREVI) <->
  0b111010 @ imm6 @ rs1 @ 0b000 @ rd @ 0b1110111
mapping clause encdec = PEXT_IMM6(imm6, rs1, rd, SRAI_U) <->
  0b110101 @ imm6 @ rs1 @ 0b001 @ rd @ 0b1110111

function clause execute (PEXT_IMM6(imm6, rs1, rd, op)) = {
  let rs1_val = X(rs1);
  let msb : bits(8) = EXTZ(imm6);
  X(rd) = 
  if sizeof(xlen) == 32
  then match op {
    BITREVI => shift_right_logic(bitrev32(rs1_val), 0x1F - msb),
    SRAI_U  => shift_right_arith_u(rs1_val, EXTZ(imm6[4..0]))
  }
  else match op {
    BITREVI => shift_right_logic(bitrev64(rs1_val), 0x3F - msb),
    SRAI_U  => shift_right_arith_u(rs1_val, EXTZ(imm6))
  };
  RETIRE_SUCCESS
}

mapping p_imm6_mapping : p_inst_imm6 <-> string = {
  BITREVI <-> "BITREVI",
  SRAI_U  <-> "SRAI_U"
}

mapping clause assembly = PEXT_IMM6(imm6, rs1, rd, p_inst)
  <-> p_imm6_mapping(p_inst) ^ spc() ^ reg_name(rd) ^ sep() ^ reg_name(rs1) ^ sep() ^ hex_bits_6(imm6)  

/* PEXT_WEXT AST */
union clause ast = PEXT_WEXT : (regidx, regidx, regidx)

mapping clause encdec = PEXT_WEXT(rs2, rs1, rd) <->
  0b1100111 @ rs2 @ rs1 @ 0b000 @ rd @ 0b1110111

function clause execute(PEXT_WEXT(rs2, rs1, rd)) = {
  X(rd) = 
  if sizeof(xlen) == 32
  then  shift_right_logic( X(rs1 | 0b00001) @ X(rs1 & 0b11110), EXTZ(X(rs2)[4..0]))[31..0]
  else  shift_right_logic( X(rs1), EXTZ(X(rs2)[4..0]));
  RETIRE_SUCCESS
}

mapping clause assembly = PEXT_WEXT(rs2, rs1, rd)
  <-> "WEXT" ^ spc() ^ reg_name(rd) ^ sep() ^ reg_name(rs1) ^ sep() ^ reg_name(rs2)

/* PEXT_WEXTI AST */
union clause ast = PEXT_WEXTI : (bits(5), regidx, regidx)

mapping clause encdec = PEXT_WEXTI(imm5, rs1, rd) <->
  0b1101111 @ imm5 @ rs1 @ 0b000 @ rd @ 0b1110111

function clause execute(PEXT_WEXTI(imm5, rs1, rd)) = {
  X(rd) = 
  if sizeof(xlen) == 32
  then  shift_right_logic( X(rs1 | 0b00001) @ X(rs1 & 0b11110), EXTZ(imm5))[31..0]
  else  shift_right_logic( X(rs1), EXTZ(imm5));
  RETIRE_SUCCESS
}

mapping clause assembly = PEXT_WEXTI(imm5, rs1, rd)
  <-> "WEXTI" ^ spc() ^ reg_name(rd) ^ sep() ^ reg_name(rs1) ^ sep() ^ hex_bits_5(imm5)

/* PEXT_KSLLIW AST */
union clause ast = PEXT_KSLLIW : (bits(5), regidx, regidx)

mapping clause encdec = PEXT_KSLLIW(imm5, rs1, rd) <->
  0b0011011 @ imm5 @ rs1 @ 0b001 @ rd @ 0b1110111

function clause execute (PEXT_KSLLIW(imm5, rs1, rd)) = {
  let sa : bits(8) = EXTZ(imm5);
  let rs1_word = slice(X(rs1), 0, 32);
  if sizeof(xlen) == 32
  then X(rd) = kshift_left_logic(rs1_word, sa)
  else X(rd) = EXTS(kshift_left_logic(rs1_word, sa));
  RETIRE_SUCCESS
}

mapping clause assembly = PEXT_KSLLIW(imm5, rs1, rd)
  <-> "KSLLIW" ^ spc() ^ reg_name(rd) ^ sep() ^ reg_name(rs1) ^ sep() ^ hex_bits_5(imm5)

/* PEXT_KABSW AST */
union clause ast = PEXT_KABSW : (regidx, regidx)

mapping clause encdec = PEXT_KABSW(rs1, rd) <->
  0b1010110 @ 0b10100 @ rs1 @ 0b000 @ rd @ 0b1110111

function clause execute (PEXT_KABSW(rs1, rd)) = {
  let rs1_word = slice(X(rs1), 0, 32);
  if sizeof(xlen) == 32
  then X(rd) = kabs(rs1_word)
  else X(rd) = EXTS(kabs(rs1_word));
  RETIRE_SUCCESS
}

mapping clause assembly = PEXT_KABSW(rs1, rd)
  <-> "KABSW" ^ spc() ^ reg_name(rd) ^ sep() ^ reg_name(rs1)

/* PEXT_INSB AST */
union clause ast = PEXT_INSB : (bits(3), regidx, regidx)

mapping clause encdec = PEXT_INSB(imm3, rs1, rd) <->
  0b1010110 @ 0b00 @ imm3 @ rs1 @ 0b000 @ rd @ 0b1110111

function clause execute (PEXT_INSB(imm3, rs1, rd)) = {
  let bpos : bits(8) = EXTZ(imm3) ;
  let rs1_val : xlenbits = X(rs1);
  let rd_val : xlenbits = X(rd);
  result : xlenbits = zeros();
  let insbyte : bits(64) = (0x00000000000000 @ slice(rs1_val, 0 ,8) ) << (bpos << 3) ;
  let mask : bits(64) = not_vec((0x00000000000000FF) << (bpos << 3)) ;

  if sizeof(xlen) == 32
  then {
    result = (( (0x00000000 @ rd_val) & mask) + insbyte )[31..0]  ;
  } else {
    result = (( rd_val  & mask) + insbyte );
  };
   X(rd) = result;
   RETIRE_SUCCESS
}

mapping clause assembly = PEXT_INSB(imm3, rs1, rd)
  <-> "INSB" ^ spc() ^ reg_name(rd) ^ sep() ^ reg_name(rs1) ^ sep() ^ hex_bits_3(imm3)

/* PEXT_BPICK AST */
union clause ast = PEXT_BPICK : (regidx, regidx, regidx, regidx)

mapping clause encdec = PEXT_BPICK(rs3, rs2, rs1, rd) <->
  rs3 @ 0b00 @ rs2 @ rs1 @ 0b011 @ rd @ 0b1110111

function clause execute (PEXT_BPICK(rs3, rs2, rs1, rd)) = {
  if sizeof(xlen) == 32
  then {
    X(rd) = slice( X(rs1) ,0 ,32) & slice( X(rs3) ,0 ,32)  | slice( X(rs2) ,0 ,32) & not_vec(slice( X(rs3) ,0 ,32));
  } else {
    X(rd) = slice(X(rs1) ,0 ,64) & slice( X(rs3) ,0 ,64) | slice( X(rs2) ,0 ,64) & not_vec(slice( X(rs3) ,0 ,64));
  };
  RETIRE_SUCCESS;
}

mapping clause assembly = PEXT_BPICK(rs3, rs2, rs1, rd)
  <-> "BPICK" ^ spc() ^ reg_name(rd) ^ sep() ^ reg_name(rs1) ^ sep() ^ reg_name(rs2) ^ sep() ^ reg_name(rs3)
