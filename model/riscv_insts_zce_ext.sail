/*=======================================================================================*/
/*  RISCV Sail Model                                                                     */
/*                                                                                       */
/*  Copyright (c) 2017-2022                                                              */
/*    Nambi Ju                                                                           */
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
/* Sail Model for the c.l and c.s encoding group                */
/* ------------------------------------------------------------------ */

/* ****************************************************************** */
union clause ast = C_LBU : (bits(2), cregidx, cregidx)

//$[wavedrom FUNCT3 _ _ _ _ C0]
mapping clause encdec_compressed = C_LBU(ui65, rs1, rd)
  <-> 0b100 @ 0b000 @ rs1 : cregidx @ ui65 : bits(2) @ rd : cregidx @ 0b00

function clause execute (C_LBU(uimm, rsc, rdc)) = {
  let immext : xlenbits = EXTZ(uimm);
  let imm : bits(12) = EXTZ(uimm);

  let rd = creg2reg_idx(rdc);
  let rs = creg2reg_idx(rsc);

  let rsext = X(rs) + immext;
  X(rs) = rsext;

   match execute(LOAD(imm, rs, rd, false, WORD, false, false)) {
     RETIRE_SUCCESS => {
                         X(rd) = EXTZ(X(rd)[7..0]);
                         RETIRE_SUCCESS
                       },
     RETIRE_FAIL => RETIRE_FAIL,
   }
}

mapping clause assembly = C_LBU(uimm, rsc, rdc)
  <-> "c.lbu" ^ spc() ^ creg_name(rdc) ^ sep() ^ creg_name(rsc) ^ sep() ^ hex_bits_5(uimm @ 0b000)
/* ****************************************************************** */
union clause ast = C_LHU : (bits(1), cregidx, cregidx)

//$[wavedrom FUNCT3 _ _ _ _ _ C0]
mapping clause encdec_compressed = C_LHU(ui5, rs1, rd)
  <-> 0b100 @ 0b001 @ rs1 : cregidx @ 0b0 @ ui5 : bits(1) @ rd : cregidx @ 0b00

function clause execute (C_LHU(uimm, rsc, rdc)) = {
  let immext : xlenbits = EXTZ(uimm);
  let imm : bits(12) = EXTZ(uimm);
  
  let rd = creg2reg_idx(rdc);
  let rs = creg2reg_idx(rsc);

  let rsext = X(rs) + immext;
  X(rs) = rsext;
  
   match execute(LOAD(imm, rs, rd, false, WORD, false, false)) {
     RETIRE_SUCCESS => {
                         X(rd) = EXTZ(X(rd)[15..0]);
                         RETIRE_SUCCESS
                       },
     RETIRE_FAIL => RETIRE_FAIL,
   }
}

mapping clause assembly = C_LHU(uimm, rsc, rdc)
  <-> "c.lhu" ^ spc() ^ creg_name(rdc) ^ sep() ^ creg_name(rsc) ^ sep() ^ hex_bits_4(uimm @ 0b000)
/* ****************************************************************** */
union clause ast = C_LH : (bits(1), cregidx, cregidx)

//$[wavedrom FUNCT3 _ _ _ _ _ C0]
mapping clause encdec_compressed = C_LH(ui5, rs1, rd)
  <-> 0b100 @ 0b001 @ rs1 : cregidx @ 0b1 @ ui5 : bits(1) @ rd : cregidx @ 0b00

function clause execute (C_LH(uimm, rsc, rdc)) = {
  let immext : xlenbits = EXTZ(uimm);
  let imm : bits(12) = EXTZ(uimm);
  
  let rd = creg2reg_idx(rdc);
  let rs = creg2reg_idx(rsc);

  let rsext = X(rs) + immext;
  X(rs) = rsext;
  
   match execute(LOAD(imm, rs, rd, false, WORD, false, false)) {
     RETIRE_SUCCESS => {
                         X(rd) = EXTS(X(rd)[15..0]);
                         RETIRE_SUCCESS
                       },
     RETIRE_FAIL => RETIRE_FAIL,
   }
}

mapping clause assembly = C_LH(uimm, rsc, rdc)
  <-> "c.lh" ^ spc() ^ creg_name(rdc) ^ sep() ^ creg_name(rsc) ^ sep() ^ hex_bits_4(uimm @ 0b000)
/* ****************************************************************** */

union clause ast = C_SB : (bits(2), cregidx, cregidx)

//$[wavedrom FUNCT3 _ _ _ _ C0]
mapping clause encdec_compressed = C_SB(ui65, rs1, rs2)
  <-> 0b100 @ 0b010 @ rs1 : cregidx @ ui65 : bits(2) @ rs2 : cregidx @ 0b00

