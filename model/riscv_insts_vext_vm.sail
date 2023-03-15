/* ******************************************************************************* */
/* This file implements part of the vector extension.                              */
/* Mask instructions from Chap 11 (integer arithmetic) and 13 (floating-point)     */
/* ******************************************************************************* */

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

mapping clause encdec = VVCMPTYPE(funct6, vm, vs2, vs1, vd) if haveRVV()
  <-> encdec_vvcmpfunct6(funct6) @ vm @ vs2 @ vs1 @ 0b000 @ vd @ 0b1010111 if haveRVV()

function clause execute(VVCMPTYPE(funct6, vm, vs2, vs1, vd)) = {
  let SEW      = get_sew();
  let LMUL_pow = get_lmul_pow();
  let num_elem = get_num_elem(LMUL_pow, SEW);

  let 'n = num_elem;
  let 'm = SEW;

  let vm_val   : vector('n, dec, bool)     = read_vmask(num_elem, vm, vreg_name("v0"));
  let vs1_val  : vector('n, dec, bits('m)) = read_vreg(num_elem, SEW, LMUL_pow, vs1);
  let vs2_val  : vector('n, dec, bits('m)) = read_vreg(num_elem, SEW, LMUL_pow, vs2);
  let vd_val   : vector('n, dec, bool)     = read_vmask(num_elem, 0b0, vd);
  result       : vector('n, dec, bool)     = undefined;
  mask         : vector('n, dec, bool)     = undefined;

  (result, mask) = init_masked_result_cmp(num_elem, SEW, LMUL_pow, vd_val, vm_val);

  foreach (i from 0 to (num_elem - 1)) {
    if mask[i] then {
      let res : bool = match funct6 {
        VVCMP_VMSEQ    => vs2_val[i] == vs1_val[i],
        VVCMP_VMSNE    => vs2_val[i] != vs1_val[i],
        VVCMP_VMSLTU   => unsigned(vs2_val[i]) < unsigned(vs1_val[i]),
        VVCMP_VMSLT    => signed(vs2_val[i]) < signed(vs1_val[i]),
        VVCMP_VMSLEU   => unsigned(vs2_val[i]) <= unsigned(vs1_val[i]),
        VVCMP_VMSLE    => signed(vs2_val[i]) <= signed(vs1_val[i])
      };
      result[i] = res
    }
  };

  write_vmask(num_elem, vd, result);
  vstart = EXTZ(0b0);
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

mapping clause encdec = VXCMPTYPE(funct6, vm, vs2, rs1, vd) if haveRVV()
  <-> encdec_vxcmpfunct6(funct6) @ vm @ vs2 @ rs1 @ 0b100 @ vd @ 0b1010111 if haveRVV()

function clause execute(VXCMPTYPE(funct6, vm, vs2, rs1, vd)) = {
  let SEW      = get_sew();
  let LMUL_pow = get_lmul_pow();
  let num_elem = get_num_elem(LMUL_pow, SEW);

  let 'n = num_elem;
  let 'm = SEW;

  let vm_val   : vector('n, dec, bool)     = read_vmask(num_elem, vm, vreg_name("v0"));
  let rs1_val  : bits('m)                  = get_scalar(rs1, SEW);
  let vs2_val  : vector('n, dec, bits('m)) = read_vreg(num_elem, SEW, LMUL_pow, vs2);
  let vd_val   : vector('n, dec, bool)     = read_vmask(num_elem, 0b0, vd);
  result       : vector('n, dec, bool)     = undefined;
  mask         : vector('n, dec, bool)     = undefined;

  (result, mask) = init_masked_result_cmp(num_elem, SEW, LMUL_pow, vd_val, vm_val);

  foreach (i from 0 to (num_elem - 1)) {
    if mask[i] then {
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
      result[i] = res
    }
  };

  write_vmask(num_elem, vd, result);
  vstart = EXTZ(0b0);
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

mapping clause encdec = VICMPTYPE(funct6, vm, vs2, simm, vd) if haveRVV()
  <-> encdec_vicmpfunct6(funct6) @ vm @ vs2 @ simm @ 0b011 @ vd @ 0b1010111 if haveRVV()

function clause execute(VICMPTYPE(funct6, vm, vs2, simm, vd)) = {
  let SEW      = get_sew();
  let LMUL_pow = get_lmul_pow();
  let num_elem = get_num_elem(LMUL_pow, SEW);

  let 'n = num_elem;
  let 'm = SEW;

  let vm_val   : vector('n, dec, bool)     = read_vmask(num_elem, vm, vreg_name("v0"));
  let imm_val  : bits('m)                  = EXTS(simm);
  let vs2_val  : vector('n, dec, bits('m)) = read_vreg(num_elem, SEW, LMUL_pow, vs2);
  let vd_val   : vector('n, dec, bool)     = read_vmask(num_elem, 0b0, vd);
  result       : vector('n, dec, bool)     = undefined;
  mask         : vector('n, dec, bool)     = undefined;

  (result, mask) = init_masked_result_cmp(num_elem, SEW, LMUL_pow, vd_val, vm_val);

  foreach (i from 0 to (num_elem - 1)) {
    if mask[i] then {
      let res : bool = match funct6 {
        VICMP_VMSEQ    => vs2_val[i] == imm_val,
        VICMP_VMSNE    => vs2_val[i] != imm_val,
        VICMP_VMSLEU   => unsigned(vs2_val[i]) <= unsigned(imm_val),
        VICMP_VMSLE    => signed(vs2_val[i]) <= signed(imm_val),
        VICMP_VMSGTU   => unsigned(vs2_val[i]) > unsigned(imm_val),
        VICMP_VMSGT    => signed(vs2_val[i]) > signed(imm_val)
      };
      result[i] = res
    }
  };

  write_vmask(num_elem, vd, result);
  vstart = EXTZ(0b0);
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
