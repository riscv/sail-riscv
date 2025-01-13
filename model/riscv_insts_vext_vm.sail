/*=======================================================================================*/
/*  This Sail RISC-V architecture model, comprising all files and                        */
/*  directories except where otherwise noted is subject the BSD                          */
/*  two-clause license in the LICENSE file.                                              */
/*                                                                                       */
/*  SPDX-License-Identifier: BSD-2-Clause                                                */
/*=======================================================================================*/

/* ******************************************************************************* */
/* This file implements part of the vector extension.                              */
/* Mask instructions from Chap 11 (integer arithmetic)                             */
/* ******************************************************************************* */

/* ******************************* OPIVV (VVMTYPE) ******************************* */
/* VVM instructions' destination is a mask register (e.g. carry out) */
/* Instructions with no carry out will set mask result to current mask value */
/* May or may not read from source mask register (e.g. carry in) */
union clause ast = VVMTYPE : (vvmfunct6, regidx, regidx, regidx)

mapping encdec_vvmfunct6 : vvmfunct6 <-> bits(6) = {
  VVM_VMADC    <-> 0b010001, /* carry in, carry out */
  VVM_VMSBC    <-> 0b010011
}

mapping clause encdec = VVMTYPE(funct6, vs2, vs1, vd) if extensionEnabled(Ext_V)
  <-> encdec_vvmfunct6(funct6) @ 0b0 @ vs2 @ vs1 @ 0b000 @ vd @ 0b1010111 if extensionEnabled(Ext_V)

function clause execute(VVMTYPE(funct6, vs2, vs1, vd)) = {
  let SEW      = get_sew();
  let LMUL_pow = get_lmul_pow();
  let num_elem = get_num_elem(LMUL_pow, SEW);

  if illegal_vd_unmasked() then { handle_illegal(); return RETIRE_FAIL };

  let 'n = num_elem;
  let 'm = SEW;

  let vm_val  : bits('n)     = read_vmask_carry(num_elem, 0b0, 0b00000);
  let vs1_val : vector('n, bits('m)) = read_vreg(num_elem, SEW, LMUL_pow, vs1);
  let vs2_val : vector('n, bits('m)) = read_vreg(num_elem, SEW, LMUL_pow, vs2);
  let vd_val  : bits('n)     = read_vmask(num_elem, 0b0, vd);

  let (initial_result, mask) = init_masked_result_carry(num_elem, SEW, LMUL_pow, vd_val);
  var result = initial_result;

  foreach (i from 0 to (num_elem - 1)) {
    if mask[i] == bitone then {
      let res : bool = match funct6 {
        VVM_VMADC    => unsigned(vs2_val[i]) + unsigned(vs1_val[i]) + (if vm_val[i] == bitone then 1 else 0) > 2 ^ SEW - 1,
        VVM_VMSBC    => unsigned(vs2_val[i]) - unsigned(vs1_val[i]) - (if vm_val[i] == bitone then 1 else 0) < 0
      };
      result[i] = bool_to_bit(res)
    }
  };

  write_vmask(num_elem, vd, result);
  vstart = zeros();
  RETIRE_SUCCESS
}

mapping vvmtype_mnemonic : vvmfunct6 <-> string = {
  VVM_VMADC    <-> "vmadc.vvm", /* carry in, carry out */
  VVM_VMSBC    <-> "vmsbc.vvm"
}

mapping clause assembly = VVMTYPE(funct6, vs2, vs1, vd)
  <-> vvmtype_mnemonic(funct6) ^ spc() ^ vreg_name(vd) ^ sep() ^ vreg_name(vs2) ^ sep() ^ vreg_name(vs1) ^ sep() ^ "v0"

/* ****************************** OPIVV (VVMCTYPE) ******************************* */
/* VVMC instructions' destination is a mask register (e.g. carry out) */
/* Instructions with no carry out will set mask result to current mask value */
/* May or may not read from source mask register (e.g. carry in) */
union clause ast = VVMCTYPE : (vvmcfunct6, regidx, regidx, regidx)

mapping encdec_vvmcfunct6 : vvmcfunct6 <-> bits(6) = {
  VVMC_VMADC    <-> 0b010001, /* no carry in, carry out */
  VVMC_VMSBC    <-> 0b010011
}

mapping clause encdec = VVMCTYPE(funct6, vs2, vs1, vd) if extensionEnabled(Ext_V)
  <-> encdec_vvmcfunct6(funct6) @ 0b1 @ vs2 @ vs1 @ 0b000 @ vd @ 0b1010111 if extensionEnabled(Ext_V)

