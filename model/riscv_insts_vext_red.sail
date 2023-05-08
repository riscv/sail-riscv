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
/* Chapter 14: Vector Reduction Instructions                                       */
/* ******************************************************************************* */

/* ********************* OPIVV (Widening Integer Reduction) ********************** */
union clause ast = RIVVTYPE : (rivvfunct6, bits(1), regidx, regidx, regidx)

mapping encdec_rivvfunct6 : rivvfunct6 <-> bits(6) = {
  IVV_VWREDSUMU   <-> 0b110000,
  IVV_VWREDSUM    <-> 0b110001
}

mapping clause encdec = RIVVTYPE(funct6, vm, vs2, vs1, vd) if haveRVV()
  <-> encdec_rivvfunct6(funct6) @ vm @ vs2 @ vs1 @ 0b000 @ vd @ 0b1010111 if haveRVV()

function clause execute(RIVVTYPE(funct6, vm, vs2, vs1, vd)) = {
  let SEW      = get_sew();
  let LMUL_pow = get_lmul_pow();
  let num_elem = get_num_elem(LMUL_pow, SEW);
  let SEW_widen      = SEW * 2;
  let LMUL_pow_widen = LMUL_pow + 1;

  if not(valid_eew_emul(SEW_widen, LMUL_pow_widen)) then { handle_illegal(); return RETIRE_FAIL };

  let 'n = num_elem;
  let 'm = SEW;
  let 'o = SEW_widen;

  let vm_val  : vector('n, dec, bool)     = read_vmask(num_elem, vm, vreg_name("v0"));
  let vd_val  : vector('n, dec, bits('o)) = read_vreg(num_elem, SEW_widen, LMUL_pow_widen, vd);
  let vs2_val : vector('n, dec, bits('m)) = read_vreg(num_elem, SEW, LMUL_pow, vs2);
  result      : vector('n, dec, bits('o)) = undefined;
  mask        : vector('n, dec, bool)     = undefined;

  assert(8 <= SEW_widen & SEW_widen <= 64);
  (result, mask) = init_masked_result(num_elem, SEW_widen, LMUL_pow_widen, vd_val, vm_val);

  let scalar : bits('o) = read_single_element(SEW_widen, 0, LMUL_pow_widen, vs1);
  sum : bits('o) = match funct6 {
    IVV_VWREDSUMU  => to_bits(SEW_widen, unsigned(scalar)),
    IVV_VWREDSUM   => to_bits(SEW_widen, signed(scalar))
  };

  foreach (i from 0 to (num_elem - 1)) {
    if mask[i] then {
      sum = match funct6 {
        IVV_VWREDSUMU  => to_bits(SEW_widen, unsigned(vs2_val[i]) + unsigned(sum)),
        IVV_VWREDSUM   => to_bits(SEW_widen, signed(vs2_val[i]) + signed(sum))
      }
    }
  };

  write_single_element(SEW_widen, 0, LMUL_pow_widen, vd, sum);
  vstart = EXTZ(0b0);
  RETIRE_SUCCESS
}

mapping rivvtype_mnemonic : rivvfunct6 <-> string = {
  IVV_VWREDSUMU  <-> "vwredsumu.vs",
  IVV_VWREDSUM   <-> "vwredsum.vs"
}

mapping clause assembly = RIVVTYPE(funct6, vm, vs2, vs1, vd)
  <-> rivvtype_mnemonic(funct6) ^ spc() ^ vreg_name(vd) ^ sep() ^ vreg_name(vs2) ^ sep() ^ vreg_name(vs1) ^ maybe_vmask(vm)

/* ******************* OPMVV (Single-Width Integer Reduction) ******************** */
union clause ast = RMVVTYPE : (rmvvfunct6, bits(1), regidx, regidx, regidx)

mapping encdec_rmvvfunct6 : rmvvfunct6 <-> bits(6) = {
  MVV_VREDSUM     <-> 0b000000,
  MVV_VREDAND     <-> 0b000001,
  MVV_VREDOR      <-> 0b000010,
  MVV_VREDXOR     <-> 0b000011,
  MVV_VREDMINU    <-> 0b000100,
  MVV_VREDMIN     <-> 0b000101,
  MVV_VREDMAXU    <-> 0b000110,
  MVV_VREDMAX     <-> 0b000111
}

mapping clause encdec = RMVVTYPE(funct6, vm, vs2, vs1, vd) if haveRVV()
  <-> encdec_rmvvfunct6(funct6) @ vm @ vs2 @ vs1 @ 0b010 @ vd @ 0b1010111 if haveRVV()

function clause execute(RMVVTYPE(funct6, vm, vs2, vs1, vd)) = {
  let SEW      = get_sew();
  let LMUL_pow = get_lmul_pow();
  let num_elem = get_num_elem(LMUL_pow, SEW);

  if not(valid_rd_mask(vd, vm)) then { handle_illegal(); return RETIRE_FAIL };

  let 'n = num_elem;
  let 'm = SEW;

  let vm_val   : vector('n, dec, bool)     = read_vmask(num_elem, vm, vreg_name("v0"));
  let vd_val   : vector('n, dec, bits('m)) = read_vreg(num_elem, SEW, LMUL_pow, vd);
  let vs2_val  : vector('n, dec, bits('m)) = read_vreg(num_elem, SEW, LMUL_pow, vs2);
  result       : vector('n, dec, bits('m)) = undefined;
  mask         : vector('n, dec, bool)     = undefined;

  (result, mask) = init_masked_result(num_elem, SEW, LMUL_pow, vd_val, vm_val);

  sum : bits('m) = read_single_element(SEW, 0, LMUL_pow, vs1);
  foreach (i from 0 to (num_elem - 1)) {
    if mask[i] then {
      sum = match funct6 {
        MVV_VREDSUM   => sum + vs2_val[i],
        MVV_VREDAND   => sum & vs2_val[i],
        MVV_VREDOR    => sum | vs2_val[i],
        MVV_VREDXOR   => sum ^ vs2_val[i],
        MVV_VREDMIN   => to_bits(SEW, min(signed(vs2_val[i]), signed(sum))),
        MVV_VREDMINU  => to_bits(SEW, min(unsigned(vs2_val[i]), unsigned(sum))),
        MVV_VREDMAX   => to_bits(SEW, max(signed(vs2_val[i]), signed(sum))),
        MVV_VREDMAXU  => to_bits(SEW, max(unsigned(vs2_val[i]), unsigned(sum)))
      }
    }
  };

  write_single_element(SEW, 0, LMUL_pow, vd, sum);
  vstart = EXTZ(0b0);
  RETIRE_SUCCESS
}

mapping rmvvtype_mnemonic : rmvvfunct6 <-> string = {
  MVV_VREDSUM   <-> "vredsum.vs",
  MVV_VREDAND   <-> "vredand.vs",
  MVV_VREDOR    <-> "vredor.vs",
  MVV_VREDXOR   <-> "vredxor.vs",
  MVV_VREDMINU  <-> "vredminu.vs",
  MVV_VREDMIN   <-> "vredmin.vs",
  MVV_VREDMAXU  <-> "vredmaxu.vs",
  MVV_VREDMAX   <-> "vredmax.vs"
}

mapping clause assembly = RMVVTYPE(funct6, vm, vs2, vs1, vd)
  <-> rmvvtype_mnemonic(funct6) ^ spc() ^ vreg_name(vd) ^ sep() ^ vreg_name(vs2) ^ sep() ^ vreg_name(vs1) ^ maybe_vmask(vm)  

/* ********************** OPFVV (Floating-Point Reduction) *********************** */
union clause ast = RFVVTYPE : (rfvvfunct6, bits(1), regidx, regidx, regidx)

mapping encdec_rfvvfunct6 : rfvvfunct6 <-> bits(6) = {
  FVV_VFREDOSUM   <-> 0b000011,
  FVV_VFREDUSUM   <-> 0b000001,
  FVV_VFREDMAX    <-> 0b000111,
  FVV_VFREDMIN    <-> 0b000101,
  FVV_VFWREDOSUM  <-> 0b110011,
  FVV_VFWREDUSUM  <-> 0b110001
}

mapping clause encdec = RFVVTYPE(funct6, vm, vs2, vs1, vd) if haveRVV()
  <-> encdec_rfvvfunct6(funct6) @ vm @ vs2 @ vs1 @ 0b001 @ vd @ 0b1010111 if haveRVV()

val process_rfvv_single: forall 'n 'm 'p, 'm in {8, 16, 32, 64}. (rfvvfunct6, bits(1), regidx, regidx, regidx, int('n), int('m), int('p)) -> Retired effect {escape, rreg, undef, wreg}
function process_rfvv_single(funct6, vm, vs2, vs1, vd, num_elem, SEW, LMUL_pow) = {
  let rm_3b = fcsr.FRM();
  if not(valid_fp_op(SEW, rm_3b)) then { handle_illegal(); return RETIRE_FAIL };
  assert(SEW != 8);

  let 'n = num_elem;
  let 'm = SEW;

  let vm_val  : vector('n, dec, bool)     = read_vmask(num_elem, vm, vreg_name("v0"));
  let vd_val  : vector('n, dec, bits('m)) = read_vreg(num_elem, SEW, LMUL_pow, vd);
  let vs2_val : vector('n, dec, bits('m)) = read_vreg(num_elem, SEW, LMUL_pow, vs2);
  result      : vector('n, dec, bits('m)) = undefined;
  mask        : vector('n, dec, bool)     = undefined;

  (result, mask) = init_masked_result(num_elem, SEW, LMUL_pow, vd_val, vm_val);

  sum : bits('m) = read_single_element(SEW, 0, LMUL_pow, vs1);
  foreach (i from 0 to (num_elem - 1)) {
    if mask[i] then {
      sum = match funct6 {
        FVV_VFREDOSUM   => fp_add(rm_3b, sum, vs2_val[i]),
        FVV_VFREDUSUM   => fp_add(rm_3b, sum, vs2_val[i]),
        FVV_VFREDMAX    => fp_max(sum, vs2_val[i]),
        FVV_VFREDMIN    => fp_min(sum, vs2_val[i])
      }
    }
  };

  write_single_element(SEW, 0, LMUL_pow, vd, sum);
  vstart = EXTZ(0b0);
  RETIRE_SUCCESS
}

val process_rfvv_widen: forall 'n 'm 'p, 'm in {8, 16, 32, 64}. (rfvvfunct6, bits(1), regidx, regidx, regidx, int('n), int('m), int('p)) -> Retired effect {escape, rreg, undef, wreg}
function process_rfvv_widen(funct6, vm, vs2, vs1, vd, num_elem, SEW, LMUL_pow) = {
  let rm_3b          = fcsr.FRM();
  let SEW_widen      = SEW * 2;
  let LMUL_pow_widen = LMUL_pow + 1;

  if   not(valid_eew_emul(SEW_widen, LMUL_pow_widen)) | not(valid_fp_op(SEW, rm_3b)) 
  then { handle_illegal(); return RETIRE_FAIL };
  assert(SEW >= 16 & SEW_widen <= 64);

  let 'n = num_elem;
  let 'm = SEW;
  let 'o = SEW_widen;

  let vm_val   : vector('n, dec, bool)     = read_vmask(num_elem, vm, vreg_name("v0"));
  let vd_val   : vector('n, dec, bits('o)) = read_vreg(num_elem, SEW_widen, LMUL_pow_widen, vd);
  let vs2_val  : vector('n, dec, bits('m)) = read_vreg(num_elem, SEW, LMUL_pow, vs2);
  result       : vector('n, dec, bits('o)) = undefined;
  mask         : vector('n, dec, bool)     = undefined;

  (result, mask) = init_masked_result(num_elem, SEW_widen, LMUL_pow_widen, vd_val, vm_val);

  sum : bits('o) = read_single_element(SEW_widen, 0, LMUL_pow_widen, vs1);
  foreach (i from 0 to (num_elem - 1)) {
    if mask[i] then {
      /* Currently ordered/unordered sum reductions do the same operations */
      sum = fp_add(rm_3b, sum, fp_widen(vs2_val[i]))
    }
  };

  write_single_element(SEW_widen, 0, LMUL_pow_widen, vd, sum);
  vstart = EXTZ(0b0);
  RETIRE_SUCCESS
}

function clause execute(RFVVTYPE(funct6, vm, vs2, vs1, vd)) = {
  let SEW      = get_sew();
  let LMUL_pow = get_lmul_pow();
  let num_elem = get_num_elem(LMUL_pow, SEW);

  if funct6 == FVV_VFWREDOSUM | funct6 == FVV_VFWREDUSUM then 
    process_rfvv_widen(funct6, vm, vs2, vs1, vd, num_elem, SEW, LMUL_pow)
  else
    process_rfvv_single(funct6, vm, vs2, vs1, vd, num_elem, SEW, LMUL_pow)
}

mapping rfvvtype_mnemonic : rfvvfunct6 <-> string = {
  FVV_VFREDOSUM   <-> "vfredosum.vs",
  FVV_VFREDUSUM   <-> "vfredusum.vs",
  FVV_VFREDMAX    <-> "vfredmax.vs",
  FVV_VFREDMIN    <-> "vfredmin.vs",
  FVV_VFWREDOSUM  <-> "vfwredosum.vs",
  FVV_VFWREDUSUM  <-> "vfwredusum.vs"
}

mapping clause assembly = RFVVTYPE(funct6, vm, vs2, vs1, vd)
  <-> rfvvtype_mnemonic(funct6) ^ spc() ^ vreg_name(vd) ^ sep() ^ vreg_name(vs2) ^ sep() ^ vreg_name(vs1) ^ maybe_vmask(vm)
