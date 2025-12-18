//=======================================================================================
// This Sail RISC-V architecture model, comprising all files and
// directories except where otherwise noted is subject the BSD
// two-clause license in the LICENSE file.
//
// SPDX-License-Identifier: BSD-2-Clause
//=======================================================================================

mapping clause csr_name_map = 0x30C <-> "mstateen0"
mapping clause csr_name_map = 0x30D <-> "mstateen1"
mapping clause csr_name_map = 0x30E <-> "mstateen2"
mapping clause csr_name_map = 0x30F <-> "mstateen3"
mapping clause csr_name_map = 0x31C <-> "mstateen0h"
mapping clause csr_name_map = 0x31D <-> "mstateen1h"
mapping clause csr_name_map = 0x31E <-> "mstateen2h"
mapping clause csr_name_map = 0x31F <-> "mstateen3h"

function clause is_CSR_accessible(0x30C, _, _) = is_mstateen_accessible()
function clause is_CSR_accessible(0x30D, _, _) = is_mstateen_accessible()
function clause is_CSR_accessible(0x30E, _, _) = is_mstateen_accessible()
function clause is_CSR_accessible(0x30F, _, _) = is_mstateen_accessible()
function clause is_CSR_accessible(0x31C, _, _) = is_mstateen_accessible() & (xlen == 32)
function clause is_CSR_accessible(0x31D, _, _) = is_mstateen_accessible() & (xlen == 32)
function clause is_CSR_accessible(0x31E, _, _) = is_mstateen_accessible() & (xlen == 32)
function clause is_CSR_accessible(0x31F, _, _) = is_mstateen_accessible() & (xlen == 32)

function clause read_CSR(0x30C) = mstateen0.bits[xlen - 1 .. 0]
function clause read_CSR(0x30D) = mstateen1.bits[xlen - 1 .. 0]
function clause read_CSR(0x30E) = mstateen2.bits[xlen - 1 .. 0]
function clause read_CSR(0x30F) = mstateen3.bits[xlen - 1 .. 0]
function clause read_CSR(0x31C if xlen == 32) = mstateen0.bits[63 .. 32]
function clause read_CSR(0x31D if xlen == 32) = mstateen1.bits[63 .. 32]
function clause read_CSR(0x31E if xlen == 32) = mstateen2.bits[63 .. 32]
function clause read_CSR(0x31F if xlen == 32) = mstateen3.bits[63 .. 32]

function clause write_CSR((0x30C, value) if xlen == 32) = { mstateen0 = legalize_mstateen0(mstateen0, mstateen0.bits[63 .. 32] @ value); Ok(mstateen0.bits[31 .. 0]) }
function clause write_CSR((0x30D, value) if xlen == 32) = { mstateen1 = legalize_mstateen1(mstateen1, mstateen1.bits[63 .. 32] @ value); Ok(mstateen1.bits[31 .. 0]) }
function clause write_CSR((0x30E, value) if xlen == 32) = { mstateen2 = legalize_mstateen2(mstateen2, mstateen2.bits[63 .. 32] @ value); Ok(mstateen2.bits[31 .. 0]) }
function clause write_CSR((0x30F, value) if xlen == 32) = { mstateen3 = legalize_mstateen3(mstateen3, mstateen3.bits[63 .. 32] @ value); Ok(mstateen3.bits[31 .. 0]) }
function clause write_CSR((0x30C, value) if xlen == 64) = { mstateen0 = legalize_mstateen0(mstateen0, value); Ok(mstateen0.bits) }
function clause write_CSR((0x30D, value) if xlen == 64) = { mstateen1 = legalize_mstateen1(mstateen1, value); Ok(mstateen1.bits) }
function clause write_CSR((0x30E, value) if xlen == 64) = { mstateen2 = legalize_mstateen2(mstateen2, value); Ok(mstateen2.bits) }
function clause write_CSR((0x30F, value) if xlen == 64) = { mstateen3 = legalize_mstateen3(mstateen3, value); Ok(mstateen3.bits) }
function clause write_CSR((0x31C, value) if xlen == 32) = { mstateen0 = legalize_mstateen0(mstateen0, value @ mstateen0.bits[31 .. 0]); Ok(mstateen0.bits[63 .. 32]) }
function clause write_CSR((0x31D, value) if xlen == 32) = { mstateen1 = legalize_mstateen1(mstateen1, value @ mstateen1.bits[31 .. 0]); Ok(mstateen1.bits[63 .. 32]) }
function clause write_CSR((0x31E, value) if xlen == 32) = { mstateen2 = legalize_mstateen2(mstateen2, value @ mstateen2.bits[31 .. 0]); Ok(mstateen2.bits[63 .. 32]) }
function clause write_CSR((0x31F, value) if xlen == 32) = { mstateen3 = legalize_mstateen3(mstateen3, value @ mstateen3.bits[31 .. 0]); Ok(mstateen3.bits[63 .. 32]) }

