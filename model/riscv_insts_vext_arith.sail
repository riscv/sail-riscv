/* ******************************************************************************* */
/* This file implements part of the vector extension.                              */
/* Chapter 11: vector integer arithmetic instructions                              */
/* Chapter 12: vector fixed-point arithmetic instructions                          */
/* Chapter 16: vector permutation instructions                                     */

/* ******************************************************************************* */

/* **************************OPIVV(VVTYPE)**************************************** */

union clause ast = VVTYPE : (vvfunct6, bits(1), regidx, regidx, regidx)

mapping encdec_vvfunct6 : vvfunct6 <-> bits(6) = {
  VV_VADD          <-> 0b000000,
  VV_VSUB          <-> 0b000010,
  VV_VMINU         <-> 0b000100,
  VV_VMIN          <-> 0b000101,
  VV_VMAXU         <-> 0b000110,
  VV_VMAX          <-> 0b000111,
  VV_VAND          <-> 0b001001,
  VV_VOR           <-> 0b001010,
  VV_VXOR          <-> 0b001011,
  VV_VRGATHER      <-> 0b001100,
  VV_VRGATHEREI16  <-> 0b001110,
  VV_VSADDU        <-> 0b100000,
  VV_VSADD         <-> 0b100001,
  VV_VSSUBU        <-> 0b100010,
  VV_VSSUB         <-> 0b100011,  
  VV_VSLL          <-> 0b100101,
  VV_VSMUL         <-> 0b100111,
  VV_VSRL          <-> 0b101000,
  VV_VSRA          <-> 0b101001,
  VV_VSSRL         <-> 0b101010,
  VV_VSSRA         <-> 0b101011
}

mapping clause encdec = VVTYPE(funct6, vm, vs2, vs1, vd)
  <-> encdec_vvfunct6(funct6) @ vm @ vs2 @ vs1 @ 0b000 @ vd @ 0b1010111

