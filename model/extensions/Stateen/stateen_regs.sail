//=======================================================================================
// This Sail RISC-V architecture model, comprising all files and
// directories except where otherwise noted is subject the BSD
// two-clause license in the LICENSE file.
//
// SPDX-License-Identifier: BSD-2-Clause
//=======================================================================================

function clause currentlyEnabled(Ext_Smstateen) = hartSupports(Ext_Smstateen)
function clause currentlyEnabled(Ext_Ssstateen) = hartSupports(Ext_Ssstateen)

function is_mstateen_accessible() -> bool = hartSupports(Ext_Smstateen)
function is_hstateen_accessible() -> bool = currentlyEnabled(Ext_H) & (currentlyEnabled(Ext_Smstateen) | currentlyEnabled(Ext_Ssstateen))
function is_sstateen_accessible() -> bool = currentlyEnabled(Ext_S) & (currentlyEnabled(Ext_Smstateen) | currentlyEnabled(Ext_Ssstateen))

bitfield Mstateen0 : bits(64) = {
  SE0     : 63,
  ENVCFG  : 62,

  CSRIND  : 60,
  AIA     : 59,
  IMSIC   : 58,
  CONTEXT : 57,
  P1P13   : 56,
  SRMCFG  : 55,
  CTR     : 54,

  JVT     : 2,
  FCSR    : 1,
  C       : 0,
}

bitfield Mstateen1 : bits(64) = {
  SE1 : 63,
}

bitfield Mstateen2 : bits(64) = {
  SE2 : 63,
}

bitfield Mstateen3 : bits(64) = {
  SE3 : 63,
}

// TODO: Update when Zcmt is implemented
function is_mstateen_SE0_readonly_zero() -> bool = {
  not(currentlyEnabled(Ext_H)) & not(currentlyEnabled(Ext_Zfinx))
}

function legalize_mstateen0(m : Mstateen0, v : bits(64)) -> Mstateen0 = {
  let v = Mk_Mstateen0(v);
  [m with
    SE0    = if is_mstateen_SE0_readonly_zero() then 0b0 else v[SE0],
    ENVCFG = if currentlyEnabled(Ext_S) then v[ENVCFG] else 0b0,
    FCSR   = if currentlyEnabled(Ext_Zfinx) then v[FCSR] else 0b0,
    C      = 0b0,
  ];
}

function legalize_mstateen1(m : Mstateen1, v : bits(64)) -> Mstateen1 = { m }
function legalize_mstateen2(m : Mstateen2, v : bits(64)) -> Mstateen2 = { m }
function legalize_mstateen3(m : Mstateen3, v : bits(64)) -> Mstateen3 = { m }

register mstateen0 : Mstateen0 = Mk_Mstateen0(zeros())
register mstateen1 : Mstateen1 = Mk_Mstateen1(zeros())
register mstateen2 : Mstateen2 = Mk_Mstateen2(zeros())
register mstateen3 : Mstateen3 = Mk_Mstateen3(zeros())

function get_mstateen(idx : range(0, 3)) -> bits(64) = {
  if not(is_mstateen_accessible()) then ones()
  else match idx {
    0 => mstateen0.bits,
    1 => mstateen1.bits,
    2 => mstateen2.bits,
    3 => mstateen3.bits,
  }
}

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

register hstateen0 : Mstateen0 = Mk_Mstateen0(zeros())
register hstateen1 : Mstateen1 = Mk_Mstateen1(zeros())
register hstateen2 : Mstateen2 = Mk_Mstateen2(zeros())
register hstateen3 : Mstateen3 = Mk_Mstateen3(zeros())

function get_hstateen(idx : range(0, 3)) -> bits(64) = {
  if not(is_hstateen_accessible()) then ones()
  else match idx {
    0 => hstateen0.bits,
    1 => hstateen1.bits,
    2 => hstateen2.bits,
    3 => hstateen3.bits,
  }
}

function get_hstateen_mask(idx : range(0, 3)) -> bits(64) = {
  get_mstateen(idx)
}

function legalize_hstateen0(h : Mstateen0, v : bits(64)) -> Mstateen0 = {
  let legalized = legalize_mstateen0(h, v);
  Mk_Mstateen0(legalized.bits & get_hstateen_mask(0))
}

function legalize_hstateen1(h : Mstateen1, v : bits(64)) -> Mstateen1 = {
  let legalized = legalize_mstateen1(h, v);
  Mk_Mstateen1(legalized.bits & get_hstateen_mask(1))
}

function legalize_hstateen2(h : Mstateen2, v : bits(64)) -> Mstateen2 = {
  let legalized = legalize_mstateen2(h, v);
  Mk_Mstateen2(legalized.bits & get_hstateen_mask(2))
}

function legalize_hstateen3(h : Mstateen3, v : bits(64)) -> Mstateen3 = {
  let legalized = legalize_mstateen3(h, v);
  Mk_Mstateen3(legalized.bits & get_hstateen_mask(3))
}

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

bitfield Sstateen0 : bits(32) = {
  JVT  : 2,
  FCSR : 1,
  C    : 0,
}

bitfield Sstateen1 : bits(32) = {
  // No bits defined yet
}

bitfield Sstateen2 : bits(32) = {
  // No bits defined yet
}

bitfield Sstateen3 : bits(32) = {
  // No bits defined yet
}

function legalize_sstateen0(s : Sstateen0, v : bits(32)) -> Sstateen0 = {
  let v = Mk_Sstateen0(v);
  [s with
    FCSR = if misa[F] == 0b1 then 0b0 else v[FCSR],
  ];
}

