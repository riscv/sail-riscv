/*=======================================================================================*/
/*  This Sail RISC-V architecture model, comprising all files and                        */
/*  directories except where otherwise noted is subject the BSD                          */
/*  two-clause license in the LICENSE file.                                              */
/*                                                                                       */
/*  SPDX-License-Identifier: BSD-2-Clause                                                */
/*=======================================================================================*/

// first bool represent the stack_adi is positive or negative.
// second bool represent xlen is 32 or 64.
mapping zcmp_assembly_mapping : (bits(4), bits(2), bool, {32, 64}) <-> string = {
  (0x4, 0b00, true, 32)  <-> "{ra} " ^ sep() ^ "16",
  (0x4, 0b00, true, 64) <-> "{ra} " ^ sep() ^ "32",
  (0x4, 0b00, false,32)  <-> "{ra} " ^ sep() ^ "-16",
  (0x4, 0b00, false,64) <-> "{ra} " ^ sep() ^ "-32",
  (0x4, 0b01, true, 32)  <-> "{ra} " ^ sep() ^ "32",
  (0x4, 0b01, true, 64) <-> "{ra} " ^ sep() ^ "48",
  (0x4, 0b01, false,32)  <-> "{ra} " ^ sep() ^ "-32",
  (0x4, 0b01, false,64) <-> "{ra} " ^ sep() ^ "-48",
  (0x4, 0b10, true, 32)  <-> "{ra} " ^ sep() ^ "48",
  (0x4, 0b10, true, 64) <-> "{ra} " ^ sep() ^ "64",
  (0x4, 0b10, false,32)  <-> "{ra} " ^ sep() ^ "-48",
  (0x4, 0b10, false,64) <-> "{ra} " ^ sep() ^ "-64",
  (0x4, 0b11, true, 32)  <-> "{ra} " ^ sep() ^ "64",
  (0x4, 0b11, true, 64) <-> "{ra} " ^ sep() ^ "80",
  (0x4, 0b11, false,32)  <-> "{ra} " ^ sep() ^ "-64",
  (0x4, 0b11, false,64) <-> "{ra} " ^ sep() ^ "-80",

  (0x5, 0b00, true, 32)  <-> "{ra" ^ sep() ^ "s0}" ^ sep() ^ "16",
  (0x5, 0b00, true, 64) <-> "{ra" ^ sep() ^ "s0}" ^ sep() ^ "32",
  (0x5, 0b00, false,32)  <-> "{ra" ^ sep() ^ "s0}" ^ sep() ^ "-16",
  (0x5, 0b00, false,64) <-> "{ra" ^ sep() ^ "s0}" ^ sep() ^ "-32",
  (0x5, 0b01, true, 32)  <-> "{ra" ^ sep() ^ "s0}" ^ sep() ^ "32",
  (0x5, 0b01, true, 64) <-> "{ra" ^ sep() ^ "s0}" ^ sep() ^ "48",
  (0x5, 0b01, false,32)  <-> "{ra" ^ sep() ^ "s0}" ^ sep() ^ "-32",
  (0x5, 0b01, false,64) <-> "{ra" ^ sep() ^ "s0}" ^ sep() ^ "-48",
  (0x5, 0b10, true, 32)  <-> "{ra" ^ sep() ^ "s0}" ^ sep() ^ "48",
  (0x5, 0b10, true, 64) <-> "{ra" ^ sep() ^ "s0}" ^ sep() ^ "64",
  (0x5, 0b10, false,32)  <-> "{ra" ^ sep() ^ "s0}" ^ sep() ^ "-48",
  (0x5, 0b10, false,64) <-> "{ra" ^ sep() ^ "s0}" ^ sep() ^ "-64",
  (0x5, 0b11, true, 32)  <-> "{ra" ^ sep() ^ "s0}" ^ sep() ^ "64",
  (0x5, 0b11, true, 64) <-> "{ra" ^ sep() ^ "s0}" ^ sep() ^ "80",
  (0x5, 0b11, false,32)  <-> "{ra" ^ sep() ^ "s0}" ^ sep() ^ "-64",
  (0x5, 0b11, false,64) <-> "{ra" ^ sep() ^ "s0}" ^ sep() ^ "-80",

  (0x6, 0b00, true, 32)  <-> "{ra" ^ sep() ^ "s0-s1}" ^ sep() ^ "-16",
  (0x6, 0b00, true, 64) <-> "{ra" ^ sep() ^ "s0-s1}" ^ sep() ^ "-32",
  (0x6, 0b00, false,32)  <-> "{ra" ^ sep() ^ "s0-s1}" ^ sep() ^ "--16",
  (0x6, 0b00, false,64) <-> "{ra" ^ sep() ^ "s0-s1}" ^ sep() ^ "--32",
  (0x6, 0b01, true, 32)  <-> "{ra" ^ sep() ^ "s0-s1}" ^ sep() ^ "-32",
  (0x6, 0b01, true, 64) <-> "{ra" ^ sep() ^ "s0-s1}" ^ sep() ^ "-48",
  (0x6, 0b01, false,32)  <-> "{ra" ^ sep() ^ "s0-s1}" ^ sep() ^ "--32",
  (0x6, 0b01, false,64) <-> "{ra" ^ sep() ^ "s0-s1}" ^ sep() ^ "--48",
  (0x6, 0b10, true, 32)  <-> "{ra" ^ sep() ^ "s0-s1}" ^ sep() ^ "-48",
  (0x6, 0b10, true, 64) <-> "{ra" ^ sep() ^ "s0-s1}" ^ sep() ^ "-64",
  (0x6, 0b10, false,32)  <-> "{ra" ^ sep() ^ "s0-s1}" ^ sep() ^ "--48",
  (0x6, 0b10, false,64) <-> "{ra" ^ sep() ^ "s0-s1}" ^ sep() ^ "--64",
  (0x6, 0b11, true, 32)  <-> "{ra" ^ sep() ^ "s0-s1}" ^ sep() ^ "-64",
  (0x6, 0b11, true, 64) <-> "{ra" ^ sep() ^ "s0-s1}" ^ sep() ^ "-80",
  (0x6, 0b11, false,32)  <-> "{ra" ^ sep() ^ "s0-s1}" ^ sep() ^ "--64",
  (0x6, 0b11, false,64) <-> "{ra" ^ sep() ^ "s0-s1}" ^ sep() ^ "--80",

  (0x7, 0b00, true, 32)  <-> "{ra" ^ sep() ^ "s0-s2}" ^ sep() ^ "16",
  (0x7, 0b00, true, 64) <-> "{ra" ^ sep() ^ "s0-s2}" ^ sep() ^ "32",
  (0x7, 0b00, false,32)  <-> "{ra" ^ sep() ^ "s0-s2}" ^ sep() ^ "-16",
  (0x7, 0b00, false,64) <-> "{ra" ^ sep() ^ "s0-s2}" ^ sep() ^ "-32",
  (0x7, 0b01, true, 32)  <-> "{ra" ^ sep() ^ "s0-s2}" ^ sep() ^ "32",
  (0x7, 0b01, true, 64) <-> "{ra" ^ sep() ^ "s0-s2}" ^ sep() ^ "48",
  (0x7, 0b01, false,32)  <-> "{ra" ^ sep() ^ "s0-s2}" ^ sep() ^ "-32",
  (0x7, 0b01, false,64) <-> "{ra" ^ sep() ^ "s0-s2}" ^ sep() ^ "-48",
  (0x7, 0b10, true, 32)  <-> "{ra" ^ sep() ^ "s0-s2}" ^ sep() ^ "48",
  (0x7, 0b10, true, 64) <-> "{ra" ^ sep() ^ "s0-s2}" ^ sep() ^ "64",
  (0x7, 0b10, false,32)  <-> "{ra" ^ sep() ^ "s0-s2}" ^ sep() ^ "-48",
  (0x7, 0b10, false,64) <-> "{ra" ^ sep() ^ "s0-s2}" ^ sep() ^ "-64",
  (0x7, 0b11, true, 32)  <-> "{ra" ^ sep() ^ "s0-s2}" ^ sep() ^ "64",
  (0x7, 0b11, true, 64) <-> "{ra" ^ sep() ^ "s0-s2}" ^ sep() ^ "80",
  (0x7, 0b11, false,32)  <-> "{ra" ^ sep() ^ "s0-s2}" ^ sep() ^ "-64",
  (0x7, 0b11, false,64) <-> "{ra" ^ sep() ^ "s0-s2}" ^ sep() ^ "-80",

  (0x8, 0b00, true, 32)  <-> "{ra" ^ sep() ^ "s0-s3}" ^ sep() ^ "32",
  (0x8, 0b00, true, 64) <-> "{ra" ^ sep() ^ "s0-s3}" ^ sep() ^ "48",
  (0x8, 0b00, false,32)  <-> "{ra" ^ sep() ^ "s0-s3}" ^ sep() ^ "-32",
  (0x8, 0b00, false,64) <-> "{ra" ^ sep() ^ "s0-s3}" ^ sep() ^ "-48",
  (0x8, 0b01, true, 32)  <-> "{ra" ^ sep() ^ "s0-s3}" ^ sep() ^ "48",
  (0x8, 0b01, true, 64) <-> "{ra" ^ sep() ^ "s0-s3}" ^ sep() ^ "64",
  (0x8, 0b01, false,32)  <-> "{ra" ^ sep() ^ "s0-s3}" ^ sep() ^ "-48",
  (0x8, 0b01, false,64) <-> "{ra" ^ sep() ^ "s0-s3}" ^ sep() ^ "-64",
  (0x8, 0b10, true, 32)  <-> "{ra" ^ sep() ^ "s0-s3}" ^ sep() ^ "64",
  (0x8, 0b10, true, 64) <-> "{ra" ^ sep() ^ "s0-s3}" ^ sep() ^ "80",
  (0x8, 0b10, false,32)  <-> "{ra" ^ sep() ^ "s0-s3}" ^ sep() ^ "-64",
  (0x8, 0b10, false,64) <-> "{ra" ^ sep() ^ "s0-s3}" ^ sep() ^ "-80",
  (0x8, 0b11, true, 32)  <-> "{ra" ^ sep() ^ "s0-s3}" ^ sep() ^ "80",
  (0x8, 0b11, true, 64) <-> "{ra" ^ sep() ^ "s0-s3}" ^ sep() ^ "96",
  (0x8, 0b11, false,32)  <-> "{ra" ^ sep() ^ "s0-s3}" ^ sep() ^ "-80",
  (0x8, 0b11, false,64) <-> "{ra" ^ sep() ^ "s0-s3}" ^ sep() ^ "-96",

  (0x9, 0b00, true, 32)  <-> "{ra" ^ sep() ^ "s0-s4}" ^ sep() ^ "32",
  (0x9, 0b00, true, 64) <-> "{ra" ^ sep() ^ "s0-s4}" ^ sep() ^ "48",
  (0x9, 0b00, false,32)  <-> "{ra" ^ sep() ^ "s0-s4}" ^ sep() ^ "-32",
  (0x9, 0b00, false,64) <-> "{ra" ^ sep() ^ "s0-s4}" ^ sep() ^ "-48",
  (0x9, 0b01, true, 32)  <-> "{ra" ^ sep() ^ "s0-s4}" ^ sep() ^ "48",
  (0x9, 0b01, true, 64) <-> "{ra" ^ sep() ^ "s0-s4}" ^ sep() ^ "64",
  (0x9, 0b01, false,32)  <-> "{ra" ^ sep() ^ "s0-s4}" ^ sep() ^ "-48",
  (0x9, 0b01, false,64) <-> "{ra" ^ sep() ^ "s0-s4}" ^ sep() ^ "-64",
  (0x9, 0b10, true, 32)  <-> "{ra" ^ sep() ^ "s0-s4}" ^ sep() ^ "64",
  (0x9, 0b10, true, 64) <-> "{ra" ^ sep() ^ "s0-s4}" ^ sep() ^ "80",
  (0x9, 0b10, false,32)  <-> "{ra" ^ sep() ^ "s0-s4}" ^ sep() ^ "-64",
  (0x9, 0b10, false,64) <-> "{ra" ^ sep() ^ "s0-s4}" ^ sep() ^ "-80",
  (0x9, 0b11, true, 32)  <-> "{ra" ^ sep() ^ "s0-s4}" ^ sep() ^ "80",
  (0x9, 0b11, true, 64) <-> "{ra" ^ sep() ^ "s0-s4}" ^ sep() ^ "96",
  (0x9, 0b11, false,32)  <-> "{ra" ^ sep() ^ "s0-s4}" ^ sep() ^ "-80",
  (0x9, 0b11, false,64) <-> "{ra" ^ sep() ^ "s0-s4}" ^ sep() ^ "-96",

  (0xa, 0b00, true, 32)  <-> "{ra" ^ sep() ^ "s0-s5} " ^ sep() ^ "32",
  (0xa, 0b00, true, 64) <-> "{ra" ^ sep() ^ "s0-s5} " ^ sep() ^ "48",
  (0xa, 0b00, false,32)  <-> "{ra" ^ sep() ^ "s0-s5} " ^ sep() ^ "-32",
  (0xa, 0b00, false,64) <-> "{ra" ^ sep() ^ "s0-s5} " ^ sep() ^ "-48",
  (0xa, 0b01, true, 32)  <-> "{ra" ^ sep() ^ "s0-s5} " ^ sep() ^ "48",
  (0xa, 0b01, true, 64) <-> "{ra" ^ sep() ^ "s0-s5} " ^ sep() ^ "64",
  (0xa, 0b01, false,32)  <-> "{ra" ^ sep() ^ "s0-s5} " ^ sep() ^ "-48",
  (0xa, 0b01, false,64) <-> "{ra" ^ sep() ^ "s0-s5} " ^ sep() ^ "-64",
  (0xa, 0b10, true, 32)  <-> "{ra" ^ sep() ^ "s0-s5} " ^ sep() ^ "64",
  (0xa, 0b10, true, 64) <-> "{ra" ^ sep() ^ "s0-s5} " ^ sep() ^ "80",
  (0xa, 0b10, false,32)  <-> "{ra" ^ sep() ^ "s0-s5} " ^ sep() ^ "-64",
  (0xa, 0b10, false,64) <-> "{ra" ^ sep() ^ "s0-s5} " ^ sep() ^ "-80",
  (0xa, 0b11, true, 32)  <-> "{ra" ^ sep() ^ "s0-s5} " ^ sep() ^ "80",
  (0xa, 0b11, true, 64) <-> "{ra" ^ sep() ^ "s0-s5} " ^ sep() ^ "96",
  (0xa, 0b11, false,32)  <-> "{ra" ^ sep() ^ "s0-s5} " ^ sep() ^ "-80",
  (0xa, 0b11, false,64) <-> "{ra" ^ sep() ^ "s0-s5} " ^ sep() ^ "-96",

  (0xb, 0b00, true, 32)  <-> "{ra" ^ sep() ^ "s0-s6}" ^ sep() ^ "32",
  (0xb, 0b00, true, 64) <-> "{ra" ^ sep() ^ "s0-s6}" ^ sep() ^ "48",
  (0xb, 0b00, false,32)  <-> "{ra" ^ sep() ^ "s0-s6}" ^ sep() ^ "-32",
  (0xb, 0b00, false,64) <-> "{ra" ^ sep() ^ "s0-s6}" ^ sep() ^ "-48",
  (0xb, 0b01, true, 32)  <-> "{ra" ^ sep() ^ "s0-s6}" ^ sep() ^ "48",
  (0xb, 0b01, true, 64) <-> "{ra" ^ sep() ^ "s0-s6}" ^ sep() ^ "64",
  (0xb, 0b01, false,32)  <-> "{ra" ^ sep() ^ "s0-s6}" ^ sep() ^ "-48",
  (0xb, 0b01, false,64) <-> "{ra" ^ sep() ^ "s0-s6}" ^ sep() ^ "-64",
  (0xb, 0b10, true, 32)  <-> "{ra" ^ sep() ^ "s0-s6}" ^ sep() ^ "64",
  (0xb, 0b10, true, 64) <-> "{ra" ^ sep() ^ "s0-s6}" ^ sep() ^ "80",
  (0xb, 0b10, false,32)  <-> "{ra" ^ sep() ^ "s0-s6}" ^ sep() ^ "-64",
  (0xb, 0b10, false,64) <-> "{ra" ^ sep() ^ "s0-s6}" ^ sep() ^ "-80",
  (0xb, 0b11, true, 32)  <-> "{ra" ^ sep() ^ "s0-s6}" ^ sep() ^ "80",
  (0xb, 0b11, true, 64) <-> "{ra" ^ sep() ^ "s0-s6}" ^ sep() ^ "96",
  (0xb, 0b11, false,32)  <-> "{ra" ^ sep() ^ "s0-s6}" ^ sep() ^ "-80",
  (0xb, 0b11, false,64) <-> "{ra" ^ sep() ^ "s0-s6}" ^ sep() ^ "-96",

  (0xc, 0b00, true, 32)  <-> "{ra" ^ sep() ^ "s0-s7}" ^ sep() ^ "48",
  (0xc, 0b00, true, 64) <-> "{ra" ^ sep() ^ "s0-s7}" ^ sep() ^ "64",
  (0xc, 0b00, false,32)  <-> "{ra" ^ sep() ^ "s0-s7}" ^ sep() ^ "-48",
  (0xc, 0b00, false,64) <-> "{ra" ^ sep() ^ "s0-s7}" ^ sep() ^ "-64",
  (0xc, 0b01, true, 32)  <-> "{ra" ^ sep() ^ "s0-s7}" ^ sep() ^ "64",
  (0xc, 0b01, true, 64) <-> "{ra" ^ sep() ^ "s0-s7}" ^ sep() ^ "80",
  (0xc, 0b01, false,32)  <-> "{ra" ^ sep() ^ "s0-s7}" ^ sep() ^ "-64",
  (0xc, 0b01, false,64) <-> "{ra" ^ sep() ^ "s0-s7}" ^ sep() ^ "-80",
  (0xc, 0b10, true, 32)  <-> "{ra" ^ sep() ^ "s0-s7}" ^ sep() ^ "80",
  (0xc, 0b10, true, 64) <-> "{ra" ^ sep() ^ "s0-s7}" ^ sep() ^ "96",
  (0xc, 0b10, false,32)  <-> "{ra" ^ sep() ^ "s0-s7}" ^ sep() ^ "-80",
  (0xc, 0b10, false,64) <-> "{ra" ^ sep() ^ "s0-s7}" ^ sep() ^ "-96",
  (0xc, 0b11, true, 32)  <-> "{ra" ^ sep() ^ "s0-s7}" ^ sep() ^ "96",
  (0xc, 0b11, true, 64) <-> "{ra" ^ sep() ^ "s0-s7}" ^ sep() ^ "112",
  (0xc, 0b11, false,32)  <-> "{ra" ^ sep() ^ "s0-s7}" ^ sep() ^ "-96",
  (0xc, 0b11, false,64 )<-> "{ra" ^ sep() ^ "s0-s7}" ^ sep() ^ "-112",

  (0xd, 0b00, true, 32)  <-> "{ra" ^ sep() ^ " s0-s8}" ^ sep() ^ "48",
  (0xd, 0b00, true, 64) <-> "{ra" ^ sep() ^ " s0-s8}" ^ sep() ^ "64",
  (0xd, 0b00, false,32)  <-> "{ra" ^ sep() ^ " s0-s8}" ^ sep() ^ "-48",
  (0xd, 0b00, false,64) <-> "{ra" ^ sep() ^ " s0-s8}" ^ sep() ^ "-64",
  (0xd, 0b01, true, 32)  <-> "{ra" ^ sep() ^ " s0-s8}" ^ sep() ^ "64",
  (0xd, 0b01, true, 64) <-> "{ra" ^ sep() ^ " s0-s8}" ^ sep() ^ "80",
  (0xd, 0b01, false,32)  <-> "{ra" ^ sep() ^ " s0-s8}" ^ sep() ^ "-64",
  (0xd, 0b01, false,64) <-> "{ra" ^ sep() ^ " s0-s8}" ^ sep() ^ "-80",
  (0xd, 0b10, true, 32)  <-> "{ra" ^ sep() ^ " s0-s8}" ^ sep() ^ "80",
  (0xd, 0b10, true, 64) <-> "{ra" ^ sep() ^ " s0-s8}" ^ sep() ^ "96",
  (0xd, 0b10, false,32)  <-> "{ra" ^ sep() ^ " s0-s8}" ^ sep() ^ "-80",
  (0xd, 0b10, false,64) <-> "{ra" ^ sep() ^ " s0-s8}" ^ sep() ^ "-96",
  (0xd, 0b11, true, 32)  <-> "{ra" ^ sep() ^ " s0-s8}" ^ sep() ^ "96",
  (0xd, 0b11, true, 64) <-> "{ra" ^ sep() ^ " s0-s8}" ^ sep() ^ "112",
  (0xd, 0b11, false,32)  <-> "{ra" ^ sep() ^ " s0-s8}" ^ sep() ^ "-96",
  (0xd, 0b11, false,64) <-> "{ra" ^ sep() ^ " s0-s8}" ^ sep() ^ "-112",

  (0xe, 0b00, true, 32)  <-> "{ra" ^ sep() ^ "s0-s9}" ^ sep() ^ "48",
  (0xe, 0b00, true, 64) <-> "{ra" ^ sep() ^ "s0-s9}" ^ sep() ^ "64",
  (0xe, 0b00, false,32)  <-> "{ra" ^ sep() ^ "s0-s9}" ^ sep() ^ "-48",
  (0xe, 0b00, false,64) <-> "{ra" ^ sep() ^ "s0-s9}" ^ sep() ^ "-64",
  (0xe, 0b01, true, 32)  <-> "{ra" ^ sep() ^ "s0-s9}" ^ sep() ^ "64",
  (0xe, 0b01, true, 64) <-> "{ra" ^ sep() ^ "s0-s9}" ^ sep() ^ "80",
  (0xe, 0b01, false,32)  <-> "{ra" ^ sep() ^ "s0-s9}" ^ sep() ^ "-64",
  (0xe, 0b01, false,64) <-> "{ra" ^ sep() ^ "s0-s9}" ^ sep() ^ "-80",
  (0xe, 0b10, true, 32)  <-> "{ra" ^ sep() ^ "s0-s9}" ^ sep() ^ "80",
  (0xe, 0b10, true, 64) <-> "{ra" ^ sep() ^ "s0-s9}" ^ sep() ^ "96",
  (0xe, 0b10, false,32)  <-> "{ra" ^ sep() ^ "s0-s9}" ^ sep() ^ "-80",
  (0xe, 0b10, false,64) <-> "{ra" ^ sep() ^ "s0-s9}" ^ sep() ^ "-96",
  (0xe, 0b11, true, 32)  <-> "{ra" ^ sep() ^ "s0-s9}" ^ sep() ^ "96",
  (0xe, 0b11, true, 64) <-> "{ra" ^ sep() ^ "s0-s9}" ^ sep() ^ "112",
  (0xe, 0b11, false,32)  <-> "{ra" ^ sep() ^ "s0-s9}" ^ sep() ^ "-96",
  (0xe, 0b11, false,64) <-> "{ra" ^ sep() ^ "s0-s9}" ^ sep() ^ "-112",

  (0xf, 0b00, true, 32)  <-> "{ra" ^ sep() ^ "s0-11}" ^ sep() ^ "64",
  (0xf, 0b00, true, 64) <-> "{ra" ^ sep() ^ "s0-11}" ^ sep() ^ "80",
  (0xf, 0b00, false,32)  <-> "{ra" ^ sep() ^ "s0-11}" ^ sep() ^ "-64",
  (0xf, 0b00, false,64) <-> "{ra" ^ sep() ^ "s0-11}" ^ sep() ^ "-80",
  (0xf, 0b01, true, 32)  <-> "{ra" ^ sep() ^ "s0-11}" ^ sep() ^ "80",
  (0xf, 0b01, true, 64) <-> "{ra" ^ sep() ^ "s0-11}" ^ sep() ^ "96",
  (0xf, 0b01, false,32)  <-> "{ra" ^ sep() ^ "s0-11}" ^ sep() ^ "-80",
  (0xf, 0b01, false,64) <-> "{ra" ^ sep() ^ "s0-11}" ^ sep() ^ "-96",
  (0xf, 0b10, true, 32)  <-> "{ra" ^ sep() ^ "s0-11}" ^ sep() ^ "96",
  (0xf, 0b10, true, 64) <-> "{ra" ^ sep() ^ "s0-11}" ^ sep() ^ "112",
  (0xf, 0b10, false,32)  <-> "{ra" ^ sep() ^ "s0-11}" ^ sep() ^ "-96",
  (0xf, 0b10, false,64) <-> "{ra" ^ sep() ^ "s0-11}" ^ sep() ^ "-112",
  (0xf, 0b11, true, 32)  <-> "{ra" ^ sep() ^ "s0-11}" ^ sep() ^ "112",
  (0xf, 0b11, true, 64) <-> "{ra" ^ sep() ^ "s0-11}" ^ sep() ^ "128",
  (0xf, 0b11, false,32)  <-> "{ra" ^ sep() ^ "s0-11}" ^ sep() ^ "-112",
  (0xf, 0b11, false,64) <-> "{ra" ^ sep() ^ "s0-11}" ^ sep() ^ "-128",
}

