/*==========================================================================*/
/*     Sail                                                                 */
/*                                                                          */
/*  Sail and the Sail architecture models here, comprising all files and    */
/*  directories except the ASL-derived Sail code in the aarch64 directory,  */
/*  are subject to the BSD two-clause licence below.                        */
/*                                                                          */
/*  The ASL derived parts of the ARMv8.3 specification in                   */
/*  aarch64/no_vector and aarch64/full are copyright ARM Ltd.               */
/*                                                                          */
/*  Copyright (c) 2013-2021                                                 */
/*    Kathyrn Gray                                                          */
/*    Shaked Flur                                                           */
/*    Stephen Kell                                                          */
/*    Gabriel Kerneis                                                       */
/*    Robert Norton-Wright                                                  */
/*    Christopher Pulte                                                     */
/*    Peter Sewell                                                          */
/*    Alasdair Armstrong                                                    */
/*    Brian Campbell                                                        */
/*    Thomas Bauereiss                                                      */
/*    Anthony Fox                                                           */
/*    Jon French                                                            */
/*    Dominic Mulligan                                                      */
/*    Stephen Kell                                                          */
/*    Mark Wassell                                                          */
/*    Alastair Reid (Arm Ltd)                                               */
/*                                                                          */
/*  All rights reserved.                                                    */
/*                                                                          */
/*  This work was partially supported by EPSRC grant EP/K008528/1 <a        */
/*  href="http://www.cl.cam.ac.uk/users/pes20/rems">REMS: Rigorous          */
/*  Engineering for Mainstream Systems</a>, an ARM iCASE award, EPSRC IAA   */
/*  KTF funding, and donations from Arm.  This project has received         */
/*  funding from the European Research Council (ERC) under the European     */
/*  Union’s Horizon 2020 research and innovation programme (grant           */
/*  agreement No 789108, ELVER).                                            */
/*                                                                          */
/*  This software was developed by SRI International and the University of  */
/*  Cambridge Computer Laboratory (Department of Computer Science and       */
/*  Technology) under DARPA/AFRL contracts FA8650-18-C-7809 ("CIFV")        */
/*  and FA8750-10-C-0237 ("CTSRD").                                         */
/*                                                                          */
/*  Redistribution and use in source and binary forms, with or without      */
/*  modification, are permitted provided that the following conditions      */
/*  are met:                                                                */
/*  1. Redistributions of source code must retain the above copyright       */
/*     notice, this list of conditions and the following disclaimer.        */
/*  2. Redistributions in binary form must reproduce the above copyright    */
/*     notice, this list of conditions and the following disclaimer in      */
/*     the documentation and/or other materials provided with the           */
/*     distribution.                                                        */
/*                                                                          */
/*  THIS SOFTWARE IS PROVIDED BY THE AUTHOR AND CONTRIBUTORS ``AS IS''      */
/*  AND ANY EXPRESS OR IMPLIED WARRANTIES, INCLUDING, BUT NOT LIMITED       */
/*  TO, THE IMPLIED WARRANTIES OF MERCHANTABILITY AND FITNESS FOR A         */
/*  PARTICULAR PURPOSE ARE DISCLAIMED.  IN NO EVENT SHALL THE AUTHOR OR     */
/*  CONTRIBUTORS BE LIABLE FOR ANY DIRECT, INDIRECT, INCIDENTAL,            */
/*  SPECIAL, EXEMPLARY, OR CONSEQUENTIAL DAMAGES (INCLUDING, BUT NOT        */
/*  LIMITED TO, PROCUREMENT OF SUBSTITUTE GOODS OR SERVICES; LOSS OF        */
/*  USE, DATA, OR PROFITS; OR BUSINESS INTERRUPTION) HOWEVER CAUSED AND     */
/*  ON ANY THEORY OF LIABILITY, WHETHER IN CONTRACT, STRICT LIABILITY,      */
/*  OR TORT (INCLUDING NEGLIGENCE OR OTHERWISE) ARISING IN ANY WAY OUT      */
/*  OF THE USE OF THIS SOFTWARE, EVEN IF ADVISED OF THE POSSIBILITY OF      */
/*  SUCH DAMAGE.                                                            */
/*==========================================================================*/

$ifndef _HEX_BITS_SIGNED
$define _HEX_BITS_SIGNED

$include <vector.sail>
$include <string.sail>

