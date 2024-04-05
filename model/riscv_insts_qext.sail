/*=======================================================================================*/
/*  This Sail RISC-V architecture model, comprising all files and                        */
/*  directories except where otherwise noted is subject the BSD                          */
/*  two-clause license in the LICENSE file.                                              */
/*                                                                                       */
/*  SPDX-License-Identifier: BSD-2-Clause                                                */
/*=======================================================================================*/

/* **************************************************************** */
/* This file specifies the instructions in the Q extension          */
/* (quad precision floating point).                                 */

/* RISC-V follows IEEE 754-2008 floating point arithmetic standard. */

/* Original version written by Rishiyur S. Nikhil, Sept-Oct 2019    */

/* **************************************************************** */
/* IMPORTANT!                                                       */
/* The files 'riscv_insts_fext.sail', 'riscv_insts_dext.sail',      */
/* 'riscv_insts_qext.sail' and 'riscv_insts_zfh.sail' define the    */
/* F, D, Q and Zfh extensions, respectively.                        */
/* The texts follow each other very closely; please try to maintain */
/* this correspondence as the files are maintained for bug-fixes,   */
/* improvements, and version updates.                               */

/* **************************************************************** */
/* Note: Rounding Modes and Floating point accrued exception flags  */
/* are defined in riscv_insts_fext.sail.                            */
/* In RISC-V, the Q extension requires the F extension, so that     */
/* should have been processed before this one.                      */

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

val      feq_quiet_Q : (bits(128), bits (128)) -> (bool, bits(5))
function feq_quiet_Q   (v1,       v2) = {
  let (s1, e1, m1) = fsplit_Q (v1);
  let (s2, e2, m2) = fsplit_Q (v2);

  let v1Is0    = f_is_neg_zero_Q(v1) | f_is_pos_zero_Q(v1);
  let v2Is0    = f_is_neg_zero_Q(v2) | f_is_pos_zero_Q(v2);

  let result = ((v1 == v2) | (v1Is0 & v2Is0));

  let fflags = if   (f_is_SNaN_Q(v1) | f_is_SNaN_Q(v2))
               then nvFlag()
               else zeros();

  (result, fflags)
}

val      flt_Q : (bits(128), bits (128), bool) -> (bool, bits(5))
function flt_Q   (v1,       v2,        is_quiet) = {
  let (s1, e1, m1) = fsplit_Q (v1);
  let (s2, e2, m2) = fsplit_Q (v2);

  let result : bool =
    if (s1 == 0b0) & (s2 == 0b0) then
      if   (e1 == e2)
      then unsigned (m1) < unsigned (m2)
      else unsigned (e1) < unsigned (e2)
    else if (s1 == 0b0) & (s2 == 0b1) then
      false
    else if (s1 == 0b1) & (s2 == 0b0) then
      true
    else
      if   (e1 == e2)
      then unsigned (m1) > unsigned (m2)
      else unsigned (e1) > unsigned (e2);

  let fflags = if is_quiet then
                 if   (f_is_SNaN_Q(v1) | f_is_SNaN_Q(v2))
                 then nvFlag()
                 else zeros()
               else
                 if   (f_is_NaN_Q(v1) | f_is_NaN_Q(v2))
                 then nvFlag()
                 else zeros();

  (result, fflags)
}

val      fle_Q : (bits(128), bits (128), bool) -> (bool, bits(5))
function fle_Q   (v1,       v2,        is_quiet) = {
  let (s1, e1, m1) = fsplit_Q (v1);
  let (s2, e2, m2) = fsplit_Q (v2);

  let v1Is0    = f_is_neg_zero_Q(v1) | f_is_pos_zero_Q(v1);
  let v2Is0    = f_is_neg_zero_Q(v2) | f_is_pos_zero_Q(v2);

  let result : bool =
    if (s1 == 0b0) & (s2 == 0b0) then
      if   (e1 == e2)
      then unsigned (m1) <=  unsigned (m2)
      else unsigned (e1)  <  unsigned (e2)
    else if (s1 == 0b0) & (s2 == 0b1) then
      (v1Is0 & v2Is0)                         /* Equal in this case (+0=-0) */
    else if (s1 == 0b1) & (s2 == 0b0) then
      true
    else
      if   (e1 == e2)
      then unsigned (m1) >=  unsigned (m2)
      else unsigned (e1)  >  unsigned (e2);

  let fflags = if is_quiet then
                 if   (f_is_SNaN_Q(v1) | f_is_SNaN_Q(v2))
                 then nvFlag()
                 else zeros()
               else
                 if   (f_is_NaN_Q(v1) | f_is_NaN_Q(v2))
                 then nvFlag()
                 else zeros();

  (result, fflags)
}

/* ****************************************************************** */
/* Floating-point loads                                               */
/* These are defined in: riscv_insts_fext.sail                        */

/* ****************************************************************** */
/* Floating-point stores                                              */
/* These are defined in: riscv_insts_fext.sail                        */