function get_stack_adj_base(rlist : bits(4)) -> int = {
  if(xlen == 32) then
    match rlist[3 .. 2] {
      0b01 => 16,
      0b10 => 32,
      0b11 => if rlist == 0b1111 then 64 else 48,
      _ => internal_error(__FILE__, __LINE__, "Unsupported rlist: " ^ bits_str(rlist))
    }
  else {
    match rlist[3 .. 1] {
      0b010 => 16,
      0b011 => 32,
      0b100 => 48,
      0b101 => 64,
      0b110 => 80,
      0b111 => if rlist == 0b1111 then 112 else 96,
      _ => internal_error(__FILE__, __LINE__, "Unsupported rlist: " ^ bits_str(rlist))
    }
  }
}

function zcmp_regmask(rlist : bits(4)) -> bits(32) = {
  var mask : bits(32) = zeros();

  if rlist >=_u 0b0100 then {
    mask[1] = bitone
  };

  foreach (i from 5 to unsigned(rlist)) {
    assert(i <= 15);
    if( (i - 5) < 2 ) then
      mask[3 + i] = bitone
    else {
      mask[11 + i] = bitone
    };
  };

  if(rlist == zero_extend(0xf)) then
    mask[27] = bitone;

  mask
}

enum clause extension = Ext_Zcmp
function clause extensionEnabled(Ext_Zcmp) = extensionEnabled(Ext_Zca) & not(extensionEnabled(Ext_Zcd)) & (xlen == 32 | xlen == 64)