function clause execute(VVTYPE(funct6, vm, vs2, vs1, vd)) = {
  status         : Retired = RETIRE_SUCCESS;
  let vsew_bits  : int  = get_vtype_vsew();
  let lmul       : real = get_vtype_LMUL();
  let num_elem   : int  = get_num_elem(lmul, vsew_bits);

  assert(8 <= vsew_bits & vsew_bits <= 64);
  assert(0 <= num_elem & num_elem <= sizeof(vlen));
  let 'n = num_elem;
  let 'm = vsew_bits;

  let vm_val  : vector('n, dec, bool)     = read_vmask(num_elem, vm, vreg_name("v0"));
  let vs1_val : vector('n, dec, bits('m)) = read_vreg(num_elem, vsew_bits, lmul, vs1);
  let vs2_val : vector('n, dec, bits('m)) = read_vreg(num_elem, vsew_bits, lmul, vs2);
  let vd_val  : vector('n, dec, bits('m)) = read_vreg(num_elem, vsew_bits, lmul, vd);
  result      : vector('n, dec, bits('m)) = undefined;
  mask_helper : vector('n, dec, bool)     = undefined;

  if vm_val      == undefined /* |
     vs1_val     == undefined |
     vs2_val     == undefined |
     vd_val      == undefined | 
     | mask_helper == undefined */ 
  then {
    status = RETIRE_FAIL;
    print("status=fail")
  };

  if status == RETIRE_SUCCESS then {
    (result, mask_helper) = init_masked_result(num_elem, vsew_bits, lmul, vd_val, vm_val);

    foreach (i from 0 to (num_elem - 1)) {
      //print("vs1_val[i]=" ^ BitStr(vs1_val[i]));
      //print("vs2_val[i]=" ^ BitStr(vs2_val[i]));
      if mask_helper[i] == true then {
        result[i] = match funct6 {
          VV_VADD         => vs2_val[i] + vs1_val[i],
          VV_VSUB         => vs2_val[i] - vs1_val[i],
          VV_VAND         => vs2_val[i] & vs1_val[i],
          VV_VOR          => vs2_val[i] | vs1_val[i],
          VV_VXOR         => vs2_val[i] ^ vs1_val[i],
          VV_VSADDU       => unsigned_saturation('m, EXTZ('m + 1, vs2_val[i]) + EXTZ('m + 1, vs1_val[i]) ),
          VV_VSADD        => signed_saturation('m, EXTS('m + 1, vs2_val[i]) + EXTS('m + 1, vs1_val[i]) ),
          VV_VSSUBU       => {
                               if unsigned(vs2_val[i]) < unsigned(vs1_val[i]) then zeros()
                               else unsigned_saturation('m, EXTZ('m + 1, vs2_val[i]) - EXTZ('m + 1, vs1_val[i]) )
                             },
          VV_VSSUB        => signed_saturation('m, EXTS('m + 1, vs2_val[i]) - EXTS('m + 1, vs1_val[i]) ),
          VV_VSMUL        => {
                               result_mul = to_bits('m * 2, signed(vs2_val[i]) * signed(vs1_val[i]));
                               rounding_incr = get_fixed_rounding_incr(result_mul, 'm - 1);
                               result_wide = (result_mul >> ('m - 1)) + EXTZ('m * 2, rounding_incr);
                               signed_saturation('m, result_wide['m..0])
                             },
          VV_VSLL         => {
                               let shift_amount = get_shift_amount(vs1_val[i], vsew_bits);
                               assert(shift_amount >= 0);
                               vs2_val[i] << shift_amount
                             },
          VV_VSRL         => {
                               let shift_amount = get_shift_amount(vs1_val[i], vsew_bits);
                               assert(shift_amount >= 0);
                               vs2_val[i] >> shift_amount
                             },
          VV_VSRA         => {
                               let shift_amount = get_shift_amount(vs1_val[i], vsew_bits);
                               assert(shift_amount >= 0);
                               let v_double : bits('m * 2) = EXTS(vs2_val[i]);
                               slice(v_double >> shift_amount, 0, vsew_bits)
                             },
          VV_VSSRL        => {
                               let shift_amount = get_shift_amount(vs1_val[i], vsew_bits);
                               assert(shift_amount >= 0);
                               let rounding_incr = get_fixed_rounding_incr(vs2_val[i], shift_amount);
                               (vs2_val[i] >> shift_amount) + EXTZ('m, rounding_incr)
                             },
          VV_VSSRA        => {
                               let shift_amount = get_shift_amount(vs1_val[i], vsew_bits);
                               assert(shift_amount >= 0);
                               let rounding_incr = get_fixed_rounding_incr(vs2_val[i], shift_amount);
                               let v_double : bits('m * 2) = EXTS(vs2_val[i]);
                               slice(v_double >> shift_amount, 0, vsew_bits) + EXTZ('m, rounding_incr)
                             },
          VV_VMINU        => to_bits(vsew_bits, min(unsigned(vs2_val[i]), unsigned(vs1_val[i]))),
          VV_VMIN         => to_bits(vsew_bits, min(signed(vs2_val[i]), signed(vs1_val[i]))),
          VV_VMAXU        => to_bits(vsew_bits, max(unsigned(vs2_val[i]), unsigned(vs1_val[i]))),
          VV_VMAX         => to_bits(vsew_bits, max(signed(vs2_val[i]), signed(vs1_val[i]))),
          VV_VRGATHER     => {
                               assert(vs1 != vd & vs2 != vd);
                               let idx = unsigned(vs1_val[i]);
                               vlmax = floor(lmul * (to_real(sizeof(vlen)) / to_real(vsew_bits)));
                               if idx < vlmax then {
                                 assert(idx < 'n); 
                                 vs2_val[idx]
                               } else zeros() 
                             },
          VV_VRGATHEREI16 => {
                               assert(vs1 != vd & vs2 != vd);
                               /* vrgatherei16.vv uses SEW/LMUL for the data in vs2 but EEW=16 and EMUL = (16/SEW)*LMUL for the indices in vs1 */
                               let vs1_new : vector('n, dec, bits(16)) = read_vreg(num_elem, 16, (lmul * 16.0 / to_real(vsew_bits)), vs1);
                               let idx = unsigned(vs1_new[i]);
                               vlmax = floor(lmul * (to_real(sizeof(vlen)) / to_real(vsew_bits)));
                               if idx < vlmax then {
                                 assert(idx < 'n); 
                                 vs2_val[idx]
                               } else zeros()                   
                             }
        };
        //print_int("mask_helper_true", i);
        //print("result[i]=" ^ BitStr(result[i]))
      }
    };
    
    write_vreg(num_elem, vsew_bits, lmul, vd, result);
    writeCSR(csr_name_map("vstart"), EXTZ(0b0))
  };

  if status == RETIRE_FAIL then handle_illegal();
  status
}

mapping vvtype_mnemonic : vvfunct6 <-> string = {
  VV_VADD          <-> "vadd.vv",
  VV_VSUB          <-> "vsub.vv",
  VV_VAND          <-> "vand.vv",
  VV_VOR           <-> "vor.vv",
  VV_VXOR          <-> "vxor.vv",
  VV_VRGATHER      <-> "vrgather.vv",
  VV_VRGATHEREI16  <-> "vrgatherei16.vv",
  VV_VSADDU        <-> "vsaddu.vv",
  VV_VSADD         <-> "vsadd.vv",
  VV_VSSUBU        <-> "vssubu.vv",
  VV_VSSUB         <-> "vssub.vv",
  VV_VSLL          <-> "vsll.vv",
  VV_VSMUL         <-> "vsmul.vv",
  VV_VSRL          <-> "vsrl.vv",
  VV_VSRA          <-> "vsra.vv",
  VV_VSSRL         <-> "vssrl.vv",
  VV_VSSRA         <-> "vssra.vv",
  VV_VMINU         <-> "vminu.vv",
  VV_VMIN          <-> "vmin.vv",
  VV_VMAXU         <-> "vmaxu.vv",
  VV_VMAX          <-> "vmax.vv"
}

mapping clause assembly = VVTYPE(funct6, vm, vs2, vs1, vd)
  <-> vvtype_mnemonic(funct6) ^ spc() ^ vreg_name(vd) ^ sep() ^ vreg_name(vs2) ^ sep() ^ vreg_name(vs1) ^ maybe_vmask(vm)


/* **************************OPIVV(VVTYPE)Widened**************************************** */

union clause ast = WVVTYPE : (wvvfunct6, bits(1), regidx, regidx, regidx)
mapping encdec_wvvfunct6 : wvvfunct6 <-> bits(6) = {
  WVV_VADD       <-> 0b110001,
  WVV_VSUB       <-> 0b110011,
  WVV_VADDU      <-> 0b110000,
  WVV_VSUBU      <-> 0b110010,
  WVV_VWMUL      <-> 0b111011,
  WVV_VWMULU     <-> 0b111000,
  WVV_VWMULSU    <-> 0b111010
}

mapping clause encdec = WVVTYPE(funct6, vm, vs2, vs1, vd)
  <-> encdec_wvvfunct6(funct6) @ vm @ vs2 @ vs1 @ 0b010 @ vd @ 0b1010111

function clause execute(WVVTYPE(funct6, vm, vs2, vs1, vd)) = {
  status          : Retired = RETIRE_SUCCESS;
  let vsew_bits   : int  = get_vtype_vsew();
  let lmul        : real = get_vtype_LMUL();
  let num_elem    : int  = get_num_elem(lmul, vsew_bits);
  let double_vsew : int  = vsew_bits * 2;
  let double_lmul : real = lmul * 2.0;

  assert(8 <= vsew_bits & vsew_bits <= 64);
  assert(0 <= num_elem & num_elem <= sizeof(vlen));
  let 'n = num_elem;
  let 'm = vsew_bits;
  let 'o = double_vsew;
  assert(8 <= double_vsew & double_vsew <= 64);

  let vm_val : vector('n, dec, bool) = read_vmask(num_elem, vm, vreg_name("v0"));
  let vd_val  : vector('n, dec, bits('o)) = read_vreg(num_elem, double_vsew, double_lmul, vd);
  let vs1_val : vector('n, dec, bits('m)) = read_vreg(num_elem, vsew_bits, lmul, vs1);
  let vs2_val : vector('n, dec, bits('m)) = read_vreg(num_elem, vsew_bits, lmul, vs2);
  result : vector('n, dec, bits('o)) = undefined;
  mask_helper : vector('n, dec, bool) = undefined;

  if vm_val == undefined  
  then {
    status = RETIRE_FAIL;
    //print("status=fail")
  };

  if status == RETIRE_SUCCESS then {
    //assert(16 <= double_vsew & double_vsew <= 64);
    (result, mask_helper) = init_masked_result(num_elem, double_vsew, double_lmul, vd_val, vm_val);
    
    foreach (i from 0 to (num_elem - 1)) {
      if mask_helper[i] == true then {
        //print_int("vs1=", signed(vs1_val[i]));
        //print_int("vs1=", signed(vs2_val[i]));
        result[i] = match funct6 {
          WVV_VADD         => to_bits(double_vsew, signed(vs2_val[i]) + signed(vs1_val[i])),
          WVV_VSUB         => to_bits(double_vsew, signed(vs2_val[i]) - signed(vs1_val[i])),
          WVV_VADDU        => to_bits(double_vsew, unsigned(vs2_val[i]) + unsigned(vs1_val[i])),
          WVV_VSUBU        => to_bits(double_vsew, unsigned(vs2_val[i]) - unsigned(vs1_val[i])),
          WVV_VWMUL        => to_bits(double_vsew, signed(vs2_val[i]) * signed(vs1_val[i])),
          WVV_VWMULU       => to_bits(double_vsew, unsigned(vs2_val[i]) * unsigned(vs1_val[i])),
          WVV_VWMULSU      => to_bits(double_vsew, signed(vs2_val[i]) * unsigned(vs1_val[i]))
        }
      }
    };
  
    write_vreg(num_elem, double_vsew, double_lmul, vd, result);
    writeCSR(csr_name_map("vstart"), EXTZ(0b0))
  };
  
  status = vcheck_vsew_lmul(double_vsew, double_lmul);
  if status == RETIRE_FAIL then handle_illegal();
  status
}

mapping wvvtype_mnemonic : wvvfunct6 <-> string = {
  WVV_VADD       <-> "vwadd.vv",
  WVV_VSUB       <-> "vwsub.vv",
  WVV_VADDU      <-> "vwaddu.vv",
  WVV_VSUBU      <-> "vwsubu.vv",
  WVV_VWMUL      <-> "vwmul.vv",
  WVV_VWMULU     <-> "vwmulu.vv",
  WVV_VWMULSU    <-> "vwmulsu.vv"
}

mapping clause assembly = WVVTYPE(funct6, vm, vs2, vs1, vd)
  <-> wvvtype_mnemonic(funct6) ^ spc() ^ vreg_name(vd) ^ sep() ^ vreg_name(vs2) ^ sep() ^ vreg_name(vs1) ^ maybe_vmask(vm)


/* **************************WVTYPE**************************************** */

union clause ast = WVTYPE : (wvfunct6, bits(1), regidx, regidx, regidx)

mapping encdec_wvfunct6 : wvfunct6 <-> bits(6) = {
  WV_VADD       <-> 0b110101,
  WV_VSUB       <-> 0b110111,
  WV_VADDU      <-> 0b110100,
  WV_VSUBU      <-> 0b110110
}

mapping clause encdec = WVTYPE(funct6, vm, vs2, vs1, vd)
  <-> encdec_wvfunct6(funct6) @ vm @ vs2 @ vs1 @ 0b010 @ vd @ 0b1010111

function clause execute(WVTYPE(funct6, vm, vs2, vs1, vd)) = {
  status          : Retired = RETIRE_SUCCESS;
  let vsew_bits   : int  = get_vtype_vsew();
  let lmul        : real = get_vtype_LMUL();
  let num_elem    : int  = get_num_elem(lmul, vsew_bits);
  let double_vsew : int  = vsew_bits * 2;
  let double_lmul : real = lmul * 2.0;

  assert(8 <= vsew_bits & vsew_bits <= 64);
  assert(0 <= num_elem & num_elem <= sizeof(vlen));
  let 'n = num_elem;
  let 'm = vsew_bits;
  let 'o = double_vsew;

  vm_val      : vector('n, dec, bool)     = undefined;
  vs1_val     : vector('n, dec, bits('m)) = undefined;
  vs2_val     : vector('n, dec, bits('o)) = undefined;
  vd_val      : vector('n, dec, bits('o)) = undefined;
  result      : vector('n, dec, bits('o)) = undefined;
  mask_helper : vector('n, dec, bool)     = undefined;

  status = vcheck_vsew_lmul(double_vsew, double_lmul);

  if status == RETIRE_SUCCESS then {
    assert(16 <= double_vsew & double_vsew <= 64);
    vm_val  = read_vmask(num_elem, vm, vreg_name("v0"));
    vs1_val = read_vreg(num_elem, vsew_bits, lmul, vs1);
    vs2_val = read_vreg(num_elem, double_vsew, double_lmul, vs2);
    vd_val  = read_vreg(num_elem, double_vsew, double_lmul, vd)
  };

  if vm_val      == undefined /*|
     vs1_val     == undefined |
     vs2_val     == undefined |
     vd_val      == undefined |
     mask_helper == undefined*/ then {
    status = RETIRE_FAIL
  };

  if status == RETIRE_SUCCESS then {
    assert(16 <= double_vsew & double_vsew <= 64);
    (result, mask_helper) = init_masked_result(num_elem, double_vsew, double_lmul, vd_val, vm_val);
  
    foreach (i from 0 to (num_elem - 1)) {
      if mask_helper[i] == true then {
        result[i] = match funct6 {
          WV_VADD         => to_bits(double_vsew, signed(vs2_val[i]) + signed(vs1_val[i])),
          WV_VSUB         => to_bits(double_vsew, signed(vs2_val[i]) - signed(vs1_val[i])),
          WV_VADDU        => to_bits(double_vsew, unsigned(vs2_val[i]) + unsigned(vs1_val[i])),
          WV_VSUBU        => to_bits(double_vsew, unsigned(vs2_val[i]) - unsigned(vs1_val[i]))
        }
      }
    };
  
    write_vreg(num_elem, double_vsew, double_lmul, vd, result)
  };
  
  if status == RETIRE_FAIL then handle_illegal();
  status
}

mapping wvtype_mnemonic : wvfunct6 <-> string = {
  WV_VADD       <-> "vwadd.wv",
  WV_VSUB       <-> "vwsub.wv",
  WV_VADDU      <-> "vwaddu.wv",
  WV_VSUBU      <-> "vwsubu.wv"
}

mapping clause assembly = WVTYPE(funct6, vm, vs2, vs1, vd)
  <-> wvtype_mnemonic(funct6) ^ spc() ^ vreg_name(vd) ^ sep() ^ vreg_name(vs2) ^ sep() ^ vreg_name(vs1) ^ maybe_vmask(vm)


/* **************************NVSTYPE(Narrowing)**************************************** */

union clause ast = NVSTYPE : (nvsfunct6, bits(1), regidx, regidx, regidx)

mapping encdec_nvsfunct6 : nvsfunct6 <-> bits(6) = {
  NVS_VNSRL       <-> 0b101100,
  NVS_VNSRA       <-> 0b101101
}

mapping clause encdec = NVSTYPE(funct6, vm, vs2, vs1, vd)
  <-> encdec_nvsfunct6(funct6) @ vm @ vs2 @ vs1 @ 0b000 @ vd @ 0b1010111

function clause execute(NVSTYPE(funct6, vm, vs2, vs1, vd)) = {
  status          : Retired = RETIRE_SUCCESS;
  let vsew_bits   : int  = get_vtype_vsew();
  let lmul        : real = get_vtype_LMUL();
  let num_elem    : int  = get_num_elem(lmul, vsew_bits);
  let double_vsew : int  = vsew_bits * 2;
  let double_lmul : real = lmul * 2.0;
  
  assert(8 <= vsew_bits & vsew_bits <= 64);
  assert(0 <= num_elem & num_elem <= sizeof(vlen));
  let 'n = num_elem;
  let 'm = vsew_bits;
  let 'o = double_vsew;

  vm_val      : vector('n, dec, bool)     = undefined;
  vs1_val     : vector('n, dec, bits('m)) = undefined;
  vs2_val     : vector('n, dec, bits('o)) = undefined;
  vd_val      : vector('n, dec, bits('m)) = undefined;
  result      : vector('n, dec, bits('m)) = undefined;
  mask_helper : vector('n, dec, bool)     = undefined;

  if (double_vsew > sizeof(elen) | double_lmul > 8.0) then {
    status = RETIRE_FAIL
  };

  if status == RETIRE_SUCCESS then {
    assert(16 <= double_vsew & double_vsew <= 64);
    vm_val  = read_vmask(num_elem, vm, vreg_name("v0"));
    vs1_val = read_vreg(num_elem, vsew_bits, lmul, vs1);
    vs2_val = read_vreg(num_elem, double_vsew, double_lmul, vs2);
    vd_val  = read_vreg(num_elem, vsew_bits, lmul, vd)
  };

  if vm_val      == undefined /*|
     vs1_val     == undefined |
     vs2_val     == undefined |
     vd_val      == undefined |
     mask_helper == undefined*/ then {
    status = RETIRE_FAIL
  };

  if status == RETIRE_SUCCESS then {
    assert(16 <= double_vsew & double_vsew <= 64);
    (result, mask_helper) = init_masked_result(num_elem, vsew_bits, lmul, vd_val, vm_val);
  
    foreach (i from 0 to (num_elem - 1)) {
      if mask_helper[i] == true then {
        result[i] = match funct6 {
          NVS_VNSRL    => {
                           let shift_amount = get_shift_amount(vs1_val[i], double_vsew);
                           assert(shift_amount >= 0);
                           slice(vs2_val[i] >> shift_amount, 0, vsew_bits)
                         },
          NVS_VNSRA    => {
                           let shift_amount = get_shift_amount(vs1_val[i], double_vsew);
                           assert(shift_amount >= 0);
                           let v_double : bits('o * 2) = EXTS(vs2_val[i]);
                           let arith_shifted : bits('o) = slice(v_double >> shift_amount, 0, double_vsew);
                           slice(arith_shifted, 0, vsew_bits)
                         }
        }
      }
    };

    write_vreg(num_elem, vsew_bits, lmul, vd, result)
  };

  if status == RETIRE_FAIL then handle_illegal();
  status
}

mapping nvstype_mnemonic : nvsfunct6 <-> string = {
  NVS_VNSRL       <-> "vnsrl.wv",
  NVS_VNSRA       <-> "vnsra.wv"
}

mapping clause assembly = NVSTYPE(funct6, vm, vs2, vs1, vd)
  <-> nvstype_mnemonic(funct6) ^ spc() ^ vreg_name(vd) ^ sep() ^ vreg_name(vs2) ^ sep() ^ vreg_name(vs1) ^ maybe_vmask(vm)


/* **************************NVTYPE(Narrowing)**************************************** */

union clause ast = NVTYPE : (nvfunct6, bits(1), regidx, regidx, regidx)

mapping encdec_nvfunct6 : nvfunct6 <-> bits(6) = {
  NV_VNCLIPU     <-> 0b101110,
  NV_VNCLIP      <-> 0b101111
}

mapping clause encdec = NVTYPE(funct6, vm, vs2, vs1, vd)
  <-> encdec_nvfunct6(funct6) @ vm @ vs2 @ vs1 @ 0b000 @ vd @ 0b1010111

function clause execute(NVTYPE(funct6, vm, vs2, vs1, vd)) = {
  let vsew_bits  : int = get_vtype_vsew();
  let lmul       : real = get_vtype_LMUL();
  let num_elem   : int = get_num_elem(lmul, vsew_bits);
  let double_vsew : int  = vsew_bits * 2;
  let double_lmul : real = lmul * 2.0;

  assert(8 <= vsew_bits & vsew_bits <= 64);
  assert(8 <= double_vsew & double_vsew <= 64);
  assert(0 <= num_elem & num_elem <= sizeof(vlen));
  let 'n = num_elem;
  let 'm = vsew_bits;
  let 'o = double_vsew;

  let vm_val  : vector('n, dec, bool)     = read_vmask(num_elem, vm, vreg_name("v0"));
  let vs1_val : vector('n, dec, bits('m)) = read_vreg(num_elem, vsew_bits, lmul, vs1);
  let vs2_val : vector('n, dec, bits('o)) = read_vreg(num_elem, double_vsew, double_lmul, vs2);
  let vd_val  : vector('n, dec, bits('m)) = read_vreg(num_elem, vsew_bits, lmul, vd);
  result      : vector('n, dec, bits('m)) = undefined;
  mask_helper : vector('n, dec, bool) = undefined;

  (result, mask_helper) = init_masked_result(num_elem, vsew_bits, lmul, vd_val, vm_val);
  foreach (i from 0 to (num_elem - 1)) {
    if mask_helper[i] == true then {
      let shift_amount = get_shift_amount(vs1_val[i], vsew_bits);
      assert(shift_amount >= 0);
      let rounding_incr = get_fixed_rounding_incr(vs2_val[i], shift_amount);
      result[i] = match funct6 {
        NV_VNCLIPU  => {                    
                         result_wide = (vs2_val[i] >> shift_amount) + EXTZ('o, rounding_incr);
                         assert('o >= 'm & 'm > 0);
                         unsigned_saturation('m, result_wide);
                       },
        NV_VNCLIP   => {          
                         assert(('m * 4) >= 'o);
                         let v_double : bits('m * 4) = sail_sign_extend(vs2_val[i], 'm * 4);
                         result_wide = slice(v_double >> shift_amount, 0, 'o) + EXTZ('o, rounding_incr);
                         assert('o >= 'm & 'm > 0);
                         signed_saturation('m, result_wide);
                       }
      }
    }
  };

  write_vreg(num_elem, vsew_bits, lmul, vd, result);

  RETIRE_SUCCESS
}

mapping nvtype_mnemonic : nvfunct6 <-> string = {
  NV_VNCLIPU     <-> "vnclipu.wv",
  NV_VNCLIP      <-> "vnclip.wv"
}

mapping clause assembly = NVTYPE(funct6, vm, vs2, vs1, vd)
  <-> nvtype_mnemonic(funct6) ^ spc() ^ vreg_name(vd) ^ sep() ^ vreg_name(vs2) ^ sep() ^ vreg_name(vs1) ^ maybe_vmask(vm)


/* **************************VEXT2**************************************** */

union clause ast = VEXT2TYPE : (vext2funct6, bits(1), regidx, regidx)

mapping vext2_vs1 : vext2funct6 <-> bits(5) = {
  VEXT2_ZVF2  <-> 0b00110,
  VEXT2_SVF2  <-> 0b00111
}

mapping clause encdec = VEXT2TYPE(funct6, vm, vs2, vd)
  <-> 0b010010 @ vm @ vs2 @ vext2_vs1(funct6) @ 0b010 @ vd @ 0b1010111

function clause execute(VEXT2TYPE(funct6, vm, vs2, vd)) = {
  status          : Retired = RETIRE_SUCCESS;
  let vsew_bits  : int  = get_vtype_vsew();
  let lmul       : real = get_vtype_LMUL();
  let num_elem   : int  = get_num_elem(lmul, vsew_bits);
  let half_vsew  : int  = vsew_bits / 2;
  let half_lmul  : real = lmul / 2.0;

  //assert(16 <= vsew_bits & vsew_bits <= 64);
  //assert(8 <= half_vsew & half_vsew <= 32);
  assert(8 <= vsew_bits & vsew_bits <= 64);
  assert(0 <= num_elem & num_elem <= sizeof(vlen));
  let 'n = num_elem;
  let 'm = vsew_bits;
  let 'o = half_vsew;

  vm_val      : vector('n, dec, bool)     = undefined;
  vs2_val     : vector('n, dec, bits('o)) = undefined;
  vd_val      : vector('n, dec, bits('m)) = undefined;
  result      : vector('n, dec, bits('m)) = undefined;
  mask_helper : vector('n, dec, bool)     = undefined;

  status = vcheck_vsew_lmul(half_vsew, half_lmul);

  if status == RETIRE_SUCCESS then {
    assert(8 <= half_vsew & half_vsew <= 64);
    assert(half_vsew < vsew_bits);
    vm_val  = read_vmask(num_elem, vm, vreg_name("v0"));
    vs2_val = read_vreg(num_elem, half_vsew, half_lmul, vs2);
    vd_val  = read_vreg(num_elem, vsew_bits, lmul, vd)
  };

  if vm_val      == undefined /*|
     vs2_val     == undefined |
     vd_val      == undefined |
     mask_helper == undefined*/ then {
    status = RETIRE_FAIL
  };

  if status == RETIRE_SUCCESS then {
    assert(8 <= half_vsew & half_vsew <= 64);
    assert(half_vsew < vsew_bits);
    (result, mask_helper) = init_masked_result(num_elem, vsew_bits, lmul, vd_val, vm_val);
  
    foreach (i from 0 to (num_elem - 1)) {
      if mask_helper[i] == true then {
        result[i] = match funct6 {
          VEXT2_ZVF2  => sail_zero_extend(vs2_val[i], vsew_bits),
          VEXT2_SVF2  => sail_sign_extend(vs2_val[i], vsew_bits)
        }
      }
    };
  
    write_vreg(num_elem, vsew_bits, lmul, vd, result)
  };
  
  if status == RETIRE_FAIL then handle_illegal();
  status
}

mapping vext2type_mnemonic : vext2funct6 <-> string = {
  VEXT2_ZVF2  <-> "vzext.vf2",
  VEXT2_SVF2  <-> "vsext.vf2"
}

mapping clause assembly = VEXT2TYPE(funct6, vm, vs2, vd)
  <-> vext2type_mnemonic(funct6) ^ spc() ^ vreg_name(vd) ^ sep() ^ vreg_name(vs2) ^ maybe_vmask(vm)


/* **************************VEXT4**************************************** */

union clause ast = VEXT4TYPE : (vext4funct6, bits(1), regidx, regidx)

mapping vext4_vs1 : vext4funct6 <-> bits(5) = {
  VEXT4_ZVF4  <-> 0b00100,
  VEXT4_SVF4  <-> 0b00101
}

mapping clause encdec = VEXT4TYPE(funct6, vm, vs2, vd)
  <-> 0b010010 @ vm @ vs2 @ vext4_vs1(funct6) @ 0b010 @ vd @ 0b1010111

function clause execute(VEXT4TYPE(funct6, vm, vs2, vd)) = {
  status          : Retired = RETIRE_SUCCESS;
  let vsew_bits  : int  = get_vtype_vsew();
  let lmul       : real = get_vtype_LMUL();
  let num_elem   : int  = get_num_elem(lmul, vsew_bits);
  let quart_vsew : int  = vsew_bits / 4;
  let quart_lmul : real = lmul / 4.0;

  assert(8 <= vsew_bits & vsew_bits <= 64);
  assert(0 <= num_elem & num_elem <= sizeof(vlen));
  let 'n = num_elem;
  let 'm = vsew_bits;
  let 'o = quart_vsew;

  vm_val      : vector('n, dec, bool)     = undefined;
  vs2_val     : vector('n, dec, bits('o)) = undefined;
  vd_val      : vector('n, dec, bits('m)) = undefined;
  result      : vector('n, dec, bits('m)) = undefined;
  mask_helper : vector('n, dec, bool)     = undefined;

  status = vcheck_vsew_lmul(quart_vsew, quart_lmul);

  if status == RETIRE_SUCCESS then {
    assert(8 <= quart_vsew & quart_vsew <= 64);
    assert(quart_vsew < vsew_bits);
    vm_val  = read_vmask(num_elem, vm, vreg_name("v0"));
    vs2_val = read_vreg(num_elem, quart_vsew, quart_lmul, vs2);
    vd_val  = read_vreg(num_elem, vsew_bits, lmul, vd)
  };

  if vm_val      == undefined /*|
     vs2_val     == undefined |
     vd_val      == undefined |
     mask_helper == undefined*/ then {
    status = RETIRE_FAIL
  };

  if status == RETIRE_SUCCESS then {
    assert(8 <= quart_vsew & quart_vsew <= 64);
    assert(quart_vsew < vsew_bits);
    (result, mask_helper) = init_masked_result(num_elem, vsew_bits, lmul, vd_val, vm_val);
  
    foreach (i from 0 to (num_elem - 1)) {
      if mask_helper[i] == true then {
        result[i] = match funct6 {
          VEXT4_ZVF4  => sail_zero_extend(vs2_val[i], vsew_bits),
          VEXT4_SVF4  => sail_sign_extend(vs2_val[i], vsew_bits)
        }
      }
    };
  
    write_vreg(num_elem, vsew_bits, lmul, vd, result)
  };
  
  if status == RETIRE_FAIL then handle_illegal();
  status
}

mapping vext4type_mnemonic : vext4funct6 <-> string = {
  VEXT4_ZVF4  <-> "vzext.vf4",
  VEXT4_SVF4  <-> "vsext.vf4"
}

mapping clause assembly = VEXT4TYPE(funct6, vm, vs2, vd)
  <-> vext4type_mnemonic(funct6) ^ spc() ^ vreg_name(vd) ^ sep() ^ vreg_name(vs2) ^ maybe_vmask(vm)


/* **************************VEXT8**************************************** */

union clause ast = VEXT8TYPE : (vext8funct6, bits(1), regidx, regidx)

mapping vext8_vs1 : vext8funct6 <-> bits(5) = {
  VEXT8_ZVF8  <-> 0b00010,
  VEXT8_SVF8  <-> 0b00011
}

mapping clause encdec = VEXT8TYPE(funct6, vm, vs2, vd)
  <-> 0b010010 @ vm @ vs2 @ vext8_vs1(funct6) @ 0b010 @ vd @ 0b1010111

function clause execute(VEXT8TYPE(funct6, vm, vs2, vd)) = {
  status          : Retired = RETIRE_SUCCESS;
  let vsew_bits   : int  = get_vtype_vsew();
  let lmul        : real = get_vtype_LMUL();
  let num_elem    : int  = get_num_elem(lmul, vsew_bits);
  let eighth_vsew : int  = vsew_bits / 8;
  let eighth_lmul : real = lmul / 8.0;

  //assert(vsew_bits <= 64);
  //assert(eighth_vsew <= 8);
  assert(8 <= vsew_bits & vsew_bits <= 64);
  assert(0 <= num_elem & num_elem <= sizeof(vlen));
  let 'n = num_elem;
  let 'm = vsew_bits;
  let 'o = eighth_vsew;

  vm_val      : vector('n, dec, bool)     = undefined;
  vs2_val     : vector('n, dec, bits('o)) = undefined;
  vd_val      : vector('n, dec, bits('m)) = undefined;
  result      : vector('n, dec, bits('m)) = undefined;
  mask_helper : vector('n, dec, bool)     = undefined;

  status = vcheck_vsew_lmul(eighth_vsew, eighth_lmul);

  if status == RETIRE_SUCCESS then {
    assert(8 <= eighth_vsew & eighth_vsew <= 64);
    assert(eighth_vsew <= vsew_bits);
    assert(8 <= 'o );
    vm_val  = read_vmask(num_elem, vm, vreg_name("v0"));
    vs2_val = read_vreg(num_elem, eighth_vsew, eighth_lmul, vs2);
    vd_val  = read_vreg(num_elem, vsew_bits, lmul, vd)
  };

  if vm_val      == undefined /*|
     vs2_val     == undefined |
     vd_val      == undefined |
     mask_helper == undefined*/ then {
    status = RETIRE_FAIL
  };

  if status == RETIRE_SUCCESS then {
    assert(8 <= eighth_vsew & eighth_vsew <= 64);
    assert(eighth_vsew <= vsew_bits);
    assert(8 <= 'o );
    (result, mask_helper) = init_masked_result(num_elem, vsew_bits, lmul, vd_val, vm_val);
  
    foreach (i from 0 to (num_elem - 1)) {
      if mask_helper[i] == true then {
        result[i] = match funct6 {
          VEXT8_ZVF8  => sail_zero_extend(vs2_val[i], vsew_bits),
          VEXT8_SVF8  => sail_sign_extend(vs2_val[i], vsew_bits)
        }
      }
    };
  
    write_vreg(num_elem, vsew_bits, lmul, vd, result)
  };

  if status == RETIRE_FAIL then handle_illegal();
  status
}

mapping vext8type_mnemonic : vext8funct6 <-> string = {
  VEXT8_ZVF8  <-> "vzext.vf8",
  VEXT8_SVF8  <-> "vsext.vf8"
}

mapping clause assembly = VEXT8TYPE(funct6, vm, vs2, vd)
  <-> vext8type_mnemonic(funct6) ^ spc() ^ vreg_name(vd) ^ sep() ^ vreg_name(vs2) ^ maybe_vmask(vm)


/* **************************instructions*************************************** */
/* **************************OPIVX(VXtype)************************************** */

union clause ast = VXTYPE : (vxfunct6, bits(1), regidx, regidx, regidx)

mapping encdec_vxfunct6 : vxfunct6 <-> bits(6) = {
  VX_VADD       <-> 0b000000,
  VX_VSUB       <-> 0b000010,
  VX_VRSUB      <-> 0b000011,
  VX_VMINU      <-> 0b000100,
  VX_VMIN       <-> 0b000101,
  VX_VMAXU      <-> 0b000110,
  VX_VMAX       <-> 0b000111,
  VX_VAND       <-> 0b001001,
  VX_VOR        <-> 0b001010,
  VX_VXOR       <-> 0b001011,
  VX_VSADDU     <-> 0b100000,
  VX_VSADD      <-> 0b100001,
  VX_VSSUBU     <-> 0b100010,
  VX_VSSUB      <-> 0b100011,
  VX_VSLL       <-> 0b100101,
  VX_VSMUL      <-> 0b100111,
  VX_VSRL       <-> 0b101000,
  VX_VSRA       <-> 0b101001,
  VX_VSSRL      <-> 0b101010,
  VX_VSSRA      <-> 0b101011
}

mapping clause encdec = VXTYPE(funct6, vm, vs2, rs1, vd)
  <-> encdec_vxfunct6(funct6) @ vm @ vs2 @ rs1 @ 0b100 @ vd @ 0b1010111

function clause execute(VXTYPE(funct6, vm, vs2, rs1, vd)) = {
  status          : Retired = RETIRE_SUCCESS;
  let vsew_bits  : int = get_vtype_vsew();
  let lmul       : real = get_vtype_LMUL();
  let num_elem   : int = get_num_elem(lmul, vsew_bits);
  //print_int("num_elem=", num_elem);
  assert(8 <= vsew_bits & vsew_bits <= 64);
  assert(0 <= num_elem & num_elem <= sizeof(vlen));
  let 'n = num_elem;
  let 'm = vsew_bits;
  let vm_val  : vector('n, dec, bool)     = read_vmask(num_elem, vm, vreg_name("v0"));
  let rs1_val                             = get_scalar(rs1, vsew_bits);
  //print("rs1_val=" ^ BitStr(rs1_val));
  let vs2_val : vector('n, dec, bits('m)) = read_vreg(num_elem, vsew_bits, lmul, vs2);
  let vd_val  : vector('n, dec, bits('m)) = read_vreg(num_elem, vsew_bits, lmul, vd);
  result      : vector('n, dec, bits('m)) = undefined;
  mask_helper : vector('n, dec, bool)     = undefined;
  if 
     vm_val      == undefined /*
    | vs2_val     == undefined |
     vd_val     == undefined   */
  then {
    status = RETIRE_FAIL;
    print("status=fail")
  };

  if status == RETIRE_SUCCESS then {
    //print("status=success");
    (result, mask_helper) = init_masked_result(num_elem, vsew_bits, lmul, vd_val, vm_val);
    foreach (i from 0 to (num_elem - 1)) {
      if mask_helper[i] == true then {
        //print("vs2_val[i]=" ^ BitStr(vs2_val[i]));
        result[i] = match funct6 {
          VX_VADD         => vs2_val[i] + rs1_val,
          VX_VSUB         => vs2_val[i] - rs1_val,
          VX_VRSUB        => rs1_val - vs2_val[i],
          VX_VAND         => vs2_val[i] & rs1_val,
          VX_VOR          => vs2_val[i] | rs1_val,
          VX_VXOR         => vs2_val[i] ^ rs1_val,
          VX_VSADDU       => unsigned_saturation('m, EXTZ('m + 1, vs2_val[i]) + EXTZ('m + 1, rs1_val) ),
          VX_VSADD        => signed_saturation('m, EXTS('m + 1, vs2_val[i]) + EXTS('m + 1, rs1_val) ),
          VX_VSSUBU       => {
                               if unsigned(vs2_val[i]) < unsigned(rs1_val) then zeros()
                               else unsigned_saturation('m, EXTZ('m + 1, vs2_val[i]) - EXTZ('m + 1, rs1_val) )
                             },
          VX_VSSUB        => signed_saturation('m, EXTS('m + 1, vs2_val[i]) - EXTS('m + 1, rs1_val) ),
          VX_VSMUL        => {
                               result_mul = to_bits('m * 2, signed(vs2_val[i]) * signed(rs1_val));
                               rounding_incr = get_fixed_rounding_incr(result_mul, 'm - 1);
                               result_wide = (result_mul >> ('m - 1)) + EXTZ('m * 2, rounding_incr);
                               signed_saturation('m, result_wide['m..0])
                             },
          VX_VSLL         => {
                               let shift_amount = get_shift_amount(rs1_val, vsew_bits);
                               assert(shift_amount >= 0);
                               vs2_val[i] << shift_amount
                             },
          VX_VSRL         => {
                               let shift_amount = get_shift_amount(rs1_val, vsew_bits);
                               assert(shift_amount >= 0);
                               vs2_val[i] >> shift_amount
                             },
          VX_VSRA         => {
                               let shift_amount = get_shift_amount(rs1_val, vsew_bits);
                               assert(shift_amount >= 0);
                               let v_double : bits('m * 2) = EXTS(vs2_val[i]);
                               slice(v_double >> shift_amount, 0, vsew_bits)
                             },
          VX_VSSRL        => {
                               let shift_amount = get_shift_amount(rs1_val, vsew_bits);
                               assert(shift_amount >= 0);
                               let rounding_incr = get_fixed_rounding_incr(vs2_val[i], shift_amount);
                               (vs2_val[i] >> shift_amount) + EXTZ('m, rounding_incr)
                             },
          VX_VSSRA        => {
                               let shift_amount = get_shift_amount(rs1_val, vsew_bits);
                               assert(shift_amount >= 0);
                               let rounding_incr = get_fixed_rounding_incr(vs2_val[i], shift_amount);
                               let v_double : bits('m * 2) = EXTS(vs2_val[i]);
                               slice(v_double >> shift_amount, 0, vsew_bits) + EXTZ('m, rounding_incr)
                             },
          VX_VMINU        => to_bits(vsew_bits, min(unsigned(vs2_val[i]), unsigned(rs1_val))),
          VX_VMIN         => to_bits(vsew_bits, min(signed(vs2_val[i]), signed(rs1_val))),
          VX_VMAXU        => to_bits(vsew_bits, max(unsigned(vs2_val[i]), unsigned(rs1_val))),
          VX_VMAX         => to_bits(vsew_bits, max(signed(vs2_val[i]), signed(rs1_val)))
        }
      }
    };
  
    write_vreg(num_elem, vsew_bits, lmul, vd, result);
    writeCSR(csr_name_map("vstart"), EXTZ(0b0)); //All instruction are designed to reset the vstart CSR to zero at the end of execution
    //print_int("vstart=", unsigned(readCSR(csr_name_map("vstart"))))
  };
  
  if status == RETIRE_FAIL then handle_illegal();
  status
}

mapping vxtype_mnemonic : vxfunct6 <-> string = {
  VX_VADD       <-> "vadd.vx",
  VX_VSUB       <-> "vsub.vx",
  VX_VRSUB      <-> "vrsub.vx",
  VX_VAND       <-> "vand.vx",
  VX_VOR        <-> "vor.vx",
  VX_VXOR       <-> "vxor.vx",
  VX_VSADDU     <-> "vsaddu.vx",
  VX_VSADD      <-> "vsadd.vx",
  VX_VSSUBU     <-> "vssubu.vx",
  VX_VSSUB      <-> "vssub.vx",
  VX_VSLL       <-> "vsll.vx",
  VX_VSMUL      <-> "vsmul.vx",
  VX_VSRL       <-> "vsrl.vx",
  VX_VSRA       <-> "vsra.vx",
  VX_VSSRL      <-> "vssrl.vx",
  VX_VSSRA      <-> "vssra.vx",
  VX_VMINU      <-> "vminu.vx",
  VX_VMIN       <-> "vmin.vx",
  VX_VMAXU      <-> "vmaxu.vx",
  VX_VMAX       <-> "vmax.vx"
}

mapping clause assembly = VXTYPE(funct6, vm, vs2, rs1, vd)
  <-> vxtype_mnemonic(funct6) ^ spc() ^ vreg_name(vd) ^ sep() ^ vreg_name(vs2) ^ sep() ^ reg_name(rs1) ^ maybe_vmask(vm)


/* **************************OPIVX(VXtype)Widened*************************************** */

union clause ast = WVXTYPE : (wvxfunct6, bits(1), regidx, regidx, regidx)

mapping encdec_wvxfunct6 : wvxfunct6 <-> bits(6) = {
  WVX_VADD       <-> 0b110001,
  WVX_VSUB       <-> 0b110011,
  WVX_VADDU      <-> 0b110000,
  WVX_VSUBU      <-> 0b110010,
  WVX_VWMUL      <-> 0b111011,
  WVX_VWMULU     <-> 0b111000,
  WVX_VWMULSU    <-> 0b111010
}

mapping clause encdec = WVXTYPE(funct6, vm, vs2, rs1, vd)
  <-> encdec_wvxfunct6(funct6) @ vm @ vs2 @ rs1 @ 0b110 @ vd @ 0b1010111

function clause execute(WVXTYPE(funct6, vm, vs2, rs1, vd)) = {
  status          : Retired = RETIRE_SUCCESS;
  let vsew_bits   : int  = get_vtype_vsew();
  let lmul        : real = get_vtype_LMUL();
  let num_elem    : int  = get_num_elem(lmul, vsew_bits);
  let double_vsew : int  = vsew_bits * 2;
  let double_lmul : real = lmul * 2.0;

  assert(8 <= vsew_bits & vsew_bits <= 64);
  assert(0 <= num_elem & num_elem <= sizeof(vlen));
  let 'n = num_elem;
  let 'm = vsew_bits;
  let 'o = double_vsew;
  assert(8 <= double_vsew & double_vsew <= 64);

  let vm_val : vector('n, dec, bool) = read_vmask(num_elem, vm, vreg_name("v0"));
  let vd_val  : vector('n, dec, bits('o)) = read_vreg(num_elem, double_vsew, double_lmul, vd);
  let rs1_val = get_scalar(rs1, vsew_bits);
  let vs2_val : vector('n, dec, bits('m)) = read_vreg(num_elem, vsew_bits, lmul, vs2);
  result : vector('n, dec, bits('o)) = undefined;
  mask_helper : vector('n, dec, bool) = undefined;

  if vm_val      == undefined /*|
     vs2_val     == undefined |
     vd_val      == undefined |
     mask_helper == undefined */ then {
    status = RETIRE_FAIL;
    //print("status=fail")
  };

  if status == RETIRE_SUCCESS then {
    assert(16 <= double_vsew & double_vsew <= 64);
    (result, mask_helper) = init_masked_result(num_elem, double_vsew, double_lmul, vd_val, vm_val);

    foreach (i from 0 to (num_elem - 1)) {
      if mask_helper[i] == true then {
        //print_int("vs2=", signed(vs2_val[i]));
        //print_int("rs1=", signed(rs1_val));        
        result[i] = match funct6 {
          WVX_VADD         => to_bits(double_vsew, signed(vs2_val[i]) + signed(rs1_val)),
          WVX_VSUB         => to_bits(double_vsew, signed(vs2_val[i]) - signed(rs1_val)),
          WVX_VADDU        => to_bits(double_vsew, unsigned(vs2_val[i]) + unsigned(rs1_val)),
          WVX_VSUBU        => to_bits(double_vsew, unsigned(vs2_val[i]) - unsigned(rs1_val)),
          WVX_VWMUL        => to_bits(double_vsew, signed(vs2_val[i]) * signed(rs1_val)),
          WVX_VWMULU       => to_bits(double_vsew, unsigned(vs2_val[i]) * unsigned(rs1_val)),
          WVX_VWMULSU      => to_bits(double_vsew, signed(vs2_val[i]) * unsigned(rs1_val))
        }
      }
    };
  
    write_vreg(num_elem, double_vsew, double_lmul, vd, result);
    writeCSR(csr_name_map("vstart"), EXTZ(0b0))
  };
  
  status = vcheck_vsew_lmul(double_vsew, double_lmul);

  if status == RETIRE_FAIL then handle_illegal();
  status
}

mapping wvxtype_mnemonic : wvxfunct6 <-> string = {
  WVX_VADD       <-> "vwadd.vx",
  WVX_VSUB       <-> "vwsub.vx",
  WVX_VADDU      <-> "vwaddu.vx",
  WVX_VSUBU      <-> "vwsubu.vx",
  WVX_VWMUL      <-> "vwmul.vx",
  WVX_VWMULU     <-> "vwmulu.vx",
  WVX_VWMULSU    <-> "vwmulsu.vx"
}

mapping clause assembly = WVXTYPE(funct6, vm, vs2, rs1, vd)
  <-> wvxtype_mnemonic(funct6) ^ spc() ^ vreg_name(vd) ^ sep() ^ vreg_name(vs2) ^ sep() ^ reg_name(rs1) ^ maybe_vmask(vm)


/* **************************WXTYPE**************************************** */

union clause ast = WXTYPE : (wxfunct6, bits(1), regidx, regidx, regidx)

mapping encdec_wxfunct6 : wxfunct6 <-> bits(6) = {
  WX_VADD       <-> 0b110101,
  WX_VSUB       <-> 0b110111,
  WX_VADDU      <-> 0b110100,
  WX_VSUBU      <-> 0b110110
}

mapping clause encdec = WXTYPE(funct6, vm, vs2, rs1, vd)
  <-> encdec_wxfunct6(funct6) @ vm @ vs2 @ rs1 @ 0b110 @ vd @ 0b1010111

function clause execute(WXTYPE(funct6, vm, vs2, rs1, vd)) = {
  status          : Retired = RETIRE_SUCCESS;
  let vsew_bits   : int  = get_vtype_vsew();
  let lmul        : real = get_vtype_LMUL();
  let num_elem    : int  = get_num_elem(lmul, vsew_bits);
  let double_vsew : int  = vsew_bits * 2;
  let double_lmul : real = lmul * 2.0;

  assert(8 <= vsew_bits & vsew_bits <= 64);
  assert(0 <= num_elem & num_elem <= sizeof(vlen));
  let 'n = num_elem;
  let 'm = vsew_bits;
  let 'o = double_vsew;

  vm_val      : vector('n, dec, bool)     = undefined;
  rs1_val                                 = get_scalar(rs1, vsew_bits);
  vs2_val     : vector('n, dec, bits('o)) = undefined;
  vd_val      : vector('n, dec, bits('o)) = undefined;
  result      : vector('n, dec, bits('o)) = undefined;
  mask_helper : vector('n, dec, bool)     = undefined;

  status = vcheck_vsew_lmul(double_vsew, double_lmul);

  if status == RETIRE_SUCCESS then {
    assert(16 <= double_vsew & double_vsew <= 64);
    vm_val  = read_vmask(num_elem, vm, vreg_name("v0"));
    vs2_val = read_vreg(num_elem, double_vsew, double_lmul, vs2);
    vd_val  = read_vreg(num_elem, double_vsew, double_lmul, vd)
  };

  if vm_val      == undefined /*|
     vs2_val     == undefined |
     vd_val      == undefined |
     mask_helper == undefined*/ then {
    status = RETIRE_FAIL
  };

  if status == RETIRE_SUCCESS then {
    assert(16 <= double_vsew & double_vsew <= 64);
    (result, mask_helper) = init_masked_result(num_elem, double_vsew, double_lmul, vd_val, vm_val);
  
    let start_element : int = get_start_element();
    foreach (i from 0 to (num_elem - 1)) {
      if mask_helper[i] == true then {
        result[i] = match funct6 {
          WX_VADD         => to_bits(double_vsew, signed(vs2_val[i]) + signed(rs1_val)),
          WX_VSUB         => to_bits(double_vsew, signed(vs2_val[i]) - signed(rs1_val)),
          WX_VADDU        => to_bits(double_vsew, unsigned(vs2_val[i]) + unsigned(rs1_val)),
          WX_VSUBU        => to_bits(double_vsew, unsigned(vs2_val[i]) - unsigned(rs1_val))
        }
      }
    };
  
    write_vreg(num_elem, double_vsew, double_lmul, vd, result)
  };
  
  if status == RETIRE_FAIL then handle_illegal();
  status
}

mapping wxtype_mnemonic : wxfunct6 <-> string = {
  WX_VADD       <-> "vwadd.wx",
  WX_VSUB       <-> "vwsub.wx",
  WX_VADDU      <-> "vwaddu.wx",
  WX_VSUBU      <-> "vwsubu.wx"
}

mapping clause assembly = WXTYPE(funct6, vm, vs2, rs1, vd)
  <-> wxtype_mnemonic(funct6) ^ spc() ^ vreg_name(vd) ^ sep() ^ vreg_name(vs2) ^ sep() ^ reg_name(rs1) ^ maybe_vmask(vm)


/* **************************NXSTYPE(Narrowing)**************************************** */

union clause ast = NXSTYPE : (nxsfunct6, bits(1), regidx, regidx, regidx)

mapping encdec_nxsfunct6 : nxsfunct6 <-> bits(6) = {
  NXS_VNSRL       <-> 0b101100,
  NXS_VNSRA       <-> 0b101101
}

mapping clause encdec = NXSTYPE(funct6, vm, vs2, rs1, vd)
  <-> encdec_nxsfunct6(funct6) @ vm @ vs2 @ rs1 @ 0b100 @ vd @ 0b1010111

function clause execute(NXSTYPE(funct6, vm, vs2, rs1, vd)) = {
  status          : Retired = RETIRE_SUCCESS;
  let vsew_bits   : int  = get_vtype_vsew();
  let lmul        : real = get_vtype_LMUL();
  let num_elem    : int  = get_num_elem(lmul, vsew_bits);
  let double_vsew : int  = vsew_bits * 2;
  let double_lmul : real = lmul * 2.0;
  
  assert(8 <= vsew_bits & vsew_bits <= 32);
  assert(16 <= double_vsew & double_vsew <= 64);
  assert(0 <= num_elem & num_elem <= sizeof(vlen));
  let 'n = num_elem;
  let 'm = vsew_bits;
  let 'o = double_vsew;

  if (double_vsew > sizeof(elen) | double_lmul > 8.0) then {
    status = RETIRE_FAIL
  };

  let vm_val  : vector('n, dec, bool)     = read_vmask(num_elem, vm, vreg_name("v0"));
  let rs1_val                             = get_scalar(rs1, vsew_bits);
  let vs2_val : vector('n, dec, bits('o)) = read_vreg(num_elem, double_vsew, double_lmul, vs2);
  let vd_val  : vector('n, dec, bits('m)) = read_vreg(num_elem, vsew_bits, lmul, vd);
  result      : vector('n, dec, bits('m)) = undefined;
  mask_helper : vector('n, dec, bool)     = undefined;

  if vm_val      == undefined /*|
     vs2_val     == undefined |
     vd_val      == undefined |
     mask_helper == undefined*/ then {
    status = RETIRE_FAIL
  };

  if status == RETIRE_SUCCESS then {
    (result, mask_helper) = init_masked_result(num_elem, vsew_bits, lmul, vd_val, vm_val);
  
    foreach (i from 0 to (num_elem - 1)) {
      if mask_helper[i] == true then {
        result[i] = match funct6 {
          NXS_VNSRL    => {
                           let shift_amount = get_shift_amount(rs1_val, double_vsew);
                           assert(shift_amount >= 0);
                           slice(vs2_val[i] >> shift_amount, 0, vsew_bits)
                         },
          NXS_VNSRA    => {
                           let shift_amount = get_shift_amount(rs1_val, double_vsew);
                           assert(shift_amount >= 0);
                           let v_double : bits('o * 2) = EXTS(vs2_val[i]);
                           let arith_shifted : bits('o) = slice(v_double >> shift_amount, 0, double_vsew);
                           slice(arith_shifted, 0, vsew_bits)
                         }
        }
      }
    };
  
    write_vreg(num_elem, vsew_bits, lmul, vd, result)
  };
  
  if status == RETIRE_FAIL then handle_illegal();
  status
}

mapping nxstype_mnemonic : nxsfunct6 <-> string = {
  NXS_VNSRL       <-> "vnsrl.wx",
  NXS_VNSRA       <-> "vnsra.wx"
}

mapping clause assembly = NXSTYPE(funct6, vm, vs2, rs1, vd)
  <-> nxstype_mnemonic(funct6) ^ spc() ^ vreg_name(vd) ^ sep() ^ vreg_name(vs2) ^ sep() ^ reg_name(rs1) ^ maybe_vmask(vm)
  

/* **************************NXTYPE(Narrowing)**************************************** */

union clause ast = NXTYPE : (nxfunct6, bits(1), regidx, regidx, regidx)

mapping encdec_nxfunct6 : nxfunct6 <-> bits(6) = {
  NX_VNCLIPU     <-> 0b101110,
  NX_VNCLIP      <-> 0b101111
}

mapping clause encdec = NXTYPE(funct6, vm, vs2, rs1, vd)
  <-> encdec_nxfunct6(funct6) @ vm @ vs2 @ rs1 @ 0b100 @ vd @ 0b1010111

function clause execute(NXTYPE(funct6, vm, vs2, rs1, vd)) = {
  let vsew_bits  : int = get_vtype_vsew();
  let lmul       : real = get_vtype_LMUL();
  let num_elem   : int = get_num_elem(lmul, vsew_bits);
  let double_vsew : int  = vsew_bits * 2;
  let double_lmul : real = lmul * 2.0;

  assert(8 <= vsew_bits & vsew_bits <= 64);
  assert(8 <= double_vsew & double_vsew <= 64);
  assert(0 <= num_elem & num_elem <= sizeof(vlen));
  let 'n = num_elem;
  let 'm = vsew_bits;
  let 'o = double_vsew;

  let vm_val  : vector('n, dec, bool)     = read_vmask(num_elem, vm, vreg_name("v0"));
  let rs1_val                             = get_scalar(rs1, vsew_bits);
  let vs2_val : vector('n, dec, bits('o)) = read_vreg(num_elem, double_vsew, double_lmul, vs2);
  let vd_val  : vector('n, dec, bits('m)) = read_vreg(num_elem, vsew_bits, lmul, vd);
  result      : vector('n, dec, bits('m)) = undefined;
  mask_helper : vector('n, dec, bool) = undefined;

  (result, mask_helper) = init_masked_result(num_elem, vsew_bits, lmul, vd_val, vm_val);
  foreach (i from 0 to (num_elem - 1)) {
    if mask_helper[i] == true then {
      let shift_amount = get_shift_amount(rs1_val, vsew_bits);
      assert(shift_amount >= 0);
      let rounding_incr = get_fixed_rounding_incr(vs2_val[i], shift_amount);

      result[i] = match funct6 {
        NX_VNCLIPU  => {                    
                         result_wide = (vs2_val[i] >> shift_amount) + EXTZ('o, rounding_incr);
                         assert('o >= 'm & 'm > 0);
                         unsigned_saturation('m, result_wide)
                       },
        NX_VNCLIP   => { 
                         assert(('m * 4) >= 'o);         
                         let v_double : bits('m * 4) = sail_sign_extend(vs2_val[i], 'm * 4);
                         result_wide = slice(v_double >> shift_amount, 0, 'o) + EXTZ('o, rounding_incr);
                         assert('o >= 'm & 'm > 0);
                         signed_saturation('m, result_wide)
                       }
      }
    }
  };

  write_vreg(num_elem, vsew_bits, lmul, vd, result);

  RETIRE_SUCCESS
}

mapping nxtype_mnemonic : nxfunct6 <-> string = {
  NX_VNCLIPU     <-> "vnclipu.wx",
  NX_VNCLIP      <-> "vnclip.wx"
}

mapping clause assembly = NXTYPE(funct6, vm, vs2, rs1, vd)
  <-> nxtype_mnemonic(funct6) ^ spc() ^ vreg_name(vd) ^ sep() ^ vreg_name(vs2) ^ sep() ^ reg_name(rs1) ^ maybe_vmask(vm)


/* **************************OPIVI(VItype)**************************************** */

union clause ast = VITYPE : (vifunct6, bits(1), regidx, bits(5), regidx)

mapping encdec_vifunct6 : vifunct6 <-> bits(6) = {
  VI_VADD       <-> 0b000000,
  VI_VRSUB      <-> 0b000011,
  VI_VAND       <-> 0b001001,
  VI_VOR        <-> 0b001010,
  VI_VXOR       <-> 0b001011,
  VI_VSADDU     <-> 0b100000,
  VI_VSADD      <-> 0b100001,
  VI_VSLL       <-> 0b100101,
  VI_VSRL       <-> 0b101000,
  VI_VSRA       <-> 0b101001,
  VI_VSSRL      <-> 0b101010,
  VI_VSSRA      <-> 0b101011
}

mapping clause encdec = VITYPE(funct6, vm, vs2, simm, vd)
  <-> encdec_vifunct6(funct6) @ vm @ vs2 @ simm @ 0b011 @ vd @ 0b1010111

function clause execute(VITYPE(funct6, vm, vs2, simm, vd)) = {
  status          : Retired = RETIRE_SUCCESS;
  let vsew_bits  : int = get_vtype_vsew();
  let lmul       : real = get_vtype_LMUL();
  let num_elem   : int = get_num_elem(lmul, vsew_bits);

  assert(8 <= vsew_bits & vsew_bits <= 64);
  assert(0 <= num_elem & num_elem <= sizeof(vlen));
  let 'n = num_elem;
  let 'm = vsew_bits;

  let vm_val  : vector('n, dec, bool)     = read_vmask(num_elem, vm, vreg_name("v0"));
  let imm_val                             = sail_sign_extend(simm, vsew_bits);
  let vs2_val : vector('n, dec, bits('m)) = read_vreg(num_elem, vsew_bits, lmul, vs2);
  let vd_val  : vector('n, dec, bits('m)) = read_vreg(num_elem, vsew_bits, lmul, vd);
  result      : vector('n, dec, bits('m)) = undefined;
  mask_helper : vector('n, dec, bool)     = undefined;

  if vm_val      == undefined /* |
     vs2_val     == undefined |
     vd_val      == undefined |
     mask_helper == undefined */then {
    status = RETIRE_FAIL;
    print("status=fail")
  };

  if status == RETIRE_SUCCESS then {
    (result, mask_helper) = init_masked_result(num_elem, vsew_bits, lmul, vd_val, vm_val);
  
    foreach (i from 0 to (num_elem - 1)) {
      if mask_helper[i] == true then {
        //print("vs2_val[i]=" ^ BitStr(vs2_val[i]));
        result[i] = match funct6 {
          VI_VADD         => vs2_val[i] + imm_val,
          VI_VRSUB        => imm_val - vs2_val[i],
          VI_VAND         => vs2_val[i] & imm_val,
          VI_VOR          => vs2_val[i] | imm_val,
          VI_VXOR         => vs2_val[i] ^ imm_val,
          VI_VSADDU       => unsigned_saturation('m, EXTZ('m + 1, vs2_val[i]) + EXTZ('m + 1, imm_val) ),
          VI_VSADD        => signed_saturation('m, EXTS('m + 1, vs2_val[i]) + EXTS('m + 1, imm_val) ),
          VI_VSLL         => {
                               let shift_amount = get_shift_amount(sail_zero_extend(simm, vsew_bits), vsew_bits);
                               assert(shift_amount >= 0);
                               vs2_val[i] << shift_amount
                             },
          VI_VSRL         => {
                               let shift_amount = get_shift_amount(sail_zero_extend(simm, vsew_bits), vsew_bits);
                               assert(shift_amount >= 0);
                               vs2_val[i] >> shift_amount
                             },
          VI_VSRA         => {
                               let shift_amount = get_shift_amount(sail_zero_extend(simm, vsew_bits), vsew_bits);
                               assert(shift_amount >= 0);
                               let v_double : bits('m * 2) = EXTS(vs2_val[i]);
                               slice(v_double >> shift_amount, 0, vsew_bits)
                             },
          VI_VSSRL        => {
                               let shift_amount = get_shift_amount(sail_zero_extend(simm, vsew_bits), vsew_bits);
                               assert(shift_amount >= 0);
                               let rounding_incr = get_fixed_rounding_incr(vs2_val[i], shift_amount);
                               (vs2_val[i] >> shift_amount) + EXTZ('m, rounding_incr)
                             },
          VI_VSSRA        => {
                               let shift_amount = get_shift_amount(sail_zero_extend(simm, vsew_bits), vsew_bits);
                               assert(shift_amount >= 0);
                               let rounding_incr = get_fixed_rounding_incr(vs2_val[i], shift_amount);
                               let v_double : bits('m * 2) = EXTS(vs2_val[i]);
                               slice(v_double >> shift_amount, 0, vsew_bits) + EXTZ('m, rounding_incr)
                             }
        }
      }
    };
  
    write_vreg(num_elem, vsew_bits, lmul, vd, result);
    writeCSR(csr_name_map("vstart"), EXTZ(0b0));
  };
  
  if status == RETIRE_FAIL then handle_illegal();
  status
}

mapping vitype_mnemonic : vifunct6 <-> string = {
  VI_VADD   <-> "vadd.vi",
  VI_VRSUB  <-> "vrsub.vi",
  VI_VAND   <-> "vand.vi",
  VI_VOR    <-> "vor.vi",
  VI_VXOR   <-> "vxor.vi",
  VI_VSADDU <-> "vsaddu.vi",
  VI_VSADD  <-> "vsadd.vi",
  VI_VSLL   <-> "vsll.vi",
  VI_VSRL   <-> "vsrl.vi",
  VI_VSRA   <-> "vsra.vi",
  VI_VSSRL  <-> "vssrl.vi",
  VI_VSSRA  <-> "vssra.vi"
}

mapping clause assembly = VITYPE(funct6, vm, vs2, simm, vd)
  <-> vitype_mnemonic(funct6) ^ spc() ^ vreg_name(vd) ^ sep() ^ vreg_name(vs2) ^ sep() ^ hex_bits_5(simm) ^ maybe_vmask(vm)


/* **************************NITYPE(Narrowing)**************************************** */

union clause ast = NISTYPE : (nisfunct6, bits(1), regidx, regidx, regidx)

mapping encdec_nisfunct6 : nisfunct6 <-> bits(6) = {
  NIS_VNSRL       <-> 0b101100,
  NIS_VNSRA       <-> 0b101101
}

mapping clause encdec = NISTYPE(funct6, vm, vs2, simm, vd)
  <-> encdec_nisfunct6(funct6) @ vm @ vs2 @ simm @ 0b011 @ vd @ 0b1010111

function clause execute(NISTYPE(funct6, vm, vs2, simm, vd)) = {
  status          : Retired = RETIRE_SUCCESS;
  let vsew_bits   : int  = get_vtype_vsew();
  let lmul        : real = get_vtype_LMUL();
  let num_elem    : int  = get_num_elem(lmul, vsew_bits);
  let double_vsew : int  = vsew_bits * 2;
  let double_lmul : real = lmul * 2.0;
  
  assert(8 <= vsew_bits & vsew_bits <= 64);
  assert(8 <= double_vsew & double_vsew <= 64);
  assert(0 <= num_elem & num_elem <= sizeof(vlen));
  let 'n = num_elem;
  let 'm = vsew_bits;
  let 'o = double_vsew;

  if (double_vsew > sizeof(elen) | double_lmul > 8.0) then {
    status = RETIRE_FAIL
  };

  let vm_val  : vector('n, dec, bool)     = read_vmask(num_elem, vm, vreg_name("v0"));
  let imm_val                             = sail_sign_extend(simm, vsew_bits);
  let vs2_val : vector('n, dec, bits('o)) = read_vreg(num_elem, double_vsew, double_lmul, vs2);
  let vd_val  : vector('n, dec, bits('m)) = read_vreg(num_elem, vsew_bits, lmul, vd);
  result      : vector('n, dec, bits('m)) = undefined;
  mask_helper : vector('n, dec, bool)     = undefined;

  if vm_val      == undefined /*|
     vs2_val     == undefined |
     vd_val      == undefined |
     mask_helper == undefined*/ then {
    status = RETIRE_FAIL
  };

  if status == RETIRE_SUCCESS then {
    (result, mask_helper) = init_masked_result(num_elem, vsew_bits, lmul, vd_val, vm_val);
  
    foreach (i from 0 to (num_elem - 1)) {
      if mask_helper[i] == true then {
        result[i] = match funct6 {
                NIS_VNSRL    => {
                                  let shift_amount = get_shift_amount(imm_val, double_vsew);
                                  assert(shift_amount >= 0);
                                  slice(vs2_val[i] >> shift_amount, 0, vsew_bits)
                                },
                NIS_VNSRA    => {
                                  let shift_amount = get_shift_amount(imm_val, double_vsew);
                                  assert(shift_amount >= 0);
                                  let v_double : bits('o * 2) = EXTS(vs2_val[i]);
                                  let arith_shifted : bits('o) = slice(v_double >> shift_amount, 0, double_vsew);
                                  slice(arith_shifted, 0, vsew_bits)
                                }
        }
      }
    };
  
    write_vreg(num_elem, vsew_bits, lmul, vd, result)
  };
  
  if status == RETIRE_FAIL then handle_illegal();
  status
}

mapping nistype_mnemonic : nisfunct6 <-> string = {
  NIS_VNSRL       <-> "vnsrl.wi",
  NIS_VNSRA       <-> "vnsra.wi"
}

mapping clause assembly = NISTYPE(funct6, vm, vs2, simm, vd)
  <-> nistype_mnemonic(funct6) ^ spc() ^ vreg_name(vd) ^ sep() ^ vreg_name(vs2) ^ sep() ^ hex_bits_5(simm) ^ maybe_vmask(vm) 


/* **************************NITYPE(Narrowing)**************************************** */

union clause ast = NITYPE : (nifunct6, bits(1), regidx, regidx, regidx)

mapping encdec_nifunct6 : nifunct6 <-> bits(6) = {
  NI_VNCLIPU     <-> 0b101110,
  NI_VNCLIP      <-> 0b101111
}

mapping clause encdec = NITYPE(funct6, vm, vs2, simm, vd)
  <-> encdec_nifunct6(funct6) @ vm @ vs2 @ simm @ 0b011 @ vd @ 0b1010111

function clause execute(NITYPE(funct6, vm, vs2, simm, vd)) = {
  let vsew_bits  : int = get_vtype_vsew();
  let lmul       : real = get_vtype_LMUL();
  let num_elem   : int = get_num_elem(lmul, vsew_bits);
  let double_vsew : int  = vsew_bits * 2;
  let double_lmul : real = lmul * 2.0;

  assert(8 <= vsew_bits & vsew_bits <= 64);
  assert(8 <= double_vsew & double_vsew <= 64);
  assert(0 <= num_elem & num_elem <= sizeof(vlen));
  let 'n = num_elem;
  let 'm = vsew_bits;
  let 'o = double_vsew;

  let vm_val  : vector('n, dec, bool)     = read_vmask(num_elem, vm, vreg_name("v0"));
  let imm_val                             = sail_sign_extend(simm, vsew_bits);
  let vs2_val : vector('n, dec, bits('o)) = read_vreg(num_elem, double_vsew, double_lmul, vs2);
  let vd_val  : vector('n, dec, bits('m)) = read_vreg(num_elem, vsew_bits, lmul, vd);
  result      : vector('n, dec, bits('m)) = undefined;
  mask_helper : vector('n, dec, bool) = undefined;

  (result, mask_helper) = init_masked_result(num_elem, vsew_bits, lmul, vd_val, vm_val);
  foreach (i from 0 to (num_elem - 1)) {
    if mask_helper[i] == true then {
      let shift_amount = get_shift_amount(imm_val, vsew_bits);
      assert(shift_amount >= 0);
      let rounding_incr = get_fixed_rounding_incr(vs2_val[i], shift_amount);
      result[i] = match funct6 {
        NI_VNCLIPU  => {                    
                         result_wide = (vs2_val[i] >> shift_amount) + EXTZ('o, rounding_incr);
                         assert('o >= 'm & 'm > 0);
                         unsigned_saturation('m, result_wide)
                       },
        NI_VNCLIP   => { 
                         assert(('m * 4) >= 'o);         
                         let v_double : bits('m * 4) = sail_sign_extend(vs2_val[i], 'm * 4);
                         result_wide = slice(v_double >> shift_amount, 0, 'o) + EXTZ('o, rounding_incr);
                         assert('o >= 'm & 'm > 0);
                         signed_saturation('m, result_wide)
                       }
      };
    };
  };

  write_vreg(num_elem, vsew_bits, lmul, vd, result);

  RETIRE_SUCCESS
}

mapping nitype_mnemonic : nifunct6 <-> string = {
  NI_VNCLIPU     <-> "vnclipu.wi",
  NI_VNCLIP      <-> "vnclip.wi"
}

mapping clause assembly = NITYPE(funct6, vm, vs2, simm, vd)
  <-> nitype_mnemonic(funct6) ^ spc() ^ vreg_name(vd) ^ sep() ^ vreg_name(vs2) ^ sep() ^ hex_bits_5(simm) ^ maybe_vmask(vm) 
  

/* *******************************OPIVX(Vector Slide & Gather Instructions)******************************** */
/* Slide and gather instructions extend rs1 / imm to XLEN bits (not SEW bits as others do) */

union clause ast = VXSG : (vxsgfunct6, bits(1), regidx, regidx, regidx)

mapping encdec_vxsgfunct6 : vxsgfunct6 <-> bits(6) = {
  VX_VSLIDEUP     <-> 0b001110,
  VX_VSLIDEDOWN   <-> 0b001111,
  VX_VRGATHER     <-> 0b001100
}

mapping clause encdec = VXSG(funct6, vm, vs2, rs1, vd)
  <-> encdec_vxsgfunct6(funct6) @ vm @ vs2 @ rs1 @ 0b100 @ vd @ 0b1010111

function clause execute(VXSG(funct6, vm, vs2, rs1, vd)) = {
  let vsew_bits  : int = get_vtype_vsew();
  let lmul       : real = get_vtype_LMUL();
  let num_elem   : int = get_num_elem(lmul, vsew_bits);

  assert(8 <= vsew_bits & vsew_bits <= 64);
  assert(0 <= num_elem & num_elem <= sizeof(vlen));
  let 'n = num_elem;
  let 'm = vsew_bits;
  
  let vm_val  : vector('n, dec, bool)     = read_vmask(num_elem, vm, vreg_name("v0"));
  let rs1_val : int                       = unsigned(X(rs1));
  let vs2_val : vector('n, dec, bits('m)) = read_vreg(num_elem, vsew_bits, lmul, vs2);
  let vd_val  : vector('n, dec, bits('m)) = read_vreg(num_elem, vsew_bits, lmul, vd);
  result      : vector('n, dec, bits('m)) = undefined;
  mask_helper : vector('n, dec, bool)     = undefined;

  (result, mask_helper) = init_masked_result(num_elem, vsew_bits, lmul, vd_val, vm_val);
  
  foreach (i from 0 to (num_elem - 1)) {
    if mask_helper[i] == true then {
      result[i] = match funct6 {
        VX_VSLIDEUP     => {
                              assert(vs2 != vd);
                              assert(i - rs1_val < 'n);
                              if i >= rs1_val then vs2_val[i - rs1_val] else vd_val[i]
                           },
        VX_VSLIDEDOWN   => {
                              assert(i + rs1_val >= 0);
                              vlmax = floor(lmul * (to_real(sizeof(vlen)) / to_real(vsew_bits)));
                              if i + rs1_val < vlmax then {
                                assert(i + rs1_val < 'n); 
                                vs2_val[i + rs1_val]
                              } else zeros()
                           },
        VX_VRGATHER     => {
                              assert(vs2 != vd);
                              assert(rs1_val >= 0);
                              vlmax = floor(lmul * (to_real(sizeof(vlen)) / to_real(vsew_bits)));
                              if rs1_val < vlmax then {
                                assert(rs1_val < 'n); 
                                vs2_val[rs1_val]
                              } else zeros() 
                           }
      }
    }
  };

  write_vreg(num_elem, vsew_bits, lmul, vd, result);
  RETIRE_SUCCESS
} 

mapping vxsg_mnemonic : vxsgfunct6 <-> string = {
  VX_VSLIDEUP     <-> "vslideup.vx",
  VX_VSLIDEDOWN   <-> "vslidedown.vx",
  VX_VRGATHER     <-> "vrgather.vx"
}

mapping clause assembly = VXSG(funct6, vm, vs2, rs1, vd)
  <-> vxsg_mnemonic(funct6) ^ spc() ^ vreg_name(vd) ^ sep() ^ vreg_name(vs2) ^ sep() ^ reg_name(rs1) ^ maybe_vmask(vm)


/* *******************************OPIVI(Vector Slide & Gather Instructions)******************************** */
/* Slide and gather instructions extend rs1 / imm to XLEN bits (not SEW bits as others do) */

union clause ast = VISG : (visgfunct6, bits(1), regidx, bits(5), regidx)

mapping encdec_visgfunct6 : visgfunct6 <-> bits(6) = {
  VI_VSLIDEUP     <-> 0b001110,
  VI_VSLIDEDOWN   <-> 0b001111,
  VI_VRGATHER     <-> 0b001100
}

mapping clause encdec = VISG(funct6, vm, vs2, simm, vd)
  <-> encdec_visgfunct6(funct6) @ vm @ vs2 @ simm @ 0b011 @ vd @ 0b1010111

function clause execute(VISG(funct6, vm, vs2, simm, vd)) = {
  let vsew_bits  : int = get_vtype_vsew();
  let lmul       : real = get_vtype_LMUL();
  let num_elem   : int = get_num_elem(lmul, vsew_bits);

  assert(8 <= vsew_bits & vsew_bits <= 64);
  assert(0 <= num_elem & num_elem <= sizeof(vlen));
  let 'n = num_elem;
  let 'm = vsew_bits;
  
  let vm_val  : vector('n, dec, bool)     = read_vmask(num_elem, vm, vreg_name("v0"));
  let imm_val : int                       = unsigned(EXTZ(sizeof(xlen), simm));
  let vs2_val : vector('n, dec, bits('m)) = read_vreg(num_elem, vsew_bits, lmul, vs2);
  let vd_val  : vector('n, dec, bits('m)) = read_vreg(num_elem, vsew_bits, lmul, vd);
  result      : vector('n, dec, bits('m)) = undefined;
  mask_helper : vector('n, dec, bool)     = undefined;

  (result, mask_helper) = init_masked_result(num_elem, vsew_bits, lmul, vd_val, vm_val);
  
  foreach (i from 0 to (num_elem - 1)) {
    if mask_helper[i] == true then {
      result[i] = match funct6 {
        VI_VSLIDEUP     => {
                              assert(vs2 != vd);
                              assert(i - imm_val < 'n);
                              if i >= imm_val then vs2_val[i - imm_val] else vd_val[i]
                           },
        VI_VSLIDEDOWN   => {
                              assert(i + imm_val >= 0);
                              vlmax = floor(lmul * (to_real(sizeof(vlen)) / to_real(vsew_bits)));
                              if i + imm_val < vlmax then {
                                assert(i + imm_val < 'n); 
                                vs2_val[i + imm_val]
                              } else zeros()
                           },
        VI_VRGATHER     => {
                              assert(vs2 != vd);
                              assert(imm_val >= 0);
                              vlmax = floor(lmul * (to_real(sizeof(vlen)) / to_real(vsew_bits)));
                              if imm_val < vlmax then {
                                assert(imm_val < 'n); 
                                vs2_val[imm_val]
                              } else zeros() 
                           }
      }
    }
  };

  write_vreg(num_elem, vsew_bits, lmul, vd, result);
  writeCSR(csr_name_map("vstart"), EXTZ(0b0));
  RETIRE_SUCCESS
} 

mapping visg_mnemonic : visgfunct6 <-> string = {
  VI_VSLIDEUP     <-> "vslideup.vi",
  VI_VSLIDEDOWN   <-> "vslidedown.vi",
  VI_VRGATHER     <-> "vrgather.vi"
}

mapping clause assembly = VISG(funct6, vm, vs2, simm, vd)
  <-> visg_mnemonic(funct6) ^ spc() ^ vreg_name(vd) ^ sep() ^ vreg_name(vs2) ^ sep() ^ reg_name(simm) ^ maybe_vmask(vm)


/* ******************************Whole Vector Register Move(OPIVI)******************************** */

union clause ast = VMVRTYPE : (regidx, bits(5), regidx)

mapping clause encdec = VMVRTYPE(vs2, simm, vd)
  <-> 0b100111 @ 0b1 @ vs2 @ simm @ 0b011 @ vd @ 0b1010111

function clause execute(VMVRTYPE(vs2, simm, vd)) = {
  let vsew_bits  : int  = get_vtype_vsew();
  let imm_val    : int  = unsigned(EXTZ(sizeof(xlen), simm));
  let lmul       : int = imm_val + 1;
  assert( (lmul == 1) | (lmul == 2) | (lmul == 4) | (lmul == 8) );
  let num_elem   : int = get_num_elem(to_real(lmul), vsew_bits);
  assert(8 <= vsew_bits & vsew_bits <= 64);

  let 'num_elem = num_elem;
  let 'veew_bits = vsew_bits;
  let vs2_val : vector('num_elem, dec, bits('veew_bits)) = read_vreg(num_elem, vsew_bits, to_real(lmul), vs2);
  write_vreg(num_elem, vsew_bits, to_real(lmul), vd, vs2_val);

  RETIRE_SUCCESS
} 

mapping simm_string : bits(5) <-> string = {
  0b00000 <-> "1",
  0b00001 <-> "2",
  0b00011 <-> "4",
  0b00111 <-> "8"
}

mapping clause assembly = VMVRTYPE(vs2, simm, vd)
  <-> "vmv" ^ simm_string(simm) ^ "r.v" ^ spc() ^ vreg_name(vd) ^ sep() ^ vreg_name(vs2)


/* ******************************OPMVV(MVVtype)*********************************** */

union clause ast = MVVTYPE : (mvvfunct6, bits(1), regidx, regidx, regidx)

mapping encdec_mvvfunct6 : mvvfunct6 <-> bits(6) = {
  MVV_VAADDU      <-> 0b001000,
  MVV_VAADD       <-> 0b001001,
  MVV_VASUBU      <-> 0b001010,
  MVV_VASUB       <-> 0b001011,
  MVV_VMUL        <-> 0b100101,
  MVV_VMULH       <-> 0b100111,
  MVV_VMULHU      <-> 0b100100,
  MVV_VMULHSU     <-> 0b100110,
  MVV_VDIVU       <-> 0b100000,
  MVV_VDIV        <-> 0b100001,
  MVV_VREMU       <-> 0b100010,
  MVV_VREM        <-> 0b100011
}

mapping clause encdec = MVVTYPE(funct6, vm, vs2, vs1, vd)
  <-> encdec_mvvfunct6(funct6) @ vm @ vs2 @ vs1 @ 0b010 @ vd @ 0b1010111

function clause execute(MVVTYPE(funct6, vm, vs2, vs1, vd)) = {
  status : Retired = RETIRE_SUCCESS;
  let vsew_bits  : int = get_vtype_vsew();
  let lmul       : real = get_vtype_LMUL();
  let num_elem   : int = get_num_elem(lmul, vsew_bits);

  assert(8 <= vsew_bits & vsew_bits <= 64);
  assert(0 <= num_elem & num_elem <= sizeof(vlen));
  let 'n = num_elem;
  let 'm = vsew_bits;  

  let vm_val  : vector('n, dec, bool)     = read_vmask(num_elem, vm, vreg_name("v0"));
  let vs1_val : vector('n, dec, bits('m)) = read_vreg(num_elem, vsew_bits, lmul, vs1);
  let vs2_val : vector('n, dec, bits('m)) = read_vreg(num_elem, vsew_bits, lmul, vs2);
  let vd_val  : vector('n, dec, bits('m)) = read_vreg(num_elem, vsew_bits, lmul, vd);
  result      : vector('n, dec, bits('m)) = undefined;
  mask_helper : vector('n, dec, bool) = undefined;

  if 
     vm_val      == undefined /*
    | vs2_val     == undefined |
     vd_val     == undefined   */
  then {
    status = RETIRE_FAIL;
    print("status=fail")
  };

  if status == RETIRE_SUCCESS then {
    (result, mask_helper) = init_masked_result(num_elem, vsew_bits, lmul, vd_val, vm_val);
    foreach (i from 0 to (num_elem - 1)) {
      if mask_helper[i] == true then{
        //print("vs1_val[i]=" ^ BitStr(vs1_val[i]));
        //print("vs2_val[i]=" ^ BitStr(vs2_val[i]));
        result[i] = match funct6 {
          MVV_VAADDU         => {
                                  result_add = EXTZ('m + 1, vs2_val[i]) + EXTZ('m + 1, vs1_val[i]);
                                  rounding_incr = get_fixed_rounding_incr(result_add, 1);
                                  slice(result_add >> 1, 0, 'm) + EXTZ('m, rounding_incr)                              
                                },
          MVV_VAADD          => {
                                  result_add = EXTS('m + 1, vs2_val[i]) + EXTS('m + 1, vs1_val[i]);
                                  rounding_incr = get_fixed_rounding_incr(result_add, 1);
                                  slice(result_add >> 1, 0, 'm) + EXTZ('m, rounding_incr)
                                },
          MVV_VASUBU         => {
                                  result_sub = EXTZ('m + 1, vs2_val[i]) - EXTZ('m + 1, vs1_val[i]);
                                  rounding_incr = get_fixed_rounding_incr(result_sub, 1);
                                  slice(result_sub >> 1, 0, 'm) + EXTZ('m, rounding_incr)                             
                                },
          MVV_VASUB          => {
                                  result_sub = EXTS('m + 1, vs2_val[i]) - EXTS('m + 1, vs1_val[i]);
                                  rounding_incr = get_fixed_rounding_incr(result_sub, 1);
                                  slice(result_sub >> 1, 0, 'm) + EXTZ('m, rounding_incr)
                                },
          MVV_VMUL         => slice(to_bits(vsew_bits * 2, signed(vs2_val[i]) * signed(vs1_val[i])), 0, vsew_bits),
          MVV_VMULH        => slice(to_bits(vsew_bits * 2, signed(vs2_val[i]) * signed(vs1_val[i])), vsew_bits, vsew_bits),
          MVV_VMULHU       => slice(to_bits(vsew_bits * 2, unsigned(vs2_val[i]) * unsigned(vs1_val[i])), vsew_bits, vsew_bits),
          MVV_VMULHSU      => slice(to_bits(vsew_bits * 2, signed(vs2_val[i]) * unsigned(vs1_val[i])), vsew_bits, vsew_bits),
          MVV_VDIVU        => {
                              let q : int = if unsigned(vs1_val[i]) == 0 then -1 else quot_round_zero(unsigned(vs2_val[i]), unsigned(vs1_val[i]));
                              to_bits(vsew_bits, q)
                            },
          MVV_VDIV         => {
                              let sew_max : int = 2 ^ (vsew_bits - 1) - 1;
                              let sew_min : int = 0 - 2 ^ (vsew_bits - 1);
                              let q : int = if signed(vs1_val[i]) == 0 then -1 else quot_round_zero(signed(vs2_val[i]), signed(vs1_val[i]));
                              /* check for signed overflow */
                              let q' : int = if q > sew_max then sew_min else q;
                              to_bits(vsew_bits, q')
                            },
          MVV_VREMU        => {
                              let r : int = if unsigned(vs1_val[i]) == 0 then unsigned(vs2_val[i]) else rem_round_zero(unsigned(vs2_val[i]), unsigned(vs1_val[i]));
                              /* signed overflow case returns zero naturally as required due to -1 divisor */
                              to_bits(vsew_bits, r)
                            },
          MVV_VREM         => {
                              let r : int = if signed(vs1_val[i]) == 0 then signed(vs2_val[i]) else rem_round_zero(signed(vs2_val[i]), signed(vs1_val[i]));
                              /* signed overflow case returns zero naturally as required due to -1 divisor */
                              to_bits(vsew_bits, r)
                            }
        }
        //print_int("result[i]=", signed(result[i]))
      }
    }
  };
  write_vreg(num_elem, vsew_bits, lmul, vd, result);
  writeCSR(csr_name_map("vstart"), EXTZ(0b0));
  
  RETIRE_SUCCESS
}

mapping mvvtype_mnemonic : mvvfunct6 <-> string = {
  MVV_VAADDU   <-> "vaaddu.vv",
  MVV_VAADD    <-> "vaadd.vv",
  MVV_VASUBU   <-> "vasubu.vv",
  MVV_VASUB    <-> "vasub.vv",
  MVV_VMUL     <-> "vmul.vv",
  MVV_VMULH    <-> "vmulh.vv",
  MVV_VMULHU   <-> "vmulhu.vv",
  MVV_VMULHSU  <-> "vmulhsu.vv",
  MVV_VDIVU    <-> "vdivu.vv",
  MVV_VDIV     <-> "vdiv.vv",
  MVV_VREMU    <-> "vremu.vv",
  MVV_VREM     <-> "vrem.vv"
}

mapping clause assembly = MVVTYPE(funct6, vm, vs2, vs1, vd)
  <-> mvvtype_mnemonic(funct6) ^ spc() ^ vreg_name(vd) ^ sep() ^ vreg_name(vs2) ^ sep() ^ vreg_name(vs1) ^ maybe_vmask(vm)  


/* ******************************OPMVV(MVVtype Multiply-Add)*********************************** */
/* Multiply-Add instructions switch the order of two operands in assembly (vs1 / rs1 before vs2) */

union clause ast = MVVMATYPE : (mvvmafunct6, bits(1), regidx, regidx, regidx)

mapping encdec_mvvmafunct6 : mvvmafunct6 <-> bits(6) = {
  MVV_VMACC       <-> 0b101101,
  MVV_VNMSAC      <-> 0b101111,
  MVV_VMADD       <-> 0b101001,
  MVV_VNMSUB      <-> 0b101011
}

mapping clause encdec = MVVMATYPE(funct6, vm, vs2, vs1, vd_or_rd)
  <-> encdec_mvvmafunct6(funct6) @ vm @ vs2 @ vs1 @ 0b010 @ vd_or_rd @ 0b1010111

function clause execute(MVVMATYPE(funct6, vm, vs2, vs1, vd_or_rd)) = {
  status : Retired = RETIRE_SUCCESS;
  let vsew_bits  : int = get_vtype_vsew();
  let lmul       : real = get_vtype_LMUL();
  let num_elem   : int = get_num_elem(lmul, vsew_bits);

  assert(8 <= vsew_bits & vsew_bits <= 64);
  assert(0 <= num_elem & num_elem <= sizeof(vlen));
  let 'n = num_elem;
  let 'm = vsew_bits;
  let vm_val  : vector('n, dec, bool)     = read_vmask(num_elem, vm, vreg_name("v0"));
  let vs1_val : vector('n, dec, bits('m)) = read_vreg(num_elem, vsew_bits, lmul, vs1);
  let vs2_val : vector('n, dec, bits('m)) = read_vreg(num_elem, vsew_bits, lmul, vs2);
  let vd_or_rd_val : vector('n, dec, bits('m)) = read_vreg(num_elem, vsew_bits, lmul, vd_or_rd);
  result      : vector('n, dec, bits('m)) = undefined;
  mask_helper : vector('n, dec, bool) = undefined;

  if 
     vm_val      == undefined /*
    | vs2_val     == undefined |
     vd_val     == undefined   */
  then {
    status = RETIRE_FAIL;
    print("status=fail")
  };

  if status == RETIRE_SUCCESS then {
    (result, mask_helper) = init_masked_result(num_elem, vsew_bits, lmul, vd_or_rd_val, vm_val);
    foreach (i from 0 to (num_elem - 1)){
      if mask_helper[i] == true then{
        //print("vs1_val[i]=" ^ BitStr(vs1_val[i]));
        //print("vs2_val[i]=" ^ BitStr(vs2_val[i]));
        result[i] = match funct6 {
        MVV_VMACC          => slice(to_bits(sizeof(vlen) , signed(vs1_val[i]) * signed(vs2_val[i]) ), 0, vsew_bits) + vd_or_rd_val[i],
        MVV_VNMSAC         => vd_or_rd_val[i] - slice(to_bits(sizeof(vlen) , signed(vs1_val[i]) * signed(vs2_val[i]) ), 0, vsew_bits),
        MVV_VMADD          => slice(to_bits(sizeof(vlen) , signed(vs1_val[i]) * signed(vd_or_rd_val[i]) ), 0, vsew_bits) + vs2_val[i],
        MVV_VNMSUB         => vs2_val[i] - slice(to_bits(sizeof(vlen) , signed(vs1_val[i]) * signed(vd_or_rd_val[i]) ), 0, vsew_bits)
        }
      }
    }
  };
  write_vreg(num_elem, vsew_bits, lmul, vd_or_rd, result);
  writeCSR(csr_name_map("vstart"), EXTZ(0b0));
  
  RETIRE_SUCCESS
}

mapping mvvmatype_mnemonic : mvvmafunct6 <-> string = {
  MVV_VMACC    <-> "vmacc.vv",
  MVV_VNMSAC   <-> "vnmsac.vv",
  MVV_VMADD    <-> "vmadd.vv",
  MVV_VNMSUB   <-> "vnmsub.vv"
}

mapping clause assembly = MVVMATYPE(funct6, vm, vs2, vs1, vd_or_rd)
  <-> mvvmatype_mnemonic(funct6) ^ spc() ^ vreg_name(vd_or_rd) ^ sep() ^ vreg_name(vs1) ^ sep() ^ vreg_name(vs2) ^ maybe_vmask(vm)  


/* *******************************OPMVX(MVXtype)********************************** */

union clause ast = MVXTYPE : (mvxfunct6, bits(1), regidx, regidx, regidx)

mapping encdec_mvxfunct6 : mvxfunct6 <-> bits(6) = {
  MVX_VAADDU        <-> 0b001000,
  MVX_VAADD         <-> 0b001001,
  MVX_VASUBU        <-> 0b001010,
  MVX_VASUB         <-> 0b001011,
  MVX_VSLIDE1UP     <-> 0b001110,
  MVX_VSLIDE1DOWN   <-> 0b001111,
  MVX_VMUL          <-> 0b100101,
  MVX_VMULH         <-> 0b100111,
  MVX_VMULHU        <-> 0b100100,
  MVX_VMULHSU       <-> 0b100110,
  MVX_VDIVU         <-> 0b100000,
  MVX_VDIV          <-> 0b100001,
  MVX_VREMU         <-> 0b100010,
  MVX_VREM          <-> 0b100011
}

mapping clause encdec = MVXTYPE(funct6, vm, vs2, rs1, vd)
  <-> encdec_mvxfunct6(funct6) @ vm @ vs2 @ rs1 @ 0b110 @ vd @ 0b1010111 

function clause execute(MVXTYPE(funct6, vm, vs2, rs1, vd)) = {
  let vsew_bits  : int = get_vtype_vsew();
  let lmul       : real = get_vtype_LMUL();
  let num_elem   : int = get_num_elem(lmul, vsew_bits);

  assert(8 <= vsew_bits & vsew_bits <= 64);
  assert(0 <= num_elem & num_elem <= sizeof(vlen));
  let 'n = num_elem;
  let 'm = vsew_bits;

  let vm_val  : vector('n, dec, bool)     = read_vmask(num_elem, vm, vreg_name("v0"));
  let vs2_val : vector('n, dec, bits('m)) = read_vreg(num_elem, vsew_bits, lmul, vs2);
  let rs1_val = get_scalar(rs1, vsew_bits);
  let vd_val : vector('n, dec, bits('m)) = read_vreg(num_elem, vsew_bits, lmul, vd);
  result      : vector('n, dec, bits('m)) = undefined;
  mask_helper : vector('n, dec, bool) = undefined;

  (result, mask_helper) = init_masked_result(num_elem, vsew_bits, lmul, vd_val, vm_val);

  foreach (i from 0 to (num_elem - 1)) {
    if mask_helper[i] == true then {
      result[i] = match funct6 {
        MVX_VAADDU         => {
                                result_add = EXTZ('m + 1, vs2_val[i]) + EXTZ('m + 1, rs1_val);
                                rounding_incr = get_fixed_rounding_incr(result_add, 1);
                                slice(result_add >> 1, 0, 'm) + EXTZ('m, rounding_incr)                              
                              },
        MVX_VAADD          => {
                                result_add = EXTS('m + 1, vs2_val[i]) + EXTS('m + 1, rs1_val);
                                rounding_incr = get_fixed_rounding_incr(result_add, 1);
                                slice(result_add >> 1, 0, 'm) + EXTZ('m, rounding_incr)
                              },
        MVX_VASUBU         => {
                                result_sub = EXTZ('m + 1, vs2_val[i]) - EXTZ('m + 1, rs1_val);
                                rounding_incr = get_fixed_rounding_incr(result_sub, 1);
                                slice(result_sub >> 1, 0, 'm) + EXTZ('m, rounding_incr)                               
                              },
        MVX_VASUB          => {
                                result_sub = EXTS('m + 1, vs2_val[i]) - EXTS('m + 1, rs1_val);
                                rounding_incr = get_fixed_rounding_incr(result_sub, 1);
                                slice(result_sub >> 1, 0, 'm) + EXTZ('m, rounding_incr)
                              },
        MVX_VSLIDE1UP      => {
                                assert(vs2 != vd);
                                if i == 0 then rs1_val else vs2_val[i - 1]
                              },
        MVX_VSLIDE1DOWN    => {
                                assert(vs2 != vd);
                                let last_elem = get_end_element();
                                assert(last_elem < num_elem);
                                if i < last_elem then vs2_val[i + 1] else rs1_val
                              },
        MVX_VMUL         => slice(to_bits(vsew_bits * 2, signed(vs2_val[i]) * signed(rs1_val)), 0, vsew_bits),
        MVX_VMULH        => slice(to_bits(vsew_bits * 2, signed(vs2_val[i]) * signed(rs1_val)), vsew_bits, vsew_bits),
        MVX_VMULHU       => slice(to_bits(vsew_bits * 2, unsigned(vs2_val[i]) * unsigned(rs1_val)), vsew_bits, vsew_bits),
        MVX_VMULHSU      => slice(to_bits(vsew_bits * 2, signed(vs2_val[i]) * unsigned(rs1_val)), vsew_bits, vsew_bits),
        MVX_VDIVU        => {
                             let q : int = if unsigned(rs1_val) == 0 then -1 else quot_round_zero(unsigned(vs2_val[i]), unsigned(rs1_val));
                             to_bits(vsew_bits, q)
                           },
        MVX_VDIV         => {
                             let sew_max : int = 2 ^ (vsew_bits - 1) - 1;
                             let sew_min : int = 0 - 2 ^ (vsew_bits - 1);
                             let q : int = if signed(rs1_val) == 0 then -1 else quot_round_zero(signed(vs2_val[i]), signed(rs1_val));
                             /* check for signed overflow */
                             let q' : int = if q > sew_max then sew_min else q;
                             to_bits(vsew_bits, q')
                           },
        MVX_VREMU        => {
                             let r : int = if unsigned(rs1_val) == 0 then unsigned(vs2_val[i]) else rem_round_zero(unsigned(vs2_val[i]), unsigned(rs1_val));
                             /* signed overflow case returns zero naturally as required due to -1 divisor */
                             to_bits(vsew_bits, r)
                           },
        MVX_VREM         => {
                             let r : int = if signed(rs1_val) == 0 then signed(vs2_val[i]) else rem_round_zero(signed(vs2_val[i]), signed(rs1_val));
                             /* signed overflow case returns zero naturally as required due to -1 divisor */
                             to_bits(vsew_bits, r)
                           }
      }
    }
  };

  write_vreg(num_elem, vsew_bits, lmul, vd, result);
  RETIRE_SUCCESS
}

mapping mvxtype_mnemonic : mvxfunct6 <-> string = {
  MVX_VAADDU        <-> "vaaddu.vx",
  MVX_VAADD         <-> "vaadd.vx",
  MVX_VASUBU        <-> "vasubu.vx",
  MVX_VASUB         <-> "vasub.vx",
  MVX_VSLIDE1UP     <-> "vslide1up.vx",
  MVX_VSLIDE1DOWN   <-> "vslide1down.vx",
  MVX_VMUL          <-> "vmul.vx",
  MVX_VMULH         <-> "vmulh.vx",
  MVX_VMULHU        <-> "vmulhu.vx",
  MVX_VMULHSU       <-> "vmulhsu.vx",
  MVX_VDIVU         <-> "vdivu.vx",
  MVX_VDIV          <-> "vdiv.vx",
  MVX_VREMU         <-> "vremu.vx",
  MVX_VREM          <-> "vrem.vx"
}

mapping clause assembly = MVXTYPE(funct6, vm, vs2, rs1, vd)
  <-> mvxtype_mnemonic(funct6) ^ spc() ^ vreg_name(vd) ^ sep() ^ vreg_name(vs2) ^ sep() ^ reg_name(rs1) ^ maybe_vmask(vm) 


/* *******************************OPMVX(MVXtype Multiply-Add)********************************** */
/* Multiply-Add instructions switch the order of two operands in assembly (vs1 / rs1 before vs2)  */

union clause ast = MVXMATYPE : (mvxmafunct6, bits(1), regidx, regidx, regidx)

mapping encdec_mvxmafunct6 : mvxmafunct6 <-> bits(6) = {
  MVX_VMACC         <-> 0b101101,
  MVX_VNMSAC        <-> 0b101111,
  MVX_VMADD         <-> 0b101001,
  MVX_VNMSUB        <-> 0b101011
}

mapping clause encdec = MVXMATYPE(funct6, vm, vs2, rs1, vd_or_rd)
  <-> encdec_mvxmafunct6(funct6) @ vm @ vs2 @ rs1 @ 0b110 @ vd_or_rd @ 0b1010111 

function clause execute(MVXMATYPE(funct6, vm, vs2, rs1, vd_or_rd)) = {
  status : Retired = RETIRE_SUCCESS;
  let vsew_bits  : int = get_vtype_vsew();
  let lmul       : real = get_vtype_LMUL();
  let num_elem   : int = get_num_elem(lmul, vsew_bits);
  
  assert(8 <= vsew_bits & vsew_bits <= 64);
  assert(0 <= num_elem & num_elem <= sizeof(vlen));
  let 'n = num_elem;
  let 'm = vsew_bits;
  let vm_val  : vector('n, dec, bool)     = read_vmask(num_elem, vm, vreg_name("v0"));
  let rs1_val = get_scalar(rs1, vsew_bits);
  let vs2_val : vector('n, dec, bits('m)) = read_vreg(num_elem, vsew_bits, lmul, vs2);
  let vd_or_rd_val : vector('n, dec, bits('m)) = read_vreg(num_elem, vsew_bits, lmul, vd_or_rd);
  result      : vector('n, dec, bits('m)) = undefined;
  mask_helper : vector('n, dec, bool) = undefined;

  if 
     vm_val      == undefined /*
    | vs2_val     == undefined |
     vd_val     == undefined   */
  then {
    status = RETIRE_FAIL;
    print("status=fail")
  };

  if status == RETIRE_SUCCESS then {
    (result, mask_helper) = init_masked_result(num_elem, vsew_bits, lmul, vd_or_rd_val, vm_val);
    foreach (i from 0 to (num_elem - 1)){
      if mask_helper[i] == true then{
        result[i] = match funct6 {
        MVX_VMACC          => slice(to_bits(sizeof(vlen) , signed(rs1_val) * signed(vs2_val[i]) ), 0, vsew_bits) + vd_or_rd_val[i],
        MVX_VNMSAC         => vd_or_rd_val[i] - slice(to_bits(sizeof(vlen) , signed(rs1_val) * signed(vs2_val[i]) ), 0, vsew_bits),
        MVX_VMADD          => slice(to_bits(sizeof(vlen) , signed(rs1_val) * signed(vd_or_rd_val[i]) ), 0, vsew_bits) + vs2_val[i],
        MVX_VNMSUB         => vs2_val[i] - slice(to_bits(sizeof(vlen) , signed(rs1_val) * signed(vd_or_rd_val[i]) ), 0, vsew_bits)
        }
      }
    }
  };

  write_vreg(num_elem, vsew_bits, lmul, vd_or_rd, result);
  writeCSR(csr_name_map("vstart"), EXTZ(0b0));
  
  RETIRE_SUCCESS
}

mapping mvxmatype_mnemonic : mvxmafunct6 <-> string = {
  MVX_VMACC         <-> "vmacc.vx",
  MVX_VNMSAC        <-> "vnmsac.vx",
  MVX_VMADD         <-> "vmadd.vx",
  MVX_VNMSUB        <-> "vnmsub.vx"
}

mapping clause assembly = MVXMATYPE(funct6, vm, vs2, rs1, vd_or_rd)
  <-> mvxmatype_mnemonic(funct6) ^ spc() ^ vreg_name(vd_or_rd) ^ sep() ^ reg_name(rs1) ^ sep() ^ vreg_name(vs2) ^ maybe_vmask(vm) 


/* **************************OPMVV(MVVtype)Widened Multiply-Add******************************** */ 
/* Multiply-Add instructions switch the order of two operands in assembly (vs1 / rs1 before vs2) */

union clause ast = WMVVTYPE : (wmvvfunct6, bits(1), regidx, regidx, regidx)

mapping encdec_wmvvfunct6 : wmvvfunct6 <-> bits(6) = {
  WMVV_VWMACCU   <-> 0b111100,
  WMVV_VWMACC     <-> 0b111101,
  WMVV_VWMACCSU  <-> 0b111111
}

mapping clause encdec =  WMVVTYPE(funct6, vm, vs2, vs1, vd_or_rd)
  <-> encdec_wmvvfunct6(funct6) @ vm @ vs2 @ vs1 @ 0b010 @ vd_or_rd @ 0b1010111

val process_wmvv : forall 'n 'm, (8 <= 'm & 'm <= 64) & (0 <= 'n & 'n <= vlen) . (wmvvfunct6, bits(1), regidx, regidx, regidx, int('n), int('m), real ) -> Retired effect {escape, rreg, undef, wreg} 
function process_wmvv(funct6, vm, vs2, vs1, vd_or_rd, num_elem, vsew_bits, lmul) = {
  let vm_val  : vector('n, dec, bool)     = read_vmask(num_elem, vm, vreg_name("v0"));
  let vs1_val : vector('n, dec, bits('m)) = read_vreg(num_elem, vsew_bits, lmul, vs1);
  let vs2_val : vector('n, dec, bits('m)) = read_vreg(num_elem, vsew_bits, lmul, vs2);
  let double_vsew : int = vsew_bits * 2;
  let double_lmul : real = lmul * 2.0;
  assert(8 <= double_vsew & double_vsew <= 64);
  let 'o = double_vsew;
  let vd_or_rd_val : vector('n, dec, bits('o)) = read_vreg(num_elem, double_vsew, double_lmul, vd_or_rd);

  result : vector('n, dec, bits('o)) =  undefined;
  mask_helper : vector('n, dec, bool) = undefined;

  (result, mask_helper) = init_masked_result(num_elem, double_vsew, double_lmul, vd_or_rd_val, vm_val);

  foreach (i from 0 to (num_elem - 1)) {
    if mask_helper[i] == true then {
      result[i] = match funct6 {
        WMVV_VWMACC       => to_bits( double_vsew, signed(vs1_val[i]) * signed(vs2_val[i]) ) + vd_or_rd_val[i],
      /*WMVV_VWMACCU      => double_bit_mul(vsew_bits, vs1_val[i], vs2_val[i]) + vd_or_rd_val[i],*/
        WMVV_VWMACCU      => to_bits( double_vsew, unsigned(vs1_val[i]) * unsigned(vs2_val[i]) ) + vd_or_rd_val[i], 
        WMVV_VWMACCSU     => to_bits( double_vsew, signed(vs1_val[i]) * unsigned(vs2_val[i]) )+ vd_or_rd_val[i]
      }
    }
  };

  write_vreg(num_elem, double_vsew, lmul, vd_or_rd, result);
  RETIRE_SUCCESS
}

function clause execute(WMVVTYPE(funct6, vm, vs2, vs1, vd_or_rd)) = {
  let vsew_bits  : int  = get_vtype_vsew();
  let lmul       : real = get_vtype_LMUL();
  let num_elem   : int  = get_num_elem(lmul, vsew_bits);
  assert(8 <= vsew_bits & vsew_bits <= 64);
  //assert(8 <= vsew_bits & vsew_bits <= 32);
  /* assert(vsew_bits >=8 & vsew_bits <= 64); */
  assert(0 <= num_elem & num_elem <= sizeof(vlen));
  process_wmvv(funct6, vm, vs2, vs1, vd_or_rd, num_elem, vsew_bits, lmul)
}

mapping wmvvtype_mnemonic : wmvvfunct6 <-> string = {
  WMVV_VWMACCU     <-> "vwmaccu.vv",
  WMVV_VWMACC      <-> "vwmacc.vv",
  WMVV_VWMACCSU    <-> "vwmaccsu.vv"
}

mapping clause assembly = WMVVTYPE(funct6, vm, vs2, vs1, vd_or_rd)
  <-> wmvvtype_mnemonic(funct6) ^ spc() ^ vreg_name(vd_or_rd) ^ sep() ^ vreg_name(vs1) ^ sep() ^ vreg_name(vs2) ^ maybe_vmask(vm)  


/* **************************OPMVX(MVXtype)Widened Multiply-Add******************************** */ 
/* Multiply-Add instructions switch the order of two operands in assembly (vs1 / rs1 before vs2) */

union clause ast =  WMVXTYPE : (wmvxfunct6, bits(1), regidx, regidx, regidx)

mapping encdec_wmvxfunct6 : wmvxfunct6 <-> bits(6) = {
  WMVX_VWMACCU    <-> 0b111100,
  WMVX_VWMACC     <-> 0b111101,
  WMVX_VWMACCUS   <-> 0b111110,
  WMVX_VWMACCSU   <-> 0b111111
}

mapping clause encdec = WMVXTYPE(funct6, vm, vs2, rs1, vd_or_rd)
  <-> encdec_wmvxfunct6(funct6) @ vm @ vs2 @ rs1 @ 0b110 @ vd_or_rd @ 0b1010111 

function clause execute(WMVXTYPE(funct6, vm, vs2, rs1, vd_or_rd)) = {
  status          : Retired = RETIRE_SUCCESS;
  let vsew_bits  : int = get_vtype_vsew();
  let lmul : real = get_vtype_LMUL();
  let double_vsew : int  = vsew_bits * 2;
  let num_elem    : int  = get_num_elem(lmul, vsew_bits);
  let double_lmul : real = lmul * 2.0;

  assert(8 <= vsew_bits & vsew_bits <= 64);
  /* assert(8 <= double_vsew & double_vsew <= 64);*/
  assert(0 <= num_elem & num_elem <= sizeof(vlen));
  let 'n = num_elem;
  let 'm = vsew_bits;
  let 'o = double_vsew;
  assert(8 <= double_vsew & double_vsew <= 64);

  let vm_val : vector('n, dec, bool) = read_vmask(num_elem, vm, vreg_name("v0"));
  let vd_or_rd_val  : vector('n, dec, bits('o)) = read_vreg(num_elem, double_vsew, double_lmul, vd_or_rd);
  let rs1_val = get_scalar(rs1, vsew_bits);
  let vs2_val : vector('n, dec, bits('m)) = read_vreg(num_elem, vsew_bits, lmul, vs2);
  result : vector('n, dec, bits('o)) = undefined;
  mask_helper : vector('n, dec, bool) = undefined;

  if vm_val == undefined  
  then {
    status = RETIRE_FAIL;
    //print("status=fail")
  };

  if status == RETIRE_SUCCESS then {
    (result, mask_helper) = init_masked_result(num_elem, double_vsew, double_lmul, vd_or_rd_val, vm_val);
    foreach (i from 0 to (num_elem - 1)) {
      if mask_helper[i] == true then {
        //print_int("vs1=", signed(vs1_val[i]));
        //print_int("vs1=", signed(vs2_val[i]));
        result[i] = match funct6 {
          WMVX_VWMACCU      => (to_bits( double_vsew, unsigned(rs1_val) * unsigned(vs2_val[i]) )) + vd_or_rd_val[i],
          WMVX_VWMACC       => (to_bits( double_vsew, signed(rs1_val) * signed(vs2_val[i]) )) + vd_or_rd_val[i], 
          WMVX_VWMACCUS     => (to_bits( double_vsew, unsigned(rs1_val) * signed(vs2_val[i]) ))+ vd_or_rd_val[i],
          WMVX_VWMACCSU     => (to_bits( double_vsew, signed(rs1_val) * unsigned(vs2_val[i]) ))+ vd_or_rd_val[i]
        }
      }
    }
  };
  
  write_vreg(num_elem, double_vsew, lmul * 2.0, vd_or_rd, result);
  writeCSR(csr_name_map("vstart"), EXTZ(0b0));
  
  status = vcheck_vsew_lmul(double_vsew, double_lmul);

  if status == RETIRE_FAIL then handle_illegal();
  status
}

mapping wmvxtype_mnemonic : wmvxfunct6 <-> string = {
  WMVX_VWMACCU     <-> "vwmaccu.vx",
  WMVX_VWMACC      <-> "vwmacc.vx",
  WMVX_VWMACCUS    <-> "vwmaccus.vx",
  WMVX_VWMACCSU    <-> "vwmaccsu.vx"
}

mapping clause assembly = WMVXTYPE(funct6, vm, vs2, rs1, vd_or_rd)
  <-> wmvxtype_mnemonic(funct6) ^ spc() ^ vreg_name(vd_or_rd) ^ sep() ^ reg_name(rs1) ^ sep() ^ vreg_name(vs2) ^ maybe_vmask(vm)  


/* **************************OPMVV(Vector Compress Instruction)*************************************** */

union clause ast = MVVCOMPRESS : (regidx, regidx, regidx)

mapping clause encdec = MVVCOMPRESS(vs2, vs1, vd)
  <-> 0b010111 @ 0b1 @ vs2 @ vs1 @ 0b010 @ vd @ 0b1010111

function clause execute(MVVCOMPRESS(vs2, vs1, vd)) = {
  let start_element : int = get_start_element();
  if start_element != 0 then {
    handle_illegal();
    RETIRE_FAIL
  } else {
    let vsew_bits  : int = get_vtype_vsew();
    let lmul       : real = get_vtype_LMUL();
    let num_elem   : int = get_num_elem(lmul, vsew_bits);

    assert(8 <= vsew_bits & vsew_bits <= 64);
    assert(0 <= num_elem & num_elem <= sizeof(vlen));
    assert(vd != vs1 & vd != vs2);
    let 'n = num_elem;
    let 'm = vsew_bits; 

    /* vcompress should always be executed with a vstart of 0 */
    let start_element : int = get_start_element();
    let end_element   : int = get_end_element();
    assert(start_element == 0); 
    assert(end_element < num_elem);

    let vs1_val : vector('n, dec, bool)     = read_vmask(num_elem, 0b0, vs1);
    let vs2_val : vector('n, dec, bits('m)) = read_vreg(num_elem, vsew_bits, lmul, vs2);
    let vd_val  : vector('n, dec, bits('m)) = read_vreg(num_elem, vsew_bits, lmul, vd);
    result      : vector('n, dec, bits('m)) = undefined;

    /* body elements */
    vd_idx : int = 0;
    foreach (i from 0 to end_element) {
      if vs1_val[i] == true then {
        let 'p = vd_idx;
        assert(0 <= 'p & 'p < 'n);
        result['p] = vs2_val[i];
        vd_idx = vd_idx + 1;
      };
    };
    /* tail elements */
    if vd_idx < num_elem then {
      let tail_ag : agtype = get_vtype_vta();
      let 'p = vd_idx;
      if tail_ag == UNDISTURBED then {
        assert('p >= 0);
        foreach (i from 'p to (num_elem - 1)) result[i] = vd_val[i]
      }
      else if tail_ag == AGNOSTIC then {
        assert('p >= 0);
        foreach (i from 'p to (num_elem - 1)) {
          //result[i] = sail_sign_extend(0b1, vsew_bits)
          result[i] = vd_val[i]
        };
      };
    };

    write_vreg(num_elem, vsew_bits, lmul, vd, result);
    RETIRE_SUCCESS
  };
}

mapping clause assembly = MVVCOMPRESS(vs2, vs1, vd)
  <-> "vcompress.vm" ^ spc() ^ vreg_name(vd) ^ sep() ^ vreg_name(vs2) ^ sep() ^ vreg_name(vs1)


/* *******************************OPMVV(VWXUNARY0)******************************** */

union clause ast = VMVXS : (regidx, regidx)

mapping clause encdec = VMVXS(vs2, rd)
  <-> 0b010000 @ 0b1 @ vs2 @ 0b00000 @ 0b010 @ rd @ 0b1010111

function clause execute(VMVXS(vs2, rd)) = {
  let vsew_bits  : int  = get_vtype_vsew();
  let lmul       : real = get_vtype_LMUL();
  let num_elem   : int = get_num_elem(lmul, vsew_bits);

  assert(8 <= vsew_bits & vsew_bits <= 64);
  assert(0 < num_elem & num_elem <= sizeof(vlen));
  let 'n = num_elem;
  let 'm = vsew_bits;

  let vs2_val : vector('n, dec, bits('m)) = read_vreg(num_elem, vsew_bits, lmul, vs2);
  if sizeof(xlen) < vsew_bits then X(rd) = slice(vs2_val[0], 0, sizeof(xlen))
  else if sizeof(xlen) > vsew_bits then X(rd) = sail_sign_extend(vs2_val[0], sizeof(xlen))
  else X(rd) = vs2_val[0];
  //print("vs2_val[0]=" ^ BitStr(vs2_val[0]));
  //print("rd_val=" ^ BitStr(X(rd)));
  writeCSR(csr_name_map("vstart"), EXTZ(0b0));

  RETIRE_SUCCESS
}

mapping clause assembly = VMVXS(vs2, rd)
  <-> "vmv.x.s" ^ spc() ^ reg_name(rd) ^ sep() ^ vreg_name(vs2)


/* *******************************OPMVX(VRXUNARY0)******************************** */

union clause ast = VMVSX : (regidx, regidx)

mapping clause encdec = VMVSX(rs1, vd)
  <-> 0b010000 @ 0b1 @ 0b00000 @ rs1 @ 0b110 @ vd @ 0b1010111

function clause execute(VMVSX(rs1, vd)) = {
  let vsew_bits  : int  = get_vtype_vsew();
  let num_elem   : int  = get_num_elem(1.0, vsew_bits);

  assert(8 <= vsew_bits & vsew_bits <= 64);
  assert(0 < num_elem & num_elem <= sizeof(vlen));
  let 'n = num_elem;
  let 'm = vsew_bits;

  let vm_val  : vector('n, dec, bool)     = read_vmask(num_elem, 0b1, vreg_name("v0"));
  let rs1_val = get_scalar(rs1, 'm);
  let vd_val  : vector('n, dec, bits('m)) = read_vreg(num_elem, vsew_bits, 1.0, vd);
  result      : vector('n, dec, bits('m)) = undefined;
  mask_helper : vector('n, dec, bool)     = undefined;

  (result, mask_helper) = init_masked_result(num_elem, vsew_bits, 1.0, vd_val, vm_val);
  
  /* one body element */
  if mask_helper[0] == true then result[0] = rs1_val;

  /* others treated as tail elements */
  let tail_ag : agtype = get_vtype_vta();
  if tail_ag == UNDISTURBED then {
    foreach (i from 1 to (num_elem - 1)) result[i] = vd_val[i]
  }
  else if tail_ag == AGNOSTIC then {
    foreach (i from 1 to (num_elem - 1)) {
      //result[i] = sail_sign_extend(0b1, vsew_bits)
      result[i] = vd_val[i]
    }
  };

  write_vreg(num_elem, vsew_bits, 1.0, vd, result);
  RETIRE_SUCCESS
}

mapping clause assembly = VMVSX(rs1, vd)
  <-> "vmv.s.x" ^ spc() ^ vreg_name(vd) ^ sep() ^ reg_name(rs1)


/* **************************Mask instruction(OPIVV)*************************************** */

union clause ast = MASKTYPEV : (regidx, regidx, regidx)

mapping clause encdec = MASKTYPEV (vs2, vs1,  vd)
  <-> 0b010111 @ 0b0 @ vs2 @ vs1 @ 0b000 @ vd @ 0b1010111

val process_maskv : forall 'n 'm, 'm >= 8. (regidx, regidx, regidx, int('n), int('m)) -> Retired effect {escape, rreg, undef, wreg}
function process_maskv(vs2, vs1, vd, total_num_element, vsew_bits) = {
  let vs1_val : vector('n, dec, bits('m)) = split_vreg(total_num_element, vsew_bits, V(vs1));
  let vs2_val : vector('n, dec, bits('m)) = split_vreg(total_num_element, vsew_bits, V(vs2));
  let v0_val = V(vreg_id("v0"));

  result : vector('n, dec, bits('m)) = undefined;

  foreach (i from 0 to (total_num_element - 1)) {
    if slice(v0_val, i, 1) == 0b0 then {
      result[i] = vs1_val[i]
    }
    else {
      result[i] = vs2_val[i]
    }
  };

  V(vd) = join_vreg(total_num_element, vsew_bits, result);

  RETIRE_SUCCESS
}

function clause execute(MASKTYPEV(vs2, vs1, vd)) = {
  let start_element : int = get_start_element();
  let vsew_bits  : int = get_vtype_vsew();
  let total_num_element : int = unsigned (readCSR(csr_name_map("vl")));
  assert(vsew_bits >= 8);
  process_maskv(vs2, vs1, vd, total_num_element, vsew_bits)
}

mapping clause assembly = MASKTYPEV(vs2, vs1, vd)
<-> "vmerge.vvm" ^ spc() ^ vreg_name(vd) ^ sep() ^ vreg_name(vs2) ^ sep() ^ vreg_name(vs1) ^ sep() ^ "v0" 


/* **************************Mask instruction(OPIVX)*************************************** */

union clause ast = MASKTYPEX : (regidx, regidx, regidx)

mapping clause encdec = MASKTYPEX(vs2, rs1, vd)
  <-> 0b010111 @ 0b0 @ vs2 @ rs1 @ 0b100 @ vd @ 0b1010111

val process_maskx : forall 'n 'm, 'm >= 8. (regidx, regidx, regidx, int('n), int('m)) -> Retired effect {escape, rreg, undef, wreg}
function process_maskx(vs2, rs1, vd, total_num_element, vsew_bits) = {
  let rs1_val = get_scalar(rs1, vsew_bits);
  let vs2_val : vector('n, dec, bits('m)) = split_vreg(total_num_element, vsew_bits, V(vs2));
  let v0_val = V(vreg_id("v0"));

  result : vector('n, dec, bits('m)) = undefined;

  foreach (i from 0 to (total_num_element - 1)) {
    if slice(v0_val, i, 1) == 0b0 then {
      result[i] = rs1_val
    }
    else {
      result[i] = vs2_val[i]
    }
  };

  V(vd) = join_vreg(total_num_element, vsew_bits, result);

  RETIRE_SUCCESS
}

function clause execute(MASKTYPEX(vs2, rs1, vd)) = {
  let start_element : int = get_start_element();
  let vsew_bits  : int = get_vtype_vsew();
  let total_num_element : int = unsigned (readCSR(csr_name_map("vl")));
  assert(vsew_bits >= 8);
  process_maskx(vs2, rs1, vd, total_num_element, vsew_bits)
}

mapping clause assembly = MASKTYPEX(vs2, rs1, vd)
  <-> "vmerge.vxm" ^ spc() ^ vreg_name(vd) ^ sep() ^ vreg_name(vs2) ^ sep() ^ reg_name(rs1) ^ sep() ^ "v0" 


/* **************************Mask instruction(OPIVI)*************************************** */

union clause ast = MASKTYPEI : (regidx, bits(5), regidx)

mapping clause encdec = MASKTYPEI(vs2, simm, vd)
  <-> 0b010111 @ 0b0 @ vs2 @ simm @ 0b011 @ vd @ 0b1010111

val process_maski : forall 'n 'm, 'm >= 8. (regidx, bits(5), regidx, int('n), int('m)) -> Retired effect {escape, rreg, undef, wreg}
function process_maski(vs2, simm, vd, total_num_element, vsew_bits) = {
  let simm = sail_sign_extend(simm, vsew_bits);
  let vs2_val : vector('n, dec, bits('m)) = split_vreg(total_num_element, vsew_bits, V(vs2));
  let v0_val = V(vreg_id("v0"));

  result : vector('n, dec, bits('m)) = undefined;

  foreach (i from 0 to (total_num_element - 1)) {
    if slice(v0_val, i, 1) == 0b0 then {
      result[i] = simm
    }
    else {
      result[i] = vs2_val[i]
    }
  };

  V(vd) = join_vreg(total_num_element, vsew_bits, result);

  RETIRE_SUCCESS
}

function clause execute(MASKTYPEI(vs2, simm, vd)) = {
  let start_element : int = get_start_element();
  let vsew_bits  : int = get_vtype_vsew();
  let total_num_element : int = unsigned (readCSR(csr_name_map("vl")));
  assert(vsew_bits >= 8);
  process_maski(vs2, simm, vd, total_num_element, vsew_bits)
}

mapping clause assembly = MASKTYPEI(vs2, simm, vd)
  <-> "vmerge.vim" ^ spc() ^ vreg_name(vd) ^ sep() ^ vreg_name(vs2) ^ sep() ^ hex_bits_5(simm) ^ sep() ^ "v0" 


/* **************************Integer move instruction(OPIVV)*************************************** */

union clause ast = MOVETYPEV : (regidx, regidx)

mapping clause encdec = MOVETYPEV (vs1, vd)
  <-> 0b010111 @ 0b1 @ 0b00000 @ vs1 @ 0b000 @ vd @ 0b1010111

function clause execute(MOVETYPEV(vs1, vd)) = {
  let vsew_bits  : int  = get_vtype_vsew();
  let lmul       : real = get_vtype_LMUL();
  let num_elem   : int  = get_num_elem(lmul, vsew_bits);

  assert(8 <= vsew_bits & vsew_bits <= 64);
  assert(0 <= num_elem & num_elem <= sizeof(vlen));
  let 'n = num_elem;
  let 'm = vsew_bits;

  let vm_val  : vector('n, dec, bool)     = read_vmask(num_elem, 0b1, vreg_name("v0"));
  let vs1_val : vector('n, dec, bits('m)) = read_vreg(num_elem, vsew_bits, lmul, vs1);
  let vd_val  : vector('n, dec, bits('m)) = read_vreg(num_elem, vsew_bits, lmul, vd);
  
  result      : vector('n, dec, bits('m)) = undefined;
  mask_helper : vector('n, dec, bool)     = undefined;
  (result, mask_helper) = init_masked_result(num_elem, vsew_bits, lmul, vd_val, vm_val);
  foreach (i from 0 to (num_elem - 1)){
    if mask_helper[i] == true then{
      result[i] = vs1_val[i]
    }
  };

  write_vreg(num_elem, vsew_bits, lmul, vd, result);
  writeCSR(csr_name_map("vstart"), EXTZ(0b0));

  RETIRE_SUCCESS
}

mapping clause assembly = MOVETYPEV(vs1, vd)
<-> "vmv.v.v" ^ spc() ^ vreg_name(vd) ^ sep() ^ vreg_name(vs1)


/* **************************Integer move instruction(OPIVX)*************************************** */

union clause ast = MOVETYPEX : (regidx, regidx)

mapping clause encdec = MOVETYPEX (rs1, vd)
  <-> 0b010111 @ 0b1 @ 0b00000 @ rs1 @ 0b100 @ vd @ 0b1010111

function clause execute(MOVETYPEX(rs1, vd)) = {
  let vsew_bits  : int = get_vtype_vsew();
  let lmul       : real = get_vtype_LMUL();
  let num_elem   : int = get_num_elem(lmul, vsew_bits);
  assert(8 <= vsew_bits & vsew_bits <= 64);
  assert(0 <= num_elem & num_elem <= sizeof(vlen));
  let 'n = num_elem;
  let 'm = vsew_bits;
  let rs1_val = get_scalar(rs1, vsew_bits);
  let vm_val  : vector('n, dec, bool)     = read_vmask(num_elem, 0b1, vreg_name("v0"));
  let vd_val  : vector('n, dec, bits('m)) = read_vreg(num_elem, vsew_bits, lmul, vd);
  result      : vector('n, dec, bits('m)) = undefined;
  mask_helper : vector('n, dec, bool)     = undefined;
  (result, mask_helper) = init_masked_result(num_elem, vsew_bits, lmul, vd_val, vm_val);
  foreach (i from 0 to (num_elem - 1)){
    if mask_helper[i] == true then{
      result[i] = rs1_val
    }
  };

  write_vreg(num_elem, vsew_bits, lmul, vd, result);
  writeCSR(csr_name_map("vstart"), EXTZ(0b0));

  RETIRE_SUCCESS
}

mapping clause assembly = MOVETYPEX(rs1, vd)
<-> "vmv.v.x" ^ spc() ^ vreg_name(vd) ^ sep() ^ reg_name(rs1)   


/* **************************Integer move instruction(OPIVI)*************************************** */

union clause ast = MOVETYPEI : (regidx, bits(5))

mapping clause encdec = MOVETYPEI (vd, simm)
  <-> 0b010111 @ 0b1 @ 0b00000 @ simm @ 0b011 @ vd @ 0b1010111

function clause execute(MOVETYPEI(vd, simm)) = {
  let vsew_bits  : int = get_vtype_vsew();
  let lmul       : real = get_vtype_LMUL();
  let num_elem   : int = get_num_elem(lmul, vsew_bits);

  assert(8 <= vsew_bits & vsew_bits <= 64);
  assert(0 <= num_elem & num_elem <= sizeof(vlen));
  let 'n = num_elem;
  let 'm = vsew_bits;

  let vm_val  : vector('n, dec, bool)     = read_vmask(num_elem, 0b1, vreg_name("v0"));
  let imm_val = sail_sign_extend(simm, vsew_bits);
  let vd_val  : vector('n, dec, bits('m)) = read_vreg(num_elem, vsew_bits, lmul, vd);
  result      : vector('n, dec, bits('m)) = undefined;
  mask_helper : vector('n, dec, bool)     = undefined;
  
  (result, mask_helper) = init_masked_result(num_elem, vsew_bits, lmul, vd_val, vm_val);
  foreach (i from 0 to (num_elem - 1)){
    if mask_helper[i] == true then{
      result[i] = imm_val
    }
  };

  write_vreg(num_elem, vsew_bits, lmul, vd, result);
  writeCSR(csr_name_map("vstart"), EXTZ(0b0));

  RETIRE_SUCCESS
}

mapping clause assembly = MOVETYPEI(vd, simm)
<-> "vmv.v.i" ^ spc() ^ vreg_name(vd) ^ sep() ^ hex_bits_5(simm)

