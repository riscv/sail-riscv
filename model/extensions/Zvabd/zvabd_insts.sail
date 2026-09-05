// =======================================================================================
// This Sail RISC-V architecture model, comprising all files and
// directories except where otherwise noted is subject the BSD
// two-clause license in the LICENSE file.
//
// SPDX-License-Identifier: BSD-2-Clause
// =======================================================================================

function clause currentlyEnabled(Ext_Zvabd) = hartSupports(Ext_Zvabd) & currentlyEnabled(Ext_Zve32x)

// The widening `vwabda/vwabdau` instructions are defined for only SEW=8 and
// SEW=16; other element sizes are reserved encodings.
private function valid_zvwabda_sew(sew : sew_bitsize) -> bool = sew == 8 | sew == 16

// ****************************** OPMVV (vabd.vv / vabdu.vv) ********************************
union clause instruction = ZVABD_VV : (zvabd_vabd_func6, bits(1), vregidx, vregidx, vregidx)

mapping encdec_zvabd_vabd_func6 : zvabd_vabd_func6 <-> bits(6) = {
  VABD  <-> 0b010101,
  VABDU <-> 0b010110
}

$[wavedrom "funct6 _ _ _ OPMVV _ OP-V"]
mapping clause encdec = ZVABD_VV(funct6, vm, vs2, vs1, vd)
  <-> encdec_zvabd_vabd_func6(funct6) @ vm @ encdec_vreg(vs2) @ encdec_vreg(vs1) @ 0b010 @ encdec_vreg(vd) @ 0b1010111
  when currentlyEnabled(Ext_Zvabd) & (get_sew() <= 32 | (currentlyEnabled(Ext_Zve64x) & get_sew() <= 64))

function clause execute ZVABD_VV(funct6, vm, vs2, vs1, vd) = {
  let SEW      = get_sew();
  let LMUL_pow = get_lmul_pow();
  let num_elem = get_num_elem(LMUL_pow, SEW);

  if illegal_vstart(VSTART_ARITH, num_elem, LMUL_pow) |
     illegal_normal(vd, vm) |
     not(valid_vm_src_overlap(vm, vs1, SEW)) |
     not(valid_vm_src_overlap(vm, vs2, SEW))
  then return Illegal_Instruction();

  let 'n = num_elem;
  let 'm = SEW;

  let vm_val  : bits('n)             = read_vmask(num_elem, vm, zvreg);
  let vs1_val : vector('n, bits('m)) = read_vreg(num_elem, SEW, LMUL_pow, vs1);
  let vs2_val : vector('n, bits('m)) = read_vreg(num_elem, SEW, LMUL_pow, vs2);
  let vd_val  : vector('n, bits('m)) = read_vreg(num_elem, SEW, LMUL_pow, vd);

  let (initial_result, mask) : (vector('n, bits('m)), bits('n)) = init_masked_result(num_elem, SEW, LMUL_pow, vd_val, vm_val);
  var result = initial_result;

  foreach (i from 0 to (num_elem - 1)) {
    if mask[i] == 0b1 then {
      result[i] = match funct6 {
        VABD  => to_bits(SEW, abs_int(signed(vs2_val[i]) - signed(vs1_val[i]))),
        VABDU => to_bits(SEW, abs_int(unsigned(vs2_val[i]) - unsigned(vs1_val[i])))
      };
    }
  };

  write_vreg(num_elem, SEW, LMUL_pow, vd, result);
  set_vstart(zeros());
  RETIRE_SUCCESS
}

mapping vabd_vv_mnemonic : zvabd_vabd_func6 <-> string = {
  VABD  <-> "vabd.vv",
  VABDU <-> "vabdu.vv"
}

mapping clause assembly = ZVABD_VV(funct6, vm, vs2, vs1, vd)
  <-> vabd_vv_mnemonic(funct6) ^ spc() ^ vreg_name(vd) ^ sep() ^ vreg_name(vs2) ^ sep() ^ vreg_name(vs1) ^ maybe_vmask(vm)

