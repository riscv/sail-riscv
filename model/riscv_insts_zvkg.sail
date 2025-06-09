/*=======================================================================================*/
/*  This Sail RISC-V architecture model, comprising all files and                        */
/*  directories except where otherwise noted is subject the BSD                          */
/*  two-clause license in the LICENSE file.                                              */
/*                                                                                       */
/*  SPDX-License-Identifier: BSD-2-Clause                                                */
/*=======================================================================================*/

function clause currentlyEnabled(Ext_Zvkg) = hartSupports(Ext_Zvkg) & currentlyEnabled(Ext_V)

function clause currentlyEnabled(Ext_Zvkgs) = hartSupports(Ext_Zvkgs) & currentlyEnabled(Ext_V) & currentlyEnabled(Ext_Zvkg)

union clause ast = VGHSH : (zvk_vghsh_funct6, vregidx, vregidx, vregidx)

mapping encdec_vghsh : zvk_vghsh_funct6 <-> bits(6) = {
  ZVKG_VGHSH_VV <-> 0b101100,
  ZVKGS_VGHSH_VS <-> 0b100011,
}

mapping clause encdec = VGHSH(funct6, vs2, vs1, vd)
  <-> encdec_vghsh(funct6) @ 0b1 @ encdec_vreg(vs2) @ encdec_vreg(vs1) @ 0b010 @ encdec_vreg(vd) @ 0b1110111
  when (currentlyEnabled(Ext_Zvkg) & funct6 == ZVKG_VGHSH_VV | currentlyEnabled(Ext_Zvkgs) & funct6 == ZVKGS_VGHSH_VS) &
   get_sew() == 32 & zvk_check_encdec(128, 4) & (funct6 != ZVKG_VGHSH_VV | zvk_valid_reg_overlap(vs2, vd, get_lmul_pow()))

function clause execute (VGHSH(funct6, vs2, vs1, vd)) = {
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
    var H : bits(128) = match funct6 {
      ZVKG_VGHSH_VV => brev8(get_velem_quad(vs2_val, i)),
      ZVKGS_VGHSH_VS => brev8(get_velem_quad(vs2_val, 0)),
    };

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

mapping vghsh_mnemonic : zvk_vghsh_funct6 <-> string = {
  ZVKG_VGHSH_VV <-> "vghsh.vv",
  ZVKGS_VGHSH_VS <-> "vghsh.vs",
}

mapping clause assembly = VGHSH(funct6, vs2, vs1, vd)
  <-> vghsh_mnemonic(funct6) ^ spc() ^ vreg_name(vd) ^ sep() ^ vreg_name(vs2) ^ sep() ^ vreg_name(vs1)

union clause ast = VGMUL : (zvk_vgmul_funct6, vregidx, vregidx)

mapping encdec_vgmul : zvk_vgmul_funct6 <-> bits(6) = {
  ZVKG_VGMUL_VV <-> 0b101000,
  ZVKGS_VGMUL_VS <-> 0b101001,
}

mapping clause encdec = VGMUL(funct6, vs2, vd)
  <-> encdec_vgmul(funct6) @ 0b1 @ encdec_vreg(vs2) @ 0b10001 @ 0b010 @ encdec_vreg(vd) @ 0b1110111
  when (currentlyEnabled(Ext_Zvkg) & funct6 == ZVKG_VGMUL_VV | currentlyEnabled(Ext_Zvkgs) & funct6 == ZVKGS_VGMUL_VS) &
   get_sew() == 32 & zvk_check_encdec(128, 4) & (funct6 != ZVKGS_VGMUL_VS & zvk_valid_reg_overlap(vs2, vd, get_lmul_pow()))

function clause execute (VGMUL(funct6, vs2, vd)) = {
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
    var H : bits(128) = match funct6 {
      ZVKG_VGMUL_VV => brev8(get_velem_quad(vs2_val, i)),
      ZVKGS_VGMUL_VS => brev8(get_velem_quad(vs2_val, 0)),
    };
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

mapping vgmul_mnemonic : zvk_vgmul_funct6 <-> string = {
  ZVKG_VGMUL_VV <-> "vgmul.vv",
  ZVKGS_VGMUL_VS <-> "vgmul.vs",
}

mapping clause assembly = VGMUL(funct6, vs2, vd)
  <-> vgmul_mnemonic(funct6) ^ spc() ^ vreg_name(vd) ^ sep() ^ vreg_name(vs2)
