// =======================================================================================
// This Sail RISC-V architecture model, comprising all files and
// directories except where otherwise noted is subject the BSD
// two-clause license in the LICENSE file.
//
// SPDX-License-Identifier: BSD-2-Clause
// =======================================================================================

// P is unratified: it needs the experimental-extensions flag and its config knob
// (see hartSupports in core/extensions.sail), and, like M/B/V, its misa bit.
function clause currentlyEnabled(Ext_P) = hartSupports(Ext_P) & misa[P] == 0b1

// ******************************************************************************
// This file implements part of the pack extension.
// ******************************************************************************

// *********************************** P MISC ***********************************
union clause instruction = PMISC : (pmiscfunct7, regidx, regidx)

mapping encdec_pmiscfunct7 : pmiscfunct7 <-> bits(7) = {
  CLS <-> 0b0000011,
  ABS <-> 0b0000111,
}

mapping clause encdec = PMISC(funct7, rs1, rd)
  <-> 0b01100 @ encdec_pmiscfunct7(funct7) @ encdec_reg(rs1) @ 0b001 @ encdec_reg(rd) @ 0b0010011
  when currentlyEnabled(Ext_P)

function clause execute (PMISC(funct7, rs1, rd)) = {
  match funct7 {
    CLS => X(rd) = to_bits(count_leading_sign_bits(X(rs1))),
    ABS => X(rd) = abs(X(rs1)),
  };
  RETIRE_SUCCESS
}

mapping pmisc_mnemonic : pmiscfunct7 <-> string = {
  CLS <-> "cls",
  ABS <-> "abs",
}

mapping clause assembly = PMISC(funct7, rs1, rd)
  <-> pmisc_mnemonic(funct7) ^ spc() ^ reg_name(rd) ^ sep() ^ reg_name(rs1)
  when currentlyEnabled(Ext_P)

// ******************************** P REV, REV16 ********************************
union clause instruction = PREV : (regidx, regidx)

// The immediate encodes the reversal span (XLEN-1), so RV32 and RV64 differ
// in bit 25; funct3 is 0b101 per draft 020.
mapping clause encdec = PREV(rs1, rd)
  <-> 0b011010011111 @ encdec_reg(rs1) @ 0b101 @ encdec_reg(rd) @ 0b0010011
  when currentlyEnabled(Ext_P) & xlen == 32

mapping clause encdec = PREV(rs1, rd)
  <-> 0b011010111111 @ encdec_reg(rs1) @ 0b101 @ encdec_reg(rd) @ 0b0010011
  when currentlyEnabled(Ext_P) & xlen == 64

function clause execute (PREV(rs1, rd)) = {
  let rs1_val = X(rs1);
  var result : xlenbits = zeros();
  foreach (i from 0 to (sizeof(xlen) - 1))
    result[i] = rs1_val[(sizeof(xlen) - i - 1)];
  X(rd) = result;
  RETIRE_SUCCESS
}

mapping clause assembly = PREV(rs1, rd)
  <-> "rev" ^ spc() ^ reg_name(rd) ^ sep() ^ reg_name(rs1)
  when currentlyEnabled(Ext_P)

// *************************** P SHIFT IMMEDIATE BYTE ***************************
union clause instruction = PSHIFTIB : (pshiftibfunct3, bits(3), regidx, regidx)

mapping encdec_pshiftibfunct3 : pshiftibfunct3 <-> bits(3) = {
  PSLLI_B <-> 0b000,
}

mapping clause encdec = PSHIFTIB(funct3, imm3, rs1, rd)
  <-> 0b1 @ encdec_pshiftibfunct3(funct3) @ 0b0 @ 0b0001 @ imm3 @ encdec_reg(rs1) @ 0b010 @ encdec_reg(rd) @ 0b0011011
  when currentlyEnabled(Ext_P)

function clause execute (PSHIFTIB(funct3, imm3, rs1, rd)) = {
  let rs1_val = X(rs1);
  let sa : bits(8) = zero_extend(imm3);
  var result : xlenbits = zeros();
  foreach (i from 0 to (sizeof(xlen) - 8) by 8) {
    let rs1_byte = slice(rs1_val, i, 8);
    result[(i+7)..i] = match funct3 {
      PSLLI_B => shift_bits_left(rs1_byte, sa),
    };
  };
  X(rd) = result;
  RETIRE_SUCCESS
}

mapping pshiftib_mnemonic : pshiftibfunct3 <-> string = {
  PSLLI_B <-> "pslli.b"
}

mapping clause assembly = PSHIFTIB(funct3, imm3, rs1, rd)
  <-> pshiftib_mnemonic(funct3) ^ spc() ^ reg_name(rd) ^ sep() ^ reg_name(rs1) ^ sep() ^ hex_bits_3(imm3)
  when currentlyEnabled(Ext_P)

// ************************* P SHIFT IMMEDIATE HALFWORD *************************
union clause instruction = PSHIFTIH : (pshiftihfunct3, bits(4), regidx, regidx)

mapping encdec_pshiftihfunct3 : pshiftihfunct3 <-> bits(3) = {
  PSLLI_H <-> 0b000,
  PSSLAI_H <-> 0b101,
}

mapping clause encdec = PSHIFTIH(funct3, imm4, rs1, rd)
  <-> 0b1 @ encdec_pshiftihfunct3(funct3) @ 0b0 @ 0b001 @ imm4 @ encdec_reg(rs1) @ 0b010 @ encdec_reg(rd) @ 0b0011011
  when currentlyEnabled(Ext_P)

function clause execute (PSHIFTIH(funct3, imm4, rs1, rd)) = {
  let rs1_val = X(rs1);
  let shamt : nat = unsigned(imm4);
  var result : xlenbits = zeros();
  foreach (i from 0 to (sizeof(xlen) - 16) by 16) {
    let rs1_halfword = slice(rs1_val, i, 16);
    result[(i+15)..i] = match funct3 {
      PSLLI_H => rs1_halfword << shamt,
      PSSLAI_H => sat_shift_left_arith(rs1_halfword, shamt),
    };
  };
  X(rd) = result;
  RETIRE_SUCCESS
}

mapping pshiftih_mnemonic : pshiftihfunct3 <-> string = {
  PSLLI_H <-> "pslli.h",
  PSSLAI_H <-> "psslai.h",
}

mapping clause assembly = PSHIFTIH(funct3, imm4, rs1, rd)
  <-> pshiftih_mnemonic(funct3) ^ spc() ^ reg_name(rd) ^ sep() ^ reg_name(rs1) ^ sep() ^ hex_bits_4(imm4)
  when currentlyEnabled(Ext_P)

// ************************* P LOAD IMMEDIATE HALFWORD **************************
union clause instruction = PLI_H : (bits(10), regidx)

mapping clause encdec = PLI_H(imm10, rd) <->
  0b10110 @ 0b00 @ imm10 @ 0b010 @ encdec_reg(rd) @ 0b0011011
  when currentlyEnabled(Ext_P)

function clause execute (PLI_H(imm10, rd)) = {
  var result : xlenbits = zeros();
  foreach (i from 0 to (sizeof(xlen) - 16) by 16) {
    result[(i+15)..i] = sign_extend(imm10[0]) @ imm10[9..1];
  };
  X(rd) = result;
  RETIRE_SUCCESS
}

mapping clause assembly = PLI_H(imm10, rd)
  <-> "pli.h" ^ spc() ^ reg_name(rd) ^ sep() ^ hex_bits_10(imm10[0] @ imm10[9..1])
  when currentlyEnabled(Ext_P)

// *************************** P LOAD IMMEDIATE BYTE ****************************
union clause instruction = PLI_B : (bits(8), regidx)

mapping clause encdec = PLI_B(imm8, rd) <->
  0b10110 @ 0b100 @ imm8 @ 0b0010 @ encdec_reg(rd) @ 0b0011011
  when currentlyEnabled(Ext_P)

function clause execute (PLI_B(imm8, rd)) = {
  var result : xlenbits = zeros();
  foreach (i from 0 to (sizeof(xlen) - 8) by 8) {
    result[(i+7)..i] = imm8;
  };
  X(rd) = result;
  RETIRE_SUCCESS
}

mapping clause assembly = PLI_B(imm8, rd)
  <-> "pli.b" ^ spc() ^ reg_name(rd) ^ sep() ^ hex_bits_8(imm8)
  when currentlyEnabled(Ext_P)

// ************************ P SIGNED EXTENSION HALFWORD *************************
union clause instruction = PSEXT_H_B : (regidx, regidx)

mapping clause encdec = PSEXT_H_B(rs1, rd) <->
  0b11100 @ 0b00 @ 0b00100 @ encdec_reg(rs1) @ 0b010 @ encdec_reg(rd) @ 0b0011011
  when currentlyEnabled(Ext_P)

function clause execute (PSEXT_H_B(rs1, rd)) = {
  let rs1_val = X(rs1);
  var result : xlenbits = zeros();
  foreach (i from 0 to (sizeof(xlen) - 16) by 16) {
    result[(i+15)..i] = sign_extend(rs1_val[(i+7)..i]);
  };
  X(rd) = result;
  RETIRE_SUCCESS
}

mapping clause assembly = PSEXT_H_B(rs1, rd)
  <-> "psext.h.b" ^ spc() ^ reg_name(rd) ^ sep() ^ reg_name(rs1)
  when currentlyEnabled(Ext_P)

// ****************************** P SATURATING ABS ******************************
union clause instruction = PSABS : (psabswidth2, regidx, regidx)

mapping encdec_psabswidth2 : psabswidth2 <-> bits(2) = {
  PSABS_B <-> 0b10,
  PSABS_H <-> 0b00,
}

mapping clause encdec = PSABS(width2, rs1, rd)
  <-> 0b11100 @ encdec_psabswidth2(width2) @ 0b00111 @ encdec_reg(rs1) @ 0b010 @ encdec_reg(rd) @ 0b0011011
  when currentlyEnabled(Ext_P)

function clause execute (PSABS(width2, rs1, rd)) = {
  let rs1_val = X(rs1);
  var result : xlenbits = zeros();
  match width2 {
    PSABS_B => {
      foreach (i from 0 to (sizeof(xlen) - 8) by 8) {
        let rs1_byte = slice(rs1_val, i, 8);
        result[(i+7)..i] = sabs(rs1_byte)
      };
    },
    PSABS_H => {
      foreach (i from 0 to (sizeof(xlen) - 16) by 16) {
        let rs1_halfword = slice(rs1_val, i, 16);
        result[(i+15)..i] = sabs(rs1_halfword)
      };
    },
  };
  X(rd) = result;
  RETIRE_SUCCESS
}

mapping psabs_mnemonic : psabswidth2 <-> string = {
  PSABS_B <-> "psabs.b",
  PSABS_H <-> "psabs.h",
}

