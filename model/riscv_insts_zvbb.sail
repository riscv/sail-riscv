/*=======================================================================================*/
/*  This Sail RISC-V architecture model, comprising all files and                        */
/*  directories except where otherwise noted is subject the BSD                          */
/*  two-clause license in the LICENSE file.                                              */
/*                                                                                       */
/*  SPDX-License-Identifier: BSD-2-Clause                                                */
/*=======================================================================================*/

enum clause extension = Ext_Zvbb
function clause extensionEnabled(Ext_Zvbb) = true

mapping vm_name : bits(1) <-> string = {
  0b0 <-> "0",
  0b1 <-> "1"
}

union clause ast = VWSLL_VV : (bits(1), regidx, regidx, regidx)

mapping clause encdec = VWSLL_VV (vm, vs2, vs1, vd) if extensionEnabled(Ext_Zvbb)
  <-> 0b110101 @ vm @ vs2 @ vs1 @ 0b000 @ vd @ 0b1010111 if extensionEnabled(Ext_Zvbb)

mapping clause assembly = VWSLL_VV (vm, vs2, vs1, vd)
  <-> "vwsll.vv" ^ spc() ^ vreg_name(vd) ^ sep() ^ vreg_name(vs2) ^ sep() ^ vreg_name(vs1) ^ sep() ^ vm_name(vm)

