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

val	 rol32 : forall 'm, 32 - 'm >= 0 & 'm >= 0. (bits(32), int('m)) -> bits(32)
function rol32(X,N) = (X << N) | (X >> (32 - N))

val	 round_key : (bits(32), bits(32)) -> bits(32)
function round_key(X, S) = ((X) ^ ((S) ^ rol32((S), 13) ^ rol32((S), 23)))

// SM4 Constant Key (CK)
let ck : list(bits(32)) = [|
      0x00070E15, 0x1C232A31, 0x383F464D, 0x545B6269,
      0x70777E85, 0x8C939AA1, 0xA8AFB6BD, 0xC4CBD2D9,
      0xE0E7EEF5, 0xFC030A11, 0x181F262D, 0x343B4249,
      0x50575E65, 0x6C737A81, 0x888F969D, 0xA4ABB2B9,
      0xC0C7CED5, 0xDCE3EAF1, 0xF8FF060D, 0x141B2229,
      0x30373E45, 0x4C535A61, 0x686F767D, 0x848B9299,
      0xA0A7AEB5, 0xBCC3CAD1, 0xD8DFE6ED, 0xF4FB0209,
      0x10171E25, 0x2C333A41, 0x484F565D, 0x646B7279
|]

/* Lookup function for Zvksed SM4 Contant Key;- takes an index and a list, and retrieves the
 * x'th element of that list.
 */
val	 zvksed_box_lookup : (bits(32), list(bits(32))) -> bits(32)
function zvksed_box_lookup(x, table) = {
  match (x, table) {
    (0x00000000, t0::tn) => t0,
    (	      _, t0::tn) => zvksed_box_lookup(x - 0x00000001, tn)
  }
}

val	 zvksed_sm4_sbox : (bits(32)) -> bits(32)
function zvksed_sm4_sbox(x) = zvksed_box_lookup(x, ck)

val	 sm4_subword : bits(32) -> bits(32)
function sm4_subword(x) = {
  sm4_sbox(x[31..24]) @
  sm4_sbox(x[23..16]) @
  sm4_sbox(x[15.. 8]) @
  sm4_sbox(x[ 7.. 0])
}

val	 sm4_round : (bits(32), bits(32)) -> bits(32)
function sm4_round(X, S) =
  ((X) ^ ((S) ^ rol32((S), 2) ^ rol32((S), 10) ^ rol32((S), 18) ^ rol32((S), 24)))

/* VSM4K.VI */

union clause ast = RISCV_VSM4K_VI : (regidx, bits(5), regidx)

mapping clause encdec = RISCV_VSM4K_VI(vs2, uimm, vd) if (haveRVV() & haveZvksed())
 <-> 0b1000011 @ vs2 @ uimm @ 0b010 @ vd @ 0b1110111  if (haveRVV() & haveZvksed())

mapping clause assembly = RISCV_VSM4K_VI(vs2, uimm, vd)
 <-> "vsm4k.vi" ^ spc() ^ vreg_name(vd)
		^ sep() ^ vreg_name(vs2)
		^ sep() ^ reg_name(uimm)

function clause execute (RISCV_VSM4K_VI(vs2, uimm, vd)) = {
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

    rk : bits(128) = undefined;

    B          : bits(32)  = zeros();
    S          : bits(32)  = zeros();
    rk7_to_rk4 : bits(128) = zeros();
    rnd        : bits(3)   = uimm[2..0]; // Lower 3 bits

    eg_len   = (unsigned(vl) / 'n);
    eg_start = (unsigned(vstart) / 'n);

    foreach (i from eg_start to (eg_len - 1)) {
      assert(0 <= ((i * 4) + 3) & ((i * 4) + 3) < 'n);
      rk[31..0]   = vs2_val[i*4+0];
      rk[63..32]  = vs2_val[i*4+1];
      rk[95..64]  = vs2_val[i*4+2];
      rk[127..96] = vs2_val[i*4+3];

      B   = rk[63..32] ^ rk[95..64] ^ rk[127..96] ^ zvksed_sm4_sbox(to_bits(32, 4 * unsigned(rnd)));
      S   = sm4_subword(B);
      rk7_to_rk4[31..0] = round_key(rk[31..0], S);

      B   = rk[95..64] ^ rk[127..96] ^ rk7_to_rk4[31..0] ^ zvksed_sm4_sbox(to_bits(32, 4 * unsigned(rnd) + 1));
      S   = sm4_subword(B);
      rk7_to_rk4[63..32] = round_key(rk[63..32], S);

      B   = rk[127..96] ^ rk7_to_rk4[31..0] ^ rk7_to_rk4[63..32] ^  zvksed_sm4_sbox(to_bits(32, 4 * unsigned(rnd) + 2));
      S   = sm4_subword(B);
      rk7_to_rk4[95..64] = round_key(rk[95..64], S);

      B   = rk7_to_rk4[31..0] ^ rk7_to_rk4[63..32] ^ rk7_to_rk4[95..64] ^ zvksed_sm4_sbox(to_bits(32, 4 * unsigned(rnd) + 3));
      S   = sm4_subword(B);
      rk7_to_rk4[127..96] = round_key(rk[127..96], S);

      result[i*4+0] = rk7_to_rk4[31..0];
      result[i*4+1] = rk7_to_rk4[63..32];
      result[i*4+2] = rk7_to_rk4[95..64];
      result[i*4+3] = rk7_to_rk4[127..96];
    };

    write_single_vreg(num_elem, 'm, vd, result);
    RETIRE_SUCCESS
  }
}
