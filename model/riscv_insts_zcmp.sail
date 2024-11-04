/*=======================================================================================*/
/*  This Sail RISC-V architecture model, comprising all files and                        */
/*  directories except where otherwise noted is subject the BSD                          */
/*  two-clause license in the LICENSE file.                                              */
/*                                                                                       */
/*  SPDX-License-Identifier: BSD-2-Clause                                                */
/*=======================================================================================*/

// first bool represent the stack_adi is positive or negative.
// second bool represent xlen is 32 or 64.
mapping zcmp_assembly_mapping : (bits(4), bits(2), bool, bool) <-> string = {
  (0x4, 0b00, true, true)  <-> "{ra}, 16",
  (0x4, 0b00, true, false) <-> "{ra}, 32",
  (0x4, 0b00, false,true)  <-> "{ra}, -16",
  (0x4, 0b00, false,false) <-> "{ra}, -32",
  (0x4, 0b01, true, true)  <-> "{ra}, 32",
  (0x4, 0b01, true, false) <-> "{ra}, 48",
  (0x4, 0b01, false,true)  <-> "{ra}, -32",
  (0x4, 0b01, false,false) <-> "{ra}, -48",
  (0x4, 0b10, true, true)  <-> "{ra}, 48",
  (0x4, 0b10, true, false) <-> "{ra}, 64",
  (0x4, 0b10, false,true)  <-> "{ra}, -48",
  (0x4, 0b10, false,false) <-> "{ra}, -64",
  (0x4, 0b11, true, true)  <-> "{ra}, 64",
  (0x4, 0b11, true, false) <-> "{ra}, 80",
  (0x4, 0b11, false,true)  <-> "{ra}, -64",
  (0x4, 0b11, false,false) <-> "{ra}, -80",

  (0x5, 0b00, true, true)  <-> "{ra, s0}, 16",
  (0x5, 0b00, true, false) <-> "{ra, s0}, 32",
  (0x5, 0b00, false,true)  <-> "{ra, s0}, -16",
  (0x5, 0b00, false,false) <-> "{ra, s0}, -32",
  (0x5, 0b01, true, true)  <-> "{ra, s0}, 32",
  (0x5, 0b01, true, false) <-> "{ra, s0}, 48",
  (0x5, 0b01, false,true)  <-> "{ra, s0}, -32",
  (0x5, 0b01, false,false) <-> "{ra, s0}, -48",
  (0x5, 0b10, true, true)  <-> "{ra, s0}, 48",
  (0x5, 0b10, true, false) <-> "{ra, s0}, 64",
  (0x5, 0b10, false,true)  <-> "{ra, s0}, -48",
  (0x5, 0b10, false,false) <-> "{ra, s0}, -64",
  (0x5, 0b11, true, true)  <-> "{ra, s0}, 64",
  (0x5, 0b11, true, false) <-> "{ra, s0}, 80",
  (0x5, 0b11, false,true)  <-> "{ra, s0}, -64",
  (0x5, 0b11, false,false) <-> "{ra, s0}, -80",

  (0x6, 0b00, true, true)  <-> "{ra, s0-s1}, -16",
  (0x6, 0b00, true, false) <-> "{ra, s0-s1}, -32",
  (0x6, 0b00, false,true)  <-> "{ra, s0-s1}, --16",
  (0x6, 0b00, false,false) <-> "{ra, s0-s1}, --32",
  (0x6, 0b01, true, true)  <-> "{ra, s0-s1}, -32",
  (0x6, 0b01, true, false) <-> "{ra, s0-s1}, -48",
  (0x6, 0b01, false,true)  <-> "{ra, s0-s1}, --32",
  (0x6, 0b01, false,false) <-> "{ra, s0-s1}, --48",
  (0x6, 0b10, true, true)  <-> "{ra, s0-s1}, -48",
  (0x6, 0b10, true, false) <-> "{ra, s0-s1}, -64",
  (0x6, 0b10, false,true)  <-> "{ra, s0-s1}, --48",
  (0x6, 0b10, false,false) <-> "{ra, s0-s1}, --64",
  (0x6, 0b11, true, true)  <-> "{ra, s0-s1}, -64",
  (0x6, 0b11, true, false) <-> "{ra, s0-s1}, -80",
  (0x6, 0b11, false,true)  <-> "{ra, s0-s1}, --64",
  (0x6, 0b11, false,false) <-> "{ra, s0-s1}, --80",

  (0x7, 0b00, true, true)  <-> "{ra, s0-s2}, 16",
  (0x7, 0b00, true, false) <-> "{ra, s0-s2}, 32",
  (0x7, 0b00, false,true)  <-> "{ra, s0-s2}, -16",
  (0x7, 0b00, false,false) <-> "{ra, s0-s2}, -32",
  (0x7, 0b01, true, true)  <-> "{ra, s0-s2}, 32",
  (0x7, 0b01, true, false) <-> "{ra, s0-s2}, 48",
  (0x7, 0b01, false,true)  <-> "{ra, s0-s2}, -32",
  (0x7, 0b01, false,false) <-> "{ra, s0-s2}, -48",
  (0x7, 0b10, true, true)  <-> "{ra, s0-s2}, 48",
  (0x7, 0b10, true, false) <-> "{ra, s0-s2}, 64",
  (0x7, 0b10, false,true)  <-> "{ra, s0-s2}, -48",
  (0x7, 0b10, false,false) <-> "{ra, s0-s2}, -64",
  (0x7, 0b11, true, true)  <-> "{ra, s0-s2}, 64",
  (0x7, 0b11, true, false) <-> "{ra, s0-s2}, 80",
  (0x7, 0b11, false,true)  <-> "{ra, s0-s2}, -64",
  (0x7, 0b11, false,false) <-> "{ra, s0-s2}, -80",

  (0x8, 0b00, true, true)  <-> "{ra, s0-s3}, 32",
  (0x8, 0b00, true, false) <-> "{ra, s0-s3}, 48",
  (0x8, 0b00, false,true)  <-> "{ra, s0-s3}, -32",
  (0x8, 0b00, false,false) <-> "{ra, s0-s3}, -48",
  (0x8, 0b01, true, true)  <-> "{ra, s0-s3}, 48",
  (0x8, 0b01, true, false) <-> "{ra, s0-s3}, 64",
  (0x8, 0b01, false,true)  <-> "{ra, s0-s3}, -48",
  (0x8, 0b01, false,false) <-> "{ra, s0-s3}, -64",
  (0x8, 0b10, true, true)  <-> "{ra, s0-s3}, 64",
  (0x8, 0b10, true, false) <-> "{ra, s0-s3}, 80",
  (0x8, 0b10, false,true)  <-> "{ra, s0-s3}, -64",
  (0x8, 0b10, false,false) <-> "{ra, s0-s3}, -80",
  (0x8, 0b11, true, true)  <-> "{ra, s0-s3}, 80",
  (0x8, 0b11, true, false) <-> "{ra, s0-s3}, 96",
  (0x8, 0b11, false,true)  <-> "{ra, s0-s3}, -80",
  (0x8, 0b11, false,false) <-> "{ra, s0-s3}, -96",

  (0x9, 0b00, true, true)  <-> "{ra, s0-s4}, 32",
  (0x9, 0b00, true, false) <-> "{ra, s0-s4}, 48",
  (0x9, 0b00, false,true)  <-> "{ra, s0-s4}, -32",
  (0x9, 0b00, false,false) <-> "{ra, s0-s4}, -48",
  (0x9, 0b01, true, true)  <-> "{ra, s0-s4}, 48",
  (0x9, 0b01, true, false) <-> "{ra, s0-s4}, 64",
  (0x9, 0b01, false,true)  <-> "{ra, s0-s4}, -48",
  (0x9, 0b01, false,false) <-> "{ra, s0-s4}, -64",
  (0x9, 0b10, true, true)  <-> "{ra, s0-s4}, 64",
  (0x9, 0b10, true, false) <-> "{ra, s0-s4}, 80",
  (0x9, 0b10, false,true)  <-> "{ra, s0-s4}, -64",
  (0x9, 0b10, false,false) <-> "{ra, s0-s4}, -80",
  (0x9, 0b11, true, true)  <-> "{ra, s0-s4}, 80",
  (0x9, 0b11, true, false) <-> "{ra, s0-s4}, 96",
  (0x9, 0b11, false,true)  <-> "{ra, s0-s4}, -80",
  (0x9, 0b11, false,false) <-> "{ra, s0-s4}, -96",

  (0xa, 0b00, true, true)  <-> "{ra, s0-s5}, 32",
  (0xa, 0b00, true, false) <-> "{ra, s0-s5}, 48",
  (0xa, 0b00, false,true)  <-> "{ra, s0-s5}, -32",
  (0xa, 0b00, false,false) <-> "{ra, s0-s5}, -48",
  (0xa, 0b01, true, true)  <-> "{ra, s0-s5}, 48",
  (0xa, 0b01, true, false) <-> "{ra, s0-s5}, 64",
  (0xa, 0b01, false,true)  <-> "{ra, s0-s5}, -48",
  (0xa, 0b01, false,false) <-> "{ra, s0-s5}, -64",
  (0xa, 0b10, true, true)  <-> "{ra, s0-s5}, 64",
  (0xa, 0b10, true, false) <-> "{ra, s0-s5}, 80",
  (0xa, 0b10, false,true)  <-> "{ra, s0-s5}, -64",
  (0xa, 0b10, false,false) <-> "{ra, s0-s5}, -80",
  (0xa, 0b11, true, true)  <-> "{ra, s0-s5}, 80",
  (0xa, 0b11, true, false) <-> "{ra, s0-s5}, 96",
  (0xa, 0b11, false,true)  <-> "{ra, s0-s5}, -80",
  (0xa, 0b11, false,false) <-> "{ra, s0-s5}, -96",

  (0xb, 0b00, true, true)  <-> "{ra, s0-s6}, 32",
  (0xb, 0b00, true, false) <-> "{ra, s0-s6}, 48",
  (0xb, 0b00, false,true)  <-> "{ra, s0-s6}, -32",
  (0xb, 0b00, false,false) <-> "{ra, s0-s6}, -48",
  (0xb, 0b01, true, true)  <-> "{ra, s0-s6}, 48",
  (0xb, 0b01, true, false) <-> "{ra, s0-s6}, 64",
  (0xb, 0b01, false,true)  <-> "{ra, s0-s6}, -48",
  (0xb, 0b01, false,false) <-> "{ra, s0-s6}, -64",
  (0xb, 0b10, true, true)  <-> "{ra, s0-s6}, 64",
  (0xb, 0b10, true, false) <-> "{ra, s0-s6}, 80",
  (0xb, 0b10, false,true)  <-> "{ra, s0-s6}, -64",
  (0xb, 0b10, false,false) <-> "{ra, s0-s6}, -80",
  (0xb, 0b11, true, true)  <-> "{ra, s0-s6}, 80",
  (0xb, 0b11, true, false) <-> "{ra, s0-s6}, 96",
  (0xb, 0b11, false,true)  <-> "{ra, s0-s6}, -80",
  (0xb, 0b11, false,false) <-> "{ra, s0-s6}, -96",

  (0xc, 0b00, true, true)  <-> "{ra, s0-s7}, 48",
  (0xc, 0b00, true, false) <-> "{ra, s0-s7}, 64",
  (0xc, 0b00, false,true)  <-> "{ra, s0-s7}, -48",
  (0xc, 0b00, false,false) <-> "{ra, s0-s7}, -64",
  (0xc, 0b01, true, true)  <-> "{ra, s0-s7}, 64",
  (0xc, 0b01, true, false) <-> "{ra, s0-s7}, 80",
  (0xc, 0b01, false,true)  <-> "{ra, s0-s7}, -64",
  (0xc, 0b01, false,false) <-> "{ra, s0-s7}, -80",
  (0xc, 0b10, true, true)  <-> "{ra, s0-s7}, 80",
  (0xc, 0b10, true, false) <-> "{ra, s0-s7}, 96",
  (0xc, 0b10, false,true)  <-> "{ra, s0-s7}, -80",
  (0xc, 0b10, false,false) <-> "{ra, s0-s7}, -96",
  (0xc, 0b11, true, true)  <-> "{ra, s0-s7}, 96",
  (0xc, 0b11, true, false) <-> "{ra, s0-s7}, 112",
  (0xc, 0b11, false,true)  <-> "{ra, s0-s7}, -96",
  (0xc, 0b11, false,false )<-> "{ra, s0-s7}, -112",

  (0xd, 0b00, true, true)  <-> "{ra, s0-s8}, 48",
  (0xd, 0b00, true, false) <-> "{ra, s0-s8}, 64",
  (0xd, 0b00, false,true)  <-> "{ra, s0-s8}, -48",
  (0xd, 0b00, false,false) <-> "{ra, s0-s8}, -64",
  (0xd, 0b01, true, true)  <-> "{ra, s0-s8}, 64",
  (0xd, 0b01, true, false) <-> "{ra, s0-s8}, 80",
  (0xd, 0b01, false,true)  <-> "{ra, s0-s8}, -64",
  (0xd, 0b01, false,false) <-> "{ra, s0-s8}, -80",
  (0xd, 0b10, true, true)  <-> "{ra, s0-s8}, 80",
  (0xd, 0b10, true, false) <-> "{ra, s0-s8}, 96",
  (0xd, 0b10, false,true)  <-> "{ra, s0-s8}, -80",
  (0xd, 0b10, false,false) <-> "{ra, s0-s8}, -96",
  (0xd, 0b11, true, true)  <-> "{ra, s0-s8}, 96",
  (0xd, 0b11, true, false) <-> "{ra, s0-s8}, 112",
  (0xd, 0b11, false,true)  <-> "{ra, s0-s8}, -96",
  (0xd, 0b11, false,false) <-> "{ra, s0-s8}, -112",

  (0xe, 0b00, true, true)  <-> "{ra, s0-s9}, 48",
  (0xe, 0b00, true, false) <-> "{ra, s0-s9}, 64",
  (0xe, 0b00, false,true)  <-> "{ra, s0-s9}, -48",
  (0xe, 0b00, false,false) <-> "{ra, s0-s9}, -64",
  (0xe, 0b01, true, true)  <-> "{ra, s0-s9}, 64",
  (0xe, 0b01, true, false) <-> "{ra, s0-s9}, 80",
  (0xe, 0b01, false,true)  <-> "{ra, s0-s9}, -64",
  (0xe, 0b01, false,false) <-> "{ra, s0-s9}, -80",
  (0xe, 0b10, true, true)  <-> "{ra, s0-s9}, 80",
  (0xe, 0b10, true, false) <-> "{ra, s0-s9}, 96",
  (0xe, 0b10, false,true)  <-> "{ra, s0-s9}, -80",
  (0xe, 0b10, false,false) <-> "{ra, s0-s9}, -96",
  (0xe, 0b11, true, true)  <-> "{ra, s0-s9}, 96",
  (0xe, 0b11, true, false) <-> "{ra, s0-s9}, 112",
  (0xe, 0b11, false,true)  <-> "{ra, s0-s9}, -96",
  (0xe, 0b11, false,false) <-> "{ra, s0-s9}, -112",

  (0xf, 0b00, true, true)  <-> "{ra, s0-11}, 64",
  (0xf, 0b00, true, false) <-> "{ra, s0-11}, 80",
  (0xf, 0b00, false,true)  <-> "{ra, s0-11}, -64",
  (0xf, 0b00, false,false) <-> "{ra, s0-11}, -80",
  (0xf, 0b01, true, true)  <-> "{ra, s0-11}, 80",
  (0xf, 0b01, true, false) <-> "{ra, s0-11}, 96",
  (0xf, 0b01, false,true)  <-> "{ra, s0-11}, -80",
  (0xf, 0b01, false,false) <-> "{ra, s0-11}, -96",
  (0xf, 0b10, true, true)  <-> "{ra, s0-11}, 96",
  (0xf, 0b10, true, false) <-> "{ra, s0-11}, 112",
  (0xf, 0b10, false,true)  <-> "{ra, s0-11}, -96",
  (0xf, 0b10, false,false) <-> "{ra, s0-11}, -112",
  (0xf, 0b11, true, true)  <-> "{ra, s0-11}, 112",
  (0xf, 0b11, true, false) <-> "{ra, s0-11}, 128",
  (0xf, 0b11, false,true)  <-> "{ra, s0-11}, -112",
  (0xf, 0b11, false,false) <-> "{ra, s0-11}, -128",
}

