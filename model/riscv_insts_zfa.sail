/*=======================================================================================*/
/*  This Sail RISC-V architecture model, comprising all files and                        */
/*  directories except where otherwise noted is subject the BSD                          */
/*  two-clause license in the LICENSE file.                                              */
/*                                                                                       */
/*  SPDX-License-Identifier: BSD-2-Clause                                                */
/*=======================================================================================*/

function clause currentlyEnabled(Ext_Zfa) = hartSupports(Ext_Zfa) & currentlyEnabled(Ext_F)

/* FLI.H */

union clause ast = FLI_H : (bits(5), fregidx)

mapping clause encdec = FLI_H(constantidx, rd)
  <-> 0b111_1010 @ 0b00001 @ constantidx @ 0b000 @ encdec_freg(rd) @ 0b101_0011
  when currentlyEnabled(Ext_Zfh) & currentlyEnabled(Ext_Zfa)

mapping clause assembly = FLI_H(constantidx, rd)
  <-> "fli.h" ^ spc() ^ freg_name(rd) ^ sep() ^ hex_bits_5(constantidx)

function clause execute (FLI_H(constantidx, rd)) = {
  let bits : bits(16) = match constantidx {
    0b00000 => { 0xbc00 },  /* -1.0 */
    0b00001 => { 0x0400 },  /* minimum positive normal */
    0b00010 => { 0x0100 },  /* 1.0 * 2^-16 */
    0b00011 => { 0x0200 },  /* 1.0 * 2^-15 */
    0b00100 => { 0x1c00 },  /* 1.0 * 2^-8  */
    0b00101 => { 0x2000 },  /* 1.0 * 2^-7  */
    0b00110 => { 0x2c00 },  /* 1.0 * 2^-4  */
    0b00111 => { 0x3000 },  /* 1.0 * 2^-3  */
    0b01000 => { 0x3400 },  /* 0.25 */
    0b01001 => { 0x3500 },  /* 0.3125 */
    0b01010 => { 0x3600 },  /* 0.375 */
    0b01011 => { 0x3700 },  /* 0.4375 */
    0b01100 => { 0x3800 },  /* 0.5 */
    0b01101 => { 0x3900 },  /* 0.625 */
    0b01110 => { 0x3a00 },  /* 0.75 */
    0b01111 => { 0x3b00 },  /* 0.875 */
    0b10000 => { 0x3c00 },  /* 1.0 */
    0b10001 => { 0x3d00 },  /* 1.25 */
    0b10010 => { 0x3e00 },  /* 1.5 */
    0b10011 => { 0x3f00 },  /* 1.75 */
    0b10100 => { 0x4000 },  /* 2.0 */
    0b10101 => { 0x4100 },  /* 2.5 */
    0b10110 => { 0x4200 },  /* 3 */
    0b10111 => { 0x4400 },  /* 4 */
    0b11000 => { 0x4800 },  /* 8 */
    0b11001 => { 0x4c00 },  /* 16 */
    0b11010 => { 0x5800 },  /* 2^7 */
    0b11011 => { 0x5c00 },  /* 2^8 */
    0b11100 => { 0x7800 },  /* 2^15 */
    0b11101 => { 0x7c00 },  /* 2^16 */
    0b11110 => { 0x7c00 },  /* +inf */
    0b11111 => { canonical_NaN_H() },
  };
  F_H(rd) = bits;
  RETIRE_SUCCESS
}

/* FLI.S */

union clause ast = FLI_S : (bits(5), fregidx)

mapping clause encdec = FLI_S(constantidx, rd)
  <-> 0b111_1000 @ 0b00001 @ constantidx @ 0b000 @ encdec_freg(rd) @ 0b101_0011
  when currentlyEnabled(Ext_Zfa)

mapping clause assembly = FLI_S(constantidx, rd)
  <-> "fli.s" ^ spc() ^ freg_name(rd) ^ sep() ^ hex_bits_5(constantidx)

function clause execute (FLI_S(constantidx, rd)) = {
  let bits : bits(32) = match constantidx {
    0b00000 => { 0xbf800000 },  /* -1.0 */
    0b00001 => { 0x00800000 },  /* minimum positive normal */
    0b00010 => { 0x37800000 },  /* 1.0 * 2^-16 */
    0b00011 => { 0x38000000 },  /* 1.0 * 2^-15 */
    0b00100 => { 0x3b800000 },  /* 1.0 * 2^-8  */
    0b00101 => { 0x3c000000 },  /* 1.0 * 2^-7  */
    0b00110 => { 0x3d800000 },  /* 1.0 * 2^-4  */
    0b00111 => { 0x3e000000 },  /* 1.0 * 2^-3  */
    0b01000 => { 0x3e800000 },  /* 0.25 */
    0b01001 => { 0x3ea00000 },  /* 0.3125 */
    0b01010 => { 0x3ec00000 },  /* 0.375 */
    0b01011 => { 0x3ee00000 },  /* 0.4375 */
    0b01100 => { 0x3f000000 },  /* 0.5 */
    0b01101 => { 0x3f200000 },  /* 0.625 */
    0b01110 => { 0x3f400000 },  /* 0.75 */
    0b01111 => { 0x3f600000 },  /* 0.875 */
    0b10000 => { 0x3f800000 },  /* 1.0 */
    0b10001 => { 0x3fa00000 },  /* 1.25 */
    0b10010 => { 0x3fc00000 },  /* 1.5 */
    0b10011 => { 0x3fe00000 },  /* 1.75 */
    0b10100 => { 0x40000000 },  /* 2.0 */
    0b10101 => { 0x40200000 },  /* 2.5 */
    0b10110 => { 0x40400000 },  /* 3 */
    0b10111 => { 0x40800000 },  /* 4 */
    0b11000 => { 0x41000000 },  /* 8 */
    0b11001 => { 0x41800000 },  /* 16 */
    0b11010 => { 0x43000000 },  /* 2^7 */
    0b11011 => { 0x43800000 },  /* 2^8 */
    0b11100 => { 0x47000000 },  /* 2^15 */
    0b11101 => { 0x47800000 },  /* 2^16 */
    0b11110 => { 0x7f800000 },  /* +inf */
    0b11111 => { canonical_NaN_S() },
  };
  F_S(rd) = bits;
  RETIRE_SUCCESS
}

/* FLI.D */

union clause ast = FLI_D : (bits(5), fregidx)

mapping clause encdec = FLI_D(constantidx, rd)
  <-> 0b111_1001 @ 0b00001 @ constantidx @ 0b000 @ encdec_freg(rd) @ 0b101_0011
  when currentlyEnabled(Ext_D) & currentlyEnabled(Ext_Zfa)

mapping clause assembly = FLI_D(constantidx, rd)
  <-> "fli.d" ^ spc() ^ freg_name(rd) ^ sep() ^ hex_bits_5(constantidx)