function clause execute (C_SB(uimm, rs1c, rs2c)) = {
  let immext : xlenbits = EXTZ(uimm);
  let imm : bits(12) = EXTZ(uimm);

  let rs1c = creg2reg_idx(rs1c);
  let rs2c = creg2reg_idx(rs2c);

  let rsext = X(rs1c) + immext;
  
  let rs2c_lbyte = X(rs2c)[7..0];

  X(rs1c) = rsext;
  //X(rs2c) = EXTZ(rs2c_lbyte);
  
  X(rs2c) = EXTZ(X(rs2c)[7..0]);
  //mem(rsext[7..0]) = X(rs2c);
  
  match execute(STORE(imm, rs2c, rs1c, WORD, false, false)){
     RETIRE_SUCCESS => RETIRE_SUCCESS,
     RETIRE_FAIL => RETIRE_FAIL,
   }
}

mapping clause assembly = C_SB(uimm, rs1, rs2)
  <-> "c.sb" ^ spc() ^ creg_name(rs2) ^ sep() ^ creg_name(rs1) ^ sep() ^ hex_bits_5(uimm @ 0b000)
/* ****************************************************************** */
union clause ast = C_SH : (bits(1), cregidx, cregidx)

//$[wavedrom FUNCT3 _ _ _ _ C0]
mapping clause encdec_compressed = C_SH(ui5, rs1, rs2)
  <-> 0b100 @ 0b011 @ rs1 : cregidx @ 0b0 @ ui5 : bits(1) @ rs2 : cregidx @ 0b00

function clause execute (C_SH(uimm, rs1c, rs2c)) = {
  let immext : xlenbits = EXTZ(uimm);
  let imm : bits(12) = EXTZ(uimm);

  let rs2c = creg2reg_idx(rs2c);
  let rs1c = creg2reg_idx(rs1c);

  let rsext = X(rs1c) + immext;
  //let rs2c_lbyte = X(rs2c)[15..0];

  X(rs2c) = EXTZ(X(rs2c)[15..0]);

  // MemValue(rsext[15..0]) = X(rs2c);
  match execute(STORE(imm, rs2c, rs1c, WORD, false, false)){
     RETIRE_SUCCESS => RETIRE_SUCCESS,
     RETIRE_FAIL => RETIRE_FAIL,
   }
}

mapping clause assembly = C_SH(uimm, rs1, rs2)
  <-> "c.sh" ^ spc() ^ creg_name(rs2) ^ sep() ^ creg_name(rs1) ^ sep() ^ hex_bits_4(uimm @ 0b000)
/* ****************************************************************** */

/* ------------------------------------------------------------------ */
/* Sail Model for the c.zext and c.sext encoding group                */
/* ------------------------------------------------------------------ */
/* ****************************************************************** */
union clause ast = C_ZEXT_B : (cregidx)

//$[wavedrom FUNCT3 _ SRCDST FUNCT2 C.ZEXT.B C1]
mapping clause encdec_compressed = C_ZEXT_B(rsd)
  <-> 0b100 @ 0b111 @ rsd : cregidx @ 0b11 @ 0b000 @ 0b01

function clause execute (C_ZEXT_B(rsd)) = {
  let rsdc = creg2reg_idx(rsd);
  
  X(rsdc) = EXTZ(X(rsdc)[7..0]);
  RETIRE_SUCCESS
}

mapping clause assembly = C_ZEXT_B(rsd)
  <-> "c.zext.b" ^ spc() ^ creg_name(rsd)

/* ****************************************************************** */
union clause ast = C_SEXT_B : (cregidx)

//$[wavedrom FUNCT3 _ SRCDST FUNCT2 C.SEXT.B C1]
mapping clause encdec_compressed = C_SEXT_B(rsd)
  <-> 0b100 @ 0b111 @ rsd : cregidx @ 0b11 @ 0b001 @ 0b01

function clause execute (C_SEXT_B(rsd)) = {
  let rsdc = creg2reg_idx(rsd);
  
  X(rsdc) = EXTS(X(rsdc)[7..0]);
  RETIRE_SUCCESS
}

mapping clause assembly = C_SEXT_B(rsd)
  <-> "c.sext.b" ^ spc() ^ creg_name(rsd)
/* ****************************************************************** */
union clause ast = C_ZEXT_H : (cregidx)

//$[wavedrom FUNCT3 _ SRCDST FUNCT2 C.ZEXT.H C1]
mapping clause encdec_compressed = C_ZEXT_H(rsd)
  <-> 0b100 @ 0b111 @ rsd : cregidx @ 0b11 @ 0b010 @ 0b01

function clause execute (C_ZEXT_H(rsd)) = {
  let rsdc = creg2reg_idx(rsd);
  
  X(rsdc) = EXTZ(X(rsdc)[15..0]);
  RETIRE_SUCCESS
}

mapping clause assembly = C_ZEXT_H(rsd)
  <-> "c.zext.h" ^ spc() ^ creg_name(rsd)