// ****************************** OPMVX (vabd.vx / vabdu.vx) ********************************
union clause instruction = ZVABD_VX : (zvabd_vabd_func6, bits(1), vregidx, regidx, vregidx)

$[wavedrom "funct6 _ _ _ OPMVX _ OP-V"]
mapping clause encdec = ZVABD_VX(funct6, vm, vs2, rs1, vd)
  <-> encdec_zvabd_vabd_func6(funct6) @ vm @ encdec_vreg(vs2) @ encdec_reg(rs1) @ 0b110 @ encdec_vreg(vd) @ 0b1010111
  when currentlyEnabled(Ext_Zvabd) & (get_sew() <= 32 | (currentlyEnabled(Ext_Zve64x) & get_sew() <= 64))

function clause execute ZVABD_VX(funct6, vm, vs2, rs1, vd) = {
  let SEW      = get_sew();
  let LMUL_pow = get_lmul_pow();
  let num_elem = get_num_elem(LMUL_pow, SEW);

  if illegal_vstart(VSTART_ARITH, num_elem, LMUL_pow) |
     illegal_normal(vd, vm) |
     not(valid_vm_src_overlap(vm, vs2, SEW))
  then return Illegal_Instruction();

  let 'n = num_elem;
  let 'm = SEW;

  let vm_val  : bits('n)             = read_vmask(num_elem, vm, zvreg);
  let rs1_val : bits('m)             = get_scalar(rs1, SEW);
  let vs2_val : vector('n, bits('m)) = read_vreg(num_elem, SEW, LMUL_pow, vs2);
  let vd_val  : vector('n, bits('m)) = read_vreg(num_elem, SEW, LMUL_pow, vd);

  let (initial_result, mask) : (vector('n, bits('m)), bits('n)) = init_masked_result(num_elem, SEW, LMUL_pow, vd_val, vm_val);
  var result = initial_result;

  foreach (i from 0 to (num_elem - 1)) {
    if mask[i] == 0b1 then {
      result[i] = match funct6 {
        VABD  => to_bits(SEW, abs_int(signed(vs2_val[i]) - signed(rs1_val))),
        VABDU => to_bits(SEW, abs_int(unsigned(vs2_val[i]) - unsigned(rs1_val)))
      };
    }
  };

  write_vreg(num_elem, SEW, LMUL_pow, vd, result);
  set_vstart(zeros());
  RETIRE_SUCCESS
}

mapping vabd_vx_mnemonic : zvabd_vabd_func6 <-> string = {
  VABD  <-> "vabd.vx",
  VABDU <-> "vabdu.vx"
}

// `vabs.v vd, vs2` is a pseudoinstruction for `vabd.vx vd, vs2, x0`
// (abs(vs2 - x0) == abs(vs2)). Only the disassembly (forwards) direction is
// provided; the assembly direction still uses `vabd.vx vd, vs2, x0`.
mapping clause assembly =
  forwards ZVABD_VX(VABD, vm, vs2, rs1, vd) => "vabs.v" ^ spc() ^ vreg_name(vd) ^ sep() ^ vreg_name(vs2) ^ maybe_vmask(vm)
    when rs1 == zreg

mapping clause assembly = ZVABD_VX(funct6, vm, vs2, rs1, vd)
  <-> vabd_vx_mnemonic(funct6) ^ spc() ^ vreg_name(vd) ^ sep() ^ vreg_name(vs2) ^ sep() ^ reg_name(rs1) ^ maybe_vmask(vm)

// ************************** OPIVV (vwabda.vv / vwabdau.vv Widening) ***************************
union clause instruction = ZVWABDA_VV : (zvabd_vwabda_func6, bits(1), vregidx, vregidx, vregidx)

mapping encdec_zvabd_vwabda_func6 : zvabd_vwabda_func6 <-> bits(6) = {
  VWABDA  <-> 0b111101,
  VWABDAU <-> 0b111110
}

$[wavedrom "funct6 _ _ _ OPIVV _ OP-V"]
mapping clause encdec = ZVWABDA_VV(funct6, vm, vs2, vs1, vd)
  <-> encdec_zvabd_vwabda_func6(funct6) @ vm @ encdec_vreg(vs2) @ encdec_vreg(vs1) @ 0b000 @ encdec_vreg(vd) @ 0b1010111
  when currentlyEnabled(Ext_Zvabd) & valid_zvwabda_sew(get_sew())

function clause execute ZVWABDA_VV(funct6, vm, vs2, vs1, vd) = {
  let SEW      = get_sew();
  let LMUL_pow = get_lmul_pow();
  let num_elem = get_num_elem(LMUL_pow, SEW);
  let SEW_widen      = SEW * 2;
  let LMUL_pow_widen = LMUL_pow + 1;

  if illegal_vstart(VSTART_ARITH, num_elem, LMUL_pow) |
     illegal_variable_width(vd, vm, SEW_widen, LMUL_pow_widen) |
     not(valid_reg_overlap(vs1, vd, LMUL_pow, LMUL_pow_widen)) |
     not(valid_reg_overlap(vs2, vd, LMUL_pow, LMUL_pow_widen)) |
     // vd is also a source register
     not(valid_src_overlap(vs1, SEW, LMUL_pow, vd, SEW_widen, LMUL_pow_widen)) |
     not(valid_src_overlap(vs2, SEW, LMUL_pow, vd, SEW_widen, LMUL_pow_widen)) |
     not(valid_vm_src_overlap(vm, vs1, SEW)) |
     not(valid_vm_src_overlap(vm, vs2, SEW))
  then return Illegal_Instruction();

  assert(SEW_widen == 16 | SEW_widen == 32);
  assert(LMUL_pow_widen <= 3);

  let 'n = num_elem;
  let 'm = SEW;
  let 'o = SEW_widen;

  let vm_val  : bits('n)             = read_vmask(num_elem, vm, zvreg);
  let vd_val  : vector('n, bits('o)) = read_vreg(num_elem, SEW_widen, LMUL_pow_widen, vd);
  let vs1_val : vector('n, bits('m)) = read_vreg(num_elem, SEW, LMUL_pow, vs1);
  let vs2_val : vector('n, bits('m)) = read_vreg(num_elem, SEW, LMUL_pow, vs2);

  let (initial_result, mask) : (vector('n, bits('o)), bits('n)) = init_masked_result(num_elem, SEW_widen, LMUL_pow_widen, vd_val, vm_val);
  var result = initial_result;

  foreach (i from 0 to (num_elem - 1)) {
    if mask[i] == 0b1 then {
      result[i] = match funct6 {
        VWABDA  => {
          let diff = signed(vs2_val[i]) - signed(vs1_val[i]);
          to_bits_truncate(SEW_widen, signed(vd_val[i]) + abs_int(diff))
        },
        VWABDAU => {
          let abs_diff = if unsigned(vs2_val[i]) >= unsigned(vs1_val[i])
                         then unsigned(vs2_val[i] - vs1_val[i])
                         else unsigned(vs1_val[i] - vs2_val[i]);
          to_bits_truncate(SEW_widen, unsigned(vd_val[i]) + abs_diff)
        }
      };
    }
  };

  write_vreg(num_elem, SEW_widen, LMUL_pow_widen, vd, result);
  set_vstart(zeros());
  RETIRE_SUCCESS
}

