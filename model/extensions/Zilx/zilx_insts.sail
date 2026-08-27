// =======================================================================================
// This Sail RISC-V architecture model, comprising all files and
// directories except where otherwise noted is subject the BSD
// two-clause license in the LICENSE file.
//
// SPDX-License-Identifier: BSD-2-Clause
// =======================================================================================

// This file specifies the instructions in the 'Zilx' extension.

function clause currentlyEnabled(Ext_Zilx) = hartSupports(Ext_Zilx)

mapping encdec_zilx_mode : zilx_mode <-> bits(5) = {
  ZILX_UNSCALED  <-> 0b10010,
  ZILX_SCALED    <-> 0b11010,
  ZILX_SCALED_UW <-> 0b11110,
}

private function zilx_encoding_valid(mode : zilx_mode, width : word_width, is_unsigned : bool) -> bool =
  valid_load_encdec(width, is_unsigned) & (mode != ZILX_UNSCALED | width != 1) & (mode != ZILX_SCALED_UW | xlen == 64)

union clause instruction = ZILX_LOAD : (zilx_mode, regidx, regidx, bool, word_width, regidx)

$[wavedrom "mode 0 base index sign width dest AMO"]
mapping clause encdec = ZILX_LOAD(mode, rs2, rs1, is_unsigned, width, rd)
  <-> encdec_zilx_mode(mode) @ 0b00 @ encdec_reg(rs2) @ encdec_reg(rs1) @ bool_bit(is_unsigned) @ width_enc(width) @ encdec_reg(rd) @ 0b0101111
  when currentlyEnabled(Ext_Zilx) & zilx_encoding_valid(mode, width, is_unsigned)

function clause execute ZILX_LOAD(mode, rs2, rs1, is_unsigned, width, rd) = {
  // This is checked during decoding.
  assert(width <= xlen_bytes);

  let index : xlenbits = if mode == ZILX_SCALED_UW then zero_extend(X(rs1)[31 .. 0]) else X(rs1);
  let offset : xlenbits = if mode == ZILX_UNSCALED then index else index << width_enc(width);

  match vmem_read(rs2, offset, width, Load(Data), false, false, false) {
    Ok(data) => {
      X(rd) = extend_value(is_unsigned, data);
      RETIRE_SUCCESS
    },
    Err(e) => e,
  }
}

private mapping zilx_mode_mnemonic : zilx_mode <-> string = {
  ZILX_UNSCALED  <-> "lx",
  ZILX_SCALED    <-> "lxs",
  ZILX_SCALED_UW <-> "lxsuw",
}

mapping clause assembly = ZILX_LOAD(mode, rs2, rs1, is_unsigned, width, rd)
  <-> zilx_mode_mnemonic(mode) ^ width_mnemonic(width) ^ maybe_u(is_unsigned) ^ spc() ^ reg_name(rd) ^ sep() ^ "(" ^ reg_name(rs2) ^ ")" ^ sep() ^ reg_name(rs1)
  when zilx_encoding_valid(mode, width, is_unsigned)