/* ****************************************************************** */
/* Fused multiply-add */

/* AST */

union clause ast = F_MADD_TYPE_Q : (fregidx, fregidx, fregidx, rounding_mode, fregidx, f_madd_op_Q)

/* AST <-> Binary encoding ================================ */

mapping clause encdec = F_MADD_TYPE_Q(rs3, rs2, rs1, rm, rd, FMADD_Q)
  <-> encdec_freg(rs3) @ 0b11 @ encdec_freg(rs2) @ encdec_freg(rs1) @ encdec_rounding_mode (rm) @ encdec_freg(rd) @ 0b100_0011
  when currentlyEnabled(Ext_Q)

mapping clause encdec = F_MADD_TYPE_Q(rs3, rs2, rs1, rm, rd, FMSUB_Q)
  <-> encdec_freg(rs3) @ 0b11 @ encdec_freg(rs2) @ encdec_freg(rs1) @ encdec_rounding_mode (rm) @ encdec_freg(rd) @ 0b100_0111
  when currentlyEnabled(Ext_Q)

mapping clause encdec = F_MADD_TYPE_Q(rs3, rs2, rs1, rm, rd, FNMSUB_Q)
  <-> encdec_freg(rs3) @ 0b11 @ encdec_freg(rs2) @ encdec_freg(rs1) @ encdec_rounding_mode (rm) @ encdec_freg(rd) @ 0b100_1011
  when currentlyEnabled(Ext_Q)

mapping clause encdec = F_MADD_TYPE_Q(rs3, rs2, rs1, rm, rd, FNMADD_Q)
  <-> encdec_freg(rs3) @ 0b11 @ encdec_freg(rs2) @ encdec_freg(rs1) @ encdec_rounding_mode (rm) @ encdec_freg(rd) @ 0b100_1111
  when currentlyEnabled(Ext_Q)

/* Execution semantics ================================ */

