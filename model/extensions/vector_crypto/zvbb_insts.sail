// =======================================================================================
// This Sail RISC-V architecture model, comprising all files and
// directories except where otherwise noted is subject the BSD
// two-clause license in the LICENSE file.
//
// SPDX-License-Identifier: BSD-2-Clause
// =======================================================================================

function clause currentlyEnabled(Ext_Zvbb) = hartSupports(Ext_Zvbb) & currentlyEnabled(Ext_V)
function clause currentlyEnabled(Ext_Zvkb) = (hartSupports(Ext_Zvkb) | currentlyEnabled(Ext_Zvbb)) & currentlyEnabled(Ext_V)

union clause instruction = VANDN_VV : (bits(1), vregidx, vregidx, vregidx)

mapping clause encdec = VANDN_VV(vm, vs1, vs2, vd)
  <-> 0b000001 @ vm @ encdec_vreg(vs2) @ encdec_vreg(vs1) @ 0b000 @ encdec_vreg(vd) @ 0b1010111
  when currentlyEnabled(Ext_Zvkb)

mapping clause assembly = VANDN_VV(vm, vs1, vs2, vd)
  <-> "vandn.vv" ^ spc() ^ vreg_name(vd) ^ sep() ^ vreg_name(vs2) ^ sep() ^ vreg_name(vs1) ^ maybe_vmask(vm)

function clause execute (VANDN_VV(vm, vs1, vs2, vd)) = {
  let SEW      = get_sew();
  let LMUL_pow = get_lmul_pow();
  let num_elem = get_num_elem(LMUL_pow, SEW);

  let 'n = num_elem;
  let 'm = SEW;

  let vm_val  : bits('n) = read_vmask(num_elem, vm, zvreg);
  let vs1_val : vector('n, bits('m)) = read_vreg(num_elem, SEW, LMUL_pow, vs1);
  let vs2_val : vector('n, bits('m)) = read_vreg(num_elem, SEW, LMUL_pow, vs2);
  let vd_val  : vector('n, bits('m)) = read_vreg(num_elem, SEW, LMUL_pow, vd);

  let (initial_result, mask) : (vector('n, bits('m)), bits('n)) = match init_masked_result(num_elem, SEW, LMUL_pow, vd_val, vm_val) {
    Ok(v)   => v,
    Err(()) => return Illegal_Instruction()
  };
  var result = initial_result;

  foreach (i from 0 to (num_elem - 1)) {
    if mask[i] == bitone then
      result[i] = ~(vs1_val[i]) & vs2_val[i];
  };
  write_vreg(num_elem, SEW, LMUL_pow, vd, result);
  set_vstart(zeros());
  RETIRE_SUCCESS
}

union clause instruction = VANDN_VX : (bits(1), vregidx, regidx, vregidx)

mapping clause encdec = VANDN_VX(vm, vs2, rs1, vd)
  <-> 0b000001 @ vm @ encdec_vreg(vs2) @ encdec_reg(rs1) @ 0b100 @ encdec_vreg(vd) @ 0b1010111
  when currentlyEnabled(Ext_Zvkb)

mapping clause assembly = VANDN_VX(vm, vs2, rs1, vd)
  <-> "vandn.vx" ^ spc() ^ vreg_name(vd) ^ sep() ^ vreg_name(vs2) ^ sep() ^ reg_name(rs1) ^ maybe_vmask(vm)

function clause execute (VANDN_VX(vm, vs2, rs1, vd)) = {
  let SEW      = get_sew();
  let LMUL_pow = get_lmul_pow();
  let num_elem = get_num_elem(LMUL_pow, SEW);

  let 'n = num_elem;
  let 'm = SEW;

  let vm_val  : bits('n) = read_vmask(num_elem, vm, zvreg);
  let rs1_val : bits('m) = get_scalar(rs1, SEW);
  let vs2_val : vector('n, bits('m)) = read_vreg(num_elem, SEW, LMUL_pow, vs2);
  let vd_val  : vector('n, bits('m)) = read_vreg(num_elem, SEW, LMUL_pow, vd);

  let (initial_result, mask) : (vector('n, bits('m)), bits('n)) = match init_masked_result(num_elem, SEW, LMUL_pow, vd_val, vm_val) {
    Ok(v)   => v,
    Err(()) => return Illegal_Instruction()
  };
  var result = initial_result;

  foreach (i from 0 to (num_elem- 1)) {
    if mask[i] == bitone then
      result[i] = ~(rs1_val) & vs2_val[i];
  };
  write_vreg(num_elem, SEW, LMUL_pow, vd, result);
  set_vstart(zeros());
  RETIRE_SUCCESS
}