function clause execute (FLI_D(constantidx, rd)) = {
  let bits : bits(64) = match constantidx {
    0b00000 => { 0xbff0000000000000 },  /* -1.0 */
    0b00001 => { 0x0010000000000000 },  /* minimum positive normal */
    0b00010 => { 0x3Ef0000000000000 },  /* 1.0 * 2^-16 */
    0b00011 => { 0x3f00000000000000 },  /* 1.0 * 2^-15 */
    0b00100 => { 0x3f70000000000000 },  /* 1.0 * 2^-8  */
    0b00101 => { 0x3f80000000000000 },  /* 1.0 * 2^-7  */
    0b00110 => { 0x3fb0000000000000 },  /* 1.0 * 2^-4  */
    0b00111 => { 0x3fc0000000000000 },  /* 1.0 * 2^-3  */
    0b01000 => { 0x3fd0000000000000 },  /* 0.25 */
    0b01001 => { 0x3fd4000000000000 },  /* 0.3125 */
    0b01010 => { 0x3fd8000000000000 },  /* 0.375 */
    0b01011 => { 0x3fdc000000000000 },  /* 0.4375 */
    0b01100 => { 0x3fe0000000000000 },  /* 0.5 */
    0b01101 => { 0x3fe4000000000000 },  /* 0.625 */
    0b01110 => { 0x3fe8000000000000 },  /* 0.75 */
    0b01111 => { 0x3fec000000000000 },  /* 0.875 */
    0b10000 => { 0x3ff0000000000000 },  /* 1.0 */
    0b10001 => { 0x3ff4000000000000 },  /* 1.25 */
    0b10010 => { 0x3ff8000000000000 },  /* 1.5 */
    0b10011 => { 0x3ffc000000000000 },  /* 1.75 */
    0b10100 => { 0x4000000000000000 },  /* 2.0 */
    0b10101 => { 0x4004000000000000 },  /* 2.5 */
    0b10110 => { 0x4008000000000000 },  /* 3 */
    0b10111 => { 0x4010000000000000 },  /* 4 */
    0b11000 => { 0x4020000000000000 },  /* 8 */
    0b11001 => { 0x4030000000000000 },  /* 16 */
    0b11010 => { 0x4060000000000000 },  /* 2^7 */
    0b11011 => { 0x4070000000000000 },  /* 2^8 */
    0b11100 => { 0x40e0000000000000 },  /* 2^15 */
    0b11101 => { 0x40f0000000000000 },  /* 2^16 */
    0b11110 => { 0x7ff0000000000000 },  /* +inf */
    0b11111 => { canonical_NaN_D() },
  };
  F_D(rd) = bits;
  RETIRE_SUCCESS
}

/* FLI.Q */

union clause ast = RISCV_FLI_Q : (bits(5), fregidx)

mapping clause encdec = RISCV_FLI_Q(rs1, rd)
  <-> 0b111_1011 @ 0b00001 @ rs1 @ 0b000 @ encdec_freg(rd) @ 0b101_0011
  when currentlyEnabled(Ext_Q) & currentlyEnabled(Ext_Zfa)

mapping clause assembly = RISCV_FLI_Q(constantidx, rd)
  <-> "fli.q" ^ spc() ^ freg_name(rd) ^ sep() ^ hex_bits_5(constantidx)

function clause execute (RISCV_FLI_Q(constantidx, rd)) = {
  let bits : bits(128) = match constantidx {
    0b00000 => { 0xbfff0000000000000000000000000000 },  /* -1.0 */
    0b00001 => { 0x00010000000000000000000000000000 },  /* minimum positive normal */
    0b00010 => { 0x3fef0000000000000000000000000000 },  /* 1.0 * 2^-16 */
    0b00011 => { 0x3ff00000000000000000000000000000 },  /* 1.0 * 2^-15 */
    0b00100 => { 0x3ff70000000000000000000000000000 },  /* 1.0 * 2^-8  */
    0b00101 => { 0x3ff80000000000000000000000000000 },  /* 1.0 * 2^-7  */
    0b00110 => { 0x3ffb0000000000000000000000000000 },  /* 1.0 * 2^-4  */
    0b00111 => { 0x3ffc0000000000000000000000000000 },  /* 1.0 * 2^-3  */
    0b01000 => { 0x3ffd0000000000000000000000000000 },  /* 0.25 */
    0b01001 => { 0x3ffd4000000000000000000000000000 },  /* 0.3125 */
    0b01010 => { 0x3ffd8000000000000000000000000000 },  /* 0.375 */
    0b01011 => { 0x3ffdc000000000000000000000000000 },  /* 0.4375 */
    0b01100 => { 0x3ffe0000000000000000000000000000 },  /* 0.5 */
    0b01101 => { 0x3ffe4000000000000000000000000000 },  /* 0.625 */
    0b01110 => { 0x3ffe8000000000000000000000000000 },  /* 0.75 */
    0b01111 => { 0x3ffec000000000000000000000000000 },  /* 0.875 */
    0b10000 => { 0x3fff0000000000000000000000000000 },  /* 1.0 */
    0b10001 => { 0x3fff4000000000000000000000000000 },  /* 1.25 */
    0b10010 => { 0x3fff8000000000000000000000000000 },  /* 1.5 */
    0b10011 => { 0x3fffc000000000000000000000000000 },  /* 1.75 */
    0b10100 => { 0x40000000000000000000000000000000 },  /* 2.0 */
    0b10101 => { 0x40004000000000000000000000000000 },  /* 2.5 */
    0b10110 => { 0x40008000000000000000000000000000 },  /* 3 */
    0b10111 => { 0x40010000000000000000000000000000 },  /* 4 */
    0b11000 => { 0x40020000000000000000000000000000 },  /* 8 */
    0b11001 => { 0x40030000000000000000000000000000 },  /* 16 */
    0b11010 => { 0x40060000000000000000000000000000 },  /* 2^7 */
    0b11011 => { 0x40070000000000000000000000000000 },  /* 2^8 */
    0b11100 => { 0x400e0000000000000000000000000000 },  /* 2^15 */
    0b11101 => { 0x400f0000000000000000000000000000 },  /* 2^16 */
    0b11110 => { 0x7fff0000000000000000000000000000 },  /* +inf */
    0b11111 => { canonical_NaN_Q() },
  };
  F_Q(rd) = bits;
  RETIRE_SUCCESS
}

/* FMINM.H */

union clause ast = FMINM_H : (fregidx, fregidx, fregidx)

mapping clause encdec = FMINM_H(rs2, rs1, rd)
  <-> 0b001_0110 @ encdec_freg(rs2) @ encdec_freg(rs1) @ 0b010 @ encdec_freg(rd) @ 0b101_0011
  when currentlyEnabled(Ext_Zfh) & currentlyEnabled(Ext_Zfa)

