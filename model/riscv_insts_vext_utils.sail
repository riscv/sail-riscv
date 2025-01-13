/*=======================================================================================*/
/*  This Sail RISC-V architecture model, comprising all files and                        */
/*  directories except where otherwise noted is subject the BSD                          */
/*  two-clause license in the LICENSE file.                                              */
/*                                                                                       */
/*  SPDX-License-Identifier: BSD-2-Clause                                                */
/*=======================================================================================*/

/* ******************************************************************************* */
/* This file implements functions used by vector instructions.                     */
/* ******************************************************************************* */

/* Vector mask mapping */
mapping maybe_vmask : string <-> bits(1) = {
  ""              <-> 0b1, /* unmasked by default */
  sep() ^ "v0.t"  <-> 0b0
}

/* Check for valid EEW and EMUL values in:
 *  1. vector widening/narrowing instructions
 *  2. vector load/store instructions
 */
val valid_eew_emul : (int, int) -> bool
function valid_eew_emul(EEW, EMUL_pow) = {
  let ELEN = 2 ^ get_elen_pow();
  EEW >= 8 & EEW <= ELEN & EMUL_pow >= -3 & EMUL_pow <= 3
}

/* Check for valid vtype setting
 *  1. If the vill bit is set, then any attempt to execute a vector instruction that depends upon vtype will raise an illegal instruction exception.
 *  2. vset{i}vl{i} and whole-register loads, stores, and moves do not depend upon vtype.
 */
val valid_vtype : unit -> bool
function valid_vtype() = {
  vtype[vill] == 0b0
}

/* Check for vstart value */
val assert_vstart : int -> bool
function assert_vstart(i) = {
  unsigned(vstart) == i
}

/* Check for valid destination register when vector masking is enabled:
 *  The destination vector register group for a masked vector instruction
 *  cannot overlap the source mask register (v0),
 *  unless the destination vector register is being written with a mask value (e.g., compares)
 *  or the scalar result of a reduction.
 */
val valid_rd_mask : (regidx, bits(1)) -> bool
function valid_rd_mask(rd, vm) = {
  vm != 0b0 | rd != 0b00000
}

/* Check for valid register overlap in vector widening/narrowing instructions:
 *  In a widening instruction, the overlap is valid only in the highest-numbered part
 *  of the destination register group, and the source EMUL is at least 1.
 *  In a narrowing instruction, the overlap is valid only in the lowest-numbered part
 *  of the source register group.
 */
val valid_reg_overlap : (regidx, regidx, int, int) -> bool
function valid_reg_overlap(rs, rd, EMUL_pow_rs, EMUL_pow_rd) = {
  let rs_group = if EMUL_pow_rs > 0 then 2 ^ EMUL_pow_rs else 1;
  let rd_group = if EMUL_pow_rd > 0 then 2 ^ EMUL_pow_rd else 1;
  let rs_int = unsigned(rs);
  let rd_int = unsigned(rd);
  if EMUL_pow_rs < EMUL_pow_rd then {
    (rs_int + rs_group <= rd_int) | (rs_int >= rd_int + rd_group) |
    ((rs_int + rs_group == rd_int + rd_group) & (EMUL_pow_rs >= 0))
  } else if EMUL_pow_rs > EMUL_pow_rd then {
    (rd_int <= rs_int) | (rd_int >= rs_int + rs_group)
  } else true;
}

/* Check for valid register grouping in vector segment load/store instructions:
 *  The EMUL of load vd or store vs3 times the number of fields per segment
 *  must not be larger than 8. (EMUL * NFIELDS <= 8)
 */
val valid_segment : (int, int) -> bool
function valid_segment(nf, EMUL_pow) = {
  if EMUL_pow < 0 then nf / (2 ^ (0 - EMUL_pow)) <= 8
  else nf * 2 ^ EMUL_pow <= 8
}

/* ******************************************************************************* */
/* The following functions summarize patterns of illegal instruction check.        */
/* ******************************************************************************* */

