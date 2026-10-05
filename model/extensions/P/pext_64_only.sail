// =======================================================================================
// This Sail RISC-V architecture model, comprising all files and
// directories except where otherwise noted is subject the BSD
// two-clause license in the LICENSE file.
//
// SPDX-License-Identifier: BSD-2-Clause
// =======================================================================================

// ******************************************************************************
// This file implements part of the pack extension.
// ******************************************************************************

// *************************** P SHIFT IMMEDIATE WORD ***************************
union clause instruction = PSHIFTIW : (pshiftiwfunct3_64only, bits(5), regidx, regidx)

mapping encdec_pshiftiwfunct3_64only : pshiftiwfunct3_64only <-> bits(3) = {
  PSLLI_W <-> 0b000,
  PSSLAI_W <-> 0b101,
}

mapping clause encdec = PSHIFTIW(funct3, imm5, rs1, rd)
  <-> 0b1 @ encdec_pshiftiwfunct3_64only(funct3) @ 0b0 @ 0b01 @ imm5 @ encdec_reg(rs1) @ 0b010 @ encdec_reg(rd) @ 0b0011011
  when currentlyEnabled(Ext_P) & xlen == 64

function clause execute (PSHIFTIW(funct3, imm5, rs1, rd)) = {
  assert(xlen == 64);
  let rs1_val = X(rs1);
  let shamt : nat = unsigned(imm5);
  var result : xlenbits = zeros();
  foreach (i from 0 to (sizeof(xlen) - 32) by 32) {
    let rs1_word = slice(rs1_val, i, 32);
    result[(i+31)..i] = match funct3 {
      PSLLI_W => rs1_word << shamt,
      PSSLAI_W => sat_shift_left_arith(rs1_word, shamt),
    };
  };
  X(rd) = result;
  RETIRE_SUCCESS
}

mapping pshiftiw_mnemonic_64only : pshiftiwfunct3_64only <-> string = {
  PSLLI_W <-> "pslli.w",
  PSSLAI_W <-> "psslai.w",
}

mapping clause assembly = PSHIFTIW(funct3, imm5, rs1, rd)
  <-> pshiftiw_mnemonic_64only(funct3) ^ spc() ^ reg_name(rd) ^ sep() ^ reg_name(rs1) ^ sep() ^ hex_bits_5(imm5)
  when currentlyEnabled(Ext_P) & xlen == 64

// *************************** P LOAD IMMEDIATE WORD ****************************
union clause instruction = PLI_W : (bits(10), regidx)

mapping clause encdec = PLI_W(imm10, rd) <->
  0b10110 @ 0b01 @ imm10 @ 0b010 @ encdec_reg(rd) @ 0b0011011
  when currentlyEnabled(Ext_P) & xlen == 64

function clause execute (PLI_W(imm10, rd)) = {
  assert(xlen == 64);
  var result : xlenbits = zeros();
  foreach (i from 0 to (sizeof(xlen) - 32) by 32) {
    result[(i+31)..i] = sign_extend(imm10[0]) @ imm10[9..1];
  };
  X(rd) = result;
  RETIRE_SUCCESS
}

mapping clause assembly = PLI_W(imm10, rd)
  <-> "pli.w" ^ spc() ^ reg_name(rd) ^ sep() ^ hex_bits_10(imm10[0] @ imm10[9..1])
  when currentlyEnabled(Ext_P) & xlen == 64

// ************************** P SIGNED EXTENSION WORD ***************************
union clause instruction = PSEXTW : (psextwfunct5_64only, regidx, regidx)

mapping encdec_psextwfunct5_64only : psextwfunct5_64only <-> bits(5) = {
  PSEXT_W_B <-> 0b00100,
  PSEXT_W_H <-> 0b00101,
}

mapping clause encdec = PSEXTW(funct5, rs1, rd) <->
  0b11100 @ 0b01 @ encdec_psextwfunct5_64only(funct5) @ encdec_reg(rs1) @ 0b010 @ encdec_reg(rd) @ 0b0011011
  when currentlyEnabled(Ext_P) & xlen == 64

function clause execute (PSEXTW(funct5, rs1, rd)) = {
  assert(xlen == 64);
  let rs1_val = X(rs1);
  var result : xlenbits = zeros();
  foreach (i from 0 to (sizeof(xlen) - 32) by 32) {
    result[(i+31)..i] = match funct5 {
      PSEXT_W_B => sign_extend(rs1_val[(i+7)..i]),
      PSEXT_W_H => sign_extend(rs1_val[(i+15)..i]),
    }
  };
  X(rd) = result;
  RETIRE_SUCCESS
}

mapping psextw_mnemonic_64only : psextwfunct5_64only <-> string = {
  PSEXT_W_B <-> "psext.w.b",
  PSEXT_W_H <-> "psext.w.h",
}

mapping clause assembly = PSEXTW(funct5, rs1, rd)
  <-> psextw_mnemonic_64only(funct5) ^ spc() ^ reg_name(rd) ^ sep() ^ reg_name(rs1)
  when currentlyEnabled(Ext_P) & xlen == 64

// ***************************** P MISC WORD (RV64) *****************************
// ABSW / CLSW: same funct7 values as the OP-IMM abs/cls, in OP-IMM-32.
union clause instruction = PMISCW_64ONLY : (pmiscfunct7, regidx, regidx)

mapping clause encdec = PMISCW_64ONLY(funct7, rs1, rd)
  <-> 0b01100 @ encdec_pmiscfunct7(funct7) @ encdec_reg(rs1) @ 0b001 @ encdec_reg(rd) @ 0b0011011
  when currentlyEnabled(Ext_P) & xlen == 64

function clause execute (PMISCW_64ONLY(funct7, rs1, rd)) = {
  assert(xlen == 64);
  let w : bits(32) = X(rs1)[31 .. 0];
  match funct7 {
    CLS => X(rd) = to_bits(count_leading_sign_bits(w)),
    ABS => X(rd) = sign_extend(abs(w)),
  };
  RETIRE_SUCCESS
}

mapping pmiscw_mnemonic_64only : pmiscfunct7 <-> string = {
  CLS <-> "clsw",
  ABS <-> "absw",
}

mapping clause assembly = PMISCW_64ONLY(funct7, rs1, rd)
  <-> pmiscw_mnemonic_64only(funct7) ^ spc() ^ reg_name(rd) ^ sep() ^ reg_name(rs1)
  when currentlyEnabled(Ext_P) & xlen == 64

// ******************************* P REV16 (RV64) *******************************
union clause instruction = PREV16_64ONLY : (regidx, regidx)

mapping clause encdec = PREV16_64ONLY(rs1, rd)
  <-> 0b011010110000 @ encdec_reg(rs1) @ 0b101 @ encdec_reg(rd) @ 0b0010011
  when currentlyEnabled(Ext_P) & xlen == 64

function clause execute (PREV16_64ONLY(rs1, rd)) = {
  assert(xlen == 64);
  let rs1_val = X(rs1);
  var result : xlenbits = zeros();
  foreach (i from 0 to (sizeof(xlen) - 16) by 16) {
    result[(i+15)..i] = rs1_val[(sizeof(xlen) - 1 - i)..(sizeof(xlen) - 16 - i)];
  };
  X(rd) = result;
  RETIRE_SUCCESS
}

mapping clause assembly = PREV16_64ONLY(rs1, rd)
  <-> "rev16" ^ spc() ^ reg_name(rd) ^ sep() ^ reg_name(rs1)
  when currentlyEnabled(Ext_P) & xlen == 64

// ************************ P LOAD UPPER IMMEDIATE WORD *************************
union clause instruction = PLUI_W : (bits(10), regidx)

mapping clause encdec = PLUI_W(imm10, rd) <->
  0b11110 @ 0b01 @ imm10 @ 0b010 @ encdec_reg(rd) @ 0b0011011
  when currentlyEnabled(Ext_P) & xlen == 64

function clause execute (PLUI_W(imm10, rd)) = {
  assert(xlen == 64);
  var result : xlenbits = zeros();
  foreach (i from 0 to (sizeof(xlen) - 32) by 32) {
    result[(i+31)..i] = imm10[8..0] @ imm10[9] @ sail_zeros(22);
  };
  X(rd) = result;
  RETIRE_SUCCESS
}

mapping clause assembly = PLUI_W(imm10, rd)
  <-> "plui.w" ^ spc() ^ reg_name(rd) ^ sep() ^ hex_bits_10(imm10[8..0] @ imm10[9])
  when currentlyEnabled(Ext_P) & xlen == 64

// ***************************** P ALU WORD SCALAR ******************************
union clause instruction = PALUWSCALAR_64ONLY : (paluwscalarfunct3_64only, regidx, regidx, regidx)

mapping encdec_paluwscalarfunct3_64only : paluwscalarfunct3_64only <-> bits(3) = {
  PSLL_WS <-> 0b000,
  PADD_WS <-> 0b001,
  PSSHL_WS <-> 0b010,
  PSSHLR_WS <-> 0b011,
  PSSHA_WS <-> 0b110,
  PSSHAR_WS <-> 0b111,
}

mapping clause encdec = PALUWSCALAR_64ONLY(funct3, rs1, rs2, rd) <->
  0b1 @ encdec_paluwscalarfunct3_64only(funct3) @ 0b1 @ 0b01 @ encdec_reg(rs2) @ encdec_reg(rs1) @ 0b010 @ encdec_reg(rd) @ 0b0011011
  when currentlyEnabled(Ext_P) & xlen == 64

function clause execute (PALUWSCALAR_64ONLY(funct3, rs1, rs2, rd)) = {
  assert(xlen == 64);
  let rs1_val = X(rs1);
  let rs2_val = X(rs2);
  var result : xlenbits = zeros();
  foreach (i from 0 to (sizeof(xlen) - 32) by 32) {
    result[(i+31)..i] = match funct3 {
      PSLL_WS => shift_bits_left(rs1_val[(i+31)..i], rs2_val[4..0]),
      PADD_WS => rs1_val[(i+31)..i] + rs2_val[31..0],
      PSSHL_WS => sshl(rs1_val[(i+31)..i], signed(rs2_val[7..0])),
      PSSHLR_WS => sshlr(rs1_val[(i+31)..i], signed(rs2_val[7..0])),
      PSSHA_WS => ssha(rs1_val[(i+31)..i], signed(rs2_val[7..0])),
      PSSHAR_WS => sshar(rs1_val[(i+31)..i], signed(rs2_val[7..0])),
    };
  };
  X(rd) = result;
  RETIRE_SUCCESS
}

mapping paluwscalar_mnemonic_64only : paluwscalarfunct3_64only <-> string = {
  PSLL_WS <-> "psll.ws",
  PADD_WS <-> "padd.ws",
  PSSHL_WS <-> "psshl.ws",
  PSSHLR_WS <-> "psshlr.ws",
  PSSHA_WS <-> "pssha.ws",
  PSSHAR_WS <-> "psshar.ws",
}

mapping clause assembly = PALUWSCALAR_64ONLY(funct3, rs1, rs2, rd)
  <-> paluwscalar_mnemonic_64only(funct3) ^ spc() ^ reg_name(rd) ^ sep() ^ reg_name(rs1) ^ sep() ^ reg_name(rs2)
  when currentlyEnabled(Ext_P) & xlen == 64

// ************************** P ALU DOUBLEWORD SCALAR ***************************
union clause instruction = PALUDSCALAR_64ONLY : (paludscalarfunct3_64only, regidx, regidx, regidx)

mapping encdec_paludscalarfunct3_64only : paludscalarfunct3_64only <-> bits(3) = {
  SHL <-> 0b010,
  SHLR <-> 0b011,
  SHA <-> 0b110,
  SHAR <-> 0b111,
}

mapping clause encdec = PALUDSCALAR_64ONLY(funct3, rs1, rs2, rd) <->
  0b1 @ encdec_paludscalarfunct3_64only(funct3) @ 0b1 @ 0b11 @ encdec_reg(rs2) @ encdec_reg(rs1) @ 0b010 @ encdec_reg(rd) @ 0b0011011
  when currentlyEnabled(Ext_P) & xlen == 64

