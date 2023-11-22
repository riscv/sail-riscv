/*=================================================================================*/
/*  Copyright (c) 2021-2023                                                        */
/*    Authors from RIOS Lab, Tsinghua University:                                  */
/*      Xinlai Wan <xinlai.w@rioslab.org>                                          */
/*      Xi Wang <xi.w@rioslab.org>                                                 */
/*      Yifei Zhu <yifei.z@rioslab.org>                                            */
/*      Shenwei Hu <shenwei.h@rioslab.org>                                         */
/*      Kalvin Vu                                                                  */
/*    Other contributors:                                                          */
/*      Jessica Clarke <jrtc27@jrtc27.com>                                         */
/*      Victor Moya <victor.moya@semidynamics.com>                                 */
/*                                                                                 */
/*  All rights reserved.                                                           */
/*                                                                                 */
/*  Redistribution and use in source and binary forms, with or without             */
/*  modification, are permitted provided that the following conditions             */
/*  are met:                                                                       */
/*  1. Redistributions of source code must retain the above copyright              */
/*     notice, this list of conditions and the following disclaimer.               */
/*  2. Redistributions in binary form must reproduce the above copyright           */
/*     notice, this list of conditions and the following disclaimer in             */
/*     the documentation and/or other materials provided with the                  */
/*     distribution.                                                               */
/*                                                                                 */
/*  THIS SOFTWARE IS PROVIDED BY THE AUTHOR AND CONTRIBUTORS ``AS IS''             */
/*  AND ANY EXPRESS OR IMPLIED WARRANTIES, INCLUDING, BUT NOT LIMITED              */
/*  TO, THE IMPLIED WARRANTIES OF MERCHANTABILITY AND FITNESS FOR A                */
/*  PARTICULAR PURPOSE ARE DISCLAIMED.  IN NO EVENT SHALL THE AUTHOR OR            */
/*  CONTRIBUTORS BE LIABLE FOR ANY DIRECT, INDIRECT, INCIDENTAL,                   */
/*  SPECIAL, EXEMPLARY, OR CONSEQUENTIAL DAMAGES (INCLUDING, BUT NOT               */
/*  LIMITED TO, PROCUREMENT OF SUBSTITUTE GOODS OR SERVICES; LOSS OF               */
/*  USE, DATA, OR PROFITS; OR BUSINESS INTERRUPTION) HOWEVER CAUSED AND            */
/*  ON ANY THEORY OF LIABILITY, WHETHER IN CONTRACT, STRICT LIABILITY,             */
/*  OR TORT (INCLUDING NEGLIGENCE OR OTHERWISE) ARISING IN ANY WAY OUT             */
/*  OF THE USE OF THIS SOFTWARE, EVEN IF ADVISED OF THE POSSIBILITY OF             */
/*  SUCH DAMAGE.                                                                   */
/*=================================================================================*/

/* ******************************************************************************* */
/* This file implements part of the vector extension.                              */
/* Chapter 6: Configuration-Setting Instructions                                   */
/* ******************************************************************************* */

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

val handle_illegal_vtype : unit -> unit effect {rreg}
function handle_illegal_vtype() = {
  /* Note: Implementations can set vill or trap if the vtype setting is not supported.
   * TODO: configuration support for both solutions
   */
  vtype->bits() = 0b1 @ zeros(sizeof(xlen) - 1); /* set vtype.vill */
  vl = zeros();
  print_reg("CSR vtype <- " ^ BitStr(vtype.bits()));
  print_reg("CSR vl <- " ^ BitStr(vl))
}

val calculate_new_vl : (int, int) -> xlenbits
function calculate_new_vl(AVL, VLMAX) = {
  /* Note: ceil(AVL / 2) ≤ vl ≤ VLMAX when VLMAX < AVL < (2 * VLMAX)
   * TODO: configuration support for either using ceil(AVL / 2) or VLMAX
   */
  if AVL <= VLMAX then to_bits(sizeof(xlen), AVL)
  else if AVL < 2 * VLMAX then to_bits(sizeof(xlen), (AVL + 1) / 2)
  else to_bits(sizeof(xlen), VLMAX)
}

