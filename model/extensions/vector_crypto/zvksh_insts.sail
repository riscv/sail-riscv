// =======================================================================================
// This Sail RISC-V architecture model, comprising all files and
// directories except where otherwise noted is subject the BSD
// two-clause license in the LICENSE file.
//
// SPDX-License-Identifier: BSD-2-Clause
// =======================================================================================

function clause currentlyEnabled(Ext_Zvksh) = hartSupports(Ext_Zvksh) & currentlyEnabled(Ext_Zve32x)

union clause instruction = VSM3ME_VV : (vregidx, vregidx, vregidx)

mapping clause encdec = VSM3ME_VV(vs2, vs1, vd)
  <-> 0b1000001 @ encdec_vreg(vs2) @ encdec_vreg(vs1) @ 0b010 @ encdec_vreg(vd) @ 0b1110111
   when currentlyEnabled(Ext_Zvksh) & get_sew() == 32 & zvk_check_encdec(256, 8) & zvk_valid_reg_overlap(vs2, vd, get_lmul_pow())

function clause execute (VSM3ME_VV(vs2, vs1, vd)) = {
  let 'SEW     = get_sew();
  let LMUL_pow = get_lmul_pow();
  let num_elem = get_num_elem(LMUL_pow, SEW);

  assert(SEW == 32);

  let vs2_val = read_vreg(num_elem, SEW, LMUL_pow, vs2);
  let vs1_val = read_vreg(num_elem, SEW, LMUL_pow, vs1);

  var w : vector(24, bits(32)) = vector_init(zeros());

  let eg_len   = (unsigned(vl) / 8);
  let eg_start = (unsigned(vstart) / 8);

  foreach (i from eg_start to (eg_len - 1)) {
    assert(i * 8 + 7 < num_elem);

    foreach (j from 0 to 7) {
      w[j]     = rev8(vs1_val[i * 8 + j]);
      w[j + 8] = rev8(vs2_val[i * 8 + j]);
    };

    foreach (j from 16 to 23)
      w[j] = zvk_sh_w(w[j - 16], w[j - 9], w[j - 3], w[j - 13], w[j - 6]);

    write_velem_oct_vec(vd, SEW,
      vrev8([w[23], w[22], w[21], w[20], w[19], w[18], w[17], w[16]]), i);
  };

  set_vstart(zeros());
  RETIRE_SUCCESS
}

mapping clause assembly = VSM3ME_VV(vs2, vs1, vd)
  <-> "vsm3me.vv" ^ spc() ^ vreg_name(vd) ^ sep() ^ vreg_name(vs2) ^ sep() ^ vreg_name(vs1)

union clause instruction = VSM3C_VI : (vregidx, bits(5), vregidx)

mapping clause encdec = VSM3C_VI(vs2, uimm, vd)
  <-> 0b1010111 @ encdec_vreg(vs2) @ uimm @ 0b010 @ encdec_vreg(vd) @ 0b1110111
  when currentlyEnabled(Ext_Zvksh) & get_sew() == 32 & zvk_check_encdec(256, 8) & zvk_valid_reg_overlap(vs2, vd, get_lmul_pow())

function clause execute (VSM3C_VI(vs2, uimm, vd)) = {
  let SEW      = get_sew();
  let LMUL_pow = get_lmul_pow();
  let num_elem = get_num_elem(LMUL_pow, SEW);

  assert(SEW == 32);

  let vs2_val = read_vreg(num_elem, SEW, LMUL_pow, vs2);
  let vd_val  = read_vreg(num_elem, SEW, LMUL_pow, vd);

  let rnds = unsigned(uimm);

  let eg_len   = (unsigned(vl) / 8);
  let eg_start = (unsigned(vstart) / 8);

  foreach (i from eg_start to (eg_len - 1)) {
    assert(i * 8 + 7 < num_elem);

    let A_H : vector(8, bits(32)) = vrev8(get_velem_oct_vec(vd_val,  i));
    let w   : vector(8, bits(32)) = vrev8(get_velem_oct_vec(vs2_val, i));

    let x_0 = w[0] ^ w[4];
    let x_1 = w[1] ^ w[5];

    let A1_H1 = zvk_sm3_round(  A_H, w[0], x_0, 2 * rnds);
    let A2_H2 = zvk_sm3_round(A1_H1, w[1], x_1, 2 * rnds + 1);

    write_velem_oct_vec(vd, SEW,
      vrev8([A1_H1[6], A2_H2[6], A1_H1[4], A2_H2[4], A1_H1[2], A2_H2[2], A1_H1[0], A2_H2[0]]), i);
  };

  set_vstart(zeros());
  RETIRE_SUCCESS
}

mapping clause assembly = VSM3C_VI(vs2, uimm, vd)
  <-> "vsm3c.vi" ^ spc() ^ vreg_name(vd) ^ sep() ^ vreg_name(vs2) ^ sep() ^ hex_bits_5(uimm)