function clause execute (PALUDSCALAR_64ONLY(funct3, rs1, rs2, rd)) = {
  assert(xlen == 64);
  let rs1_val = X(rs1);
  let rs2_val = X(rs2);
  let result : xlenbits = match funct3 {
    SHL => shl(rs1_val, signed(rs2_val[7..0])),
    SHLR => shlr(rs1_val, signed(rs2_val[7..0])),
    SHA => sha(rs1_val, signed(rs2_val[7..0])),
    SHAR => shar(rs1_val, signed(rs2_val[7..0])),
  };
  X(rd) = result;
  RETIRE_SUCCESS
}

mapping paludscalar_mnemonic_64only : paludscalarfunct3_64only <-> string = {
  SHL <-> "shl",
  SHLR <-> "shlr",
  SHA <-> "sha",
  SHAR <-> "shar",
}

mapping clause assembly = PALUDSCALAR_64ONLY(funct3, rs1, rs2, rd)
  <-> paludscalar_mnemonic_64only(funct3) ^ spc() ^ reg_name(rd) ^ sep() ^ reg_name(rs1) ^ sep() ^ reg_name(rs2)
  when currentlyEnabled(Ext_P) & xlen == 64

// ********************** P SHIFT SATURATE IMMEDIATE WORD ***********************
union clause instruction = PSHIFTSATIW_64ONLY : (pshiftsatiwfunct3_64only, bits(5), regidx, regidx)

mapping encdec_pshiftsatiwfunct3_64only : pshiftsatiwfunct3_64only <-> bits(3) = {
  PSRLI_W <-> 0b000,
  PUSATI_W <-> 0b010,
  PSRAI_W <-> 0b100,
  PSRARI_W <-> 0b101,
  PSATI_W <-> 0b110,
}

mapping clause encdec = PSHIFTSATIW_64ONLY(funct3, imm5, rs1, rd)
  <-> 0b1 @ encdec_pshiftsatiwfunct3_64only(funct3) @ 0b0 @ 0b01 @ imm5 @ encdec_reg(rs1) @ 0b100 @ encdec_reg(rd) @ 0b0011011
  when currentlyEnabled(Ext_P) & xlen == 64

function clause execute (PSHIFTSATIW_64ONLY(funct3, imm5, rs1, rd)) = {
  assert(xlen == 64);
  let rs1_val = X(rs1);
  let sa : nat = unsigned(imm5);
  var result : xlenbits = zeros();
  foreach (i from 0 to (sizeof(xlen) - 32) by 32) {
    let rs1_word = slice(rs1_val, i, 32);
    result[(i+31)..i] = match funct3 {
      PSRLI_W => rs1_word >> sa,
      PUSATI_W =>
        let maxval : bits(32) = ~(0xFFFFFFFF << sa) in
        if (rs1_word <_s 0x00000000) then { write_vxsat(0b1); 0x00000000 }
        else if (rs1_word >_s maxval) then { write_vxsat(0b1); maxval } else rs1_word,
      PSRAI_W => shift_right_arith(rs1_word, sa),
      PSRARI_W => shift_right_arith_rounding(rs1_word, sa),
      PSATI_W =>
        let minval : bits(32) = 0xFFFFFFFF << sa in
        let maxval = ~(minval) in
        if (rs1_word <_s minval) then { write_vxsat(0b1); minval }
        else if (rs1_word >_s maxval) then { write_vxsat(0b1); maxval } else rs1_word,
    };
  };
  X(rd) = result;
  RETIRE_SUCCESS
}

mapping pshiftsatiw_mnemonic_64only : pshiftsatiwfunct3_64only <-> string = {
  PSRLI_W <-> "psrli.w",
  PUSATI_W <-> "pusati.w",
  PSRAI_W <-> "psrai.w",
  PSRARI_W <-> "psrari.w",
  PSATI_W <-> "psati.w",
}

mapping clause assembly = PSHIFTSATIW_64ONLY(funct3, imm5, rs1, rd)
  <-> pshiftsatiw_mnemonic_64only(funct3) ^ spc() ^ reg_name(rd) ^ sep() ^ reg_name(rs1) ^ sep() ^ hex_bits_5(imm5)
  when currentlyEnabled(Ext_P) & xlen == 64
// ******************* P SHIFT SATURATE IMMEDIATE DOUBLEWORD ********************
// RV64 scalar sati/usati/srari (imm6). Shares its funct3 values and mnemonics
// with the RV32 scalar group, so the 32-only enum and mappings are reused.
union clause instruction = PSHIFTSATID_64ONLY : (pshiftsatiwfunct3_32only, bits(6), regidx, regidx)

mapping clause encdec = PSHIFTSATID_64ONLY(funct3, imm6, rs1, rd)
  <-> 0b1 @ encdec_pshiftsatiwfunct3_32only(funct3) @ 0b0 @ 0b1 @ imm6 @ encdec_reg(rs1) @ 0b100 @ encdec_reg(rd) @ 0b0011011
  when currentlyEnabled(Ext_P) & xlen == 64

function clause execute (PSHIFTSATID_64ONLY(funct3, imm6, rs1, rd)) = {
  assert(xlen == 64);
  let rs1_val = X(rs1);
  let sa : nat = unsigned(imm6);
  let result : xlenbits = match funct3 {
    USATI =>
      let maxval : bits(xlen) = not_vec(ones(xlen) << sa) in
      if (rs1_val <_s zeros(xlen)) then { write_vxsat(0b1); zeros(xlen) }
      else if (rs1_val >_s maxval) then { write_vxsat(0b1); maxval } else rs1_val,
    SRARI => shift_right_arith_rounding(rs1_val, sa),
    SATI =>
      let minval : bits(xlen) = ones(xlen) << sa in
      let maxval = not_vec(minval) in
      if (rs1_val <_s minval) then { write_vxsat(0b1); minval }
      else if (rs1_val >_s maxval) then { write_vxsat(0b1); maxval } else rs1_val,
  };
  X(rd) = result;
  RETIRE_SUCCESS
}

mapping clause assembly = PSHIFTSATID_64ONLY(funct3, imm6, rs1, rd)
  <-> pshiftsatiw_mnemonic_32only(funct3) ^ spc() ^ reg_name(rd) ^ sep() ^ reg_name(rs1) ^ sep() ^ hex_bits_6(imm6)
  when currentlyEnabled(Ext_P) & xlen == 64

// **************************** P SHIFT WORD SCALAR *****************************
union clause instruction = PSHIFTWSCALAR_64ONLY : (pshiftwscalarfunct3_64only, regidx, regidx, regidx)

mapping encdec_pshiftwscalarfunct3_64only : pshiftwscalarfunct3_64only <-> bits(3) = {
  PSRL_WS <-> 0b000,
  PSRA_WS <-> 0b100,
}

mapping clause encdec = PSHIFTWSCALAR_64ONLY(funct3, rs1, rs2, rd) <->
  0b1 @ encdec_pshiftwscalarfunct3_64only(funct3) @ 0b1 @ 0b01 @ encdec_reg(rs2) @ encdec_reg(rs1) @ 0b100 @ encdec_reg(rd) @ 0b0011011
  when currentlyEnabled(Ext_P) & xlen == 64

function clause execute (PSHIFTWSCALAR_64ONLY(funct3, rs1, rs2, rd)) = {
  assert(xlen == 64);
  let rs1_val = X(rs1);
  let rs2_val = X(rs2);
  var result : xlenbits = zeros();
  foreach (i from 0 to (sizeof(xlen) - 32) by 32) {
    let rs1_word = slice(rs1_val, i, 32);
    result[(i+31)..i] = match funct3 {
      PSRL_WS => rs1_word >> rs2_val[4..0],
      PSRA_WS => shift_right_arith(rs1_word, unsigned(rs2_val[4..0])),
    };
  };
  X(rd) = result;
  RETIRE_SUCCESS
}

mapping pshiftwscalar_mnemonic_64only : pshiftwscalarfunct3_64only <-> string = {
  PSRL_WS <-> "psrl.ws",
  PSRA_WS <-> "psra.ws",
}

mapping clause assembly = PSHIFTWSCALAR_64ONLY(funct3, rs1, rs2, rd)
  <-> pshiftwscalar_mnemonic_64only(funct3) ^ spc() ^ reg_name(rd) ^ sep() ^ reg_name(rs1) ^ sep() ^ reg_name(rs2)
  when currentlyEnabled(Ext_P) & xlen == 64

// ************************ P REDUCTION SUM WORD SCALAR *************************
union clause instruction = PREDSUMWSCALAR_64ONLY : (predsumwscalarfunct3_64only, regidx, regidx, regidx)

mapping encdec_predsumwscalarfunct3_64only : predsumwscalarfunct3_64only <-> bits(3) = {
  PREDSUM_WS <-> 0b001,
  PREDSUMU_WS <-> 0b011,
}

mapping clause encdec = PREDSUMWSCALAR_64ONLY(funct3, rs1, rs2, rd) <->
  0b1 @ encdec_predsumwscalarfunct3_64only(funct3) @ 0b1 @ 0b01 @ encdec_reg(rs2) @ encdec_reg(rs1) @ 0b100 @ encdec_reg(rd) @ 0b0011011
  when currentlyEnabled(Ext_P) & xlen == 64

function clause execute (PREDSUMWSCALAR_64ONLY(funct3, rs1, rs2, rd)) = {
  assert(xlen == 64);
  let rs1_val = X(rs1);
  let rs2_val = X(rs2);
  var result : xlenbits = rs2_val;
  foreach (i from 0 to (sizeof(xlen) - 32) by 32) {
    let rs1_word = slice(rs1_val, i, 32);
    result = match funct3 {
      PREDSUM_WS => result + sign_extend(rs1_word),
      PREDSUMU_WS => result + zero_extend(rs1_word),
    };
  };
  X(rd) = result;
  RETIRE_SUCCESS
}

mapping predsumwscalar_mnemonic_64only : predsumwscalarfunct3_64only <-> string = {
  PREDSUM_WS <-> "predsum.ws",
  PREDSUMU_WS <-> "predsumu.ws",
}

mapping clause assembly = PREDSUMWSCALAR_64ONLY(funct3, rs1, rs2, rd)
  <-> predsumwscalar_mnemonic_64only(funct3) ^ spc() ^ reg_name(rd) ^ sep() ^ reg_name(rs1) ^ sep() ^ reg_name(rs2)
  when currentlyEnabled(Ext_P) & xlen == 64

// **************************** P REDUCTION ALU WORD ****************************
union clause instruction = PALUW_64ONLY : (paluwfunct4_64only, regidx, regidx, regidx)

mapping encdec_paluwfunct4_64only : paluwfunct4_64only <-> bits(4) = {
  PADD_W <-> 0b0000,
  PSADD_W <-> 0b0010,
  PAADD_W <-> 0b0011,
  PSADDU_W <-> 0b0110,
  PAADDU_W <-> 0b0111,
  PSUB_W <-> 0b1000,
  PSSUB_W <-> 0b1010,
  PASUB_W <-> 0b1011,
  PSSUBU_W <-> 0b1110,
  PASUBU_W <-> 0b1111,
}

mapping clause encdec = PALUW_64ONLY(funct4, rs1, rs2, rd) <->
  0b1 @ encdec_paluwfunct4_64only(funct4) @ 0b01 @ encdec_reg(rs2) @ encdec_reg(rs1) @ 0b000 @ encdec_reg(rd) @ 0b0111011
  when currentlyEnabled(Ext_P) & xlen == 64

function clause execute (PALUW_64ONLY(funct4, rs1, rs2, rd)) = {
  assert(xlen == 64);
  let rs1_val = X(rs1);
  let rs2_val = X(rs2);
  var result : xlenbits = rs2_val;
  foreach (i from 0 to (sizeof(xlen) - 32) by 32) {
    let rs1_word = slice(rs1_val, i, 32);
    let rs2_word = slice(rs2_val, i, 32);
    result[(i+31)..i] = match funct4 {
      PADD_W => rs1_word + rs2_word,
      PSADD_W => sadd(rs1_word, rs2_word),
      PAADD_W => aadd(rs1_word, rs2_word),
      PSADDU_W => saddu(rs1_word, rs2_word),
      PAADDU_W => aaddu(rs1_word, rs2_word),
      PSUB_W => rs1_word - rs2_word,
      PSSUB_W => ssub(rs1_word, rs2_word),
      PASUB_W => asub(rs1_word, rs2_word),
      PSSUBU_W => ssubu(rs1_word, rs2_word),
      PASUBU_W => asubu(rs1_word, rs2_word),
    };
  };
  X(rd) = result;
  RETIRE_SUCCESS
}

