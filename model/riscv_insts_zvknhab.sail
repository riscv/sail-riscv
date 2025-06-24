/*=======================================================================================*/
/*  This Sail RISC-V architecture model, comprising all files and                        */
/*  directories except where otherwise noted is subject the BSD                          */
/*  two-clause license in the LICENSE file.                                              */
/*                                                                                       */
/*  SPDX-License-Identifier: BSD-2-Clause                                                */
/*=======================================================================================*/

function clause currentlyEnabled(Ext_Zvknha) = hartSupports(Ext_Zvknha) & currentlyEnabled(Ext_V)
function clause currentlyEnabled(Ext_Zvknhb) = (hartSupports(Ext_Zvknhb) | currentlyEnabled(Ext_Zvkn)) & currentlyEnabled(Ext_V)

union clause instruction = VSHA2MS_VV : (vregidx, vregidx, vregidx)

mapping clause encdec = VSHA2MS_VV(vs2, vs1, vd)
  <-> 0b1011011 @ encdec_vreg(vs2) @ encdec_vreg(vs1) @ 0b010 @ encdec_vreg(vd) @ 0b1110111
  when (currentlyEnabled(Ext_Zvknha) & get_sew() == 32) | (currentlyEnabled(Ext_Zvknhb) & (get_sew() == 32 | get_sew() == 64)) & zvknhab_check_encdec(vs2, vs1, vd)

mapping clause assembly = VSHA2MS_VV(vs2, vs1, vd)
  <-> "vsha2ms.vv" ^ spc() ^ vreg_name(vd) ^ sep() ^ vreg_name(vs2) ^ sep() ^ vreg_name(vs1)

function clause execute (VSHA2MS_VV(vs2, vs1, vd)) = {
  let 'SEW     = get_sew();
  let LMUL_pow = get_lmul_pow();
  let num_elem = get_num_elem(LMUL_pow, SEW);

  assert(SEW == 32 | SEW == 64);

  let vs2_val = read_vreg(num_elem, SEW, LMUL_pow, vs2);
  let vs1_val = read_vreg(num_elem, SEW, LMUL_pow, vs1);
  let vd_val  = read_vreg(num_elem, SEW, LMUL_pow, vd);

  var w : vector(20, bits('SEW)) = vector_init(zeros());

  let eg_len   = (unsigned(vl) / 4);
  let eg_start = (unsigned(vstart) / 4);

  foreach (i from eg_start to (eg_len - 1)) {
    assert(i * 4 + 3 < num_elem);

    w = [w with
      0  = vd_val[i*4],
      1  = vd_val[i*4+1],
      2  = vd_val[i*4+2],
      3  = vd_val[i*4+3],

      4  = vs2_val[i*4],
      9  = vs2_val[i*4+1],
      10 = vs2_val[i*4+2],
      11 = vs2_val[i*4+3],

      12 = vs1_val[i*4],
      13 = vs1_val[i*4+1],
      14 = vs1_val[i*4+2],
      15 = vs1_val[i*4+3]
    ];

    w[16] = zvk_sig1(w[14], SEW) + w[9]  + zvk_sig0(w[1], SEW) + w[0];
    w[17] = zvk_sig1(w[15], SEW) + w[10] + zvk_sig0(w[2], SEW) + w[1];
    w[18] = zvk_sig1(w[16], SEW) + w[11] + zvk_sig0(w[3], SEW) + w[2];
    w[19] = zvk_sig1(w[17], SEW) + w[12] + zvk_sig0(w[4], SEW) + w[3];

    write_velem_quad(vd, SEW, w[19] @ w[18] @ w[17] @ w[16], i);
  };

  set_vstart(zeros());
  RETIRE_SUCCESS
}

union clause instruction = ZVKSHA2TYPE : (zvk_vsha2_funct6, vregidx, vregidx, vregidx)

mapping encdec_vsha2 : zvk_vsha2_funct6 <-> bits(6) = {
  ZVK_VSHA2CH_VV <-> 0b101110,
  ZVK_VSHA2CL_VV <-> 0b101111,
}

mapping clause encdec = ZVKSHA2TYPE(funct6, vs2, vs1, vd)
  <-> encdec_vsha2(funct6) @ 0b1 @ encdec_vreg(vs2) @ encdec_vreg(vs1) @ 0b010 @ encdec_vreg(vd) @ 0b1110111
  when (currentlyEnabled(Ext_Zvknha) & get_sew() == 32) | (currentlyEnabled(Ext_Zvknhb) & (get_sew() == 32 | get_sew() == 64)) & zvknhab_check_encdec(vs2, vs1, vd)

mapping vsha2_mnemonic : zvk_vsha2_funct6 <-> string = {
  ZVK_VSHA2CH_VV <-> "vsha2ch.vv",
  ZVK_VSHA2CL_VV <-> "vsha2cl.vv",
}

mapping clause assembly = ZVKSHA2TYPE(funct6, vs2, vs1, vd)
  <-> vsha2_mnemonic(funct6) ^ spc() ^ vreg_name(vd) ^ sep() ^ vreg_name(vs2) ^ sep() ^ vreg_name(vs1)

function clause execute (ZVKSHA2TYPE(funct6, vs2, vs1, vd)) = {
  let SEW      = get_sew();
  let LMUL_pow = get_lmul_pow();
  let num_elem = get_num_elem(LMUL_pow, SEW);

  assert(SEW == 32 | SEW == 64);

  let vs2_val = read_vreg(num_elem, SEW, LMUL_pow, vs2);
  let vs1_val = read_vreg(num_elem, SEW, LMUL_pow, vs1);
  let vd_val  = read_vreg(num_elem, SEW, LMUL_pow, vd);

  let eg_len   = (unsigned(vl) / 4);
  let eg_start = (unsigned(vstart) / 4);

  foreach (i from eg_start to (eg_len - 1)) {
    assert(i * 4 + 3 < num_elem);

    var f = vs2_val[i*4+0];
    var e = vs2_val[i*4+1];
    var b = vs2_val[i*4+2];
    var a = vs2_val[i*4+3];

    var h = vd_val[i*4+0];
    var g = vd_val[i*4+1];
    var d = vd_val[i*4+2];
    var c = vd_val[i*4+3];

    let message_sched_plus_c = get_velem_quad(vs1_val, i);

    let w0 = if funct6 == ZVK_VSHA2CL_VV
             then message_sched_plus_c[(SEW * 1) - 1 .. 0]
             else message_sched_plus_c[(SEW * 3) - 1 .. (SEW * 2)];

    let w1 = if funct6 == ZVK_VSHA2CL_VV
             then message_sched_plus_c[(SEW * 2) - 1 .. SEW]
             else message_sched_plus_c[(SEW * 4) - 1 .. (SEW * 3)];

    var T1 = h + zvk_sum1(e, SEW) + zvk_ch(e,f,g) + w0;
    var T2 = zvk_sum0(a, SEW) + zvk_maj(a, b, c);

    h  = g;
    g  = f;
    f  = e;
    e  = d + T1;
    d  = c;
    c  = b;
    b  = a;
    a  = T1 + T2;

    T1 = h + zvk_sum1(e, SEW) + zvk_ch(e, f, g) + w1;
    T2 = zvk_sum0(a, SEW) + zvk_maj(a, b, c);
    h  = g;
    g  = f;
    f  = e;
    e  = d + T1;
    d  = c;
    c  = b;
    b  = a;
    a  = T1 + T2;

    write_velem_quad(vd, SEW, a @ b @ e @ f, i);
  };

  set_vstart(zeros());
  RETIRE_SUCCESS
}
