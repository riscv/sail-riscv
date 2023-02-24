/* FLI.H */

union clause ast = RISCV_FLI_H : (bits(5), regidx)

mapping clause encdec = RISCV_FLI_H(rs1, rd)                if (haveZfh() & haveZfa())
  <-> 0b111_1010 @ 0b00001 @ rs1 @ 0b000 @ rd @ 0b101_0011  if (haveZfh() & haveZfa())

mapping clause assembly = RISCV_FLI_H(constantidx, rd)
  <-> "fli.h" ^ spc() ^ freg_name(rd) ^ sep() ^ hex_bits_5(constantidx)

function clause execute (RISCV_FLI_H(constantidx, rd)) = {
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
  F(rd) = nan_box(bits);
  RETIRE_SUCCESS
}

/* FLI.S */

union clause ast = RISCV_FLI_S : (bits(5), regidx)

mapping clause encdec = RISCV_FLI_S(rs1, rd)                if (haveFExt() & haveZfa())
  <-> 0b111_1000 @ 0b00001 @ rs1 @ 0b000 @ rd @ 0b101_0011  if (haveFExt() & haveZfa())

mapping clause assembly = RISCV_FLI_S(constantidx, rd)
  <-> "fli.s" ^ spc() ^ freg_name(rd) ^ sep() ^ hex_bits_5(constantidx)

function clause execute (RISCV_FLI_S(constantidx, rd)) = {
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
  F(rd) = nan_box(bits);
  RETIRE_SUCCESS
}

/* FLI.D */

union clause ast = RISCV_FLI_D : (bits(5), regidx)

mapping clause encdec = RISCV_FLI_D(rs1, rd)                if (haveDExt() & haveZfa())
  <-> 0b111_1001 @ 0b00001 @ rs1 @ 0b000 @ rd @ 0b101_0011  if (haveDExt() & haveZfa())

mapping clause assembly = RISCV_FLI_D(constantidx, rd)
  <-> "fli.d" ^ spc() ^ freg_name(rd) ^ sep() ^ hex_bits_5(constantidx)

function clause execute (RISCV_FLI_D(constantidx, rd)) = {
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
  F(rd) = bits;
  RETIRE_SUCCESS
}

/* FMINM.H */

union clause ast = RISCV_FMINM_H : (regidx, regidx, regidx)

mapping clause encdec = RISCV_FMINM_H(rs2, rs1, rd)     if (haveZfh() & haveZfa())
  <-> 0b001_0110 @ rs2 @ rs1 @ 0b010 @ rd @ 0b101_0011  if (haveZfh() & haveZfa())

mapping clause assembly = RISCV_FMINM_H(rs2, rs1, rd)
  <-> "fminm.h" ^ spc() ^ freg_name(rd)
                ^ spc() ^ freg_name(rs1)
                ^ spc() ^ freg_name(rs2)

function clause execute (RISCV_FMINM_H(rs2, rs1, rd)) = {
  let rs1_val_H = nan_unbox_H(F(rs1));
  let rs2_val_H = nan_unbox_H(F(rs2));

  let is_quiet  = true;
  let (rs1_lt_rs2, fflags) = fle_H (rs1_val_H, rs2_val_H, is_quiet);

  let rd_val_H  = if      (f_is_NaN_H(rs1_val_H) | f_is_NaN_H(rs2_val_H))           then canonical_NaN_H()
                  else if (f_is_neg_zero_H(rs1_val_H) & f_is_pos_zero_H(rs2_val_H)) then rs1_val_H
                  else if (f_is_neg_zero_H(rs2_val_H) & f_is_pos_zero_H(rs1_val_H)) then rs2_val_H
                  else if rs1_lt_rs2                                                then rs1_val_H
                  else /* (not rs1_lt_rs2) */                                            rs2_val_H;

  accrue_fflags(fflags);
  F(rd) = nan_box(rd_val_H);
  RETIRE_SUCCESS
}

/* FMAXM.H */

union clause ast = RISCV_FMAXM_H : (regidx, regidx, regidx)

