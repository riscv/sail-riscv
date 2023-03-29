/*
 * Vector Cryptography Extension - ShangMi Suite: SM3 Secure Hash
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

val	 rol32 : forall 'm, 32 - 'm >= 0 & 'm >= 0. (bits(32), int('m)) -> bits(32)
function rol32(X,N) = (X << N) | (X >> (32 - N))

val	 P1 : forall 'm, 'm == 32. (bits('m)) -> bits('m)
function P1(X) = ((X) ^ rol32((X), 15) ^ rol32((X), 23))

val	 ZVKSH_W : forall 'm, 'm == 32. (bits('m),bits('m),bits('m),bits('m),bits('m)) -> bits('m)
function ZVKSH_W(M16, M9, M3, M13, M6) =
  (P1(M6 ^ M9 ^ rol32(M3, 15)) ^ rol32(M13, 7) ^ M6)

val	 rev8 : forall 'm, 'm == 32. (bits('m)) -> bits('m)
function rev8(x) = {     // endian swap
  output : bits('m) = zeros();
  foreach (k from 0 to ('m - 8) by 8) {
    output[(k + 7)..k] = x[('m - k - 1)..('m - k - 8)];
  };

  output
}

/* VSM3ME.VV */

union clause ast = RISCV_VSM3ME_VV : (regidx, regidx, regidx)

mapping clause encdec = RISCV_VSM3ME_VV(vs2, vs1, vd) if (haveRVV() & haveZvksh())
 <-> 0b1000001 @ vs2 @ vs1 @ 0b010 @ vd @ 0b1110111   if (haveRVV() & haveZvksh())

mapping clause assembly = RISCV_VSM3ME_VV(vs2, vs1, vd)
 <-> "vsm3me.vv" ^ spc() ^ vreg_name(vd)
		 ^ sep() ^ vreg_name(vs2)
		 ^ sep() ^ vreg_name(vs1)

function clause execute (RISCV_VSM3ME_VV(vs2, vs1, vd)) = {
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
    assert(0 <= 7 & 7 < 'n);

    let vm_val  : vector('n, dec, bool)     = read_vmask(num_elem, 0b1, vreg_name("v0"));
    let vs2_val : vector('n, dec, bits('m)) = read_vreg(num_elem, SEW, LMUL_pow, vs2);
    let vs1_val : vector('n, dec, bits('m)) = read_vreg(num_elem, SEW, LMUL_pow, vs1);
    let vd_val  : vector('n, dec, bits('m)) = read_vreg(num_elem, SEW, LMUL_pow, vd);
    result      : vector('n, dec, bits('m)) = undefined;
    mask        : vector('n, dec, bool)     = undefined;

    (result, mask) = init_masked_result(num_elem, SEW, LMUL_pow, vd_val, vm_val);

    w : bits(512) = undefined;

    foreach (i from 0 to (num_elem - 1)) {
      w[255..0]   = to_bits(256, unsigned(vs1_val[i]));
      w[511..256] = to_bits(256, unsigned(vs2_val[i]));

      w15 = rev8(w[511..480]);
      w14 = rev8(w[479..448]);
      w13 = rev8(w[447..416]);
      w12 = rev8(w[415..384]);
      w11 = rev8(w[383..352]);
      w10 = rev8(w[351..320]);
      w9  = rev8(w[319..288]);
      w8  = rev8(w[287..256]);
      w7  = rev8(w[255..224]);
      w6  = rev8(w[223..192]);
      w5  = rev8(w[191..160]);
      w4  = rev8(w[159..128]);
      w3  = rev8(w[127..96]);
      w2  = rev8(w[95..64]);
      w1  = rev8(w[63..32]);
      w0  = rev8(w[31..0]);

      w16 = ZVKSH_W(w0, w7, w13, w3, w10);
      w17 = ZVKSH_W(w1, w8, w14, w4, w11);
      w18 = ZVKSH_W(w2, w9, w15, w5, w12);
      w19 = ZVKSH_W(w3, w10, w16, w6, w12);
      w20 = ZVKSH_W(w4, w11, w17, w7, w13);
      w21 = ZVKSH_W(w5, w12, w18, w8, w14);
      w22 = ZVKSH_W(w6, w13, w19, w9, w15);
      w23 = ZVKSH_W(w7, w14, w20, w10, w16);

      w16 = rev8(w16);
      w17 = rev8(w17);
      w18 = rev8(w18);
      w19 = rev8(w19);
      w20 = rev8(w20);
      w21 = rev8(w21);
      w22 = rev8(w22);
      w23 = rev8(w23);

      result[0] = w16;
      result[1] = w17;
      result[2] = w18;
      result[3] = w19;
      result[4] = w20;
      result[5] = w21;
      result[6] = w22;
      result[7] = w23;
    };

    write_single_vreg(num_elem, 'm, vd, result);
    RETIRE_SUCCESS
  }
}