/* ****************************************************************** */
union clause ast = C_SEXT_H : (cregidx)

//$[wavedrom FUNCT3 _ SRCDST FUNCT2 C.SEXT.H C1]
mapping clause encdec_compressed = C_SEXT_H(rsd)
  <-> 0b100 @ 0b111 @ rsd : cregidx @ 0b11 @ 0b011 @ 0b01

function clause execute (C_SEXT_H(rsd)) = {
  let rsdc = creg2reg_idx(rsd);
  
  X(rsdc) = EXTS(X(rsdc)[15..0]);
  RETIRE_SUCCESS
}

mapping clause assembly = C_SEXT_H(rsd)
  <-> "c.sext.h" ^ spc() ^ creg_name(rsd)
/* ****************************************************************** */
union clause ast = C_ZEXT_W : (cregidx)

//$[wavedrom FUNCT3 _ SRCDST FUNCT2 C.ZEXT.W C1]
mapping clause encdec_compressed = C_ZEXT_W(rsd)
  <-> 0b100 @ 0b111 @ rsd : cregidx @ 0b11 @ 0b100 @ 0b01

function clause execute (C_ZEXT_W(rsd)) = {
  let rsdc = creg2reg_idx(rsd);
  
  X(rsdc) = EXTZ(X(rsdc)[31..0]);
  RETIRE_SUCCESS
}

mapping clause assembly = C_ZEXT_W(rsd)
  <-> "c.zext.w" ^ spc() ^ creg_name(rsd)

/* ****************************************************************** */

/* ------------------------------------------------------------------ */
/* Sail Model for the c.mul encoding group                            */
/* ------------------------------------------------------------------ */

/* the assembly abstract syntax tree (AST) clause for the CMUL instructions */
union clause ast = C_MUL : (cregidx,cregidx)

/* the encode/decode mapping between AST elements and 16-bit half words */

//$[wavedrom FUNCT3 _ SRCDST FUNCT2 C.MUL C1]
mapping clause encdec_compressed = C_MUL(rsd, rs2)
  <-> 0b100 @ 0b111 @ rsd : cregidx @ 0b00 @ rs2 : cregidx @ 0b01

function clause execute (C_MUL(rsd,rs2)) = {
  let rd = creg2reg_idx(rsd);
  let rs = creg2reg_idx(rs2);
  
  let result_wide = to_bits(2 * sizeof(xlen), signed(X(rd)) * signed(X(rs)));
  X(rd) = result_wide[(sizeof(xlen) - 1) .. 0];
  RETIRE_SUCCESS
}

mapping clause assembly = C_MUL(rsd, rs2) <->
  "c.mul" ^ spc() ^ creg_name(rsd) ^ spc() ^ creg_name(rs2)

/* ------------------------------------------------------------------ */
/* Sail Model for the c.not encoding group                            */
/* ------------------------------------------------------------------ */

/* the assembly abstract syntax tree (AST) clause for the CNOT instructions */

union clause ast = C_NOT : (cregidx)

/* the encode/decode mapping between AST elements and 16-bit half words */

//$[wavedrom FUNCT3 _ SRCDST FUNCT2 C.NOT C1]
mapping clause encdec_compressed = C_NOT(rsd)
  <-> 0b100 @ 0b111 @ rsd : cregidx @ 0b11 @ 0b101 @ 0b01

function clause execute (C_NOT(rsd)) = {
  let rsd = creg2reg_idx(rsd);
  X(rsd) = ~(X(rsd));
  RETIRE_SUCCESS
}

mapping clause assembly = C_NOT(rsd) <->
  "c.not" ^ spc() ^ creg_name(rsd)

/* ------------------------------------------------------------------ */
/* Sail Model for the cm.push encoding group                          */
/* ------------------------------------------------------------------ */
/* the assembly abstract syntax tree (AST) clause for the CM.PUSH instructions */

union clause ast = CM_PUSH : (bits(4), bits(2))

/* the encode/decode mapping between AST elements and 16-bit half words */

//$[wavedrom FUNCT3 _ _ _ C2]
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

//$[wavedrom FUNCT3 _ _ _ C2]
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

//$[wavedrom FUNCT3 _ _ _ C2]
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

//$[wavedrom FUNCT3 _ _ _ C2]
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

//$[wavedrom FUNCT3 _ _ _ _ C2]
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

//$[wavedrom FUNCT3 _ _ _ _ C2]
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

/* ------------------------------------------------------------------ */
/* Sail Model for the cm.jt and cm.jalt encoding group                */
/* ------------------------------------------------------------------ */
/* the assembly abstract syntax tree (AST) clause for the CM.JT instructions */

union clause ast = CM_JT : bits(8)

/* the encode/decode mapping between AST elements and 16-bit half words */

//$[wavedrom FUNCT3 _ _ C2]
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

//$[wavedrom FUNCT3 _ _ C2]
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
