/*=======================================================================================*/
/*  This Sail RISC-V architecture model, comprising all files and                        */
/*  directories except where otherwise noted is subject the BSD                          */
/*  two-clause license in the LICENSE file.                                              */
/*                                                                                       */
/*  SPDX-License-Identifier: BSD-2-Clause                                                */
/*=======================================================================================*/

function clause currentlyEnabled(Ext_Zcmp) = hartSupports(Ext_Zcmp) & currentlyEnabled(Ext_Zca) & not(currentlyEnabled(Ext_Zcd)) & (xlen == 32 | xlen == 64)

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

function get_stack_adj_base(rlist : bits(4)) -> int = {
  if xlen == 32 then
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
    /* Backward mapping for cm.push, cm.pop, cm.popret, and cm.popretz */
    /* is not implemented due to the complexity of parsing these instructions. */
    not_implemented("Backward mapping for (cm.push/cm.pop/cm.popret/cm.popretz) is not implemented.");
  },
}

function zcmp_regmask(rlist : bits(4)) -> bits(32) = {
  var mask : bits(32) = zeros();

  if rlist >=_u 0b0100 then mask[1] = bitone;

  foreach (i from 5 to unsigned(rlist)) {
    assert(i <= 15);
    if i - 5 < 2
    then mask[ 3 + i] = bitone
    else mask[11 + i] = bitone
  };

  if rlist == zero_extend(0xf) then mask[27] = bitone;

  mask
}

union clause ast = CMPP : (cmop_zcmp, bits(4), bits(2))

mapping clause encdec_compressed = CMPP(RISCV_CM_POP, rlist, spimm)
  <-> 0b101 @ 0b11010 @ rlist : bits(4) @ spimm : bits(2) @ 0b10
  when currentlyEnabled(Ext_Zcmp) & rlist >=_u 0b0100

mapping clause encdec_compressed = CMPP(RISCV_CM_POPRET, rlist, spimm)
  <-> 0b101 @ 0b11110 @ rlist : bits(4) @ spimm : bits(2) @ 0b10
  when currentlyEnabled(Ext_Zcmp) & rlist >=_u 0b0100

mapping clause encdec_compressed = CMPP(RISCV_CM_POPRETZ, rlist, spimm)
  <-> 0b101 @ 0b11100 @ rlist : bits(4) @ spimm : bits(2) @ 0b10
  when currentlyEnabled(Ext_Zcmp) & rlist >=_u 0b0100

mapping zcmp_mnemonic : cmop_zcmp <-> string = {
  RISCV_CM_POP     <-> "cm.pop",
  RISCV_CM_POPRET  <-> "cm.popret",
  RISCV_CM_POPRETZ <-> "cm.popretz",
}

mapping clause assembly = CMPP(op, rlist, spimm)
  <->  zcmp_mnemonic(op) ^ spc() ^ zcmp_assembly_mapping(rlist, spimm, false)

function clause execute (CMPP(op, rlist, spimm)) = {
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

  if op == RISCV_CM_POPRETZ then X(a0) = zeros();
  X(sp) = new_sp;
  if op == RISCV_CM_POPRET | op == RISCV_CM_POPRETZ then set_next_pc(X(ra));
  RETIRE_SUCCESS
}

/* ****************************************************************** */
union clause ast = CM_PUSH : (bits(4), bits(2))

mapping clause encdec_compressed = CM_PUSH(rlist, spimm)
  <-> 0b101 @ 0b11000 @ rlist : bits(4) @ spimm : bits(2) @ 0b10
  when currentlyEnabled(Ext_Zcmp) & rlist >=_u 0b0100

function clause execute (CM_PUSH(rlist, spimm)) = {
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

mapping clause assembly = CM_PUSH(rlist, spimm)
  <-> "cm.push" ^ spc() ^ zcmp_assembly_mapping(rlist, spimm, false)
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
  when currentlyEnabled(Ext_Zcmp)

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
  when currentlyEnabled(Ext_Zcmp) & r1s' != r2s'

function clause execute (CM_MVSA01(r1s', r2s')) = {
  X(rns_to_regidx(r1s')) = X(a0);
  X(rns_to_regidx(r2s')) = X(a1);
  RETIRE_SUCCESS
}

mapping clause assembly = CM_MVSA01(r1s', r2s')
  <-> "cm.mvsa01" ^ spc() ^ creg_zcmp_name(r1s') ^ sep() ^ creg_zcmp_name(r2s')
