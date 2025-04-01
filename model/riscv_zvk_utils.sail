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

val ROTR : forall 'n 'm 'p, 'n >= 0. (bits('n), int('m), int('p)) -> bits('n)
function ROTR (x, n, SEW) = (x >> to_bits('n, n)) | (x << (to_bits('n, SEW) - to_bits('n, n)))

val SHR : forall 'n 'm, 'n >= 0. (bits('n), int('m)) -> bits('n)
function SHR (x, n) = x >> to_bits('n, n)

val sig0 : forall 'n 'm, 'n >= 0 & ('m == 32 | 'm == 64). (bits('n), int('m)) -> bits('n)
function sig0 (x, SEW) = {
  match SEW {
    32 => (ROTR(x, 7, SEW) ^ ROTR(x, 18, SEW) ^ SHR(x, 3)),
    64 => (ROTR(x, 1, SEW) ^ ROTR(x,  8, SEW) ^ SHR(x, 7)),
  }
}

val sig1 : forall 'n 'm, 'n >= 0 & ('m == 32 | 'm == 64). (bits('n), int('m)) -> bits('n)
function sig1 (x, SEW) = {
  match SEW {
    32 => (ROTR(x, 17, SEW) ^ ROTR(x, 19, SEW) ^ SHR(x, 10)),
    64 => (ROTR(x, 19, SEW) ^ ROTR(x, 61, SEW) ^ SHR(x,  6)),
  }
}

val sum0 : forall 'n 'm, 'n >= 0 & ('m == 32 | 'm == 64). (bits('n), int('m)) -> bits('n)
function sum0 (x, SEW) = {
  match SEW {
    32 => (ROTR(x,  2, SEW) ^ ROTR(x, 13, SEW) ^ ROTR(x, 22, SEW)),
    64 => (ROTR(x, 28, SEW) ^ ROTR(x, 34, SEW) ^ ROTR(x, 39, SEW)),
  }
}

val sum1 : forall 'n 'm, 'n >= 0 & ('m == 32 | 'm == 64). (bits('n), int('m)) -> bits('n)
function sum1 (x, SEW) = {
  match SEW {
    32 => (ROTR(x,  6, SEW) ^ ROTR(x, 11, SEW) ^ ROTR(x, 25, SEW)),
    64 => (ROTR(x, 14, SEW) ^ ROTR(x, 18, SEW) ^ ROTR(x, 41, SEW)),
  }
}

val ch : forall 'n, 'n >= 0. (bits('n), bits('n), bits('n)) -> bits('n)
function ch (x, y, z) = (x & y) ^ (~(x) & z)

val maj : forall 'n, 'n >= 0. (bits('n), bits('n), bits('n)) -> bits('n)
function maj (x, y, z) = (x & y) ^ (x & z) ^ (y & z)
