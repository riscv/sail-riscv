/*
 * Vector Cryptography Extension - Vector Bit-manipulation instructions
 * ----------------------------------------------------------------------
 */

/* VROL.VV */

union clause ast = RISCV_VROL_VV : (bits(1), regidx, regidx, regidx)

mapping clause encdec = RISCV_VROL_VV(vm, vs1, vs2, vd) if (haveRVV() & haveZvkb() & sizeof(xlen) == 64)
 <-> 0b010101 @ vm @ vs2 @ vs1 @ 0b000 @ vd @ 0b1010111 if (haveRVV() & haveZvkb() & sizeof(xlen) == 64)

mapping clause assembly = RISCV_VROL_VV(vm, vs1, vs2, vd)
 <-> "vrol.vv" ^ spc() ^ vreg_name(vd)
	       ^ sep() ^ vreg_name(vs2)
	       ^ sep() ^ vreg_name(vs1)
	       ^ maybe_vmask(vm)

function clause execute (RISCV_VROL_VV(vm, vs1, vs2, vd)) = {
  let SEW      = get_sew();
  let LMUL_pow = get_lmul_pow();
  let VLEN     = int_power(2, get_vlen_pow());
  let num_elem = get_num_elem(LMUL_pow, SEW);

  let 'n = num_elem;
  let 'm = SEW;

  let vm_val  : vector('n, dec, bool)     = read_vmask(num_elem, vm, vreg_name("v0"));
  let vs2_val : vector('n, dec, bits('m)) = read_vreg(num_elem, SEW, LMUL_pow, vs2);
  let vs1_val : vector('n, dec, bits('m)) = read_vreg(num_elem, SEW, LMUL_pow, vs1);
  let vd_val  : vector('n, dec, bits('m)) = read_vreg(num_elem, SEW, LMUL_pow, vd);
  result      : vector('n, dec, bits('m)) = undefined;
  mask        : vector('n, dec, bool)     = undefined;

  (result, mask) = init_masked_result(num_elem, SEW, LMUL_pow, vd_val, vm_val);

  foreach (i from unsigned(vstart) to (unsigned(vl) - 1)) {
    assert(0 <= i & i < 'n);
    if mask[i] then
      result[i] = rotate_bits_left(vs2_val[i], (vs1_val[i] & (to_bits('m, SEW - 1))));
  };

  write_single_vreg(num_elem, 'm, vd, result);
  vstart = EXTZ(0b0);
  RETIRE_SUCCESS
}

/* VROL.VX */

union clause ast = RISCV_VROL_VX : (bits(1), regidx, regidx, regidx)

mapping clause encdec = RISCV_VROL_VX(vm, vs2, rs1, vd) if (haveRVV() & haveZvkb() & sizeof(xlen) == 64)
 <-> 0b010101 @ vm @ vs2 @ rs1 @ 0b100 @ vd @ 0b1010111 if (haveRVV() & haveZvkb() & sizeof(xlen) == 64)

mapping clause assembly = RISCV_VROL_VX(vm, vs2, rs1, vd)
 <-> "vrol.vx" ^ spc() ^ vreg_name(vd)
	       ^ sep() ^ vreg_name(vs2)
	       ^ sep() ^ reg_name(rs1)
	       ^ maybe_vmask(vm)

function clause execute (RISCV_VROL_VX(vm, vs2, rs1, vd)) = {
  let SEW      = get_sew();
  let LMUL_pow = get_lmul_pow();
  let VLEN     = int_power(2, get_vlen_pow());
  let num_elem = get_num_elem(LMUL_pow, SEW);

  let 'n = num_elem;
  let 'm = SEW;

  let vm_val  : vector('n, dec, bool)     = read_vmask(num_elem, vm, vreg_name("v0"));
  let vs2_val : vector('n, dec, bits('m)) = read_vreg(num_elem, SEW, LMUL_pow, vs2);
  let rs1_val				  = X(rs1);
  let vd_val  : vector('n, dec, bits('m)) = read_vreg(num_elem, SEW, LMUL_pow, vd);
  result      : vector('n, dec, bits('m)) = undefined;
  mask        : vector('n, dec, bool)     = undefined;

  (result, mask) = init_masked_result(num_elem, SEW, LMUL_pow, vd_val, vm_val);

  foreach (i from unsigned(vstart) to (unsigned(vl) - 1)) {
    assert(0 <= i & i < 'n);
    if mask[i] then
      result[i] = rotate_bits_left(vs2_val[i], (to_bits('m, unsigned(rs1_val)) & to_bits('m, SEW - 1)));
  };

  write_single_vreg(num_elem, 'm, vd, result);
  vstart = EXTZ(0b0);
  RETIRE_SUCCESS
}

/* VROR.VV */

union clause ast = RISCV_VROR_VV : (bits(1), regidx, regidx, regidx)

mapping clause encdec = RISCV_VROR_VV(vm, vs1, vs2, vd) if (haveRVV() & haveZvkb() & sizeof(xlen) == 64)
 <-> 0b010100 @ vm @ vs2 @ vs1 @ 0b000 @ vd @ 0b1010111 if (haveRVV() & haveZvkb() & sizeof(xlen) == 64)

mapping clause assembly = RISCV_VROR_VV(vm, vs1, vs2, vd)
 <-> "vror.vv" ^ spc() ^ vreg_name(vd)
	       ^ sep() ^ vreg_name(vs2)
	       ^ sep() ^ vreg_name(vs1)
	       ^ maybe_vmask(vm)

function clause execute (RISCV_VROR_VV(vm, vs1, vs2, vd)) = {
  let SEW      = get_sew();
  let LMUL_pow = get_lmul_pow();
  let VLEN     = int_power(2, get_vlen_pow());
  let num_elem = get_num_elem(LMUL_pow, SEW);

  let 'n = num_elem;
  let 'm = SEW;

  let vm_val  : vector('n, dec, bool)     = read_vmask(num_elem, vm, vreg_name("v0"));
  let vs2_val : vector('n, dec, bits('m)) = read_vreg(num_elem, SEW, LMUL_pow, vs2);
  let vs1_val : vector('n, dec, bits('m)) = read_vreg(num_elem, SEW, LMUL_pow, vs1);
  let vd_val  : vector('n, dec, bits('m)) = read_vreg(num_elem, SEW, LMUL_pow, vd);
  result      : vector('n, dec, bits('m)) = undefined;
  mask        : vector('n, dec, bool)     = undefined;

  (result, mask) = init_masked_result(num_elem, SEW, LMUL_pow, vd_val, vm_val);

  foreach (i from unsigned(vstart) to (unsigned(vl) - 1)) {
    assert(0 <= i & i < 'n);
    if mask[i] then
      result[i] = rotate_bits_right(vs2_val[i], (vs1_val[i] & (to_bits('m, SEW - 1))));
  };

  write_single_vreg(num_elem, 'm, vd, result);
  vstart = EXTZ(0b0);
  RETIRE_SUCCESS
}

/* VROR.VX */

union clause ast = RISCV_VROR_VX : (bits(1), regidx, regidx, regidx)

mapping clause encdec = RISCV_VROR_VX(vm, vs2, rs1, vd) if (haveRVV() & haveZvkb() & sizeof(xlen) == 64)
 <-> 0b010100 @ vm @ vs2 @ rs1 @ 0b100 @ vd @ 0b1010111 if (haveRVV() & haveZvkb() & sizeof(xlen) == 64)

mapping clause assembly = RISCV_VROR_VX(vm, vs2, rs1, vd)
 <-> "vror.vx" ^ spc() ^ vreg_name(vd)
	       ^ sep() ^ vreg_name(vs2)
	       ^ sep() ^ reg_name(rs1)
	       ^ maybe_vmask(vm)

function clause execute (RISCV_VROR_VX(vm, vs2, rs1, vd)) = {
  let SEW      = get_sew();
  let LMUL_pow = get_lmul_pow();
  let VLEN     = int_power(2, get_vlen_pow());
  let num_elem = get_num_elem(LMUL_pow, SEW);

  let 'n = num_elem;
  let 'm = SEW;

  let vm_val  : vector('n, dec, bool)     = read_vmask(num_elem, vm, vreg_name("v0"));
  let vs2_val : vector('n, dec, bits('m)) = read_vreg(num_elem, SEW, LMUL_pow, vs2);
  let rs1_val				  = X(rs1);
  let vd_val  : vector('n, dec, bits('m)) = read_vreg(num_elem, SEW, LMUL_pow, vd);
  result      : vector('n, dec, bits('m)) = undefined;
  mask        : vector('n, dec, bool)     = undefined;

  (result, mask) = init_masked_result(num_elem, SEW, LMUL_pow, vd_val, vm_val);

  foreach (i from unsigned(vstart) to (unsigned(vl) - 1)) {
    assert(0 <= i & i < 'n);
    if mask[i] then
      result[i] = rotate_bits_right(vs2_val[i], (to_bits('m, unsigned(rs1_val)) & to_bits('m, SEW - 1)));
  };

  write_single_vreg(num_elem, 'm, vd, result);
  vstart = EXTZ(0b0);
  RETIRE_SUCCESS
}

/* VROR.VI */

union clause ast = RISCV_VROR_VI : (bits(1), regidx, bits(5), regidx)

mapping clause encdec = RISCV_VROR_VI(vm, vs2, imm, vd) if (haveRVV() & haveZvkb() & sizeof(xlen) == 64)
 <-> 0b010100 @ vm @ vs2 @ imm @ 0b011 @ vd @ 0b1010111 if (haveRVV() & haveZvkb() & sizeof(xlen) == 64)

mapping clause assembly = RISCV_VROR_VI(vm, vs2, imm, vd)
 <-> "vror.vi" ^ spc() ^ vreg_name(vd)
	       ^ sep() ^ vreg_name(vs2)
	       ^ sep() ^ reg_name(imm)
	       ^ maybe_vmask(vm)

function clause execute (RISCV_VROR_VI(vm, vs2, imm, vd)) = {
  let SEW      = get_sew();
  let LMUL_pow = get_lmul_pow();
  let VLEN     = int_power(2, get_vlen_pow());
  let num_elem = get_num_elem(LMUL_pow, SEW);

  let 'n = num_elem;
  let 'm = SEW;

  let vm_val  : vector('n, dec, bool)     = read_vmask(num_elem, vm, vreg_name("v0"));
  let vs2_val : vector('n, dec, bits('m)) = read_vreg(num_elem, SEW, LMUL_pow, vs2);
  let rs1_val : bits('m)		  = EXTS(imm);
  let vd_val  : vector('n, dec, bits('m)) = read_vreg(num_elem, SEW, LMUL_pow, vd);
  result      : vector('n, dec, bits('m)) = undefined;
  mask        : vector('n, dec, bool)     = undefined;

  (result, mask) = init_masked_result(num_elem, SEW, LMUL_pow, vd_val, vm_val);

  foreach (i from unsigned(vstart) to (unsigned(vl) - 1)) {
    assert(0 <= i & i < 'n);
    if mask[i] then
      result[i] = rotate_bits_right(vs2_val[i], (rs1_val & to_bits('m, SEW - 1)));
  };

  write_single_vreg(num_elem, 'm, vd, result);
  vstart = EXTZ(0b0);
  RETIRE_SUCCESS
}

/* VBREV8.V */

union clause ast = RISCV_VBREV8_V : (bits(1), regidx, regidx)

mapping clause encdec = RISCV_VBREV8_V(vm, vs2, vd)         if (haveRVV() & haveZvkb() & sizeof(xlen) == 64)
 <-> 0b010010 @ vm @ vs2 @ 0b01000 @ 0b010 @ vd @ 0b1010111 if (haveRVV() & haveZvkb() & sizeof(xlen) == 64)

mapping clause assembly = RISCV_VBREV8_V(vm, vs2, vd)
 <-> "vbrev8.v" ^ spc() ^ vreg_name(vd)
		^ sep() ^ vreg_name(vs2)
		^ maybe_vmask(vm)

function clause execute (RISCV_VBREV8_V(vm, vs2, vd)) = {
  let SEW      = get_sew();
  let LMUL_pow = get_lmul_pow();
  let VLEN     = int_power(2, get_vlen_pow());
  let num_elem = get_num_elem(LMUL_pow, SEW);

  let 'n = num_elem;
  let 'm = SEW;

  let vm_val  : vector('n, dec, bool)     = read_vmask(num_elem, vm, vreg_name("v0"));
  let vs2_val : vector('n, dec, bits('m)) = read_vreg(num_elem, SEW, LMUL_pow, vs2);
  let vd_val  : vector('n, dec, bits('m)) = read_vreg(num_elem, SEW, LMUL_pow, vd);
  result      : vector('n, dec, bits('m)) = undefined;
  mask        : vector('n, dec, bool)     = undefined;

  (result, mask) = init_masked_result(num_elem, SEW, LMUL_pow, vd_val, vm_val);

  foreach (i from unsigned(vstart) to (unsigned(vl) - 1)) {
    assert(0 <= i & i < 'n);
    if mask[i] then {
      let input         = vs2_val[i];
      output : bits('m) = zeros();
      foreach (i from 0 to ('m - 8) by 8)
	output[i+7..i] = reverse_bits_in_byte(input[i+7..i]);
      result[i] = output;
    };
  };

  write_single_vreg(num_elem, 'm, vd, result);
  vstart = EXTZ(0b0);
  RETIRE_SUCCESS
}

/* VREV8.V */

union clause ast = RISCV_VREV8_V : (bits(1), regidx, regidx)

mapping clause encdec = RISCV_VREV8_V(vm, vs2, vd)          if (haveRVV() & haveZvkb() & sizeof(xlen) == 64)
 <-> 0b010010 @ vm @ vs2 @ 0b01001 @ 0b010 @ vd @ 0b1010111 if (haveRVV() & haveZvkb() & sizeof(xlen) == 64)

mapping clause assembly = RISCV_VREV8_V(vm, vs2, vd)
 <-> "vrev8.v" ^ spc() ^ vreg_name(vd)
	       ^ sep() ^ vreg_name(vs2)
	       ^ maybe_vmask(vm)

function clause execute (RISCV_VREV8_V(vm, vs2, vd)) = {
  let SEW      = get_sew();
  let LMUL_pow = get_lmul_pow();
  let VLEN     = int_power(2, get_vlen_pow());
  let num_elem = get_num_elem(LMUL_pow, SEW);

  let 'n = num_elem;
  let 'm = SEW;

  let vm_val  : vector('n, dec, bool)     = read_vmask(num_elem, vm, vreg_name("v0"));
  let vs2_val : vector('n, dec, bits('m)) = read_vreg(num_elem, SEW, LMUL_pow, vs2);
  let vd_val  : vector('n, dec, bits('m)) = read_vreg(num_elem, SEW, LMUL_pow, vd);
  result      : vector('n, dec, bits('m)) = undefined;
  mask        : vector('n, dec, bool)     = undefined;

  (result, mask) = init_masked_result(num_elem, SEW, LMUL_pow, vd_val, vm_val);

  foreach (i from unsigned(vstart) to (unsigned(vl) - 1)) {
    assert(0 <= i & i < 'n);
    if mask[i] then {
      let input : bits('m) = vs2_val[i];
      output    : bits('m) = zeros();

      foreach (k from 0 to ('m - 8) by 8) {
	output[(k + 7)..k] = input[('m - k - 1) .. ('m - k - 8)];
      };

      result[i] = output;
    };
  };

  write_single_vreg(num_elem, 'm, vd, result);
  vstart = EXTZ(0b0);
  RETIRE_SUCCESS
}
