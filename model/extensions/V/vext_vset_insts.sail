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

val handle_illegal_vtype : unit -> unit
function handle_illegal_vtype() = {
  // Note: Implementations can set vill or trap with an illegal
  // instruction if the vtype setting is not supported.
  // TODO: configuration support for both solutions.
  // NOTE: vstart should NOT be zeroed out if trapping.

  vtype.bits = 0b1 @ zeros(xlen - 1); // set vtype.vill
  vl = zeros();
  csr_write_callback("vtype", vtype.bits);
  csr_write_callback("vl", vl);
  set_vstart(zeros());
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

// ********************************** vsetvli ***********************************
union clause instruction = VSETVLI : (bits(1), bits(1), bits(3), bits(3), regidx, regidx)

mapping clause encdec = VSETVLI(ma, ta, sew, lmul, rs1, rd)
  <-> 0b0000 @ ma @ ta @ sew @ lmul @ encdec_reg(rs1) @ 0b111 @ encdec_reg(rd) @ 0b1010111
  when currentlyEnabled(Ext_V)

function clause execute VSETVLI(ma, ta, sew, lmul, rs1, rd) = {
  let LMUL_pow_ori  = get_lmul_pow();
  let SEW_pow_ori   = get_sew_pow();
  let ratio_pow_ori = SEW_pow_ori - LMUL_pow_ori;

  // check new SEW and LMUL are legal and calculate VLMAX
  if is_invalid_lmul_pow(lmul) | is_invalid_sew_pow(sew) then {
    handle_illegal_vtype();
    return RETIRE_SUCCESS
  };
  let LMUL_pow_new = lmul_pow_val(lmul);
  let SEW_pow_new = sew_pow_val(sew);

  if SEW_pow_new > (LMUL_pow_new + elen_exp) then { handle_illegal_vtype(); return RETIRE_SUCCESS };
  let VLMAX = 2 ^ (LMUL_pow_new + vlen_exp - SEW_pow_new);

  // Set vl according to VLMAX and AVL.
  if rs1 != zreg then {
    // Normal stripmining.
    vl = to_bits(calculate_new_vl(X(rs1), VLMAX));
    X(rd) = vl;
  } else if rd != zreg then {
    // Set vl to VLMAX.
    vl = to_bits(xlen, VLMAX);
    X(rd) = vl;
  } else {
    // Keep existing vl if it is compatible and vtype.ill is valid.
    let ratio_pow_new = SEW_pow_new - LMUL_pow_new;
    let is_legal_vset = ratio_pow_new == ratio_pow_ori & valid_vtype();
    if not(is_legal_vset) then { handle_illegal_vtype(); return RETIRE_SUCCESS }
  };

  // set vtype
  vtype.bits = 0b0 @ zeros(xlen - 9) @ ma @ ta @ sew @ lmul;

  // reset vstart to 0
  set_vstart(zeros());

  csr_write_callback("vtype", vtype.bits);
  csr_write_callback("vl", vl);
  csr_write_callback("vstart", vstart);

  RETIRE_SUCCESS
}

mapping clause assembly = VSETVLI(ma, ta, sew, lmul, rs1, rd)
  <-> "vsetvli" ^ spc() ^ reg_name(rd) ^ sep() ^ reg_name(rs1) ^ sep() ^ vtype_assembly(ma, ta, sew, lmul)

// ********************************** vsetvl ************************************
union clause instruction = VSETVL : (regidx, regidx, regidx)

mapping clause encdec = VSETVL(rs2, rs1, rd)
  <-> 0b1000000 @ encdec_reg(rs2) @ encdec_reg(rs1) @ 0b111 @ encdec_reg(rd) @ 0b1010111
  when currentlyEnabled(Ext_V)

function clause execute VSETVL(rs2, rs1, rd) = {
  let vtype_new = Mk_Vtype(X(rs2));

  if   vtype_new[vill] == 0b1 | vtype_new[reserved] != zeros()
  then { handle_illegal_vtype(); return RETIRE_SUCCESS };

  let ma   = vtype_new[vma];
  let ta   = vtype_new[vta];
  let sew  = vtype_new[vsew];
  let lmul = vtype_new[vlmul];

  execute(VSETVLI(ma, ta, sew, lmul, rs1, rd))
}

mapping clause assembly = VSETVL(rs2, rs1, rd)
  <-> "vsetvl" ^ spc() ^ reg_name(rd) ^ sep() ^ reg_name(rs1) ^ sep() ^ reg_name(rs2)

// ********************************* vsetivli ***********************************
union clause instruction = VSETIVLI : ( bits(1), bits(1), bits(3), bits(3), bits(5), regidx)

mapping clause encdec = VSETIVLI(ma, ta, sew, lmul, uimm, rd)
  <-> 0b1100 @ ma @ ta @ sew @ lmul @ uimm @ 0b111 @ encdec_reg(rd) @ 0b1010111
  when currentlyEnabled(Ext_V)

function clause execute VSETIVLI(ma, ta, sew, lmul, uimm, rd) = {
  // check new SEW and LMUL are legal and calculate VLMAX
  if is_invalid_lmul_pow(lmul) | is_invalid_sew_pow(sew) then {
    handle_illegal_vtype();
    return RETIRE_SUCCESS
  };
  let LMUL_pow_new = lmul_pow_val(lmul);
  let SEW_pow_new = sew_pow_val(sew);

  if SEW_pow_new > (LMUL_pow_new + elen_exp) then { handle_illegal_vtype(); return RETIRE_SUCCESS };
  let VLMAX = 2 ^ (LMUL_pow_new + vlen_exp - SEW_pow_new);

  // set vl according to VLMAX and AVL
  // AVL is encoded as 5-bit zero-extended imm in the rs1 field
  vl = to_bits(calculate_new_vl(zero_extend(uimm), VLMAX));
  X(rd) = vl;

  // set vtype
  vtype.bits = 0b0 @ zeros(xlen - 9) @ ma @ ta @ sew @ lmul;

  // reset vstart to 0
  set_vstart(zeros());

  csr_write_callback("vtype", vtype.bits);
  csr_write_callback("vl", vl);
  csr_write_callback("vstart", vstart);

  RETIRE_SUCCESS
}

mapping clause assembly = VSETIVLI(ma, ta, sew, lmul, uimm, rd)
  <-> "vsetivli" ^ spc() ^ reg_name(rd) ^ sep() ^ hex_bits_5(uimm) ^ sep() ^ vtype_assembly(ma, ta, sew, lmul)
