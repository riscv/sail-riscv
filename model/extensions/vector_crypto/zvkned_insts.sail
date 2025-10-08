// =======================================================================================
// This Sail RISC-V architecture model, comprising all files and
// directories except where otherwise noted is subject the BSD
// two-clause license in the LICENSE file.
//
// SPDX-License-Identifier: BSD-2-Clause
// =======================================================================================

function clause currentlyEnabled(Ext_Zvkned) = hartSupports(Ext_Zvkned) & currentlyEnabled(Ext_Zve32x)

union clause instruction = VAESDF : (zvk_vaesdf_funct6, vregidx, vregidx)

mapping encdec_vaesdf : zvk_vaesdf_funct6 <-> bits(6) = {
  ZVK_VAESDF_VV <-> 0b101000,
  ZVK_VAESDF_VS <-> 0b101001,
}

mapping clause encdec = VAESDF(funct6, vs2, vd)
  <-> encdec_vaesdf(funct6) @ 0b1 @ encdec_vreg(vs2) @ 0b00001 @ 0b010 @ encdec_vreg(vd) @ 0b1110111
  when currentlyEnabled(Ext_Zvkned) & get_sew() == 32 & zvk_check_encdec(128, 4) & (funct6 == ZVK_VAESDF_VV |
  zvk_valid_reg_overlap(vs2, vd, get_lmul_pow()))

function clause execute VAESDF(funct6, vs2, vd) = {
  let SEW      = get_sew();
  let LMUL_pow = get_lmul_pow();
  let num_elem = get_num_elem(LMUL_pow, SEW);

  assert(SEW == 32);

  let vs2_val = read_vreg(num_elem, SEW, LMUL_pow, vs2);
  let vd_val  = read_vreg(num_elem, SEW, LMUL_pow, vd);

  let eg_len   = (unsigned(vl) / 4);
  let eg_start = (unsigned(vstart) / 4);

  foreach (i from eg_start to (eg_len - 1)) {
    assert(i * 4 + 3 < num_elem);

    let state = get_velem_quad(vd_val, i);
    let rkey : bits(128) = match funct6 {
      ZVK_VAESDF_VV => get_velem_quad(vs2_val, i),
      ZVK_VAESDF_VS => get_velem_quad(vs2_val, 0),
    };
    let sr  = aes_shift_rows_inv(state);
    let sb  = aes_subbytes_inv(sr);
    let ark = sb ^ rkey;

    write_velem_quad(vd, SEW, ark, i);
  };

  set_vstart(zeros());
  RETIRE_SUCCESS
}

mapping vaesdf_mnemonic : zvk_vaesdf_funct6 <-> string = {
  ZVK_VAESDF_VV <-> "vaesdf.vv",
  ZVK_VAESDF_VS <-> "vaesdf.vs",
}

mapping clause assembly = VAESDF(funct6, vs2, vd)
  <-> vaesdf_mnemonic(funct6) ^ spc() ^ vreg_name(vd) ^ sep() ^ vreg_name(vs2)

union clause instruction = VAESDM : (zvk_vaesdm_funct6, vregidx, vregidx)

mapping encdec_vaesdm : zvk_vaesdm_funct6 <-> bits(6) = {
  ZVK_VAESDM_VV <-> 0b101000,
  ZVK_VAESDM_VS <-> 0b101001,
}

mapping clause encdec = VAESDM(funct6, vs2, vd)
  <-> encdec_vaesdm(funct6) @ 0b1 @ encdec_vreg(vs2) @ 0b00000 @ 0b010 @ encdec_vreg(vd) @ 0b1110111
  when currentlyEnabled(Ext_Zvkned) & get_sew() == 32 & zvk_check_encdec(128, 4) & (funct6 == ZVK_VAESDM_VV |
  zvk_valid_reg_overlap(vs2, vd, get_lmul_pow()))