function clause execute (F_MADD_TYPE_Q(rs3, rs2, rs1, rm, rd, op)) = {
  let rs1_val_128b = F_Q(rs1);
  let rs2_val_128b = F_Q(rs2);
  let rs3_val_128b = F_Q(rs3);

  match (select_instr_or_fcsr_rm (rm)) {
    None()    => RETIRE_FAIL(Illegal_Instruction()),
    Some(rm') => {
      let rm_3b = encdec_rounding_mode(rm');
      let (fflags, rd_val_128b) : (bits(5), bits(128)) =
        match op {
          FMADD_Q  => riscv_f128MulAdd (rm_3b, rs1_val_128b, rs2_val_128b, rs3_val_128b),
          FMSUB_Q  => riscv_f128MulAdd (rm_3b, rs1_val_128b, rs2_val_128b, negate_Q (rs3_val_128b)),
          FNMSUB_Q => riscv_f128MulAdd (rm_3b, negate_Q (rs1_val_128b), rs2_val_128b, rs3_val_128b),
          FNMADD_Q => riscv_f128MulAdd (rm_3b, negate_Q (rs1_val_128b), rs2_val_128b, negate_Q (rs3_val_128b))
        };
      accrue_fflags(fflags);
      F_Q(rd) = rd_val_128b;
      RETIRE_SUCCESS
    }
  }
}

/* AST -> Assembly notation ================================ */

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

/* ****************************************************************** */
/* Binary ops with rounding mode */

/* AST */

union clause ast = F_BIN_RM_TYPE_Q : (fregidx, fregidx, rounding_mode, fregidx, f_bin_rm_op_Q)

/* AST <-> Binary encoding ================================ */

mapping clause encdec = F_BIN_RM_TYPE_Q(rs2, rs1, rm, rd, FADD_Q)
  <-> 0b000_0011 @ encdec_freg(rs2) @ encdec_freg(rs1) @ encdec_rounding_mode (rm) @ encdec_freg(rd) @ 0b101_0011
  when currentlyEnabled(Ext_Q)

mapping clause encdec = F_BIN_RM_TYPE_Q(rs2, rs1, rm, rd, FSUB_Q)
  <-> 0b000_0111 @ encdec_freg(rs2) @ encdec_freg(rs1) @ encdec_rounding_mode (rm) @ encdec_freg(rd) @ 0b101_0011
  when currentlyEnabled(Ext_Q)

mapping clause encdec = F_BIN_RM_TYPE_Q(rs2, rs1, rm, rd, FMUL_Q)
  <-> 0b000_1011 @ encdec_freg(rs2) @ encdec_freg(rs1) @ encdec_rounding_mode (rm) @ encdec_freg(rd) @ 0b101_0011
  when currentlyEnabled(Ext_Q)

mapping clause encdec = F_BIN_RM_TYPE_Q(rs2, rs1, rm, rd, FDIV_Q)
  <-> 0b000_1111 @ encdec_freg(rs2) @ encdec_freg(rs1) @ encdec_rounding_mode (rm) @ encdec_freg(rd) @ 0b101_0011
  when currentlyEnabled(Ext_Q)

/* Execution semantics ================================ */

function clause execute (F_BIN_RM_TYPE_Q(rs2, rs1, rm, rd, op)) = {
  let rs1_val_128b = F_Q(rs1);
  let rs2_val_128b = F_Q(rs2);
  match (select_instr_or_fcsr_rm (rm)) {
    None()    => RETIRE_FAIL(Illegal_Instruction()),
    Some(rm') => {
      let rm_3b = encdec_rounding_mode(rm');
      let (fflags, rd_val_128b) : (bits(5), bits(128)) = match op {
        FADD_Q  => riscv_f128Add (rm_3b, rs1_val_128b, rs2_val_128b),
        FSUB_Q  => riscv_f128Sub (rm_3b, rs1_val_128b, rs2_val_128b),
        FMUL_Q  => riscv_f128Mul (rm_3b, rs1_val_128b, rs2_val_128b),
        FDIV_Q  => riscv_f128Div (rm_3b, rs1_val_128b, rs2_val_128b)
      };
      accrue_fflags(fflags);
      F_Q(rd) = rd_val_128b;
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

union clause ast = F_UN_RM_FF_TYPE_Q : (fregidx, rounding_mode, fregidx, f_un_rm_ff_op_Q)
union clause ast = F_UN_RM_XF_TYPE_Q : (regidx, rounding_mode, fregidx, f_un_rm_xf_op_Q)
union clause ast = F_UN_RM_FX_TYPE_Q : (fregidx, rounding_mode, regidx, f_un_rm_fx_op_Q)

/* AST <-> Binary encoding ================================ */

mapping clause encdec = F_UN_RM_FF_TYPE_Q(rs1, rm, rd, FSQRT_Q)
  <-> 0b010_1111 @ 0b00000 @ encdec_freg(rs1) @ encdec_rounding_mode (rm) @ encdec_freg(rd) @ 0b101_0011
  when currentlyEnabled(Ext_Q)

mapping clause encdec = F_UN_RM_FX_TYPE_Q(rs1, rm, rd, FCVT_W_Q)
  <-> 0b110_0011 @ 0b00000 @ encdec_freg(rs1) @ encdec_rounding_mode (rm) @ encdec_reg(rd) @ 0b101_0011
  when currentlyEnabled(Ext_Q)

mapping clause encdec = F_UN_RM_FX_TYPE_Q(rs1, rm, rd, FCVT_WU_Q)
  <-> 0b110_0011 @ 0b00001 @ encdec_freg(rs1) @ encdec_rounding_mode (rm) @ encdec_reg(rd) @ 0b101_0011
  when currentlyEnabled(Ext_Q)

mapping clause encdec = F_UN_RM_XF_TYPE_Q(rs1, rm, rd, FCVT_Q_W)
  <-> 0b110_1011 @ 0b00000 @ encdec_reg(rs1) @ encdec_rounding_mode (rm) @ encdec_freg(rd) @ 0b101_0011
  when currentlyEnabled(Ext_Q)

mapping clause encdec = F_UN_RM_XF_TYPE_Q(rs1, rm, rd, FCVT_Q_WU)
  <-> 0b110_1011 @ 0b00001 @ encdec_reg(rs1) @ encdec_rounding_mode (rm) @ encdec_freg(rd) @ 0b101_0011
  when currentlyEnabled(Ext_Q)

mapping clause encdec = F_UN_RM_FF_TYPE_Q(rs1, rm, rd, FCVT_S_Q)
  <-> 0b010_0000 @ 0b00011 @ encdec_freg(rs1) @ encdec_rounding_mode (rm) @ encdec_freg(rd) @ 0b101_0011
  when currentlyEnabled(Ext_Q)

mapping clause encdec = F_UN_RM_FF_TYPE_Q(rs1, rm, rd, FCVT_Q_S)
  <-> 0b010_0011 @ 0b00000 @ encdec_freg(rs1) @ encdec_rounding_mode (rm) @ encdec_freg(rd) @ 0b101_0011
  when currentlyEnabled(Ext_Q)

mapping clause encdec = F_UN_RM_FF_TYPE_Q(rs1, rm, rd, FCVT_D_Q)
  <-> 0b010_0001 @ 0b00011 @ encdec_freg(rs1) @ encdec_rounding_mode (rm) @ encdec_freg(rd) @ 0b101_0011
  when currentlyEnabled(Ext_Q)

mapping clause encdec = F_UN_RM_FF_TYPE_Q(rs1, rm, rd, FCVT_Q_D)
  <-> 0b010_0011 @ 0b00001 @ encdec_freg(rs1) @ encdec_rounding_mode (rm) @ encdec_freg(rd) @ 0b101_0011
  when currentlyEnabled(Ext_Q)

/* Q instructions, RV64 only */

mapping clause encdec = F_UN_RM_FX_TYPE_Q(rs1, rm, rd, FCVT_L_Q)
  <-> 0b110_0011 @ 0b00010 @ encdec_freg(rs1) @ encdec_rounding_mode (rm) @ encdec_reg(rd) @ 0b101_0011
  when currentlyEnabled(Ext_Q) & xlen >= 64

mapping clause encdec = F_UN_RM_FX_TYPE_Q(rs1, rm, rd, FCVT_LU_Q)
  <-> 0b110_0011 @ 0b00011 @ encdec_freg(rs1) @ encdec_rounding_mode (rm) @ encdec_reg(rd) @ 0b101_0011
  when currentlyEnabled(Ext_Q) & xlen >= 64

mapping clause encdec = F_UN_RM_XF_TYPE_Q(rs1, rm, rd, FCVT_Q_L)
  <-> 0b110_1011 @ 0b00010 @ encdec_reg(rs1) @ encdec_rounding_mode (rm) @ encdec_freg(rd) @ 0b101_0011
  when currentlyEnabled(Ext_Q) & xlen >= 64

mapping clause encdec = F_UN_RM_XF_TYPE_Q(rs1, rm, rd, FCVT_Q_LU)
  <-> 0b110_1011 @ 0b00011 @ encdec_reg(rs1) @ encdec_rounding_mode (rm) @ encdec_freg(rd) @ 0b101_0011
  when currentlyEnabled(Ext_Q) & xlen >= 64

/* Execution semantics ================================ */

function clause execute (F_UN_RM_FF_TYPE_Q(rs1, rm, rd, FSQRT_Q)) = {
  let rs1_val_Q = F_Q(rs1);
  match (select_instr_or_fcsr_rm (rm)) {
    None()    => RETIRE_FAIL(Illegal_Instruction()),
    Some(rm') => {
      let rm_3b = encdec_rounding_mode(rm');
      let (fflags, rd_val_Q) = riscv_f128Sqrt   (rm_3b, rs1_val_Q);

      accrue_fflags(fflags);
      F_Q(rd) = rd_val_Q;
      RETIRE_SUCCESS
    }
  }
}

function clause execute (F_UN_RM_FX_TYPE_Q(rs1, rm, rd, FCVT_W_Q)) = {
  let rs1_val_Q = F_Q(rs1);
  match (select_instr_or_fcsr_rm (rm)) {
    None()    => RETIRE_FAIL(Illegal_Instruction()),
    Some(rm') => {
      let rm_3b = encdec_rounding_mode(rm');
      let (fflags, rd_val_W) = riscv_f128ToI32 (rm_3b, rs1_val_Q);

      accrue_fflags(fflags);
      X(rd) = sign_extend (rd_val_W);
      RETIRE_SUCCESS
    }
  }
}

function clause execute (F_UN_RM_FX_TYPE_Q(rs1, rm, rd, FCVT_WU_Q)) = {
  let rs1_val_Q = F_Q(rs1);
  match (select_instr_or_fcsr_rm (rm)) {
    None()    => RETIRE_FAIL(Illegal_Instruction()),
    Some(rm') => {
      let rm_3b = encdec_rounding_mode(rm');
      let (fflags, rd_val_WU) = riscv_f128ToUi32 (rm_3b, rs1_val_Q);

      accrue_fflags(fflags);
      X(rd) = sign_extend (rd_val_WU);
      RETIRE_SUCCESS
    }
  }
}

function clause execute (F_UN_RM_XF_TYPE_Q(rs1, rm, rd, FCVT_Q_W)) = {
  let rs1_val_W = X(rs1) [31..0];
  match (select_instr_or_fcsr_rm (rm)) {
    None()    => RETIRE_FAIL(Illegal_Instruction()),
    Some(rm') => {
      let rm_3b = encdec_rounding_mode(rm');
      let (fflags, rd_val_Q) = riscv_i32ToF128 (rm_3b, rs1_val_W);

      accrue_fflags(fflags);
      F_Q(rd) = rd_val_Q;
      RETIRE_SUCCESS
    }
  }
}

function clause execute (F_UN_RM_XF_TYPE_Q(rs1, rm, rd, FCVT_Q_WU)) = {
  let rs1_val_WU = X(rs1) [31..0];
  match (select_instr_or_fcsr_rm (rm)) {
    None()    => RETIRE_FAIL(Illegal_Instruction()),
    Some(rm') => {
      let rm_3b = encdec_rounding_mode(rm');
      let (fflags, rd_val_Q) = riscv_ui32ToF128 (rm_3b, rs1_val_WU);

      accrue_fflags(fflags);
      F_Q(rd) = rd_val_Q;
      RETIRE_SUCCESS
    }
  }
}

function clause execute (F_UN_RM_FF_TYPE_Q(rs1, rm, rd, FCVT_S_Q)) = {
  let rs1_val_Q = F_Q(rs1);
  match (select_instr_or_fcsr_rm (rm)) {
    None()    => RETIRE_FAIL(Illegal_Instruction()),
    Some(rm') => {
      let rm_3b = encdec_rounding_mode(rm');
      let (fflags, rd_val_S) = riscv_f128ToF32 (rm_3b, rs1_val_Q);

      accrue_fflags(fflags);
      F_S(rd) = rd_val_S;
      RETIRE_SUCCESS
    }
  }
}

function clause execute (F_UN_RM_FF_TYPE_Q(rs1, rm, rd, FCVT_Q_S)) = {
  let rs1_val_S = F_S(rs1);
  match (select_instr_or_fcsr_rm (rm)) {
    None()    => RETIRE_FAIL(Illegal_Instruction()),
    Some(rm') => {
      let rm_3b = encdec_rounding_mode(rm');
      let (fflags, rd_val_Q) = riscv_f32ToF128 (rm_3b, rs1_val_S);

      accrue_fflags(fflags);
      F_Q(rd) = rd_val_Q;
      RETIRE_SUCCESS
    }
  }
}

function clause execute (F_UN_RM_FF_TYPE_Q(rs1, rm, rd, FCVT_D_Q)) = {
  let rs1_val_Q = F_Q(rs1);
  match (select_instr_or_fcsr_rm (rm)) {
    None()    => RETIRE_FAIL(Illegal_Instruction()),
    Some(rm') => {
      let rm_3b = encdec_rounding_mode(rm');
      let (fflags, rd_val_D) = riscv_f128ToF64 (rm_3b, rs1_val_Q);

      accrue_fflags(fflags);
      F_D(rd) = rd_val_D;
      RETIRE_SUCCESS
    }
  }
}

function clause execute (F_UN_RM_FF_TYPE_Q(rs1, rm, rd, FCVT_Q_D)) = {
  let rs1_val_D = F_D(rs1);
  match (select_instr_or_fcsr_rm (rm)) {
    None()    => RETIRE_FAIL(Illegal_Instruction()),
    Some(rm') => {
      let rm_3b = encdec_rounding_mode(rm');
      let (fflags, rd_val_Q) = riscv_f64ToF128 (rm_3b, rs1_val_D);

      accrue_fflags(fflags);
      F_Q(rd) = rd_val_Q;
      RETIRE_SUCCESS
    }
  }
}

function clause execute (F_UN_RM_FX_TYPE_Q(rs1, rm, rd, FCVT_L_Q)) = {
  assert(xlen >= 64);
  let rs1_val_Q = F_Q(rs1);
  match (select_instr_or_fcsr_rm (rm)) {
    None()    => RETIRE_FAIL(Illegal_Instruction()),
    Some(rm') => {
      let rm_3b = encdec_rounding_mode(rm');
      let (fflags, rd_val_L) = riscv_f128ToI64 (rm_3b, rs1_val_Q);

      accrue_fflags(fflags);
      X(rd) = sign_extend(rd_val_L);
      RETIRE_SUCCESS
    }
  }
}

function clause execute (F_UN_RM_FX_TYPE_Q(rs1, rm, rd, FCVT_LU_Q)) = {
  assert(xlen >= 64);
  let rs1_val_Q = F_Q(rs1);
  match (select_instr_or_fcsr_rm (rm)) {
    None()    => RETIRE_FAIL(Illegal_Instruction()),
    Some(rm') => {
      let rm_3b = encdec_rounding_mode(rm');
      let (fflags, rd_val_LU) = riscv_f128ToUi64 (rm_3b, rs1_val_Q);

      accrue_fflags(fflags);
      X(rd) = sign_extend(rd_val_LU);
      RETIRE_SUCCESS
    }
  }
}

function clause execute (F_UN_RM_XF_TYPE_Q(rs1, rm, rd, FCVT_Q_L)) = {
  assert(xlen >= 64);
  let rs1_val_L = X(rs1)[63..0];
  match (select_instr_or_fcsr_rm (rm)) {
    None()    => RETIRE_FAIL(Illegal_Instruction()),
    Some(rm') => {
      let rm_3b = encdec_rounding_mode(rm');
      let (fflags, rd_val_Q) = riscv_i64ToF128 (rm_3b, rs1_val_L);

      accrue_fflags(fflags);
      F_Q(rd) = rd_val_Q;
      RETIRE_SUCCESS
    }
  }
}

function clause execute (F_UN_RM_XF_TYPE_Q(rs1, rm, rd, FCVT_Q_LU)) = {
  assert(xlen >= 64);
  let rs1_val_LU = X(rs1)[63..0];
  match (select_instr_or_fcsr_rm (rm)) {
    None()    => RETIRE_FAIL(Illegal_Instruction()),
    Some(rm') => {
      let rm_3b = encdec_rounding_mode(rm');
      let (fflags, rd_val_Q) = riscv_ui64ToF128 (rm_3b, rs1_val_LU);

      accrue_fflags(fflags);
      F_Q(rd) = rd_val_Q;
      RETIRE_SUCCESS
    }
  }
}

/* AST -> Assembly notation ================================ */

mapping f_un_rm_ff_type_mnemonic_Q : f_un_rm_ff_op_Q <-> string = {
    FSQRT_Q   <-> "fsqrt.q",
    FCVT_S_Q  <-> "fcvt.s.q",
    FCVT_Q_S  <-> "fcvt.q.s",
    FCVT_D_Q  <-> "fcvt.d.q",
    FCVT_Q_D  <-> "fcvt.q.d"
}

mapping clause assembly = F_UN_RM_FF_TYPE_Q(rs1, rm, rd, op)
                      <-> f_un_rm_ff_type_mnemonic_Q(op)
                          ^ spc() ^ freg_or_reg_name(rd)
                          ^ sep() ^ freg_or_reg_name(rs1)
                          ^ sep() ^ frm_mnemonic(rm)

mapping f_un_rm_fx_type_mnemonic_Q : f_un_rm_fx_op_Q <-> string = {
  FCVT_W_Q  <-> "fcvt.w.q",
    FCVT_WU_Q <-> "fcvt.wu.q",
    FCVT_L_Q  <-> "fcvt.l.q",
    FCVT_LU_Q <-> "fcvt.lu.q",
}

mapping clause assembly = F_UN_RM_FX_TYPE_Q(rs1, rm, rd, op)
                      <-> f_un_rm_fx_type_mnemonic_Q(op)
                          ^ spc() ^ reg_name(rd)
                          ^ sep() ^ freg_or_reg_name(rs1)
                          ^ sep() ^ frm_mnemonic(rm)

mapping f_un_rm_xf_type_mnemonic_Q : f_un_rm_xf_op_Q <-> string = {
    FCVT_Q_L  <-> "fcvt.q.l",
    FCVT_Q_LU <-> "fcvt.q.lu",
    FCVT_Q_W  <-> "fcvt.q.w",
    FCVT_Q_WU <-> "fcvt.q.wu",
}

mapping clause assembly = F_UN_RM_XF_TYPE_Q(rs1, rm, rd, op)
                      <-> f_un_rm_xf_type_mnemonic_Q(op)
                          ^ spc() ^ freg_or_reg_name(rd)
                          ^ sep() ^ reg_name(rs1)
                          ^ sep() ^ frm_mnemonic(rm)

/* ****************************************************************** */
/* Binary, no rounding mode */

/* AST */

union clause ast = F_BIN_F_TYPE_Q : (fregidx, fregidx, fregidx, f_bin_f_op_Q)
union clause ast = F_BIN_X_TYPE_Q : (fregidx, fregidx, regidx, f_bin_x_op_Q)

/* AST <-> Binary encoding ================================ */

mapping clause encdec = F_BIN_F_TYPE_Q(rs2, rs1, rd, FSGNJ_Q)
  <-> 0b001_0011 @ encdec_freg(rs2) @ encdec_freg(rs1) @ 0b000 @ encdec_freg(rd) @ 0b101_0011
  when currentlyEnabled(Ext_Q)

mapping clause encdec = F_BIN_F_TYPE_Q(rs2, rs1, rd, FSGNJN_Q)
  <-> 0b001_0011 @ encdec_freg(rs2) @ encdec_freg(rs1) @ 0b001 @ encdec_freg(rd) @ 0b101_0011
  when currentlyEnabled(Ext_Q)

mapping clause encdec = F_BIN_F_TYPE_Q(rs2, rs1, rd, FSGNJX_Q)
  <-> 0b001_0011 @ encdec_freg(rs2) @ encdec_freg(rs1) @ 0b010 @ encdec_freg(rd) @ 0b101_0011
  when currentlyEnabled(Ext_Q)

mapping clause encdec = F_BIN_F_TYPE_Q(rs2, rs1, rd, FMIN_Q)
  <-> 0b001_0111 @ encdec_freg(rs2) @ encdec_freg(rs1) @ 0b000 @ encdec_freg(rd) @ 0b101_0011
  when currentlyEnabled(Ext_Q)

mapping clause encdec = F_BIN_F_TYPE_Q(rs2, rs1, rd, FMAX_Q)
  <-> 0b001_0111 @ encdec_freg(rs2) @ encdec_freg(rs1) @ 0b001 @ encdec_freg(rd) @ 0b101_0011
  when currentlyEnabled(Ext_Q)

mapping clause encdec = F_BIN_X_TYPE_D(rs2, rs1, rd, FEQ_D)
  <-> 0b101_0011 @ encdec_freg(rs2) @ encdec_freg(rs1) @ 0b010 @ encdec_reg(rd) @ 0b101_0011
  when currentlyEnabled(Ext_Q)

mapping clause encdec = F_BIN_X_TYPE_D(rs2, rs1, rd, FLT_D)
  <-> 0b101_0011 @ encdec_freg(rs2) @ encdec_freg(rs1) @ 0b001 @ encdec_reg(rd) @ 0b101_0011
  when currentlyEnabled(Ext_Q)

mapping clause encdec = F_BIN_X_TYPE_D(rs2, rs1, rd, FLE_D)
  <-> 0b101_0011 @ encdec_freg(rs2) @ encdec_freg(rs1) @ 0b000 @ encdec_reg(rd) @ 0b101_0011
  when currentlyEnabled(Ext_Q)

/* Execution semantics ================================ */

function clause execute (F_BIN_F_TYPE_Q(rs2, rs1, rd, FSGNJ_Q)) = {
  let rs1_val_Q    = F_Q(rs1);
  let rs2_val_Q    = F_Q(rs2);

  let (s1, e1, m1) = fsplit_Q (rs1_val_Q);
  let (s2, e2, m2) = fsplit_Q (rs2_val_Q);
  let rd_val_Q     = fmake_Q (s2, e1, m1);

  F_Q(rd) = rd_val_Q;
  RETIRE_SUCCESS
}

function clause execute (F_BIN_F_TYPE_Q(rs2, rs1, rd, FSGNJN_Q)) = {
  let rs1_val_Q    = F_Q(rs1);
  let rs2_val_Q    = F_Q(rs2);
  let (s1, e1, m1) = fsplit_Q (rs1_val_Q);
  let (s2, e2, m2) = fsplit_Q (rs2_val_Q);
  let rd_val_Q     = fmake_Q (0b1 ^ s2, e1, m1);

  F_Q(rd) = rd_val_Q;
  RETIRE_SUCCESS
}

function clause execute (F_BIN_F_TYPE_Q(rs2, rs1, rd, FSGNJX_Q)) = {
  let rs1_val_Q    = F_Q(rs1);
  let rs2_val_Q    = F_Q(rs2);
  let (s1, e1, m1) = fsplit_Q (rs1_val_Q);
  let (s2, e2, m2) = fsplit_Q (rs2_val_Q);
  let rd_val_Q     = fmake_Q (s1 ^ s2, e1, m1);

  F_Q(rd) = rd_val_Q;
  RETIRE_SUCCESS
}

function clause execute (F_BIN_F_TYPE_Q(rs2, rs1, rd, FMIN_Q)) = {
  let rs1_val_Q = F_Q(rs1);
  let rs2_val_Q = F_Q(rs2);

  let is_quiet  = true;
  let (rs1_lt_rs2, fflags) = fle_Q (rs1_val_Q, rs2_val_Q, is_quiet);

  let rd_val_Q  = if      (f_is_NaN_Q(rs1_val_Q) & f_is_NaN_Q(rs2_val_Q))           then canonical_NaN_Q()
                  else if f_is_NaN_Q(rs1_val_Q)                                     then rs2_val_Q
                  else if f_is_NaN_Q(rs2_val_Q)                                     then rs1_val_Q
                  else if (f_is_neg_zero_Q(rs1_val_Q) & f_is_pos_zero_Q(rs2_val_Q)) then rs1_val_Q
                  else if (f_is_neg_zero_Q(rs2_val_Q) & f_is_pos_zero_Q(rs1_val_Q)) then rs2_val_Q
                  else if rs1_lt_rs2                                                then rs1_val_Q
                  else /* (not rs1_lt_rs2) */                                            rs2_val_Q;

  accrue_fflags(fflags);
  F_Q(rd) = rd_val_Q;
  RETIRE_SUCCESS
}

function clause execute (F_BIN_F_TYPE_Q(rs2, rs1, rd, FMAX_Q)) = {
  let rs1_val_Q = F_Q(rs1);
  let rs2_val_Q = F_Q(rs2);

  let is_quiet  = true;
  let (rs2_lt_rs1, fflags) = fle_Q (rs2_val_Q, rs1_val_Q, is_quiet);

  let rd_val_Q  = if      (f_is_NaN_Q(rs1_val_Q) & f_is_NaN_Q(rs2_val_Q))           then canonical_NaN_Q()
                  else if f_is_NaN_Q(rs1_val_Q)                                     then rs2_val_Q
                  else if f_is_NaN_Q(rs2_val_Q)                                     then rs1_val_Q
                  else if (f_is_neg_zero_Q(rs1_val_Q) & f_is_pos_zero_Q(rs2_val_Q)) then rs2_val_Q
                  else if (f_is_neg_zero_Q(rs2_val_Q) & f_is_pos_zero_Q(rs1_val_Q)) then rs1_val_Q
                  else if rs2_lt_rs1                                                then rs1_val_Q
                  else /* (not rs2_lt_rs1) */                                            rs2_val_Q;

  accrue_fflags(fflags);
  F_Q(rd) = rd_val_Q;
  RETIRE_SUCCESS
}

function clause execute (F_BIN_X_TYPE_Q(rs2, rs1, rd, FEQ_Q)) = {
  let rs1_val_Q = F_Q(rs1);
  let rs2_val_Q = F_Q(rs2);

  let (fflags, rd_val) : (bits_fflags, bool) =
      riscv_f128Eq (rs1_val_Q, rs2_val_Q);

  accrue_fflags(fflags);
  X(rd) = zero_extend(bool_to_bits(rd_val));
  RETIRE_SUCCESS
}

function clause execute (F_BIN_X_TYPE_Q(rs2, rs1, rd, FLT_Q)) = {
  let rs1_val_Q = F_Q(rs1);
  let rs2_val_Q = F_Q(rs2);

  let (fflags, rd_val) : (bits_fflags, bool) =
      riscv_f128Lt (rs1_val_Q, rs2_val_Q);

  accrue_fflags(fflags);
  X(rd) = zero_extend(bool_to_bits(rd_val));
  RETIRE_SUCCESS
}

function clause execute (F_BIN_X_TYPE_Q(rs2, rs1, rd, FLE_Q)) = {
  let rs1_val_Q = F_Q(rs1);
  let rs2_val_Q = F_Q(rs2);

  let (fflags, rd_val) : (bits_fflags, bool) =
      riscv_f128Le (rs1_val_Q, rs2_val_Q);

  accrue_fflags(fflags);
  X(rd) = zero_extend(bool_to_bits(rd_val));
  RETIRE_SUCCESS
}

/* AST -> Assembly notation ================================ */

mapping f_bin_f_type_mnemonic_Q : f_bin_f_op_Q <-> string = {
    FSGNJ_Q  <-> "fsgnj.q",
    FSGNJN_Q <-> "fsgnjn.q",
    FSGNJX_Q <-> "fsgnjx.q",
    FMIN_Q   <-> "fmin.q",
    FMAX_Q   <-> "fmax.q",
}

mapping clause assembly = F_BIN_F_TYPE_Q(rs2, rs1, rd, op)
                      <-> f_bin_f_type_mnemonic_Q(op)
                          ^ spc() ^ freg_or_reg_name(rd)
                          ^ sep() ^ freg_or_reg_name(rs1)
                          ^ sep() ^ freg_or_reg_name(rs2)

mapping f_bin_x_type_mnemonic_Q : f_bin_x_op_Q <-> string = {
    FEQ_Q    <-> "feq.q",
    FLT_Q    <-> "flt.q",
    FLE_Q    <-> "fle.q"
}

mapping clause assembly = F_BIN_X_TYPE_Q(rs2, rs1, rd, op)
                      <-> f_bin_x_type_mnemonic_Q(op)
                          ^ spc() ^ reg_name(rd)
                          ^ sep() ^ freg_or_reg_name(rs1)
                          ^ sep() ^ freg_or_reg_name(rs2)

/* ****************************************************************** */
/* Unary, no rounding mode */

union clause ast = F_UN_X_TYPE_Q : (fregidx, regidx, f_un_x_op_Q)

/* AST <-> Binary encoding ================================ */

mapping clause encdec = F_UN_X_TYPE_Q(rs1, rd, FCLASS_Q)
  <-> 0b111_0011 @ 0b00000 @ encdec_freg(rs1) @ 0b001 @ encdec_reg(rd) @ 0b101_0011
  when currentlyEnabled(Ext_Q)

/* FMV Q instructions are RV128 only */

/* Execution semantics ================================ */

function clause execute (F_UN_X_TYPE_Q(rs1, rd, FCLASS_Q)) = {
  let rs1_val_Q = F_Q(rs1);

  let rd_val_10b : bits (10) =
    if      f_is_neg_inf_Q     (rs1_val_Q) then 0b_00_0000_0001
    else if f_is_neg_norm_Q    (rs1_val_Q) then 0b_00_0000_0010
    else if f_is_neg_subnorm_Q (rs1_val_Q) then 0b_00_0000_0100
    else if f_is_neg_zero_Q    (rs1_val_Q) then 0b_00_0000_1000
    else if f_is_pos_zero_Q    (rs1_val_Q) then 0b_00_0001_0000
    else if f_is_pos_subnorm_Q (rs1_val_Q) then 0b_00_0010_0000
    else if f_is_pos_norm_Q    (rs1_val_Q) then 0b_00_0100_0000
    else if f_is_pos_inf_Q     (rs1_val_Q) then 0b_00_1000_0000
    else if f_is_SNaN_Q        (rs1_val_Q) then 0b_01_0000_0000
    else if f_is_QNaN_Q        (rs1_val_Q) then 0b_10_0000_0000
    else zeros();

  X(rd) = zero_extend (rd_val_10b);
  RETIRE_SUCCESS
}

/* AST -> Assembly notation ================================ */

mapping f_un_x_type_mnemonic_Q : f_un_x_op_Q <-> string = {
    FCLASS_Q <-> "fclass.d",
}

mapping clause assembly = F_UN_X_TYPE_Q(rs1, rd, op)
                      <-> f_un_x_type_mnemonic_Q(op)
                          ^ spc() ^ reg_name(rd)
                          ^ sep() ^ freg_name(rs1)

/* ****************************************************************** */
