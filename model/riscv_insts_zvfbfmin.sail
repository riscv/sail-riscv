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
/*      Andrew de los Reyes <adlr@rivosinc.com>                                    */
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

/* ************************** OPFVV (VFUNARY0 Widening) ************************** */

mapping encdec_vfwunarybf16_0_vs1 : vfwunary0 <-> bits(5) = {
  FWV_CVT_BF16_F_F  <-> 0b01101
}

mapping clause encdec = VFWUNARY0(vm, vs2, vfwunary0, vd) if haveZvfbfmin()
  <-> 0b010010 @ vm @ vs2 @ encdec_vfwunarybf16_0_vs1(vfwunary0) @ 0b001 @ vd @ 0b1010111 if haveZvfbfmin()

mapping vfwunary0_mnemonic_bf16 : vfwunary0 <-> string = {
  FWV_CVT_BF16_F_F  <-> "vfwcvtbf16.f.f.v"
}

mapping clause assembly = VFWUNARY0(vm, vs2, vfwunary0, vd)
  <-> vfwunary0_mnemonic_bf16(vfwunary0) ^ spc() ^ vreg_name(vd) ^ sep() ^ vreg_name(vs2) ^ maybe_vmask(vm)

/* ************************* OPFVV (VFUNARY0 Narrowing) ************************** */

mapping encdec_vfnunarybf16_0_vs1 : vfnunary0 <-> bits(5) = {
  FNV_CVT_BF16_F_F  <-> 0b11101
}

mapping clause encdec = VFNUNARY0(vm, vs2, vfnunary0, vd) if haveRVV()
  <-> 0b010010 @ vm @ vs2 @ encdec_vfnunarybf16_0_vs1(vfnunary0) @ 0b001 @ vd @ 0b1010111 if haveRVV()

mapping vfnunary0_mnemonic_bf16 : vfnunary0 <-> string = {
  FNV_CVT_BF16_F_F  <-> "vfncvtbf16.f.f.w"
}

mapping clause assembly = VFNUNARY0(vm, vs2, vfnunary0, vd)
  <-> vfnunary0_mnemonic_bf16(vfnunary0) ^ spc() ^ vreg_name(vd) ^ sep() ^ vreg_name(vs2) ^ maybe_vmask(vm)
