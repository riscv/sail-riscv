// =======================================================================================
// This Sail RISC-V architecture model, comprising all files and
// directories except where otherwise noted is subject the BSD
// two-clause license in the LICENSE file.
//
// SPDX-License-Identifier: BSD-2-Clause
// =======================================================================================

// This file defines the "Zibi" extension, which appends conditional branch instructions with an
// immediate operand. In real world applications, conditional branches comparing with constants are
// of great universality. With only conditional branch in current RISC-V ISA, we need to load
// immediate values into registers before branching, which will increase register pressure and
// potentially cause register spills/reloads.

// The Zibi extension defines 2 instructions named BEQI and BNEI. BEQI and BNEI compare a register
// with an immediate, and it takes the branch if registers rs1 and cimm are equal or unequal

enum biop = {BEQI, BNEI}

union clause instruction = BITYPE : (bits(13), bits(5), regidx, biop)

mapping encdec_biop : biop <-> bits(3) = {
  BEQI  <-> 0b010,
  BNEI  <-> 0b011
}

function b_imm5(cimm : bits(5)) =
  if cimm == 0b0 then
    0b11111
  else cimm

mapping clause encdec = BITYPE(imm @ 0b0, cimm, rs1, op)
  <-> imm[11] @ imm[9..4] @ b_imm5(cimm) @ encdec_reg(rs1) @ encdec_biop(op) @ imm[3..0] @ imm[10] @ 0b1100011
  when currentlyEnabled(Ext_Zibi)

$[split op]
function clause execute BITYPE(imm, cimm, rs1, op) = {
  let taken : bool = match op {
    BEQI  => X(rs1) == cimm,
    BNEI  => X(rs1) != cimm
  };
  if taken
  then jump_to(PC + sign_extend(imm))
  else RETIRE_SUCCESS
}


mapping bitype_mnemonic : biop <-> string = {
  BEQI  <-> "beqi",
  BNEI  <-> "bnei"
}

mapping clause assembly = BITYPE(imm, cimm, rs1, op)
  <-> bitype_mnemonic(op) ^ spc() ^ reg_name(rs1) ^ sep() ^ fence_bits(cimm) ^ sep() ^ hex_bits_signed_13(imm)