union clause instruction = VBREV_V : (bits(1), vregidx, vregidx)

mapping clause encdec = VBREV_V(vm, vs2, vd)
  <-> 0b010010 @ vm @ encdec_vreg(vs2) @ 0b01010 @ 0b010 @ encdec_vreg(vd) @ 0b1010111
  when currentlyEnabled(Ext_Zvbb)

mapping clause assembly = VBREV_V(vm, vs2, vd)
  <-> "vbrev.v" ^ spc() ^ vreg_name(vd) ^ sep() ^ vreg_name(vs2) ^ maybe_vmask(vm)

function clause execute (VBREV_V(vm, vs2, vd)) = {
  let SEW      = get_sew();
  let LMUL_pow = get_lmul_pow();
  let num_elem = get_num_elem(LMUL_pow, SEW);

  let 'n = num_elem;
  let 'm = SEW;

  let vm_val  : bits('n) = read_vmask(num_elem, vm, zvreg);
  let vs2_val : vector('n, bits('m)) = read_vreg(num_elem, SEW, LMUL_pow, vs2);
  let vd_val  : vector('n, bits('m)) = read_vreg(num_elem, SEW, LMUL_pow, vd);

  let (initial_result, mask) : (vector('n, bits('m)), bits('n)) = match init_masked_result(num_elem, SEW, LMUL_pow, vd_val, vm_val) {
    Ok(v)   => v,
    Err(()) => return Illegal_Instruction()
  };
  var result = initial_result;

  foreach (i from 0 to (num_elem - 1)) {
    if mask[i] == bitone then {
      var output : bits('m) = zeros();
      foreach (j from 0 to (SEW - 1))
        output[SEW - 1 - j] = vs2_val[i][j];
      result[i] = output;
    };
  };
  write_vreg(num_elem, SEW, LMUL_pow, vd, result);
  set_vstart(zeros());
  RETIRE_SUCCESS
}

union clause instruction = VBREV8_V : (bits(1), vregidx, vregidx)

mapping clause encdec = VBREV8_V(vm, vs2, vd)
  <-> 0b010010 @ vm @ encdec_vreg(vs2) @ 0b01000 @ 0b010 @ encdec_vreg(vd) @ 0b1010111
  when currentlyEnabled(Ext_Zvkb)

mapping clause assembly = VBREV8_V(vm, vs2, vd)
  <-> "vbrev8.v" ^ spc() ^ vreg_name(vd) ^ sep() ^ vreg_name(vs2) ^ maybe_vmask(vm)

function clause execute (VBREV8_V(vm, vs2, vd)) = {
  let SEW      = get_sew();
  let LMUL_pow = get_lmul_pow();
  let num_elem = get_num_elem(LMUL_pow, SEW);

  let 'n = num_elem;
  let 'm = SEW;

  let vm_val  : bits('n)= read_vmask(num_elem, vm, zvreg);
  let vs2_val : vector('n, bits('m)) = read_vreg(num_elem, SEW, LMUL_pow, vs2);
  let vd_val  : vector('n, bits('m)) = read_vreg(num_elem, SEW, LMUL_pow, vd);

  let (initial_result, mask) : (vector('n, bits('m)), bits('n)) = match init_masked_result(num_elem, SEW, LMUL_pow, vd_val, vm_val) {
    Ok(v)   => v,
    Err(()) => return Illegal_Instruction()
  };
  var result = initial_result;

  foreach (i from 0 to (num_elem - 1)) {
    if mask[i] == bitone then {
      result[i] = brev8(vs2_val[i]);
    };
  };
  write_vreg(num_elem, SEW, LMUL_pow, vd, result);
  set_vstart(zeros());
  RETIRE_SUCCESS
}

union clause instruction = VREV8_V : (bits(1), vregidx, vregidx)

mapping clause encdec = VREV8_V(vm, vs2, vd)
  <-> 0b010010 @ vm @ encdec_vreg(vs2) @ 0b01001 @ 0b010 @ encdec_vreg(vd) @ 0b1010111
  when currentlyEnabled(Ext_Zvkb)