union clause ast = CM_PUSH : (bits(4), bits(2))

mapping clause encdec_compressed = CM_PUSH(rlist, spimm)   if extensionEnabled(Ext_Zcmp)
  <-> 0b101 @ 0b11000 @ rlist : bits(4) @ spimm : bits(2) @ 0b10    if extensionEnabled(Ext_Zcmp)

function process_cmpush (rlist : bits(4), spimm : bits(2)) -> Retired = {
  let width_bytes = xlen_bytes;
  assert(width_bytes <= xlen_bytes);

  let addr = X(sp);
  let stack_adj = negate_int(get_stack_adj_base(rlist) + unsigned(spimm) * 16);
  let new_sp = addr + to_bits(xlen, stack_adj);
  let mask = zcmp_regmask(rlist);

  var offset : int = width_bytes;

  foreach (i from 31 downto 1) {
    if mask[i] == bitone then {
      match ext_data_get_addr(sp, to_bits(xlen, negate_int(offset)), Write(Data), xlen / 8) {
        Ext_DataAddr_Error(e)  => { ext_handle_data_check_error(e); return RETIRE_FAIL },
        Ext_DataAddr_OK(vaddr) =>
        if   check_misaligned(vaddr, size_bytes(xlen_bytes))
        then { handle_mem_exception(vaddr, E_SAMO_Addr_Align()); return RETIRE_FAIL }
        else match translateAddr(vaddr, Write(Data)) {
            TR_Failure(e, _)    => { handle_mem_exception(vaddr, e); return RETIRE_FAIL },
            TR_Address(paddr, _) => {
              let eares = mem_write_ea(paddr, width_bytes, false, false, false);
              match (eares) {
                  MemException(e) => { handle_mem_exception(vaddr, e); return RETIRE_FAIL },
                  MemValue(_) => {
                  let reg_val = X(to_bits(5, i));
                  match mem_write_value(paddr, width_bytes, reg_val[width_bytes * 8 - 1 .. 0], false, false, false) {
                      MemValue(true)  => { offset = offset + width_bytes },
                      MemValue(false) => internal_error(__FILE__, __LINE__, "store got false from mem_write_value"),
                      MemException(e) => { handle_mem_exception(vaddr, e); return RETIRE_FAIL }
                    }
                  }
              }
            }
        }
      }
    }
  };
  X(sp) = new_sp;
  RETIRE_SUCCESS
}