mapping paluw_mnemonic_64only : paluwfunct4_64only <-> string = {
  PADD_W <-> "padd.w",
  PSADD_W <-> "psadd.w",
  PAADD_W <-> "paadd.w",
  PSADDU_W <-> "psaddu.w",
  PAADDU_W <-> "paaddu.w",
  PSUB_W <-> "psub.w",
  PSSUB_W <-> "pssub.w",
  PASUB_W <-> "pasub.w",
  PSSUBU_W <-> "pssubu.w",
  PASUBU_W <-> "pasubu.w",
}

mapping clause assembly = PALUW_64ONLY(funct4, rs1, rs2, rd)
  <-> paluw_mnemonic_64only(funct4) ^ spc() ^ reg_name(rd) ^ sep() ^ reg_name(rs1) ^ sep() ^ reg_name(rs2)
  when currentlyEnabled(Ext_P) & xlen == 64

// ********************* P MULTIPLICATION WORD HALFWORD 01 **********************
union clause instruction = PMULWH01_64ONLY : (pmulwh01funct4_64only, regidx, regidx, regidx)

mapping encdec_pmulwh01funct4_64only : pmulwh01funct4_64only <-> bits(4) = {
  PMUL_W_H01 <-> 0b0010,
  PMACC_W_H01 <-> 0b0011,
  PMULU_W_H01 <-> 0b0110,
  PMACCU_W_H01 <-> 0b0111,
}

mapping clause encdec = PMULWH01_64ONLY(funct4, rs1, rs2, rd) <->
  0b1 @ encdec_pmulwh01funct4_64only(funct4) @ 0b01 @ encdec_reg(rs2) @ encdec_reg(rs1) @ 0b001 @ encdec_reg(rd) @ 0b0111011
  when currentlyEnabled(Ext_P) & xlen == 64

function clause execute (PMULWH01_64ONLY(funct4, rs1, rs2, rd)) = {
  assert(xlen == 64);
  let rs1_val = X(rs1);
  let rs2_val = X(rs2);
  var result = X(rd);
  foreach (i from 0 to (sizeof(xlen) - 32) by 32) {
    let rs1_halfword = rs1_val[(i+15)..i];
    let rs2_halfword = rs2_val[(i+31)..(i+16)];
    result[(i+31)..i] = match funct4 {
      PMUL_W_H01 => muls(rs1_halfword, rs2_halfword),
      PMACC_W_H01 => result[(i+31)..i] + muls(rs1_halfword, rs2_halfword),
      PMULU_W_H01 => mulu(rs1_halfword, rs2_halfword),
      PMACCU_W_H01 => result[(i+31)..i] + mulu(rs1_halfword, rs2_halfword),
    };
  };
  X(rd) = result;
  RETIRE_SUCCESS
}

mapping pmulwh01_mnemonic_64only : pmulwh01funct4_64only <-> string = {
  PMUL_W_H01 <-> "pmul.w.h01",
  PMACC_W_H01 <-> "pmacc.w.h01",
  PMULU_W_H01 <-> "pmulu.w.h01",
  PMACCU_W_H01 <-> "pmaccu.w.h01",
}

mapping clause assembly = PMULWH01_64ONLY(funct4, rs1, rs2, rd)
  <-> pmulwh01_mnemonic_64only(funct4) ^ spc() ^ reg_name(rd) ^ sep() ^ reg_name(rs1) ^ sep() ^ reg_name(rs2)
  when currentlyEnabled(Ext_P) & xlen == 64

// ******************** P MULTIPLICATION DOUBLEWORD WORD 01 *********************
union clause instruction = PMULDW01_64ONLY : (pmuldw01funct4_64only, regidx, regidx, regidx)

mapping encdec_pmuldw01funct4_64only : pmuldw01funct4_64only <-> bits(4) = {
  MUL_W01 <-> 0b0010,
  MACC_W01 <-> 0b0011,
  MULU_W01 <-> 0b0110,
  MACCU_W01 <-> 0b0111,
}

mapping clause encdec = PMULDW01_64ONLY(funct4, rs1, rs2, rd) <->
  0b1 @ encdec_pmuldw01funct4_64only(funct4) @ 0b11 @ encdec_reg(rs2) @ encdec_reg(rs1) @ 0b001 @ encdec_reg(rd) @ 0b0111011
  when currentlyEnabled(Ext_P) & xlen == 64

function clause execute (PMULDW01_64ONLY(funct4, rs1, rs2, rd)) = {
  assert(xlen == 64);
  let rs1_val = X(rs1);
  let rs2_val = X(rs2);
  let rd_val = X(rd);
  let rs1_word = rs1_val[31..0];
  let rs2_word = rs2_val[63..32];
  let result : xlenbits = match funct4 {
    MUL_W01 => muls(rs1_word, rs2_word),
    MACC_W01 => rd_val + muls(rs1_word, rs2_word),
    MULU_W01 => mulu(rs1_word, rs2_word),
    MACCU_W01 => rd_val + mulu(rs1_word, rs2_word),
  };
  X(rd) = result;
  RETIRE_SUCCESS
}

mapping pmuldw01_mnemonic_64only : pmuldw01funct4_64only <-> string = {
  MUL_W01 <-> "mul.w01",
  MACC_W01 <-> "macc.w01",
  MULU_W01 <-> "mulu.w01",
  MACCU_W01 <-> "maccu.w01",
}

mapping clause assembly = PMULDW01_64ONLY(funct4, rs1, rs2, rd)
  <-> pmuldw01_mnemonic_64only(funct4) ^ spc() ^ reg_name(rd) ^ sep() ^ reg_name(rs1) ^ sep() ^ reg_name(rs2)
  when currentlyEnabled(Ext_P) & xlen == 64

// **************************** P SHIFT ONE ADD WORD ****************************
union clause instruction = PSHIFTONEADDW_64ONLY : (pshiftoneaddwfunct3_64only, regidx, regidx, regidx)

mapping encdec_pshiftoneaddwfunct3_64only : pshiftoneaddwfunct3_64only <-> bits(3) = {
  PSH1ADD_W <-> 0b010,
  PSSH1SADD_W <-> 0b011,
}

mapping clause encdec = PSHIFTONEADDW_64ONLY(funct3, rs1, rs2, rd) <->
  0b1 @ encdec_pshiftoneaddwfunct3_64only(funct3) @ 0b0 @ 0b01 @ encdec_reg(rs2) @ encdec_reg(rs1) @ 0b010 @ encdec_reg(rd) @ 0b0111011
  when currentlyEnabled(Ext_P) & xlen == 64

function clause execute (PSHIFTONEADDW_64ONLY(funct3, rs1, rs2, rd)) = {
  assert(xlen == 64);
  let rs1_val = X(rs1);
  let rs2_val = X(rs2);
  var result : xlenbits = zeros();
  foreach (i from 0 to (sizeof(xlen) - 32) by 32) {
    result[(i+31)..i] = match funct3 {
      PSH1ADD_W => (rs1_val[(i+31)..i] << 1) + rs2_val[(i+31)..i],
      PSSH1SADD_W => sadd(sat_shift_left_arith(rs1_val[(i+31)..i], 1), rs2_val[(i+31)..i]),
    };
  };
  X(rd) = result;
  RETIRE_SUCCESS
}

mapping pshiftoneaddw_mnemonic_64only : pshiftoneaddwfunct3_64only <-> string = {
  PSH1ADD_W <-> "psh1add.w",
  PSSH1SADD_W <-> "pssh1sadd.w",
}

mapping clause assembly = PSHIFTONEADDW_64ONLY(funct3, rs1, rs2, rd)
  <-> pshiftoneaddw_mnemonic_64only(funct3) ^ spc() ^ reg_name(rd) ^ sep() ^ reg_name(rs1) ^ sep() ^ reg_name(rs2)
  when currentlyEnabled(Ext_P) & xlen == 64

// ************************* P NARROWING SATURATE BYTE **************************
union clause instruction = PNARROWSATB_64ONLY : (pnarrowsatbfunct3_64only, regidx, regidx, regidx)

mapping encdec_pnarrowsatbfunct3_64only : pnarrowsatbfunct3_64only <-> bits(3) = {
  PNCLIPUP_B <-> 0b000,
  PNCLIPP_B <-> 0b100,
}

mapping clause encdec = PNARROWSATB_64ONLY(funct3, rs1, rs2, rd) <->
  0b1 @ encdec_pnarrowsatbfunct3_64only(funct3) @ 0b0 @ 0b00 @ encdec_reg(rs2) @ encdec_reg(rs1) @ 0b010 @ encdec_reg(rd) @ 0b0111011
  when currentlyEnabled(Ext_P) & xlen == 64

function clause execute (PNARROWSATB_64ONLY(funct3, rs1, rs2, rd)) = {
  assert(xlen == 64);
  let rs_val = X(rs2) @ X(rs1);
  var result : xlenbits = zeros();
  foreach (i from 0 to (sizeof(xlen) - 8) by 8) {
    result[(i+7)..i] = match funct3 {
      PNCLIPUP_B => nclipu(rs_val[(i*2+15)..(i*2)], 0),
      PNCLIPP_B => nclips(rs_val[(i*2+15)..(i*2)], 0),
    };
  };
  X(rd) = result;
  RETIRE_SUCCESS
}

mapping pnarrowsatb_mnemonic_64only : pnarrowsatbfunct3_64only <-> string = {
  PNCLIPUP_B <-> "pnclipup.b",
  PNCLIPP_B <-> "pnclipp.b",
}

mapping clause assembly = PNARROWSATB_64ONLY(funct3, rs1, rs2, rd)
  <-> pnarrowsatb_mnemonic_64only(funct3) ^ spc() ^ reg_name(rd) ^ sep() ^ reg_name(rs1) ^ sep() ^ reg_name(rs2)
  when currentlyEnabled(Ext_P) & xlen == 64

// *********************** P NARROWING SATURATE HALFBYTE ************************
union clause instruction = PNARROWSATH_64ONLY : (pnarrowsathfunct3_64only, regidx, regidx, regidx)

mapping encdec_pnarrowsathfunct3_64only : pnarrowsathfunct3_64only <-> bits(3) = {
  PNCLIPUP_H <-> 0b000,
  PNCLIPP_H <-> 0b100,
}

mapping clause encdec = PNARROWSATH_64ONLY(funct3, rs1, rs2, rd) <->
  0b1 @ encdec_pnarrowsathfunct3_64only(funct3) @ 0b0 @ 0b01 @ encdec_reg(rs2) @ encdec_reg(rs1) @ 0b010 @ encdec_reg(rd) @ 0b0111011
  when currentlyEnabled(Ext_P) & xlen == 64

function clause execute (PNARROWSATH_64ONLY(funct3, rs1, rs2, rd)) = {
  assert(xlen == 64);
  let rs_val = X(rs2) @ X(rs1);
  var result : xlenbits = zeros();
  foreach (i from 0 to (sizeof(xlen) - 16) by 16) {
    result[(i+15)..i] = match funct3 {
      PNCLIPUP_H => nclipu(rs_val[(i*2+31)..(i*2)], 0),
      PNCLIPP_H => nclips(rs_val[(i*2+31)..(i*2)], 0),
    };
  };
  X(rd) = result;
  RETIRE_SUCCESS
}

mapping pnarrowsath_mnemonic_64only : pnarrowsathfunct3_64only <-> string = {
  PNCLIPUP_H <-> "pnclipup.h",
  PNCLIPP_H <-> "pnclipp.h",
}

mapping clause assembly = PNARROWSATH_64ONLY(funct3, rs1, rs2, rd)
  <-> pnarrowsath_mnemonic_64only(funct3) ^ spc() ^ reg_name(rd) ^ sep() ^ reg_name(rs1) ^ sep() ^ reg_name(rs2)
  when currentlyEnabled(Ext_P) & xlen == 64

