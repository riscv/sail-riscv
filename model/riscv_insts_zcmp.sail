/*=======================================================================================*/
/*  This Sail RISC-V architecture model, comprising all files and                        */
/*  directories except where otherwise noted is subject the BSD                          */
/*  two-clause license in the LICENSE file.                                              */
/*                                                                                       */
/*  SPDX-License-Identifier: BSD-2-Clause                                                */
/*=======================================================================================*/

enum clause extension = Ext_Zcmp
function clause extensionEnabled(Ext_Zcmp) = sys_enable_zcb()

union clause ast = C_LBU : (bits(2), cregidx, cregidx)

mapping clause encdec_compressed =
      C_LBU(uimm1 @ uimm0, rdc, rs1c)                                                           if extensionEnabled(Ext_Zcmp)
  <-> 0b100 @ 0b000 @ rs1c : cregidx @ uimm0 : bits(1) @ uimm1 : bits(1) @ rdc : cregidx @ 0b00 if extensionEnabled(Ext_Zcmp)

mapping clause assembly = C_LBU(uimm, rdc, rs1c) <->
  "c.lbu" ^ spc() ^ creg_name(rdc) ^ sep() ^ hex_bits_2(uimm) ^ opt_spc() ^ "(" ^ opt_spc() ^ creg_name(rs1c) ^ opt_spc() ^ ")"

function clause execute C_LBU(uimm, rdc, rs1c) = {
  let imm : bits(12) = zero_extend(uimm);
  let rd = creg2reg_idx(rdc);
  let rs1 = creg2reg_idx(rs1c);
  execute(LOAD(imm, rs1, rd, true, BYTE, false, false))
}