mapping clause assembly = PSABS(width2, rs1, rd)
  <-> psabs_mnemonic(width2) ^ spc() ^ reg_name(rd) ^ sep() ^ reg_name(rs1)
  when currentlyEnabled(Ext_P)

// ********************** P LOAD UPPER IMMEDIATE HALFWORD ***********************
union clause instruction = PLUI_H : (bits(10), regidx)

mapping clause encdec = PLUI_H(imm10, rd) <->
  0b11110 @ 0b00 @ imm10 @ 0b010 @ encdec_reg(rd) @ 0b0011011
  when currentlyEnabled(Ext_P)

function clause execute (PLUI_H(imm10, rd)) = {
  var result : xlenbits = zeros();
  foreach (i from 0 to (sizeof(xlen) - 16) by 16) {
    result[(i+15)..i] = imm10[8..0] @ imm10[9] @ sail_zeros(6);
  };
  X(rd) = result;
  RETIRE_SUCCESS
}

mapping clause assembly = PLUI_H(imm10, rd)
  <-> "plui.h" ^ spc() ^ reg_name(rd) ^ sep() ^ hex_bits_10(imm10[8..0] @ imm10[9])
  when currentlyEnabled(Ext_P)

// ***************************** P ALU BYTE SCALAR ******************************
union clause instruction = PALUBSCALAR : (palubscalarfunct3, regidx, regidx, regidx)

mapping encdec_palubscalarfunct3 : palubscalarfunct3 <-> bits(3) = {
  PSLL_BS <-> 0b000,
  PADD_BS <-> 0b001,
}

mapping clause encdec = PALUBSCALAR(funct3, rs1, rs2, rd) <->
  0b1 @ encdec_palubscalarfunct3(funct3) @ 0b1 @ 0b10 @ encdec_reg(rs2) @ encdec_reg(rs1) @ 0b010 @ encdec_reg(rd) @ 0b0011011
  when currentlyEnabled(Ext_P)

function clause execute (PALUBSCALAR(funct3, rs1, rs2, rd)) = {
  let rs1_val = X(rs1);
  let rs2_val = X(rs2);
  var result : xlenbits = zeros();
  foreach (i from 0 to (sizeof(xlen) - 8) by 8) {
    result[(i+7)..i] = match funct3 {
      PSLL_BS => shift_bits_left(rs1_val[(i+7)..i], rs2_val[4..0]),
      PADD_BS => rs1_val[(i+7)..i] + rs2_val[7..0],
    };
  };
  X(rd) = result;
  RETIRE_SUCCESS
}

mapping palubscalar_mnemonic : palubscalarfunct3 <-> string = {
  PSLL_BS <-> "psll.bs",
  PADD_BS <-> "padd.bs",
}

mapping clause assembly = PALUBSCALAR(funct3, rs1, rs2, rd)
  <-> palubscalar_mnemonic(funct3) ^ spc() ^ reg_name(rd) ^ sep() ^ reg_name(rs1) ^ sep() ^ reg_name(rs2)
  when currentlyEnabled(Ext_P)

// *************************** P ALU HALFWORD SCALAR ****************************
union clause instruction = PALUHSCALAR : (paluhscalarfunct3, regidx, regidx, regidx)

mapping encdec_paluhscalarfunct3 : paluhscalarfunct3 <-> bits(3) = {
  PSLL_HS <-> 0b000,
  PADD_HS <-> 0b001,
  PSSHL_HS <-> 0b010,
  PSSHLR_HS <-> 0b011,
  PSSHA_HS <-> 0b110,
  PSSHAR_HS <-> 0b111,
}

mapping clause encdec = PALUHSCALAR(funct3, rs1, rs2, rd) <->
  0b1 @ encdec_paluhscalarfunct3(funct3) @ 0b1 @ 0b00 @ encdec_reg(rs2) @ encdec_reg(rs1) @ 0b010 @ encdec_reg(rd) @ 0b0011011
  when currentlyEnabled(Ext_P)

function clause execute (PALUHSCALAR(funct3, rs1, rs2, rd)) = {
  let rs1_val = X(rs1);
  let rs2_val = X(rs2);
  var result : xlenbits = zeros();
  foreach (i from 0 to (sizeof(xlen) - 16) by 16) {
    result[(i+15)..i] = match funct3 {
      PSLL_HS => shift_bits_left(rs1_val[(i+15)..i], rs2_val[4..0]),
      PADD_HS => rs1_val[(i+15)..i] + rs2_val[15..0],
      PSSHL_HS => sshl(rs1_val[(i+15)..i], signed(rs2_val[7..0])),
      PSSHLR_HS => sshlr(rs1_val[(i+15)..i], signed(rs2_val[7..0])),
      PSSHA_HS => ssha(rs1_val[(i+15)..i], signed(rs2_val[7..0])),
      PSSHAR_HS => sshar(rs1_val[(i+15)..i], signed(rs2_val[7..0])),
    };
  };
  X(rd) = result;
  RETIRE_SUCCESS
}

mapping paluhscalar_mnemonic : paluhscalarfunct3 <-> string = {
  PSLL_HS <-> "psll.hs",
  PADD_HS <-> "padd.hs",
  PSSHL_HS <-> "psshl.hs",
  PSSHLR_HS <-> "psshlr.hs",
  PSSHA_HS <-> "pssha.hs",
  PSSHAR_HS <-> "psshar.hs",
}

mapping clause assembly = PALUHSCALAR(funct3, rs1, rs2, rd)
  <-> paluhscalar_mnemonic(funct3) ^ spc() ^ reg_name(rd) ^ sep() ^ reg_name(rs1) ^ sep() ^ reg_name(rs2)
  when currentlyEnabled(Ext_P)

// ********************** P SHIFT SATURATE BYTE IMMEDIATE ***********************
union clause instruction = PSHIFTSATIB : (pshiftsatibfunct3, bits(3), regidx, regidx)

mapping encdec_pshiftsatibfunct3 : pshiftsatibfunct3 <-> bits(3) = {
  PSRLI_B <-> 0b000,
  PSRAI_B <-> 0b100,
}

mapping clause encdec = PSHIFTSATIB(funct3, imm3, rs1, rd)
  <-> 0b1 @ encdec_pshiftsatibfunct3(funct3) @ 0b0 @ 0b0001 @ imm3 @ encdec_reg(rs1) @ 0b100 @ encdec_reg(rd) @ 0b0011011
  when currentlyEnabled(Ext_P)

function clause execute (PSHIFTSATIB(funct3, imm3, rs1, rd)) = {
  let rs1_val = X(rs1);
  let sa : nat = unsigned(imm3);
  var result : xlenbits = zeros();
  foreach (i from 0 to (sizeof(xlen) - 8) by 8) {
    let rs1_byte = slice(rs1_val, i, 8);
    result[(i+7)..i] = match funct3 {
      PSRLI_B => rs1_byte >> sa,
      PSRAI_B => shift_right_arith(rs1_byte, sa),
    };
  };
  X(rd) = result;
  RETIRE_SUCCESS
}

mapping pshiftsatib_mnemonic : pshiftsatibfunct3 <-> string = {
  PSRLI_B <-> "psrli.b",
  PSRAI_B <-> "psrai.b",
}

mapping clause assembly = PSHIFTSATIB(funct3, imm3, rs1, rd)
  <-> pshiftsatib_mnemonic(funct3) ^ spc() ^ reg_name(rd) ^ sep() ^ reg_name(rs1) ^ sep() ^ hex_bits_3(imm3)
  when currentlyEnabled(Ext_P)

// ******************** P SHIFT SATURATE IMMEDIATE HALFWORD *********************
union clause instruction = PSHIFTSATIH : (pshiftsatihfunct3, bits(4), regidx, regidx)

mapping encdec_pshiftsatihfunct3 : pshiftsatihfunct3 <-> bits(3) = {
  PSRLI_H <-> 0b000,
  PUSATI_H <-> 0b010,
  PSRAI_H <-> 0b100,
  PSRARI_H <-> 0b101,
  PSATI_H <-> 0b110,
}

mapping clause encdec = PSHIFTSATIH(funct3, imm4, rs1, rd)
  <-> 0b1 @ encdec_pshiftsatihfunct3(funct3) @ 0b0 @ 0b001 @ imm4 @ encdec_reg(rs1) @ 0b100 @ encdec_reg(rd) @ 0b0011011
  when currentlyEnabled(Ext_P)

function clause execute (PSHIFTSATIH(funct3, imm4, rs1, rd)) = {
  let rs1_val = X(rs1);
  let shamt : nat = unsigned(imm4);
  var result : xlenbits = zeros();
  foreach (i from 0 to (sizeof(xlen) - 16) by 16) {
    let rs1_halfword = slice(rs1_val, i, 16);
    result[(i+15)..i] = match funct3 {
      PSRLI_H => rs1_halfword >> shamt,
      PUSATI_H =>
        let maxval : bits(16) = ~(0xFFFF << shamt) in
        if (rs1_halfword <_s 0x0000) then { write_vxsat(0b1); 0x0000 }
        else if (rs1_halfword >_s maxval) then { write_vxsat(0b1); maxval } else rs1_halfword,
      PSRAI_H => shift_right_arith(rs1_halfword, shamt),
      PSRARI_H => shift_right_arith_rounding(rs1_halfword, shamt),
      PSATI_H =>
        let minval : bits(16) = 0xFFFF << shamt in
        let maxval = ~(minval) in
        if (rs1_halfword <_s minval) then { write_vxsat(0b1); minval }
        else if (rs1_halfword >_s maxval) then { write_vxsat(0b1); maxval } else rs1_halfword,
    };
  };
  X(rd) = result;
  RETIRE_SUCCESS
}

mapping pshiftsatih_mnemonic : pshiftsatihfunct3 <-> string = {
  PSRLI_H <-> "psrli.h",
  PUSATI_H <-> "pusati.h",
  PSRAI_H <-> "psrai.h",
  PSRARI_H <-> "psrari.h",
  PSATI_H <-> "psati.h",
}

mapping clause assembly = PSHIFTSATIH(funct3, imm4, rs1, rd)
  <-> pshiftsatih_mnemonic(funct3) ^ spc() ^ reg_name(rd) ^ sep() ^ reg_name(rs1) ^ sep() ^ hex_bits_4(imm4)
  when currentlyEnabled(Ext_P)

// **************************** P SHIFT BYTE SCALAR *****************************
union clause instruction = PSHIFTBSCALAR : (pshiftbscalarfunct3, regidx, regidx, regidx)

mapping encdec_pshiftbscalarfunct3 : pshiftbscalarfunct3 <-> bits(3) = {
  PSRL_BS <-> 0b000,
  PSRA_BS <-> 0b100,
}

