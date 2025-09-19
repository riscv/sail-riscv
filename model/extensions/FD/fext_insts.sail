// =======================================================================================
// This Sail RISC-V architecture model, comprising all files and
// directories except where otherwise noted is subject the BSD
// two-clause license in the LICENSE file.
//
// SPDX-License-Identifier: BSD-2-Clause
// =======================================================================================

// ***************************************************************
// This file specifies the instructions in the F extension
// (single precision floating point).

// RISC-V follows IEEE 754-2008 floating point arithmetic standard.

// Original version written by Rishiyur S. Nikhil, Sept-Oct 2019

// ***************************************************************
// IMPORTANT!
// The files 'fext_insts.sail', 'dext_insts.sail' and
// 'zfh_insts.sail' define the F, D and Zfh extensions,
// respectively.
// The texts follow each other very closely; please try to maintain
// this correspondence as the files are maintained for bug-fixes,
// improvements, and version updates.

// ***************************************************************

function clause currentlyEnabled(Ext_Zfh) =  hartSupports(Ext_Zfh) & currentlyEnabled(Ext_F)
function clause currentlyEnabled(Ext_Zfhmin) =  (hartSupports(Ext_Zfhmin) & currentlyEnabled(Ext_F)) | currentlyEnabled(Ext_Zfh)

mapping encdec_rounding_mode : rounding_mode <-> bits(3) = {
  RM_RNE <-> 0b000,
  RM_RTZ <-> 0b001,
  RM_RDN <-> 0b010,
  RM_RUP <-> 0b011,
  RM_RMM <-> 0b100,
  RM_DYN <-> 0b111
}

mapping frm_mnemonic : rounding_mode <-> string = {
  RM_RNE <-> "rne",
  RM_RTZ <-> "rtz",
  RM_RDN <-> "rdn",
  RM_RUP <-> "rup",
  RM_RMM <-> "rmm",
  RM_DYN <-> "dyn"
}

val      valid_rounding_mode : bits(3) -> bool
function valid_rounding_mode rm = (rm != 0b101 & rm != 0b110)

val      select_instr_or_fcsr_rm : rounding_mode -> option(rounding_mode)
function select_instr_or_fcsr_rm instr_rm =
  if (instr_rm == RM_DYN)
  then {
    let fcsr_rm = fcsr[FRM];
    if (valid_rounding_mode(fcsr_rm) & fcsr_rm != encdec_rounding_mode(RM_DYN))
      then Some(encdec_rounding_mode(fcsr_rm)) else None()
  }
  else Some(instr_rm)

// ***************************************************************
// Floating point accrued exception flags

function nxFlag() -> bits(5) = 0b_00001
function ufFlag() -> bits(5) = 0b_00010
function ofFlag() -> bits(5) = 0b_00100
function dzFlag() -> bits(5) = 0b_01000
function nvFlag() -> bits(5) = 0b_10000

// ***************************************************************
// S and D value structure (sign, exponent, mantissa)

// TODO: this should be a 'mapping'
val      fsplit_S : bits(32) -> (bits(1), bits(8), bits(23))
function fsplit_S   x32 = (x32[31..31], x32[30..23], x32[22..0])

val      fmake_S  : (bits(1), bits(8), bits(23)) -> bits(32)
function fmake_S (sign, exp, mant) = sign @ exp @ mant

// ---- Structure tests

val      f_is_neg_inf_S : bits(32) -> bool
function f_is_neg_inf_S   x32 = {
  let (sign, exp, mant) = fsplit_S (x32);
  (  (sign == 0b1)
   & (exp  == ones())
   & (mant == zeros()))
}

val      f_is_neg_norm_S : bits(32) -> bool
function f_is_neg_norm_S   x32 = {
  let (sign, exp, mant) = fsplit_S (x32);
  (  (sign == 0b1)
   & (exp  != zeros())
   & (exp  != ones()))
}

val      f_is_neg_subnorm_S : bits(32) -> bool
function f_is_neg_subnorm_S   x32 = {
  let (sign, exp, mant) = fsplit_S (x32);
  (  (sign == 0b1)
   & (exp  == zeros())
   & (mant != zeros()))
}

val      f_is_neg_zero_S : bits(32) -> bool
function f_is_neg_zero_S   x32 = {
  let (sign, exp, mant) = fsplit_S (x32);
  (  (sign == ones())
   & (exp  == zeros())
   & (mant == zeros()))
}

val      f_is_pos_zero_S : bits(32) -> bool
function f_is_pos_zero_S   x32 = {
  let (sign, exp, mant) = fsplit_S (x32);
  (  (sign == zeros())
   & (exp  == zeros())
   & (mant == zeros()))
}

val      f_is_pos_subnorm_S : bits(32) -> bool
function f_is_pos_subnorm_S   x32 = {
  let (sign, exp, mant) = fsplit_S (x32);
  (  (sign == zeros())
   & (exp  == zeros())
   & (mant != zeros()))
}

val      f_is_pos_norm_S : bits(32) -> bool
function f_is_pos_norm_S   x32 = {
  let (sign, exp, mant) = fsplit_S (x32);
  (  (sign == zeros())
   & (exp  != zeros())
   & (exp  != ones()))
}

val      f_is_pos_inf_S : bits(32) -> bool
function f_is_pos_inf_S   x32 = {
  let (sign, exp, mant) = fsplit_S (x32);
  (  (sign == zeros())
   & (exp  == ones())
   & (mant == zeros()))
}

