// =======================================================================================
// This Sail RISC-V architecture model, comprising all files and
// directories except where otherwise noted is subject the BSD
// two-clause license in the LICENSE file.
//
// SPDX-License-Identifier: BSD-2-Clause
// =======================================================================================

function clause currentlyEnabled(Ext_Zvzip) = hartSupports(Ext_Zvzip) &
                                              currentlyEnabled(Ext_Zve32x)

union clause instruction = VZIP_VV : (bits(1), vregidx, vregidx, vregidx)

$[wavedrom "_ _ _ _ OPMVV _ OP-V"]
mapping clause encdec = VZIP_VV(vm, vs1, vs2, vd)
  <-> 0b111110 @ vm @ encdec_vreg(vs2) @ encdec_vreg(vs1) @ 0b010 @ encdec_vreg(vd) @ 0b1010111
  when currentlyEnabled(Ext_Zvzip) & (get_sew() <= 32 | (get_sew() == 64 & currentlyEnabled(Ext_Zve64x)))

mapping clause assembly = VZIP_VV(vm, vs1, vs2, vd)
  <-> "vzip.vv" ^ spc() ^ vreg_name(vd) ^ sep() ^ vreg_name(vs2) ^ sep() ^ vreg_name(vs1) ^ maybe_vmask(vm)

function clause execute VZIP_VV(vm, vs1, vs2, vd) = {
  let SEW = get_sew();
  let LMUL_pow_src = get_lmul_pow();
  let num_src_elem = get_num_elem(LMUL_pow_src, SEW);

  assert(LMUL_pow_src <= 2);

  // This instruction operates with an effective vector length of 2*VL.
  // The destination EMUL is 2xLMUL.
  let effective_vl = (unsigned(vl) * 2);
  let LMUL_pow_dst = LMUL_pow_src + 1;
  let num_dst_elem = get_num_elem(LMUL_pow_dst, SEW);

  assert(num_dst_elem == 2 * num_src_elem);

  let 'nd = num_dst_elem;
  let 'ns = num_src_elem;
  let 'm = SEW;

  let vm_val  : bits('nd) = read_vmask(num_dst_elem, vm, zvreg);
  let vs1_val : vector('ns, bits('m)) = read_vreg(num_src_elem, SEW, LMUL_pow_src, vs1);
  let vs2_val : vector('ns, bits('m)) = read_vreg(num_src_elem, SEW, LMUL_pow_src, vs2);
  let vd_val  : vector('nd, bits('m)) = read_vreg(num_dst_elem, SEW, LMUL_pow_dst, vd);

  // The destination vector register group may overlap the source vector
  // register group if the overlap is in the highest-numbered part of the
  // destination register group and the source EMUL is at least 1. If the
  // overlap violates these constraints, the instruction encoding is
  // reserved. The instruction is reserved when LMUL is 8.
  if ((LMUL_pow_src == 3) |
      not(valid_reg_overlap(vs2, vd, LMUL_pow_src, LMUL_pow_dst)) |
      not(valid_reg_overlap(vs1, vd, LMUL_pow_src, LMUL_pow_dst)))
  then return Illegal_Instruction();

  let (initial_result, mask) : (vector('nd, bits('m)), bits('nd)) =
    match init_masked_result_evl(num_dst_elem, SEW, effective_vl, LMUL_pow_dst, vd_val, vm_val) {
      Ok(v)   => v,
      Err(()) => return Illegal_Instruction()
    };
  var result = initial_result;

  // The vector zip instruction (VZIP) interleaves element at a given index in
  // each source vector register group, in destination vector register group.
  foreach (i from 0 to (num_dst_elem - 1)) {
    let j = i / 2;

    assert(j < num_src_elem);

    if mask[i] == bitone then
      result[i] = if (i % 2 == 0) then vs2_val[j] else vs1_val[j];
  };
  write_vreg(num_dst_elem, SEW, LMUL_pow_dst, vd, result);
  set_vstart(zeros());
  RETIRE_SUCCESS
}