mapping clause assembly = VREV8_V(vm, vs2, vd)
  <-> "vrev8.v" ^ spc() ^ vreg_name(vd) ^ sep() ^ vreg_name(vs2) ^ maybe_vmask(vm)

function clause execute (VREV8_V(vm, vs2, vd)) = {
  let SEW      = get_sew();
  let LMUL_pow = get_lmul_pow();
  let num_elem = get_num_elem(LMUL_pow, SEW);

  let 'n = num_elem;
  let 'm = SEW;

  let vm_val  : bits('n) = read_vmask(num_elem, vm, zvreg);
  let vs2_val : vector('n, bits('m)) = read_vreg(num_elem, SEW, LMUL_pow, vs2);
  let vd_val  : vector('n, bits('m)) = read_vreg(num_elem, SEW, LMUL_pow, vd);

  let (initial_result, mask) : (vector('n, bits('m)), bits('n)) = match init_masked_result(num_elem, SEW, LMUL_pow, vd_val, vm_val) {
    Ok(v)   => v,
    Err(()) => return Illegal_Instruction()
  };
  var result = initial_result;

  foreach (i from 0 to (num_elem - 1)) {
    if mask[i] == bitone then {
      result[i] = rev8(vs2_val[i]);
    };
  };
  write_vreg(num_elem, SEW, LMUL_pow, vd, result);
  set_vstart(zeros());
  RETIRE_SUCCESS
}

union clause instruction = VCLZ_V : (bits(1), vregidx, vregidx)

mapping clause encdec = VCLZ_V (vm, vs2, vd)
  <-> 0b010010 @ vm @ encdec_vreg(vs2) @ 0b01100 @ 0b010 @ encdec_vreg(vd) @ 0b1010111
  when currentlyEnabled(Ext_Zvbb)

mapping clause assembly = VCLZ_V (vm, vs2, vd)
  <-> "vclz.v" ^ spc() ^ vreg_name(vd) ^ sep() ^ vreg_name(vs2) ^ maybe_vmask(vm)

function clause execute (VCLZ_V(vm, vs2, vd)) = {
  let SEW      = get_sew();
  let LMUL_pow = get_lmul_pow();
  let num_elem = get_num_elem(LMUL_pow, SEW);

  let 'n = num_elem;
  let 'm = SEW;

  let vm_val  : bits('n) = read_vmask(num_elem, vm, zvreg);
  let vs2_val : vector('n, bits('m)) = read_vreg(num_elem, SEW, LMUL_pow, vs2);
  let vd_val  : vector('n, bits('m)) = read_vreg(num_elem, SEW, LMUL_pow, vd);

  let (initial_result, mask) : (vector('n, bits('m)), bits('n)) = match init_masked_result(num_elem, SEW, LMUL_pow, vd_val, vm_val) {
    Ok(v)   => v,
    Err(()) => return Illegal_Instruction()
  };
  var result = initial_result;

  foreach (i from 0 to (num_elem - 1)) {
    if mask[i] == bitone then {
      let clz = count_leading_zeros(vs2_val[i]);
      result[i] = to_bits(clz);
    };
  };
  write_vreg(num_elem, SEW, LMUL_pow, vd, result);
  set_vstart(zeros());
  RETIRE_SUCCESS
}

union clause instruction = VCTZ_V : (bits(1), vregidx, vregidx)

mapping clause encdec = VCTZ_V (vm, vs2, vd)
  <-> 0b010010 @ vm @ encdec_vreg(vs2) @ 0b01101 @ 0b010 @ encdec_vreg(vd) @ 0b1010111
  when currentlyEnabled(Ext_Zvbb)

mapping clause assembly = VCTZ_V (vm, vs2, vd)
  <-> "vctz.v" ^ spc() ^ vreg_name(vd) ^ sep() ^ vreg_name(vs2) ^ maybe_vmask(vm)

