/*=======================================================================================*/
/*  This Sail RISC-V architecture model, comprising all files and                        */
/*  directories except where otherwise noted is subject the BSD                          */
/*  two-clause license in the LICENSE file.                                              */
/*                                                                                       */
/*  SPDX-License-Identifier: BSD-2-Clause                                                */
/*=======================================================================================*/

/* ******************************************************************************* */
/* This file implements part of the vector extension.                              */
/* Chapter 6: Configuration-Setting Instructions                                   */
/* ******************************************************************************* */

enum clause extension = Ext_V
function clause extensionEnabled(Ext_V) = (misa[V] == 0b1) & (mstatus[VS] != 0b00)

mapping sew_flag : string <-> bits(3) = {
  "e8"    <-> 0b000,
  "e16"   <-> 0b001,
  "e32"   <-> 0b010,
  "e64"   <-> 0b011
}

mapping maybe_lmul_flag : string <-> bits(3) = {
  ""              <-> 0b000, /* m1 by default */
  sep() ^ "mf8"   <-> 0b101,
  sep() ^ "mf4"   <-> 0b110,
  sep() ^ "mf2"   <-> 0b111,
  sep() ^ "m1"    <-> 0b000,
  sep() ^ "m2"    <-> 0b001,
  sep() ^ "m4"    <-> 0b010,
  sep() ^ "m8"    <-> 0b011
}

mapping maybe_ta_flag : string <-> bits(1) = {
  ""           <-> 0b0, /* tu by default */
  sep() ^ "ta" <-> 0b1,
  sep() ^ "tu" <-> 0b0
}

mapping maybe_ma_flag : string <-> bits(1) = {
  ""           <-> 0b0, /* mu by default */
  sep() ^ "ma" <-> 0b1,
  sep() ^ "mu" <-> 0b0
}

val handle_illegal_vtype : unit -> unit
function handle_illegal_vtype() = {
  /* Note: Implementations can set vill or trap if the vtype setting is not supported.
   * TODO: configuration support for both solutions
   */
  vtype.bits = 0b1 @ zeros(xlen - 1); /* set vtype.vill */
  vl = zeros();
  csr_write_callback(csr_name_map("vtype"), vtype.bits);
  csr_write_callback(csr_name_map("vl"), vl);
}

val calculate_new_vl : (int, int) -> xlenbits
function calculate_new_vl(AVL, VLMAX) = {
  /* Note: ceil(AVL / 2) ≤ vl ≤ VLMAX when VLMAX < AVL < (2 * VLMAX)
   * TODO: configuration support for either using ceil(AVL / 2) or VLMAX
   */
  if AVL <= VLMAX then to_bits(xlen, AVL)
  else if AVL < 2 * VLMAX then to_bits(xlen, (AVL + 1) / 2)
  else to_bits(xlen, VLMAX)
}

/* *********************************** vsetvli *********************************** */
union clause ast = VSETVLI : (bits(1), bits(1), bits(3), bits(3), regidx, regidx)

mapping clause encdec = VSETVLI(ma, ta, sew, lmul, rs1, rd) if extensionEnabled(Ext_V)
  <-> 0b0000 @ ma @ ta @ sew @ lmul @ rs1 @ 0b111 @ rd @ 0b1010111 if extensionEnabled(Ext_V)

function clause execute VSETVLI(ma, ta, sew, lmul, rs1, rd) = {
  let LMUL_pow_ori  = get_lmul_pow();
  let SEW_pow_ori   = get_sew_pow();
  let ratio_pow_ori = SEW_pow_ori - LMUL_pow_ori;

  /* set vtype */
  vtype.bits = 0b0 @ zeros(xlen - 9) @ ma @ ta @ sew @ lmul;

  /* check new SEW and LMUL are legal and calculate VLMAX */
  let VLEN_pow     = get_vlen_pow();
  let ELEN_pow     = get_elen_pow();
  let LMUL_pow_new = get_lmul_pow();
  let SEW_pow_new  = get_sew_pow();
  if SEW_pow_new > (LMUL_pow_new + ELEN_pow) then { handle_illegal_vtype(); return RETIRE_SUCCESS };
  let VLMAX = 2 ^ (VLEN_pow + LMUL_pow_new - SEW_pow_new);

  /* set vl according to VLMAX and AVL */
  if (rs1 != 0b00000) then { /* normal stripmining */
    let rs1_val = X(rs1);
    let AVL = unsigned(rs1_val);
    vl = calculate_new_vl(AVL, VLMAX);
    X(rd) = vl;
  } else if (rd != 0b00000) then { /* set vl to VLMAX */
    let AVL = unsigned(ones(xlen));
    vl = to_bits(xlen, VLMAX);
    X(rd) = vl;
  } else { /* keep existing vl */
    let AVL = unsigned(vl);
    let ratio_pow_new = SEW_pow_new - LMUL_pow_new;
    if (ratio_pow_new != ratio_pow_ori) then { handle_illegal_vtype(); return RETIRE_SUCCESS }
  };

  /* reset vstart to 0 */
  vstart = zeros();

  csr_write_callback(csr_name_map("vtype"), vtype.bits);
  csr_write_callback(csr_name_map("vl"), vl);
  csr_write_callback(csr_name_map("vstart"), zero_extend(vstart));

  RETIRE_SUCCESS
}

