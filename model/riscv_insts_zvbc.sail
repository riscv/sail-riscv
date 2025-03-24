/*=======================================================================================*/
/*  This Sail RISC-V architecture model, comprising all files and                        */
/*  directories except where otherwise noted is subject the BSD                          */
/*  two-clause license in the LICENSE file.                                              */
/*                                                                                       */
/*  SPDX-License-Identifier: BSD-2-Clause                                                */
/*=======================================================================================*/

function clause extensionEnabled(Ext_Zvbc) = true

union clause ast = VCLMUL_VV : (bits(1), vregidx, vregidx, vregidx)

mapping clause encdec = VCLMUL_VV (vm, vs2, vs1, vd)
  <-> 0b001100 @ vm @ encdec_vreg(vs2) @ encdec_vreg(vs1) @ 0b010 @ encdec_vreg(vd) @ 0b1010111 when extensionEnabled(Ext_Zvbc)

mapping clause assembly = VCLMUL_VV (vm, vs2, vs1, vd)
  <-> "vclmul.vv" ^ spc() ^ vreg_name(vd) ^ sep() ^ vreg_name(vs2) ^ sep() ^ vreg_name(vs1) ^ maybe_vmask(vm)

function clause execute (VCLMUL_VV(vm, vs2, vs1, vd)) = {
  let SEW                     = get_sew();
  let LMUL_pow                = get_lmul_pow();
  let num_elem                = get_num_elem(LMUL_pow, SEW);

  let 'n = num_elem;
  let 'm = SEW;

  let vm_val  : bits('n)                  = read_vmask(num_elem, vm, zvreg);
  let vd_val  : vector('n, bits('m)) = read_vreg(num_elem, SEW, LMUL_pow, vd);

  let vs1_val : vector('n, bits('m)) = read_vreg(num_elem, SEW, LMUL_pow, vs1);
  let vs2_val : vector('n, bits('m)) = read_vreg(num_elem, SEW, LMUL_pow, vs2);

  let (initial_result, mask) = init_masked_result(num_elem, SEW, LMUL_pow, vd_val, vm_val);
  var result = initial_result;

  foreach (i from 0 to (num_elem - 1)) {
    if mask[i] == bitone then {
      foreach (n from 0 to (SEW - 1))
        if vs2_val[i][n] == bitone then result[i] = result[i] ^ (vs1_val[i] << n);
    };
  };
  write_vreg(num_elem, SEW, LMUL_pow, vd, result);
  vstart = zeros();
  RETIRE_SUCCESS
}

union clause ast = VCLMUL_VX : (bits(1), vregidx, regidx, vregidx)

mapping clause encdec = VCLMUL_VX (vm, vs2, rs1, vd)
  <-> 0b001100 @ vm @ encdec_vreg(vs2) @ encdec_reg(rs1) @ 0b110 @ encdec_vreg(vd) @ 0b1010111 when extensionEnabled(Ext_Zvbc)

mapping clause assembly = VCLMUL_VX (vm, vs2, rs1, vd)
  <-> "vclmul.vx" ^ spc() ^ vreg_name(vd) ^ sep() ^ vreg_name(vs2) ^ sep() ^ reg_name(rs1) ^ maybe_vmask(vm)

function clause execute (VCLMUL_VX(vm, vs2, rs1, vd)) = {
  let SEW                     = get_sew();
  let LMUL_pow                = get_lmul_pow();
  let num_elem                = get_num_elem(LMUL_pow, SEW);

  let 'n = num_elem;
  let 'm = SEW;

  let vm_val  : bits('n)                  = read_vmask(num_elem, vm, zvreg);
  let vd_val  : vector('n, bits('m)) = read_vreg(num_elem, SEW, LMUL_pow, vd);

  let rs1_val : bits('m)                  = get_scalar(rs1, SEW);
  let vs2_val : vector('n, bits('m)) = read_vreg(num_elem, SEW, LMUL_pow, vs2);

  let (initial_result, mask) = init_masked_result(num_elem, SEW, LMUL_pow, vd_val, vm_val);
  var result = initial_result;

  foreach (i from 0 to (num_elem - 1)) {
    if mask[i] == bitone then {
      foreach (n from 0 to (SEW - 1))
        if vs2_val[i][n] == bitone then result[i] = result[i] ^ (rs1_val << n);
      write_vreg(num_elem, SEW, LMUL_pow, vd, result);
    };
  };
  vstart = zeros();
  RETIRE_SUCCESS
}