/* *********************************** vsetvli *********************************** */
union clause ast = VSETVLI : (bits(1), bits(1), bits(3), bits(3), regidx, regidx)

mapping clause encdec = VSETVLI(ma, ta, sew, lmul, rs1, rd) if haveVExt()
  <-> 0b0000 @ ma @ ta @ sew @ lmul @ rs1 @ 0b111 @ rd @ 0b1010111 if haveVExt()

function clause execute VSETVLI(ma, ta, sew, lmul, rs1, rd) = {
  let LMUL_pow_ori  = get_lmul_pow();
  let SEW_pow_ori   = get_sew_pow();
  let ratio_pow_ori = SEW_pow_ori - LMUL_pow_ori;

  /* set vtype */
  vtype->bits() = 0b0 @ zeros(sizeof(xlen) - 9) @ ma @ ta @ sew @ lmul;

  /* check new SEW and LMUL are legal and calculate VLMAX */
  let VLEN_pow     = get_vlen_pow();
  let ELEN_pow     = get_elen_pow();
  let LMUL_pow_new = get_lmul_pow();
  let SEW_pow_new  = get_sew_pow();
  if SEW_pow_new > LMUL_pow_new + ELEN_pow then { handle_illegal_vtype(); return RETIRE_SUCCESS };
  let VLMAX = int_power(2, VLEN_pow + LMUL_pow_new - SEW_pow_new);

  /* set vl according to VLMAX and AVL */
  if (rs1 != 0b00000) then { /* normal stripmining */
    let rs1_val = X(rs1);
    let AVL = unsigned(rs1_val);
    vl = calculate_new_vl(AVL, VLMAX);
    X(rd) = vl;
  } else if (rd != 0b00000) then { /* set vl to VLMAX */
    let AVL = unsigned(ones(sizeof(xlen)));
    vl = to_bits(sizeof(xlen), VLMAX);
    X(rd) = vl;
  } else { /* keep existing vl */
    let AVL = unsigned(vl);
    let ratio_pow_new = SEW_pow_new - LMUL_pow_new;
    if (ratio_pow_new != ratio_pow_ori) then { handle_illegal_vtype(); return RETIRE_SUCCESS }
  };

  /* reset vstart to 0 */
  vstart = zeros();

  print_reg("CSR vtype <- " ^ BitStr(vtype.bits()));
  print_reg("CSR vl <- " ^ BitStr(vl));
  print_reg("CSR vstart <- " ^ BitStr(vstart));

  RETIRE_SUCCESS
}

mapping clause assembly = VSETVLI(ma, ta, sew, lmul, rs1, rd)
  <-> "vsetvli" ^ spc() ^ reg_name(rd) ^ sep() ^ reg_name(rs1) ^ sep() ^ sew_flag(sew) ^ maybe_lmul_flag(lmul) ^ maybe_ta_flag(ta) ^ maybe_ma_flag(ma)

/* *********************************** vsetvl ************************************ */
union clause ast = VSETVL : (regidx, regidx, regidx)

mapping clause encdec = VSETVL(rs2, rs1, rd) if haveVExt()
  <-> 0b1000000 @ rs2 @ rs1 @ 0b111 @ rd @ 0b1010111 if haveVExt()

