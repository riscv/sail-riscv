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

register elen : bits(1)

val get_elen_pow : unit -> {|5, 6|} effect {rreg}

function get_elen_pow() = match elen {
    0b0 => 5,
    0b1 => 6
}
/* Note: ELEN=32 requires a different encoding of the CSR vtype.
 * The current version of vtype implementation corresponds to the ELEN=64 configuration.
 * TODO: the configurarion of ELEN and its corresponding vtype implementations.
 */

register vlen : bits(4)

val get_vlen_pow : unit -> {|5, 6, 7, 8, 9, 10, 11, 12, 13, 14, 15, 16|} effect {rreg}

function get_vlen_pow() = match vlen {
    0b0000 => 5,
    0b0001 => 6,
    0b0010 => 7,
    0b0011 => 8,
    0b0100 => 9,
    0b0101 => 10,
    0b0110 => 11,
    0b0111 => 12,
    0b1000 => 13,
    0b1001 => 14,
    0b1010 => 15,
    _      => 16
}

type vlenmax : Int = 65536

/* Note: At present, the values of elen and vlen need to be manually speficied
 * in the init_sys() function of riscv_sys_control.sail before compiling the emulators,
 * e.g.,
 *  vlen = 0b0101;
 *  elen = 0b1;
 * means VLEN = 1024 and ELEN = 64,
 * They will be configurable when user-specified configuration is supported in Sail.
 *
 * Also, VLEN >= ELEN must be satisfied and this condition check should be added
 * after their initialization.
 */