function clause execute VAESDM(funct6, vs2, vd) = {
  let SEW      = get_sew();
  let LMUL_pow = get_lmul_pow();
  let num_elem = get_num_elem(LMUL_pow, SEW);

  assert(SEW == 32);

  let vs2_val = read_vreg(num_elem, SEW, LMUL_pow, vs2);
  let vd_val  = read_vreg(num_elem, SEW, LMUL_pow, vd);

  let eg_len   = (unsigned(vl) / 4);
  let eg_start = (unsigned(vstart) / 4);

  foreach (i from eg_start to (eg_len - 1)) {
    assert(i * 4 + 3 < num_elem);

    let state = get_velem_quad(vd_val, i);
    let rkey : bits(128) = match funct6 {
      ZVK_VAESDM_VV => get_velem_quad(vs2_val, i),
      ZVK_VAESDM_VS => get_velem_quad(vs2_val, 0),
    };
    let sr    = aes_shift_rows_inv(state);
    let sb    = aes_subbytes_inv(sr);
    let ark   = sb ^ rkey;
    let mix   = aes_mixcolumns_inv(ark);

    write_velem_quad(vd, SEW, mix, i);
  };

  set_vstart(zeros());
  RETIRE_SUCCESS
}

mapping vaesdm_mnemonic : zvk_vaesdm_funct6 <-> string = {
  ZVK_VAESDM_VV <-> "vaesdm.vv",
  ZVK_VAESDM_VS <-> "vaesdm.vs",
}

mapping clause assembly = VAESDM(funct6, vs2, vd)
  <-> vaesdm_mnemonic(funct6) ^ spc() ^ vreg_name(vd) ^ sep() ^ vreg_name(vs2)

union clause instruction = VAESEF : (zvk_vaesef_funct6, vregidx, vregidx)

mapping encdec_vaesef : zvk_vaesef_funct6 <-> bits(6) = {
  ZVK_VAESEF_VV <-> 0b101000,
  ZVK_VAESEF_VS <-> 0b101001,
}

mapping clause encdec = VAESEF(funct6, vs2, vd)
  <-> encdec_vaesef(funct6) @ 0b1 @ encdec_vreg(vs2) @ 0b00011 @ 0b010 @ encdec_vreg(vd) @ 0b1110111
  when currentlyEnabled(Ext_Zvkned) & get_sew() == 32 & zvk_check_encdec(128, 4) & (funct6 == ZVK_VAESEF_VV |
  zvk_valid_reg_overlap(vs2, vd, get_lmul_pow()))

function clause execute VAESEF(funct6, vs2, vd) = {
  let SEW = get_sew();
  let LMUL_pow = get_lmul_pow();
  let num_elem = get_num_elem(LMUL_pow, SEW);

  assert(SEW == 32);

  let vs2_val = read_vreg(num_elem, SEW, LMUL_pow, vs2);
  let vd_val  = read_vreg(num_elem, SEW, LMUL_pow, vd);

  let eg_len   = (unsigned(vl) / 4);
  let eg_start = (unsigned(vstart) / 4);

  foreach (i from eg_start to (eg_len - 1)) {
    assert(i * 4 + 3 < num_elem);

    let state = get_velem_quad(vd_val, i);
    let rkey : bits(128) = match funct6 {
      ZVK_VAESEF_VV => get_velem_quad(vs2_val, i),
      ZVK_VAESEF_VS => get_velem_quad(vs2_val, 0),
    };
    let sb    = aes_subbytes_fwd(state);
    let sr    = aes_shift_rows_fwd(sb);
    let ark   = sr ^ rkey;

    write_velem_quad(vd, SEW, ark, i);
  };

  set_vstart(zeros());
  RETIRE_SUCCESS
}

mapping vaesef_mnemonic : zvk_vaesef_funct6 <-> string = {
  ZVK_VAESEF_VV <-> "vaesef.vv",
  ZVK_VAESEF_VS <-> "vaesef.vs",
}

mapping clause assembly = VAESEF(funct6, vs2, vd)
  <-> vaesef_mnemonic(funct6) ^ spc() ^ vreg_name(vd) ^ sep() ^ vreg_name(vs2)

union clause instruction = VAESEM : (zvk_vaesem_funct6, vregidx, vregidx)

mapping encdec_vaesem : zvk_vaesem_funct6 <-> bits(6) = {
  ZVK_VAESEM_VV <-> 0b101000,
  ZVK_VAESEM_VS <-> 0b101001,
}