union clause instruction = VUNZIPE_V : (bits(1), vregidx, vregidx)

$[wavedrom "_ _ _ _ OPMVV _ OP-V"]
mapping clause encdec = VUNZIPE_V(vm, vs2, vd)
  <-> 0b010010 @ vm @ encdec_vreg(vs2) @ 0b01011 @ 0b010 @ encdec_vreg(vd) @ 0b1010111
  when currentlyEnabled(Ext_Zvzip) & (get_sew() <= 32 | (get_sew() == 64 & currentlyEnabled(Ext_Zve64x)))

mapping clause assembly = VUNZIPE_V(vm, vs2, vd)
  <-> "vunzipe.v" ^ spc() ^ vreg_name(vd) ^ sep() ^ vreg_name(vs2) ^ maybe_vmask(vm)

function clause execute VUNZIPE_V(vm, vs2, vd) = {
  // This instruction accesses 2*VL number of elements in the source vector
  // register group and the source EMUL is 2xLMUL.
  let SEW = get_sew();
  let LMUL_pow_dst = get_lmul_pow();
  let num_dst_elem = get_num_elem(LMUL_pow_dst, SEW);
  let LMUL_pow_src = LMUL_pow_dst + 1;

  assert(LMUL_pow_src <= 3);

  let num_src_elem = get_num_elem(LMUL_pow_src, SEW);

  assert(num_src_elem == 2 * num_dst_elem);

  let 'nd = num_dst_elem;
  let 'ns = num_src_elem;
  let 'm = SEW;

  let vm_val  : bits('nd) = read_vmask(num_dst_elem, vm, zvreg);
  let vs2_val : vector('ns, bits('m)) = read_vreg(num_src_elem, SEW, LMUL_pow_src, vs2);
  let vd_val  : vector('nd, bits('m)) = read_vreg(num_dst_elem, SEW, LMUL_pow_dst, vd);

  // The destination vector register group may overlap the source vector
  // register group if the overlap is in the lowest-numbered part of the
  // source register group. If the overlap violates these constraints, the
  // instruction encoding is reserved. The instruction is reserved when
  // LMUL is 8.
  if ((LMUL_pow_dst == 3) |
      not(valid_reg_overlap(vs2, vd, LMUL_pow_src, LMUL_pow_dst)))
  then return Illegal_Instruction();

  let (initial_result, mask) : (vector('nd, bits('m)), bits('nd)) =
    match init_masked_result(num_dst_elem, SEW, LMUL_pow_dst, vd_val, vm_val) {
      Ok(v)   => v,
      Err(()) => return Illegal_Instruction()
    };
  var result = initial_result;

  // The vector unzip-even instruction (VNZIPE) extracts the VL number of
  // even-indexed elements from the source vector register group into the
  // destination vector register group.
  foreach (i from 0 to (num_dst_elem - 1)) {
    let j = 2 * i;

    assert(j < num_src_elem);

    if mask[i] == bitone then
      result[i] = vs2_val[j];
  };
  write_vreg(num_dst_elem, SEW, LMUL_pow_dst, vd, result);
  set_vstart(zeros());
  RETIRE_SUCCESS
}

union clause instruction = VUNZIPO_V : (bits(1), vregidx, vregidx)

$[wavedrom "_ _ _ _ OPMVV _ OP-V"]
mapping clause encdec = VUNZIPO_V(vm, vs2, vd)
  <-> 0b010010 @ vm @ encdec_vreg(vs2) @ 0b01111 @ 0b010 @ encdec_vreg(vd) @ 0b1010111
  when currentlyEnabled(Ext_Zvzip) & (get_sew() <= 32 | (get_sew() == 64 & currentlyEnabled(Ext_Zve64x)))

