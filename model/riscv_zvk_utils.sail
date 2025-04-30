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

val zvk_sig0 : forall 'n 'm, 'n == 'm & ('m == 32 | 'm == 64). (bits('n), int('m)) -> bits('n)
function zvk_sig0(x, SEW) = {
  match SEW {
    32 => ((x >>> 7) ^ (x >>> 18) ^ (x >> 3)),
    64 => ((x >>> 1) ^ (x >>>  8) ^ (x >> 7)),
  }
}

val zvk_sig1 : forall 'n 'm, 'n == 'm & ('m == 32 | 'm == 64). (bits('n), int('m)) -> bits('n)
function zvk_sig1(x, SEW) = {
  match SEW {
    32 => ((x >>> 17) ^ (x >>> 19) ^ (x >> 10)),
    64 => ((x >>> 19) ^ (x >>> 61) ^ (x >>  6)),
  }
}

val zvk_sum0 : forall 'n 'm, 'n == 'm & ('m == 32 | 'm == 64). (bits('n), int('m)) -> bits('n)
function zvk_sum0(x, SEW) = {
  match SEW {
    32 => ((x >>>  2) ^ (x >>> 13) ^ (x >>> 22)),
    64 => ((x >>> 28) ^ (x >>> 34) ^ (x >>> 39)),
  }
}

val zvk_sum1 : forall 'n 'm, 'n == 'm & ('m == 32 | 'm == 64). (bits('n), int('m)) -> bits('n)
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