mapping clause encdec = PSHIFTBSCALAR(funct3, rs1, rs2, rd) <->
  0b1 @ encdec_pshiftbscalarfunct3(funct3) @ 0b1 @ 0b10 @ encdec_reg(rs2) @ encdec_reg(rs1) @ 0b100 @ encdec_reg(rd) @ 0b0011011
  when currentlyEnabled(Ext_P)

function clause execute (PSHIFTBSCALAR(funct3, rs1, rs2, rd)) = {
  let rs1_val = X(rs1);
  let rs2_val = X(rs2);
  var result : xlenbits = zeros();
  foreach (i from 0 to (sizeof(xlen) - 8) by 8) {
    let rs1_byte = slice(rs1_val, i, 8);
    result[(i+7)..i] = match funct3 {
      PSRL_BS => rs1_byte >> rs2_val[4..0],
      PSRA_BS => shift_right_arith(rs1_byte, unsigned(rs2_val[4..0])),
    };
  };
  X(rd) = result;
  RETIRE_SUCCESS
}

mapping pshiftbscalar_mnemonic : pshiftbscalarfunct3 <-> string = {
  PSRL_BS <-> "psrl.bs",
  PSRA_BS <-> "psra.bs",
}

mapping clause assembly = PSHIFTBSCALAR(funct3, rs1, rs2, rd)
  <-> pshiftbscalar_mnemonic(funct3) ^ spc() ^ reg_name(rd) ^ sep() ^ reg_name(rs1) ^ sep() ^ reg_name(rs2)
  when currentlyEnabled(Ext_P)

// ************************** P SHIFT HALFWORD SCALAR ***************************
union clause instruction = PSHIFTHSCALAR : (pshifthscalarfunct3, regidx, regidx, regidx)

mapping encdec_pshifthscalarfunct3 : pshifthscalarfunct3 <-> bits(3) = {
  PSRL_HS <-> 0b000,
  PSRA_HS <-> 0b100,
}

mapping clause encdec = PSHIFTHSCALAR(funct3, rs1, rs2, rd) <->
  0b1 @ encdec_pshifthscalarfunct3(funct3) @ 0b1 @ 0b00 @ encdec_reg(rs2) @ encdec_reg(rs1) @ 0b100 @ encdec_reg(rd) @ 0b0011011
  when currentlyEnabled(Ext_P)

function clause execute (PSHIFTHSCALAR(funct3, rs1, rs2, rd)) = {
  let rs1_val = X(rs1);
  let rs2_val = X(rs2);
  var result : xlenbits = zeros();
  foreach (i from 0 to (sizeof(xlen) - 16) by 16) {
    let rs1_halfword = slice(rs1_val, i, 16);
    result[(i+15)..i] = match funct3 {
      PSRL_HS => rs1_halfword >> rs2_val[4..0],
      PSRA_HS => shift_right_arith(rs1_halfword, unsigned(rs2_val[4..0])),
    };
  };
  X(rd) = result;
  RETIRE_SUCCESS
}

mapping pshifthscalar_mnemonic : pshifthscalarfunct3 <-> string = {
  PSRL_HS <-> "psrl.hs",
  PSRA_HS <-> "psra.hs",
}

mapping clause assembly = PSHIFTHSCALAR(funct3, rs1, rs2, rd)
  <-> pshifthscalar_mnemonic(funct3) ^ spc() ^ reg_name(rd) ^ sep() ^ reg_name(rs1) ^ sep() ^ reg_name(rs2)
  when currentlyEnabled(Ext_P)

// ************************ P REDUCTION SUM BYTE SCALAR *************************
union clause instruction = PREDSUMBSCALAR : (predsumbscalarfunct3, regidx, regidx, regidx)

mapping encdec_predsumbscalarfunct3 : predsumbscalarfunct3 <-> bits(3) = {
  PREDSUM_BS <-> 0b001,
  PREDSUMU_BS <-> 0b011,
}

mapping clause encdec = PREDSUMBSCALAR(funct3, rs1, rs2, rd) <->
  0b1 @ encdec_predsumbscalarfunct3(funct3) @ 0b1 @ 0b10 @ encdec_reg(rs2) @ encdec_reg(rs1) @ 0b100 @ encdec_reg(rd) @ 0b0011011
  when currentlyEnabled(Ext_P)

function clause execute (PREDSUMBSCALAR(funct3, rs1, rs2, rd)) = {
  let rs1_val = X(rs1);
  let rs2_val = X(rs2);
  var result : xlenbits = rs2_val;
  foreach (i from 0 to (sizeof(xlen) - 8) by 8) {
    let rs1_byte = slice(rs1_val, i, 8);
    result = match funct3 {
      PREDSUM_BS => result + sign_extend(rs1_byte),
      PREDSUMU_BS => result + zero_extend(rs1_byte),
    };
  };
  X(rd) = result;
  RETIRE_SUCCESS
}

mapping predsumbscalar_mnemonic : predsumbscalarfunct3 <-> string = {
  PREDSUM_BS <-> "predsum.bs",
  PREDSUMU_BS <-> "predsumu.bs",
}

mapping clause assembly = PREDSUMBSCALAR(funct3, rs1, rs2, rd)
  <-> predsumbscalar_mnemonic(funct3) ^ spc() ^ reg_name(rd) ^ sep() ^ reg_name(rs1) ^ sep() ^ reg_name(rs2)
  when currentlyEnabled(Ext_P)

// ********************** P REDUCTION SUM HALFWORD SCALAR ***********************
union clause instruction = PREDSUMHSCALAR : (predsumhscalarfunct3, regidx, regidx, regidx)

mapping encdec_predsumhscalarfunct3 : predsumhscalarfunct3 <-> bits(3) = {
  PREDSUM_HS <-> 0b001,
  PREDSUMU_HS <-> 0b011,
}

mapping clause encdec = PREDSUMHSCALAR(funct3, rs1, rs2, rd) <->
  0b1 @ encdec_predsumhscalarfunct3(funct3) @ 0b1 @ 0b00 @ encdec_reg(rs2) @ encdec_reg(rs1) @ 0b100 @ encdec_reg(rd) @ 0b0011011
  when currentlyEnabled(Ext_P)

function clause execute (PREDSUMHSCALAR(funct3, rs1, rs2, rd)) = {
  let rs1_val = X(rs1);
  let rs2_val = X(rs2);
  var result : xlenbits = rs2_val;
  foreach (i from 0 to (sizeof(xlen) - 16) by 16) {
    let rs1_halfword = slice(rs1_val, i, 16);
    result = match funct3 {
      PREDSUM_HS => result + sign_extend(rs1_halfword),
      PREDSUMU_HS => result + zero_extend(rs1_halfword),
    };
  };
  X(rd) = result;
  RETIRE_SUCCESS
}

mapping predsumhscalar_mnemonic : predsumhscalarfunct3 <-> string = {
  PREDSUM_HS <-> "predsum.hs",
  PREDSUMU_HS <-> "predsumu.hs",
}

mapping clause assembly = PREDSUMHSCALAR(funct3, rs1, rs2, rd)
  <-> predsumhscalar_mnemonic(funct3) ^ spc() ^ reg_name(rd) ^ sep() ^ reg_name(rs1) ^ sep() ^ reg_name(rs2)
  when currentlyEnabled(Ext_P)

// ********************************* P ALU BYTE *********************************
union clause instruction = PALUB : (palubfunct4, regidx, regidx, regidx)

mapping encdec_palubfunct4 : palubfunct4 <-> bits(4) = {
  PADD_B <-> 0b0000,
  PSADD_B <-> 0b0010,
  PAADD_B <-> 0b0011,
  PSADDU_B <-> 0b0110,
  PAADDU_B <-> 0b0111,
  PSUB_B <-> 0b1000,
  PABD_B <-> 0b1001,
  PSSUB_B <-> 0b1010,
  PASUB_B <-> 0b1011,
  PABDU_B <-> 0b1101,
  PSSUBU_B <-> 0b1110,
  PASUBU_B <-> 0b1111,
}

mapping clause encdec = PALUB(funct4, rs1, rs2, rd) <->
  0b1 @ encdec_palubfunct4(funct4) @ 0b10 @ encdec_reg(rs2) @ encdec_reg(rs1) @ 0b000 @ encdec_reg(rd) @ 0b0111011
  when currentlyEnabled(Ext_P)

function clause execute (PALUB(funct4, rs1, rs2, rd)) = {
  let rs1_val = X(rs1);
  let rs2_val = X(rs2);
  var result : xlenbits = rs2_val;
  foreach (i from 0 to (sizeof(xlen) - 8) by 8) {
    let rs1_byte = slice(rs1_val, i, 8);
    let rs2_byte = slice(rs2_val, i, 8);
    result[(i+7)..i] = match funct4 {
      PADD_B => rs1_byte + rs2_byte,
      PSADD_B => sadd(rs1_byte, rs2_byte),
      PAADD_B => aadd(rs1_byte, rs2_byte),
      PSADDU_B => saddu(rs1_byte, rs2_byte),
      PAADDU_B => aaddu(rs1_byte, rs2_byte),
      PSUB_B => rs1_byte - rs2_byte,
      PABD_B => if rs1_byte <_s rs2_byte then rs2_byte - rs1_byte else rs1_byte - rs2_byte,
      PSSUB_B => ssub(rs1_byte, rs2_byte),
      PASUB_B => asub(rs1_byte, rs2_byte),
      PABDU_B => if rs1_byte <_u rs2_byte then rs2_byte - rs1_byte else rs1_byte - rs2_byte,
      PSSUBU_B => ssubu(rs1_byte, rs2_byte),
      PASUBU_B => asubu(rs1_byte, rs2_byte),
    };
  };
  X(rd) = result;
  RETIRE_SUCCESS
}

mapping palub_mnemonic : palubfunct4 <-> string = {
  PADD_B <-> "padd.b",
  PSADD_B <-> "psadd.b",
  PAADD_B <-> "paadd.b",
  PSADDU_B <-> "psaddu.b",
  PAADDU_B <-> "paaddu.b",
  PSUB_B <-> "psub.b",
  PABD_B <-> "pabd.b",
  PSSUB_B <-> "pssub.b",
  PASUB_B <-> "pasub.b",
  PABDU_B <-> "pabdu.b",
  PSSUBU_B <-> "pssubu.b",
  PASUBU_B <-> "pasubu.b",
}

mapping clause assembly = PALUB(funct4, rs1, rs2, rd)
  <-> palub_mnemonic(funct4) ^ spc() ^ reg_name(rd) ^ sep() ^ reg_name(rs1) ^ sep() ^ reg_name(rs2)
  when currentlyEnabled(Ext_P)