mapping clause encdec = VAESEM(funct6, vs2, vd)
  <-> encdec_vaesem(funct6) @ 0b1 @ encdec_vreg(vs2) @ 0b00010 @ 0b010 @ encdec_vreg(vd) @ 0b1110111
  when currentlyEnabled(Ext_Zvkned) & get_sew() == 32 & zvk_check_encdec(128, 4) & (funct6 == ZVK_VAESEM_VV |
  zvk_valid_reg_overlap(vs2, vd, get_lmul_pow()))

function clause execute VAESEM(funct6, vs2, vd) = {
  let SEW = get_sew();
  let LMUL_pow = get_lmul_pow();
  let num_elem = get_num_elem(LMUL_pow, SEW);

  assert(SEW == 32);

  let vs2_val = read_vreg(num_elem, SEW, LMUL_pow, vs2);
  let vd_val  = read_vreg(num_elem, SEW, LMUL_pow, vd);

  let eg_len   = (unsigned(vl) / 4);
  let eg_start = (unsigned(vstart) / 4);

  foreach (i from eg_start to (eg_len - 1)) {
    assert(i * 4 + 3 < num_elem);

    let state = get_velem_quad(vd_val, i);
    let rkey : bits(128) = match funct6 {
      ZVK_VAESEM_VV => get_velem_quad(vs2_val, i),
      ZVK_VAESEM_VS => get_velem_quad(vs2_val, 0),
    };
    let sb    = aes_subbytes_fwd(state);
    let sr    = aes_shift_rows_fwd(sb);
    let mix   = aes_mixcolumns_fwd(sr);
    let ark   = mix ^ rkey;

    write_velem_quad(vd, SEW, ark, i);
  };

  set_vstart(zeros());
  RETIRE_SUCCESS
}

mapping vaesem_mnemonic : zvk_vaesem_funct6 <-> string = {
  ZVK_VAESEM_VV <-> "vaesem.vv",
  ZVK_VAESEM_VS <-> "vaesem.vs",
}

mapping clause assembly = VAESEM(funct6, vs2, vd)
  <-> vaesem_mnemonic(funct6) ^ spc() ^ vreg_name(vd) ^ sep() ^ vreg_name(vs2)

union clause instruction = VAESKF1_VI : (vregidx, bits(5), vregidx)

mapping clause encdec = VAESKF1_VI(vs2, rnd, vd)
  <-> 0b1000101 @ encdec_vreg(vs2) @ rnd @ 0b010 @ encdec_vreg(vd) @ 0b1110111
  when currentlyEnabled(Ext_Zvkned) & get_sew() == 32 & zvk_check_encdec(128, 4)

function clause execute VAESKF1_VI(vs2, rnd, vd) = {
  let SEW = get_sew();
  let LMUL_pow = get_lmul_pow();
  let num_elem = get_num_elem(LMUL_pow, SEW);

  assert(SEW == 32);

  let vs2_val = read_vreg(num_elem, SEW, LMUL_pow, vs2);
  let vd_val  = read_vreg(num_elem, SEW, LMUL_pow, vd);

  var rnd_val : bits(5) = rnd;

  if (unsigned(rnd_val[3..0]) > 10) | (unsigned(rnd_val[3..0]) == 0)
  then rnd_val[3] = not_bit(rnd_val[3]);

  let r : bits(4) = rnd_val[3..0] - 1;

  var w : vector(4, bits(32)) = vector_init(zeros());

  let eg_len   = (unsigned(vl) / 4);
  let eg_start = (unsigned(vstart) / 4);

  foreach (i from eg_start to (eg_len - 1)) {
    assert(i * 4 + 3 < num_elem);

    let current_round_key = get_velem_quad_vec(vs2_val, i);

    w[0] = aes_subword_fwd(current_round_key[3] >>> 8) ^
           aes_decode_rcon(r) ^ current_round_key[0];
    w[1] = w[0] ^ current_round_key[1];
    w[2] = w[1] ^ current_round_key[2];
    w[3] = w[2] ^ current_round_key[3];

    write_velem_quad_vec(vd, SEW, w, i);
  };

  set_vstart(zeros());
  RETIRE_SUCCESS
}

