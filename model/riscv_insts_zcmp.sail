/*=======================================================================================*/
/*  This Sail RISC-V architecture model, comprising all files and                        */
/*  directories except where otherwise noted is subject the BSD                          */
/*  two-clause license in the LICENSE file.                                              */
/*                                                                                       */
/*  SPDX-License-Identifier: BSD-2-Clause                                                */
/*=======================================================================================*/


enum clause extension = Ext_Zcmp
function clause extensionEnabled(Ext_Zcmp) = extensionEnabled(Ext_Zca) & not(extensionEnabled(Ext_Zcd))

mapping RLIST_MAPPING : bits(4) <-> string = {
  0x4 <-> "{ra}",
  0x5 <-> "{ra, s0}",
  0x6 <-> "{ra, s0-s1}",
  0x7 <-> "{ra, s0-s2}",
  0x8 <-> "{ra, s0-s3}",
  0x9 <-> "{ra, s0-s4}",
  0xa <-> "{ra, s0-s5}",
  0xb <-> "{ra, s0-s6}",
  0xc <-> "{ra, s0-s7}",
  0xd <-> "{ra, s0-s8}",
  0xe <-> "{ra, s0-s9}",
  0xf <-> "{ra, s0-11}",
} 

mapping CM_PUSH_MAPPING_32 : (bits(4), bits(2)) <-> string = {
  (0x4, 0b00) <-> "{ra}, -16",
  (0x4, 0b01) <-> "{ra}, -32",
  (0x4, 0b10) <-> "{ra}, -48",
  (0x4, 0b11) <-> "{ra}, -64",
  (0x5, 0b00) <-> "{ra, s0}, -16",
  (0x5, 0b01) <-> "{ra, s0}, -32",
  (0x5, 0b10) <-> "{ra, s0}, -48",
  (0x5, 0b11) <-> "{ra, s0}, -64",
  (0x6, 0b00) <-> "{ra, s0-s1}, -16",
  (0x6, 0b01) <-> "{ra, s0-s1}, -32",
  (0x6, 0b10) <-> "{ra, s0-s1}, -48",
  (0x6, 0b11) <-> "{ra, s0-s1}, -64",
  (0x7, 0b00) <-> "{ra, s0-s2}, -16",
  (0x7, 0b01) <-> "{ra, s0-s2}, -32",
  (0x7, 0b10) <-> "{ra, s0-s2}, -48",
  (0x7, 0b11) <-> "{ra, s0-s2}, -64",
  (0x8, 0b00) <-> "{ra, s0-s3}, -32",
  (0x8, 0b01) <-> "{ra, s0-s3}, -48",
  (0x8, 0b10) <-> "{ra, s0-s3}, -64",
  (0x8, 0b11) <-> "{ra, s0-s3}, -80",
  (0x9, 0b00) <-> "{ra, s0-s4}, -32",
  (0x9, 0b01) <-> "{ra, s0-s4}, -48",
  (0x9, 0b10) <-> "{ra, s0-s4}, -64",
  (0x9, 0b11) <-> "{ra, s0-s4}, -80",
  (0xa, 0b00) <-> "{ra, s0-s5}, -32",
  (0xa, 0b01) <-> "{ra, s0-s5}, -48",
  (0xa, 0b10) <-> "{ra, s0-s5}, -64",
  (0xa, 0b11) <-> "{ra, s0-s5}, -80",
  (0xb, 0b00) <-> "{ra, s0-s6}, -32",
  (0xb, 0b01) <-> "{ra, s0-s6}, -48",
  (0xb, 0b10) <-> "{ra, s0-s6}, -64",
  (0xb, 0b11) <-> "{ra, s0-s6}, -80",
  (0xc, 0b00) <-> "{ra, s0-s7}, -48",
  (0xc, 0b01) <-> "{ra, s0-s7}, -64",
  (0xc, 0b10) <-> "{ra, s0-s7}, -80",
  (0xc, 0b11) <-> "{ra, s0-s7}, -96",
  (0xd, 0b00) <-> "{ra, s0-s8}, -48",
  (0xd, 0b01) <-> "{ra, s0-s8}, -64",
  (0xd, 0b10) <-> "{ra, s0-s8}, -80",
  (0xd, 0b11) <-> "{ra, s0-s8}, -96",
  (0xe, 0b00) <-> "{ra, s0-s9}, -48",
  (0xe, 0b01) <-> "{ra, s0-s9}, -64",
  (0xe, 0b10) <-> "{ra, s0-s9}, -80",
  (0xe, 0b11) <-> "{ra, s0-s9}, -96",
  (0xf, 0b00) <-> "{ra, s0-11}, -64",
  (0xf, 0b01) <-> "{ra, s0-11}, -80",
  (0xf, 0b10) <-> "{ra, s0-11}, -96",
  (0xf, 0b11) <-> "{ra, s0-11}, -112",
}