function clause execute (VCTZ_V(vm, vs2, vd)) = {
  let SEW      = get_sew();
  let LMUL_pow = get_lmul_pow();
  let num_elem = get_num_elem(LMUL_pow, SEW);

  let 'n = num_elem;
  let 'm = SEW;

  let vm_val  : bits('n) = read_vmask(num_elem, vm, zvreg);
  let vs2_val : vector('n, bits('m)) = read_vreg(num_elem, SEW, LMUL_pow, vs2);
  let vd_val  : vector('n, bits('m)) = read_vreg(num_elem, SEW, LMUL_pow, vd);

  let (initial_result, mask) : (vector('n, bits('m)), bits('n)) = match init_masked_result(num_elem, SEW, LMUL_pow, vd_val, vm_val) {
    Ok(v)   => v,
    Err(()) => return Illegal_Instruction()
  };
  var result = initial_result;

  foreach (i from 0 to (num_elem - 1)) {
    if mask[i] == bitone then {
      let ctz = count_trailing_zeros(vs2_val[i]);
      result[i] = to_bits(ctz);
    };
  };
  write_vreg(num_elem, SEW, LMUL_pow, vd, result);
  set_vstart(zeros());
  RETIRE_SUCCESS
}

union clause instruction = VCPOP_V : (bits(1), vregidx, vregidx)

mapping clause encdec = VCPOP_V (vm, vs2, vd)
  <-> 0b010010 @ vm @ encdec_vreg(vs2) @ 0b01110 @ 0b010 @ encdec_vreg(vd) @ 0b1010111
  when currentlyEnabled(Ext_Zvbb)

mapping clause assembly = VCPOP_V (vm, vs2, vd)
  <-> "vcpop.v" ^ spc() ^ vreg_name(vd) ^ sep() ^ vreg_name(vs2) ^ maybe_vmask(vm)

function clause execute (VCPOP_V(vm, vs2, vd)) = {
  let SEW      = get_sew();
  let LMUL_pow = get_lmul_pow();
  let num_elem = get_num_elem(LMUL_pow, SEW);

  let 'n = num_elem;
  let 'm = SEW;

  let vm_val  : bits('n) = read_vmask(num_elem, vm, zvreg);
  let vs2_val : vector('n, bits('m)) = read_vreg(num_elem, SEW, LMUL_pow, vs2);
  let vd_val  : vector('n, bits('m)) = read_vreg(num_elem, SEW, LMUL_pow, vd);

  let (initial_result, mask) : (vector('n, bits('m)), bits('n)) = match init_masked_result(num_elem, SEW, LMUL_pow, vd_val, vm_val) {
    Ok(v)   => v,
    Err(()) => return Illegal_Instruction()
  };
  var result = initial_result;

  foreach (i from 0 to (num_elem - 1)) {
    if mask[i] == bitone then {
      foreach (j from 0 to (SEW - 1)) {
        if vs2_val[i][j] == bitone then {
          result[i] = result[i] + 1;
        };
      }
    };
  };
  write_vreg(num_elem, SEW, LMUL_pow, vd, result);
  set_vstart(zeros());
  RETIRE_SUCCESS
}

union clause instruction = VROL_VV : (bits(1), vregidx, vregidx, vregidx)

mapping clause encdec = VROL_VV(vm, vs1, vs2, vd)
  <-> 0b010101 @ vm @ encdec_vreg(vs2) @ encdec_vreg(vs1) @ 0b000 @ encdec_vreg(vd) @ 0b1010111
  when currentlyEnabled(Ext_Zvkb)

mapping clause assembly = VROL_VV(vm, vs1, vs2, vd)
 <-> "vrol.vv" ^ spc() ^ vreg_name(vd) ^ sep() ^ vreg_name(vs2) ^ sep() ^ vreg_name(vs1) ^ maybe_vmask(vm)

function clause execute (VROL_VV(vm, vs1, vs2, vd)) = {
  let SEW_pow  = get_sew_pow();
  let SEW      = 2 ^ SEW_pow;
  let LMUL_pow = get_lmul_pow();
  let num_elem = get_num_elem(LMUL_pow, SEW);

  let 'n = num_elem;
  let 'm = SEW;

  let vm_val  : bits('n) = read_vmask(num_elem, vm, zvreg);
  let vs1_val : vector('n, bits('m)) = read_vreg(num_elem, SEW, LMUL_pow, vs1);
  let vs2_val : vector('n, bits('m)) = read_vreg(num_elem, SEW, LMUL_pow, vs2);
  let vd_val  : vector('n, bits('m)) = read_vreg(num_elem, SEW, LMUL_pow, vd);

  let (initial_result, mask) : (vector('n, bits('m)), bits('n)) = match init_masked_result(num_elem, SEW, LMUL_pow, vd_val, vm_val) {
    Ok(v)   => v,
    Err(()) => return Illegal_Instruction()
  };
  var result = initial_result;

  foreach (i from 0 to (num_elem - 1)) {
    if mask[i] == bitone then
      result[i] = vs2_val[i] <<< vs1_val[i][SEW_pow - 1 .. 0];
  };
  write_vreg(num_elem, SEW, LMUL_pow, vd, result);
  set_vstart(zeros());
  RETIRE_SUCCESS
}

