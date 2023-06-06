/*
 * Vector Cryptography Extension - Vector GCM/GMAC
 * ----------------------------------------------------------------------
 */

/*
 * Helper functions.
 * ----------------------------------------------------------------------
 */

val	 zvk_check_elements : (int, int, int, int) -> bool
function zvk_check_elements(VLEN, num_elem, LMUL, SEW) = {
  ((unsigned(vl)%num_elem) != 0) | ((unsigned(vstart)%num_elem) != 0) | (LMUL*VLEN) < (num_elem*SEW)
}

val      brev8 : forall 'm, 'm >= 0 & 'm <= 128. (bits('m)) -> bits('m)
function brev8(vec) = {
  input = vec;
  output : bits('m) = to_bits('m, 0);
  foreach (j from 0 to ('m - 8) by 8) {
    output[j+7..j] = reverse_bits_in_byte(input[j+7..j]);
  };

  output
}

/* VGHSH.VV */

union clause ast = RISCV_VGHSH_VV : (regidx, regidx, regidx)

mapping clause encdec = RISCV_VGHSH_VV(vs2, vs1, vd) if (haveRVV() & haveZvkg())
 <-> 0b1011001 @ vs2 @ vs1 @ 0b010 @ vd @ 0b1110111  if (haveRVV() & haveZvkg())

mapping clause assembly = RISCV_VGHSH_VV(vs2, vs1, vd)
 <-> "vghsh.vv" ^ spc() ^ vreg_name(vd)
		^ sep() ^ vreg_name(vs2)
		^ sep() ^ vreg_name(vs1)

function clause execute (RISCV_VGHSH_VV(vs2, vs1, vd)) = {
let SEW      = get_sew();
  let LMUL_pow = get_lmul_pow();
  let LMUL     = if LMUL_pow < 0 then 0 else LMUL_pow;
  let VLEN     = int_power(2, get_vlen_pow());
  let num_elem = get_num_elem(LMUL_pow, SEW);

  if (zvk_check_elements(VLEN, num_elem, LMUL, SEW) == false)
  then {
    handle_illegal();
    RETIRE_FAIL
  } else {
    let 'n = num_elem;
    let 'm = SEW;
    assert('m == 32);

    let vs2_val : vector('n, dec, bits('m)) = read_vreg(num_elem, SEW, LMUL_pow, vs2);
    let vs1_val : vector('n, dec, bits('m)) = read_vreg(num_elem, SEW, LMUL_pow, vs1);
    let vd_val  : vector('n, dec, bits('m)) = read_vreg(num_elem, SEW, LMUL_pow, vd);
    result      : vector('n, dec, bits('m)) = undefined;

    Y : bits(128) = undefined;
    X : bits(128) = undefined;
    H : bits(128) = undefined;
    Z : bits(128) = undefined;
    S : bits(128) = undefined;

    eg_len = (unsigned(vl) / 'n);
    eg_start = (unsigned(vstart) / 'n);

    foreach (i from eg_start to (eg_len - 1)) {
      assert(0 <= ((i * 4) + 3) & ((i * 4) + 3) < 'n);

      // Current partial-hash
      Y[31..0]   = vd_val[i*4+0];
      Y[63..32]  = vd_val[i*4+1];
      Y[95..64]  = vd_val[i*4+2];
      Y[127..96] = vd_val[i*4+3];
      // Block cipher output
      X[31..0]   = vs1_val[i*4+0];
      X[63..32]  = vs1_val[i*4+1];
      X[95..64]  = vs1_val[i*4+2];
      X[127..96] = vs1_val[i*4+3];
      // Hash subkey
      H[31..0]   = brev8(vs2_val[i*4+0]);
      H[63..32]  = brev8(vs2_val[i*4+1]);
      H[95..64]  = brev8(vs2_val[i*4+2]);
      H[127..96] = brev8(vs2_val[i*4+3]);

      Z = zeros();
      S = brev8(Y ^ X);

      foreach (b from 0 to 127 by 1) {
	if bit_to_bool(S[b])
	then Z = Z ^ H;

	reduce : bool = bit_to_bool(H[127]);

	H = H << 1;
	if (reduce)
	// Reduce using x^7 + x^2 + x^1 + 1 polynomial
	then H = xor_vec(H, to_bits(128, unsigned(0x87)));
      };

      assert(0 <= 'n & 3 < 'n);
      // Bit reverse bytes to get back to GCM standard ordering
      let res = brev8(Z);
      result[i*4+0] = res[31..0];
      result[i*4+1] = res[63..32];
      result[i*4+2] = res[95..64];
      result[i*4+3] = res[127..96];
    };

    write_single_vreg(num_elem, 'm, vd, result);
    RETIRE_SUCCESS
  }
}

/* VGMUL.VV */

union clause ast = RISCV_VGMUL_VV : (regidx, regidx)

mapping clause encdec = RISCV_VGMUL_VV(vs2, vd)		if (haveRVV() & haveZvkg())
 <-> 0b1010001 @ vs2 @ 0b10001 @ 0b010 @ vd @ 0b1110111 if (haveRVV() & haveZvkg())

mapping clause assembly = RISCV_VGMUL_VV(vs2, vd)
 <-> "vgmul.vv" ^ spc() ^ vreg_name(vd)
		^ sep() ^ vreg_name(vs2)

function clause execute (RISCV_VGMUL_VV(vs2, vd)) = {
  let SEW      = get_sew();
  let LMUL_pow = get_lmul_pow();
  let LMUL     = if LMUL_pow < 0 then 0 else LMUL_pow;
  let VLEN     = int_power(2, get_vlen_pow());
  let num_elem = get_num_elem(LMUL_pow, SEW);

  if (zvk_check_elements(VLEN, num_elem, LMUL, SEW) == false)
  then {
    handle_illegal();
    RETIRE_FAIL
  } else {
    let 'n = num_elem;
    let 'm = SEW;
    assert('m == 32);

    let vs2_val : vector('n, dec, bits('m)) = read_vreg(num_elem, SEW, LMUL_pow, vs2);
    let vd_val  : vector('n, dec, bits('m)) = read_vreg(num_elem, SEW, LMUL_pow, vd);
    result      : vector('n, dec, bits('m)) = undefined;

    Y : bits(128) = undefined;
    H : bits(128) = undefined;
    Z : bits(128) = undefined;

    eg_len = (unsigned(vl) / 'n);
    eg_start = (unsigned(vstart) / 'n);

    foreach (i from eg_start to (eg_len - 1)) {
      assert(0 <= ((i * 4) + 3) & ((i * 4) + 3) < 'n);

      // Current partial-hash
      Y[31..0]   = brev8(vd_val[i*4+0]);
      Y[63..32]  = brev8(vd_val[i*4+1]);
      Y[95..64]  = brev8(vd_val[i*4+2]);
      Y[127..96] = brev8(vd_val[i*4+3]);
      // Block cipher output
      H[31..0]   = brev8(vs2_val[i*4+0]);
      H[63..32]  = brev8(vs2_val[i*4+1]);
      H[95..64]  = brev8(vs2_val[i*4+2]);
      H[127..96] = brev8(vs2_val[i*4+3]);

      Z : bits(128) = zeros();

      foreach (b from 0 to 127 by 1) {
	if bit_to_bool(Y[b])
	then Z = Z ^ H;

	reduce : bool = bit_to_bool(H[127]);

	H = H << 1;
	if (reduce)
	// Reduce using x^7 + x^2 + x^1 + 1 polynomial
	then H = H ^ to_bits(128, unsigned(0x87));
      };

      assert(0 <= 'n & 3 < 'n);
      let res = brev8(Z);
      result[i*4+0] = res[31..0];
      result[i*4+1] = res[63..32];
      result[i*4+2] = res[95..64];
      result[i*4+3] = res[127..96];
    };

    write_single_vreg(num_elem, 'm, vd, result);

    RETIRE_SUCCESS
  }
}