// ************************* P NARROWING SATURATE WORD **************************
union clause instruction = PNARROWSATW_64ONLY : (pnarrowsatwfunct3_64only, regidx, regidx, regidx)

mapping encdec_pnarrowsatwfunct3_64only : pnarrowsatwfunct3_64only <-> bits(3) = {
  PNCLIPUP_W <-> 0b000,
  PNCLIPP_W <-> 0b100,
}

mapping clause encdec = PNARROWSATW_64ONLY(funct3, rs1, rs2, rd) <->
  0b1 @ encdec_pnarrowsatwfunct3_64only(funct3) @ 0b0 @ 0b11 @ encdec_reg(rs2) @ encdec_reg(rs1) @ 0b010 @ encdec_reg(rd) @ 0b0111011
  when currentlyEnabled(Ext_P) & xlen == 64

function clause execute (PNARROWSATW_64ONLY(funct3, rs1, rs2, rd)) = {
  assert(xlen == 64);
  let rs_val = X(rs2) @ X(rs1);
  var result : xlenbits = zeros();
  foreach (i from 0 to (sizeof(xlen) - 32) by 32) {
    result[(i+31)..i] = match funct3 {
      PNCLIPUP_W => nclipu(rs_val[(i*2+63)..(i*2)], 0),
      PNCLIPP_W => nclips(rs_val[(i*2+63)..(i*2)], 0),
    };
  };
  X(rd) = result;
  RETIRE_SUCCESS
}

mapping pnarrowsatw_mnemonic_64only : pnarrowsatwfunct3_64only <-> string = {
  PNCLIPUP_W <-> "pnclipup.w",
  PNCLIPP_W <-> "pnclipp.w",
}

mapping clause assembly = PNARROWSATW_64ONLY(funct3, rs1, rs2, rd)
  <-> pnarrowsatw_mnemonic_64only(funct3) ^ spc() ^ reg_name(rd) ^ sep() ^ reg_name(rs1) ^ sep() ^ reg_name(rs2)
  when currentlyEnabled(Ext_P) & xlen == 64

// ********************************** P UNZIP ***********************************
union clause instruction = PUNZIP_64ONLY : (punzipwidth2_64only, regidx, regidx, regidx)

mapping encdec_punzipwidth2_64only : punzipwidth2_64only <-> bits(2) = {
  UNZIP8P <-> 0b00,
  UNZIP16P <-> 0b01,
  UNZIP8HP <-> 0b10,
  UNZIP16HP <-> 0b11,
}

mapping clause encdec = PUNZIP_64ONLY(width2, rs1, rs2, rd) <->
  0b1 @ 0b110 @ 0b0 @ encdec_punzipwidth2_64only(width2) @ encdec_reg(rs2) @ encdec_reg(rs1) @ 0b010 @ encdec_reg(rd) @ 0b0111011
  when currentlyEnabled(Ext_P) & xlen == 64

function clause execute (PUNZIP_64ONLY(width2, rs1, rs2, rd)) = {
  assert(xlen == 64);
  let rs1_val = X(rs1);
  let rs2_val = X(rs2);
  var result : xlenbits = zeros();
  result = match width2 {
    UNZIP8P => rs2_val[55..48] @ rs2_val[39..32] @ rs2_val[23..16] @ rs2_val[7..0]
                   @ rs1_val[55..48] @ rs1_val[39..32] @ rs1_val[23..16] @ rs1_val[7..0],
    UNZIP16P => rs2_val[47..32] @ rs2_val[15..0] @ rs1_val[47..32] @ rs1_val[15..0],
    UNZIP8HP => rs2_val[63..56] @ rs2_val[47..40] @ rs2_val[31..24] @ rs2_val[15..8]
                    @ rs1_val[63..56] @ rs1_val[47..40] @ rs1_val[31..24] @ rs1_val[15..8],
    UNZIP16HP => rs2_val[63..48] @ rs2_val[31..16] @ rs1_val[63..48] @ rs1_val[31..16],
  };
  X(rd) = result;
  RETIRE_SUCCESS
}

mapping punzipwidth2_mnemonic_64only : punzipwidth2_64only <-> string = {
  UNZIP8P <-> "unzip8p",
  UNZIP16P <-> "unzip16p",
  UNZIP8HP <-> "unzip8hp",
  UNZIP16HP <-> "unzip16hp",
}

mapping clause assembly = PUNZIP_64ONLY(width2, rs1, rs2, rd)
  <-> punzipwidth2_mnemonic_64only(width2) ^ spc() ^ reg_name(rd) ^ sep() ^ reg_name(rs1) ^ sep() ^ reg_name(rs2)
  when currentlyEnabled(Ext_P) & xlen == 64

// *********************************** P ZIP ************************************
union clause instruction = PZIP_64ONLY : (pzipwidth2_64only, regidx, regidx, regidx)

mapping encdec_pzipwidth2_64only : pzipwidth2_64only <-> bits(2) = {
  ZIP8P <-> 0b00,
  ZIP16P <-> 0b01,
  ZIP8HP <-> 0b10,
  ZIP16HP <-> 0b11,
}

mapping clause encdec = PZIP_64ONLY(width2, rs1, rs2, rd) <->
  0b1 @ 0b111 @ 0b0 @ encdec_pzipwidth2_64only(width2) @ encdec_reg(rs2) @ encdec_reg(rs1) @ 0b010 @ encdec_reg(rd) @ 0b0111011
  when currentlyEnabled(Ext_P) & xlen == 64

function clause execute (PZIP_64ONLY(width2, rs1, rs2, rd)) = {
  assert(xlen == 64);
  let rs1_val = X(rs1);
  let rs2_val = X(rs2);
  var result : xlenbits = zeros();
  result = match width2 {
    ZIP8P => rs2_val[31..24] @ rs1_val[31..24] @ rs2_val[23..16] @ rs1_val[23..16]
                 @ rs2_val[15..8] @ rs1_val[15..8] @ rs2_val[7..0] @ rs1_val[7..0],
    ZIP16P => rs2_val[31..16] @ rs1_val[31..16] @ rs2_val[15..0] @ rs1_val[15..0],
    ZIP8HP => rs2_val[63..56] @ rs1_val[63..56] @ rs2_val[55..48] @ rs1_val[55..48]
                  @ rs2_val[47..40] @ rs1_val[47..40] @ rs2_val[39..32] @ rs1_val[39..32],
    ZIP16HP => rs2_val[63..48] @ rs1_val[63..48] @ rs2_val[47..32] @ rs1_val[47..32],
  };
  X(rd) = result;
  RETIRE_SUCCESS
}

mapping pzipwidth2_mnemonic_64only : pzipwidth2_64only <-> string = {
  ZIP8P <-> "zip8p",
  ZIP16P <-> "zip16p",
  ZIP8HP <-> "zip8hp",
  ZIP16HP <-> "zip16hp",
}

mapping clause assembly = PZIP_64ONLY(width2, rs1, rs2, rd)
  <-> pzipwidth2_mnemonic_64only(width2) ^ spc() ^ reg_name(rd) ^ sep() ^ reg_name(rs1) ^ sep() ^ reg_name(rs2)
  when currentlyEnabled(Ext_P) & xlen == 64

// *********************** P MULTIPLICATION WORD HALFWORD ***********************
union clause instruction = PMULWH_64ONLY : (pmulwhfunct4_64only, regidx, regidx, regidx)

mapping encdec_pmulwhfunct4_64only : pmulwhfunct4_64only <-> bits(4) = {
  PMUL_W_H00 <-> 0b0000,
  PMACC_W_H00 <-> 0b0001,
  PMUL_W_H11 <-> 0b0010,
  PMACC_W_H11 <-> 0b0011,
  PMULU_W_H00 <-> 0b0100,
  PMACCU_W_H00 <-> 0b0101,
  PMULU_W_H11 <-> 0b0110,
  PMACCU_W_H11 <-> 0b0111,
  PMULSU_W_H00 <-> 0b1100,
  PMACCSU_W_H00 <-> 0b1101,
  PMULSU_W_H11 <-> 0b1110,
  PMACCSU_W_H11 <-> 0b1111,
}

mapping clause encdec = PMULWH_64ONLY(funct4, rs1, rs2, rd) <->
  0b1 @ encdec_pmulwhfunct4_64only(funct4) @ 0b01 @ encdec_reg(rs2) @ encdec_reg(rs1) @ 0b011 @ encdec_reg(rd) @ 0b0111011
  when currentlyEnabled(Ext_P) & xlen == 64

function clause execute (PMULWH_64ONLY(funct4, rs1, rs2, rd)) = {
  assert(xlen == 64);
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
      PMUL_W_H00 => muls(rs1_halfword_even, rs2_halfword_even),
      PMACC_W_H00 => rd_val[(i+31)..i] + muls(rs1_halfword_even, rs2_halfword_even),
      PMUL_W_H11 => muls(rs1_halfword_odd, rs2_halfword_odd),
      PMACC_W_H11 => rd_val[(i+31)..i] + muls(rs1_halfword_odd, rs2_halfword_odd),
      PMULU_W_H00 => mulu(rs1_halfword_even, rs2_halfword_even),
      PMACCU_W_H00 => rd_val[(i+31)..i] + mulu(rs1_halfword_even, rs2_halfword_even),
      PMULU_W_H11 => mulu(rs1_halfword_odd, rs2_halfword_odd),
      PMACCU_W_H11 => rd_val[(i+31)..i] + mulu(rs1_halfword_odd, rs2_halfword_odd),
      PMULSU_W_H00 => mulsu(rs1_halfword_even, rs2_halfword_even),
      PMACCSU_W_H00 => rd_val[(i+31)..i] + mulsu(rs1_halfword_even, rs2_halfword_even),
      PMULSU_W_H11 => mulsu(rs1_halfword_odd, rs2_halfword_odd),
      PMACCSU_W_H11 => rd_val[(i+31)..i] + mulsu(rs1_halfword_odd, rs2_halfword_odd),
    };
  };
  X(rd) = result;
  RETIRE_SUCCESS
}

mapping pmulwh_mnemonic_64only : pmulwhfunct4_64only <-> string = {
  PMUL_W_H00 <-> "pmul.w.h00",
  PMUL_W_H11 <-> "pmul.w.h11",
  PMULU_W_H00 <-> "pmulu.w.h00",
  PMULU_W_H11 <-> "pmulu.w.h11",
  PMULSU_W_H00 <-> "pmulsu.w.h00",
  PMULSU_W_H11 <-> "pmulsu.w.h11",
  PMACC_W_H00 <-> "pmacc.w.h00",
  PMACC_W_H11 <-> "pmacc.w.h11",
  PMACCU_W_H00 <-> "pmaccu.w.h00",
  PMACCU_W_H11 <-> "pmaccu.w.h11",
  PMACCSU_W_H00 <-> "pmaccsu.w.h00",
  PMACCSU_W_H11 <-> "pmaccsu.w.h11",
}

mapping clause assembly = PMULWH_64ONLY(funct4, rs1, rs2, rd)
  <-> pmulwh_mnemonic_64only(funct4) ^ spc() ^ reg_name(rd) ^ sep() ^ reg_name(rs1) ^ sep() ^ reg_name(rs2)
  when currentlyEnabled(Ext_P) & xlen == 64

// ********************** P MULTIPLICATION DOUBLEWORD WORD **********************
union clause instruction = PMULDW_64ONLY : (pmuldwfunct4_64only, regidx, regidx, regidx)

mapping encdec_pmuldwfunct4_64only : pmuldwfunct4_64only <-> bits(4) = {
  MUL_W00 <-> 0b0000,
  MACC_W00 <-> 0b0001,
  MUL_W11 <-> 0b0010,
  MACC_W11 <-> 0b0011,
  MULU_W00 <-> 0b0100,
  MACCU_W00 <-> 0b0101,
  MULU_W11 <-> 0b0110,
  MACCU_W11 <-> 0b0111,
  MULSU_W00 <-> 0b1100,
  MACCSU_W00 <-> 0b1101,
  MULSU_W11 <-> 0b1110,
  MACCSU_W11 <-> 0b1111,
}