function get_stack_adj_base(rlist : bits(4)) -> int = {
  if(xlen == 32) then
    match(rlist) {
        0b0100 => 16,
        0b0101 => 16,
        0b0110 => 16,
        0b0111 => 16,
        0b1000 => 32,
        0b1001 => 32,
        0b1010 => 32,
        0b1011 => 32,
        0b1100 => 48,
        0b1101 => 48,
        0b1110 => 48,
        0b1111 => 64,
        _ => internal_error(__FILE__, __LINE__, "Unsupported rlist: " ^ bits_str(rlist))
    }
  else {
    match(rlist) {
        0b0100 => 16,
        0b0101 => 16,
        0b0110 => 32,
        0b0111 => 32,
        0b1000 => 48,
        0b1001 => 48,
        0b1010 => 64,
        0b1011 => 64,
        0b1100 => 80,
        0b1101 => 80,
        0b1110 => 96,
        0b1111 => 112,
        _ => internal_error(__FILE__, __LINE__, "Unsupported rlist: " ^ bits_str(rlist))
    }
  }
}

mapping reg_list : bits(4) <-> string = {
  0b0100     <-> "ra",
  0b0101     <-> "ra, s0",
  0b0110     <-> "ra, s0-s1",
  0b0111     <-> "ra, s0-s2",
  0b1000     <-> "ra, s0-s3",
  0b1001     <-> "ra, s0-s4",
  0b1010     <-> "ra, s0-s5",
  0b1011     <-> "ra, s0-s6",
  0b1100     <-> "ra, s0-s7",
  0b1101     <-> "ra, s0-s8",
  0b1110     <-> "ra, s0-s9",
  0b1111     <-> "ra, s0-s11",
}