union clause instruction = VROL_VX : (bits(1), vregidx, regidx, vregidx)

mapping clause encdec = VROL_VX(vm, vs2, rs1, vd)
  <-> 0b010101 @ vm @ encdec_vreg(vs2) @ encdec_reg(rs1) @ 0b100 @ encdec_vreg(vd) @ 0b1010111
  when currentlyEnabled(Ext_Zvkb)

mapping clause assembly = VROL_VX(vm, vs2, rs1, vd)
 <-> "vrol.vx" ^ spc() ^ vreg_name(vd) ^ sep() ^ vreg_name(vs2) ^ sep() ^ reg_name(rs1) ^ maybe_vmask(vm)

function clause execute (VROL_VX(vm, vs2, rs1, vd)) = {
  let SEW_pow  = get_sew_pow();
  let SEW      = 2 ^ SEW_pow;
  let LMUL_pow = get_lmul_pow();
  let num_elem = get_num_elem(LMUL_pow, SEW);

  let 'n = num_elem;
  let 'm = SEW;

  let vm_val  : bits('n) = read_vmask(num_elem, vm, zvreg);
  let rs1_val : bits('m) = get_scalar(rs1, SEW);
  let vs2_val : vector('n, bits('m)) = read_vreg(num_elem, SEW, LMUL_pow, vs2);
  let vd_val  : vector('n, bits('m)) = read_vreg(num_elem, SEW, LMUL_pow, vd);

  let (initial_result, mask) : (vector('n, bits('m)), bits('n)) = match init_masked_result(num_elem, SEW, LMUL_pow, vd_val, vm_val) {
    Ok(v)   => v,
    Err(()) => return Illegal_Instruction()
  };
  var result = initial_result;

  foreach (i from 0 to (num_elem - 1)) {
    if mask[i] == bitone then
      result[i] = vs2_val[i] <<< rs1_val[SEW_pow - 1 .. 0];
  };
  write_vreg(num_elem, SEW, LMUL_pow, vd, result);
  set_vstart(zeros());
  RETIRE_SUCCESS
}

union clause instruction = VROR_VV : (bits(1), vregidx, vregidx, vregidx)

mapping clause encdec = VROR_VV(vm, vs1, vs2, vd)
  <-> 0b010100 @ vm @ encdec_vreg(vs2) @ encdec_vreg(vs1) @ 0b000 @ encdec_vreg(vd) @ 0b1010111
  when currentlyEnabled(Ext_Zvkb)

mapping clause assembly = VROR_VV(vm, vs1, vs2, vd)
 <-> "vror.vv" ^ spc() ^ vreg_name(vd) ^ sep() ^ vreg_name(vs2) ^ sep() ^ vreg_name(vs1) ^ maybe_vmask(vm)

function clause execute (VROR_VV(vm, vs1, vs2, vd)) = {
  let SEW_pow  = get_sew_pow();
  let SEW      = 2 ^ SEW_pow;
  let LMUL_pow = get_lmul_pow();
  let num_elem = get_num_elem(LMUL_pow, SEW);

  let 'n = num_elem;
  let 'm = SEW;

  let vm_val  : bits('n) = read_vmask(num_elem, vm, zvreg);
  let vs1_val : vector('n, bits('m)) = read_vreg(num_elem, SEW, LMUL_pow, vs1);
  let vs2_val : vector('n, bits('m)) = read_vreg(num_elem, SEW, LMUL_pow, vs2);
  let vd_val  : vector('n, bits('m)) = read_vreg(num_elem, SEW, LMUL_pow, vd);

  let (initial_result, mask) : (vector('n, bits('m)), bits('n)) = match init_masked_result(num_elem, SEW, LMUL_pow, vd_val, vm_val) {
    Ok(v)   => v,
    Err(()) => return Illegal_Instruction()
  };
  var result = initial_result;

  foreach (i from 0 to (num_elem - 1)) {
    if mask[i] == bitone then
      result[i] = vs2_val[i] >>> vs1_val[i][SEW_pow - 1 .. 0];
  };
  write_vreg(num_elem, SEW, LMUL_pow, vd, result);
  set_vstart(zeros());
  RETIRE_SUCCESS
}

