/*=======================================================================================*/
/*  RISCV Sail Model                                                                     */
/*                                                                                       */
/*  This Sail RISC-V architecture model, comprising all files and                        */
/*  directories except for the snapshots of the Lem and Sail libraries                   */
/*  in the prover_snapshots directory (which include copies of their                     */
/*  licences), is subject to the BSD two-clause licence below.                           */
/*                                                                                       */
/*  Copyright (c) 2017-2023                                                              */
/*    Prashanth Mundkur                                                                  */
/*    Rishiyur S. Nikhil and Bluespec, Inc.                                              */
/*    Jon French                                                                         */
/*    Brian Campbell                                                                     */
/*    Robert Norton-Wright                                                               */
/*    Alasdair Armstrong                                                                 */
/*    Thomas Bauereiss                                                                   */
/*    Shaked Flur                                                                        */
/*    Christopher Pulte                                                                  */
/*    Peter Sewell                                                                       */
/*    Alexander Richardson                                                               */
/*    Hesham Almatary                                                                    */
/*    Jessica Clarke                                                                     */
/*    Microsoft, for contributions by Robert Norton-Wright and Nathaniel Wesley Filardo  */
/*    Intel, for contributions by Pan Li                                                 */
/*    Peter Rugg                                                                         */
/*    Aril Computer Corp., for contributions by Scott Johnson                            */
/*    Philipp Tomsich                                                                    */
/*    VRULL GmbH, for contributions by its employees                                     */
/*                                                                                       */
/*  All rights reserved.                                                                 */
/*                                                                                       */
/*  This software was developed by the above within the Rigorous                         */
/*  Engineering of Mainstream Systems (REMS) project, partly funded by                   */
/*  EPSRC grant EP/K008528/1, at the Universities of Cambridge and                       */
/*  Edinburgh.                                                                           */
/*                                                                                       */
/*  This software was developed by SRI International and the University of               */
/*  Cambridge Computer Laboratory (Department of Computer Science and                    */
/*  Technology) under DARPA/AFRL contract FA8650-18-C-7809 ("CIFV"), and                 */
/*  under DARPA contract HR0011-18-C-0016 ("ECATS") as part of the DARPA                 */
/*  SSITH research programme.                                                            */
/*                                                                                       */
/*  This project has received funding from the European Research Council                 */
/*  (ERC) under the European Union’s Horizon 2020 research and innovation                */
/*  programme (grant agreement 789108, ELVER).                                           */
/*                                                                                       */
/*                                                                                       */
/*  Redistribution and use in source and binary forms, with or without                   */
/*  modification, are permitted provided that the following conditions                   */
/*  are met:                                                                             */
/*  1. Redistributions of source code must retain the above copyright                    */
/*     notice, this list of conditions and the following disclaimer.                     */
/*  2. Redistributions in binary form must reproduce the above copyright                 */
/*     notice, this list of conditions and the following disclaimer in                   */
/*     the documentation and/or other materials provided with the                        */
/*     distribution.                                                                     */
/*                                                                                       */
/*  THIS SOFTWARE IS PROVIDED BY THE AUTHOR AND CONTRIBUTORS ``AS IS''                   */
/*  AND ANY EXPRESS OR IMPLIED WARRANTIES, INCLUDING, BUT NOT LIMITED                    */
/*  TO, THE IMPLIED WARRANTIES OF MERCHANTABILITY AND FITNESS FOR A                      */
/*  PARTICULAR PURPOSE ARE DISCLAIMED.  IN NO EVENT SHALL THE AUTHOR OR                  */
/*  CONTRIBUTORS BE LIABLE FOR ANY DIRECT, INDIRECT, INCIDENTAL,                         */
/*  SPECIAL, EXEMPLARY, OR CONSEQUENTIAL DAMAGES (INCLUDING, BUT NOT                     */
/*  LIMITED TO, PROCUREMENT OF SUBSTITUTE GOODS OR SERVICES; LOSS OF                     */
/*  USE, DATA, OR PROFITS; OR BUSINESS INTERRUPTION) HOWEVER CAUSED AND                  */
/*  ON ANY THEORY OF LIABILITY, WHETHER IN CONTRACT, STRICT LIABILITY,                   */
/*  OR TORT (INCLUDING NEGLIGENCE OR OTHERWISE) ARISING IN ANY WAY OUT                   */
/*  OF THE USE OF THIS SOFTWARE, EVEN IF ADVISED OF THE POSSIBILITY OF                   */
/*  SUCH DAMAGE.                                                                         */
/*=======================================================================================*/