// ******************************* P ALU HALFWORD *******************************
union clause instruction = PALUH : (paluhfunct4, regidx, regidx, regidx)

mapping encdec_paluhfunct4 : paluhfunct4 <-> bits(4) = {
  PADD_H <-> 0b0000,
  PSADD_H <-> 0b0010,
  PAADD_H <-> 0b0011,
  PSADDU_H <-> 0b0110,
  PAADDU_H <-> 0b0111,
  PSUB_H <-> 0b1000,
  PABD_H <-> 0b1001,
  PSSUB_H <-> 0b1010,
  PASUB_H <-> 0b1011,
  PABDU_H <-> 0b1101,
  PSSUBU_H <-> 0b1110,
  PASUBU_H <-> 0b1111,
}

mapping clause encdec = PALUH(funct4, rs1, rs2, rd) <->
  0b1 @ encdec_paluhfunct4(funct4) @ 0b00 @ encdec_reg(rs2) @ encdec_reg(rs1) @ 0b000 @ encdec_reg(rd) @ 0b0111011
  when currentlyEnabled(Ext_P)

function clause execute (PALUH(funct4, rs1, rs2, rd)) = {
  let rs1_val = X(rs1);
  let rs2_val = X(rs2);
  var result : xlenbits = rs2_val;
  foreach (i from 0 to (sizeof(xlen) - 16) by 16) {
    let rs1_halfword = slice(rs1_val, i, 16);
    let rs2_halfword = slice(rs2_val, i, 16);
    result[(i+15)..i] = match funct4 {
      PADD_H => rs1_halfword + rs2_halfword,
      PSADD_H => sadd(rs1_halfword, rs2_halfword),
      PAADD_H => aadd(rs1_halfword, rs2_halfword),
      PSADDU_H => saddu(rs1_halfword, rs2_halfword),
      PAADDU_H => aaddu(rs1_halfword, rs2_halfword),
      PSUB_H => rs1_halfword - rs2_halfword,
      PABD_H => if rs1_halfword <_s rs2_halfword then rs2_halfword - rs1_halfword else rs1_halfword - rs2_halfword,
      PSSUB_H => ssub(rs1_halfword, rs2_halfword),
      PASUB_H => asub(rs1_halfword, rs2_halfword),
      PABDU_H => if rs1_halfword <_u rs2_halfword then rs2_halfword - rs1_halfword else rs1_halfword - rs2_halfword,
      PSSUBU_H => ssubu(rs1_halfword, rs2_halfword),
      PASUBU_H => asubu(rs1_halfword, rs2_halfword),
    };
  };
  X(rd) = result;
  RETIRE_SUCCESS
}

mapping paluh_mnemonic : paluhfunct4 <-> string = {
  PADD_H <-> "padd.h",
  PSADD_H <-> "psadd.h",
  PAADD_H <-> "paadd.h",
  PSADDU_H <-> "psaddu.h",
  PAADDU_H <-> "paaddu.h",
  PSUB_H <-> "psub.h",
  PABD_H <-> "pabd.h",
  PSSUB_H <-> "pssub.h",
  PASUB_H <-> "pasub.h",
  PABDU_H <-> "pabdu.h",
  PSSUBU_H <-> "pssubu.h",
  PASUBU_H <-> "pasubu.h",
}

mapping clause assembly = PALUH(funct4, rs1, rs2, rd)
  <-> paluh_mnemonic(funct4) ^ spc() ^ reg_name(rd) ^ sep() ^ reg_name(rs1) ^ sep() ^ reg_name(rs2)
  when currentlyEnabled(Ext_P)

// ******************************* P SHIFT EXTEND *******************************
union clause instruction = PSHIFTEXTEND : (pshiftextendfunct4, regidx, regidx, regidx)

mapping encdec_pshiftextendfunct4 : pshiftextendfunct4 <-> bits(4) = {
  SLX <-> 0b0001,
  SRX <-> 0b0101,
}

mapping clause encdec = PSHIFTEXTEND(funct4, rs1, rs2, rd) <->
  0b1 @ encdec_pshiftextendfunct4(funct4) @ 0b11 @ encdec_reg(rs2) @ encdec_reg(rs1) @ 0b001 @ encdec_reg(rd) @ 0b0111011
  when currentlyEnabled(Ext_P)

function clause execute (PSHIFTEXTEND(funct4, rs1, rs2, rd)) = {
  let sa : bits(8) = zero_extend(X(rs2)[(log2_xlen - 1)..0]);
  match funct4 {
    SLX => {
      X(rd) = ((X(rd) @ X(rs1)) << sa)[(sizeof(xlen) * 2 - 1)..sizeof(xlen)];
    },
    SRX => {
      X(rd) = ((X(rs1) @ X(rd)) >> sa)[(sizeof(xlen) - 1)..0];
    },
  };
  RETIRE_SUCCESS
}

mapping pshiftextend_mnemonic : pshiftextendfunct4 <-> string = {
  SLX <-> "slx",
  SRX <-> "srx",
}

mapping clause assembly = PSHIFTEXTEND(funct4, rs1, rs2, rd)
  <-> pshiftextend_mnemonic(funct4) ^ spc() ^ reg_name(rd) ^ sep() ^ reg_name(rs1) ^ sep() ^ reg_name(rs2)
  when currentlyEnabled(Ext_P)

// **************************** P MOVE MASKED MERGE *****************************
union clause instruction = PMOVEMASKMERGE : (pmovemaskmergewidth2, regidx, regidx, regidx)

mapping encdec_pmovemaskmergewidth2 : pmovemaskmergewidth2 <-> bits(2) = {
  MVM <-> 0b00,
  MVMN <-> 0b01,
  MERGE <-> 0b10,
}

mapping clause encdec = PMOVEMASKMERGE(width2, rs1, rs2, rd) <->
  0b1 @ 0b0101 @ encdec_pmovemaskmergewidth2(width2) @ encdec_reg(rs2) @ encdec_reg(rs1) @ 0b001 @ encdec_reg(rd) @ 0b0111011
  when currentlyEnabled(Ext_P)

function clause execute (PMOVEMASKMERGE(width2, rs1, rs2, rd)) = {
  match width2 {
    MVM => {
      let rs2_val = X(rs2);
      X(rd) = (not_vec(rs2_val) & X(rd)) | (rs2_val & X(rs1));
    },
    MVMN => {
      let rs2_val = X(rs2);
      X(rd) = (not_vec(rs2_val) & X(rs1)) | (rs2_val & X(rd));
    },
    MERGE => {
      let rd_val = X(rd);
      X(rd) = (not_vec(rd_val) & X(rs1)) | (rd_val & X(rs2));
    },
  };
  RETIRE_SUCCESS
}

mapping pmovemaskmerge_mnemonic : pmovemaskmergewidth2 <-> string = {
  MVM <-> "mvm",
  MVMN <-> "mvmn",
  MERGE <-> "merge",
}

mapping clause assembly = PMOVEMASKMERGE(width2, rs1, rs2, rd)
  <-> pmovemaskmerge_mnemonic(width2) ^ spc() ^ reg_name(rd) ^ sep() ^ reg_name(rs1) ^ sep() ^ reg_name(rs2)
  when currentlyEnabled(Ext_P)

// ********************* P MULTIPLICATION HALFWORD BYTE 01 **********************
union clause instruction = PMULHB01 : (pmulhb01funct4, regidx, regidx, regidx)

mapping encdec_pmulhb01funct4 : pmulhb01funct4 <-> bits(4) = {
  PMUL_H_B01 <-> 0b0010,
  PMULU_H_B01 <-> 0b0110,
}

mapping clause encdec = PMULHB01(funct4, rs1, rs2, rd) <->
  0b1 @ encdec_pmulhb01funct4(funct4) @ 0b00 @ encdec_reg(rs2) @ encdec_reg(rs1) @ 0b001 @ encdec_reg(rd) @ 0b0111011
  when currentlyEnabled(Ext_P)

function clause execute (PMULHB01(funct4, rs1, rs2, rd)) = {
  let rs1_val = X(rs1);
  let rs2_val = X(rs2);
  var result : xlenbits = zeros();
  foreach (i from 0 to (sizeof(xlen) - 16) by 16) {
    let rs1_byte = rs1_val[(i+7)..i];
    let rs2_byte = rs2_val[(i+15)..(i+8)];
    result[(i+15)..i] = match funct4 {
      PMUL_H_B01 => muls(rs1_byte, rs2_byte),
      PMULU_H_B01 => mulu(rs1_byte, rs2_byte),
    };
  };
  X(rd) = result;
  RETIRE_SUCCESS
}

mapping pmulhb01_mnemonic : pmulhb01funct4 <-> string = {
  PMUL_H_B01 <-> "pmul.h.b01",
  PMULU_H_B01 <-> "pmulu.h.b01",
}

mapping clause assembly = PMULHB01(funct4, rs1, rs2, rd)
  <-> pmulhb01_mnemonic(funct4) ^ spc() ^ reg_name(rd) ^ sep() ^ reg_name(rs1) ^ sep() ^ reg_name(rs2)
  when currentlyEnabled(Ext_P)

// ********************** P ABSOLUTE DIFFERENCE SUM BYTE  ***********************
union clause instruction = PABDSUMB : (pabdsumbfunct4, regidx, regidx, regidx)

mapping encdec_pabdsumbfunct4 : pabdsumbfunct4 <-> bits(4) = {
  PABDSUMU_B <-> 0b0110,
  PABDSUMAU_B <-> 0b0111,
}

mapping clause encdec = PABDSUMB(funct4, rs1, rs2, rd) <->
  0b1 @ encdec_pabdsumbfunct4(funct4) @ 0b10 @ encdec_reg(rs2) @ encdec_reg(rs1) @ 0b001 @ encdec_reg(rd) @ 0b0111011
  when currentlyEnabled(Ext_P)

function clause execute (PABDSUMB(funct4, rs1, rs2, rd)) = {
  let rs1_val = X(rs1);
  let rs2_val = X(rs2);
  var result : xlenbits = zeros();
  foreach (i from 0 to (sizeof(xlen) - 8) by 8) {
    let rs1_byte : xlenbits = zero_extend(rs1_val[(i+7)..i]);
    let rs2_byte : xlenbits = zero_extend(rs2_val[(i+7)..i]);
    result = result + abs(rs1_byte - rs2_byte);
  };
  X(rd) = match funct4 {
    PABDSUMU_B => result,
    PABDSUMAU_B => X(rd) + result,
  };
  RETIRE_SUCCESS
}

mapping pabdsumb_mnemonic : pabdsumbfunct4 <-> string = {
  PABDSUMU_B <-> "pabdsumu.b",
  PABDSUMAU_B <-> "pabdsumau.b",
}

