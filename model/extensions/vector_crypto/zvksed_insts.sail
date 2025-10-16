// =======================================================================================
// This Sail RISC-V architecture model, comprising all files and
// directories except where otherwise noted is subject the BSD
// two-clause license in the LICENSE file.
//
// SPDX-License-Identifier: BSD-2-Clause
// =======================================================================================

function clause currentlyEnabled(Ext_Zvksed) = hartSupports(Ext_Zvksed) & currentlyEnabled(Ext_Zve32x)

union clause instruction = VSM4K_VI : (vregidx, bits(5), vregidx)

$[wavedrom "_ _ _ _ OPMVV _ OP-VE"]
mapping clause encdec = VSM4K_VI(vs2, uimm, vd)
  <-> 0b100001 @ 0b1 @ encdec_vreg(vs2) @ uimm @ 0b010 @ encdec_vreg(vd) @ 0b1110111
  when currentlyEnabled(Ext_Zvksed) & get_sew() == 32 & zvk_check_encdec(128, 4)

function clause execute VSM4K_VI(vs2, uimm, vd) = {
  let SEW      = get_sew();
  let LMUL_pow = get_lmul_pow();
  let num_elem = get_num_elem(LMUL_pow, SEW);

  assert(SEW == 32);

  let vs2_val = read_vreg(num_elem, SEW, LMUL_pow, vs2);

  let rnd = 0b00 @ uimm[2..0];

  let eg_len   = (unsigned(vl) / 4);
  let eg_start = (unsigned(vstart) / 4);

  foreach (i from eg_start to (eg_len - 1)) {
    assert(i * 4 + 3 < num_elem);

    let rk_in = get_velem_quad_vec(vs2_val, i);

    var rk_out : vector(4, bits(32)) = vector_init(zeros());

    var B = rk_in[1] ^ rk_in[2] ^ rk_in[3] ^ zvk_sm4_sbox(rnd << 2);
    var S = zvk_sm4_subword(B);
    rk_out[0] = zvk_round_key(rk_in[0], S);

    B = rk_in[2]  ^ rk_in[3]  ^ rk_out[0] ^ zvk_sm4_sbox(rnd << 2 + 1);
    S = zvk_sm4_subword(B);
    rk_out[1] = zvk_round_key(rk_in[1], S);

    B = rk_in[3]  ^ rk_out[0] ^ rk_out[1] ^ zvk_sm4_sbox(rnd << 2 + 2);
    S = zvk_sm4_subword(B);
    rk_out[2] = zvk_round_key(rk_in[2], S);

    B = rk_out[0] ^ rk_out[1] ^ rk_out[2] ^ zvk_sm4_sbox(rnd << 2 + 3);
    S = zvk_sm4_subword(B);
    rk_out[3] = zvk_round_key(rk_in[3], S);

    write_velem_quad_vec(vd, SEW, rk_out, i);
  };

  set_vstart(zeros());
  RETIRE_SUCCESS
}

mapping clause assembly = VSM4K_VI(vs2, uimm, vd)
  <-> "vsm4k.vi" ^ spc() ^ vreg_name(vd) ^ sep() ^ vreg_name(vs2) ^ sep() ^ hex_bits_5(uimm)

union clause instruction = ZVKSM4RTYPE : (zvk_vsm4r_funct6, vregidx, vregidx)

$[wavedrom "_ _ _ _ OPMVV _ OP-VE"]
mapping clause encdec = ZVKSM4RTYPE(ZVK_VSM4R_VV, vs2, vd)
  <-> 0b101000 @ 0b1 @ encdec_vreg(vs2) @ 0b10000 @ 0b010 @ encdec_vreg(vd) @ 0b1110111
  when currentlyEnabled(Ext_Zvksed) & get_sew() == 32 & zvk_check_encdec(128, 4)

$[wavedrom "_ _ _ _ OPMVV _ OP-VE"]
mapping clause encdec = ZVKSM4RTYPE(ZVK_VSM4R_VS, vs2, vd)
  <-> 0b101001 @ 0b1 @ encdec_vreg(vs2) @ 0b10000 @ 0b010 @ encdec_vreg(vd) @ 0b1110111
  when currentlyEnabled(Ext_Zvksed) & get_sew() == 32 & zvk_check_encdec(128, 4) & zvk_valid_reg_overlap(vs2, vd, get_lmul_pow())

function clause execute ZVKSM4RTYPE(funct6, vs2, vd) = {
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

    let rk_in = if funct6 == ZVK_VSM4R_VV
                then get_velem_quad_vec(vs2_val, i)
                else get_velem_quad_vec(vs2_val, 0);

    let x_in  = get_velem_quad_vec(vd_val, i);

    var x_out : vector(4, bits(32)) = vector_init(zeros());

    var B = x_in[1] ^ x_in[2] ^ x_in[3] ^ rk_in[0];
    var S = zvk_sm4_subword(B);
    x_out[0] = zvk_sm4_round(x_in[0], S);

    B = x_in[2]  ^ x_in[3]  ^ x_out[0] ^ rk_in[1];
    S = zvk_sm4_subword(B);
    x_out[1] = zvk_sm4_round(x_in[1], S);

    B = x_in[3]  ^ x_out[0] ^ x_out[1] ^ rk_in[2];
    S = zvk_sm4_subword(B);
    x_out[2] = zvk_sm4_round(x_in[2], S);

    B = x_out[0] ^ x_out[1] ^ x_out[2] ^ rk_in[3];
    S = zvk_sm4_subword(B);
    x_out[3] = zvk_sm4_round(x_in[3], S);

    write_velem_quad_vec(vd, SEW, x_out, i);
  };

  set_vstart(zeros());
  RETIRE_SUCCESS
}

mapping vsm4r_mnemonic : zvk_vsm4r_funct6 <-> string = {
   ZVK_VSM4R_VV <-> "vsm4r.vv",
   ZVK_VSM4R_VS <-> "vsm4r.vs",
}

mapping clause assembly = ZVKSM4RTYPE(funct6, vs2, vd)
  <-> vsm4r_mnemonic(funct6) ^ spc() ^ vreg_name(vd) ^ sep() ^ vreg_name(vs2)
