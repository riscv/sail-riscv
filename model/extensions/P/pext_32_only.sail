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
union clause instruction = SSLAI : (bits(5), regidx, regidx)

mapping clause encdec = SSLAI(imm5, rs1, rd)
  <-> 0b1 @ 0b101 @ 0b0 @ 0b01 @ imm5 @ encdec_reg(rs1) @ 0b010 @ encdec_reg(rd) @ 0b0011011
  when currentlyEnabled(Ext_P) & xlen == 32

function clause execute (SSLAI(imm5, rs1, rd)) = {
  assert(xlen == 32);
  let rs1_val = X(rs1);
  let shamt : nat = unsigned(imm5);
  X(rd) = sat_shift_left_arith(rs1_val, shamt);
  RETIRE_SUCCESS
}

mapping clause assembly = SSLAI(imm5, rs1, rd)
  <-> "sslai" ^ spc() ^ reg_name(rd) ^ sep() ^ reg_name(rs1) ^ sep() ^ hex_bits_5(imm5)
  when currentlyEnabled(Ext_P) & xlen == 32

// ***************************** P ALU WORD SCALAR ******************************
union clause instruction = PALUWSCALAR_32ONLY : (paluwscalarfunct3_32only, regidx, regidx, regidx)

mapping encdec_paluwscalarfunct3_32only : paluwscalarfunct3_32only <-> bits(3) = {
  SSHL <-> 0b010,
  SSHLR <-> 0b011,
  SSHA <-> 0b110,
  SSHAR <-> 0b111,
}

mapping clause encdec = PALUWSCALAR_32ONLY(funct3, rs1, rs2, rd) <->
  0b1 @ encdec_paluwscalarfunct3_32only(funct3) @ 0b1 @ 0b01 @ encdec_reg(rs2) @ encdec_reg(rs1) @ 0b010 @ encdec_reg(rd) @ 0b0011011
  when currentlyEnabled(Ext_P) & xlen == 32

function clause execute (PALUWSCALAR_32ONLY(funct3, rs1, rs2, rd)) = {
  assert(xlen == 32);
  let rs1_val = X(rs1);
  let rs2_val = X(rs2);
  let result : xlenbits = match funct3 {
    SSHL => sshl(rs1_val, signed(rs2_val[7..0])),
    SSHLR => sshlr(rs1_val, signed(rs2_val[7..0])),
    SSHA => ssha(rs1_val, signed(rs2_val[7..0])),
    SSHAR => sshar(rs1_val, signed(rs2_val[7..0])),
  };
  X(rd) = result;
  RETIRE_SUCCESS
}

mapping paluwscalar_mnemonic_32only : paluwscalarfunct3_32only <-> string = {
  SSHL <-> "sshl",
  SSHLR <-> "sshlr",
  SSHA <-> "ssha",
  SSHAR <-> "sshar",
}

mapping clause assembly = PALUWSCALAR_32ONLY(funct3, rs1, rs2, rd)
  <-> paluwscalar_mnemonic_32only(funct3) ^ spc() ^ reg_name(rd) ^ sep() ^ reg_name(rs1) ^ sep() ^ reg_name(rs2)
  when currentlyEnabled(Ext_P) & xlen == 32

// ********************** P SHIFT SATURATE IMMEDIATE WORD ***********************
union clause instruction = PSHIFTSATIW_32ONLY : (pshiftsatiwfunct3_32only, bits(5), regidx, regidx)

mapping encdec_pshiftsatiwfunct3_32only : pshiftsatiwfunct3_32only <-> bits(3) = {
  USATI <-> 0b010,
  SRARI <-> 0b101,
  SATI <-> 0b110,
}

mapping clause encdec = PSHIFTSATIW_32ONLY(funct3, imm5, rs1, rd)
  <-> 0b1 @ encdec_pshiftsatiwfunct3_32only(funct3) @ 0b0 @ 0b01 @ imm5 @ encdec_reg(rs1) @ 0b100 @ encdec_reg(rd) @ 0b0011011
  when currentlyEnabled(Ext_P) & xlen == 32

