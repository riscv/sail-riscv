/*=======================================================================================*/
/*  This Sail RISC-V architecture model, comprising all files and                        */
/*  directories except where otherwise noted is subject the BSD                          */
/*  two-clause license in the LICENSE file.                                              */
/*                                                                                       */
/*  SPDX-License-Identifier: BSD-2-Clause                                                */
/*=======================================================================================*/

val zvk_valid_reg_overlap : (vregidx, vregidx, int) -> bool
function zvk_valid_reg_overlap(rs, rd, emul_pow) = {
  let reg_group_size = if emul_pow > 0 then 2 ^ emul_pow else 1;
  let rs_int = unsigned(vregidx_bits(rs));
  let rd_int = unsigned(vregidx_bits(rd));
  (rs_int + reg_group_size <= rd_int) | (rd_int + reg_group_size <= rs_int)
}

function zvk_check_encdec(EGW: nat, EGS: nat1) -> bool = {
  let LMUL_pow = get_lmul_pow();
  let LMUL_times_VLEN = if LMUL_pow < 0 then vlen / (2 ^ abs_int(LMUL_pow)) else (2 ^ LMUL_pow) * vlen in
  (unsigned(vl) % EGS == 0) & (unsigned(vstart) % EGS == 0) & LMUL_times_VLEN >= EGW
}

/*
 * Utility functions for Zvknh[ab]
 * ----------------------------------------------------------------------
 */

enum zvk_vsha2_funct6 = {ZVK_VSHA2CH_VV, ZVK_VSHA2CL_VV}

function zvknhab_check_encdec(vs2: vregidx, vs1: vregidx, vd: vregidx) -> bool = {
  let SEW      = get_sew();
  let LMUL_pow = get_lmul_pow();
  zvk_check_encdec(SEW, 4) & zvk_valid_reg_overlap(vs1, vd, LMUL_pow) & zvk_valid_reg_overlap(vs2, vd, LMUL_pow);
}

