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
  let vsew_bits : int  = get_vtype_vsew();
  let lmul      : real = get_vtype_LMUL();
  let num_elem  : int  = get_num_elem(lmul, vsew_bits);

  assert(vsew_bits == 8 | vsew_bits == 16 | vsew_bits == 32 | vsew_bits == 64);
  assert(0 <= num_elem & num_elem <= get_vlen());
  let 'n = num_elem;
  let 'm = vsew_bits;

  let vm_val  : vector('n, dec, bool)     = read_vmask(num_elem, vm, vreg_name("v0"));
  let vs1_val : vector('n, dec, bits('m)) = read_vreg(num_elem, vsew_bits, lmul, vs1);
  let vs2_val : vector('n, dec, bits('m)) = read_vreg(num_elem, vsew_bits, lmul, vs2);
  let vd_val  : vector('n, dec, bits('m)) = read_vreg(num_elem, vsew_bits, lmul, vd);
  result      : vector('n, dec, bits('m)) = undefined;
  mask_helper : vector('n, dec, bool)     = undefined;

  (result, mask_helper) = init_masked_result(num_elem, vsew_bits, lmul, vd_val, vm_val);

  foreach (i from 0 to (num_elem - 1)) {
    if mask_helper[i] == true then {
      result[i] = match funct6 {
        VV_VADD          => vs2_val[i] + vs1_val[i],
        VV_VSUB          => vs2_val[i] - vs1_val[i],
        VV_VAND          => vs2_val[i] & vs1_val[i],
        VV_VOR           => vs2_val[i] | vs1_val[i],
        VV_VXOR          => vs2_val[i] ^ vs1_val[i],
        VV_VSADDU        => unsigned_saturation('m, EXTZ('m + 1, vs2_val[i]) + EXTZ('m + 1, vs1_val[i]) ),
        VV_VSADD         => signed_saturation('m, EXTS('m + 1, vs2_val[i]) + EXTS('m + 1, vs1_val[i]) ),
        VV_VSSUBU        => {
                              if unsigned(vs2_val[i]) < unsigned(vs1_val[i]) then zeros()
                              else unsigned_saturation('m, EXTZ('m + 1, vs2_val[i]) - EXTZ('m + 1, vs1_val[i]) )
                            },
        VV_VSSUB         => signed_saturation('m, EXTS('m + 1, vs2_val[i]) - EXTS('m + 1, vs1_val[i]) ),
        VV_VSMUL         => {
                              result_mul = to_bits('m * 2, signed(vs2_val[i]) * signed(vs1_val[i]));
                              rounding_incr = get_fixed_rounding_incr(result_mul, 'm - 1);
                              result_wide = (result_mul >> ('m - 1)) + EXTZ('m * 2, rounding_incr);
                              signed_saturation('m, result_wide['m..0])
                            },
        VV_VSLL          => {
                              let shift_amount = get_shift_amount(vs1_val[i], vsew_bits);
                              assert(shift_amount >= 0);
                              vs2_val[i] << shift_amount
                            },
        VV_VSRL          => {
                              let shift_amount = get_shift_amount(vs1_val[i], vsew_bits);
                              assert(shift_amount >= 0);
                              vs2_val[i] >> shift_amount
                            },
        VV_VSRA          => {
                              let shift_amount = get_shift_amount(vs1_val[i], vsew_bits);
                              assert(shift_amount >= 0);
                              let v_double : bits('m * 2) = EXTS(vs2_val[i]);
                              slice(v_double >> shift_amount, 0, vsew_bits)
                            },
        VV_VSSRL         => {
                              let shift_amount = get_shift_amount(vs1_val[i], vsew_bits);
                              assert(shift_amount >= 0);
                              let rounding_incr = get_fixed_rounding_incr(vs2_val[i], shift_amount);
                              (vs2_val[i] >> shift_amount) + EXTZ('m, rounding_incr)
                            },
        VV_VSSRA         => {
                              let shift_amount = get_shift_amount(vs1_val[i], vsew_bits);
                              assert(shift_amount >= 0);
                              let rounding_incr = get_fixed_rounding_incr(vs2_val[i], shift_amount);
                              let v_double : bits('m * 2) = EXTS(vs2_val[i]);
                              slice(v_double >> shift_amount, 0, vsew_bits) + EXTZ('m, rounding_incr)
                            },
        VV_VMINU         => to_bits(vsew_bits, min(unsigned(vs2_val[i]), unsigned(vs1_val[i]))),
        VV_VMIN          => to_bits(vsew_bits, min(signed(vs2_val[i]), signed(vs1_val[i]))),
        VV_VMAXU         => to_bits(vsew_bits, max(unsigned(vs2_val[i]), unsigned(vs1_val[i]))),
        VV_VMAX          => to_bits(vsew_bits, max(signed(vs2_val[i]), signed(vs1_val[i]))),
        VV_VRGATHER      => {
                              assert(vs1 != vd & vs2 != vd);
                              let idx = unsigned(vs1_val[i]);
                              vlmax = floor(lmul * (to_real(get_vlen()) / to_real(vsew_bits)));
                              if idx < vlmax then {
                                assert(idx < 'n); 
                                vs2_val[idx]
                              } else zeros() 
                            },
        VV_VRGATHEREI16  => {
                              assert(vs1 != vd & vs2 != vd);
                              /* vrgatherei16.vv uses SEW/LMUL for the data in vs2 but EEW=16 and EMUL = (16/SEW)*LMUL for the indices in vs1 */
                              let vs1_new : vector('n, dec, bits(16)) = read_vreg(num_elem, 16, (lmul * 16.0 / to_real(vsew_bits)), vs1);
                              let idx = unsigned(vs1_new[i]);
                              vlmax = floor(lmul * (to_real(get_vlen()) / to_real(vsew_bits)));
                              if idx < vlmax then {
                                assert(idx < 'n); 
                                vs2_val[idx]
                              } else zeros()                   
                            }
      }
    }
  };

  write_vreg(num_elem, vsew_bits, lmul, vd, result);
  vstart = EXTZ(0b0);
  RETIRE_SUCCESS
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
  let vsew_bits : int  = get_vtype_vsew();
  let lmul      : real = get_vtype_LMUL();
  let num_elem  : int  = get_num_elem(lmul, vsew_bits);

  assert(8 <= vsew_bits & vsew_bits <= 64);
  assert(0 <= num_elem & num_elem <= get_vlen());
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
        VX_VSLIDEUP    => {
                            assert(vs2 != vd);
                            assert(i - rs1_val < 'n);
                            if i >= rs1_val then vs2_val[i - rs1_val] else vd_val[i]
                          },
        VX_VSLIDEDOWN  => {
                            assert(i + rs1_val >= 0);
                            vlmax = floor(lmul * to_real(get_vlen()) / to_real(vsew_bits));
                            if i + rs1_val < vlmax then {
                              assert(i + rs1_val < 'n); 
                              vs2_val[i + rs1_val]
                            } else zeros()
                          },
        VX_VRGATHER    => {
                            assert(vs2 != vd);
                            assert(rs1_val >= 0);
                            vlmax = floor(lmul * to_real(get_vlen()) / to_real(vsew_bits));
                            if rs1_val < vlmax then {
                              assert(rs1_val < 'n); 
                              vs2_val[rs1_val]
                            } else zeros() 
                          }
      }
    }
  };

  write_vreg(num_elem, vsew_bits, lmul, vd, result);
  vstart = EXTZ(0b0);
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
  let vsew_bits : int  = get_vtype_vsew();
  let lmul      : real = get_vtype_LMUL();
  let num_elem  : int  = get_num_elem(lmul, vsew_bits);

  assert(8 <= vsew_bits & vsew_bits <= 64);
  assert(0 <= num_elem & num_elem <= get_vlen());
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
        VI_VSLIDEUP    => {
                            assert(vs2 != vd);
                            assert(i - imm_val < 'n);
                            if i >= imm_val then vs2_val[i - imm_val] else vd_val[i]
                          },
        VI_VSLIDEDOWN  => {
                            assert(i + imm_val >= 0);
                            vlmax = floor(lmul * to_real(get_vlen()) / to_real(vsew_bits));
                            if i + imm_val < vlmax then {
                              assert(i + imm_val < 'n); 
                              vs2_val[i + imm_val]
                            } else zeros()
                          },
        VI_VRGATHER    => {
                            assert(vs2 != vd);
                            assert(imm_val >= 0);
                            vlmax = floor(lmul * to_real(get_vlen()) / to_real(vsew_bits));
                            if imm_val < vlmax then {
                              assert(imm_val < 'n); 
                              vs2_val[imm_val]
                            } else zeros() 
                          }
      }
    }
  };

  write_vreg(num_elem, vsew_bits, lmul, vd, result);
  vstart = EXTZ(0b0);
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
  let vsew_bits : int = get_vtype_vsew();
  let imm_val   : int = unsigned(EXTZ(sizeof(xlen), simm));
  let lmul      : int = imm_val + 1;

  assert(8 <= vsew_bits & vsew_bits <= 64);
  assert(lmul == 1 | lmul == 2 | lmul == 4 | lmul == 8);
  let num_elem  : int = get_num_elem(to_real(lmul), vsew_bits);
  let 'n = num_elem;
  let 'm = vsew_bits;

  let vs2_val : vector('n, dec, bits('m)) = read_vreg(num_elem, vsew_bits, to_real(lmul), vs2);
  write_vreg(num_elem, vsew_bits, to_real(lmul), vd, vs2_val);
  vstart = EXTZ(0b0);

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


/* *******************************OPMVV(VWXUNARY0)******************************** */

union clause ast = VMVXS : (regidx, regidx)

mapping clause encdec = VMVXS(vs2, rd)
  <-> 0b010000 @ 0b1 @ vs2 @ 0b00000 @ 0b010 @ rd @ 0b1010111

function clause execute(VMVXS(vs2, rd)) = {
  let vsew_bits : int = get_vtype_vsew();
  let num_elem  : int = get_num_elem(1.0, vsew_bits);

  assert(8 <= vsew_bits & vsew_bits <= 64);
  assert(0 < num_elem & num_elem <= get_vlen());
  let 'n = num_elem;
  let 'm = vsew_bits;

  let vs2_val : vector('n, dec, bits('m)) = read_vreg(num_elem, vsew_bits, 1.0, vs2);
  if sizeof(xlen) < vsew_bits then X(rd) = slice(vs2_val[0], 0, sizeof(xlen))
  else if sizeof(xlen) > vsew_bits then X(rd) = sail_sign_extend(vs2_val[0], sizeof(xlen))
  else X(rd) = vs2_val[0];
  vstart = EXTZ(0b0);

  RETIRE_SUCCESS
}

mapping clause assembly = VMVXS(vs2, rd)
  <-> "vmv.x.s" ^ spc() ^ reg_name(rd) ^ sep() ^ vreg_name(vs2)


/* *******************************OPMVX(VRXUNARY0)******************************** */

union clause ast = VMVSX : (regidx, regidx)

mapping clause encdec = VMVSX(rs1, vd)
  <-> 0b010000 @ 0b1 @ 0b00000 @ rs1 @ 0b110 @ vd @ 0b1010111

function clause execute(VMVSX(rs1, vd)) = {
  let vsew_bits : int  = get_vtype_vsew();
  let num_elem  : int  = get_num_elem(1.0, vsew_bits);

  assert(8 <= vsew_bits & vsew_bits <= 64);
  assert(0 < num_elem & num_elem <= get_vlen());
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
    foreach (i from 1 to (num_elem - 1)) result[i] = vd_val[i]
  };

  write_vreg(num_elem, vsew_bits, 1.0, vd, result);
  vstart = EXTZ(0b0);

  RETIRE_SUCCESS
}

mapping clause assembly = VMVSX(rs1, vd)
  <-> "vmv.s.x" ^ spc() ^ vreg_name(vd) ^ sep() ^ reg_name(rs1)


/* **************************Integer move instruction(OPIVV)*************************************** */

union clause ast = MOVETYPEV : (regidx, regidx)

mapping clause encdec = MOVETYPEV (vs1, vd)
  <-> 0b010111 @ 0b1 @ 0b00000 @ vs1 @ 0b000 @ vd @ 0b1010111

function clause execute(MOVETYPEV(vs1, vd)) = {
  let vsew_bits : int  = get_vtype_vsew();
  let lmul      : real = get_vtype_LMUL();
  let num_elem  : int  = get_num_elem(lmul, vsew_bits);

  assert(8 <= vsew_bits & vsew_bits <= 64);
  assert(0 <= num_elem & num_elem <= get_vlen());
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
  vstart = EXTZ(0b0);

  RETIRE_SUCCESS
}

mapping clause assembly = MOVETYPEV(vs1, vd)
<-> "vmv.v.v" ^ spc() ^ vreg_name(vd) ^ sep() ^ vreg_name(vs1)


/* **************************Integer move instruction(OPIVX)*************************************** */

union clause ast = MOVETYPEX : (regidx, regidx)

mapping clause encdec = MOVETYPEX (rs1, vd)
  <-> 0b010111 @ 0b1 @ 0b00000 @ rs1 @ 0b100 @ vd @ 0b1010111

function clause execute(MOVETYPEX(rs1, vd)) = {
  let vsew_bits : int  = get_vtype_vsew();
  let lmul      : real = get_vtype_LMUL();
  let num_elem  : int  = get_num_elem(lmul, vsew_bits);

  assert(8 <= vsew_bits & vsew_bits <= 64);
  assert(0 <= num_elem & num_elem <= get_vlen());
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
  vstart = EXTZ(0b0);

  RETIRE_SUCCESS
}

mapping clause assembly = MOVETYPEX(rs1, vd)
<-> "vmv.v.x" ^ spc() ^ vreg_name(vd) ^ sep() ^ reg_name(rs1)   


/* **************************Integer move instruction(OPIVI)*************************************** */

union clause ast = MOVETYPEI : (regidx, bits(5))

mapping clause encdec = MOVETYPEI (vd, simm)
  <-> 0b010111 @ 0b1 @ 0b00000 @ simm @ 0b011 @ vd @ 0b1010111

function clause execute(MOVETYPEI(vd, simm)) = {
  let vsew_bits : int = get_vtype_vsew();
  let lmul      : real = get_vtype_LMUL();
  let num_elem  : int = get_num_elem(lmul, vsew_bits);

  assert(8 <= vsew_bits & vsew_bits <= 64);
  assert(0 <= num_elem & num_elem <= get_vlen());
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
  vstart = EXTZ(0b0);

  RETIRE_SUCCESS
}

mapping clause assembly = MOVETYPEI(vd, simm)
<-> "vmv.v.i" ^ spc() ^ vreg_name(vd) ^ sep() ^ hex_bits_5(simm)

