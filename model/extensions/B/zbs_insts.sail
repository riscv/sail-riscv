// =======================================================================================
// This Sail RISC-V architecture model, comprising all files and
// directories except where otherwise noted is subject the BSD
// two-clause license in the LICENSE file.
//
// SPDX-License-Identifier: BSD-2-Clause
// =======================================================================================

function clause currentlyEnabled(Ext_Zbs) = hartSupports(Ext_Zbs) | currentlyEnabled(Ext_B)

// *****************************************************************
union clause instruction = ZBS_IOP : (bits(6), regidx, regidx, biop_zbs)

$[wavedrom "BEXTI/BCLRI _ _ BCLRI _ OP-IMM"]
mapping clause encdec = ZBS_IOP(shamt, rs1, rd, BCLRI)
  <-> 0b010010 @ shamt @ encdec_reg(rs1) @ 0b001 @ encdec_reg(rd) @ 0b0010011
  when currentlyEnabled(Ext_Zbs) & (xlen == 64 | shamt[5] == 0b0)

$[wavedrom "BEXTI/BCLRI _ _ BEXTI _ OP-IMM"]
mapping clause encdec = ZBS_IOP(shamt, rs1, rd, BEXTI)
  <-> 0b010010 @ shamt @ encdec_reg(rs1) @ 0b101 @ encdec_reg(rd) @ 0b0010011
  when currentlyEnabled(Ext_Zbs) & (xlen == 64 | shamt[5] == 0b0)

$[wavedrom "BINVI _ _ BINVI _ OP-IMM"]
mapping clause encdec = ZBS_IOP(shamt, rs1, rd, BINVI)
  <-> 0b011010 @ shamt @ encdec_reg(rs1) @ 0b001 @ encdec_reg(rd) @ 0b0010011
  when currentlyEnabled(Ext_Zbs) & (xlen == 64 | shamt[5] == 0b0)

$[wavedrom "BSETI _ _ BSETI _ OP-IMM"]
mapping clause encdec = ZBS_IOP(shamt, rs1, rd, BSETI)
  <-> 0b001010 @ shamt @ encdec_reg(rs1) @ 0b001 @ encdec_reg(rd) @ 0b0010011
  when currentlyEnabled(Ext_Zbs) & (xlen == 64 | shamt[5] == 0b0)

mapping zbs_iop_mnemonic : biop_zbs <-> string = {
  BCLRI <-> "bclri",
  BEXTI <-> "bexti",
  BINVI <-> "binvi",
  BSETI <-> "bseti"
}

mapping clause assembly = ZBS_IOP(shamt, rs1, rd, op)
  <-> zbs_iop_mnemonic(op) ^ spc() ^ reg_name(rd) ^ sep() ^ reg_name(rs1) ^ sep() ^ hex_bits_6(shamt)

$[split op]
function clause execute ZBS_IOP(shamt, rs1, rd, op) = {
  let rs1_val = X(rs1);
  let mask : xlenbits = if xlen == 32
                        then zero_extend(0b1) << shamt[4..0]
                        else zero_extend(0b1) << shamt;
  let result : xlenbits = match op {
    BCLRI => rs1_val & ~(mask),
    BEXTI => zero_extend(bool_to_bit((rs1_val & mask) != zeros())),
    BINVI => rs1_val ^ mask,
    BSETI => rs1_val | mask
  };
  X(rd) = result;
  RETIRE_SUCCESS
}

// *****************************************************************
union clause instruction = ZBS_RTYPE : (regidx, regidx, regidx, brop_zbs)

$[wavedrom "BCLR/BEXT _ _ BCLR _ OP"]
mapping clause encdec = ZBS_RTYPE(rs2, rs1, rd, BCLR)
  <-> 0b0100100 @ encdec_reg(rs2) @ encdec_reg(rs1) @ 0b001 @ encdec_reg(rd) @ 0b0110011
  when currentlyEnabled(Ext_Zbs)

$[wavedrom "BCLR/BEXT _ _ BEXT _ OP"]
mapping clause encdec = ZBS_RTYPE(rs2, rs1, rd, BEXT)
  <-> 0b0100100 @ encdec_reg(rs2) @ encdec_reg(rs1) @ 0b101 @ encdec_reg(rd) @ 0b0110011
  when currentlyEnabled(Ext_Zbs)

$[wavedrom "BINV _ _ BINV _ OP"]
mapping clause encdec = ZBS_RTYPE(rs2, rs1, rd, BINV)
  <-> 0b0110100 @ encdec_reg(rs2) @ encdec_reg(rs1) @ 0b001 @ encdec_reg(rd) @ 0b0110011
  when currentlyEnabled(Ext_Zbs)

$[wavedrom "BSET _ _ BSET _ OP"]
mapping clause encdec = ZBS_RTYPE(rs2, rs1, rd, BSET)
  <-> 0b0010100 @ encdec_reg(rs2) @ encdec_reg(rs1) @ 0b001 @ encdec_reg(rd) @ 0b0110011
  when currentlyEnabled(Ext_Zbs)

mapping zbs_rtype_mnemonic : brop_zbs <-> string = {
  BCLR    <-> "bclr",
  BEXT    <-> "bext",
  BINV    <-> "binv",
  BSET    <-> "bset"
}

mapping clause assembly = ZBS_RTYPE(rs2, rs1, rd, op)
  <-> zbs_rtype_mnemonic(op) ^ spc() ^ reg_name(rd) ^ sep() ^ reg_name(rs1) ^ sep() ^ reg_name(rs2)

$[split op]
function clause execute ZBS_RTYPE(rs2, rs1, rd, op) = {
  let rs1_val = X(rs1);
  let rs2_val = X(rs2);
  let mask : xlenbits = if xlen == 32
                        then zero_extend(0b1) << rs2_val[4..0]
                        else zero_extend(0b1) << rs2_val[5..0];
  let result : xlenbits = match op {
    BCLR => rs1_val & ~(mask),
    BEXT => zero_extend(bool_to_bit((rs1_val & mask) != zeros())),
    BINV => rs1_val ^ mask,
    BSET => rs1_val | mask
  };
  X(rd) = result;
  RETIRE_SUCCESS
}