mapping clause csr_name_map = 0x60C <-> "hstateen0"
mapping clause csr_name_map = 0x60D <-> "hstateen1"
mapping clause csr_name_map = 0x60E <-> "hstateen2"
mapping clause csr_name_map = 0x60F <-> "hstateen3"
mapping clause csr_name_map = 0x61C <-> "hstateen0h"
mapping clause csr_name_map = 0x61D <-> "hstateen1h"
mapping clause csr_name_map = 0x61E <-> "hstateen2h"
mapping clause csr_name_map = 0x61F <-> "hstateen3h"

function clause is_CSR_accessible(0x60C, _, _) = is_hstateen_accessible()
function clause is_CSR_accessible(0x60D, _, _) = is_hstateen_accessible()
function clause is_CSR_accessible(0x60E, _, _) = is_hstateen_accessible()
function clause is_CSR_accessible(0x60F, _, _) = is_hstateen_accessible()
function clause is_CSR_accessible(0x61C, _, _) = is_hstateen_accessible() & (xlen == 32)
function clause is_CSR_accessible(0x61D, _, _) = is_hstateen_accessible() & (xlen == 32)
function clause is_CSR_accessible(0x61E, _, _) = is_hstateen_accessible() & (xlen == 32)
function clause is_CSR_accessible(0x61F, _, _) = is_hstateen_accessible() & (xlen == 32)

function clause read_CSR(0x60C) = (hstateen0.bits & get_hstateen_mask(0))[xlen - 1 .. 0]
function clause read_CSR(0x60D) = (hstateen1.bits & get_hstateen_mask(1))[xlen - 1 .. 0]
function clause read_CSR(0x60E) = (hstateen2.bits & get_hstateen_mask(2))[xlen - 1 .. 0]
function clause read_CSR(0x60F) = (hstateen3.bits & get_hstateen_mask(3))[xlen - 1 .. 0]
function clause read_CSR(0x61C if xlen == 32) = (hstateen0.bits & get_hstateen_mask(0))[63 .. 32]
function clause read_CSR(0x61D if xlen == 32) = (hstateen1.bits & get_hstateen_mask(1))[63 .. 32]
function clause read_CSR(0x61E if xlen == 32) = (hstateen2.bits & get_hstateen_mask(2))[63 .. 32]
function clause read_CSR(0x61F if xlen == 32) = (hstateen3.bits & get_hstateen_mask(3))[63 .. 32]

function clause write_CSR((0x60C, value) if xlen == 32) = { hstateen0 = legalize_hstateen0(hstateen0, hstateen0.bits[63 .. 32] @ value); Ok(hstateen0.bits[31 .. 0]) }
function clause write_CSR((0x60D, value) if xlen == 32) = { hstateen1 = legalize_hstateen1(hstateen1, hstateen1.bits[63 .. 32] @ value); Ok(hstateen1.bits[31 .. 0]) }
function clause write_CSR((0x60E, value) if xlen == 32) = { hstateen2 = legalize_hstateen2(hstateen2, hstateen2.bits[63 .. 32] @ value); Ok(hstateen2.bits[31 .. 0]) }
function clause write_CSR((0x60F, value) if xlen == 32) = { hstateen3 = legalize_hstateen3(hstateen3, hstateen3.bits[63 .. 32] @ value); Ok(hstateen3.bits[31 .. 0]) }
function clause write_CSR((0x60C, value) if xlen == 64) = { hstateen0 = legalize_hstateen0(hstateen0, value); Ok(hstateen0.bits) }
function clause write_CSR((0x60D, value) if xlen == 64) = { hstateen1 = legalize_hstateen1(hstateen1, value); Ok(hstateen1.bits) }
function clause write_CSR((0x60E, value) if xlen == 64) = { hstateen2 = legalize_hstateen2(hstateen2, value); Ok(hstateen2.bits) }
function clause write_CSR((0x60F, value) if xlen == 64) = { hstateen3 = legalize_hstateen3(hstateen3, value); Ok(hstateen3.bits) }
function clause write_CSR((0x61C, value) if xlen == 32) = { hstateen0 = legalize_hstateen0(hstateen0, value @ hstateen0.bits[31 .. 0]); Ok(hstateen0.bits[63 .. 32]) }
function clause write_CSR((0x61D, value) if xlen == 32) = { hstateen1 = legalize_hstateen1(hstateen1, value @ hstateen1.bits[31 .. 0]); Ok(hstateen1.bits[63 .. 32]) }
function clause write_CSR((0x61E, value) if xlen == 32) = { hstateen2 = legalize_hstateen2(hstateen2, value @ hstateen2.bits[31 .. 0]); Ok(hstateen2.bits[63 .. 32]) }
function clause write_CSR((0x61F, value) if xlen == 32) = { hstateen3 = legalize_hstateen3(hstateen3, value @ hstateen3.bits[31 .. 0]); Ok(hstateen3.bits[63 .. 32]) }

