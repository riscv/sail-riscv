/*=======================================================================================*/
/*  This Sail RISC-V architecture model, comprising all files and                        */
/*  directories except where otherwise noted is subject the BSD                          */
/*  two-clause license in the LICENSE file.                                              */
/*                                                                                       */
/*  SPDX-License-Identifier: BSD-2-Clause                                                */
/*=======================================================================================*/

function clause currentlyEnabled(Ext_Zvkg) = hartSupports(Ext_Zvkg) & currentlyEnabled(Ext_V)

union clause instruction = VGHSH_VV : (vregidx, vregidx, vregidx)

mapping clause encdec = VGHSH_VV(vs2, vs1, vd)
  <-> 0b1011001 @ encdec_vreg(vs2) @ encdec_vreg(vs1) @ 0b010 @ encdec_vreg(vd) @ 0b1110111
  when currentlyEnabled(Ext_Zvkg) & get_sew() == 32 & zvk_check_encdec(128, 4)

function clause execute (VGHSH_VV(vs2, vs1, vd)) = {
  let SEW      = get_sew();
  let LMUL_pow = get_lmul_pow();
  let num_elem = get_num_elem(LMUL_pow, SEW);

  assert(SEW == 32);

  let vs2_val = read_vreg(num_elem, SEW, LMUL_pow, vs2);
  let vs1_val = read_vreg(num_elem, SEW, LMUL_pow, vs1);
  let vd_val  = read_vreg(num_elem, SEW, LMUL_pow, vd);

  let eg_len   = (unsigned(vl) / 4);
  let eg_start = (unsigned(vstart) / 4);

  foreach (i from eg_start to (eg_len - 1)) {
    assert(i * 4 + 3 < num_elem);

    let Y : bits(128) = get_velem_quad(vd_val, i);
    let X : bits(128) = get_velem_quad(vs1_val, i);
    var H : bits(128) = brev8(get_velem_quad(vs2_val, i));

    var Z : bits(128) = zeros();
    let S : bits(128) = brev8(Y ^ X);

    foreach (b from 0 to 127) {
      if S[b] == bitone then Z = Z ^ H;

      let reduce = H[127] == bitone;
      H = H << 1;
      if reduce then H = H[127..8] @ (H[7..0] ^ 0x87);
    };

    write_velem_quad(vd, SEW, brev8(Z), i);
  };

  set_vstart(zeros());
  RETIRE_SUCCESS
}

mapping clause assembly = VGHSH_VV(vs2, vs1, vd)
  <-> "vghsh.vv" ^ spc() ^ vreg_name(vd) ^ sep() ^ vreg_name(vs2) ^ sep() ^ vreg_name(vs1)

union clause instruction = VGMUL_VV : (vregidx, vregidx)

mapping clause encdec = VGMUL_VV(vs2, vd)
  <-> 0b1010001 @ encdec_vreg(vs2) @ 0b10001 @ 0b010 @ encdec_vreg(vd) @ 0b1110111
  when currentlyEnabled(Ext_Zvkg) & get_sew() == 32 & zvk_check_encdec(128, 4)

function clause execute (VGMUL_VV(vs2, vd)) = {
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

    let Y : bits(128) = brev8(get_velem_quad(vd_val, i));
    var H : bits(128) = brev8(get_velem_quad(vs2_val, i));
    var Z : bits(128) = zeros();

    foreach (b from 0 to 127) {
      if Y[b] == bitone then Z = Z ^ H;

      let reduce = H[127] == bitone;
      H = H << 1;
      if reduce then H = H[127..8] @ (H[7..0] ^ 0x87);
    };

    write_velem_quad(vd, SEW, brev8(Z), i);
  };

  set_vstart(zeros());
  RETIRE_SUCCESS
}

mapping clause assembly = VGMUL_VV(vs2, vd)
  <-> "vgmul.vv" ^ spc() ^ vreg_name(vd) ^ sep() ^ vreg_name(vs2)