mapping clause encdec = RISCV_FMAXM_H(rs2, rs1, rd)     if (haveZfh() & haveZfa())
  <-> 0b001_0110 @ rs2 @ rs1 @ 0b011 @ rd @ 0b101_0011  if (haveZfh() & haveZfa())

mapping clause assembly = RISCV_FMAXM_H(rs2, rs1, rd)
  <-> "fmaxm.h" ^ spc() ^ freg_name(rd)
                ^ spc() ^ freg_name(rs1)
                ^ spc() ^ freg_name(rs2)

function clause execute (RISCV_FMAXM_H(rs2, rs1, rd)) = {
  let rs1_val_H = nan_unbox_H(F(rs1));
  let rs2_val_H = nan_unbox_H(F(rs2));

  let is_quiet  = true;
  let (rs2_lt_rs1, fflags) = fle_H (rs2_val_H, rs1_val_H, is_quiet);

  let rd_val_H =  if      (f_is_NaN_H(rs1_val_H) | f_is_NaN_H(rs2_val_H))           then canonical_NaN_H()
                  else if (f_is_neg_zero_H(rs1_val_H) & f_is_pos_zero_H(rs2_val_H)) then rs2_val_H
                  else if (f_is_neg_zero_H(rs2_val_H) & f_is_pos_zero_H(rs1_val_H)) then rs1_val_H
                  else if rs2_lt_rs1                                                then rs1_val_H
                  else /* (not rs2_lt_rs1) */                                            rs2_val_H;

  accrue_fflags(fflags);
  F(rd) = nan_box(rd_val_H);
  RETIRE_SUCCESS
}

/* FMINM.S */

union clause ast = RISCV_FMINM_S : (regidx, regidx, regidx)

mapping clause encdec = RISCV_FMINM_S(rs2, rs1, rd)     if (haveFExt() & haveZfa())
  <-> 0b001_0100 @ rs2 @ rs1 @ 0b010 @ rd @ 0b101_0011  if (haveFExt() & haveZfa())

mapping clause assembly = RISCV_FMINM_S(rs2, rs1, rd)
  <-> "fminm.s" ^ spc() ^ freg_name(rd)
                ^ spc() ^ freg_name(rs1)
                ^ spc() ^ freg_name(rs2)

function clause execute (RISCV_FMINM_S(rs2, rs1, rd)) = {
  let rs1_val_S = nan_unbox_S(F(rs1));
  let rs2_val_S = nan_unbox_S(F(rs2));

  let is_quiet  = true;
  let (rs1_lt_rs2, fflags) = fle_S (rs1_val_S, rs2_val_S, is_quiet);

  let rd_val_S  = if      (f_is_NaN_S(rs1_val_S) | f_is_NaN_S(rs2_val_S))           then canonical_NaN_S()
                  else if (f_is_neg_zero_S(rs1_val_S) & f_is_pos_zero_S(rs2_val_S)) then rs1_val_S
                  else if (f_is_neg_zero_S(rs2_val_S) & f_is_pos_zero_S(rs1_val_S)) then rs2_val_S
                  else if rs1_lt_rs2                                                then rs1_val_S
                  else /* (not rs1_lt_rs2) */                                            rs2_val_S;

  accrue_fflags(fflags);
  F(rd) = nan_box(rd_val_S);
  RETIRE_SUCCESS
}

/* FMAXM.S */

union clause ast = RISCV_FMAXM_S : (regidx, regidx, regidx)

mapping clause encdec = RISCV_FMAXM_S(rs2, rs1, rd)     if (haveFExt() & haveZfa())
  <-> 0b001_0100 @ rs2 @ rs1 @ 0b011 @ rd @ 0b101_0011  if (haveFExt() & haveZfa())

mapping clause assembly = RISCV_FMAXM_S(rs2, rs1, rd)
  <-> "fmaxm.s" ^ spc() ^ freg_name(rd)
                ^ spc() ^ freg_name(rs1)
                ^ spc() ^ freg_name(rs2)