mapping clause assembly = FMINM_H(rs2, rs1, rd)
  <-> "fminm.h" ^ spc() ^ freg_name(rd)
                ^ sep() ^ freg_name(rs1)
                ^ sep() ^ freg_name(rs2)

function clause execute (FMINM_H(rs2, rs1, rd)) = {
  let rs1_val_H = F_H(rs1);
  let rs2_val_H = F_H(rs2);

  let is_quiet  = true;
  let (rs1_lt_rs2, fflags) = fle_H (rs1_val_H, rs2_val_H, is_quiet);

  let rd_val_H  = if      (f_is_NaN_H(rs1_val_H) | f_is_NaN_H(rs2_val_H))           then canonical_NaN_H()
                  else if (f_is_neg_zero_H(rs1_val_H) & f_is_pos_zero_H(rs2_val_H)) then rs1_val_H
                  else if (f_is_neg_zero_H(rs2_val_H) & f_is_pos_zero_H(rs1_val_H)) then rs2_val_H
                  else if rs1_lt_rs2                                                then rs1_val_H
                  else /* (not rs1_lt_rs2) */                                            rs2_val_H;

  accrue_fflags(fflags);
  F_H(rd) = rd_val_H;
  RETIRE_SUCCESS
}

/* FMAXM.H */

union clause ast = FMAXM_H : (fregidx, fregidx, fregidx)

mapping clause encdec = FMAXM_H(rs2, rs1, rd)
  <-> 0b001_0110 @ encdec_freg(rs2) @ encdec_freg(rs1) @ 0b011 @ encdec_freg(rd) @ 0b101_0011
  when currentlyEnabled(Ext_Zfh) & currentlyEnabled(Ext_Zfa)

mapping clause assembly = FMAXM_H(rs2, rs1, rd)
  <-> "fmaxm.h" ^ spc() ^ freg_name(rd)
                ^ sep() ^ freg_name(rs1)
                ^ sep() ^ freg_name(rs2)

function clause execute (FMAXM_H(rs2, rs1, rd)) = {
  let rs1_val_H = F_H(rs1);
  let rs2_val_H = F_H(rs2);

  let is_quiet  = true;
  let (rs2_lt_rs1, fflags) = fle_H (rs2_val_H, rs1_val_H, is_quiet);

  let rd_val_H =  if      (f_is_NaN_H(rs1_val_H) | f_is_NaN_H(rs2_val_H))           then canonical_NaN_H()
                  else if (f_is_neg_zero_H(rs1_val_H) & f_is_pos_zero_H(rs2_val_H)) then rs2_val_H
                  else if (f_is_neg_zero_H(rs2_val_H) & f_is_pos_zero_H(rs1_val_H)) then rs1_val_H
                  else if rs2_lt_rs1                                                then rs1_val_H
                  else /* (not rs2_lt_rs1) */                                            rs2_val_H;

  accrue_fflags(fflags);
  F_H(rd) = rd_val_H;
  RETIRE_SUCCESS
}

/* FMINM.S */

union clause ast = FMINM_S : (fregidx, fregidx, fregidx)

mapping clause encdec = FMINM_S(rs2, rs1, rd)
  <-> 0b001_0100 @ encdec_freg(rs2) @ encdec_freg(rs1) @ 0b010 @ encdec_freg(rd) @ 0b101_0011
  when currentlyEnabled(Ext_Zfa)

mapping clause assembly = FMINM_S(rs2, rs1, rd)
  <-> "fminm.s" ^ spc() ^ freg_name(rd)
                ^ sep() ^ freg_name(rs1)
                ^ sep() ^ freg_name(rs2)

function clause execute (FMINM_S(rs2, rs1, rd)) = {
  let rs1_val_S = F_S(rs1);
  let rs2_val_S = F_S(rs2);

  let is_quiet  = true;
  let (rs1_lt_rs2, fflags) = fle_S (rs1_val_S, rs2_val_S, is_quiet);

  let rd_val_S  = if      (f_is_NaN_S(rs1_val_S) | f_is_NaN_S(rs2_val_S))           then canonical_NaN_S()
                  else if (f_is_neg_zero_S(rs1_val_S) & f_is_pos_zero_S(rs2_val_S)) then rs1_val_S
                  else if (f_is_neg_zero_S(rs2_val_S) & f_is_pos_zero_S(rs1_val_S)) then rs2_val_S
                  else if rs1_lt_rs2                                                then rs1_val_S
                  else /* (not rs1_lt_rs2) */                                            rs2_val_S;

  accrue_fflags(fflags);
  F_S(rd) = rd_val_S;
  RETIRE_SUCCESS
}

/* FMAXM.S */

union clause ast = FMAXM_S : (fregidx, fregidx, fregidx)

mapping clause encdec = FMAXM_S(rs2, rs1, rd)
  <-> 0b001_0100 @ encdec_freg(rs2) @ encdec_freg(rs1) @ 0b011 @ encdec_freg(rd) @ 0b101_0011
  when currentlyEnabled(Ext_Zfa)

mapping clause assembly = FMAXM_S(rs2, rs1, rd)
  <-> "fmaxm.s" ^ spc() ^ freg_name(rd)
                ^ sep() ^ freg_name(rs1)
                ^ sep() ^ freg_name(rs2)

function clause execute (FMAXM_S(rs2, rs1, rd)) = {
  let rs1_val_S = F_S(rs1);
  let rs2_val_S = F_S(rs2);

  let is_quiet  = true;
  let (rs2_lt_rs1, fflags) = fle_S (rs2_val_S, rs1_val_S, is_quiet);

  let rd_val_S  = if      (f_is_NaN_S(rs1_val_S) | f_is_NaN_S(rs2_val_S))           then canonical_NaN_S()
                  else if (f_is_neg_zero_S(rs1_val_S) & f_is_pos_zero_S(rs2_val_S)) then rs2_val_S
                  else if (f_is_neg_zero_S(rs2_val_S) & f_is_pos_zero_S(rs1_val_S)) then rs1_val_S
                  else if rs2_lt_rs1                                                then rs1_val_S
                  else /* (not rs2_lt_rs1) */                                            rs2_val_S;

  accrue_fflags(fflags);
  F_S(rd) = rd_val_S;
  RETIRE_SUCCESS
}

/* FMINM.D */

union clause ast = FMINM_D : (fregidx, fregidx, fregidx)

mapping clause encdec = FMINM_D(rs2, rs1, rd)
  <-> 0b001_0101 @ encdec_freg(rs2) @ encdec_freg(rs1) @ 0b010 @ encdec_freg(rd) @ 0b101_0011
  when currentlyEnabled(Ext_D) & currentlyEnabled(Ext_Zfa)

