/*=======================================================================================*/
/*  This Sail RISC-V architecture model, comprising all files and                        */
/*  directories except where otherwise noted is subject the BSD                          */
/*  two-clause license in the LICENSE file.                                              */
/*                                                                                       */
/*  SPDX-License-Identifier: BSD-2-Clause                                                */
/*=======================================================================================*/

function clause currentlyEnabled(Ext_Zcmp) = hartSupports(Ext_Zcmp) & currentlyEnabled(Ext_Zca) & not(currentlyEnabled(Ext_Zcd))


mapping zcmp_abi_assembly_rlist : bits(4) <-> string = {
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
  0xf <-> "ra" ^ sep() ^ "s0-s11",
}

mapping zcmp_arch_assembly_rlist : bits(4) <-> string = {
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

mapping zcmp_assembly_rlist : bits(4) <-> string = {
  i if get_config_use_abi_names()      <-> zcmp_abi_assembly_rlist(i),
  i if not(get_config_use_abi_names()) <-> zcmp_arch_assembly_rlist(i),
}

mapping zcmp_rlist_regmask : bits(4) <-> bits(32) = {
  0x4 <-> 0b00000000000000000000000000000010,
  0x5 <-> 0b00000000000000000000000100000010,
  0x6 <-> 0b00000000000000000000001100000010,
  0x7 <-> 0b00000000000001000000001100000010,
  0x8 <-> 0b00000000000011000000001100000010,
  0x9 <-> 0b00000000000111000000001100000010,
  0xA <-> 0b00000000001111000000001100000010,
  0xB <-> 0b00000000011111000000001100000010,
  0xC <-> 0b00000000111111000000001100000010,
  0xD <-> 0b00000001111111000000001100000010,
  0xE <-> 0b00000011111111000000001100000010,
  0xF <-> 0b00001111111111000000001100000010,
}

function get_stack_adj(rlist : bits(4), spimm : bits(2)) -> int = {
  let num_regs = count_ones(zcmp_rlist_regmask(rlist));
  let chunks_for_regs = (num_regs * xlen_bytes + 15) / 16;
  (chunks_for_regs + unsigned(spimm)) * 16
}

mapping zcmp_assembly_map : (bits(4), bits(2), bool) <-> string = {
  forwards (rlist, spimm, is_negative) => {
    let stack_adj = get_stack_adj(rlist, spimm);
    let sign = if is_negative then "-" else "";

    "{" ^ zcmp_assembly_rlist(rlist) ^ "}" ^ sep() ^ sign ^ dec_str(stack_adj)
  },
  backwards str_input => {
    /* Backwards mapping for cm.push, cm.pop, cm.popret, and cm.popretz */
    /* is not implemented due to the complexity of parsing these instructions. */
    not_implemented("Backwards mapping for (cm.push/cm.pop/cm.popret/cm.popretz) is not implemented.");
  },
}

union clause ast = CM_PUSH : (bits(4), bits(2))

mapping clause encdec_compressed = CM_PUSH(rlist, spimm)
  <-> 0b101 @ 0b11000 @ rlist : bits(4) @ spimm : bits(2) @ 0b10
  when currentlyEnabled(Ext_Zcmp) & rlist >=_u 0b0100

function clause execute (CM_PUSH(rlist, spimm)) = {
  let addr      = X(sp);
  let stack_adj = get_stack_adj(rlist, spimm);
  let new_sp    = addr - stack_adj;

  let reg_mask  = zcmp_rlist_regmask(rlist);
  var sp_offset = negate_int(xlen_bytes);

  foreach (i from 31 downto 1) {
    if reg_mask[i] == bitone then {
      let offset = to_bits_truncate(xlen, sp_offset);
      let rs2    = Regidx(to_bits(5, i));
      let data   = X(rs2);
      match vmem_write(sp, offset, xlen_bytes, data, Write(Data), false, false, false) {
        Err(e) => ( return e ),
        Ok(_)  => { sp_offset = sp_offset - xlen_bytes }
      };
    }
  };

  X(sp) = new_sp;
  RETIRE_SUCCESS
}

mapping clause assembly = CM_PUSH(rlist, spimm)
  <-> "cm.push" ^ spc() ^ zcmp_assembly_map(rlist, spimm, true)

union clause ast = CMPP : (cmop_zcmp, bits(4), bits(2))

mapping encdec_cmop : cmop_zcmp <-> bits(5) = {
  CM_POP     <-> 0b11010,
  CM_POPRET  <-> 0b11110,
  CM_POPRETZ <-> 0b11100,
}

mapping clause encdec_compressed = CMPP(cmop, rlist, spimm)
  <-> 0b101 @ encdec_cmop(cmop) @ rlist : bits(4) @ spimm : bits(2) @ 0b10
  when currentlyEnabled(Ext_Zcmp) & rlist >=_u 0b0100

function clause execute (CMPP(cmop, rlist, spimm)) = {
  let addr      = X(sp);
  let stack_adj = get_stack_adj(rlist, spimm);
  let new_sp    = addr + stack_adj;

  let reg_mask = zcmp_rlist_regmask(rlist);
  var sp_offset : int = stack_adj - xlen_bytes;

  foreach (i from 31 downto 1) {
    if reg_mask[i] == bitone then {
      let offset = to_bits_truncate(xlen, sp_offset);
      let rd     = Regidx(to_bits(5, i));
      match vmem_read(sp, offset, xlen_bytes, Read(Data), false, false, false) {
        Err(e)   => { return e },
        Ok(data) => { X(rd) = data; sp_offset = sp_offset - xlen_bytes }
      };
    }
  };

  if cmop == CM_POPRETZ then X(a0) = zeros();
  X(sp) = new_sp;
  if cmop == CM_POPRET | cmop == CM_POPRETZ then set_next_pc(X(ra));
  RETIRE_SUCCESS
}

mapping zcmp_mnemonic : cmop_zcmp <-> string = {
  CM_POP     <-> "cm.pop",
  CM_POPRET  <-> "cm.popret",
  CM_POPRETZ <-> "cm.popretz",
}

mapping clause assembly = CMPP(cmop, rlist, spimm)
  <->  zcmp_mnemonic(cmop) ^ spc() ^ zcmp_assembly_map(rlist, spimm, false)

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

union clause ast = CM_MVSA01 : (cregidx, cregidx)

mapping clause encdec_compressed = CM_MVSA01(r1s', r2s')
  <-> 0b101 @ 0b011 @ encdec_creg(r1s') @ 0b01 @ encdec_creg(r2s') @ 0b10
  when currentlyEnabled(Ext_Zcmp) & r1s' != r2s'

function clause execute (CM_MVSA01(r1s', r2s')) = {
  X(rns_to_regidx(r1s')) = X(a0);
  X(rns_to_regidx(r2s')) = X(a1);
  RETIRE_SUCCESS
}

mapping clause assembly = CM_MVSA01(r1s', r2s')
  <-> "cm.mvsa01" ^ spc() ^ creg_zcmp_name(r1s') ^ sep() ^ creg_zcmp_name(r2s')

union clause ast = CM_MVA01S : (cregidx, cregidx)

mapping clause encdec_compressed = CM_MVA01S(r1s', r2s')
  <-> 0b101 @ 0b011 @ encdec_creg(r1s') @ 0b11 @ encdec_creg(r2s') @ 0b10
  when currentlyEnabled(Ext_Zcmp)

function clause execute (CM_MVA01S(r1s', r2s')) = {
  X(a0) = X(rns_to_regidx(r1s'));
  X(a1) = X(rns_to_regidx(r2s'));
  RETIRE_SUCCESS
}

mapping clause assembly = CM_MVA01S(r1s', r2s')
  <-> "cm.mva01s" ^ spc() ^ creg_zcmp_name(r1s') ^ sep() ^ creg_zcmp_name(r2s')
