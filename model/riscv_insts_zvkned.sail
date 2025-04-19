/*=======================================================================================*/
/*  This Sail RISC-V architecture model, comprising all files and                        */
/*  directories except where otherwise noted is subject the BSD                          */
/*  two-clause license in the LICENSE file.                                              */
/*                                                                                       */
/*  SPDX-License-Identifier: BSD-2-Clause                                                */
/*=======================================================================================*/

function clause currentlyEnabled(Ext_Zvkned) = hartSupports(Ext_Zvkned) & currentlyEnabled(Ext_V)

union clause ast = ZVKVAESDFTYPE : (zvkfunct6, vregidx, vregidx)

mapping clause encdec = ZVKVAESDFTYPE(ZVK_VAESDFVV, vs2, vd)
  <-> 0b1010001 @ encdec_vreg(vs2) @ 0b00001 @ 0b010 @ encdec_vreg(vd) @ 0b1110111
  when currentlyEnabled(Ext_Zvkned) & get_sew() == 32 & zvk_check_encdec(128, 4)

mapping clause encdec = ZVKVAESDFTYPE(ZVK_VAESDFVS, vs2, vd)
  <-> 0b1010011 @ encdec_vreg(vs2) @ 0b00001 @ 0b010 @ encdec_vreg(vd) @ 0b1110111
  when currentlyEnabled(Ext_Zvkned) & get_sew() == 32 & zvk_check_encdec(128, 4) & zvk_valid_reg_overlap(vs2, vd, get_lmul_pow())

function clause execute (ZVKVAESDFTYPE(funct6, vs2, vd)) = {
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
    let rkey  = if funct6 == ZVK_VAESDFVV
                then get_velem_quad(vs2_val, i)
                else get_velem_quad(vs2_val, 0);
    let sr  = aes_shift_rows_inv(state);
    let sb  = aes_subbytes_inv(sr);
    let ark = sb ^ rkey;

    write_velem_quad(vd, SEW, ark, i);
  };

  set_vstart(zeros());
  RETIRE_SUCCESS
}

mapping vaesdf_mnemonic : zvkfunct6 <-> string = {
  ZVK_VAESDFVV <-> "vaesdf.vv",
  ZVK_VAESDFVS <-> "vaesdf.vs",
}

mapping clause assembly = ZVKVAESDFTYPE(funct6, vs2, vd)
  <-> vaesdf_mnemonic(funct6) ^ sep() ^ vreg_name(vd) ^ sep() ^ vreg_name(vs2)

union clause ast = ZVKVAESDMTYPE : (zvkfunct6, vregidx, vregidx)

mapping clause encdec = ZVKVAESDMTYPE(ZVK_VAESDMVV, vs2, vd)
  <-> 0b1010001 @ encdec_vreg(vs2) @ 0b00000 @ 0b010 @ encdec_vreg(vd) @ 0b1110111
  when currentlyEnabled(Ext_Zvkned) & get_sew() == 32 & zvk_check_encdec(128, 4)

mapping clause encdec = ZVKVAESDMTYPE(ZVK_VAESDMVS, vs2, vd)
  <-> 0b1010011 @ encdec_vreg(vs2) @ 0b00000 @ 0b010 @ encdec_vreg(vd) @ 0b1110111
  when currentlyEnabled(Ext_Zvkned) & get_sew() == 32 & zvk_check_encdec(128, 4) & zvk_valid_reg_overlap(vs2, vd, get_lmul_pow())

function clause execute (ZVKVAESDMTYPE(funct6, vs2, vd)) = {
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
    let rkey  = if funct6 == ZVK_VAESDMVV
                then get_velem_quad(vs2_val, i)
                else get_velem_quad(vs2_val, 0);
    let sr    = aes_shift_rows_inv(state);
    let sb    = aes_subbytes_inv(sr);
    let ark   = sb ^ rkey;
    let mix   = aes_mixcolumns_inv(ark);

    write_velem_quad(vd, SEW, mix, i);
  };

  set_vstart(zeros());
  RETIRE_SUCCESS
}

mapping vaesdm_mnemonic : zvkfunct6 <-> string = {
  ZVK_VAESDMVV <-> "vaesdm.vv",
  ZVK_VAESDMVS <-> "vaesdm.vs",
}

mapping clause assembly = ZVKVAESDMTYPE(funct6, vs2, vd)
  <-> vaesdm_mnemonic(funct6) ^ spc() ^ vreg_name(vd) ^ sep() ^ vreg_name(vs2)

union clause ast = ZVKVAESEFTYPE : (zvkfunct6, vregidx, vregidx)

mapping clause encdec = ZVKVAESEFTYPE(ZVK_VAESEFVV, vs2, vd)
  <-> 0b1010001 @ encdec_vreg(vs2) @ 0b00011 @ 0b010 @ encdec_vreg(vd) @ 0b1110111
  when currentlyEnabled(Ext_Zvkned) & get_sew() == 32 & zvk_check_encdec(128, 4)

mapping clause encdec = ZVKVAESEFTYPE(ZVK_VAESEFVS, vs2, vd)
  <-> 0b1010011 @ encdec_vreg(vs2) @ 0b00011 @ 0b010 @ encdec_vreg(vd) @ 0b1110111
  when currentlyEnabled(Ext_Zvkned) & get_sew() == 32 & zvk_check_encdec(128, 4) & zvk_valid_reg_overlap(vs2, vd, get_lmul_pow())