mapping clause assembly = FMINM_D(rs2, rs1, rd)
  <-> "fminm.d" ^ spc() ^ freg_name(rd)
                ^ sep() ^ freg_name(rs1)
                ^ sep() ^ freg_name(rs2)

function clause execute (FMINM_D(rs2, rs1, rd)) = {
  let rs1_val_D = F_D(rs1);
  let rs2_val_D = F_D(rs2);

  let is_quiet  = true;
  let (rs1_lt_rs2, fflags) = fle_D (rs1_val_D, rs2_val_D, is_quiet);

  let rd_val_D  = if      (f_is_NaN_D(rs1_val_D) | f_is_NaN_D(rs2_val_D))           then canonical_NaN_D()
                  else if (f_is_neg_zero_D(rs1_val_D) & f_is_pos_zero_D(rs2_val_D)) then rs1_val_D
                  else if (f_is_neg_zero_D(rs2_val_D) & f_is_pos_zero_D(rs1_val_D)) then rs2_val_D
                  else if rs1_lt_rs2                                                then rs1_val_D
                  else                                                              rs2_val_D;

  accrue_fflags(fflags);
  F_D(rd) = rd_val_D;
  RETIRE_SUCCESS
}

/* FMAXM.D */

union clause ast = FMAXM_D : (fregidx, fregidx, fregidx)

mapping clause encdec = FMAXM_D(rs2, rs1, rd)
  <-> 0b001_0101 @ encdec_freg(rs2) @ encdec_freg(rs1) @ 0b011 @ encdec_freg(rd) @ 0b101_0011
  when currentlyEnabled(Ext_D) & currentlyEnabled(Ext_Zfa)

mapping clause assembly = FMAXM_D(rs2, rs1, rd)
  <-> "fmaxm.d" ^ spc() ^ freg_name(rd)
                ^ sep() ^ freg_name(rs1)
                ^ sep() ^ freg_name(rs2)

function clause execute (FMAXM_D(rs2, rs1, rd)) = {
  let rs1_val_D = F_D(rs1);
  let rs2_val_D = F_D(rs2);

  let is_quiet  = true;
  let (rs2_lt_rs1, fflags) = fle_D (rs2_val_D, rs1_val_D, is_quiet);

  let rd_val_D  = if      (f_is_NaN_D(rs1_val_D) | f_is_NaN_D(rs2_val_D))           then canonical_NaN_D()
                  else if (f_is_neg_zero_D(rs1_val_D) & f_is_pos_zero_D(rs2_val_D)) then rs2_val_D
                  else if (f_is_neg_zero_D(rs2_val_D) & f_is_pos_zero_D(rs1_val_D)) then rs1_val_D
                  else if rs2_lt_rs1                                                then rs1_val_D
                  else                                                              rs2_val_D;

  accrue_fflags(fflags);
  F_D(rd) = rd_val_D;
  RETIRE_SUCCESS
}

/* FMINM.Q */

union clause ast = RISCV_FMINM_Q : (fregidx, fregidx, fregidx)

mapping clause encdec = RISCV_FMINM_Q(rs2, rs1, rd)
  <-> 0b001_0111 @ encdec_freg(rs2) @ encdec_freg(rs1)@ 0b010 @ encdec_freg(rd) @ 0b101_0011
  when currentlyEnabled(Ext_Q) & currentlyEnabled(Ext_Zfa)

mapping clause assembly = RISCV_FMINM_Q(rs2, rs1, rd)
  <-> "fminm.q" ^ spc() ^ freg_name(rd)
                ^ sep() ^ freg_name(rs1)
                ^ sep() ^ freg_name(rs2)

function clause execute (RISCV_FMINM_Q(rs2, rs1, rd)) = {
  let rs1_val_Q = F_Q(rs1);
  let rs2_val_Q = F_Q(rs2);

  let is_quiet  = true;
  let (rs1_lt_rs2, fflags) = fle_Q (rs1_val_Q, rs2_val_Q, is_quiet);

  let rd_val_Q  = if      (f_is_NaN_Q(rs1_val_Q) | f_is_NaN_Q(rs2_val_Q))           then canonical_NaN_Q()
                  else if (f_is_neg_zero_Q(rs1_val_Q) & f_is_pos_zero_Q(rs2_val_Q)) then rs1_val_Q
                  else if (f_is_neg_zero_Q(rs2_val_Q) & f_is_pos_zero_Q(rs1_val_Q)) then rs2_val_Q
                  else if rs1_lt_rs2                                                then rs1_val_Q
                  else                                                              rs2_val_Q;

  accrue_fflags(fflags);
  F_Q(rd) = rd_val_Q;
  RETIRE_SUCCESS
}

/* FMAXM.Q */

union clause ast = RISCV_FMAXM_Q : (fregidx, fregidx, fregidx)

mapping clause encdec = RISCV_FMAXM_Q(rs2, rs1, rd)
  <-> 0b001_0111 @ encdec_freg(rs2) @ encdec_freg(rs1) @ 0b011 @ encdec_freg(rd) @ 0b101_0011
  when currentlyEnabled(Ext_Q) & currentlyEnabled(Ext_Zfa)

mapping clause assembly = RISCV_FMAXM_Q(rs2, rs1, rd)
  <-> "fmaxm.q" ^ spc() ^ freg_name(rd)
                ^ sep() ^ freg_name(rs1)
                ^ sep() ^ freg_name(rs2)

function clause execute (RISCV_FMAXM_Q(rs2, rs1, rd)) = {
  let rs1_val_Q = F_Q(rs1);
  let rs2_val_Q = F_Q(rs2);

  let is_quiet  = true;
  let (rs2_lt_rs1, fflags) = fle_Q (rs2_val_Q, rs1_val_Q, is_quiet);

  let rd_val_Q  = if      (f_is_NaN_Q(rs1_val_Q) | f_is_NaN_Q(rs2_val_Q))           then canonical_NaN_Q()
                  else if (f_is_neg_zero_Q(rs1_val_Q) & f_is_pos_zero_Q(rs2_val_Q)) then rs2_val_Q
                  else if (f_is_neg_zero_Q(rs2_val_Q) & f_is_pos_zero_Q(rs1_val_Q)) then rs1_val_Q
                  else if rs2_lt_rs1                                                then rs1_val_Q
                  else                                                              rs2_val_Q;

  accrue_fflags(fflags);
  F_Q(rd) = rd_val_Q;
  RETIRE_SUCCESS
}

/* FROUND.H */

union clause ast = FROUND_H : (fregidx, rounding_mode, fregidx)

mapping clause encdec = FROUND_H(rs1, rm, rd)
  <-> 0b010_0010 @ 0b00100 @ encdec_freg(rs1) @ encdec_rounding_mode(rm) @ encdec_freg(rd) @ 0b101_0011
  when currentlyEnabled(Ext_Zfh) & currentlyEnabled(Ext_Zfa)