function clause execute (VWSLL_VV(vm, vs2, vs1, vd)) = {
  let SEW                     = get_sew();
  let LMUL_pow                = get_lmul_pow();
  let num_elem                = get_num_elem(LMUL_pow, SEW);
  let SEW_widen               = SEW * 2;
  let LMUL_pow_widen          = LMUL_pow + 1;

  let 'n = num_elem;
  let 'm = SEW;
  let 'o = SEW_widen;

  var result      : vector('n, dec, bits('o)) = undefined;
  var mask        : vector('n, dec, bool)     = undefined;
  let vm_val      : vector('n, dec, bool)     = read_vmask(num_elem, vm, 0b00000);
  let vd_val      : vector('n, dec, bits('o)) = read_vreg(num_elem, SEW_widen, LMUL_pow, vd);
  let vs1_val_vec : vector('n, dec, bits('m)) = read_vreg(num_elem, SEW, LMUL_pow, vs1);
  let vs2_val_vec : vector('n, dec, bits('m)) = read_vreg(num_elem, SEW, LMUL_pow, vs2);

  (result, mask)  = init_masked_result(num_elem, SEW_widen, LMUL_pow - 1, vd_val, vm_val);

  foreach (i from 0 to (num_elem - 1)) {
    if mask[i] then {
      let SEW_widen_bits = to_bits(SEW_widen, 'o);
      let vs1_val : bits('o) = zero_extend(vs1_val_vec[i]);
      let vs2_val : bits('o) = zero_extend(vs2_val_vec[i]);
      result[i] = vs2_val << (vs1_val & zero_extend(SEW_widen_bits - 1));
    };
    write_vreg(num_elem, SEW_widen, LMUL_pow, vd, result);
  };
  vstart = zeros();
  RETIRE_SUCCESS
}

union clause ast = VWSLL_VX : (bits(1), regidx, regidx, regidx)

mapping clause encdec = VWSLL_VX (vm, vs2, rs1, vd) if extensionEnabled(Ext_Zvbb)
  <-> 0b110101 @ vm @ vs2 @ rs1 @ 0b100 @ vd @ 0b1010111 if extensionEnabled(Ext_Zvbb)

mapping clause assembly = VWSLL_VX (vm, vs2, rs1, vd)
  <-> "vwsll.vx" ^ spc() ^ vreg_name(vd) ^ sep() ^ vreg_name(vs2) ^ sep() ^ reg_name(rs1) ^ sep() ^ vm_name(vm)

function clause execute (VWSLL_VX(vm, vs2, rs1, vd)) = {
  let SEW                     = get_sew();
  let LMUL_pow                = get_lmul_pow();
  let num_elem                = get_num_elem(LMUL_pow, SEW);
  let SEW_widen               = SEW * 2;
  let LMUL_pow_widen          = LMUL_pow + 1;

  let 'n = num_elem;
  let 'm = SEW;
  let 'o = SEW_widen;

  var result      : vector('n, dec, bits('o)) = undefined;
  var mask        : vector('n, dec, bool)     = undefined;
  let vm_val      : vector('n, dec, bool)     = read_vmask(num_elem, vm, 0b00000);
  let vd_val      : vector('n, dec, bits('o)) = read_vreg(num_elem, SEW_widen, LMUL_pow, vd);
  let rs1_val     : bits('o)                  = zero_extend(get_scalar(rs1, SEW));
  let vs2_val_vec : vector('n, dec, bits('m)) = read_vreg(num_elem, SEW, LMUL_pow, vs2);

  (result, mask)  = init_masked_result(num_elem, SEW_widen, LMUL_pow - 1, vd_val, vm_val);

  foreach (i from 0 to (num_elem - 1)) {
    if mask[i] then {
      let SEW_widen_bits = to_bits(SEW_widen, 'o);
      let vs2_val : bits('o) = zero_extend(vs2_val_vec[i]);
      result[i] = vs2_val << (rs1_val & zero_extend(SEW_widen_bits - 1));
    };
    write_vreg(num_elem, SEW_widen, LMUL_pow, vd, result);
  };
  vstart = zeros();
  RETIRE_SUCCESS
}

union clause ast = VWSLL_VI : (bits(1), regidx, bits(5), regidx)

mapping clause encdec = VWSLL_VI (vm, vs2, uimm, vd) if extensionEnabled(Ext_Zvbb)
  <-> 0b110101 @ vm @ vs2 @ uimm @ 0b011 @ vd @ 0b1010111 if extensionEnabled(Ext_Zvbb)

mapping clause assembly = VWSLL_VI (vm, vs2, uimm, vd)
  <-> "vwsll.vi" ^ spc() ^ vreg_name(vd) ^ sep() ^ vreg_name(vs2) ^ sep() ^ hex_bits_signed_5(uimm) ^ sep() ^ vm_name(vm)

function clause execute (VWSLL_VI(vm, vs2, uimm, vd)) = {
  let SEW                     = get_sew();
  let LMUL_pow                = get_lmul_pow();
  let num_elem = get_num_elem(LMUL_pow, SEW);
  let SEW_widen               = SEW * 2;
  let LMUL_pow_widen          = LMUL_pow + 1;

  let 'n = num_elem;
  let 'm = SEW;
  let 'o = SEW_widen;

  let vm_val  : vector('n, dec, bool)     = read_vmask(num_elem, vm, 0b00000);
  let uimm_val: bits('o)                  = zero_extend(uimm);

  var mask        : vector('n, dec, bool)     = undefined;
  var result      : vector('n, dec, bits('o)) = undefined;
  let vs2_val_vec : vector('n, dec, bits('m)) = read_vreg(num_elem, SEW, LMUL_pow, vs2);
  let vd_val      : vector('n, dec, bits('o)) = read_vreg(num_elem, SEW_widen, LMUL_pow, vd);

  (result, mask)  = init_masked_result(num_elem, SEW_widen, LMUL_pow - 1, vd_val, vm_val);

  foreach (i from 0 to (num_elem - 1)) {
    if mask[i] then {
        let SEW_widen_bits = to_bits(SEW_widen, 'o);
        let vs2_val : bits('o) = zero_extend(vs2_val_vec[i]);
        result[i] = vs2_val << (uimm_val & zero_extend(SEW_widen_bits - 1));
    };
    write_vreg(num_elem, SEW_widen, LMUL_pow, vd, result);
  };
  vstart = zeros();
  RETIRE_SUCCESS
}
