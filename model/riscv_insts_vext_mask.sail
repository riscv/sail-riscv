/* ************************************************************************ */
/* This file implements part of the vector extension.                       */
/* Chapter 15: vector mask instructions                                     */

/* ************************************************************************ */

/* **************************MMTYPE**************************************** */

union clause ast = MMTYPE : (mmfunct6, regidx, regidx, regidx)

mapping encdec_mmfunct6 : mmfunct6 <-> bits(6) = {
  MM_VMAND     <-> 0b011001,
  MM_VMNAND    <-> 0b011101,
  MM_VMANDNOT  <-> 0b011000,
  MM_VMXOR     <-> 0b011011,
  MM_VMOR      <-> 0b011010,
  MM_VMNOR     <-> 0b011110,
  MM_VMORNOT   <-> 0b011100,
  MM_VMXNOR    <-> 0b011111
}

mapping clause encdec = MMTYPE(funct6, vs2, vs1, vd)
  <-> encdec_mmfunct6(funct6) @ 0b1 @ vs2 @ vs1 @ 0b010 @ vd @ 0b1010111

function clause execute(MMTYPE(funct6, vs2, vs1, vd)) = {
  status         : Retired = RETIRE_SUCCESS;
  let vsew_bits  : int  = get_vtype_vsew();
  let lmul       : real = get_vtype_LMUL();
  let num_elem   : int  = get_num_elem(lmul, vsew_bits);

  assert(8 <= vsew_bits & vsew_bits <= 64);
  assert(0 <= num_elem & num_elem <= sizeof(vlen));
  let 'n = num_elem;
  let 'm = vsew_bits;

  let vs1_val : vector('n, dec, bool) = read_vmask(num_elem, 0b0, vs1);
  let vs2_val : vector('n, dec, bool) = read_vmask(num_elem, 0b0, vs2);
  let vd_val  : vector('n, dec, bool) = read_vmask(num_elem, 0b0, vd);
  result      : vector('n, dec, bool) = undefined;
  mask_helper : vector('n, dec, bool) = undefined;

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
        resval : bool = match funct6 {
          MM_VMAND     => vs2_val[i] & vs1_val[i],
          MM_VMNAND    => ~(vs2_val[i] & vs1_val[i]),
          MM_VMANDNOT  => vs2_val[i] & ~(vs1_val[i]),
          MM_VMXOR     => vs2_val[i] ^ vs1_val[i],
          MM_VMOR      => vs2_val[i] | vs1_val[i],
          MM_VMNOR     => ~(vs2_val[i] | vs1_val[i]),
          MM_VMORNOT   => vs2_val[i] | ~(vs1_val[i]),
          MM_VMXNOR    => ~(vs2_val[i] ^ vs1_val[i])
        };
	result[i] = resval
      }
    };
    
    write_vmask(num_elem, vd, result)
  };

  if status == RETIRE_FAIL then handle_illegal();
  status
}

mapping mmtype_mnemonic : mmfunct6 <-> string = {
  MM_VMAND     <-> "vmand.mm",
  MM_VMNAND    <-> "vmnand.mm",
  MM_VMANDNOT  <-> "vmandnot.mm",
  MM_VMXOR     <-> "vmxor.mm",
  MM_VMOR      <-> "vmor.mm",
  MM_VMNOR     <-> "vmnor.mm",
  MM_VMORNOT   <-> "vmornot.mm",
  MM_VMXNOR    <-> "vmxnor.mm"
}

mapping clause assembly = MMTYPE(funct6, vs2, vs1, vd)
  <-> mmtype_mnemonic(funct6) ^ spc() ^ vreg_name(vd) ^ sep() ^ vreg_name(vs2) ^ sep() ^ vreg_name(vs1)


/* **************************VCPOP_M******************** ******************** */

union clause ast = VCPOP_M : (bits(1), regidx, regidx)

mapping clause encdec = VCPOP_M(vm, vs2, rd)
  <-> 0b010000 @ vm @ vs2 @ 0b10000 @ 0b010 @ rd @ 0b1010111

function clause execute(VCPOP_M(vm, vs2, rd)) = {
  status         : Retired = RETIRE_SUCCESS;
  let vsew_bits  : int  = get_vtype_vsew();
  let lmul       : real = get_vtype_LMUL();
  let num_elem   : int  = get_num_elem(lmul, vsew_bits);

  assert(8 <= vsew_bits & vsew_bits <= 64);
  assert(0 <= num_elem & num_elem <= sizeof(vlen));
  let 'n = num_elem;
  let 'm = vsew_bits;
  
  let vm_val  : vector('n, dec, bool) = read_vmask(num_elem, vm, vreg_name("v0"));
  let vs2_val : vector('n, dec, bool) = read_vmask(num_elem, 0b0, vs2);
  var result      : int                   = 0;
  mask_result : vector('n, dec, bool) = undefined;
  mask_helper : vector('n, dec, bool) = undefined;

  /* Value of vstart must be 0 */
  status = assert_vstart(0);

  if status == RETIRE_SUCCESS then {
    (mask_result, mask_helper) = init_masked_result_cmp(num_elem, vsew_bits, lmul, vs2_val, vm_val);

    foreach (i from 0 to (num_elem - 1)) {
      if mask_helper[i] == true then {
        if vs2_val[i] == true then {
          result = result + 1;
        }
      }
    };
    
    X(rd) = to_bits(sizeof(xlen), result)
  };

  if status == RETIRE_FAIL then handle_illegal();
  writeCSR(csr_name_map("vstart"), EXTZ(0b0));
  status
}

mapping clause assembly = VCPOP_M(vm, vs2, rd)
  <-> "vpopc.m" ^ spc() ^ reg_name(rd) ^ sep() ^ vreg_name(vs2) ^ maybe_vmask(vm)


/* **************************VFIRST_M**************************************** */

union clause ast = VFIRST_M : (bits(1), regidx, regidx)

mapping clause encdec = VFIRST_M(vm, vs2, rd)
  <-> 0b010000 @ vm @ vs2 @ 0b10001 @ 0b010 @ rd @ 0b1010111

function clause execute(VFIRST_M(vm, vs2, rd)) = {
  status         : Retired = RETIRE_SUCCESS;
  let vsew_bits  : int  = get_vtype_vsew();
  let lmul       : real = get_vtype_LMUL();
  let num_elem   : int  = get_num_elem(lmul, vsew_bits);

  assert(8 <= vsew_bits & vsew_bits <= 64);
  assert(0 <= num_elem & num_elem <= sizeof(vlen));
  let 'n = num_elem;
  let 'm = vsew_bits;
  
  let vm_val  : vector('n, dec, bool) = read_vmask(num_elem, vm, vreg_name("v0"));
  let vs2_val : vector('n, dec, bool) = read_vmask(num_elem, 0b0, vs2);
  result      : int                   = -1;

  /* Value of vstart must be 0 */
  status = assert_vstart(0);

  if status == RETIRE_SUCCESS then {

    foreach (i from 0 to (num_elem - 1)) {
      if result == -1 then {
        if vm_val[i] == true then {
          if vs2_val[i] == true then {
            result = i
          }
        };
      };
    };

    X(rd) = to_bits(sizeof(xlen), result)
  };

  if status == RETIRE_FAIL then handle_illegal();
  status
}

mapping clause assembly = VFIRST_M(vm, vs2, rd)
  <-> "vfirst.m" ^ spc() ^ reg_name(rd) ^ sep() ^ vreg_name(vs2) ^ maybe_vmask(vm)


/* **************************VMSBF_M**************************************** */

union clause ast = VMSBF_M : (bits(1), regidx, regidx)

mapping clause encdec = VMSBF_M(vm, vs2, vd)
  <-> 0b010100 @ vm @ vs2 @ 0b00001 @ 0b010 @ vd @ 0b1010111

function clause execute(VMSBF_M(vm, vs2, vd)) = {
  status         : Retired = RETIRE_SUCCESS;
  let vsew_bits  : int  = get_vtype_vsew();
  let lmul       : real = get_vtype_LMUL();
  let num_elem   : int  = get_num_elem(lmul, vsew_bits);

  assert(8 <= vsew_bits & vsew_bits <= 64);
  assert(0 <= num_elem & num_elem <= sizeof(vlen));
  let 'n = num_elem;
  let 'm = vsew_bits;
  
  let vm_val  : vector('n, dec, bool) = read_vmask(num_elem, vm, vreg_name("v0"));
  let vs2_val : vector('n, dec, bool) = read_vmask(num_elem, 0b0, vs2);
  let vd_val  : vector('n, dec, bool) = read_vmask(num_elem, 0b0, vd);
  result      : vector('n, dec, bool) = undefined;
  mask_helper : vector('n, dec, bool) = undefined;

  /* Value of vstart must be 0 */
  status = assert_vstart(0);

  /* If masking is enabled, then dest reg cannot be v0 */
  if vm == 0b0 & vd == vreg_name("v0") then {
    status = RETIRE_FAIL
  };

  /* Dest reg cannot be the same as source reg */
  if vd == vs2 then {
    status = RETIRE_FAIL
  };

  if vm_val      == undefined /*|
     vs2_val     == undefined |
     vd_val      == undefined |
     mask_helper == undefined*/ then {
    status = RETIRE_FAIL
  };

  if status == RETIRE_SUCCESS then {
    (result, mask_helper) = init_masked_result_cmp(num_elem, vsew_bits, lmul, vd_val, vm_val);

    var found_elem : bool = false;
    foreach (i from 0 to (num_elem - 1)) {
      if mask_helper[i] == true then {
        if vs2_val[i] == true then {
          found_elem = true
        };

        if found_elem then {
          result[i] = false
        }
	      else {
          result[i] = true
        }
      }
    };
    
    write_vmask(num_elem, vd, result)
  };

  if status == RETIRE_FAIL then handle_illegal();
  status
}

mapping clause assembly = VMSBF_M(vm, vs2, vd)
  <-> "vmsbf.m" ^ spc() ^ vreg_name(vd) ^ sep() ^ vreg_name(vs2) ^ maybe_vmask(vm)


/* **************************VMSIF_M**************************************** */

union clause ast = VMSIF_M : (bits(1), regidx, regidx)

mapping clause encdec = VMSIF_M(vm, vs2, vd)
  <-> 0b010100 @ vm @ vs2 @ 0b00011 @ 0b010 @ vd @ 0b1010111

function clause execute(VMSIF_M(vm, vs2, vd)) = {
  status         : Retired = RETIRE_SUCCESS;
  let vsew_bits  : int  = get_vtype_vsew();
  let lmul       : real = get_vtype_LMUL();
  let num_elem   : int  = get_num_elem(lmul, vsew_bits);

  assert(8 <= vsew_bits & vsew_bits <= 64);
  assert(0 <= num_elem & num_elem <= sizeof(vlen));
  let 'n = num_elem;
  let 'm = vsew_bits;
  
  let vm_val  : vector('n, dec, bool) = read_vmask(num_elem, vm, vreg_name("v0"));
  let vs2_val : vector('n, dec, bool) = read_vmask(num_elem, 0b0, vs2);
  let vd_val  : vector('n, dec, bool) = read_vmask(num_elem, 0b0, vd);
  result      : vector('n, dec, bool) = undefined;
  mask_helper : vector('n, dec, bool) = undefined;

  /* Value of vstart must be 0 */
  status = assert_vstart(0);

  /* If masking is enabled, then dest reg cannot be v0 */
  if vm == 0b0 & vd == vreg_name("v0") then {
    status = RETIRE_FAIL
  };

  /* Dest reg cannot be the same as source reg */
  if vd == vs2 then {
    status = RETIRE_FAIL
  };

  if vm_val      == undefined /*|
     vs2_val     == undefined |
     vd_val      == undefined |
     mask_helper == undefined*/ then {
    status = RETIRE_FAIL
  };

  if status == RETIRE_SUCCESS then {
    (result, mask_helper) = init_masked_result_cmp(num_elem, vsew_bits, lmul, vd_val, vm_val);

    var found_elem : bool = false;
    foreach (i from 0 to (num_elem - 1)) {
      if mask_helper[i] == true then {
        if found_elem then {
          result[i] = false
        }
	      else {
          result[i] = true
        };

        if vs2_val[i] == true then {
          found_elem = true
        }
      }
    };
    
    write_vmask(num_elem, vd, result)
  };

  if status == RETIRE_FAIL then handle_illegal();
  status
}

mapping clause assembly = VMSIF_M(vm, vs2, vd)
  <-> "vmsif.m" ^ spc() ^ vreg_name(vd) ^ sep() ^ vreg_name(vs2) ^ maybe_vmask(vm)


/* **************************VMSOF_M**************************************** */

union clause ast = VMSOF_M : (bits(1), regidx, regidx)

mapping clause encdec = VMSOF_M(vm, vs2, vd)
  <-> 0b010100 @ vm @ vs2 @ 0b00010 @ 0b010 @ vd @ 0b1010111

function clause execute(VMSOF_M(vm, vs2, vd)) = {
  status         : Retired = RETIRE_SUCCESS;
  let vsew_bits  : int  = get_vtype_vsew();
  let lmul       : real = get_vtype_LMUL();
  let num_elem   : int  = get_num_elem(lmul, vsew_bits);

  assert(8 <= vsew_bits & vsew_bits <= 64);
  assert(0 <= num_elem & num_elem <= sizeof(vlen));
  let 'n = num_elem;
  let 'm = vsew_bits;
  
  let vm_val  : vector('n, dec, bool) = read_vmask(num_elem, vm, vreg_name("v0"));
  let vs2_val : vector('n, dec, bool) = read_vmask(num_elem, 0b0, vs2);
  let vd_val  : vector('n, dec, bool) = read_vmask(num_elem, 0b0, vd);
  result      : vector('n, dec, bool) = undefined;
  mask_helper : vector('n, dec, bool) = undefined;

  /* Value of vstart must be 0 */
  status = assert_vstart(0);

  /* If masking is enabled, then dest reg cannot be v0 */
  if vm == 0b0 & vd == vreg_name("v0") then {
    status = RETIRE_FAIL
  };

  /* Dest reg cannot be the same as source reg */
  if vd == vs2 then {
    status = RETIRE_FAIL
  };

  if vm_val      == undefined /*|
     vs2_val     == undefined |
     vd_val      == undefined |
     mask_helper == undefined*/ then {
    status = RETIRE_FAIL
  };

  if status == RETIRE_SUCCESS then {
    (result, mask_helper) = init_masked_result_cmp(num_elem, vsew_bits, lmul, vd_val, vm_val);

    var found_elem : bool = false;
    foreach (i from 0 to (num_elem - 1)) {
      if mask_helper[i] == true then {
        if vs2_val[i] == true & found_elem == false then {
          result[i] = true;
	        found_elem = true
        }
	      else {
          result[i] = false
        }
      }
    };
    
    write_vmask(num_elem, vd, result)
  };

  if status == RETIRE_FAIL then handle_illegal();
  status
}

mapping clause assembly = VMSOF_M(vm, vs2, vd)
  <-> "vmsof.m" ^ spc() ^ vreg_name(vd) ^ sep() ^ vreg_name(vs2) ^ maybe_vmask(vm)


/* **************************VIOTA_M**************************************** */

union clause ast = VIOTA_M : (bits(1), regidx, regidx)

mapping clause encdec = VIOTA_M(vm, vs2, vd)
  <-> 0b010100 @ vm @ vs2 @ 0b10000 @ 0b010 @ vd @ 0b1010111

function clause execute(VIOTA_M(vm, vs2, vd)) = {
  status         : Retired = RETIRE_SUCCESS;
  let vsew_bits  : int  = get_vtype_vsew();
  let lmul       : real = get_vtype_LMUL();
  let num_elem   : int  = get_num_elem(lmul, vsew_bits);

  assert(8 <= vsew_bits & vsew_bits <= 64);
  assert(0 <= num_elem & num_elem <= sizeof(vlen));
  let 'n = num_elem;
  let 'm = vsew_bits;
  
  let vm_val  : vector('n, dec, bool)     = read_vmask(num_elem, vm, vreg_name("v0"));
  let vs2_val : vector('n, dec, bool)     = read_vmask(num_elem, 0b0, vs2);
  let vd_val  : vector('n, dec, bits('m)) = read_vreg(num_elem, vsew_bits, lmul, vd);
  result      : vector('n, dec, bits('m)) = undefined;
  mask_helper : vector('n, dec, bool)     = undefined;

  /* Value of vstart must be 0 */
  status = assert_vstart(0);

  /* If masking is enabled, then dest reg cannot be v0 */
  if vm == 0b0 & vd == vreg_name("v0") then {
    status = RETIRE_FAIL
  };

  /* Dest reg cannot be the same as source reg */
  if vd == vs2 then {
    status = RETIRE_FAIL
  };

  if vm_val      == undefined /*|
     vs2_val     == undefined |
     vd_val      == undefined |
     mask_helper == undefined*/ then {
    status = RETIRE_FAIL
  };

  if status == RETIRE_SUCCESS then {
    (result, mask_helper) = init_masked_result(num_elem, vsew_bits, lmul, vd_val, vm_val);

    var total : int = 0;
    foreach (i from 0 to (num_elem - 1)) {
      if mask_helper[i] == true then {
	      result[i] = to_bits(vsew_bits, total);
        if vs2_val[i] == true then total = total + 1
      }
    };
    
    write_vreg(num_elem, vsew_bits, lmul, vd, result)
  };

  if status == RETIRE_FAIL then handle_illegal();
  status
}

mapping clause assembly = VIOTA_M(vm, vs2, vd)
  <-> "viota.m" ^ spc() ^ vreg_name(vd) ^ sep() ^ vreg_name(vs2) ^ maybe_vmask(vm)


/* **************************VID_V**************************************** */

union clause ast = VID_V : (bits(1), regidx)

mapping clause encdec = VID_V(vm, vd)
  <-> 0b010100 @ vm @ 0b00000 @ 0b10001 @ 0b010 @ vd @ 0b1010111

function clause execute(VID_V(vm, vd)) = {
  status         : Retired = RETIRE_SUCCESS;
  let vsew_bits  : int  = get_vtype_vsew();
  let lmul       : real = get_vtype_LMUL();
  let num_elem   : int  = get_num_elem(lmul, vsew_bits);

  assert(8 <= vsew_bits & vsew_bits <= 64);
  assert(0 <= num_elem & num_elem <= sizeof(vlen));
  let 'n = num_elem;
  let 'm = vsew_bits;
  
  let vm_val  : vector('n, dec, bool)     = read_vmask(num_elem, vm, vreg_name("v0"));
  let vd_val  : vector('n, dec, bits('m)) = read_vreg(num_elem, vsew_bits, lmul, vd);
  result      : vector('n, dec, bits('m)) = undefined;
  mask_helper : vector('n, dec, bool)     = undefined;

  if vm_val      == undefined /*|
     vd_val      == undefined |
     mask_helper == undefined*/ then {
    status = RETIRE_FAIL
  };

  if status == RETIRE_SUCCESS then {
    (result, mask_helper) = init_masked_result(num_elem, vsew_bits, lmul, vd_val, vm_val);

    foreach (i from 0 to (num_elem - 1)) {
      if mask_helper[i] == true then {
        result[i] = to_bits(vsew_bits, i)
      }
    };
    
    write_vreg(num_elem, vsew_bits, lmul, vd, result)
  };

  if status == RETIRE_FAIL then handle_illegal();
  status
}

mapping clause assembly = VID_V(vm, vd)
  <-> "vid.v" ^ spc() ^ vreg_name(vd) ^ maybe_vmask(vm)