mapping clause assembly = PABDSUMB(funct4, rs1, rs2, rd)
  <-> pabdsumb_mnemonic(funct4) ^ spc() ^ reg_name(rd) ^ sep() ^ reg_name(rs1) ^ sep() ^ reg_name(rs2)
  when currentlyEnabled(Ext_P)

// ************************** P SHIFT ONE ADD HALFWORD **************************
union clause instruction = PSHIFTONEADDH : (pshiftoneaddhfunct3, regidx, regidx, regidx)

mapping encdec_pshiftoneaddhfunct3 : pshiftoneaddhfunct3 <-> bits(3) = {
  PSH1ADD_H <-> 0b010,
  PSSH1SADD_H <-> 0b011,
}

mapping clause encdec = PSHIFTONEADDH(funct3, rs1, rs2, rd) <->
  0b1 @ encdec_pshiftoneaddhfunct3(funct3) @ 0b0 @ 0b00 @ encdec_reg(rs2) @ encdec_reg(rs1) @ 0b010 @ encdec_reg(rd) @ 0b0111011
  when currentlyEnabled(Ext_P)

function clause execute (PSHIFTONEADDH(funct3, rs1, rs2, rd)) = {
  let rs1_val = X(rs1);
  let rs2_val = X(rs2);
  var result : xlenbits = zeros();
  foreach (i from 0 to (sizeof(xlen) - 16) by 16) {
    result[(i+15)..i] = match funct3 {
      PSH1ADD_H => (rs1_val[(i+15)..i] << 1) + rs2_val[(i+15)..i],
      PSSH1SADD_H => sadd(sat_shift_left_arith(rs1_val[(i+15)..i], 1), rs2_val[(i+15)..i]),
    };
  };
  X(rd) = result;
  RETIRE_SUCCESS
}

mapping pshiftoneaddh_mnemonic : pshiftoneaddhfunct3 <-> string = {
  PSH1ADD_H <-> "psh1add.h",
  PSSH1SADD_H <-> "pssh1sadd.h",
}

mapping clause assembly = PSHIFTONEADDH(funct3, rs1, rs2, rd)
  <-> pshiftoneaddh_mnemonic(funct3) ^ spc() ^ reg_name(rd) ^ sep() ^ reg_name(rs1) ^ sep() ^ reg_name(rs2)
  when currentlyEnabled(Ext_P)

// *********************** P MULTIPLICATION HALFWORD BYTE ***********************
union clause instruction = PMULHB : (pmulhbfunct4, regidx, regidx, regidx)

mapping encdec_pmulhbfunct4 : pmulhbfunct4 <-> bits(4) = {
  PMUL_H_B00 <-> 0b0000,
  PMUL_H_B11 <-> 0b0010,
  PMULU_H_B00 <-> 0b0100,
  PMULU_H_B11 <-> 0b0110,
  PMULSU_H_B00 <-> 0b1100,
  PMULSU_H_B11 <-> 0b1110,
}

mapping clause encdec = PMULHB(funct4, rs1, rs2, rd) <->
  0b1 @ encdec_pmulhbfunct4(funct4) @ 0b00 @ encdec_reg(rs2) @ encdec_reg(rs1) @ 0b011 @ encdec_reg(rd) @ 0b0111011
  when currentlyEnabled(Ext_P)

function clause execute (PMULHB(funct4, rs1, rs2, rd)) = {
  let rs1_val = X(rs1);
  let rs2_val = X(rs2);
  var result : xlenbits = zeros();
  foreach (i from 0 to (sizeof(xlen) - 16) by 16) {
    let rs1_byte_even = slice(rs1_val, i, 8);
    let rs2_byte_even = slice(rs2_val, i, 8);
    let rs1_byte_odd = slice(rs1_val, i + 8, 8);
    let rs2_byte_odd = slice(rs2_val, i + 8, 8);
    result[(i+15)..i] = match funct4 {
      PMUL_H_B00 => muls(rs1_byte_even, rs2_byte_even),
      PMUL_H_B11 => muls(rs1_byte_odd, rs2_byte_odd),
      PMULU_H_B00 => mulu(rs1_byte_even, rs2_byte_even),
      PMULU_H_B11 => mulu(rs1_byte_odd, rs2_byte_odd),
      PMULSU_H_B00 => mulsu(rs1_byte_even, rs2_byte_even),
      PMULSU_H_B11 => mulsu(rs1_byte_odd, rs2_byte_odd),
    };
  };
  X(rd) = result;
  RETIRE_SUCCESS
}

mapping pmulhb_mnemonic : pmulhbfunct4 <-> string = {
  PMUL_H_B00 <-> "pmul.h.b00",
  PMUL_H_B11 <-> "pmul.h.b11",
  PMULU_H_B00 <-> "pmulu.h.b00",
  PMULU_H_B11 <-> "pmulu.h.b11",
  PMULSU_H_B00 <-> "pmulsu.h.b00",
  PMULSU_H_B11 <-> "pmulsu.h.b11",
}

mapping clause assembly = PMULHB(funct4, rs1, rs2, rd)
  <-> pmulhb_mnemonic(funct4) ^ spc() ^ reg_name(rd) ^ sep() ^ reg_name(rs1) ^ sep() ^ reg_name(rs2)
  when currentlyEnabled(Ext_P)

// ******************************** P PAIR BYTE *********************************
union clause instruction = PPAIRB : (ppairbfunct3, regidx, regidx, regidx)

mapping encdec_ppairbfunct3 : ppairbfunct3 <-> bits(3) = {
  PPAIRE_B <-> 0b000,
  PPAIREO_B <-> 0b001,
  PPAIROE_B <-> 0b010,
  PPAIRO_B <-> 0b011,
}

mapping clause encdec = PPAIRB(funct3, rs1, rs2, rd) <->
  0b1 @ encdec_ppairbfunct3(funct3) @ 0b0 @ 0b00 @ encdec_reg(rs2) @ encdec_reg(rs1) @ 0b100 @ encdec_reg(rd) @ 0b0111011
  when currentlyEnabled(Ext_P)

function clause execute (PPAIRB(funct3, rs1, rs2, rd)) = {
  let rs1_val = X(rs1);
  let rs2_val = X(rs2);
  var result : xlenbits = zeros();
  foreach (i from 0 to (sizeof(xlen) - 16) by 16) {
    let rs1_byte_even = slice(rs1_val, i, 8);
    let rs2_byte_even = slice(rs2_val, i, 8);
    let rs1_byte_odd = slice(rs1_val, i + 8, 8);
    let rs2_byte_odd = slice(rs2_val, i + 8, 8);
    result[(i+15)..i] = match funct3 {
      PPAIRE_B => rs2_byte_even @ rs1_byte_even,
      PPAIREO_B => rs2_byte_odd @ rs1_byte_even,
      PPAIROE_B => rs2_byte_even @ rs1_byte_odd,
      PPAIRO_B => rs2_byte_odd @ rs1_byte_odd,
    };
  };
  X(rd) = result;
  RETIRE_SUCCESS
}

mapping ppairb_mnemonic : ppairbfunct3 <-> string = {
  PPAIRE_B <-> "ppaire.b",
  PPAIREO_B <-> "ppaireo.b",
  PPAIROE_B <-> "ppairoe.b",
  PPAIRO_B <-> "ppairo.b",
}

mapping clause assembly = PPAIRB(funct3, rs1, rs2, rd)
  <-> ppairb_mnemonic(funct3) ^ spc() ^ reg_name(rd) ^ sep() ^ reg_name(rs1) ^ sep() ^ reg_name(rs2)
  when currentlyEnabled(Ext_P)

// ****************************** P PAIR HALFWORD *******************************
union clause instruction = PPAIRH : (ppairhfunct3, regidx, regidx, regidx)

mapping encdec_ppairhfunct3 : ppairhfunct3 <-> bits(3) = {
  PPAIREO_H <-> 0b001,
  PPAIROE_H <-> 0b010,
  PPAIRO_H <-> 0b011,
}

mapping clause encdec = PPAIRH(funct3, rs1, rs2, rd) <->
  0b1 @ encdec_ppairhfunct3(funct3) @ 0b0 @ 0b01 @ encdec_reg(rs2) @ encdec_reg(rs1) @ 0b100 @ encdec_reg(rd) @ 0b0111011
  when currentlyEnabled(Ext_P)

function clause execute (PPAIRH(funct3, rs1, rs2, rd)) = {
  let rs1_val = X(rs1);
  let rs2_val = X(rs2);
  var result : xlenbits = zeros();
  foreach (i from 0 to (sizeof(xlen) - 32) by 32) {
    let rs1_halfword_even = slice(rs1_val, i, 16);
    let rs2_halfword_even = slice(rs2_val, i, 16);
    let rs1_halfword_odd = slice(rs1_val, i + 16, 16);
    let rs2_halfword_odd = slice(rs2_val, i + 16, 16);
    result[(i+31)..i] = match funct3 {
      PPAIREO_H => rs2_halfword_odd @ rs1_halfword_even,
      PPAIROE_H => rs2_halfword_even @ rs1_halfword_odd,
      PPAIRO_H => rs2_halfword_odd @ rs1_halfword_odd,
    };
  };
  X(rd) = result;
  RETIRE_SUCCESS
}

mapping ppairh_mnemonic : ppairhfunct3 <-> string = {
  PPAIREO_H <-> "ppaireo.h",
  PPAIROE_H <-> "ppairoe.h",
  PPAIRO_H <-> "ppairo.h",
}

mapping clause assembly = PPAIRH(funct3, rs1, rs2, rd)
  <-> ppairh_mnemonic(funct3) ^ spc() ^ reg_name(rd) ^ sep() ^ reg_name(rs1) ^ sep() ^ reg_name(rs2)
  when currentlyEnabled(Ext_P)

// *********************** P MULTIPLICATION TWO HALFWORD ************************
union clause instruction = PMUL2H : (pmul2hfunct4, regidx, regidx, regidx)

mapping encdec_pmul2hfunct4 : pmul2hfunct4 <-> bits(4) = {
  PM2ADD_H <-> 0b0000,
  PM2ADDA_H <-> 0b0001,
  PM2ADD_HX <-> 0b0010,
  PM2ADDA_HX <-> 0b0011,
  PM2ADDU_H <-> 0b0100,
  PM2ADDAU_H <-> 0b0101,
  PMQ2ADD_H <-> 0b0110,
  PMQ2ADDA_H <-> 0b0111,
  PM2SUB_H <-> 0b1000,
  PM2SUBA_H <-> 0b1001,
  PM2SUB_HX <-> 0b1010,
  PM2SUBA_HX <-> 0b1011,
  PM2ADDSU_H <-> 0b1100,
  PM2ADDASU_H <-> 0b1101,
}