mapping clause assembly = FROUND_H(rs1, rm, rd)
  <-> "fround.h" ^ spc() ^ freg_name(rd)
                 ^ sep() ^ freg_name(rs1)
                 ^ sep() ^ frm_mnemonic(rm)

function clause execute (FROUND_H(rs1, rm, rd)) = {
  let rs1_val_H = F_H(rs1);

  match (select_instr_or_fcsr_rm(rm)) {
    None() => RETIRE_FAIL(Illegal_Instruction()),
    Some(rm') => {
      let rm_3b =  encdec_rounding_mode(rm');
      let (fflags, rd_val_H) = riscv_f16roundToInt(rm_3b, rs1_val_H, false);

      accrue_fflags(fflags);
      F_H(rd) = rd_val_H;
      RETIRE_SUCCESS
    }
  }
}

/* FROUNDNX.H */

union clause ast = FROUNDNX_H : (fregidx, rounding_mode, fregidx)

mapping clause encdec = FROUNDNX_H(rs1, rm, rd)
  <-> 0b010_0010 @ 0b00101 @ encdec_freg(rs1) @ encdec_rounding_mode(rm) @ encdec_freg(rd) @ 0b101_0011
  when currentlyEnabled(Ext_Zfh) & currentlyEnabled(Ext_Zfa)

mapping clause assembly = FROUNDNX_H(rs1, rm, rd)
  <-> "froundnx.h" ^ spc() ^ freg_name(rd)
                   ^ sep() ^ freg_name(rs1)
                   ^ sep() ^ frm_mnemonic(rm)

function clause execute (FROUNDNX_H(rs1, rm, rd)) = {
  let rs1_val_H = F_H(rs1);

  match (select_instr_or_fcsr_rm(rm)) {
    None() => RETIRE_FAIL(Illegal_Instruction()),
    Some(rm') => {
      let rm_3b =  encdec_rounding_mode(rm');
      let (fflags, rd_val_H) = riscv_f16roundToInt(rm_3b, rs1_val_H, true);

      accrue_fflags(fflags);
      F_H(rd) = rd_val_H;
      RETIRE_SUCCESS
    }
  }
}

/* FROUND.S */

union clause ast = FROUND_S : (fregidx, rounding_mode, fregidx)

mapping clause encdec = FROUND_S(rs1, rm, rd)
  <-> 0b010_0000 @ 0b00100 @ encdec_freg(rs1) @ encdec_rounding_mode(rm) @ encdec_freg(rd) @ 0b101_0011
  when currentlyEnabled(Ext_Zfa)

mapping clause assembly = FROUND_S(rs1, rm, rd)
  <-> "fround.s" ^ spc() ^ freg_name(rd)
                 ^ sep() ^ freg_name(rs1)
                 ^ sep() ^ frm_mnemonic(rm)

function clause execute (FROUND_S(rs1, rm, rd)) = {
  let rs1_val_S = F_S(rs1);

  match (select_instr_or_fcsr_rm(rm)) {
    None() => RETIRE_FAIL(Illegal_Instruction()),
    Some(rm') => {
      let rm_3b =  encdec_rounding_mode(rm');
      let (fflags, rd_val_S) = riscv_f32roundToInt(rm_3b, rs1_val_S, false);

      accrue_fflags(fflags);
      F_S(rd) = rd_val_S;
      RETIRE_SUCCESS
    }
  }
}

/* FROUNDNX.S */

union clause ast = FROUNDNX_S : (fregidx, rounding_mode, fregidx)

mapping clause encdec = FROUNDNX_S(rs1, rm, rd)
  <-> 0b010_0000 @ 0b00101 @ encdec_freg(rs1) @ encdec_rounding_mode(rm) @ encdec_freg(rd) @ 0b101_0011
  when currentlyEnabled(Ext_Zfa)

mapping clause assembly = FROUNDNX_S(rs1, rm, rd)
  <-> "froundnx.s" ^ spc() ^ freg_name(rd)
                   ^ sep() ^ freg_name(rs1)
                   ^ sep() ^ frm_mnemonic(rm)

function clause execute (FROUNDNX_S(rs1, rm, rd)) = {
  let rs1_val_S = F_S(rs1);

  match (select_instr_or_fcsr_rm(rm)) {
    None() => RETIRE_FAIL(Illegal_Instruction()),
    Some(rm') => {
      let rm_3b =  encdec_rounding_mode(rm');
      let (fflags, rd_val_S) = riscv_f32roundToInt(rm_3b, rs1_val_S, true);

      accrue_fflags(fflags);
      F_S(rd) = rd_val_S;
      RETIRE_SUCCESS
    }
  }
}

/* FROUND.D */

union clause ast = FROUND_D : (fregidx, rounding_mode, fregidx)

mapping clause encdec = FROUND_D(rs1, rm, rd)
  <-> 0b010_0001 @ 0b00100 @ encdec_freg(rs1) @ encdec_rounding_mode(rm) @ encdec_freg(rd) @ 0b101_0011
  when currentlyEnabled(Ext_D) & currentlyEnabled(Ext_Zfa)

mapping clause assembly = FROUND_D(rs1, rm, rd)
  <-> "fround.d" ^ spc() ^ freg_name(rd)
                 ^ sep() ^ freg_name(rs1)
                 ^ sep() ^ frm_mnemonic(rm)

function clause execute (FROUND_D(rs1, rm, rd)) = {
  let rs1_val_D = F_D(rs1);

  match (select_instr_or_fcsr_rm(rm)) {
    None() => RETIRE_FAIL(Illegal_Instruction()),
    Some(rm') => {
      let rm_3b =  encdec_rounding_mode(rm');
      let (fflags, rd_val_D) = riscv_f64roundToInt(rm_3b, rs1_val_D, false);

      accrue_fflags(fflags);
      F_D(rd) = rd_val_D;
      RETIRE_SUCCESS
    }
  }
}

/* FROUNDNX.D */

union clause ast = FROUNDNX_D : (fregidx, rounding_mode, fregidx)

mapping clause encdec = FROUNDNX_D(rs1, rm, rd)
  <-> 0b010_0001 @ 0b00101 @ encdec_freg(rs1) @ encdec_rounding_mode(rm) @ encdec_freg(rd) @ 0b101_0011
  when currentlyEnabled(Ext_D) & currentlyEnabled(Ext_Zfa)

mapping clause assembly = FROUNDNX_D(rs1, rm, rd)
  <-> "froundnx.d" ^ spc() ^ freg_name(rd)
                   ^ sep() ^ freg_name(rs1)
                   ^ sep() ^ frm_mnemonic(rm)

function clause execute (FROUNDNX_D(rs1, rm, rd)) = {
  let rs1_val_D = F_D(rs1);

  match (select_instr_or_fcsr_rm(rm)) {
    None() => RETIRE_FAIL(Illegal_Instruction()),
    Some(rm') => {
      let rm_3b =  encdec_rounding_mode(rm');
      let (fflags, rd_val_D) = riscv_f64roundToInt(rm_3b, rs1_val_D, true);

      accrue_fflags(fflags);
      F_D(rd) = rd_val_D;
      RETIRE_SUCCESS
    }
  }
}

/* FROUND.Q */

union clause ast = RISCV_FROUND_Q : (fregidx, rounding_mode, fregidx)

mapping clause encdec = RISCV_FROUND_Q(rs1, rm, rd)
  <-> 0b010_0011 @ 0b00100 @ encdec_freg(rs1) @ encdec_rounding_mode(rm) @ encdec_freg(rd) @ 0b101_0011
  when currentlyEnabled(Ext_Q) & currentlyEnabled(Ext_Zfa)

mapping clause assembly = RISCV_FROUND_Q(rs1, rm, rd)
  <-> "fround.q" ^ spc() ^ freg_name(rd)
                 ^ sep() ^ freg_name(rs1)
                 ^ sep() ^ frm_mnemonic(rm)

function clause execute (RISCV_FROUND_Q(rs1, rm, rd)) = {
  let rs1_val_Q = F_Q(rs1);

  match (select_instr_or_fcsr_rm(rm)) {
    None()    => RETIRE_FAIL(Illegal_Instruction()),
    Some(rm') => {
      let rm_3b =  encdec_rounding_mode(rm');
      let (fflags, rd_val_Q) = riscv_f128roundToInt(rm_3b, rs1_val_Q, false);

      accrue_fflags(fflags);
      F_Q(rd) = rd_val_Q;
      RETIRE_SUCCESS
    }
  }
}

/* FROUNDNX.Q */

union clause ast = RISCV_FROUNDNX_Q : (fregidx, rounding_mode, fregidx)

mapping clause encdec = RISCV_FROUNDNX_Q(rs1, rm, rd)
  <-> 0b010_0011 @ 0b00101 @ encdec_freg(rs1) @ encdec_rounding_mode(rm) @ encdec_freg(rd) @ 0b101_0011
  when currentlyEnabled(Ext_Q) & currentlyEnabled(Ext_Zfa)

mapping clause assembly = RISCV_FROUNDNX_Q(rs1, rm, rd)
  <-> "froundnx.q" ^ spc() ^ freg_name(rd)
                   ^ sep() ^ freg_name(rs1)
                   ^ sep() ^ frm_mnemonic(rm)

function clause execute (RISCV_FROUNDNX_Q(rs1, rm, rd)) = {
  let rs1_val_Q = F_Q(rs1);

  match (select_instr_or_fcsr_rm(rm)) {
    None()    => RETIRE_FAIL(Illegal_Instruction()),
    Some(rm') => {
      let rm_3b =  encdec_rounding_mode(rm');
      let (fflags, rd_val_Q) = riscv_f128roundToInt(rm_3b, rs1_val_Q, true);

      accrue_fflags(fflags);
      F_Q(rd) = rd_val_Q;
      RETIRE_SUCCESS
    }
  }
}

/* FMVH.X.D */

union clause ast = FMVH_X_D : (fregidx, regidx)

mapping clause encdec   = FMVH_X_D(rs1, rd)
  <-> 0b111_0001 @ 0b00001 @ encdec_freg(rs1) @ 0b000 @ encdec_reg(rd) @ 0b101_0011
  when currentlyEnabled(Ext_D) & currentlyEnabled(Ext_Zfa) & in32BitMode()

mapping clause assembly = FMVH_X_D(rs1, rd)
  <-> "fmvh.x.d" ^ spc() ^ reg_name(rd)
                 ^ sep() ^ freg_name(rs1)

function clause execute (FMVH_X_D(rs1, rd)) = {
  let rs1_val_D           = F_D(rs1)[63..32];
  let rd_val_X : xlenbits = sign_extend(rs1_val_D);
  X(rd)                   = rd_val_X;
  RETIRE_SUCCESS
}

/* FMVP.X.D */

union clause ast = FMVP_D_X : (regidx, regidx, fregidx)

mapping clause encdec = FMVP_D_X(rs2, rs1, rd)
  <-> 0b101_1001 @ encdec_reg(rs2) @ encdec_reg(rs1) @ 0b000 @ encdec_freg(rd) @ 0b101_0011
  when currentlyEnabled(Ext_D) & currentlyEnabled(Ext_Zfa) & in32BitMode()

mapping clause assembly = FMVP_D_X(rs2, rs1, rd)
  <-> "fmvp.d.x" ^ spc() ^ freg_name(rd)
                 ^ sep() ^ reg_name(rs1)
                 ^ sep() ^ reg_name(rs2)

function clause execute (FMVP_D_X(rs2, rs1, rd)) = {
  let rs1_val_X     = X(rs1)[31..0];
  let rs2_val_X     = X(rs2)[31..0];

  /* Concatenate the two values using '@' operator */
  /* e.g. */
  /*   rs1 = 0x01234567 */
  /*   rs2 = 0x89abcdef */
  /*   rd  = rs1 @ rs2 => 0x89abcdef01234567 */
  let rd_val_D      = rs2_val_X @ rs1_val_X;

  F_D(rd)           = rd_val_D;
  RETIRE_SUCCESS
}

/* FMVH.X.Q */

union clause ast = RISCV_FMVH_X_Q : (fregidx, regidx)

mapping clause encdec   = RISCV_FMVH_X_Q(rs1, rd)
  <-> 0b111_0011 @ 0b00001 @ encdec_freg(rs1) @ 0b000 @ encdec_reg(rd) @ 0b101_0011
  when currentlyEnabled(Ext_Q) & currentlyEnabled(Ext_Zfa) & in64BitMode()

mapping clause assembly = RISCV_FMVH_X_Q(rs1, rd)
  <-> "fmvh.x.q" ^ spc() ^ reg_name(rd)
                 ^ sep() ^ freg_name(rs1)

function clause execute (RISCV_FMVH_X_Q(rs1, rd)) = {
  assert(xlen == 64);
  let rs1_val_Q           = F_Q(rs1)[127..64];
  let rd_val_X : xlenbits = sign_extend(rs1_val_Q);
  X(rd)                   = rd_val_X;
  RETIRE_SUCCESS
}

/* FMVP.X.Q */

union clause ast = RISCV_FMVP_Q_X : (regidx, regidx, fregidx)

mapping clause encdec = RISCV_FMVP_Q_X(rs2, rs1, rd)
  <-> 0b101_1011 @ encdec_reg(rs2) @ encdec_reg(rs1) @ 0b000 @ encdec_freg(rd) @ 0b101_0011
  when currentlyEnabled(Ext_Q) & currentlyEnabled(Ext_Zfa) & in64BitMode()

mapping clause assembly = RISCV_FMVP_Q_X(rs2, rs1, rd)
  <-> "fmvp.q.x" ^ spc() ^ freg_name(rd)
                 ^ sep() ^ reg_name(rs1)
                 ^ sep() ^ reg_name(rs2)

function clause execute (RISCV_FMVP_Q_X(rs2, rs1, rd)) = {
  assert(xlen ==64);
  let rs1_val_X     = X(rs1)[63..0];
  let rs2_val_X     = X(rs2)[63..0];

  /* Concatenate the two values using '@' operator */
  /* e.g. */
  /*   rs1 = 0x01234567 */
  /*   rs2 = 0x89abcdef */
  /*   rd  = rs1 @ rs2 => 0x89abcdef01234567 */
  let rd_val_Q      = rs2_val_X @ rs1_val_X;

  F_Q(rd)           = rd_val_Q;
  RETIRE_SUCCESS
}

/* FLEQ.H */

union clause ast = FLEQ_H : (fregidx, fregidx, regidx)

mapping clause encdec = FLEQ_H(rs2, rs1, rd)
  <-> 0b101_0010 @ encdec_freg(rs2) @ encdec_freg(rs1) @ 0b100 @ encdec_reg(rd) @ 0b101_0011
  when currentlyEnabled(Ext_Zfh) & currentlyEnabled(Ext_Zfa)

mapping clause assembly = FLEQ_H(rs2, rs1, rd)
  <-> "fleq.h" ^ spc() ^ reg_name(rd)
               ^ sep() ^ freg_name(rs1)
               ^ sep() ^ freg_name(rs2)

function clause execute(FLEQ_H(rs2, rs1, rd)) = {
  let rs1_val_H = F_H(rs1);
  let rs2_val_H = F_H(rs2);

  let (fflags, rd_val) : (bits_fflags, bool) =
      riscv_f16Le_quiet   (rs1_val_H, rs2_val_H);

  accrue_fflags(fflags);
  X(rd) = zero_extend(bool_to_bits(rd_val));
  RETIRE_SUCCESS
}

/* FLTQ.H */

union clause ast = FLTQ_H : (fregidx, fregidx, regidx)

mapping clause encdec = FLTQ_H(rs2, rs1, rd)
  <-> 0b101_0010 @ encdec_freg(rs2) @ encdec_freg(rs1) @ 0b101 @ encdec_reg(rd) @ 0b101_0011
  when currentlyEnabled(Ext_Zfh) & currentlyEnabled(Ext_Zfa)

mapping clause assembly = FLTQ_H(rs2, rs1, rd)
  <-> "fltq.h" ^ spc() ^ reg_name(rd)
               ^ sep() ^ freg_name(rs1)
               ^ sep() ^ freg_name(rs2)

function clause execute(FLTQ_H(rs2, rs1, rd)) = {
  let rs1_val_H = F_H(rs1);
  let rs2_val_H = F_H(rs2);

  let (fflags, rd_val) : (bits_fflags, bool) =
      riscv_f16Lt_quiet   (rs1_val_H, rs2_val_H);

  accrue_fflags(fflags);
  X(rd) = zero_extend(bool_to_bits(rd_val));
  RETIRE_SUCCESS
}

/* FLEQ.S */

union clause ast = FLEQ_S : (fregidx, fregidx, regidx)

mapping clause encdec = FLEQ_S(rs2, rs1, rd)
  <-> 0b101_0000 @ encdec_freg(rs2) @ encdec_freg(rs1) @ 0b100 @ encdec_reg(rd) @ 0b101_0011
  when currentlyEnabled(Ext_Zfa)

mapping clause assembly = FLEQ_S(rs2, rs1, rd)
  <-> "fleq.s" ^ spc() ^ reg_name(rd)
               ^ sep() ^ freg_name(rs1)
               ^ sep() ^ freg_name(rs2)

function clause execute(FLEQ_S(rs2, rs1, rd)) = {
  let rs1_val_S = F_S(rs1);
  let rs2_val_S = F_S(rs2);

  let (fflags, rd_val) : (bits_fflags, bool) =
      riscv_f32Le_quiet   (rs1_val_S, rs2_val_S);

  accrue_fflags(fflags);
  X(rd) = zero_extend(bool_to_bits(rd_val));
  RETIRE_SUCCESS
}

/* FLTQ.S */

union clause ast = FLTQ_S : (fregidx, fregidx, regidx)

mapping clause encdec = FLTQ_S(rs2, rs1, rd)
  <-> 0b101_0000 @ encdec_freg(rs2) @ encdec_freg(rs1) @ 0b101 @ encdec_reg(rd) @ 0b101_0011
  when currentlyEnabled(Ext_Zfa)

mapping clause assembly = FLTQ_S(rs2, rs1, rd)
  <-> "fltq.s" ^ spc() ^ reg_name(rd)
               ^ sep() ^ freg_name(rs1)
               ^ sep() ^ freg_name(rs2)

function clause execute(FLTQ_S(rs2, rs1, rd)) = {
  let rs1_val_S = F_S(rs1);
  let rs2_val_S = F_S(rs2);

  let (fflags, rd_val) : (bits_fflags, bool) =
      riscv_f32Lt_quiet   (rs1_val_S, rs2_val_S);

  accrue_fflags(fflags);
  X(rd) = zero_extend(bool_to_bits(rd_val));
  RETIRE_SUCCESS
}


/* FLEQ.D */

union clause ast = FLEQ_D : (fregidx, fregidx, regidx)

mapping clause encdec = FLEQ_D(rs2, rs1, rd)
  <-> 0b101_0001 @ encdec_freg(rs2) @ encdec_freg(rs1) @ 0b100 @ encdec_reg(rd) @ 0b101_0011
  when currentlyEnabled(Ext_D) & currentlyEnabled(Ext_Zfa)

mapping clause assembly = FLEQ_D(rs2, rs1, rd)
  <-> "fleq.d" ^ spc() ^ reg_name(rd)
               ^ sep() ^ freg_name(rs1)
               ^ sep() ^ freg_name(rs2)

function clause execute(FLEQ_D(rs2, rs1, rd)) = {
  let rs1_val_D = F_D(rs1);
  let rs2_val_D = F_D(rs2);

  let (fflags, rd_val) : (bits_fflags, bool) =
      riscv_f64Le_quiet   (rs1_val_D, rs2_val_D);

  accrue_fflags(fflags);
  X(rd) = zero_extend(bool_to_bits(rd_val));
  RETIRE_SUCCESS
}

/* FLTQ.D */

union clause ast = FLTQ_D : (fregidx, fregidx, regidx)

mapping clause encdec = FLTQ_D(rs2, rs1, rd)
  <-> 0b101_0001 @ encdec_freg(rs2) @ encdec_freg(rs1) @ 0b101 @ encdec_reg(rd) @ 0b101_0011
  when currentlyEnabled(Ext_D) & currentlyEnabled(Ext_Zfa)

mapping clause assembly = FLTQ_D(rs2, rs1, rd)
  <-> "fltq.d" ^ spc() ^ reg_name(rd)
               ^ sep() ^ freg_name(rs1)
               ^ sep() ^ freg_name(rs2)

function clause execute(FLTQ_D(rs2, rs1, rd)) = {
  let rs1_val_D = F_D(rs1);
  let rs2_val_D = F_D(rs2);

  let (fflags, rd_val) : (bits_fflags, bool) =
      riscv_f64Lt_quiet   (rs1_val_D, rs2_val_D);

  accrue_fflags(fflags);
  X(rd) = zero_extend(bool_to_bits(rd_val));
  RETIRE_SUCCESS
}

/* FLEQ.Q */

union clause ast = RISCV_FLEQ_Q : (fregidx, fregidx, regidx)

mapping clause encdec = RISCV_FLEQ_Q(rs2, rs1, rd)
  <-> 0b101_0011 @ encdec_freg(rs2) @ encdec_freg(rs1) @ 0b100 @ encdec_reg(rd) @ 0b101_0011
  when currentlyEnabled(Ext_Q) & currentlyEnabled(Ext_Zfa)

mapping clause assembly = RISCV_FLEQ_Q(rs2, rs1, rd)
  <-> "fleq.q" ^ spc() ^ reg_name(rd)
               ^ sep() ^ freg_name(rs1)
               ^ sep() ^ freg_name(rs2)

function clause execute(RISCV_FLEQ_Q(rs2, rs1, rd)) = {
  let rs1_val_Q = F_Q(rs1);
  let rs2_val_Q = F_Q(rs2);

  let (fflags, rd_val) : (bits_fflags, bool) =
      riscv_f128Le_quiet   (rs1_val_Q, rs2_val_Q);

  accrue_fflags(fflags);
  X(rd) = zero_extend(bool_to_bits(rd_val));
  RETIRE_SUCCESS
}

/* FLTQ.Q */

union clause ast = RISCV_FLTQ_Q : (fregidx, fregidx, regidx)

mapping clause encdec = RISCV_FLTQ_Q(rs2, rs1, rd)
  <-> 0b101_0011 @ encdec_freg(rs2) @ encdec_freg(rs1) @ 0b101 @ encdec_reg(rd) @ 0b101_0011
  when currentlyEnabled(Ext_Q) & currentlyEnabled(Ext_Zfa)

mapping clause assembly = RISCV_FLTQ_Q(rs2, rs1, rd)
  <-> "fltq.q" ^ spc() ^ reg_name(rd)
               ^ sep() ^ freg_name(rs1)
               ^ sep() ^ freg_name(rs2)

function clause execute(RISCV_FLTQ_Q(rs2, rs1, rd)) = {
  let rs1_val_Q = F_Q(rs1);
  let rs2_val_Q = F_Q(rs2);

  let (fflags, rd_val) : (bits_fflags, bool) =
      riscv_f128Lt_quiet   (rs1_val_Q, rs2_val_Q);

  accrue_fflags(fflags);
  X(rd) = zero_extend(bool_to_bits(rd_val));
  RETIRE_SUCCESS
}

/* FCVTMOD.W.D */

/*
 * Implement float64 to int32 conversion without saturation, the
 * result is supplied modulo 2^32.
 */
val      fcvtmod_helper : bits(64) -> (bits(5), bits(32))
function fcvtmod_helper(x64) = {
  let (sign, exp, mant) = fsplit_D(x64);

  /* Detect the non-normal cases */
  let is_subnorm    = exp == zeros() & mant != zeros();
  let is_zero       = exp == zeros() & mant == zeros();
  let is_nan_or_inf = exp == ones();

  /* For normal numbers, the mantissa and exponent use special encoding */
  let true_mant     = 0b1 @ mant;  /* concatenate with the implicit bit */
  let true_exp      = unsigned(exp) - 1023;   /* undo the offset-binary */

  /*
   * Detect the trivial cases for normal numbers.
   *
   * While is_too_large could subsume is_nan_or_inf, and is_too_small
   * cound subsume is_subnorm, we deliberately enumerate these
   * separately as is_too_large/is_too_small operate on normal
   * numbers.
   */
  let is_too_large  = true_exp >= 84;  /* bits will be 'multiplied' out */
  let is_too_small  = true_exp <  0;   /* bits will be 'divided' out    */

       if is_zero       then (zeros(),  zeros())
  else if is_subnorm    then (nxFlag(), zeros())
  else if is_nan_or_inf then (nvFlag(), zeros())
  else if is_too_large  then (nvFlag(), zeros())
  else if is_too_small  then (nxFlag(), zeros())
  else {
    /*
     * Calculate the low 32 bits of the integer value from the
     * binary64 floating-point number and return them together with an
     * indicator whether a NV (overflow) or NX (inexact) exceptions is
     * to be raised.
     */

    /* Perform the exponentation on the fixed-point mantissa and
       extract the integer part */
    let fixedpoint : bits(84) = zero_extend(true_mant) << true_exp;
    let integer    = fixedpoint[83..52];
    let fractional = fixedpoint[51..0];

    /* Apply the sign bit */
    let result = if sign == 0b1 then ~(integer) + 1
                                else integer;

    /* Raise FP exception flags, honoring the precedence of nV > nX */
    let max_integer = if sign == 0b1 then unsigned(0x80000000)
                                     else unsigned(0x7fffffff);
    let flags : bits(5) = if true_exp > 31 then nvFlag()
                     else if unsigned(integer) > max_integer then nvFlag()
                     else if (fractional != zeros()) then nxFlag()
                     else                            zeros();

    (flags, result)
  }
}

union clause ast = FCVTMOD_W_D : (fregidx, regidx)

/* We need rounding mode to be explicitly specified to RTZ(0b001) */
mapping clause encdec = FCVTMOD_W_D(rs1, rd)
  <-> 0b110_0001 @ 0b01000 @ encdec_freg(rs1) @ 0b001 @ encdec_reg(rd) @ 0b101_0011
  when currentlyEnabled(Ext_D) & currentlyEnabled(Ext_Zfa)

mapping clause assembly = FCVTMOD_W_D(rs1, rd)
  <-> "fcvtmod.w.d" ^ spc() ^ reg_name(rd) ^ sep() ^ freg_name(rs1)

function clause execute(FCVTMOD_W_D(rs1, rd)) = {
  let rs1_val_D = F_D(rs1);
  let (fflags, rd_val) = fcvtmod_helper(rs1_val_D);
  accrue_fflags(fflags);
  X(rd) = sign_extend(rd_val);
  RETIRE_SUCCESS
}
