/*=======================================================================================*/
/*  This Sail RISC-V architecture model, comprising all files and                        */
/*  directories except where otherwise noted is subject the BSD                          */
/*  two-clause license in the LICENSE file.                                              */
/*                                                                                       */
/*  SPDX-License-Identifier: BSD-2-Clause                                                */
/*=======================================================================================*/

function clause currentlyEnabled(Ext_Zbkx) = hartSupports(Ext_Zbkx)

/* ****************************************************************** */
union clause instruction = XPERM8 : (regidx, regidx, regidx)

mapping clause encdec = XPERM8(rs2, rs1, rd)
  <-> 0b0010100 @ encdec_reg(rs2) @ encdec_reg(rs1) @ 0b100 @ encdec_reg(rd) @ 0b0110011
  when currentlyEnabled(Ext_Zbkx)

mapping clause assembly = XPERM8(rs2, rs1, rd)
  <-> "xperm8" ^ spc() ^ reg_name(rd) ^ sep() ^ reg_name(rs1) ^ sep() ^ reg_name(rs2)

function clause execute (XPERM8(rs2, rs1, rd)) = {
  let rs1_val = X(rs1);
  let rs2_val = X(rs2);
  var result : xlenbits = zeros();
  foreach (i from 0 to (xlen - 8) by 8) {
    let index = unsigned(rs2_val[i+7..i]);
    result[i+7..i] = if 8*index < xlen
                     then rs1_val[8*index+7..8*index]
                     else zeros()
  };
  X(rd) = result;
  RETIRE_SUCCESS
}

/* ****************************************************************** */
union clause instruction = XPERM4 : (regidx, regidx, regidx)

mapping clause encdec = XPERM4(rs2, rs1, rd)
  <-> 0b0010100 @ encdec_reg(rs2) @ encdec_reg(rs1) @ 0b010 @ encdec_reg(rd) @ 0b0110011
  when currentlyEnabled(Ext_Zbkx)

mapping clause assembly = XPERM4(rs2, rs1, rd)
  <-> "xperm4" ^ spc() ^ reg_name(rd) ^ sep() ^ reg_name(rs1) ^ sep() ^ reg_name(rs2)

function clause execute (XPERM4(rs2, rs1, rd)) = {
  let rs1_val = X(rs1);
  let rs2_val = X(rs2);
  var result : xlenbits = zeros();
  foreach (i from 0 to (xlen - 4) by 4) {
    let index = unsigned(rs2_val[i+3..i]);
    result[i+3..i] = if 4*index < xlen
                     then rs1_val[4*index+3..4*index]
                     else zeros()
  };
  X(rd) = result;
  RETIRE_SUCCESS
}