mapping clause assembly = VUNZIPO_V(vm, vs2, vd)
  <-> "vunzipo.v" ^ spc() ^ vreg_name(vd) ^ sep() ^ vreg_name(vs2) ^ maybe_vmask(vm)

function clause execute VUNZIPO_V(vm, vs2, vd) = {
  // This instruction accesses 2*VL number of elements in the source vector
  // register group and the source EMUL is 2xLMUL.
  let SEW = get_sew();
  let LMUL_pow_dst = get_lmul_pow();
  let num_dst_elem = get_num_elem(LMUL_pow_dst, SEW);
  let LMUL_pow_src = LMUL_pow_dst + 1;

  assert(LMUL_pow_src <= 3);

  let num_src_elem = get_num_elem(LMUL_pow_src, SEW);

  assert(num_src_elem == 2 * num_dst_elem);

  let 'nd = num_dst_elem;
  let 'ns = num_src_elem;
  let 'm = SEW;

  let vm_val  : bits('nd) = read_vmask(num_dst_elem, vm, zvreg);
  let vs2_val : vector('ns, bits('m)) = read_vreg(num_src_elem, SEW, LMUL_pow_src, vs2);
  let vd_val  : vector('nd, bits('m)) = read_vreg(num_dst_elem, SEW, LMUL_pow_dst, vd);

  // The destination vector register group may overlap the source vector
  // register group if the overlap is in the lowest-numbered part of the
  // source register group. If the overlap violates these constraints, the
  // instruction encoding is reserved. The instruction is reserved when
  // LMUL is 8.
  if ((LMUL_pow_dst == 3) |
      not(valid_reg_overlap(vs2, vd, LMUL_pow_src, LMUL_pow_dst)))
  then return Illegal_Instruction();

  let (initial_result, mask) : (vector('nd, bits('m)), bits('nd)) =
    match init_masked_result(num_dst_elem, SEW, LMUL_pow_dst, vd_val, vm_val) {
      Ok(v)   => v,
      Err(()) => return Illegal_Instruction()
    };
  var result = initial_result;

  // The vector unzip-odd instruction (VNZIPO) extracts the VL number of
  // odd-indexed elements from the source vector register group into the
  // destination vector register group.
  foreach (i from 0 to (num_dst_elem - 1)) {
    let j = (2 * i) + 1;

    assert(j < num_src_elem);

    if mask[i] == bitone then
      result[i] = vs2_val[j];
  };
  write_vreg(num_dst_elem, SEW, LMUL_pow_dst, vd, result);
  set_vstart(zeros());
  RETIRE_SUCCESS
}

union clause instruction = VPAIRE_VV : (bits(1), vregidx, vregidx, vregidx)

$[wavedrom "_ _ _ _ OPIVV _ OP-V"]
mapping clause encdec = VPAIRE_VV(vm, vs1, vs2, vd)
  <-> 0b001111 @ vm @ encdec_vreg(vs2) @ encdec_vreg(vs1) @ 0b000 @ encdec_vreg(vd) @ 0b1010111
  when currentlyEnabled(Ext_Zvzip) & (get_sew() <= 32 | (get_sew() == 64 & currentlyEnabled(Ext_Zve64x)))

mapping clause assembly = VPAIRE_VV(vm, vs1, vs2, vd)
  <-> "vpaire.vv" ^ spc() ^ vreg_name(vd) ^ sep() ^ vreg_name(vs2) ^ sep() ^ vreg_name(vs1) ^ maybe_vmask(vm)

