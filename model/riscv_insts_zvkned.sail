/*=======================================================================================*/
/*  This Sail RISC-V architecture model, comprising all files and                        */
/*  directories except where otherwise noted is subject the BSD                          */
/*  two-clause license in the LICENSE file.                                              */
/*                                                                                       */
/*  SPDX-License-Identifier: BSD-2-Clause                                                */
/*=======================================================================================*/
/*
 * Vector Cryptography Extension - NIST Suite: Vector AES Block Cipher
 * ----------------------------------------------------------------------
 */

function clause currentlyEnabled(Ext_Zvkned) = true

val get_velem : forall 'n 'm 'p, 'n > 0 & 'm > 0 & 'p >= 0 & 4 * 'p + 3 < 'n . (vector('n, bits('m)), int('p)) -> bits(4 * 'm)
function get_velem(v, i) = v[4 * i + 3] @ v[4 * i + 2] @ v[4 * i + 1] @ v[4 * i]

val set_velem : forall 'n 'm 'p, 'n > 0 & 'm > 0 & 'p >= 0 & 4 * 'p + 3 < 'n . (vector('n, bits('m)), bits(4 * 'm), int('p)) -> vector('n, bits('m))
function set_velem(s, v, i) = {
  let m = length(v) / 4;
  [s with
    (4 * i) = v[m - 1 .. 0],
    (4 * i + 1) = v[2 * m - 1 .. m],
    (4 * i + 2) = v[3 * m - 1 .. 2 * m],
    (4 * i + 3) = v[4 * m - 1 .. 3 * m],
  ]
}

function aes_rotword(x : bits(32)) -> bits(32) = x[7.. 0] @ x[31..24] @ x[23..16] @ x[15.. 8]

function zvk_check_elements(VLEN : int, num_elem : int, LMUL : int, SEW : int) -> bool = {
  ((unsigned(vl)%num_elem) != 0) | ((unsigned(vstart)%num_elem) != 0) | (LMUL*VLEN) < (num_elem*SEW)
}

function zvk_check_encdec(EGW : int, EGS : int) -> bool = {
  let LMUL_pow = get_lmul_pow();

  (unsigned(vl) % EGS == 0) & (unsigned(vstart) % EGS == 0) & (2 ^ LMUL_pow * VLEN >= 128)
}

val vv_or_vs_index : forall 'n , 0 <= 'n . (suffix_kind , int('n)) -> range(0, 'n)
function vv_or_vs_index(suffix, i) = {
  match suffix {
    Vector_Vector => i,
    Vector_Scalar => 0,
  }
}

mapping vv_or_vs : suffix_kind <-> bits(6) = {
  Vector_Vector <-> 0b101000,
  Vector_Scalar <-> 0b101001,
}

mapping vv_or_vs_mnemonic : suffix_kind <-> string = {
  Vector_Vector <-> "vv",
  Vector_Scalar <-> "vs",
}

/* VAESEF.[VV, VS] */

union clause ast = RISCV_VAESEF : (vregidx, vregidx, suffix_kind)

mapping clause encdec = RISCV_VAESEF(vs2, vd, suffix)
  <-> vv_or_vs(suffix) @ 0b1 @ encdec_vreg(vs2) @ 0b00011 @ 0b010 @ encdec_vreg(vd) @ 0b1110111
  when currentlyEnabled(Ext_Zvkned) & get_sew() == 32 & zvk_check_encdec(128, 4)

mapping clause assembly = RISCV_VAESEF(vs2, vd, suffix)
  <-> "vaesef." ^ vv_or_vs_mnemonic(suffix) ^ spc() ^ vreg_name(vd)
                                            ^ spc() ^ vreg_name(vs2)

function clause execute (RISCV_VAESEF(vs2, vd, suffix)) = {
  let 'SEW = get_sew();
  let LMUL_pow = get_lmul_pow();
  let 'num_elem = get_num_elem(LMUL_pow, SEW);

  assert(SEW == 32);
  let vs2_val = read_vreg(num_elem, SEW, LMUL_pow, vs2);
  let vd_val = read_vreg(num_elem, SEW, LMUL_pow, vd);
  var result : vector('num_elem, bits('SEW)) = vector_init(zeros());

  let eg_len = (unsigned(vl) / 4);
  let eg_start = (unsigned(vstart) / 4);

  foreach (i from eg_start to (eg_len - 1)) {
    assert(0 <= ((i * 4) + 3) & ((i * 4) + 3) < num_elem);

    let vd_state = get_velem(vd_val, i);
    let vs2_key  = get_velem(vs2_val, vv_or_vs_index(suffix, i));
    let sb = aes_subbytes_fwd(vd_state);
    let sr = aes_shift_rows_fwd(sb);
    let ark = sr ^ vs2_key;

    result = set_velem(result, ark, i);
  };

  write_vreg(num_elem, SEW, LMUL_pow, vd, result);
  set_vstart(zeros());
  RETIRE_SUCCESS
}

