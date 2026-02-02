// =======================================================================================
// This Sail RISC-V architecture model, comprising all files and
// directories except where otherwise noted is subject the BSD
// two-clause license in the LICENSE file.
//
// SPDX-License-Identifier: BSD-2-Clause
// =======================================================================================

function clause currentlyEnabled(Ext_Zvl32b) = hartSupports(Ext_Zvl32b)
function clause currentlyEnabled(Ext_Zvl64b) = hartSupports(Ext_Zvl64b)
function clause currentlyEnabled(Ext_Zvl128b) = hartSupports(Ext_Zvl128b)
function clause currentlyEnabled(Ext_Zvl256b) = hartSupports(Ext_Zvl256b)
function clause currentlyEnabled(Ext_Zvl512b) = hartSupports(Ext_Zvl512b)
function clause currentlyEnabled(Ext_Zvl1024b) = hartSupports(Ext_Zvl1024b)

// TODO: the interaction of Ext_Zve32x with a writable misa.V when misa.V == 0 needs settling.
function clause currentlyEnabled(Ext_Zve32x) = hartSupports(Ext_Zve32x) & currentlyEnabled(Ext_Zvl32b) & (mstatus[VS] != 0b00) & currentlyEnabled(Ext_Zicsr)
function clause currentlyEnabled(Ext_Zve32f) = hartSupports(Ext_Zve32f) & currentlyEnabled(Ext_Zve32x) & currentlyEnabled(Ext_F)
function clause currentlyEnabled(Ext_Zve64x) = hartSupports(Ext_Zve64x) & currentlyEnabled(Ext_Zvl64b) & currentlyEnabled(Ext_Zve32x)
function clause currentlyEnabled(Ext_Zve64f) = hartSupports(Ext_Zve64f) & currentlyEnabled(Ext_Zve64x) & currentlyEnabled(Ext_Zve32f)
function clause currentlyEnabled(Ext_Zve64d) = hartSupports(Ext_Zve64d) & currentlyEnabled(Ext_Zve64f) & currentlyEnabled(Ext_D)

function clause currentlyEnabled(Ext_V) = hartSupports(Ext_V) & (misa[V] == 0b1) & currentlyEnabled(Ext_Zvl128b) & currentlyEnabled(Ext_Zve64d)

function clause currentlyEnabled(Ext_Zvfh)    = hartSupports(Ext_Zvfh)     & currentlyEnabled(Ext_Zve32f) & currentlyEnabled(Ext_Zfhmin)
function clause currentlyEnabled(Ext_Zvfhmin) = (hartSupports(Ext_Zvfhmin) & currentlyEnabled(Ext_Zve32f)) | currentlyEnabled(Ext_Zvfh)

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
val read_single_element : forall 'sew, is_sew_bitsize('sew) . (int('sew), nat, vregidx) -> bits('sew)
function read_single_element(EEW, index, vrid) = {
  assert(EEW <= vlen);
  static_assert(vlen % EEW == 0);

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

// The general vreg reading operation with num_elem as max(VLMAX,VLEN/SEW)).
val read_vreg : forall 'n 'sew 'p, 'n >= 0 & is_sew_bitsize('sew) . (int('n), int('sew), int('p), vregidx) -> vector('n, bits('sew))
function read_vreg(num_elem, SEW, LMUL_pow, vrid) = {
  let vrid_val = unsigned(vregidx_bits(vrid));
  let LMUL_pow_reg = if LMUL_pow < 0 then 0 else LMUL_pow;
  let LMUL = 2 ^ LMUL_pow_reg;
  let vrid_end = vrid_val + LMUL;
  assert(vrid_end <= 32, "invalid register group: group " ^ dec_str(vrid_val) ^ " ends at " ^ dec_str(vrid_end) ^ " and overflows the largest register number (32)");
  assert(vrid_val % LMUL == 0, "invalid register group: group " ^ dec_str(vrid_val) ^ " is not a multiple of its EMUL " ^ dec_str(LMUL));

  var result : vector('n, bits('sew)) = vector_init(zeros());

  foreach (i from 0 to (num_elem - 1)) {
    result[i] = read_single_element(SEW, i, vrid);
  };

  result
}