mapping clause encdec = PMULDW_64ONLY(funct4, rs1, rs2, rd) <->
  0b1 @ encdec_pmuldwfunct4_64only(funct4) @ 0b11 @ encdec_reg(rs2) @ encdec_reg(rs1) @ 0b011 @ encdec_reg(rd) @ 0b0111011
  when currentlyEnabled(Ext_P) & xlen == 64

function clause execute (PMULDW_64ONLY(funct4, rs1, rs2, rd)) = {
  assert(xlen == 64);
  let rs1_val = X(rs1);
  let rs2_val = X(rs2);
  let rd_val = X(rd);
  let rs1_word_even = rs1_val[31..0];
  let rs2_word_even = rs2_val[31..0];
  let rs1_word_odd = rs1_val[63..32];
  let rs2_word_odd = rs2_val[63..32];
  let result : xlenbits = match funct4 {
    MUL_W00 => muls(rs1_word_even, rs2_word_even),
    MACC_W00 => rd_val + muls(rs1_word_even, rs2_word_even),
    MUL_W11 => muls(rs1_word_odd, rs2_word_odd),
    MACC_W11 => rd_val + muls(rs1_word_odd, rs2_word_odd),
    MULU_W00 => mulu(rs1_word_even, rs2_word_even),
    MACCU_W00 => rd_val + mulu(rs1_word_even, rs2_word_even),
    MULU_W11 => mulu(rs1_word_odd, rs2_word_odd),
    MACCU_W11 => rd_val + mulu(rs1_word_odd, rs2_word_odd),
    MULSU_W00 => mulsu(rs1_word_even, rs2_word_even),
    MACCSU_W00 => rd_val + mulsu(rs1_word_even, rs2_word_even),
    MULSU_W11 => mulsu(rs1_word_odd, rs2_word_odd),
    MACCSU_W11 => rd_val + mulsu(rs1_word_odd, rs2_word_odd),
  };
  X(rd) = result;
  RETIRE_SUCCESS
}

mapping pmuldw_mnemonic_64only : pmuldwfunct4_64only <-> string = {
  MUL_W00 <-> "mul.w00",
  MACC_W00 <-> "macc.w00",
  MUL_W11 <-> "mul.w11",
  MACC_W11 <-> "macc.w11",
  MULU_W00 <-> "mulu.w00",
  MACCU_W00 <-> "maccu.w00",
  MULU_W11 <-> "mulu.w11",
  MACCU_W11 <-> "maccu.w11",
  MULSU_W00 <-> "mulsu.w00",
  MACCSU_W00 <-> "maccsu.w00",
  MULSU_W11 <-> "mulsu.w11",
  MACCSU_W11 <-> "maccsu.w11",
}

mapping clause assembly = PMULDW_64ONLY(funct4, rs1, rs2, rd)
  <-> pmuldw_mnemonic_64only(funct4) ^ spc() ^ reg_name(rd) ^ sep() ^ reg_name(rs1) ^ sep() ^ reg_name(rs2)
  when currentlyEnabled(Ext_P) & xlen == 64

// ****************************** P PAIR HALFWORD *******************************
union clause instruction = PPAIRH_64ONLY : (regidx, regidx, regidx)

mapping clause encdec = PPAIRH_64ONLY(rs1, rs2, rd) <->
  0b1 @ 0b000 @ 0b0 @ 0b01 @ encdec_reg(rs2) @ encdec_reg(rs1) @ 0b100 @ encdec_reg(rd) @ 0b0111011
  when currentlyEnabled(Ext_P) & xlen == 64

function clause execute (PPAIRH_64ONLY(rs1, rs2, rd)) = {
  assert(xlen == 64);
  let rs1_val = X(rs1);
  let rs2_val = X(rs2);
  var result : xlenbits = zeros();
  foreach (i from 0 to (sizeof(xlen) - 32) by 32) {
    let rs1_halfword_even = slice(rs1_val, i, 16);
    let rs2_halfword_even = slice(rs2_val, i, 16);
    result[(i+31)..i] = rs2_halfword_even @ rs1_halfword_even;
  };
  X(rd) = result;
  RETIRE_SUCCESS
}

mapping clause assembly = PPAIRH_64ONLY(rs1, rs2, rd)
  <-> "ppaire.h" ^ spc() ^ reg_name(rd) ^ sep() ^ reg_name(rs1) ^ sep() ^ reg_name(rs2)
  when currentlyEnabled(Ext_P) & xlen == 64

// ******************************** P PAIR WORD *********************************
union clause instruction = PPAIRW_64ONLY : (ppairwfunct3_64only, regidx, regidx, regidx)

mapping encdec_ppairwfunct3 : ppairwfunct3_64only <-> bits(3) = {
  PPAIREO_W <-> 0b001,
  PPAIROE_W <-> 0b010,
  PPAIRO_W <-> 0b011,
}

mapping clause encdec = PPAIRW_64ONLY(funct3, rs1, rs2, rd) <->
  0b1 @ encdec_ppairwfunct3(funct3) @ 0b0 @ 0b11 @ encdec_reg(rs2) @ encdec_reg(rs1) @ 0b100 @ encdec_reg(rd) @ 0b0111011
  when currentlyEnabled(Ext_P) & xlen == 64

function clause execute (PPAIRW_64ONLY(funct3, rs1, rs2, rd)) = {
  assert(xlen == 64);
  let rs1_val = X(rs1);
  let rs2_val = X(rs2);
  let rs1_word_even = rs1_val[31..0];
  let rs2_word_even = rs2_val[31..0];
  let rs1_word_odd = rs1_val[63..32];
  let rs2_word_odd = rs2_val[63..32];
  let result : xlenbits = match funct3 {
    PPAIREO_W => rs2_word_odd @ rs1_word_even,
    PPAIROE_W => rs2_word_even @ rs1_word_odd,
    PPAIRO_W => rs2_word_odd @ rs1_word_odd,
  };
  X(rd) = result;
  RETIRE_SUCCESS
}

mapping ppairw_mnemonic_64only : ppairwfunct3_64only <-> string = {
  PPAIREO_W <-> "ppaireo.w",
  PPAIROE_W <-> "ppairoe.w",
  PPAIRO_W <-> "ppairo.w",
}

mapping clause assembly = PPAIRW_64ONLY(funct3, rs1, rs2, rd)
  <-> ppairw_mnemonic_64only(funct3) ^ spc() ^ reg_name(rd) ^ sep() ^ reg_name(rs1) ^ sep() ^ reg_name(rs2)
  when currentlyEnabled(Ext_P) & xlen == 64

// ************************* P MULTIPLICATION TWO WORD **************************
union clause instruction = PMUL2W_64ONLY : (pmul2wfunct4_64only, regidx, regidx, regidx)

mapping encdec_pmul2wfunct4_64only : pmul2wfunct4_64only <-> bits(4) = {
  PM2ADD_W <-> 0b0000,
  PM2ADDA_W <-> 0b0001,
  PM2ADD_WX <-> 0b0010,
  PM2ADDA_WX <-> 0b0011,
  PM2ADDU_W <-> 0b0100,
  PM2ADDAU_W <-> 0b0101,
  PMQ2ADD_W <-> 0b0110,
  PMQ2ADDA_W <-> 0b0111,
  PM2SUB_W <-> 0b1000,
  PM2SUBA_W <-> 0b1001,
  PM2SUB_WX <-> 0b1010,
  PM2SUBA_WX <-> 0b1011,
  PM2ADDSU_W <-> 0b1100,
  PM2ADDASU_W <-> 0b1101,
}

mapping clause encdec = PMUL2W_64ONLY(funct4, rs1, rs2, rd) <->
  0b1 @ encdec_pmul2wfunct4_64only(funct4) @ 0b01 @ encdec_reg(rs2) @ encdec_reg(rs1) @ 0b101 @ encdec_reg(rd) @ 0b0111011
  when currentlyEnabled(Ext_P) & xlen == 64

function clause execute (PMUL2W_64ONLY(funct4, rs1, rs2, rd)) = {
  assert(xlen == 64);
  let rs1_val = X(rs1);
  let rs2_val = X(rs2);
  let rd_val = X(rd);
  let rs1_word_even = rs1_val[31..0];
  let rs2_word_even = rs2_val[31..0];
  let rs1_word_odd = rs1_val[63..32];
  let rs2_word_odd = rs2_val[63..32];
  let result : xlenbits = match funct4 {
    PM2ADD_W => muls(rs1_word_odd, rs2_word_odd) + muls(rs1_word_even, rs2_word_even),
    PM2ADDA_W => rd_val + muls(rs1_word_odd, rs2_word_odd) + muls(rs1_word_even, rs2_word_even),
    PM2ADD_WX => muls(rs1_word_odd, rs2_word_even) + muls(rs1_word_even, rs2_word_odd),
    PM2ADDA_WX => rd_val + muls(rs1_word_odd, rs2_word_even) + muls(rs1_word_even, rs2_word_odd),
    PM2ADDU_W => mulu(rs1_word_odd, rs2_word_odd) + mulu(rs1_word_even, rs2_word_even),
    PM2ADDAU_W => rd_val + mulu(rs1_word_odd, rs2_word_odd) + mulu(rs1_word_even, rs2_word_even),
    PMQ2ADD_W => mulq(rs1_word_odd, rs2_word_odd) + mulq(rs1_word_even, rs2_word_even),
    PMQ2ADDA_W => rd_val + mulq(rs1_word_odd, rs2_word_odd) + mulq(rs1_word_even, rs2_word_even),
    PM2SUB_W => muls(rs1_word_even, rs2_word_even) - muls(rs1_word_odd, rs2_word_odd),
    PM2SUBA_W => rd_val + muls(rs1_word_even, rs2_word_even) - muls(rs1_word_odd, rs2_word_odd),
    PM2SUB_WX => muls(rs1_word_even, rs2_word_odd) - muls(rs1_word_odd, rs2_word_even),
    PM2SUBA_WX => rd_val + muls(rs1_word_even, rs2_word_odd) - muls(rs1_word_odd, rs2_word_even),
    PM2ADDSU_W => mulsu(rs1_word_odd, rs2_word_odd) + mulsu(rs1_word_even, rs2_word_even),
    PM2ADDASU_W => rd_val + mulsu(rs1_word_odd, rs2_word_odd) + mulsu(rs1_word_even, rs2_word_even),
  };
  X(rd) = result;
  RETIRE_SUCCESS
}

mapping pmul2w_mnemonic_64only : pmul2wfunct4_64only <-> string = {
  PM2ADD_W <-> "pm2add.w",
  PM2ADDA_W <-> "pm2adda.w",
  PM2ADD_WX <-> "pm2add.wx",
  PM2ADDA_WX <-> "pm2adda.wx",
  PM2ADDU_W <-> "pm2addu.w",
  PM2ADDAU_W <-> "pm2addau.w",
  PMQ2ADD_W <-> "pmq2add.w",
  PMQ2ADDA_W <-> "pmq2adda.w",
  PM2SUB_W <-> "pm2sub.w",
  PM2SUBA_W <-> "pm2suba.w",
  PM2SUB_WX <-> "pm2sub.wx",
  PM2SUBA_WX <-> "pm2suba.wx",
  PM2ADDSU_W <-> "pm2addsu.w",
  PM2ADDASU_W <-> "pm2addasu.w",
}

mapping clause assembly = PMUL2W_64ONLY(funct4, rs1, rs2, rd)
  <-> pmul2w_mnemonic_64only(funct4) ^ spc() ^ reg_name(rd) ^ sep() ^ reg_name(rs1) ^ sep() ^ reg_name(rs2)
  when currentlyEnabled(Ext_P) & xlen == 64

// ******************** P MULTIPLICATION TWO WORD CONTINUED *********************
union clause instruction = PMUL2WCONTD_64ONLY : (pmul2wcontdfunct4_64only, regidx, regidx, regidx)

mapping encdec_pmul2wcontdfunct4_64only : pmul2wcontdfunct4_64only <-> bits(4) = {
  PMQR2ADD_W <-> 0b0110,
  PMQR2ADDA_W <-> 0b0111,
}

mapping clause encdec = PMUL2WCONTD_64ONLY(funct4, rs1, rs2, rd) <->
  0b1 @ encdec_pmul2wcontdfunct4_64only(funct4) @ 0b11 @ encdec_reg(rs2) @ encdec_reg(rs1) @ 0b101 @ encdec_reg(rd) @ 0b0111011
  when currentlyEnabled(Ext_P) & xlen == 64

