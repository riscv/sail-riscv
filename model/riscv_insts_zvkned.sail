/*
 * Vector Cryptography Extension - NIST Suite: Vecttor AES Block Cipher
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

mapping vv_or_vs : string <-> bits(7) = {
  "vv" <-> 0b1010001,
  "vs" <-> 0b1010011,
}

val	 aes_rotword : bits(32) -> bits(32)
function aes_rotword(x) = {
  let a0 : bits (8) = x[ 7.. 0];
  let a1 : bits (8) = x[15.. 8];
  let a2 : bits (8) = x[23..16];
  let a3 : bits (8) = x[31..24];
  (a0 @ a3 @ a2 @ a1) /* Return Value */
}

/* VAESEF.[VV, VS] */

mapping vaesef_mnemonic : bits(7) <-> string = {
  0b1010001 <-> "vaesef.vv",
  0b1010011 <-> "vaesef.vs",
}

union clause ast = RISCV_VAESEF : (regidx, regidx, string)

mapping clause encdec = RISCV_VAESEF(vs2, vd, suffix)	       if (haveRVV() & haveZvkned())
 <-> vv_or_vs(suffix) @ vs2 @ 0b00011 @ 0b010 @ vd @ 0b1110111 if (haveRVV() & haveZvkned())

mapping clause assembly = RISCV_VAESEF(vs2, vd, suffix)
 <-> vaesef_mnemonic(vv_or_vs(suffix)) ^ spc() ^ vreg_name(vd)
				       ^ spc() ^ vreg_name(vs2)