mapping rlist_to_int : bits(4) <-> int = {
  0b0000     <-> 0,
  0b0001     <-> 1,
  0b0010     <-> 2,
  0b0011     <-> 3,
  0b0100     <-> 4,
  0b0101     <-> 5,
  0b0110     <-> 6,
  0b0111     <-> 7,
  0b1000     <-> 8,
  0b1001     <-> 9,
  0b1010     <-> 10,
  0b1011     <-> 11,
  0b1100     <-> 12,
  0b1101     <-> 13,
  0b1110     <-> 14,
  0b1111     <-> 15,
}

mapping spimm_to_int : bits(2) <-> int = {
  0b00     <-> 0,
  0b01     <-> 1,
  0b10     <-> 2,
  0b11     <-> 3,
}

function zcmp_regmask(rlist : bits(4)) -> vector(32, bool) = {
  var mask : vector(32, bool) = undefined;

  if(unsigned(rlist) >= unsigned(0b100)) then {
    mask[1] = true
  };

  let rlist_num = rlist_to_int(rlist);

  foreach (i from 5 to rlist_num) {
    assert(i <= 15);
    if( (i - 5) < 2 ) then
      mask[3 + i] = true
    else {
      mask[11 + i] = true
    };
  };

  if(rlist == zero_extend(0xf)) then
    mask[27] = true;

  mask
}

