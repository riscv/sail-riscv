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
/* Sail Model for the cm.push encoding group                          */
/* ------------------------------------------------------------------ */
/* the assembly abstract syntax tree (AST) clause for the CM.PUSH instructions */

union clause ast = CM_PUSH : (bits(4), bits(2))

/* the encode/decode mapping between AST elements and 16-bit half words */

mapping clause encdec_compressed = CM_PUSH(rlist,spimm)
  <-> 0b101 @ 0b11000 @ rlist : bits(4) @ spimm : bits(2) @ 0b10

function clause execute (CM_PUSH(rlist,spimm)) = {

  var bytes : bits(4) = zeros();
  
  if (sizeof(xlen) == 32) then {
    bytes = 0x4
  };
  
  if (sizeof(xlen) == 64) then {
    bytes = 0x8
  };

  reg_list : vector (13,dec,int) = [0,0,0,0,0,0,0,0,0,0,0,0,0];
  
  match (rlist) {
    0x4 => reg_list = [0,0,0,0,0,0,0,0,0,0,0,0,1],     
    0x5 => reg_list = [0,0,0,0,0,0,0,0,0,0,0,8,1],     
    0x6 => reg_list = [0,0,0,0,0,0,0,0,0,0,9,8,1],     
    0x7 => reg_list = [0,0,0,0,0,0,0,0,0,18,9,8,1],    
    0x8 => reg_list = [0,0,0,0,0,0,0,0,19,18,9,8,1],   
    0x9 => reg_list = [0,0,0,0,0,0,0,20,19,18,9,8,1],  
    0xa => reg_list = [0,0,0,0,0,0,21,20,19,18,9,8,1], 
    0xb => reg_list = [0,0,0,0,0,22,21,20,19,18,9,8,1],   
    0xc => reg_list = [0,0,0,0,23,22,21,20,19,18,9,8,1],  
    0xd => reg_list = [0,0,0,24,23,22,21,20,19,18,9,8,1], 
    0xe => reg_list = [0,0,25,24,23,22,21,20,19,18,9,8,1],
    //note - to include s10, s11 must also be included
    0xf => reg_list = [27,26,25,24,23,22,21,20,19,18,9,8,1],
//     _  => None()
  };


  stack_adj_base : bits(xlen) = zeros();
  stack_adj : bits(xlen) = zeros();
  
  if (sizeof(xlen) == 32) then {
    match (rlist) {
      0x4 => {stack_adj_base = EXTZ(0x10);}, //16;},
      0x5 => {stack_adj_base = EXTZ(0x10);}, //16;},
      0x6 => {stack_adj_base = EXTZ(0x10);}, //16;},
      0x7 => {stack_adj_base = EXTZ(0x10);}, //16;},
      0x8 => {stack_adj_base = EXTZ(0x20);}, //32;},
      0x9 => {stack_adj_base = EXTZ(0x20);}, //32;},
      0xa => {stack_adj_base = EXTZ(0x20);}, //32;},
      0xb => {stack_adj_base = EXTZ(0x20);}, //32;}, 
      0xc => {stack_adj_base = EXTZ(0x30);}, //48;}, 
      0xd => {stack_adj_base = EXTZ(0x30);}, //48;}, 
      0xe => {stack_adj_base = EXTZ(0x30);}, //48;}, 
      0xf => {stack_adj_base = EXTZ(0x40);}, //64;} 
    };
    /* Need to validate the value of stack_adj here */
/*    match (rlist) {                                  
        0x4 => {let stack_adj = 16;}, //|32|48| 64];},
        0x5 => {stack_adj =     16;}, //|32|48| 64];},
        0x6 => {stack_adj =     16;}, //|32|48| 64];},
        0x7 => {stack_adj =     16;}, //|32|48| 64];},
        0x8 => {stack_adj =     32;}, //|48|64| 80];},
        0x9 => {stack_adj =     32;}, //|48|64| 80];},
        0xa => {stack_adj =     32;}, //|48|64| 80];},
        0xb => {stack_adj =     32;}, //|48|64| 80];}, 
        0xc => {stack_adj =     48;}, //|64|80| 96];}, 
        0xd => {stack_adj =     48;}, //|64|80| 96];}, 
        0xe => {stack_adj =     48;}, //|64|80| 96];}, 
        0xf => {stack_adj =     64;} //|80|96|112];}
      };
    */
    } else {
    match (rlist) {
      0x4 => {stack_adj_base = EXTZ(0x10);}, //16;},
      0x5 => {stack_adj_base = EXTZ(0x10);}, //16;},
      0x6 => {stack_adj_base = EXTZ(0x20);}, //32;},
      0x7 => {stack_adj_base = EXTZ(0x20);}, //32;},
      0x8 => {stack_adj_base = EXTZ(0x30);}, //48;},
      0x9 => {stack_adj_base = EXTZ(0x30);}, //48;},
      0xa => {stack_adj_base = EXTZ(0x40);}, //64;},
      0xb => {stack_adj_base = EXTZ(0x40);}, //64;}, 
      0xc => {stack_adj_base = EXTZ(0x50);}, //80;}, 
      0xd => {stack_adj_base = EXTZ(0x50);}, //80;}, 
      0xe => {stack_adj_base = EXTZ(0x60);}, //96;}, 
      0xf => {stack_adj_base = EXTZ(0x70);}, //112;} 
    };
    /* Need to validate the value of stack_adj here */
    /*    match (rlist) {                                  
      0x4 => {stack_adj =  16;}, //[| 32| 48| 64];},
      0x5 => {stack_adj =  16;}, //[| 32| 48| 64];},
      0x6 => {stack_adj =  32;}, //[| 48| 64| 80];},
      0x7 => {stack_adj =  32;}, //[| 48| 64| 80];},
      0x8 => {stack_adj =  48;}, //[| 64| 80| 96];},
      0x9 => {stack_adj =  48;}, //[| 64| 80| 96];},
      0xa => {stack_adj =  64;}, //[| 80| 96|112];},
      0xb => {stack_adj =  64;}, //[| 80| 96|112];}, 
      0xc => {stack_adj =  80;}, //[| 96|112|128];}, 
      0xd => {stack_adj =  80;}, //[| 96|112|128];}, 
      0xe => {stack_adj =  96;}, //[|112|128|144];}, 
      0xf => {stack_adj = 112;}  //[|128|144|160];}
    };*/
  };

  let stack_adj_by : bits(xlen) = EXTZ(spimm << 4);
  stack_adj = stack_adj_base + stack_adj_by;

  let addr : bits(xlen) = X(sp) - EXTZ(bytes);

  let l : vector (13,dec,int) = [27,26,25,24,23,22,21,20,19,18,9,8,1];
/*
  foreach (i from 1 to 13) {
    //if register i is in xreg_list
    if (reg_list[i]) then {
      match bytes {
        4 => exectue (C_SW(0b000 @ spimm,x[reg_list[i]],addr)), //asm("sw x[reg_list[i]], 0(addr)"),
        8 => execute (C_SD(0b000 @ spimm,x[reg_list[i]],addr)) //asm("sd x[reg_list[i]], 0(addr)")
      };
      addr = addr - bytes;
    }
  };
  */
  X(sp) = X(sp) - stack_adj;
  
  RETIRE_SUCCESS
}