mapping CM_PUSH_MAPPING_64 : (bits(4), bits(2)) <-> string = {
  (0x4, 0b00) <-> "{ra}, -16",
  (0x4, 0b01) <-> "{ra}, -32",
  (0x4, 0b10) <-> "{ra}, -48",
  (0x4, 0b11) <-> "{ra}, -64",
  (0x5, 0b00) <-> "{ra, s0}, -16",
  (0x5, 0b01) <-> "{ra, s0}, -32",
  (0x5, 0b10) <-> "{ra, s0}, -48",
  (0x5, 0b11) <-> "{ra, s0}, -64",
  (0x6, 0b00) <-> "{ra, s0-s1}, -32",
  (0x6, 0b01) <-> "{ra, s0-s1}, -48",
  (0x6, 0b10) <-> "{ra, s0-s1}, -64",
  (0x6, 0b11) <-> "{ra, s0-s1}, -80",
  (0x7, 0b00) <-> "{ra, s0-s2}, -32",
  (0x7, 0b01) <-> "{ra, s0-s2}, -48",
  (0x7, 0b10) <-> "{ra, s0-s2}, -64",
  (0x7, 0b11) <-> "{ra, s0-s2}, -80",
  (0x8, 0b00) <-> "{ra, s0-s3}, -48",
  (0x8, 0b01) <-> "{ra, s0-s3}, -64",
  (0x8, 0b10) <-> "{ra, s0-s3}, -80",
  (0x8, 0b11) <-> "{ra, s0-s3}, -96",
  (0x9, 0b00) <-> "{ra, s0-s4}, -48",
  (0x9, 0b01) <-> "{ra, s0-s4}, -64",
  (0x9, 0b10) <-> "{ra, s0-s4}, -80",
  (0x9, 0b11) <-> "{ra, s0-s4}, -96",
  (0xa, 0b00) <-> "{ra, s0-s5}, -64",
  (0xa, 0b01) <-> "{ra, s0-s5}, -80",
  (0xa, 0b10) <-> "{ra, s0-s5}, -96",
  (0xa, 0b11) <-> "{ra, s0-s5}, -112",
  (0xb, 0b00) <-> "{ra, s0-s6}, -64",
  (0xb, 0b01) <-> "{ra, s0-s6}, -80",
  (0xb, 0b10) <-> "{ra, s0-s6}, -96",
  (0xb, 0b11) <-> "{ra, s0-s6}, -112",
  (0xc, 0b00) <-> "{ra, s0-s7}, -80",
  (0xc, 0b01) <-> "{ra, s0-s7}, -96",
  (0xc, 0b10) <-> "{ra, s0-s7}, -112",
  (0xc, 0b11) <-> "{ra, s0-s7}, -128",
  (0xd, 0b00) <-> "{ra, s0-s8}, -80",
  (0xd, 0b01) <-> "{ra, s0-s8}, -96",
  (0xd, 0b10) <-> "{ra, s0-s8}, -112",
  (0xd, 0b11) <-> "{ra, s0-s8}, -120",
  (0xe, 0b00) <-> "{ra, s0-s9}, -96",
  (0xe, 0b01) <-> "{ra, s0-s9}, -112",
  (0xe, 0b10) <-> "{ra, s0-s9}, -128",
  (0xe, 0b11) <-> "{ra, s0-s9}, -144",
  (0xf, 0b00) <-> "{ra, s0-s11}, -112",
  (0xf, 0b01) <-> "{ra, s0-s11}, -128",
  (0xf, 0b10) <-> "{ra, s0-s11}, -144",
  (0xf, 0b11) <-> "{ra, s0-s11}, -160",
}

mapping CM_POP_MAPPING_32 : (bits(4), bits(2)) <-> string = {
  (0x4, 0b00) <-> "{ra}, 16",
  (0x4, 0b01) <-> "{ra}, 32",
  (0x4, 0b10) <-> "{ra}, 48",
  (0x4, 0b11) <-> "{ra}, 64",
  (0x5, 0b00) <-> "{ra, s0}, 16",
  (0x5, 0b01) <-> "{ra, s0}, 32",
  (0x5, 0b10) <-> "{ra, s0}, 48",
  (0x5, 0b11) <-> "{ra, s0}, 64",
  (0x6, 0b00) <-> "{ra, s0-s1}, 16",
  (0x6, 0b01) <-> "{ra, s0-s1}, 32",
  (0x6, 0b10) <-> "{ra, s0-s1}, 48",
  (0x6, 0b11) <-> "{ra, s0-s1}, 64",
  (0x7, 0b00) <-> "{ra, s0-s2}, 16",
  (0x7, 0b01) <-> "{ra, s0-s2}, 32",
  (0x7, 0b10) <-> "{ra, s0-s2}, 48",
  (0x7, 0b11) <-> "{ra, s0-s2}, 64",
  (0x8, 0b00) <-> "{ra, s0-s3}, 32",
  (0x8, 0b01) <-> "{ra, s0-s3}, 48",
  (0x8, 0b10) <-> "{ra, s0-s3}, 64",
  (0x8, 0b11) <-> "{ra, s0-s3}, 80",
  (0x9, 0b00) <-> "{ra, s0-s4}, 32",
  (0x9, 0b01) <-> "{ra, s0-s4}, 48",
  (0x9, 0b10) <-> "{ra, s0-s4}, 64",
  (0x9, 0b11) <-> "{ra, s0-s4}, 80",
  (0xa, 0b00) <-> "{ra, s0-s5}, 32",
  (0xa, 0b01) <-> "{ra, s0-s5}, 48",
  (0xa, 0b10) <-> "{ra, s0-s5}, 64",
  (0xa, 0b11) <-> "{ra, s0-s5}, 80",
  (0xb, 0b00) <-> "{ra, s0-s6}, 32",
  (0xb, 0b01) <-> "{ra, s0-s6}, 48",
  (0xb, 0b10) <-> "{ra, s0-s6}, 64",
  (0xb, 0b11) <-> "{ra, s0-s6}, 80",
  (0xc, 0b00) <-> "{ra, s0-s7}, 48",
  (0xc, 0b01) <-> "{ra, s0-s7}, 64",
  (0xc, 0b10) <-> "{ra, s0-s7}, 80",
  (0xc, 0b11) <-> "{ra, s0-s7}, 96",
  (0xd, 0b00) <-> "{ra, s0-s8}, 48",
  (0xd, 0b01) <-> "{ra, s0-s8}, 64",
  (0xd, 0b10) <-> "{ra, s0-s8}, 80",
  (0xd, 0b11) <-> "{ra, s0-s8}, 96",
  (0xe, 0b00) <-> "{ra, s0-s9}, 48",
  (0xe, 0b01) <-> "{ra, s0-s9}, 64",
  (0xe, 0b10) <-> "{ra, s0-s9}, 80",
  (0xe, 0b11) <-> "{ra, s0-s9}, 96",
  (0xf, 0b00) <-> "{ra, s0-11}, 64",
  (0xf, 0b01) <-> "{ra, s0-11}, 80",
  (0xf, 0b10) <-> "{ra, s0-11}, 96",
  (0xf, 0b11) <-> "{ra, s0-11}, 112",
}

