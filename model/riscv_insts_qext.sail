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

/* **************************************************************** */
/* This file specifies the instructions in the F extension          */
/* (single precision floating point).                               */

/* RISC-V follows IEEE 754-2008 floating point arithmetic standard. */

/* Original version written by Rishiyur S. Nikhil, Sept-Oct 2019    */

/* **************************************************************** */
/* IMPORTANT!                                                       */
/* The files 'riscv_insts_fext.sail', 'riscv_insts_dext.sail' and   */
/* 'riscv_insts_zfh.sail' define the F, D and Zfh extensions,       */
/* respectively.                                                    */
/* The texts follow each other very closely; please try to maintain */
/* this correspondence as the files are maintained for bug-fixes,   */
/* improvements, and version updates.                               */

/* **************************************************************** */

/* **************************************************************** */
/* S and D value structure (sign, exponent, mantissa)               */

/* TODO: this should be a 'mapping' */
val      fsplit_Q : bits(128) -> (bits(1), bits(15), bits(112))
function fsplit_Q   x128 = (x128[127..127], x128[126..112], x128[111..0])

val      fmake_Q  : (bits(1), bits(15), bits(112)) -> bits(128)
function fmake_Q (sign, exp, mant) = sign @ exp @ mant

/* ---- Structure tests */

val      f_is_neg_inf_Q : bits(128) -> bool
function f_is_neg_inf_Q   x128 = {
  let (sign, exp, mant) = fsplit_Q (x128);
  (  (sign == 0b1)
   & (exp  == ones())
   & (mant == zeros()))
}

val      f_is_neg_norm_Q : bits(128) -> bool
function f_is_neg_norm_Q   x128 = {
  let (sign, exp, mant) = fsplit_Q (x128);
  (  (sign == 0b1)
   & (exp  != zeros())
   & (exp  != ones()))
}

val      f_is_neg_subnorm_Q : bits(128) -> bool
function f_is_neg_subnorm_Q   x128 = {
  let (sign, exp, mant) = fsplit_Q (x128);
  (  (sign == 0b1)
   & (exp  == zeros())
   & (mant != zeros()))
}

val      f_is_neg_zero_Q : bits(128) -> bool
function f_is_neg_zero_Q   x128 = {
  let (sign, exp, mant) = fsplit_Q (x128);
  (  (sign == ones())
   & (exp  == zeros())
   & (mant == zeros()))
}

val      f_is_pos_zero_Q : bits(128) -> bool
function f_is_pos_zero_Q   x128 = {
  let (sign, exp, mant) = fsplit_Q (x128);
  (  (sign == zeros())
   & (exp  == zeros())
   & (mant == zeros()))
}

val      f_is_pos_subnorm_Q : bits(128) -> bool
function f_is_pos_subnorm_Q   x128 = {
  let (sign, exp, mant) = fsplit_Q (x128);
  (  (sign == zeros())
   & (exp  == zeros())
   & (mant != zeros()))
}

val      f_is_pos_norm_Q : bits(128) -> bool
function f_is_pos_norm_Q   x128 = {
  let (sign, exp, mant) = fsplit_Q (x128);
  (  (sign == zeros())
   & (exp  != zeros())
   & (exp  != ones()))
}

val      f_is_pos_inf_Q : bits(128) -> bool
function f_is_pos_inf_Q   x128 = {
  let (sign, exp, mant) = fsplit_Q (x128);
  (  (sign == zeros())
   & (exp  == ones())
   & (mant == zeros()))
}

val      f_is_SNaN_Q : bits(128) -> bool
function f_is_SNaN_Q   x128 = {
  let (sign, exp, mant) = fsplit_Q (x128);
  (  (exp == ones())
   & (mant [51] == bitzero)
   & (mant != zeros()))
}

val      f_is_QNaN_Q : bits(128) -> bool
function f_is_QNaN_Q   x128 = {
  let (sign, exp, mant) = fsplit_Q (x128);
  (  (exp == ones())
   & (mant [51] == bitone))
}

/* Either QNaN or SNan */
val      f_is_NaN_Q : bits(128) -> bool
function f_is_NaN_Q   x128 = {
  let (sign, exp, mant) = fsplit_Q (x128);
  (  (exp == ones())
   & (mant != zeros()))
}


/* **************************************************************** */
/* Help functions used in the semantic functions                    */

val      negate_Q : bits(128) -> bits(128)
function negate_Q (x128) = {
  let (sign, exp, mant) = fsplit_Q (x128);
  let new_sign = if (sign == 0b0) then 0b1 else 0b0;
  fmake_Q (new_sign, exp, mant)
}

/* not sure about the bits repr, thus extract here TODO : check the repr */
let Q_word_width_repr = 0b100

