/*=======================================================================================*/
/*  This Sail RISC-V architecture model, comprising all files and                        */
/*  directories except where otherwise noted is subject the BSD                          */
/*  two-clause license in the LICENSE file.                                              */
/*                                                                                       */
/*  SPDX-License-Identifier: BSD-2-Clause                                                */
/*=======================================================================================*/

val      split_BF16 : bits(16) -> (bits(1), bits(8), bits(7))
function split_BF16 (v) = (v[15..15], v[14..7], v[6..0])

function clause currentlyEnabled(Ext_Zfbfmin) = hartSupports(Ext_Zfbfmin) & currentlyEnabled(Ext_Zfh)

union clause instruction = FCVT_BF16_S : (fregidx, rounding_mode, fregidx)

mapping clause encdec = FCVT_BF16_S(rs1, rm, rd)
 <-> 0b01000 @ 0b10 @ 0b01000 @ encdec_freg(rs1) @ encdec_rounding_mode(rm) @ encdec_freg(rd) @ 0b1010011 when currentlyEnabled(Ext_Zfbfmin)

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

mapping clause assembly = FCVT_BF16_S(rs1, rm, rd)
  <-> "fcvt.bf16.s" ^ spc() ^ freg_name(rd) ^ sep() ^ freg_name(rs1) ^ sep() ^ frm_mnemonic(rm)

union clause instruction = FCVT_S_BF16 : (fregidx, rounding_mode, fregidx)

mapping clause encdec = FCVT_S_BF16(rs1, rm, rd)
 <-> 0b01000 @ 0b00 @ 0b00110 @ encdec_freg(rs1) @ encdec_rounding_mode(rm) @ encdec_freg(rd) @ 0b1010011 when currentlyEnabled(Ext_Zfbfmin)

function clause execute (FCVT_S_BF16(rs1, rm, rd)) = {
  let rs1_val_BF16 = F_or_X_BF16(rs1);

  let (sign, exp, mant) = split_BF16(rs1_val_BF16);

  if select_instr_or_fcsr_rm(rm) == None() then return Illegal_Instruction();

  F_or_X_S(rd) = match exp {
    0xFF => {
      if mant != 0b0000000 then {
        if mant[6] == bitzero then accrue_fflags(0b10000);
        sign @ 0xFF @ 0b1 @ zeros(22)
      } else {
        sign @ 0xFF @ zeros(23)
      }
    },
    _ => sign @ exp @ mant @ zeros(16)
  };

  RETIRE_SUCCESS
}

mapping clause assembly = FCVT_S_BF16(rs1, rm, rd)
  <-> "fcvt.s.bf16" ^ spc() ^ freg_name(rd) ^ sep() ^ freg_name(rs1) ^ sep() ^ frm_mnemonic(rm)
