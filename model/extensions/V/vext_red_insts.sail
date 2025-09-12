/*=======================================================================================*/
/*  This Sail RISC-V architecture model, comprising all files and                        */
/*  directories except where otherwise noted is subject the BSD                          */
/*  two-clause license in the LICENSE file.                                              */
/*                                                                                       */
/*  SPDX-License-Identifier: BSD-2-Clause                                                */
/*=======================================================================================*/

/* ******************************************************************************* */
/* This file implements part of the vector extension.                              */
/* Chapter 14: Vector Reduction Instructions                                       */
/* ******************************************************************************* */

/* ********************* OPIVV (Widening Integer Reduction) ********************** */
union clause instruction = RIVVTYPE : (rivvfunct6, bits(1), vregidx, vregidx, vregidx)

mapping encdec_rivvfunct6 : rivvfunct6 <-> bits(6) = {
  IVV_VWREDSUMU   <-> 0b110000,
  IVV_VWREDSUM    <-> 0b110001
}

mapping clause encdec = RIVVTYPE(funct6, vm, vs2, vs1, vd)
  <-> encdec_rivvfunct6(funct6) @ vm @ encdec_vreg(vs2) @ encdec_vreg(vs1) @ 0b000 @ encdec_vreg(vd) @ 0b1010111
  when currentlyEnabled(Ext_V)

function clause execute(RIVVTYPE(funct6, vm, vs2, vs1, vd)) = {
  let SEW      = get_sew();
  let LMUL_pow = get_lmul_pow();
  let SEW_widen = SEW * 2;

  if illegal_widening_reduction(SEW_widen) then return Illegal_Instruction();

  assert(SEW_widen <= 64);

  let num_elem_vs = get_num_elem(LMUL_pow, SEW);
  let num_elem_vd = get_num_elem(0, SEW_widen); /* vd regardless of LMUL setting */

  if unsigned(vl) == 0 then return RETIRE_SUCCESS; /* if vl=0, no operation is performed */

  let 'n = num_elem_vs;
  let 'd = num_elem_vd;
  let 'm = SEW;
  let 'o = SEW_widen;

  let vm_val  : bits('n)     = read_vmask(num_elem_vs, vm, zvreg);
  let vd_val  : vector('d, bits('o)) = read_vreg(num_elem_vd, SEW_widen, 0, vd);
  let vs2_val : vector('n, bits('m)) = read_vreg(num_elem_vs, SEW, LMUL_pow, vs2);
  let mask    : bits('n)     = match init_masked_source(num_elem_vs, LMUL_pow, vm_val) {
    Ok(v)   => v,
    Err(()) => return Illegal_Instruction()
  };

  var sum : bits('o) = read_single_element(SEW_widen, 0, vs1); /* vs1 regardless of LMUL setting */
  foreach (i from 0 to (num_elem_vs - 1)) {
    if mask[i] == bitone then {
      let elem : bits('o) = match funct6 {
        IVV_VWREDSUMU  => to_bits_unsafe(SEW_widen, unsigned(vs2_val[i])),
        IVV_VWREDSUM   => to_bits_unsafe(SEW_widen, signed(vs2_val[i]))
      };
      sum = sum + elem
    }
  };

  write_single_element(SEW_widen, 0, vd, sum);
  /* other elements in vd are treated as tail elements, currently remain unchanged */
  /* TODO: configuration support for agnostic behavior */
  set_vstart(zeros());
  RETIRE_SUCCESS
}

mapping rivvtype_mnemonic : rivvfunct6 <-> string = {
  IVV_VWREDSUMU  <-> "vwredsumu.vs",
  IVV_VWREDSUM   <-> "vwredsum.vs"
}

mapping clause assembly = RIVVTYPE(funct6, vm, vs2, vs1, vd)
  <-> rivvtype_mnemonic(funct6) ^ spc() ^ vreg_name(vd) ^ sep() ^ vreg_name(vs2) ^ sep() ^ vreg_name(vs1) ^ maybe_vmask(vm)

/* ******************* OPMVV (Single-Width Integer Reduction) ******************** */
union clause instruction = RMVVTYPE : (rmvvfunct6, bits(1), vregidx, vregidx, vregidx)

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
  <-> encdec_rmvvfunct6(funct6) @ vm @ encdec_vreg(vs2) @ encdec_vreg(vs1) @ 0b010 @ encdec_vreg(vd) @ 0b1010111
  when currentlyEnabled(Ext_V)

function clause execute(RMVVTYPE(funct6, vm, vs2, vs1, vd)) = {
  let SEW      = get_sew();
  let LMUL_pow = get_lmul_pow();
  let num_elem_vs = get_num_elem(LMUL_pow, SEW);
  let num_elem_vd = get_num_elem(0, SEW); /* vd regardless of LMUL setting */

  if illegal_reduction() then return Illegal_Instruction();

  if unsigned(vl) == 0 then return RETIRE_SUCCESS; /* if vl=0, no operation is performed */

  let 'n = num_elem_vs;
  let 'd = num_elem_vd;
  let 'm = SEW;

  let vm_val  : bits('n)     = read_vmask(num_elem_vs, vm, zvreg);
  let vd_val  : vector('d, bits('m)) = read_vreg(num_elem_vd, SEW, 0, vd);
  let vs2_val : vector('n, bits('m)) = read_vreg(num_elem_vs, SEW, LMUL_pow, vs2);
  let mask    : bits('n)     = match init_masked_source(num_elem_vs, LMUL_pow, vm_val) {
    Ok(v)   => v,
    Err(()) => return Illegal_Instruction()
  };

  var sum : bits('m) = read_single_element(SEW, 0, vs1); /* vs1 regardless of LMUL setting */
  foreach (i from 0 to (num_elem_vs - 1)) {
    if mask[i] == bitone then {
      sum = match funct6 {
        MVV_VREDSUM   => sum + vs2_val[i],
        MVV_VREDAND   => sum & vs2_val[i],
        MVV_VREDOR    => sum | vs2_val[i],
        MVV_VREDXOR   => sum ^ vs2_val[i],
        MVV_VREDMIN   => to_bits_unsafe(SEW, min(signed(vs2_val[i]), signed(sum))),
        MVV_VREDMINU  => to_bits_unsafe(SEW, min(unsigned(vs2_val[i]), unsigned(sum))),
        MVV_VREDMAX   => to_bits_unsafe(SEW, max(signed(vs2_val[i]), signed(sum))),
        MVV_VREDMAXU  => to_bits_unsafe(SEW, max(unsigned(vs2_val[i]), unsigned(sum)))
      }
    }
  };

  write_single_element(SEW, 0, vd, sum);
  /* other elements in vd are treated as tail elements, currently remain unchanged */
  /* TODO: configuration support for agnostic behavior */
  set_vstart(zeros());
  RETIRE_SUCCESS
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