mapping CM_POP_MAPPING_64 : (bits(4), bits(2)) <-> string = {
  (0x4, 0b00) <-> "{ra}, 16",
  (0x4, 0b01) <-> "{ra}, 32",
  (0x4, 0b10) <-> "{ra}, 48",
  (0x4, 0b11) <-> "{ra}, 64",
  (0x5, 0b00) <-> "{ra, s0}, 16",
  (0x5, 0b01) <-> "{ra, s0}, 32",
  (0x5, 0b10) <-> "{ra, s0}, 48",
  (0x5, 0b11) <-> "{ra, s0}, 64",
  (0x6, 0b00) <-> "{ra, s0-s1}, 32",
  (0x6, 0b01) <-> "{ra, s0-s1}, 48",
  (0x6, 0b10) <-> "{ra, s0-s1}, 64",
  (0x6, 0b11) <-> "{ra, s0-s1}, 80",
  (0x7, 0b00) <-> "{ra, s0-s2}, 32",
  (0x7, 0b01) <-> "{ra, s0-s2}, 48",
  (0x7, 0b10) <-> "{ra, s0-s2}, 64",
  (0x7, 0b11) <-> "{ra, s0-s2}, 80",
  (0x8, 0b00) <-> "{ra, s0-s3}, 48",
  (0x8, 0b01) <-> "{ra, s0-s3}, 64",
  (0x8, 0b10) <-> "{ra, s0-s3}, 80",
  (0x8, 0b11) <-> "{ra, s0-s3}, 96",
  (0x9, 0b00) <-> "{ra, s0-s4}, 48",
  (0x9, 0b01) <-> "{ra, s0-s4}, 64",
  (0x9, 0b10) <-> "{ra, s0-s4}, 80",
  (0x9, 0b11) <-> "{ra, s0-s4}, 96",
  (0xa, 0b00) <-> "{ra, s0-s5}, 64",
  (0xa, 0b01) <-> "{ra, s0-s5}, 80",
  (0xa, 0b10) <-> "{ra, s0-s5}, 96",
  (0xa, 0b11) <-> "{ra, s0-s5}, 112",
  (0xb, 0b00) <-> "{ra, s0-s6}, 64",
  (0xb, 0b01) <-> "{ra, s0-s6}, 80",
  (0xb, 0b10) <-> "{ra, s0-s6}, 96",
  (0xb, 0b11) <-> "{ra, s0-s6}, 112",
  (0xc, 0b00) <-> "{ra, s0-s7}, 80",
  (0xc, 0b01) <-> "{ra, s0-s7}, 96",
  (0xc, 0b10) <-> "{ra, s0-s7}, 112",
  (0xc, 0b11) <-> "{ra, s0-s7}, 128",
  (0xd, 0b00) <-> "{ra, s0-s8}, 80",
  (0xd, 0b01) <-> "{ra, s0-s8}, 96",
  (0xd, 0b10) <-> "{ra, s0-s8}, 112",
  (0xd, 0b11) <-> "{ra, s0-s8}, 120",
  (0xe, 0b00) <-> "{ra, s0-s9}, 96",
  (0xe, 0b01) <-> "{ra, s0-s9}, 112",
  (0xe, 0b10) <-> "{ra, s0-s9}, 128",
  (0xe, 0b11) <-> "{ra, s0-s9}, 144",
  (0xf, 0b00) <-> "{ra, s0-s11}, 112",
  (0xf, 0b01) <-> "{ra, s0-s11}, 128",
  (0xf, 0b10) <-> "{ra, s0-s11}, 144",
  (0xf, 0b11) <-> "{ra, s0-s11}, 160",
}

union clause ast = CM_PUSH : (bits(4), bits(2))

mapping clause encdec_compressed = CM_PUSH(rlist, sp54)                if extensionEnabled(Ext_Zcmp)
  <-> 0b101 @ 0b11000 @ rlist : bits(4) @ sp54 : bits(2) @ 0b10        if extensionEnabled(Ext_Zcmp)