union clause ast = VCLMULH_VV : (bits(1), vregidx, vregidx, vregidx)

mapping clause encdec = VCLMULH_VV (vm, vs2, vs1, vd)
  <-> 0b001101 @ vm @ encdec_vreg(vs2) @ encdec_vreg(vs1) @ 0b010 @ encdec_vreg(vd) @ 0b1010111 when extensionEnabled(Ext_Zvbc)

mapping clause assembly = VCLMULH_VV (vm, vs2, vs1, vd)
  <-> "vclmulh.vv" ^ spc() ^ vreg_name(vd) ^ sep() ^ vreg_name(vs2) ^ sep() ^ vreg_name(vs1) ^ maybe_vmask(vm)

function clause execute (VCLMULH_VV(vm, vs2, vs1, vd)) = {
  let SEW                     = get_sew();
  let LMUL_pow                = get_lmul_pow();
  let num_elem                = get_num_elem(LMUL_pow, SEW);

  let 'n = num_elem;
  let 'm = SEW;

  let vm_val  : bits('n)                  = read_vmask(num_elem, vm, zvreg);
  let vd_val  : vector('n, bits('m)) = read_vreg(num_elem, SEW, LMUL_pow, vd);

  let vs1_val : vector('n, bits('m)) = read_vreg(num_elem, SEW, LMUL_pow, vs1);
  let vs2_val : vector('n, bits('m)) = read_vreg(num_elem, SEW, LMUL_pow, vs2);

  let (initial_result, mask) = init_masked_result(num_elem, SEW, LMUL_pow, vd_val, vm_val);
  var result = initial_result;

  foreach (i from 0 to (num_elem - 1)) {
    if mask[i] == bitone then {
      foreach (n from 0 to (SEW - 1))
        if vs2_val[i][n] == bitone then result[i] = result[i] ^ (vs1_val[i] >> (SEW - n));
      write_vreg(num_elem, SEW, LMUL_pow, vd, result);
    };
  };
  vstart = zeros();
  RETIRE_SUCCESS
}

union clause ast = VCLMULH_VX : (bits(1), vregidx, regidx, vregidx)

mapping clause encdec = VCLMULH_VX (vm, vs2, rs1, vd)
  <-> 0b001101 @ vm @ encdec_vreg(vs2) @ encdec_reg(rs1) @ 0b110 @ encdec_vreg(vd) @ 0b1010111 when extensionEnabled(Ext_Zvbc)

mapping clause assembly = VCLMULH_VX (vm, vs2, rs1, vd)
  <-> "vclmulh.vx" ^ spc() ^ vreg_name(vd) ^ sep() ^ vreg_name(vs2) ^ sep() ^ reg_name(rs1) ^ maybe_vmask(vm)

function clause execute (VCLMULH_VX(vm, vs2, rs1, vd)) = {
  let SEW                     = get_sew();
  let LMUL_pow                = get_lmul_pow();
  let num_elem                = get_num_elem(LMUL_pow, SEW);

  let 'n = num_elem;
  let 'm = SEW;

  let vm_val  : bits('n)                  = read_vmask(num_elem, vm, zvreg);
  let vd_val  : vector('n, bits('m)) = read_vreg(num_elem, SEW, LMUL_pow, vd);

  let rs1_val : bits('m)                  = get_scalar(rs1, SEW);
  let vs2_val : vector('n, bits('m)) = read_vreg(num_elem, SEW, LMUL_pow, vs2);

  let (initial_result, mask) = init_masked_result(num_elem, SEW, LMUL_pow, vd_val, vm_val);
  var result = initial_result;

  foreach (i from 0 to (num_elem - 1)) {
    if mask[i] == bitone then {
      foreach (n from 0 to (SEW - 1))
        if vs2_val[i][n] == bitone then result[i] = result[i] ^ (rs1_val >> (SEW - n));
      write_vreg(num_elem, SEW, LMUL_pow, vd, result);
    };
  };
  vstart = zeros();
  RETIRE_SUCCESS
}
