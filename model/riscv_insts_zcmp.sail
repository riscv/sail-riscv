/*=======================================================================================*/
/*  This Sail RISC-V architecture model, comprising all files and                        */
/*  directories except where otherwise noted is subject the BSD                          */
/*  two-clause license in the LICENSE file.                                              */
/*                                                                                       */
/*  SPDX-License-Identifier: BSD-2-Clause                                                */
/*=======================================================================================*/


function clause extensionEnabled(Ext_Zcmp) = extensionEnabled(Ext_Zca) & sys_enable_zcmp() & not(sys_enable_zcd()) & (xlen == 32 | xlen == 64)

function str_dec(str: string) -> int = {
  let base : int = 10;
  var result : int = 0;
  var sign : int = 1;
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
  0x5 <-> "ra" ^ sep() ^ "s0",
  0x6 <-> "ra" ^ sep() ^ "s0-s1",
  0x7 <-> "ra" ^ sep() ^ "s0-s2",
  0x8 <-> "ra" ^ sep() ^ "s0-s3",
  0x9 <-> "ra" ^ sep() ^ "s0-s4",
  0xa <-> "ra" ^ sep() ^ "s0-s5",
  0xb <-> "ra" ^ sep() ^ "s0-s6",
  0xc <-> "ra" ^ sep() ^ "s0-s7",
  0xd <-> "ra" ^ sep() ^ "s0-s8",
  0xe <-> "ra" ^ sep() ^ "s0-s9",
  // To include s10, s11 must also be included.
  0xf <-> "ra" ^ sep() ^ "s0-s11",

  // Using X names instead of ABI names.
  0x4 <-> "x1",
  0x5 <-> "x1" ^ sep() ^ "x8",
  0x6 <-> "x1" ^ sep() ^ "x8-x9",
  0x7 <-> "x1" ^ sep() ^ "x8-x9" ^ sep() ^ "x18",
  0x8 <-> "x1" ^ sep() ^ "x8-x9" ^ sep() ^ "x18-x19",
  0x9 <-> "x1" ^ sep() ^ "x8-x9" ^ sep() ^ "x18-x20",
  0xa <-> "x1" ^ sep() ^ "x8-x9" ^ sep() ^ "x18-x21",
  0xb <-> "x1" ^ sep() ^ "x8-x9" ^ sep() ^ "x18-x22",
  0xc <-> "x1" ^ sep() ^ "x8-x9" ^ sep() ^ "x18-x23",
  0xd <-> "x1" ^ sep() ^ "x8-x9" ^ sep() ^ "x18-x24",
  0xe <-> "x1" ^ sep() ^ "x8-x9" ^ sep() ^ "x18-x25",
  0xf <-> "x1" ^ sep() ^ "x8-x9" ^ sep() ^ "x18-x27",
}

