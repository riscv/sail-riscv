/*=======================================================================================*/
/*  This Sail RISC-V architecture model, comprising all files and                        */
/*  directories except where otherwise noted is subject the BSD                          */
/*  two-clause license in the LICENSE file.                                              */
/*                                                                                       */
/*  SPDX-License-Identifier: BSD-2-Clause                                                */
/*=======================================================================================*/

function clause currentlyEnabled(Ext_V) = hartSupports(Ext_V) & (misa[V] == 0b1) & (mstatus[VS] != 0b00) & currentlyEnabled(Ext_Zicsr)

// Get the total number of elements in a register group (not considering `vl`).
// For fractional groups (negative LMUL_pow) we return the number of elements
// in a single register. The fractional aspect is handled by `init_masked_result()`.
//
// The minimum number of elements is 1.
// The maximum is VLMAX = LMUL*VLEN/SEW. VLMAX can never be more than vlen
// because the minimum SEW is 8 and the maximum LMUL is 8. This is also
// true because all elements must be able to fit into a single register
// at 1-bit per element for masks.
function get_num_elem(LMUL_pow : LMUL_pow, SEW : sew_bitsize) -> range(1, vlen) = {
  assert(vlen >= SEW);
  (2 ^ max(0, LMUL_pow)) * vlen / SEW
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

/* The general vreg reading operation with num_elem as max(VLMAX,VLEN/SEW)) */
val read_vreg : forall 'n 'm 'p, 'n >= 0 & is_sew_bitsize('m) . (int('n), int('m), int('p), vregidx) -> vector('n, bits('m))
function read_vreg(num_elem, SEW, LMUL_pow, vrid) = {
  let vrid_val = unsigned(vregidx_bits(vrid));
  let LMUL_pow_reg = if LMUL_pow < 0 then 0 else LMUL_pow;
  assert(vrid_val + 2 ^ LMUL_pow_reg <= 32, "invalid register group: vrid overflow the largest number");
  assert(vrid_val % (2 ^ LMUL_pow_reg) == 0, "invalid register group: vrid is not a multiple of EMUL");

  var result : vector('n, bits('m)) = vector_init(zeros());

  foreach (i from 0 to (num_elem - 1)) {
    result[i] = read_single_element(SEW, i, vrid);
  };

  result
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

/* The general vreg writing operation with num_elem as max(VLMAX,VLEN/SEW)) */
val write_vreg : forall 'n 'm 'p, 'n >= 0 & is_sew_bitsize('m) . (int('n), int('m), int('p), vregidx, vector('n, bits('m))) -> unit
function write_vreg(num_elem, SEW, LMUL_pow, vrid, vec) = {
  // TODO: LMUL_pow is unused; we can remove it.
  foreach (i from 0 to (num_elem - 1)) {
    write_single_element(SEW, i, vrid, vec[i]);
  };
}

// Mask register reading operation with num_elem as max(VLMAX,vlen/SEW)).
val read_vmask : forall 'n, 0 < 'n <= vlen . (int('n), bits(1), vregidx) -> bits('n)
function read_vmask(num_elem, vm, vrid) =
  if vm == 0b1 then ones() else ones('n - num_elem) @ V(vrid)[num_elem - 1 .. 0]

// This is a special version of read_vmask for carry/borrow instructions, where vm=1 means no carry.
val read_vmask_carry : forall 'n, 0 < 'n <= vlen . (int('n), bits(1), vregidx) -> bits('n)
function read_vmask_carry(num_elem, vm, vrid) =
  if vm == 0b1 then zeros() else zeros('n - num_elem) @ V(vrid)[num_elem - 1 .. 0]

/* Mask register writing operation with num_elem as max(VLMAX,vlen/SEW)) */
val write_vmask : forall 'n, 'n > 0. (int('n), vregidx, bits('n)) -> unit
function write_vmask(num_elem, vrid, v) = {
  // TODO: This should be part of the type signature.
  assert(0 < num_elem & num_elem <= vlen);

  // Mask tail is always agnostic. Currently we always
  // leave it undisturbed.
  // TODO: Configuration support for ones/undisturbed.
  V(vrid) = [V(vrid) with (num_elem - 1) .. 0 = v]
}
