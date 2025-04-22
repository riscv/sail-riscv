/*=======================================================================================*/
/*  This Sail RISC-V architecture model, comprising all files and                        */
/*  directories except where otherwise noted is subject the BSD                          */
/*  two-clause license in the LICENSE file.                                              */
/*                                                                                       */
/*  SPDX-License-Identifier: BSD-2-Clause                                                */
/*=======================================================================================*/

/* ****************************************************************** */
union clause ast = ZBKB_RTYPE : (regidx, regidx, regidx, brop_zbkb)

mapping clause encdec = ZBKB_RTYPE(rs2, rs1, rd, PACK)
  <-> 0b0000100 @ encdec_reg(rs2) @ encdec_reg(rs1) @ 0b100 @ encdec_reg(rd) @ 0b0110011
  when currentlyEnabled(Ext_Zbkb)

mapping clause encdec = ZBKB_RTYPE(rs2, rs1, rd, PACKH)
  <-> 0b0000100 @ encdec_reg(rs2) @ encdec_reg(rs1) @ 0b111 @ encdec_reg(rd) @ 0b0110011
  when currentlyEnabled(Ext_Zbkb)

mapping zbkb_rtype_mnemonic : brop_zbkb <-> string = {
  PACK  <-> "pack",
  PACKH <-> "packh"
}

mapping clause assembly = ZBKB_RTYPE(rs2, rs1, rd, op)
  <-> zbkb_rtype_mnemonic(op) ^ spc() ^ reg_name(rd) ^ sep() ^ reg_name(rs1) ^ sep() ^ reg_name(rs2)

function clause execute (ZBKB_RTYPE(rs2, rs1, rd, op)) = {
  let rs1_val = X(rs1);
  let rs2_val = X(rs2);
  let result : xlenbits = match op {
    PACK  => rs2_val[(xlen_bytes*4 - 1)..0] @ rs1_val[(xlen_bytes*4 - 1)..0],
    PACKH => zero_extend(rs2_val[7..0] @ rs1_val[7..0])
  };
  X(rd) = result;
  RETIRE_SUCCESS
}

/* ****************************************************************** */
union clause ast = ZBKB_PACKW : (regidx, regidx, regidx)

mapping clause encdec = ZBKB_PACKW(rs2, rs1, rd)
  <-> 0b0000100 @ encdec_reg(rs2) @ encdec_reg(rs1) @ 0b100 @ encdec_reg(rd) @ 0b0111011
  when currentlyEnabled(Ext_Zbkb) & xlen == 64

mapping clause assembly = ZBKB_PACKW(rs2, rs1, rd)
  <-> "packw" ^ spc() ^ reg_name(rd) ^ sep() ^ reg_name(rs1) ^ sep() ^ reg_name(rs2)

function clause execute (ZBKB_PACKW(rs2, rs1, rd)) = {
  assert(xlen == 64);
  let rs1_val = X(rs1);
  let rs2_val = X(rs2);
  let result : bits(32) = rs2_val[15..0] @ rs1_val[15..0];
  X(rd) = sign_extend(result);
  RETIRE_SUCCESS
}

/* ****************************************************************** */
union clause ast = ZIP : (regidx, regidx)

mapping clause encdec = ZIP(rs1, rd)
  <-> 0b000010001111 @ encdec_reg(rs1) @ 0b001 @ encdec_reg(rd) @ 0b0010011
  when currentlyEnabled(Ext_Zbkb) & xlen == 32

mapping clause assembly = ZIP(rs1, rd)
  <-> "zip" ^ spc() ^ reg_name(rd) ^ sep() ^ reg_name(rs1)

function clause execute (ZIP(rs1, rd)) = {
  assert(xlen == 32);
  let rs1_val = X(rs1);
  var result : xlenbits = zeros();
  foreach (i from 0 to (xlen_bytes*4 - 1)) {
    result[i*2] = rs1_val[i];
    result[i*2 + 1] = rs1_val[i + xlen_bytes*4];
  };
  X(rd) = result;
  RETIRE_SUCCESS
}

/* ****************************************************************** */
union clause ast = UNZIP : (regidx, regidx)

mapping clause encdec = UNZIP(rs1, rd)
  <-> 0b000010001111 @ encdec_reg(rs1) @ 0b101 @ encdec_reg(rd) @ 0b0010011
  when currentlyEnabled(Ext_Zbkb) & xlen == 32

mapping clause assembly = UNZIP(rs1, rd)
  <-> "unzip" ^ spc() ^ reg_name(rd) ^ sep() ^ reg_name(rs1)

function clause execute (UNZIP(rs1, rd)) = {
  assert(xlen == 32);
  let rs1_val = X(rs1);
  var result : xlenbits = zeros();
  foreach (i from 0 to (xlen_bytes*4 - 1)) {
    result[i] = rs1_val[i*2];
    result[i + xlen_bytes*4] = rs1_val[i*2 + 1];
  };
  X(rd) = result;
  RETIRE_SUCCESS
}

/* ****************************************************************** */
union clause ast = BREV8 : (regidx, regidx)

mapping clause encdec = BREV8(rs1, rd)
  <-> 0b011010000111 @ encdec_reg(rs1) @ 0b101 @ encdec_reg(rd) @ 0b0010011
  when currentlyEnabled(Ext_Zbkb)

mapping clause assembly = BREV8(rs1, rd)
  <-> "brev8" ^ spc() ^ reg_name(rd) ^ sep() ^ reg_name(rs1)

function clause execute (BREV8(rs1, rd)) = {
  let rs1_val = X(rs1);
  var result : xlenbits = zeros();
  foreach (i from 0 to (xlen - 8) by 8)
    result[i+7..i] = reverse_bits(rs1_val[i+7..i]);
  X(rd) = result;
  RETIRE_SUCCESS
}