val      f_is_SNaN_S : bits(32) -> bool
function f_is_SNaN_S   x32 = {
  let (sign, exp, mant) = fsplit_S (x32);
  (  (exp == ones())
   & (mant [22] == bitzero)
   & (mant != zeros()))
}

val      f_is_QNaN_S : bits(32) -> bool
function f_is_QNaN_S   x32 = {
  let (sign, exp, mant) = fsplit_S (x32);
  (  (exp == ones())
   & (mant [22] == bitone))
}

// Either QNaN or SNan
val      f_is_NaN_S : bits(32) -> bool
function f_is_NaN_S   x32 = {
  let (sign, exp, mant) = fsplit_S (x32);
  (  (exp == ones())
   & (mant != zeros()))
}

// ***************************************************************
// Help functions used in the semantic functions

val      negate_S : bits(32) -> bits(32)
function negate_S (x32) = {
  let (sign, exp, mant) = fsplit_S (x32);
  let new_sign = if (sign == 0b0) then 0b1 else 0b0;
  fmake_S (new_sign, exp, mant)
}

val      feq_quiet_S : (bits(32), bits (32)) -> (bool, bits(5))
function feq_quiet_S   (v1,       v2) = {
  let (s1, e1, m1) = fsplit_S (v1);
  let (s2, e2, m2) = fsplit_S (v2);

  let v1Is0    = f_is_neg_zero_S(v1) | f_is_pos_zero_S(v1);
  let v2Is0    = f_is_neg_zero_S(v2) | f_is_pos_zero_S(v2);

  let result = ((v1 == v2) | (v1Is0 & v2Is0));

  let fflags = if   (f_is_SNaN_S(v1) | f_is_SNaN_S(v2))
               then nvFlag()
               else zeros();

  (result, fflags)
}

val      flt_S : (bits(32), bits (32), bool) -> (bool, bits(5))
function flt_S   (v1,       v2,        is_quiet) = {
  let (s1, e1, m1) = fsplit_S (v1);
  let (s2, e2, m2) = fsplit_S (v2);

  let result : bool =
    if (s1 == 0b0) & (s2 == 0b0) then
      if   (e1 == e2)
      then unsigned (m1) < unsigned (m2)
      else unsigned (e1) < unsigned (e2)
    else if (s1 == 0b0) & (s2 == 0b1)
    then false
    else if (s1 == 0b1) & (s2 == 0b0)
    then true
    else
        if   (e1 == e2)
        then unsigned (m1) > unsigned (m2)
        else unsigned (e1) > unsigned (e2);

  let fflags = if is_quiet then
                 if   (f_is_SNaN_S(v1) | f_is_SNaN_S(v2))
                 then nvFlag()
                 else zeros()
               else
                 if   (f_is_NaN_S(v1) | f_is_NaN_S(v2))
                 then nvFlag()
                 else zeros();

  (result, fflags)
}

val      fle_S : (bits(32), bits (32), bool) -> (bool, bits(5))
function fle_S   (v1,       v2,        is_quiet) = {
  let (s1, e1, m1) = fsplit_S (v1);
  let (s2, e2, m2) = fsplit_S (v2);

  let v1Is0    = f_is_neg_zero_S(v1) | f_is_pos_zero_S(v1);
  let v2Is0    = f_is_neg_zero_S(v2) | f_is_pos_zero_S(v2);

  let result : bool =
    if (s1 == 0b0) & (s2 == 0b0) then
      if   (e1 == e2)
      then unsigned (m1) <=  unsigned (m2)
      else unsigned (e1)  <  unsigned (e2)
    else if (s1 == 0b0) & (s2 == 0b1)
    then (v1Is0 & v2Is0)                         // Equal in this case (+0=-0)
    else if (s1 == 0b1) & (s2 == 0b0)
    then true
    else
      if   (e1 == e2)
      then unsigned (m1) >=  unsigned (m2)
      else unsigned (e1)  >  unsigned (e2);

  let fflags = if is_quiet then
                 if   (f_is_SNaN_S(v1) | f_is_SNaN_S(v2))
                 then nvFlag()
                 else zeros()
               else
                 if   (f_is_NaN_S(v1) | f_is_NaN_S(v2))
                 then nvFlag()
                 else zeros();

  (result, fflags)
}

// ***************************************************************
// Helper functions for 'encdec()'

function haveSingleFPU() -> bool = currentlyEnabled(Ext_F) | currentlyEnabled(Ext_Zfinx)

function float_load_store_width_supported(width : word_width) -> bool =
  match width {
    1 => false,
    2 => currentlyEnabled(Ext_Zfhmin) | currentlyEnabled(Ext_Zfbfmin),
    4 => currentlyEnabled(Ext_F),
    8 => currentlyEnabled(Ext_D),
  }

// *****************************************************************
// Floating-point loads

// instruction
// FLH, FLW and FLD; H/W/D is encoded in 'word_width'

union clause instruction = LOAD_FP : (bits(12), regidx, fregidx, word_width)

// instruction <-> Binary encoding ================================

mapping clause encdec = LOAD_FP(imm, rs1, rd, width)
  <-> imm @ encdec_reg(rs1) @ 0b0 @ width_enc(width) @ encdec_freg(rd) @ 0b000_0111
  when float_load_store_width_supported(width)

// Execution semantics ================================

function clause execute(LOAD_FP(imm, rs1, rd, width)) = {
  // This is checked during decoding.
  assert(width <= flen_bytes);

  let offset : xlenbits = sign_extend(imm);
  match vmem_read(rs1, offset, width, Read(Data), false, false, false) {
    Ok(result) => { F(rd) = nan_box(result); RETIRE_SUCCESS },
    Err(e)     => e,
  }
}