function clause execute(VVMCTYPE(funct6, vs2, vs1, vd)) = {
  let SEW      = get_sew();
  let LMUL_pow = get_lmul_pow();
  let num_elem = get_num_elem(LMUL_pow, SEW);

  if illegal_vd_unmasked() then { handle_illegal(); return RETIRE_FAIL };

  let 'n = num_elem;
  let 'm = SEW;

  let vs1_val : vector('n, bits('m)) = read_vreg(num_elem, SEW, LMUL_pow, vs1);
  let vs2_val : vector('n, bits('m)) = read_vreg(num_elem, SEW, LMUL_pow, vs2);
  let vd_val  : bits('n)     = read_vmask(num_elem, 0b0, vd);

  let (initial_result, mask) = init_masked_result_carry(num_elem, SEW, LMUL_pow, vd_val);
  var result = initial_result;

  foreach (i from 0 to (num_elem - 1)) {
    if mask[i] == bitone then {
      let res : bool = match funct6 {
        VVMC_VMADC    => unsigned(vs2_val[i]) + unsigned(vs1_val[i]) > 2 ^ SEW - 1,
        VVMC_VMSBC    => unsigned(vs2_val[i]) - unsigned(vs1_val[i]) < 0
      };
      result[i] = bool_to_bit(res)
    }
  };

  write_vmask(num_elem, vd, result);
  vstart = zeros();
  RETIRE_SUCCESS
}

mapping vvmctype_mnemonic : vvmcfunct6 <-> string = {
  VVMC_VMADC    <-> "vmadc.vv", /* no carry in, carry out */
  VVMC_VMSBC    <-> "vmsbc.vv"
}

mapping clause assembly = VVMCTYPE(funct6, vs2, vs1, vd)
  <-> vvmctype_mnemonic(funct6) ^ spc() ^ vreg_name(vd) ^ sep() ^ vreg_name(vs2) ^ sep() ^ vreg_name(vs1)

/* ****************************** OPIVV (VVMSTYPE) ******************************* */
/* VVMS instructions' destination is a vector register (e.g. actual sum) */
/* Instructions with no carry out will set mask result to current mask value */
/* May or may not read from source mask register (e.g. carry in) */
union clause ast = VVMSTYPE : (vvmsfunct6, regidx, regidx, regidx)

mapping encdec_vvmsfunct6 : vvmsfunct6 <-> bits(6) = {
  VVMS_VADC     <-> 0b010000, /* carry in, no carry out */
  VVMS_VSBC     <-> 0b010010
}

mapping clause encdec = VVMSTYPE(funct6, vs2, vs1, vd) if extensionEnabled(Ext_V)
  <-> encdec_vvmsfunct6(funct6) @ 0b0 @ vs2 @ vs1 @ 0b000 @ vd @ 0b1010111 if extensionEnabled(Ext_V)

function clause execute(VVMSTYPE(funct6, vs2, vs1, vd)) = {
  let SEW      = get_sew();
  let LMUL_pow = get_lmul_pow();
  let num_elem = get_num_elem(LMUL_pow, SEW);

  if illegal_vd_masked(vd) then { handle_illegal(); return RETIRE_FAIL };

  let 'n = num_elem;
  let 'm = SEW;

  /* for bypassing normal masking in init_masked_result */
  let vec_trues : bits('n) = ones();

  let vm_val  : bits('n)     = read_vmask_carry(num_elem, 0b0, 0b00000);
  let vs1_val : vector('n, bits('m)) = read_vreg(num_elem, SEW, LMUL_pow, vs1);
  let vs2_val : vector('n, bits('m)) = read_vreg(num_elem, SEW, LMUL_pow, vs2);
  let vd_val  : vector('n, bits('m)) = read_vreg(num_elem, SEW, LMUL_pow, vd);

  let (initial_result, mask) = init_masked_result(num_elem, SEW, LMUL_pow, vd_val, vec_trues);
  var result = initial_result;

  foreach (i from 0 to (num_elem - 1)) {
    if mask[i] == bitone then {
      result[i] = match funct6 {
        VVMS_VADC     => to_bits(SEW, unsigned(vs2_val[i]) + unsigned(vs1_val[i]) + (if vm_val[i] == bitone then 1 else 0)),
        VVMS_VSBC     => to_bits(SEW, unsigned(vs2_val[i]) - unsigned(vs1_val[i]) - (if vm_val[i] == bitone then 1 else 0))
      }
    }
  };

  write_vreg(num_elem, SEW, LMUL_pow, vd, result);
  vstart = zeros();
  RETIRE_SUCCESS
}

mapping vvmstype_mnemonic : vvmsfunct6 <-> string = {
  VVMS_VADC     <-> "vadc.vvm", /* carry in, no carry out */
  VVMS_VSBC     <-> "vsbc.vvm"
}