function clause execute (CM_PUSH(rlist, sp54)) = {
  var bytes : bits(4) = zeros();

  if (sizeof(xlen) == 32) then {
    bytes = 0x4
  };

  if (sizeof(xlen) == 64) then {
    bytes = 0x8
  };

  reg_list : vector (13,dec, bits(5)) = [0b00000,0b00000,0b00000,0b00000,0b00000,0b00000,0b00000,0b00000,0b00000,0b00000,0b00000,0b00000,0b00000];

  match rlist {
    0x4  => reg_list = [0b00000, 0b00000, 0b00000, 0b00000, 0b00000, 0b00000, 0b00000, 0b00000, 0b00000, 0b00000, 0b00000, 0b00000, 0b00001],
    0x5  => reg_list = [0b00000, 0b00000, 0b00000, 0b00000, 0b00000, 0b00000, 0b00000, 0b00000, 0b00000, 0b00000, 0b00000, 0b01000, 0b00001],
    0x6  => reg_list = [0b00000, 0b00000, 0b00000, 0b00000, 0b00000, 0b00000, 0b00000, 0b00000, 0b00000, 0b00000, 0b01001, 0b01000, 0b00001],
    0x7  => reg_list = [0b00000, 0b00000, 0b00000, 0b00000, 0b00000, 0b00000, 0b00000, 0b00000, 0b00000, 0b10010, 0b01001, 0b01000, 0b00001],
    0x8  => reg_list = [0b00000, 0b00000, 0b00000, 0b00000, 0b00000, 0b00000, 0b00000, 0b00000, 0b10011, 0b10010, 0b01001, 0b01000, 0b00001],
    0x9  => reg_list = [0b00000, 0b00000, 0b00000, 0b00000, 0b00000, 0b00000, 0b00000, 0b10100, 0b10011, 0b10010, 0b01001, 0b01000, 0b00001],
    0xa  => reg_list = [0b00000, 0b00000, 0b00000, 0b00000, 0b00000, 0b00000, 0b10101, 0b10100, 0b10011, 0b10010, 0b01001, 0b01000, 0b00001],
    0xb  => reg_list = [0b00000, 0b00000, 0b00000, 0b00000, 0b00000, 0b10110, 0b10101, 0b10100, 0b10011, 0b10010, 0b01001, 0b01000, 0b00001],
    0xc  => reg_list = [0b00000, 0b00000, 0b00000, 0b00000, 0b10111, 0b10110, 0b10101, 0b10100, 0b10011, 0b10010, 0b01001, 0b01000, 0b00001],
    0xd  => reg_list = [0b00000, 0b00000, 0b00000, 0b11000, 0b10111, 0b10110, 0b10101, 0b10100, 0b10011, 0b10010, 0b01001, 0b01000, 0b00001],
    0xe  => reg_list = [0b00000, 0b00000, 0b11001, 0b11000, 0b10111, 0b10110, 0b10101, 0b10100, 0b10011, 0b10010, 0b01001, 0b01000, 0b00001],
    0xf  => reg_list = [0b11011, 0b11010, 0b11001, 0b11000, 0b10111, 0b10110, 0b10101, 0b10100, 0b10011, 0b10010, 0b01001, 0b01000, 0b00001],
  };


  var stack_adj_base : bits(xlen) = zeros();
  var stack_adj : bits(xlen) = zeros();

  if (sizeof(xlen) == 32) then {
    match rlist {
      0x4 => {stack_adj_base = zero_extend(0x10);},
      0x5 => {stack_adj_base = zero_extend(0x10);}, 
      0x6 => {stack_adj_base = zero_extend(0x10);},
      0x7 => {stack_adj_base = zero_extend(0x10);},
      0x8 => {stack_adj_base = zero_extend(0x20);},
      0x9 => {stack_adj_base = zero_extend(0x20);},
      0xa => {stack_adj_base = zero_extend(0x20);},
      0xb => {stack_adj_base = zero_extend(0x20);}, 
      0xc => {stack_adj_base = zero_extend(0x30);}, 
      0xd => {stack_adj_base = zero_extend(0x30);}, 
      0xe => {stack_adj_base = zero_extend(0x30);}, 
      0xf => {stack_adj_base = zero_extend(0x40);},
    };
    } else {
    match rlist {
      0x4 => {stack_adj_base = zero_extend(0x10);},
      0x5 => {stack_adj_base = zero_extend(0x10);},
      0x6 => {stack_adj_base = zero_extend(0x20);},
      0x7 => {stack_adj_base = zero_extend(0x20);},
      0x8 => {stack_adj_base = zero_extend(0x30);},
      0x9 => {stack_adj_base = zero_extend(0x30);},
      0xa => {stack_adj_base = zero_extend(0x40);},
      0xb => {stack_adj_base = zero_extend(0x40);}, 
      0xc => {stack_adj_base = zero_extend(0x50);}, 
      0xd => {stack_adj_base = zero_extend(0x50);}, 
      0xe => {stack_adj_base = zero_extend(0x60);}, 
      0xf => {stack_adj_base = zero_extend(0x70);},
    };
  };

  var stack_adj_by : bits(xlen) = zero_extend(sp54 << 4);
  stack_adj = stack_adj_base + stack_adj_by;
  
  var addr : bits(xlen) = X(sp) - zero_extend(bytes);

  foreach (i from 0 to 12) {
    //if register i is in xreg_list
    if (reg_list[i] != 0b00000) then {
      if (bytes == 0x4) then {
        let rs1 = reg_list[i];
        let imm : bits(xlen) = stack_adj - zero_extend(bytes);
        let _ = execute(STORE(imm[11..0], rs1, sp, WORD, false, false))
      } else {
        let rs1 = reg_list[i];
        let imm : bits(xlen) = stack_adj - zero_extend(bytes);
        let _ = execute(STORE(imm[11..0], rs1, sp, DOUBLE, false, false))
      };
      addr = addr - zero_extend(bytes);
    }
  };

  X(sp) = X(sp) - stack_adj;

  RETIRE_SUCCESS
}

