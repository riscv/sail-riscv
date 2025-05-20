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

function zvk_check_encdec(EGW: int, EGS: int) -> bool = (unsigned(vl) % EGS == 0) & (unsigned(vstart) % EGS == 0) & (2 ^ get_lmul_pow() * VLEN) >= EGW

/*
 * Utility functions for Zvknh[ab]
 * ----------------------------------------------------------------------
 */

enum zvkfunct6 = {ZVK_VSHA2CH, ZVK_VSHA2CL}

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

val zvk_ff_j : (bits(32), bits(32), bits(32), int) -> bits(32)
function zvk_ff_j(X, Y, Z, J) = if J <= 15 then zvk_ff1(X, Y, Z) else zvk_ff2(X, Y, Z)

val zvk_gg1 : (bits(32), bits(32), bits(32)) -> bits(32)
function zvk_gg1(X, Y, Z) = X ^ Y ^ Z

val zvk_gg2 : (bits(32), bits(32), bits(32)) -> bits(32)
function zvk_gg2(X, Y, Z) = (X & Y) | (~(X) & Z)

val zvk_gg_j : (bits(32), bits(32), bits(32), int) -> bits(32)
function zvk_gg_j(X, Y, Z, J) = if J <= 15 then zvk_gg1(X, Y, Z) else zvk_gg2(X, Y, Z)

val zvk_t_j : int -> bits(32)
function zvk_t_j(J) = if J <= 15 then 0x79CC4519 else 0x7A879D8A

function zvk_sm3_round(A_H : vector(8, bits(32)), w : bits(32), x : bits(32), j : int) -> vector(8, bits(32)) = {
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