function clause execute (PSHIFTSATIW_32ONLY(funct3, imm5, rs1, rd)) = {
  assert(xlen == 32);
  let rs1_val = X(rs1);
  let sa : nat = unsigned(imm5);
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

mapping pshiftsatiw_mnemonic_32only : pshiftsatiwfunct3_32only <-> string = {
  USATI <-> "usati",
  SRARI <-> "srari",
  SATI <-> "sati",
}

mapping clause assembly = PSHIFTSATIW_32ONLY(funct3, imm5, rs1, rd)
  <-> pshiftsatiw_mnemonic_32only(funct3) ^ spc() ^ reg_name(rd) ^ sep() ^ reg_name(rs1) ^ sep() ^ hex_bits_5(imm5)
  when currentlyEnabled(Ext_P) & xlen == 32

// **************************** P REDUCTION ALU WORD ****************************
union clause instruction = PALUW_32ONLY : (paluwfunct4_32only, regidx, regidx, regidx)

mapping encdec_paluwfunct4_32only : paluwfunct4_32only <-> bits(4) = {
  SADD <-> 0b0010,
  AADD <-> 0b0011,
  SADDU <-> 0b0110,
  AADDU <-> 0b0111,
  SSUB <-> 0b1010,
  ASUB <-> 0b1011,
  SSUBU <-> 0b1110,
  ASUBU <-> 0b1111,
}

mapping clause encdec = PALUW_32ONLY(funct4, rs1, rs2, rd) <->
  0b1 @ encdec_paluwfunct4_32only(funct4) @ 0b01 @ encdec_reg(rs2) @ encdec_reg(rs1) @ 0b000 @ encdec_reg(rd) @ 0b0111011
  when currentlyEnabled(Ext_P) & xlen == 32

function clause execute (PALUW_32ONLY(funct4, rs1, rs2, rd)) = {
  assert(xlen == 32);
  let rs1_val = X(rs1);
  let rs2_val = X(rs2);
  let result : xlenbits = match funct4 {
    SADD => sadd(rs1_val, rs2_val),
    AADD => aadd(rs1_val, rs2_val),
    SADDU => saddu(rs1_val, rs2_val),
    AADDU => aaddu(rs1_val, rs2_val),
    SSUB => ssub(rs1_val, rs2_val),
    ASUB => asub(rs1_val, rs2_val),
    SSUBU => ssubu(rs1_val, rs2_val),
    ASUBU => asubu(rs1_val, rs2_val),
  };
  X(rd) = result;
  RETIRE_SUCCESS
}

mapping paluw_mnemonic_32only : paluwfunct4_32only <-> string = {
  SADD <-> "sadd",
  AADD <-> "aadd",
  SADDU <-> "saddu",
  AADDU <-> "aaddu",
  SSUB <-> "ssub",
  ASUB <-> "asub",
  SSUBU <-> "ssubu",
  ASUBU <-> "asubu",
}

mapping clause assembly = PALUW_32ONLY(funct4, rs1, rs2, rd)
  <-> paluw_mnemonic_32only(funct4) ^ spc() ^ reg_name(rd) ^ sep() ^ reg_name(rs1) ^ sep() ^ reg_name(rs2)
  when currentlyEnabled(Ext_P) & xlen == 32

// ********************* P MULTIPLICATION WORD HALFWORD 01 **********************
union clause instruction = PMULWH01_32ONLY : (pmulwh01funct4_32only, regidx, regidx, regidx)

mapping encdec_pmulwh01funct4_32only : pmulwh01funct4_32only <-> bits(4) = {
  MUL_H01 <-> 0b0010,
  MACC_H01 <-> 0b0011,
  MULU_H01 <-> 0b0110,
  MACCU_H01 <-> 0b0111,
}

mapping clause encdec = PMULWH01_32ONLY(funct4, rs1, rs2, rd) <->
  0b1 @ encdec_pmulwh01funct4_32only(funct4) @ 0b01 @ encdec_reg(rs2) @ encdec_reg(rs1) @ 0b001 @ encdec_reg(rd) @ 0b0111011
  when currentlyEnabled(Ext_P) & xlen == 32

function clause execute (PMULWH01_32ONLY(funct4, rs1, rs2, rd)) = {
  assert(xlen == 32);
  let rs1_val = X(rs1);
  let rs2_val = X(rs2);
  let rd_val = X(rd);
  let rs1_halfword = rs1_val[15..0];
  let rs2_halfword = rs2_val[31..16];
  let result : xlenbits = match funct4 {
    MUL_H01 => muls(rs1_halfword, rs2_halfword),
    MACC_H01 => rd_val + muls(rs1_halfword, rs2_halfword),
    MULU_H01 => mulu(rs1_halfword, rs2_halfword),
    MACCU_H01 => rd_val + mulu(rs1_halfword, rs2_halfword),
  };
  X(rd) = zero_extend(result);
  RETIRE_SUCCESS
}

mapping pmulwh01_mnemonic_32only : pmulwh01funct4_32only <-> string = {
  MUL_H01 <-> "mul.h01",
  MACC_H01 <-> "macc.h01",
  MULU_H01 <-> "mulu.h01",
  MACCU_H01 <-> "maccu.h01",
}

mapping clause assembly = PMULWH01_32ONLY(funct4, rs1, rs2, rd)
  <-> pmulwh01_mnemonic_32only(funct4) ^ spc() ^ reg_name(rd) ^ sep() ^ reg_name(rs1) ^ sep() ^ reg_name(rs2)
  when currentlyEnabled(Ext_P) & xlen == 32

// **************************** P SHIFT ONE ADD WORD ****************************
union clause instruction = PSHIFTONEADDH_32ONLY : (regidx, regidx, regidx)

mapping clause encdec = PSHIFTONEADDH_32ONLY(rs1, rs2, rd) <->
  0b1 @ 0b011 @ 0b0 @ 0b01 @ encdec_reg(rs2) @ encdec_reg(rs1) @ 0b010 @ encdec_reg(rd) @ 0b0111011
  when currentlyEnabled(Ext_P) & xlen == 32

function clause execute (PSHIFTONEADDH_32ONLY(rs1, rs2, rd)) = {
  assert(xlen == 32);
  let rs1_val = X(rs1);
  let rs2_val = X(rs2);
  X(rd) = sadd(sat_shift_left_arith(rs1_val, 1), rs2_val);
  RETIRE_SUCCESS
}

mapping clause assembly = PSHIFTONEADDH_32ONLY(rs1, rs2, rd)
  <-> "ssh1sadd" ^ spc() ^ reg_name(rd) ^ sep() ^ reg_name(rs1) ^ sep() ^ reg_name(rs2)
  when currentlyEnabled(Ext_P) & xlen == 32

// *********************** P MULTIPLICATION WORD HALFWORD ***********************
union clause instruction = PMULWH_32ONLY : (pmulwhfunct4_32only, regidx, regidx, regidx)

mapping encdec_pmulwhfunct4_32only : pmulwhfunct4_32only <-> bits(4) = {
  MUL_H00 <-> 0b0000,
  MACC_H00 <-> 0b0001,
  MUL_H11 <-> 0b0010,
  MACC_H11 <-> 0b0011,
  MULU_H00 <-> 0b0100,
  MACCU_H00 <-> 0b0101,
  MULU_H11 <-> 0b0110,
  MACCU_H11 <-> 0b0111,
  MULSU_H00 <-> 0b1100,
  MACCSU_H00 <-> 0b1101,
  MULSU_H11 <-> 0b1110,
  MACCSU_H11 <-> 0b1111,
}

mapping clause encdec = PMULWH_32ONLY(funct4, rs1, rs2, rd) <->
  0b1 @ encdec_pmulwhfunct4_32only(funct4) @ 0b01 @ encdec_reg(rs2) @ encdec_reg(rs1) @ 0b011 @ encdec_reg(rd) @ 0b0111011
  when currentlyEnabled(Ext_P) & xlen == 32

function clause execute (PMULWH_32ONLY(funct4, rs1, rs2, rd)) = {
  assert(xlen == 32);
  let rs1_val = X(rs1);
  let rs2_val = X(rs2);
  let rd_val = X(rd);
  let rs1_halfword_even = rs1_val[15..0];
  let rs2_halfword_even = rs2_val[15..0];
  let rs1_halfword_odd = rs1_val[31..16];
  let rs2_halfword_odd = rs2_val[31..16];
  let result : xlenbits = match funct4 {
    MUL_H00 => muls(rs1_halfword_even, rs2_halfword_even),
    MACC_H00 => rd_val + muls(rs1_halfword_even, rs2_halfword_even),
    MUL_H11 => muls(rs1_halfword_odd, rs2_halfword_odd),
    MACC_H11 => rd_val + muls(rs1_halfword_odd, rs2_halfword_odd),
    MULU_H00 => mulu(rs1_halfword_even, rs2_halfword_even),
    MACCU_H00 => rd_val + mulu(rs1_halfword_even, rs2_halfword_even),
    MULU_H11 => mulu(rs1_halfword_odd, rs2_halfword_odd),
    MACCU_H11 => rd_val + mulu(rs1_halfword_odd, rs2_halfword_odd),
    MULSU_H00 => mulsu(rs1_halfword_even, rs2_halfword_even),
    MACCSU_H00 => rd_val + mulsu(rs1_halfword_even, rs2_halfword_even),
    MULSU_H11 => mulsu(rs1_halfword_odd, rs2_halfword_odd),
    MACCSU_H11 => rd_val + mulsu(rs1_halfword_odd, rs2_halfword_odd),
  };
  X(rd) = result;
  RETIRE_SUCCESS
}

mapping pmulwh_mnemonic_32only : pmulwhfunct4_32only <-> string = {
  MUL_H00 <-> "mul.h00",
  MACC_H00 <-> "macc.h00",
  MUL_H11 <-> "mul.h11",
  MACC_H11 <-> "macc.h11",
  MULU_H00 <-> "mulu.h00",
  MACCU_H00 <-> "maccu.h00",
  MULU_H11 <-> "mulu.h11",
  MACCU_H11 <-> "maccu.h11",
  MULSU_H00 <-> "mulsu.h00",
  MACCSU_H00 <-> "maccsu.h00",
  MULSU_H11 <-> "mulsu.h11",
  MACCSU_H11 <-> "maccsu.h11",
}

mapping clause assembly = PMULWH_32ONLY(funct4, rs1, rs2, rd)
  <-> pmulwh_mnemonic_32only(funct4) ^ spc() ^ reg_name(rd) ^ sep() ^ reg_name(rs1) ^ sep() ^ reg_name(rs2)
  when currentlyEnabled(Ext_P) & xlen == 32

// **************** P MULTIPLICATION WORD HALFWORD 01 CONTINUED *****************
union clause instruction = PMULWH01CONTD_32ONLY : (pmulwh01contdwidth2_32only, regidx, regidx, regidx)

mapping encdec_pmulwh01contdwidth2_32only : pmulwh01contdwidth2_32only <-> bits(2) = {
  MQACC_H01 <-> 0b00,
  MQRACC_H01 <-> 0b10,
}

mapping clause encdec = PMULWH01CONTD_32ONLY(width2, rs1, rs2, rd) <->
  0b1 @ 0b1111 @ encdec_pmulwh01contdwidth2_32only(width2) @ encdec_reg(rs2) @ encdec_reg(rs1) @ 0b101 @ encdec_reg(rd) @ 0b0111011
  when currentlyEnabled(Ext_P) & xlen == 32

function clause execute (PMULWH01CONTD_32ONLY(width2, rs1, rs2, rd)) = {
  assert(xlen == 32);
  let rs1_val = X(rs1);
  let rs2_val = X(rs2);
  let rd_val = X(rd);
  let rs1_halfword_even = rs1_val[15..0];
  let rs2_halfword_odd = rs2_val[31..16];
  let result : xlenbits = match width2 {
    MQACC_H01 => rd_val + mulq(rs1_halfword_even, rs2_halfword_odd),
    MQRACC_H01 => rd_val + mulqr(rs1_halfword_even, rs2_halfword_odd),
  };
  X(rd) = result;
  RETIRE_SUCCESS
}

mapping pmulwh01contd_mnemonic_32only : pmulwh01contdwidth2_32only <-> string = {
  MQACC_H01 <-> "mqacc.h01",
  MQRACC_H01 <-> "mqracc.h01",
}

mapping clause assembly = PMULWH01CONTD_32ONLY(width2, rs1, rs2, rd)
  <-> pmulwh01contd_mnemonic_32only(width2) ^ spc() ^ reg_name(rd) ^ sep() ^ reg_name(rs1) ^ sep() ^ reg_name(rs2)
  when currentlyEnabled(Ext_P) & xlen == 32

// *************************** P MULTIPLICATION WORD ****************************
union clause instruction = PMULW_32ONLY : (pmulwfunct4_32only, regidx, regidx, regidx)

mapping encdec_pmulwfunct4_32only : pmulwfunct4_32only <-> bits(4) = {
  MHACC <-> 0b0001,
  MHACCU <-> 0b0011,
  MHACCSU <-> 0b1001,
  MULQ <-> 0b1010,
}

mapping clause encdec = PMULW_32ONLY(funct4, rs1, rs2, rd) <->
  0b1 @ encdec_pmulwfunct4_32only(funct4) @ 0b01 @ encdec_reg(rs2) @ encdec_reg(rs1) @ 0b111 @ encdec_reg(rd) @ 0b0111011
  when currentlyEnabled(Ext_P) & xlen == 32

function clause execute (PMULW_32ONLY(funct4, rs1, rs2, rd)) = {
  assert(xlen == 32);
  let rs1_val = X(rs1);
  let rs2_val = X(rs2);
  let rd_val = X(rd);
  let result : xlenbits = match funct4 {
    MHACC => rd_val + mulh(rs1_val, rs2_val),
    MHACCU => rd_val + mulhu(rs1_val, rs2_val),
    MHACCSU => rd_val + mulhsu(rs1_val, rs2_val),
    MULQ => mulq_sat(rs1_val, rs2_val)[31..0],
  };
  X(rd) = result;
  RETIRE_SUCCESS
}

mapping pmulw_mnemonic_32only : pmulwfunct4_32only <-> string = {
  MHACC <-> "mhacc",
  MHACCU <-> "mhaccu",
  MHACCSU <-> "mhaccsu",
  MULQ <-> "mulq",
}

mapping clause assembly = PMULW_32ONLY(funct4, rs1, rs2, rd)
  <-> pmulw_mnemonic_32only(funct4) ^ spc() ^ reg_name(rd) ^ sep() ^ reg_name(rs1) ^ sep() ^ reg_name(rs2)
  when currentlyEnabled(Ext_P) & xlen == 32

// ********************** P MULTIPLICATION WORD CONTINUED ***********************
union clause instruction = PMULWCONTD_32ONLY : (pmulwcontdfunct4_32only, regidx, regidx, regidx)

mapping encdec_pmulwcontdfunct4_32only : pmulwcontdfunct4_32only <-> bits(4) = {
  MULHR <-> 0b0000,
  MHRACC <-> 0b0001,
  MULHRU <-> 0b0010,
  MHRACCU <-> 0b0011,
  MULHRSU <-> 0b1000,
  MHRACCSU <-> 0b1001,
  MULQR <-> 0b1010,
}

mapping clause encdec = PMULWCONTD_32ONLY(funct4, rs1, rs2, rd) <->
  0b1 @ encdec_pmulwcontdfunct4_32only(funct4) @ 0b11 @ encdec_reg(rs2) @ encdec_reg(rs1) @ 0b111 @ encdec_reg(rd) @ 0b0111011
  when currentlyEnabled(Ext_P) & xlen == 32

function clause execute (PMULWCONTD_32ONLY(funct4, rs1, rs2, rd)) = {
  assert(xlen == 32);
  let rs1_val = X(rs1);
  let rs2_val = X(rs2);
  let rd_val = X(rd);
  let result : xlenbits = match funct4 {
    MULHR => mulhr(rs1_val, rs2_val),
    MHRACC => rd_val + mulhr(rs1_val, rs2_val),
    MULHRU => mulhru(rs1_val, rs2_val),
    MHRACCU => rd_val + mulhru(rs1_val, rs2_val),
    MULHRSU => mulhrsu(rs1_val, rs2_val),
    MHRACCSU => rd_val + mulhrsu(rs1_val, rs2_val),
    MULQR => mulqr_sat(rs1_val, rs2_val)[31..0],
  };
  X(rd) = result;
  RETIRE_SUCCESS
}

mapping pmulwcontd_mnemonic_32only : pmulwcontdfunct4_32only <-> string = {
  MULHR <-> "mulhr",
  MHRACC <-> "mhracc",
  MULHRU <-> "mulhru",
  MHRACCU <-> "mhraccu",
  MULHRSU <-> "mulhrsu",
  MHRACCSU <-> "mhraccsu",
  MULQR <-> "mulqr",
}

mapping clause assembly = PMULWCONTD_32ONLY(funct4, rs1, rs2, rd)
  <-> pmulwcontd_mnemonic_32only(funct4) ^ spc() ^ reg_name(rd) ^ sep() ^ reg_name(rs1) ^ sep() ^ reg_name(rs2)
  when currentlyEnabled(Ext_P) & xlen == 32

// ************************ P COMPARE WORD (RV32 SCALAR) ************************
union clause instruction = PCOMPAREW_32ONLY : (pcomparewfunct4_32only, regidx, regidx, regidx)

mapping encdec_pcomparewfunct4_32only : pcomparewfunct4_32only <-> bits(4) = {
  MSEQ <-> 0b1000,
  MSLT <-> 0b1010,
  MSLTU <-> 0b1011,
}

mapping clause encdec = PCOMPAREW_32ONLY(funct4, rs1, rs2, rd) <->
  0b1 @ encdec_pcomparewfunct4_32only(funct4) @ 0b01 @ encdec_reg(rs2) @ encdec_reg(rs1) @ 0b110 @ encdec_reg(rd) @ 0b0111011
  when currentlyEnabled(Ext_P) & xlen == 32

function clause execute (PCOMPAREW_32ONLY(funct4, rs1, rs2, rd)) = {
  assert(xlen == 32);
  let rs1_val = X(rs1);
  let rs2_val = X(rs2);
  X(rd) = match funct4 {
    MSEQ => mseq(rs1_val, rs2_val),
    MSLT => mslt(rs1_val, rs2_val),
    MSLTU => msltu(rs1_val, rs2_val),
  };
  RETIRE_SUCCESS
}

mapping pcomparew_mnemonic_32only : pcomparewfunct4_32only <-> string = {
  MSEQ <-> "mseq",
  MSLT <-> "mslt",
  MSLTU <-> "msltu",
}

mapping clause assembly = PCOMPAREW_32ONLY(funct4, rs1, rs2, rd)
  <-> pcomparew_mnemonic_32only(funct4) ^ spc() ^ reg_name(rd) ^ sep() ^ reg_name(rs1) ^ sep() ^ reg_name(rs2)
  when currentlyEnabled(Ext_P) & xlen == 32

// ******************* P MULTIPLICATION WORD HALFWORD SIGNED ********************
union clause instruction = PMULWHSIGNED_32ONLY : (pmulwhsignedfunct4_32only, regidx, regidx, regidx)

mapping encdec_pmulwhsignedfunct4_32only : pmulwhsignedfunct4_32only <-> bits(4) = {
  MULH_H0 <-> 0b0100,
  MHACC_H0 <-> 0b0101,
  MULH_H1 <-> 0b0110,
  MHACC_H1 <-> 0b0111,
}

mapping clause encdec = PMULWHSIGNED_32ONLY(funct4, rs1, rs2, rd) <->
  0b1 @ encdec_pmulwhsignedfunct4_32only(funct4) @ 0b01 @ encdec_reg(rs2) @ encdec_reg(rs1) @ 0b111 @ encdec_reg(rd) @ 0b0111011
  when currentlyEnabled(Ext_P) & xlen == 32

function clause execute (PMULWHSIGNED_32ONLY(funct4, rs1, rs2, rd)) = {
  assert(xlen == 32);
  let rs1_val = X(rs1);
  let rs2_val = X(rs2);
  let rd_val = X(rd);
  let rs2_halfword_even = rs2_val[15..0];
  let rs2_halfword_odd = rs2_val[31..16];
  let result : xlenbits = match funct4 {
    MULH_H0 => mulh_mixed(rs1_val, rs2_halfword_even),
    MHACC_H0 => rd_val + mulh_mixed(rs1_val, rs2_halfword_even),
    MULH_H1 => mulh_mixed(rs1_val, rs2_halfword_odd),
    MHACC_H1 => rd_val + mulh_mixed(rs1_val, rs2_halfword_odd),
  };
  X(rd) = result;
  RETIRE_SUCCESS
}

mapping pmulwhsigned_mnemonic_32only : pmulwhsignedfunct4_32only <-> string = {
  MULH_H0 <-> "mulh.h0",
  MHACC_H0 <-> "mhacc.h0",
  MULH_H1 <-> "mulh.h1",
  MHACC_H1 <-> "mhacc.h1",
}

mapping clause assembly = PMULWHSIGNED_32ONLY(funct4, rs1, rs2, rd)
  <-> pmulwhsigned_mnemonic_32only(funct4) ^ spc() ^ reg_name(rd) ^ sep() ^ reg_name(rs1) ^ sep() ^ reg_name(rs2)
  when currentlyEnabled(Ext_P) & xlen == 32

// ****************** P MULTIPLICATION WORD HALFWORD UNSIGNED *******************
union clause instruction = PMULWHUNSIGNED_32ONLY : (pmulwhunsignedfunct4_32only, regidx, regidx, regidx)

mapping encdec_pmulwhunsignedfunct4_32only : pmulwhunsignedfunct4_32only <-> bits(4) = {
  MULHSU_H0 <-> 0b0100,
  MHACCSU_H0 <-> 0b0101,
  MULHSU_H1 <-> 0b0110,
  MHACCSU_H1 <-> 0b0111,
}

mapping clause encdec = PMULWHUNSIGNED_32ONLY(funct4, rs1, rs2, rd) <->
  0b1 @ encdec_pmulwhunsignedfunct4_32only(funct4) @ 0b11 @ encdec_reg(rs2) @ encdec_reg(rs1) @ 0b111 @ encdec_reg(rd) @ 0b0111011
  when currentlyEnabled(Ext_P) & xlen == 32

function clause execute (PMULWHUNSIGNED_32ONLY(funct4, rs1, rs2, rd)) = {
  assert(xlen == 32);
  let rs1_val = X(rs1);
  let rs2_val = X(rs2);
  let rd_val = X(rd);
  let rs2_halfword_even = rs2_val[15..0];
  let rs2_halfword_odd = rs2_val[31..16];
  let result : xlenbits = match funct4 {
    MULHSU_H0 => mulhsu_mixed(rs1_val, rs2_halfword_even),
    MHACCSU_H0 => rd_val + mulhsu_mixed(rs1_val, rs2_halfword_even),
    MULHSU_H1 => mulhsu_mixed(rs1_val, rs2_halfword_odd),
    MHACCSU_H1 => rd_val + mulhsu_mixed(rs1_val, rs2_halfword_odd),
  };
  X(rd) = result;
  RETIRE_SUCCESS
}

mapping pmulwhunsigned_mnemonic_32only : pmulwhunsignedfunct4_32only <-> string = {
  MULHSU_H0 <-> "mulhsu.h0",
  MHACCSU_H0 <-> "mhaccsu.h0",
  MULHSU_H1 <-> "mulhsu.h1",
  MHACCSU_H1 <-> "mhaccsu.h1",
}

mapping clause assembly = PMULWHUNSIGNED_32ONLY(funct4, rs1, rs2, rd)
  <-> pmulwhunsigned_mnemonic_32only(funct4) ^ spc() ^ reg_name(rd) ^ sep() ^ reg_name(rs1) ^ sep() ^ reg_name(rs2)
  when currentlyEnabled(Ext_P) & xlen == 32

// ****************** P MULTIPLICATION WORD HALFWORD CONTINUED ******************
union clause instruction = PMULWHCONTD_32ONLY : (pmulwhcontdfunct4_32only, regidx, regidx, regidx)

mapping encdec_pmulwhcontdfunct4_32only : pmulwhcontdfunct4_32only <-> bits(4) = {
  MQACC_H00 <-> 0b1101,
  MQACC_H11 <-> 0b1111,
}

mapping clause encdec = PMULWHCONTD_32ONLY(funct4, rs1, rs2, rd) <->
  0b1 @ encdec_pmulwhcontdfunct4_32only(funct4) @ 0b00 @ encdec_reg(rs2) @ encdec_reg(rs1) @ 0b111 @ encdec_reg(rd) @ 0b0111011
  when currentlyEnabled(Ext_P) & xlen == 32

function clause execute (PMULWHCONTD_32ONLY(funct4, rs1, rs2, rd)) = {
  assert(xlen == 32);
  let rs1_val = X(rs1);
  let rs2_val = X(rs2);
  let rd_val = X(rd);
  let rs1_halfword_even = rs1_val[15..0];
  let rs2_halfword_even = rs2_val[15..0];
  let rs1_halfword_odd = rs1_val[31..16];
  let rs2_halfword_odd = rs2_val[31..16];
  let result : xlenbits = match funct4 {
    MQACC_H00 => rd_val + mulq(rs1_halfword_even, rs2_halfword_even),
    MQACC_H11 => rd_val + mulq(rs1_halfword_odd, rs2_halfword_odd),
  };
  X(rd) = result;
  RETIRE_SUCCESS
}

mapping pmulwhcontd_mnemonic_32only : pmulwhcontdfunct4_32only <-> string = {
  MQACC_H00 <-> "mqacc.h00",
  MQACC_H11 <-> "mqacc.h11",
}

mapping clause assembly = PMULWHCONTD_32ONLY(funct4, rs1, rs2, rd)
  <-> pmulwhcontd_mnemonic_32only(funct4) ^ spc() ^ reg_name(rd) ^ sep() ^ reg_name(rs1) ^ sep() ^ reg_name(rs2)
  when currentlyEnabled(Ext_P) & xlen == 32

// ***************** P MULTIPLICATION WORD HALFWORD CONTINUED 2 *****************
union clause instruction = PMULWHCONTD2_32ONLY : (pmulwhcontd2funct4_32only, regidx, regidx, regidx)

mapping encdec_pmulwhcontd2funct4_32only : pmulwhcontd2funct4_32only <-> bits(4) = {
  MQRACC_H00 <-> 0b1101,
  MQRACC_H11 <-> 0b1111,
}
mapping clause encdec = PMULWHCONTD2_32ONLY(funct4, rs1, rs2, rd) <->
  0b1 @ encdec_pmulwhcontd2funct4_32only(funct4) @ 0b10 @ encdec_reg(rs2) @ encdec_reg(rs1) @ 0b111 @ encdec_reg(rd) @ 0b0111011
  when currentlyEnabled(Ext_P) & xlen == 32

function clause execute (PMULWHCONTD2_32ONLY(funct4, rs1, rs2, rd)) = {
  assert(xlen == 32);
  let rs1_val = X(rs1);
  let rs2_val = X(rs2);
  let rd_val = X(rd);
  let rs1_halfword_even = rs1_val[15..0];
  let rs2_halfword_even = rs2_val[15..0];
  let rs1_halfword_odd = rs1_val[31..16];
  let rs2_halfword_odd = rs2_val[31..16];
  let result : xlenbits = match funct4 {
    MQRACC_H00 => rd_val + mulqr(rs1_halfword_even, rs2_halfword_even),
    MQRACC_H11 => rd_val + mulqr(rs1_halfword_odd, rs2_halfword_odd),
  };
  X(rd) = result;
  RETIRE_SUCCESS
}

mapping pmulwhcontd2_mnemonic_32only : pmulwhcontd2funct4_32only <-> string = {
  MQRACC_H00 <-> "mqracc.h00",
  MQRACC_H11 <-> "mqracc.h11",
}

mapping clause assembly = PMULWHCONTD2_32ONLY(funct4, rs1, rs2, rd)
  <-> pmulwhcontd2_mnemonic_32only(funct4) ^ spc() ^ reg_name(rd) ^ sep() ^ reg_name(rs1) ^ sep() ^ reg_name(rs2)
  when currentlyEnabled(Ext_P) & xlen == 32

// ********************** P WIDENING SHIFT IMMEDIATE BYTE ***********************
union clause instruction = PWSHIFTIB_32ONLY : (pwshiftibfunct3_32only, bits(4), regidx, pregidx)

mapping encdec_pwshiftibfunct3_32only : pwshiftibfunct3_32only <-> bits(3) = {
  PWSLLI_B <-> 0b000,
  PWSLAI_B <-> 0b100,
}

mapping clause encdec = PWSHIFTIB_32ONLY(funct3, imm4, rs1, rdp)
  <-> 0b0 @ encdec_pwshiftibfunct3_32only(funct3) @ 0b0 @ 0b001 @ imm4 @ encdec_reg(rs1) @ 0b010 @ encdec_preg(rdp) @ 0b00011011
  when currentlyEnabled(Ext_P) & xlen == 32

function clause execute (PWSHIFTIB_32ONLY(funct3, imm4, rs1, rdp)) = {
  assert(xlen == 32);
  let rs1_val = X(rs1);
  let shamt : nat = unsigned(imm4);
  var result : bits(64) = zeros();
  foreach (i from 0 to (sizeof(xlen) - 8) by 8) {
    let rs1_byte = slice(rs1_val, i, 8);
    result[(2*i+15)..(2*i)] = match funct3 {
      PWSLLI_B => zero_extend(rs1_byte) << shamt,
      PWSLAI_B => sign_extend(rs1_byte) << shamt,
    };
  };
  X_pair(regidx_of_pregidx(rdp)) = result;
  RETIRE_SUCCESS
}

mapping pwshiftib_mnemonic_32only : pwshiftibfunct3_32only <-> string = {
  PWSLLI_B <-> "pwslli.b",
  PWSLAI_B <-> "pwslai.b",
}

mapping clause assembly = PWSHIFTIB_32ONLY(funct3, imm4, rs1, rdp)
  <-> pwshiftib_mnemonic_32only(funct3) ^ spc() ^ preg_name(rdp) ^ sep() ^ reg_name(rs1) ^ sep() ^ hex_bits_4(imm4)
  when currentlyEnabled(Ext_P) & xlen == 32

// ******************** P WIDENING SHIFT IMMEDIATE HALFWORD *********************
union clause instruction = PWSHIFTIH_32ONLY : (pwshiftihfunct3_32only, bits(5), regidx, pregidx)

mapping encdec_pwshiftihfunct3_32only : pwshiftihfunct3_32only <-> bits(3) = {
  PWSLLI_H <-> 0b000,
  PWSLAI_H <-> 0b100,
}

mapping clause encdec = PWSHIFTIH_32ONLY(funct3, imm5, rs1, rdp)
  <-> 0b0 @ encdec_pwshiftihfunct3_32only(funct3) @ 0b0 @ 0b01 @ imm5 @ encdec_reg(rs1) @ 0b010 @ encdec_preg(rdp) @ 0b00011011
  when currentlyEnabled(Ext_P) & xlen == 32

function clause execute (PWSHIFTIH_32ONLY(funct3, imm5, rs1, rdp)) = {
  assert(xlen == 32);
  let rs1_val = X(rs1);
  let shamt : nat = unsigned(imm5);
  var result : bits(64) = zeros();
  foreach (i from 0 to (sizeof(xlen) - 16) by 16) {
    let rs1_halfword = slice(rs1_val, i, 16);
    result[(2*i+31)..(2*i)] = match funct3 {
      PWSLLI_H => zero_extend(rs1_halfword) << shamt,
      PWSLAI_H => sign_extend(rs1_halfword) << shamt,
    };
  };
  X_pair(regidx_of_pregidx(rdp)) = result;
  RETIRE_SUCCESS
}

mapping pwshiftih_mnemonic_32only : pwshiftihfunct3_32only <-> string = {
  PWSLLI_H <-> "pwslli.h",
  PWSLAI_H <-> "pwslai.h",
}

mapping clause assembly = PWSHIFTIH_32ONLY(funct3, imm5, rs1, rdp)
  <-> pwshiftih_mnemonic_32only(funct3) ^ spc() ^ preg_name(rdp) ^ sep() ^ reg_name(rs1) ^ sep() ^ hex_bits_5(imm5)
  when currentlyEnabled(Ext_P) & xlen == 32

// ********************** P WIDENING SHIFT IMMEDIATE WORD ***********************
union clause instruction = PWSHIFTIW_32ONLY : (pwshiftiwfunct3_32only, bits(6), regidx, pregidx)

mapping encdec_pwshiftiwfunct3_32only : pwshiftiwfunct3_32only <-> bits(3) = {
  WSLLI <-> 0b000,
  WSLAI <-> 0b100,
}

mapping clause encdec = PWSHIFTIW_32ONLY(funct3, imm6, rs1, rdp)
  <-> 0b0 @ encdec_pwshiftiwfunct3_32only(funct3) @ 0b0 @ 0b1 @ imm6 @ encdec_reg(rs1) @ 0b010 @ encdec_preg(rdp) @ 0b00011011
  when currentlyEnabled(Ext_P) & xlen == 32

function clause execute (PWSHIFTIW_32ONLY(funct3, imm6, rs1, rdp)) = {
  assert(xlen == 32);
  let rs1_val = X(rs1);
  let shamt : nat = unsigned(imm6);
  let result : bits(64) = match funct3 {
    WSLLI => zero_extend(rs1_val) << shamt,
    WSLAI => sign_extend(rs1_val) << shamt,
  };
  X_pair(regidx_of_pregidx(rdp)) = result;
  RETIRE_SUCCESS
}

mapping pwshiftiw_mnemonic_32only : pwshiftiwfunct3_32only <-> string = {
  WSLLI <-> "wslli",
  WSLAI <-> "wslai",
}

mapping clause assembly = PWSHIFTIW_32ONLY(funct3, imm6, rs1, rdp)
  <-> pwshiftiw_mnemonic_32only(funct3) ^ spc() ^ preg_name(rdp) ^ sep() ^ reg_name(rs1) ^ sep() ^ hex_bits_6(imm6)
  when currentlyEnabled(Ext_P) & xlen == 32

// ************************ P LOAD IMMEDIATE DOUBLE BYTE ************************
union clause instruction = PLIDB_32ONLY : (bits(8), pregidx)

mapping clause encdec = PLIDB_32ONLY(imm8, rdp)
  <-> 0b00110 @ 0b100 @ imm8 @ 0b0010 @ encdec_preg(rdp) @ 0b00011011
  when currentlyEnabled(Ext_P) & xlen == 32

function clause execute (PLIDB_32ONLY(imm8, rdp)) = {
  assert(xlen == 32);
  var result : bits(64) = zeros();
  foreach (i from 0 to (64 - 8) by 8) {
    result[(i+7)..i] = imm8;
  };
  X_pair(regidx_of_pregidx(rdp)) = result;
  RETIRE_SUCCESS
}

mapping clause assembly = PLIDB_32ONLY(imm8, rdp)
  <-> "pli.db" ^ spc() ^ preg_name(rdp) ^ sep() ^ hex_bits_8(imm8)
  when currentlyEnabled(Ext_P) & xlen == 32

// ********************** P LOAD IMMEDIATE DOUBLE HALFWORD **********************
union clause instruction = PLIDH_32ONLY : (plidhfunct5_32only, bits(10), pregidx)

mapping encdec_plidhfunct5_32only : plidhfunct5_32only <-> bits(5) = {
  PLI_DH <-> 0b00110,
  PLUI_DH <-> 0b01110,
}

mapping clause encdec = PLIDH_32ONLY(funct5, imm10, rdp)
  <-> encdec_plidhfunct5_32only(funct5) @ 0b00 @ imm10 @ 0b010 @ encdec_preg(rdp) @ 0b00011011
  when currentlyEnabled(Ext_P) & xlen == 32

function clause execute (PLIDH_32ONLY(funct5, imm10, rdp)) = {
  assert(xlen == 32);
  var result : bits(64) = zeros();
  foreach (i from 0 to (64 - 16) by 16) {
    result[(i+15)..i] = match funct5 {
      PLI_DH => sign_extend(imm10[0] @ imm10[9..1]),
      PLUI_DH => imm10[8..0] @ imm10[9] @ sail_zeros(6),
    };
  };
  X_pair(regidx_of_pregidx(rdp)) = result;
  RETIRE_SUCCESS
}

mapping plidh_mnemonic_32only : plidhfunct5_32only <-> string = {
  PLI_DH <-> "pli.dh",
  PLUI_DH <-> "plui.dh",
}

mapping clause assembly = PLIDH_32ONLY(funct5, imm10, rdp)
  <-> plidh_mnemonic_32only(funct5) ^ spc() ^ preg_name(rdp) ^ sep() ^ hex_bits_10(imm10)
  when currentlyEnabled(Ext_P) & xlen == 32

// ************************ P WIDENING SHIFT BYTE SCALAR ************************
union clause instruction = PWSHIFTBS_32ONLY : (pwshiftbsfunct3_32only, regidx, regidx, pregidx)

mapping encdec_pwshiftbsfunct3_32only : pwshiftbsfunct3_32only <-> bits(3) = {
  PWSLL_BS <-> 0b000,
  PWSLA_BS <-> 0b100,
}

mapping clause encdec = PWSHIFTBS_32ONLY(funct3, rs1, rs2, rdp)
  <-> 0b0 @ encdec_pwshiftbsfunct3_32only(funct3) @ 0b1 @ 0b00 @ encdec_reg(rs2) @ encdec_reg(rs1) @ 0b010 @ encdec_preg(rdp) @ 0b00011011
  when currentlyEnabled(Ext_P) & xlen == 32

function clause execute (PWSHIFTBS_32ONLY(funct3, rs1, rs2, rdp)) = {
  assert(xlen == 32);
  let rs1_val = X(rs1);
  let shamt : nat = unsigned(X(rs2)[4..0]);
  var result : bits(64) = zeros();
  foreach (i from 0 to (sizeof(xlen) - 8) by 8) {
    let rs1_byte = slice(rs1_val, i, 8);
    result[(2*i+15)..(2*i)] = match funct3 {
      PWSLL_BS => zero_extend(rs1_byte) << shamt,
      PWSLA_BS => sign_extend(rs1_byte) << shamt,
    };
  };
  X_pair(regidx_of_pregidx(rdp)) = result;
  RETIRE_SUCCESS
}

mapping pwshiftbs_mnemonic_32only : pwshiftbsfunct3_32only <-> string = {
  PWSLL_BS <-> "pwsll.bs",
  PWSLA_BS <-> "pwsla.bs",
}

mapping clause assembly = PWSHIFTBS_32ONLY(funct3, rs1, rs2, rdp)
  <-> pwshiftbs_mnemonic_32only(funct3) ^ spc() ^ preg_name(rdp) ^ sep() ^ reg_name(rs1) ^ sep() ^ reg_name(rs2)
  when currentlyEnabled(Ext_P) & xlen == 32

// ********************** P WIDENING SHIFT HALFWORD SCALAR **********************
union clause instruction = PWSHIFTHS_32ONLY : (pwshifthsfunct3_32only, regidx, regidx, pregidx)

mapping encdec_pwshifthsfunct3_32only : pwshifthsfunct3_32only <-> bits(3) = {
  PWSLL_HS <-> 0b000,
  PWSLA_HS <-> 0b100,
}

mapping clause encdec = PWSHIFTHS_32ONLY(funct3, rs1, rs2, rdp)
  <-> 0b0 @ encdec_pwshifthsfunct3_32only(funct3) @ 0b1 @ 0b01 @ encdec_reg(rs2) @ encdec_reg(rs1) @ 0b010 @ encdec_preg(rdp) @ 0b00011011
  when currentlyEnabled(Ext_P) & xlen == 32

function clause execute (PWSHIFTHS_32ONLY(funct3, rs1, rs2, rdp)) = {
  assert(xlen == 32);
  let rs1_val = X(rs1);
  let shamt : nat = unsigned(X(rs2)[4..0]);
  var result : bits(64) = zeros();
  foreach (i from 0 to (sizeof(xlen) - 16) by 16) {
    let rs1_halfword = slice(rs1_val, i, 16);
    result[(2*i+31)..(2*i)] = match funct3 {
      PWSLL_HS => zero_extend(rs1_halfword) << shamt,
      PWSLA_HS => sign_extend(rs1_halfword) << shamt,
    };
  };
  X_pair(regidx_of_pregidx(rdp)) = result;
  RETIRE_SUCCESS
}

mapping pwshifths_mnemonic_32only : pwshifthsfunct3_32only <-> string = {
  PWSLL_HS <-> "pwsll.hs",
  PWSLA_HS <-> "pwsla.hs",
}

mapping clause assembly = PWSHIFTHS_32ONLY(funct3, rs1, rs2, rdp)
  <-> pwshifths_mnemonic_32only(funct3) ^ spc() ^ preg_name(rdp) ^ sep() ^ reg_name(rs1) ^ sep() ^ reg_name(rs2)
  when currentlyEnabled(Ext_P) & xlen == 32

// ************************ P WIDENING SHIFT WORD SCALAR ************************
union clause instruction = PWSHIFTWS_32ONLY : (pwshiftwsfunct3_32only, regidx, regidx, pregidx)

mapping encdec_pwshiftwsfunct3_32only : pwshiftwsfunct3_32only <-> bits(3) = {
  WSLL <-> 0b000,
  WSLA <-> 0b100,
}

mapping clause encdec = PWSHIFTWS_32ONLY(funct3, rs1, rs2, rdp)
  <-> 0b0 @ encdec_pwshiftwsfunct3_32only(funct3) @ 0b1 @ 0b11 @ encdec_reg(rs2) @ encdec_reg(rs1) @ 0b010 @ encdec_preg(rdp) @ 0b00011011
  when currentlyEnabled(Ext_P) & xlen == 32

function clause execute (PWSHIFTWS_32ONLY(funct3, rs1, rs2, rdp)) = {
  assert(xlen == 32);
  let rs1_val = X(rs1);
  let shamt : nat = unsigned(X(rs2)[5..0]);
  let result : bits(64) = match funct3 {
    WSLL => zero_extend(rs1_val) << shamt,
    WSLA => sign_extend(rs1_val) << shamt,
  };
  X_pair(regidx_of_pregidx(rdp)) = result;
  RETIRE_SUCCESS
}

mapping pwshiftws_mnemonic_32only : pwshiftwsfunct3_32only <-> string = {
  WSLL <-> "wsll",
  WSLA <-> "wsla",
}

mapping clause assembly = PWSHIFTWS_32ONLY(funct3, rs1, rs2, rdp)
  <-> pwshiftws_mnemonic_32only(funct3) ^ spc() ^ preg_name(rdp) ^ sep() ^ reg_name(rs1) ^ sep() ^ reg_name(rs2)
  when currentlyEnabled(Ext_P) & xlen == 32

// ******************************* P WIDENING ZIP *******************************
union clause instruction = PWZIP_32ONLY : (pwzipwidth2_32only, regidx, regidx, pregidx)

mapping encdec_pwzipwidth2_32only : pwzipwidth2_32only <-> bits(2) = {
  WZIP8P <-> 0b00,
  WZIP16P <-> 0b01,
}

mapping clause encdec = PWZIP_32ONLY(width2, rs1, rs2, rdp) <->
  0b0 @ 0b111 @ 0b1 @ encdec_pwzipwidth2_32only(width2) @ encdec_reg(rs2) @ encdec_reg(rs1) @ 0b010 @ encdec_preg(rdp) @ 0b00011011
  when currentlyEnabled(Ext_P) & xlen == 32

function clause execute (PWZIP_32ONLY(width2, rs1, rs2, rdp)) = {
  assert(xlen == 32);
  let rs1_val = X(rs1);
  let rs2_val = X(rs2);
  let result : bits(64) = match width2 {
    WZIP8P => rs2_val[31..24] @ rs1_val[31..24] @ rs2_val[23..16] @ rs1_val[23..16]
                 @ rs2_val[15..8] @ rs1_val[15..8] @ rs2_val[7..0] @ rs1_val[7..0],
    WZIP16P => rs2_val[31..16] @ rs1_val[31..16] @ rs2_val[15..0] @ rs1_val[15..0],
  };
  X_pair(regidx_of_pregidx(rdp)) = result;
  RETIRE_SUCCESS
}

mapping pwzipwidth2_mnemonic_32only : pwzipwidth2_32only <-> string = {
  WZIP8P <-> "wzip8p",
  WZIP16P <-> "wzip16p",
}

mapping clause assembly = PWZIP_32ONLY(width2, rs1, rs2, rdp)
  <-> pwzipwidth2_mnemonic_32only(width2) ^ spc() ^ preg_name(rdp) ^ sep() ^ reg_name(rs1) ^ sep() ^ reg_name(rs2)
  when currentlyEnabled(Ext_P) & xlen == 32

// **************************** P WIDENING ALU BYTE *****************************
union clause instruction = PWALUB_32ONLY : (pwalubfunct4_32only, regidx, regidx, pregidx)

mapping encdec_pwalubfunct4_32only : pwalubfunct4_32only <-> bits(4) = {
  PWADD_B <-> 0b0000,
  PWADDA_B <-> 0b0001,
  PWADDU_B <-> 0b0010,
  PWADDAU_B <-> 0b0011,
  PWMUL_B <-> 0b0100,
  PWMULU_B <-> 0b0110,
  PWSUB_B <-> 0b1000,
  PWSUBA_B <-> 0b1001,
  PWSUBU_B <-> 0b1010,
  PWSUBAU_B <-> 0b1011,
  PWMULSU_B <-> 0b1100,
}

mapping clause encdec = PWALUB_32ONLY(funct4, rs1, rs2, rdp) <->
  0b0 @ encdec_pwalubfunct4_32only(funct4) @ 0b10 @ encdec_reg(rs2) @ encdec_reg(rs1) @ 0b010 @ encdec_preg(rdp) @ 0b10011011
  when currentlyEnabled(Ext_P) & xlen == 32

function clause execute (PWALUB_32ONLY(funct4, rs1, rs2, rdp)) = {
  assert(xlen == 32);
  let rs1_val = X(rs1);
  let rs2_val = X(rs2);
  let rd_val = X_pair(regidx_of_pregidx(rdp));
  var result : bits(64) = zeros();
  foreach (i from 0 to (sizeof(xlen) - 8) by 8) {
    let rs1_byte = slice(rs1_val, i, 8);
    let rs2_byte = slice(rs2_val, i, 8);
    let rd_halfword = slice(rd_val, 2 * i, 16);
    result[(2*i+15)..(2*i)] = match funct4 {
      PWADD_B => sign_extend(rs1_byte) + sign_extend(rs2_byte),
      PWADDA_B => rd_halfword + sign_extend(rs1_byte) + sign_extend(rs2_byte),
      PWADDU_B => zero_extend(rs1_byte) + zero_extend(rs2_byte),
      PWADDAU_B => rd_halfword + zero_extend(rs1_byte) + zero_extend(rs2_byte),
      PWMUL_B => muls(rs1_byte, rs2_byte),
      PWMULU_B => mulu(rs1_byte, rs2_byte),
      PWSUB_B => sign_extend(rs1_byte) - sign_extend(rs2_byte),
      PWSUBA_B => rd_halfword + sign_extend(rs1_byte) - sign_extend(rs2_byte),
      PWSUBU_B => zero_extend(rs1_byte) - zero_extend(rs2_byte),
      PWSUBAU_B => rd_halfword + zero_extend(rs1_byte) - zero_extend(rs2_byte),
      PWMULSU_B => mulsu(rs1_byte, rs2_byte),
    };
  };
  X_pair(regidx_of_pregidx(rdp)) = result;
  RETIRE_SUCCESS
}

mapping pwalub_mnemonic_32only : pwalubfunct4_32only <-> string = {
  PWADD_B <-> "pwadd.b",
  PWADDA_B <-> "pwadda.b",
  PWADDU_B <-> "pwaddu.b",
  PWADDAU_B <-> "pwaddau.b",
  PWMUL_B <-> "pwmul.b",
  PWMULU_B <-> "pwmulu.b",
  PWSUB_B <-> "pwsub.b",
  PWSUBA_B <-> "pwsuba.b",
  PWSUBU_B <-> "pwsubu.b",
  PWSUBAU_B <-> "pwsubau.b",
  PWMULSU_B <-> "pwmulsu.b",
}

mapping clause assembly = PWALUB_32ONLY(funct4, rs1, rs2, rdp)
  <-> pwalub_mnemonic_32only(funct4) ^ spc() ^ preg_name(rdp) ^ sep() ^ reg_name(rs1) ^ sep() ^ reg_name(rs2)
  when currentlyEnabled(Ext_P) & xlen == 32

// ************************** P WIDENING ALU HALFWORD ***************************
union clause instruction = PWALUH_32ONLY : (pwaluhfunct4_32only, regidx, regidx, pregidx)

mapping encdec_pwaluhfunct4_32only : pwaluhfunct4_32only <-> bits(4) = {
  PWADD_H <-> 0b0000,
  PWADDA_H <-> 0b0001,
  PWADDU_H <-> 0b0010,
  PWADDAU_H <-> 0b0011,
  PWMUL_H <-> 0b0100,
  PWMACC_H <-> 0b0101,
  PWMULU_H <-> 0b0110,
  PWMACCU_H <-> 0b0111,
  PWSUB_H <-> 0b1000,
  PWSUBA_H <-> 0b1001,
  PWSUBU_H <-> 0b1010,
  PWSUBAU_H <-> 0b1011,
  PWMULSU_H <-> 0b1100,
  PWMACCSU_H <-> 0b1101,
}

mapping clause encdec = PWALUH_32ONLY(funct4, rs1, rs2, rdp) <->
  0b0 @ encdec_pwaluhfunct4_32only(funct4) @ 0b00 @ encdec_reg(rs2) @ encdec_reg(rs1) @ 0b010 @ encdec_preg(rdp) @ 0b10011011
  when currentlyEnabled(Ext_P) & xlen == 32

function clause execute (PWALUH_32ONLY(funct4, rs1, rs2, rdp)) = {
  assert(xlen == 32);
  let rs1_val = X(rs1);
  let rs2_val = X(rs2);
  let rd_val = X_pair(regidx_of_pregidx(rdp));
  var result : bits(64) = zeros();
  foreach (i from 0 to (sizeof(xlen) - 16) by 16) {
    let rs1_halfword = slice(rs1_val, i, 16);
    let rs2_halfword = slice(rs2_val, i, 16);
    let rd_word = slice(rd_val, 2 * i, 32);
    result[(2*i+31)..(2*i)] = match funct4 {
      PWADD_H => sign_extend(rs1_halfword) + sign_extend(rs2_halfword),
      PWADDA_H => rd_word + sign_extend(rs1_halfword) + sign_extend(rs2_halfword),
      PWADDU_H => zero_extend(rs1_halfword) + zero_extend(rs2_halfword),
      PWADDAU_H => rd_word + zero_extend(rs1_halfword) + zero_extend(rs2_halfword),
      PWMUL_H => muls(rs1_halfword, rs2_halfword),
      PWMACC_H => rd_word + muls(rs1_halfword, rs2_halfword),
      PWMULU_H => mulu(rs1_halfword, rs2_halfword),
      PWMACCU_H => rd_word + mulu(rs1_halfword, rs2_halfword),
      PWSUB_H => sign_extend(rs1_halfword) - sign_extend(rs2_halfword),
      PWSUBA_H => rd_word + sign_extend(rs1_halfword) - sign_extend(rs2_halfword),
      PWSUBU_H => zero_extend(rs1_halfword) - zero_extend(rs2_halfword),
      PWSUBAU_H => rd_word + zero_extend(rs1_halfword) - zero_extend(rs2_halfword),
      PWMULSU_H => mulsu(rs1_halfword, rs2_halfword),
      PWMACCSU_H => rd_word + mulsu(rs1_halfword, rs2_halfword),
    };
  };
  X_pair(regidx_of_pregidx(rdp)) = result;
  RETIRE_SUCCESS
}

mapping pwaluh_mnemonic_32only : pwaluhfunct4_32only <-> string = {
  PWADD_H <-> "pwadd.h",
  PWADDA_H <-> "pwadda.h",
  PWADDU_H <-> "pwaddu.h",
  PWADDAU_H <-> "pwaddau.h",
  PWMUL_H <-> "pwmul.h",
  PWMACC_H <-> "pwmacc.h",
  PWMULU_H <-> "pwmulu.h",
  PWMACCU_H <-> "pwmaccu.h",
  PWSUB_H <-> "pwsub.h",
  PWSUBA_H <-> "pwsuba.h",
  PWSUBU_H <-> "pwsubu.h",
  PWSUBAU_H <-> "pwsubau.h",
  PWMULSU_H <-> "pwmulsu.h",
  PWMACCSU_H <-> "pwmaccsu.h",
}

mapping clause assembly = PWALUH_32ONLY(funct4, rs1, rs2, rdp)
  <-> pwaluh_mnemonic_32only(funct4) ^ spc() ^ preg_name(rdp) ^ sep() ^ reg_name(rs1) ^ sep() ^ reg_name(rs2)
  when currentlyEnabled(Ext_P) & xlen == 32

// **************************** P WIDENING ALU WORD *****************************
union clause instruction = PWALUW_32ONLY : (pwaluwfunct4_32only, regidx, regidx, pregidx)

mapping encdec_pwaluwfunct4_32only : pwaluwfunct4_32only <-> bits(4) = {
  WADD <-> 0b0000,
  WADDA <-> 0b0001,
  WADDU <-> 0b0010,
  WADDAU <-> 0b0011,
  WMUL <-> 0b0100,
  WMACC <-> 0b0101,
  WMULU <-> 0b0110,
  WMACCU <-> 0b0111,
  WSUB <-> 0b1000,
  WSUBA <-> 0b1001,
  WSUBU <-> 0b1010,
  WSUBAU <-> 0b1011,
  WMULSU <-> 0b1100,
  WMACCSU <-> 0b1101,
}

mapping clause encdec = PWALUW_32ONLY(funct4, rs1, rs2, rdp) <->
  0b0 @ encdec_pwaluwfunct4_32only(funct4) @ 0b01 @ encdec_reg(rs2) @ encdec_reg(rs1) @ 0b010 @ encdec_preg(rdp) @ 0b10011011
  when currentlyEnabled(Ext_P) & xlen == 32

function clause execute (PWALUW_32ONLY(funct4, rs1, rs2, rdp)) = {
  assert(xlen == 32);
  let rs1_val = X(rs1);
  let rs2_val = X(rs2);
  let rd_val = X_pair(regidx_of_pregidx(rdp));
  let result : bits(64) = match funct4 {
    WADD => sign_extend(rs1_val) + sign_extend(rs2_val),
    WADDA => rd_val + sign_extend(rs1_val) + sign_extend(rs2_val),
    WADDU => zero_extend(rs1_val) + zero_extend(rs2_val),
    WADDAU => rd_val + zero_extend(rs1_val) + zero_extend(rs2_val),
    WMUL => muls(rs1_val, rs2_val),
    WMACC => rd_val + muls(rs1_val, rs2_val),
    WMULU => mulu(rs1_val, rs2_val),
    WMACCU => rd_val + mulu(rs1_val, rs2_val),
    WSUB => sign_extend(rs1_val) - sign_extend(rs2_val),
    WSUBA => rd_val + sign_extend(rs1_val) - sign_extend(rs2_val),
    WSUBU => zero_extend(rs1_val) - zero_extend(rs2_val),
    WSUBAU => rd_val + zero_extend(rs1_val) - zero_extend(rs2_val),
    WMULSU => mulsu(rs1_val, rs2_val),
    WMACCSU => rd_val + mulsu(rs1_val, rs2_val),
  };
  X_pair(regidx_of_pregidx(rdp)) = result;
  RETIRE_SUCCESS
}

mapping pwaluw_mnemonic_32only : pwaluwfunct4_32only <-> string = {
  WADD <-> "wadd",
  WADDA <-> "wadda",
  WADDU <-> "waddu",
  WADDAU <-> "waddau",
  WMUL <-> "wmul",
  WMACC <-> "wmacc",
  WMULU <-> "wmulu",
  WMACCU <-> "wmaccu",
  WSUB <-> "wsub",
  WSUBA <-> "wsuba",
  WSUBU <-> "wsubu",
  WSUBAU <-> "wsubau",
  WMULSU <-> "wmulsu",
  WMACCSU <-> "wmaccsu",
}

mapping clause assembly = PWALUW_32ONLY(funct4, rs1, rs2, rdp)
  <-> pwaluw_mnemonic_32only(funct4) ^ spc() ^ preg_name(rdp) ^ sep() ^ reg_name(rs1) ^ sep() ^ reg_name(rs2)
  when currentlyEnabled(Ext_P) & xlen == 32

// ******************* P WIDENING MULTIPLICATION TWO HALFWORD *******************
union clause instruction = PWMUL2H_32ONLY : (pwmul2hfunct4_32only, regidx, regidx, pregidx)

mapping encdec_pwmul2hfunct4_32only : pwmul2hfunct4_32only <-> bits(4) = {
  PM2WADD_H <-> 0b0000,
  PM2WADDA_H <-> 0b0001,
  PM2WADD_HX <-> 0b0010,
  PM2WADDA_HX <-> 0b0011,
  PM2WADDU_H <-> 0b0100,
  PM2WADDAU_H <-> 0b0101,
  PM2WSUB_H <-> 0b1000,
  PM2WSUBA_H <-> 0b1001,
  PM2WSUB_HX <-> 0b1010,
  PM2WSUBA_HX <-> 0b1011,
  PM2WADDSU_H <-> 0b1100,
  PM2WADDASU_H <-> 0b1101,
}

mapping clause encdec = PWMUL2H_32ONLY(funct4, rs1, rs2, rdp) <->
  0b0 @ encdec_pwmul2hfunct4_32only(funct4) @ 0b11 @ encdec_reg(rs2) @ encdec_reg(rs1) @ 0b010 @ encdec_preg(rdp) @ 0b10011011
  when currentlyEnabled(Ext_P) & xlen == 32

function clause execute (PWMUL2H_32ONLY(funct4, rs1, rs2, rdp)) = {
  assert(xlen == 32);
  let rs1_val = X(rs1);
  let rs2_val = X(rs2);
  let rd_val = X_pair(regidx_of_pregidx(rdp));
  let rs1_halfword_even = rs1_val[15..0];
  let rs2_halfword_even = rs2_val[15..0];
  let rs1_halfword_odd = rs1_val[31..16];
  let rs2_halfword_odd = rs2_val[31..16];
  let result : bits(64) = match funct4 {
    PM2WADD_H => sign_extend(muls(rs1_halfword_odd, rs2_halfword_odd)) + sign_extend(muls(rs1_halfword_even, rs2_halfword_even)),
    PM2WADDA_H => rd_val + sign_extend(muls(rs1_halfword_odd, rs2_halfword_odd)) + sign_extend(muls(rs1_halfword_even, rs2_halfword_even)),
    PM2WADD_HX => sign_extend(muls(rs1_halfword_odd, rs2_halfword_even)) + sign_extend(muls(rs1_halfword_even, rs2_halfword_odd)),
    PM2WADDA_HX => rd_val + sign_extend(muls(rs1_halfword_odd, rs2_halfword_even)) + sign_extend(muls(rs1_halfword_even, rs2_halfword_odd)),
    PM2WADDU_H => zero_extend(mulu(rs1_halfword_odd, rs2_halfword_odd)) + zero_extend(mulu(rs1_halfword_even, rs2_halfword_even)),
    PM2WADDAU_H => rd_val + zero_extend(mulu(rs1_halfword_odd, rs2_halfword_odd)) + zero_extend(mulu(rs1_halfword_even, rs2_halfword_even)),
    PM2WADDSU_H => sign_extend(mulsu(rs1_halfword_odd, rs2_halfword_odd)) + sign_extend(mulsu(rs1_halfword_even, rs2_halfword_even)),
    PM2WADDASU_H => rd_val + sign_extend(mulsu(rs1_halfword_odd, rs2_halfword_odd)) + sign_extend(mulsu(rs1_halfword_even, rs2_halfword_even)),
    PM2WSUB_H => sign_extend(muls(rs1_halfword_odd, rs2_halfword_odd)) - sign_extend(muls(rs1_halfword_even, rs2_halfword_even)),
    PM2WSUBA_H => rd_val + sign_extend(muls(rs1_halfword_odd, rs2_halfword_odd)) - sign_extend(muls(rs1_halfword_even, rs2_halfword_even)),
    PM2WSUB_HX => sign_extend(muls(rs1_halfword_odd, rs2_halfword_even)) - sign_extend(muls(rs1_halfword_even, rs2_halfword_odd)),
    PM2WSUBA_HX => rd_val + sign_extend(muls(rs1_halfword_odd, rs2_halfword_even)) - sign_extend(muls(rs1_halfword_even, rs2_halfword_odd)),
  };
  X_pair(regidx_of_pregidx(rdp)) = result;
  RETIRE_SUCCESS
}

mapping pwmul2h_mnemonic_32only : pwmul2hfunct4_32only <-> string = {
  PM2WADD_H <-> "pm2wadd.h",
  PM2WADDA_H <-> "pm2wadda.h",
  PM2WADD_HX <-> "pm2wadd.hx",
  PM2WADDA_HX <-> "pm2wadda.hx",
  PM2WADDU_H <-> "pm2waddu.h",
  PM2WADDAU_H <-> "pm2waddau.h",
  PM2WSUB_H <-> "pm2wsub.h",
  PM2WSUBA_H <-> "pm2wsuba.h",
  PM2WSUB_HX <-> "pm2wsub.hx",
  PM2WSUBA_HX <-> "pm2wsuba.hx",
  PM2WADDSU_H <-> "pm2waddsu.h",
  PM2WADDASU_H <-> "pm2waddasu.h",
}

mapping clause assembly = PWMUL2H_32ONLY(funct4, rs1, rs2, rdp)
  <-> pwmul2h_mnemonic_32only(funct4) ^ spc() ^ preg_name(rdp) ^ sep() ^ reg_name(rs1) ^ sep() ^ reg_name(rs2)
  when currentlyEnabled(Ext_P) & xlen == 32

// ********************* P WIDENING MULTIPLICATION HALFWORD *********************
union clause instruction = PWMULH_32ONLY : (pwmulhwidth2_32only, regidx, regidx, pregidx)

mapping encdec_pwmulhwidth2_32only : pwmulhwidth2_32only <-> bits(2) = {
  PMQWACC_H <-> 0b00,
  PMQRWACC_H <-> 0b10,
}

mapping clause encdec = PWMULH_32ONLY(width2, rs1, rs2, rdp) <->
  0b0 @ 0b1111 @ encdec_pwmulhwidth2_32only(width2) @ encdec_reg(rs2) @ encdec_reg(rs1) @ 0b010 @ encdec_preg(rdp) @ 0b10011011
  when currentlyEnabled(Ext_P) & xlen == 32

function clause execute (PWMULH_32ONLY(width2, rs1, rs2, rdp)) = {
  assert(xlen == 32);
  let rs1_val = X(rs1);
  let rs2_val = X(rs2);
  let rd_val = X_pair(regidx_of_pregidx(rdp));
  var result : bits(64) = zeros();
  foreach (i from 0 to (sizeof(xlen) - 16) by 16) {
    let rs1_halfword = slice(rs1_val, i, 16);
    let rs2_halfword = slice(rs2_val, i, 16);
    result[(2*i+31)..(2*i)] = match width2 {
      PMQWACC_H => rd_val[(2*i+31)..(2*i)] + sign_extend(mulq(rs1_halfword, rs2_halfword)),
      PMQRWACC_H => rd_val[(2*i+31)..(2*i)] + sign_extend(mulqr(rs1_halfword, rs2_halfword)),
    };
  };
  X_pair(regidx_of_pregidx(rdp)) = result;
  RETIRE_SUCCESS
}

mapping pwmulhwidth2_mnemonic_32only : pwmulhwidth2_32only <-> string = {
  PMQWACC_H <-> "pmqwacc.h",
  PMQRWACC_H <-> "pmqrwacc.h",
}

mapping clause assembly = PWMULH_32ONLY(width2, rs1, rs2, rdp)
  <-> pwmulhwidth2_mnemonic_32only(width2) ^ spc() ^ preg_name(rdp) ^ sep() ^ reg_name(rs1) ^ sep() ^ reg_name(rs2)
  when currentlyEnabled(Ext_P) & xlen == 32

// *********************** P WIDENING MULTIPLICATION WORD ***********************
union clause instruction = PWMULW_32ONLY : (pwmulwwidth2_32only, regidx, regidx, pregidx)

mapping encdec_pwmulwwidth2_32only : pwmulwwidth2_32only <-> bits(2) = {
  MQWACC <-> 0b01,
  MQRWACC <-> 0b11,
}

mapping clause encdec = PWMULW_32ONLY(width2, rs1, rs2, rdp) <->
  0b0 @ 0b1111 @ encdec_pwmulwwidth2_32only(width2) @ encdec_reg(rs2) @ encdec_reg(rs1) @ 0b010 @ encdec_preg(rdp) @ 0b10011011
  when currentlyEnabled(Ext_P) & xlen == 32

function clause execute (PWMULW_32ONLY(width2, rs1, rs2, rdp)) = {
  assert(xlen == 32);
  let rs1_val = X(rs1);
  let rs2_val = X(rs2);
  let rd_val = X_pair(regidx_of_pregidx(rdp));
  let result : bits(64) = match width2 {
    MQWACC => rd_val + sign_extend(mulq(rs1_val, rs2_val)),
    MQRWACC => rd_val + sign_extend(mulqr(rs1_val, rs2_val)),
  };
  X_pair(regidx_of_pregidx(rdp)) = result;
  RETIRE_SUCCESS
}

mapping pwmulwwidth2_mnemonic_32only : pwmulwwidth2_32only <-> string = {
  MQWACC <-> "mqwacc",
  MQRWACC <-> "mqrwacc",
}

mapping clause assembly = PWMULW_32ONLY(width2, rs1, rs2, rdp)
  <-> pwmulwwidth2_mnemonic_32only(width2) ^ spc() ^ preg_name(rdp) ^ sep() ^ reg_name(rs1) ^ sep() ^ reg_name(rs2)
  when currentlyEnabled(Ext_P) & xlen == 32

// ********************* P REDUCTION SUM DOUBLE BYTE SCALAR *********************
union clause instruction = PREDSUMDBSCALAR_32ONLY : (predsumdbscalarfunct3_32only, pregidx, regidx, regidx)

mapping encdec_predsumdbscalarfunct3_32only : predsumdbscalarfunct3_32only <-> bits(3) = {
  PREDSUM_DBS <-> 0b001,
  PREDSUMU_DBS <-> 0b011,
}

mapping clause encdec = PREDSUMDBSCALAR_32ONLY(funct3, rs1p, rs2, rd) <->
  0b0 @ encdec_predsumdbscalarfunct3_32only(funct3) @ 0b1 @ 0b10 @ encdec_reg(rs2) @ encdec_preg(rs1p) @ 0b0100 @ encdec_reg(rd) @ 0b0011011
  when currentlyEnabled(Ext_P) & xlen == 32

function clause execute (PREDSUMDBSCALAR_32ONLY(funct3, rs1p, rs2, rd)) = {
  assert(xlen == 32);
  let rs1_val = X_pair(regidx_of_pregidx(rs1p));
  let rd_val = X(rd);
  var result : xlenbits = X(rs2);
  foreach (i from 0 to (64 - 8) by 8) {
    result = match funct3 {
      PREDSUM_DBS => result + sign_extend(rs1_val[(i+7)..i]),
      PREDSUMU_DBS => result + zero_extend(rs1_val[(i+7)..i])
    };
  };
  X(rd) = result;
  RETIRE_SUCCESS
}

mapping predsumdbscalarfunct3_mnemonic_32only : predsumdbscalarfunct3_32only <-> string = {
  PREDSUM_DBS <-> "predsum.dbs",
  PREDSUMU_DBS <-> "predsumu.dbs"
}

mapping clause assembly = PREDSUMDBSCALAR_32ONLY(funct3, rs1p, rs2, rd)
  <-> predsumdbscalarfunct3_mnemonic_32only(funct3) ^ spc() ^ reg_name(rd) ^ sep() ^ preg_name(rs1p) ^ sep() ^ reg_name(rs2)
  when currentlyEnabled(Ext_P) & xlen == 32

// ******************* P REDUCTION SUM DOUBLE HALFWORD SCALAR *******************
union clause instruction = PREDSUMDHSCALAR_32ONLY : (predsumdhscalarfunct3_32only, pregidx, regidx, regidx)

mapping encdec_predsumdhscalarfunct3_32only : predsumdhscalarfunct3_32only <-> bits(3) = {
  PREDSUM_DHS <-> 0b001,
  PREDSUMU_DHS <-> 0b011,
}

mapping clause encdec = PREDSUMDHSCALAR_32ONLY(funct3, rs1p, rs2, rd) <->
  0b0 @ encdec_predsumdhscalarfunct3_32only(funct3) @ 0b1 @ 0b00 @ encdec_reg(rs2) @ encdec_preg(rs1p) @ 0b0100 @ encdec_reg(rd) @ 0b0011011
  when currentlyEnabled(Ext_P) & xlen == 32

function clause execute (PREDSUMDHSCALAR_32ONLY(funct3, rs1p, rs2, rd)) = {
  assert(xlen == 32);
  let rs1_val = X_pair(regidx_of_pregidx(rs1p));
  let rd_val = X(rd);
  var result : xlenbits = X(rs2);
  foreach (i from 0 to (64 - 16) by 16) {
    let rs1_halfword = rs1_val[(i+15)..i];
    result = match funct3 {
      PREDSUM_DHS => result + sign_extend(rs1_halfword),
      PREDSUMU_DHS => result + zero_extend(rs1_halfword)
    };
  };
  X(rd) = result;
  RETIRE_SUCCESS
}

mapping predsumdhscalarfunct3_mnemonic_32only : predsumdhscalarfunct3_32only <-> string = {
  PREDSUM_DHS <-> "predsum.dhs",
  PREDSUMU_DHS <-> "predsumu.dhs"
}

mapping clause assembly = PREDSUMDHSCALAR_32ONLY(funct3, rs1p, rs2, rd)
  <-> predsumdhscalarfunct3_mnemonic_32only(funct3) ^ spc() ^ reg_name(rd) ^ sep() ^ preg_name(rs1p) ^ sep() ^ reg_name(rs2)
  when currentlyEnabled(Ext_P) & xlen == 32

// ******************** P NARROWING SATURATE IMMEDIATE BYTE *********************
union clause instruction = PNARROWSATIB_32ONLY : (pnarrowsatibfunct3_32only, bits(4), pregidx, regidx)

mapping encdec_pnarrowsatibfunct3_32only : pnarrowsatibfunct3_32only <-> bits(3) = {
  PNSRLI_B <-> 0b000,
  PNCLIPIU_B <-> 0b010,
  PNCLIPRIU_B <-> 0b011,
  PNSRAI_B <-> 0b100,
  PNSRARI_B <-> 0b101,
  PNCLIPI_B <-> 0b110,
  PNCLIPRI_B <-> 0b111,
}

mapping clause encdec = PNARROWSATIB_32ONLY(funct3, imm4, rs1p, rd) <->
  0b0 @ encdec_pnarrowsatibfunct3_32only(funct3) @ 0b0 @ 0b001 @ imm4 @ encdec_preg(rs1p) @ 0b1100 @ encdec_reg(rd) @ 0b0011011
  when currentlyEnabled(Ext_P) & xlen == 32

function clause execute (PNARROWSATIB_32ONLY(funct3, imm4, rs1p, rd)) = {
  assert(xlen == 32);
  let rs1_val = X_pair(regidx_of_pregidx(rs1p));
  let shamt : nat = unsigned(imm4);
  var result : xlenbits = zeros();
  foreach (i from 0 to (sizeof(xlen) - 8) by 8) {
    let rs1_halfword = rs1_val[(2*i+15)..(2*i)];
    result[(i+7)..i] = match funct3 {
      PNSRLI_B => (rs1_halfword >> shamt)[7..0],
      PNCLIPIU_B => nclipu(rs1_halfword, shamt),
      PNCLIPRIU_B => nclipru(rs1_halfword, shamt),
      PNSRAI_B => shift_right_arith(rs1_halfword, shamt)[7..0],
      PNSRARI_B => shift_right_arith_rounding(rs1_halfword, shamt)[7..0],
      PNCLIPI_B => nclips(rs1_halfword, shamt),
      PNCLIPRI_B => ncliprs(rs1_halfword, shamt),
    };
  };
  X(rd) = result;
  RETIRE_SUCCESS
}

mapping pnarrowsatib_mnemonic_32only : pnarrowsatibfunct3_32only <-> string = {
  PNSRLI_B <-> "pnsrli.b",
  PNCLIPIU_B <-> "pnclipiu.b",
  PNCLIPRIU_B <-> "pnclipriu.b",
  PNSRAI_B <-> "pnsrai.b",
  PNSRARI_B <-> "pnsrari.b",
  PNCLIPI_B <-> "pnclipi.b",
  PNCLIPRI_B <-> "pnclipri.b",
}

mapping clause assembly = PNARROWSATIB_32ONLY(funct3, imm4, rs1p, rd)
  <-> pnarrowsatib_mnemonic_32only(funct3) ^ spc() ^ reg_name(rd) ^ sep() ^ preg_name(rs1p) ^ sep() ^ hex_bits_4(imm4)
  when currentlyEnabled(Ext_P) & xlen == 32

// ****************** P NARROWING SATURATE IMMEDIATE HALFWORD *******************
union clause instruction = PNARROWSATIH_32ONLY : (pnarrowsatihfunct3_32only, bits(5), pregidx, regidx)

mapping encdec_pnarrowsatihfunct3_32only : pnarrowsatihfunct3_32only <-> bits(3) = {
  PNSRLI_H <-> 0b000,
  PNCLIPIU_H <-> 0b010,
  PNCLIPRIU_H <-> 0b011,
  PNSRAI_H <-> 0b100,
  PNSRARI_H <-> 0b101,
  PNCLIPI_H <-> 0b110,
  PNCLIPRI_H <-> 0b111,
}

mapping clause encdec = PNARROWSATIH_32ONLY(funct3, imm5, rs1p, rd) <->
  0b0 @ encdec_pnarrowsatihfunct3_32only(funct3) @ 0b0 @ 0b01 @ imm5 @ encdec_preg(rs1p) @ 0b1100 @ encdec_reg(rd) @ 0b0011011
  when currentlyEnabled(Ext_P) & xlen == 32

function clause execute (PNARROWSATIH_32ONLY(funct3, imm5, rs1p, rd)) = {
  assert(xlen == 32);
  let rs1_val = X_pair(regidx_of_pregidx(rs1p));
  let shamt : nat = unsigned(imm5);
  var result : xlenbits = zeros();
  foreach (i from 0 to (sizeof(xlen) - 16) by 16) {
    let rs1_word = rs1_val[(2*i+31)..(2*i)];
    result[(i+15)..i] = match funct3 {
      PNSRLI_H => (rs1_word >> shamt)[15..0],
      PNCLIPIU_H => nclipu(rs1_word, shamt),
      PNCLIPRIU_H => nclipru(rs1_word, shamt),
      PNSRAI_H => shift_right_arith(rs1_word, shamt)[15..0],
      PNSRARI_H => shift_right_arith_rounding(rs1_word, shamt)[15..0],
      PNCLIPI_H => nclips(rs1_word, shamt),
      PNCLIPRI_H => ncliprs(rs1_word, shamt),
    };
  };
  X(rd) = result;
  RETIRE_SUCCESS
}

mapping pnarrowsatih_mnemonic_32only : pnarrowsatihfunct3_32only <-> string = {
  PNSRLI_H <-> "pnsrli.h",
  PNCLIPIU_H <-> "pnclipiu.h",
  PNCLIPRIU_H <-> "pnclipriu.h",
  PNSRAI_H <-> "pnsrai.h",
  PNSRARI_H <-> "pnsrari.h",
  PNCLIPI_H <-> "pnclipi.h",
  PNCLIPRI_H <-> "pnclipri.h",
}

mapping clause assembly = PNARROWSATIH_32ONLY(funct3, imm5, rs1p, rd)
  <-> pnarrowsatih_mnemonic_32only(funct3) ^ spc() ^ reg_name(rd) ^ sep() ^ preg_name(rs1p) ^ sep() ^ hex_bits_5(imm5)
  when currentlyEnabled(Ext_P) & xlen == 32

// ******************** P NARROWING SATURATE IMMEDIATE WORD *********************
union clause instruction = PNARROWSATIW_32ONLY : (pnarrowsatiwfunct3_32only, bits(6), pregidx, regidx)

mapping encdec_pnarrowsatiwfunct3_32only : pnarrowsatiwfunct3_32only <-> bits(3) = {
  NSRLI <-> 0b000,
  NCLIPIU <-> 0b010,
  NCLIPRIU <-> 0b011,
  NSRAI <-> 0b100,
  NSRARI <-> 0b101,
  NCLIPI <-> 0b110,
  NCLIPRI <-> 0b111,
}

mapping clause encdec = PNARROWSATIW_32ONLY(funct3, imm6, rs1p, rd) <->
  0b0 @ encdec_pnarrowsatiwfunct3_32only(funct3) @ 0b0 @ 0b1 @ imm6 @ encdec_preg(rs1p) @ 0b1100 @ encdec_reg(rd) @ 0b0011011
  when currentlyEnabled(Ext_P) & xlen == 32

function clause execute (PNARROWSATIW_32ONLY(funct3, imm6, rs1p, rd)) = {
  assert(xlen == 32);
  let rs1_val = X_pair(regidx_of_pregidx(rs1p));
  let shamt : nat = unsigned(imm6);
  let result : xlenbits = match funct3 {
    NSRLI => (rs1_val >> shamt)[31..0],
    NCLIPIU => nclipu(rs1_val, shamt),
    NCLIPRIU => nclipru(rs1_val, shamt),
    NSRAI => shift_right_arith(rs1_val, shamt)[31..0],
    NSRARI => shift_right_arith_rounding(rs1_val, shamt)[31..0],
    NCLIPI => nclips(rs1_val, shamt),
    NCLIPRI => ncliprs(rs1_val, shamt),
  };
  X(rd) = result;
  RETIRE_SUCCESS
}

mapping pnarrowsatiw_mnemonic_32only : pnarrowsatiwfunct3_32only <-> string = {
  NSRLI <-> "nsrli",
  NCLIPIU <-> "nclipiu",
  NCLIPRIU <-> "nclipriu",
  NSRAI <-> "nsrai",
  NSRARI <-> "nsrari",
  NCLIPI <-> "nclipi",
  NCLIPRI <-> "nclipri",
}

mapping clause assembly = PNARROWSATIW_32ONLY(funct3, imm6, rs1p, rd)
  <-> pnarrowsatiw_mnemonic_32only(funct3) ^ spc() ^ reg_name(rd) ^ sep() ^ preg_name(rs1p) ^ sep() ^ hex_bits_6(imm6)
  when currentlyEnabled(Ext_P) & xlen == 32

// ********************** P NARROWING SATURATE BYTE SCALAR **********************
union clause instruction = PNARROWSATBSCALAR_32ONLY : (pnarrowsatbscalarfunct3_32only, pregidx, regidx, regidx)

mapping encdec_pnarrowsatbscalarfunct3_32only : pnarrowsatbscalarfunct3_32only <-> bits(3) = {
  PNSRL_BS <-> 0b000,
  PNCLIPU_BS <-> 0b010,
  PNCLIPRU_BS <-> 0b011,
  PNSRA_BS <-> 0b100,
  PNSRAR_BS <-> 0b101,
  PNCLIP_BS <-> 0b110,
  PNCLIPR_BS <-> 0b111,
}

mapping clause encdec = PNARROWSATBSCALAR_32ONLY(funct3, rs1p, rs2, rd) <->
  0b0 @ encdec_pnarrowsatbscalarfunct3_32only(funct3) @ 0b1 @ 0b00 @ encdec_reg(rs2) @ encdec_preg(rs1p) @ 0b1100 @ encdec_reg(rd) @ 0b0011011
  when currentlyEnabled(Ext_P) & xlen == 32

function clause execute (PNARROWSATBSCALAR_32ONLY(funct3, rs1p, rs2, rd)) = {
  assert(xlen == 32);
  let rs1_val = X_pair(regidx_of_pregidx(rs1p));
  let shamt : nat = unsigned(X(rs2)[4..0]);
  var result : xlenbits = zeros();
  foreach (i from 0 to (sizeof(xlen) - 8) by 8) {
    let rs1_halfword = rs1_val[(2*i+15)..(2*i)];
    result[(i+7)..i] = match funct3 {
      PNSRL_BS => (rs1_halfword >> shamt)[7..0],
      PNCLIPU_BS => nclipu(rs1_halfword, shamt),
      PNCLIPRU_BS => nclipru(rs1_halfword, shamt),
      PNSRA_BS => shift_right_arith(rs1_halfword, shamt)[7..0],
      PNSRAR_BS => shift_right_arith_rounding(rs1_halfword, shamt)[7..0],
      PNCLIP_BS => nclips(rs1_halfword, shamt),
      PNCLIPR_BS => ncliprs(rs1_halfword, shamt),
    };
  };
  X(rd) = result;
  RETIRE_SUCCESS
}

mapping pnarrowsatbscalarfunct3_mnemonic_32only : pnarrowsatbscalarfunct3_32only <-> string = {
  PNSRL_BS <-> "pnsrl.bs",
  PNCLIPU_BS <-> "pnclipu.bs",
  PNCLIPRU_BS <-> "pnclipru.bs",
  PNSRA_BS <-> "pnsra.bs",
  PNSRAR_BS <-> "pnsrar.bs",
  PNCLIP_BS <-> "pnclip.bs",
  PNCLIPR_BS <-> "pnclipr.bs",
}

mapping clause assembly = PNARROWSATBSCALAR_32ONLY(funct3, rs1p, rs2, rd)
  <-> pnarrowsatbscalarfunct3_mnemonic_32only(funct3) ^ spc() ^ reg_name(rd) ^ sep() ^ preg_name(rs1p) ^ sep() ^ reg_name(rs2)
  when currentlyEnabled(Ext_P) & xlen == 32

// ******************** P NARROWING SATURATE HALFWORD SCALAR ********************
union clause instruction = PNARROWSATHSCALAR_32ONLY : (pnarrowsathscalarfunct3_32only, pregidx, regidx, regidx)

mapping encdec_pnarrowsathscalarfunct3_32only : pnarrowsathscalarfunct3_32only <-> bits(3) = {
  PNSRL_HS <-> 0b000,
  PNCLIPU_HS <-> 0b010,
  PNCLIPRU_HS <-> 0b011,
  PNSRA_HS <-> 0b100,
  PNSRAR_HS <-> 0b101,
  PNCLIP_HS <-> 0b110,
  PNCLIPR_HS <-> 0b111,
}

mapping clause encdec = PNARROWSATHSCALAR_32ONLY(funct3, rs1p, rs2, rd) <->
  0b0 @ encdec_pnarrowsathscalarfunct3_32only(funct3) @ 0b1 @ 0b01 @ encdec_reg(rs2) @ encdec_preg(rs1p) @ 0b1100 @ encdec_reg(rd) @ 0b0011011
  when currentlyEnabled(Ext_P) & xlen == 32

function clause execute (PNARROWSATHSCALAR_32ONLY(funct3, rs1p, rs2, rd)) = {
  assert(xlen == 32);
  let rs1_val = X_pair(regidx_of_pregidx(rs1p));
  let shamt : nat = unsigned(X(rs2)[4..0]);
  var result : xlenbits = zeros();
  foreach (i from 0 to (sizeof(xlen) - 16) by 16) {
    let rs1_word = rs1_val[(2*i+31)..(2*i)];
    result[(i+15)..i] = match funct3 {
      PNSRL_HS => (rs1_word >> shamt)[15..0],
      PNCLIPU_HS => nclipu(rs1_word, shamt),
      PNCLIPRU_HS => nclipru(rs1_word, shamt),
      PNSRA_HS => shift_right_arith(rs1_word, shamt)[15..0],
      PNSRAR_HS => shift_right_arith_rounding(rs1_word, shamt)[15..0],
      PNCLIP_HS => nclips(rs1_word, shamt),
      PNCLIPR_HS => ncliprs(rs1_word, shamt),
    };
  };
  X(rd) = result;
  RETIRE_SUCCESS
}

mapping pnarrowsathscalarfunct3_mnemonic_32only : pnarrowsathscalarfunct3_32only <-> string = {
  PNSRL_HS <-> "pnsrl.hs",
  PNCLIPU_HS <-> "pnclipu.hs",
  PNCLIPRU_HS <-> "pnclipru.hs",
  PNSRA_HS <-> "pnsra.hs",
  PNSRAR_HS <-> "pnsrar.hs",
  PNCLIP_HS <-> "pnclip.hs",
  PNCLIPR_HS <-> "pnclipr.hs",
}

mapping clause assembly = PNARROWSATHSCALAR_32ONLY(funct3, rs1p, rs2, rd)
  <-> pnarrowsathscalarfunct3_mnemonic_32only(funct3) ^ spc() ^ reg_name(rd) ^ sep() ^ preg_name(rs1p) ^ sep() ^ reg_name(rs2)
  when currentlyEnabled(Ext_P) & xlen == 32

// ********************** P NARROWING SATURATE WORD SCALAR **********************
union clause instruction = PNARROWSATWSCALAR_32ONLY : (pnarrowsatwscalarfunct3_32only, pregidx, regidx, regidx)

mapping encdec_pnarrowsatwscalarfunct3_32only : pnarrowsatwscalarfunct3_32only <-> bits(3) = {
  NSRL <-> 0b000,
  NCLIPU <-> 0b010,
  NCLIPRU <-> 0b011,
  NSRA <-> 0b100,
  NSRAR <-> 0b101,
  NCLIP <-> 0b110,
  NCLIPR <-> 0b111,
}

mapping clause encdec = PNARROWSATWSCALAR_32ONLY(funct3, rs1p, rs2, rd) <->
  0b0 @ encdec_pnarrowsatwscalarfunct3_32only(funct3) @ 0b1 @ 0b11 @ encdec_reg(rs2) @ encdec_preg(rs1p) @ 0b1100 @ encdec_reg(rd) @ 0b0011011
  when currentlyEnabled(Ext_P) & xlen == 32

function clause execute (PNARROWSATWSCALAR_32ONLY(funct3, rs1p, rs2, rd)) = {
  assert(xlen == 32);
  let rs1_val = X_pair(regidx_of_pregidx(rs1p));
  let shamt : nat = unsigned(X(rs2)[5..0]);
  let result : xlenbits = match funct3 {
    NSRL => (rs1_val >> shamt)[31..0],
    NCLIPU => nclipu(rs1_val, shamt),
    NCLIPRU => nclipru(rs1_val, shamt),
    NSRA => shift_right_arith(rs1_val, shamt)[31..0],
    NSRAR => shift_right_arith_rounding(rs1_val, shamt)[31..0],
    NCLIP => nclips(rs1_val, shamt),
    NCLIPR => ncliprs(rs1_val, shamt),
  };
  X(rd) = result;
  RETIRE_SUCCESS
}

mapping pnarrowsatwscalarfunct3_mnemonic_32only : pnarrowsatwscalarfunct3_32only <-> string = {
  NSRL <-> "nsrl",
  NCLIPU <-> "nclipu",
  NCLIPRU <-> "nclipru",
  NSRA <-> "nsra",
  NSRAR <-> "nsrar",
  NCLIP <-> "nclip",
  NCLIPR <-> "nclipr",
}

mapping clause assembly = PNARROWSATWSCALAR_32ONLY(funct3, rs1p, rs2, rd)
  <-> pnarrowsatwscalarfunct3_mnemonic_32only(funct3) ^ spc() ^ reg_name(rd) ^ sep() ^ preg_name(rs1p) ^ sep() ^ reg_name(rs2)
  when currentlyEnabled(Ext_P) & xlen == 32

// *********************** P SHIFT IMMEDIATE DOUBLE BYTE ************************
union clause instruction = PSHIFTIDB_32ONLY : (pshiftidbfunct3_32only, bits(3), pregidx, pregidx)

mapping encdec_pshiftidbfunct3_32only : pshiftidbfunct3_32only <-> bits(3) = {
  PSLLI_DB <-> 0b000,
}

mapping clause encdec = PSHIFTIDB_32ONLY(funct3, imm3, rs1p, rdp)
  <-> 0b0 @ encdec_pshiftidbfunct3_32only(funct3) @ 0b0 @ 0b0001 @ imm3 @ encdec_preg(rs1p) @ 0b0110 @ encdec_preg(rdp) @ 0b00011011
  when currentlyEnabled(Ext_P) & xlen == 32

function clause execute (PSHIFTIDB_32ONLY(funct3, imm3, rs1p, rdp)) = {
  assert(xlen == 32);
  let rs1_val = X_pair(regidx_of_pregidx(rs1p));
  let shamt : nat = unsigned(imm3);
  var result : bits(64) = zeros();
  foreach (i from 0 to (64 - 8) by 8) {
    let rs1_halfword = slice(rs1_val, i, 8);
    result[(i+7)..i] = match funct3 {
      PSLLI_DB => rs1_halfword << shamt,
    };
  };
  X_pair(regidx_of_pregidx(rdp)) = result;
  RETIRE_SUCCESS
}

mapping pshiftidb_mnemonic_32only : pshiftidbfunct3_32only <-> string = {
  PSLLI_DB <-> "pslli.db",
}

mapping clause assembly = PSHIFTIDB_32ONLY(funct3, imm3, rs1p, rdp)
  <-> pshiftidb_mnemonic_32only(funct3) ^ spc() ^ preg_name(rdp) ^ sep() ^ preg_name(rs1p) ^ sep() ^ hex_bits_3(imm3)
  when currentlyEnabled(Ext_P) & xlen == 32

// ********************* P SHIFT IMMEDIATE DOUBLE HALFWORD **********************
union clause instruction = PSHIFTIDH_32ONLY : (pshiftidhfunct3_32only, bits(4), pregidx, pregidx)

mapping encdec_pshiftidhfunct3_32only : pshiftidhfunct3_32only <-> bits(3) = {
  PSLLI_DH <-> 0b000,
  PSSLAI_DH <-> 0b101,
}

mapping clause encdec = PSHIFTIDH_32ONLY(funct3, imm4, rs1p, rdp)
  <-> 0b0 @ encdec_pshiftidhfunct3_32only(funct3) @ 0b0 @ 0b001 @ imm4 @ encdec_preg(rs1p) @ 0b0110 @ encdec_preg(rdp) @ 0b00011011
  when currentlyEnabled(Ext_P) & xlen == 32

function clause execute (PSHIFTIDH_32ONLY(funct3, imm4, rs1p, rdp)) = {
  assert(xlen == 32);
  let rs1_val = X_pair(regidx_of_pregidx(rs1p));
  let shamt : nat = unsigned(imm4);
  var result : bits(64) = zeros();
  foreach (i from 0 to (64 - 16) by 16) {
    let rs1_halfword = slice(rs1_val, i, 16);
    result[(i+15)..i] = match funct3 {
      PSLLI_DH => rs1_halfword << shamt,
      PSSLAI_DH => sat_shift_left_arith(rs1_halfword, shamt),
    };
  };
  X_pair(regidx_of_pregidx(rdp)) = result;
  RETIRE_SUCCESS
}

mapping pshiftidh_mnemonic_32only : pshiftidhfunct3_32only <-> string = {
  PSLLI_DH <-> "pslli.dh",
  PSSLAI_DH <-> "psslai.dh",
}

mapping clause assembly = PSHIFTIDH_32ONLY(funct3, imm4, rs1p, rdp)
  <-> pshiftidh_mnemonic_32only(funct3) ^ spc() ^ preg_name(rdp) ^ sep() ^ preg_name(rs1p) ^ sep() ^ hex_bits_4(imm4)
  when currentlyEnabled(Ext_P) & xlen == 32

// *********************** P SHIFT IMMEDIATE DOUBLE WORD ************************
union clause instruction = PSHIFTIDW_32ONLY : (pshiftidwfunct3_32only, bits(5), pregidx, pregidx)

mapping encdec_pshiftidwfunct3_32only : pshiftidwfunct3_32only <-> bits(3) = {
  PSLLI_DW <-> 0b000,
  PSSLAI_DW <-> 0b101,
}

mapping clause encdec = PSHIFTIDW_32ONLY(funct3, imm5, rs1p, rdp)
  <-> 0b0 @ encdec_pshiftidwfunct3_32only(funct3) @ 0b0 @ 0b01 @ imm5 @ encdec_preg(rs1p) @ 0b0110 @ encdec_preg(rdp) @ 0b00011011
  when currentlyEnabled(Ext_P) & xlen == 32

function clause execute (PSHIFTIDW_32ONLY(funct3, imm5, rs1p, rdp)) = {
  assert(xlen == 32);
  let rs1_val = X_pair(regidx_of_pregidx(rs1p));
  let shamt : nat = unsigned(imm5);
  var result : bits(64) = zeros();
  foreach (i from 0 to (64 - 32) by 32) {
    let rs1_halfword = slice(rs1_val, i, 32);
    result[(i+31)..i] = match funct3 {
      PSLLI_DW => rs1_halfword << shamt,
      PSSLAI_DW => sat_shift_left_arith(rs1_halfword, shamt),
    };
  };
  X_pair(regidx_of_pregidx(rdp)) = result;
  RETIRE_SUCCESS
}

mapping pshiftidw_mnemonic_32only : pshiftidwfunct3_32only <-> string = {
  PSLLI_DW <-> "pslli.dw",
  PSSLAI_DW <-> "psslai.dw",
}

mapping clause assembly = PSHIFTIDW_32ONLY(funct3, imm5, rs1p, rdp)
  <-> pshiftidw_mnemonic_32only(funct3) ^ spc() ^ preg_name(rdp) ^ sep() ^ preg_name(rs1p) ^ sep() ^ hex_bits_5(imm5)
  when currentlyEnabled(Ext_P) & xlen == 32

// ********************* P SIGNED EXTENSION DOUBLE HALFWORD *********************
union clause instruction = PSEXT_DH_B_32ONLY : (pregidx, pregidx)

mapping clause encdec = PSEXT_DH_B_32ONLY(rs1p, rdp) <->
  0b01100 @ 0b00 @ 0b00100 @ encdec_preg(rs1p) @ 0b0110 @ encdec_preg(rdp) @ 0b00011011
  when currentlyEnabled(Ext_P) & xlen == 32

function clause execute (PSEXT_DH_B_32ONLY(rs1p, rdp)) = {
  assert(xlen == 32);
  let rs1_val = X_pair(regidx_of_pregidx(rs1p));
  var result : bits(64) = zeros();
  foreach (i from 0 to (64 - 16) by 16) {
    result[(i+15)..i] = sign_extend(rs1_val[(i+7)..i]);
  };
  X_pair(regidx_of_pregidx(rdp)) = result;
  RETIRE_SUCCESS
}

mapping clause assembly = PSEXT_DH_B_32ONLY(rs1p, rdp)
  <-> "psext.dh.b" ^ spc() ^ preg_name(rdp) ^ sep() ^ preg_name(rs1p)
  when currentlyEnabled(Ext_P) & xlen == 32

// ********************* P SIGNED EXTENSION DOUBLE WORD *************************
union clause instruction = PSEXT_DW_B_32ONLY : (pregidx, pregidx)

mapping clause encdec = PSEXT_DW_B_32ONLY(rs1p, rdp) <->
  0b01100 @ 0b01 @ 0b00100 @ encdec_preg(rs1p) @ 0b0110 @ encdec_preg(rdp) @ 0b00011011
  when currentlyEnabled(Ext_P) & xlen == 32

function clause execute (PSEXT_DW_B_32ONLY(rs1p, rdp)) = {
  assert(xlen == 32);
  let rs1_val = X_pair(regidx_of_pregidx(rs1p));
  var result : bits(64) = zeros();
  foreach (i from 0 to (64 - 32) by 32) {
    result[(i+31)..i] = sign_extend(rs1_val[(i+7)..i]);
  };
  X_pair(regidx_of_pregidx(rdp)) = result;
  RETIRE_SUCCESS
}

mapping clause assembly = PSEXT_DW_B_32ONLY(rs1p, rdp)
  <-> "psext.dw.b" ^ spc() ^ preg_name(rdp) ^ sep() ^ preg_name(rs1p)
  when currentlyEnabled(Ext_P) & xlen == 32

union clause instruction = PSEXT_DW_H_32ONLY : (pregidx, pregidx)

mapping clause encdec = PSEXT_DW_H_32ONLY(rs1p, rdp) <->
  0b01100 @ 0b01 @ 0b00101 @ encdec_preg(rs1p) @ 0b0110 @ encdec_preg(rdp) @ 0b00011011
  when currentlyEnabled(Ext_P) & xlen == 32

function clause execute (PSEXT_DW_H_32ONLY(rs1p, rdp)) = {
  assert(xlen == 32);
  let rs1_val = X_pair(regidx_of_pregidx(rs1p));
  var result : bits(64) = zeros();
  foreach (i from 0 to (64 - 32) by 32) {
    result[(i+31)..i] = sign_extend(rs1_val[(i+15)..i]);
  };
  X_pair(regidx_of_pregidx(rdp)) = result;
  RETIRE_SUCCESS
}

mapping clause assembly = PSEXT_DW_H_32ONLY(rs1p, rdp)
  <-> "psext.dw.h" ^ spc() ^ preg_name(rdp) ^ sep() ^ preg_name(rs1p)
  when currentlyEnabled(Ext_P) & xlen == 32

// ************************** P SATURATING ABS DOUBLE ***************************
union clause instruction = PSABSD_32ONLY : (psabsdwidth2_32only, pregidx, pregidx)

mapping encdec_psabsdwidth2_32only : psabsdwidth2_32only <-> bits(2) = {
  PSABS_DB <-> 0b10,
  PSABS_DH <-> 0b00,
}

mapping clause encdec = PSABSD_32ONLY(width2, rs1p, rdp)
  <-> 0b01100 @ encdec_psabsdwidth2_32only(width2) @ 0b00111 @ encdec_preg(rs1p) @ 0b0110 @ encdec_preg(rdp) @ 0b00011011
  when currentlyEnabled(Ext_P) & xlen == 32

function clause execute (PSABSD_32ONLY(width2, rs1p, rdp)) = {
  assert(xlen == 32);
  let rs1_val = X_pair(regidx_of_pregidx(rs1p));
  var result : bits(64) = zeros();
  match width2 {
    PSABS_DB => {
      foreach (i from 0 to (64 - 8) by 8) {
        let rs1_byte = slice(rs1_val, i, 8);
        result[(i+7)..i] = sabs(rs1_byte)
      };
    },
    PSABS_DH => {
      foreach (i from 0 to (64 - 16) by 16) {
        let rs1_halfword = slice(rs1_val, i, 16);
        result[(i+15)..i] = sabs(rs1_halfword)
      };
    },
  };
  X_pair(regidx_of_pregidx(rdp)) = result;
  RETIRE_SUCCESS
}

mapping psabsd_mnemonic_32only : psabsdwidth2_32only <-> string = {
  PSABS_DB <-> "psabs.db",
  PSABS_DH <-> "psabs.dh",
}

mapping clause assembly = PSABSD_32ONLY(width2, rs1p, rdp)
  <-> psabsd_mnemonic_32only(width2) ^ spc() ^ preg_name(rdp) ^ sep() ^ preg_name(rs1p)
  when currentlyEnabled(Ext_P) & xlen == 32

// ************************** P ALU DOUBLE BYTE SCALAR **************************
union clause instruction = PALUDBSCALAR_32ONLY : (paludbscalarfunct3_32only, pregidx, regidx, pregidx)

mapping encdec_paludbscalarfunct3_32only : paludbscalarfunct3_32only <-> bits(3) = {
  PSLL_DBS <-> 0b000,
  PADD_DBS <-> 0b001,
}

mapping clause encdec = PALUDBSCALAR_32ONLY(funct3, rs1p, rs2, rdp) <->
  0b0 @ encdec_paludbscalarfunct3_32only(funct3) @ 0b1 @ 0b10 @ encdec_reg(rs2) @ encdec_preg(rs1p) @ 0b0110 @ encdec_preg(rdp) @ 0b00011011
  when currentlyEnabled(Ext_P) & xlen == 32

function clause execute (PALUDBSCALAR_32ONLY(funct3, rs1p, rs2, rdp)) = {
  assert(xlen == 32);
  let rs1_val = X_pair(regidx_of_pregidx(rs1p));
  let rs2_val = X(rs2);
  var result : bits(64) = zeros();
  foreach (i from 0 to (64 - 8) by 8) {
    let rs1_halfword = rs1_val[(i+7)..i];
    result[(i+7)..i] = match funct3 {
      PSLL_DBS => rs1_halfword << rs2_val[4..0],
      PADD_DBS => rs1_halfword + rs2_val[7..0],
    };
  };
  X_pair(regidx_of_pregidx(rdp)) = result;
  RETIRE_SUCCESS
}

mapping paludbscalar_mnemonic_32only : paludbscalarfunct3_32only <-> string = {
  PSLL_DBS <-> "psll.dbs",
  PADD_DBS <-> "padd.dbs",
}

mapping clause assembly = PALUDBSCALAR_32ONLY(funct3, rs1p, rs2, rdp)
  <-> paludbscalar_mnemonic_32only(funct3) ^ spc() ^ preg_name(rdp) ^ sep() ^ preg_name(rs1p) ^ sep() ^ reg_name(rs2)
  when currentlyEnabled(Ext_P) & xlen == 32

// ************************ P ALU DOUBLE HALFWORD SCALAR ************************
union clause instruction = PALUDHSCALAR_32ONLY : (paludhscalarfunct3_32only, pregidx, regidx, pregidx)

mapping encdec_paludhscalarfunct3_32only : paludhscalarfunct3_32only <-> bits(3) = {
  PSLL_DHS <-> 0b000,
  PADD_DHS <-> 0b001,
  PSSHL_DHS <-> 0b010,
  PSSHLR_DHS <-> 0b011,
  PSSHA_DHS <-> 0b110,
  PSSHAR_DHS <-> 0b111,
}

mapping clause encdec = PALUDHSCALAR_32ONLY(funct3, rs1p, rs2, rdp) <->
  0b0 @ encdec_paludhscalarfunct3_32only(funct3) @ 0b1 @ 0b00 @ encdec_reg(rs2) @ encdec_preg(rs1p) @ 0b0110 @ encdec_preg(rdp) @ 0b00011011
  when currentlyEnabled(Ext_P) & xlen == 32

function clause execute (PALUDHSCALAR_32ONLY(funct3, rs1p, rs2, rdp)) = {
  assert(xlen == 32);
  let rs1_val = X_pair(regidx_of_pregidx(rs1p));
  let rs2_val = X(rs2);
  var result : bits(64) = zeros();
  foreach (i from 0 to (64 - 16) by 16) {
    let rs1_halfword = rs1_val[(i+15)..i];
    result[(i+15)..i] = match funct3 {
      PSLL_DHS => rs1_halfword << rs2_val[4..0],
      PADD_DHS => rs1_halfword + rs2_val[15..0],
      PSSHL_DHS => sshl(rs1_halfword, signed(rs2_val[7..0])),
      PSSHLR_DHS => sshlr(rs1_halfword, signed(rs2_val[7..0])),
      PSSHA_DHS => ssha(rs1_halfword, signed(rs2_val[7..0])),
      PSSHAR_DHS => sshar(rs1_halfword, signed(rs2_val[7..0])),
    };
  };
  X_pair(regidx_of_pregidx(rdp)) = result;
  RETIRE_SUCCESS
}

mapping paludhscalar_mnemonic_32only : paludhscalarfunct3_32only <-> string = {
  PSLL_DHS <-> "psll.dhs",
  PADD_DHS <-> "padd.dhs",
  PSSHL_DHS <-> "psshl.dhs",
  PSSHLR_DHS <-> "psshlr.dhs",
  PSSHA_DHS <-> "pssha.dhs",
  PSSHAR_DHS <-> "psshar.dhs",
}

mapping clause assembly = PALUDHSCALAR_32ONLY(funct3, rs1p, rs2, rdp)
  <-> paludhscalar_mnemonic_32only(funct3) ^ spc() ^ preg_name(rdp) ^ sep() ^ preg_name(rs1p) ^ sep() ^ reg_name(rs2)
  when currentlyEnabled(Ext_P) & xlen == 32

// ************************** P ALU DOUBLE WORD SCALAR **************************
union clause instruction = PALUDWSCALAR_32ONLY : (paludwscalarfunct3_32only, pregidx, regidx, pregidx)

mapping encdec_paludwscalarfunct3_32only : paludwscalarfunct3_32only <-> bits(3) = {
  PSLL_DWS <-> 0b000,
  PADD_DWS <-> 0b001,
  PSSHL_DWS <-> 0b010,
  PSSHLR_DWS <-> 0b011,
  PSSHA_DWS <-> 0b110,
  PSSHAR_DWS <-> 0b111,
}

mapping clause encdec = PALUDWSCALAR_32ONLY(funct3, rs1p, rs2, rdp) <->
  0b0 @ encdec_paludwscalarfunct3_32only(funct3) @ 0b1 @ 0b01 @ encdec_reg(rs2) @ encdec_preg(rs1p) @ 0b0110 @ encdec_preg(rdp) @ 0b00011011
  when currentlyEnabled(Ext_P) & xlen == 32

function clause execute (PALUDWSCALAR_32ONLY(funct3, rs1p, rs2, rdp)) = {
  assert(xlen == 32);
  let rs1_val = X_pair(regidx_of_pregidx(rs1p));
  let rs2_val = X(rs2);
  var result : bits(64) = zeros();
  foreach (i from 0 to (64 - 32) by 32) {
    let rs1_word = rs1_val[(i+31)..i];
    result[(i+31)..i] = match funct3 {
      PSLL_DWS => rs1_word << rs2_val[4..0],
      PADD_DWS => rs1_word + rs2_val,
      PSSHL_DWS => sshl(rs1_word, signed(rs2_val[7..0])),
      PSSHLR_DWS => sshlr(rs1_word, signed(rs2_val[7..0])),
      PSSHA_DWS => ssha(rs1_word, signed(rs2_val[7..0])),
      PSSHAR_DWS => sshar(rs1_word, signed(rs2_val[7..0])),
    };
  };
  X_pair(regidx_of_pregidx(rdp)) = result;
  RETIRE_SUCCESS
}

mapping paludwscalar_mnemonic_32only : paludwscalarfunct3_32only <-> string = {
  PSLL_DWS <-> "psll.dws",
  PADD_DWS <-> "padd.dws",
  PSSHL_DWS <-> "psshl.dws",
  PSSHLR_DWS <-> "psshlr.dws",
  PSSHA_DWS <-> "pssha.dws",
  PSSHAR_DWS <-> "psshar.dws",
}

mapping clause assembly = PALUDWSCALAR_32ONLY(funct3, rs1p, rs2, rdp)
  <-> paludwscalar_mnemonic_32only(funct3) ^ spc() ^ preg_name(rdp) ^ sep() ^ preg_name(rs1p) ^ sep() ^ reg_name(rs2)
  when currentlyEnabled(Ext_P) & xlen == 32

// ******************* P SHIFT SATURATE IMMEDIATE DOUBLE BYTE *******************
union clause instruction = PSHIFTSATIDB_32ONLY : (pshiftsatidbfunct3_32only, bits(3), pregidx, pregidx)

mapping encdec_pshiftsatidbfunct3_32only : pshiftsatidbfunct3_32only <-> bits(3) = {
  PSRLI_DB <-> 0b000,
  PSRAI_DB <-> 0b100,
}

mapping clause encdec = PSHIFTSATIDB_32ONLY(funct3, imm3, rs1p, rdp)
  <-> 0b0 @ encdec_pshiftsatidbfunct3_32only(funct3) @ 0b0 @ 0b0001 @ imm3 @ encdec_preg(rs1p) @ 0b1110 @ encdec_preg(rdp) @ 0b00011011
  when currentlyEnabled(Ext_P) & xlen == 32

function clause execute (PSHIFTSATIDB_32ONLY(funct3, imm3, rs1p, rdp)) = {
  assert(xlen == 32);
  let rs1_val = X_pair(regidx_of_pregidx(rs1p));
  let shamt : nat = unsigned(imm3);
  var result : bits(64) = zeros();
  foreach (i from 0 to (64 - 8) by 8) {
    let rs1_byte = slice(rs1_val, i, 8);
    result[(i+7)..i] = match funct3 {
      PSRLI_DB => rs1_byte >> shamt,
      PSRAI_DB => shift_right_arith(rs1_byte, shamt),
    };
  };
  X_pair(regidx_of_pregidx(rdp)) = result;
  RETIRE_SUCCESS
}

mapping pshiftsatidb_mnemonic_32only : pshiftsatidbfunct3_32only <-> string = {
  PSRLI_DB <-> "psrli.db",
  PSRAI_DB <-> "psrai.db",
}

mapping clause assembly = PSHIFTSATIDB_32ONLY(funct3, imm3, rs1p, rdp)
  <-> pshiftsatidb_mnemonic_32only(funct3) ^ spc() ^ preg_name(rdp) ^ sep() ^ preg_name(rs1p) ^ sep() ^ hex_bits_3(imm3)
  when currentlyEnabled(Ext_P) & xlen == 32

// ***************** P SHIFT SATURATE IMMEDIATE DOUBLE HALFWORD *****************
union clause instruction = PSHIFTSATIDH_32ONLY : (pshiftsatidhfunct3_32only, bits(4), pregidx, pregidx)

mapping encdec_pshiftsatidhfunct3_32only : pshiftsatidhfunct3_32only <-> bits(3) = {
  PSRLI_DH <-> 0b000,
  PUSATI_DH <-> 0b010,
  PSRAI_DH <-> 0b100,
  PSRARI_DH <-> 0b101,
  PSATI_DH <-> 0b110,
}

mapping clause encdec = PSHIFTSATIDH_32ONLY(funct3, imm4, rs1p, rdp)
  <-> 0b0 @ encdec_pshiftsatidhfunct3_32only(funct3) @ 0b0 @ 0b001 @ imm4 @ encdec_preg(rs1p) @ 0b1110 @ encdec_preg(rdp) @ 0b00011011
  when currentlyEnabled(Ext_P) & xlen == 32

function clause execute (PSHIFTSATIDH_32ONLY(funct3, imm4, rs1p, rdp)) = {
  assert(xlen == 32);
  let rs1_val = X_pair(regidx_of_pregidx(rs1p));
  let shamt : nat = unsigned(imm4);
  var result : bits(64) = zeros();
  foreach (i from 0 to (64 - 16) by 16) {
    let rs1_halfword = slice(rs1_val, i, 16);
    result[(i+15)..i] = match funct3 {
      PSRLI_DH => rs1_halfword >> shamt,
      PUSATI_DH =>
        let maxval : bits(16) = ~(0xFFFF << shamt) in
        if (rs1_halfword <_s 0x0000) then { write_vxsat(0b1); 0x0000 }
        else if (rs1_halfword >_s maxval) then { write_vxsat(0b1); maxval } else rs1_halfword,
      PSRAI_DH => shift_right_arith(rs1_halfword, shamt),
      PSRARI_DH => shift_right_arith_rounding(rs1_halfword, shamt),
      PSATI_DH =>
        let minval : bits(16) = 0xFFFF << shamt in
        let maxval = ~(minval) in
        if (rs1_halfword <_s minval) then { write_vxsat(0b1); minval }
        else if (rs1_halfword >_s maxval) then { write_vxsat(0b1); maxval } else rs1_halfword,
    };
  };
  X_pair(regidx_of_pregidx(rdp)) = result;
  RETIRE_SUCCESS
}

mapping pshiftsatidh_mnemonic_32only : pshiftsatidhfunct3_32only <-> string = {
  PSRLI_DH <-> "psrli.dh",
  PUSATI_DH <-> "pusati.dh",
  PSRAI_DH <-> "psrai.dh",
  PSRARI_DH <-> "psrari.dh",
  PSATI_DH <-> "psati.dh",
}

mapping clause assembly = PSHIFTSATIDH_32ONLY(funct3, imm4, rs1p, rdp)
  <-> pshiftsatidh_mnemonic_32only(funct3) ^ spc() ^ preg_name(rdp) ^ sep() ^ preg_name(rs1p) ^ sep() ^ hex_bits_4(imm4)
  when currentlyEnabled(Ext_P) & xlen == 32

// ******************* P SHIFT SATURATE IMMEDIATE DOUBLE WORD *******************
union clause instruction = PSHIFTSATIDW_32ONLY : (pshiftsatidwfunct3_32only, bits(5), pregidx, pregidx)

mapping encdec_pshiftsatidwfunct3_32only : pshiftsatidwfunct3_32only <-> bits(3) = {
  PSRLI_DW <-> 0b000,
  PUSATI_DW <-> 0b010,
  PSRAI_DW <-> 0b100,
  PSRARI_DW <-> 0b101,
  PSATI_DW <-> 0b110,
}

mapping clause encdec = PSHIFTSATIDW_32ONLY(funct3, imm5, rs1p, rdp)
  <-> 0b0 @ encdec_pshiftsatidwfunct3_32only(funct3) @ 0b0 @ 0b01 @ imm5 @ encdec_preg(rs1p) @ 0b1110 @ encdec_preg(rdp) @ 0b00011011
  when currentlyEnabled(Ext_P) & xlen == 32

function clause execute (PSHIFTSATIDW_32ONLY(funct3, imm5, rs1p, rdp)) = {
  assert(xlen == 32);
  let rs1_val = X_pair(regidx_of_pregidx(rs1p));
  let shamt : nat = unsigned(imm5);
  var result : bits(64) = zeros();
  foreach (i from 0 to (64 - 32) by 32) {
    let rs1_word = slice(rs1_val, i, 32);
    result[(i+31)..i] = match funct3 {
      PSRLI_DW => rs1_word >> shamt,
      PUSATI_DW =>
        let maxval : bits(32) = ~(0xFFFFFFFF << shamt) in
        if (rs1_word <_s 0x00000000) then { write_vxsat(0b1); 0x00000000 }
        else if (rs1_word >_s maxval) then { write_vxsat(0b1); maxval } else rs1_word,
      PSRAI_DW => shift_right_arith(rs1_word, shamt),
      PSRARI_DW => shift_right_arith_rounding(rs1_word, shamt),
      PSATI_DW =>
        let minval : bits(32) = 0xFFFFFFFF << shamt in
        let maxval = ~(minval) in
        if (rs1_word <_s minval) then { write_vxsat(0b1); minval }
        else if (rs1_word >_s maxval) then { write_vxsat(0b1); maxval } else rs1_word,
    };
  };
  X_pair(regidx_of_pregidx(rdp)) = result;
  RETIRE_SUCCESS
}

mapping pshiftsatidw_mnemonic_32only : pshiftsatidwfunct3_32only <-> string = {
  PSRLI_DW <-> "psrli.dw",
  PUSATI_DW <-> "pusati.dw",
  PSRAI_DW <-> "psrai.dw",
  PSRARI_DW <-> "psrari.dw",
  PSATI_DW <-> "psati.dw",
}

mapping clause assembly = PSHIFTSATIDW_32ONLY(funct3, imm5, rs1p, rdp)
  <-> pshiftsatidw_mnemonic_32only(funct3) ^ spc() ^ preg_name(rdp) ^ sep() ^ preg_name(rs1p) ^ sep() ^ hex_bits_5(imm5)
  when currentlyEnabled(Ext_P) & xlen == 32

// ************************* P SHIFT DOUBLE BYTE SCALAR *************************
union clause instruction = PSHIFTDBSCALAR_32ONLY : (pshiftdbscalarfunct3_32only, pregidx, regidx, pregidx)

mapping encdec_pshiftdbscalarfunct3_32only : pshiftdbscalarfunct3_32only <-> bits(3) = {
  PSRL_DBS <-> 0b000,
  PSRA_DBS <-> 0b100,
}

mapping clause encdec = PSHIFTDBSCALAR_32ONLY(funct3, rs1p, rs2, rdp) <->
  0b0 @ encdec_pshiftdbscalarfunct3_32only(funct3) @ 0b1 @ 0b10 @ encdec_reg(rs2) @ encdec_preg(rs1p) @ 0b1110 @ encdec_preg(rdp) @ 0b00011011
  when currentlyEnabled(Ext_P) & xlen == 32

function clause execute (PSHIFTDBSCALAR_32ONLY(funct3, rs1p, rs2, rdp)) = {
  assert(xlen == 32);
  let rs1_val = X_pair(regidx_of_pregidx(rs1p));
  let rs2_val = X(rs2);
  var result : bits(64) = zeros();
  foreach (i from 0 to (64 - 8) by 8) {
    let rs1_byte = slice(rs1_val, i, 8);
    result[(i+7)..i] = match funct3 {
      PSRL_DBS => rs1_byte >> rs2_val[4..0],
      PSRA_DBS => shift_right_arith(rs1_byte, unsigned(rs2_val[4..0])),
    };
  };
  X_pair(regidx_of_pregidx(rdp)) = result;
  RETIRE_SUCCESS
}

mapping pshiftdbscalar_mnemonic_32only : pshiftdbscalarfunct3_32only <-> string = {
  PSRL_DBS <-> "psrl.dbs",
  PSRA_DBS <-> "psra.dbs",
}

mapping clause assembly = PSHIFTDBSCALAR_32ONLY(funct3, rs1p, rs2, rdp)
  <-> pshiftdbscalar_mnemonic_32only(funct3) ^ spc() ^ preg_name(rdp) ^ sep() ^ preg_name(rs1p) ^ sep() ^ reg_name(rs2)
  when currentlyEnabled(Ext_P) & xlen == 32

// *********************** P SHIFT DOUBLE HALFWORD SCALAR ***********************
union clause instruction = PSHIFTDHSCALAR_32ONLY : (pshiftdhscalarfunct3_32only, pregidx, regidx, pregidx)

mapping encdec_pshiftdhscalarfunct3_32only : pshiftdhscalarfunct3_32only <-> bits(3) = {
  PSRL_DHS <-> 0b000,
  PSRA_DHS <-> 0b100,
}

mapping clause encdec = PSHIFTDHSCALAR_32ONLY(funct3, rs1p, rs2, rdp) <->
  0b0 @ encdec_pshiftdhscalarfunct3_32only(funct3) @ 0b1 @ 0b00 @ encdec_reg(rs2) @ encdec_preg(rs1p) @ 0b1110 @ encdec_preg(rdp) @ 0b00011011
  when currentlyEnabled(Ext_P) & xlen == 32

function clause execute (PSHIFTDHSCALAR_32ONLY(funct3, rs1p, rs2, rdp)) = {
  assert(xlen == 32);
  let rs1_val = X_pair(regidx_of_pregidx(rs1p));
  let rs2_val = X(rs2);
  var result : bits(64) = zeros();
  foreach (i from 0 to (64 - 16) by 16) {
    let rs1_halfword = slice(rs1_val, i, 16);
    result[(i+15)..i] = match funct3 {
      PSRL_DHS => rs1_halfword >> rs2_val[4..0],
      PSRA_DHS => shift_right_arith(rs1_halfword, unsigned(rs2_val[4..0])),
    };
  };
  X_pair(regidx_of_pregidx(rdp)) = result;
  RETIRE_SUCCESS
}

mapping pshiftdhscalar_mnemonic_32only : pshiftdhscalarfunct3_32only <-> string = {
  PSRL_DHS <-> "psrl.dhs",
  PSRA_DHS <-> "psra.dhs",
}

mapping clause assembly = PSHIFTDHSCALAR_32ONLY(funct3, rs1p, rs2, rdp)
  <-> pshiftdhscalar_mnemonic_32only(funct3) ^ spc() ^ preg_name(rdp) ^ sep() ^ preg_name(rs1p) ^ sep() ^ reg_name(rs2)
  when currentlyEnabled(Ext_P) & xlen == 32

// ************************* P SHIFT DOUBLE WORD SCALAR *************************
union clause instruction = PSHIFTDWSCALAR_32ONLY : (pshiftdwscalarfunct3_32only, pregidx, regidx, pregidx)

mapping encdec_pshiftdwscalarfunct3_32only : pshiftdwscalarfunct3_32only <-> bits(3) = {
  PSRL_DWS <-> 0b000,
  PSRA_DWS <-> 0b100,
}

mapping clause encdec = PSHIFTDWSCALAR_32ONLY(funct3, rs1p, rs2, rdp) <->
  0b0 @ encdec_pshiftdwscalarfunct3_32only(funct3) @ 0b1 @ 0b01 @ encdec_reg(rs2) @ encdec_preg(rs1p) @ 0b1110 @ encdec_preg(rdp) @ 0b00011011
  when currentlyEnabled(Ext_P) & xlen == 32

function clause execute (PSHIFTDWSCALAR_32ONLY(funct3, rs1p, rs2, rdp)) = {
  assert(xlen == 32);
  let rs1_val = X_pair(regidx_of_pregidx(rs1p));
  let rs2_val = X(rs2);
  var result : bits(64) = zeros();
  foreach (i from 0 to (64 - 32) by 32) {
    let rs1_word = slice(rs1_val, i, 32);
    result[(i+31)..i] = match funct3 {
      PSRL_DWS => rs1_word >> rs2_val[4..0],
      PSRA_DWS => shift_right_arith(rs1_word, unsigned(rs2_val[4..0])),
    };
  };
  X_pair(regidx_of_pregidx(rdp)) = result;
  RETIRE_SUCCESS
}

mapping pshiftdwscalar_mnemonic_32only : pshiftdwscalarfunct3_32only <-> string = {
  PSRL_DWS <-> "psrl.dws",
  PSRA_DWS <-> "psra.dws",
}

mapping clause assembly = PSHIFTDWSCALAR_32ONLY(funct3, rs1p, rs2, rdp)
  <-> pshiftdwscalar_mnemonic_32only(funct3) ^ spc() ^ preg_name(rdp) ^ sep() ^ preg_name(rs1p) ^ sep() ^ reg_name(rs2)
  when currentlyEnabled(Ext_P) & xlen == 32

// ***************************** P ALU DOUBLE BYTE ******************************
union clause instruction = PALUDB_32ONLY : (paludbfunct4_32only, pregidx, pregidx, pregidx)

mapping encdec_paludbfunct4_32only : paludbfunct4_32only <-> bits(4) = {
  PADD_DB <-> 0b0000,
  PSADD_DB <-> 0b0010,
  PAADD_DB <-> 0b0011,
  PSADDU_DB <-> 0b0110,
  PAADDU_DB <-> 0b0111,
  PSUB_DB <-> 0b1000,
  PABD_DB <-> 0b1001,
  PSSUB_DB <-> 0b1010,
  PASUB_DB <-> 0b1011,
  PABDU_DB <-> 0b1101,
  PSSUBU_DB <-> 0b1110,
  PASUBU_DB <-> 0b1111,
}

mapping clause encdec = PALUDB_32ONLY(funct4, rs1p, rs2p, rdp) <->
  0b1 @ encdec_paludbfunct4_32only(funct4) @ 0b10 @ encdec_preg(rs2p) @ 0b0 @ encdec_preg(rs1p) @ 0b0110 @ encdec_preg(rdp) @ 0b00011011
  when currentlyEnabled(Ext_P) & xlen == 32

function clause execute (PALUDB_32ONLY(funct4, rs1p, rs2p, rdp)) = {
  assert(xlen == 32);
  let rs1_val = X_pair(regidx_of_pregidx(rs1p));
  let rs2_val = X_pair(regidx_of_pregidx(rs2p));
  var result : bits(64) = rs2_val;
  foreach (i from 0 to (64 - 8) by 8) {
    let rs1_byte = slice(rs1_val, i, 8);
    let rs2_byte = slice(rs2_val, i, 8);
    result[(i+7)..i] = match funct4 {
      PADD_DB => rs1_byte + rs2_byte,
      PSADD_DB => sadd(rs1_byte, rs2_byte),
      PAADD_DB => aadd(rs1_byte, rs2_byte),
      PSADDU_DB => saddu(rs1_byte, rs2_byte),
      PAADDU_DB => aaddu(rs1_byte, rs2_byte),
      PSUB_DB => rs1_byte - rs2_byte,
      PABD_DB => if rs1_byte <_s rs2_byte then rs2_byte - rs1_byte else rs1_byte - rs2_byte,
      PSSUB_DB => ssub(rs1_byte, rs2_byte),
      PASUB_DB => asub(rs1_byte, rs2_byte),
      PABDU_DB => if rs1_byte <_u rs2_byte then rs2_byte - rs1_byte else rs1_byte - rs2_byte,
      PSSUBU_DB => ssubu(rs1_byte, rs2_byte),
      PASUBU_DB => asubu(rs1_byte, rs2_byte),
    };
  };
  X_pair(regidx_of_pregidx(rdp)) = result;
  RETIRE_SUCCESS
}

mapping paludb_mnemonic_32only : paludbfunct4_32only <-> string = {
  PADD_DB <-> "padd.db",
  PSADD_DB <-> "psadd.db",
  PAADD_DB <-> "paadd.db",
  PSADDU_DB <-> "psaddu.db",
  PAADDU_DB <-> "paaddu.db",
  PSUB_DB <-> "psub.db",
  PABD_DB <-> "pabd.db",
  PSSUB_DB <-> "pssub.db",
  PASUB_DB <-> "pasub.db",
  PABDU_DB <-> "pabdu.db",
  PSSUBU_DB <-> "pssubu.db",
  PASUBU_DB <-> "pasubu.db",
}

mapping clause assembly = PALUDB_32ONLY(funct4, rs1p, rs2p, rdp)
  <-> paludb_mnemonic_32only(funct4) ^ spc() ^ preg_name(rdp) ^ sep() ^ preg_name(rs1p) ^ sep() ^ preg_name(rs2p)
  when currentlyEnabled(Ext_P) & xlen == 32

// *************************** P ALU DOUBLE HALFWORD ****************************
union clause instruction = PALUDH_32ONLY : (paludhfunct4_32only, pregidx, pregidx, pregidx)

mapping encdec_paludhfunct4_32only : paludhfunct4_32only <-> bits(4) = {
  PADD_DH <-> 0b0000,
  PSADD_DH <-> 0b0010,
  PAADD_DH <-> 0b0011,
  PSADDU_DH <-> 0b0110,
  PAADDU_DH <-> 0b0111,
  PSUB_DH <-> 0b1000,
  PABD_DH <-> 0b1001,
  PSSUB_DH <-> 0b1010,
  PASUB_DH <-> 0b1011,
  PABDU_DH <-> 0b1101,
  PSSUBU_DH <-> 0b1110,
  PASUBU_DH <-> 0b1111,
}

mapping clause encdec = PALUDH_32ONLY(funct4, rs1p, rs2p, rdp) <->
  0b1 @ encdec_paludhfunct4_32only(funct4) @ 0b00 @ encdec_preg(rs2p) @ 0b0 @ encdec_preg(rs1p) @ 0b0110 @ encdec_preg(rdp) @ 0b00011011
  when currentlyEnabled(Ext_P) & xlen == 32

function clause execute (PALUDH_32ONLY(funct4, rs1p, rs2p, rdp)) = {
  assert(xlen == 32);
  let rs1_val = X_pair(regidx_of_pregidx(rs1p));
  let rs2_val = X_pair(regidx_of_pregidx(rs2p));
  var result : bits(64) = rs2_val;
  foreach (i from 0 to (64 - 16) by 16) {
    let rs1_halfword = slice(rs1_val, i, 16);
    let rs2_halfword = slice(rs2_val, i, 16);
    result[(i+15)..i] = match funct4 {
      PADD_DH => rs1_halfword + rs2_halfword,
      PSADD_DH => sadd(rs1_halfword, rs2_halfword),
      PAADD_DH => aadd(rs1_halfword, rs2_halfword),
      PSADDU_DH => saddu(rs1_halfword, rs2_halfword),
      PAADDU_DH => aaddu(rs1_halfword, rs2_halfword),
      PSUB_DH => rs1_halfword - rs2_halfword,
      PABD_DH => if rs1_halfword <_s rs2_halfword then rs2_halfword - rs1_halfword else rs1_halfword - rs2_halfword,
      PSSUB_DH => ssub(rs1_halfword, rs2_halfword),
      PASUB_DH => asub(rs1_halfword, rs2_halfword),
      PABDU_DH => if rs1_halfword <_u rs2_halfword then rs2_halfword - rs1_halfword else rs1_halfword - rs2_halfword,
      PSSUBU_DH => ssubu(rs1_halfword, rs2_halfword),
      PASUBU_DH => asubu(rs1_halfword, rs2_halfword),
    };
  };
  X_pair(regidx_of_pregidx(rdp)) = result;
  RETIRE_SUCCESS
}

mapping paludh_mnemonic_32only : paludhfunct4_32only <-> string = {
  PADD_DH <-> "padd.dh",
  PSADD_DH <-> "psadd.dh",
  PAADD_DH <-> "paadd.dh",
  PSADDU_DH <-> "psaddu.dh",
  PAADDU_DH <-> "paaddu.dh",
  PSUB_DH <-> "psub.dh",
  PABD_DH <-> "pabd.dh",
  PSSUB_DH <-> "pssub.dh",
  PASUB_DH <-> "pasub.dh",
  PABDU_DH <-> "pabdu.dh",
  PSSUBU_DH <-> "pssubu.dh",
  PASUBU_DH <-> "pasubu.dh",
}

mapping clause assembly = PALUDH_32ONLY(funct4, rs1p, rs2p, rdp)
  <-> paludh_mnemonic_32only(funct4) ^ spc() ^ preg_name(rdp) ^ sep() ^ preg_name(rs1p) ^ sep() ^ preg_name(rs2p)
  when currentlyEnabled(Ext_P) & xlen == 32

// ***************************** P ALU DOUBLE WORD ******************************
union clause instruction = PALUDW_32ONLY : (paludwfunct4_32only, pregidx, pregidx, pregidx)

mapping encdec_paludwfunct4_32only : paludwfunct4_32only <-> bits(4) = {
  PADD_DW <-> 0b0000,
  PSADD_DW <-> 0b0010,
  PAADD_DW <-> 0b0011,
  PSADDU_DW <-> 0b0110,
  PAADDU_DW <-> 0b0111,
  PSUB_DW <-> 0b1000,
  PSSUB_DW <-> 0b1010,
  PASUB_DW <-> 0b1011,
  PSSUBU_DW <-> 0b1110,
  PASUBU_DW <-> 0b1111,
}

mapping clause encdec = PALUDW_32ONLY(funct4, rs1p, rs2p, rdp) <->
  0b1 @ encdec_paludwfunct4_32only(funct4) @ 0b01 @ encdec_preg(rs2p) @ 0b0 @ encdec_preg(rs1p) @ 0b0110 @ encdec_preg(rdp) @ 0b00011011
  when currentlyEnabled(Ext_P) & xlen == 32

function clause execute (PALUDW_32ONLY(funct4, rs1p, rs2p, rdp)) = {
  assert(xlen == 32);
  let rs1_val = X_pair(regidx_of_pregidx(rs1p));
  let rs2_val = X_pair(regidx_of_pregidx(rs2p));
  var result : bits(64) = rs2_val;
  foreach (i from 0 to (64 - 32) by 32) {
    let rs1_word = slice(rs1_val, i, 32);
    let rs2_word = slice(rs2_val, i, 32);
    result[(i+31)..i] = match funct4 {
      PADD_DW => rs1_word + rs2_word,
      PSADD_DW => sadd(rs1_word, rs2_word),
      PAADD_DW => aadd(rs1_word, rs2_word),
      PSADDU_DW => saddu(rs1_word, rs2_word),
      PAADDU_DW => aaddu(rs1_word, rs2_word),
      PSUB_DW => rs1_word - rs2_word,
      PSSUB_DW => ssub(rs1_word, rs2_word),
      PASUB_DW => asub(rs1_word, rs2_word),
      PSSUBU_DW => ssubu(rs1_word, rs2_word),
      PASUBU_DW => asubu(rs1_word, rs2_word),
    };
  };
  X_pair(regidx_of_pregidx(rdp)) = result;
  RETIRE_SUCCESS
}

mapping paludw_mnemonic_32only : paludwfunct4_32only <-> string = {
  PADD_DW <-> "padd.dw",
  PSADD_DW <-> "psadd.dw",
  PAADD_DW <-> "paadd.dw",
  PSADDU_DW <-> "psaddu.dw",
  PAADDU_DW <-> "paaddu.dw",
  PSUB_DW <-> "psub.dw",
  PSSUB_DW <-> "pssub.dw",
  PASUB_DW <-> "pasub.dw",
  PSSUBU_DW <-> "pssubu.dw",
  PASUBU_DW <-> "pasubu.dw",
}

mapping clause assembly = PALUDW_32ONLY(funct4, rs1p, rs2p, rdp)
  <-> paludw_mnemonic_32only(funct4) ^ spc() ^ preg_name(rdp) ^ sep() ^ preg_name(rs1p) ^ sep() ^ preg_name(rs2p)
  when currentlyEnabled(Ext_P) & xlen == 32

// ************************** P ALU DOUBLE DOUBLEWORD ***************************
union clause instruction = PALUDD_32ONLY : (paluddfunct4_32only, pregidx, pregidx, pregidx)

mapping encdec_paluddfunct4_32only : paluddfunct4_32only <-> bits(4) = {
  ADDD <-> 0b0000,
  SUBD <-> 0b1000,
}

mapping clause encdec = PALUDD_32ONLY(funct4, rs1p, rs2p, rdp) <->
  0b1 @ encdec_paluddfunct4_32only(funct4) @ 0b11 @ encdec_preg(rs2p) @ 0b0 @ encdec_preg(rs1p) @ 0b0110 @ encdec_preg(rdp) @ 0b00011011
  when currentlyEnabled(Ext_P) & xlen == 32

function clause execute (PALUDD_32ONLY(funct4, rs1p, rs2p, rdp)) = {
  assert(xlen == 32);
  let rs1_val = X_pair(regidx_of_pregidx(rs1p));
  let rs2_val = X_pair(regidx_of_pregidx(rs2p));
  let result : bits(64) = match funct4 {
    ADDD => rs1_val + rs2_val,
    SUBD => rs1_val - rs2_val,
  };
  X_pair(regidx_of_pregidx(rdp)) = result;
  RETIRE_SUCCESS
}

mapping paludd_mnemonic_32only : paluddfunct4_32only <-> string = {
  ADDD <-> "addd",
  SUBD <-> "subd",
}

mapping clause assembly = PALUDD_32ONLY(funct4, rs1p, rs2p, rdp)
  <-> paludd_mnemonic_32only(funct4) ^ spc() ^ preg_name(rdp) ^ sep() ^ preg_name(rs1p) ^ sep() ^ preg_name(rs2p)
  when currentlyEnabled(Ext_P) & xlen == 32

// ********************** P SHIFT ONE ADD DOUBLE HALFWORD ***********************
union clause instruction = PSHIFTONEADDDH_32ONLY : (pshiftoneadddhfunct3_32only, pregidx, pregidx, pregidx)

mapping encdec_pshiftoneadddhfunct3_32only : pshiftoneadddhfunct3_32only <-> bits(3) = {
  PSH1ADD_DH <-> 0b010,
  PSSH1SADD_DH <-> 0b011,
}

mapping clause encdec = PSHIFTONEADDDH_32ONLY(funct3, rs1p, rs2p, rdp) <->
  0b1 @ encdec_pshiftoneadddhfunct3_32only(funct3) @ 0b0 @ 0b00 @ encdec_preg(rs2p) @ 0b1 @ encdec_preg(rs1p) @ 0b0110 @ encdec_preg(rdp) @ 0b00011011
  when currentlyEnabled(Ext_P) & xlen == 32

function clause execute (PSHIFTONEADDDH_32ONLY(funct3, rs1p, rs2p, rdp)) = {
  assert(xlen == 32);
  let rs1_val = X_pair(regidx_of_pregidx(rs1p));
  let rs2_val = X_pair(regidx_of_pregidx(rs2p));
  var result : bits(64) = zeros();
  foreach (i from 0 to (64 - 16) by 16) {
    result[(i+15)..i] = match funct3 {
      PSH1ADD_DH => (rs1_val[(i+15)..i] << 1) + rs2_val[(i+15)..i],
      PSSH1SADD_DH => sadd(sat_shift_left_arith(rs1_val[(i+15)..i], 1), rs2_val[(i+15)..i]),
    };
  };
  X_pair(regidx_of_pregidx(rdp)) = result;
  RETIRE_SUCCESS
}

mapping pshiftoneadddh_mnemonic_32only : pshiftoneadddhfunct3_32only <-> string = {
  PSH1ADD_DH <-> "psh1add.dh",
  PSSH1SADD_DH <-> "pssh1sadd.dh",
}

mapping clause assembly = PSHIFTONEADDDH_32ONLY(funct3, rs1p, rs2p, rdp)
  <-> pshiftoneadddh_mnemonic_32only(funct3) ^ spc() ^ preg_name(rdp) ^ sep() ^ preg_name(rs1p) ^ sep() ^ preg_name(rs2p)
  when currentlyEnabled(Ext_P) & xlen == 32

// ************************ P SHIFT ONE ADD DOUBLE WORD *************************
union clause instruction = PSHIFTONEADDDW_32ONLY : (pshiftoneadddwfunct3_32only, pregidx, pregidx, pregidx)

mapping encdec_pshiftoneadddwfunct3_32only : pshiftoneadddwfunct3_32only <-> bits(3) = {
  PSH1ADD_DW <-> 0b010,
  PSSH1SADD_DW <-> 0b011,
}

mapping clause encdec = PSHIFTONEADDDW_32ONLY(funct3, rs1p, rs2p, rdp) <->
  0b1 @ encdec_pshiftoneadddwfunct3_32only(funct3) @ 0b0 @ 0b01 @ encdec_preg(rs2p) @ 0b1 @ encdec_preg(rs1p) @ 0b0110 @ encdec_preg(rdp) @ 0b00011011
  when currentlyEnabled(Ext_P) & xlen == 32

function clause execute (PSHIFTONEADDDW_32ONLY(funct3, rs1p, rs2p, rdp)) = {
  assert(xlen == 32);
  let rs1_val = X_pair(regidx_of_pregidx(rs1p));
  let rs2_val = X_pair(regidx_of_pregidx(rs2p));
  var result : bits(64) = zeros();
  foreach (i from 0 to (64 - 32) by 32) {
    result[(i+31)..i] = match funct3 {
      PSH1ADD_DW => (rs1_val[(i+31)..i] << 1) + rs2_val[(i+31)..i],
      PSSH1SADD_DW => sadd(sat_shift_left_arith(rs1_val[(i+31)..i], 1), rs2_val[(i+31)..i]),
    };
  };
  X_pair(regidx_of_pregidx(rdp)) = result;
  RETIRE_SUCCESS
}

mapping pshiftoneadddw_mnemonic_32only : pshiftoneadddwfunct3_32only <-> string = {
  PSH1ADD_DW <-> "psh1add.dw",
  PSSH1SADD_DW <-> "pssh1sadd.dw",
}

mapping clause assembly = PSHIFTONEADDDW_32ONLY(funct3, rs1p, rs2p, rdp)
  <-> pshiftoneadddw_mnemonic_32only(funct3) ^ spc() ^ preg_name(rdp) ^ sep() ^ preg_name(rs1p) ^ sep() ^ preg_name(rs2p)
  when currentlyEnabled(Ext_P) & xlen == 32

// ***************************** P PAIR DOUBLE BYTE *****************************
union clause instruction = PPAIRDB_32ONLY : (ppairdbfunct3_32only, pregidx, pregidx, pregidx)

mapping encdec_ppairdbfunct3_32only : ppairdbfunct3_32only <-> bits(3) = {
  PPAIRE_DB <-> 0b000,
  PPAIREO_DB <-> 0b001,
  PPAIROE_DB <-> 0b010,
  PPAIRO_DB <-> 0b011,
}

mapping clause encdec = PPAIRDB_32ONLY(funct3, rs1p, rs2p, rdp) <->
  0b1 @ encdec_ppairdbfunct3_32only(funct3) @ 0b0 @ 0b00 @ encdec_preg(rs2p) @ 0b0 @ encdec_preg(rs1p) @ 0b1110 @ encdec_preg(rdp) @ 0b00011011
  when currentlyEnabled(Ext_P) & xlen == 32

function clause execute (PPAIRDB_32ONLY(funct3, rs1p, rs2p, rdp)) = {
  assert(xlen == 32);
  let rs1_val = X_pair(regidx_of_pregidx(rs1p));
  let rs2_val = X_pair(regidx_of_pregidx(rs2p));
  var result : bits(64) = zeros();
  foreach (i from 0 to (64 - 16) by 16) {
    let rs1_byte_even = slice(rs1_val, i, 8);
    let rs2_byte_even = slice(rs2_val, i, 8);
    let rs1_byte_odd = slice(rs1_val, i + 8, 8);
    let rs2_byte_odd = slice(rs2_val, i + 8, 8);
    result[(i+15)..i] = match funct3 {
      PPAIRE_DB => rs2_byte_even @ rs1_byte_even,
      PPAIREO_DB => rs2_byte_odd @ rs1_byte_even,
      PPAIROE_DB => rs2_byte_even @ rs1_byte_odd,
      PPAIRO_DB => rs2_byte_odd @ rs1_byte_odd,
    };
  };
  X_pair(regidx_of_pregidx(rdp)) = result;
  RETIRE_SUCCESS
}

mapping ppairdb_mnemonic_32only : ppairdbfunct3_32only <-> string = {
  PPAIRE_DB <-> "ppaire.db",
  PPAIREO_DB <-> "ppaireo.db",
  PPAIROE_DB <-> "ppairoe.db",
  PPAIRO_DB <-> "ppairo.db",
}

mapping clause assembly = PPAIRDB_32ONLY(funct3, rs1p, rs2p, rdp)
  <-> ppairdb_mnemonic_32only(funct3) ^ spc() ^ preg_name(rdp) ^ sep() ^ preg_name(rs1p) ^ sep() ^ preg_name(rs2p)
  when currentlyEnabled(Ext_P) & xlen == 32

// *************************** P PAIR DOUBLE HALFWORD ***************************
union clause instruction = PPAIRDH_32ONLY : (ppairdhfunct3_32only, pregidx, pregidx, pregidx)

mapping encdec_ppairdhfunct3_32only : ppairdhfunct3_32only <-> bits(3) = {
  PPAIRE_DH <-> 0b000,
  PPAIREO_DH <-> 0b001,
  PPAIROE_DH <-> 0b010,
  PPAIRO_DH <-> 0b011,
}

mapping clause encdec = PPAIRDH_32ONLY(funct3, rs1p, rs2p, rdp) <->
  0b1 @ encdec_ppairdhfunct3_32only(funct3) @ 0b0 @ 0b01 @ encdec_preg(rs2p) @ 0b0 @ encdec_preg(rs1p) @ 0b1110 @ encdec_preg(rdp) @ 0b00011011
  when currentlyEnabled(Ext_P) & xlen == 32

function clause execute (PPAIRDH_32ONLY(funct3, rs1p, rs2p, rdp)) = {
  assert(xlen == 32);
  let rs1_val = X_pair(regidx_of_pregidx(rs1p));
  let rs2_val = X_pair(regidx_of_pregidx(rs2p));
  var result : bits(64) = zeros();
  foreach (i from 0 to (64 - 32) by 32) {
    let rs1_halfword_even = slice(rs1_val, i, 16);
    let rs2_halfword_even = slice(rs2_val, i, 16);
    let rs1_halfword_odd = slice(rs1_val, i + 16, 16);
    let rs2_halfword_odd = slice(rs2_val, i + 16, 16);
    result[(i+31)..i] = match funct3 {
      PPAIRE_DH => rs2_halfword_even @ rs1_halfword_even,
      PPAIREO_DH => rs2_halfword_odd @ rs1_halfword_even,
      PPAIROE_DH => rs2_halfword_even @ rs1_halfword_odd,
      PPAIRO_DH => rs2_halfword_odd @ rs1_halfword_odd,
    };
  };
  X_pair(regidx_of_pregidx(rdp)) = result;
  RETIRE_SUCCESS
}

mapping ppairdh_mnemonic_32only : ppairdhfunct3_32only <-> string = {
  PPAIRE_DH <-> "ppaire.dh",
  PPAIREO_DH <-> "ppaireo.dh",
  PPAIROE_DH <-> "ppairoe.dh",
  PPAIRO_DH <-> "ppairo.dh",
}

mapping clause assembly = PPAIRDH_32ONLY(funct3, rs1p, rs2p, rdp)
  <-> ppairdh_mnemonic_32only(funct3) ^ spc() ^ preg_name(rdp) ^ sep() ^ preg_name(rs1p) ^ sep() ^ preg_name(rs2p)
  when currentlyEnabled(Ext_P) & xlen == 32

// ************************* P ADD SUB DOUBLE HALFWORD **************************
union clause instruction = PADDSUBDH_32ONLY : (paddsubdhfunct4_32only, pregidx, pregidx, pregidx)

mapping encdec_paddsubdhfunct4_32only : paddsubdhfunct4_32only <-> bits(4) = {
  PAS_DHX <-> 0b0000,
  PSAS_DHX <-> 0b0010,
  PAAS_DHX <-> 0b0011,
}

mapping clause encdec = PADDSUBDH_32ONLY(funct4, rs1p, rs2p, rdp) <->
  0b1 @ encdec_paddsubdhfunct4_32only(funct4) @ 0b00 @ encdec_preg(rs2p) @ 0b1 @ encdec_preg(rs1p) @ 0b1110 @ encdec_preg(rdp) @ 0b00011011
  when currentlyEnabled(Ext_P) & xlen == 32

function clause execute (PADDSUBDH_32ONLY(funct4, rs1p, rs2p, rdp)) = {
  assert(xlen == 32);
  let rs1_val = X_pair(regidx_of_pregidx(rs1p));
  let rs2_val = X_pair(regidx_of_pregidx(rs2p));
  var result : bits(64) = zeros();
  foreach (i from 0 to (64 - 32) by 32) {
    let rs1_halfword_even = slice(rs1_val, i, 16);
    let rs2_halfword_even = slice(rs2_val, i, 16);
    let rs1_halfword_odd = slice(rs1_val, i + 16, 16);
    let rs2_halfword_odd = slice(rs2_val, i + 16, 16);
    result[(i+31)..i] = match funct4 {
      PAS_DHX => (rs1_halfword_odd + rs2_halfword_even) @ (rs1_halfword_even - rs2_halfword_odd),
      PSAS_DHX => sadd(rs1_halfword_odd, rs2_halfword_even) @ ssub(rs1_halfword_even, rs2_halfword_odd),
      PAAS_DHX => aadd(rs1_halfword_odd, rs2_halfword_even) @ asub(rs1_halfword_even, rs2_halfword_odd),
    };
  };
  X_pair(regidx_of_pregidx(rdp)) = result;
  RETIRE_SUCCESS
}

mapping paddsubdh_mnemonic_32only : paddsubdhfunct4_32only <-> string = {
  PAS_DHX <-> "pas.dhx",
  PSAS_DHX <-> "psas.dhx",
  PAAS_DHX <-> "paas.dhx",
}

mapping clause assembly = PADDSUBDH_32ONLY(funct4, rs1p, rs2p, rdp)
  <-> paddsubdh_mnemonic_32only(funct4) ^ spc() ^ preg_name(rdp) ^ sep() ^ preg_name(rs1p) ^ sep() ^ preg_name(rs2p)
  when currentlyEnabled(Ext_P) & xlen == 32

// ************************* P SUB ADD DOUBLE HALFWORD **************************
union clause instruction = PSUBADDDH_32ONLY : (psubadddhfunct4_32only, pregidx, pregidx, pregidx)

mapping encdec_psubadddhfunct4_32only : psubadddhfunct4_32only <-> bits(4) = {
  PSA_DHX <-> 0b0000,
  PSSA_DHX <-> 0b0010,
  PASA_DHX <-> 0b0011,
}

mapping clause encdec = PSUBADDDH_32ONLY(funct4, rs1p, rs2p, rdp) <->
  0b1 @ encdec_psubadddhfunct4_32only(funct4) @ 0b10 @ encdec_preg(rs2p) @ 0b1 @ encdec_preg(rs1p) @ 0b1110 @ encdec_preg(rdp) @ 0b00011011
  when currentlyEnabled(Ext_P) & xlen == 32

function clause execute (PSUBADDDH_32ONLY(funct4, rs1p, rs2p, rdp)) = {
  assert(xlen == 32);
  let rs1_val = X_pair(regidx_of_pregidx(rs1p));
  let rs2_val = X_pair(regidx_of_pregidx(rs2p));
  var result : bits(64) = zeros();
  foreach (i from 0 to (64 - 32) by 32) {
    let rs1_halfword_even = slice(rs1_val, i, 16);
    let rs2_halfword_even = slice(rs2_val, i, 16);
    let rs1_halfword_odd = slice(rs1_val, i + 16, 16);
    let rs2_halfword_odd = slice(rs2_val, i + 16, 16);
    result[(i+31)..i] = match funct4 {
      PSA_DHX => (rs1_halfword_odd - rs2_halfword_even) @ (rs1_halfword_even + rs2_halfword_odd),
      PSSA_DHX => ssub(rs1_halfword_odd, rs2_halfword_even) @ sadd(rs1_halfword_even, rs2_halfword_odd),
      PASA_DHX => asub(rs1_halfword_odd, rs2_halfword_even) @ aadd(rs1_halfword_even, rs2_halfword_odd),
    };
  };
  X_pair(regidx_of_pregidx(rdp)) = result;
  RETIRE_SUCCESS
}

mapping psubadddh_mnemonic_32only : psubadddhfunct4_32only <-> string = {
  PSA_DHX <-> "psa.dhx",
  PSSA_DHX <-> "pssa.dhx",
  PASA_DHX <-> "pasa.dhx",
}

mapping clause assembly = PSUBADDDH_32ONLY(funct4, rs1p, rs2p, rdp)
  <-> psubadddh_mnemonic_32only(funct4) ^ spc() ^ preg_name(rdp) ^ sep() ^ preg_name(rs1p) ^ sep() ^ preg_name(rs2p)
  when currentlyEnabled(Ext_P) & xlen == 32

// ************************** P COMPARISON DOUBLE BYTE **************************
union clause instruction = PCOMPAREDB_32ONLY : (pcomparedbfunct4_32only, pregidx, pregidx, pregidx)

mapping encdec_pcomparedbfunct4_32only : pcomparedbfunct4_32only <-> bits(4) = {
  PMSEQ_DB <-> 0b1000,
  PMSLT_DB <-> 0b1010,
  PMSLTU_DB <-> 0b1011,
  PMIN_DB <-> 0b1100,
  PMINU_DB <-> 0b1101,
  PMAX_DB <-> 0b1110,
  PMAXU_DB <-> 0b1111,
}

mapping clause encdec = PCOMPAREDB_32ONLY(funct4, rs1p, rs2p, rdp) <->
  0b1 @ encdec_pcomparedbfunct4_32only(funct4) @ 0b10 @ encdec_preg(rs2p) @ 0b1 @ encdec_preg(rs1p) @ 0b1110 @ encdec_preg(rdp) @ 0b00011011
  when currentlyEnabled(Ext_P) & xlen == 32

function clause execute (PCOMPAREDB_32ONLY(funct4, rs1p, rs2p, rdp)) = {
  assert(xlen == 32);
  let rs1_val = X_pair(regidx_of_pregidx(rs1p));
  let rs2_val = X_pair(regidx_of_pregidx(rs2p));
  var result : bits(64) = zeros();
  foreach (i from 0 to (64 - 8) by 8) {
    let rs1_byte = slice(rs1_val, i, 8);
    let rs2_byte = slice(rs2_val, i, 8);
    result[(i+7)..i] = match funct4 {
      PMSEQ_DB => mseq(rs1_byte, rs2_byte),
      PMSLT_DB => mslt(rs1_byte, rs2_byte),
      PMSLTU_DB => msltu(rs1_byte, rs2_byte),
      PMIN_DB => mins(rs1_byte, rs2_byte),
      PMINU_DB => minu(rs1_byte, rs2_byte),
      PMAX_DB => maxs(rs1_byte, rs2_byte),
      PMAXU_DB => maxu(rs1_byte, rs2_byte),
    };
  };
  X_pair(regidx_of_pregidx(rdp)) = result;
  RETIRE_SUCCESS
}

mapping pcomparedb_mnemonic_32only : pcomparedbfunct4_32only <-> string = {
  PMSEQ_DB <-> "pmseq.db",
  PMSLT_DB <-> "pmslt.db",
  PMSLTU_DB <-> "pmsltu.db",
  PMIN_DB <-> "pmin.db",
  PMINU_DB <-> "pminu.db",
  PMAX_DB <-> "pmax.db",
  PMAXU_DB <-> "pmaxu.db",
}

mapping clause assembly = PCOMPAREDB_32ONLY(funct4, rs1p, rs2p, rdp)
  <-> pcomparedb_mnemonic_32only(funct4) ^ spc() ^ preg_name(rdp) ^ sep() ^ preg_name(rs1p) ^ sep() ^ preg_name(rs2p)
  when currentlyEnabled(Ext_P) & xlen == 32

// ************************ P COMPARISON DOUBLE HALFWORD ************************
union clause instruction = PCOMPAREDH_32ONLY : (pcomparedhfunct4_32only, pregidx, pregidx, pregidx)

mapping encdec_pcomparedhfunct4_32only : pcomparedhfunct4_32only <-> bits(4) = {
  PMSEQ_DH <-> 0b1000,
  PMSLT_DH <-> 0b1010,
  PMSLTU_DH <-> 0b1011,
  PMIN_DH <-> 0b1100,
  PMINU_DH <-> 0b1101,
  PMAX_DH <-> 0b1110,
  PMAXU_DH <-> 0b1111,
}

mapping clause encdec = PCOMPAREDH_32ONLY(funct4, rs1p, rs2p, rdp) <->
  0b1 @ encdec_pcomparedhfunct4_32only(funct4) @ 0b00 @ encdec_preg(rs2p) @ 0b1 @ encdec_preg(rs1p) @ 0b1110 @ encdec_preg(rdp) @ 0b00011011
  when currentlyEnabled(Ext_P) & xlen == 32

function clause execute (PCOMPAREDH_32ONLY(funct4, rs1p, rs2p, rdp)) = {
  assert(xlen == 32);
  let rs1_val = X_pair(regidx_of_pregidx(rs1p));
  let rs2_val = X_pair(regidx_of_pregidx(rs2p));
  var result : bits(64) = zeros();
  foreach (i from 0 to (64 - 16) by 16) {
    let rs1_halfword = slice(rs1_val, i, 16);
    let rs2_halfword = slice(rs2_val, i, 16);
    result[(i+15)..i] = match funct4 {
      PMSEQ_DH => mseq(rs1_halfword, rs2_halfword),
      PMSLT_DH => mslt(rs1_halfword, rs2_halfword),
      PMSLTU_DH => msltu(rs1_halfword, rs2_halfword),
      PMIN_DH => mins(rs1_halfword, rs2_halfword),
      PMINU_DH => minu(rs1_halfword, rs2_halfword),
      PMAX_DH => maxs(rs1_halfword, rs2_halfword),
      PMAXU_DH => maxu(rs1_halfword, rs2_halfword),
    };
  };
  X_pair(regidx_of_pregidx(rdp)) = result;
  RETIRE_SUCCESS
}

mapping pcomparedh_mnemonic_32only : pcomparedhfunct4_32only <-> string = {
  PMSEQ_DH <-> "pmseq.dh",
  PMSLT_DH <-> "pmslt.dh",
  PMSLTU_DH <-> "pmsltu.dh",
  PMIN_DH <-> "pmin.dh",
  PMINU_DH <-> "pminu.dh",
  PMAX_DH <-> "pmax.dh",
  PMAXU_DH <-> "pmaxu.dh",
}

mapping clause assembly = PCOMPAREDH_32ONLY(funct4, rs1p, rs2p, rdp)
  <-> pcomparedh_mnemonic_32only(funct4) ^ spc() ^ preg_name(rdp) ^ sep() ^ preg_name(rs1p) ^ sep() ^ preg_name(rs2p)
  when currentlyEnabled(Ext_P) & xlen == 32

// ************************** P COMPARISON DOUBLE WORD **************************
union clause instruction = PCOMPAREDW_32ONLY : (pcomparedwfunct4_32only, pregidx, pregidx, pregidx)

mapping encdec_pcomparedwfunct4_32only : pcomparedwfunct4_32only <-> bits(4) = {
  PMSEQ_DW <-> 0b1000,
  PMSLT_DW <-> 0b1010,
  PMSLTU_DW <-> 0b1011,
  PMIN_DW <-> 0b1100,
  PMINU_DW <-> 0b1101,
  PMAX_DW <-> 0b1110,
  PMAXU_DW <-> 0b1111,
}

mapping clause encdec = PCOMPAREDW_32ONLY(funct4, rs1p, rs2p, rdp) <->
  0b1 @ encdec_pcomparedwfunct4_32only(funct4) @ 0b01 @ encdec_preg(rs2p) @ 0b1 @ encdec_preg(rs1p) @ 0b1110 @ encdec_preg(rdp) @ 0b00011011
  when currentlyEnabled(Ext_P) & xlen == 32

function clause execute (PCOMPAREDW_32ONLY(funct4, rs1p, rs2p, rdp)) = {
  assert(xlen == 32);
  let rs1_val = X_pair(regidx_of_pregidx(rs1p));
  let rs2_val = X_pair(regidx_of_pregidx(rs2p));
  var result : bits(64) = zeros();
  foreach (i from 0 to (64 - 32) by 32) {
    let rs1_word = slice(rs1_val, i, 32);
    let rs2_word = slice(rs2_val, i, 32);
    result[(i+31)..i] = match funct4 {
      PMSEQ_DW => mseq(rs1_word, rs2_word),
      PMSLT_DW => mslt(rs1_word, rs2_word),
      PMSLTU_DW => msltu(rs1_word, rs2_word),
      PMIN_DW => mins(rs1_word, rs2_word),
      PMINU_DW => minu(rs1_word, rs2_word),
      PMAX_DW => maxs(rs1_word, rs2_word),
      PMAXU_DW => maxu(rs1_word, rs2_word),
    };
  };
  X_pair(regidx_of_pregidx(rdp)) = result;
  RETIRE_SUCCESS
}

mapping pcomparedw_mnemonic_32only : pcomparedwfunct4_32only <-> string = {
  PMSEQ_DW <-> "pmseq.dw",
  PMSLT_DW <-> "pmslt.dw",
  PMSLTU_DW <-> "pmsltu.dw",
  PMIN_DW <-> "pmin.dw",
  PMINU_DW <-> "pminu.dw",
  PMAX_DW <-> "pmax.dw",
  PMAXU_DW <-> "pmaxu.dw",
}

mapping clause assembly = PCOMPAREDW_32ONLY(funct4, rs1p, rs2p, rdp)
  <-> pcomparedw_mnemonic_32only(funct4) ^ spc() ^ preg_name(rdp) ^ sep() ^ preg_name(rs1p) ^ sep() ^ preg_name(rs2p)
  when currentlyEnabled(Ext_P) & xlen == 32
