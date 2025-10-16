// =======================================================================================
// This Sail RISC-V architecture model, comprising all files and
// directories except where otherwise noted is subject the BSD
// two-clause license in the LICENSE file.
//
// SPDX-License-Identifier: BSD-2-Clause
// =======================================================================================

// Zfbfmin also defines FLH, FSH, FMV.X.H, and FMV.H.X instructions as defined in the Zfh extension

function clause currentlyEnabled(Ext_Zfbfmin) = hartSupports(Ext_Zfbfmin) & currentlyEnabled(Ext_F)

union clause instruction = FCVT_BF16_S : (fregidx, rounding_mode, fregidx)

$[wavedrom "fcvt h bf16.s _ _ _ OP-FP"]
mapping clause encdec = FCVT_BF16_S(rs1, rm, rd)
  <-> 0b01000 @ 0b10 @ 0b01000 @ encdec_freg(rs1) @ encdec_rounding_mode(rm) @ encdec_freg(rd) @ 0b1010011
  when currentlyEnabled(Ext_Zfbfmin)

function clause execute FCVT_BF16_S(rs1, rm, rd) = {
  let rs1_val_S = F_or_X_S(rs1);
  match (select_instr_or_fcsr_rm (rm)) {
    None() => Illegal_Instruction(),
    Some(rm') => {
      let rm_3b = encdec_rounding_mode(rm');
      let (fflags, rd_val_BF16) = riscv_f32ToBF16(rm_3b, rs1_val_S);

      accrue_fflags(fflags);
      F_BF16(rd) = rd_val_BF16;
      RETIRE_SUCCESS
    }
  }
}

mapping clause assembly = FCVT_BF16_S(rs1, rm, rd)
  <-> "fcvt.bf16.s" ^ spc() ^ freg_name(rd) ^ sep() ^ freg_name(rs1) ^ sep() ^ frm_mnemonic(rm)

union clause instruction = FCVT_S_BF16 : (fregidx, rounding_mode, fregidx)

$[wavedrom "fcvt s bf16.s _ _ _ OP-FP"]
mapping clause encdec = FCVT_S_BF16(rs1, rm, rd)
  <-> 0b01000 @ 0b00 @ 0b00110 @ encdec_freg(rs1) @ encdec_rounding_mode(rm) @ encdec_freg(rd) @ 0b1010011
  when currentlyEnabled(Ext_Zfbfmin)

function clause execute FCVT_S_BF16(rs1, rm, rd) = {
  if select_instr_or_fcsr_rm(rm) == None()
  then return Illegal_Instruction();

  let (fflags, rd_val_S) = bf16_to_f32(F_BF16(rs1));

  accrue_fflags(fflags);
  F_S(rd) = rd_val_S;
  RETIRE_SUCCESS
}

mapping clause assembly = FCVT_S_BF16(rs1, rm, rd)
  <-> "fcvt.s.bf16" ^ spc() ^ freg_name(rd) ^ sep() ^ freg_name(rs1) ^ sep() ^ frm_mnemonic(rm)
