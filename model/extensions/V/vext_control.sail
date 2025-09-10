/*=======================================================================================*/
/*  This Sail RISC-V architecture model, comprising all files and                        */
/*  directories except where otherwise noted is subject the BSD                          */
/*  two-clause license in the LICENSE file.                                              */
/*                                                                                       */
/*  SPDX-License-Identifier: BSD-2-Clause                                                */
/*=======================================================================================*/

function clause currentlyEnabled(Ext_V) = hartSupports(Ext_V) & (misa[V] == 0b1) & (mstatus[VS] != 0b00) & currentlyEnabled(Ext_Zicsr)

/* num_elem means max(VLMAX,VLEN/SEW)) according to Section 5.4 of RVV spec */
val get_num_elem : (int, sew_bitsize) -> nat1
function get_num_elem(LMUL_pow, SEW) = {
  let LMUL_pow_reg = if LMUL_pow < 0 then 0 else LMUL_pow;
  /* Ignore lmul < 1 so that the entire vreg is read, allowing all masking to
   * be handled in init_masked_result */
  let num_elem = (2 ^ LMUL_pow_reg) * vlen / SEW;
  assert(num_elem > 0);
  num_elem
}

/* Reads a single vreg into multiple elements */
val read_single_vreg : forall 'n 'm, 'n >= 0 & is_sew_bitsize('m) . (int('n), int('m), vregidx) -> vector('n, bits('m))
function read_single_vreg(num_elem, SEW, vrid) = {
  // TODO: This should be part of the type signature for this function.
  assert(num_elem * SEW <= vlen);

  let bv = V(vrid);
  var result : vector('n, bits('m)) = vector_init(zeros());

  foreach (i from 0 to (num_elem - 1)) {
    let start_index = i * SEW;
    result[i] = bv[start_index + SEW - 1 .. start_index];
  };

  result
}

/* Writes multiple elements into a single vreg */
val write_single_vreg : forall 'n 'm, 'n >= 0 & is_sew_bitsize('m) . (int('n), int('m), vregidx, vector('n, bits('m))) -> unit
function write_single_vreg(num_elem, SEW, vrid, v) = {
  var r : vlenbits = zeros();

  assert(SEW <= vlen);

  foreach (i from (num_elem - 1) downto 0) {
    r = r << SEW;
    r = r | zero_extend(v[i]);
  };

  V(vrid) = r
}

