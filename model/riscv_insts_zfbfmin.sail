/* **************************************************************** */
/* This file specifies the instructions in the Zfh extension        */
/* (half precision floating point).                                 */

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

/* Unary with rounding mode */

/* AST */

union clause ast = F_BF16_UN_RM_TYPE_H : (regidx, rounding_mode, regidx, f_bf16_un_rm_op_H)

/* AST <-> Binary encoding ================================ */

mapping clause encdec =
    F_BF16_UN_RM_TYPE_H(rs1, rm, rd, FCVT_BF16_S)                             if haveZfbfmin()
<-> 0b010_0010 @ 0b01000 @ rs1 @ encdec_rounding_mode (rm) @ rd @ 0b101_0011  if haveZfbfmin()

mapping clause encdec =
    F_BF16_UN_RM_TYPE_H(rs1, rm, rd, FCVT_S_BF16)                             if haveZfbfmin()
<-> 0b010_0000 @ 0b00110 @ rs1 @ encdec_rounding_mode (rm) @ rd @ 0b101_0011  if haveZfbfmin()

/* Execution semantics ================================ */

function clause execute (F_BF16_UN_RM_TYPE_H(rs1, rm, rd, FCVT_BF16_S)) = {
  let rs1_val_S = F_or_X_S(rs1);
  match (select_instr_or_fcsr_rm (rm)) {
    None() => { handle_illegal(); RETIRE_FAIL },
    Some(rm') => {
      let rm_3b = encdec_rounding_mode(rm');
      let (fflags, rd_val_H) = riscv_f32ToBF16 (rm_3b, rs1_val_S);

      write_fflags(fflags);
      F_or_X_H(rd) = rd_val_H;
      RETIRE_SUCCESS
    }
  }
}

function clause execute (F_BF16_UN_RM_TYPE_H(rs1, rm, rd, FCVT_S_BF16)) = {
  let rs1_val_H = F_or_X_H(rs1);
  match (select_instr_or_fcsr_rm (rm)) {
    None() => { handle_illegal(); RETIRE_FAIL },
    Some(rm') => {
      let rm_3b = encdec_rounding_mode(rm');
      let (fflags, rd_val_S) = riscv_bf16ToF32 (rm_3b, rs1_val_H);

      write_fflags(fflags);
      F_or_X_S(rd) = rd_val_S;
      RETIRE_SUCCESS
    }
  }
}

/* AST -> Assembly notation ================================ */

mapping f_bf16_un_rm_type_mnemonic_H : f_bf16_un_rm_op_H <-> string = {
    FCVT_BF16_S  <-> "fcvt.bf16.s",
    FCVT_S_BF16  <-> "fcvt.s.bf16",
}

mapping clause assembly = F_BF16_UN_RM_TYPE_H(rs1, rm, rd, FCVT_BF16_S)
                      <-> f_bf16_un_rm_type_mnemonic_H(FCVT_BF16_S)
                          ^ spc() ^ freg_or_reg_name(rd)
                          ^ sep() ^ freg_or_reg_name(rs1)
                          ^ sep() ^ frm_mnemonic(rm)

mapping clause assembly = F_BF16_UN_RM_TYPE_H(rs1, rm, rd, FCVT_S_BF16)
                      <-> f_bf16_un_rm_type_mnemonic_H(FCVT_S_BF16)
                          ^ spc() ^ freg_or_reg_name(rd)
                          ^ sep() ^ freg_or_reg_name(rs1)
                          ^ sep() ^ frm_mnemonic(rm)
