/* ******************************************************************************* */
/* This file implements part of the vector extension.                              */
/* Mask instructions from Chap 11 (integer arithmetic) and 13 (floating-point)     */

/* ******************************************************************************* */

/* **************************VVMTYPE**************************************** */
/* VVM instructions' destination is a mask register (e.g. carry out) */
/* Instructions with no carry out will set mask result to current mask value */
/* May or may not read from source mask register (e.g. carry in) */

union clause ast = VVMTYPE : (vvmfunct6, regidx, regidx, regidx)

mapping encdec_vvmfunct6 : vvmfunct6 <-> bits(6) = {
  VVM_VMADC    <-> 0b010001, /* Carry in, carry out */
  VVM_VMSBC    <-> 0b010011
}

mapping clause encdec = VVMTYPE(funct6, vs2, vs1, vd)
  <-> encdec_vvmfunct6(funct6) @ 0b0 @ vs2 @ vs1 @ 0b000 @ vd @ 0b1010111

function clause execute(VVMTYPE(funct6, vs2, vs1, vd)) = {
  status          : Retired = RETIRE_SUCCESS;
  let vsew_bits  : int  = get_vtype_vsew();
  let lmul       : real = get_vtype_LMUL();
  let num_elem   : int  = get_num_elem(lmul, vsew_bits);

  assert(8 <= vsew_bits & vsew_bits <= 64);
  assert(0 <= num_elem & num_elem <= sizeof(vlen));
  let 'n = num_elem;
  let 'm = vsew_bits;

  let vm_val   : vector('n, dec, bool)     = read_vmask_carry(num_elem, 0b0, vreg_name("v0"));
  let vs1_val  : vector('n, dec, bits('m)) = read_vreg(num_elem, vsew_bits, lmul, vs1);
  let vs2_val  : vector('n, dec, bits('m)) = read_vreg(num_elem, vsew_bits, lmul, vs2);
  let vd_val   : vector('n, dec, bool)     = read_vmask(num_elem, 0b0, vd);
  result       : vector('n, dec, bool)     = undefined;
  mask_helper  : vector('n, dec, bool)     = undefined;

  /*if vm_val      == undefined |
     vs1_val     == undefined |
     vs2_val     == undefined |
     vd_val      == undefined |
     mask_helper == undefined then {
    status = RETIRE_FAIL
  };*/

  if status == RETIRE_SUCCESS then {
    (result, mask_helper) = init_masked_result_carry(num_elem, vsew_bits, lmul, vd_val);
  
    foreach (i from 0 to (num_elem - 1)) {
      if mask_helper[i] == true then {
        let resval : bool = match funct6 {
          VVM_VMADC    => if unsigned(vs2_val[i]) + unsigned(vs1_val[i]) + unsigned(bool_to_bits(vm_val[i])) > 2 ^ vsew_bits - 1 then true else false,
          VVM_VMSBC    => if unsigned(vs2_val[i]) - unsigned(vs1_val[i]) - unsigned(bool_to_bits(vm_val[i])) < 0 then true else false
        };
        result[i] = resval
      }
    };
  
    write_vmask(num_elem, vd, result)
  };
  
  if status == RETIRE_FAIL then handle_illegal();
  status
}

mapping vvmtype_mnemonic : vvmfunct6 <-> string = {
  VVM_VMADC    <-> "vmadc.vvm", /* Carry in, carry out */
  VVM_VMSBC    <-> "vmsbc.vvm"
}

mapping clause assembly = VVMTYPE(funct6, vs2, vs1, vd)
  <-> vvmtype_mnemonic(funct6) ^ spc() ^ vreg_name(vd) ^ sep() ^ vreg_name(vs2) ^ sep() ^ vreg_name(vs1) ^ sep() ^ "v0"


/* **************************VVMCTYPE**************************************** */
/* VVMC instructions' destination is a mask register (e.g. carry out) */
/* Instructions with no carry out will set mask result to current mask value */
/* May or may not read from source mask register (e.g. carry in) */

union clause ast = VVMCTYPE : (vvmcfunct6, regidx, regidx, regidx)

mapping encdec_vvmcfunct6 : vvmcfunct6 <-> bits(6) = {
  VVMC_VMADC    <-> 0b010001, /* Carry in, carry out */
  VVMC_VMSBC    <-> 0b010011
}

mapping clause encdec = VVMCTYPE(funct6, vs2, vs1, vd)
  <-> encdec_vvmcfunct6(funct6) @ 0b1 @ vs2 @ vs1 @ 0b000 @ vd @ 0b1010111

function clause execute(VVMCTYPE(funct6, vs2, vs1, vd)) = {
  status          : Retired = RETIRE_SUCCESS;
  let vsew_bits  : int  = get_vtype_vsew();
  let lmul       : real = get_vtype_LMUL();
  let num_elem   : int  = get_num_elem(lmul, vsew_bits);

  assert(8 <= vsew_bits & vsew_bits <= 64);
  assert(0 <= num_elem & num_elem <= sizeof(vlen));
  let 'n = num_elem;
  let 'm = vsew_bits;

  let vs1_val  : vector('n, dec, bits('m)) = read_vreg(num_elem, vsew_bits, lmul, vs1);
  let vs2_val  : vector('n, dec, bits('m)) = read_vreg(num_elem, vsew_bits, lmul, vs2);
  let vd_val   : vector('n, dec, bool)     = read_vmask(num_elem, 0b0, vd);
  result       : vector('n, dec, bool)     = undefined;
  mask_helper  : vector('n, dec, bool)     = undefined;

  /*if vs1_val     == undefined |
     vs2_val     == undefined |
     vd_val      == undefined |
     mask_helper == undefined then {
    status = RETIRE_FAIL
  };*/

  if status == RETIRE_SUCCESS then {
    (result, mask_helper) = init_masked_result_carry(num_elem, vsew_bits, lmul, vd_val);
  
    foreach (i from 0 to (num_elem - 1)) {
      if mask_helper[i] == true then {
        let resval : bool = match funct6 {
          VVMC_VMADC    => if unsigned(vs2_val[i]) + unsigned(vs1_val[i]) > 2 ^ vsew_bits - 1 then true else false,
          VVMC_VMSBC    => if unsigned(vs2_val[i]) - unsigned(vs1_val[i]) < 0 then true else false
        };
        result[i] = resval
      }
    };
  
    write_vmask(num_elem, vd, result)
  };
  
  if status == RETIRE_FAIL then handle_illegal();
  status
}

mapping vvmctype_mnemonic : vvmcfunct6 <-> string = {
  VVMC_VMADC    <-> "vmadc.vv", /* No carry in, carry out */
  VVMC_VMSBC    <-> "vmsbc.vv"
}

mapping clause assembly = VVMCTYPE(funct6, vs2, vs1, vd)
  <-> vvmctype_mnemonic(funct6) ^ spc() ^ vreg_name(vd) ^ sep() ^ vreg_name(vs2) ^ sep() ^ vreg_name(vs1)


/* **************************VVMSTYPE**************************************** */
/* VVMS instructions' destination is a vector register (e.g. actual sum) */
/* Instructions with no carry out will set mask result to current mask value */
/* May or may not read from source mask register (e.g. carry in) */

union clause ast = VVMSTYPE : (vvmsfunct6, regidx, regidx, regidx)

mapping encdec_vvmsfunct6 : vvmsfunct6 <-> bits(6) = {
  VVMS_VADC     <-> 0b010000, /* Carry in, no carry out */
  VVMS_VSBC     <-> 0b010010
}

mapping clause encdec = VVMSTYPE(funct6, vs2, vs1, vd)
  <-> encdec_vvmsfunct6(funct6) @ 0b0 @ vs2 @ vs1 @ 0b000 @ vd @ 0b1010111

function clause execute(VVMSTYPE(funct6, vs2, vs1, vd)) = {
  status          : Retired = RETIRE_SUCCESS;
  let vsew_bits  : int  = get_vtype_vsew();
  let lmul       : real = get_vtype_LMUL();
  let num_elem   : int  = get_num_elem(lmul, vsew_bits);

  assert(8 <= vsew_bits & vsew_bits <= 64);
  assert(0 <= num_elem & num_elem <= sizeof(vlen));
  let 'n = num_elem;
  let 'm = vsew_bits;

  vm_val       : vector('n, dec, bool)     = undefined;
  vs1_val      : vector('n, dec, bits('m)) = undefined;
  vs2_val      : vector('n, dec, bits('m)) = undefined;
  vd_val       : vector('n, dec, bits('m)) = undefined;
  result       : vector('n, dec, bits('m)) = undefined;
  mask_helper  : vector('n, dec, bool)     = undefined;

  /* For bypassing vm masking in init_masked_result */
  all_trues : vector('n, dec, bool) = undefined;
  foreach (i from 0 to (num_elem - 1)) {
    all_trues[i] = true
  };

  if vd == vreg_name("v0") then {
    status = RETIRE_FAIL
  };

  if status == RETIRE_SUCCESS then {
    vm_val  = read_vmask_carry(num_elem, 0b0, vreg_name("v0"));
    vs1_val = read_vreg(num_elem, vsew_bits, lmul, vs1);
    vs2_val = read_vreg(num_elem, vsew_bits, lmul, vs2);
    vd_val  = read_vreg(num_elem, vsew_bits, lmul, vd)
  };

  /*if vm_val      == undefined |
     vs1_val     == undefined |
     vs2_val     == undefined |
     vd_val      == undefined |
     mask_helper == undefined then {
    status = RETIRE_FAIL
  };*/

  if status == RETIRE_SUCCESS then {
    (result, mask_helper) = init_masked_result(num_elem, vsew_bits, lmul, vd_val, all_trues);
  
    foreach (i from 0 to (num_elem - 1)) {
      if mask_helper[i] == true then {
        result[i] = match funct6 {
          VVMS_VADC     => to_bits(vsew_bits, signed(vs2_val[i]) + signed(vs1_val[i]) + signed(bool_to_bits(vm_val[i]))),
          VVMS_VSBC     => to_bits(vsew_bits, signed(vs2_val[i]) - signed(vs1_val[i]) - signed(bool_to_bits(vm_val[i])))
        }
      }
    };
  
    write_vreg(num_elem, vsew_bits, lmul, vd, result)
  };
  
  if status == RETIRE_FAIL then handle_illegal();
  status
}

mapping vvmstype_mnemonic : vvmsfunct6 <-> string = {
  VVMS_VADC     <-> "vadc.vvm", /* Carry in, no carry out */
  VVMS_VSBC     <-> "vsbc.vvm"
}

mapping clause assembly = VVMSTYPE(funct6, vs2, vs1, vd)
  <-> vvmstype_mnemonic(funct6) ^ spc() ^ vreg_name(vd) ^ sep() ^ vreg_name(vs2) ^ sep() ^ vreg_name(vs1) ^ sep() ^ "v0"


/* **************************VVCMPTYPE**************************************** */
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

mapping clause encdec = VVCMPTYPE(funct6, vm, vs2, vs1, vd)
  <-> encdec_vvcmpfunct6(funct6) @ vm @ vs2 @ vs1 @ 0b000 @ vd @ 0b1010111

function clause execute(VVCMPTYPE(funct6, vm, vs2, vs1, vd)) = {
  status          : Retired = RETIRE_SUCCESS;
  let vsew_bits  : int  = get_vtype_vsew();
  let lmul       : real = get_vtype_LMUL();
  let num_elem   : int  = get_num_elem(lmul, vsew_bits);

  assert(8 <= vsew_bits & vsew_bits <= 64);
  assert(0 <= num_elem & num_elem <= sizeof(vlen));
  let 'n = num_elem;
  let 'm = vsew_bits;

  let vm_val   : vector('n, dec, bool)     = read_vmask(num_elem, vm, vreg_name("v0"));
  let vs1_val  : vector('n, dec, bits('m)) = read_vreg(num_elem, vsew_bits, lmul, vs1);
  let vs2_val  : vector('n, dec, bits('m)) = read_vreg(num_elem, vsew_bits, lmul, vs2);
  let vd_val   : vector('n, dec, bool)     = read_vmask(num_elem, 0b0, vd);
  result       : vector('n, dec, bool)     = undefined;
  mask_helper  : vector('n, dec, bool)     = undefined;

  if status == RETIRE_SUCCESS then {
    (result, mask_helper) = init_masked_result_cmp(num_elem, vsew_bits, lmul, vd_val, vm_val);
  
    foreach (i from 0 to (num_elem - 1)) {
      if mask_helper[i] == true then {
        let resval : bool = match funct6 {
          VVCMP_VMSEQ    => if vs2_val[i] == vs1_val[i] then true else false,
          VVCMP_VMSNE    => if vs2_val[i] != vs1_val[i] then true else false,
          VVCMP_VMSLTU   => if unsigned(vs2_val[i]) < unsigned(vs1_val[i]) then true else false,
          VVCMP_VMSLT    => if signed(vs2_val[i]) < signed(vs1_val[i]) then true else false,
          VVCMP_VMSLEU   => if unsigned(vs2_val[i]) <= unsigned(vs1_val[i]) then true else false,
          VVCMP_VMSLE    => if signed(vs2_val[i]) <= signed(vs1_val[i]) then true else false
        };
        result[i] = resval
      }
    };
  
    write_vmask(num_elem, vd, result)
  };
  
  if status == RETIRE_FAIL then handle_illegal();
  writeCSR(csr_name_map("vstart"), EXTZ(0b0));
  status
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


/* **************************VXMTYPE**************************************** */
/* VXM instructions' destination is a mask register (e.g. carry out) */
/* Instructions with no carry out will set mask result to current mask value */
/* May or may not read from source mask register (e.g. carry in) */

union clause ast = VXMTYPE : (vxmfunct6, regidx, regidx, regidx)

mapping encdec_vxmfunct6 : vxmfunct6 <-> bits(6) = {
  VXM_VMADC    <-> 0b010001, /* Carry in, carry out */
  VXM_VMSBC    <-> 0b010011
}

mapping clause encdec = VXMTYPE(funct6, vs2, rs1, vd)
  <-> encdec_vxmfunct6(funct6) @ 0b0 @ vs2 @ rs1 @ 0b100 @ vd @ 0b1010111

function clause execute(VXMTYPE(funct6, vs2, rs1, vd)) = {
  status          : Retired = RETIRE_SUCCESS;
  let vsew_bits  : int  = get_vtype_vsew();
  let lmul       : real = get_vtype_LMUL();
  let num_elem   : int  = get_num_elem(lmul, vsew_bits);

  assert(8 <= vsew_bits & vsew_bits <= 64);
  assert(0 <= num_elem & num_elem <= sizeof(vlen));
  let 'n = num_elem;
  let 'm = vsew_bits;

  let vm_val   : vector('n, dec, bool)     = read_vmask_carry(num_elem, 0b0, vreg_name("v0"));
  let rs1_val                              = get_scalar(rs1, vsew_bits);
  let vs2_val  : vector('n, dec, bits('m)) = read_vreg(num_elem, vsew_bits, lmul, vs2);
  let vd_val   : vector('n, dec, bool)     = read_vmask(num_elem, 0b0, vd);
  result       : vector('n, dec, bool)     = undefined;
  mask_helper  : vector('n, dec, bool)     = undefined;

  /*if vm_val      == undefined |
     vs2_val     == undefined |
     vd_val      == undefined |
     mask_helper == undefined then {
    status = RETIRE_FAIL
  };*/

  if status == RETIRE_SUCCESS then {
    (result, mask_helper) = init_masked_result_carry(num_elem, vsew_bits, lmul, vd_val);
  
    foreach (i from 0 to (num_elem - 1)) {
      if mask_helper[i] == true then {
        let resval : bool = match funct6 {
          VXM_VMADC    => if unsigned(vs2_val[i]) + unsigned(rs1_val) + unsigned(bool_to_bits(vm_val[i])) > 2 ^ vsew_bits - 1 then true else false,
          VXM_VMSBC    => if unsigned(vs2_val[i]) - unsigned(rs1_val) - unsigned(bool_to_bits(vm_val[i])) < 0 then true else false
        };
        result[i] = resval
      }
    };
  
    write_vmask(num_elem, vd, result)
  };
  
  if status == RETIRE_FAIL then handle_illegal();
  status
}

mapping vxmtype_mnemonic : vxmfunct6 <-> string = {
  VXM_VMADC    <-> "vmadc.vxm", /* Carry in, carry out */
  VXM_VMSBC    <-> "vmsbc.vxm"
}

mapping clause assembly = VXMTYPE(funct6, vs2, rs1, vd)
  <-> vxmtype_mnemonic(funct6) ^ spc() ^ vreg_name(vd) ^ sep() ^ vreg_name(vs2) ^ sep() ^ reg_name(rs1) ^ sep() ^ "v0"


/* **************************VXMCTYPE**************************************** */
/* VXMC instructions' destination is a mask register (e.g. carry out) */
/* Instructions with no carry out will set mask result to current mask value */
/* May or may not read from source mask register (e.g. carry in) */

union clause ast = VXMCTYPE : (vxmcfunct6, regidx, regidx, regidx)

mapping encdec_vxmcfunct6 : vxmcfunct6 <-> bits(6) = {
  VXMC_VMADC    <-> 0b010001, /* Carry in, carry out */
  VXMC_VMSBC    <-> 0b010011
}

mapping clause encdec = VXMCTYPE(funct6, vs2, rs1, vd)
  <-> encdec_vxmcfunct6(funct6) @ 0b1 @ vs2 @ rs1 @ 0b100 @ vd @ 0b1010111

function clause execute(VXMCTYPE(funct6, vs2, rs1, vd)) = {
  status          : Retired = RETIRE_SUCCESS;
  let vsew_bits  : int  = get_vtype_vsew();
  let lmul       : real = get_vtype_LMUL();
  let num_elem   : int  = get_num_elem(lmul, vsew_bits);

  assert(8 <= vsew_bits & vsew_bits <= 64);
  assert(0 <= num_elem & num_elem <= sizeof(vlen));
  let 'n = num_elem;
  let 'm = vsew_bits;

  let rs1_val                              = get_scalar(rs1, vsew_bits);
  let vs2_val  : vector('n, dec, bits('m)) = read_vreg(num_elem, vsew_bits, lmul, vs2);
  let vd_val   : vector('n, dec, bool)     = read_vmask(num_elem, 0b0, vd);
  result       : vector('n, dec, bool)     = undefined;
  mask_helper  : vector('n, dec, bool)     = undefined;

  /*if vs2_val     == undefined |
     vd_val      == undefined |
     mask_helper == undefined then {
    status = RETIRE_FAIL
  };*/

  if status == RETIRE_SUCCESS then {
    (result, mask_helper) = init_masked_result_carry(num_elem, vsew_bits, lmul, vd_val);
  
    foreach (i from 0 to (num_elem - 1)) {
      if mask_helper[i] == true then {
        let resval : bool = match funct6 {
          VXMC_VMADC    => if unsigned(vs2_val[i]) + unsigned(rs1_val) > 2 ^ vsew_bits - 1 then true else false,
          VXMC_VMSBC    => if unsigned(vs2_val[i]) - unsigned(rs1_val) < 0 then true else false
        };
        result[i] = resval
      }
    };
  
    write_vmask(num_elem, vd, result)
  };
  
  if status == RETIRE_FAIL then handle_illegal();
  status
}

mapping vxmctype_mnemonic : vxmcfunct6 <-> string = {
  VXMC_VMADC    <-> "vmadc.vx", /* Carry in, carry out */
  VXMC_VMSBC    <-> "vmsbc.vx"
}

mapping clause assembly = VXMCTYPE(funct6, vs2, rs1, vd)
  <-> vxmctype_mnemonic(funct6) ^ spc() ^ vreg_name(vd) ^ sep() ^ vreg_name(vs2) ^ sep() ^ reg_name(rs1)


/* **************************VXMSTYPE**************************************** */
/* VXMS instructions' destination is a vector register (e.g. actual sum) */
/* Instructions with no carry out will set mask result to current mask value */
/* May or may not read from source mask register (e.g. carry in) */

union clause ast = VXMSTYPE : (vxmsfunct6, regidx, regidx, regidx)

mapping encdec_vxmsfunct6 : vxmsfunct6 <-> bits(6) = {
  VXMS_VADC     <-> 0b010000, /* Carry in, no carry out */
  VXMS_VSBC     <-> 0b010010
}

mapping clause encdec = VXMSTYPE(funct6, vs2, rs1, vd)
  <-> encdec_vxmsfunct6(funct6) @ 0b0 @ vs2 @ rs1 @ 0b100 @ vd @ 0b1010111

function clause execute(VXMSTYPE(funct6, vs2, rs1, vd)) = {
  status          : Retired = RETIRE_SUCCESS;
  let vsew_bits  : int  = get_vtype_vsew();
  let lmul       : real = get_vtype_LMUL();
  let num_elem   : int  = get_num_elem(lmul, vsew_bits);

  assert(8 <= vsew_bits & vsew_bits <= 64);
  assert(0 <= num_elem & num_elem <= sizeof(vlen));
  let 'n = num_elem;
  let 'm = vsew_bits;

  vm_val       : vector('n, dec, bool)     = undefined;
  rs1_val                                  = get_scalar(rs1, vsew_bits);
  vs2_val      : vector('n, dec, bits('m)) = undefined;
  vd_val       : vector('n, dec, bits('m)) = undefined;
  result       : vector('n, dec, bits('m)) = undefined;
  mask_helper  : vector('n, dec, bool)     = undefined;

  /* For bypassing vm masking in init_masked_result */
  all_trues : vector('n, dec, bool) = undefined;
  foreach (i from 0 to (num_elem - 1)) {
    all_trues[i] = true
  };

  if vd == vreg_name("v0") then {
    status = RETIRE_FAIL
  };

  if status == RETIRE_SUCCESS then {
    vm_val  = read_vmask_carry(num_elem, 0b0, vreg_name("v0"));
    vs2_val = read_vreg(num_elem, vsew_bits, lmul, vs2);
    vd_val  = read_vreg(num_elem, vsew_bits, lmul, vd)
  };

  /*if vm_val      == undefined |
     vs2_val     == undefined |
     vd_val      == undefined |
     mask_helper == undefined then {
    status = RETIRE_FAIL
  };*/

  if status == RETIRE_SUCCESS then {
    (result, mask_helper) = init_masked_result(num_elem, vsew_bits, lmul, vd_val, all_trues);
  
    foreach (i from 0 to (num_elem - 1)) {
      if mask_helper[i] == true then {
        result[i] = match funct6 {
          VXMS_VADC     => to_bits(vsew_bits, signed(vs2_val[i]) + signed(rs1_val) + signed(bool_to_bits(vm_val[i]))),
          VXMS_VSBC     => to_bits(vsew_bits, signed(vs2_val[i]) - signed(rs1_val) - signed(bool_to_bits(vm_val[i])))
        }
      }
    };
  
    write_vreg(num_elem, vsew_bits, lmul, vd, result)
  };
  
  if status == RETIRE_FAIL then handle_illegal();
  status
}

mapping vxmstype_mnemonic : vxmsfunct6 <-> string = {
  VXMS_VADC     <-> "vadc.vxm", /* Carry in, no carry out */
  VXMS_VSBC     <-> "vsbc.vxm"
}

mapping clause assembly = VXMSTYPE(funct6, vs2, rs1, vd)
  <-> vxmstype_mnemonic(funct6) ^ spc() ^ vreg_name(vd) ^ sep() ^ vreg_name(vs2) ^ sep() ^ reg_name(rs1) ^ sep() ^ "v0"


/* **************************VXCMPTYPE**************************************** */
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

mapping clause encdec = VXCMPTYPE(funct6, vm, vs2, rs1, vd)
  <-> encdec_vxcmpfunct6(funct6) @ vm @ vs2 @ rs1 @ 0b100 @ vd @ 0b1010111

function clause execute(VXCMPTYPE(funct6, vm, vs2, rs1, vd)) = {
  status          : Retired = RETIRE_SUCCESS;
  let vsew_bits  : int  = get_vtype_vsew();
  let lmul       : real = get_vtype_LMUL();
  let num_elem   : int  = get_num_elem(lmul, vsew_bits);

  assert(8 <= vsew_bits & vsew_bits <= 64);
  assert(0 <= num_elem & num_elem <= sizeof(vlen));
  let 'n = num_elem;
  let 'm = vsew_bits;

  let vm_val   : vector('n, dec, bool)     = read_vmask(num_elem, vm, vreg_name("v0"));
  let rs1_val                              = get_scalar(rs1, vsew_bits);
  let vs2_val  : vector('n, dec, bits('m)) = read_vreg(num_elem, vsew_bits, lmul, vs2);
  let vd_val   : vector('n, dec, bool)     = read_vmask(num_elem, 0b0, vd);
  result       : vector('n, dec, bool)     = undefined;
  mask_helper  : vector('n, dec, bool)     = undefined;

  if status == RETIRE_SUCCESS then {
    (result, mask_helper) = init_masked_result_cmp(num_elem, vsew_bits, lmul, vd_val, vm_val);
    
    foreach (i from 0 to (num_elem - 1)) {
      if mask_helper[i] == true then {
        let resval : bool = match funct6 {
          VXCMP_VMSEQ    => if vs2_val[i] == rs1_val then true else false,
          VXCMP_VMSNE    => if vs2_val[i] != rs1_val then true else false,
          VXCMP_VMSLTU   => if unsigned(vs2_val[i]) < unsigned(rs1_val) then true else false,
          VXCMP_VMSLT    => if signed(vs2_val[i]) < signed(rs1_val) then true else false,
          VXCMP_VMSLEU   => if unsigned(vs2_val[i]) <= unsigned(rs1_val) then true else false,
          VXCMP_VMSLE    => if signed(vs2_val[i]) <= signed(rs1_val) then true else false,
          VXCMP_VMSGTU   => if unsigned(vs2_val[i]) > unsigned(rs1_val) then true else false,
          VXCMP_VMSGT    => if signed(vs2_val[i]) > signed(rs1_val) then true else false
        };
        result[i] = resval
      }
    };
  
    write_vmask(num_elem, vd, result)
  };
  
  if status == RETIRE_FAIL then handle_illegal();
  writeCSR(csr_name_map("vstart"), EXTZ(0b0));
  status
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


/* **************************VIMTYPE**************************************** */
/* VIM instructions' destination is a mask register (e.g. carry out) */
/* Instructions with no carry out will set mask result to current mask value */
/* May or may not read from source mask register (e.g. carry in) */

union clause ast = VIMTYPE : (vimfunct6, regidx, regidx, regidx)

mapping encdec_vimfunct6 : vimfunct6 <-> bits(6) = {
  VIM_VMADC    <-> 0b010001 /* Carry in, carry out */
}

mapping clause encdec = VIMTYPE(funct6, vs2, simm, vd)
  <-> encdec_vimfunct6(funct6) @ 0b0 @ vs2 @ simm @ 0b011 @ vd @ 0b1010111

function clause execute(VIMTYPE(funct6, vs2, simm, vd)) = {
  status          : Retired = RETIRE_SUCCESS;
  let vsew_bits  : int  = get_vtype_vsew();
  let lmul       : real = get_vtype_LMUL();
  let num_elem   : int  = get_num_elem(lmul, vsew_bits);

  assert(8 <= vsew_bits & vsew_bits <= 64);
  assert(0 <= num_elem & num_elem <= sizeof(vlen));
  let 'n = num_elem;
  let 'm = vsew_bits;

  let vm_val   : vector('n, dec, bool)     = read_vmask_carry(num_elem, 0b0, vreg_name("v0"));
  let imm_val                              = sail_sign_extend(simm, vsew_bits);
  let vs2_val  : vector('n, dec, bits('m)) = read_vreg(num_elem, vsew_bits, lmul, vs2);
  let vd_val   : vector('n, dec, bool)     = read_vmask(num_elem, 0b0, vd);
  result       : vector('n, dec, bool)     = undefined;
  mask_helper  : vector('n, dec, bool)     = undefined;

  /*if vm_val      == undefined |
     vs2_val     == undefined |
     vd_val      == undefined |
     mask_helper == undefined then {
    status = RETIRE_FAIL
  };*/

  if status == RETIRE_SUCCESS then {
    (result, mask_helper) = init_masked_result_carry(num_elem, vsew_bits, lmul, vd_val);
  
    foreach (i from 0 to (num_elem - 1)) {
      if mask_helper[i] == true then {
        let resval : bool = match funct6 {
          VIM_VMADC    => if unsigned(vs2_val[i]) + unsigned(imm_val) + unsigned(bool_to_bits(vm_val[i])) > 2 ^ vsew_bits - 1 then true else false
        };
        result[i] = resval
      }
    };
  
    write_vmask(num_elem, vd, result)
  };
  
  if status == RETIRE_FAIL then handle_illegal();
  status
}

mapping vimtype_mnemonic : vimfunct6 <-> string = {
  VIM_VMADC    <-> "vmadc.vim" /* Carry in, carry out */
}

mapping clause assembly = VIMTYPE(funct6, vs2, simm, vd)
  <-> vimtype_mnemonic(funct6) ^ spc() ^ vreg_name(vd) ^ sep() ^ vreg_name(vs2) ^ sep() ^ hex_bits_5(simm) ^ sep() ^ "v0"


/* **************************VIMCTYPE**************************************** */
/* VIMC instructions' destination is a mask register (e.g. carry out) */
/* Instructions with no carry out will set mask result to current mask value */
/* May or may not read from source mask register (e.g. carry in) */

union clause ast = VIMCTYPE : (vimcfunct6, regidx, regidx, regidx)

mapping encdec_vimcfunct6 : vimcfunct6 <-> bits(6) = {
  VIMC_VMADC    <-> 0b010001 /* Carry in, carry out */
}

mapping clause encdec = VIMCTYPE(funct6, vs2, simm, vd)
  <-> encdec_vimcfunct6(funct6) @ 0b1 @ vs2 @ simm @ 0b011 @ vd @ 0b1010111

function clause execute(VIMCTYPE(funct6, vs2, simm, vd)) = {
  status          : Retired = RETIRE_SUCCESS;
  let vsew_bits  : int  = get_vtype_vsew();
  let lmul       : real = get_vtype_LMUL();
  let num_elem   : int  = get_num_elem(lmul, vsew_bits);

  assert(8 <= vsew_bits & vsew_bits <= 64);
  assert(0 <= num_elem & num_elem <= sizeof(vlen));
  let 'n = num_elem;
  let 'm = vsew_bits;

  let imm_val                              = sail_sign_extend(simm, vsew_bits);
  let vs2_val  : vector('n, dec, bits('m)) = read_vreg(num_elem, vsew_bits, lmul, vs2);
  let vd_val   : vector('n, dec, bool)     = read_vmask(num_elem, 0b0, vd);
  result       : vector('n, dec, bool)     = undefined;
  mask_helper  : vector('n, dec, bool)     = undefined;

  /*if vs2_val     == undefined |
     vd_val      == undefined |
     mask_helper == undefined then {
    status = RETIRE_FAIL
  };*/

  if status == RETIRE_SUCCESS then {
    (result, mask_helper) = init_masked_result_carry(num_elem, vsew_bits, lmul, vd_val);
  
    foreach (i from 0 to (num_elem - 1)) {
      if mask_helper[i] == true then {
        let resval : bool = match funct6 {
          VIMC_VMADC    => if unsigned(vs2_val[i]) + unsigned(imm_val) > 2 ^ vsew_bits - 1 then true else false
        };
        result[i] = resval
      }
    };
  
    write_vmask(num_elem, vd, result)
  };
  
  if status == RETIRE_FAIL then handle_illegal();
  status
}

mapping vimctype_mnemonic : vimcfunct6 <-> string = {
  VIMC_VMADC    <-> "vmadc.vi" /* Carry in, carry out */
}

mapping clause assembly = VIMCTYPE(funct6, vs2, simm, vd)
  <-> vimctype_mnemonic(funct6) ^ spc() ^ vreg_name(vd) ^ sep() ^ vreg_name(vs2) ^ sep() ^ hex_bits_5(simm)


/* **************************VIMSTYPE**************************************** */
/* VIMS instructions' destination is a vector register (e.g. actual sum) */
/* Instructions with no carry out will set mask result to current mask value */
/* May or may not read from source mask register (e.g. carry in) */

union clause ast = VIMSTYPE : (vimsfunct6, regidx, regidx, regidx)

mapping encdec_vimsfunct6 : vimsfunct6 <-> bits(6) = {
  VIMS_VADC     <-> 0b010000 /* Carry in, no carry out */
}

mapping clause encdec = VIMSTYPE(funct6, vs2, simm, vd)
  <-> encdec_vimsfunct6(funct6) @ 0b0 @ vs2 @ simm @ 0b011 @ vd @ 0b1010111

function clause execute(VIMSTYPE(funct6, vs2, simm, vd)) = {
  status          : Retired = RETIRE_SUCCESS;
  let vsew_bits  : int  = get_vtype_vsew();
  let lmul       : real = get_vtype_LMUL();
  let num_elem   : int  = get_num_elem(lmul, vsew_bits);

  assert(8 <= vsew_bits & vsew_bits <= 64);
  assert(0 <= num_elem & num_elem <= sizeof(vlen));
  let 'n = num_elem;
  let 'm = vsew_bits;

  vm_val       : vector('n, dec, bool)     = undefined;
  imm_val                                  = sail_sign_extend(simm, vsew_bits);
  vs2_val      : vector('n, dec, bits('m)) = undefined;
  vd_val       : vector('n, dec, bits('m)) = undefined;
  result       : vector('n, dec, bits('m)) = undefined;
  mask_helper  : vector('n, dec, bool)     = undefined;

  /* For bypassing vm masking in init_masked_result */
  all_trues : vector('n, dec, bool) = undefined;
  foreach (i from 0 to (num_elem - 1)) {
    all_trues[i] = true
  };

  if vd == vreg_name("v0") then {
    status = RETIRE_FAIL
  };

  if status == RETIRE_SUCCESS then {
    vm_val  = read_vmask_carry(num_elem, 0b0, vreg_name("v0"));
    vs2_val = read_vreg(num_elem, vsew_bits, lmul, vs2);
    vd_val  = read_vreg(num_elem, vsew_bits, lmul, vd)
  };

  /*if vm_val      == undefined |
     vs2_val     == undefined |
     vd_val      == undefined |
     mask_helper == undefined then {
    status = RETIRE_FAIL
  };*/

  if status == RETIRE_SUCCESS then {
    (result, mask_helper) = init_masked_result(num_elem, vsew_bits, lmul, vd_val, all_trues);
  
    foreach (i from 0 to (num_elem - 1)) {
      if mask_helper[i] == true then {
        result[i] = match funct6 {
          VIMS_VADC     => to_bits(vsew_bits, signed(vs2_val[i]) + signed(imm_val) + signed(bool_to_bits(vm_val[i])))
        }
      }
    };
  
    write_vreg(num_elem, vsew_bits, lmul, vd, result)
  };
  
  if status == RETIRE_FAIL then handle_illegal();
  status
}

mapping vimstype_mnemonic : vimsfunct6 <-> string = {
  VIMS_VADC     <-> "vadc.vim" /* Carry in, no carry out */
}

mapping clause assembly = VIMSTYPE(funct6, vs2, simm, vd)
  <-> vimstype_mnemonic(funct6) ^ spc() ^ vreg_name(vd) ^ sep() ^ vreg_name(vs2) ^ sep() ^ hex_bits_5(simm) ^ sep() ^ "v0"


/* **************************VICMPTYPE**************************************** */
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

mapping clause encdec = VICMPTYPE(funct6, vm, vs2, simm, vd)
  <-> encdec_vicmpfunct6(funct6) @ vm @ vs2 @ simm @ 0b011 @ vd @ 0b1010111

function clause execute(VICMPTYPE(funct6, vm, vs2, simm, vd)) = {
  status          : Retired = RETIRE_SUCCESS;
  let vsew_bits  : int  = get_vtype_vsew();
  let lmul       : real = get_vtype_LMUL();
  let num_elem   : int  = get_num_elem(lmul, vsew_bits);

  assert(8 <= vsew_bits & vsew_bits <= 64);
  assert(0 <= num_elem & num_elem <= sizeof(vlen));
  let 'n = num_elem;
  let 'm = vsew_bits;

  let vm_val   : vector('n, dec, bool)     = read_vmask(num_elem, vm, vreg_name("v0"));
  let imm_val                              = sail_sign_extend(simm, vsew_bits);
  let vs2_val  : vector('n, dec, bits('m)) = read_vreg(num_elem, vsew_bits, lmul, vs2);
  let vd_val   : vector('n, dec, bool)     = read_vmask(num_elem, 0b0, vd);
  result       : vector('n, dec, bool)     = undefined;
  mask_helper  : vector('n, dec, bool)     = undefined;

  if status == RETIRE_SUCCESS then {
    (result, mask_helper) = init_masked_result_cmp(num_elem, vsew_bits, lmul, vd_val, vm_val);
  
    let start_element : int = get_start_element();
    foreach (i from 0 to (num_elem - 1)) {
      if mask_helper[i] == true then {
        let resval : bool = match funct6 {
          VICMP_VMSEQ    => if vs2_val[i] == imm_val then true else false,
          VICMP_VMSNE    => if vs2_val[i] != imm_val then true else false,
          VICMP_VMSLEU   => if unsigned(vs2_val[i]) <= unsigned(imm_val) then true else false,
          VICMP_VMSLE    => if signed(vs2_val[i]) <= signed(imm_val) then true else false,
          VICMP_VMSGTU   => if unsigned(vs2_val[i]) > unsigned(imm_val) then true else false,
          VICMP_VMSGT    => if signed(vs2_val[i]) > signed(imm_val) then true else false
        };
        result[i] = resval
      }
    };
  
    write_vmask(num_elem, vd, result)
  };
  
  if status == RETIRE_FAIL then handle_illegal();
  writeCSR(csr_name_map("vstart"), EXTZ(0b0));
  status
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


/* *******************************OPFVV(FVVMtype)******************************** */
/* FVVM instructions' destination is a mask register */

union clause ast = FVVMTYPE : (fvvmfunct6, bits(1), regidx, regidx, regidx)

mapping encdec_fvvmfunct6 : fvvmfunct6 <-> bits(6) = {
  FVVM_VMFEQ      <-> 0b011000,
  FVVM_VMFLE      <-> 0b011001,
  FVVM_VMFLT      <-> 0b011011,
  FVVM_VMFNE      <-> 0b011100
}

mapping clause encdec = FVVMTYPE(funct6, vm, vs2, vs1, vd)
  <-> encdec_fvvmfunct6(funct6) @ vm @ vs2 @ vs1 @ 0b001 @ vd @ 0b1010111

function clause execute(FVVMTYPE(funct6, vm, vs2, vs1, vd)) = {
  let rm_3b   = fcsr.FRM();
  if rm_3b == 0b101 | rm_3b == 0b110 | rm_3b == 0b111 then {
    handle_illegal();
    RETIRE_FAIL
  } else {
    let vsew_bits  : int  = get_vtype_vsew();
    let lmul       : real = get_vtype_LMUL();
    let num_elem   : int  = get_num_elem(lmul, vsew_bits);

    assert(vsew_bits == 16 | vsew_bits == 32 | vsew_bits == 64);
    assert(0 <= num_elem & num_elem <= sizeof(vlen));
    let 'n = num_elem;
    let 'm = vsew_bits;

    let vm_val  : vector('n, dec, bool)     = read_vmask(num_elem, vm, vreg_name("v0"));
    let vs1_val : vector('n, dec, bits('m)) = read_vreg(num_elem, vsew_bits, lmul, vs1);
    let vs2_val : vector('n, dec, bits('m)) = read_vreg(num_elem, vsew_bits, lmul, vs2);
    let vd_val  : vector('n, dec, bool) = read_vmask(num_elem, 0b0, vd);    
    result      : vector('n, dec, bool) = undefined;
    mask_helper : vector('n, dec, bool) = undefined;

    (result, mask_helper) = init_masked_result_cmp(num_elem, vsew_bits, lmul, vd_val, vm_val);

    foreach (i from 0 to (num_elem - 1)) {
      if mask_helper[i] == true then {
        let resval : bool = match funct6 {
          FVVM_VMFEQ    => fp_eq(vs2_val[i], vs1_val[i]),
          FVVM_VMFNE    => ~(fp_eq(vs2_val[i], vs1_val[i])),
          FVVM_VMFLE    => fp_le(vs2_val[i], vs1_val[i]),
          FVVM_VMFLT    => fp_lt(vs2_val[i], vs1_val[i])
        };
        result[i] = resval
      };
    };

    write_vmask(num_elem, vd, result);
    RETIRE_SUCCESS
  };
}

mapping fvvmtype_mnemonic : fvvmfunct6 <-> string = {
  FVVM_VMFEQ      <-> "vmfeq.vv",
  FVVM_VMFLE      <-> "vmfle.vv",
  FVVM_VMFLT      <-> "vmflt.vv",
  FVVM_VMFNE      <-> "vmfne.vv"
}

mapping clause assembly = FVVMTYPE(funct6, vm, vs2, vs1, vd)
  <-> fvvmtype_mnemonic(funct6) ^ spc() ^ vreg_name(vd) ^ sep() ^ vreg_name(vs2) ^ sep() ^ vreg_name(vs1) ^ maybe_vmask(vm)


/* *******************************OPFVF(VFMtype)******************************** */
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

mapping clause encdec = FVFMTYPE(funct6, vm, vs2, rs1, vd)
  <-> encdec_fvfmfunct6(funct6) @ vm @ vs2 @ rs1 @ 0b101 @ vd @ 0b1010111

function clause execute(FVFMTYPE(funct6, vm, vs2, rs1, vd)) = {
  let rm_3b   = fcsr.FRM();
  if rm_3b == 0b101 | rm_3b == 0b110 | rm_3b == 0b111 then {
    handle_illegal();
    RETIRE_FAIL
  } else {
    let vsew_bits  : int  = get_vtype_vsew();
    let lmul       : real = get_vtype_LMUL();
    let num_elem   : int  = get_num_elem(lmul, vsew_bits);

    assert(vsew_bits == 16 | vsew_bits == 32 | vsew_bits == 64);
    assert(0 <= num_elem & num_elem <= sizeof(vlen));
    let 'n = num_elem;
    let 'm = vsew_bits;

    let vm_val  : vector('n, dec, bool)     = read_vmask(num_elem, vm, vreg_name("v0"));
    let rs1_val = get_scalar_fp(rs1, 'm);
    let vs2_val : vector('n, dec, bits('m)) = read_vreg(num_elem, vsew_bits, lmul, vs2);
    let vd_val  : vector('n, dec, bool) = read_vmask(num_elem, 0b0, vd);    
    result      : vector('n, dec, bool) = undefined;
    mask_helper : vector('n, dec, bool) = undefined;

    (result, mask_helper) = init_masked_result_cmp(num_elem, vsew_bits, lmul, vd_val, vm_val);

    foreach (i from 0 to (num_elem - 1)) {
      if mask_helper[i] == true then {
        let resval : bool = match funct6 {
          VFM_VMFEQ    => fp_eq(vs2_val[i], rs1_val),
          VFM_VMFNE    => ~(fp_eq(vs2_val[i], rs1_val)),
          VFM_VMFLE    => fp_le(vs2_val[i], rs1_val),
          VFM_VMFLT    => fp_lt(vs2_val[i], rs1_val),
          VFM_VMFGE    => fp_ge(vs2_val[i], rs1_val),
          VFM_VMFGT    => fp_gt(vs2_val[i], rs1_val)
        };
        result[i] = resval
      };
    };

    write_vmask(num_elem, vd, result);
    RETIRE_SUCCESS
  };
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

