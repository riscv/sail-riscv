/*=======================================================================================*/
/*  This Sail RISC-V architecture model, comprising all files and                        */
/*  directories except where otherwise noted is subject the BSD                          */
/*  two-clause license in the LICENSE file.                                              */
/*                                                                                       */
/*  SPDX-License-Identifier: BSD-2-Clause                                                */
/*=======================================================================================*/

/* ******************************************************************************* */
/* This file implements part of the vector extension.                              */
/* Chapter 15: vector mask instructions                                            */
/* ******************************************************************************* */

/* ******************************* OPMVV (MMTYPE) ******************************** */
union clause instruction = MMTYPE : (mmfunct6, vregidx, vregidx, vregidx)

mapping encdec_mmfunct6 : mmfunct6 <-> bits(6) = {
  MM_VMAND     <-> 0b011001,
  MM_VMNAND    <-> 0b011101,
  MM_VMANDN    <-> 0b011000,
  MM_VMXOR     <-> 0b011011,
  MM_VMOR      <-> 0b011010,
  MM_VMNOR     <-> 0b011110,
  MM_VMORN     <-> 0b011100,
  MM_VMXNOR    <-> 0b011111
}

mapping clause encdec = MMTYPE(funct6, vs2, vs1, vd)
  <-> encdec_mmfunct6(funct6) @ 0b1 @ encdec_vreg(vs2) @ encdec_vreg(vs1) @ 0b010 @ encdec_vreg(vd) @ 0b1010111
  when currentlyEnabled(Ext_V)