mapping negative_sign : bool <-> string = {
  false <-> "",
  true  <-> "-",
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
    var stack_adj : int = undefined;
    let stack_adj_base = get_stack_adj_base(rlist);
    stack_adj = stack_adj_base + unsigned(spimm54) * 16;

    if stack_adj_base == 0 then {
      "unsupport rlist" ^ sep() ^ negative_sign(is_negative) ^ dec_str(stack_adj)
    } else {
      "{" ^ zcmp_assembly_rlist(rlist) ^ "}" ^ sep() ^ negative_sign(is_negative) ^ dec_str(stack_adj)
    }
  },
  backwards str_input => {
    var str = str_input;
    var rlist : bits(4) = undefined;
    var spimm54 : bits(2) = undefined;
    var is_negative : bool = false;

    if string_take(str, 7) == "cm.push" then {
      is_negative = true;
      str = string_drop(str, 9);
    } else if string_take(str, 6) == "cm.pop" then {
      is_negative = false;
      str = string_drop(str, 8);
    } else if string_take(str, 9) == "cm.popret" then {
      is_negative = false;
      str = string_drop(str, 11);
    } else {
      is_negative = false;
      str = string_drop(str, 12);
    };

    if string_take(str, 3) == "ra," then {
      if string_take(str, 5) == "ra, s0" then {
        rlist = zcmp_assembly_rlist(string_take(str, 5));
        str = string_drop(str, 9);
      } else {
        if string_take(str, 10) == "ra, s0-s11" then {
          rlist = zcmp_assembly_rlist(string_take(str, 10));
          str = string_drop(str, 13);
        } else {
          rlist = zcmp_assembly_rlist(string_take(str, 9));
          str = string_drop(str, 12);
        }
      }
    } else {
      rlist = zcmp_assembly_rlist(string_take(str, 2));
      str = string_drop(str, 5);
    };

    if string_take(str, 1) == "-" then {
      str = string_drop(str, 1);
    };

    let stack_adj_offset : int = str_dec(str);

    spimm54 = to_bits(2, (stack_adj_offset - get_stack_adj_base(rlist)) / 16);

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

mapping clause encdec_compressed = CM_PUSH(rlist, spimm)   if extensionEnabled(Ext_Zcmp)
  <-> 0b101 @ 0b11000 @ rlist : bits(4) @ spimm : bits(2) @ 0b10    if extensionEnabled(Ext_Zcmp)

function process_cmpush (rlist : bits(4), spimm : bits(2)) -> Retired = {
  let addr = X(sp);
  let stack_adj = negate_int(get_stack_adj_base(rlist) + unsigned(spimm) * 16);
  let new_sp = addr + to_bits(xlen, stack_adj);
  let mask = zcmp_regmask(rlist);
  let width = size_bytes(xlen_bytes);

  var offset : int = negate_int(xlen_bytes);

  foreach (i from 31 downto 1) {
    if mask[i] == bitone then {
      match execute(STORE(to_bits(12, offset), to_bits(5, i), sp, width, false, false)) {
        RETIRE_SUCCESS  => { offset = offset - xlen_bytes },
        RETIRE_FAIL     => { return RETIRE_FAIL }
      };
    }
  };
  X(sp) = new_sp;
  RETIRE_SUCCESS
}

function clause execute (CM_PUSH(rlist, spimm)) = {
  assert(rlist >=_u 0b0100);

  process_cmpush(rlist, spimm)
}

mapping clause assembly = CM_PUSH(rlist, spimm) if (xlen == 32 | xlen == 64) <->
  "cm.push" ^ spc() ^ zcmp_assembly_mapping(rlist, spimm, false) if (xlen == 32 | xlen == 64)
/* ****************************************************************** */
union clause ast = CM_POP : (bits(4), bits(2))

mapping clause encdec_compressed = CM_POP(rlist, spimm)   if extensionEnabled(Ext_Zcmp)
  <-> 0b101 @ 0b11010 @ rlist : bits(4) @ spimm : bits(2) @ 0b10    if extensionEnabled(Ext_Zcmp)

function process_cmpop (rlist : bits(4), spimm : bits(2), write_pc : bool, write_a0 : bool) -> Retired = {
  let addr = X(sp);
  let stack_adj = get_stack_adj_base(rlist) + unsigned(spimm) * 16;
  let new_sp = addr + to_bits(xlen, stack_adj);
  let mask = zcmp_regmask(rlist);
  let width = size_bytes(xlen_bytes);

  var offset : int = stack_adj - xlen_bytes;

  foreach (i from 31 downto 1) {
    if mask[i] == bitone then {
      match execute(LOAD(to_bits(12, offset), sp, to_bits(5, i), true, width, false, false)) {
        RETIRE_SUCCESS  => { offset = offset - xlen_bytes },
        RETIRE_FAIL     => { return RETIRE_FAIL }
      };
    }
  };
  // cm.popretz write a0 with zero.
  if write_a0 then {
    X(10) = zeros();
  };
  X(sp) = new_sp;
  // cm.popret or cm.popretz write pc with ra.
  if write_pc then {
    set_next_pc(X(1));
  };
  RETIRE_SUCCESS
}

function clause execute (CM_POP(rlist, spimm)) = {
  assert(rlist >=_u 0b0100);

  process_cmpop(rlist, spimm, false, false)
}

mapping clause assembly = CM_POP(rlist, spimm) if (xlen == 32 | xlen == 64) <->
  "cm.pop" ^ spc() ^ zcmp_assembly_mapping(rlist, spimm, true) if (xlen == 32 | xlen == 64)

/* ****************************************************************** */
union clause ast = CM_POPRET : (bits(4), bits(2))

mapping clause encdec_compressed = CM_POPRET(rlist, spimm)   if extensionEnabled(Ext_Zcmp)
  <-> 0b101 @ 0b11110 @ rlist : bits(4) @ spimm : bits(2) @ 0b10    if extensionEnabled(Ext_Zcmp)

function clause execute (CM_POPRET(rlist, spimm)) = {
  assert(rlist >=_u 0b0100);

  process_cmpop(rlist, spimm, true, false)
}

mapping clause assembly = CM_POPRET(rlist, spimm) if (xlen == 32 | xlen == 64) <->
  "cm.popret" ^ spc() ^ zcmp_assembly_mapping(rlist, spimm, true) if (xlen == 32 | xlen == 64)
/* ****************************************************************** */
union clause ast = CM_POPRETZ : (bits(4), bits(2))

mapping clause encdec_compressed = CM_POPRETZ(rlist, spimm)   if extensionEnabled(Ext_Zcmp)
  <-> 0b101 @ 0b11100 @ rlist : bits(4) @ spimm : bits(2) @ 0b10    if extensionEnabled(Ext_Zcmp)

function clause execute (CM_POPRETZ(rlist, spimm)) = {
  assert(rlist >=_u 0b0100);

  process_cmpop(rlist, spimm, true, true)
}

mapping clause assembly = CM_POPRETZ(rlist, spimm) if (xlen == 32 | xlen == 64) <->
  "cm.popretz" ^ spc() ^ zcmp_assembly_mapping(rlist, spimm, true) if (xlen == 32 | xlen == 64)
/* ****************************************************************** */
union clause ast = CM_MVA01S : (cregidx, cregidx)

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

mapping clause encdec_compressed = CM_MVA01S(r1s', r2s')   if extensionEnabled(Ext_Zcmp)
  <-> 0b101 @ 0b011 @ r1s' : cregidx @ 0b11 @ r2s' : cregidx @ 0b10    if extensionEnabled(Ext_Zcmp)

function clause execute (CM_MVA01S(r1s', r2s')) = {
  X(10) = X(rns_to_regidx(r1s'));
  X(11) = X(rns_to_regidx(r2s'));

  RETIRE_SUCCESS
}

mapping clause assembly = CM_MVA01S(r1s', r2s') if (xlen == 32 | xlen == 64) <->
  "cm.mva01s" ^ spc() ^ rns_name(r1s') ^ sep() ^ rns_name(r2s') if (xlen == 32 | xlen == 64)
/* ****************************************************************** */
union clause ast = CM_MVSA01 : (cregidx, cregidx)

mapping clause encdec_compressed = CM_MVSA01(r1s', r2s')   if extensionEnabled(Ext_Zcmp)
  <-> 0b101 @ 0b011 @ r1s' : cregidx @ 0b01 @ r2s' : cregidx @ 0b10    if extensionEnabled(Ext_Zcmp)

function clause execute (CM_MVSA01(r1s', r2s')) = {
  assert(r1s' != r2s');

  X(rns_to_regidx(r1s')) = X(10);
  X(rns_to_regidx(r2s')) = X(11);

  RETIRE_SUCCESS
}

mapping clause assembly = CM_MVSA01(r1s', r2s') if (xlen == 32 | xlen == 64) <->
  "cm.mvsa01" ^ spc() ^ rns_name(r1s') ^ sep() ^ rns_name(r2s') if (xlen == 32 | xlen == 64)