mapping clause assembly = CM_PUSH(rlist, sp54) if (sizeof(xlen) == 32) <->
  "cm.push" ^ spc() ^ CM_PUSH_MAPPING_32(rlist, sp54) if (sizeof(xlen) == 32)

mapping clause assembly = CM_PUSH(rlist, sp54) if (sizeof(xlen) == 64) <->
  "cm.push" ^ spc() ^ CM_PUSH_MAPPING_64(rlist, sp54) if (sizeof(xlen) == 64)

// cm.pop
union clause ast = CM_POP : (bits(4), bits(2))

mapping clause encdec_compressed = CM_POP(rlist, sp54) if extensionEnabled(Ext_Zcmp)
 <-> 0b101 @ 0b11010 @ rlist : bits(4) @ sp54 : bits(2) @ 0b10 if extensionEnabled(Ext_Zcmp)

function clause execute (CM_POP(rlist, sp54)) = {

  var bytes : bits(4) = zeros();

  if (sizeof(xlen) == 32) then {
    bytes = 0x4
  };

  if (sizeof(xlen) == 64) then {
    bytes = 0x8
  };

  reg_list : vector (13, dec, bits(5)) = [0b00000, 0b00000, 0b00000, 0b00000, 0b00000, 0b00000, 0b00000, 0b00000, 0b00000, 0b00000, 0b00000, 0b00000, 0b00000];

  match rlist {
    0x4  => reg_list = [0b00000, 0b00000, 0b00000, 0b00000, 0b00000, 0b00000, 0b00000, 0b00000, 0b00000, 0b00000, 0b00000, 0b00000, 0b00001],
    0x5  => reg_list = [0b00000, 0b00000, 0b00000, 0b00000, 0b00000, 0b00000, 0b00000, 0b00000, 0b00000, 0b00000, 0b00000, 0b01000, 0b00001],
    0x6  => reg_list = [0b00000, 0b00000, 0b00000, 0b00000, 0b00000, 0b00000, 0b00000, 0b00000, 0b00000, 0b00000, 0b01001, 0b01000, 0b00001],
    0x7  => reg_list = [0b00000, 0b00000, 0b00000, 0b00000, 0b00000, 0b00000, 0b00000, 0b00000, 0b00000, 0b10010, 0b01001, 0b01000, 0b00001],
    0x8  => reg_list = [0b00000, 0b00000, 0b00000, 0b00000, 0b00000, 0b00000, 0b00000, 0b00000, 0b10011, 0b10010, 0b01001, 0b01000, 0b00001],
    0x9  => reg_list = [0b00000, 0b00000, 0b00000, 0b00000, 0b00000, 0b00000, 0b00000, 0b10100, 0b10011, 0b10010, 0b01001, 0b01000, 0b00001],
    0xa  => reg_list = [0b00000, 0b00000, 0b00000, 0b00000, 0b00000, 0b00000, 0b10101, 0b10100, 0b10011, 0b10010, 0b01001, 0b01000, 0b00001],
    0xb  => reg_list = [0b00000, 0b00000, 0b00000, 0b00000, 0b00000, 0b10110, 0b10101, 0b10100, 0b10011, 0b10010, 0b01001, 0b01000, 0b00001],
    0xc  => reg_list = [0b00000, 0b00000, 0b00000, 0b00000, 0b10111, 0b10110, 0b10101, 0b10100, 0b10011, 0b10010, 0b01001, 0b01000, 0b00001],
    0xd  => reg_list = [0b00000, 0b00000, 0b00000, 0b11000, 0b10111, 0b10110, 0b10101, 0b10100, 0b10011, 0b10010, 0b01001, 0b01000, 0b00001],
    0xe  => reg_list = [0b00000, 0b00000, 0b11001, 0b11000, 0b10111, 0b10110, 0b10101, 0b10100, 0b10011, 0b10010, 0b01001, 0b01000, 0b00001],
    0xf  => reg_list = [0b11011, 0b11010, 0b11001, 0b11000, 0b10111, 0b10110, 0b10101, 0b10100, 0b10011, 0b10010, 0b01001, 0b01000, 0b00001],
  };


  var stack_adj_base : bits(xlen) = zeros();
  var stack_adj : bits(xlen) = zeros();

  if (sizeof(xlen) == 32) then {
    match rlist {
      0x4 => {stack_adj_base = zero_extend(0x10);},
      0x5 => {stack_adj_base = zero_extend(0x10);},
      0x6 => {stack_adj_base = zero_extend(0x10);},
      0x7 => {stack_adj_base = zero_extend(0x10);},
      0x8 => {stack_adj_base = zero_extend(0x20);},
      0x9 => {stack_adj_base = zero_extend(0x20);},
      0xa => {stack_adj_base = zero_extend(0x20);},
      0xb => {stack_adj_base = zero_extend(0x20);},
      0xc => {stack_adj_base = zero_extend(0x30);}, 
      0xd => {stack_adj_base = zero_extend(0x30);}, 
      0xe => {stack_adj_base = zero_extend(0x30);}, 
      0xf => {stack_adj_base = zero_extend(0x40);}, 
    };
    } else {
    match rlist {
      0x4 => {stack_adj_base = zero_extend(0x10);},
      0x5 => {stack_adj_base = zero_extend(0x10);},
      0x6 => {stack_adj_base = zero_extend(0x20);},
      0x7 => {stack_adj_base = zero_extend(0x20);},
      0x8 => {stack_adj_base = zero_extend(0x30);},
      0x9 => {stack_adj_base = zero_extend(0x30);},
      0xa => {stack_adj_base = zero_extend(0x40);},
      0xb => {stack_adj_base = zero_extend(0x40);}, 
      0xc => {stack_adj_base = zero_extend(0x50);}, 
      0xd => {stack_adj_base = zero_extend(0x50);}, 
      0xe => {stack_adj_base = zero_extend(0x60);}, 
      0xf => {stack_adj_base = zero_extend(0x70);}, 
    };
  };

  let stack_adj_by : bits(xlen) = zero_extend(sp54 << 4);
  stack_adj = stack_adj_base + stack_adj_by;

  var addr : bits(xlen) = X(sp) - zero_extend(bytes);

  foreach (i from 0 to 12) {
    //if register i is in xreg_list
    if (reg_list[i] != 0b00000) then {
      if (bytes == 0x4) then {
        let rs1 = reg_list[i];
        let imm : bits(xlen) = stack_adj - zero_extend(bytes);
        let _ = execute(LOAD(imm[11..0], sp, rs1, false, WORD, false, false))
      } else {
        let rs1 = reg_list[i];
        let imm : bits(xlen) = stack_adj - zero_extend(bytes);
        let _ = execute(LOAD(imm[11..0], sp, rs1, false, DOUBLE, false, false))
      };
      addr = addr - zero_extend(bytes);
    }
  };
  X(sp) = X(sp) + stack_adj;

  RETIRE_SUCCESS
}

