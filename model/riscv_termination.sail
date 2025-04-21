/*=======================================================================================*/
/*  This Sail RISC-V architecture model, comprising all files and                        */
/*  directories except where otherwise noted is subject the BSD                          */
/*  two-clause license in the LICENSE file.                                              */
/*                                                                                       */
/*  SPDX-License-Identifier: BSD-2-Clause                                                */
/*=======================================================================================*/

val compressed_measure : ast -> int
function compressed_measure(instr) =
  match instr {
    C_ADDI4SPN (rdc,nzimm) => 1,
    C_LW (uimm,rsc,rdc) => 1,
    C_LD (uimm,rsc,rdc) => 1,
    C_SW (uimm,rsc1,rsc2) => 1,
    C_SD (uimm,rsc1,rsc2) => 1,
    C_ADDI (nzi,rsd) => 1,
    C_JAL (imm) => 1,
    C_ADDIW (imm,rsd) => 1,
    C_LI (imm,rd) => 1,
    C_ADDI16SP (imm) => 1,
    C_LUI (imm,rd) => 1,
    C_SRLI (shamt,rsd) => 1,
    C_SRAI (shamt,rsd) => 1,
    C_ANDI (imm,rsd) => 1,
    C_SUB (rsd,rs2) => 1,
    C_XOR (rsd,rs2) => 1,
    C_OR (rsd,rs2) => 1,
    C_AND (rsd,rs2) => 1,
    C_SUBW (rsd,rs2) => 1,
    C_ADDW (rsd,rs2) => 1,
    C_J (imm) => 1,
    C_BEQZ (imm,rs) => 1,
    C_BNEZ (imm,rs) => 1,
    C_SLLI (shamt,rsd) => 1,
    C_LWSP (uimm,rd) => 1,
    C_LDSP (uimm,rd) => 1,
    C_SWSP (uimm,rs2) => 1,
    C_SDSP (uimm,rs2) => 1,
    C_JR (rs1) => 1,
    C_JALR (rs1) => 1,
    C_MV (rd,rs2) => 1,
    C_EBREAK (tt) => 1,
    C_ADD (rsd,rs2) => 1,
    C_FLDSP(uimm, rd) => 1,
    C_FSDSP(uimm, rs2) => 1,
    C_FLD(uimm, rsc, rdc) => 1,
    C_FSD(uimm, rsc1, rsc2) => 1,
    C_FLWSP(imm, rd) => 1,
    C_FSWSP(uimm, rs2) => 1,
    C_FLW(uimm, rsc, rdc) => 1,
    C_FSW(uimm, rsc1, rsc2) => 1,
    _ => 0
  }
termination_measure execute(i) = compressed_measure(i)
termination_measure pt_walk(_,_,_,_,_,_,_,level,_, _) = level

function currentlyEnabled_measure(ext : extension) -> int =
  match ext {
    Ext_Zca => 1, // Ext_C
    Ext_Zba => 1, // Ext_B
    Ext_Zbb => 1, // Ext_B
    Ext_Zbs => 1, // Ext_B
    Ext_Zcb => 2, // Ext_Zca
    Ext_Zcd => 2, // Ext_Zca, (Ext_D)
    Ext_Zcf => 2, // Ext_Zca, (Ext_F)
    Ext_Zabha => 2, // Ext_Zaamo
    Ext_Zalrsc => 1, // Ext_A
    Ext_Zaamo => 1, // Ext_A
    Ext_Zfh => 1, // Ext_F
    Ext_Zfhmin => 2, // Ext_F, Ext_Zfh
    Ext_Zmmul => 1, // Ext_M
    Ext_Zcmop => 2, // Ext_Zca
    Ext_Zfa => 1, // Ext_F
    Ext_Zhinx => 1, // Ext_Zfinx
    Ext_Zvbb => 1, // Ext_V
    Ext_Zvkb => 2, // Ext_Zvbb, Ext_V
    Ext_Zvbc => 1, // Ext_V
    Ext_Smcntrpmf => 1, // Ext_Zicntr
    Ext_Sscofpmf => 2, // Ext_Zihpm
    Ext_Zihpm => 1, // Ext_Zicntr
    _ => 0
  }
termination_measure currentlyEnabled(ext) = currentlyEnabled_measure(ext)

function hartSupports_measure(ext : extension) -> int =
  match ext {
    Ext_C => 1,
    _ => 0,
  }

termination_measure hartSupports(ext) = hartSupports_measure(ext)

$iftarget coq
// The top-level loop isn't terminating, but we put a limit so that it can still be included in the Coq output
termination_measure loop while 100
$endif