/* AST <-> Binary encoding ================================ */
union clause ast = F_MADD_TYPE_Q : (regidx, regidx, regidx, rounding_mode, regidx, f_madd_op_Q)

mapping clause encdec = 
    F_MADD_TYPE_Q(rs3, rs2, rs1, rm, rd, FMADD_Q)                        if haveQExt()
<-> rs3 @ 0b11 @ rs2 @ rs1 @ encdec_rounding_mode (rm) @ rd @ 0b100_0011 if haveQExt()

mapping clause encdec = 
    F_MADD_TYPE_Q(rs3, rs2, rs1, rm, rd, FMSUB_Q)                        if haveQExt()
<-> rs3 @ 0b11 @ rs2 @ rs1 @ encdec_rounding_mode (rm) @ rd @ 0b100_0111 if haveQExt()

mapping clause encdec = 
    F_MADD_TYPE_Q(rs3, rs2, rs1, rm, rd, FNMSUB_Q)                       if haveQExt()
<-> rs3 @ 0b11 @ rs2 @ rs1 @ encdec_rounding_mode (rm) @ rd @ 0b100_1011 if haveQExt()

mapping clause encdec = 
    F_MADD_TYPE_Q(rs3, rs2, rs1, rm, rd, FNMADD_Q)                       if haveQExt()
<-> rs3 @ 0b11 @ rs2 @ rs1 @ encdec_rounding_mode (rm) @ rd @ 0b100_1111 if haveQExt()