/* a. Normal check including vtype.vill field and vd/v0 overlap if vm = 0 */
val illegal_normal : (regidx, bits(1)) -> bool
function illegal_normal(vd, vm) = {
  not(valid_vtype()) | not(valid_rd_mask(vd, vm))
}

/* b. Masked check for instructions encoded with vm = 0 */
val illegal_vd_masked : regidx -> bool
function illegal_vd_masked(vd) = {
  not(valid_vtype()) | vd == 0b00000
}

/* c. Unmasked check for:
 *  1. instructions encoded with vm = 1
 *  2. instructions with scalar rd: vcpop.m, vfirst.m
 *  3. vd as mask register (eew = 1):
 *     vmadc.vvm/vxm/vim, vmsbc.vvm/vxm, mask logical, integer compare, vlm.v, vsm.v
 */
val illegal_vd_unmasked : unit -> bool
function illegal_vd_unmasked() = {
  not(valid_vtype())
}

/* d. Variable width check for:
 *  1. integer/fixed-point widening/narrowing instructions
 *  2. vector integer extension: vzext, vsext
 */
val illegal_variable_width : (regidx, bits(1), int, int) -> bool
function illegal_variable_width(vd, vm, SEW_new, LMUL_pow_new) = {
  not(valid_vtype()) | not(valid_rd_mask(vd, vm)) | not(valid_eew_emul(SEW_new, LMUL_pow_new))
}

/* e. Normal check for reduction instructions:
 *  The destination vector register can overlap the source operands, including the mask register.
 *  Vector reduction operations raise an illegal instruction exception if vstart is non-zero.
 */
val illegal_reduction : unit -> bool
function illegal_reduction() = {
  not(valid_vtype()) | not(assert_vstart(0))
}

/* f. Variable width check for widening reduction instructions */
val illegal_reduction_widen : (int, int) -> bool
function illegal_reduction_widen(SEW_widen, LMUL_pow_widen) = {
  not(valid_vtype()) | not(assert_vstart(0)) | not(valid_eew_emul(SEW_widen, LMUL_pow_widen))
}

/* g. Non-indexed load instruction check */
val illegal_load : (regidx, bits(1), int, int, int) -> bool
function illegal_load(vd, vm, nf, EEW, EMUL_pow) = {
  not(valid_vtype()) | not(valid_rd_mask(vd, vm)) |
  not(valid_eew_emul(EEW, EMUL_pow)) | not(valid_segment(nf, EMUL_pow))
}

/* h. Non-indexed store instruction check (with vs3 rather than vd) */
val illegal_store : (int, int, int) -> bool
function illegal_store(nf, EEW, EMUL_pow) = {
  not(valid_vtype()) | not(valid_eew_emul(EEW, EMUL_pow)) | not(valid_segment(nf, EMUL_pow))
}

/* i. Indexed load instruction check */
val illegal_indexed_load : (regidx, bits(1), int, int, int, int) -> bool
function illegal_indexed_load(vd, vm, nf, EEW_index, EMUL_pow_index, EMUL_pow_data) = {
  not(valid_vtype()) | not(valid_rd_mask(vd, vm)) |
  not(valid_eew_emul(EEW_index, EMUL_pow_index)) | not(valid_segment(nf, EMUL_pow_data))
}

/* j. Indexed store instruction check (with vs3 rather than vd) */
val illegal_indexed_store : (int, int, int, int) -> bool
function illegal_indexed_store(nf, EEW_index, EMUL_pow_index, EMUL_pow_data) = {
  not(valid_vtype()) | not(valid_eew_emul(EEW_index, EMUL_pow_index)) |
  not(valid_segment(nf, EMUL_pow_data))
}