function clause execute (PMUL2WCONTD_64ONLY(funct4, rs1, rs2, rd)) = {
  assert(xlen == 64);
  let rs1_val = X(rs1);
  let rs2_val = X(rs2);
  let rd_val = X(rd);
  let rs1_word_even = rs1_val[31..0];
  let rs2_word_even = rs2_val[31..0];
  let rs1_word_odd = rs1_val[63..32];
  let rs2_word_odd = rs2_val[63..32];
  let result : xlenbits = match funct4 {
    PMQR2ADD_W => mulqr(rs1_word_odd, rs2_word_odd) + mulqr(rs1_word_even, rs2_word_even),
    PMQR2ADDA_W => rd_val + mulqr(rs1_word_odd, rs2_word_odd) + mulqr(rs1_word_even, rs2_word_even),
  };
  X(rd) = result;
  RETIRE_SUCCESS
}

mapping pmul2wcontd_mnemonic_64only : pmul2wcontdfunct4_64only <-> string = {
  PMQR2ADD_W <-> "pmqr2add.w",
  PMQR2ADDA_W <-> "pmqr2adda.w",
}

mapping clause assembly = PMUL2WCONTD_64ONLY(funct4, rs1, rs2, rd)
  <-> pmul2wcontd_mnemonic_64only(funct4) ^ spc() ^ reg_name(rd) ^ sep() ^ reg_name(rs1) ^ sep() ^ reg_name(rs2)
  when currentlyEnabled(Ext_P) & xlen == 64

// *********************** P MULTIPLICATION FOUR HALFWORD ***********************
union clause instruction = PMUL4H_64ONLY : (pmul4hfunct4_64only, regidx, regidx, regidx)

mapping encdec_pmul4hfunct4_64only : pmul4hfunct4_64only <-> bits(4) = {
  PM4ADD_H <-> 0b0000,
  PM4ADDA_H <-> 0b0001,
  PM4ADDU_H <-> 0b0100,
  PM4ADDAU_H <-> 0b0101,
  PM4ADDSU_H <-> 0b1100,
  PM4ADDASU_H <-> 0b1101,
}

mapping clause encdec = PMUL4H_64ONLY(funct4, rs1, rs2, rd) <->
  0b1 @ encdec_pmul4hfunct4_64only(funct4) @ 0b11 @ encdec_reg(rs2) @ encdec_reg(rs1) @ 0b101 @ encdec_reg(rd) @ 0b0111011
  when currentlyEnabled(Ext_P) & xlen == 64

function clause execute (PMUL4H_64ONLY(funct4, rs1, rs2, rd)) = {
  assert(xlen == 64);
  let rs1_val = X(rs1);
  let rs2_val = X(rs2);
  let rd_val = X(rd);
  var result : xlenbits = match funct4 {
    PM4ADD_H => zeros(),
    PM4ADDA_H => rd_val,
    PM4ADDU_H => zeros(),
    PM4ADDAU_H => rd_val,
    PM4ADDSU_H => zeros(),
    PM4ADDASU_H => rd_val,
  };
  foreach (i from 0 to 48 by 16) {
    let rs1_halfword = rs1_val[(i+15)..i];
    let rs2_halfword = rs2_val[(i+15)..i];
    result = match funct4 {
      PM4ADD_H => result + sign_extend(muls(rs1_halfword, rs2_halfword)),
      PM4ADDA_H => result + sign_extend(muls(rs1_halfword, rs2_halfword)),
      PM4ADDU_H => result + zero_extend(mulu(rs1_halfword, rs2_halfword)),
      PM4ADDAU_H => result + zero_extend(mulu(rs1_halfword, rs2_halfword)),
      PM4ADDSU_H => result + sign_extend(mulsu(rs1_halfword, rs2_halfword)),
      PM4ADDASU_H => result + sign_extend(mulsu(rs1_halfword, rs2_halfword)),
    };
  };
  X(rd) = result;
  RETIRE_SUCCESS
}

mapping pmul4h_mnemonic_64only : pmul4hfunct4_64only <-> string = {
  PM4ADD_H <-> "pm4add.h",
  PM4ADDA_H <-> "pm4adda.h",
  PM4ADDU_H <-> "pm4addu.h",
  PM4ADDAU_H <-> "pm4addau.h",
  PM4ADDSU_H <-> "pm4addsu.h",
  PM4ADDASU_H <-> "pm4addasu.h",
}

mapping clause assembly = PMUL4H_64ONLY(funct4, rs1, rs2, rd)
  <-> pmul4h_mnemonic_64only(funct4) ^ spc() ^ reg_name(rd) ^ sep() ^ reg_name(rs1) ^ sep() ^ reg_name(rs2)
  when currentlyEnabled(Ext_P) & xlen == 64

// **************** P MULTIPLICATION WORD HALFWORD 01 CONTINUED *****************
union clause instruction = PMULWH01CONTD_64ONLY : (pmulwh01contdwidth2_64only, regidx, regidx, regidx)

mapping encdec_pmulwh01contdwidth2_64only : pmulwh01contdwidth2_64only <-> bits(2) = {
  PMQACC_W_H01 <-> 0b00,
  PMQRACC_W_H01 <-> 0b10,
}

mapping clause encdec = PMULWH01CONTD_64ONLY(width2, rs1, rs2, rd) <->
  0b1 @ 0b1111 @ encdec_pmulwh01contdwidth2_64only(width2) @ encdec_reg(rs2) @ encdec_reg(rs1) @ 0b101 @ encdec_reg(rd) @ 0b0111011
  when currentlyEnabled(Ext_P) & xlen == 64

function clause execute (PMULWH01CONTD_64ONLY(width2, rs1, rs2, rd)) = {
  assert(xlen == 64);
  let rs1_val = X(rs1);
  let rs2_val = X(rs2);
  let rd_val = X(rd);
  var result : xlenbits = zeros();
  foreach (i from 0 to (sizeof(xlen) - 32) by 32) {
    let rs1_halfword_even = rs1_val[(i+15)..i];
    let rs2_halfword_odd = rs2_val[(i+31)..(i+16)];
    result[(i+31)..i] = match width2 {
      PMQACC_W_H01 => rd_val[(i+31)..i] + mulq(rs1_halfword_even, rs2_halfword_odd),
      PMQRACC_W_H01 => rd_val[(i+31)..i] + mulqr(rs1_halfword_even, rs2_halfword_odd),
    };
  };
  X(rd) = result;
  RETIRE_SUCCESS
}

mapping pmulwh01contd_mnemonic_64only : pmulwh01contdwidth2_64only <-> string = {
  PMQACC_W_H01 <-> "pmqacc.w.h01",
  PMQRACC_W_H01 <-> "pmqracc.w.h01",
}

mapping clause assembly = PMULWH01CONTD_64ONLY(width2, rs1, rs2, rd)
  <-> pmulwh01contd_mnemonic_64only(width2) ^ spc() ^ reg_name(rd) ^ sep() ^ reg_name(rs1) ^ sep() ^ reg_name(rs2)
  when currentlyEnabled(Ext_P) & xlen == 64

// *************** P MULTIPLICATION DOUBLEWORD WORD 01 CONTINUED ****************
union clause instruction = PMULDW01CONTD_64ONLY : (pmuldw01contdwidth2_64only, regidx, regidx, regidx)

mapping encdec_pmuldw01contdwidth2_64only : pmuldw01contdwidth2_64only <-> bits(2) = {
  MQACC_W01 <-> 0b01,
  MQRACC_W01 <-> 0b11,
}

mapping clause encdec = PMULDW01CONTD_64ONLY(width2, rs1, rs2, rd) <->
  0b1 @ 0b1111 @ encdec_pmuldw01contdwidth2_64only(width2) @ encdec_reg(rs2) @ encdec_reg(rs1) @ 0b101 @ encdec_reg(rd) @ 0b0111011
  when currentlyEnabled(Ext_P) & xlen == 64

function clause execute (PMULDW01CONTD_64ONLY(width2, rs1, rs2, rd)) = {
  assert(xlen == 64);
  let rs1_val = X(rs1);
  let rs2_val = X(rs2);
  let rd_val = X(rd);
  let rs1_word_even = rs1_val[31..0];
  let rs2_word_odd = rs2_val[63..32];
  let result : xlenbits = match width2 {
    MQACC_W01 => rd_val + mulq(rs1_word_even, rs2_word_odd),
    MQRACC_W01 => rd_val + mulqr(rs1_word_even, rs2_word_odd),
  };
  X(rd) = result;
  RETIRE_SUCCESS
}

mapping pmuldw01contd_mnemonic_64only : pmuldw01contdwidth2_64only <-> string = {
  MQACC_W01 <-> "mqacc.w01",
  MQRACC_W01 <-> "mqracc.w01",
}

mapping clause assembly = PMULDW01CONTD_64ONLY(width2, rs1, rs2, rd)
  <-> pmuldw01contd_mnemonic_64only(width2) ^ spc() ^ reg_name(rd) ^ sep() ^ reg_name(rs1) ^ sep() ^ reg_name(rs2)
  when currentlyEnabled(Ext_P) & xlen == 64

// ******************************* P ADD SUB WORD *******************************
union clause instruction = PADDSUBW_64ONLY : (paddsubwfunct4_64only, regidx, regidx, regidx)

mapping encdec_paddsubwfunct4_64only : paddsubwfunct4_64only <-> bits(4) = {
  PAS_WX <-> 0b0000,
  PSAS_WX <-> 0b0010,
  PAAS_WX <-> 0b0011,
}

mapping clause encdec = PADDSUBW_64ONLY(funct4, rs1, rs2, rd) <->
  0b1 @ encdec_paddsubwfunct4_64only(funct4) @ 0b01 @ encdec_reg(rs2) @ encdec_reg(rs1) @ 0b110 @ encdec_reg(rd) @ 0b0111011
  when currentlyEnabled(Ext_P) & xlen == 64

function clause execute (PADDSUBW_64ONLY(funct4, rs1, rs2, rd)) = {
  assert(xlen == 64);
  let rs1_val = X(rs1);
  let rs2_val = X(rs2);
  let rs1_word_even = rs1_val[31..0];
  let rs2_word_even = rs2_val[31..0];
  let rs1_word_odd = rs1_val[63..32];
  let rs2_word_odd = rs2_val[63..32];
  let result : xlenbits = match funct4 {
    PAS_WX => (rs1_word_odd + rs2_word_even) @ (rs1_word_even - rs2_word_odd),
    PSAS_WX => sadd(rs1_word_odd, rs2_word_even) @ ssub(rs1_word_even, rs2_word_odd),
    PAAS_WX => aadd(rs1_word_odd, rs2_word_even) @ asub(rs1_word_even, rs2_word_odd),
  };
  X(rd) = result;
  RETIRE_SUCCESS
}

mapping paddsubw_mnemonic_64only : paddsubwfunct4_64only <-> string = {
  PAS_WX <-> "pas.wx",
  PSAS_WX <-> "psas.wx",
  PAAS_WX <-> "paas.wx",
}

mapping clause assembly = PADDSUBW_64ONLY(funct4, rs1, rs2, rd)
  <-> paddsubw_mnemonic_64only(funct4) ^ spc() ^ reg_name(rd) ^ sep() ^ reg_name(rs1) ^ sep() ^ reg_name(rs2)
  when currentlyEnabled(Ext_P) & xlen == 64

// ******************************* P SUB ADD WORD *******************************
union clause instruction = PSUBADDW_64ONLY : (psubaddwfunct4_64only, regidx, regidx, regidx)

mapping encdec_psubaddwfunct4_64only : psubaddwfunct4_64only <-> bits(4) = {
  PSA_WX <-> 0b0000,
  PSSA_WX <-> 0b0010,
  PASA_WX <-> 0b0011,
}

mapping clause encdec = PSUBADDW_64ONLY(funct4, rs1, rs2, rd) <->
  0b1 @ encdec_psubaddwfunct4_64only(funct4) @ 0b11 @ encdec_reg(rs2) @ encdec_reg(rs1) @ 0b110 @ encdec_reg(rd) @ 0b0111011
  when currentlyEnabled(Ext_P) & xlen == 64

