/*=======================================================================================*/
/*  This Sail RISC-V architecture model, comprising all files and                        */
/*  directories except where otherwise noted is subject the BSD                          */
/*  two-clause license in the LICENSE file.                                              */
/*                                                                                       */
/*  SPDX-License-Identifier: BSD-2-Clause                                                */
/*=======================================================================================*/

function clause opcode2format _ = Unknown_Format

mapping fmt2bits : instruction_input <-> bits(32) = {

  UFormat(struct { imm = imm, rd = rd, opcode = opcode }) if opcode2format(opcode) == U_Format
    <-> imm @ rd @ opcode if opcode2format(opcode) == U_Format,

  RFormat(struct { funct7 = funct7, rs2 = rs2, rs1 = rs1, funct3 = funct3, rd = rd, opcode = opcode }) if opcode2format(opcode) == R_Format
    <-> funct7 @ rs2 @ rs1 @ funct3 @ rd @ opcode if opcode2format(opcode) == R_Format,

  JFormat(struct { imm = imm_20 : bits(1) @ imm_19_12 : bits(8) @ imm_11 : bits(1) @ imm_10_1 : bits(10) @ 0b0, rd = rd, opcode = opcode }) if opcode2format(opcode) == J_Format
    <-> imm_20 @ imm_10_1 @ imm_11 @ imm_19_12 @ rd @ opcode if opcode2format(opcode) == J_Format,

  BFormat(struct { imm = imm_12 : bits(1) @ imm_11 : bits(1) @ imm_10_5 : bits(6) @ imm_4_1 : bits(4) @ 0b0, rs2 = rs2, rs1 = rs1, funct3 = funct3, opcode = opcode }) if opcode2format(opcode) == B_Format
    <-> imm_12 @ imm_10_5 @ rs2 @ rs1 @ funct3 @ imm_4_1 @ imm_11 @ opcode if opcode2format(opcode) == B_Format,

  SFormat(struct { imm = imm7 : bits(7) @ imm5 : bits(5), rs2 = rs2, rs1 = rs1, funct3 = funct3, opcode = opcode }) if opcode2format(opcode) == S_Format
    <-> imm7 @ rs2 @ rs1 @ funct3 @ imm5 @ opcode if opcode2format(opcode) == S_Format,

  IFormat(struct { imm = imm, rs1 = rs1, funct3 = funct3, rd = rd, opcode = opcode }) if opcode2format(opcode) == I_Format
    <-> imm @ rs1 @ funct3 @ rd @ opcode if opcode2format(opcode) == I_Format,
}

/* Put the illegal instructions last to use their wildcard match. */

/* ****************************************************************** */

mapping clause oldencdec = ILLEGAL(s) <-> s

function clause execute (ILLEGAL(s)) = { handle_illegal(); RETIRE_FAIL }

mapping clause assembly = ILLEGAL(s) <-> "illegal" ^ spc() ^ hex_bits_32(s)

/* ****************************************************************** */

mapping clause encdec_compressed = C_ILLEGAL(s) <-> s

function clause execute C_ILLEGAL(s) = { handle_illegal(); RETIRE_FAIL }

mapping clause assembly = C_ILLEGAL(s) <-> "c.illegal" ^ spc() ^ hex_bits_16(s)

/* ****************************************************************** */

/* End definitions */
end extension
end extensionEnabled
end ast
end execute
end assembly
end encdec
end encdec_compressed

val print_insn : ast -> string
function print_insn insn = assembly(insn)

overload to_str = {print_insn}