// instruction -> Assembly notation ================================

mapping clause assembly = LOAD_FP(imm, rs1, rd, width)
                      <-> "fl" ^ width_mnemonic(width)
                          ^ spc() ^ freg_or_reg_name(rd)
                          ^ sep() ^ hex_bits_signed_12(imm)
                          ^ opt_spc() ^ "(" ^ opt_spc() ^ reg_name(rs1) ^ opt_spc() ^ ")"

// *****************************************************************
// Floating-point stores

// instruction
// FSH, FSW and FSD; H/W/D is encoded in 'word_width'

union clause instruction = STORE_FP : (bits(12), fregidx, regidx, word_width)

// instruction <-> Binary encoding ================================

mapping clause encdec = STORE_FP(imm7 @ imm5, rs2, rs1, width)
  <-> imm7 : bits(7) @ encdec_freg(rs2) @ encdec_reg(rs1) @ 0b0 @ width_enc(width) @ imm5 : bits(5) @ 0b010_0111
  when float_load_store_width_supported(width)

// Execution semantics ================================

function clause execute (STORE_FP(imm, rs2, rs1, width)) = {
  // This is checked during decoding.
  assert(width <= flen_bytes);

  let offset : xlenbits = sign_extend(imm);
  let data = F(rs2)[width * 8 - 1 ..  0];
  match vmem_write(rs1, offset, width, data, Write(Data), false, false, false) {
    Ok(true)  => RETIRE_SUCCESS,
    Ok(false) => internal_error(__FILE__, __LINE__, "store got false from vmem_write"),
    Err(e)    => e,
  }
}

// instruction -> Assembly notation ================================

mapping clause assembly = STORE_FP(imm, rs2, rs1, width)
                      <-> "fs" ^ width_mnemonic(width)
                          ^ spc() ^ freg_name(rs2)
                          ^ sep() ^ hex_bits_signed_12(imm)
                          ^ opt_spc() ^ "(" ^ opt_spc() ^ reg_name(rs1) ^ opt_spc() ^ ")"

// *****************************************************************
// Fused multiply-add

// instruction

union clause instruction = F_MADD_TYPE_S : (fregidx, fregidx, fregidx, rounding_mode, fregidx, f_madd_op_S)

// instruction <-> Binary encoding ================================

mapping clause encdec = F_MADD_TYPE_S(rs3, rs2, rs1, rm, rd, FMADD_S)
  <-> encdec_freg(rs3) @ 0b00 @ encdec_freg(rs2) @ encdec_freg(rs1) @ encdec_rounding_mode (rm) @ encdec_freg(rd) @ 0b100_0011
  when haveSingleFPU()

mapping clause encdec = F_MADD_TYPE_S(rs3, rs2, rs1, rm, rd, FMSUB_S)
  <-> encdec_freg(rs3) @ 0b00 @ encdec_freg(rs2) @ encdec_freg(rs1) @ encdec_rounding_mode (rm) @ encdec_freg(rd) @ 0b100_0111
  when haveSingleFPU()

mapping clause encdec = F_MADD_TYPE_S(rs3, rs2, rs1, rm, rd, FNMSUB_S)
  <-> encdec_freg(rs3) @ 0b00 @ encdec_freg(rs2) @ encdec_freg(rs1) @ encdec_rounding_mode (rm) @ encdec_freg(rd) @ 0b100_1011
  when haveSingleFPU()

mapping clause encdec = F_MADD_TYPE_S(rs3, rs2, rs1, rm, rd, FNMADD_S)
  <-> encdec_freg(rs3) @ 0b00 @ encdec_freg(rs2) @ encdec_freg(rs1) @ encdec_rounding_mode (rm) @ encdec_freg(rd) @ 0b100_1111
  when haveSingleFPU()

// Execution semantics ================================