mapping clause assembly = CM_PUSH(rlist,spimm) <->
  "cm.push" ^ spc() ^ hex_bits_4(rlist) ^ sep() ^ hex_bits_2(spimm)

/* ------------------------------------------------------------------ */
/* Sail Model for the cm.pop encoding group                           */
/* ------------------------------------------------------------------ */
/* the assembly abstract syntax tree (AST) clause for the CM.POP instructions */

union clause ast = CM_POP : (bits(4), bits(2))

/* the encode/decode mapping between AST elements and 16-bit half words */

mapping clause encdec_compressed = CM_POP(rlist,spimm)
  <-> 0b101 @ 0b11010 @ rlist : bits(4) @ spimm : bits(2) @ 0b10

function clause execute (CM_POP(rlist,spimm)) = {
  
  var bytes : bits(4) = zeros();
  
  if (sizeof(xlen) == 32) then {
    bytes = 0x4
  };
  
  if (sizeof(xlen) == 64) then {
    bytes = 0x8
  };

  reg_list : vector (13,dec,int) = [0,0,0,0,0,0,0,0,0,0,0,0,0];
  
  match (rlist) {
    0x4 => reg_list = [0,0,0,0,0,0,0,0,0,0,0,0,1],     
    0x5 => reg_list = [0,0,0,0,0,0,0,0,0,0,0,8,1],     
    0x6 => reg_list = [0,0,0,0,0,0,0,0,0,0,9,8,1],     
    0x7 => reg_list = [0,0,0,0,0,0,0,0,0,18,9,8,1],    
    0x8 => reg_list = [0,0,0,0,0,0,0,0,19,18,9,8,1],   
    0x9 => reg_list = [0,0,0,0,0,0,0,20,19,18,9,8,1],  
    0xa => reg_list = [0,0,0,0,0,0,21,20,19,18,9,8,1], 
    0xb => reg_list = [0,0,0,0,0,22,21,20,19,18,9,8,1],   
    0xc => reg_list = [0,0,0,0,23,22,21,20,19,18,9,8,1],  
    0xd => reg_list = [0,0,0,24,23,22,21,20,19,18,9,8,1], 
    0xe => reg_list = [0,0,25,24,23,22,21,20,19,18,9,8,1],
    //note - to include s10, s11 must also be included
    0xf => reg_list = [27,26,25,24,23,22,21,20,19,18,9,8,1],
//     _  => None()
  };


  stack_adj_base : bits(xlen) = zeros();
  stack_adj : bits(xlen) = zeros();
  
  if (sizeof(xlen) == 32) then {
    match (rlist) {
      0x4 => {stack_adj_base = EXTZ(0x10);}, //16;},
      0x5 => {stack_adj_base = EXTZ(0x10);}, //16;},
      0x6 => {stack_adj_base = EXTZ(0x10);}, //16;},
      0x7 => {stack_adj_base = EXTZ(0x10);}, //16;},
      0x8 => {stack_adj_base = EXTZ(0x20);}, //32;},
      0x9 => {stack_adj_base = EXTZ(0x20);}, //32;},
      0xa => {stack_adj_base = EXTZ(0x20);}, //32;},
      0xb => {stack_adj_base = EXTZ(0x20);}, //32;}, 
      0xc => {stack_adj_base = EXTZ(0x30);}, //48;}, 
      0xd => {stack_adj_base = EXTZ(0x30);}, //48;}, 
      0xe => {stack_adj_base = EXTZ(0x30);}, //48;}, 
      0xf => {stack_adj_base = EXTZ(0x40);}, //64;} 
    };
    /* Need to validate the value of stack_adj here */
/*    match (rlist) {                                  
        0x4 => {let stack_adj = 16;}, //|32|48| 64];},
        0x5 => {stack_adj =     16;}, //|32|48| 64];},
        0x6 => {stack_adj =     16;}, //|32|48| 64];},
        0x7 => {stack_adj =     16;}, //|32|48| 64];},
        0x8 => {stack_adj =     32;}, //|48|64| 80];},
        0x9 => {stack_adj =     32;}, //|48|64| 80];},
        0xa => {stack_adj =     32;}, //|48|64| 80];},
        0xb => {stack_adj =     32;}, //|48|64| 80];}, 
        0xc => {stack_adj =     48;}, //|64|80| 96];}, 
        0xd => {stack_adj =     48;}, //|64|80| 96];}, 
        0xe => {stack_adj =     48;}, //|64|80| 96];}, 
        0xf => {stack_adj =     64;} //|80|96|112];}
      };
    */
    } else {
    match (rlist) {
      0x4 => {stack_adj_base = EXTZ(0x10);}, //16;},
      0x5 => {stack_adj_base = EXTZ(0x10);}, //16;},
      0x6 => {stack_adj_base = EXTZ(0x20);}, //32;},
      0x7 => {stack_adj_base = EXTZ(0x20);}, //32;},
      0x8 => {stack_adj_base = EXTZ(0x30);}, //48;},
      0x9 => {stack_adj_base = EXTZ(0x30);}, //48;},
      0xa => {stack_adj_base = EXTZ(0x40);}, //64;},
      0xb => {stack_adj_base = EXTZ(0x40);}, //64;}, 
      0xc => {stack_adj_base = EXTZ(0x50);}, //80;}, 
      0xd => {stack_adj_base = EXTZ(0x50);}, //80;}, 
      0xe => {stack_adj_base = EXTZ(0x60);}, //96;}, 
      0xf => {stack_adj_base = EXTZ(0x70);}, //112;} 
    };
    /* Need to validate the value of stack_adj here */
    /*    match (rlist) {                                  
      0x4 => {stack_adj =  16;}, //[| 32| 48| 64];},
      0x5 => {stack_adj =  16;}, //[| 32| 48| 64];},
      0x6 => {stack_adj =  32;}, //[| 48| 64| 80];},
      0x7 => {stack_adj =  32;}, //[| 48| 64| 80];},
      0x8 => {stack_adj =  48;}, //[| 64| 80| 96];},
      0x9 => {stack_adj =  48;}, //[| 64| 80| 96];},
      0xa => {stack_adj =  64;}, //[| 80| 96|112];},
      0xb => {stack_adj =  64;}, //[| 80| 96|112];}, 
      0xc => {stack_adj =  80;}, //[| 96|112|128];}, 
      0xd => {stack_adj =  80;}, //[| 96|112|128];}, 
      0xe => {stack_adj =  96;}, //[|112|128|144];}, 
      0xf => {stack_adj = 112;}  //[|128|144|160];}
    };*/
  };

  let stack_adj_by : bits(xlen) = EXTZ(spimm << 4);
  stack_adj = stack_adj_base + stack_adj_by;

  let addr : bits(xlen) = X(sp) - EXTZ(bytes);

  let l : vector (13,dec,int) = [27,26,25,24,23,22,21,20,19,18,9,8,1];
/*
  foreach (i from 1 to 13) {
    //if register i is in xreg_list
    if (reg_list[i]) then {
      match bytes {
        4 => exectue (C_LW(0b000 @ spimm,x[reg_list[i]],addr)), //asm("lw x[reg_list[i]], 0(addr)"),
        8 => execute (C_LD(0b000 @ spimm,x[reg_list[i]],addr)) //asm("ld x[reg_list[i]], 0(addr)")
      };
      addr = addr - bytes;
    }
  };
  */
  X(sp) = X(sp) + stack_adj;
  
  RETIRE_SUCCESS
}