union clause instruction = VROR_VX : (bits(1), vregidx, regidx, vregidx)

mapping clause encdec = VROR_VX(vm, vs2, rs1, vd)
  <-> 0b010100 @ vm @ encdec_vreg(vs2) @ encdec_reg(rs1) @ 0b100 @ encdec_vreg(vd) @ 0b1010111
  when currentlyEnabled(Ext_Zvkb)

mapping clause assembly = VROR_VX(vm, vs2, rs1, vd)
 <-> "vror.vx" ^ spc() ^ vreg_name(vd) ^ sep() ^ vreg_name(vs2) ^ sep() ^ reg_name(rs1)^ maybe_vmask(vm)

function clause execute (VROR_VX(vm, vs2, rs1, vd)) = {
  let SEW_pow  = get_sew_pow();
  let SEW      = 2 ^ SEW_pow;
  let LMUL_pow = get_lmul_pow();
  let num_elem = get_num_elem(LMUL_pow, SEW);

  let 'n = num_elem;
  let 'm = SEW;

  let vm_val  : bits('n) = read_vmask(num_elem, vm, zvreg);
  let rs1_val : bits('m) = get_scalar(rs1, SEW);
  let vs2_val : vector('n, bits('m)) = read_vreg(num_elem, SEW, LMUL_pow, vs2);
  let vd_val  : vector('n, bits('m)) = read_vreg(num_elem, SEW, LMUL_pow, vd);

  let (initial_result, mask) : (vector('n, bits('m)), bits('n)) = match init_masked_result(num_elem, SEW, LMUL_pow, vd_val, vm_val) {
    Ok(v)   => v,
    Err(()) => return Illegal_Instruction()
  };
  var result = initial_result;

  foreach (i from 0 to (num_elem - 1)) {
    if mask[i] == bitone then
      result[i] = vs2_val[i] >>> rs1_val[SEW_pow - 1 .. 0];
  };
  write_vreg(num_elem, SEW, LMUL_pow, vd, result);
  set_vstart(zeros());
  RETIRE_SUCCESS
}

union clause instruction = VROR_VI : (bits(1), vregidx, bits(6), vregidx)

mapping clause encdec = VROR_VI(vm, vs2, uimm5 @ uimm40, vd)
  <-> 0b01010 @ uimm5 @ vm @ encdec_vreg(vs2) @ uimm40 : bits(5) @ 0b011 @ encdec_vreg(vd) @ 0b1010111
  when currentlyEnabled(Ext_Zvkb)

mapping clause assembly = VROR_VI(vm, vs2, uimm, vd)
 <-> "vror.vi" ^ spc() ^ vreg_name(vd) ^ sep() ^ vreg_name(vs2) ^ sep() ^ hex_bits_6(uimm) ^ maybe_vmask(vm)

function clause execute (VROR_VI(vm, vs2, uimm, vd)) = {
  let SEW_pow  = get_sew_pow();
  let SEW      = 2 ^ SEW_pow;
  let LMUL_pow = get_lmul_pow();
  let num_elem = get_num_elem(LMUL_pow, SEW);

  let 'n = num_elem;
  let 'm = SEW;

  let vm_val   : bits('n) = read_vmask(num_elem, vm, zvreg);
  let uimm_val : bits('m) = zero_extend(uimm);
  let vs2_val  : vector('n, bits('m)) = read_vreg(num_elem, SEW, LMUL_pow, vs2);
  let vd_val   : vector('n, bits('m)) = read_vreg(num_elem, SEW, LMUL_pow, vd);

  let (initial_result, mask) : (vector('n, bits('m)), bits('n)) = match init_masked_result(num_elem, SEW, LMUL_pow, vd_val, vm_val) {
    Ok(v)   => v,
    Err(()) => return Illegal_Instruction()
  };
  var result = initial_result;

  foreach (i from 0 to (num_elem - 1)) {
    if mask[i] == bitone then
      result[i] = vs2_val[i] >>> uimm_val[SEW_pow - 1 .. 0];
  };
  write_vreg(num_elem, SEW, LMUL_pow, vd, result);
  set_vstart(zeros());
  RETIRE_SUCCESS
}