$[split op]
function clause execute F_MADD_TYPE_S(rs3, rs2, rs1, rm, rd, op) = {
  let rs1_val_32b = F_or_X_S(rs1);
  let rs2_val_32b = F_or_X_S(rs2);
  let rs3_val_32b = F_or_X_S(rs3);
  match (select_instr_or_fcsr_rm (rm)) {
    None() => Illegal_Instruction(),
    Some(rm') => {
      let rm_3b = encdec_rounding_mode(rm');
      let (fflags, rd_val_32b) : (bits(5), bits(32)) =
        match op {
          FMADD_S  => riscv_f32MulAdd (rm_3b, rs1_val_32b, rs2_val_32b, rs3_val_32b),
          FMSUB_S  => riscv_f32MulAdd (rm_3b, rs1_val_32b, rs2_val_32b, negate_S (rs3_val_32b)),
          FNMSUB_S => riscv_f32MulAdd (rm_3b, negate_S (rs1_val_32b), rs2_val_32b, rs3_val_32b),
          FNMADD_S => riscv_f32MulAdd (rm_3b, negate_S (rs1_val_32b), rs2_val_32b, negate_S (rs3_val_32b))
        };
      accrue_fflags(fflags);
      F_or_X_S(rd) = rd_val_32b;
      RETIRE_SUCCESS
    }
  }
}

// instruction -> Assembly notation ================================

mapping f_madd_type_mnemonic_S : f_madd_op_S <-> string = {
    FMADD_S  <-> "fmadd.s",
    FMSUB_S  <-> "fmsub.s",
    FNMSUB_S <-> "fnmsub.s",
    FNMADD_S <-> "fnmadd.s"
}

mapping clause assembly = F_MADD_TYPE_S(rs3, rs2, rs1, rm, rd, op)
                      <-> f_madd_type_mnemonic_S(op)
                          ^ spc() ^ freg_or_reg_name(rd)
                          ^ sep() ^ freg_or_reg_name(rs1)
                          ^ sep() ^ freg_or_reg_name(rs2)
                          ^ sep() ^ freg_or_reg_name(rs3)
                          ^ sep() ^ frm_mnemonic(rm)

// *****************************************************************
// Binary ops with rounding mode

// instruction

union clause instruction = F_BIN_RM_TYPE_S : (fregidx, fregidx, rounding_mode, fregidx, f_bin_rm_op_S)

// instruction <-> Binary encoding ================================

mapping clause encdec = F_BIN_RM_TYPE_S(rs2, rs1, rm, rd, FADD_S)
  <-> 0b000_0000 @ encdec_freg(rs2) @ encdec_freg(rs1) @ encdec_rounding_mode (rm) @ encdec_freg(rd) @ 0b101_0011
  when haveSingleFPU()

mapping clause encdec = F_BIN_RM_TYPE_S(rs2, rs1, rm, rd, FSUB_S)
  <-> 0b000_0100 @ encdec_freg(rs2) @ encdec_freg(rs1) @ encdec_rounding_mode (rm) @ encdec_freg(rd) @ 0b101_0011
  when haveSingleFPU()

mapping clause encdec = F_BIN_RM_TYPE_S(rs2, rs1, rm, rd, FMUL_S)
  <-> 0b000_1000 @ encdec_freg(rs2) @ encdec_freg(rs1) @ encdec_rounding_mode (rm) @ encdec_freg(rd) @ 0b101_0011
  when haveSingleFPU()

mapping clause encdec = F_BIN_RM_TYPE_S(rs2, rs1, rm, rd, FDIV_S)
  <-> 0b000_1100 @ encdec_freg(rs2) @ encdec_freg(rs1) @ encdec_rounding_mode (rm) @ encdec_freg(rd) @ 0b101_0011
  when haveSingleFPU()

// Execution semantics ================================

$[split op]
function clause execute F_BIN_RM_TYPE_S(rs2, rs1, rm, rd, op) = {
  let rs1_val_32b = F_or_X_S(rs1);
  let rs2_val_32b = F_or_X_S(rs2);
  match (select_instr_or_fcsr_rm (rm)) {
    None() => Illegal_Instruction(),
    Some(rm') => {
      let rm_3b = encdec_rounding_mode(rm');
      let (fflags, rd_val_32b) : (bits(5), bits(32)) = match op {
        FADD_S  => riscv_f32Add (rm_3b, rs1_val_32b, rs2_val_32b),
        FSUB_S  => riscv_f32Sub (rm_3b, rs1_val_32b, rs2_val_32b),
        FMUL_S  => riscv_f32Mul (rm_3b, rs1_val_32b, rs2_val_32b),
        FDIV_S  => riscv_f32Div (rm_3b, rs1_val_32b, rs2_val_32b)
      };
      accrue_fflags(fflags);
      F_or_X_S(rd) = rd_val_32b;
      RETIRE_SUCCESS
    }
  }
}

// instruction -> Assembly notation ================================

mapping f_bin_rm_type_mnemonic_S : f_bin_rm_op_S <-> string = {
  FADD_S  <-> "fadd.s",
  FSUB_S  <-> "fsub.s",
  FMUL_S  <-> "fmul.s",
  FDIV_S  <-> "fdiv.s"
}

mapping clause assembly = F_BIN_RM_TYPE_S(rs2, rs1, rm, rd, op)
                      <-> f_bin_rm_type_mnemonic_S(op)
                          ^ spc() ^ freg_or_reg_name(rd)
                          ^ sep() ^ freg_or_reg_name(rs1)
                          ^ sep() ^ freg_or_reg_name(rs2)
                          ^ sep() ^ frm_mnemonic(rm)

// *****************************************************************
// Unary with rounding mode

// instruction

union clause instruction = F_UN_RM_FF_TYPE_S : (fregidx, rounding_mode, fregidx, f_un_rm_ff_op_S)
union clause instruction = F_UN_RM_FX_TYPE_S : (fregidx, rounding_mode, regidx, f_un_rm_fx_op_S)
union clause instruction = F_UN_RM_XF_TYPE_S : (regidx, rounding_mode, fregidx, f_un_rm_xf_op_S)

// instruction <-> Binary encoding ================================

mapping clause encdec = F_UN_RM_FF_TYPE_S(rs1, rm, rd, FSQRT_S)
  <-> 0b010_1100 @ 0b00000 @ encdec_freg(rs1) @ encdec_rounding_mode (rm) @ encdec_freg(rd) @ 0b101_0011
  when haveSingleFPU()

mapping clause encdec = F_UN_RM_FX_TYPE_S(rs1, rm, rd, FCVT_W_S)
  <-> 0b110_0000 @ 0b00000 @ encdec_freg(rs1) @ encdec_rounding_mode (rm) @ encdec_reg(rd) @ 0b101_0011
  when haveSingleFPU()

mapping clause encdec = F_UN_RM_FX_TYPE_S(rs1, rm, rd, FCVT_WU_S)
  <-> 0b110_0000 @ 0b00001 @ encdec_freg(rs1) @ encdec_rounding_mode (rm) @ encdec_reg(rd) @ 0b101_0011
  when haveSingleFPU()

mapping clause encdec = F_UN_RM_XF_TYPE_S(rs1, rm, rd, FCVT_S_W)
  <-> 0b110_1000 @ 0b00000 @ encdec_reg(rs1) @ encdec_rounding_mode (rm) @ encdec_freg(rd) @ 0b101_0011
  when haveSingleFPU()

mapping clause encdec = F_UN_RM_XF_TYPE_S(rs1, rm, rd, FCVT_S_WU)
  <-> 0b110_1000 @ 0b00001 @ encdec_reg(rs1) @ encdec_rounding_mode (rm) @ encdec_freg(rd) @ 0b101_0011
  when haveSingleFPU()

// F instructions, RV64 only

mapping clause encdec = F_UN_RM_FX_TYPE_S(rs1, rm, rd, FCVT_L_S)
  <-> 0b110_0000 @ 0b00010 @ encdec_freg(rs1) @ encdec_rounding_mode (rm) @ encdec_reg(rd) @ 0b101_0011
  when haveSingleFPU() & xlen >= 64

mapping clause encdec = F_UN_RM_FX_TYPE_S(rs1, rm, rd, FCVT_LU_S)
  <-> 0b110_0000 @ 0b00011 @ encdec_freg(rs1) @ encdec_rounding_mode (rm) @ encdec_reg(rd) @ 0b101_0011
  when haveSingleFPU() & xlen >= 64

mapping clause encdec = F_UN_RM_XF_TYPE_S(rs1, rm, rd, FCVT_S_L)
  <-> 0b110_1000 @ 0b00010 @ encdec_reg(rs1) @ encdec_rounding_mode (rm) @ encdec_freg(rd) @ 0b101_0011
  when haveSingleFPU() & xlen >= 64

mapping clause encdec = F_UN_RM_XF_TYPE_S(rs1, rm, rd, FCVT_S_LU)
  <-> 0b110_1000 @ 0b00011 @ encdec_reg(rs1) @ encdec_rounding_mode (rm) @ encdec_freg(rd) @ 0b101_0011
  when haveSingleFPU() & xlen >= 64

// Execution semantics ================================

function clause execute (F_UN_RM_FF_TYPE_S(rs1, rm, rd, FSQRT_S)) = {
  let rs1_val_S = F_or_X_S(rs1);
  match (select_instr_or_fcsr_rm (rm)) {
    None() => Illegal_Instruction(),
    Some(rm') => {
      let rm_3b = encdec_rounding_mode(rm');
      let (fflags, rd_val_S) = riscv_f32Sqrt   (rm_3b, rs1_val_S);

      accrue_fflags(fflags);
      F_or_X_S(rd) = rd_val_S;
      RETIRE_SUCCESS
    }
  }
}

function clause execute (F_UN_RM_FX_TYPE_S(rs1, rm, rd, FCVT_W_S)) = {
  let rs1_val_S = F_or_X_S(rs1);
  match (select_instr_or_fcsr_rm (rm)) {
    None() => Illegal_Instruction(),
    Some(rm') => {
      let rm_3b = encdec_rounding_mode(rm');
      let (fflags, rd_val_W) = riscv_f32ToI32 (rm_3b, rs1_val_S);

      accrue_fflags(fflags);
      X(rd) = sign_extend (rd_val_W);
      RETIRE_SUCCESS
    }
  }
}

function clause execute (F_UN_RM_FX_TYPE_S(rs1, rm, rd, FCVT_WU_S)) = {
  let rs1_val_S = F_or_X_S(rs1);
  match (select_instr_or_fcsr_rm (rm)) {
    None() => Illegal_Instruction(),
    Some(rm') => {
      let rm_3b = encdec_rounding_mode(rm');
      let (fflags, rd_val_WU) = riscv_f32ToUi32 (rm_3b, rs1_val_S);

      accrue_fflags(fflags);
      X(rd) = sign_extend (rd_val_WU);
      RETIRE_SUCCESS
    }
  }
}

function clause execute (F_UN_RM_XF_TYPE_S(rs1, rm, rd, FCVT_S_W)) = {
  let rs1_val_W = X(rs1) [31..0];
  match (select_instr_or_fcsr_rm (rm)) {
    None() => Illegal_Instruction(),
    Some(rm') => {
      let rm_3b = encdec_rounding_mode(rm');
      let (fflags, rd_val_S) = riscv_i32ToF32 (rm_3b, rs1_val_W);

      accrue_fflags(fflags);
      F_or_X_S(rd) = rd_val_S;
      RETIRE_SUCCESS
    }
  }
}

function clause execute (F_UN_RM_XF_TYPE_S(rs1, rm, rd, FCVT_S_WU)) = {
  let rs1_val_WU = X(rs1) [31..0];
  match (select_instr_or_fcsr_rm (rm)) {
    None() => Illegal_Instruction(),
    Some(rm') => {
      let rm_3b = encdec_rounding_mode(rm');
      let (fflags, rd_val_S) = riscv_ui32ToF32 (rm_3b, rs1_val_WU);

      accrue_fflags(fflags);
      F_or_X_S(rd) = rd_val_S;
      RETIRE_SUCCESS
    }
  }
}

function clause execute (F_UN_RM_FX_TYPE_S(rs1, rm, rd, FCVT_L_S)) = {
  assert(xlen >= 64);
  let rs1_val_S = F_or_X_S(rs1);
  match (select_instr_or_fcsr_rm (rm)) {
    None() => Illegal_Instruction(),
    Some(rm') => {
      let rm_3b = encdec_rounding_mode(rm');
      let (fflags, rd_val_L) = riscv_f32ToI64 (rm_3b, rs1_val_S);

      accrue_fflags(fflags);
      X(rd) = sign_extend(rd_val_L);
      RETIRE_SUCCESS
    }
  }
}

function clause execute (F_UN_RM_FX_TYPE_S(rs1, rm, rd, FCVT_LU_S)) = {
  assert(xlen >= 64);
  let rs1_val_S = F_or_X_S(rs1);
  match (select_instr_or_fcsr_rm (rm)) {
    None() => Illegal_Instruction(),
    Some(rm') => {
      let rm_3b = encdec_rounding_mode(rm');
      let (fflags, rd_val_LU) = riscv_f32ToUi64 (rm_3b, rs1_val_S);

      accrue_fflags(fflags);
      X(rd) = sign_extend(rd_val_LU);
      RETIRE_SUCCESS
    }
  }
}

function clause execute (F_UN_RM_XF_TYPE_S(rs1, rm, rd, FCVT_S_L)) = {
  assert(xlen >= 64);
  let rs1_val_L = X(rs1)[63..0];
  match (select_instr_or_fcsr_rm (rm)) {
    None() => Illegal_Instruction(),
    Some(rm') => {
      let rm_3b = encdec_rounding_mode(rm');
      let (fflags, rd_val_S) = riscv_i64ToF32 (rm_3b, rs1_val_L);

      accrue_fflags(fflags);
      F_or_X_S(rd) = rd_val_S;
      RETIRE_SUCCESS
    }
  }
}

function clause execute (F_UN_RM_XF_TYPE_S(rs1, rm, rd, FCVT_S_LU)) = {
  assert(xlen >= 64);
  let rs1_val_LU = X(rs1)[63..0];
  match (select_instr_or_fcsr_rm (rm)) {
    None() => Illegal_Instruction(),
    Some(rm') => {
      let rm_3b = encdec_rounding_mode(rm');
      let (fflags, rd_val_S) = riscv_ui64ToF32 (rm_3b, rs1_val_LU);

      accrue_fflags(fflags);
      F_or_X_S(rd) = rd_val_S;
      RETIRE_SUCCESS
    }
  }
}

// instruction -> Assembly notation ================================

mapping clause assembly = F_UN_RM_FF_TYPE_S(rs1, rm, rd, FSQRT_S)
                      <-> "fsqrt.s"
                          ^ spc() ^ freg_or_reg_name(rd)
                          ^ sep() ^ freg_or_reg_name(rs1)
                          ^ sep() ^ frm_mnemonic(rm)


mapping f_un_rm_fx_type_mnemonic_S : f_un_rm_fx_op_S <-> string = {
    FCVT_W_S  <-> "fcvt.w.s",
    FCVT_WU_S <-> "fcvt.wu.s",
    FCVT_L_S  <-> "fcvt.l.s",
    FCVT_LU_S <-> "fcvt.lu.s",
}

mapping clause assembly = F_UN_RM_FX_TYPE_S(rs1, rm, rd, op)
                      <-> f_un_rm_fx_type_mnemonic_S(op)
                          ^ spc() ^ reg_name(rd)
                          ^ sep() ^ freg_or_reg_name(rs1)
                          ^ sep() ^ frm_mnemonic(rm)

mapping f_un_rm_xf_type_mnemonic_S : f_un_rm_xf_op_S <-> string = {
    FCVT_S_W  <-> "fcvt.s.w",
    FCVT_S_WU <-> "fcvt.s.wu",
    FCVT_S_L  <-> "fcvt.s.l",
    FCVT_S_LU <-> "fcvt.s.lu"
}

mapping clause assembly = F_UN_RM_XF_TYPE_S(rs1, rm, rd, op)
                      <-> f_un_rm_xf_type_mnemonic_S(op)
                          ^ spc() ^ freg_or_reg_name(rd)
                          ^ sep() ^ reg_name(rs1)
                          ^ sep() ^ frm_mnemonic(rm)

// *****************************************************************
// Binary, no rounding mode

// instruction

union clause instruction = F_BIN_TYPE_F_S : (fregidx, fregidx, fregidx, f_bin_op_f_S)
union clause instruction = F_BIN_TYPE_X_S : (fregidx, fregidx, regidx, f_bin_op_x_S)

// instruction <-> Binary encoding ================================

mapping clause encdec = F_BIN_TYPE_F_S(rs2, rs1, rd, FSGNJ_S)
                    <-> 0b001_0000 @ encdec_freg(rs2) @ encdec_freg(rs1) @ 0b000 @ encdec_freg(rd) @ 0b101_0011
                    when haveSingleFPU()

mapping clause encdec = F_BIN_TYPE_F_S(rs2, rs1, rd, FSGNJN_S)
                    <-> 0b001_0000 @ encdec_freg(rs2) @ encdec_freg(rs1) @ 0b001 @ encdec_freg(rd) @ 0b101_0011
                    when haveSingleFPU()

mapping clause encdec = F_BIN_TYPE_F_S(rs2, rs1, rd, FSGNJX_S)
                    <-> 0b001_0000 @ encdec_freg(rs2) @ encdec_freg(rs1) @ 0b010 @ encdec_freg(rd) @ 0b101_0011
                    when haveSingleFPU()

mapping clause encdec = F_BIN_TYPE_F_S(rs2, rs1, rd, FMIN_S)
                    <-> 0b001_0100 @ encdec_freg(rs2) @ encdec_freg(rs1) @ 0b000 @ encdec_freg(rd) @ 0b101_0011
                    when haveSingleFPU()

mapping clause encdec = F_BIN_TYPE_F_S(rs2, rs1, rd, FMAX_S)
                    <-> 0b001_0100 @ encdec_freg(rs2) @ encdec_freg(rs1) @ 0b001 @ encdec_freg(rd) @ 0b101_0011
                    when haveSingleFPU()

mapping clause encdec = F_BIN_TYPE_X_S(rs2, rs1, rd, FEQ_S)
                    <-> 0b101_0000 @ encdec_freg(rs2) @ encdec_freg(rs1) @ 0b010 @ encdec_reg(rd) @ 0b101_0011
                    when haveSingleFPU()

mapping clause encdec = F_BIN_TYPE_X_S(rs2, rs1, rd, FLT_S)
                    <-> 0b101_0000 @ encdec_freg(rs2) @ encdec_freg(rs1) @ 0b001 @ encdec_reg(rd) @ 0b101_0011
                    when haveSingleFPU()

mapping clause encdec = F_BIN_TYPE_X_S(rs2, rs1, rd, FLE_S)
                    <-> 0b101_0000 @ encdec_freg(rs2) @ encdec_freg(rs1) @ 0b000 @ encdec_reg(rd) @ 0b101_0011
                    when haveSingleFPU()

// Execution semantics ================================

function clause execute (F_BIN_TYPE_F_S(rs2, rs1, rd, FSGNJ_S)) = {
  let rs1_val_S    = F_or_X_S(rs1);
  let rs2_val_S    = F_or_X_S(rs2);
  let (s1, e1, m1) = fsplit_S (rs1_val_S);
  let (s2, e2, m2) = fsplit_S (rs2_val_S);
  let rd_val_S     = fmake_S (s2, e1, m1);

  F_or_X_S(rd) = rd_val_S;
  RETIRE_SUCCESS
}

function clause execute (F_BIN_TYPE_F_S(rs2, rs1, rd, FSGNJN_S)) = {
  let rs1_val_S    = F_or_X_S(rs1);
  let rs2_val_S    = F_or_X_S(rs2);
  let (s1, e1, m1) = fsplit_S (rs1_val_S);
  let (s2, e2, m2) = fsplit_S (rs2_val_S);
  let rd_val_S     = fmake_S (0b1 ^ s2, e1, m1);

  F_or_X_S(rd) = rd_val_S;
  RETIRE_SUCCESS
}

function clause execute (F_BIN_TYPE_F_S(rs2, rs1, rd, FSGNJX_S)) = {
  let rs1_val_S    = F_or_X_S(rs1);
  let rs2_val_S    = F_or_X_S(rs2);
  let (s1, e1, m1) = fsplit_S (rs1_val_S);
  let (s2, e2, m2) = fsplit_S (rs2_val_S);
  let rd_val_S     = fmake_S (s1 ^ s2, e1, m1);

  F_or_X_S(rd) = rd_val_S;
  RETIRE_SUCCESS
}

function clause execute (F_BIN_TYPE_F_S(rs2, rs1, rd, FMIN_S)) = {
  let rs1_val_S = F_or_X_S(rs1);
  let rs2_val_S = F_or_X_S(rs2);

  let is_quiet  = true;
  let (rs1_lt_rs2, fflags) = fle_S (rs1_val_S, rs2_val_S, is_quiet);

  let rd_val_S  = if      (f_is_NaN_S(rs1_val_S) & f_is_NaN_S(rs2_val_S))           then canonical_NaN_S()
                  else if f_is_NaN_S(rs1_val_S)                                     then rs2_val_S
                  else if f_is_NaN_S(rs2_val_S)                                     then rs1_val_S
                  else if (f_is_neg_zero_S(rs1_val_S) & f_is_pos_zero_S(rs2_val_S)) then rs1_val_S
                  else if (f_is_neg_zero_S(rs2_val_S) & f_is_pos_zero_S(rs1_val_S)) then rs2_val_S
                  else if rs1_lt_rs2                                                then rs1_val_S
                  else /* (not rs1_lt_rs2) */                                            rs2_val_S;

  accrue_fflags(fflags);
  F_or_X_S(rd) = rd_val_S;
  RETIRE_SUCCESS
}

function clause execute (F_BIN_TYPE_F_S(rs2, rs1, rd, FMAX_S)) = {
  let rs1_val_S = F_or_X_S(rs1);
  let rs2_val_S = F_or_X_S(rs2);

  let is_quiet  = true;
  let (rs2_lt_rs1, fflags) = fle_S (rs2_val_S, rs1_val_S, is_quiet);

  let rd_val_S  = if      (f_is_NaN_S(rs1_val_S) & f_is_NaN_S(rs2_val_S))           then canonical_NaN_S()
                  else if f_is_NaN_S(rs1_val_S)                                     then rs2_val_S
                  else if f_is_NaN_S(rs2_val_S)                                     then rs1_val_S
                  else if (f_is_neg_zero_S(rs1_val_S) & f_is_pos_zero_S(rs2_val_S)) then rs2_val_S
                  else if (f_is_neg_zero_S(rs2_val_S) & f_is_pos_zero_S(rs1_val_S)) then rs1_val_S
                  else if rs2_lt_rs1                                                then rs1_val_S
                  else /* (not rs2_lt_rs1) */                                            rs2_val_S;

  accrue_fflags(fflags);
  F_or_X_S(rd) = rd_val_S;
  RETIRE_SUCCESS
}

function clause execute (F_BIN_TYPE_X_S(rs2, rs1, rd, FEQ_S)) = {
  let rs1_val_S = F_or_X_S(rs1);
  let rs2_val_S = F_or_X_S(rs2);

  let (fflags, rd_val) : (bits_fflags, bool) =
      riscv_f32Eq (rs1_val_S, rs2_val_S);

  accrue_fflags(fflags);
  X(rd) = zero_extend(bool_to_bits(rd_val));
  RETIRE_SUCCESS
}

function clause execute (F_BIN_TYPE_X_S(rs2, rs1, rd, FLT_S)) = {
  let rs1_val_S = F_or_X_S(rs1);
  let rs2_val_S = F_or_X_S(rs2);

  let (fflags, rd_val) : (bits_fflags, bool) =
      riscv_f32Lt (rs1_val_S, rs2_val_S);

  accrue_fflags(fflags);
  X(rd) = zero_extend(bool_to_bits(rd_val));
  RETIRE_SUCCESS
}

function clause execute (F_BIN_TYPE_X_S(rs2, rs1, rd, FLE_S)) = {
  let rs1_val_S = F_or_X_S(rs1);
  let rs2_val_S = F_or_X_S(rs2);

  let (fflags, rd_val) : (bits_fflags, bool) =
      riscv_f32Le (rs1_val_S, rs2_val_S);

  accrue_fflags(fflags);
  X(rd) = zero_extend(bool_to_bits(rd_val));
  RETIRE_SUCCESS
}

// instruction -> Assembly notation ================================

mapping f_bin_type_mnemonic_f_S : f_bin_op_f_S <-> string = {
    FSGNJ_S  <-> "fsgnj.s",
    FSGNJN_S <-> "fsgnjn.s",
    FSGNJX_S <-> "fsgnjx.s",
    FMIN_S   <-> "fmin.s",
    FMAX_S   <-> "fmax.s"
}

mapping clause assembly = F_BIN_TYPE_F_S(rs2, rs1, rd, op)
                      <-> f_bin_type_mnemonic_f_S(op)
                          ^ spc() ^ freg_or_reg_name(rd)
                          ^ sep() ^ freg_or_reg_name(rs1)
                          ^ sep() ^ freg_or_reg_name(rs2)

mapping f_bin_type_mnemonic_x_S : f_bin_op_x_S <-> string = {
    FEQ_S    <-> "feq.s",
    FLT_S    <-> "flt.s",
    FLE_S    <-> "fle.s"
}

mapping clause assembly = F_BIN_TYPE_X_S(rs2, rs1, rd, op)
                      <-> f_bin_type_mnemonic_x_S(op)
                          ^ spc() ^ reg_name(rd)
                          ^ sep() ^ freg_or_reg_name(rs1)
                          ^ sep() ^ freg_or_reg_name(rs2)

// *****************************************************************
// Unary, no rounding mode

union clause instruction = F_UN_TYPE_F_S : (regidx, fregidx, f_un_op_f_S)
union clause instruction = F_UN_TYPE_X_S : (fregidx, regidx, f_un_op_x_S)

// instruction <-> Binary encoding ================================

mapping clause encdec = F_UN_TYPE_X_S(rs1, rd, FCLASS_S)
                    <-> 0b111_0000 @ 0b00000 @ encdec_freg(rs1) @ 0b001 @ encdec_reg(rd) @ 0b101_0011
                    when haveSingleFPU()

mapping clause encdec = F_UN_TYPE_X_S(rs1, rd, FMV_X_W)
                    <-> 0b111_0000 @ 0b00000 @ encdec_freg(rs1) @ 0b000 @ encdec_reg(rd) @ 0b101_0011
                    when currentlyEnabled(Ext_F)

mapping clause encdec = F_UN_TYPE_F_S(rs1, rd, FMV_W_X)
                    <-> 0b111_1000 @ 0b00000 @ encdec_reg(rs1) @ 0b000 @ encdec_freg(rd) @ 0b101_0011
                    when currentlyEnabled(Ext_F)

// Execution semantics ================================

function clause execute (F_UN_TYPE_X_S(rs1, rd, FCLASS_S)) = {
  let rs1_val = F_or_X_S(rs1);
  X(rd) = zero_extend(float_point_class_bits(float_classify(rs1_val)));
  RETIRE_SUCCESS
}

function clause execute (F_UN_TYPE_X_S(rs1, rd, FMV_X_W)) = {
  X(rd) = sign_extend(F(rs1)[31..0]);
  RETIRE_SUCCESS
}

function clause execute (F_UN_TYPE_F_S(rs1, rd, FMV_W_X)) = {
  F(rd) = nan_box(X(rs1)[31..0]);
  RETIRE_SUCCESS
}

// instruction -> Assembly notation ================================

mapping f_un_type_mnemonic_x_S : f_un_op_x_S <-> string = {
    FCLASS_S <-> "fclass.s",
    FMV_X_W  <-> "fmv.x.w",
}

mapping clause assembly = F_UN_TYPE_X_S(rs1, rd, op)
                      <-> f_un_type_mnemonic_x_S(op)
                          ^ spc() ^ reg_name(rd)
                          ^ sep() ^ freg_name(rs1)

mapping f_un_type_mnemonic_f_S : f_un_op_f_S <-> string = {
    FMV_W_X  <-> "fmv.w.x"
}

mapping clause assembly = F_UN_TYPE_F_S(rs1, rd, op)
                      <-> f_un_type_mnemonic_f_S(op)
                          ^ spc() ^ freg_name(rd)
                          ^ sep() ^ reg_name(rs1)



// *****************************************************************