mapping clause assembly = CM_POP(rlist, sp54) if (sizeof(xlen) == 32) <->
  "cm.pop" ^ spc() ^ CM_POP_MAPPING_32(rlist, sp54) if (sizeof(xlen) == 32)

mapping clause assembly = CM_POP(rlist, sp54) if (sizeof(xlen) == 64) <->
  "cm.pop" ^ spc() ^ CM_POP_MAPPING_64(rlist, sp54) if (sizeof(xlen) == 64)

// cm.popretz

union clause ast = CM_POPRETZ : (bits(4), bits(2))

mapping clause encdec_compressed = CM_POPRETZ(rlist, sp54)                if extensionEnabled(Ext_Zcmp)
  <-> 0b101 @ 0b11100 @ rlist : bits(4) @ sp54 : bits(2) @ 0b10        if extensionEnabled(Ext_Zcmp)

function clause execute (CM_POPRETZ(rlist, sp54)) = {

  var bytes : bits(4) = zeros();

  if (sizeof(xlen) == 32) then {
    bytes = 0x4
  };

  if (sizeof(xlen) == 64) then {
    bytes = 0x8
  };

  reg_list : vector (13, dec, bits(5)) = [0b00000, 0b00000, 0b00000, 0b00000, 0b00000, 0b00000, 0b00000, 0b00000, 0b00000, 0b00000, 0b00000, 0b00000, 0b00000];

  match rlist {
    0x4  => reg_list = [0b00000, 0b00000, 0b00000, 0b00000, 0b00000, 0b00000, 0b00000, 0b00000, 0b00000, 0b00000, 0b00000, 0b00000, 0b00001],
    0x5  => reg_list = [0b00000, 0b00000, 0b00000, 0b00000, 0b00000, 0b00000, 0b00000, 0b00000, 0b00000, 0b00000, 0b00000, 0b01000, 0b00001],
    0x6  => reg_list = [0b00000, 0b00000, 0b00000, 0b00000, 0b00000, 0b00000, 0b00000, 0b00000, 0b00000, 0b00000, 0b01001, 0b01000, 0b00001],
    0x7  => reg_list = [0b00000, 0b00000, 0b00000, 0b00000, 0b00000, 0b00000, 0b00000, 0b00000, 0b00000, 0b10010, 0b01001, 0b01000, 0b00001],
    0x8  => reg_list = [0b00000, 0b00000, 0b00000, 0b00000, 0b00000, 0b00000, 0b00000, 0b00000, 0b10011, 0b10010, 0b01001, 0b01000, 0b00001],
    0x9  => reg_list = [0b00000, 0b00000, 0b00000, 0b00000, 0b00000, 0b00000, 0b00000, 0b10100, 0b10011, 0b10010, 0b01001, 0b01000, 0b00001],
    0xa  => reg_list = [0b00000, 0b00000, 0b00000, 0b00000, 0b00000, 0b00000, 0b10101, 0b10100, 0b10011, 0b10010, 0b01001, 0b01000, 0b00001],
    0xb  => reg_list = [0b00000, 0b00000, 0b00000, 0b00000, 0b00000, 0b10110, 0b10101, 0b10100, 0b10011, 0b10010, 0b01001, 0b01000, 0b00001],
    0xc  => reg_list = [0b00000, 0b00000, 0b00000, 0b00000, 0b10111, 0b10110, 0b10101, 0b10100, 0b10011, 0b10010, 0b01001, 0b01000, 0b00001],
    0xd  => reg_list = [0b00000, 0b00000, 0b00000, 0b11000, 0b10111, 0b10110, 0b10101, 0b10100, 0b10011, 0b10010, 0b01001, 0b01000, 0b00001],
    0xe  => reg_list = [0b00000, 0b00000, 0b11001, 0b11000, 0b10111, 0b10110, 0b10101, 0b10100, 0b10011, 0b10010, 0b01001, 0b01000, 0b00001],
    0xf  => reg_list = [0b11011, 0b11010, 0b11001, 0b11000, 0b10111, 0b10110, 0b10101, 0b10100, 0b10011, 0b10010, 0b01001, 0b01000, 0b00001],
  };


  var stack_adj_base : bits(xlen) = zeros();
  var stack_adj : bits(xlen) = zeros();

  if (sizeof(xlen) == 32) then {
    match rlist {
      0x4 => {stack_adj_base = zero_extend(0x10);},
      0x5 => {stack_adj_base = zero_extend(0x10);},
      0x6 => {stack_adj_base = zero_extend(0x10);},
      0x7 => {stack_adj_base = zero_extend(0x10);},
      0x8 => {stack_adj_base = zero_extend(0x20);},
      0x9 => {stack_adj_base = zero_extend(0x20);},
      0xa => {stack_adj_base = zero_extend(0x20);},
      0xb => {stack_adj_base = zero_extend(0x20);}, 
      0xc => {stack_adj_base = zero_extend(0x30);}, 
      0xd => {stack_adj_base = zero_extend(0x30);}, 
      0xe => {stack_adj_base = zero_extend(0x30);}, 
      0xf => {stack_adj_base = zero_extend(0x40);}, 
    };
    } else {
    match rlist {
      0x4 => {stack_adj_base = zero_extend(0x10);},
      0x5 => {stack_adj_base = zero_extend(0x10);},
      0x6 => {stack_adj_base = zero_extend(0x20);}, 
      0x7 => {stack_adj_base = zero_extend(0x20);},
      0x8 => {stack_adj_base = zero_extend(0x30);},
      0x9 => {stack_adj_base = zero_extend(0x30);}, 
      0xa => {stack_adj_base = zero_extend(0x40);},
      0xb => {stack_adj_base = zero_extend(0x40);}, 
      0xc => {stack_adj_base = zero_extend(0x50);}, 
      0xd => {stack_adj_base = zero_extend(0x50);}, 
      0xe => {stack_adj_base = zero_extend(0x60);}, 
      0xf => {stack_adj_base = zero_extend(0x70);},
    };
  };

  let stack_adj_by : bits(xlen) = zero_extend(sp54 << 4);
  stack_adj = stack_adj_base + stack_adj_by;

  var addr : bits(xlen) = X(sp) + stack_adj - zero_extend(bytes);

  foreach (i from 0 to 12) {
    //if register i is in xreg_list
    if (reg_list[i] != 0b00000) then {
      if (bytes == 0x4) then {
        let rs1 = reg_list[i];
        let imm : bits(xlen) = stack_adj - zero_extend(bytes);
        let _ = execute(LOAD(imm[11..0], sp, rs1, false, WORD, false, false))
      } else {
        let rs1 = reg_list[i];
        let imm : bits(xlen) = stack_adj - zero_extend(bytes);
        let _ = execute(LOAD(imm[11..0], sp, rs1, false, DOUBLE, false, false))
      };
      addr = addr - zero_extend(bytes);
    }
  };
  let _ = execute(C_LI(0b000000, 0b01010));
  X(sp) = X(sp) + stack_adj;
  let _ = execute(RISCV_JALR(0b000000000000, ra, zreg));


  RETIRE_SUCCESS
}

