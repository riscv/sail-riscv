/*=======================================================================================*/
/*  This Sail RISC-V architecture model, comprising all files and                        */
/*  directories except where otherwise noted is subject the BSD                          */
/*  two-clause license in the LICENSE file.                                              */
/*                                                                                       */
/*  SPDX-License-Identifier: BSD-2-Clause                                                */
/*=======================================================================================*/

function clause compressed_measure(_) = 0
//  match instr {
//    C_ADDI4SPN (rdc,nzimm) => 1,
//    C_LW (uimm,rsc,rdc) => 1,
//    C_LD (uimm,rsc,rdc) => 1,
//    C_SW (uimm,rsc1,rsc2) => 1,
//    C_SD (uimm,rsc1,rsc2) => 1,
//    C_ADDI (nzi,rsd) => 1,
//    C_JAL (imm) => 1,
//    C_ADDIW (imm,rsd) => 1,
//    C_LI (imm,rd) => 1,
//    C_ADDI16SP (imm) => 1,
//    C_LUI (imm,rd) => 1,
//    C_SRLI (shamt,rsd) => 1,
//    C_SRAI (shamt,rsd) => 1,
//    C_ANDI (imm,rsd) => 1,
//    C_SUB (rsd,rs2) => 1,
//    C_XOR (rsd,rs2) => 1,
//    C_OR (rsd,rs2) => 1,
//    C_AND (rsd,rs2) => 1,
//    C_SUBW (rsd,rs2) => 1,
//    C_ADDW (rsd,rs2) => 1,
//    C_J (imm) => 1,
//    C_BEQZ (imm,rs) => 1,
//    C_BNEZ (imm,rs) => 1,
//    C_SLLI (shamt,rsd) => 1,
//    C_LWSP (uimm,rd) => 1,
//    C_LDSP (uimm,rd) => 1,
//    C_SWSP (uimm,rs2) => 1,
//    C_SDSP (uimm,rs2) => 1,
//    C_JR (rs1) => 1,
//    C_JALR (rs1) => 1,
//    C_MV (rd,rs2) => 1,
//    C_EBREAK (tt) => 1,
//    C_ADD (rsd,rs2) => 1,
//    C_FLDSP(uimm, rd) => 1,
//    C_FSDSP(uimm, rs2) => 1,
//    C_FLD(uimm, rsc, rdc) => 1,
//    C_FSD(uimm, rsc1, rsc2) => 1,
//    C_FLWSP(imm, rd) => 1,
//    C_FSWSP(uimm, rs2) => 1,
//    C_FLW(uimm, rsc, rdc) => 1,
//    C_FSW(uimm, rsc1, rsc2) => 1,
//    _ => 0
//  }

termination_measure execute(i) = compressed_measure(i)
termination_measure pt_walk(_,_,_,_,_,_,_,level,_, _) = level

end compressed_measure