union clause instruction = VWSLL_VV : (bits(1), vregidx, vregidx, vregidx)

mapping clause encdec = VWSLL_VV (vm, vs2, vs1, vd)
  <-> 0b110101 @ vm @ encdec_vreg(vs2) @ encdec_vreg(vs1) @ 0b000 @ encdec_vreg(vd) @ 0b1010111
  when currentlyEnabled(Ext_Zvbb)

mapping clause assembly = VWSLL_VV (vm, vs2, vs1, vd)
  <-> "vwsll.vv" ^ spc() ^ vreg_name(vd) ^ sep() ^ vreg_name(vs2) ^ sep() ^ vreg_name(vs1) ^ maybe_vmask(vm)

function clause execute (VWSLL_VV(vm, vs2, vs1, vd)) = {
  let SEW            = get_sew();
  let LMUL_pow       = get_lmul_pow();
  let num_elem       = get_num_elem(LMUL_pow, SEW);
  let SEW_widen      = SEW * 2;
  let LMUL_pow_widen = LMUL_pow + 1;

  if  illegal_variable_width(vd, vm, SEW_widen, LMUL_pow_widen) |
      not(valid_reg_overlap(vs1, vd, LMUL_pow, LMUL_pow_widen)) |
      not(valid_reg_overlap(vs2, vd, LMUL_pow, LMUL_pow_widen))
  then return Illegal_Instruction();

  assert(SEW_widen <= 64);
  assert(LMUL_pow_widen <= 3);

  let 'n = num_elem;
  let 'm = SEW;
  let 'o = SEW_widen;

  let vm_val      : bits('n) = read_vmask(num_elem, vm, zvreg);
  let vs1_val_vec : vector('n, bits('m)) = read_vreg(num_elem, SEW, LMUL_pow, vs1);
  let vs2_val_vec : vector('n, bits('m)) = read_vreg(num_elem, SEW, LMUL_pow, vs2);
  let vd_val      : vector('n, bits('o)) = read_vreg(num_elem, SEW_widen, LMUL_pow_widen, vd);

  let SEW_widen_bits = to_bits_unsafe(SEW_widen, 'o);
  let (initial_result, mask) : (vector('n, bits('o)), bits('n)) = match init_masked_result(num_elem, SEW_widen, LMUL_pow_widen, vd_val, vm_val) {
    Ok(v)   => v,
    Err(()) => return Illegal_Instruction()
  };
  var result = initial_result;

  foreach (i from 0 to (num_elem - 1)) {
    if mask[i] == bitone then {
      let vs1_val : bits('o) = zero_extend(vs1_val_vec[i]);
      let vs2_val : bits('o) = zero_extend(vs2_val_vec[i]);
      result[i] = vs2_val << (vs1_val & zero_extend(SEW_widen_bits - 1));
    };
  };
  write_vreg(num_elem, SEW_widen, LMUL_pow_widen, vd, result);
  set_vstart(zeros());
  RETIRE_SUCCESS
}

union clause instruction = VWSLL_VX : (bits(1), vregidx, regidx, vregidx)

mapping clause encdec = VWSLL_VX (vm, vs2, rs1, vd)
  <-> 0b110101 @ vm @ encdec_vreg(vs2) @ encdec_reg(rs1) @ 0b100 @ encdec_vreg(vd) @ 0b1010111
  when currentlyEnabled(Ext_Zvbb)

mapping clause assembly = VWSLL_VX (vm, vs2, rs1, vd)
  <-> "vwsll.vx" ^ spc() ^ vreg_name(vd) ^ sep() ^ vreg_name(vs2) ^ sep() ^ reg_name(rs1) ^ maybe_vmask(vm)

function clause execute (VWSLL_VX(vm, vs2, rs1, vd)) = {
  let SEW            = get_sew();
  let LMUL_pow       = get_lmul_pow();
  let num_elem       = get_num_elem(LMUL_pow, SEW);
  let SEW_widen      = SEW * 2;
  let LMUL_pow_widen = LMUL_pow + 1;

  if  illegal_variable_width(vd, vm, SEW_widen, LMUL_pow_widen) |
      not(valid_reg_overlap(vs2, vd, LMUL_pow, LMUL_pow_widen))
  then return Illegal_Instruction();

  assert(SEW_widen <= 64);
  assert(LMUL_pow_widen <= 3);

  let 'n = num_elem;
  let 'm = SEW;
  let 'o = SEW_widen;

  let vm_val      : bits('n) = read_vmask(num_elem, vm, zvreg);
  let rs1_val     : bits('o) = zero_extend(get_scalar(rs1, SEW));
  let vs2_val_vec : vector('n, bits('m)) = read_vreg(num_elem, SEW, LMUL_pow, vs2);
  let vd_val      : vector('n, bits('o)) = read_vreg(num_elem, SEW_widen, LMUL_pow_widen, vd);

  let SEW_widen_bits = to_bits_unsafe(SEW_widen, 'o);
  let (initial_result, mask) : (vector('n, bits('o)), bits('n)) = match init_masked_result(num_elem, SEW_widen, LMUL_pow_widen, vd_val, vm_val) {
    Ok(v)   => v,
    Err(()) => return Illegal_Instruction()
  };
  var result = initial_result;

  foreach (i from 0 to (num_elem - 1)) {
    if mask[i] == bitone then {
      let vs2_val : bits('o) = zero_extend(vs2_val_vec[i]);
      result[i] = vs2_val << (rs1_val & zero_extend(SEW_widen_bits - 1));
    };
  };
  write_vreg(num_elem, SEW_widen, LMUL_pow_widen, vd, result);
  set_vstart(zeros());
  RETIRE_SUCCESS
}

union clause instruction = VWSLL_VI : (bits(1), vregidx, bits(5), vregidx)

mapping clause encdec = VWSLL_VI (vm, vs2, uimm, vd)
  <-> 0b110101 @ vm @ encdec_vreg(vs2) @ uimm @ 0b011 @ encdec_vreg(vd) @ 0b1010111
  when currentlyEnabled(Ext_Zvbb)

mapping clause assembly = VWSLL_VI (vm, vs2, uimm, vd)
  <-> "vwsll.vi" ^ spc() ^ vreg_name(vd) ^ sep() ^ vreg_name(vs2) ^ sep() ^ hex_bits_5(uimm) ^ maybe_vmask(vm)

function clause execute (VWSLL_VI(vm, vs2, uimm, vd)) = {
  let SEW            = get_sew();
  let LMUL_pow       = get_lmul_pow();
  let num_elem       = get_num_elem(LMUL_pow, SEW);
  let SEW_widen      = SEW * 2;
  let LMUL_pow_widen = LMUL_pow + 1;

  if  illegal_variable_width(vd, vm, SEW_widen, LMUL_pow_widen) |
      not(valid_reg_overlap(vs2, vd, LMUL_pow, LMUL_pow_widen))
  then return Illegal_Instruction();

  assert(SEW_widen <= 64);
  assert(LMUL_pow_widen <= 3);

  let 'n = num_elem;
  let 'm = SEW;
  let 'o = SEW_widen;

  let vm_val      : bits('n) = read_vmask(num_elem, vm, zvreg);
  let uimm_val    : bits('o) = zero_extend(uimm);
  let vs2_val_vec : vector('n, bits('m)) = read_vreg(num_elem, SEW, LMUL_pow, vs2);
  let vd_val      : vector('n, bits('o)) = read_vreg(num_elem, SEW_widen, LMUL_pow_widen, vd);

  let SEW_widen_bits = to_bits_unsafe(SEW_widen, 'o);
  let (initial_result, mask) : (vector('n, bits('o)), bits('n)) = match init_masked_result(num_elem, SEW_widen, LMUL_pow_widen, vd_val, vm_val) {
    Ok(v)   => v,
    Err(()) => return Illegal_Instruction()
  };
  var result = initial_result;

  foreach (i from 0 to (num_elem - 1)) {
    if mask[i] == bitone then {
        let vs2_val : bits('o) = zero_extend(vs2_val_vec[i]);
        result[i] = vs2_val << (uimm_val & zero_extend(SEW_widen_bits - 1));
    };
  };
  write_vreg(num_elem, SEW_widen, LMUL_pow_widen, vd, result);
  set_vstart(zeros());
  RETIRE_SUCCESS
}