function clause execute (ZVKVAESEFTYPE(funct6, vs2, vd)) = {
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
    let rkey  = if funct6 == ZVK_VAESEFVV
                then get_velem_quad(vs2_val, i)
                else get_velem_quad(vs2_val, 0);
    let sb    = aes_subbytes_fwd(state);
    let sr    = aes_shift_rows_fwd(sb);
    let ark   = sr ^ rkey;

    write_velem_quad(vd, SEW, ark, i);
  };

  set_vstart(zeros());
  RETIRE_SUCCESS
}

mapping vaesef_mnemonic : zvkfunct6 <-> string = {
  ZVK_VAESEFVV <-> "vaesef.vv",
  ZVK_VAESEFVS <-> "vaesef.vs",
}

mapping clause assembly = ZVKVAESEFTYPE(funct6, vs2, vd)
  <-> vaesef_mnemonic(funct6) ^ spc() ^ vreg_name(vd) ^ spc() ^ vreg_name(vs2)

union clause ast = ZVKVAESEMTYPE : (zvkfunct6, vregidx, vregidx)

mapping clause encdec = ZVKVAESEMTYPE(ZVK_VAESEMVV, vs2, vd)
  <-> 0b1010001 @ encdec_vreg(vs2) @ 0b00010 @ 0b010 @ encdec_vreg(vd) @ 0b1110111
  when currentlyEnabled(Ext_Zvkned) & get_sew() == 32 & zvk_check_encdec(128, 4)

mapping clause encdec = ZVKVAESEMTYPE(ZVK_VAESEMVS, vs2, vd)
  <-> 0b1010011 @ encdec_vreg(vs2) @ 0b00010 @ 0b010 @ encdec_vreg(vd) @ 0b1110111
  when currentlyEnabled(Ext_Zvkned) & get_sew() == 32 & zvk_check_encdec(128, 4) & zvk_valid_reg_overlap(vs2, vd, get_lmul_pow())

function clause execute (ZVKVAESEMTYPE(funct6, vs2, vd)) = {
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
    let rkey  = if funct6 == ZVK_VAESEMVV
                then get_velem_quad(vs2_val, i)
                else get_velem_quad(vs2_val, 0);
    let sb    = aes_subbytes_fwd(state);
    let sr    = aes_shift_rows_fwd(sb);
    let mix   = aes_mixcolumns_fwd(sr);
    let ark   = mix ^ rkey;

    write_velem_quad(vd, SEW, ark, i);
  };

  set_vstart(zeros());
  RETIRE_SUCCESS
}

mapping vaesem_mnemonic : zvkfunct6 <-> string = {
  ZVK_VAESEMVV <-> "vaesem.vv",
  ZVK_VAESEMVS <-> "vaesem.vs",
}

mapping clause assembly = ZVKVAESEMTYPE(funct6, vs2, vd)
  <-> vaesem_mnemonic(funct6) ^ spc() ^ vreg_name(vd) ^ sep() ^ vreg_name(vs2)

union clause ast = VAESKF1_VI : (vregidx, bits(5), vregidx)

mapping clause encdec = VAESKF1_VI(vs2, rnd, vd)
  <-> 0b1000101 @ encdec_vreg(vs2) @ rnd @ 0b010 @ encdec_vreg(vd) @ 0b1110111
  when currentlyEnabled(Ext_Zvkned) & get_sew() == 32 & zvk_check_encdec(128, 4)

function clause execute (VAESKF1_VI(vs2, rnd, vd)) = {
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

    w[0] = aes_subword_fwd(aes_rotword(current_round_key[3])) ^
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
  <-> "vaeskf1.vi" ^ sep() ^ vreg_name(vd) ^ sep() ^ vreg_name(vs2) ^ sep() ^ hex_bits_5(rnd)

union clause ast = VAESKF2_VI : (vregidx, bits(5), vregidx)

mapping clause encdec = VAESKF2_VI(vs2, rnd, vd)
  <-> 0b1010101 @ encdec_vreg(vs2) @ rnd @ 0b010 @ encdec_vreg(vd) @ 0b1110111
  when currentlyEnabled(Ext_Zvkned) & get_sew() == 32 & zvk_check_encdec(128, 4)

function clause execute (VAESKF2_VI(vs2, rnd, vd)) = {
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
           else aes_subword_fwd(aes_rotword(current_round_key[3])) ^
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
  <-> "vaeskf2.vi" ^ sep() ^ vreg_name(vd) ^ sep() ^ vreg_name(vs2) ^ sep() ^ hex_bits_5(rnd)

union clause ast = VAESZ_VS : (vregidx, vregidx)

mapping clause encdec = VAESZ_VS(vs2, vd)
  <-> 0b1010011 @ encdec_vreg(vs2) @ 0b00111 @ 0b010 @ encdec_vreg(vd) @ 0b1110111
  when currentlyEnabled(Ext_Zvkned) & get_sew() == 32 & zvk_check_encdec(128, 4) & zvk_valid_reg_overlap(vs2, vd, get_lmul_pow())

function clause execute (VAESZ_VS(vs2, vd)) = {
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
  <-> "vaesz.vs" ^ sep() ^ vreg_name(vd) ^ sep() ^ vreg_name(vs2)
