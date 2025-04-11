/*=======================================================================================*/
/*  This Sail RISC-V architecture model, comprising all files and                        */
/*  directories except where otherwise noted is subject the BSD                          */
/*  two-clause license in the LICENSE file.                                              */
/*                                                                                       */
/*  SPDX-License-Identifier: BSD-2-Clause                                                */
/*=======================================================================================*/

function clause currentlyEnabled(Ext_Zbs) = hartSupports(Ext_Zbs) | currentlyEnabled(Ext_B)

/* ****************************************************************** */
union clause ast = ZBS_IOP : (bits(6), regidx, regidx, biop_zbs)

mapping clause encdec = ZBS_IOP(shamt, rs1, rd, RISCV_BCLRI)
  <-> 0b010010 @ shamt @ encdec_reg(rs1) @ 0b001 @ encdec_reg(rd) @ 0b0010011
  when currentlyEnabled(Ext_Zbs) & (xlen == 64 | shamt[5] == bitzero)

mapping clause encdec = ZBS_IOP(shamt, rs1, rd, RISCV_BEXTI)
  <-> 0b010010 @ shamt @ encdec_reg(rs1) @ 0b101 @ encdec_reg(rd) @ 0b0010011
  when currentlyEnabled(Ext_Zbs) & (xlen == 64 | shamt[5] == bitzero)

mapping clause encdec = ZBS_IOP(shamt, rs1, rd, RISCV_BINVI)
  <-> 0b011010 @ shamt @ encdec_reg(rs1) @ 0b001 @ encdec_reg(rd) @ 0b0010011
  when currentlyEnabled(Ext_Zbs) & (xlen == 64 | shamt[5] == bitzero)

mapping clause encdec = ZBS_IOP(shamt, rs1, rd, RISCV_BSETI)
  <-> 0b001010 @ shamt @ encdec_reg(rs1) @ 0b001 @ encdec_reg(rd) @ 0b0010011
  when currentlyEnabled(Ext_Zbs) & (xlen == 64 | shamt[5] == bitzero)

mapping zbs_iop_mnemonic : biop_zbs <-> string = {
  RISCV_BCLRI <-> "bclri",
  RISCV_BEXTI <-> "bexti",
  RISCV_BINVI <-> "binvi",
  RISCV_BSETI <-> "bseti"
}

mapping clause assembly = ZBS_IOP(shamt, rs1, rd, op)
  <-> zbs_iop_mnemonic(op) ^ spc() ^ reg_name(rd) ^ sep() ^ reg_name(rs1) ^ sep() ^ hex_bits_6(shamt)

function clause execute (ZBS_IOP(shamt, rs1, rd, op)) = {
  let rs1_val = X(rs1);
  let mask : xlenbits = if xlen == 32
                        then zero_extend(0b1) << shamt[4..0]
                        else zero_extend(0b1) << shamt;
  let result : xlenbits = match op {
    RISCV_BCLRI => rs1_val & ~(mask),
    RISCV_BEXTI => zero_extend(bool_to_bits((rs1_val & mask) != zeros())),
    RISCV_BINVI => rs1_val ^ mask,
    RISCV_BSETI => rs1_val | mask
  };
  X(rd) = result;
  RETIRE_SUCCESS
}

/* ****************************************************************** */
union clause ast = ZBS_RTYPE : (regidx, regidx, regidx, brop_zbs)

mapping clause encdec = ZBS_RTYPE(rs2, rs1, rd, RISCV_BCLR)
  <-> 0b0100100 @ encdec_reg(rs2) @ encdec_reg(rs1) @ 0b001 @ encdec_reg(rd) @ 0b0110011
  when currentlyEnabled(Ext_Zbs)

mapping clause encdec = ZBS_RTYPE(rs2, rs1, rd, RISCV_BEXT)
  <-> 0b0100100 @ encdec_reg(rs2) @ encdec_reg(rs1) @ 0b101 @ encdec_reg(rd) @ 0b0110011
  when currentlyEnabled(Ext_Zbs)

mapping clause encdec = ZBS_RTYPE(rs2, rs1, rd, RISCV_BINV)
  <-> 0b0110100 @ encdec_reg(rs2) @ encdec_reg(rs1) @ 0b001 @ encdec_reg(rd) @ 0b0110011
  when currentlyEnabled(Ext_Zbs)

mapping clause encdec = ZBS_RTYPE(rs2, rs1, rd, RISCV_BSET)
  <-> 0b0010100 @ encdec_reg(rs2) @ encdec_reg(rs1) @ 0b001 @ encdec_reg(rd) @ 0b0110011
  when currentlyEnabled(Ext_Zbs)

mapping zbs_rtype_mnemonic : brop_zbs <-> string = {
  RISCV_BCLR    <-> "bclr",
  RISCV_BEXT    <-> "bext",
  RISCV_BINV    <-> "binv",
  RISCV_BSET    <-> "bset"
}

mapping clause assembly = ZBS_RTYPE(rs2, rs1, rd, op)
  <-> zbs_rtype_mnemonic(op) ^ spc() ^ reg_name(rd) ^ sep() ^ reg_name(rs1) ^ sep() ^ reg_name(rs2)

function clause execute (ZBS_RTYPE(rs2, rs1, rd, op)) = {
  let rs1_val = X(rs1);
  let rs2_val = X(rs2);
  let mask : xlenbits = if xlen == 32
                        then zero_extend(0b1) << rs2_val[4..0]
                        else zero_extend(0b1) << rs2_val[5..0];
  let result : xlenbits = match op {
    RISCV_BCLR => rs1_val & ~(mask),
    RISCV_BEXT => zero_extend(bool_to_bits((rs1_val & mask) != zeros())),
    RISCV_BINV => rs1_val ^ mask,
    RISCV_BSET => rs1_val | mask
  };
  X(rd) = result;
  RETIRE_SUCCESS
}
