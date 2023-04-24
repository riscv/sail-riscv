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
/*    Peter Rugg                                                                         */
/*    Aril Computer Corp., for contributions by Scott Johnson                            */
/*    Nambi JU                                                                           */
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

/* ****************************************************************** */
/* This file specifies the instructions in the 'ZCEE' extension.      */
/* ****************************************************************** */

/* ------------------------------------------------------------------ */
/* Sail Model for the cm.jt and cm.jalt encoding group                */
/* ------------------------------------------------------------------ */
/* the assembly abstract syntax tree (AST) clause for the CM.JT instructions */

union clause ast = CM_JT : bits(8)

/* the encode/decode mapping between AST elements and 16-bit half words */

mapping clause encdec_compressed = CM_JT(index)
  <-> 0b101 @ 0b000 @ index : bits(8) @ 0b10

function clause execute (CM_JT(index)) = {

  let xlenbits = sizeof(xlen);

  let jvt_base : bits(xlen - 6) = jvt.Base();

  let addr_32 = jvt_base + EXTZ(index << 2);
  let addr_64 = jvt_base + EXTZ(index << 3);

  //let table_address : vector (xlen,dec,bit);
  
  if (xlenbits == 32) then {
    let table_address = addr_32;
  };

  if (xlenbits == 64) then {
    let table_address = addr_64;
  };

  //fetch from the jump table
  //target_address[(xlenbits - 1)..0] = InstMemory[table_address][(xlenbits - 1)..0];

//  asm ("j target_address[(xlenbits - 1):0] &~ 0x1");
  //execute(RISCV_JAL((target_address[(xlenbits - 1)..0] & 0x1),0x0));

  RETIRE_SUCCESS
}

mapping clause assembly = CM_JT(index) <->
  "cm.jt" ^ spc() ^ hex_bits_8(index)

/* ****************************************************************** */
/* the assembly abstract syntax tree (AST) clause for the CM.JALT instructions */

union clause ast = CM_JALT : bits(8)

/* the encode/decode mapping between AST elements and 16-bit half words */

mapping clause encdec_compressed = CM_JALT(index)
  <-> 0b101 @ 0b000 @ index : bits(8) @ 0b10

function clause execute (CM_JALT(index)) = {
  let xlenbits = sizeof(xlen);

  let jvt_base : bits(xlen - 6) = jvt.Base();

  let addr_32 = jvt_base + EXTZ(index << 2);
  let addr_64 = jvt_base + EXTZ(index << 3);

  //let table_address : vector (xlen,dec,bit);
  
  if (xlenbits == 32) then {
    let table_address = addr_32;
  };

  if (xlenbits == 64) then {
    let table_address = addr_64;
  };

  /*
  //fetch from the jump table
  target_address[(xlenbits - 1)..0] = InstMemory[table_address][(xlenbits - 1)..0];

  //asm("jal ra,target_address[(xlenbits - 1)..0] &~ 0x1");
  execute(RISCV_JAL((target_address[(xlenbits - 1)..0] & 0x1),0x0));
  */
  RETIRE_SUCCESS
}

mapping clause assembly = CM_JALT(index) <->
  "cm.jalt" ^ spc() ^ hex_bits_8(index)

/* ****************************************************************** */