/* The general vreg reading operation with num_elem as max(VLMAX,VLEN/SEW)) */
val read_vreg : forall 'n 'm 'p, 'n >= 0 & is_sew_bitsize('m) . (int('n), int('m), int('p), vregidx) -> vector('n, bits('m))
function read_vreg(num_elem, SEW, LMUL_pow, vrid) = {
  let vrid_val = unsigned(vregidx_bits(vrid));
  var result : vector('n, bits('m)) = vector_init(zeros());
  let LMUL_pow_reg = if LMUL_pow < 0 then 0 else LMUL_pow;

  /* Check for valid vrid */
  if vrid_val + 2 ^ LMUL_pow_reg > 32 then {
    /* vrid would read past largest vreg (v31) */
    assert(false, "invalid register group: vrid overflow the largest number")
  } else if vrid_val % (2 ^ LMUL_pow_reg) != 0 then {
    /* vrid must be a multiple of emul */
    assert(false, "invalid register group: vrid is not a multiple of EMUL")
  } else {
    /* Check if a single register read suffices. */
    if num_elem * SEW < vlen then {
      result = read_single_vreg('n, SEW, vrid);
    } else {
      let 'num_elem_single = vlen / SEW;
      assert('num_elem_single >= 0);
      foreach (i_lmul from 0 to (2 ^ LMUL_pow_reg - 1)) {
        let r_start_i : int = i_lmul * 'num_elem_single;
        let r_end_i   : int = r_start_i + 'num_elem_single - 1;
        let vrid_lmul     : vregidx = vregidx_offset(vrid, to_bits_unsafe(5, i_lmul));
        let single_result : vector('num_elem_single, bits('m)) = read_single_vreg('num_elem_single, SEW, vrid_lmul);
        foreach (r_i from r_start_i to r_end_i) {
          let s_i : int = r_i - r_start_i;
          assert(0 <= r_i & r_i < num_elem);
          assert(0 <= s_i & s_i < 'num_elem_single);
          result[r_i] = single_result[s_i];
        }
      }
    }
  };

  result
}

// Read a single element of a vector register group (starting at vrid).
val read_single_element : forall 'm, is_sew_bitsize('m) . (int('m), nat, vregidx) -> bits('m)
function read_single_element(EEW, index, vrid) = {
  assert(EEW <= vlen);

  // Number of EEW-bit elements per vector register.
  let elem_per_reg = vlen / EEW;

  // Register in group. Max LMUL is 8, so this should be in [0, 8).
  let reg_in_group = index / elem_per_reg;
  assert(reg_in_group < 8);

  // Get the actual register in the group that we need to write, and the index into it.
  let vrid = vrid + reg_in_group;
  let index = index % elem_per_reg;
  // Bit offset in register.
  let offset = index * EEW;

  V(vrid)[(offset + EEW - 1) .. offset]
}

/* The general vreg writing operation with num_elem as max(VLMAX,VLEN/SEW)) */
val write_vreg : forall 'n 'm 'p, 'n >= 0 & is_sew_bitsize('m) . (int('n), int('m), int('p), vregidx, vector('n, bits('m))) -> unit
function write_vreg(num_elem, SEW, LMUL_pow, vrid, vec) = {
  let LMUL_pow_reg = if LMUL_pow < 0 then 0 else LMUL_pow;

  let 'num_elem_single = vlen / SEW;
  assert('num_elem_single >= 0);
  foreach (i_lmul from 0 to (2 ^ LMUL_pow_reg - 1)) {
    var single_vec : vector('num_elem_single, bits('m)) = vector_init(zeros());
    let vrid_lmul  : vregidx = vregidx_offset(vrid, to_bits_unsafe(5, i_lmul));
    let r_start_i  : int = i_lmul * 'num_elem_single;
    let r_end_i    : int = r_start_i + 'num_elem_single - 1;
    foreach (r_i from r_start_i to r_end_i) {
      let s_i : int = r_i - r_start_i;
      assert(0 <= r_i & r_i < num_elem);
      assert(0 <= s_i & s_i < 'num_elem_single);
      single_vec[s_i] = vec[r_i]
    };
    write_single_vreg('num_elem_single, SEW, vrid_lmul, single_vec)
  }
}

// Write a single element of a vector register group (starting at vrid),
// leaving all other elements unchanged.
val write_single_element : forall 'm, is_sew_bitsize('m) . (int('m), nat, vregidx, bits('m)) -> unit
function write_single_element(EEW, index, vrid, value) = {
  assert(EEW <= vlen);

  // Number of EEW-bit elements per vector register.
  let elem_per_reg = vlen / EEW;

  // Register in group. Max LMUL is 8, so this should be in [0, 8).
  let reg_in_group = index / elem_per_reg;
  assert(reg_in_group < 8);

  // Get the actual register in the group that we need to write, and the index into it.
  let vrid = vrid + reg_in_group;
  let index = index % elem_per_reg;
  // Bit offset in register.
  let offset = index * EEW;

  V(vrid) = [V(vrid) with (offset + EEW - 1) .. offset = value];
}

/* Mask register reading operation with num_elem as max(VLMAX,vlen/SEW)) */
val read_vmask : forall 'n, 'n > 0. (int('n), bits(1), vregidx) -> bits('n)
function read_vmask(num_elem, vm, vrid) = {
  assert(num_elem <= vlen);

  let vreg_val = V(vrid);
  var result   : bits('n) = ones();

  if vm == 0b1 then {
    return result
  };

  foreach (i from 0 to (num_elem - 1)) {
    result[i] = vreg_val[i]
  };

  result
}

/* This is a special version of read_vmask for carry/borrow instructions, where vm=1 means no carry */
val read_vmask_carry : forall 'n, 'n > 0. (int('n), bits(1), vregidx) -> bits('n)
function read_vmask_carry(num_elem, vm, vrid) = {
  assert(num_elem <= vlen);

  let vreg_val = V(vrid);
  var result   : bits('n) = zeros();

  if vm == 0b1 then {
    return result
  };

  foreach (i from 0 to (num_elem - 1)) {
    result[i] = vreg_val[i]
  };

  result
}

/* Mask register writing operation with num_elem as max(VLMAX,vlen/SEW)) */
val write_vmask : forall 'n, 'n > 0. (int('n), vregidx, bits('n)) -> unit
function write_vmask(num_elem, vrid, v) = {
  assert(0 < num_elem & num_elem <= vlen);
  let vreg_val = V(vrid);
  var result : vlenbits = undefined;

  foreach (i from 0 to (num_elem - 1)) {
    result[i] = v[i]
  };
  foreach (i from num_elem to (vlen - 1)) {
    /* Mask tail is always agnostic */
    result[i] = vreg_val[i] /* TODO: configuration support */
  };

  V(vrid) = result
}