mapping clause assembly = CM_POPRETZ(rlist, sp54) if (sizeof(xlen) == 32) <->
  "cm.popretz" ^ spc() ^ CM_POP_MAPPING_32(rlist, sp54) if (sizeof(xlen) == 32)

mapping clause assembly = CM_POPRETZ(rlist, sp54) if (sizeof(xlen) == 64) <->
  "cm.popretz" ^ spc() ^ CM_POP_MAPPING_64(rlist, sp54) if (sizeof(xlen) == 64)


// cm.popret
union clause ast = CM_POPRET : (bits(4), bits(2))

mapping clause encdec_compressed = CM_POPRET(rlist, sp54)                if extensionEnabled(Ext_Zcmp)
  <-> 0b101 @ 0b11110 @ rlist : bits(4) @ sp54 : bits(2) @ 0b10        if extensionEnabled(Ext_Zcmp)

function clause execute (CM_POPRET(rlist, sp54)) = {

  var bytes : bits(4) = zeros();

  if (sizeof(xlen) == 32) then {
    bytes = 0x4
  };

  if (sizeof(xlen) == 64) then {
    bytes = 0x8
  };

  reg_list : vector (13, dec, bits(5)) = [0b00000, 0b00000, 0b00000, 0b00000, 0b00000, 0b00000, 0b00000, 0b00000, 0b00000, 0b00000, 0b00000, 0b00000, 0b00000];

  match rlist {
    0x4  => reg_list = [0b00000, 0b00000, 0b00000, 0b00000, 0b00000, 0b00000, 0b00000, 0b00000, 0b00000, 0b00000, 0b00000, 0b00000, 0b00001],
    0x5  => reg_list = [0b00000, 0b00000, 0b00000, 0b00000, 0b00000, 0b00000, 0b00000, 0b00000, 0b00000, 0b00000, 0b00000, 0b01000, 0b00001],
    0x6  => reg_list = [0b00000, 0b00000, 0b00000, 0b00000, 0b00000, 0b00000, 0b00000, 0b00000, 0b00000, 0b00000, 0b01001, 0b01000, 0b00001],
    0x7  => reg_list = [0b00000, 0b00000, 0b00000, 0b00000, 0b00000, 0b00000, 0b00000, 0b00000, 0b00000, 0b10010, 0b01001, 0b01000, 0b00001],
    0x8  => reg_list = [0b00000, 0b00000, 0b00000, 0b00000, 0b00000, 0b00000, 0b00000, 0b00000, 0b10011, 0b10010, 0b01001, 0b01000, 0b00001],
    0x9  => reg_list = [0b00000, 0b00000, 0b00000, 0b00000, 0b00000, 0b00000, 0b00000, 0b10100, 0b10011, 0b10010, 0b01001, 0b01000, 0b00001],
    0xa  => reg_list = [0b00000, 0b00000, 0b00000, 0b00000, 0b00000, 0b00000, 0b10101, 0b10100, 0b10011, 0b10010, 0b01001, 0b01000, 0b00001],
    0xb  => reg_list = [0b00000, 0b00000, 0b00000, 0b00000, 0b00000, 0b10110, 0b10101, 0b10100, 0b10011, 0b10010, 0b01001, 0b01000, 0b00001],
    0xc  => reg_list = [0b00000, 0b00000, 0b00000, 0b00000, 0b10111, 0b10110, 0b10101, 0b10100, 0b10011, 0b10010, 0b01001, 0b01000, 0b00001],
    0xd  => reg_list = [0b00000, 0b00000, 0b00000, 0b11000, 0b10111, 0b10110, 0b10101, 0b10100, 0b10011, 0b10010, 0b01001, 0b01000, 0b00001],
    0xe  => reg_list = [0b00000, 0b00000, 0b11001, 0b11000, 0b10111, 0b10110, 0b10101, 0b10100, 0b10011, 0b10010, 0b01001, 0b01000, 0b00001],
    0xf  => reg_list = [0b11011, 0b11010, 0b11001, 0b11000, 0b10111, 0b10110, 0b10101, 0b10100, 0b10011, 0b10010, 0b01001, 0b01000, 0b00001],
  };


  var stack_adj_base : bits(xlen) = zeros();
  var stack_adj : bits(xlen) = zeros();

  if (sizeof(xlen) == 32) then {
    match rlist {
      0x4 => {stack_adj_base = zero_extend(0x10);},
      0x5 => {stack_adj_base = zero_extend(0x10);},
      0x6 => {stack_adj_base = zero_extend(0x10);},
      0x7 => {stack_adj_base = zero_extend(0x10);},
      0x8 => {stack_adj_base = zero_extend(0x20);},
      0x9 => {stack_adj_base = zero_extend(0x20);},
      0xa => {stack_adj_base = zero_extend(0x20);},
      0xb => {stack_adj_base = zero_extend(0x20);}, 
      0xc => {stack_adj_base = zero_extend(0x30);}, 
      0xd => {stack_adj_base = zero_extend(0x30);}, 
      0xe => {stack_adj_base = zero_extend(0x30);}, 
      0xf => {stack_adj_base = zero_extend(0x40);}, 
    };
    } else {
    match rlist {
      0x4 => {stack_adj_base = zero_extend(0x10);}, 
      0x5 => {stack_adj_base = zero_extend(0x10);},
      0x6 => {stack_adj_base = zero_extend(0x20);},
      0x7 => {stack_adj_base = zero_extend(0x20);}, 
      0x8 => {stack_adj_base = zero_extend(0x30);},
      0x9 => {stack_adj_base = zero_extend(0x30);}, 
      0xa => {stack_adj_base = zero_extend(0x40);},
      0xb => {stack_adj_base = zero_extend(0x40);}, 
      0xc => {stack_adj_base = zero_extend(0x50);}, 
      0xd => {stack_adj_base = zero_extend(0x50);},  
      0xe => {stack_adj_base = zero_extend(0x60);}, 
      0xf => {stack_adj_base = zero_extend(0x70);}, 
    };
  };

  let stack_adj_by : bits(xlen) = zero_extend(sp54 << 4);
  stack_adj = stack_adj_base + stack_adj_by;

  var addr : bits(xlen) = X(sp) + stack_adj - zero_extend(bytes);

  foreach (i from 0 to 12) {
    //if register i is in xreg_list
    if (reg_list[i] != 0b00000) then {
      if (bytes == 0x4) then {
        let rs1 = reg_list[i];
        let imm : bits(xlen) = stack_adj - zero_extend(bytes);
        let _ = execute(LOAD(imm[11..0], sp, rs1, false, WORD, false, false))
      } else {
        let rs1 = reg_list[i];
        let imm : bits(xlen) = stack_adj - zero_extend(bytes);
        let _ = execute(LOAD(imm[11..0], sp, rs1, false, DOUBLE, false, false))
      };
      addr = addr - zero_extend(bytes);
    }
  };
  X(sp) = X(sp) + stack_adj;
  let _ = execute(RISCV_JALR(0b000000000000, ra, zreg));

  RETIRE_SUCCESS
}

mapping clause assembly = CM_POPRET(rlist, sp54) if (sizeof(xlen) == 32) <->
  "cm.popret" ^ spc() ^ CM_POP_MAPPING_32(rlist, sp54) if (sizeof(xlen) == 32)

mapping clause assembly = CM_POPRET(rlist, sp54) if (sizeof(xlen) == 64) <->
  "cm.popret" ^ spc() ^ CM_POP_MAPPING_64(rlist, sp54) if (sizeof(xlen) == 64)