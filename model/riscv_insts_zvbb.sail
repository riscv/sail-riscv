/*=======================================================================================*/
/*  This Sail RISC-V architecture model, comprising all files and                        */
/*  directories except where otherwise noted is subject the BSD                          */
/*  two-clause license in the LICENSE file.                                              */
/*                                                                                       */
/*  SPDX-License-Identifier: BSD-2-Clause                                                */
/*=======================================================================================*/

enum clause extension = Ext_Zvbb
function clause extensionEnabled(Ext_Zvbb) = true

union clause ast = VANDN_VV : (bits(1), regidx, regidx, regidx)

mapping clause encdec = VANDN_VV (vm, vs2, vs1, vd) if extensionEnabled(Ext_Zvbb)
  <-> 0b000001 @ vm @ vs2 @ vs1 @ 0b010 @ vd @ 0b1010111 if extensionEnabled(Ext_Zvbb)

mapping clause assembly = VCLMUL_VV (vm, vs2, vs1, vd)
  <-> "vandn.vv" ^ spc() ^ vreg_name(vd) ^ sep() ^ vreg_name(vs2) ^ sep() ^ vreg_name(vs1) ^ sep() ^ vm_name(vm)

function clause execute (VCLMUL_VV(vm, vs2, vs1, vd)) = {
  let SEW                     = get_sew();
  let LMUL_pow                = get_lmul_pow();
  let num_elem                = get_num_elem(LMUL_pow, SEW);

  let 'n = num_elem;
  let 'm = SEW;

  var result  : vector('n, dec, bits('m)) = undefined;
  var mask    : vector('n, dec, bool)     = undefined;
  let vs1_val : vector('n, dec, bits('m)) = read_vreg(num_elem, SEW, LMUL_pow, vs1);
  let vs2_val : vector('n, dec, bits('m)) = read_vreg(num_elem, SEW, LMUL_pow, vs2);

  (result, mask) = init_masked_result(num_elem, SEW, LMUL_pow, vd_val, vm_val);

  foreach (i from 0 to (num_elem - 1)) {
    if mask[i] then {
        result[i] = vs2_val[i] & ~vs1_val[i];
    };
    write_vreg(num_elem, SEW, LMUL_pow, vd, result);
  };
  vstart = zeros();
  RETIRE_SUCCESS
}

union clause ast = VANDN_VX : (bits(1), regidx, regidx, regidx)

mapping clause encdec = VANDN_VX (vm, vs2, rs1, vd) if extensionEnabled(Ext_Zvbb)
  <-> 0b000001 @ vm @ vs2 @ rs1 @ 0b110 @ vd @ 0b1010111 if extensionEnabled(Ext_Zvbb)

mapping clause assembly = VCLMUL_VX (vm, vs2, rs1, vd)
  <-> "vandn.vx" ^ spc() ^ vreg_name(vd) ^ sep() ^ vreg_name(vs2) ^ sep() ^ vreg_name(rs1) ^ sep() ^ vm_name(vm)

function clause execute (VCLMUL_VX(vm, vs2, rs1, vd)) = {
  let SEW                     = get_sew();
  let LMUL_pow                = get_lmul_pow();
  let num_elem                = get_num_elem(LMUL_pow, SEW);

  let 'n = num_elem;
  let 'm = SEW;

  var result  : vector('n, dec, bits('m)) = undefined;
  var mask    : vector('n, dec, bool)     = undefined;
  let vs2_val : vector('n, dec, bits('m)) = read_vreg(num_elem, SEW, LMUL_pow, vs2);
  let rs1_val : vector('n, dec, bits('m)) = read_vreg(num_elem, SEW, LMUL_pow, rs1);

  (result, mask) = init_masked_result(num_elem, SEW, LMUL_pow, vd_val, vm_val);

  foreach (i from 0 to (num_elem - 1)) {
    if mask[i] then {
      result[i] = vs2_val[i] & ~rs1_val[i];
    };
    write_vreg(num_elem, SEW, LMUL_pow, vd, result);
  };
  vstart = zeros();
  RETIRE_SUCCESS
}

union clause ast = VBREV_V : (bits(1), regidx, regidx)

mapping clause encdec = VBREV_V (vm, vs2, vd) if extensionEnabled(Ext_Zvbb)
  <-> 0b010010 @ vm @ vs2 @ 01010 @ 0b010 @ vd @ 0b1010111 if extensionEnabled(Ext_Zvbb)

mapping clause assembly = VBREV_V (vm, vs2, vd)
  <-> "vbrev.v" ^ spc() ^ vreg_name(vd) ^ sep() ^ vreg_name(vs2) ^ sep() ^ vm_name(vm)

function clause execute (VBREV_V(vm, vs2, vd)) = {
  let SEW                     = get_sew();
  let LMUL_pow                = get_lmul_pow();
  let num_elem                = get_num_elem(LMUL_pow, SEW);

  let 'n = num_elem;
  let 'm = SEW;

  var result  : vector('n, dec, bits('m)) = undefined;
  var mask    : vector('n, dec, bool)     = undefined;
  let vs2_val : vector('n, dec, bits('m)) = read_vreg(num_elem, SEW, LMUL_pow, vs2);

  (result, mask) = init_masked_result(num_elem, SEW, LMUL_pow, vd_val, vm_val);

  foreach (i from 0 to (num_elem - 1)) {
    if mask[i] then {
      result[i] = reverse(vs2_val[i]);
    };
    write_vreg(num_elem, SEW, LMUL_pow, vd, result);
  };
  vstart = zeros();
  RETIRE_SUCCESS
}

union clause ast = VBREV8_V : (bits(1), regidx, regidx)

mapping clause encdec = VBREV8_V (vm, vs2, vd) if extensionEnabled(Ext_Zvbb)
  <-> 0b010010 @ vm @ vs2 @ 01000 @ 0b010 @ vd @ 0b1010111 if extensionEnabled(Ext_Zvbb)

mapping clause assembly = VBREV8_V (vm, vs2, vd)
  <-> "vbrev8.v" ^ spc() ^ vreg_name(vd) ^ sep() ^ vreg_name(vs2) ^ sep() ^ vm_name(vm)

function clause execute (VBREV8_V (vm, vs2, vd)) = {

};