val zvk_sig0 : forall 'n, 'n in {32, 64} . (bits('n), int('n)) -> bits('n)
function zvk_sig0(x, SEW) = {
  match SEW {
    32 => ((x >>> 7) ^ (x >>> 18) ^ (x >> 3)),
    64 => ((x >>> 1) ^ (x >>>  8) ^ (x >> 7)),
  }
}

val zvk_sig1 : forall 'n, 'n in {32, 64} . (bits('n), int('n)) -> bits('n)
function zvk_sig1(x, SEW) = {
  match SEW {
    32 => ((x >>> 17) ^ (x >>> 19) ^ (x >> 10)),
    64 => ((x >>> 19) ^ (x >>> 61) ^ (x >>  6)),
  }
}

val zvk_sum0 : forall 'n, 'n in {32, 64} . (bits('n), int('n)) -> bits('n)
function zvk_sum0(x, SEW) = {
  match SEW {
    32 => ((x >>>  2) ^ (x >>> 13) ^ (x >>> 22)),
    64 => ((x >>> 28) ^ (x >>> 34) ^ (x >>> 39)),
  }
}

val zvk_sum1 : forall 'n, 'n in {32, 64} . (bits('n), int('n)) -> bits('n)
function zvk_sum1(x, SEW) = {
  match SEW {
    32 => ((x >>>  6) ^ (x >>> 11) ^ (x >>> 25)),
    64 => ((x >>> 14) ^ (x >>> 18) ^ (x >>> 41)),
  }
}

val zvk_ch : forall 'n, 'n >= 0. (bits('n), bits('n), bits('n)) -> bits('n)
function zvk_ch(x, y, z) = (x & y) ^ (~(x) & z)

val zvk_maj : forall 'n, 'n >= 0. (bits('n), bits('n), bits('n)) -> bits('n)
function zvk_maj(x, y, z) = (x & y) ^ (x & z) ^ (y & z)

/*
 * Utility functions for Zvksed
 * ----------------------------------------------------------------------
 */

enum zvk_vsm4r_funct6 = {ZVK_VSM4R_VV, ZVK_VSM4R_VS}

val zvk_round_key : (bits(32), bits(32)) -> bits(32)
function zvk_round_key(X, S) = X ^ (S ^ (S <<< 13) ^ (S <<< 23))

val zvk_sm4_round : (bits(32), bits(32)) -> bits(32)
function zvk_sm4_round(X, S) = X ^ (S ^ (S <<< 2) ^ (S <<< 10) ^ (S <<< 18) ^ (S <<< 24))

// SM4 Constant Key (CK)
let zvksed_ck : vector(32, bits(32)) = [
  0x00070E15, 0x1C232A31, 0x383F464D, 0x545B6269,
  0x70777E85, 0x8C939AA1, 0xA8AFB6BD, 0xC4CBD2D9,
  0xE0E7EEF5, 0xFC030A11, 0x181F262D, 0x343B4249,
  0x50575E65, 0x6C737A81, 0x888F969D, 0xA4ABB2B9,
  0xC0C7CED5, 0xDCE3EAF1, 0xF8FF060D, 0x141B2229,
  0x30373E45, 0x4C535A61, 0x686F767D, 0x848B9299,
  0xA0A7AEB5, 0xBCC3CAD1, 0xD8DFE6ED, 0xF4FB0209,
  0x10171E25, 0x2C333A41, 0x484F565D, 0x646B7279,
]

val zvksed_box_lookup : (bits(5), vector(32, bits(32))) -> bits(32)
function zvksed_box_lookup(x, table) = {
  table[31 - unsigned(x)]
}

val zvk_sm4_sbox : (bits(5)) -> bits(32)
function zvk_sm4_sbox(x) = zvksed_box_lookup(x, zvksed_ck)

val zvk_sm4_subword : bits(32) -> bits(32)
function zvk_sm4_subword(x) = {
  sm4_sbox(x[31..24]) @
  sm4_sbox(x[23..16]) @
  sm4_sbox(x[15.. 8]) @
  sm4_sbox(x[ 7.. 0])
}

/*
 * Utility functions for Zvksh
 * ----------------------------------------------------------------------
 */

val zvk_p0 : bits(32) -> bits(32)
function zvk_p0(X) = X ^ (X <<<  9) ^ (X <<< 17)

val zvk_p1 : bits(32) -> bits(32)
function zvk_p1(X) = X ^ (X <<< 15) ^ (X <<< 23)

val zvk_sh_w : (bits(32), bits(32), bits(32), bits(32), bits(32)) -> bits(32)
function zvk_sh_w(A, B, C, D, E) = zvk_p1(A ^ B ^ (C <<< 15)) ^ (D <<< 7) ^ E

val zvk_ff1 : (bits(32), bits(32), bits(32)) -> bits(32)
function zvk_ff1(X, Y, Z) = X ^ Y ^ Z

val zvk_ff2 : (bits(32), bits(32), bits(32)) -> bits(32)
function zvk_ff2(X, Y, Z) = (X & Y) | (X & Z) | (Y & Z)

val zvk_ff_j : (bits(32), bits(32), bits(32), nat) -> bits(32)
function zvk_ff_j(X, Y, Z, J) = if J <= 15 then zvk_ff1(X, Y, Z) else zvk_ff2(X, Y, Z)

val zvk_gg1 : (bits(32), bits(32), bits(32)) -> bits(32)
function zvk_gg1(X, Y, Z) = X ^ Y ^ Z

val zvk_gg2 : (bits(32), bits(32), bits(32)) -> bits(32)
function zvk_gg2(X, Y, Z) = (X & Y) | (~(X) & Z)

val zvk_gg_j : (bits(32), bits(32), bits(32), nat) -> bits(32)
function zvk_gg_j(X, Y, Z, J) = if J <= 15 then zvk_gg1(X, Y, Z) else zvk_gg2(X, Y, Z)

val zvk_t_j : nat -> bits(32)
function zvk_t_j(J) = if J <= 15 then 0x79CC4519 else 0x7A879D8A

function zvk_sm3_round(A_H : vector(8, bits(32)), w : bits(32), x : bits(32), j : nat) -> vector(8, bits(32)) = {
  let t_j = zvk_t_j(j) <<< (j % 32);
  let ss1 = ((A_H[0] <<< 12) + A_H[4] + t_j) <<< 7;
  let ss2 = ss1 ^ (A_H[0] <<< 12);

  let tt1 = zvk_ff_j(A_H[0], A_H[1], A_H[2], j) + A_H[3] + ss2 + x;
  let tt2 = zvk_gg_j(A_H[4], A_H[5], A_H[6], j) + A_H[7] + ss1 + w;

  let A1 = tt1;
  let C1 = A_H[1] <<< 9;
  let E1 = zvk_p0(tt2);
  let G1 = A_H[5] <<< 19;

  [ A_H[6], G1, A_H[4], E1, A_H[2], C1, A_H[0], A1 ]
}

/*
 * Utility functions for Zvkned
 * ----------------------------------------------------------------------
 */

enum zvk_vaesdf_funct6 = {ZVK_VAESDF_VV, ZVK_VAESDF_VS}
enum zvk_vaesdm_funct6 = {ZVK_VAESDM_VV, ZVK_VAESDM_VS}
enum zvk_vaesef_funct6 = {ZVK_VAESEF_VV, ZVK_VAESEF_VS}
enum zvk_vaesem_funct6 = {ZVK_VAESEM_VV, ZVK_VAESEM_VS}