function clause execute VPAIRE_VV(vm, vs1, vs2, vd) = {
  let SEW = get_sew();
  let LMUL_pow = get_lmul_pow();
  let num_elem = get_num_elem(LMUL_pow, SEW);

  let 'n = num_elem;
  let 'm = SEW;

  let vm_val  : bits('n) = read_vmask(num_elem, vm, zvreg);
  let vs1_val : vector('n, bits('m)) = read_vreg(num_elem, SEW, LMUL_pow, vs1);
  let vs2_val : vector('n, bits('m)) = read_vreg(num_elem, SEW, LMUL_pow, vs2);
  let vd_val  : vector('n, bits('m)) = read_vreg(num_elem, SEW, LMUL_pow, vd);

  let (initial_result, mask) : (vector('n, bits('m)), bits('n)) =
    match init_masked_result(num_elem, SEW, LMUL_pow, vd_val, vm_val) {
      Ok(v)   => v,
      Err(()) => return Illegal_Instruction()
    };
  var result = initial_result;

  // The vector pair-even instruction (VPAIRE) interleaves the even-indexed
  // elements of the source vector register groups into the destination
  // vector register group.
  foreach (i from 0 to (num_elem - 1)) {
    if mask[i] == bitone then
      result[i] = if (i % 2 == 0) then vs2_val[i] else vs1_val[i - 1];
  };
  write_vreg(num_elem, SEW, LMUL_pow, vd, result);
  set_vstart(zeros());
  RETIRE_SUCCESS
}

union clause instruction = VPAIRO_VV : (bits(1), vregidx, vregidx, vregidx)

$[wavedrom "_ _ _ _ OPMVV _ OP-V"]
mapping clause encdec = VPAIRO_VV(vm, vs1, vs2, vd)
  <-> 0b001111 @ vm @ encdec_vreg(vs2) @ encdec_vreg(vs1) @ 0b010 @ encdec_vreg(vd) @ 0b1010111
  when currentlyEnabled(Ext_Zvzip) & (get_sew() <= 32 | (get_sew() == 64 & currentlyEnabled(Ext_Zve64x)))

mapping clause assembly = VPAIRO_VV(vm, vs1, vs2, vd)
  <-> "vpairo.vv" ^ spc() ^ vreg_name(vd) ^ sep() ^ vreg_name(vs2) ^ sep() ^ vreg_name(vs1) ^ maybe_vmask(vm)

function clause execute VPAIRO_VV(vm, vs1, vs2, vd) = {
  let SEW_pow = get_sew_pow();
  let SEW = get_sew();
  let LMUL_pow = get_lmul_pow();
  let num_elem = get_num_elem(LMUL_pow, SEW);

  let 'n = num_elem;
  let 'm = SEW;

  let vm_val  : bits('n) = read_vmask(num_elem, vm, zvreg);
  let vs1_val : vector('n, bits('m)) = read_vreg(num_elem, SEW, LMUL_pow, vs1);
  let vs2_val : vector('n, bits('m)) = read_vreg(num_elem, SEW, LMUL_pow, vs2);
  let vd_val  : vector('n, bits('m)) = read_vreg(num_elem, SEW, LMUL_pow, vd);

  let (initial_result, mask) : (vector('n, bits('m)), bits('n)) =
    match init_masked_result(num_elem, SEW, LMUL_pow, vd_val, vm_val) {
      Ok(v)   => v,
      Err(()) => return Illegal_Instruction()
    };
  var result = initial_result;

  // The vector pair-odd instruction (VPAIRO) interleaves the odd-indexed
  // elements of the source vector register groups into the destination
  // vector register group.
  assert(LMUL_pow + vlen_exp - SEW_pow >= 0);
  let VLMAX = 2 ^ (LMUL_pow + vlen_exp - SEW_pow);
  assert(VLMAX <= 'n);
  foreach (i from 0 to (num_elem - 1)) {
    if mask[i] == bitone then
      result[i] =
        if (i % 2 == 0) then {
          let idx = i + 1;
          // VPAIRO may read one element past VL in vs2 if VL is odd.
          // The general policy is to return the value 0 when the index is
          // greater than VLMAX in the source vector register group.
          if idx < VLMAX then vs2_val[idx] else zeros()
        } else {
          vs1_val[i]
        };
  };
  write_vreg(num_elem, SEW, LMUL_pow, vd, result);
  set_vstart(zeros());
  RETIRE_SUCCESS
}