mapping clause assembly = CM_POP(rlist,spimm) <->
  "cm.pop" ^ spc() ^ hex_bits_4(rlist) ^ sep() ^ hex_bits_2(spimm)

/* ------------------------------------------------------------------ */
/* Sail Model for the cm.popretz encoding group                           */
/* ------------------------------------------------------------------ */
/* the assembly abstract syntax tree (AST) clause for the CM.POPRETZ instructions */

union clause ast = CM_POPRETZ : (bits(4), bits(2))

/* the encode/decode mapping between AST elements and 16-bit half words */

mapping clause encdec_compressed = CM_POPRETZ(rlist,spimm)
  <-> 0b101 @ 0b11100 @ rlist : bits(4) @ spimm : bits(2) @ 0b10

function clause execute (CM_POPRETZ(rlist,spimm)) = {
  var bytes : bits(4) = zeros();
  
  if (sizeof(xlen) == 32) then {
    bytes = 0x4
  };
  
  if (sizeof(xlen) == 64) then {
    bytes = 0x8
  };

  reg_list : vector (13,dec,int) = [0,0,0,0,0,0,0,0,0,0,0,0,0];
  
  match (rlist) {
    0x4 => reg_list = [0,0,0,0,0,0,0,0,0,0,0,0,1],     
    0x5 => reg_list = [0,0,0,0,0,0,0,0,0,0,0,8,1],     
    0x6 => reg_list = [0,0,0,0,0,0,0,0,0,0,9,8,1],     
    0x7 => reg_list = [0,0,0,0,0,0,0,0,0,18,9,8,1],    
    0x8 => reg_list = [0,0,0,0,0,0,0,0,19,18,9,8,1],   
    0x9 => reg_list = [0,0,0,0,0,0,0,20,19,18,9,8,1],  
    0xa => reg_list = [0,0,0,0,0,0,21,20,19,18,9,8,1], 
    0xb => reg_list = [0,0,0,0,0,22,21,20,19,18,9,8,1],   
    0xc => reg_list = [0,0,0,0,23,22,21,20,19,18,9,8,1],  
    0xd => reg_list = [0,0,0,24,23,22,21,20,19,18,9,8,1], 
    0xe => reg_list = [0,0,25,24,23,22,21,20,19,18,9,8,1],
    //note - to include s10, s11 must also be included
    0xf => reg_list = [27,26,25,24,23,22,21,20,19,18,9,8,1],
//     _  => None()
  };


  stack_adj_base : bits(xlen) = zeros();
  stack_adj : bits(xlen) = zeros();
  
  if (sizeof(xlen) == 32) then {
    match (rlist) {
      0x4 => {stack_adj_base = EXTZ(0x10);}, //16;},
      0x5 => {stack_adj_base = EXTZ(0x10);}, //16;},
      0x6 => {stack_adj_base = EXTZ(0x10);}, //16;},
      0x7 => {stack_adj_base = EXTZ(0x10);}, //16;},
      0x8 => {stack_adj_base = EXTZ(0x20);}, //32;},
      0x9 => {stack_adj_base = EXTZ(0x20);}, //32;},
      0xa => {stack_adj_base = EXTZ(0x20);}, //32;},
      0xb => {stack_adj_base = EXTZ(0x20);}, //32;}, 
      0xc => {stack_adj_base = EXTZ(0x30);}, //48;}, 
      0xd => {stack_adj_base = EXTZ(0x30);}, //48;}, 
      0xe => {stack_adj_base = EXTZ(0x30);}, //48;}, 
      0xf => {stack_adj_base = EXTZ(0x40);}, //64;} 
    };
    /* Need to validate the value of stack_adj here */
/*    match (rlist) {                                  
        0x4 => {let stack_adj = 16;}, //|32|48| 64];},
        0x5 => {stack_adj =     16;}, //|32|48| 64];},
        0x6 => {stack_adj =     16;}, //|32|48| 64];},
        0x7 => {stack_adj =     16;}, //|32|48| 64];},
        0x8 => {stack_adj =     32;}, //|48|64| 80];},
        0x9 => {stack_adj =     32;}, //|48|64| 80];},
        0xa => {stack_adj =     32;}, //|48|64| 80];},
        0xb => {stack_adj =     32;}, //|48|64| 80];}, 
        0xc => {stack_adj =     48;}, //|64|80| 96];}, 
        0xd => {stack_adj =     48;}, //|64|80| 96];}, 
        0xe => {stack_adj =     48;}, //|64|80| 96];}, 
        0xf => {stack_adj =     64;} //|80|96|112];}
      };
    */
    } else {
    match (rlist) {
      0x4 => {stack_adj_base = EXTZ(0x10);}, //16;},
      0x5 => {stack_adj_base = EXTZ(0x10);}, //16;},
      0x6 => {stack_adj_base = EXTZ(0x20);}, //32;},
      0x7 => {stack_adj_base = EXTZ(0x20);}, //32;},
      0x8 => {stack_adj_base = EXTZ(0x30);}, //48;},
      0x9 => {stack_adj_base = EXTZ(0x30);}, //48;},
      0xa => {stack_adj_base = EXTZ(0x40);}, //64;},
      0xb => {stack_adj_base = EXTZ(0x40);}, //64;}, 
      0xc => {stack_adj_base = EXTZ(0x50);}, //80;}, 
      0xd => {stack_adj_base = EXTZ(0x50);}, //80;}, 
      0xe => {stack_adj_base = EXTZ(0x60);}, //96;}, 
      0xf => {stack_adj_base = EXTZ(0x70);}, //112;} 
    };
    /* Need to validate the value of stack_adj here */
    /*    match (rlist) {                                  
      0x4 => {stack_adj =  16;}, //[| 32| 48| 64];},
      0x5 => {stack_adj =  16;}, //[| 32| 48| 64];},
      0x6 => {stack_adj =  32;}, //[| 48| 64| 80];},
      0x7 => {stack_adj =  32;}, //[| 48| 64| 80];},
      0x8 => {stack_adj =  48;}, //[| 64| 80| 96];},
      0x9 => {stack_adj =  48;}, //[| 64| 80| 96];},
      0xa => {stack_adj =  64;}, //[| 80| 96|112];},
      0xb => {stack_adj =  64;}, //[| 80| 96|112];}, 
      0xc => {stack_adj =  80;}, //[| 96|112|128];}, 
      0xd => {stack_adj =  80;}, //[| 96|112|128];}, 
      0xe => {stack_adj =  96;}, //[|112|128|144];}, 
      0xf => {stack_adj = 112;}  //[|128|144|160];}
    };*/
  };

  let stack_adj_by : bits(xlen) = EXTZ(spimm << 4);
  stack_adj = stack_adj_base + stack_adj_by;

  let addr : bits(xlen) = X(sp) - EXTZ(bytes);

  let l : vector (13,dec,int) = [27,26,25,24,23,22,21,20,19,18,9,8,1];
/*
  foreach (i from 1 to 13) {
    //if register i is in xreg_list
    if (reg_list[i]) then {
      match bytes {
        4 => exectue (C_LW(0b000 @ spimm,x[reg_list[i]],addr)), //asm("lw x[reg_list[i]], 0(addr)"),
        8 => execute (C_LD(0b000 @ spimm,x[reg_list[i]],addr)) //asm("ld x[reg_list[i]], 0(addr)")
      };
      addr = addr - bytes;
    }
  };
  */

//  execute(C_LI(0b000000,a0)); //asm("li a0, 0");
  X(sp) = X(sp) + stack_adj;
//  asm("ret");

  RETIRE_SUCCESS
}