mapping clause assembly = VAESKF1_VI(vs2, rnd, vd)
  <-> "vaeskf1.vi" ^ spc() ^ vreg_name(vd) ^ sep() ^ vreg_name(vs2) ^ sep() ^ hex_bits_5(rnd)

union clause instruction = VAESKF2_VI : (vregidx, bits(5), vregidx)

mapping clause encdec = VAESKF2_VI(vs2, rnd, vd)
  <-> 0b1010101 @ encdec_vreg(vs2) @ rnd @ 0b010 @ encdec_vreg(vd) @ 0b1110111
  when currentlyEnabled(Ext_Zvkned) & get_sew() == 32 & zvk_check_encdec(128, 4)

function clause execute VAESKF2_VI(vs2, rnd, vd) = {
  let SEW      = get_sew();
  let LMUL_pow = get_lmul_pow();
  let num_elem = get_num_elem(LMUL_pow, SEW);

  assert(SEW == 32);

  let vs2_val = read_vreg(num_elem, SEW, LMUL_pow, vs2);
  let vd_val  = read_vreg(num_elem, SEW, LMUL_pow, vd);

  var rnd_val : bits(4) = rnd[3..0];

  if (unsigned(rnd_val) < 2) | (unsigned(rnd_val) > 14)
  then rnd_val[3] = not_bit(rnd_val[3]);

  var w : vector(4, bits(32)) = vector_init(zeros());

  let eg_len   = (unsigned(vl) / 4);
  let eg_start = (unsigned(vstart) / 4);

  foreach (i from eg_start to (eg_len - 1)) {
    assert(i * 4 + 3 < num_elem);

    let current_round_key = get_velem_quad_vec(vs2_val, i);
    let round_key_b       = get_velem_quad_vec(vd_val, i);

    w[0] = if (rnd_val[0] == bitone)
           then aes_subword_fwd(current_round_key[3]) ^ round_key_b[0]
           else aes_subword_fwd(current_round_key[3] >>> 8) ^
                aes_decode_rcon((rnd_val >> 1) - 1) ^ round_key_b[0];
    w[1] = w[0] ^ round_key_b[1];
    w[2] = w[1] ^ round_key_b[2];
    w[3] = w[2] ^ round_key_b[3];

    write_velem_quad_vec(vd, SEW, w, i)
  };

  set_vstart(zeros());
  RETIRE_SUCCESS
}

mapping clause assembly = VAESKF2_VI(vs2, rnd, vd)
  <-> "vaeskf2.vi" ^ spc() ^ vreg_name(vd) ^ sep() ^ vreg_name(vs2) ^ sep() ^ hex_bits_5(rnd)

union clause instruction = VAESZ_VS : (vregidx, vregidx)

mapping clause encdec = VAESZ_VS(vs2, vd)
  <-> 0b1010011 @ encdec_vreg(vs2) @ 0b00111 @ 0b010 @ encdec_vreg(vd) @ 0b1110111
  when currentlyEnabled(Ext_Zvkned) & get_sew() == 32 & zvk_check_encdec(128, 4) & zvk_valid_reg_overlap(vs2, vd, get_lmul_pow())

function clause execute VAESZ_VS(vs2, vd) = {
  let SEW      = get_sew();
  let LMUL_pow = get_lmul_pow();
  let num_elem = get_num_elem(LMUL_pow, SEW);

  assert(SEW == 32);

  let vs2_val = read_vreg(num_elem, SEW, LMUL_pow, vs2);
  let vd_val  = read_vreg(num_elem, SEW, LMUL_pow, vd);

  let eg_len   = (unsigned(vl) / 4);
  let eg_start = (unsigned(vstart) / 4);

  foreach (i from eg_start to (eg_len - 1)) {
    assert(i * 4 + 3 < num_elem);

    let state = get_velem_quad(vd_val, i);
    let rkey  = get_velem_quad(vs2_val, 0);
    let ark   = state ^ rkey;

    write_velem_quad(vd, SEW, ark, i)
  };

  set_vstart(zeros());
  RETIRE_SUCCESS
}

mapping clause assembly = VAESZ_VS(vs2, vd)
  <-> "vaesz.vs" ^ spc() ^ vreg_name(vd) ^ sep() ^ vreg_name(vs2)