function clause execute VSETVL(rs2, rs1, rd) = {
  let LMUL_pow_ori  = get_lmul_pow();
  let SEW_pow_ori   = get_sew_pow();
  let ratio_pow_ori = SEW_pow_ori - LMUL_pow_ori;

  /* set vtype */
  vtype->bits() = X(rs2);

  /* check new SEW and LMUL are legal and calculate VLMAX */
  let VLEN_pow     = get_vlen_pow();
  let ELEN_pow     = get_elen_pow();
  let LMUL_pow_new = get_lmul_pow();
  let SEW_pow_new  = get_sew_pow();
  if SEW_pow_new > LMUL_pow_new + ELEN_pow then { handle_illegal_vtype(); return RETIRE_SUCCESS };
  let VLMAX = int_power(2, VLEN_pow + LMUL_pow_new - SEW_pow_new);

  /* set vl according to VLMAX and AVL */
  if (rs1 != 0b00000) then { /* normal stripmining */
    let rs1_val = X(rs1);
    let AVL = unsigned(rs1_val);
    vl = calculate_new_vl(AVL, VLMAX);
    X(rd) = vl;
  } else if (rd != 0b00000) then { /* set vl to VLMAX */
    let AVL = unsigned(ones(sizeof(xlen)));
    vl = to_bits(sizeof(xlen), VLMAX);
    X(rd) = vl;
  } else { /* keep existing vl */
    let AVL = unsigned(vl);
    let ratio_pow_new = SEW_pow_new - LMUL_pow_new;
    if (ratio_pow_new != ratio_pow_ori) then { handle_illegal_vtype(); return RETIRE_SUCCESS }
  };

  /* reset vstart to 0 */
  vstart = zeros();

  print_reg("CSR vtype <- " ^ BitStr(vtype.bits()));
  print_reg("CSR vl <- " ^ BitStr(vl));
  print_reg("CSR vstart <- " ^ BitStr(vstart));

  RETIRE_SUCCESS
}

mapping clause assembly = VSETVL(rs2, rs1, rd)
  <-> "vsetvl" ^ spc() ^ reg_name(rd) ^ sep() ^ reg_name(rs1) ^ sep() ^ reg_name(rs2)

/* ********************************** vsetivli *********************************** */
union clause ast = VSETIVLI : ( bits(1), bits(1), bits(3), bits(3), regidx, regidx)

mapping clause encdec = VSETIVLI(ma, ta, sew, lmul, uimm, rd) if haveVExt()
  <-> 0b1100 @ ma @ ta @ sew @ lmul @ uimm @ 0b111 @ rd @ 0b1010111 if haveVExt()

function clause execute VSETIVLI(ma, ta, sew, lmul, uimm, rd) = {
  /* set vtype */
  vtype->bits() = 0b0 @ zeros(sizeof(xlen) - 9) @ ma @ ta @ sew @ lmul;

  /* check new SEW and LMUL are legal and calculate VLMAX */
  let VLEN_pow     = get_vlen_pow();
  let ELEN_pow     = get_elen_pow();
  let LMUL_pow_new = get_lmul_pow();
  let SEW_pow_new  = get_sew_pow();
  if SEW_pow_new > LMUL_pow_new + ELEN_pow then { handle_illegal_vtype(); return RETIRE_SUCCESS };
  let VLMAX = int_power(2, VLEN_pow + LMUL_pow_new - SEW_pow_new);

  /* set vl according to VLMAX and AVL */
  let AVL = unsigned(uimm); /* AVL is encoded as 5-bit zero-extended imm in the rs1 field */
  vl = calculate_new_vl(AVL, VLMAX);
  X(rd) = vl;

  /* reset vstart to 0 */
  vstart = zeros();

  print_reg("CSR vtype <- " ^ BitStr(vtype.bits()));
  print_reg("CSR vl <- " ^ BitStr(vl));
  print_reg("CSR vstart <- " ^ BitStr(vstart));

  RETIRE_SUCCESS
}

mapping clause assembly = VSETIVLI(ma, ta, sew, lmul, uimm, rd)
  <-> "vsetivli" ^ spc() ^ reg_name(rd) ^ sep() ^ hex_bits_5(uimm) ^ sep() ^ sew_flag(sew) ^ maybe_lmul_flag(lmul) ^ maybe_ta_flag(ta) ^ maybe_ma_flag(ma)