mapping clause assembly = CM_POPRETZ(rlist,spimm) <->
  "cm.popretz" ^ spc() ^ hex_bits_4(rlist) ^ sep() ^ hex_bits_2(spimm)

/* ------------------------------------------------------------------ */
/* Sail Model for the cm.popret encoding group                           */
/* ------------------------------------------------------------------ */
/* the assembly abstract syntax tree (AST) clause for the CM.POPRET instructions */

union clause ast = CM_POPRET : (bits(4),bits(2))

/* the encode/decode mapping between AST elements and 16-bit half words */

mapping clause encdec_compressed = CM_POPRET(rlist,spimm)
  <-> 0b101 @ 0b11110 @ rlist : bits(4) @ spimm : bits(2) @ 0b10

function clause execute (CM_POPRET(rlist,spimm)) = {
  var bytes : bits(4) = zeros();
  
  if (sizeof(xlen) == 32) then {
    bytes = 0x4
  };
  
  if (sizeof(xlen) == 64) then {
    bytes = 0x8
  };

  reg_list : vector (13,dec,int) = [0,0,0,0,0,0,0,0,0,0,0,0,0];
  
  match (rlist) {
    0x4 => reg_list = [0,0,0,0,0,0,0,0,0,0,0,0,1],     
    0x5 => reg_list = [0,0,0,0,0,0,0,0,0,0,0,8,1],     
    0x6 => reg_list = [0,0,0,0,0,0,0,0,0,0,9,8,1],     
    0x7 => reg_list = [0,0,0,0,0,0,0,0,0,18,9,8,1],    
    0x8 => reg_list = [0,0,0,0,0,0,0,0,19,18,9,8,1],   
    0x9 => reg_list = [0,0,0,0,0,0,0,20,19,18,9,8,1],  
    0xa => reg_list = [0,0,0,0,0,0,21,20,19,18,9,8,1], 
    0xb => reg_list = [0,0,0,0,0,22,21,20,19,18,9,8,1],   
    0xc => reg_list = [0,0,0,0,23,22,21,20,19,18,9,8,1],  
    0xd => reg_list = [0,0,0,24,23,22,21,20,19,18,9,8,1], 
    0xe => reg_list = [0,0,25,24,23,22,21,20,19,18,9,8,1],
    //note - to include s10, s11 must also be included
    0xf => reg_list = [27,26,25,24,23,22,21,20,19,18,9,8,1],
//     _  => None()
  };


  stack_adj_base : bits(xlen) = zeros();
  stack_adj : bits(xlen) = zeros();
  
  if (sizeof(xlen) == 32) then {
    match (rlist) {
      0x4 => {stack_adj_base = EXTZ(0x10);}, //16;},
      0x5 => {stack_adj_base = EXTZ(0x10);}, //16;},
      0x6 => {stack_adj_base = EXTZ(0x10);}, //16;},
      0x7 => {stack_adj_base = EXTZ(0x10);}, //16;},
      0x8 => {stack_adj_base = EXTZ(0x20);}, //32;},
      0x9 => {stack_adj_base = EXTZ(0x20);}, //32;},
      0xa => {stack_adj_base = EXTZ(0x20);}, //32;},
      0xb => {stack_adj_base = EXTZ(0x20);}, //32;}, 
      0xc => {stack_adj_base = EXTZ(0x30);}, //48;}, 
      0xd => {stack_adj_base = EXTZ(0x30);}, //48;}, 
      0xe => {stack_adj_base = EXTZ(0x30);}, //48;}, 
      0xf => {stack_adj_base = EXTZ(0x40);}, //64;} 
    };
    /* Need to validate the value of stack_adj here */
/*    match (rlist) {                                  
        0x4 => {let stack_adj = 16;}, //|32|48| 64];},
        0x5 => {stack_adj =     16;}, //|32|48| 64];},
        0x6 => {stack_adj =     16;}, //|32|48| 64];},
        0x7 => {stack_adj =     16;}, //|32|48| 64];},
        0x8 => {stack_adj =     32;}, //|48|64| 80];},
        0x9 => {stack_adj =     32;}, //|48|64| 80];},
        0xa => {stack_adj =     32;}, //|48|64| 80];},
        0xb => {stack_adj =     32;}, //|48|64| 80];}, 
        0xc => {stack_adj =     48;}, //|64|80| 96];}, 
        0xd => {stack_adj =     48;}, //|64|80| 96];}, 
        0xe => {stack_adj =     48;}, //|64|80| 96];}, 
        0xf => {stack_adj =     64;} //|80|96|112];}
      };
    */
    } else {
    match (rlist) {
      0x4 => {stack_adj_base = EXTZ(0x10);}, //16;},
      0x5 => {stack_adj_base = EXTZ(0x10);}, //16;},
      0x6 => {stack_adj_base = EXTZ(0x20);}, //32;},
      0x7 => {stack_adj_base = EXTZ(0x20);}, //32;},
      0x8 => {stack_adj_base = EXTZ(0x30);}, //48;},
      0x9 => {stack_adj_base = EXTZ(0x30);}, //48;},
      0xa => {stack_adj_base = EXTZ(0x40);}, //64;},
      0xb => {stack_adj_base = EXTZ(0x40);}, //64;}, 
      0xc => {stack_adj_base = EXTZ(0x50);}, //80;}, 
      0xd => {stack_adj_base = EXTZ(0x50);}, //80;}, 
      0xe => {stack_adj_base = EXTZ(0x60);}, //96;}, 
      0xf => {stack_adj_base = EXTZ(0x70);}, //112;} 
    };
    /* Need to validate the value of stack_adj here */
    /*    match (rlist) {                                  
      0x4 => {stack_adj =  16;}, //[| 32| 48| 64];},
      0x5 => {stack_adj =  16;}, //[| 32| 48| 64];},
      0x6 => {stack_adj =  32;}, //[| 48| 64| 80];},
      0x7 => {stack_adj =  32;}, //[| 48| 64| 80];},
      0x8 => {stack_adj =  48;}, //[| 64| 80| 96];},
      0x9 => {stack_adj =  48;}, //[| 64| 80| 96];},
      0xa => {stack_adj =  64;}, //[| 80| 96|112];},
      0xb => {stack_adj =  64;}, //[| 80| 96|112];}, 
      0xc => {stack_adj =  80;}, //[| 96|112|128];}, 
      0xd => {stack_adj =  80;}, //[| 96|112|128];}, 
      0xe => {stack_adj =  96;}, //[|112|128|144];}, 
      0xf => {stack_adj = 112;}  //[|128|144|160];}
    };*/
  };

  let stack_adj_by : bits(xlen) = EXTZ(spimm << 4);
  stack_adj = stack_adj_base + stack_adj_by;

  let addr : bits(xlen) = X(sp) - EXTZ(bytes);

  let l : vector (13,dec,int) = [27,26,25,24,23,22,21,20,19,18,9,8,1];
/*
  foreach (i from 1 to 13) {
    //if register i is in xreg_list
    if (reg_list[i]) then {
      match bytes {
        4 => exectue (C_LW(0b000 @ spimm,x[reg_list[i]],addr)), //asm("lw x[reg_list[i]], 0(addr)"),
        8 => execute (C_LD(0b000 @ spimm,x[reg_list[i]],addr)) //asm("ld x[reg_list[i]], 0(addr)")
      };
      addr = addr - bytes;
    }
  };
*/

  X(sp) = X(sp) + stack_adj;
  //asm("ret");

  RETIRE_SUCCESS
}

