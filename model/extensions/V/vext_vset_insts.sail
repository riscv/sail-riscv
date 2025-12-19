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

mapping vtype_assembly : string <-> (bits(1), bits(1), bits(3), bits(3)) = {
  // Mnemonics are preferable but there's no mnemonic for lmul=0b100.
  sew_flag(sew) ^ maybe_lmul_flag(lmul) ^ ta_flag(ta) ^ ma_flag(ma) <-> (ma, ta, sew, lmul)
    when sew[2] != bitone & lmul != 0b100,
  // However that is still potentially a legal instruction so you can
  // use an integer for the whole vtype in that case.
  hex_bits_8(ma @ ta @ sew @ lmul)  <-> (ma, ta, sew, lmul),
}

function handle_illegal_vtype(rd : regidx) -> unit = {
  // Note: Implementations can set vill or trap with an illegal
  // instruction if the vtype setting is not supported.
  // TODO: configuration support for both solutions.
  // NOTE: vstart should NOT be zeroed out and rd
  //       should NOT be written if trapping.

  vtype.bits = 0b1 @ zeros(xlen - 1); // set vtype.vill
  vl = zeros();
  csr_write_callback("vtype", vtype.bits);
  csr_write_callback("vl", vl);
  set_vstart(zeros());

  // The new value of `vl` needs to be written to `rd`.
  X(rd) = vl;
}

let vl_use_ceil : bool = config extensions.V.vl_use_ceil

function calculate_new_vl(AVL : xlenbits, VLMAX : range(1, vlen)) -> range(0, vlen) = {
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
function execute_vsetvl_type(
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
    handle_illegal_vtype(rd);
    return RETIRE_SUCCESS;
  };

  let LMUL_pow_new = signed(lmul);
  let SEW_pow_new = unsigned(sew) + 3;

  let lmul_sew_ratio = get_lmul_pow() - get_sew_pow();
  let lmul_sew_ratio_new = LMUL_pow_new - SEW_pow_new;

  // "For a given supported fractional LMUL setting, implementations must
  // support SEW settings between SEWMIN and LMUL * ELEN, inclusive."
  //
  // Also some cases require that VLMAX doesn't change (i.e. LMUL/SEW is constant).
  if SEW_pow_new > (LMUL_pow_new + elen_exp) |
     (requires_fixed_vlmax & (lmul_sew_ratio != lmul_sew_ratio_new | not(valid_vtype()))) then {
    handle_illegal_vtype(rd);
    return RETIRE_SUCCESS;
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
union clause instruction = VSETVLI : (bits(1), bits(1), bits(3), bits(3), regidx, regidx)

mapping clause encdec = VSETVLI(ma, ta, sew, lmul, rs1, rd)
  <-> 0b0000 @ ma @ ta @ sew @ lmul @ encdec_reg(rs1) @ 0b111 @ encdec_reg(rd) @ 0b1010111
  when currentlyEnabled(Ext_Zve32x)

function clause execute VSETVLI(ma, ta, sew, lmul, rs1, rd) = {
  let avl =
    if rs1 != zreg then X(rs1)
    else if rd != zreg then ones()
    else vl;

  let requires_fixed_vlmax = rd == zreg & rs1 == zreg;

  execute_vsetvl_type(ma, ta, sew, lmul, avl, requires_fixed_vlmax, rd)
}

mapping clause assembly = VSETVLI(ma, ta, sew, lmul, rs1, rd)
  <-> "vsetvli" ^ spc() ^ reg_name(rd) ^ sep() ^ reg_name(rs1) ^ sep() ^ vtype_assembly(ma, ta, sew, lmul)

// ********************************** vsetvl ************************************
union clause instruction = VSETVL : (regidx, regidx, regidx)

mapping clause encdec = VSETVL(rs2, rs1, rd)
  <-> 0b1000000 @ encdec_reg(rs2) @ encdec_reg(rs1) @ 0b111 @ encdec_reg(rd) @ 0b1010111
  when currentlyEnabled(Ext_Zve32x)

function clause execute VSETVL(rs2, rs1, rd) = {
  let vt = Mk_Vtype(X(rs2));

  if vt[vill] == 0b1 | vt[reserved] != zeros()
  then { handle_illegal_vtype(rd); return RETIRE_SUCCESS };

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
union clause instruction = VSETIVLI : ( bits(1), bits(1), bits(3), bits(3), bits(5), regidx)

mapping clause encdec = VSETIVLI(ma, ta, sew, lmul, uimm, rd)
  <-> 0b1100 @ ma @ ta @ sew @ lmul @ uimm @ 0b111 @ encdec_reg(rd) @ 0b1010111
  when currentlyEnabled(Ext_Zve32x)

function clause execute VSETIVLI(ma, ta, sew, lmul, uimm, rd) = {
  let avl : xlenbits = zero_extend(uimm);
  execute_vsetvl_type(ma, ta, sew, lmul, avl, false, rd)
}

mapping clause assembly = VSETIVLI(ma, ta, sew, lmul, uimm, rd)
  <-> "vsetivli" ^ spc() ^ reg_name(rd) ^ sep() ^ hex_bits_5(uimm) ^ sep() ^ vtype_assembly(ma, ta, sew, lmul)