function clause execute (CM_PUSH(rlist, spimm)) = {
  assert(rlist >=_u 0b0100);

  if (xlen == 32) then
    process_cmpush(rlist, spimm)
  else
    process_cmpush(rlist, spimm)
}

mapping clause assembly = CM_PUSH(rlist, spimm) if (sizeof(xlen) == 32) <->
  "cm.push" ^ spc() ^ zcmp_assembly_mapping(rlist, spimm, false, 32) if (sizeof(xlen) == 32)

mapping clause assembly = CM_PUSH(rlist, spimm) if (sizeof(xlen) == 64) <->
  "cm.push" ^ spc() ^ zcmp_assembly_mapping(rlist, spimm, false, 64) if (sizeof(xlen) == 64)


union clause ast = CM_POP : (bits(4), bits(2))

mapping clause encdec_compressed = CM_POP(rlist, spimm)   if extensionEnabled(Ext_Zcmp)
  <-> 0b101 @ 0b11010 @ rlist : bits(4) @ spimm : bits(2) @ 0b10    if extensionEnabled(Ext_Zcmp)

function process_cmpop (rlist : bits(4), spimm : bits(2), write_pc : bool, write_a0 : bool) -> Retired = {
  let width_bytes = xlen_bytes;
  assert(width_bytes <= xlen_bytes);

  let addr = X(sp);
  let stack_adj = get_stack_adj_base(rlist) + unsigned(spimm) * 16;
  let new_sp = addr + to_bits(xlen, stack_adj);
  let mask = zcmp_regmask(rlist);
  let bytes = if sizeof(xlen) == 32 then 4 else 8;

  X(sp) = new_sp;

  var offset : int = width_bytes;

  foreach (i from 31 downto 1) {
    if mask[i] == bitone then {
      match ext_data_get_addr(sp, to_bits(xlen, negate_int(offset)), Write(Data), xlen / 8) {
        Ext_DataAddr_Error(e)  => { ext_handle_data_check_error(e); return RETIRE_FAIL },
        Ext_DataAddr_OK(vaddr) =>
        if   check_misaligned(vaddr, size_bytes(xlen_bytes))
        then { handle_mem_exception(vaddr, E_SAMO_Addr_Align()); return RETIRE_FAIL }
        else match translateAddr(vaddr, Write(Data)) {
            TR_Failure(e, _)    => { handle_mem_exception(vaddr, e); return RETIRE_FAIL },
            TR_Address(paddr, _) => {
              match mem_read(Read(Data), paddr, width_bytes, false, false, false) {
                  MemException(e) => { handle_mem_exception(vaddr, e); return RETIRE_FAIL },
                  MemValue(v) => {
                  X(to_bits(5, i)) = extend_value(true, v);
                  offset = offset + width_bytes
                }
              }
            }
        }
      }
    }
  };

  // cm.popret write pc with ra.
  if write_pc then {
    set_next_pc(X(0b00001));
  };

  // cm.popretz write a0 with zero.
  if write_a0 then {
    X(0b01010) = zeros();
  };

  RETIRE_SUCCESS
}

