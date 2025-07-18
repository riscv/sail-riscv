/*=======================================================================================*/
/*  This Sail RISC-V architecture model, comprising all files and                        */
/*  directories except where otherwise noted is subject the BSD                          */
/*  two-clause license in the LICENSE file.                                              */
/*                                                                                       */
/*  SPDX-License-Identifier: BSD-2-Clause                                                */
/*=======================================================================================*/

function clause currentlyEnabled(Ext_Zfbfmin) = hartSupports(Ext_Zfbfmin) & currentlyEnabled(Ext_Zfh)

union clause instruction = FCVT_BF16_S : (fregidx, rounding_mode, fregidx)

mapping clause encdec = FCVT_BF16_S(rs1, rm, rd)
 <-> 0b01000 @ 0b10 @ 0b01000 @ encdec_freg(rs1) @ encdec_rounding_mode(rm) @ encdec_freg(rd) @ 0b1010011 when currentlyEnabled(Ext_Zfbfmin)

 mapping clause assembly = FCVT_BF16_S(rs1, rm, rd)
  <-> "fcvt.bf16.s" ^ spc() ^ freg_name(rd) ^ spc() ^ freg_name(rs1) ^ spc() ^ frm_mnemonic(rm)

function clause execute (FCVT_BF16_S(rs1, rm, rd)) = {
  let rs1_val_S = F_or_X_S(rs1);
  match (select_instr_or_fcsr_rm (rm)) {
    None() => Illegal_Instruction(),
    Some(rm') => {
      let rm_3b = encdec_rounding_mode(rm');
      let (fflags, rd_val_BF16) = riscv_f32ToBF16(rm_3b, rs1_val_S);

      accrue_fflags(fflags);
      F_or_X_BF16(rd) = rd_val_BF16;
      RETIRE_SUCCESS
    }
  }
}

union clause instruction = FCVT_S_BF16 : (fregidx, rounding_mode, fregidx)

mapping clause encdec = FCVT_S_BF16(rs1, rm, rd)
 <-> 0b01000 @ 0b00 @ 0b00110 @ encdec_freg(rs1) @ encdec_rounding_mode(rm) @ encdec_freg(rd) @ 0b1010011 when currentlyEnabled(Ext_Zfbfmin)

 mapping clause assembly = FCVT_S_BF16(rs1, rm, rd)
  <-> "fcvt.s.bf16" ^ spc() ^ freg_name(rd) ^ spc() ^ freg_name(rs1) ^ spc() ^ frm_mnemonic(rm)

function clause execute (FCVT_S_BF16(rs1, rm, rd)) = {
    let rs1_val_BF16 = F_or_X_BF16(rs1);
    match(select_instr_or_fcsr_rm (rm)) {
      None () => Illegal_Instruction(),
      Some(rm') => {
        let rm_3b = encdec_rounding_mode(rm');
        let (fflags, rd_val_S) = riscv_bf16ToF32(rm_3b, rs1_val_BF16);

        accrue_fflags(fflags);
        F_or_X_S(rd) = rd_val_S;
        RETIRE_SUCCESS
      }
    }
}