mapping vwabda_vv_mnemonic : zvabd_vwabda_func6 <-> string = {
  VWABDA  <-> "vwabda.vv",
  VWABDAU <-> "vwabdau.vv"
}

mapping clause assembly = ZVWABDA_VV(funct6, vm, vs2, vs1, vd)
  <-> vwabda_vv_mnemonic(funct6) ^ spc() ^ vreg_name(vd) ^ sep() ^ vreg_name(vs2) ^ sep() ^ vreg_name(vs1) ^ maybe_vmask(vm)

// ************************** OPIVX (vwabda.vx / vwabdau.vx Widening) ***************************
union clause instruction = ZVWABDA_VX : (zvabd_vwabda_func6, bits(1), vregidx, regidx, vregidx)

$[wavedrom "funct6 _ _ _ OPIVX _ OP-V"]
mapping clause encdec = ZVWABDA_VX(funct6, vm, vs2, rs1, vd)
  <-> encdec_zvabd_vwabda_func6(funct6) @ vm @ encdec_vreg(vs2) @ encdec_reg(rs1) @ 0b100 @ encdec_vreg(vd) @ 0b1010111
  when currentlyEnabled(Ext_Zvabd) & valid_zvwabda_sew(get_sew())

function clause execute ZVWABDA_VX(funct6, vm, vs2, rs1, vd) = {
  let SEW      = get_sew();
  let LMUL_pow = get_lmul_pow();
  let num_elem = get_num_elem(LMUL_pow, SEW);
  let SEW_widen      = SEW * 2;
  let LMUL_pow_widen = LMUL_pow + 1;

  if illegal_vstart(VSTART_ARITH, num_elem, LMUL_pow) |
     illegal_variable_width(vd, vm, SEW_widen, LMUL_pow_widen) |
     not(valid_reg_overlap(vs2, vd, LMUL_pow, LMUL_pow_widen)) |
     // vd is also a source register
     not(valid_src_overlap(vs2, SEW, LMUL_pow, vd, SEW_widen, LMUL_pow_widen)) |
     not(valid_vm_src_overlap(vm, vs2, SEW))
  then return Illegal_Instruction();

  assert(SEW_widen == 16 | SEW_widen == 32);
  assert(LMUL_pow_widen <= 3);

  let 'n = num_elem;
  let 'm = SEW;
  let 'o = SEW_widen;

  let vm_val  : bits('n)             = read_vmask(num_elem, vm, zvreg);
  let vd_val  : vector('n, bits('o)) = read_vreg(num_elem, SEW_widen, LMUL_pow_widen, vd);
  let rs1_val : bits('m)             = get_scalar(rs1, SEW);
  let vs2_val : vector('n, bits('m)) = read_vreg(num_elem, SEW, LMUL_pow, vs2);

  let (initial_result, mask) : (vector('n, bits('o)), bits('n)) = init_masked_result(num_elem, SEW_widen, LMUL_pow_widen, vd_val, vm_val);
  var result = initial_result;

  foreach (i from 0 to (num_elem - 1)) {
    if mask[i] == 0b1 then {
      result[i] = match funct6 {
        VWABDA  => {
          let diff = signed(vs2_val[i]) - signed(rs1_val);
          to_bits_truncate(SEW_widen, signed(vd_val[i]) + abs_int(diff))
        },
        VWABDAU => {
          let abs_diff = if unsigned(vs2_val[i]) >= unsigned(rs1_val)
                         then unsigned(vs2_val[i] - rs1_val)
                         else unsigned(rs1_val - vs2_val[i]);
          to_bits_truncate(SEW_widen, unsigned(vd_val[i]) + abs_diff)
        }
      };
    }
  };

  write_vreg(num_elem, SEW_widen, LMUL_pow_widen, vd, result);
  set_vstart(zeros());
  RETIRE_SUCCESS
}

mapping vwabda_vx_mnemonic : zvabd_vwabda_func6 <-> string = {
  VWABDA  <-> "vwabda.vx",
  VWABDAU <-> "vwabdau.vx"
}

mapping clause assembly = ZVWABDA_VX(funct6, vm, vs2, rs1, vd)
  <-> vwabda_vx_mnemonic(funct6) ^ spc() ^ vreg_name(vd) ^ sep() ^ vreg_name(vs2) ^ sep() ^ reg_name(rs1) ^ maybe_vmask(vm)