function clause execute (PSUBADDW_64ONLY(funct4, rs1, rs2, rd)) = {
  assert(xlen == 64);
  let rs1_val = X(rs1);
  let rs2_val = X(rs2);
  let rs1_word_even = rs1_val[31..0];
  let rs2_word_even = rs2_val[31..0];
  let rs1_word_odd = rs1_val[63..32];
  let rs2_word_odd = rs2_val[63..32];
  let result : xlenbits = match funct4 {
    PSA_WX => (rs1_word_odd - rs2_word_even) @ (rs1_word_even + rs2_word_odd),
    PSSA_WX => ssub(rs1_word_odd, rs2_word_even) @ sadd(rs1_word_even, rs2_word_odd),
    PASA_WX => asub(rs1_word_odd, rs2_word_even) @ aadd(rs1_word_even, rs2_word_odd),
  };
  X(rd) = result;
  RETIRE_SUCCESS
}

mapping psubaddw_mnemonic_64only : psubaddwfunct4_64only <-> string = {
  PSA_WX <-> "psa.wx",
  PSSA_WX <-> "pssa.wx",
  PASA_WX <-> "pasa.wx",
}

mapping clause assembly = PSUBADDW_64ONLY(funct4, rs1, rs2, rd)
  <-> psubaddw_mnemonic_64only(funct4) ^ spc() ^ reg_name(rd) ^ sep() ^ reg_name(rs1) ^ sep() ^ reg_name(rs2)
  when currentlyEnabled(Ext_P) & xlen == 64

// ***************************** P COMPARISON WORD ******************************
union clause instruction = PCOMPAREW_64ONLY : (pcomparewfunct4_64only, regidx, regidx, regidx)

mapping encdec_pcomparewfunct4_64only : pcomparewfunct4_64only <-> bits(4) = {
  PMSEQ_W <-> 0b1000,
  PMSLT_W <-> 0b1010,
  PMSLTU_W <-> 0b1011,
  PMIN_W <-> 0b1100,
  PMINU_W <-> 0b1101,
  PMAX_W <-> 0b1110,
  PMAXU_W <-> 0b1111,
}

mapping clause encdec = PCOMPAREW_64ONLY(funct4, rs1, rs2, rd) <->
  0b1 @ encdec_pcomparewfunct4_64only(funct4) @ 0b01 @ encdec_reg(rs2) @ encdec_reg(rs1) @ 0b110 @ encdec_reg(rd) @ 0b0111011
  when currentlyEnabled(Ext_P) & xlen == 64

function clause execute (PCOMPAREW_64ONLY(funct4, rs1, rs2, rd)) = {
  assert(xlen == 64);
  let rs1_val = X(rs1);
  let rs2_val = X(rs2);
  var result : xlenbits = zeros();
  foreach (i from 0 to (sizeof(xlen) - 32) by 32) {
    let rs1_word = slice(rs1_val, i, 32);
    let rs2_word = slice(rs2_val, i, 32);
    result[(i+31)..i] = match funct4 {
      PMSEQ_W => mseq(rs1_word, rs2_word),
      PMSLT_W => mslt(rs1_word, rs2_word),
      PMSLTU_W => msltu(rs1_word, rs2_word),
      PMIN_W => mins(rs1_word, rs2_word),
      PMINU_W => minu(rs1_word, rs2_word),
      PMAX_W => maxs(rs1_word, rs2_word),
      PMAXU_W => maxu(rs1_word, rs2_word),
    };
  };
  X(rd) = result;
  RETIRE_SUCCESS
}

mapping pcomparew_mnemonic_64only : pcomparewfunct4_64only <-> string = {
  PMSEQ_W <-> "pmseq.w",
  PMSLT_W <-> "pmslt.w",
  PMSLTU_W <-> "pmsltu.w",
  PMIN_W <-> "pmin.w",
  PMINU_W <-> "pminu.w",
  PMAX_W <-> "pmax.w",
  PMAXU_W <-> "pmaxu.w",
}

mapping clause assembly = PCOMPAREW_64ONLY(funct4, rs1, rs2, rd)
  <-> pcomparew_mnemonic_64only(funct4) ^ spc() ^ reg_name(rd) ^ sep() ^ reg_name(rs1) ^ sep() ^ reg_name(rs2)
  when currentlyEnabled(Ext_P) & xlen == 64

// *************************** P MULTIPLICATION WORD ****************************
union clause instruction = PMULW_64ONLY : (pmulwfunct4_64only, regidx, regidx, regidx)

mapping encdec_pmulwfunct4_64only : pmulwfunct4_64only <-> bits(4) = {
  PMULH_W <-> 0b0000,
  PMHACC_W <-> 0b0001,
  PMULHU_W <-> 0b0010,
  PMHACCU_W <-> 0b0011,
  PMULHSU_W <-> 0b1000,
  PMHACCSU_W <-> 0b1001,
  PMULQ_W <-> 0b1010,
}

mapping clause encdec = PMULW_64ONLY(funct4, rs1, rs2, rd) <->
  0b1 @ encdec_pmulwfunct4_64only(funct4) @ 0b01 @ encdec_reg(rs2) @ encdec_reg(rs1) @ 0b111 @ encdec_reg(rd) @ 0b0111011
  when currentlyEnabled(Ext_P) & xlen == 64

function clause execute (PMULW_64ONLY(funct4, rs1, rs2, rd)) = {
  assert(xlen == 64);
  let rs1_val = X(rs1);
  let rs2_val = X(rs2);
  let rd_val = X(rd);
  var result : xlenbits = zeros();
  foreach (i from 0 to (sizeof(xlen) - 32) by 32) {
    let rs1_word = rs1_val[(i+31)..i];
    let rs2_word = rs2_val[(i+31)..i];
    let rd_word = rd_val[(i+31)..i];
    result[(i+31)..i] = match funct4 {
      PMULH_W => mulh(rs1_word, rs2_word),
      PMHACC_W => rd_word + mulh(rs1_word, rs2_word),
      PMULHU_W => mulhu(rs1_word, rs2_word),
      PMHACCU_W => rd_word + mulhu(rs1_word, rs2_word),
      PMULHSU_W => mulhsu(rs1_word, rs2_word),
      PMHACCSU_W => rd_word + mulhsu(rs1_word, rs2_word),
      PMULQ_W => mulq_sat(rs1_word, rs2_word)[31..0],
    };
  };
  X(rd) = result;
  RETIRE_SUCCESS
}

mapping pmulw_mnemonic_64only : pmulwfunct4_64only <-> string = {
  PMULH_W <-> "pmulh.w",
  PMHACC_W <-> "pmhacc.w",
  PMULHU_W <-> "pmulhu.w",
  PMHACCU_W <-> "pmhaccu.w",
  PMULHSU_W <-> "pmulhsu.w",
  PMHACCSU_W <-> "pmhaccsu.w",
  PMULQ_W <-> "pmulq.w",
}

mapping clause assembly = PMULW_64ONLY(funct4, rs1, rs2, rd)
  <-> pmulw_mnemonic_64only(funct4) ^ spc() ^ reg_name(rd) ^ sep() ^ reg_name(rs1) ^ sep() ^ reg_name(rs2)
  when currentlyEnabled(Ext_P) & xlen == 64

// ********************** P MULTIPLICATION WORD CONTINUED ***********************
union clause instruction = PMULWCONTD_64ONLY : (pmulwcontdfunct4_64only, regidx, regidx, regidx)

mapping encdec_pmulwcontdfunct4_64only : pmulwcontdfunct4_64only <-> bits(4) = {
  PMULHR_W <-> 0b0000,
  PMHRACC_W <-> 0b0001,
  PMULHRU_W <-> 0b0010,
  PMHRACCU_W <-> 0b0011,
  PMULHRSU_W <-> 0b1000,
  PMHRACCSU_W <-> 0b1001,
  PMULQR_W <-> 0b1010,
}

mapping clause encdec = PMULWCONTD_64ONLY(funct4, rs1, rs2, rd) <->
  0b1 @ encdec_pmulwcontdfunct4_64only(funct4) @ 0b11 @ encdec_reg(rs2) @ encdec_reg(rs1) @ 0b111 @ encdec_reg(rd) @ 0b0111011
  when currentlyEnabled(Ext_P) & xlen == 64

function clause execute (PMULWCONTD_64ONLY(funct4, rs1, rs2, rd)) = {
  assert(xlen == 64);
  let rs1_val = X(rs1);
  let rs2_val = X(rs2);
  let rd_val = X(rd);
  var result : xlenbits = zeros();
  foreach (i from 0 to (sizeof(xlen) - 32) by 32) {
    let rs1_word = rs1_val[(i+31)..i];
    let rs2_word = rs2_val[(i+31)..i];
    let rd_word = rd_val[(i+31)..i];
    result[(i+31)..i] = match funct4 {
      PMULHR_W => mulhr(rs1_word, rs2_word),
      PMHRACC_W => rd_word + mulhr(rs1_word, rs2_word),
      PMULHRU_W => mulhru(rs1_word, rs2_word),
      PMHRACCU_W => rd_word + mulhru(rs1_word, rs2_word),
      PMULHRSU_W => mulhrsu(rs1_word, rs2_word),
      PMHRACCSU_W => rd_word + mulhrsu(rs1_word, rs2_word),
      PMULQR_W => mulqr_sat(rs1_word, rs2_word)[31..0],
    };
  };
  X(rd) = result;
  RETIRE_SUCCESS
}

mapping pmulwcontd_mnemonic_64only : pmulwcontdfunct4_64only <-> string = {
  PMULHR_W <-> "pmulhr.w",
  PMHRACC_W <-> "pmhracc.w",
  PMULHRU_W <-> "pmulhru.w",
  PMHRACCU_W <-> "pmhraccu.w",
  PMULHRSU_W <-> "pmulhrsu.w",
  PMHRACCSU_W <-> "pmhraccsu.w",
  PMULQR_W <-> "pmulqr.w",
}

mapping clause assembly = PMULWCONTD_64ONLY(funct4, rs1, rs2, rd)
  <-> pmulwcontd_mnemonic_64only(funct4) ^ spc() ^ reg_name(rd) ^ sep() ^ reg_name(rs1) ^ sep() ^ reg_name(rs2)
  when currentlyEnabled(Ext_P) & xlen == 64

// ******************* P MULTIPLICATION WORD HALFWORD SIGNED ********************
union clause instruction = PMULWHSIGNED_64ONLY : (pmulwhsignedfunct4_64only, regidx, regidx, regidx)

mapping encdec_pmulwhsignedfunct4_64only : pmulwhsignedfunct4_64only <-> bits(4) = {
  PMULH_W_H0 <-> 0b0100,
  PMHACC_W_H0 <-> 0b0101,
  PMULH_W_H1 <-> 0b0110,
  PMHACC_W_H1 <-> 0b0111,
}

mapping clause encdec = PMULWHSIGNED_64ONLY(funct4, rs1, rs2, rd) <->
  0b1 @ encdec_pmulwhsignedfunct4_64only(funct4) @ 0b01 @ encdec_reg(rs2) @ encdec_reg(rs1) @ 0b111 @ encdec_reg(rd) @ 0b0111011
  when currentlyEnabled(Ext_P) & xlen == 64

function clause execute (PMULWHSIGNED_64ONLY(funct4, rs1, rs2, rd)) = {
  assert(xlen == 64);
  let rs1_val = X(rs1);
  let rs2_val = X(rs2);
  let rd_val = X(rd);
  var result : xlenbits = zeros();
  foreach (i from 0 to (sizeof(xlen) - 32) by 32) {
    let rs1_word = rs1_val[(i+31)..i];
    let rs2_halfword_even = rs2_val[(i+15)..i];
    let rs2_halfword_odd = rs2_val[(i+31)..(i+16)];
    let rd_word = rd_val[(i+31)..i];
    result[(i+31)..i] = match funct4 {
      PMULH_W_H0 => mulh_mixed(rs1_word, rs2_halfword_even),
      PMHACC_W_H0 => rd_word + mulh_mixed(rs1_word, rs2_halfword_even),
      PMULH_W_H1 => mulh_mixed(rs1_word, rs2_halfword_odd),
      PMHACC_W_H1 => rd_word + mulh_mixed(rs1_word, rs2_halfword_odd),
    };
  };
  X(rd) = result;
  RETIRE_SUCCESS
}

