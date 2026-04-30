// =======================================================================================
// This Sail RISC-V architecture model, comprising all files and
// directories except where otherwise noted is subject the BSD
// two-clause license in the LICENSE file.
//
// SPDX-License-Identifier: BSD-2-Clause
// =======================================================================================

function clause currentlyEnabled(Ext_Zvabd) = hartSupports(Ext_Zvabd) & currentlyEnabled(Ext_Zve32x)

// Since the targeted use cases are mostly based on 8-bit and 16-bit integer,
// `vabd/vabdu/vwabda/vwabdau` are designed for only SEW=8 and SEW=16.
// Additionally, `vabs` is considered to support all the element sizes
// as it is quite common used and simple to implement.
private function valid_zvabd_sew(sew : sew_bitsize) -> bool = sew == 8 | sew == 16

union clause instruction = VABS_V : (bits(1), vregidx, vregidx)

$[wavedrom "funct6 _ _ _ OPMVV _ OP-V"]
mapping clause encdec = VABS_V(vm, vs2, vd)
  <-> 0b010010 @ vm @ encdec_vreg(vs2) @ 0b10000 @ 0b010 @ encdec_vreg(vd) @ 0b1010111
  when currentlyEnabled(Ext_Zvabd)
    & ((get_sew() <= 32) | (currentlyEnabled(Ext_Zve64x) & get_sew() <= 64))

function clause execute VABS_V(vm, vs2, vd) = {
  let SEW      = get_sew();
  let LMUL_pow = get_lmul_pow();
  let num_elem = get_num_elem(LMUL_pow, SEW);

  if illegal_normal(vd, vm) then return Illegal_Instruction();

  let 'n = num_elem;
  let 'm = SEW;

  let vm_val  : bits('n)             = read_vmask(num_elem, vm, zvreg);
  let vs2_val : vector('n, bits('m)) = read_vreg(num_elem, SEW, LMUL_pow, vs2);
  let vd_val  : vector('n, bits('m)) = read_vreg(num_elem, SEW, LMUL_pow, vd);

  let (initial_result, mask) : (vector('n, bits('m)), bits('n)) = match init_masked_result(num_elem, SEW, LMUL_pow, vd_val, vm_val) {
    Ok(v)   => v,
    Err(()) => return Illegal_Instruction()
  };
  var result = initial_result;

  foreach (i from 0 to (num_elem - 1)) {
    if mask[i] == 0b1 then
      result[i] = to_bits(SEW, abs_int(signed(vs2_val[i])))
  };

  write_vreg(num_elem, SEW, LMUL_pow, vd, result);
  set_vstart(zeros());
  RETIRE_SUCCESS
}

mapping clause assembly = VABS_V(vm, vs2, vd)
  <-> "vabs.v" ^ spc() ^ vreg_name(vd) ^ sep() ^ vreg_name(vs2) ^ maybe_vmask(vm)

union clause instruction = ZVABDTYPE : (zvabd_vabd_func6, bits(1), vregidx, vregidx, vregidx)

mapping encdec_zvabd_vabd_func6 : zvabd_vabd_func6 <-> bits(6) = {
  VV_VABD  <-> 0b010001,
  VV_VABDU <-> 0b010011
}

$[wavedrom "funct6 _ _ _ OPMVV _ OP-V"]
mapping clause encdec = ZVABDTYPE(funct6, vm, vs2, vs1, vd)
  <-> encdec_zvabd_vabd_func6(funct6) @ vm @ encdec_vreg(vs2) @ encdec_vreg(vs1) @ 0b010 @ encdec_vreg(vd) @ 0b1010111
  when currentlyEnabled(Ext_Zvabd) & valid_zvabd_sew(get_sew())

function clause execute ZVABDTYPE(funct6, vm, vs2, vs1, vd) = {
  let SEW      = get_sew();
  let LMUL_pow = get_lmul_pow();
  let num_elem = get_num_elem(LMUL_pow, SEW);

  if illegal_normal(vd, vm) then return Illegal_Instruction();

  let 'n = num_elem;
  let 'm = SEW;

  let vm_val  : bits('n)             = read_vmask(num_elem, vm, zvreg);
  let vs1_val : vector('n, bits('m)) = read_vreg(num_elem, SEW, LMUL_pow, vs1);
  let vs2_val : vector('n, bits('m)) = read_vreg(num_elem, SEW, LMUL_pow, vs2);
  let vd_val  : vector('n, bits('m)) = read_vreg(num_elem, SEW, LMUL_pow, vd);

  let (initial_result, mask) : (vector('n, bits('m)), bits('n)) = match init_masked_result(num_elem, SEW, LMUL_pow, vd_val, vm_val) {
    Ok(v)   => v,
    Err(()) => return Illegal_Instruction()
  };
  var result = initial_result;

  foreach (i from 0 to (num_elem - 1)) {
    if mask[i] == 0b1 then {
      result[i] = match funct6 {
        VV_VABD  => to_bits(SEW, abs_int(signed(vs2_val[i]) - signed(vs1_val[i]))),
        VV_VABDU => to_bits(SEW, abs_int(unsigned(vs2_val[i]) - unsigned(vs1_val[i])))
      };
    }
  };

  write_vreg(num_elem, SEW, LMUL_pow, vd, result);
  set_vstart(zeros());
  RETIRE_SUCCESS
}

