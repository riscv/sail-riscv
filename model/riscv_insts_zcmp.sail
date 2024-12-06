/*=======================================================================================*/
/*  This Sail RISC-V architecture model, comprising all files and                        */
/*  directories except where otherwise noted is subject the BSD                          */
/*  two-clause license in the LICENSE file.                                              */
/*                                                                                       */
/*  SPDX-License-Identifier: BSD-2-Clause                                                */
/*=======================================================================================*/

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
}

mapping negative_sign : bool <-> string = {
  false <-> "",
  true <-> "-",
}

// Note for the integer types we deal in 16s, so a value of 1 here means 16 bytes.
type stack_adj = range(1, if xlen == 32 then 7 else 10)
type stack_adj_base = range(1, if xlen == 32 then 4 else 7)

mapping stack_adj_str : string <-> stack_adj = {
  "16" <-> 1,
  "32" <-> 2,
  "48" <-> 3,
  "64" <-> 4,
  "80" <-> 5,
  "96" <-> 6,
  "112" <-> 7,
  "128" if xlen == 64 <-> 8  if xlen == 64,
  "144" if xlen == 64 <-> 9  if xlen == 64,
  "160" if xlen == 64 <-> 10 if xlen == 64,
}

function get_stack_adj_base(rlist : bits(4)) -> int = {
  if(xlen == 32) then
    match rlist[3 .. 2] {
      0b01 => 16,
      0b10 => 32,
      0b11 => if rlist == 0b1111 then 64 else 48
    }
  else {
    match rlist[3 .. 1] {
      0b010 => 16,
      0b011 => 32,
      0b100 => 48,
      0b101 => 64,
      0b110 => 80,
      0b111 => if rlist == 0b1111 then 112 else 96,
    }
  }
}

val zcmp_assembly_mapping : (bits(4), bits(2), bool) <-> string

function zcmp_assembly_mapping_forwards (rlist, spimm, is_negative) = {
  var stack_adj : int = undefined;
  stack_adj = get_stack_adj_base(rlist) + unsigned(spimm);

  "{" ^ zcmp_assembly_rlist(rlist) ^ ", " ^ BitStr(to_bits(xlen, stack_adj)) ^ ", " ^ negative_sign(is_negative) ^ "}"
}

function zcmp_assembly_mapping_forwards_matches (rlist, spimm54, is_negative) = true

function zcmp_assembly_mapping_backwards(str_input) = {
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

  var stack_adj_offset : int = 0;

  foreach (i from string_length(str) downto 1) {
    let temp_val : int = match string_take(str, 1) {
      "0" => 0,
      "1" => 1,
      "2" => 2,
      "3" => 3,
      "4" => 4,
      "5" => 5,
      "6" => 6,
      "7" => 7,
      "8" => 8,
      "9" => 9
    };
    stack_adj_offset = stack_adj_offset + temp_val;
    stack_adj_offset = stack_adj_offset * 10;
  };

  spimm54 = to_bits(2, (stack_adj_offset - get_stack_adj_base(rlist)) / 16);

  (rlist, spimm54, is_negative)
}

function zcmp_assembly_mapping_backwards_matches (str) = true


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
  let stack_adj = rlist_stack_adj_base(rlist) + unsigned(spimm) * 16;
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