/* VAESEM.[VV, VS] */

union clause ast = RISCV_VAESEM : (vregidx, vregidx, suffix_kind)

mapping clause encdec = RISCV_VAESEM(vs2, vd, suffix)
  <-> vv_or_vs(suffix) @ 0b1 @ encdec_vreg(vs2) @ 0b00010 @ 0b010 @ encdec_vreg(vd) @ 0b1110111
  when currentlyEnabled(Ext_Zvkned) & get_sew() == 32 & zvk_check_encdec(128, 4)

mapping clause assembly = RISCV_VAESEM(vs2, vd, suffix)
  <-> "vaesem." ^ vv_or_vs_mnemonic(suffix) ^ spc() ^ vreg_name(vd)
                                            ^ sep() ^ vreg_name(vs2)

function clause execute (RISCV_VAESEM(vs2, vd, suffix)) = {
  let 'SEW = get_sew();
  let LMUL_pow = get_lmul_pow();
  let 'num_elem = get_num_elem(LMUL_pow, SEW);

  assert(SEW == 32);
  let vs2_val = read_vreg(num_elem, SEW, LMUL_pow, vs2);
  let vd_val = read_vreg(num_elem, SEW, LMUL_pow, vd);
  var result : vector('num_elem, bits('SEW)) = vector_init(zeros());

  let eg_len = (unsigned(vl) / 4);
  let eg_start = (unsigned(vstart) / 4);

  foreach (i from eg_start to (eg_len - 1)) {
    assert(0 <= ((i * 4) + 3) & ((i * 4) + 3) < num_elem);

    let vd_state = get_velem(vd_val, i);
    let vs2_key  = get_velem(vs2_val, vv_or_vs_index(suffix, i));
    let sb : bits(128) = aes_subbytes_fwd(vd_state);
    let sr : bits(128) = aes_shift_rows_fwd(sb);
    let mix : bits(128) = aes_mixcolumns_fwd(sr);
    let ark : bits(128) = mix ^ vs2_key;

    result = set_velem(result, ark, i);
  };

  write_vreg(num_elem, SEW, LMUL_pow, vd, result);
  set_vstart(zeros());
  RETIRE_SUCCESS
}

/* VAESDF.VV */

union clause ast = RISCV_VAESDF : (vregidx, vregidx, suffix_kind)

mapping clause encdec = RISCV_VAESDF(vs2, vd, suffix)
  <-> vv_or_vs(suffix) @ 0b1 @ encdec_vreg(vs2) @ 0b00001 @ 0b010 @ encdec_vreg(vd) @ 0b1110111
  when currentlyEnabled(Ext_Zvkned) & get_sew() == 32 & zvk_check_encdec(128, 4)

mapping clause assembly = RISCV_VAESDF(vs2, vd, suffix)
  <-> "vaesdf." ^ vv_or_vs_mnemonic(suffix) ^ sep() ^ vreg_name(vd)
                                            ^ sep() ^ vreg_name(vs2)

function clause execute (RISCV_VAESDF(vs2, vd, suffix)) = {
  let 'SEW = get_sew();
  let LMUL_pow = get_lmul_pow();
  let 'num_elem = get_num_elem(LMUL_pow, SEW);

  assert(SEW == 32);
  let vs2_val = read_vreg(num_elem, SEW, LMUL_pow, vs2);
  let vd_val = read_vreg(num_elem, SEW, LMUL_pow, vd);
  var result : vector('num_elem, bits('SEW)) = vector_init(zeros());

  let eg_len = (unsigned(vl) / 4);
  let eg_start = (unsigned(vstart) / 4);

  foreach (i from eg_start to (eg_len - 1)) {
    assert(0 <= ((i * 4) + 3) & ((i * 4) + 3) < num_elem);

    let vd_state = get_velem(vd_val, i);
    let vs2_key  = get_velem(vs2_val, vv_or_vs_index(suffix, i));
    let sr : bits(128) = aes_shift_rows_inv(vd_state);
    let sb : bits(128) = aes_subbytes_inv(sr);
    let ark : bits(128) = sb ^ vs2_key;

    result = set_velem(result, ark, i);
  };

  write_vreg(num_elem, SEW, LMUL_pow, vd, result);
  set_vstart(zeros());
  RETIRE_SUCCESS
}