/* Scalar register shaping */
val get_scalar : forall 'm, 'm >= 8. (regidx, int('m)) -> bits('m)
function get_scalar(rs1, SEW) = {
  if SEW <= xlen then {
    /* Least significant SEW bits */
    X(rs1)[SEW - 1 .. 0]
  } else {
    /* Sign extend to SEW */
    sign_extend(SEW, X(rs1))
  }
}

/* Get the starting element index from csr vtype */
val get_start_element : unit -> nat
function get_start_element() = {
  let start_element = unsigned(vstart);
  let VLEN_pow = get_vlen_pow();
  let SEW_pow = get_sew_pow();
  /* The use of vstart values greater than the largest element
    index for the current SEW setting is reserved.
    It is recommended that implementations trap if vstart is out of bounds.
    It is not required to trap, as a possible future use of upper vstart bits
    is to store imprecise trap information. */
  if start_element > (2 ^ (3 + VLEN_pow - SEW_pow) - 1) then handle_illegal();
  start_element
}

/* Get the ending element index from csr vl */
val get_end_element : unit -> int
function get_end_element() = unsigned(vl) - 1

/* Mask handling; creates a pre-masked result vector for vstart, vl, vta/vma, and vm */
/* vm should be baked into vm_val from doing read_vmask */
/* tail masking when lmul < 1 is handled in write_vreg */
/* Returns two vectors:
 *   vector1 is the result vector with values applied to masked elements
 *   vector2 is a "mask" vector that is true for an element if the corresponding element
 *     in the result vector should be updated by the calling instruction
 */
val init_masked_result : forall 'n 'm 'p, 'n >= 0 & 'm >= 0. (int('n), int('m), int('p), vector('n, bits('m)), bits('n)) -> (vector('n, bits('m)), bits('n))
function init_masked_result(num_elem, SEW, LMUL_pow, vd_val, vm_val) = {
  let start_element = get_start_element();
  let end_element   = get_end_element();
  let tail_ag : agtype = get_vtype_vta();
  let mask_ag : agtype = get_vtype_vma();
  var mask : bits('n) = undefined;
  var result : vector('n, bits('m)) = undefined;

  /* Determine the actual number of elements when lmul < 1 */
  let real_num_elem = if LMUL_pow >= 0 then num_elem else num_elem / (2 ^ (0 - LMUL_pow));
  assert(num_elem >= real_num_elem);

  foreach (i from 0 to (num_elem - 1)) {
    if i < start_element then {
      /* Prestart elements defined by vstart */
      result[i] = vd_val[i];
      mask[i] = bitzero
    } else if i > end_element then {
      /* Tail elements defined by vl */
      result[i] = match tail_ag {
        UNDISTURBED => vd_val[i],
        AGNOSTIC    => vd_val[i] /* TODO: configuration support */
      };
      mask[i] = bitzero
    } else if i >= real_num_elem then {
      /* Tail elements defined by lmul < 1 */
      result[i] = match tail_ag {
        UNDISTURBED => vd_val[i],
        AGNOSTIC    => vd_val[i] /* TODO: configuration support */
      };
      mask[i] = bitzero
    } else if vm_val[i] == bitzero then {
      /* Inactive body elements defined by vm */
      result[i] = match mask_ag {
        UNDISTURBED => vd_val[i],
        AGNOSTIC    => vd_val[i] /* TODO: configuration support */
      };
      mask[i] = bitzero
    } else {
      /* Active body elements */
      mask[i] = bitone;
    }
  };

  (result, mask)
}

/* For instructions like vector reduction and vector store,
 * masks on prestart, inactive and tail elements only affect the validation of source register elements
 * (vs3 for store and vs2 for reduction). There's no destination register to be masked.
 * In these cases, this function can be called to simply get the mask vector for vs (without the prepared vd result vector).
 */
