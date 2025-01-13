/*=======================================================================================*/
/*  This Sail RISC-V architecture model, comprising all files and                        */
/*  directories except where otherwise noted is subject the BSD                          */
/*  two-clause license in the LICENSE file.                                              */
/*                                                                                       */
/*  SPDX-License-Identifier: BSD-2-Clause                                                */
/*=======================================================================================*/

/* ******************************************************************************* */
/* This file implements part of the vector extension.                              */
/* Mask instructions from Chap 13 (floating-point)                                 */
/* ******************************************************************************* */

/* ******************************* OPFVV (VVMTYPE) ******************************* */
/* FVVM instructions' destination is a mask register */
union clause ast = FVVMTYPE : (fvvmfunct6, bits(1), regidx, regidx, regidx)

mapping encdec_fvvmfunct6 : fvvmfunct6 <-> bits(6) = {
  FVVM_VMFEQ      <-> 0b011000,
  FVVM_VMFLE      <-> 0b011001,
  FVVM_VMFLT      <-> 0b011011,
  FVVM_VMFNE      <-> 0b011100
}

mapping clause encdec = FVVMTYPE(funct6, vm, vs2, vs1, vd) if extensionEnabled(Ext_V)
  <-> encdec_fvvmfunct6(funct6) @ vm @ vs2 @ vs1 @ 0b001 @ vd @ 0b1010111 if extensionEnabled(Ext_V)

function clause execute(FVVMTYPE(funct6, vm, vs2, vs1, vd)) = {
  let rm_3b    = fcsr[FRM];
  let SEW      = get_sew();
  let LMUL_pow = get_lmul_pow();
  let num_elem = get_num_elem(LMUL_pow, SEW);

  if illegal_fp_vd_unmasked(SEW, rm_3b) then { handle_illegal(); return RETIRE_FAIL };
  assert(SEW != 8);

  let 'n = num_elem;
  let 'm = SEW;

  let vm_val  : bits('n)     = read_vmask(num_elem, vm, 0b00000);
  let vs1_val : vector('n, bits('m)) = read_vreg(num_elem, SEW, LMUL_pow, vs1);
  let vs2_val : vector('n, bits('m)) = read_vreg(num_elem, SEW, LMUL_pow, vs2);
  let vd_val  : bits('n)     = read_vmask(num_elem, 0b0, vd);

  let (initial_result, mask) = init_masked_result_cmp(num_elem, SEW, LMUL_pow, vd_val, vm_val);
  var result = initial_result;

  foreach (i from 0 to (num_elem - 1)) {
    if mask[i] == bitone then {
      let res : bool = match funct6 {
        FVVM_VMFEQ    => fp_eq(vs2_val[i], vs1_val[i]),
        FVVM_VMFNE    => ~(fp_eq(vs2_val[i], vs1_val[i])),
        FVVM_VMFLE    => fp_le(vs2_val[i], vs1_val[i]),
        FVVM_VMFLT    => fp_lt(vs2_val[i], vs1_val[i])
      };
      result[i] = bool_to_bit(res)
    }
  };

  write_vmask(num_elem, vd, result);
  vstart = zeros();
  RETIRE_SUCCESS
}

mapping fvvmtype_mnemonic : fvvmfunct6 <-> string = {
  FVVM_VMFEQ      <-> "vmfeq.vv",
  FVVM_VMFLE      <-> "vmfle.vv",
  FVVM_VMFLT      <-> "vmflt.vv",
  FVVM_VMFNE      <-> "vmfne.vv"
}

mapping clause assembly = FVVMTYPE(funct6, vm, vs2, vs1, vd)
  <-> fvvmtype_mnemonic(funct6) ^ spc() ^ vreg_name(vd) ^ sep() ^ vreg_name(vs2) ^ sep() ^ vreg_name(vs1) ^ maybe_vmask(vm)

/* ******************************* OPFVF (VFMTYPE) ******************************* */
/* VFM instructions' destination is a mask register */
union clause ast = FVFMTYPE : (fvfmfunct6, bits(1), regidx, regidx, regidx)

mapping encdec_fvfmfunct6 : fvfmfunct6 <-> bits(6) = {
  VFM_VMFEQ      <-> 0b011000,
  VFM_VMFLE      <-> 0b011001,
  VFM_VMFLT      <-> 0b011011,
  VFM_VMFNE      <-> 0b011100,
  VFM_VMFGT      <-> 0b011101,
  VFM_VMFGE      <-> 0b011111
}

mapping clause encdec = FVFMTYPE(funct6, vm, vs2, rs1, vd) if extensionEnabled(Ext_V)
  <-> encdec_fvfmfunct6(funct6) @ vm @ vs2 @ rs1 @ 0b101 @ vd @ 0b1010111 if extensionEnabled(Ext_V)

function clause execute(FVFMTYPE(funct6, vm, vs2, rs1, vd)) = {
  let rm_3b    = fcsr[FRM];
  let SEW      = get_sew();
  let LMUL_pow = get_lmul_pow();
  let num_elem = get_num_elem(LMUL_pow, SEW);

  if illegal_fp_vd_unmasked(SEW, rm_3b) then { handle_illegal(); return RETIRE_FAIL };
  assert(SEW != 8);

  let 'n = num_elem;
  let 'm = SEW;

  let vm_val  : bits('n)     = read_vmask(num_elem, vm, 0b00000);
  let rs1_val : bits('m)                  = get_scalar_fp(rs1, 'm);
  let vs2_val : vector('n, bits('m)) = read_vreg(num_elem, SEW, LMUL_pow, vs2);
  let vd_val  : bits('n)     = read_vmask(num_elem, 0b0, vd);

  let (initial_result, mask) = init_masked_result_cmp(num_elem, SEW, LMUL_pow, vd_val, vm_val);
  var result = initial_result;

  foreach (i from 0 to (num_elem - 1)) {
    if mask[i] == bitone then {
      let res : bool = match funct6 {
        VFM_VMFEQ    => fp_eq(vs2_val[i], rs1_val),
        VFM_VMFNE    => ~(fp_eq(vs2_val[i], rs1_val)),
        VFM_VMFLE    => fp_le(vs2_val[i], rs1_val),
        VFM_VMFLT    => fp_lt(vs2_val[i], rs1_val),
        VFM_VMFGE    => fp_ge(vs2_val[i], rs1_val),
        VFM_VMFGT    => fp_gt(vs2_val[i], rs1_val)
      };
      result[i] = bool_to_bit(res)
    }
  };

  write_vmask(num_elem, vd, result);
  vstart = zeros();
  RETIRE_SUCCESS
}

mapping fvfmtype_mnemonic : fvfmfunct6 <-> string = {
  VFM_VMFEQ      <-> "vmfeq.vf",
  VFM_VMFLE      <-> "vmfle.vf",
  VFM_VMFLT      <-> "vmflt.vf",
  VFM_VMFNE      <-> "vmfne.vf",
  VFM_VMFGT      <-> "vmfgt.vf",
  VFM_VMFGE      <-> "vmfge.vf"
}

mapping clause assembly = FVFMTYPE(funct6, vm, vs2, rs1, vd)
  <-> fvfmtype_mnemonic(funct6) ^ spc() ^ vreg_name(vd) ^ sep() ^ vreg_name(vs2) ^ sep() ^ reg_name(rs1) ^ maybe_vmask(vm)