function clause execute (RISCV_FMAXM_S(rs2, rs1, rd)) = {
  let rs1_val_S = nan_unbox_S(F(rs1));
  let rs2_val_S = nan_unbox_S(F(rs2));

  let is_quiet  = true;
  let (rs2_lt_rs1, fflags) = fle_S (rs2_val_S, rs1_val_S, is_quiet);

  let rd_val_S  = if      (f_is_NaN_S(rs1_val_S) | f_is_NaN_S(rs2_val_S))           then canonical_NaN_S()
                  else if (f_is_neg_zero_S(rs1_val_S) & f_is_pos_zero_S(rs2_val_S)) then rs2_val_S
                  else if (f_is_neg_zero_S(rs2_val_S) & f_is_pos_zero_S(rs1_val_S)) then rs1_val_S
                  else if rs2_lt_rs1                                                then rs1_val_S
                  else /* (not rs2_lt_rs1) */                                            rs2_val_S;

  accrue_fflags(fflags);
  F(rd) = nan_box(rd_val_S);
  RETIRE_SUCCESS
}

/* FMINM.D */

union clause ast = RISCV_FMINM_D : (regidx, regidx, regidx)

mapping clause encdec = RISCV_FMINM_D(rs2, rs1, rd)     if (haveDExt() & haveZfa())
  <-> 0b001_0101 @ rs2 @ rs1 @ 0b010 @ rd @ 0b101_0011  if (haveDExt() & haveZfa())

mapping clause assembly = RISCV_FMINM_D(rs2, rs1, rd)
  <-> "fminm.d" ^ spc() ^ freg_name(rd)
                ^ spc() ^ freg_name(rs1)
                ^ spc() ^ freg_name(rs2)

function clause execute (RISCV_FMINM_D(rs2, rs1, rd)) = {
  let rs1_val_D = F(rs1);
  let rs2_val_D = F(rs2);

  let is_quiet  = true;
  let (rs1_lt_rs2, fflags) = fle_D (rs1_val_D, rs2_val_D, is_quiet);

  let rd_val_D  = if      (f_is_NaN_D(rs1_val_D) | f_is_NaN_D(rs2_val_D))           then canonical_NaN_D()
                  else if (f_is_neg_zero_D(rs1_val_D) & f_is_pos_zero_D(rs2_val_D)) then rs1_val_D
                  else if (f_is_neg_zero_D(rs2_val_D) & f_is_pos_zero_D(rs1_val_D)) then rs2_val_D
                  else if rs1_lt_rs2                                                then rs1_val_D
                  else                                                              rs2_val_D;

  accrue_fflags(fflags);
  F(rd) = rd_val_D;
  RETIRE_SUCCESS
}

/* FMAXM.D */

union clause ast = RISCV_FMAXM_D : (regidx, regidx, regidx)

mapping clause encdec = RISCV_FMAXM_D(rs2, rs1, rd)     if (haveDExt() & haveZfa())
  <-> 0b001_0101 @ rs2 @ rs1 @ 0b011 @ rd @ 0b101_0011  if (haveDExt() & haveZfa())

mapping clause assembly = RISCV_FMAXM_D(rs2, rs1, rd)
  <-> "fmaxm.s" ^ spc() ^ freg_name(rd)
                ^ spc() ^ freg_name(rs1)
                ^ spc() ^ freg_name(rs2)

function clause execute (RISCV_FMAXM_D(rs2, rs1, rd)) = {
  let rs1_val_D = F(rs1);
  let rs2_val_D = F(rs2);

  let is_quiet  = true;
  let (rs2_lt_rs1, fflags) = fle_D (rs2_val_D, rs1_val_D, is_quiet);

  let rd_val_D  = if      (f_is_NaN_D(rs1_val_D) | f_is_NaN_D(rs2_val_D))           then canonical_NaN_D()
                  else if (f_is_neg_zero_D(rs1_val_D) & f_is_pos_zero_D(rs2_val_D)) then rs2_val_D
                  else if (f_is_neg_zero_D(rs2_val_D) & f_is_pos_zero_D(rs1_val_D)) then rs1_val_D
                  else if rs2_lt_rs1                                                then rs1_val_D
                  else                                                              rs2_val_D;

  accrue_fflags(fflags);
  F(rd) = rd_val_D;
  RETIRE_SUCCESS
}

/* FROUND.H */