enum clause extension = Ext_Zcmp
function clause extensionEnabled(Ext_Zcmp) = extensionEnabled(Ext_Zca) & extensionEnabled(Ext_Zcd) == false & (xlen == 32 | xlen == 64)

union clause ast = CM_PUSH : (bits(4), bits(2))

mapping clause encdec_compressed = CM_PUSH(rlist, spimm)   if extensionEnabled(Ext_Zcmp)
  <-> 0b101 @ 0b11000 @ rlist : bits(4) @ spimm : bits(2) @ 0b10    if extensionEnabled(Ext_Zcmp)

val process_cmpush : (bits(4), bits(2), word_width) -> Retired
function process_cmpush (rlist : bits(4), spimm : bits(2), width : word_width) = {
  let width_bytes = size_bytes(width);
  assert(width_bytes <= xlen_bytes);

  let addr = X(sp);
  let spimm_int = spimm_to_int(spimm);
  let stack_adj = negate_int(get_stack_adj_base(rlist) + spimm_int * 16);
  let new_sp = addr + to_bits(xlen, stack_adj);
  let mask = zcmp_regmask(rlist);
  let bytes = if sizeof(xlen) == 32 then 4 else 8;

  var imm : int = width_bytes;

  foreach (i from 31 downto 1) {
    if mask[i] then {
      match ext_data_get_addr(sp, to_bits(xlen, negate_int(imm)), Write(Data), xlen / 8) {
        Ext_DataAddr_Error(e)  => { ext_handle_data_check_error(e); return RETIRE_FAIL },
        Ext_DataAddr_OK(vaddr) =>
        if   check_misaligned(vaddr, width)
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
                      MemValue(true)  => { imm = imm + width_bytes },
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
  if (xlen == 32) then
    process_cmpush(rlist, spimm, WORD)
  else
    process_cmpush(rlist, spimm, DOUBLE)
}

mapping clause assembly = CM_PUSH(rlist, spimm) if (sizeof(xlen) == 32) <->
  "cm.push" ^ spc() ^ zcmp_assembly_mapping(rlist, spimm, false, true) if (sizeof(xlen) == 32)

mapping clause assembly = CM_PUSH(rlist, spimm) if (sizeof(xlen) == 64) <->
  "cm.push" ^ spc() ^ zcmp_assembly_mapping(rlist, spimm, false, false) if (sizeof(xlen) == 64)


union clause ast = CM_POP : (bits(4), bits(2))

mapping clause encdec_compressed = CM_POP(rlist, spimm)   if extensionEnabled(Ext_Zcmp)
  <-> 0b101 @ 0b11010 @ rlist : bits(4) @ spimm : bits(2) @ 0b10    if extensionEnabled(Ext_Zcmp)

val process_cmpop : (bits(4), bits(2), word_width, bool, bool) -> Retired
function process_cmpop (rlist : bits(4), spimm : bits(2), width : word_width, write_pc : bool, write_a0 : bool) = {
  let width_bytes = size_bytes(width);
  assert(width_bytes <= xlen_bytes);

  let addr = X(sp);
  let spimm_int = spimm_to_int(spimm);
  let stack_adj = get_stack_adj_base(rlist) + spimm_int * 16;
  let new_sp = addr + to_bits(xlen, stack_adj);
  let mask = zcmp_regmask(rlist);
  let bytes = if sizeof(xlen) == 32 then 4 else 8;

  X(sp) = new_sp;

  var imm : int = width_bytes;

  foreach (i from 31 downto 1) {
    if mask[i] then {
      match ext_data_get_addr(sp, to_bits(xlen, negate_int(imm)), Write(Data), xlen / 8) {
        Ext_DataAddr_Error(e)  => { ext_handle_data_check_error(e); return RETIRE_FAIL },
        Ext_DataAddr_OK(vaddr) =>
        if   check_misaligned(vaddr, width)
        then { handle_mem_exception(vaddr, E_SAMO_Addr_Align()); return RETIRE_FAIL }
        else match translateAddr(vaddr, Write(Data)) {
            TR_Failure(e, _)    => { handle_mem_exception(vaddr, e); return RETIRE_FAIL },
            TR_Address(paddr, _) => {
              match mem_read(Read(Data), paddr, width_bytes, false, false, false) {
                  MemException(e) => { handle_mem_exception(vaddr, e); return RETIRE_FAIL },
                  MemValue(v) => {
                  X(to_bits(5, i)) = extend_value(true, v);
                  imm = imm + width_bytes
                }
              }
            }
        }
      }
    }
  };

  // cm.popret write pc with ra.
  if write_pc then {
    let ra_val = X(to_bits(5, 1));
    set_next_pc(ra_val);
  };

  // cm.popretz write a0 with zero.
  if write_a0 then {
    let a0 : regidx = to_bits(5, 10);
    X(a0) = to_bits(xlen, 0);
  };

  RETIRE_SUCCESS
}

function clause execute (CM_POP(rlist, spimm)) = {
  if (xlen == 32) then
    process_cmpop(rlist, spimm, WORD, false, false)
  else
    process_cmpop(rlist, spimm, DOUBLE, false, false)
}

mapping clause assembly = CM_POP(rlist, spimm) if (sizeof(xlen) == 32) <->
  "cm.pop" ^ spc() ^ zcmp_assembly_mapping(rlist, spimm, true, true) if (sizeof(xlen) == 32)

mapping clause assembly = CM_POP(rlist, spimm) if (sizeof(xlen) == 64) <->
  "cm.pop" ^ spc() ^ zcmp_assembly_mapping(rlist, spimm, true, false) if (sizeof(xlen) == 64)


union clause ast = CM_POPRET : (bits(4), bits(2))

mapping clause encdec_compressed = CM_POPRET(rlist, spimm)   if extensionEnabled(Ext_Zcmp)
  <-> 0b101 @ 0b11110 @ rlist : bits(4) @ spimm : bits(2) @ 0b10    if extensionEnabled(Ext_Zcmp)

function clause execute (CM_POPRET(rlist, spimm)) = {
  if (xlen == 32) then
    process_cmpop(rlist, spimm, WORD, true, false)
  else
    process_cmpop(rlist, spimm, DOUBLE, true, false)
}

mapping clause assembly = CM_POPRET(rlist, spimm) if (sizeof(xlen) == 32) <->
  "cm.popret" ^ spc() ^ zcmp_assembly_mapping(rlist, spimm, true, true) if (sizeof(xlen) == 32)

mapping clause assembly = CM_POPRET(rlist, spimm) if (sizeof(xlen) == 64) <->
  "cm.popret" ^ spc() ^ zcmp_assembly_mapping(rlist, spimm, true, false) if (sizeof(xlen) == 64)


union clause ast = CM_POPRETZ : (bits(4), bits(2))

mapping clause encdec_compressed = CM_POPRETZ(rlist, spimm)   if extensionEnabled(Ext_Zcmp)
  <-> 0b101 @ 0b11100 @ rlist : bits(4) @ spimm : bits(2) @ 0b10    if extensionEnabled(Ext_Zcmp)

function clause execute (CM_POPRETZ(rlist, spimm)) = {
  if (xlen == 32) then
    process_cmpop(rlist, spimm, WORD, false, true)
  else
    process_cmpop(rlist, spimm, DOUBLE, false, true)
}