val parse_hex_bits_signed : forall 'n, 'n > 0. (int('n), string) -> bits('n)
val valid_hex_bits_signed : forall 'n, 'n > 0. (int('n), string) -> bool

val hex_bits_signed: forall 'n, 'n > 0. bits('n) <-> (int('n), string)

function hex_bits_signed_forwards(bv) = {
  if signed(bv) < 0
  then (length(bv), concat_str("-", hex_str(unsigned(not_vec(bv) + 1))))
  else (length(bv), hex_str(unsigned(bv)))
}
function hex_bits_signed_forwards_matches(bv) = true

function parse_hex_bits_signed(n, str) = {
  if string_take(str, 1) == "-"
  then {
    let str_ = string_drop(str, 1);
    let bv = parse_hex_bits(n, str_);
    not_vec(bv) + 1
  }
  else parse_hex_bits(n, str)
}

function valid_hex_bits_signed(n, str) = {
  if string_take(str, 1) == "-"
  then valid_hex_bits(n, string_drop(str, 1))
  else valid_hex_bits(n, str)
}

function hex_bits_signed_backwards(n, str) = parse_hex_bits_signed(n, str)
function hex_bits_signed_backwards_matches(n, str) = valid_hex_bits_signed(n, str)

mapping hex_bits_signed_1 : bits(1) <-> string = { hex_bits_signed(1, s) <-> s }
mapping hex_bits_signed_2 : bits(2) <-> string = { hex_bits_signed(2, s) <-> s }
mapping hex_bits_signed_3 : bits(3) <-> string = { hex_bits_signed(3, s) <-> s }
mapping hex_bits_signed_4 : bits(4) <-> string = { hex_bits_signed(4, s) <-> s }
mapping hex_bits_signed_5 : bits(5) <-> string = { hex_bits_signed(5, s) <-> s }
mapping hex_bits_signed_6 : bits(6) <-> string = { hex_bits_signed(6, s) <-> s }
mapping hex_bits_signed_7 : bits(7) <-> string = { hex_bits_signed(7, s) <-> s }
mapping hex_bits_signed_8 : bits(8) <-> string = { hex_bits_signed(8, s) <-> s }
mapping hex_bits_signed_9 : bits(9) <-> string = { hex_bits_signed(9, s) <-> s }

mapping hex_bits_signed_10 : bits(10) <-> string = { hex_bits_signed(10, s) <-> s }
mapping hex_bits_signed_11 : bits(11) <-> string = { hex_bits_signed(11, s) <-> s }
mapping hex_bits_signed_12 : bits(12) <-> string = { hex_bits_signed(12, s) <-> s }
mapping hex_bits_signed_13 : bits(13) <-> string = { hex_bits_signed(13, s) <-> s }
mapping hex_bits_signed_14 : bits(14) <-> string = { hex_bits_signed(14, s) <-> s }
mapping hex_bits_signed_15 : bits(15) <-> string = { hex_bits_signed(15, s) <-> s }
mapping hex_bits_signed_16 : bits(16) <-> string = { hex_bits_signed(16, s) <-> s }
mapping hex_bits_signed_17 : bits(17) <-> string = { hex_bits_signed(17, s) <-> s }
mapping hex_bits_signed_18 : bits(18) <-> string = { hex_bits_signed(18, s) <-> s }
mapping hex_bits_signed_19 : bits(19) <-> string = { hex_bits_signed(19, s) <-> s }

mapping hex_bits_signed_20 : bits(20) <-> string = { hex_bits_signed(20, s) <-> s }
mapping hex_bits_signed_21 : bits(21) <-> string = { hex_bits_signed(21, s) <-> s }
mapping hex_bits_signed_22 : bits(22) <-> string = { hex_bits_signed(22, s) <-> s }
mapping hex_bits_signed_23 : bits(23) <-> string = { hex_bits_signed(23, s) <-> s }
mapping hex_bits_signed_24 : bits(24) <-> string = { hex_bits_signed(24, s) <-> s }
mapping hex_bits_signed_25 : bits(25) <-> string = { hex_bits_signed(25, s) <-> s }
mapping hex_bits_signed_26 : bits(26) <-> string = { hex_bits_signed(26, s) <-> s }
mapping hex_bits_signed_27 : bits(27) <-> string = { hex_bits_signed(27, s) <-> s }
mapping hex_bits_signed_28 : bits(28) <-> string = { hex_bits_signed(28, s) <-> s }
mapping hex_bits_signed_29 : bits(29) <-> string = { hex_bits_signed(29, s) <-> s }

mapping hex_bits_signed_30 : bits(30) <-> string = { hex_bits_signed(30, s) <-> s }
mapping hex_bits_signed_31 : bits(31) <-> string = { hex_bits_signed(31, s) <-> s }
mapping hex_bits_signed_32 : bits(32) <-> string = { hex_bits_signed(32, s) <-> s }

$endif _HEX_BITS_SIGNED