mapping clause assembly = VVMSTYPE(funct6, vs2, vs1, vd)
  <-> vvmstype_mnemonic(funct6) ^ spc() ^ vreg_name(vd) ^ sep() ^ vreg_name(vs2) ^ sep() ^ vreg_name(vs1) ^ sep() ^ "v0"

/* ***************** OPIVV (Vector Integer Compare Instructions) ***************** */
/* VVCMP instructions' destination is a mask register */
union clause ast = VVCMPTYPE : (vvcmpfunct6, bits(1), regidx, regidx, regidx)

mapping encdec_vvcmpfunct6 : vvcmpfunct6 <-> bits(6) = {
  VVCMP_VMSEQ    <-> 0b011000,
  VVCMP_VMSNE    <-> 0b011001,
  VVCMP_VMSLTU   <-> 0b011010,
  VVCMP_VMSLT    <-> 0b011011,
  VVCMP_VMSLEU   <-> 0b011100,
  VVCMP_VMSLE    <-> 0b011101
}

mapping clause encdec = VVCMPTYPE(funct6, vm, vs2, vs1, vd) if extensionEnabled(Ext_V)
  <-> encdec_vvcmpfunct6(funct6) @ vm @ vs2 @ vs1 @ 0b000 @ vd @ 0b1010111 if extensionEnabled(Ext_V)

function clause execute(VVCMPTYPE(funct6, vm, vs2, vs1, vd)) = {
  let SEW      = get_sew();
  let LMUL_pow = get_lmul_pow();
  let num_elem = get_num_elem(LMUL_pow, SEW);

  if illegal_vd_unmasked() then { handle_illegal(); return RETIRE_FAIL };

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
        VVCMP_VMSEQ    => vs2_val[i] == vs1_val[i],
        VVCMP_VMSNE    => vs2_val[i] != vs1_val[i],
        VVCMP_VMSLTU   => unsigned(vs2_val[i]) < unsigned(vs1_val[i]),
        VVCMP_VMSLT    => signed(vs2_val[i]) < signed(vs1_val[i]),
        VVCMP_VMSLEU   => unsigned(vs2_val[i]) <= unsigned(vs1_val[i]),
        VVCMP_VMSLE    => signed(vs2_val[i]) <= signed(vs1_val[i])
      };
      result[i] = bool_to_bit(res)
    }
  };

  write_vmask(num_elem, vd, result);
  vstart = zeros();
  RETIRE_SUCCESS
}

mapping vvcmptype_mnemonic : vvcmpfunct6 <-> string = {
  VVCMP_VMSEQ    <-> "vmseq.vv",
  VVCMP_VMSNE    <-> "vmsne.vv",
  VVCMP_VMSLTU   <-> "vmsltu.vv",
  VVCMP_VMSLT    <-> "vmslt.vv",
  VVCMP_VMSLEU   <-> "vmsleu.vv",
  VVCMP_VMSLE    <-> "vmsle.vv"
}

mapping clause assembly = VVCMPTYPE(funct6, vm, vs2, vs1, vd)
  <-> vvcmptype_mnemonic(funct6) ^ spc() ^ vreg_name(vd) ^ sep() ^ vreg_name(vs2) ^ sep() ^ vreg_name(vs1) ^ maybe_vmask(vm)

/* ******************************* OPIVX (VXMTYPE) ******************************* */
/* VXM instructions' destination is a mask register (e.g. carry out) */
/* Instructions with no carry out will set mask result to current mask value */
/* May or may not read from source mask register (e.g. carry in) */
union clause ast = VXMTYPE : (vxmfunct6, regidx, regidx, regidx)

mapping encdec_vxmfunct6 : vxmfunct6 <-> bits(6) = {
  VXM_VMADC    <-> 0b010001, /* carry in, carry out */
  VXM_VMSBC    <-> 0b010011
}

mapping clause encdec = VXMTYPE(funct6, vs2, rs1, vd) if extensionEnabled(Ext_V)
  <-> encdec_vxmfunct6(funct6) @ 0b0 @ vs2 @ rs1 @ 0b100 @ vd @ 0b1010111 if extensionEnabled(Ext_V)