mapping clause encdec = PMUL2H(funct4, rs1, rs2, rd) <->
  0b1 @ encdec_pmul2hfunct4(funct4) @ 0b00 @ encdec_reg(rs2) @ encdec_reg(rs1) @ 0b101 @ encdec_reg(rd) @ 0b0111011
  when currentlyEnabled(Ext_P)

function clause execute (PMUL2H(funct4, rs1, rs2, rd)) = {
  let rs1_val = X(rs1);
  let rs2_val = X(rs2);
  let rd_val = X(rd);
  var result : xlenbits = zeros();
  foreach (i from 0 to (sizeof(xlen) - 32) by 32) {
    let rs1_halfword_even = slice(rs1_val, i, 16);
    let rs2_halfword_even = slice(rs2_val, i, 16);
    let rs1_halfword_odd = slice(rs1_val, i + 16, 16);
    let rs2_halfword_odd = slice(rs2_val, i + 16, 16);
    result[(i+31)..i] = match funct4 {
      PM2ADD_H => muls(rs1_halfword_odd, rs2_halfword_odd) + muls(rs1_halfword_even, rs2_halfword_even),
      PM2ADDA_H => rd_val[(i+31)..i] + muls(rs1_halfword_odd, rs2_halfword_odd) + muls(rs1_halfword_even, rs2_halfword_even),
      PM2ADD_HX => muls(rs1_halfword_odd, rs2_halfword_even) + muls(rs1_halfword_even, rs2_halfword_odd),
      PM2ADDA_HX => rd_val[(i+31)..i] + muls(rs1_halfword_odd, rs2_halfword_even) + muls(rs1_halfword_even, rs2_halfword_odd),
      PM2ADDU_H => mulu(rs1_halfword_odd, rs2_halfword_odd) + mulu(rs1_halfword_even, rs2_halfword_even),
      PM2ADDAU_H => rd_val[(i+31)..i] + mulu(rs1_halfword_odd, rs2_halfword_odd) + mulu(rs1_halfword_even, rs2_halfword_even),
      PMQ2ADD_H => mulq(rs1_halfword_odd, rs2_halfword_odd) + mulq(rs1_halfword_even, rs2_halfword_even),
      PMQ2ADDA_H => rd_val[(i+31)..i] + mulq(rs1_halfword_odd, rs2_halfword_odd) + mulq(rs1_halfword_even, rs2_halfword_even),
      PM2SUB_H => muls(rs1_halfword_even, rs2_halfword_even) - muls(rs1_halfword_odd, rs2_halfword_odd),
      PM2SUBA_H => rd_val[(i+31)..i] + muls(rs1_halfword_even, rs2_halfword_even) - muls(rs1_halfword_odd, rs2_halfword_odd),
      PM2SUB_HX => muls(rs1_halfword_even, rs2_halfword_odd) - muls(rs1_halfword_odd, rs2_halfword_even),
      PM2SUBA_HX => rd_val[(i+31)..i] + muls(rs1_halfword_even, rs2_halfword_odd) - muls(rs1_halfword_odd, rs2_halfword_even),
      PM2ADDSU_H => mulsu(rs1_halfword_odd, rs2_halfword_odd) + mulsu(rs1_halfword_even, rs2_halfword_even),
      PM2ADDASU_H => rd_val[(i+31)..i] + mulsu(rs1_halfword_odd, rs2_halfword_odd) + mulsu(rs1_halfword_even, rs2_halfword_even),
    };
  };
  X(rd) = result;
  RETIRE_SUCCESS
}

mapping pmul2h_mnemonic : pmul2hfunct4 <-> string = {
  PM2ADD_H <-> "pm2add.h",
  PM2ADDA_H <-> "pm2adda.h",
  PM2ADD_HX <-> "pm2add.hx",
  PM2ADDA_HX <-> "pm2adda.hx",
  PM2ADDU_H <-> "pm2addu.h",
  PM2ADDAU_H <-> "pm2addau.h",
  PMQ2ADD_H <-> "pmq2add.h",
  PMQ2ADDA_H <-> "pmq2adda.h",
  PM2SUB_H <-> "pm2sub.h",
  PM2SUBA_H <-> "pm2suba.h",
  PM2SUB_HX <-> "pm2sub.hx",
  PM2SUBA_HX <-> "pm2suba.hx",
  PM2ADDSU_H <-> "pm2addsu.h",
  PM2ADDASU_H <-> "pm2addasu.h",
}

mapping clause assembly = PMUL2H(funct4, rs1, rs2, rd)
  <-> pmul2h_mnemonic(funct4) ^ spc() ^ reg_name(rd) ^ sep() ^ reg_name(rs1) ^ sep() ^ reg_name(rs2)
  when currentlyEnabled(Ext_P)

// ****************** P MULTIPLICATION TWO HALFWORD CONTINUED *******************
union clause instruction = PMUL2HCONTD : (pmul2hcontdfunct4, regidx, regidx, regidx)

mapping encdec_pmul2hcontdfunct4 : pmul2hcontdfunct4 <-> bits(4) = {
  PMQR2ADD_H <-> 0b0110,
  PMQR2ADDA_H <-> 0b0111,
  PM2SADD_H <-> 0b1000,
  PM2SADD_HX <-> 0b1010,
}

mapping clause encdec = PMUL2HCONTD(funct4, rs1, rs2, rd) <->
  0b1 @ encdec_pmul2hcontdfunct4(funct4) @ 0b10 @ encdec_reg(rs2) @ encdec_reg(rs1) @ 0b101 @ encdec_reg(rd) @ 0b0111011
  when currentlyEnabled(Ext_P)

function clause execute (PMUL2HCONTD(funct4, rs1, rs2, rd)) = {
  let rs1_val = X(rs1);
  let rs2_val = X(rs2);
  let rd_val = X(rd);
  var result : xlenbits = zeros();
  foreach (i from 0 to (sizeof(xlen) - 32) by 32) {
    let rs1_halfword_even = slice(rs1_val, i, 16);
    let rs2_halfword_even = slice(rs2_val, i, 16);
    let rs1_halfword_odd = slice(rs1_val, i + 16, 16);
    let rs2_halfword_odd = slice(rs2_val, i + 16, 16);
    result[(i+31)..i] = match funct4 {
      PMQR2ADD_H => mulqr(rs1_halfword_odd, rs2_halfword_odd) + mulqr(rs1_halfword_even, rs2_halfword_even),
      PMQR2ADDA_H => rd_val[(i+31)..i] + mulqr(rs1_halfword_odd, rs2_halfword_odd) + mulqr(rs1_halfword_even, rs2_halfword_even),
      PM2SADD_H => sadd(muls(rs1_halfword_odd, rs2_halfword_odd), muls(rs1_halfword_even, rs2_halfword_even)),
      PM2SADD_HX => sadd(muls(rs1_halfword_odd, rs2_halfword_even), muls(rs1_halfword_even, rs2_halfword_odd)),
    };
  };
  X(rd) = result;
  RETIRE_SUCCESS
}

mapping pmul2hcontd_mnemonic : pmul2hcontdfunct4 <-> string = {
  PMQR2ADD_H <-> "pmqr2add.h",
  PMQR2ADDA_H <-> "pmqr2adda.h",
  PM2SADD_H <-> "pm2sadd.h",
  PM2SADD_HX <-> "pm2sadd.hx",
}

mapping clause assembly = PMUL2HCONTD(funct4, rs1, rs2, rd)
  <-> pmul2hcontd_mnemonic(funct4) ^ spc() ^ reg_name(rd) ^ sep() ^ reg_name(rs1) ^ sep() ^ reg_name(rs2)
  when currentlyEnabled(Ext_P)

// ************************* P MULTIPLICATION FOUR BYTE *************************
union clause instruction = PMUL4B : (pmul4bfunct4, regidx, regidx, regidx)

mapping encdec_pmul4bfunct4 : pmul4bfunct4 <-> bits(4) = {
  PM4ADD_B <-> 0b0000,
  PM4ADDA_B <-> 0b0001,
  PM4ADDU_B <-> 0b0100,
  PM4ADDAU_B <-> 0b0101,
  PM4ADDSU_B <-> 0b1100,
  PM4ADDASU_B <-> 0b1101,
}

mapping clause encdec = PMUL4B(funct4, rs1, rs2, rd) <->
  0b1 @ encdec_pmul4bfunct4(funct4) @ 0b10 @ encdec_reg(rs2) @ encdec_reg(rs1) @ 0b101 @ encdec_reg(rd) @ 0b0111011
  when currentlyEnabled(Ext_P)

function clause execute (PMUL4B(funct4, rs1, rs2, rd)) = {
  let rs1_val = X(rs1);
  let rs2_val = X(rs2);
  let rd_val = X(rd);
  var result : xlenbits = match funct4 {
    PM4ADD_B => zeros(),
    PM4ADDA_B => rd_val,
    PM4ADDU_B => zeros(),
    PM4ADDAU_B => rd_val,
    PM4ADDSU_B => zeros(),
    PM4ADDASU_B => rd_val,
  };
  foreach (i from 0 to (sizeof(xlen) - 32) by 32) {
    foreach (j from i to (i + 24) by 8) {
      let rs1_byte = rs1_val[(j+7)..j];
      let rs2_byte = rs2_val[(j+7)..j];
      result[(i+31)..i] = match funct4 {
        PM4ADD_B => result[(i+31)..i] + sign_extend(muls(rs1_byte, rs2_byte)),
        PM4ADDA_B => result[(i+31)..i] + sign_extend(muls(rs1_byte, rs2_byte)),
        PM4ADDU_B => result[(i+31)..i] + zero_extend(mulu(rs1_byte, rs2_byte)),
        PM4ADDAU_B => result[(i+31)..i] + zero_extend(mulu(rs1_byte, rs2_byte)),
        PM4ADDSU_B => result[(i+31)..i] + sign_extend(mulsu(rs1_byte, rs2_byte)),
        PM4ADDASU_B => result[(i+31)..i] + sign_extend(mulsu(rs1_byte, rs2_byte)),
      };
    };
  };
  X(rd) = result;
  RETIRE_SUCCESS
}

mapping pmul4b_mnemonic : pmul4bfunct4 <-> string = {
  PM4ADD_B <-> "pm4add.b",
  PM4ADDA_B <-> "pm4adda.b",
  PM4ADDU_B <-> "pm4addu.b",
  PM4ADDAU_B <-> "pm4addau.b",
  PM4ADDSU_B <-> "pm4addsu.b",
  PM4ADDASU_B <-> "pm4addasu.b",
}

mapping clause assembly = PMUL4B(funct4, rs1, rs2, rd)
  <-> pmul4b_mnemonic(funct4) ^ spc() ^ reg_name(rd) ^ sep() ^ reg_name(rs1) ^ sep() ^ reg_name(rs2)
  when currentlyEnabled(Ext_P)

