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

val	 P0  : forall 'm, 'm == 32. (bits('m)) -> bits('m)
function P0(X) = ((X) ^ rol32((X),  9) ^ rol32((X), 17))

val	 P1 : forall 'm, 'm == 32. (bits('m)) -> bits('m)
function P1(X) = ((X) ^ rol32((X), 15) ^ rol32((X), 23))

val	 ZVKSH_W : forall 'm, 'm == 32. (bits('m), bits('m), bits('m), bits('m), bits('m)) -> bits('m)
function ZVKSH_W(M16, M9, M3, M13, M6) =
  (P1(M16 ^ M9 ^ rol32(M3, 15)) ^ rol32(M13, 7) ^ M6)

val	 rev8 : forall 'm, 'm == 32. (bits('m)) -> bits('m)
function rev8(x) = {     // endian swap
  output : bits('m) = zeros();
  foreach (k from 0 to ('m - 8) by 8) {
    output[(k + 7)..k] = x[('m - k - 1)..('m - k - 8)];
  };

  output
}

val	 FF1: forall 'm, 'm == 32. (bits('m), bits('m), bits('m)) -> bits('m)
function FF1(X, Y, Z) = ((X) ^ (Y) ^ (Z))

val	 FF2: forall 'm, 'm == 32. (bits('m), bits('m), bits('m)) -> bits('m)
function FF2(X, Y, Z) = (((X) & (Y)) | ((X) & (Z)) | ((Y) & (Z)))

val	 FF_j: forall 'm, 'm == 32. (bits('m), bits('m), bits('m), int) -> bits(32)
function FF_j(X, Y, Z, J) = if (J <= 15) then FF1(X, Y, Z) else FF2(X, Y, Z)

val	 GG1: forall 'm, 'm == 32. (bits('m), bits('m), bits('m)) -> bits('m)
function GG1(X, Y, Z) = ((X) ^ (Y) ^ (Z))

val	 GG2: forall 'm, 'm == 32. (bits('m), bits('m), bits('m)) -> bits('m)
function GG2(X, Y, Z) = (((X) & (Y)) | ((~(X)) & (Z)))

val	 GG_j: forall 'm, 'm == 32. (bits('m), bits('m), bits('m), int) -> bits(32)
function GG_j(X, Y, Z, J) = if (J <= 15) then GG1(X, Y, Z) else GG2(X, Y, Z)

val	 T_j : (int) -> bits(32)
function T_j(J) = if (J <= 15) then 0x79CC4519 else 0x7A879D8A

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

    let vs2_val : vector('n, dec, bits('m)) = read_vreg(num_elem, SEW, LMUL_pow, vs2);
    let vs1_val : vector('n, dec, bits('m)) = read_vreg(num_elem, SEW, LMUL_pow, vs1);
    let vd_val  : vector('n, dec, bits('m)) = read_vreg(num_elem, SEW, LMUL_pow, vd);
    result      : vector('n, dec, bits('m)) = undefined;

    eg_len = (unsigned(vl) / 'n);
    eg_start = (unsigned(vstart) / 'n);

    w : vector(24, dec, bits(32)) = undefined;

    foreach (i from eg_start to (eg_len - 1)) {
      assert(0 <= ((i * 4) + 0) & ((i * 4) + 0) < 'n);
      assert(0 <= ((i * 4) + 7) & ((i * 4) + 7) < 'n);

      /* Load and Byte Swap from big-endian to little-endian. */
      w[0]  = rev8(vs1_val[i*4+0]);
      w[1]  = rev8(vs1_val[i*4+1]);
      w[2]  = rev8(vs1_val[i*4+2]);
      w[3]  = rev8(vs1_val[i*4+3]);
      w[4]  = rev8(vs1_val[i*4+4]);
      w[5]  = rev8(vs1_val[i*4+5]);
      w[6]  = rev8(vs1_val[i*4+6]);
      w[7]  = rev8(vs1_val[i*4+7]);

      /* Load and Byte Swap from big-endian to little-endian. */
      w[8]  = rev8(vs2_val[i*4+0]);
      w[9]  = rev8(vs2_val[i*4+1]);
      w[10] = rev8(vs2_val[i*4+2]);
      w[11] = rev8(vs2_val[i*4+3]);
      w[12] = rev8(vs2_val[i*4+4]);
      w[13] = rev8(vs2_val[i*4+5]);
      w[14] = rev8(vs2_val[i*4+6]);
      w[15] = rev8(vs2_val[i*4+7]);

      /* Eight Eight rounds of SM3 message expansion. */
      foreach (j from 16 to 23) {
	w[j] = ZVKSH_W(w[j - 16], w[j - 9],  w[j - 3], w[j - 13],  w[j - 6]);
      };

      /* Byte Swap from big-endian to little-endian and store back. */
      result[i*4+0] = rev8(w[16]);
      result[i*4+1] = rev8(w[17]);
      result[i*4+2] = rev8(w[18]);
      result[i*4+3] = rev8(w[19]);
      result[i*4+4] = rev8(w[20]);
      result[i*4+5] = rev8(w[21]);
      result[i*4+6] = rev8(w[22]);
      result[i*4+7] = rev8(w[23]);
    };

    write_single_vreg(num_elem, 'm, vd, result);
    RETIRE_SUCCESS
  }
}
