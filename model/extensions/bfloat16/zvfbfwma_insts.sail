//=======================================================================================
//  This Sail RISC-V architecture model, comprising all files and
//  directories except where otherwise noted is subject the BSD
//  two-clause license in the LICENSE file.
//
//  SPDX-License-Identifier: BSD-2-Clause
//=======================================================================================

function clause currentlyEnabled(Ext_Zvfbfwma) = hartSupports(Ext_Zvfbfwma) & currentlyEnabled(Ext_Zvfbfmin) & currentlyEnabled(Ext_Zfbfmin)

union clause instruction = VFWMACCBF16_VV : (bits(1), vregidx, vregidx, vregidx)

$[wavedrom "vfwmaccbf16 _ _ _ OPFVV _ OP-V"]
mapping clause encdec = VFWMACCBF16_VV(vm, vs2, vs1, vd)
  <-> 0b111011 @ vm @ encdec_vreg(vs2) @ encdec_vreg(vs1) @ 0b001 @ encdec_vreg(vd) @ 0b1010111
  when currentlyEnabled(Ext_Zvfbfwma) & get_sew() == 16

function clause execute VFWMACCBF16_VV(vm, vs2, vs1, vd) = {
  let rm_3b    = fcsr[FRM];
  let SEW      = get_sew();
  let LMUL_pow = get_lmul_pow();
  let num_elem = get_num_elem(LMUL_pow, SEW);
  let SEW_widen      = SEW * 2;
  let LMUL_pow_widen = LMUL_pow + 1;

  if  illegal_fp_variable_width(vd, vm, SEW, rm_3b, SEW_widen, LMUL_pow_widen) |
      not(valid_reg_overlap(vs1, vd, LMUL_pow, LMUL_pow_widen)) |
      not(valid_reg_overlap(vs2, vd, LMUL_pow, LMUL_pow_widen))
  then return Illegal_Instruction();

  assert(SEW == 16);
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
      result[i] = fp_muladd(rm_3b, bf16_to_f32_set_flags(vs2_val[i]), bf16_to_f32_set_flags(vs1_val[i]), vd_val[i]);
    }
  };

  write_vreg(num_elem, SEW_widen, LMUL_pow_widen, vd, result);
  set_vstart(zeros());
  RETIRE_SUCCESS
}

mapping clause assembly = VFWMACCBF16_VV(vm, vs2, vs1, vd)
  <-> "vfwmaccbf16.vv" ^ spc() ^ vreg_name(vd) ^ sep() ^ vreg_name(vs1) ^ spc() ^ vreg_name(vs2) ^ maybe_vmask(vm)

union clause instruction = VFWMACCBF16_VF : (bits(1), vregidx, fregidx, vregidx)

$[wavedrom "vfwmaccbf16 _ _ _ OPFVF _ OP-V"]
mapping clause encdec = VFWMACCBF16_VF(vm, vs2, rs1, vd)
  <-> 0b111011 @ vm @ encdec_vreg(vs2) @ encdec_freg(rs1) @ 0b101 @ encdec_vreg(vd) @ 0b1010111
  when currentlyEnabled(Ext_Zvfbfwma) & get_sew() == 16

function clause execute VFWMACCBF16_VF(vm, vs2, rs1, vd) = {
  let rm_3b    = fcsr[FRM];
  let SEW      = get_sew();
  let LMUL_pow = get_lmul_pow();
  let num_elem = get_num_elem(LMUL_pow, SEW);
  let SEW_widen      = SEW * 2;
  let LMUL_pow_widen = LMUL_pow + 1;
  assert(LMUL_pow_widen <= 3);

  if  illegal_fp_variable_width(vd, vm, SEW, rm_3b, SEW_widen, LMUL_pow_widen) |
      not(valid_reg_overlap(vs2, vd, LMUL_pow, LMUL_pow_widen))
  then return Illegal_Instruction();

  assert(SEW == 16);

  let 'n = num_elem;
  let 'm = SEW;
  let 'o = SEW_widen;

  let vm_val  : bits('n)             = read_vmask(num_elem, vm, zvreg);
  let vd_val  : vector('n, bits('o)) = read_vreg(num_elem, SEW_widen, LMUL_pow_widen, vd);
  let vs2_val : vector('n, bits('m)) = read_vreg(num_elem, SEW, LMUL_pow, vs2);

  let (initial_result, mask) : (vector('n, bits('o)), bits('n)) = match init_masked_result(num_elem, SEW_widen, LMUL_pow_widen, vd_val, vm_val) {
    Ok(v)   => v,
    Err(()) => return Illegal_Instruction()
  };
  var result = initial_result;

  let rs1_val = bf16_to_f32_set_flags(F_BF16(rs1));

  foreach (i from 0 to (num_elem - 1)) {
    if mask[i] == 0b1 then {
      result[i] = fp_muladd(rm_3b, bf16_to_f32_set_flags(vs2_val[i]), rs1_val, vd_val[i]);
    }
  };

  write_vreg(num_elem, SEW_widen, LMUL_pow_widen, vd, result);
  set_vstart(zeros());
  RETIRE_SUCCESS
}

mapping clause assembly = VFWMACCBF16_VF(vm, vs2, vs1, vd)
  <-> "vfwmaccbf16.vf" ^ spc() ^ vreg_name(vd) ^ sep() ^ freg_name(vs1) ^ spc() ^ vreg_name(vs2) ^ maybe_vmask(vm)
