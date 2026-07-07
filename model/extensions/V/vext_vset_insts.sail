// =======================================================================================
// This Sail RISC-V architecture model, comprising all files and
// directories except where otherwise noted is subject the BSD
// two-clause license in the LICENSE file.
//
// SPDX-License-Identifier: BSD-2-Clause
// =======================================================================================

// ******************************************************************************
// This file implements part of the vector extension.
// Chapter 6: Configuration-Setting Instructions
// ******************************************************************************


mapping sew_flag : string <-> bits(3) = {
  "e8"    <-> 0b000,
  "e16"   <-> 0b001,
  "e32"   <-> 0b010,
  "e64"   <-> 0b011,
}

mapping maybe_lmul_flag : string <-> bits(3) = {
  sep() ^ "mf8"   <-> 0b101,
  sep() ^ "mf4"   <-> 0b110,
  sep() ^ "mf2"   <-> 0b111,
  sep() ^ "m1"    <-> 0b000,
  sep() ^ "m2"    <-> 0b001,
  sep() ^ "m4"    <-> 0b010,
  sep() ^ "m8"    <-> 0b011,
  forwards ""      => 0b000, // m1 by default
}

mapping ta_flag : string <-> bits(1) = {
  sep() ^ "ta" <-> 0b1,
  sep() ^ "tu" <-> 0b0,
}

mapping ma_flag : string <-> bits(1) = {
  sep() ^ "ma" <-> 0b1,
  sep() ^ "mu" <-> 0b0,
}

// For vsetvli and vsetivli, vtr = 0b000 is implicit in the assembly and
// cannot be printed.
val vtr_mnemonic : bits(3) <-> string
function vtr_mnemonic_forwards(_vtr) = ""
function vtr_mnemonic_forwards_matches(_vtr) = true

mapping vtype_assembly : (bits(3), bits(1), bits(1), bits(3), bits(3)) <-> string = {
  // Mnemonics are preferable but there's no mnemonic for lmul=0b100.
  (vtr, ma, ta, sew, lmul) <-> sew_flag(sew) ^ maybe_lmul_flag(lmul) ^ ta_flag(ta) ^ ma_flag(ma) ^ vtr_mnemonic(vtr)
    when sew[2] != 0b1 & lmul != 0b100 & vtr == 0b000,
  // However that is still potentially a legal instruction so you can
  // use an integer for the whole vtype in that case.
  (vtr, ma, ta, sew, lmul) <-> hex_bits_11(vtr @ ma @ ta @ sew @ lmul)
}

private function handle_illegal_vtype(rd : regidx) -> ExecutionResult = {
  // Note: vstart should NOT be zeroed out and rd
  //       should NOT be written if trapping.
  match illegal_vtype_reserved_behavior {
    IllegalVtype_Illegal => return Illegal_Instruction(),
    IllegalVtype_Fatal   => reserved_behavior("unsupported or reserved vtype"),
    IllegalVtype_SetVill => (),
  };

  vtype.bits = 0b1 @ zeros(xlen - 1); // set vtype.vill
  vl = zeros();
  csr_write_callback("vtype", vtype.bits);
  csr_write_callback("vl", vl);
  set_vstart(zeros());

  // "The vset{i}vl{i} instructions set the vtype and vl CSRs based on their arguments,
  //  and write the new value of vl into rd."
  // So `rd` should be written even if the arguments were illegal or reserved.
  X(rd) = vl;
  RETIRE_SUCCESS
}

let vl_use_ceil : bool = config extensions.V.vl_use_ceil

private function calculate_new_vl(AVL : xlenbits, VLMAX : range(1, vlen)) -> range(0, vlen) = {
  let AVL = unsigned(AVL);
  // See "Constraints on Setting vl" in the vector spec.
  if AVL <= VLMAX then AVL
  else if AVL < 2 * VLMAX then {
    // If VLMAX < AVL < 2 * VLMAX then we can use any value
    // such that ceil(AVL / 2) <= vl <= VLMAX. Here we provide
    // two options: ceil(AVL / 2) or VLMAX.
    if vl_use_ceil then (AVL + 1) / 2 else VLMAX
  } else VLMAX
}

