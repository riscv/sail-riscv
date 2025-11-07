// =======================================================================================
// This Sail RISC-V architecture model, comprising all files and
// directories except where otherwise noted is subject the BSD
// two-clause license in the LICENSE file.
//
// SPDX-License-Identifier: BSD-2-Clause
// =======================================================================================

function compressed_measure(instr : instruction) -> int =
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

// When adding a new extension X, we need to make sure that if X being enabled
// depends on Y being enabled, then the value associated to X is _greater_ than
// the value associated to Y. The default value is 2, so that if it does not
// depend on anything or only on extensions A, B, C, D, F, M, S, Zve32x, Zvl* or Zicsr,
// nothing needs to be done.
function currentlyEnabled_measure(ext : extension) -> int =
  match ext {
    Ext_Zicsr => 0,
    Ext_A => 1,
    Ext_B => 1,
    Ext_C => 1,
    Ext_D => 1,
    Ext_F => 1,
    Ext_M => 1,
    Ext_S => 1,
    Ext_V => 5,
    Ext_H => 4,
    Ext_Smcntrpmf => 3,
    Ext_Zabha => 3,
    Ext_Zacas => 3,
    Ext_Za64rs => 3,
    Ext_Za128rs => 3,
    Ext_Zcb => 3,
    Ext_Zcd => 3,
    Ext_Zcf => 3,
    Ext_Zcmop => 3,
    Ext_Zfhmin => 3,
    Ext_Zhinx => 3,
    Ext_Zicfilp => 3,
    Ext_Zvl32b => 0,
    Ext_Zvl64b => 0,
    Ext_Zvl128b => 0,
    Ext_Zvl256b => 0,
    Ext_Zvl512b => 0,
    Ext_Zvl1024b => 0,
    Ext_Zve32x => 1,
    Ext_Zvfbfmin => 3,
    Ext_Zvfbfwma => 4,
    Ext_Zve64f => 3,
    Ext_Zve64d => 4,
    Ext_Zvfh => 4,
    Ext_Zvfhmin => 5,
    Ext_Zvbb => 6,
    Ext_Zvbc => 6,
    Ext_Zvkb => 7,
    Ext_Zvkg => 6,
    Ext_Zvkned => 6,
    Ext_Zvknha => 6,
    Ext_Zvknhb => 6,
    Ext_Zvksed => 6,
    Ext_Zvksh => 6,
    Ext_Sscofpmf => 3,
    Ext_Svrsw60t59b => 3,
    Ext_Zhinxmin => 4,
    _ => 2
  }

termination_measure currentlyEnabled(ext) = currentlyEnabled_measure(ext)
termination_measure virtual_memory_supported(_) = 3

// get_xLPE() and currentlyEnabled() are mutually recursive
termination_measure get_xLPE(_) = 2

function hartSupports_measure(ext : extension) -> int =
  match ext {
    Ext_D => 1,
    Ext_V => 1,
    Ext_Zvkn => 1,
    Ext_Zvks => 1,
    Ext_C => 2,
    Ext_Zvknc => 2,
    Ext_Zvkng => 2,
    Ext_Zvksc => 2,
    Ext_Zvksg => 2,
    Ext_Sstvecd => 1,
    _ => 0,
  }

termination_measure hartSupports(ext) = hartSupports_measure(ext)

// Termination measures for loops are not supported by the Lean backend, so they
// should be guarded by this condition:
$iftarget coq

termination_measure vmem_write_addr repeat n
termination_measure vmem_read_addr repeat n

// The top-level loop isn't terminating, but we put a limit so that it can still be included in the Coq output
termination_measure loop while 100

$endif