function clause execute (F_MADD_TYPE_Q(rs3, rs2, rs1, rm, rd, op)) = {
  let rs1_val_128b = F(rs1);
  let rs2_val_128b = F(rs2);
  let rs3_val_128b = F(rs3);

  match (select_instr_or_fcsr_rm (rm)) {
    None() => { handle_illegal(); RETIRE_FAIL },
    Some(rm') => {
      let rm_3b = encdec_rounding_mode(rm');
      let (fflags, rd_val_128b) : (bits(5), bits(128)) =
        match op {
          FMADD_Q  => riscv_f128MulAdd (rm_3b, rs1_val_128b, rs2_val_128b, rs3_val_128b),
          FMSUB_Q  => riscv_f128MulAdd (rm_3b, rs1_val_128b, rs2_val_128b, negate_Q (rs3_val_128b)),
          FNMSUB_Q => riscv_f128MulAdd (rm_3b, negate_Q (rs1_val_128b), rs2_val_128b, rs3_val_128b),
          FNMADD_Q => riscv_f128MulAdd (rm_3b, negate_Q (rs1_val_128b), rs2_val_128b, negate_Q (rs3_val_128b))
        };
      write_fflags(fflags);
      F(rd) = rd_val_128b;
      RETIRE_SUCCESS
    }
  }
}

mapping f_madd_type_mnemonic_Q : f_madd_op_Q <-> string = {
    FMADD_Q  <-> "fmadd.q",
    FMSUB_Q  <-> "fmsub.q",
    FNMSUB_Q  <-> "fnmsub.q",
    FNMADD_Q  <-> "fnmadd.q"
}

mapping clause assembly = F_MADD_TYPE_Q(rs3, rs2, rs1, rm, rd, op)
                      <-> f_madd_type_mnemonic_Q(op)
                          ^ spc() ^ freg_or_reg_name(rd)
                          ^ sep() ^ freg_or_reg_name(rs1)
                          ^ sep() ^ freg_or_reg_name(rs2)
                          ^ sep() ^ freg_or_reg_name(rs3)
                          ^ sep() ^ frm_mnemonic(rm)



union clause ast = F_BIN_RM_TYPE_Q : (regidx, regidx, rounding_mode, regidx, f_bin_rm_op_Q)

/* AST <-> Binary encoding ================================ */

mapping clause encdec =
    F_BIN_RM_TYPE_Q(rs2, rs1, rm, rd, FADD_Q)                             if haveQExt()
<-> 0b000_0011 @ rs2 @ rs1 @ encdec_rounding_mode (rm) @ rd @ 0b101_0011  if haveQExt()

mapping clause encdec =
    F_BIN_RM_TYPE_Q(rs2, rs1, rm, rd, FSUB_Q)                             if haveQExt()
<-> 0b000_0111 @ rs2 @ rs1 @ encdec_rounding_mode (rm) @ rd @ 0b101_0011  if haveQExt()

mapping clause encdec =
    F_BIN_RM_TYPE_Q(rs2, rs1, rm, rd, FMUL_Q)                             if haveQExt()
<-> 0b000_1011 @ rs2 @ rs1 @ encdec_rounding_mode (rm) @ rd @ 0b101_0011  if haveQExt()

mapping clause encdec =
    F_BIN_RM_TYPE_Q(rs2, rs1, rm, rd, FDIV_Q)                             if haveQExt()
<-> 0b000_1111 @ rs2 @ rs1 @ encdec_rounding_mode (rm) @ rd @ 0b101_0011  if haveQExt()

/* Execution semantics ================================ */

function clause execute (F_BIN_RM_TYPE_Q(rs2, rs1, rm, rd, op)) = {
  let rs1_val_128b = F(rs1);
  let rs2_val_128b = F(rs2);
  match (select_instr_or_fcsr_rm (rm)) {
    None() => { handle_illegal(); RETIRE_FAIL },
    Some(rm') => {
      let rm_3b = encdec_rounding_mode(rm');
      let (fflags, rd_val_128b) : (bits(5), bits(128)) = match op {
        FADD_Q  => riscv_f128Add (rm_3b, rs1_val_128b, rs2_val_128b),
        FSUB_Q  => riscv_f128Sub (rm_3b, rs1_val_128b, rs2_val_128b),
        FMUL_Q  => riscv_f128Mul (rm_3b, rs1_val_128b, rs2_val_128b),
        FDIV_Q  => riscv_f128Div (rm_3b, rs1_val_128b, rs2_val_128b)
      };
      write_fflags(fflags);
      F(rd) = rd_val_128b;
      RETIRE_SUCCESS
    }
  }
}

/* AST -> Assembly notation ================================ */

mapping f_bin_rm_type_mnemonic_Q : f_bin_rm_op_Q <-> string = {
  FADD_Q  <-> "fadd.q",
  FSUB_Q  <-> "fsub.q",
  FMUL_Q  <-> "fmul.q",
  FDIV_Q  <-> "fdiv.q"
}

mapping clause assembly = F_BIN_RM_TYPE_Q(rs2, rs1, rm, rd, op)
                      <-> f_bin_rm_type_mnemonic_Q(op)
                          ^ spc() ^ freg_or_reg_name(rd)
                          ^ sep() ^ freg_or_reg_name(rs1)
                          ^ sep() ^ freg_or_reg_name(rs2)
                          ^ sep() ^ frm_mnemonic(rm)


/* ****************************************************************** */
/* Unary with rounding mode */

/* AST */

union clause ast = F_UN_RM_TYPE_Q : (regidx, rounding_mode, regidx, f_un_rm_op_Q)

/* AST <-> Binary encoding ================================ */

mapping clause encdec =
    F_UN_RM_TYPE_Q(rs1, rm, rd, FSQRT_Q)                                      if haveQExt()
<-> 0b010_1111 @ 0b00000 @ rs1 @ encdec_rounding_mode (rm) @ rd @ 0b101_0011  if haveQExt()

mapping clause encdec =
    F_UN_RM_TYPE_Q(rs1, rm, rd, FCVT_W_Q)                                     if haveQExt()
<-> 0b110_0011 @ 0b00000 @ rs1 @ encdec_rounding_mode (rm) @ rd @ 0b101_0011  if haveQExt()

mapping clause encdec =
    F_UN_RM_TYPE_Q(rs1, rm, rd, FCVT_WU_Q)                                    if haveQExt()
<-> 0b110_0011 @ 0b00001 @ rs1 @ encdec_rounding_mode (rm) @ rd @ 0b101_0011  if haveQExt()

mapping clause encdec =
    F_UN_RM_TYPE_Q(rs1, rm, rd, FCVT_Q_W)                                     if haveQExt()
<-> 0b110_1011 @ 0b00000 @ rs1 @ encdec_rounding_mode (rm) @ rd @ 0b101_0011  if haveQExt()

mapping clause encdec =
    F_UN_RM_TYPE_Q(rs1, rm, rd, FCVT_Q_WU)                                    if haveQExt()
<-> 0b110_1011 @ 0b00001 @ rs1 @ encdec_rounding_mode (rm) @ rd @ 0b101_0011  if haveQExt()

mapping clause encdec =
    F_UN_RM_TYPE_Q(rs1, rm, rd, FCVT_S_Q)                                     if haveQExt()
<-> 0b010_0000 @ 0b00011 @ rs1 @ encdec_rounding_mode (rm) @ rd @ 0b101_0011  if haveQExt()

mapping clause encdec =
    F_UN_RM_TYPE_Q(rs1, rm, rd, FCVT_Q_S)                                     if haveQExt()
<-> 0b010_0011 @ 0b00000 @ rs1 @ encdec_rounding_mode (rm) @ rd @ 0b101_0011  if haveQExt()

mapping clause encdec =
    F_UN_RM_TYPE_Q(rs1, rm, rd, FCVT_D_Q)                                     if haveQExt()
<-> 0b010_0001 @ 0b00011 @ rs1 @ encdec_rounding_mode (rm) @ rd @ 0b101_0011  if haveQExt()

mapping clause encdec =
    F_UN_RM_TYPE_Q(rs1, rm, rd, FCVT_Q_D)                                     if haveQExt()
<-> 0b010_0011 @ 0b00001 @ rs1 @ encdec_rounding_mode (rm) @ rd @ 0b101_0011  if haveQExt()

/* Q instructions, RV64 only */

mapping clause encdec =
    F_UN_RM_TYPE_Q(rs1, rm, rd, FCVT_L_Q)                                     if haveQExt()
<-> 0b110_0011 @ 0b00010 @ rs1 @ encdec_rounding_mode (rm) @ rd @ 0b101_0011  if haveQExt()

mapping clause encdec =
    F_UN_RM_TYPE_Q(rs1, rm, rd, FCVT_LU_Q)                                    if haveQExt()
<-> 0b110_0011 @ 0b00011 @ rs1 @ encdec_rounding_mode (rm) @ rd @ 0b101_0011  if haveQExt()

mapping clause encdec =
    F_UN_RM_TYPE_Q(rs1, rm, rd, FCVT_Q_L)                                     if haveQExt()
<-> 0b110_1011 @ 0b00010 @ rs1 @ encdec_rounding_mode (rm) @ rd @ 0b101_0011  if haveQExt()

mapping clause encdec =
    F_UN_RM_TYPE_Q(rs1, rm, rd, FCVT_Q_LU)                                    if haveQExt()
<-> 0b110_1011 @ 0b00011 @ rs1 @ encdec_rounding_mode (rm) @ rd @ 0b101_0011  if haveQExt()

/* Execution semantics ================================ */

function clause execute (F_UN_RM_TYPE_Q(rs1, rm, rd, FSQRT_Q)) = {
  let rs1_val_Q = F(rs1);
  match (select_instr_or_fcsr_rm (rm)) {
    None() => { handle_illegal(); RETIRE_FAIL },
    Some(rm') => {
      let rm_3b = encdec_rounding_mode(rm');
      let (fflags, rd_val_Q) = riscv_f128Sqrt   (rm_3b, rs1_val_Q);

      write_fflags(fflags);
      F(rd) = rd_val_Q;
      RETIRE_SUCCESS
    }
  }
}

function clause execute (F_UN_RM_TYPE_Q(rs1, rm, rd, FCVT_W_Q)) = {
  let rs1_val_Q = F(rs1);
  match (select_instr_or_fcsr_rm (rm)) {
    None() => { handle_illegal(); RETIRE_FAIL },
    Some(rm') => {
      let rm_3b = encdec_rounding_mode(rm');
      let (fflags, rd_val_W) = riscv_f128ToI32 (rm_3b, rs1_val_Q);

      write_fflags(fflags);
      X(rd) = EXTS (rd_val_W);
      RETIRE_SUCCESS
    }
  }
}

function clause execute (F_UN_RM_TYPE_Q(rs1, rm, rd, FCVT_WU_Q)) = {
  let rs1_val_Q = F(rs1);
  match (select_instr_or_fcsr_rm (rm)) {
    None() => { handle_illegal(); RETIRE_FAIL },
    Some(rm') => {
      let rm_3b = encdec_rounding_mode(rm');
      let (fflags, rd_val_WU) = riscv_f128ToUi32 (rm_3b, rs1_val_Q);

      write_fflags(fflags);
      X(rd) = EXTS (rd_val_WU);
      RETIRE_SUCCESS
    }
  }
}

function clause execute (F_UN_RM_TYPE_Q(rs1, rm, rd, FCVT_Q_W)) = {
  let rs1_val_W = X(rs1) [31..0];
  match (select_instr_or_fcsr_rm (rm)) {
    None() => { handle_illegal(); RETIRE_FAIL },
    Some(rm') => {
      let rm_3b = encdec_rounding_mode(rm');
      let (fflags, rd_val_Q) = riscv_i32ToF128 (rm_3b, rs1_val_W);

      write_fflags(fflags);
      F(rd) = rd_val_Q;
      RETIRE_SUCCESS
    }
  }
}

function clause execute (F_UN_RM_TYPE_Q(rs1, rm, rd, FCVT_Q_WU)) = {
  let rs1_val_WU = X(rs1) [31..0];
  match (select_instr_or_fcsr_rm (rm)) {
    None() => { handle_illegal(); RETIRE_FAIL },
    Some(rm') => {
      let rm_3b = encdec_rounding_mode(rm');
      let (fflags, rd_val_Q) = riscv_ui32ToF128 (rm_3b, rs1_val_WU);

      write_fflags(fflags);
      F(rd) = rd_val_Q;
      RETIRE_SUCCESS
    }
  }
}

function clause execute (F_UN_RM_TYPE_Q(rs1, rm, rd, FCVT_S_Q)) = {
  let rs1_val_Q = F(rs1);
  match (select_instr_or_fcsr_rm (rm)) {
    None() => { handle_illegal(); RETIRE_FAIL },
    Some(rm') => {
      let rm_3b = encdec_rounding_mode(rm');
      let (fflags, rd_val_S) = riscv_f128ToF32 (rm_3b, rs1_val_Q);

      write_fflags(fflags);
      F(rd) = rd_val_S;
      RETIRE_SUCCESS
    }
  }
}

function clause execute (F_UN_RM_TYPE_Q(rs1, rm, rd, FCVT_Q_S)) = {
  let rs1_val_S = F(rs1);
  match (select_instr_or_fcsr_rm (rm)) {
    None() => { handle_illegal(); RETIRE_FAIL },
    Some(rm') => {
      let rm_3b = encdec_rounding_mode(rm');
      let (fflags, rd_val_Q) = riscv_f32ToF128 (rm_3b, rs1_val_S);

      write_fflags(fflags);
      F(rd) = rd_val_Q;
      RETIRE_SUCCESS
    }
  }
}

function clause execute (F_UN_RM_TYPE_Q(rs1, rm, rd, FCVT_D_Q)) = {
  let rs1_val_Q = F(rs1);
  match (select_instr_or_fcsr_rm (rm)) {
    None() => { handle_illegal(); RETIRE_FAIL },
    Some(rm') => {
      let rm_3b = encdec_rounding_mode(rm');
      let (fflags, rd_val_D) = riscv_f128ToF64 (rm_3b, rs1_val_Q);

      write_fflags(fflags);
      F(rd) = rd_val_D;
      RETIRE_SUCCESS
    }
  }
}

function clause execute (F_UN_RM_TYPE_Q(rs1, rm, rd, FCVT_Q_D)) = {
  let rs1_val_D = F(rs1);
  match (select_instr_or_fcsr_rm (rm)) {
    None() => { handle_illegal(); RETIRE_FAIL },
    Some(rm') => {
      let rm_3b = encdec_rounding_mode(rm');
      let (fflags, rd_val_Q) = riscv_f64ToF128 (rm_3b, rs1_val_D);

      write_fflags(fflags);
      F(rd) = rd_val_Q;
      RETIRE_SUCCESS
    }
  }
}

function clause execute (F_UN_RM_TYPE_Q(rs1, rm, rd, FCVT_L_Q)) = {
  assert(sizeof(xlen) >= 64);
  let rs1_val_Q = F(rs1);
  match (select_instr_or_fcsr_rm (rm)) {
    None() => { handle_illegal(); RETIRE_FAIL },
    Some(rm') => {
      let rm_3b = encdec_rounding_mode(rm');
      let (fflags, rd_val_L) = riscv_f128ToI64 (rm_3b, rs1_val_Q);

      write_fflags(fflags);
      X(rd) = EXTS(rd_val_L);
      RETIRE_SUCCESS
    }
  }
}

function clause execute (F_UN_RM_TYPE_Q(rs1, rm, rd, FCVT_LU_Q)) = {
  assert(sizeof(xlen) >= 64);
  let rs1_val_Q = F(rs1);
  match (select_instr_or_fcsr_rm (rm)) {
    None() => { handle_illegal(); RETIRE_FAIL },
    Some(rm') => {
      let rm_3b = encdec_rounding_mode(rm');
      let (fflags, rd_val_LU) = riscv_f128ToUi64 (rm_3b, rs1_val_Q);

      write_fflags(fflags);
      X(rd) = EXTS(rd_val_LU);
      RETIRE_SUCCESS
    }
  }
}

function clause execute (F_UN_RM_TYPE_Q(rs1, rm, rd, FCVT_Q_L)) = {
  assert(sizeof(xlen) >= 64);
  let rs1_val_L = X(rs1)[63..0];
  match (select_instr_or_fcsr_rm (rm)) {
    None() => { handle_illegal(); RETIRE_FAIL },
    Some(rm') => {
      let rm_3b = encdec_rounding_mode(rm');
      let (fflags, rd_val_Q) = riscv_i64ToF128 (rm_3b, rs1_val_L);

      write_fflags(fflags);
      F(rd) = rd_val_Q;
      RETIRE_SUCCESS
    }
  }
}

function clause execute (F_UN_RM_TYPE_Q(rs1, rm, rd, FCVT_Q_LU)) = {
  assert(sizeof(xlen) >= 64);
  let rs1_val_LU = X(rs1)[63..0];
  match (select_instr_or_fcsr_rm (rm)) {
    None() => { handle_illegal(); RETIRE_FAIL },
    Some(rm') => {
      let rm_3b = encdec_rounding_mode(rm');
      let (fflags, rd_val_Q) = riscv_ui64ToF128 (rm_3b, rs1_val_LU);

      write_fflags(fflags);
      F(rd) = rd_val_Q;
      RETIRE_SUCCESS
    }
  }
}

/* AST -> Assembly notation ================================ */

mapping f_un_rm_type_mnemonic_Q : f_un_rm_op_Q <-> string = {
    FSQRT_Q   <-> "fsqrt.q",
    FCVT_W_Q  <-> "fcvt.w.q",
    FCVT_WU_Q <-> "fcvt.wu.q",
    FCVT_Q_W  <-> "fcvt.q.w",
    FCVT_Q_WU <-> "fcvt.q.wu",

    FCVT_L_Q  <-> "fcvt.l.q",
    FCVT_LU_Q <-> "fcvt.lu.q",
    FCVT_Q_L  <-> "fcvt.q.l",
    FCVT_Q_LU <-> "fcvt.q.lu",

    FCVT_S_Q  <-> "fcvt.s.q",
    FCVT_Q_S  <-> "fcvt.q.s",
    FCVT_D_Q  <-> "fcvt.d.q",
    FCVT_Q_D  <-> "fcvt.q.d"
}

mapping clause assembly = F_UN_RM_TYPE_Q(rs1, rm, rd, FSQRT_Q)
                      <-> f_un_rm_type_mnemonic_Q(FSQRT_Q)
                          ^ spc() ^ freg_or_reg_name(rd)
                          ^ sep() ^ freg_or_reg_name(rs1)
                          ^ sep() ^ frm_mnemonic(rm)

mapping clause assembly = F_UN_RM_TYPE_Q(rs1, rm, rd, FCVT_W_Q)
                      <-> f_un_rm_type_mnemonic_Q(FCVT_W_Q)
                          ^ spc() ^ reg_name(rd)
                          ^ sep() ^ freg_or_reg_name(rs1)
                          ^ sep() ^ frm_mnemonic(rm)

mapping clause assembly = F_UN_RM_TYPE_Q(rs1, rm, rd, FCVT_WU_Q)
                      <-> f_un_rm_type_mnemonic_Q(FCVT_WU_Q)
                          ^ spc() ^ reg_name(rd)
                          ^ sep() ^ freg_or_reg_name(rs1)
                          ^ sep() ^ frm_mnemonic(rm)

mapping clause assembly = F_UN_RM_TYPE_Q(rs1, rm, rd, FCVT_Q_W)
                      <-> f_un_rm_type_mnemonic_Q(FCVT_Q_W)
                          ^ spc() ^ freg_or_reg_name(rd)
                          ^ sep() ^ reg_name(rs1)
                          ^ sep() ^ frm_mnemonic(rm)

mapping clause assembly = F_UN_RM_TYPE_Q(rs1, rm, rd, FCVT_Q_WU)
                      <-> f_un_rm_type_mnemonic_Q(FCVT_Q_WU)
                          ^ spc() ^ freg_or_reg_name(rd)
                          ^ sep() ^ reg_name(rs1)
                          ^ sep() ^ frm_mnemonic(rm)

mapping clause assembly = F_UN_RM_TYPE_Q(rs1, rm, rd, FCVT_L_Q)
                      <-> f_un_rm_type_mnemonic_Q(FCVT_L_Q)
                          ^ spc() ^ reg_name(rd)
                          ^ sep() ^ freg_or_reg_name(rs1)
                          ^ sep() ^ frm_mnemonic(rm)

mapping clause assembly = F_UN_RM_TYPE_Q(rs1, rm, rd, FCVT_LU_Q)
                      <-> f_un_rm_type_mnemonic_Q(FCVT_LU_Q)
                          ^ spc() ^ reg_name(rd)
                          ^ sep() ^ freg_or_reg_name(rs1)
                          ^ sep() ^ frm_mnemonic(rm)

mapping clause assembly = F_UN_RM_TYPE_Q(rs1, rm, rd, FCVT_Q_L)
                      <-> f_un_rm_type_mnemonic_Q(FCVT_Q_L)
                          ^ spc() ^ freg_or_reg_name(rd)
                          ^ sep() ^ reg_name(rs1)
                          ^ sep() ^ frm_mnemonic(rm)

mapping clause assembly = F_UN_RM_TYPE_Q(rs1, rm, rd, FCVT_Q_LU)
                      <-> f_un_rm_type_mnemonic_Q(FCVT_Q_LU)
                          ^ spc() ^ freg_or_reg_name(rd)
                          ^ sep() ^ reg_name(rs1)
                          ^ sep() ^ frm_mnemonic(rm)

mapping clause assembly = F_UN_RM_TYPE_Q(rs1, rm, rd, FCVT_S_Q)
                      <-> f_un_rm_type_mnemonic_Q(FCVT_S_Q)
                          ^ spc() ^ freg_or_reg_name(rd)
                          ^ sep() ^ freg_or_reg_name(rs1)
                          ^ sep() ^ frm_mnemonic(rm)

mapping clause assembly = F_UN_RM_TYPE_Q(rs1, rm, rd, FCVT_Q_S)
                      <-> f_un_rm_type_mnemonic_Q(FCVT_Q_S)
                          ^ spc() ^ freg_or_reg_name(rd)
                          ^ sep() ^ freg_or_reg_name(rs1)
                          ^ sep() ^ frm_mnemonic(rm)


mapping clause assembly = F_UN_RM_TYPE_Q(rs1, rm, rd, FCVT_D_Q)
                      <-> f_un_rm_type_mnemonic_Q(FCVT_D_Q)
                          ^ spc() ^ freg_or_reg_name(rd)
                          ^ sep() ^ freg_or_reg_name(rs1)
                          ^ sep() ^ frm_mnemonic(rm)

mapping clause assembly = F_UN_RM_TYPE_Q(rs1, rm, rd, FCVT_Q_D)
                      <-> f_un_rm_type_mnemonic_Q(FCVT_Q_D)
                          ^ spc() ^ freg_or_reg_name(rd)
                          ^ sep() ^ freg_or_reg_name(rs1)
                          ^ sep() ^ frm_mnemonic(rm)

/* ****************************************************************** */
/* Binary, no rounding mode */

/* AST */

union clause ast = F_BIN_TYPE_Q : (regidx, regidx, regidx, f_bin_op_Q)

/* AST <-> Binary encoding ================ */
 
mapping clause encdec = F_BIN_TYPE_Q(rs2, rs1, rd, FSGNJ_Q)               if haveQExt()
                    <-> 0b001_0011 @ rs2 @ rs1 @ 0b000 @ rd @ 0b101_0011  if haveQExt()

mapping clause encdec = F_BIN_TYPE_Q(rs2, rs1, rd, FSGNJN_Q)              if haveQExt()
                    <-> 0b001_0011 @ rs2 @ rs1 @ 0b001 @ rd @ 0b101_0011  if haveQExt()

mapping clause encdec = F_BIN_TYPE_Q(rs2, rs1, rd, FSGNJX_Q)              if haveQExt()
                    <-> 0b001_0011 @ rs2 @ rs1 @ 0b010 @ rd @ 0b101_0011  if haveQExt()


mapping clause encdec = F_BIN_TYPE_D(rs2, rs1, rd, FEQ_D)                 if haveQExt()
                    <-> 0b101_0011 @ rs2 @ rs1 @ 0b010 @ rd @ 0b101_0011  if haveQExt()

mapping clause encdec = F_BIN_TYPE_D(rs2, rs1, rd, FLT_D)                 if haveQExt()
                    <-> 0b101_0011 @ rs2 @ rs1 @ 0b001 @ rd @ 0b101_0011  if haveQExt()

mapping clause encdec = F_BIN_TYPE_D(rs2, rs1, rd, FLE_D)                 if haveQExt()
                    <-> 0b101_0011 @ rs2 @ rs1 @ 0b000 @ rd @ 0b101_0011  if haveQExt()

function clause execute (F_BIN_TYPE_Q(rs2, rs1, rd, FSGNJ_Q)) = {
  let rs1_val_Q    = F(rs1);
  let rs2_val_Q    = F(rs2);

  let (s1, e1, m1) = fsplit_Q (rs1_val_Q);
  let (s2, e2, m2) = fsplit_Q (rs2_val_Q);
  let rd_val_Q     = fmake_Q (s2, e1, m1);

  F(rd) = rd_val_Q;
  RETIRE_SUCCESS
}

function clause execute (F_BIN_TYPE_Q(rs2, rs1, rd, FSGNJN_Q)) = {
  let rs1_val_Q    = F(rs1);
  let rs2_val_Q    = F(rs2);
  let (s1, e1, m1) = fsplit_Q (rs1_val_Q);
  let (s2, e2, m2) = fsplit_Q (rs2_val_Q);
  let rd_val_Q     = fmake_Q (0b1 ^ s2, e1, m1);

  F(rd) = rd_val_Q;
  RETIRE_SUCCESS
}

function clause execute (F_BIN_TYPE_Q(rs2, rs1, rd, FSGNJX_Q)) = {
  let rs1_val_Q    = F(rs1);
  let rs2_val_Q    = F(rs2);
  let (s1, e1, m1) = fsplit_Q (rs1_val_Q);
  let (s2, e2, m2) = fsplit_Q (rs2_val_Q);
  let rd_val_Q     = fmake_Q (s1 ^ s2, e1, m1);

  F(rd) = rd_val_Q;
  RETIRE_SUCCESS
}

function clause execute (F_BIN_TYPE_Q(rs2, rs1, rd, FEQ_Q)) = {
  let rs1_val_Q = F(rs1);
  let rs2_val_Q = F(rs2);

  let (fflags, rd_val) : (bits_fflags, bool) =
      riscv_f128Eq (rs1_val_Q, rs2_val_Q);

  write_fflags(fflags);
  X(rd) = EXTZ(bool_to_bits(rd_val));
  RETIRE_SUCCESS
}

function clause execute (F_BIN_TYPE_Q(rs2, rs1, rd, FLT_Q)) = {
  let rs1_val_Q = F(rs1);
  let rs2_val_Q = F(rs2);

  let (fflags, rd_val) : (bits_fflags, bool) =
      riscv_f128Lt (rs1_val_Q, rs2_val_Q);

  write_fflags(fflags);
  X(rd) = EXTZ(bool_to_bits(rd_val));
  RETIRE_SUCCESS
}

function clause execute (F_BIN_TYPE_Q(rs2, rs1, rd, FLE_Q)) = {
  let rs1_val_Q = F(rs1);
  let rs2_val_Q = F(rs2);

  let (fflags, rd_val) : (bits_fflags, bool) =
      riscv_f128Le (rs1_val_Q, rs2_val_Q);

  write_fflags(fflags);
  X(rd) = EXTZ(bool_to_bits(rd_val));
  RETIRE_SUCCESS
}

mapping f_bin_type_mnemonic_Q : f_bin_op_Q <-> string = {
    FSGNJ_Q  <-> "fsgnj.q",
    FSGNJN_Q <-> "fsgnjn.q",
    FSGNJX_Q <-> "fsgnjx.q",
    FMIN_Q   <-> "fmin.q",
    FMAX_Q   <-> "fmax.q",
    FEQ_Q    <-> "feq.q",
    FLT_Q    <-> "flt.q",
    FLE_Q    <-> "fle.q"
}

mapping clause assembly = F_BIN_TYPE_Q(rs2, rs1, rd, FSGNJ_Q)
                      <-> f_bin_type_mnemonic_Q(FSGNJ_Q)
                          ^ spc() ^ freg_or_reg_name(rd)
                          ^ sep() ^ freg_or_reg_name(rs1)
                          ^ sep() ^ freg_or_reg_name(rs2)

mapping clause assembly = F_BIN_TYPE_Q(rs2, rs1, rd, FSGNJN_Q)
                      <-> f_bin_type_mnemonic_Q(FSGNJN_Q)
                          ^ spc() ^ freg_or_reg_name(rd)
                          ^ sep() ^ freg_or_reg_name(rs1)
                          ^ sep() ^ freg_or_reg_name(rs2)

mapping clause assembly = F_BIN_TYPE_Q(rs2, rs1, rd, FSGNJX_Q)
                      <-> f_bin_type_mnemonic_Q(FSGNJX_Q)
                          ^ spc() ^ freg_or_reg_name(rd)
                          ^ sep() ^ freg_or_reg_name(rs1)
                          ^ sep() ^ freg_or_reg_name(rs2)


mapping clause assembly = F_BIN_TYPE_Q(rs2, rs1, rd, FEQ_Q)
                      <-> f_bin_type_mnemonic_Q(FEQ_Q)
                          ^ spc() ^ reg_name(rd)
                          ^ sep() ^ freg_or_reg_name(rs1)
                          ^ sep() ^ freg_or_reg_name(rs2)

mapping clause assembly = F_BIN_TYPE_Q(rs2, rs1, rd, FLT_Q)
                      <-> f_bin_type_mnemonic_Q(FLT_Q)
                          ^ spc() ^ reg_name(rd)
                          ^ sep() ^ freg_or_reg_name(rs1)
                          ^ sep() ^ freg_or_reg_name(rs2)

mapping clause assembly = F_BIN_TYPE_Q(rs2, rs1, rd, FLE_Q)
                      <-> f_bin_type_mnemonic_Q(FLE_Q)
                          ^ spc() ^ reg_name(rd)
                          ^ sep() ^ freg_or_reg_name(rs1)
                          ^ sep() ^ freg_or_reg_name(rs2)