/* VAESDM.VV */

union clause ast = RISCV_VAESDM : (vregidx, vregidx, suffix_kind)

mapping clause encdec = RISCV_VAESDM(vs2, vd, suffix)
  <-> vv_or_vs(suffix) @ 0b1 @ encdec_vreg(vs2) @ 0b00000 @ 0b010 @ encdec_vreg(vd) @ 0b1110111
  when currentlyEnabled(Ext_Zvkned) & get_sew() == 32 & zvk_check_encdec(128, 4)

mapping clause assembly = RISCV_VAESDM(vs2, vd, suffix)
  <-> "vaesdm." ^ vv_or_vs_mnemonic(suffix) ^ spc() ^ vreg_name(vd)
                                            ^ sep() ^ vreg_name(vs2)

function clause execute (RISCV_VAESDM(vs2, vd, suffix)) = {
  let 'SEW = get_sew();
  let LMUL_pow = get_lmul_pow();
  let 'num_elem = get_num_elem(LMUL_pow, SEW);

  assert(SEW == 32);
  let vs2_val = read_vreg(num_elem, SEW, LMUL_pow, vs2);
  let vd_val = read_vreg(num_elem, SEW, LMUL_pow, vd);
  var result : vector('num_elem, bits('SEW)) = vector_init(zeros());

  let eg_len = (unsigned(vl) / 4);
  let eg_start = (unsigned(vstart) / 4);

  foreach (i from eg_start to (eg_len - 1)) {
    assert(0 <= ((i * 4) + 3) & ((i * 4) + 3) < num_elem);

    let vd_state = get_velem(vd_val, i);
    let vs2_key  = get_velem(vs2_val, vv_or_vs_index(suffix, i));
    let sr : bits(128) = aes_shift_rows_inv(vd_state);
    let sb : bits(128) = aes_subbytes_inv(sr);
    let ark : bits(128) = sb ^ vs2_key;
    let mix : bits(128) = aes_mixcolumns_inv(ark);

    result = set_velem(result, mix, i);
  };

  write_vreg(num_elem, SEW, LMUL_pow, vd, result);
  set_vstart(zeros());
  RETIRE_SUCCESS
}

/* VAESKF1.VI */

union clause ast = RISCV_VAESKF1_VI : (vregidx, bits(5), vregidx)

mapping clause encdec = RISCV_VAESKF1_VI(vs2, rnd, vd)
  <-> 0b1000101 @ encdec_vreg(vs2) @ rnd @ 0b010 @ encdec_vreg(vd) @ 0b1110111
  when currentlyEnabled(Ext_Zvkned) & get_sew() == 32 & zvk_check_encdec(128, 4)

mapping clause assembly = RISCV_VAESKF1_VI(vs2, rnd, vd)
  <-> "vaeskf1.vi" ^ sep() ^ vreg_name(vd)
                   ^ sep() ^ vreg_name(vs2)
                   ^ sep() ^ hex_bits_5(rnd)

function clause execute (RISCV_VAESKF1_VI(vs2, rnd, vd)) = {
  let 'SEW = get_sew();
  let LMUL_pow = get_lmul_pow();
  let 'num_elem = get_num_elem(LMUL_pow, SEW);

  assert(SEW == 32);
  var rnd_val : bits(5) = rnd;
  let vs2_val = read_vreg(num_elem, SEW, LMUL_pow, vs2);
  let vd_val = read_vreg(num_elem, SEW, LMUL_pow, vd);

  if (unsigned(rnd_val[3..0]) > 10) | (unsigned(rnd_val[3..0]) == 0)
  then rnd_val[3] = not_bit(rnd_val[3]);

  let r : bits(4) = rnd_val[3..0] - 1;

  var w : bits(128) = zeros();
  var result : vector('num_elem, bits('SEW)) = vector_init(zeros());

  let eg_len = (unsigned(vl) / 4);
  let eg_start = (unsigned(vstart) / 4);

  foreach (i from eg_start to (eg_len - 1)) {
    assert(0 <= ((i * 4) + 3) & ((i * 4) + 3) < num_elem);
    let current_round_key = get_velem(vs2_val, i);

    w[31..0] = aes_subword_fwd(aes_rotword(current_round_key[127..96]))
             ^ aes_decode_rcon(r)
             ^ current_round_key[31..0];
    w[63..32]  = w[31..0]  ^ current_round_key[63..32];
    w[95..64]  = w[63..32] ^ current_round_key[95..64];
    w[127..96] = w[95..64] ^ current_round_key[127..96];

    result = set_velem(result, w, i);
  };

  write_vreg(num_elem, SEW, LMUL_pow, vd, result);
  set_vstart(zeros());
  RETIRE_SUCCESS
}

