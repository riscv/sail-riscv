/* ******************************************************************************* */
/* This file implements part of the vector extension.                              */
/* Chapter 14: vector reduction instructions                                       */

/* ******************************************************************************* */

/* **************************OPIVV(VVTYPE) Reduction****************************** */

union clause ast = RIVVTYPE : (rivvfunct6, bits(1), regidx, regidx, regidx)

mapping encdec_rivvfunct6 : rivvfunct6 <-> bits(6) = {
  IVV_VWREDSUMU   <-> 0b110000,
  IVV_VWREDSUM    <-> 0b110001
}

mapping clause encdec = RIVVTYPE(funct6, vm, vs2, vs1, vd)
  <-> encdec_rivvfunct6(funct6) @ vm @ vs2 @ vs1 @ 0b000 @ vd @ 0b1010111

val process_rivv : forall 'n 'm, (8 <= 'm <= 64 & 0 <= 'n <= vlen). 
(rivvfunct6, bits(1), regidx, regidx, regidx, int('n), int('m), real) -> Retired effect {escape, rreg, undef, wreg}
function process_rivv(funct6, vm, vs2, vs1, vd, num_elem, vsew_bits, lmul) = {
  let double_vsew : int  = vsew_bits * 2;
  let double_lmul : real = lmul * 2.0;
  let 'double_vsew = double_vsew;
  let vs2_val  : vector('n, dec, bits('m)) = read_vreg(num_elem, vsew_bits, lmul, vs2);
  let vm_val   : vector('n, dec, bool)     = read_vmask(num_elem, vm, vreg_name("v0"));
  assert ( 8 <= 'double_vsew & 'double_vsew <= 64 );
  let vd_val   : vector('n, dec, bits('double_vsew)) = read_vreg(num_elem, double_vsew, double_lmul, vd); // only to generate mask_helper
  result       : vector('n, dec, bits('double_vsew))     = undefined;
  mask_helper  : vector('n, dec, bool)     = undefined;
  (result, mask_helper) = init_masked_result(num_elem, double_vsew, double_lmul, vd_val, vm_val);

  vs1_0 : bits('double_vsew) = read_single_element(double_vsew, 0, double_lmul, vs1);
  sum_elems : bits('double_vsew) = match funct6 {
    IVV_VWREDSUMU  => to_bits(double_vsew, unsigned(vs1_0)),
    IVV_VWREDSUM   => to_bits(double_vsew, signed(vs1_0))
  };
  foreach (i from 0 to (num_elem - 1)) {
    if mask_helper[i] == true then {
      sum_elems = match funct6 {
        IVV_VWREDSUMU  => to_bits(double_vsew, unsigned(vs2_val[i]) + unsigned(sum_elems)),
        IVV_VWREDSUM   => to_bits(double_vsew, signed(vs2_val[i]) + signed(sum_elems))
      };
    }
  };
  
  write_single_element(double_vsew, 0, double_lmul, vd, sum_elems);
  RETIRE_SUCCESS
}

function clause execute(RIVVTYPE(funct6, vm, vs2, vs1, vd)) = {
  let vsew_bits   : int  = get_vtype_vsew();
  let lmul        : real = get_vtype_LMUL();
  let num_elem    : int  = get_num_elem(lmul, vsew_bits);

  assert(8 <= vsew_bits & vsew_bits <= 64);
  assert(0 <= num_elem & num_elem <= sizeof(vlen));
  process_rivv(funct6, vm, vs2, vs1, vd, num_elem, vsew_bits, lmul)
}

mapping rivvtype_mnemonic : rivvfunct6 <-> string = {
  IVV_VWREDSUMU  <-> "vwredsumu.vs",
  IVV_VWREDSUM   <-> "vwredsum.vs"
}

mapping clause assembly = RIVVTYPE(funct6, vm, vs2, vs1, vd)
  <-> rivvtype_mnemonic(funct6) ^ spc() ^ vreg_name(vd) ^ sep() ^ vreg_name(vs2) ^ sep() ^ vreg_name(vs1) ^ maybe_vmask(vm)


/* **************************OPMVV(MVVtype) Reduction********************************* */

 union clause ast = RMVVTYPE : (rmvvfunct6, bits(1), regidx, regidx, regidx)

mapping encdec_rmvvfunct6 : rmvvfunct6 <-> bits(6) = {
  MVV_VREDSUM     <-> 0b000000,
  MVV_VREDAND     <-> 0b000001,
  MVV_VREDOR      <-> 0b000010,
  MVV_VREDXOR     <-> 0b000011,
  MVV_VREDMINU    <-> 0b000100,
  MVV_VREDMIN     <-> 0b000101,
  MVV_VREDMAXU    <-> 0b000110,
  MVV_VREDMAX     <-> 0b000111
}

mapping clause encdec = RMVVTYPE(funct6, vm, vs2, vs1, vd)
  <-> encdec_rmvvfunct6(funct6) @ vm @ vs2 @ vs1 @ 0b010 @ vd @ 0b1010111

val process_rmvv : forall 'n 'm, (8 <= 'm <= 64 & 0 <= 'n <= vlen). 
(rmvvfunct6, bits(1), regidx, regidx, regidx, int('n), int('m), real) -> Retired effect {escape, rreg, undef, wreg}
function process_rmvv(funct6, vm, vs2, vs1, vd, num_elem, vsew_bits, lmul) = {
  let vs2_val  : vector('n, dec, bits('m)) = read_vreg(num_elem, vsew_bits, lmul, vs2);
  let vm_val   : vector('n, dec, bool)     = read_vmask(num_elem, vm, vreg_name("v0"));
  let vd_val   : vector('n, dec, bits('m)) = read_vreg(num_elem, vsew_bits, lmul, vd); // only to generate mask_helper
  result       : vector('n, dec, bits('m))     = undefined;
  mask_helper  : vector('n, dec, bool)     = undefined;
  (result, mask_helper) = init_masked_result(num_elem, vsew_bits, lmul, vd_val, vm_val);

  ans : bits('m) = read_single_element(vsew_bits, 0, lmul, vs1);
  foreach (i from 0 to (num_elem - 1)) {
    if mask_helper[i] == true then {
      ans = match funct6 {
        MVV_VREDSUM   => ans + vs2_val[i],
        MVV_VREDAND   => ans & vs2_val[i],
        MVV_VREDOR    => ans | vs2_val[i],
        MVV_VREDXOR   => ans ^ vs2_val[i],
        MVV_VREDMIN   => to_bits(vsew_bits, min(signed(vs2_val[i]), signed(ans))),
        MVV_VREDMINU  => to_bits(vsew_bits, min(unsigned(vs2_val[i]), unsigned(ans))),
        MVV_VREDMAX   => to_bits(vsew_bits, max(signed(vs2_val[i]), signed(ans))),
        MVV_VREDMAXU  => to_bits(vsew_bits, max(unsigned(vs2_val[i]), unsigned(ans)))
      }
    }
  };
  write_single_element(vsew_bits, 0, lmul, vd, ans);
  RETIRE_SUCCESS
}

function clause execute(RMVVTYPE(funct6, vm, vs2, vs1, vd)) = {
  let vsew_bits  : int = get_vtype_vsew();
  let lmul       : real = get_vtype_LMUL();
  let num_elem   : int = get_num_elem(lmul, vsew_bits);

  assert(8 <= vsew_bits & vsew_bits <= 64);
  assert(0 <= num_elem & num_elem <= sizeof(vlen));
  process_rmvv(funct6, vm, vs2, vs1, vd, num_elem, vsew_bits, lmul)
}

mapping rmvvtype_mnemonic : rmvvfunct6 <-> string = {
  MVV_VREDSUM   <-> "vredsum.vs",
  MVV_VREDAND   <-> "vredand.vs",
  MVV_VREDOR    <-> "vredor.vs",
  MVV_VREDXOR   <-> "vredxor.vs",
  MVV_VREDMINU  <-> "vredminu.vs",
  MVV_VREDMIN   <-> "vredmin.vs",
  MVV_VREDMAXU  <-> "vredmaxu.vs",
  MVV_VREDMAX   <-> "vredmax.vs"
}

mapping clause assembly = RMVVTYPE(funct6, vm, vs2, vs1, vd)
  <-> rmvvtype_mnemonic(funct6) ^ spc() ^ vreg_name(vd) ^ sep() ^ vreg_name(vs2) ^ sep() ^ vreg_name(vs1) ^ maybe_vmask(vm)  


/* ****************************OPFVV(FVVtype) Reduction***************************** */

union clause ast = RFVVTYPE : (rfvvfunct6, bits(1), regidx, regidx, regidx)

mapping encdec_rfvvfunct6 : rfvvfunct6 <-> bits(6) = {
  FVV_VFREDOSUM   <-> 0b000011,
  FVV_VFREDUSUM   <-> 0b000001,
  FVV_VFREDMAX    <-> 0b000111,
  FVV_VFREDMIN    <-> 0b000101,
  FVV_VFWREDOSUM  <-> 0b110011,
  FVV_VFWREDUSUM  <-> 0b110001
}

mapping clause encdec = RFVVTYPE(funct6, vm, vs2, vs1, vd)
  <-> encdec_rfvvfunct6(funct6) @ vm @ vs2 @ vs1 @ 0b001 @ vd @ 0b1010111

val process_rfvv_single: forall 'n 'm, (8 <= 'm <= 64 & 0 <= 'n <= vlen). 
(rfvvfunct6, bits(1), regidx, regidx, regidx, int('n), int('m), real) -> Retired effect {escape, rreg, undef, wreg}
function process_rfvv_single(funct6, vm, vs2, vs1, vd, num_elem, vsew_bits, lmul) = {
  let rm_3b   = fcsr.FRM();
  if rm_3b == 0b101 | rm_3b == 0b110 | rm_3b == 0b111 then {
    handle_illegal();
    RETIRE_FAIL
  } else{
    let vs2_val  : vector('n, dec, bits('m)) = read_vreg(num_elem, vsew_bits, lmul, vs2);
    let vm_val   : vector('n, dec, bool)     = read_vmask(num_elem, vm, vreg_name("v0"));
    let vd_val   : vector('n, dec, bits('m)) = read_vreg(num_elem, vsew_bits, lmul, vd); // only to generate mask_helper
    result       : vector('n, dec, bits('m))     = undefined;
    mask_helper  : vector('n, dec, bool)     = undefined;
    (result, mask_helper) = init_masked_result(num_elem, vsew_bits, lmul, vd_val, vm_val);

    vs1_0 : bits('m) = read_single_element(vsew_bits, 0, lmul, vs1);
    assert(vsew_bits == 16 | vsew_bits == 32 | vsew_bits == 64 | vsew_bits == 128);
    foreach (i from 0 to (num_elem - 1)) {
      if mask_helper[i] == true then {
        vs1_0 = match funct6 {
          FVV_VFREDOSUM   => fp_add(rm_3b, vs1_0, vs2_val[i]),
          FVV_VFREDUSUM   => fp_add(rm_3b, vs1_0, vs2_val[i]),
          FVV_VFREDMAX    => fp_max(vs1_0, vs2_val[i]),
          FVV_VFREDMIN    => fp_min(vs1_0, vs2_val[i])
        };
      }
    };

    write_single_element(vsew_bits, 0, lmul, vd, vs1_0);
    RETIRE_SUCCESS
  }
}


val process_rfvv_widen: forall 'n 'm, (8 <= 'm <= 64 & 0 <= 'n <= vlen). 
(rfvvfunct6, bits(1), regidx, regidx, regidx, int('n), int('m), real) -> Retired effect {escape, rreg, undef, wreg}
function process_rfvv_widen(funct6, vm, vs2, vs1, vd, num_elem, vsew_bits, lmul) = {
  let double_vsew : int  = vsew_bits * 2;
  let double_lmul : real = lmul * 2.0;
  let 'double_vsew = double_vsew;
  let vs2_val  : vector('n, dec, bits('m)) = read_vreg(num_elem, vsew_bits, lmul, vs2);
  let vm_val   : vector('n, dec, bool)     = read_vmask(num_elem, vm, vreg_name("v0"));
  assert ( vsew_bits == 16 | vsew_bits == 32 | vsew_bits == 64 );
  // assert ( 'double_vsew == 16 | 'double_vsew == 32 |'double_vsew == 64 |'double_vsew == 128 );
  assert ( 'double_vsew == 16 | 'double_vsew == 32 |'double_vsew == 64 );
  let vd_val   : vector('n, dec, bits('double_vsew)) = read_vreg(num_elem, double_vsew, double_lmul, vd); // only to generate mask_helper
  result       : vector('n, dec, bits('double_vsew)) = undefined;
  mask_helper  : vector('n, dec, bool)               = undefined;
  (result, mask_helper) = init_masked_result(num_elem, double_vsew, double_lmul, vd_val, vm_val);

  vs1_0 : bits('double_vsew) = read_single_element(double_vsew, 0, double_lmul, vs1);
  foreach (i from 0 to (num_elem - 1)) {
    if mask_helper[i] == true then {
      result_real : real = undefined;
      /* Currently Ordered/Unordered sum do the same operations */
      (fptype, sign, result_real) = fpreal_add(fp_to_real(vs2_val[i]), fp_to_real(vs1_0));
      vs1_0 = real_to_fp(result_real)
    }
  };
  
  write_single_element(double_vsew, 0, double_lmul, vd, vs1_0);
  RETIRE_SUCCESS
}

function clause execute(RFVVTYPE(funct6, vm, vs2, vs1, vd)) = {
  let vsew_bits   : int  = get_vtype_vsew();
  let lmul        : real = get_vtype_LMUL();
  let num_elem    : int  = get_num_elem(lmul, vsew_bits);

  assert(8 <= vsew_bits & vsew_bits <= 64);
  assert(0 <= num_elem & num_elem <= sizeof(vlen));
  if funct6 == FVV_VFWREDOSUM | funct6 == FVV_VFWREDUSUM then 
    process_rfvv_widen(funct6, vm, vs2, vs1, vd, num_elem, vsew_bits, lmul)
  else
    process_rfvv_single(funct6, vm, vs2, vs1, vd, num_elem, vsew_bits, lmul)
}

mapping rfvvtype_mnemonic : rfvvfunct6 <-> string = {
  FVV_VFREDOSUM   <-> "vfredosum.vs",
  FVV_VFREDUSUM   <-> "vfredusum.vs",
  FVV_VFREDMAX    <-> "vfredmax.vs",
  FVV_VFREDMIN    <-> "vfredmin.vs",
  FVV_VFWREDOSUM  <-> "vfwredosum.vs",
  FVV_VFWREDUSUM  <-> "vfwredusum.vs"
}

mapping clause assembly = RFVVTYPE(funct6, vm, vs2, vs1, vd)
  <-> rfvvtype_mnemonic(funct6) ^ spc() ^ vreg_name(vd) ^ sep() ^ vreg_name(vs2) ^ sep() ^ vreg_name(vs1) ^ maybe_vmask(vm)