// ***************************** P ADD SUB HALFWORD *****************************
union clause instruction = PADDSUBH : (paddsubhfunct4, regidx, regidx, regidx)

mapping encdec_paddsubhfunct4 : paddsubhfunct4 <-> bits(4) = {
  PAS_HX <-> 0b0000,
  PSAS_HX <-> 0b0010,
  PAAS_HX <-> 0b0011,
}

mapping clause encdec = PADDSUBH(funct4, rs1, rs2, rd) <->
  0b1 @ encdec_paddsubhfunct4(funct4) @ 0b00 @ encdec_reg(rs2) @ encdec_reg(rs1) @ 0b110 @ encdec_reg(rd) @ 0b0111011
  when currentlyEnabled(Ext_P)

function clause execute (PADDSUBH(funct4, rs1, rs2, rd)) = {
  let rs1_val = X(rs1);
  let rs2_val = X(rs2);
  var result : xlenbits = zeros();
  foreach (i from 0 to (sizeof(xlen) - 32) by 32) {
    let rs1_halfword_even = slice(rs1_val, i, 16);
    let rs2_halfword_even = slice(rs2_val, i, 16);
    let rs1_halfword_odd = slice(rs1_val, i + 16, 16);
    let rs2_halfword_odd = slice(rs2_val, i + 16, 16);
    result[(i+31)..i] = match funct4 {
      PAS_HX => (rs1_halfword_odd + rs2_halfword_even) @ (rs1_halfword_even - rs2_halfword_odd),
      PSAS_HX => sadd(rs1_halfword_odd, rs2_halfword_even) @ ssub(rs1_halfword_even, rs2_halfword_odd),
      PAAS_HX => aadd(rs1_halfword_odd, rs2_halfword_even) @ asub(rs1_halfword_even, rs2_halfword_odd),
    };
  };
  X(rd) = result;
  RETIRE_SUCCESS
}

mapping paddsubh_mnemonic : paddsubhfunct4 <-> string = {
  PAS_HX <-> "pas.hx",
  PSAS_HX <-> "psas.hx",
  PAAS_HX <-> "paas.hx",
}

mapping clause assembly = PADDSUBH(funct4, rs1, rs2, rd)
  <-> paddsubh_mnemonic(funct4) ^ spc() ^ reg_name(rd) ^ sep() ^ reg_name(rs1) ^ sep() ^ reg_name(rs2)
  when currentlyEnabled(Ext_P)

// ***************************** P SUB ADD HALFWORD *****************************
union clause instruction = PSUBADDH : (psubaddhfunct4, regidx, regidx, regidx)

mapping encdec_psubaddhfunct4 : psubaddhfunct4 <-> bits(4) = {
  PSA_HX <-> 0b0000,
  PSSA_HX <-> 0b0010,
  PASA_HX <-> 0b0011,
}

mapping clause encdec = PSUBADDH(funct4, rs1, rs2, rd) <->
  0b1 @ encdec_psubaddhfunct4(funct4) @ 0b10 @ encdec_reg(rs2) @ encdec_reg(rs1) @ 0b110 @ encdec_reg(rd) @ 0b0111011
  when currentlyEnabled(Ext_P)

function clause execute (PSUBADDH(funct4, rs1, rs2, rd)) = {
  let rs1_val = X(rs1);
  let rs2_val = X(rs2);
  var result : xlenbits = zeros();
  foreach (i from 0 to (sizeof(xlen) - 32) by 32) {
    let rs1_halfword_even = slice(rs1_val, i, 16);
    let rs2_halfword_even = slice(rs2_val, i, 16);
    let rs1_halfword_odd = slice(rs1_val, i + 16, 16);
    let rs2_halfword_odd = slice(rs2_val, i + 16, 16);
    result[(i+31)..i] = match funct4 {
      PSA_HX => (rs1_halfword_odd - rs2_halfword_even) @ (rs1_halfword_even + rs2_halfword_odd),
      PSSA_HX => ssub(rs1_halfword_odd, rs2_halfword_even) @ sadd(rs1_halfword_even, rs2_halfword_odd),
      PASA_HX => asub(rs1_halfword_odd, rs2_halfword_even) @ aadd(rs1_halfword_even, rs2_halfword_odd),
    };
  };
  X(rd) = result;
  RETIRE_SUCCESS
}

mapping psubaddh_mnemonic : psubaddhfunct4 <-> string = {
  PSA_HX <-> "psa.hx",
  PSSA_HX <-> "pssa.hx",
  PASA_HX <-> "pasa.hx",
}

mapping clause assembly = PSUBADDH(funct4, rs1, rs2, rd)
  <-> psubaddh_mnemonic(funct4) ^ spc() ^ reg_name(rd) ^ sep() ^ reg_name(rs1) ^ sep() ^ reg_name(rs2)
  when currentlyEnabled(Ext_P)

// ***************************** P COMPARISON BYTE ******************************
union clause instruction = PCOMPAREB : (pcomparebfunct4, regidx, regidx, regidx)

mapping encdec_pcomparebfunct4 : pcomparebfunct4 <-> bits(4) = {
  PMSEQ_B <-> 0b1000,
  PMSLT_B <-> 0b1010,
  PMSLTU_B <-> 0b1011,
  PMIN_B <-> 0b1100,
  PMINU_B <-> 0b1101,
  PMAX_B <-> 0b1110,
  PMAXU_B <-> 0b1111,
}

mapping clause encdec = PCOMPAREB(funct4, rs1, rs2, rd) <->
  0b1 @ encdec_pcomparebfunct4(funct4) @ 0b10 @ encdec_reg(rs2) @ encdec_reg(rs1) @ 0b110 @ encdec_reg(rd) @ 0b0111011
  when currentlyEnabled(Ext_P)

function clause execute (PCOMPAREB(funct4, rs1, rs2, rd)) = {
  let rs1_val = X(rs1);
  let rs2_val = X(rs2);
  var result : xlenbits = zeros();
  foreach (i from 0 to (sizeof(xlen) - 8) by 8) {
    let rs1_byte = slice(rs1_val, i, 8);
    let rs2_byte = slice(rs2_val, i, 8);
    result[(i+7)..i] = match funct4 {
      PMSEQ_B => mseq(rs1_byte, rs2_byte),
      PMSLT_B => mslt(rs1_byte, rs2_byte),
      PMSLTU_B => msltu(rs1_byte, rs2_byte),
      PMIN_B => mins(rs1_byte, rs2_byte),
      PMINU_B => minu(rs1_byte, rs2_byte),
      PMAX_B => maxs(rs1_byte, rs2_byte),
      PMAXU_B => maxu(rs1_byte, rs2_byte),
    };
  };
  X(rd) = result;
  RETIRE_SUCCESS
}

mapping pcompareb_mnemonic : pcomparebfunct4 <-> string = {
  PMSEQ_B <-> "pmseq.b",
  PMSLT_B <-> "pmslt.b",
  PMSLTU_B <-> "pmsltu.b",
  PMIN_B <-> "pmin.b",
  PMINU_B <-> "pminu.b",
  PMAX_B <-> "pmax.b",
  PMAXU_B <-> "pmaxu.b",
}

mapping clause assembly = PCOMPAREB(funct4, rs1, rs2, rd)
  <-> pcompareb_mnemonic(funct4) ^ spc() ^ reg_name(rd) ^ sep() ^ reg_name(rs1) ^ sep() ^ reg_name(rs2)
  when currentlyEnabled(Ext_P)

// *************************** P COMPARISON HALFWORD ****************************
union clause instruction = PCOMPAREH : (pcomparehfunct4, regidx, regidx, regidx)

mapping encdec_pcomparehfunct4 : pcomparehfunct4 <-> bits(4) = {
  PMSEQ_H <-> 0b1000,
  PMSLT_H <-> 0b1010,
  PMSLTU_H <-> 0b1011,
  PMIN_H <-> 0b1100,
  PMINU_H <-> 0b1101,
  PMAX_H <-> 0b1110,
  PMAXU_H <-> 0b1111,
}

mapping clause encdec = PCOMPAREH(funct4, rs1, rs2, rd) <->
  0b1 @ encdec_pcomparehfunct4(funct4) @ 0b00 @ encdec_reg(rs2) @ encdec_reg(rs1) @ 0b110 @ encdec_reg(rd) @ 0b0111011
  when currentlyEnabled(Ext_P)

function clause execute (PCOMPAREH(funct4, rs1, rs2, rd)) = {
  let rs1_val = X(rs1);
  let rs2_val = X(rs2);
  var result : xlenbits = zeros();
  foreach (i from 0 to (sizeof(xlen) - 16) by 16) {
    let rs1_byte = slice(rs1_val, i, 16);
    let rs2_byte = slice(rs2_val, i, 16);
    result[(i+15)..i] = match funct4 {
      PMSEQ_H => mseq(rs1_byte, rs2_byte),
      PMSLT_H => mslt(rs1_byte, rs2_byte),
      PMSLTU_H => msltu(rs1_byte, rs2_byte),
      PMIN_H => mins(rs1_byte, rs2_byte),
      PMINU_H => minu(rs1_byte, rs2_byte),
      PMAX_H => maxs(rs1_byte, rs2_byte),
      PMAXU_H => maxu(rs1_byte, rs2_byte),
    };
  };
  X(rd) = result;
  RETIRE_SUCCESS
}

mapping pcompareh_mnemonic : pcomparehfunct4 <-> string = {
  PMSEQ_H <-> "pmseq.h",
  PMSLT_H <-> "pmslt.h",
  PMSLTU_H <-> "pmsltu.h",
  PMIN_H <-> "pmin.h",
  PMINU_H <-> "pminu.h",
  PMAX_H <-> "pmax.h",
  PMAXU_H <-> "pmaxu.h",
}

mapping clause assembly = PCOMPAREH(funct4, rs1, rs2, rd)
  <-> pcompareh_mnemonic(funct4) ^ spc() ^ reg_name(rd) ^ sep() ^ reg_name(rs1) ^ sep() ^ reg_name(rs2)
  when currentlyEnabled(Ext_P)

// ************************* P MULTIPLICATION HALFWORD **************************
union clause instruction = PMULH : (pmulhfunct4, regidx, regidx, regidx)

mapping encdec_pmulhfunct4 : pmulhfunct4 <-> bits(4) = {
  PMULH_H <-> 0b0000,
  PMHACC_H <-> 0b0001,
  PMULHU_H <-> 0b0010,
  PMHACCU_H <-> 0b0011,
  PMULHSU_H <-> 0b1000,
  PMHACCSU_H <-> 0b1001,
  PMULQ_H <-> 0b1010,
}

