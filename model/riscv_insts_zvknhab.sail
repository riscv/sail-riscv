/*
 * Vector Cryptography Extension - NIST Suite: Vector SHA-2 Secure Hash
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

val ROTR : forall 'n 'm, 'm >= 0. (bits('n), bits('m), bits('m)) -> bits('n)
function ROTR (x, n, SEW) = (x >> n) | (x << (SEW - n))

val SHR : forall 'n 'm, 'm >= 0. (bits('n), bits('m)) -> bits('n)
function SHR (x, n) = x >> n


val sig0 : forall 'n, 'n >= 0. (bits('n), int) -> bits('n)
function sig0 (x, SEW) = {
  let sew_bits : bits('n) = to_bits('n, SEW);
  match SEW {
    32 => (ROTR(x, to_bits('n, 7), sew_bits) ^ ROTR(x, to_bits('n, 18), sew_bits) ^ SHR(x, to_bits('n, 3))),
    64 => (ROTR(x, to_bits('n, 1), sew_bits) ^ ROTR(x, to_bits('n, 8),  sew_bits) ^ SHR(x, to_bits('n, 7))),
  }
}

val sig1 : forall 'n, 'n >= 0. (bits('n), int) -> bits('n)
function sig1 (x, SEW) = {
  let sew_bits : bits('n) = to_bits('n, SEW);
  match SEW {
    32 => (ROTR(x, to_bits('n, 17), sew_bits) ^ ROTR(x, to_bits('n, 19), sew_bits) ^ SHR(x, to_bits('n, 10))),
    64 => (ROTR(x, to_bits('n, 19), sew_bits) ^ ROTR(x, to_bits('n, 61), sew_bits) ^ SHR(x, to_bits('n, 6 ))),
  }
}

val ch : forall 'n, 'n >= 0. (bits('n), bits('n), bits('n)) -> bits('n)
function ch (x, y, z) = ((x & y) ^ (not_vec(x) & z))

val maj : forall 'n, 'n >= 0. (bits('n), bits('n), bits('n)) -> bits('n)
function maj (x, y, z) = ((x & y) ^ (x & z) ^ (y & z))

val sum0 : forall 'n, 'n >= 0. (bits('n), int) -> bits('n)
function sum0 (x, SEW) = {
  let sew_bits : bits('n) = to_bits('n, SEW);
  match SEW {
    32 => (ROTR(x, to_bits('n, 2), sew_bits)  ^ ROTR(x, to_bits('n, 13), sew_bits) ^ ROTR(x, to_bits('n, 22), sew_bits)),
    64 => (ROTR(x, to_bits('n, 28), sew_bits) ^ ROTR(x, to_bits('n, 34), sew_bits) ^ ROTR(x, to_bits('n, 39), sew_bits)),
  }
}

val sum1 : forall 'n, 'n >= 0. (bits('n), int) -> bits('n)
function sum1 (x, SEW) = {
  let sew_bits : bits('n) = to_bits('n, SEW);
  match SEW {
    32 => (ROTR(x, to_bits('n, 6), sew_bits)  ^ ROTR(x, to_bits('n, 11), sew_bits) ^ ROTR(x, to_bits('n, 25), sew_bits)),
    64 => (ROTR(x, to_bits('n, 14), sew_bits) ^ ROTR(x, to_bits('n, 18), sew_bits) ^ ROTR(x, to_bits('n, 41), sew_bits)),
  }
}

/* VSHA2MS.VV */

union clause ast = RISCV_VSHA2ms : (regidx, regidx, regidx)

mapping clause encdec = RISCV_VSHA2ms(vs2, vs1, vd) if (haveRVV() & (haveZvknha() | haveZvknhb()))
 <-> 0b1011011 @ vs2 @ vs1 @ 0b010 @ vd @ 0b1110111 if (haveRVV() & (haveZvknha() | haveZvknhb()))

mapping clause assembly = RISCV_VSHA2ms(vs2, vs1, vd)
 <-> "vsha2ms.vv" ^ spc() ^ vreg_name(vd) ^ sep() ^ vreg_name(vs1) ^ vreg_name(vs2)