/* **************************************************************** */
/* This file implements the floating-point for equal and consumes   */
/* by the softfloat API contract, riscv_softfloat_interface.sail.   */
/*                                                                  */
/* The below floating-point types are supported.                    */
/* 1. Double-precision, aka 64 bits floating-point.                 */
/* 2. Single-precision, aka 32 bits floating-point.                 */
/* 3. Half-precision, aka 16 bits floating-point.                   */
/*                                                                  */
/* However, the implementation still need some global variables in  */
/* file riscv_softfloat_interface.sail. It includes:                */
/* 1. float_result.                                                 */
/* 2. float_fflags.                                                 */
/* 3. float_roundingMode.                                           */
/* **************************************************************** */

val            operator == : (bits_S, bits_S) -> bool
val            operator |  : (bool, bool) -> bool
val            operator |  : (bits_S, bits_S) -> bits_S
val            operator << : (bits_S, int) -> bits_S
val  f_is_at_least_one_NaN : forall 'm, 'm in {16, 32, 64}. (bits('m), bits('m)) -> bool
val f_is_at_least_one_SNaN : forall 'm, 'm in {16, 32, 64}. (bits('m), bits('m)) -> bool

val      riscv_float_f16_eq : (bits_H, bits_H) -> unit
function riscv_float_f16_eq (op1, op2) = {
  riscv_float_enter (0b000);

  var result : bits_H = zeros(16);

  if f_is_at_least_one_NaN (op1, op2) then {
    if f_is_at_least_one_SNaN (op1, op2) then {
      riscv_float_raise_flags (float_flag_invalid);
    };
  } else if op1 == op2 | ((op1 | op2) << 1) == zeros(16) then {
    result[0] = bitone;
  };

  riscv_float_leave (result);
}

val      riscv_float_f32_eq : (bits_S, bits_S) -> unit
function riscv_float_f32_eq (op1, op2) = {
  riscv_float_enter (0b000);

  var result : bits_S = zeros(32);

  if f_is_at_least_one_NaN (op1, op2) then {
    if f_is_at_least_one_SNaN (op1, op2) then {
      riscv_float_raise_flags (float_flag_invalid);
    };
  } else if op1 == op2 | ((op1 | op2) << 1) == zeros(32) then {
    result[0] = bitone;
  };

  riscv_float_leave (result);
}

val      riscv_float_f64_eq : (bits_D, bits_D) -> unit
function riscv_float_f64_eq (op1, op2) = {
  riscv_float_enter (0b000);

  var result : bits_D = zeros(64);

  if f_is_at_least_one_NaN (op1, op2) then {
    if f_is_at_least_one_SNaN (op1, op2) then {
      riscv_float_raise_flags (float_flag_invalid);
    };
  } else if op1 == op2 | ((op1 | op2) & 0x7fffffffffffffff) == zeros(64) then {
    result[0] = bitone;
  };

  riscv_float_leave (result);
}

val      riscv_float_eq : forall 'm, 'm in {16, 32, 64}. (bits('m), bits('m)) -> unit
function riscv_float_eq (op1, op2) = {
  match 'm {
    16 => riscv_float_f16_eq(op1, op2),
    32 => riscv_float_f32_eq(op1, op2),
    64 => riscv_float_f64_eq(op1, op2),
  }
}
