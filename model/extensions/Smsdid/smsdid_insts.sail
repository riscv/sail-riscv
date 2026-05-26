// =======================================================================================
// This Sail RISC-V architecture model, comprising all files and
// directories except where not noted, is subject the BSD
// two-clause license in the LICENSE file.
//
// SPDX-License-Identifier: BSD-2-Clause
// =======================================================================================

union clause instruction = MFENCE_PA : (regidx, regidx)

mapping clause encdec = MFENCE_PA(rs1, rs2)
  <-> 0b0011001 @ encdec_reg(rs2) @ encdec_reg(rs1) @ 0b000 @ 0b00000 @ 0b1110011
  when currentlyEnabled(Ext_Smsdid)

function clause execute MFENCE_PA(rs1, rs2) = {
  // MFENCE.PA is only valid in M-mode.
  if cur_privilege != Machine then Illegal_Instruction()
  else {
    // In the Sail model, all memory operations are immediately visible,
    // so MFENCE.PA is implemented as a no-op for functional correctness.
    // A real implementation would flush MPT page-walk caches.
    sail_barrier(Barrier_RISCV_i);
    RETIRE_SUCCESS
  }
}

mapping clause assembly =
  forwards MFENCE_PA(rs1, rs2) => "mfence.pa" ^ spc() ^ reg_name(rs1) ^ sep() ^ reg_name(rs2)

union clause instruction = MINVAL_PA : (regidx, regidx)

mapping clause encdec = MINVAL_PA(rs1, rs2)
  <-> 0b0011011 @ encdec_reg(rs2) @ encdec_reg(rs1) @ 0b000 @ 0b00000 @ 0b1110011
  when currentlyEnabled(Ext_Smsdid) & currentlyEnabled(Ext_Svinval)

function clause execute MINVAL_PA(rs1, rs2) = {
  // MINVAL.PA is only valid in M-mode.
  if cur_privilege != Machine then Illegal_Instruction()
  else {
    // Ordered against SFENCE.W.INVAL and SFENCE.INVAL.IR.
    // In the Sail model, this is a no-op as all memory operations
    // are immediately visible.
    sail_barrier(Barrier_RISCV_i);
    RETIRE_SUCCESS
  }
}

mapping clause assembly =
  forwards MINVAL_PA(rs1, rs2) => "minval.pa" ^ spc() ^ reg_name(rs1) ^ sep() ^ reg_name(rs2)