mapping vabd_mnemonic : zvabd_vabd_func6 <-> string = {
  VV_VABD  <-> "vabd.vv",
  VV_VABDU <-> "vabdu.vv"
}

mapping clause assembly = ZVABDTYPE(funct6, vm, vs2, vs1, vd)
  <-> vabd_mnemonic(funct6) ^ spc() ^ vreg_name(vd) ^ sep() ^ vreg_name(vs2) ^ sep() ^ vreg_name(vs1) ^ maybe_vmask(vm)

union clause instruction = ZVWABDATYPE : (zvabd_vwabda_func6, bits(1), vregidx, vregidx, vregidx)

mapping encdec_zvabd_vwabda_func6 : zvabd_vwabda_func6 <-> bits(6) = {
  VV_VWABDA  <-> 0b010101,
  VV_VWABDAU <-> 0b010110
}

$[wavedrom "funct6 _ _ _ OPMVV _ OP-V"]
mapping clause encdec = ZVWABDATYPE(funct6, vm, vs2, vs1, vd)
  <-> encdec_zvabd_vwabda_func6(funct6) @ vm @ encdec_vreg(vs2) @ encdec_vreg(vs1) @ 0b010 @ encdec_vreg(vd) @ 0b1010111
  when currentlyEnabled(Ext_Zvabd) & valid_zvabd_sew(get_sew())

function clause execute ZVWABDATYPE(funct6, vm, vs2, vs1, vd) = {
  let SEW      = get_sew();
  let LMUL_pow = get_lmul_pow();
  let num_elem = get_num_elem(LMUL_pow, SEW);
  let SEW_widen      = SEW * 2;
  let LMUL_pow_widen = LMUL_pow + 1;

  if  illegal_variable_width(vd, vm, SEW_widen, LMUL_pow_widen) |
      not(valid_reg_overlap(vs1, vd, LMUL_pow, LMUL_pow_widen)) |
      not(valid_reg_overlap(vs2, vd, LMUL_pow, LMUL_pow_widen))
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

  let (initial_result, mask) : (vector('n, bits('o)), bits('n)) = match init_masked_result(num_elem, SEW_widen, LMUL_pow_widen, vd_val, vm_val) {
    Ok(v)   => v,
    Err(()) => return Illegal_Instruction()
  };
  var result = initial_result;

  foreach (i from 0 to (num_elem - 1)) {
    if mask[i] == 0b1 then {
      result[i] = match funct6 {
        VV_VWABDA  => {
          let diff = signed(vs2_val[i]) - signed(vs1_val[i]);
          to_bits_unsafe(SEW_widen, signed(vd_val[i]) + abs_int(diff))
        },
        VV_VWABDAU => {
          let abs_diff = if unsigned(vs2_val[i]) >= unsigned(vs1_val[i])
                         then unsigned(vs2_val[i] - vs1_val[i])
                         else unsigned(vs1_val[i] - vs2_val[i]);
          to_bits_unsafe(SEW_widen, unsigned(vd_val[i]) + abs_diff)
        }
      };
    }
  };

  write_vreg(num_elem, SEW_widen, LMUL_pow_widen, vd, result);
  set_vstart(zeros());
  RETIRE_SUCCESS
}

mapping vwabda_mnemonic : zvabd_vwabda_func6 <-> string = {
  VV_VWABDA  <-> "vwabda.vv",
  VV_VWABDAU <-> "vwabdau.vv"
}

mapping clause assembly = ZVWABDATYPE(funct6, vm, vs2, vs1, vd)
  <-> vwabda_mnemonic(funct6) ^ spc() ^ vreg_name(vd) ^ sep() ^ vreg_name(vs2) ^ sep() ^ vreg_name(vs1) ^ maybe_vmask(vm)
