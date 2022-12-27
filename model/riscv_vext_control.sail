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

function clause ext_is_CSR_defined (0x008, _) = true
function clause ext_is_CSR_defined (0xC20, _) = true
function clause ext_is_CSR_defined (0xC21, _) = true
function clause ext_is_CSR_defined (0xC22, _) = true

function clause ext_is_CSR_defined (0x009, _) = true
function clause ext_is_CSR_defined (0x00A, _) = true
function clause ext_is_CSR_defined (0x00F, _) = true

function clause ext_read_CSR (0x009) = Some (zero_extend(vcsr.vxsat()))
function clause ext_read_CSR (0x00A) = Some (zero_extend(vcsr.vxrm()))
function clause ext_read_CSR (0x00F) = Some (zero_extend(vcsr.bits()))

function clause ext_read_CSR (0x009) = Some (zero_extend(vcsr.vxsat()))
function clause ext_read_CSR (0x00A) = Some (zero_extend(vcsr.vxrm()))
function clause ext_read_CSR (0x00F) = Some (zero_extend(vcsr.bits()))

function clause ext_write_CSR (0x009, value) = { ext_write_vcsr (vcsr.vxrm(), value[0 .. 0]); Some(zero_extend(vcsr.vxsat())) }
function clause ext_write_CSR (0x00A, value) = { ext_write_vcsr (value[1 .. 0], vcsr.vxsat()); Some(zero_extend(vcsr.vxrm())) }
function clause ext_write_CSR (0x00F, value) = { ext_write_vcsr (value [2 .. 1], value [0 .. 0]); Some(zero_extend(vcsr.bits())) }