// Write a single element of a vector register group (starting at vrid),
// leaving all other elements unchanged.
val write_single_element : forall 'sew, is_sew_bitsize('sew) . (int('sew), nat, vregidx, bits('sew)) -> unit
function write_single_element(EEW, index, vrid, value) = {
  assert(EEW <= vlen);
  static_assert(vlen % EEW == 0);

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

// Write a complete vector register group.
//
// num_elem: Number of elements in the entire group (ignoring
//           fractional lmul and vl).
// SEW:      Element size in bits.
// LMUL_pow: LMUL exponent; size of the register group.
//           Negative values indicate fractions of a single register, but
//           we still require the full register's worth of elements.
// vrid:     Index of the first register in the group.
// data:     Data of each element.
//
val write_vreg : forall 'n 'sew, 'n >= 0 & is_sew_bitsize('sew) . (int('n), int('sew), LMUL_pow, vregidx, vector('n, bits('sew))) -> unit
function write_vreg(num_elem, SEW, LMUL_pow, vrid, vec) = {
  // Number of registers in the group (treating fractional lmul as 0).
  let group_size = 2 ^ max(LMUL_pow, 0);

  assert(SEW <= vlen);
  static_assert(vlen % SEW == 0);

  // Number of SEW-bit elements per vector register.
  let elem_per_reg = vlen / SEW;

  // Normally num_elem == group_size * elem_per_reg, however
  // in the specific case of fractional lmul with widening instructions
  // get_num_elem() returns vlen / SEW, but SEW is doubled before
  // feeding into this instruction, so elem_per_reg is half the
  // pre-widening value. Since `group_size` will be unchanged
  // (because max(LMUL_pow, 0) is still 0), we will end up
  // with num_elem == group_size * (elem_per_reg * 2).
  //
  // In that case the second half of the `vec` array will be ignored.
  assert(num_elem == group_size * elem_per_reg | num_elem == 2 * group_size * elem_per_reg);

  foreach (reg_in_group from 0 to (group_size - 1)) {
    var reg_value : vlenbits = zeros();
    foreach (i_elem from 0 to (elem_per_reg - 1)) {
      reg_value[(i_elem * SEW) + SEW - 1 .. (i_elem * SEW)] = vec[reg_in_group * elem_per_reg + i_elem];
    };
    V(vrid + reg_in_group) = reg_value;
  }
}

// Mask register reading operation with num_elem as max(VLMAX,vlen/SEW)).
val read_vmask : forall 'n, 0 < 'n <= vlen . (int('n), bits(1), vregidx) -> bits('n)
function read_vmask(num_elem, vm, vrid) =
  if vm == 0b1 then ones() else ones('n - num_elem) @ V(vrid)[num_elem - 1 .. 0]

// This is a special version of read_vmask for carry/borrow instructions, where vm=1 means no carry.
val read_vmask_carry : forall 'n, 0 < 'n <= vlen . (int('n), bits(1), vregidx) -> bits('n)
function read_vmask_carry(num_elem, vm, vrid) =
  if vm == 0b1 then zeros() else zeros('n - num_elem) @ V(vrid)[num_elem - 1 .. 0]

// Mask register writing operation with num_elem as max(VLMAX,vlen/SEW))
val write_vmask : forall 'n, 'n > 0. (int('n), vregidx, bits('n)) -> unit
function write_vmask(num_elem, vrid, v) = {
  // TODO: This should be part of the type signature.
  assert(0 < num_elem & num_elem <= vlen);

  // Mask tail is always agnostic. Currently we always
  // leave it undisturbed.
  // TODO: Configuration support for ones/undisturbed.
  V(vrid) = [V(vrid) with (num_elem - 1) .. 0 = v]
}
