// =======================================================================================
// This Sail RISC-V architecture model, comprising all files and
// directories except where otherwise noted is subject the BSD
// two-clause license in the LICENSE file.
//
// SPDX-License-Identifier: BSD-2-Clause
// =======================================================================================

// Zvqwdota8i: Quad-widening 8-bit integer dot-product (unratified, v0.2).
// Two instructions, both in major opcode 0x77 (OP-VE) with funct3=000:
//   vqwdotau.vv  vd, vs2, vs1, vm   funct6=0x26   vs2 unsigned
//   vqwdotas.vv  vd, vs2, vs1, vm   funct6=0x27   vs2 signed
// Computes  vd[0] += sum_{i=vstart..vl-1} (mask[i] ? vs2[i] * vs1[i] : 0)
// modulo 2^32.  vs1, vs2 are EEW=8, EMUL=LMUL; vd is EEW=32, EMUL=1, accumulator in vd[0].
// Other elements of vd are tail.
//
// TODO(Zvfbfa): The spec uses vtype.altfmt to select vs1 signedness
// (0=unsigned, 1=signed).  vtype.altfmt is not yet in sail-riscv master;
// it depends on the Zvfbfa extension, currently in draft PR:
//   https://github.com/riscv/sail-riscv/pull/1581
// This implementation pins vs1 to UNSIGNED, matching the altfmt=0 case.
// When the Zvfbfa PR lands, extend the funct6 match block below to branch
// on vtype.altfmt for vs1 signedness (two more arms).

function clause currentlyEnabled(Ext_Zvqwdota8i) = hartSupports(Ext_Zvqwdota8i) & currentlyEnabled(Ext_Zve32x)

union clause instruction = ZVQWDOTA8I : (zvqwdota8i_funct6, bits(1), vregidx, vregidx, vregidx)

mapping encdec_zvqwdota8i_funct6 : zvqwdota8i_funct6 <-> bits(6) = {
  VQWDOTAU_VV <-> 0b100110,
  VQWDOTAS_VV <-> 0b100111
}

$[wavedrom "funct6 _ _ _ OPIVV _ OP-VE"]
mapping clause encdec = ZVQWDOTA8I(funct6, vm, vs2, vs1, vd)
  <-> encdec_zvqwdota8i_funct6(funct6) @ vm @ encdec_vreg(vs2) @ encdec_vreg(vs1) @ 0b000 @ encdec_vreg(vd) @ 0b1110111
  when currentlyEnabled(Ext_Zvqwdota8i) & get_sew() == 8

function clause execute ZVQWDOTA8I(funct6, vm, vs2, vs1, vd) = {
  let SEW         = get_sew();
  let LMUL_pow    = get_lmul_pow();
  let num_elem_vs = get_num_elem(LMUL_pow, SEW);
  let SEW_acc = 32;

  // vstart==0 required ("nonzero vstart is reserved") and vtype validity
  if illegal_reduction() | not(valid_reg_group(vs1, LMUL_pow)) | not(valid_reg_group(vs2, LMUL_pow))
  then return Illegal_Instruction();

  // "The destination vector register cannot overlap with the source vector register groups."
  let vd_int      = unsigned(vregidx_bits(vd));
  let vs2_int     = unsigned(vregidx_bits(vs2));
  let vs1_int     = unsigned(vregidx_bits(vs1));
  let src_group_size : int = if LMUL_pow > 0 then 2 ^ LMUL_pow else 1;
  if (vd_int >= vs2_int & vd_int < vs2_int + src_group_size) |
     (vd_int >= vs1_int & vd_int < vs1_int + src_group_size)
  then return Illegal_Instruction();

  if unsigned(vl) == 0 then return RETIRE_SUCCESS;

  // Guaranteed by the encdec when-clause; needed to give the Sail typechecker
  // a concrete bound for bits('m).
  assert(SEW == 8);

  let 'n = num_elem_vs;
  let 'm = SEW;
  let vm_val  : bits('n)             = read_vmask(num_elem_vs, vm, zvreg);
  let vs1_val : vector('n, bits('m)) = read_vreg(num_elem_vs, SEW, LMUL_pow, vs1);
  let vs2_val : vector('n, bits('m)) = read_vreg(num_elem_vs, SEW, LMUL_pow, vs2);

  let mask : bits('n) = match init_masked_source(num_elem_vs, LMUL_pow, vm_val) {
    Ok(v)   => v,
    Err(()) => return Illegal_Instruction()
  };

  // vd[0] is the running 32-bit accumulator; sum modulo 2^32.
  var sum : bits(32) = read_single_element(SEW_acc, 0, vd);

  foreach (i from 0 to (num_elem_vs - 1)) {
    if mask[i] == 0b1 then {
      // TODO(Zvfbfa, https://github.com/riscv/sail-riscv/pull/1581):
      // vs1 is pinned to unsigned (altfmt=0).  Once vtype.altfmt is available,
      // branch on it here to also support altfmt=1 (vs1 signed).
      let prod : bits(32) = match funct6 {
        VQWDOTAU_VV => to_bits_unsafe(32, unsigned(vs2_val[i]) * unsigned(vs1_val[i])),
        VQWDOTAS_VV => to_bits_unsafe(32, signed(vs2_val[i])   * unsigned(vs1_val[i]))
      };
      sum = sum + prod
    }
  };

  write_single_element(SEW_acc, 0, vd, sum);
  // vd[1..] are tail elements, currently left undisturbed (matches vredsum.vs convention).
  // TODO: configuration support for agnostic tail behavior.
  set_vstart(zeros());
  RETIRE_SUCCESS
}

mapping zvqwdota8i_mnemonic : zvqwdota8i_funct6 <-> string = {
  VQWDOTAU_VV <-> "vqwdotau.vv",
  VQWDOTAS_VV <-> "vqwdotas.vv"
}

mapping clause assembly = ZVQWDOTA8I(funct6, vm, vs2, vs1, vd)
  <-> zvqwdota8i_mnemonic(funct6) ^ spc() ^ vreg_name(vd) ^ sep() ^ vreg_name(vs2) ^ sep() ^ vreg_name(vs1) ^ maybe_vmask(vm)
