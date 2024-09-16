/*=======================================================================================*/
/*  This Sail RISC-V architecture model, comprising all files and                        */
/*  directories except where otherwise noted is subject the BSD                          */
/*  two-clause license in the LICENSE file.                                              */
/*                                                                                       */
/*  SPDX-License-Identifier: BSD-2-Clause                                                */
/*=======================================================================================*/

/* Instruction definitions.
 *
 * This includes decoding, execution, and assembly parsing and printing.
 */

scattered union ast

/* returns whether an instruction was retired, used for computing minstret */
val execute : ast -> Retired
scattered function execute

val assembly : ast <-> string
scattered mapping assembly

val oldencdec : ast <-> bits(32)
scattered mapping oldencdec

union instruction_input = {
  RFormat: { funct7: bits(7), rs2: regidx, rs1: regidx, funct3: bits(3), rd: regidx, opcode: bits(7) },
  IFormat: { imm: bits(12), rs1: regidx, funct3: bits(3), rd: regidx, opcode: bits(7) },
  SFormat: { imm: bits(12), rs2: regidx, rs1: regidx, funct3: bits(3), opcode: bits(7) },
  BFormat: { imm: bits(13), rs2: regidx, rs1: regidx, funct3: bits(3), opcode: bits(7) },
  UFormat: { imm: bits(20), rd: regidx, opcode: bits(7) },
  JFormat: { imm: bits(21), rd: regidx, opcode: bits(7) }
}

val encdec_compressed : ast <-> bits(16)
scattered mapping encdec_compressed

union instruction_input_compressed = {
  CRFormat: { funct4: bits(4), rd: regidx, rs2: regidx, op: bits(2) },
  // CIFormat: { funct3: bits(3), imm1: bits(1), rd: regidx, imm5: bits(5), op: bits(2) },
  CIFormat: { funct3: bits(3), imm: bits(6), rd: regidx, op: bits(2) },
  CSSFormat: { funct3: bits(3), imm6: bits(6), rs2: regidx, op: bits(2) },
  CIWFormat: { funct3: bits(3), imm8: bits(8), rd: cregidx, op: bits(2) },
  CLFormat: { funct3: bits(3), imm: bits(5), rs1: cregidx, rd: cregidx, op: bits(2) },
  CSFormat: { funct3: bits(3), imm: bits(5), rs1: cregidx, rs2: cregidx, op: bits(2) },
  CAFormat: { funct6: bits(6), rd: cregidx, imm2: bits(2), rs2: cregidx, op: bits(2) },
  CBFormat: { funct3: bits(3), offset3: bits(3), rs1: cregidx, offset5: bits(5), op: bits(2) },
  CJFormat: { funct3: bits(3), target: bits(11), op: bits(2) }
}

val fmtencdec : ast <-> instruction_input
scattered mapping fmtencdec

val fmtencdec_compressed : ast <-> instruction_input_compressed
scattered mapping fmtencdec_compressed

enum Format = { R_Format, U_Format, I_Format, J_Format, S_Format, B_Format, Unknown_Format }
val opcode2format : bits(7) -> Format
scattered function opcode2format

val fmt2bits16 : instruction_input_compressed <-> bits(16)
scattered mapping fmt2bits16

mapping clause fmt2bits16 = CIFormat(struct { imm = imm1 : bits(1) @ imm5: bits(5), rd = rd, funct3 = funct3, op = op })
  <-> funct3 @ imm1 @ rd @ imm5 @ op

/*
 * We declare the ILLEGAL/C_ILLEGAL ast clauses here instead of in
 * riscv_insts_end, so that model extensions can make use of them.
 * However, the encdec mapping must come last to ensure that all
 * unmatched encodings decode to an illegal instruction.
 */
union clause ast = ILLEGAL : word
union clause ast = C_ILLEGAL : half