mapping pmulwhsigned_mnemonic_64only : pmulwhsignedfunct4_64only <-> string = {
  PMULH_W_H0 <-> "pmulh.w.h0",
  PMHACC_W_H0 <-> "pmhacc.w.h0",
  PMULH_W_H1 <-> "pmulh.w.h1",
  PMHACC_W_H1 <-> "pmhacc.w.h1",
}

mapping clause assembly = PMULWHSIGNED_64ONLY(funct4, rs1, rs2, rd)
  <-> pmulwhsigned_mnemonic_64only(funct4) ^ spc() ^ reg_name(rd) ^ sep() ^ reg_name(rs1) ^ sep() ^ reg_name(rs2)
  when currentlyEnabled(Ext_P) & xlen == 64

// ****************** P MULTIPLICATION WORD HALFWORD UNSIGNED *******************
union clause instruction = PMULWHUNSIGNED_64ONLY : (pmulwhunsignedfunct4_64only, regidx, regidx, regidx)

mapping encdec_pmulwhunsignedfunct4_64only : pmulwhunsignedfunct4_64only <-> bits(4) = {
  PMULHSU_W_H0 <-> 0b0100,
  PMHACCSU_W_H0 <-> 0b0101,
  PMULHSU_W_H1 <-> 0b0110,
  PMHACCSU_W_H1 <-> 0b0111,
}

mapping clause encdec = PMULWHUNSIGNED_64ONLY(funct4, rs1, rs2, rd) <->
  0b1 @ encdec_pmulwhunsignedfunct4_64only(funct4) @ 0b11 @ encdec_reg(rs2) @ encdec_reg(rs1) @ 0b111 @ encdec_reg(rd) @ 0b0111011
  when currentlyEnabled(Ext_P) & xlen == 64

function clause execute (PMULWHUNSIGNED_64ONLY(funct4, rs1, rs2, rd)) = {
  assert(xlen == 64);
  let rs1_val = X(rs1);
  let rs2_val = X(rs2);
  let rd_val = X(rd);
  var result : xlenbits = zeros();
  foreach (i from 0 to (sizeof(xlen) - 32) by 32) {
    let rs1_word = rs1_val[(i+31)..i];
    let rs2_halfword_even = rs2_val[(i+15)..i];
    let rs2_halfword_odd = rs2_val[(i+31)..(i+16)];
    let rd_word = rd_val[(i+31)..i];
    result[(i+31)..i] = match funct4 {
      PMULHSU_W_H0 => mulhsu_mixed(rs1_word, rs2_halfword_even),
      PMHACCSU_W_H0 => rd_word + mulhsu_mixed(rs1_word, rs2_halfword_even),
      PMULHSU_W_H1 => mulhsu_mixed(rs1_word, rs2_halfword_odd),
      PMHACCSU_W_H1 => rd_word + mulhsu_mixed(rs1_word, rs2_halfword_odd),
    };
  };
  X(rd) = result;
  RETIRE_SUCCESS
}

mapping pmulwhunsigned_mnemonic_64only : pmulwhunsignedfunct4_64only <-> string = {
  PMULHSU_W_H0 <-> "pmulhsu.w.h0",
  PMHACCSU_W_H0 <-> "pmhaccsu.w.h0",
  PMULHSU_W_H1 <-> "pmulhsu.w.h1",
  PMHACCSU_W_H1 <-> "pmhaccsu.w.h1",
}

mapping clause assembly = PMULWHUNSIGNED_64ONLY(funct4, rs1, rs2, rd)
  <-> pmulwhunsigned_mnemonic_64only(funct4) ^ spc() ^ reg_name(rd) ^ sep() ^ reg_name(rs1) ^ sep() ^ reg_name(rs2)
  when currentlyEnabled(Ext_P) & xlen == 64

// ****************** P MULTIPLICATION WORD HALFWORD CONTINUED ******************
union clause instruction = PMULWHCONTD_64ONLY : (pmulwhcontdfunct4_64only, regidx, regidx, regidx)

mapping encdec_pmulwhcontdfunct4_64only : pmulwhcontdfunct4_64only <-> bits(4) = {
  PMQACC_W_H00 <-> 0b1101,
  PMQACC_W_H11 <-> 0b1111,
}

mapping clause encdec = PMULWHCONTD_64ONLY(funct4, rs1, rs2, rd) <->
  0b1 @ encdec_pmulwhcontdfunct4_64only(funct4) @ 0b00 @ encdec_reg(rs2) @ encdec_reg(rs1) @ 0b111 @ encdec_reg(rd) @ 0b0111011
  when currentlyEnabled(Ext_P) & xlen == 64

function clause execute (PMULWHCONTD_64ONLY(funct4, rs1, rs2, rd)) = {
  assert(xlen == 64);
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
      PMQACC_W_H00 => rd_val[(i+31)..i] + mulq(rs1_halfword_even, rs2_halfword_even),
      PMQACC_W_H11 => rd_val[(i+31)..i] + mulq(rs1_halfword_odd, rs2_halfword_odd),
    };
  };
  X(rd) = result;
  RETIRE_SUCCESS
}

mapping pmulwhcontd_mnemonic_64only : pmulwhcontdfunct4_64only <-> string = {
  PMQACC_W_H00 <-> "pmqacc.w.h00",
  PMQACC_W_H11 <-> "pmqacc.w.h11",
}

mapping clause assembly = PMULWHCONTD_64ONLY(funct4, rs1, rs2, rd)
  <-> pmulwhcontd_mnemonic_64only(funct4) ^ spc() ^ reg_name(rd) ^ sep() ^ reg_name(rs1) ^ sep() ^ reg_name(rs2)
  when currentlyEnabled(Ext_P) & xlen == 64

// ***************** P MULTIPLICATION WORD HALFWORD CONTINUED 2 *****************
union clause instruction = PMULWHCONTD2_64ONLY : (pmulwhcontd2funct4_64only, regidx, regidx, regidx)

mapping encdec_pmulwhcontd2funct4_64only : pmulwhcontd2funct4_64only <-> bits(4) = {
  PMQRACC_W_H00 <-> 0b1101,
  PMQRACC_W_H11 <-> 0b1111,
}
mapping clause encdec = PMULWHCONTD2_64ONLY(funct4, rs1, rs2, rd) <->
  0b1 @ encdec_pmulwhcontd2funct4_64only(funct4) @ 0b10 @ encdec_reg(rs2) @ encdec_reg(rs1) @ 0b111 @ encdec_reg(rd) @ 0b0111011
  when currentlyEnabled(Ext_P) & xlen == 64

function clause execute (PMULWHCONTD2_64ONLY(funct4, rs1, rs2, rd)) = {
  assert(xlen == 64);
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
      PMQRACC_W_H00 => rd_val[(i+31)..i] + mulqr(rs1_halfword_even, rs2_halfword_even),
      PMQRACC_W_H11 => rd_val[(i+31)..i] + mulqr(rs1_halfword_odd, rs2_halfword_odd),
    };
  };
  X(rd) = result;
  RETIRE_SUCCESS
}

mapping pmulwhcontd2_mnemonic_64only : pmulwhcontd2funct4_64only <-> string = {
  PMQRACC_W_H00 <-> "pmqracc.w.h00",
  PMQRACC_W_H11 <-> "pmqracc.w.h11",
}

mapping clause assembly = PMULWHCONTD2_64ONLY(funct4, rs1, rs2, rd)
  <-> pmulwhcontd2_mnemonic_64only(funct4) ^ spc() ^ reg_name(rd) ^ sep() ^ reg_name(rs1) ^ sep() ^ reg_name(rs2)
  when currentlyEnabled(Ext_P) & xlen == 64

// ***************** P MULTIPLICATION DOUBLEWORD WORD CONTINUED *****************
union clause instruction = PMULDWCONTD_64ONLY : (pmuldwcontdfunct4_64only, regidx, regidx, regidx)

mapping encdec_pmuldwcontdfunct4_64only : pmuldwcontdfunct4_64only <-> bits(4) = {
  MQACC_W00 <-> 0b1101,
  MQACC_W11 <-> 0b1111,
}

mapping clause encdec = PMULDWCONTD_64ONLY(funct4, rs1, rs2, rd) <->
  0b1 @ encdec_pmuldwcontdfunct4_64only(funct4) @ 0b01 @ encdec_reg(rs2) @ encdec_reg(rs1) @ 0b111 @ encdec_reg(rd) @ 0b0111011
  when currentlyEnabled(Ext_P) & xlen == 64

function clause execute (PMULDWCONTD_64ONLY(funct4, rs1, rs2, rd)) = {
  assert(xlen == 64);
  let rs1_val = X(rs1);
  let rs2_val = X(rs2);
  let rd_val = X(rd);
  let rs1_word_even = rs1_val[31..0];
  let rs2_word_even = rs2_val[31..0];
  let rs1_word_odd = rs1_val[63..32];
  let rs2_word_odd = rs2_val[63..32];
  let result : xlenbits = match funct4 {
    MQACC_W00 => rd_val + mulq(rs1_word_even, rs2_word_even),
    MQACC_W11 => rd_val + mulq(rs1_word_odd, rs2_word_odd),
  };
  X(rd) = result;
  RETIRE_SUCCESS
}

mapping pmuldwcontd_mnemonic_64only : pmuldwcontdfunct4_64only <-> string = {
  MQACC_W00 <-> "mqacc.w00",
  MQACC_W11 <-> "mqacc.w11",
}

mapping clause assembly = PMULDWCONTD_64ONLY(funct4, rs1, rs2, rd)
  <-> pmuldwcontd_mnemonic_64only(funct4) ^ spc() ^ reg_name(rd) ^ sep() ^ reg_name(rs1) ^ sep() ^ reg_name(rs2)
  when currentlyEnabled(Ext_P) & xlen == 64

// **************** P MULTIPLICATION DOUBLEWORD WORD CONTINUED 2 ****************
union clause instruction = PMULDWCONTD2_64ONLY : (pmuldwcontd2funct4_64only, regidx, regidx, regidx)

mapping encdec_pmuldwcontd2funct4_64only : pmuldwcontd2funct4_64only <-> bits(4) = {
  MQRACC_W00 <-> 0b1101,
  MQRACC_W11 <-> 0b1111,
}

mapping clause encdec = PMULDWCONTD2_64ONLY(funct4, rs1, rs2, rd) <->
  0b1 @ encdec_pmuldwcontd2funct4_64only(funct4) @ 0b11 @ encdec_reg(rs2) @ encdec_reg(rs1) @ 0b111 @ encdec_reg(rd) @ 0b0111011
  when currentlyEnabled(Ext_P) & xlen == 64

function clause execute (PMULDWCONTD2_64ONLY(funct4, rs1, rs2, rd)) = {
  assert(xlen == 64);
  let rs1_val = X(rs1);
  let rs2_val = X(rs2);
  let rd_val = X(rd);
  let rs1_word_even = rs1_val[31..0];
  let rs2_word_even = rs2_val[31..0];
  let rs1_word_odd = rs1_val[63..32];
  let rs2_word_odd = rs2_val[63..32];
  let result : xlenbits = match funct4 {
    MQRACC_W00 => rd_val + mulqr(rs1_word_even, rs2_word_even),
    MQRACC_W11 => rd_val + mulqr(rs1_word_odd, rs2_word_odd),
  };
  X(rd) = result;
  RETIRE_SUCCESS
}

mapping pmuldwcontd2_mnemonic_64only : pmuldwcontd2funct4_64only <-> string = {
  MQRACC_W00 <-> "mqracc.w00",
  MQRACC_W11 <-> "mqracc.w11",
}

mapping clause assembly = PMULDWCONTD2_64ONLY(funct4, rs1, rs2, rd)
  <-> pmuldwcontd2_mnemonic_64only(funct4) ^ spc() ^ reg_name(rd) ^ sep() ^ reg_name(rs1) ^ sep() ^ reg_name(rs2)
  when currentlyEnabled(Ext_P) & xlen == 64
