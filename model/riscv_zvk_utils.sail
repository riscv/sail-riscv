
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
 * Utility functions for Zvksed
 * ----------------------------------------------------------------------
 */

enum zvkfunct6 = {ZVK_VSM4RVV, ZVK_VSM4RVS}

val round_key : (bits(32), bits(32)) -> bits(32)
function round_key(X, S) = X ^ (S ^ (S <<< 13) ^ (S <<< 23))

val sm4_round : (bits(32), bits(32)) -> bits(32)
function sm4_round(X, S) = X ^ (S ^ (S <<< 2) ^ (S <<< 10) ^ (S <<< 18) ^ (S <<< 24))

// SM4 Constant Key (CK)
let zvksed_ck : vector(32, bits(32)) = [
0x00070E15, 0x1C232A31, 0x383F464D, 0x545B6269,
0x70777E85, 0x8C939AA1, 0xA8AFB6BD, 0xC4CBD2D9,
0xE0E7EEF5, 0xFC030A11, 0x181F262D, 0x343B4249,
0x50575E65, 0x6C737A81, 0x888F969D, 0xA4ABB2B9,
0xC0C7CED5, 0xDCE3EAF1, 0xF8FF060D, 0x141B2229,
0x30373E45, 0x4C535A61, 0x686F767D, 0x848B9299,
0xA0A7AEB5, 0xBCC3CAD1, 0xD8DFE6ED, 0xF4FB0209,
0x10171E25, 0x2C333A41, 0x484F565D, 0x646B7279
]

val zvksed_box_lookup : (bits(5), vector(32, bits(32))) -> bits(32)
function zvksed_box_lookup(x, table) = {
  table[31 - unsigned(x)]
}

val zvksed_sm4_sbox : (int) -> bits(32)
function zvksed_sm4_sbox(x) = zvksed_box_lookup(to_bits(5, x), zvksed_ck)

val sm4_subword : bits(32) -> bits(32)
function sm4_subword(x) = {
  sm4_sbox(x[31..24]) @
  sm4_sbox(x[23..16]) @
  sm4_sbox(x[15.. 8]) @
  sm4_sbox(x[ 7.. 0])
}
