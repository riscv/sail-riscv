/*=======================================================================================*/
/*  This Sail RISC-V architecture model, comprising all files and                        */
/*  directories except where otherwise noted is subject the BSD                          */
/*  two-clause license in the LICENSE file.                                              */
/*                                                                                       */
/*  SPDX-License-Identifier: BSD-2-Clause                                                */
/*=======================================================================================*/

function clause extensionEnabled(Ext_Zcmp) = extensionEnabled(Ext_Zca) & sys_enable_zcmp() & not(sys_enable_zcd()) & (xlen == 32 | xlen == 64)

function str_dec(str: string) -> int = {
  let base    : int = 10;
  var result  : int = 0;
  var sign    : int = 1;
  var num_str : string = str;

  // Handle negative sign
  if string_take(num_str, 1) == "-" then {
    sign = -1;
    num_str = string_drop(num_str, 1);
  };

  // Iterate over each character
  foreach (i from 1 to string_length(num_str)) {
    let digit : int = match string_take(num_str, 1) {
      "0" => 0,
      "1" => 1,
      "2" => 2,
      "3" => 3,
      "4" => 4,
      "5" => 5,
      "6" => 6,
      "7" => 7,
      "8" => 8,
      "9" => 9,
      _ => internal_error(__FILE__, __LINE__, "Expected numerical value: " ^ str)
    };
    num_str = string_drop(num_str, 1);
    result = result * base + digit;
  };
  sign * result
}

mapping zcmp_assembly_rlist : bits(4) <-> string = {
  0x4 <-> "ra",
  0x5 <-> "ra, s0",
  0x6 <-> "ra, s0-s1",
  0x7 <-> "ra, s0-s2",
  0x8 <-> "ra, s0-s3",
  0x9 <-> "ra, s0-s4",
  0xa <-> "ra, s0-s5",
  0xb <-> "ra, s0-s6",
  0xc <-> "ra, s0-s7",
  0xd <-> "ra, s0-s8",
  0xe <-> "ra, s0-s9",
  0xf <-> "ra, s0-s11",
  // Using X names instead of ABI names.
  0x4 <-> "x1",
  0x5 <-> "x1, x8",
  0x6 <-> "x1, x8-x9",
  0x7 <-> "x1, x8-x9, x18",
  0x8 <-> "x1, x8-x9, x18-x19",
  0x9 <-> "x1, x8-x9, x18-x20",
  0xa <-> "x1, x8-x9, x18-x21",
  0xb <-> "x1, x8-x9, x18-x22",
  0xc <-> "x1, x8-x9, x18-x23",
  0xd <-> "x1, x8-x9, x18-x24",
  0xe <-> "x1, x8-x9, x18-x25",
  0xf <-> "x1, x8-x9, x18-x27"
}


function get_stack_adj_base(rlist : bits(4)) -> int = {
  if(xlen == 32) then
    match rlist[3 .. 2] {
      0b01 => 16,
      0b10 => 32,
      0b11 => if rlist == 0b1111 then 64 else 48,
      _    => 0
    }
  else {
    match rlist[3 .. 1] {
      0b010 => 16,
      0b011 => 32,
      0b100 => 48,
      0b101 => 64,
      0b110 => 80,
      0b111 => if rlist == 0b1111 then 112 else 96,
      _     => 0
    }
  }
}