function clause execute (CM_POP(rlist, spimm)) = {
  assert(rlist >=_u 0b0100);

  if (xlen == 32) then
    process_cmpop(rlist, spimm, false, false)
  else
    process_cmpop(rlist, spimm, false, false)
}

mapping clause assembly = CM_POP(rlist, spimm) if (sizeof(xlen) == 32) <->
  "cm.pop" ^ spc() ^ zcmp_assembly_mapping(rlist, spimm, true, 32) if (sizeof(xlen) == 32)

mapping clause assembly = CM_POP(rlist, spimm) if (sizeof(xlen) == 64) <->
  "cm.pop" ^ spc() ^ zcmp_assembly_mapping(rlist, spimm, true, 64) if (sizeof(xlen) == 64)


union clause ast = CM_POPRET : (bits(4), bits(2))

mapping clause encdec_compressed = CM_POPRET(rlist, spimm)   if extensionEnabled(Ext_Zcmp)
  <-> 0b101 @ 0b11110 @ rlist : bits(4) @ spimm : bits(2) @ 0b10    if extensionEnabled(Ext_Zcmp)

function clause execute (CM_POPRET(rlist, spimm)) = {
  assert(rlist >=_u 0b0100);

  if (xlen == 32) then
    process_cmpop(rlist, spimm, true, false)
  else
    process_cmpop(rlist, spimm, true, false)
}