mapping clause csr_name_map = 0x10C <-> "sstateen0"
mapping clause csr_name_map = 0x10D <-> "sstateen1"
mapping clause csr_name_map = 0x10E <-> "sstateen2"
mapping clause csr_name_map = 0x10F <-> "sstateen3"

function clause is_CSR_accessible(0x10C, _, _) = is_sstateen_accessible()
function clause is_CSR_accessible(0x10D, _, _) = is_sstateen_accessible()
function clause is_CSR_accessible(0x10E, _, _) = is_sstateen_accessible()
function clause is_CSR_accessible(0x10F, _, _) = is_sstateen_accessible()

function clause read_CSR(0x10C) = { let mask = get_sstateen_mask(0); zero_extend(sstateen0.bits & mask[31..0]) }
function clause read_CSR(0x10D) = { let mask = get_sstateen_mask(1); zero_extend(sstateen1.bits & mask[31..0]) }
function clause read_CSR(0x10E) = { let mask = get_sstateen_mask(2); zero_extend(sstateen2.bits & mask[31..0]) }
function clause read_CSR(0x10F) = { let mask = get_sstateen_mask(3); zero_extend(sstateen3.bits & mask[31..0]) }

function clause write_CSR(0x10C, value) = {
  let legalized = legalize_sstateen0(sstateen0, value[31 .. 0]);
  let mask = get_sstateen_mask(0);
  sstateen0 = Mk_Sstateen0(legalized.bits & mask[31..0]);
  Ok(zero_extend(sstateen0.bits))
}

function clause write_CSR(0x10D, value) = { sstateen1 = legalize_sstateen1(sstateen1, value[31 .. 0]); Ok(zero_extend(sstateen1.bits)) }
function clause write_CSR(0x10E, value) = { sstateen2 = legalize_sstateen2(sstateen2, value[31 .. 0]); Ok(zero_extend(sstateen2.bits)) }
function clause write_CSR(0x10F, value) = { sstateen3 = legalize_sstateen3(sstateen3, value[31 .. 0]); Ok(zero_extend(sstateen3.bits)) }

// Stateen permission checks for CSRs gated by stateen bits.
val is_CSR_accessible_stateen : (csreg, Privilege) -> bool
scattered function is_CSR_accessible_stateen

function clause is_CSR_accessible_stateen(0x60C, priv) = check_stateen_bit(priv, STATEEN_SE, 0)
function clause is_CSR_accessible_stateen(0x60D, priv) = check_stateen_bit(priv, STATEEN_SE, 1)
function clause is_CSR_accessible_stateen(0x60E, priv) = check_stateen_bit(priv, STATEEN_SE, 2)
function clause is_CSR_accessible_stateen(0x60F, priv) = check_stateen_bit(priv, STATEEN_SE, 3)

function clause is_CSR_accessible_stateen(0x61C, priv) = check_stateen_bit(priv, STATEEN_SE, 0)
function clause is_CSR_accessible_stateen(0x61D, priv) = check_stateen_bit(priv, STATEEN_SE, 1)
function clause is_CSR_accessible_stateen(0x61E, priv) = check_stateen_bit(priv, STATEEN_SE, 2)
function clause is_CSR_accessible_stateen(0x61F, priv) = check_stateen_bit(priv, STATEEN_SE, 3)

function clause is_CSR_accessible_stateen(0x10C, priv) = check_stateen_bit(priv, STATEEN_SE, 0)
function clause is_CSR_accessible_stateen(0x10D, priv) = check_stateen_bit(priv, STATEEN_SE, 1)
function clause is_CSR_accessible_stateen(0x10E, priv) = check_stateen_bit(priv, STATEEN_SE, 2)
function clause is_CSR_accessible_stateen(0x10F, priv) = check_stateen_bit(priv, STATEEN_SE, 3)

function clause is_CSR_accessible_stateen(0x10A, priv) = check_stateen_bit(priv, STATEEN_ENVCFG, 0)

function clause is_CSR_accessible_stateen(0x001, priv) = if currentlyEnabled(Ext_Zfinx) then check_stateen_bit(priv, STATEEN_FCSR, 0) else true
function clause is_CSR_accessible_stateen(0x002, priv) = if currentlyEnabled(Ext_Zfinx) then check_stateen_bit(priv, STATEEN_FCSR, 0) else true
function clause is_CSR_accessible_stateen(0x003, priv) = if currentlyEnabled(Ext_Zfinx) then check_stateen_bit(priv, STATEEN_FCSR, 0) else true

function clause is_CSR_accessible_stateen(_, _) = true
end is_CSR_accessible_stateen