function clause execute (RISCV_VSHA2ms(vs2, vs1, vd)) = {
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
    assert('m == 32 | 'm == 64);

    let vs2_val : vector('n, dec, bits('m)) = read_vreg(num_elem, SEW, LMUL_pow, vs2);
    let vs1_val : vector('n, dec, bits('m)) = read_vreg(num_elem, SEW, LMUL_pow, vs1);
    let vd_val  : vector('n, dec, bits('m)) = read_vreg(num_elem, SEW, LMUL_pow, vd);
    result      : vector('n, dec, bits('m)) = undefined;

    eg_len = (unsigned(vl) / 'n);
    eg_start = (unsigned(vstart) / 'n);

    foreach (i from eg_start to (eg_len - 1)) {
      assert(0 <= ((i * 4) + 3) & ((i * 4) + 3) < 'n);

      w : vector(20, dec, bits('m)) = undefined;

      w[0]  = vd_val[i*4+0];
      w[1]  = vd_val[i*4+1];
      w[2]  = vd_val[i*4+2];
      w[3]  = vd_val[i*4+3];

      w[4]  = vs2_val[i*4+0];
      w[9]  = vs2_val[i*4+1];
      w[10] = vs2_val[i*4+2];
      w[11] = vs2_val[i*4+3];

      w[12] = vs1_val[i*4+0];
      w[13] = vs1_val[i*4+1];
      w[14] = vs1_val[i*4+2];
      w[15] = vs1_val[i*4+3];

      w[16] = sig1(w[14], SEW) + w[9] +  sig0(w[1], SEW) + w[0];
      w[17] = sig1(w[15], SEW) + w[10] + sig0(w[2], SEW) + w[1];
      w[18] = sig1(w[16], SEW) + w[11] + sig0(w[3], SEW) + w[2];
      w[19] = sig1(w[17], SEW) + w[12] + sig0(w[4], SEW) + w[3];

      assert(0 <= 3 & 3 < 'n);
      result[i*4+0] = w[16];
      result[i*4+1] = w[17];
      result[i*4+2] = w[18];
      result[i*4+3] = w[19];
    };

    write_single_vreg(num_elem, 'm, vd, result);
    vstart = EXTZ(0b0);
    RETIRE_SUCCESS
  }
}

/* VSHA2C[HL].VV */

mapping ch_or_cl : string <-> bits(7) = {
  "ch" <-> 0b1011101,
  "cl" <-> 0b1011111,
}

mapping vsha2c_mnemonic : bits(7) <-> string = {
  0b1011101 <-> "vsha2ch.vv",
  0b1011111 <-> "vsha2cl.vv",
}

union clause ast = RISCV_VSHA2c : (regidx, regidx, regidx, string)

mapping clause encdec = RISCV_VSHA2c(vs2, vs1, vd, suffix) if (haveRVV() & (haveZvknha() | haveZvknhb()))
 <-> ch_or_cl(suffix) @ vs2 @ vs1 @ 0b010 @ vd @ 0b1110111 if (haveRVV() & (haveZvknha() | haveZvknhb()))

mapping clause assembly = RISCV_VSHA2c(vs2, vs1, vd, suffix)
 <-> vsha2c_mnemonic(ch_or_cl(suffix)) ^ spc() ^ vreg_name(vd)
				       ^ spc() ^ vreg_name(vs2)
				       ^ spc() ^ vreg_name(vs1)

function clause execute (RISCV_VSHA2c(vs2, vs1, vd, suffix)) = {
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
    assert('m == 32 | 'm == 64);

    let vs2_val : vector('n, dec, bits('m)) = read_vreg(num_elem, SEW, LMUL_pow, vs2);
    let vs1_val : vector('n, dec, bits('m)) = read_vreg(num_elem, SEW, LMUL_pow, vs1);
    let vd_val  : vector('n, dec, bits('m)) = read_vreg(num_elem, SEW, LMUL_pow, vd);
    result      : vector('n, dec, bits('m)) = undefined;

    foreach (i from 0 to (num_elem - 1)) {
      assert(0 <= ((i * 4) + 3) & ((i * 4) + 3) < 'n);

      a = vs2_val[i*4+0];
      b = vs2_val[i*4+1];
      e = vs2_val[i*4+2];
      f = vs2_val[i*4+3];

      c = vd_val[i*4+0];
      d = vd_val[i*4+1];
      g = vd_val[i*4+2];
      h = vd_val[i*4+3];

      MessageSchedPlusC = vs1_val[i*4+3]
                        @ vs1_val[i*4+2]
                        @ vs1_val[i*4+1]
                        @ vs1_val[i*4+0];

      w0 =
	 if suffix == "cl" then MessageSchedPlusC[('m * 1) - 1..0]
	 else MessageSchedPlusC[('m * 4) - 1..('m * 3)];
      w1 =
	 if suffix == "cl" then MessageSchedPlusC[('m * 1) - 1..0]
	 else MessageSchedPlusC[('m * 4) - 1..('m * 3)];

      T1 = h + sum1(e, 'm) + ch(e,f,g) + to_bits('m, unsigned(w0));
      T2 = sum0(a, 'm) + maj(a, b, c);
      h  = g;
      g  = f;
      f  = e;
      e  = d + T1;
      d  = c;
      c  = b;
      b  = a;
      a  = T1 + T2;

      T1 = h + sum1(e, 'm) + ch(e, f, g) + to_bits('m, unsigned(w1));
      T2 = sum0(a, 'm) + maj(a, b, c);
      h  = g;
      g  = f;
      f  = e;
      e  = d + T1;
      d  = c;
      c  = b;
      b  = a;
      a  = T1 + T2;

      result[i*4+0] = f;
      result[i*4+1] = e;
      result[i*4+2] = b;
      result[i*4+3] = a;
    };

    write_single_vreg(num_elem, 'm, vd, result);
    vstart = EXTZ(0b0);
    RETIRE_SUCCESS
  }
}