mapping clause assembly = CM_POPRET(rlist,spimm) <->
  "cm.popret" ^ spc() ^ hex_bits_4(rlist) ^ sep() ^ hex_bits_2(spimm)

/* ------------------------------------------------------------------ */
/* Sail Model for the cm.mv encoding group                            */
/* ------------------------------------------------------------------ */
/* the assembly abstract syntax tree (AST) clause for the CM.MVSA01 instructions */

union clause ast = CM_MVSA01 : (bits(3), bits(3))

/* the encode/decode mapping between AST elements and 16-bit half words */

mapping clause encdec_compressed = CM_MVSA01(sreg1,sreg2)
  <-> 0b101 @ 0b011 @ sreg1 : bits(3) @ 0b01 @ sreg2 : bits(3) @ 0b10

function clause execute (CM_MVSA01(sreg1,sreg2)) = {
  if (sreg1 == sreg2) then {
    RETIRE_FAIL
  } else {
/*
    if (((sreg1[2..0] > 0b001) | (sreg2[2..0] > 0b001))) then {
      reserved();         
    }; 
    xreg1 = {(sreg1[2..1] > 0) & (sreg1[2..1] == 0) & (sreg1[2..0])};
    xreg2 = {(sreg2[2..1] > 0) & (sreg2[2..1] == 0) & (sreg2[2..0])};

    X[xreg1] = X[10];
    X[xreg2] = X[11];
*/    
    RETIRE_SUCCESS
  }
}