mapping clause encdec = PMULH(funct4, rs1, rs2, rd) <->
  0b1 @ encdec_pmulhfunct4(funct4) @ 0b00 @ encdec_reg(rs2) @ encdec_reg(rs1) @ 0b111 @ encdec_reg(rd) @ 0b0111011
  when currentlyEnabled(Ext_P)

function clause execute (PMULH(funct4, rs1, rs2, rd)) = {
  let rs1_val = X(rs1);
  let rs2_val = X(rs2);
  let rd_val = X(rd);
  var result : xlenbits = zeros();
  foreach (i from 0 to (sizeof(xlen) - 16) by 16) {
    let rs1_halfword = rs1_val[(i+15)..i];
    let rs2_halfword = rs2_val[(i+15)..i];
    let rd_halfword = rd_val[(i+15)..i];
    result[(i+15)..i] = match funct4 {
      PMULH_H => mulh(rs1_halfword, rs2_halfword),
      PMHACC_H => rd_halfword + mulh(rs1_halfword, rs2_halfword),
      PMULHU_H => mulhu(rs1_halfword, rs2_halfword),
      PMHACCU_H => rd_halfword + mulhu(rs1_halfword, rs2_halfword),
      PMULHSU_H => mulhsu(rs1_halfword, rs2_halfword),
      PMHACCSU_H => rd_halfword + mulhsu(rs1_halfword, rs2_halfword),
      PMULQ_H => mulq_sat(rs1_halfword, rs2_halfword)[15..0],
    };
  };
  X(rd) = result;
  RETIRE_SUCCESS
}

mapping pmulh_mnemonic : pmulhfunct4 <-> string = {
  PMULH_H <-> "pmulh.h",
  PMHACC_H <-> "pmhacc.h",
  PMULHU_H <-> "pmulhu.h",
  PMHACCU_H <-> "pmhaccu.h",
  PMULHSU_H <-> "pmulhsu.h",
  PMHACCSU_H <-> "pmhaccsu.h",
  PMULQ_H <-> "pmulq.h",
}

mapping clause assembly = PMULH(funct4, rs1, rs2, rd)
  <-> pmulh_mnemonic(funct4) ^ spc() ^ reg_name(rd) ^ sep() ^ reg_name(rs1) ^ sep() ^ reg_name(rs2)
  when currentlyEnabled(Ext_P)

// ******************** P MULTIPLICATION HALFWORD CONTINUED *********************
union clause instruction = PMULHCONTD : (pmulhcontdfunct4, regidx, regidx, regidx)

mapping encdec_pmulhcontdfunct4 : pmulhcontdfunct4 <-> bits(4) = {
  PMULHR_H <-> 0b0000,
  PMHRACC_H <-> 0b0001,
  PMULHRU_H <-> 0b0010,
  PMHRACCU_H <-> 0b0011,
  PMULHRSU_H <-> 0b1000,
  PMHRACCSU_H <-> 0b1001,
  PMULQR_H <-> 0b1010,
}

mapping clause encdec = PMULHCONTD(funct4, rs1, rs2, rd) <->
  0b1 @ encdec_pmulhcontdfunct4(funct4) @ 0b10 @ encdec_reg(rs2) @ encdec_reg(rs1) @ 0b111 @ encdec_reg(rd) @ 0b0111011
  when currentlyEnabled(Ext_P)

function clause execute (PMULHCONTD(funct4, rs1, rs2, rd)) = {
  let rs1_val = X(rs1);
  let rs2_val = X(rs2);
  let rd_val = X(rd);
  var result : xlenbits = zeros();
  foreach (i from 0 to (sizeof(xlen) - 16) by 16) {
    let rs1_halfword = rs1_val[(i+15)..i];
    let rs2_halfword = rs2_val[(i+15)..i];
    let rd_halfword = rd_val[(i+15)..i];
    result[(i+15)..i] = match funct4 {
      PMULHR_H => mulhr(rs1_halfword, rs2_halfword),
      PMHRACC_H => rd_halfword + mulhr(rs1_halfword, rs2_halfword),
      PMULHRU_H => mulhru(rs1_halfword, rs2_halfword),
      PMHRACCU_H => rd_halfword + mulhru(rs1_halfword, rs2_halfword),
      PMULHRSU_H => mulhrsu(rs1_halfword, rs2_halfword),
      PMHRACCSU_H => rd_halfword + mulhrsu(rs1_halfword, rs2_halfword),
      PMULQR_H => mulqr_sat(rs1_halfword, rs2_halfword)[15..0],
    };
  };
  X(rd) = result;
  RETIRE_SUCCESS
}

mapping pmulhcontd_mnemonic : pmulhcontdfunct4 <-> string = {
  PMULHR_H <-> "pmulhr.h",
  PMHRACC_H <-> "pmhracc.h",
  PMULHRU_H <-> "pmulhru.h",
  PMHRACCU_H <-> "pmhraccu.h",
  PMULHRSU_H <-> "pmulhrsu.h",
  PMHRACCSU_H <-> "pmhraccsu.h",
  PMULQR_H <-> "pmulqr.h",
}

mapping clause assembly = PMULHCONTD(funct4, rs1, rs2, rd)
  <-> pmulhcontd_mnemonic(funct4) ^ spc() ^ reg_name(rd) ^ sep() ^ reg_name(rs1) ^ sep() ^ reg_name(rs2)
  when currentlyEnabled(Ext_P)

// ******************* P MULTIPLICATION HALFWORD BYTE SIGNED ********************
union clause instruction = PMULHBSIGNED : (pmulhbsignedfunct4, regidx, regidx, regidx)

mapping encdec_pmulhbsignedfunct4 : pmulhbsignedfunct4 <-> bits(4) = {
  PMULH_H_B0 <-> 0b0100,
  PMHACC_H_B0 <-> 0b0101,
  PMULH_H_B1 <-> 0b0110,
  PMHACC_H_B1 <-> 0b0111,
}

mapping clause encdec = PMULHBSIGNED(funct4, rs1, rs2, rd) <->
  0b1 @ encdec_pmulhbsignedfunct4(funct4) @ 0b00 @ encdec_reg(rs2) @ encdec_reg(rs1) @ 0b111 @ encdec_reg(rd) @ 0b0111011
  when currentlyEnabled(Ext_P)

function clause execute (PMULHBSIGNED(funct4, rs1, rs2, rd)) = {
  let rs1_val = X(rs1);
  let rs2_val = X(rs2);
  let rd_val = X(rd);
  var result : xlenbits = zeros();
  foreach (i from 0 to (sizeof(xlen) - 16) by 16) {
    let rs1_halfword = rs1_val[(i+15)..i];
    let rs2_byte_even = rs2_val[(i+7)..i];
    let rs2_byte_odd = rs2_val[(i+15)..(i+8)];
    let rd_halfword = rd_val[(i+15)..i];
    result[(i+15)..i] = match funct4 {
      PMULH_H_B0 => mulh_mixed(rs1_halfword, rs2_byte_even),
      PMHACC_H_B0 => rd_halfword + mulh_mixed(rs1_halfword, rs2_byte_even),
      PMULH_H_B1 => mulh_mixed(rs1_halfword, rs2_byte_odd),
      PMHACC_H_B1 => rd_halfword + mulh_mixed(rs1_halfword, rs2_byte_odd),
    };
  };
  X(rd) = result;
  RETIRE_SUCCESS
}

mapping pmulhbsigned_mnemonic : pmulhbsignedfunct4 <-> string = {
  PMULH_H_B0 <-> "pmulh.h.b0",
  PMHACC_H_B0 <-> "pmhacc.h.b0",
  PMULH_H_B1 <-> "pmulh.h.b1",
  PMHACC_H_B1 <-> "pmhacc.h.b1",
}

mapping clause assembly = PMULHBSIGNED(funct4, rs1, rs2, rd)
  <-> pmulhbsigned_mnemonic(funct4) ^ spc() ^ reg_name(rd) ^ sep() ^ reg_name(rs1) ^ sep() ^ reg_name(rs2)
  when currentlyEnabled(Ext_P)

// ****************** P MULTIPLICATION HALFWORD BYTE UNSIGNED *******************
union clause instruction = PMULHBUNSIGNED : (pmulhbunsignedfunct4, regidx, regidx, regidx)

mapping encdec_pmulhbunsignedfunct4 : pmulhbunsignedfunct4 <-> bits(4) = {
  PMULHSU_H_B0 <-> 0b0100,
  PMHACCSU_H_B0 <-> 0b0101,
  PMULHSU_H_B1 <-> 0b0110,
  PMHACCSU_H_B1 <-> 0b0111,
}

mapping clause encdec = PMULHBUNSIGNED(funct4, rs1, rs2, rd) <->
  0b1 @ encdec_pmulhbunsignedfunct4(funct4) @ 0b10 @ encdec_reg(rs2) @ encdec_reg(rs1) @ 0b111 @ encdec_reg(rd) @ 0b0111011
  when currentlyEnabled(Ext_P)

function clause execute (PMULHBUNSIGNED(funct4, rs1, rs2, rd)) = {
  let rs1_val = X(rs1);
  let rs2_val = X(rs2);
  let rd_val = X(rd);
  var result : xlenbits = zeros();
  foreach (i from 0 to (sizeof(xlen) - 16) by 16) {
    let rs1_halfword = rs1_val[(i+15)..i];
    let rs2_byte_even = rs2_val[(i+7)..i];
    let rs2_byte_odd = rs2_val[(i+15)..(i+8)];
    let rd_halfword = rd_val[(i+15)..i];
    result[(i+15)..i] = match funct4 {
      PMULHSU_H_B0 => mulhsu_mixed(rs1_halfword, rs2_byte_even),
      PMHACCSU_H_B0 => rd_halfword + mulhsu_mixed(rs1_halfword, rs2_byte_even),
      PMULHSU_H_B1 => mulhsu_mixed(rs1_halfword, rs2_byte_odd),
      PMHACCSU_H_B1 => rd_halfword + mulhsu_mixed(rs1_halfword, rs2_byte_odd),
    };
  };
  X(rd) = result;
  RETIRE_SUCCESS
}

mapping pmulhbunsigned_mnemonic : pmulhbunsignedfunct4 <-> string = {
  PMULHSU_H_B0 <-> "pmulhsu.h.b0",
  PMHACCSU_H_B0 <-> "pmhaccsu.h.b0",
  PMULHSU_H_B1 <-> "pmulhsu.h.b1",
  PMHACCSU_H_B1 <-> "pmhaccsu.h.b1",
}

mapping clause assembly = PMULHBUNSIGNED(funct4, rs1, rs2, rd)
  <-> pmulhbunsigned_mnemonic(funct4) ^ spc() ^ reg_name(rd) ^ sep() ^ reg_name(rs1) ^ sep() ^ reg_name(rs2)
  when currentlyEnabled(Ext_P)