function clause execute (RISCV_VAESEF(vs2, vd, suffix)) = {
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

    vd_state : bits(128) = undefined;
    vs2_key  : bits(128) = undefined;

    eg_len = (unsigned(vl) / 'n);
    eg_start = (unsigned(vstart) / 'n);

    foreach (i from eg_start to (eg_len - 1)) {
      assert(0 <= ((i * 4) + 3) & ((i * 4) + 3) < 'n);
      vd_state[31..0]   = vd_val[i*4+0];
      vd_state[63..32]  = vd_val[i*4+1];
      vd_state[95..64]  = vd_val[i*4+2];
      vd_state[127..96] = vd_val[i*4+3];

      if suffix == "vv" then {
	vs2_key[31..0]   = vs2_val[i*4+0];
	vs2_key[63..32]  = vs2_val[i*4+1];
	vs2_key[95..64]  = vs2_val[i*4+2];
	vs2_key[127..96] = vs2_val[i*4+3];
      } else {
	vs2_key[31..0]   = vs2_val[0];
	vs2_key[63..32]  = vs2_val[1];
	vs2_key[95..64]  = vs2_val[2];
	vs2_key[127..96] = vs2_val[3];
      };

      let sb       : bitvector(128, dec) = aes_subbytes_fwd(vd_state);
      let sr       : bitvector(128, dec) = aes_shift_rows_fwd(sb);
      ark		 : bitvector(128, dec) = sr ^ vs2_key;

      result[i*4+0] = ark[31..0];
      result[i*4+1] = ark[63..32];
      result[i*4+2] = ark[95..64];
      result[i*4+3] = ark[127..96];
    };

    write_single_vreg(num_elem, 'm, vd, result);
    vstart = EXTZ(0b0);
    RETIRE_SUCCESS
  }
}

/* VAESEM.[VV, VS] */

mapping vaesem_mnemonic : bits(7) <-> string = {
  0b1010001 <-> "vaesem.vv",
  0b1010011 <-> "vaesem.vs",
}

union clause ast = RISCV_VAESEM : (regidx, regidx, string)

mapping clause encdec = RISCV_VAESEM(vs2, vd, suffix)	       if (haveRVV() & haveZvkned())
 <-> vv_or_vs(suffix) @ vs2 @ 0b00010 @ 0b010 @ vd @ 0b1110111 if (haveRVV() & haveZvkned())

mapping clause assembly = RISCV_VAESEM(vs2, vd, suffix)
 <-> vaesem_mnemonic(vv_or_vs(suffix)) ^ spc() ^ vreg_name(vd)
				       ^ sep() ^ vreg_name(vs2)

function clause execute (RISCV_VAESEM(vs2, vd, suffix)) = {
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

    vd_state : bits(128) = undefined;
    vs2_key  : bits(128) = undefined;

    eg_len = (unsigned(vl) / 'n);
    eg_start = (unsigned(vstart) / 'n);

    foreach (i from eg_start to (eg_len - 1)) {
      assert(0 <= ((i * 4) + 3) & ((i * 4) + 3) < 'n);
      vd_state[31..0]   = vd_val[i*4+0];
      vd_state[63..32]  = vd_val[i*4+1];
      vd_state[95..64]  = vd_val[i*4+2];
      vd_state[127..96] = vd_val[i*4+3];

      if suffix == "vv" then {
	vs2_key[31..0]   = vs2_val[i*4+0];
	vs2_key[63..32]  = vs2_val[i*4+1];
	vs2_key[95..64]  = vs2_val[i*4+2];
	vs2_key[127..96] = vs2_val[i*4+3];
      } else {
	vs2_key[31..0]   = vs2_val[0];
	vs2_key[63..32]  = vs2_val[1];
	vs2_key[95..64]  = vs2_val[2];
	vs2_key[127..96] = vs2_val[3];
      };

      let sb       : bitvector(128, dec) = aes_subbytes_fwd(vd_state);
      let sr       : bitvector(128, dec) = aes_shift_rows_fwd(sb);
      let mix      : bitvector(128, dec) = aes_mixcolumns_fwd(sr);
      let ark      : bitvector(128, dec) = mix ^ vs2_key;

      result[i*4+0] = ark[31..0];
      result[i*4+1] = ark[63..32];
      result[i*4+2] = ark[95..64];
      result[i*4+3] = ark[127..96];
    };

    write_single_vreg(num_elem, 'm, vd, result);
    vstart = EXTZ(0b0);
    RETIRE_SUCCESS
  }
}

/* VAESDF.VV */

mapping vaesdf_mnemonic : bits(7) <-> string = {
  0b1010001 <-> "vaesdf.vv",
  0b1010011 <-> "vaesdf.vs",
}

union clause ast = RISCV_VAESDF : (regidx, regidx, string)

mapping clause encdec = RISCV_VAESDF(vs2, vd, suffix)		if (haveRVV() & haveZvkned())
 <-> vv_or_vs(suffix) @ vs2 @ 0b00001 @ 0b010 @ vd @ 0b1110111	if (haveRVV() & haveZvkned())

mapping clause assembly = RISCV_VAESDF(vs2, vd, suffix)
 <-> vaesdf_mnemonic(vv_or_vs(suffix)) ^ sep() ^ vreg_name(vd)
				       ^ sep() ^ vreg_name(vs2)

function clause execute (RISCV_VAESDF(vs2, vd, suffix)) = {
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

    vd_state : bits(128) = undefined;
    vs2_key  : bits(128) = undefined;

    eg_len = (unsigned(vl) / 'n);
    eg_start = (unsigned(vstart) / 'n);

    foreach (i from eg_start to (eg_len - 1)) {
      assert(0 <= ((i * 4) + 3) & ((i * 4) + 3) < 'n);
      vd_state[31..0]   = vd_val[i*4+0];
      vd_state[63..32]  = vd_val[i*4+1];
      vd_state[95..64]  = vd_val[i*4+2];
      vd_state[127..96] = vd_val[i*4+3];

      if suffix == "vv" then {
	vs2_key[31..0]   = vs2_val[i*4+0];
	vs2_key[63..32]  = vs2_val[i*4+1];
	vs2_key[95..64]  = vs2_val[i*4+2];
	vs2_key[127..96] = vs2_val[i*4+3];
      } else {
	vs2_key[31..0]   = vs2_val[0];
	vs2_key[63..32]  = vs2_val[1];
	vs2_key[95..64]  = vs2_val[2];
	vs2_key[127..96] = vs2_val[3];
      };

      let sr       : bits(128) = aes_shift_rows_inv(vd_state);
      let sb       : bits(128) = aes_subbytes_inv(sr);
      let ark      : bits(128) = sb ^ vs2_key;

      result[i*4+0] = ark[31..0];
      result[i*4+1] = ark[63..32];
      result[i*4+2] = ark[95..64];
      result[i*4+3] = ark[127..96];
    };

    write_single_vreg(num_elem, 'm, vd, result);
    vstart = EXTZ(0b0);
    RETIRE_SUCCESS
  }
}

/* VAESDM.VV */

mapping vaesdm_mnemonic : bits(7) <-> string = {
  0b1010001 <-> "vaesem.vv",
  0b1010011 <-> "vaesem.vs",
}

union clause ast = RISCV_VAESDM : (regidx, regidx, string)

mapping clause encdec = RISCV_VAESDM(vs2, vd, suffix)	       if (haveRVV() & haveZvkned())
 <-> vv_or_vs(suffix) @ vs2 @ 0b00000 @ 0b010 @ vd @ 0b1110111 if (haveRVV() & haveZvkned())

mapping clause assembly = RISCV_VAESDM(vs2, vd, suffix)
 <-> vaesdm_mnemonic(vv_or_vs(suffix)) ^ spc() ^ vreg_name(vd)
				       ^ sep() ^ vreg_name(vs2)

function clause execute (RISCV_VAESDM(vs2, vd, suffix)) = {
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

    vd_state : bits(128) = undefined;
    vs2_key  : bits(128) = undefined;

    eg_len = (unsigned(vl) / 'n);
    eg_start = (unsigned(vstart) / 'n);

    foreach (i from eg_start to (eg_len - 1)) {
      assert(0 <= ((i * 4) + 3) & ((i * 4) + 3) < 'n);
      vd_state[31..0]   = vd_val[i*4+0];
      vd_state[63..32]  = vd_val[i*4+1];
      vd_state[95..64]  = vd_val[i*4+2];
      vd_state[127..96] = vd_val[i*4+3];

      if suffix == "vv" then {
	vs2_key[31..0]   = vs2_val[i*4+0];
	vs2_key[63..32]  = vs2_val[i*4+1];
	vs2_key[95..64]  = vs2_val[i*4+2];
	vs2_key[127..96] = vs2_val[i*4+3];
      } else {
	vs2_key[31..0]   = vs2_val[0];
	vs2_key[63..32]  = vs2_val[1];
	vs2_key[95..64]  = vs2_val[2];
	vs2_key[127..96] = vs2_val[3];
      };

      let sr       : bits(128) = aes_shift_rows_inv(vd_state);
      let sb       : bits(128) = aes_subbytes_inv(sr);
      let ark      : bits(128) = sb ^ vs2_key;
      let mix      : bits(128) = aes_mixcolumns_inv(ark);

      result[i*4+0] = mix[31..0];
      result[i*4+1] = mix[63..32];
      result[i*4+2] = mix[95..64];
      result[i*4+3] = mix[127..96];
    };

    write_single_vreg(num_elem, 'm, vd, result);
    vstart = EXTZ(0b0);
    RETIRE_SUCCESS
  }
}

/* VAESKF1.VI */

union clause ast = RISCV_VAESKF1_VI : (regidx, regidx, regidx)

mapping clause encdec = RISCV_VAESKF1_VI(vs2, rnd, vd) if (haveRVV() & haveZvkned())
 <-> 0b1000101 @ vs2 @ rnd @ 0b010 @ vd @ 0b1110111    if (haveRVV() & haveZvkned())

mapping clause assembly = RISCV_VAESKF1_VI(vs2, rnd, vd)
 <-> "vaeskf1.vi" ^ sep() ^ vreg_name(vd)
		  ^ sep() ^ vreg_name(vs2)
		  ^ sep() ^ reg_name(rnd)

function clause execute (RISCV_VAESKF1_VI(vs2, rnd, vd)) = {
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

    rnd_val	: bits(5)		    = rnd;
    let vs2_val : vector('n, dec, bits('m)) = read_vreg(num_elem, SEW, LMUL_pow, vs2);
    let vd_val  : vector('n, dec, bits('m)) = read_vreg(num_elem, SEW, LMUL_pow, vd);
    result      : vector('n, dec, bits('m)) = undefined;

    if (unsigned(rnd_val[3..0]) > 10) | (unsigned(rnd_val[3..0]) == 0)
    then rnd_val[3] = not_bit(rnd_val[3]);

    let r : bits(4) = rnd_val[3..0] - 1;

    current_round_key : bits(128) = undefined;
    w		      : bits(128) = undefined;

    eg_len = (unsigned(vl) / 'n);
    eg_start = (unsigned(vstart) / 'n);

    foreach (i from eg_start to (eg_len - 1)) {
      assert(0 <= ((i * 4) + 3) & ((i * 4) + 3) < 'n);
      current_round_key[31..0]   = vs2_val[i*4+0];
      current_round_key[63..32]  = vs2_val[i*4+1];
      current_round_key[95..64]  = vs2_val[i*4+2];
      current_round_key[127..96] = vs2_val[i*4+3];

      w[31..0] = aes_subword_fwd(aes_rotword(current_round_key[127..96]))
	       ^ aes_decode_rcon(r)
	       ^ current_round_key[31..0];
      w[63..32]  = w[31..0]  ^ current_round_key[63..32];
      w[95..64]  = w[63..32] ^ current_round_key[95..64];
      w[127..96] = w[95..64] ^ current_round_key[127..96];

      result[i*4+0] = w[31..0];
      result[i*4+1] = w[63..32];
      result[i*4+2] = w[95..64];
      result[i*4+3] = w[127..96];
    };

    write_single_vreg(num_elem, 'm, vd, result);
    vstart = EXTZ(0b0);
    RETIRE_SUCCESS
  }
}

/* VAESKF2.VI */

union clause ast = RISCV_VAESKF2_VI : (regidx, regidx, regidx)

mapping clause encdec = RISCV_VAESKF2_VI(vs2, rnd, vd) if (haveRVV() & haveZvkned())
 <-> 0b1010101 @ vs2 @ rnd @ 0b010 @ vd @ 0b1110111    if (haveRVV() & haveZvkned())

mapping clause assembly = RISCV_VAESKF2_VI(vs2, rnd, vd)
 <-> "vaeskf2.vi" ^ sep() ^ vreg_name(vd)
		  ^ sep() ^ vreg_name(vs2)
		  ^ sep() ^ reg_name(rnd)

function clause execute (RISCV_VAESKF2_VI(vs2, rnd, vd)) = {
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

    rnd_val : bits(4)                   = rnd[3..0];
    let vs2_val : vector('n, dec, bits('m)) = read_vreg(num_elem, SEW, LMUL_pow, vs2);
    let vd_val  : vector('n, dec, bits('m)) = read_vreg(num_elem, SEW, LMUL_pow, vd);
    result      : vector('n, dec, bits('m)) = undefined;

    if (unsigned(rnd_val) < 2) | (unsigned(rnd_val) > 14)
    then rnd_val[3] = not_bit(rnd_val[3]);

    current_round_key : bits(128) = undefined;
    round_key_b       : bits(128) = undefined;
    w		      : bits(128) = undefined;

    eg_len = (unsigned(vl) / 'n);
    eg_start = (unsigned(vstart) / 'n);

    foreach (i from eg_start to (eg_len - 1)) {
      assert(0 <= ((i * 4) + 3) & ((i * 4) + 3) < 'n);
      current_round_key[31..0]   = vs2_val[i*4+0];
      current_round_key[63..32]  = vs2_val[i*4+1];
      current_round_key[95..64]  = vs2_val[i*4+2];
      current_round_key[127..96] = vs2_val[i*4+3];

      round_key_b[31..0]   = vd_val[i*4+0];
      round_key_b[63..32]  = vd_val[i*4+1];
      round_key_b[95..64]  = vd_val[i*4+2];
      round_key_b[127..96] = vd_val[i*4+3];

      w[31..0] = if (rnd_val[0] == bitone)
		 then
		   aes_subword_fwd(current_round_key[127..96]) ^ round_key_b[31..0]
		 else
		   aes_subword_fwd(aes_rotword(current_round_key[127..96]))
		     ^ aes_decode_rcon(rnd_val >> 1)
		     ^ round_key_b[31..0];

      w[63..32]  = w[31..0]  ^ round_key_b[63..32];
      w[95..64]  = w[63..32] ^ round_key_b[95..64];
      w[127..96] = w[95..64] ^ round_key_b[127..96];

      result[i*4+0] = w[31..0];
      result[i*4+1] = w[63..32];
      result[i*4+2] = w[95..64];
      result[i*4+3] = w[127..96];
    };

    write_single_vreg(num_elem, 'm, vd, result);
    vstart = EXTZ(0b0);
    RETIRE_SUCCESS
  }
}

/* VAESZ.VS */

union clause ast = RISCV_VAESZ_VS : (regidx, regidx)

mapping clause encdec = RISCV_VAESZ_VS(vs2, vd)		if (haveRVV() & haveZvkned())
 <-> 0b1010011 @ vs2 @ 0b00111 @ 0b010 @ vd @ 0b1110111 if (haveRVV() & haveZvkned())

mapping clause assembly = RISCV_VAESZ_VS(vs2, vd)
 <-> "vaesz.vs" ^ sep() ^ vreg_name(vd)
		^ sep() ^ vreg_name(vs2)

function clause execute (RISCV_VAESZ_VS(vs2, vd)) = {
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

    vd_state : bits(128) = undefined;
    vs2_key  : bits(128) = undefined;

    eg_len = (unsigned(vl) / 'n);
    eg_start = (unsigned(vstart) / 'n);

    foreach (i from eg_start to (eg_len - 1)) {
      assert(0 <= ((i * 4) + 3) & ((i * 4) + 3) < 'n);
      vd_state[31..0]   = vd_val[i*4+0];
      vd_state[63..32]  = vd_val[i*4+1];
      vd_state[95..64]  = vd_val[i*4+2];
      vd_state[127..96] = vd_val[i*4+3];

      vs2_key[31..0]   = vs2_val[0];
      vs2_key[63..32]  = vs2_val[1];
      vs2_key[95..64]  = vs2_val[2];
      vs2_key[127..96] = vs2_val[3];

      let ark : bits(128) = vd_state ^ vs2_key;

      result[i*4+0] = ark[31..0];
      result[i*4+1] = ark[63..32];
      result[i*4+2] = ark[95..64];
      result[i*4+3] = ark[127..96];
    };

    write_single_vreg(num_elem, 'm, vd, result);
    vstart = EXTZ(0b0);
    RETIRE_SUCCESS
  }
}