mapping zcmp_assembly_mapping : (bits(4), bits(2), bool) <-> string = {
  forwards (rlist, spimm54, is_negative) => {
    let stack_adj_base = get_stack_adj_base(rlist);
    let stack_adj = stack_adj_base + unsigned(spimm54) * 16;
    let sign = if is_negative then "-" else "";

    "{" ^ zcmp_assembly_rlist(rlist) ^ "}" ^ sep() ^ sign ^ dec_str(stack_adj)
  },
  backwards str_input => {
    var str   = str_input;
    var rlist : bits(4) = zeros();
    let is_negative = string_take(str, 7) == "cm.push";

    // Determine instruction and drop prefix
    let drop_len = if is_negative then 9
               else if string_take(str, 6) == "cm.pop" then 8
               else if string_take(str, 9) == "cm.popret" then 11
               else 12; // cm.popretz

    str = string_drop(str, drop_len);

    // Parse register list
    if string_take(str, 3) == "ra," then {
      // Handle registers starting with "ra,"
      if string_take(str, 5) == "ra, s0" then {
        rlist = zcmp_assembly_rlist(string_take(str, 5));
        str = string_drop(str, 9);
      } else if string_take(str, 10) == "ra, s0-s11" then {
        rlist = zcmp_assembly_rlist(string_take(str, 10));
        str = string_drop(str, 13);
      } else {
        rlist = zcmp_assembly_rlist(string_take(str, 9));
        str = string_drop(str, 12);
      }
    } else {
      rlist = zcmp_assembly_rlist(string_take(str, 2));
      str = string_drop(str, 5);
    };

    if string_take(str, 1) == "-" then
      str = string_drop(str, 1);

    let stack_adj_offset = str_dec(str);
    let spimm54 = to_bits(2, (stack_adj_offset - get_stack_adj_base(rlist)) / 16);

    (rlist, spimm54, is_negative)
  },
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

/* ****************************************************************** */
union clause ast = CM_PUSH : (bits(4), bits(2))

mapping clause encdec_compressed = CM_PUSH(rlist, spimm)
  <-> 0b101 @ 0b11000 @ rlist : bits(4) @ spimm : bits(2) @ 0b10
  when extensionEnabled(Ext_Zcmp) & rlist >=_u 0b0100

function process_cmpush (rlist : bits(4), spimm : bits(2)) -> Retired = {
  let addr      = X(sp);
  let stack_adj = negate_int(get_stack_adj_base(rlist) + unsigned(spimm) * 16);
  let new_sp    = addr + to_bits(xlen, stack_adj);

  let mask      = zcmp_regmask(rlist);
  let width     = size_bytes(xlen_bytes);
  var offset    = negate_int(xlen_bytes);

  foreach (i from 31 downto 1) {
    if mask[i] == bitone then {
      let imm = to_bits(12, offset);
      let rs2 = bits_regidx(to_bits(5, i));
      match execute(STORE(imm, rs2, sp, width, false, false)) {
        RETIRE_SUCCESS => { offset = offset - xlen_bytes },
        RETIRE_FAIL    => { return RETIRE_FAIL }
      };
    }
  };
  X(sp) = new_sp;
  RETIRE_SUCCESS
}

function clause execute (CM_PUSH(rlist, spimm)) = {
  process_cmpush(rlist, spimm)
}

mapping clause assembly = CM_PUSH(rlist, spimm)
  <-> "cm.push" ^ spc() ^ zcmp_assembly_mapping(rlist, spimm, false)
/* ****************************************************************** */
union clause ast = CM_POP : (bits(4), bits(2))

mapping clause encdec_compressed = CM_POP(rlist, spimm)
  <-> 0b101 @ 0b11010 @ rlist : bits(4) @ spimm : bits(2) @ 0b10
  when extensionEnabled(Ext_Zcmp) & rlist >=_u 0b0100

function process_cmpop (rlist : bits(4), spimm : bits(2), write_pc : bool, write_a0 : bool) -> Retired = {
  let addr         = X(sp);
  let stack_adj    = get_stack_adj_base(rlist) + unsigned(spimm) * 16;
  let new_sp       = addr + to_bits(xlen, stack_adj);

  let mask         = zcmp_regmask(rlist);
  let width        = size_bytes(xlen_bytes);
  var offset : int = stack_adj - xlen_bytes;

  foreach (i from 31 downto 1) {
    if mask[i] == bitone then {
      let imm = to_bits(12, offset);
      let rd  = bits_regidx(to_bits(5, i));
      match execute(LOAD(imm, sp, rd, true, width, false, false)) {
        RETIRE_SUCCESS => { offset = offset - xlen_bytes },
        RETIRE_FAIL    => { return RETIRE_FAIL }
      };
    }
  };
  if write_a0 then X(a0) = zeros();
  X(sp) = new_sp;
  if write_pc then set_next_pc(X(ra));
  RETIRE_SUCCESS
}

function clause execute (CM_POP(rlist, spimm)) = {
  process_cmpop(rlist, spimm, false, false)
}

mapping clause assembly = CM_POP(rlist, spimm)
  <-> "cm.pop" ^ spc() ^ zcmp_assembly_mapping(rlist, spimm, true)

/* ****************************************************************** */
union clause ast = CM_POPRET : (bits(4), bits(2))

mapping clause encdec_compressed = CM_POPRET(rlist, spimm)
  <-> 0b101 @ 0b11110 @ rlist : bits(4) @ spimm : bits(2) @ 0b10
  when extensionEnabled(Ext_Zcmp) & rlist >=_u 0b0100

function clause execute (CM_POPRET(rlist, spimm)) = {
  process_cmpop(rlist, spimm, true, false)
}

mapping clause assembly = CM_POPRET(rlist, spimm)
  <-> "cm.popret" ^ spc() ^ zcmp_assembly_mapping(rlist, spimm, true)
/* ****************************************************************** */
union clause ast = CM_POPRETZ : (bits(4), bits(2))

mapping clause encdec_compressed = CM_POPRETZ(rlist, spimm)
  <-> 0b101 @ 0b11100 @ rlist : bits(4) @ spimm : bits(2) @ 0b10
  when extensionEnabled(Ext_Zcmp) & rlist >=_u 0b0100

function clause execute (CM_POPRETZ(rlist, spimm)) = {
  process_cmpop(rlist, spimm, true, true)
}

mapping clause assembly = CM_POPRETZ(rlist, spimm)
  <-> "cm.popretz" ^ spc() ^ zcmp_assembly_mapping(rlist, spimm, true)
/* ****************************************************************** */

mapping rns_name : bits(3) <-> string = {
  0b000 <-> "s0",
  0b001 <-> "s1",
  0b010 <-> "s2",
  0b011 <-> "s3",
  0b100 <-> "s4",
  0b101 <-> "s5",
  0b110 <-> "s6",
  0b111 <-> "s7",
}

mapping rns_to_regidx : cregidx <-> regidx = {
  Cregidx(0b000) <-> Regidx(0b01000),
  Cregidx(0b001) <-> Regidx(0b01001),
  Cregidx(0b010) <-> Regidx(0b10010),
  Cregidx(0b011) <-> Regidx(0b10011),
  Cregidx(0b100) <-> Regidx(0b10100),
  Cregidx(0b101) <-> Regidx(0b10101),
  Cregidx(0b110) <-> Regidx(0b10110),
  Cregidx(0b111) <-> Regidx(0b10111),
}

mapping creg_zcmp_name : cregidx <-> string = { Cregidx(i) <-> rns_name(i) }

union clause ast = CM_MVA01S : (cregidx, cregidx)

mapping clause encdec_compressed = CM_MVA01S(r1s', r2s')
  <-> 0b101 @ 0b011 @ encdec_creg(r1s') @ 0b11 @ encdec_creg(r2s') @ 0b10
  when extensionEnabled(Ext_Zcmp)

function clause execute (CM_MVA01S(r1s', r2s')) = {
  X(a0) = X(rns_to_regidx(r1s'));
  X(a1) = X(rns_to_regidx(r2s'));
  RETIRE_SUCCESS
}

mapping clause assembly = CM_MVA01S(r1s', r2s')
  <-> "cm.mva01s" ^ spc() ^ creg_zcmp_name(r1s') ^ sep() ^ creg_zcmp_name(r2s')
/* ****************************************************************** */
union clause ast = CM_MVSA01 : (cregidx, cregidx)

mapping clause encdec_compressed = CM_MVSA01(r1s', r2s')
  <-> 0b101 @ 0b011 @ encdec_creg(r1s') @ 0b01 @ encdec_creg(r2s') @ 0b10
  when extensionEnabled(Ext_Zcmp) & r1s' != r2s'

function clause execute (CM_MVSA01(r1s', r2s')) = {
  X(rns_to_regidx(r1s')) = X(a0);
  X(rns_to_regidx(r2s')) = X(a1);
  RETIRE_SUCCESS
}

mapping clause assembly = CM_MVSA01(r1s', r2s')
  <-> "cm.mvsa01" ^ spc() ^ creg_zcmp_name(r1s') ^ sep() ^ creg_zcmp_name(r2s')