val init_masked_source : forall 'n 'p, 'n > 0. (int('n), int('p), bits('n)) -> bits('n)
function init_masked_source(num_elem, LMUL_pow, vm_val) = {
  let start_element = get_start_element();
  let end_element   = get_end_element();
  var mask : bits('n) = undefined;

  /* Determine the actual number of elements when lmul < 1 */
  let real_num_elem = if LMUL_pow >= 0 then num_elem else num_elem / (2 ^ (0 - LMUL_pow));
  assert(num_elem >= real_num_elem);

  foreach (i from 0 to (num_elem - 1)) {
    if i < start_element then {
      /* Prestart elements defined by vstart */
      mask[i] = bitzero
    } else if i > end_element then {
      /* Tail elements defined by vl */
      mask[i] = bitzero
    } else if i >= real_num_elem then {
      /* Tail elements defined by lmul < 1 */
      mask[i] = bitzero
    } else if vm_val[i] == bitzero then {
      /* Inactive body elements defined by vm */
      mask[i] = bitzero
    } else {
      /* Active body elements */
      mask[i] = bitone;
    }
  };

  mask
}

/* Mask handling for carry functions that use masks as input/output */
/* Only prestart and tail elements are masked in a mask value */
val init_masked_result_carry : forall 'n 'm 'p, 'n >= 0. (int('n), int('m), int('p), bits('n)) -> (bits('n), bits('n))
function init_masked_result_carry(num_elem, SEW, LMUL_pow, vd_val) = {
  let start_element = get_start_element();
  let end_element   = get_end_element();
  var mask : bits('n) = undefined;
  var result : bits('n) = undefined;

  /* Determine the actual number of elements when lmul < 1 */
  let real_num_elem = if LMUL_pow >= 0 then num_elem else num_elem / (2 ^ (0 - LMUL_pow));
  assert(num_elem >= real_num_elem);

  foreach (i from 0 to (num_elem - 1)) {
    if i < start_element then {
      /* Prestart elements defined by vstart */
      result[i] = vd_val[i];
      mask[i] = bitzero
    } else if i > end_element then {
      /* Tail elements defined by vl */
      /* Mask tail is always agnostic */
      result[i] = vd_val[i]; /* TODO: configuration support */
      mask[i] = bitzero
    } else if i >= real_num_elem then {
      /* Tail elements defined by lmul < 1 */
      /* Mask tail is always agnostic */
      result[i] = vd_val[i]; /* TODO: configuration support */
      mask[i] = bitzero
    } else {
      /* Active body elements */
      mask[i] = bitone
    }
  };

  (result, mask)
}

/* Mask handling for cmp functions that use masks as output */
val init_masked_result_cmp : forall 'n 'm 'p, 'n >= 0. (int('n), int('m), int('p), bits('n), bits('n)) -> (bits('n), bits('n))
function init_masked_result_cmp(num_elem, SEW, LMUL_pow, vd_val, vm_val) = {
  let start_element = get_start_element();
  let end_element   = get_end_element();
  let mask_ag : agtype = get_vtype_vma();
  var mask : bits('n) = undefined;
  var result : bits('n) = undefined;

  /* Determine the actual number of elements when lmul < 1 */
  let real_num_elem = if LMUL_pow >= 0 then num_elem else num_elem / (2 ^ (0 - LMUL_pow));
  assert(num_elem >= real_num_elem);

  foreach (i from 0 to (num_elem - 1)) {
    if i < start_element then {
      /* Prestart elements defined by vstart */
      result[i] = vd_val[i];
      mask[i] = bitzero
    } else if i > end_element then {
      /* Tail elements defined by vl */
      /* Mask tail is always agnostic */
      result[i] = vd_val[i]; /* TODO: configuration support */
      mask[i] = bitzero
    } else if i >= real_num_elem then {
      /* Tail elements defined by lmul < 1 */
      /* Mask tail is always agnostic */
      result[i] = vd_val[i]; /* TODO: configuration support */
      mask[i] = bitzero
    } else if vm_val[i] == bitzero then {
      /* Inactive body elements defined by vm */
      result[i] = match mask_ag {
        UNDISTURBED => vd_val[i],
        AGNOSTIC    => vd_val[i] /* TODO: configuration support */
      };
      mask[i] = bitzero
    } else {
      /* Active body elements */
      mask[i] = bitone
    }
  };

  (result, mask)
}

/* For vector load/store segment instructions:
 *   Read multiple register groups and concatenate them in parallel
 *   The whole segments with the same element index are combined together
 */
val read_vreg_seg : forall 'n 'm 'p 'q, 'n >= 0 & 'm >= 0 & 'q >= 0. (int('n), int('m), int('p), int('q), regidx) -> vector('n, bits('q * 'm))
function read_vreg_seg(num_elem, SEW, LMUL_pow, nf, vrid) = {
  let LMUL_reg : int = if LMUL_pow <= 0 then 1 else 2 ^ LMUL_pow;
  var vreg_list : vector('q, vector('n, bits('m))) = vector_init(vector_init(zeros()));
  var result : vector('n, bits('q * 'm)) = vector_init(zeros());
  foreach (j from 0 to (nf - 1)) {
    vreg_list[j] = read_vreg(num_elem, SEW, LMUL_pow, vrid + to_bits(5, j * LMUL_reg));
  };
  foreach (i from 0 to (num_elem - 1)) {
    result[i] = zeros('q * 'm);
    foreach (j from 0 to (nf - 1)) {
      result[i] = result[i] | (zero_extend(vreg_list[j][i]) << (j * 'm))
    }
  };
  result
}

/* Shift amounts */
val get_shift_amount : forall 'n 'm, 0 <= 'n & 'm in {8, 16, 32, 64}. (bits('n), int('m)) -> nat
function get_shift_amount(bit_val, SEW) = {
  let lowlog2bits = log2(SEW);
  assert(0 < lowlog2bits & lowlog2bits < 'n);
  unsigned(bit_val[lowlog2bits - 1 .. 0]);
}

/* Fixed point rounding increment */
val get_fixed_rounding_incr : forall ('m 'n : Int), ('m > 0 & 'n >= 0). (bits('m), int('n)) -> bits(1)
function get_fixed_rounding_incr(vec_elem, shift_amount) = {
  if shift_amount == 0 then 0b0
  else {
    let rounding_mode = vcsr[vxrm];
    match rounding_mode {
      0b00 => slice(vec_elem, shift_amount - 1, 1),
      0b01 => bool_to_bits(
        (slice(vec_elem, shift_amount - 1, 1) == 0b1) & (slice(vec_elem, 0, shift_amount - 1) != zeros() | slice(vec_elem, shift_amount, 1) == 0b1)),
      0b10 => 0b0,
      0b11 => bool_to_bits(
        not(slice(vec_elem, shift_amount, 1) == 0b1) & (slice(vec_elem, 0, shift_amount) != zeros()))
    }
  }
}

/* Fixed point unsigned saturation */
val unsigned_saturation : forall ('m 'n: Int), ('n >= 'm > 1). (int('m), bits('n)) -> bits('m)
function unsigned_saturation(len, elem) = {
  if unsigned(elem) > unsigned(ones('m)) then {
    vcsr[vxsat] = 0b1;
    ones('m)
  } else {
    elem['m - 1 .. 0]
  }
}

/* Fixed point signed saturation */
val signed_saturation : forall ('m 'n: Int), ('n >= 'm > 1). (int('m), bits('n)) -> bits('m)
function signed_saturation(len, elem) = {
  if signed(elem) > signed(0b0 @ ones('m - 1)) then {
    vcsr[vxsat] = 0b1;
    0b0 @ ones('m - 1)
  } else if signed(elem) < signed(0b1 @ zeros('m - 1)) then {
    vcsr[vxsat] = 0b1;
    0b1 @ zeros('m - 1)
  } else {
    elem['m - 1 .. 0]
  };
}

val count_leadingzeros : (bits(64), int) -> int
function count_leadingzeros (sig, len) = {
  var idx : int = -1;
  assert(len == 10 | len == 23 | len == 52);
  foreach (i from 0 to (len - 1)) {
    if sig[i] == bitone then idx = i;
  };
  len - idx - 1
}
