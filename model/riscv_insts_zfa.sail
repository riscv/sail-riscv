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