mapping clause assembly = VSETVLI(ma, ta, sew, lmul, rs1, rd)
  <-> "vsetvli" ^ spc() ^ reg_name(rd) ^ sep() ^ reg_name(rs1) ^ sep() ^ sew_flag(sew) ^ maybe_lmul_flag(lmul) ^ maybe_ta_flag(ta) ^ maybe_ma_flag(ma)

/* *********************************** vsetvl ************************************ */
union clause ast = VSETVL : (regidx, regidx, regidx)

mapping clause encdec = VSETVL(rs2, rs1, rd) if extensionEnabled(Ext_V)
  <-> 0b1000000 @ rs2 @ rs1 @ 0b111 @ rd @ 0b1010111 if extensionEnabled(Ext_V)

function clause execute VSETVL(rs2, rs1, rd) = {
  let LMUL_pow_ori  = get_lmul_pow();
  let SEW_pow_ori   = get_sew_pow();
  let ratio_pow_ori = SEW_pow_ori - LMUL_pow_ori;

  /* set vtype */
  vtype.bits = X(rs2);

  /* check new SEW and LMUL are legal and calculate VLMAX */
  let VLEN_pow     = get_vlen_pow();
  let ELEN_pow     = get_elen_pow();
  let LMUL_pow_new = get_lmul_pow();
  let SEW_pow_new  = get_sew_pow();
  if SEW_pow_new > (LMUL_pow_new + ELEN_pow) then { handle_illegal_vtype(); return RETIRE_SUCCESS };
  let VLMAX = 2 ^ (VLEN_pow + LMUL_pow_new - SEW_pow_new);

  /* set vl according to VLMAX and AVL */
  if (rs1 != 0b00000) then { /* normal stripmining */
    let rs1_val = X(rs1);
    let AVL = unsigned(rs1_val);
    vl = calculate_new_vl(AVL, VLMAX);
    X(rd) = vl;
  } else if (rd != 0b00000) then { /* set vl to VLMAX */
    let AVL = unsigned(ones(xlen));
    vl = to_bits(xlen, VLMAX);
    X(rd) = vl;
  } else { /* keep existing vl */
    let AVL = unsigned(vl);
    let ratio_pow_new = SEW_pow_new - LMUL_pow_new;
    if (ratio_pow_new != ratio_pow_ori) then { handle_illegal_vtype(); return RETIRE_SUCCESS }
  };

  /* reset vstart to 0 */
  vstart = zeros();

  csr_write_callback(csr_name_map("vtype"), vtype.bits);
  csr_write_callback(csr_name_map("vl"), vl);
  csr_write_callback(csr_name_map("vstart"), zero_extend(vstart));

  RETIRE_SUCCESS
}

mapping clause assembly = VSETVL(rs2, rs1, rd)
  <-> "vsetvl" ^ spc() ^ reg_name(rd) ^ sep() ^ reg_name(rs1) ^ sep() ^ reg_name(rs2)

/* ********************************** vsetivli *********************************** */
union clause ast = VSETIVLI : ( bits(1), bits(1), bits(3), bits(3), regidx, regidx)

mapping clause encdec = VSETIVLI(ma, ta, sew, lmul, uimm, rd) if extensionEnabled(Ext_V)
  <-> 0b1100 @ ma @ ta @ sew @ lmul @ uimm @ 0b111 @ rd @ 0b1010111 if extensionEnabled(Ext_V)

function clause execute VSETIVLI(ma, ta, sew, lmul, uimm, rd) = {
  /* set vtype */
  vtype.bits = 0b0 @ zeros(xlen - 9) @ ma @ ta @ sew @ lmul;

  /* check new SEW and LMUL are legal and calculate VLMAX */
  let VLEN_pow     = get_vlen_pow();
  let ELEN_pow     = get_elen_pow();
  let LMUL_pow_new = get_lmul_pow();
  let SEW_pow_new  = get_sew_pow();
  if SEW_pow_new > (LMUL_pow_new + ELEN_pow) then { handle_illegal_vtype(); return RETIRE_SUCCESS };
  let VLMAX = 2 ^ (VLEN_pow + LMUL_pow_new - SEW_pow_new);

  /* set vl according to VLMAX and AVL */
  let AVL = unsigned(uimm); /* AVL is encoded as 5-bit zero-extended imm in the rs1 field */
  vl = calculate_new_vl(AVL, VLMAX);
  X(rd) = vl;

  /* reset vstart to 0 */
  vstart = zeros();

  csr_write_callback(csr_name_map("vtype"), vtype.bits);
  csr_write_callback(csr_name_map("vl"), vl);
  csr_write_callback(csr_name_map("vstart"), zero_extend(vstart));

  RETIRE_SUCCESS
}

mapping clause assembly = VSETIVLI(ma, ta, sew, lmul, uimm, rd)
  <-> "vsetivli" ^ spc() ^ reg_name(rd) ^ sep() ^ hex_bits_5(uimm) ^ sep() ^ sew_flag(sew) ^ maybe_lmul_flag(lmul) ^ maybe_ta_flag(ta) ^ maybe_ma_flag(ma)