function legalize_sstateen1(s : Sstateen1, v : bits(32)) -> Sstateen1 = { s }
function legalize_sstateen2(s : Sstateen2, v : bits(32)) -> Sstateen2 = { s }
function legalize_sstateen3(s : Sstateen3, v : bits(32)) -> Sstateen3 = { s }

register sstateen0 : Sstateen0 = Mk_Sstateen0(zeros())
register sstateen1 : Sstateen1 = Mk_Sstateen1(zeros())
register sstateen2 : Sstateen2 = Mk_Sstateen2(zeros())
register sstateen3 : Sstateen3 = Mk_Sstateen3(zeros())

function get_sstateen(idx : range(0, 3)) -> bits(64) =
  0xFFFFFFFF @ (
    if is_sstateen_accessible() then (match idx {
      0 => sstateen0.bits,
      1 => sstateen1.bits,
      2 => sstateen2.bits,
      3 => sstateen3.bits,
    }) else ones()
  )

function get_sstateen_mask(idx : range(0, 3)) -> bits(64) = {
  get_mstateen(idx) & get_hstateen(idx)
}

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

enum stateen_control_bits = {STATEEN_FCSR, STATEEN_ENVCFG, STATEEN_SE}

mapping csr_permission_idx : stateen_control_bits <-> {1, 62, 63} = {
  STATEEN_SE     <-> 63,
  STATEEN_ENVCFG <-> 62,
  STATEEN_FCSR   <-> 1,
}

// Maps a CSR address to the corresponding stateen permission bit and stateen id
// NOTE: Add more mappings as needed
function csr_to_stateen_bit(csr : csreg) -> option((stateen_control_bits, range(0, 3))) = {
  match csr {
    // hstateen (controlled by mstateen SE bits)
    0x60C /* hstateen0  */ => Some((STATEEN_SE, 0)),
    0x60D /* hstateen1  */ => Some((STATEEN_SE, 1)),
    0x60E /* hstateen2  */ => Some((STATEEN_SE, 2)),
    0x60F /* hstateen3  */ => Some((STATEEN_SE, 3)),
    0x61C /* hstateen0h */ => Some((STATEEN_SE, 0)),
    0x61D /* hstateen1h */ => Some((STATEEN_SE, 1)),
    0x61E /* hstateen2h */ => Some((STATEEN_SE, 2)),
    0x61F /* hstateen3h */ => Some((STATEEN_SE, 3)),

    // sstateen (controlled by mstateen AND hstateen SE bits)
    0x10C /* sstateen0 */ => Some((STATEEN_SE, 0)),
    0x10D /* sstateen1 */ => Some((STATEEN_SE, 1)),
    0x10E /* sstateen2 */ => Some((STATEEN_SE, 2)),
    0x10F /* sstateen3 */ => Some((STATEEN_SE, 3)),

    0x10A /* senvcfg   */ => Some((STATEEN_ENVCFG, 0)),
    0x001 /* fflags    */ => if currentlyEnabled(Ext_Zfinx) then Some((STATEEN_FCSR, 0)) else None(),
    0x002 /* frm       */ => if currentlyEnabled(Ext_Zfinx) then Some((STATEEN_FCSR, 0)) else None(),
    0x003 /* fcsr      */ => if currentlyEnabled(Ext_Zfinx) then Some((STATEEN_FCSR, 0)) else None(),

    _ => None(),
  }
}

// Returns true if the CSR is an hstateen register
function is_hstateen_csr(csr : csreg) -> bool = {
  match csr {
    0x60C => true, // hstateen0
    0x60D => true, // hstateen1
    0x60E => true, // hstateen2
    0x60F => true, // hstateen3
    0x61C => true, // hstateen0h
    0x61D => true, // hstateen1h
    0x61E => true, // hstateen2h
    0x61F => true, // hstateen3h
    _     => false,
  }
}

// Verifies whether access to CSRs protected by the Smstateen or Ssstateen
// extensions is allowed at the current privilege level.
function check_CSR_stateen_permission(csr : csreg) -> bool = {
  match csr_to_stateen_bit(csr) {
    Some((bit_idx, stateen_register_index)) => {
      let mask : bits(64) = match cur_privilege {
        Machine           => ones(),
        Supervisor        => if is_hstateen_csr(csr)
                             then get_hstateen_mask(stateen_register_index)
                             else get_sstateen_mask(stateen_register_index),
        User              => get_sstateen_mask(stateen_register_index) & get_sstateen(stateen_register_index),
        VirtualUser       => internal_error(__FILE__, __LINE__, "Hypervisor extension not supported"),
        VirtualSupervisor => internal_error(__FILE__, __LINE__, "Hypervisor extension not supported"),
      };
      mask[csr_permission_idx(bit_idx)] == bitone
    },
    None() => true
  }
}

// Check if floating-point instructions using X registers
// (Zfinx, Zdinx, etc.) are permitted in the given privilege mode.
function check_fp_stateen() -> bool = {
  let mask : bits(64) = match cur_privilege {
    Machine           => ones(),
    Supervisor        => get_sstateen_mask(0),
    User              => get_sstateen_mask(0) & get_sstateen(0),
    VirtualUser       => internal_error(__FILE__, __LINE__, "Hypervisor extension not supported"),
    VirtualSupervisor => internal_error(__FILE__, __LINE__, "Hypervisor extension not supported"),
  };
  mask[csr_permission_idx(STATEEN_FCSR)] == bitone
}

function reset_stateen() -> unit = {
  mstateen0.bits = zeros();
  mstateen1.bits = zeros();
  mstateen2.bits = zeros();
  mstateen3.bits = zeros();
}