mapping clause assembly = CM_POPRET(rlist, spimm) if (sizeof(xlen) == 32) <->
  "cm.popret" ^ spc() ^ zcmp_assembly_mapping(rlist, spimm, true, 32) if (sizeof(xlen) == 32)

mapping clause assembly = CM_POPRET(rlist, spimm) if (sizeof(xlen) == 64) <->
  "cm.popret" ^ spc() ^ zcmp_assembly_mapping(rlist, spimm, true, 64) if (sizeof(xlen) == 64)


union clause ast = CM_POPRETZ : (bits(4), bits(2))

mapping clause encdec_compressed = CM_POPRETZ(rlist, spimm)   if extensionEnabled(Ext_Zcmp)
  <-> 0b101 @ 0b11100 @ rlist : bits(4) @ spimm : bits(2) @ 0b10    if extensionEnabled(Ext_Zcmp)

function clause execute (CM_POPRETZ(rlist, spimm)) = {
  assert(rlist >=_u 0b0100);

  if (xlen == 32) then
    process_cmpop(rlist, spimm, false, true)
  else
    process_cmpop(rlist, spimm, false, true)
}

mapping clause assembly = CM_POPRETZ(rlist, spimm) if (sizeof(xlen) == 32) <->
  "cm.popretz" ^ spc() ^ zcmp_assembly_mapping(rlist, spimm, true, 32) if (sizeof(xlen) == 32)

