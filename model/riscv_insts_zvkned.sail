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