function clause execute(VXMTYPE(funct6, vs2, rs1, vd)) = {
  let SEW      = get_sew();
  let LMUL_pow = get_lmul_pow();
  let num_elem = get_num_elem(LMUL_pow, SEW);

  if illegal_vd_unmasked() then { handle_illegal(); return RETIRE_FAIL };

  let 'n = num_elem;
  let 'm = SEW;

  let vm_val  : bits('n)     = read_vmask_carry(num_elem, 0b0, 0b00000);
  let rs1_val : bits('m)                  = get_scalar(rs1, SEW);
  let vs2_val : vector('n, bits('m)) = read_vreg(num_elem, SEW, LMUL_pow, vs2);
  let vd_val  : bits('n)     = read_vmask(num_elem, 0b0, vd);

  let (initial_result, mask) = init_masked_result_carry(num_elem, SEW, LMUL_pow, vd_val);
  var result = initial_result;

  foreach (i from 0 to (num_elem - 1)) {
    if mask[i] == bitone then {
      let res : bool = match funct6 {
        VXM_VMADC    => unsigned(vs2_val[i]) + unsigned(rs1_val) + (if vm_val[i] == bitone then 1 else 0) > 2 ^ SEW - 1,
        VXM_VMSBC    => unsigned(vs2_val[i]) - unsigned(rs1_val) - (if vm_val[i] == bitone then 1 else 0) < 0
      };
      result[i] = bool_to_bit(res)
    }
  };

  write_vmask(num_elem, vd, result);
  vstart = zeros();
  RETIRE_SUCCESS
}

mapping vxmtype_mnemonic : vxmfunct6 <-> string = {
  VXM_VMADC    <-> "vmadc.vxm", /* carry in, carry out */
  VXM_VMSBC    <-> "vmsbc.vxm"
}

mapping clause assembly = VXMTYPE(funct6, vs2, rs1, vd)
  <-> vxmtype_mnemonic(funct6) ^ spc() ^ vreg_name(vd) ^ sep() ^ vreg_name(vs2) ^ sep() ^ reg_name(rs1) ^ sep() ^ "v0"

/* ****************************** OPIVX (VXMCTYPE) ******************************* */
/* VXMC instructions' destination is a mask register (e.g. carry out) */
/* Instructions with no carry out will set mask result to current mask value */
/* May or may not read from source mask register (e.g. carry in) */
union clause ast = VXMCTYPE : (vxmcfunct6, regidx, regidx, regidx)

mapping encdec_vxmcfunct6 : vxmcfunct6 <-> bits(6) = {
  VXMC_VMADC    <-> 0b010001, /* carry in, carry out */
  VXMC_VMSBC    <-> 0b010011
}

mapping clause encdec = VXMCTYPE(funct6, vs2, rs1, vd) if extensionEnabled(Ext_V)
  <-> encdec_vxmcfunct6(funct6) @ 0b1 @ vs2 @ rs1 @ 0b100 @ vd @ 0b1010111 if extensionEnabled(Ext_V)

function clause execute(VXMCTYPE(funct6, vs2, rs1, vd)) = {
  let SEW      = get_sew();
  let LMUL_pow = get_lmul_pow();
  let num_elem = get_num_elem(LMUL_pow, SEW);

  if illegal_vd_unmasked() then { handle_illegal(); return RETIRE_FAIL };

  let 'n = num_elem;
  let 'm = SEW;

  let rs1_val : bits('m)                  = get_scalar(rs1, SEW);
  let vs2_val : vector('n, bits('m)) = read_vreg(num_elem, SEW, LMUL_pow, vs2);
  let vd_val  : bits('n)     = read_vmask(num_elem, 0b0, vd);

  let (initial_result, mask) = init_masked_result_carry(num_elem, SEW, LMUL_pow, vd_val);
  var result = initial_result;

  foreach (i from 0 to (num_elem - 1)) {
    if mask[i] == bitone then {
      let res : bool = match funct6 {
        VXMC_VMADC    => unsigned(vs2_val[i]) + unsigned(rs1_val) > 2 ^ SEW - 1,
        VXMC_VMSBC    => unsigned(vs2_val[i]) - unsigned(rs1_val) < 0
      };
      result[i] = bool_to_bit(res)
    }
  };

  write_vmask(num_elem, vd, result);
  vstart = zeros();
  RETIRE_SUCCESS
}

mapping vxmctype_mnemonic : vxmcfunct6 <-> string = {
  VXMC_VMADC    <-> "vmadc.vx", /* carry in, carry out */
  VXMC_VMSBC    <-> "vmsbc.vx"
}

mapping clause assembly = VXMCTYPE(funct6, vs2, rs1, vd)
  <-> vxmctype_mnemonic(funct6) ^ spc() ^ vreg_name(vd) ^ sep() ^ vreg_name(vs2) ^ sep() ^ reg_name(rs1)

/* ****************************** OPIVX (VXMSTYPE) ******************************* */
/* VXMS instructions' destination is a vector register (e.g. actual sum) */
/* Instructions with no carry out will set mask result to current mask value */
/* May or may not read from source mask register (e.g. carry in) */
union clause ast = VXMSTYPE : (vxmsfunct6, regidx, regidx, regidx)

mapping encdec_vxmsfunct6 : vxmsfunct6 <-> bits(6) = {
  VXMS_VADC     <-> 0b010000, /* carry in, no carry out */
  VXMS_VSBC     <-> 0b010010
}

mapping clause encdec = VXMSTYPE(funct6, vs2, rs1, vd) if extensionEnabled(Ext_V)
  <-> encdec_vxmsfunct6(funct6) @ 0b0 @ vs2 @ rs1 @ 0b100 @ vd @ 0b1010111 if extensionEnabled(Ext_V)

function clause execute(VXMSTYPE(funct6, vs2, rs1, vd)) = {
  let SEW      = get_sew();
  let LMUL_pow = get_lmul_pow();
  let num_elem = get_num_elem(LMUL_pow, SEW);

  if illegal_vd_masked(vd) then { handle_illegal(); return RETIRE_FAIL };

  let 'n = num_elem;
  let 'm = SEW;

  /* for bypassing normal masking in init_masked_result */
  let vec_trues : bits('n) = ones();

  let vm_val  : bits('n)     = read_vmask_carry(num_elem, 0b0, 0b00000);
  let rs1_val : bits('m)                  = get_scalar(rs1, SEW);
  let vs2_val : vector('n, bits('m)) = read_vreg(num_elem, SEW, LMUL_pow, vs2);
  let vd_val  : vector('n, bits('m)) = read_vreg(num_elem, SEW, LMUL_pow, vd);

  let (initial_result, mask) = init_masked_result(num_elem, SEW, LMUL_pow, vd_val, vec_trues);
  var result = initial_result;

  foreach (i from 0 to (num_elem - 1)) {
    if mask[i] == bitone then {
      result[i] = match funct6 {
        VXMS_VADC     => to_bits(SEW, unsigned(vs2_val[i]) + unsigned(rs1_val) + (if vm_val[i] == bitone then 1 else 0)),
        VXMS_VSBC     => to_bits(SEW, unsigned(vs2_val[i]) - unsigned(rs1_val) - (if vm_val[i] == bitone then 1 else 0))
      }
    }
  };

  write_vreg(num_elem, SEW, LMUL_pow, vd, result);
  vstart = zeros();
  RETIRE_SUCCESS
}

mapping vxmstype_mnemonic : vxmsfunct6 <-> string = {
  VXMS_VADC     <-> "vadc.vxm", /* carry in, no carry out */
  VXMS_VSBC     <-> "vsbc.vxm"
}

mapping clause assembly = VXMSTYPE(funct6, vs2, rs1, vd)
  <-> vxmstype_mnemonic(funct6) ^ spc() ^ vreg_name(vd) ^ sep() ^ vreg_name(vs2) ^ sep() ^ reg_name(rs1) ^ sep() ^ "v0"

/* ***************** OPIVX (Vector Integer Compare Instructions) ***************** */
/* VXCMP instructions' destination is a mask register */
union clause ast = VXCMPTYPE : (vxcmpfunct6, bits(1), regidx, regidx, regidx)

mapping encdec_vxcmpfunct6 : vxcmpfunct6 <-> bits(6) = {
  VXCMP_VMSEQ    <-> 0b011000,
  VXCMP_VMSNE    <-> 0b011001,
  VXCMP_VMSLTU   <-> 0b011010,
  VXCMP_VMSLT    <-> 0b011011,
  VXCMP_VMSLEU   <-> 0b011100,
  VXCMP_VMSLE    <-> 0b011101,
  VXCMP_VMSGTU   <-> 0b011110,
  VXCMP_VMSGT    <-> 0b011111
}

mapping clause encdec = VXCMPTYPE(funct6, vm, vs2, rs1, vd) if extensionEnabled(Ext_V)
  <-> encdec_vxcmpfunct6(funct6) @ vm @ vs2 @ rs1 @ 0b100 @ vd @ 0b1010111 if extensionEnabled(Ext_V)

function clause execute(VXCMPTYPE(funct6, vm, vs2, rs1, vd)) = {
  let SEW      = get_sew();
  let LMUL_pow = get_lmul_pow();
  let num_elem = get_num_elem(LMUL_pow, SEW);

  if illegal_vd_unmasked() then { handle_illegal(); return RETIRE_FAIL };

  let 'n = num_elem;
  let 'm = SEW;

  let vm_val  : bits('n)     = read_vmask(num_elem, vm, 0b00000);
  let rs1_val : bits('m)                  = get_scalar(rs1, SEW);
  let vs2_val : vector('n, bits('m)) = read_vreg(num_elem, SEW, LMUL_pow, vs2);
  let vd_val  : bits('n)     = read_vmask(num_elem, 0b0, vd);

  let (initial_result, mask) = init_masked_result_cmp(num_elem, SEW, LMUL_pow, vd_val, vm_val);
  var result = initial_result;

  foreach (i from 0 to (num_elem - 1)) {
    if mask[i] == bitone then {
      let res : bool = match funct6 {
        VXCMP_VMSEQ    => vs2_val[i] == rs1_val,
        VXCMP_VMSNE    => vs2_val[i] != rs1_val,
        VXCMP_VMSLTU   => unsigned(vs2_val[i]) < unsigned(rs1_val),
        VXCMP_VMSLT    => signed(vs2_val[i]) < signed(rs1_val),
        VXCMP_VMSLEU   => unsigned(vs2_val[i]) <= unsigned(rs1_val),
        VXCMP_VMSLE    => signed(vs2_val[i]) <= signed(rs1_val),
        VXCMP_VMSGTU   => unsigned(vs2_val[i]) > unsigned(rs1_val),
        VXCMP_VMSGT    => signed(vs2_val[i]) > signed(rs1_val)
      };
      result[i] = bool_to_bit(res)
    }
  };

  write_vmask(num_elem, vd, result);
  vstart = zeros();
  RETIRE_SUCCESS
}

mapping vxcmptype_mnemonic : vxcmpfunct6 <-> string = {
  VXCMP_VMSEQ    <-> "vmseq.vx",
  VXCMP_VMSNE    <-> "vmsne.vx",
  VXCMP_VMSLTU   <-> "vmsltu.vx",
  VXCMP_VMSLT    <-> "vmslt.vx",
  VXCMP_VMSLEU   <-> "vmsleu.vx",
  VXCMP_VMSLE    <-> "vmsle.vx",
  VXCMP_VMSGTU   <-> "vmsgtu.vx",
  VXCMP_VMSGT    <-> "vmsgt.vx"
}

mapping clause assembly = VXCMPTYPE(funct6, vm, vs2, rs1, vd)
  <-> vxcmptype_mnemonic(funct6) ^ spc() ^ vreg_name(vd) ^ sep() ^ vreg_name(vs2) ^ sep() ^ reg_name(rs1) ^ maybe_vmask(vm)

/* ******************************* OPIVI (VIMTYPE) ******************************* */
/* VIM instructions' destination is a mask register (e.g. carry out) */
/* Instructions with no carry out will set mask result to current mask value */
/* May or may not read from source mask register (e.g. carry in) */
union clause ast = VIMTYPE : (vimfunct6, regidx, regidx, regidx)

mapping encdec_vimfunct6 : vimfunct6 <-> bits(6) = {
  VIM_VMADC    <-> 0b010001 /* carry in, carry out */
}

mapping clause encdec = VIMTYPE(funct6, vs2, simm, vd) if extensionEnabled(Ext_V)
  <-> encdec_vimfunct6(funct6) @ 0b0 @ vs2 @ simm @ 0b011 @ vd @ 0b1010111 if extensionEnabled(Ext_V)

function clause execute(VIMTYPE(funct6, vs2, simm, vd)) = {
  let SEW      = get_sew();
  let LMUL_pow = get_lmul_pow();
  let num_elem = get_num_elem(LMUL_pow, SEW);

  if illegal_vd_unmasked() then { handle_illegal(); return RETIRE_FAIL };

  let 'n = num_elem;
  let 'm = SEW;

  let vm_val  : bits('n)     = read_vmask_carry(num_elem, 0b0, 0b00000);
  let imm_val : bits('m)                  = sign_extend(simm);
  let vs2_val : vector('n, bits('m)) = read_vreg(num_elem, SEW, LMUL_pow, vs2);
  let vd_val  : bits('n)     = read_vmask(num_elem, 0b0, vd);

  let (initial_result, mask) = init_masked_result_carry(num_elem, SEW, LMUL_pow, vd_val);
  var result = initial_result;

  foreach (i from 0 to (num_elem - 1)) {
    if mask[i] == bitone then {
      let res : bool = match funct6 {
        VIM_VMADC    => unsigned(vs2_val[i]) + unsigned(imm_val) + (if vm_val[i] == bitone then 1 else 0) > 2 ^ SEW - 1
      };
      result[i] = bool_to_bit(res)
    }
  };

  write_vmask(num_elem, vd, result);
  vstart = zeros();
  RETIRE_SUCCESS
}

mapping vimtype_mnemonic : vimfunct6 <-> string = {
  VIM_VMADC    <-> "vmadc.vim" /* carry in, carry out */
}

mapping clause assembly = VIMTYPE(funct6, vs2, simm, vd)
  <-> vimtype_mnemonic(funct6) ^ spc() ^ vreg_name(vd) ^ sep() ^ vreg_name(vs2) ^ sep() ^ hex_bits_5(simm) ^ sep() ^ "v0"

/* ****************************** OPIVI (VIMCTYPE) ******************************* */
/* VIMC instructions' destination is a mask register (e.g. carry out) */
/* Instructions with no carry out will set mask result to current mask value */
/* May or may not read from source mask register (e.g. carry in) */
union clause ast = VIMCTYPE : (vimcfunct6, regidx, regidx, regidx)

mapping encdec_vimcfunct6 : vimcfunct6 <-> bits(6) = {
  VIMC_VMADC    <-> 0b010001 /* carry in, carry out */
}

mapping clause encdec = VIMCTYPE(funct6, vs2, simm, vd) if extensionEnabled(Ext_V)
  <-> encdec_vimcfunct6(funct6) @ 0b1 @ vs2 @ simm @ 0b011 @ vd @ 0b1010111 if extensionEnabled(Ext_V)

function clause execute(VIMCTYPE(funct6, vs2, simm, vd)) = {
  let SEW      = get_sew();
  let LMUL_pow = get_lmul_pow();
  let num_elem = get_num_elem(LMUL_pow, SEW);

  if illegal_vd_unmasked() then { handle_illegal(); return RETIRE_FAIL };

  let 'n = num_elem;
  let 'm = SEW;

  let imm_val : bits('m)                  = sign_extend(simm);
  let vs2_val : vector('n, bits('m)) = read_vreg(num_elem, SEW, LMUL_pow, vs2);
  let vd_val  : bits('n)     = read_vmask(num_elem, 0b0, vd);

  let (initial_result, mask) = init_masked_result_carry(num_elem, SEW, LMUL_pow, vd_val);
  var result = initial_result;

  foreach (i from 0 to (num_elem - 1)) {
    if mask[i] == bitone then {
      let res : bool = match funct6 {
        VIMC_VMADC    => unsigned(vs2_val[i]) + unsigned(imm_val) > 2 ^ SEW - 1
      };
      result[i] = bool_to_bit(res)
    }
  };

  write_vmask(num_elem, vd, result);
  vstart = zeros();
  RETIRE_SUCCESS
}

mapping vimctype_mnemonic : vimcfunct6 <-> string = {
  VIMC_VMADC    <-> "vmadc.vi" /* Carry in, carry out */
}

mapping clause assembly = VIMCTYPE(funct6, vs2, simm, vd)
  <-> vimctype_mnemonic(funct6) ^ spc() ^ vreg_name(vd) ^ sep() ^ vreg_name(vs2) ^ sep() ^ hex_bits_5(simm)

/* ****************************** OPIVI (VIMSTYPE) ******************************* */
/* VIMS instructions' destination is a vector register (e.g. actual sum) */
/* Instructions with no carry out will set mask result to current mask value */
/* May or may not read from source mask register (e.g. carry in) */
union clause ast = VIMSTYPE : (vimsfunct6, regidx, regidx, regidx)

mapping encdec_vimsfunct6 : vimsfunct6 <-> bits(6) = {
  VIMS_VADC     <-> 0b010000 /* Carry in, no carry out */
}

mapping clause encdec = VIMSTYPE(funct6, vs2, simm, vd) if extensionEnabled(Ext_V)
  <-> encdec_vimsfunct6(funct6) @ 0b0 @ vs2 @ simm @ 0b011 @ vd @ 0b1010111 if extensionEnabled(Ext_V)

function clause execute(VIMSTYPE(funct6, vs2, simm, vd)) = {
  let SEW      = get_sew();
  let LMUL_pow = get_lmul_pow();
  let num_elem = get_num_elem(LMUL_pow, SEW);

  if illegal_vd_masked(vd) then { handle_illegal(); return RETIRE_FAIL };

  let 'n = num_elem;
  let 'm = SEW;

  /* for bypassing normal masking in init_masked_result */
  let vec_trues : bits('n) = ones();

  let vm_val  : bits('n)     = read_vmask_carry(num_elem, 0b0, 0b00000);
  let imm_val : bits('m)                  = sign_extend(simm);
  let vs2_val : vector('n, bits('m)) = read_vreg(num_elem, SEW, LMUL_pow, vs2);
  let vd_val  : vector('n, bits('m)) = read_vreg(num_elem, SEW, LMUL_pow, vd);

  let (initial_result, mask) = init_masked_result(num_elem, SEW, LMUL_pow, vd_val, vec_trues);
  var result = initial_result;

  foreach (i from 0 to (num_elem - 1)) {
    if mask[i] == bitone then {
      result[i] = match funct6 {
        VIMS_VADC     => to_bits(SEW, unsigned(vs2_val[i]) + unsigned(imm_val) + (if vm_val[i] == bitone then 1 else 0))
      }
    }
  };

  write_vreg(num_elem, SEW, LMUL_pow, vd, result);
  vstart = zeros();
  RETIRE_SUCCESS
}

mapping vimstype_mnemonic : vimsfunct6 <-> string = {
  VIMS_VADC     <-> "vadc.vim" /* Carry in, no carry out */
}

mapping clause assembly = VIMSTYPE(funct6, vs2, simm, vd)
  <-> vimstype_mnemonic(funct6) ^ spc() ^ vreg_name(vd) ^ sep() ^ vreg_name(vs2) ^ sep() ^ hex_bits_5(simm) ^ sep() ^ "v0"

/* ***************** OPIVI (Vector Integer Compare Instructions) ***************** */
/* VICMP instructions' destination is a mask register */
union clause ast = VICMPTYPE : (vicmpfunct6, bits(1), regidx, regidx, regidx)

mapping encdec_vicmpfunct6 : vicmpfunct6 <-> bits(6) = {
  VICMP_VMSEQ    <-> 0b011000,
  VICMP_VMSNE    <-> 0b011001,
  VICMP_VMSLEU   <-> 0b011100,
  VICMP_VMSLE    <-> 0b011101,
  VICMP_VMSGTU   <-> 0b011110,
  VICMP_VMSGT    <-> 0b011111
}

mapping clause encdec = VICMPTYPE(funct6, vm, vs2, simm, vd) if extensionEnabled(Ext_V)
  <-> encdec_vicmpfunct6(funct6) @ vm @ vs2 @ simm @ 0b011 @ vd @ 0b1010111 if extensionEnabled(Ext_V)

function clause execute(VICMPTYPE(funct6, vm, vs2, simm, vd)) = {
  let SEW      = get_sew();
  let LMUL_pow = get_lmul_pow();
  let num_elem = get_num_elem(LMUL_pow, SEW);

  if illegal_vd_unmasked() then { handle_illegal(); return RETIRE_FAIL };

  let 'n = num_elem;
  let 'm = SEW;

  let vm_val  : bits('n)     = read_vmask(num_elem, vm, 0b00000);
  let imm_val : bits('m)                  = sign_extend(simm);
  let vs2_val : vector('n, bits('m)) = read_vreg(num_elem, SEW, LMUL_pow, vs2);
  let vd_val  : bits('n)     = read_vmask(num_elem, 0b0, vd);

  let (initial_result, mask) = init_masked_result_cmp(num_elem, SEW, LMUL_pow, vd_val, vm_val);
  var result = initial_result;

  foreach (i from 0 to (num_elem - 1)) {
    if mask[i] == bitone then {
      let res : bool = match funct6 {
        VICMP_VMSEQ    => vs2_val[i] == imm_val,
        VICMP_VMSNE    => vs2_val[i] != imm_val,
        VICMP_VMSLEU   => unsigned(vs2_val[i]) <= unsigned(imm_val),
        VICMP_VMSLE    => signed(vs2_val[i]) <= signed(imm_val),
        VICMP_VMSGTU   => unsigned(vs2_val[i]) > unsigned(imm_val),
        VICMP_VMSGT    => signed(vs2_val[i]) > signed(imm_val)
      };
      result[i] = bool_to_bit(res)
    }
  };

  write_vmask(num_elem, vd, result);
  vstart = zeros();
  RETIRE_SUCCESS
}

mapping vicmptype_mnemonic : vicmpfunct6 <-> string = {
  VICMP_VMSEQ    <-> "vmseq.vi",
  VICMP_VMSNE    <-> "vmsne.vi",
  VICMP_VMSLEU   <-> "vmsleu.vi",
  VICMP_VMSLE    <-> "vmsle.vi",
  VICMP_VMSGTU   <-> "vmsgtu.vi",
  VICMP_VMSGT    <-> "vmsgt.vi"
}

mapping clause assembly = VICMPTYPE(funct6, vm, vs2, simm, vd)
  <-> vicmptype_mnemonic(funct6) ^ spc() ^ vreg_name(vd) ^ sep() ^ vreg_name(vs2) ^ sep() ^ hex_bits_5(simm) ^ maybe_vmask(vm)