mapping clause assembly = CM_POPRETZ(rlist, spimm) if (sizeof(xlen) == 64) <->
  "cm.popretz" ^ spc() ^ zcmp_assembly_mapping(rlist, spimm, true, 64) if (sizeof(xlen) == 64)

// Differ from creg_name.
mapping rns_name : cregidx <-> string = {
  0b000     <-> "s0",
  0b001     <-> "s1",
  0b010     <-> "s2",
  0b011     <-> "s3",
  0b100     <-> "s4",
  0b101     <-> "s5",
  0b110     <-> "s6",
  0b111     <-> "s7",
}

mapping rns_to_regidx : cregidx <-> regidx = {
  0b000     <-> 0b01000,
  0b001     <-> 0b01001,
  0b010     <-> 0b10010,
  0b011     <-> 0b10011,
  0b100     <-> 0b10100,
  0b101     <-> 0b10101,
  0b110     <-> 0b10110,
  0b111     <-> 0b10111,
}

union clause ast = CM_MVA01S : (cregidx, cregidx)

mapping clause encdec_compressed = CM_MVA01S(r1s', r2s')   if extensionEnabled(Ext_Zcmp)
  <-> 0b101 @ 0b011 @ r1s' : cregidx @ 0b11 @ r2s' : cregidx @ 0b10    if extensionEnabled(Ext_Zcmp)

function clause execute (CM_MVA01S(r1s', r2s')) = {
  X(0b01010) = X(rns_to_regidx(r1s'));
  X(0b01011) = X(rns_to_regidx(r2s'));

  RETIRE_SUCCESS
}

mapping clause assembly = CM_MVA01S(r1s', r2s') <->
  "cm.mva01s" ^ spc() ^ rns_name(r1s') ^ sep() ^ rns_name(r2s')

union clause ast = CM_MVSA01 : (cregidx, cregidx)

mapping clause encdec_compressed = CM_MVSA01(r1s', r2s')   if extensionEnabled(Ext_Zcmp)
  <-> 0b101 @ 0b011 @ r1s' : cregidx @ 0b01 @ r2s' : cregidx @ 0b10    if extensionEnabled(Ext_Zcmp)

function clause execute (CM_MVSA01(r1s', r2s')) = {
  assert(r1s' != r2s');

  X(rns_to_regidx(r1s')) = X(0b01010);
  X(rns_to_regidx(r2s')) = X(0b01011);

  RETIRE_SUCCESS
}

mapping clause assembly = CM_MVSA01(r1s', r2s') <->
  "cm.mvsa01" ^ spc() ^ rns_name(r1s') ^ sep() ^ rns_name(r2s')