union clause ast = RISCV_FROUND_H : (regidx, rounding_mode, regidx)

mapping clause encdec = RISCV_FROUND_H(rs1, rm, rd)                           if (haveZfh() & haveZfa())
  <-> 0b010_0010 @ 0b00100 @ rs1 @ encdec_rounding_mode(rm) @ rd @ 0b101_0011 if (haveZfh() & haveZfa())

mapping clause assembly = RISCV_FROUND_H(rs1, rm, rd)
  <-> "fround.h" ^ spc() ^ freg_name(rd)
                 ^ spc() ^ freg_name(rs1)
                 ^ spc() ^ frm_mnemonic(rm)

function clause execute (RISCV_FROUND_H(rs1, rm, rd)) = {
  let rs1_val_H = nan_unbox_H(F(rs1));
  let fflags = fcsr.FFLAGS();

  match (select_instr_or_fcsr_rm(rm)) {
    None() => { handle_illegal(); RETIRE_FAIL },
    Some(rm') => {
      let rm_3b =  encdec_rounding_mode(rm');

      let (result_fflags, result_F) = if (f_is_NaN_H(rs1_val_H))        then (nvFlag(), rs1_val_H)
      else if (f_is_pos_inf_H(rs1_val_H)  | f_is_neg_inf_H(rs1_val_H))  then (fflags, rs1_val_H)
      else if (f_is_pos_zero_H(rs1_val_H) | f_is_neg_zero_H(rs1_val_H)) then (fflags, rs1_val_H)
      else {
        let (_, rd_val_H) = riscv_f16ToI32(rm_3b, rs1_val_H);
        let (_, rd_val_H) = riscv_i32ToF16(rm_3b, rd_val_H);
        (fflags, rd_val_H)
      };

      write_fflags(result_fflags);
      F(rd) = nan_box_H(result_F);
      RETIRE_SUCCESS
    }
  }
}

/* FROUNDNX.H */

union clause ast = RISCV_FROUNDNX_H : (regidx, rounding_mode, regidx)

mapping clause encdec = RISCV_FROUNDNX_H(rs1, rm, rd)                         if (haveZfh() & haveZfa())
  <-> 0b010_0010 @ 0b00101 @ rs1 @ encdec_rounding_mode(rm) @ rd @ 0b101_0011 if (haveZfh() & haveZfa())

mapping clause assembly = RISCV_FROUNDNX_H(rs1, rm, rd)
  <-> "froundnx.h" ^ spc() ^ freg_name(rd)
                   ^ spc() ^ freg_name(rs1)
                   ^ spc() ^ frm_mnemonic(rm)

function clause execute (RISCV_FROUNDNX_H(rs1, rm, rd)) = {
  let rs1_val_H = nan_unbox_H(F(rs1));
  let fflags = fcsr.FFLAGS();

  match (select_instr_or_fcsr_rm(rm)) {
    None() => { handle_illegal(); RETIRE_FAIL },
    Some(rm') => {
      let rm_3b =  encdec_rounding_mode(rm');

      let (result_fflags, result_F) = if (f_is_NaN_H(rs1_val_H))        then (nvFlag(), rs1_val_H)
      else if (f_is_pos_inf_H(rs1_val_H)  | f_is_neg_inf_H(rs1_val_H))  then (fflags, rs1_val_H)
      else if (f_is_pos_zero_H(rs1_val_H) | f_is_neg_zero_H(rs1_val_H)) then (fflags, rs1_val_H)
      else {
        let (_, rd_val_H) = riscv_f16ToI32(rm_3b, rs1_val_H);
        let (_, rd_val_H) = riscv_i32ToF16(rm_3b, rd_val_H);

        if (rs1_val_H != rd_val_H) then (nxFlag(), rd_val_H)
        else                            (fflags, rd_val_H)
      };

      write_fflags(result_fflags);
      F(rd) = nan_box_H(result_F);
      RETIRE_SUCCESS
    }
  }
}

/* FROUND.S */

union clause ast = RISCV_FROUND_S : (regidx, rounding_mode, regidx)

mapping clause encdec = RISCV_FROUND_S(rs1, rm, rd)                            if (haveFExt() & haveZfa())
  <-> 0b010_0000 @ 0b00100 @ rs1 @ encdec_rounding_mode(rm) @ rd @ 0b101_0011  if (haveFExt() & haveZfa())

mapping clause assembly = RISCV_FROUND_S(rs1, rm, rd)
  <-> "fround.s" ^ spc() ^ freg_name(rd)
                 ^ spc() ^ freg_name(rs1)
                 ^ spc() ^ frm_mnemonic(rm)

function clause execute (RISCV_FROUND_S(rs1, rm, rd)) = {
  let rs1_val_S = nan_unbox_S(F(rs1));
  let fflags = fcsr.FFLAGS();

  match (select_instr_or_fcsr_rm(rm)) {
    None() => { handle_illegal(); RETIRE_FAIL },
    Some(rm') => {
      let rm_3b =  encdec_rounding_mode(rm');

      let (result_fflags, result_F) = if (f_is_NaN_S(rs1_val_S))        then (nvFlag(), rs1_val_S)
      else if (f_is_pos_inf_S(rs1_val_S)  | f_is_neg_inf_S(rs1_val_S))  then (fflags, rs1_val_S)
      else if (f_is_pos_zero_S(rs1_val_S) | f_is_neg_zero_S(rs1_val_S)) then (fflags, rs1_val_S)
      else {
        let (_, rd_val_S) = riscv_f32ToI32(rm_3b, rs1_val_S);
        let (_, rd_val_S) = riscv_i32ToF32(rm_3b, rd_val_S);
        (fflags, rd_val_S)
      };

      write_fflags(result_fflags);
      F(rd) = nan_box_S(result_F);
      RETIRE_SUCCESS
    }
  }
}

/* FROUNDNX.S */

union clause ast = RISCV_FROUNDNX_S : (regidx, rounding_mode, regidx)

mapping clause encdec = RISCV_FROUNDNX_S(rs1, rm, rd)                         if (haveFExt() & haveZfa())
  <-> 0b010_0000 @ 0b00101 @ rs1 @ encdec_rounding_mode(rm) @ rd @ 0b101_0011 if (haveFExt() & haveZfa())

mapping clause assembly = RISCV_FROUNDNX_S(rs1, rm, rd)
  <-> "froundnx.s" ^ spc() ^ freg_name(rd)
                   ^ spc() ^ freg_name(rs1)
                   ^ spc() ^ frm_mnemonic(rm)

function clause execute (RISCV_FROUNDNX_S(rs1, rm, rd)) = {
  let rs1_val_S = nan_unbox_S(F(rs1));
  let fflags = fcsr.FFLAGS();

  match (select_instr_or_fcsr_rm(rm)) {
    None() => { handle_illegal(); RETIRE_FAIL },
    Some(rm') => {
      let rm_3b =  encdec_rounding_mode(rm');

      let (result_fflags, result_F) = if (f_is_NaN_S(rs1_val_S))        then (nvFlag(), rs1_val_S)
      else if (f_is_pos_inf_S(rs1_val_S)  | f_is_neg_inf_S(rs1_val_S))  then (fflags, rs1_val_S)
      else if (f_is_pos_zero_S(rs1_val_S) | f_is_neg_zero_S(rs1_val_S)) then (fflags, rs1_val_S)
      else {
        let (_, rd_val_S) = riscv_f32ToI32(rm_3b, rs1_val_S);
        let (_, rd_val_S) = riscv_i32ToF32(rm_3b, rd_val_S);

        if (rs1_val_S != rd_val_S) then (nxFlag(), rd_val_S)
        else                            (fflags, rd_val_S)
      };

      write_fflags(result_fflags);
      F(rd) = nan_box_S(result_F);
      RETIRE_SUCCESS
    }
  }
}

/* FROUND.D */

union clause ast = RISCV_FROUND_D : (regidx, rounding_mode, regidx)

mapping clause encdec = RISCV_FROUND_D(rs1, rm, rd)                            if (haveDExt() & haveZfa())
  <-> 0b010_0001 @ 0b00100 @ rs1 @ encdec_rounding_mode(rm) @ rd @ 0b101_0011  if (haveDExt() & haveZfa())

mapping clause assembly = RISCV_FROUND_D(rs1, rm, rd)
  <-> "fround.d" ^ spc() ^ freg_name(rd)
                 ^ spc() ^ freg_name(rs1)
                 ^ spc() ^ frm_mnemonic(rm)

function clause execute (RISCV_FROUND_D(rs1, rm, rd)) = {
  let rs1_val_D = F(rs1);
  let fflags = fcsr.FFLAGS();

  match (select_instr_or_fcsr_rm(rm)) {
    None() => { handle_illegal(); RETIRE_FAIL },
    Some(rm') => {
      let rm_3b =  encdec_rounding_mode(rm');

      let (result_fflags, result_F) = if (f_is_NaN_D(rs1_val_D))        then (nvFlag(), rs1_val_D)
      else if (f_is_pos_inf_D(rs1_val_D)  | f_is_neg_inf_D(rs1_val_D))  then (fflags, rs1_val_D)
      else if (f_is_pos_zero_D(rs1_val_D) | f_is_neg_zero_D(rs1_val_D)) then (fflags, rs1_val_D)
      else {
        let (_, rd_val_D) = riscv_f64ToI64(rm_3b, rs1_val_D);
        let (_, rd_val_D) = riscv_i64ToF64(rm_3b, rd_val_D);
        (fflags, rd_val_D)
      };

      write_fflags(result_fflags);
      F(rd) = result_F;
      RETIRE_SUCCESS
    }
  }
}

/* FROUNDNX.D */

union clause ast = RISCV_FROUNDNX_D : (regidx, rounding_mode, regidx)

mapping clause encdec = RISCV_FROUNDNX_D(rs1, rm, rd)                         if (haveDExt() & haveZfa())
  <-> 0b010_0001 @ 0b00101 @ rs1 @ encdec_rounding_mode(rm) @ rd @ 0b101_0011 if (haveDExt() & haveZfa())

mapping clause assembly = RISCV_FROUNDNX_D(rs1, rm, rd)
  <-> "froundnx.d" ^ spc() ^ freg_name(rd)
                   ^ spc() ^ freg_name(rs1)
                   ^ spc() ^ frm_mnemonic(rm)

function clause execute (RISCV_FROUNDNX_D(rs1, rm, rd)) = {
  let rs1_val_D = F(rs1);
  let fflags = fcsr.FFLAGS();

  match (select_instr_or_fcsr_rm(rm)) {
    None() => { handle_illegal(); RETIRE_FAIL },
    Some(rm') => {
      let rm_3b =  encdec_rounding_mode(rm');

      let (result_fflags, result_F) = if (f_is_NaN_D(rs1_val_D))        then (nvFlag(), rs1_val_D)
      else if (f_is_pos_inf_D(rs1_val_D)  | f_is_neg_inf_D(rs1_val_D))  then (fflags, rs1_val_D)
      else if (f_is_pos_zero_D(rs1_val_D) | f_is_neg_zero_D(rs1_val_D)) then (fflags, rs1_val_D)
      else {
        let (_, rd_val_D) = riscv_f64ToI64(rm_3b, rs1_val_D);
        let (_, rd_val_D) = riscv_i64ToF64(rm_3b, rd_val_D);

        if (rs1_val_D != rd_val_D) then (nxFlag(), rd_val_D)
        else                            (fflags, rd_val_D)
      };

      write_fflags(result_fflags);
      F(rd) = result_F;
      RETIRE_SUCCESS
    }
  }
}

/* FMVH.X.D */

union clause ast = RISCV_FMVH_X_D : (regidx, regidx)

mapping clause encdec   = RISCV_FMVH_X_D(rs1, rd)           if (haveDExt() & haveZfa() & in32BitMode())
  <-> 0b111_0001 @ 0b00001 @ rs1 @ 0b000 @ rd @ 0b101_0011  if (haveDExt() & haveZfa() & in32BitMode())

mapping clause assembly = RISCV_FMVH_X_D(rs1, rd)
  <-> "fmvh.x.d" ^ spc() ^ reg_name(rd)
                 ^ spc() ^ freg_name(rs1)

function clause execute (RISCV_FMVH_X_D(rs1, rd)) = {
  let rs1_val_D           = F(rs1)[63..32];
  let rd_val_X : xlenbits = EXTS(rs1_val_D);
  X(rd)                   = rd_val_X;
  RETIRE_SUCCESS
}

/* FMVP.X.D */

union clause ast = RISCV_FMVP_D_X : (regidx, regidx, regidx)

mapping clause encdec = RISCV_FMVP_D_X(rs2, rs1, rd)        if (haveDExt() & haveZfa() & in32BitMode())
  <-> 0b101_1001 @ rs2 @ rs1 @ 0b000 @ rd @ 0b101_0011      if (haveDExt() & haveZfa() & in32BitMode())

mapping clause assembly = RISCV_FMVP_D_X(rs2, rs1, rd)
  <-> "fmvp.d.x" ^ spc() ^ freg_name(rd)
                 ^ spc() ^ reg_name(rs1)
                 ^ spc() ^ reg_name(rs2)

function clause execute (RISCV_FMVP_D_X(rs2, rs1, rd)) = {
  let rs1_val_X     = X(rs1)[31..0];
  let rs2_val_X     = X(rs2)[31..0];

  /* Concatenate the two values using '@' operator */
  /* e.g. */
  /*   rs1 = 0x01234567 */
  /*   rs2 = 0x89abcdef */
  /*   rd  = rs1 @ rs2 => 0x89abcdef01234567 */
  let rd_val_D      = rs2_val_X @ rs1_val_X;

  F(rd)             = rd_val_D;
  RETIRE_SUCCESS
}

/* FLEQ.H */

union clause ast = RISCV_FLEQ_H : (regidx, regidx, regidx)

mapping clause encdec = RISCV_FLEQ_H(rs2, rs1, rd)               if (haveZfh() & haveZfa())
  <-> 0b101_0010 @ rs2 @ rs1 @ 0b100 @ rd @ 0b101_0011           if (haveZfh() & haveZfa())

mapping clause assembly = RISCV_FLEQ_H(rs2, rs1, rd)
  <-> "fleq.h" ^ spc() ^ freg_name(rd)
               ^ spc() ^ freg_name(rs1)
               ^ spc() ^ freg_name(rs2)

function clause execute(RISCV_FLEQ_H(rs2, rs1, rd)) = {
  let rs1_val_H = nan_unbox_H(F(rs1));
  let rs2_val_H = nan_unbox_H(F(rs2));

  let (_, rd_val) : (bits_fflags, bool) =
      riscv_f16Le   (rs1_val_H, rs2_val_H);

  X(rd) = EXTZ(bool_to_bits(rd_val));
  RETIRE_SUCCESS
}

/* FLTQ.H */

union clause ast = RISCV_FLTQ_H : (regidx, regidx, regidx)

mapping clause encdec = RISCV_FLTQ_H(rs2, rs1, rd)               if (haveZfh() & haveZfa())
  <-> 0b101_0010 @ rs2 @ rs1 @ 0b101 @ rd @ 0b101_0011           if (haveZfh() & haveZfa())

mapping clause assembly = RISCV_FLTQ_H(rs2, rs1, rd)
  <-> "fltq.h" ^ spc() ^ freg_name(rd)
               ^ spc() ^ freg_name(rs1)
               ^ spc() ^ freg_name(rs2)

function clause execute(RISCV_FLTQ_H(rs2, rs1, rd)) = {
  let rs1_val_H = nan_unbox_H(F(rs1));
  let rs2_val_H = nan_unbox_H(F(rs2));

  let (_, rd_val) : (bits_fflags, bool) =
      riscv_f16Lt   (rs1_val_H, rs2_val_H);

  X(rd) = EXTZ(bool_to_bits(rd_val));
  RETIRE_SUCCESS
}

/* FLEQ.S */

union clause ast = RISCV_FLEQ_S : (regidx, regidx, regidx)

mapping clause encdec = RISCV_FLEQ_S(rs2, rs1, rd)               if (haveFExt() & haveZfa())
  <-> 0b101_0000 @ rs2 @ rs1 @ 0b100 @ rd @ 0b101_0011           if (haveFExt() & haveZfa())

mapping clause assembly = RISCV_FLEQ_S(rs2, rs1, rd)
  <-> "fleq.s" ^ spc() ^ freg_name(rd)
               ^ spc() ^ freg_name(rs1)
               ^ spc() ^ freg_name(rs2)

function clause execute(RISCV_FLEQ_S(rs2, rs1, rd)) = {
  let rs1_val_S = nan_unbox_S(F(rs1));
  let rs2_val_S = nan_unbox_S(F(rs2));

  let (_, rd_val) : (bits_fflags, bool) =
      riscv_f32Le   (rs1_val_S, rs2_val_S);

  X(rd) = EXTZ(bool_to_bits(rd_val));
  RETIRE_SUCCESS
}

/* FLTQ.S */

union clause ast = RISCV_FLTQ_S : (regidx, regidx, regidx)

mapping clause encdec = RISCV_FLTQ_S(rs2, rs1, rd)               if (haveFExt() & haveZfa())
  <-> 0b101_0000 @ rs2 @ rs1 @ 0b101 @ rd @ 0b101_0011           if (haveFExt() & haveZfa())

mapping clause assembly = RISCV_FLTQ_S(rs2, rs1, rd)
  <-> "fltq.s" ^ spc() ^ freg_name(rd)
               ^ spc() ^ freg_name(rs1)
               ^ spc() ^ freg_name(rs2)

function clause execute(RISCV_FLTQ_S(rs2, rs1, rd)) = {
  let rs1_val_S = nan_unbox_S(F(rs1));
  let rs2_val_S = nan_unbox_S(F(rs2));

  let (_, rd_val) : (bits_fflags, bool) =
      riscv_f32Lt   (rs1_val_S, rs2_val_S);

  X(rd) = EXTZ(bool_to_bits(rd_val));
  RETIRE_SUCCESS
}


/* FLEQ.D */

union clause ast = RISCV_FLEQ_D : (regidx, regidx, regidx)

mapping clause encdec = RISCV_FLEQ_D(rs2, rs1, rd)               if (haveDExt() & haveZfa())
  <-> 0b101_0001 @ rs2 @ rs1 @ 0b100 @ rd @ 0b101_0011           if (haveDExt() & haveZfa())

mapping clause assembly = RISCV_FLEQ_D(rs2, rs1, rd)
  <-> "fleq.d" ^ spc() ^ freg_name(rd)
               ^ spc() ^ freg_name(rs1)
               ^ spc() ^ freg_name(rs2)

function clause execute(RISCV_FLEQ_D(rs2, rs1, rd)) = {
  let rs1_val_D = F(rs1);
  let rs2_val_D = F(rs2);

  let (_, rd_val) : (bits_fflags, bool) =
      riscv_f64Le   (rs1_val_D, rs2_val_D);

  X(rd) = EXTZ(bool_to_bits(rd_val));
  RETIRE_SUCCESS
}

/* FLTQ.D */

union clause ast = RISCV_FLTQ_D : (regidx, regidx, regidx)

mapping clause encdec = RISCV_FLTQ_D(rs2, rs1, rd)               if (haveDExt() & haveZfa())
  <-> 0b101_0001 @ rs2 @ rs1 @ 0b101 @ rd @ 0b101_0011           if (haveDExt() & haveZfa())

mapping clause assembly = RISCV_FLTQ_D(rs2, rs1, rd)
  <-> "fltq.d" ^ spc() ^ freg_name(rd)
               ^ spc() ^ freg_name(rs1)
               ^ spc() ^ freg_name(rs2)

function clause execute(RISCV_FLTQ_D(rs2, rs1, rd)) = {
  let rs1_val_D = F(rs1);
  let rs2_val_D = F(rs2);

  let (_, rd_val) : (bits_fflags, bool) =
      riscv_f64Lt   (rs1_val_D, rs2_val_D);

  X(rd) = EXTZ(bool_to_bits(rd_val));
  RETIRE_SUCCESS
}