// Execute vsetvl, vsetvli, or vsetivli.
private function execute_vsetvl_type(
  ma : bits(1),
  ta : bits(1),
  sew : bits(3),
  lmul : bits(3),
  avl : xlenbits,
  requires_fixed_vlmax : bool,
  rd : regidx,
) -> ExecutionResult = {
  // Check new SEW and LMUL have legal encodings. There are some reserved values.
  if is_invalid_lmul_pow(lmul) | is_invalid_sew_pow(sew) then {
    return handle_illegal_vtype(rd);
  };

  let LMUL_pow_new = signed(lmul);
  let SEW_pow_new = unsigned(sew) + 3;

  let lmul_sew_ratio = get_lmul_pow() - get_sew_pow();
  let lmul_sew_ratio_new = LMUL_pow_new - SEW_pow_new;

  // Check the following:
  // - SEW cannot exceed ELEN.
  // - "For a given supported fractional LMUL setting, implementations must
  //   support SEW settings between SEWMIN and LMUL * ELEN, inclusive."
  // - Also some cases require that VLMAX doesn't change (i.e. LMUL/SEW is constant).
  if SEW_pow_new > elen_exp |
     SEW_pow_new > (LMUL_pow_new + elen_exp) |
     (requires_fixed_vlmax & (lmul_sew_ratio != lmul_sew_ratio_new | not(valid_vtype()))) then {
    return handle_illegal_vtype(rd);
  };

  let VLMAX = 2 ^ (LMUL_pow_new + vlen_exp - SEW_pow_new);

  vl = to_bits(calculate_new_vl(avl, VLMAX));
  X(rd) = vl;

  vtype = [Mk_Vtype(zeros()) with
    vill = 0b0,
    vma = ma,
    vta = ta,
    vsew = sew,
    vlmul = lmul,
  ];

  // reset vstart to 0
  set_vstart(zeros());

  csr_write_callback("vtype", vtype.bits);
  csr_write_callback("vl", vl);
  csr_write_callback("vstart", vstart);

  RETIRE_SUCCESS
}

// ********************************** vsetvli ***********************************
union clause instruction = VSETVLI : (bits(3), bits(1), bits(1), bits(3), bits(3), regidx, regidx)

mapping clause encdec = VSETVLI(vtr, ma, ta, sew, lmul, rs1, rd)
  <-> 0b0 @ vtr @ ma @ ta @ sew @ lmul @ encdec_reg(rs1) @ 0b111 @ encdec_reg(rd) @ 0b1010111
  when currentlyEnabled(Ext_Zve32x)

function clause execute VSETVLI(vtr, ma, ta, sew, lmul, rs1, rd) = {
  if vtr != zeros()
  then return handle_illegal_vtype(rd);

  let avl =
    if rs1 != zreg then X(rs1)
    else if rd != zreg then ones()
    else vl;

  let requires_fixed_vlmax = rd == zreg & rs1 == zreg;

  execute_vsetvl_type(ma, ta, sew, lmul, avl, requires_fixed_vlmax, rd)
}


mapping clause assembly = VSETVLI(vtr, ma, ta, sew, lmul, rs1, rd)
  <-> "vsetvli" ^ spc() ^ reg_name(rd) ^ sep() ^ reg_name(rs1) ^ sep() ^ vtype_assembly(vtr, ma, ta, sew, lmul)

// ********************************** vsetvl ************************************
union clause instruction = VSETVL : (regidx, regidx, regidx)

mapping clause encdec = VSETVL(rs2, rs1, rd)
  <-> 0b1000000 @ encdec_reg(rs2) @ encdec_reg(rs1) @ 0b111 @ encdec_reg(rd) @ 0b1010111
  when currentlyEnabled(Ext_Zve32x)

function clause execute VSETVL(rs2, rs1, rd) = {
  let vt = Mk_Vtype(X(rs2));

  if vt[vill] == 0b1 | vt[reserved] != zeros()
  then return handle_illegal_vtype(rd);

  let avl =
    if rs1 != zreg then X(rs1)
    else if rd != zreg then ones()
    else vl;

  let requires_fixed_vlmax = rd == zreg & rs1 == zreg;

  execute_vsetvl_type(vt[vma], vt[vta], vt[vsew], vt[vlmul], avl, requires_fixed_vlmax, rd)
}

mapping clause assembly = VSETVL(rs2, rs1, rd)
  <-> "vsetvl" ^ spc() ^ reg_name(rd) ^ sep() ^ reg_name(rs1) ^ sep() ^ reg_name(rs2)

// ********************************* vsetivli ***********************************
union clause instruction = VSETIVLI : (bits(3), bits(1), bits(1), bits(3), bits(3), bits(5), regidx)

mapping clause encdec = VSETIVLI(0b0 @ vtr, ma, ta, sew, lmul, uimm, rd)
  <-> 0b11 @ vtr @ ma @ ta @ sew @ lmul @ uimm @ 0b111 @ encdec_reg(rd) @ 0b1010111
  when currentlyEnabled(Ext_Zve32x)

function clause execute VSETIVLI(vtr, ma, ta, sew, lmul, uimm, rd) = {
  if vtr != zeros()
  then return handle_illegal_vtype(rd);

  let avl : xlenbits = zero_extend(uimm);
  execute_vsetvl_type(ma, ta, sew, lmul, avl, false, rd)
}

mapping clause assembly = VSETIVLI(vtr, ma, ta, sew, lmul, uimm, rd)
  <-> "vsetivli" ^ spc() ^ reg_name(rd) ^ sep() ^ hex_bits_5(uimm) ^ sep() ^ vtype_assembly(vtr, ma, ta, sew, lmul)
