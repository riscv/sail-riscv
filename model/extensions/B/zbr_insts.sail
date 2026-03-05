// =======================================================================================
// This Sail RISC-V architecture model, comprising all files and
// directories except where otherwise noted is subject the BSD
// two-clause license in the LICENSE file.
//
// SPDX-License-Identifier: BSD-2-Clause
// =======================================================================================

function clause currentlyEnabled(Ext_Zbr) = hartSupports(Ext_Zbr)

union clause instruction = CRC32_RTYPE : (regidx, regidx, word_width)

$[wavedrom "_ _ _ _ _ OP-IMM"]
mapping clause encdec = CRC32_RTYPE(rs1, rd, 8)
  <-> 0b0110000 @ 0b10011 @ encdec_reg(rs1) @ 0b001 @ encdec_reg(rd) @ 0b0010011
  when currentlyEnabled(Ext_Zbr) & xlen == 64

mapping clause encdec = CRC32_RTYPE(rs1, rd, width)
  <-> 0b0110000 @ 0b100 @ width_enc(width) @ encdec_reg(rs1) @ 0b001 @ encdec_reg(rd) @ 0b0010011
  when currentlyEnabled(Ext_Zbr)

mapping clause assembly = CRC32_RTYPE(rs1, rd, width)
  <-> "crc32." ^ width_mnemonic(width) ^ sep() ^ reg_name(rd) ^ sep() ^ reg_name(rs1)

function clause execute CRC32_RTYPE(rs1, rd, width) = {
  var result = X(rs1);
  let nbits = width * 8;
  foreach (i from 0 to (nbits - 1)) {
    let mask : bits(32) = if (result & zero_extend(0b1)) == zeros() then zeros() else ones();
    result = (result >> 1) ^ zero_extend(0xEDB88320 & mask);
  };
  X(rd) = result;
  RETIRE_SUCCESS
}

union clause instruction = CRC32C_RTYPE : (regidx, regidx, word_width)

$[wavedrom "_ _ _ _ _ OP-IMM"]
mapping clause encdec = CRC32C_RTYPE(rs1, rd, 8)
  <-> 0b0110000 @ 0b11011 @ encdec_reg(rs1) @ 0b001 @ encdec_reg(rd) @ 0b0010011
  when currentlyEnabled(Ext_Zbr) & xlen == 64

mapping clause encdec = CRC32C_RTYPE(rs1, rd, width)
  <-> 0b0110000 @ 0b110 @ width_enc(width) @ encdec_reg(rs1) @ 0b001 @ encdec_reg(rd) @ 0b0010011
  when currentlyEnabled(Ext_Zbr)

mapping clause assembly = CRC32C_RTYPE(rs1, rd, width)
  <-> "crc32c." ^ width_mnemonic(width) ^ sep() ^ reg_name(rd) ^ sep() ^ reg_name(rs1)

function clause execute CRC32C_RTYPE(rs1, rd, width) = {
  var result = X(rs1);
  let nbits = width * 8;
  foreach (i from 0 to (nbits - 1)) {
    let mask : bits(32) = if (result & zero_extend(0b1)) == zeros() then zeros() else ones();
    result = (result >> 1) ^ zero_extend(0x82F63B78 & mask);
  };
  X(rd) = result;
  RETIRE_SUCCESS
}