function clause execute(MMTYPE(funct6, vs2, vs1, vd)) = {
  let SEW      = get_sew();
  let LMUL_pow = get_lmul_pow();
  let num_elem = vlen;

  if illegal_vd_unmasked() then return Illegal_Instruction();

  let 'n = num_elem;
  let 'm = SEW;

  let vs1_val : bits('n) = read_vmask(num_elem, 0b0, vs1);
  let vs2_val : bits('n) = read_vmask(num_elem, 0b0, vs2);
  let vd_val  : bits('n) = read_vmask(num_elem, 0b0, vd);

  let (initial_result, mask) : (bits('n), bits('n)) = match init_masked_result_carry(num_elem, SEW, 0, vd_val) {
    Ok(v)   => v,
    Err(()) => return Illegal_Instruction()
  };
  var result = initial_result;

  foreach (i from 0 to (num_elem - 1)) {
    if mask[i] == bitone then {
      result[i] = match funct6 {
        MM_VMAND     => (vs2_val & vs1_val)[i],
        MM_VMNAND    => ~(vs2_val & vs1_val)[i],
        MM_VMANDN    => (vs2_val & ~(vs1_val))[i],
        MM_VMXOR     => (vs2_val ^ vs1_val)[i],
        MM_VMOR      => (vs2_val | vs1_val)[i],
        MM_VMNOR     => (~(vs2_val | vs1_val))[i],
        MM_VMORN     => (vs2_val | ~(vs1_val))[i],
        MM_VMXNOR    => (~(vs2_val ^ vs1_val))[i]
      }
    }
  };

  write_vmask(num_elem, vd, result);
  set_vstart(zeros());
  RETIRE_SUCCESS
}

mapping mmtype_mnemonic : mmfunct6 <-> string = {
  MM_VMAND     <-> "vmand.mm",
  MM_VMNAND    <-> "vmnand.mm",
  MM_VMANDN    <-> "vmandn.mm",
  MM_VMXOR     <-> "vmxor.mm",
  MM_VMOR      <-> "vmor.mm",
  MM_VMNOR     <-> "vmnor.mm",
  MM_VMORN     <-> "vmorn.mm",
  MM_VMXNOR    <-> "vmxnor.mm"
}

mapping clause assembly = MMTYPE(funct6, vs2, vs1, vd)
  <-> mmtype_mnemonic(funct6) ^ spc() ^ vreg_name(vd) ^ sep() ^ vreg_name(vs2) ^ sep() ^ vreg_name(vs1)

/* ************************* OPMVV (vcpop in VWXUNARY0) ************************** */
union clause instruction = VCPOP_M : (bits(1), vregidx, regidx)

mapping clause encdec = VCPOP_M(vm, vs2, rd)
  <-> 0b010000 @ vm @ encdec_vreg(vs2) @ 0b10000 @ 0b010 @ encdec_reg(rd) @ 0b1010111
  when currentlyEnabled(Ext_V)

function clause execute(VCPOP_M(vm, vs2, rd)) = {
  let SEW      = get_sew();
  let LMUL_pow = get_lmul_pow();
  let num_elem = vlen;

  if illegal_vd_unmasked() | not(assert_vstart(0)) then return Illegal_Instruction();

  let 'n = num_elem;
  let 'm = SEW;

  let vm_val  : bits('n) = read_vmask(num_elem, vm, zvreg);
  let vs2_val : bits('n) = read_vmask(num_elem, 0b0, vs2);

  let (_, mask) : (bits('n), bits('n)) = match init_masked_result_cmp(num_elem, SEW, 0, vs2_val, vm_val) {
    Ok(v)   => v,
    Err(()) => return Illegal_Instruction()
  };

  var count : nat = 0;
  foreach (i from 0 to (num_elem - 1)) {
    if (mask & vs2_val)[i] == bitone then count = count + 1;
  };

  X(rd) = to_bits_unsafe(xlen, count);
  set_vstart(zeros());
  RETIRE_SUCCESS
}

mapping clause assembly = VCPOP_M(vm, vs2, rd)
  <-> "vcpop.m" ^ spc() ^ reg_name(rd) ^ sep() ^ vreg_name(vs2) ^ maybe_vmask(vm)

/* ************************* OPMVV (vfirst in VWXUNARY0) ************************* */
union clause instruction = VFIRST_M : (bits(1), vregidx, regidx)

mapping clause encdec = VFIRST_M(vm, vs2, rd)
  <-> 0b010000 @ vm @ encdec_vreg(vs2) @ 0b10001 @ 0b010 @ encdec_reg(rd) @ 0b1010111
  when currentlyEnabled(Ext_V)

function clause execute(VFIRST_M(vm, vs2, rd)) = {
  let SEW      = get_sew();
  let LMUL_pow = get_lmul_pow();
  let num_elem = vlen;

  if illegal_vd_unmasked() | not(assert_vstart(0)) then return Illegal_Instruction();

  let 'n = num_elem;
  let 'm = SEW;

  let vm_val  : bits('n) = read_vmask(num_elem, vm, zvreg);
  let vs2_val : bits('n) = read_vmask(num_elem, 0b0, vs2);

  let (_, mask) : (bits('n), bits('n)) = match init_masked_result_cmp(num_elem, SEW, 0, vs2_val, vm_val) {
    Ok(v)   => v,
    Err(()) => return Illegal_Instruction()
  };

  var index : int = -1;
  foreach (i from 0 to (num_elem - 1)) {
    if index == -1 then {
      if (mask & vs2_val)[i] == bitone then index = i;
    };
  };

  X(rd) = to_bits_unsafe(xlen, index);
  set_vstart(zeros());
  RETIRE_SUCCESS
}

mapping clause assembly = VFIRST_M(vm, vs2, rd)
  <-> "vfirst.m" ^ spc() ^ reg_name(rd) ^ sep() ^ vreg_name(vs2) ^ maybe_vmask(vm)

/* ************************** OPMVV (vmsbf in VMUNARY0) ************************** */
union clause instruction = VMSBF_M : (bits(1), vregidx, vregidx)

mapping clause encdec = VMSBF_M(vm, vs2, vd)
  <-> 0b010100 @ vm @ encdec_vreg(vs2) @ 0b00001 @ 0b010 @ encdec_vreg(vd) @ 0b1010111
  when currentlyEnabled(Ext_V)

function clause execute(VMSBF_M(vm, vs2, vd)) = {
  let SEW      = get_sew();
  let LMUL_pow = get_lmul_pow();
  let num_elem = vlen;

  if illegal_normal(vd, vm) | not(assert_vstart(0)) | vd == vs2
  then return Illegal_Instruction();

  let 'n = num_elem;
  let 'm = SEW;

  let vm_val  : bits('n) = read_vmask(num_elem, vm, zvreg);
  let vs2_val : bits('n) = read_vmask(num_elem, 0b0, vs2);
  let vd_val  : bits('n) = read_vmask(num_elem, 0b0, vd);

  let (initial_result, mask) : (bits('n), bits('n)) = match init_masked_result_cmp(num_elem, SEW, 0, vd_val, vm_val) {
    Ok(v)   => v,
    Err(()) => return Illegal_Instruction()
  };
  var result = initial_result;

  var found_elem : bool = false;
  foreach (i from 0 to (num_elem - 1)) {
    if mask[i] == bitone then {
      if vs2_val[i] == bitone then found_elem = true;
      result[i] = bool_to_bit(not(found_elem))
    }
  };

  write_vmask(num_elem, vd, result);
  set_vstart(zeros());
  RETIRE_SUCCESS
}

mapping clause assembly = VMSBF_M(vm, vs2, vd)
  <-> "vmsbf.m" ^ spc() ^ vreg_name(vd) ^ sep() ^ vreg_name(vs2) ^ maybe_vmask(vm)

/* ************************** OPMVV (vmsif in VMUNARY0) ************************** */
union clause instruction = VMSIF_M : (bits(1), vregidx, vregidx)

mapping clause encdec = VMSIF_M(vm, vs2, vd)
  <-> 0b010100 @ vm @ encdec_vreg(vs2) @ 0b00011 @ 0b010 @ encdec_vreg(vd) @ 0b1010111
  when currentlyEnabled(Ext_V)

function clause execute(VMSIF_M(vm, vs2, vd)) = {
  let SEW      = get_sew();
  let LMUL_pow = get_lmul_pow();
  let num_elem = vlen;

  if illegal_normal(vd, vm) | not(assert_vstart(0)) | vd == vs2
  then return Illegal_Instruction();

  let 'n = num_elem;
  let 'm = SEW;

  let vm_val  : bits('n) = read_vmask(num_elem, vm, zvreg);
  let vs2_val : bits('n) = read_vmask(num_elem, 0b0, vs2);
  let vd_val  : bits('n) = read_vmask(num_elem, 0b0, vd);

  let (initial_result, mask) : (bits('n), bits('n)) = match init_masked_result_cmp(num_elem, SEW, 0, vd_val, vm_val) {
    Ok(v)   => v,
    Err(()) => return Illegal_Instruction()
  };
  var result = initial_result;

  var found_elem : bool = false;
  foreach (i from 0 to (num_elem - 1)) {
    if mask[i] == bitone then {
      result[i] = bool_to_bit(not(found_elem));
      if vs2_val[i] == bitone then found_elem = true
    }
  };

  write_vmask(num_elem, vd, result);
  set_vstart(zeros());
  RETIRE_SUCCESS
}

mapping clause assembly = VMSIF_M(vm, vs2, vd)
  <-> "vmsif.m" ^ spc() ^ vreg_name(vd) ^ sep() ^ vreg_name(vs2) ^ maybe_vmask(vm)

/* ************************** OPMVV (vmsof in VMUNARY0) ************************** */
union clause instruction = VMSOF_M : (bits(1), vregidx, vregidx)

mapping clause encdec = VMSOF_M(vm, vs2, vd)
  <-> 0b010100 @ vm @ encdec_vreg(vs2) @ 0b00010 @ 0b010 @ encdec_vreg(vd) @ 0b1010111
  when currentlyEnabled(Ext_V)

function clause execute(VMSOF_M(vm, vs2, vd)) = {
  let SEW      = get_sew();
  let LMUL_pow = get_lmul_pow();
  let num_elem = vlen;

  if illegal_normal(vd, vm) | not(assert_vstart(0)) | vd == vs2
  then return Illegal_Instruction();

  let 'n = num_elem;
  let 'm = SEW;

  let vm_val  : bits('n) = read_vmask(num_elem, vm, zvreg);
  let vs2_val : bits('n) = read_vmask(num_elem, 0b0, vs2);
  let vd_val  : bits('n) = read_vmask(num_elem, 0b0, vd);

  let (initial_result, mask) : (bits('n), bits('n)) = match init_masked_result_cmp(num_elem, SEW, 0, vd_val, vm_val) {
    Ok(v)   => v,
    Err(()) => return Illegal_Instruction()
  };
  var result = initial_result;

  var found_elem : bool = false;
  foreach (i from 0 to (num_elem - 1)) {
    if mask[i] == bitone then {
      if (vs2_val[i] == bitone) & not(found_elem) then {
        result[i] = bitone;
        found_elem = true
      } else {
        result[i] = bitzero
      }
    }
  };

  write_vmask(num_elem, vd, result);
  set_vstart(zeros());
  RETIRE_SUCCESS
}

mapping clause assembly = VMSOF_M(vm, vs2, vd)
  <-> "vmsof.m" ^ spc() ^ vreg_name(vd) ^ sep() ^ vreg_name(vs2) ^ maybe_vmask(vm)

/* ************************** OPMVV (viota in VMUNARY0) ************************** */
union clause instruction = VIOTA_M : (bits(1), vregidx, vregidx)

mapping clause encdec = VIOTA_M(vm, vs2, vd)
  <-> 0b010100 @ vm @ encdec_vreg(vs2) @ 0b10000 @ 0b010 @ encdec_vreg(vd) @ 0b1010111
  when currentlyEnabled(Ext_V)

function clause execute(VIOTA_M(vm, vs2, vd)) = {
  let SEW      = get_sew();
  let LMUL_pow = get_lmul_pow();
  let num_elem = get_num_elem(LMUL_pow, SEW);

  if illegal_normal(vd, vm) | not(assert_vstart(0)) | vd == vs2
  then return Illegal_Instruction();

  let 'n = num_elem;
  let 'm = SEW;

  let vm_val  : bits('n)     = read_vmask(num_elem, vm, zvreg);
  let vs2_val : bits('n)     = read_vmask(num_elem, 0b0, vs2);
  let vd_val  : vector('n, bits('m)) = read_vreg(num_elem, SEW, LMUL_pow, vd);

  let (initial_result, mask) : (vector('n, bits('m)), bits('n)) = match init_masked_result(num_elem, SEW, LMUL_pow, vd_val, vm_val) {
    Ok(v)   => v,
    Err(()) => return Illegal_Instruction()
  };
  var result = initial_result;

  var sum : int = 0;
  foreach (i from 0 to (num_elem - 1)) {
    if mask[i] == bitone then {
      result[i] = to_bits_unsafe(SEW, sum);
      if vs2_val[i] == bitone then sum = sum + 1
    }
  };

  write_vreg(num_elem, SEW, LMUL_pow, vd, result);
  set_vstart(zeros());
  RETIRE_SUCCESS
}

mapping clause assembly = VIOTA_M(vm, vs2, vd)
  <-> "viota.m" ^ spc() ^ vreg_name(vd) ^ sep() ^ vreg_name(vs2) ^ maybe_vmask(vm)

/* *************************** OPMVV (vid in VMUNARY0) *************************** */
union clause instruction = VID_V : (bits(1), vregidx)

mapping clause encdec = VID_V(vm, vd)
  <-> 0b010100 @ vm @ 0b00000 @ 0b10001 @ 0b010 @ encdec_vreg(vd) @ 0b1010111
  when currentlyEnabled(Ext_V)

function clause execute(VID_V(vm, vd)) = {
  let SEW      = get_sew();
  let LMUL_pow = get_lmul_pow();
  let num_elem = get_num_elem(LMUL_pow, SEW);

  if illegal_normal(vd, vm) then return Illegal_Instruction();

  let 'n = num_elem;
  let 'm = SEW;

  let vm_val  : bits('n)     = read_vmask(num_elem, vm, zvreg);
  let vd_val  : vector('n, bits('m)) = read_vreg(num_elem, SEW, LMUL_pow, vd);

  let (initial_result, mask) : (vector('n, bits('m)), bits('n)) = match init_masked_result(num_elem, SEW, LMUL_pow, vd_val, vm_val) {
    Ok(v)    => v,
    Err(())  => return Illegal_Instruction()
  };
  var result = initial_result;

  foreach (i from 0 to (num_elem - 1)) {
    if mask[i] == bitone then result[i] = to_bits_unsafe(SEW, i)
  };

  write_vreg(num_elem, SEW, LMUL_pow, vd, result);
  set_vstart(zeros());
  RETIRE_SUCCESS
}

mapping clause assembly = VID_V(vm, vd)
  <-> "vid.v" ^ spc() ^ vreg_name(vd) ^ maybe_vmask(vm)