/* VAESKF2.VI */

union clause ast = RISCV_VAESKF2_VI : (vregidx, bits(5), vregidx)

mapping clause encdec = RISCV_VAESKF2_VI(vs2, rnd, vd)
  <-> 0b1010101 @ encdec_vreg(vs2) @ rnd @ 0b010 @ encdec_vreg(vd) @ 0b1110111
  when currentlyEnabled(Ext_Zvkned) & get_sew() == 32 & zvk_check_encdec(128, 4)

mapping clause assembly = RISCV_VAESKF2_VI(vs2, rnd, vd)
  <-> "vaeskf2.vi" ^ sep() ^ vreg_name(vd)
                   ^ sep() ^ vreg_name(vs2)
                   ^ sep() ^ hex_bits_5(rnd)

function clause execute (RISCV_VAESKF2_VI(vs2, rnd, vd)) = {
  let 'SEW = get_sew();
  let LMUL_pow = get_lmul_pow();
  let 'num_elem = get_num_elem(LMUL_pow, SEW);

  assert(SEW == 32);
  var rnd_val : bits(4) = rnd[3..0];
  let vs2_val = read_vreg(num_elem, SEW, LMUL_pow, vs2);
  let vd_val = read_vreg(num_elem, SEW, LMUL_pow, vd);

  if (unsigned(rnd_val) < 2) | (unsigned(rnd_val) > 14)
  then rnd_val[3] = not_bit(rnd_val[3]);

  var w : bits(128) = zeros();
  var result : vector('num_elem, bits('SEW)) = vector_init(zeros());

  let eg_len = (unsigned(vl) / 4);
  let eg_start = (unsigned(vstart) / 4);

  foreach (i from eg_start to (eg_len - 1)) {
    assert(0 <= ((i * 4) + 3) & ((i * 4) + 3) < num_elem);

    let current_round_key = get_velem(vs2_val, i);

    let round_key_b = get_velem(vd_val, i);

    w[31..0] = if (rnd_val[0] == bitone)
               then
                 aes_subword_fwd(current_round_key[127..96]) ^ round_key_b[31..0]
               else
                 aes_subword_fwd(aes_rotword(current_round_key[127..96]))
                   ^ aes_decode_rcon((rnd_val >> 1) - 1)
                   ^ round_key_b[31..0];

    w[63..32]  = w[31..0]  ^ round_key_b[63..32];
    w[95..64]  = w[63..32] ^ round_key_b[95..64];
    w[127..96] = w[95..64] ^ round_key_b[127..96];

    result = set_velem(result, w, i);
  };

  write_vreg(num_elem, SEW, LMUL_pow, vd, result);
  set_vstart(zeros());
  RETIRE_SUCCESS
}

/* VAESZ.VS */

union clause ast = RISCV_VAESZ_VS : (vregidx, vregidx)

mapping clause encdec = RISCV_VAESZ_VS(vs2, vd)
  <-> 0b1010011 @ encdec_vreg(vs2) @ 0b00111 @ 0b010 @ encdec_vreg(vd) @ 0b1110111
  when currentlyEnabled(Ext_Zvkned) & get_sew() == 32 & zvk_check_encdec(128, 4)

mapping clause assembly = RISCV_VAESZ_VS(vs2, vd)
  <-> "vaesz.vs" ^ sep() ^ vreg_name(vd)
                 ^ sep() ^ vreg_name(vs2)

function clause execute (RISCV_VAESZ_VS(vs2, vd)) = {
  let 'SEW = get_sew();
  let LMUL_pow = get_lmul_pow();
  let 'num_elem = get_num_elem(LMUL_pow, SEW);

  assert(SEW == 32);
  let vs2_val = read_vreg(num_elem, SEW, LMUL_pow, vs2);
  let vd_val = read_vreg(num_elem, SEW, LMUL_pow, vd);
  var result : vector('num_elem, bits('SEW)) = vector_init(zeros());

  let eg_len = (unsigned(vl) / 4);
  let eg_start = (unsigned(vstart) / 4);

  foreach (i from eg_start to (eg_len - 1)) {
    assert(0 <= ((i * 4) + 3) & ((i * 4) + 3) < num_elem);

    let vd_state = get_velem(vd_val, i);
    let vs2_key  = get_velem(vs2_val, 0);
    let ark : bits(128) = vd_state ^ vs2_key;

    result = set_velem(result, ark, i);
  };

  write_vreg(num_elem, SEW, LMUL_pow, vd, result);
  set_vstart(zeros());
  RETIRE_SUCCESS
}