mapping clause assembly = CM_MVSA01(sreg1,sreg2) <->
  "cm.mvsa01" ^ spc() ^ hex_bits_3(sreg1) ^ spc() ^ hex_bits_3(sreg2)

/* ****************************************************************** */
/* the assembly abstract syntax tree (AST) clause for the CM.MVA01S instructions */

union clause ast = CM_MVA01S : (bits(3),bits(3))

/* the encode/decode mapping between AST elements and 16-bit half words */

mapping clause encdec_compressed = CM_MVA01S(sreg1,sreg2)
  <-> 0b101 @ 0b011 @ sreg1 : bits(3) @ 0b11 @ sreg2 : bits(3) @ 0b10

function clause execute (CM_MVA01S(sreg1,sreg2)) = {
  /*
  if (((sreg1[2..0] > 1) | (sreg2[2..0] > 1))) then {
    reserved();
  };
  xreg1 = {(sreg1[2..1] > 0) & (sreg1[2..1] == 0) & (sreg1[2..0])};
  xreg2 = {(sreg2[2..1] > 0) & (sreg2[2..1] == 0) & (sreg2[2..0])};

  X[10] = X[xreg1];
  X[11] = X[xreg2];
  */
  RETIRE_SUCCESS
}

mapping clause assembly = CM_MVA01S(sreg1,sreg2) <->
  "cm.mva01s" ^ spc() ^ hex_bits_3(sreg1) ^ spc() ^ hex_bits_3(sreg2)
