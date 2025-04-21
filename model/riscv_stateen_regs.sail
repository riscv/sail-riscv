 /*=======================================================================================*/
/*  This Sail RISC-V architecture model, comprising all files and                        */
/*  directories except where otherwise noted is subject the BSD                          */
/*  two-clause license in the LICENSE file.                                              */
/*                                                                                       */
/*  SPDX-License-Identifier: BSD-2-Clause                                                */
/*=======================================================================================*/

function clause currentlyEnabled(Ext_Smstateen) = hartSupports(Ext_Smstateen)
function clause currentlyEnabled(Ext_Ssstateen) = hartSupports(Ext_Ssstateen)

function enable_mstateen() -> bool = hartSupports(Ext_Smstateen)
function enable_sstateen() -> bool = currentlyEnabled(Ext_S) & (currentlyEnabled(Ext_Smstateen) | currentlyEnabled(Ext_Ssstateen))
function enable_hstateen() -> bool = false & (currentlyEnabled(Ext_Smstateen) | currentlyEnabled(Ext_Ssstateen))

bitfield Mstateen0 : bits(64) = {
  SE0     : 63,
  ENVCFG  : 62,

  CSRIND  : 60,
  AIA     : 59,
  IMSIC   : 58,
  CONTEXT : 57,
  P1P13   : 56,
  P1P14   : 55,
  CTR     : 54,

  JVT     : 2,
  FCSR    : 1,
  C       : 0,
}

// TODO: This needs to be modified once support Hypervisor is added
// see https://github.com/riscv/sail-riscv/pull/910#discussion_r2070685435
function enable_SE0() -> bool = currentlyEnabled(Ext_S) | misa[F] == 0b0

function legalize_mstateen0(m : Mstateen0, v : bits(64)) -> Mstateen0 = {
  let v = Mk_Mstateen0(v);

  [m with
    SE0     = if enable_SE0() then v[SE0] else 0b0,
    ENVCFG  = if currentlyEnabled(Ext_S) then v[ENVCFG] else 0b0,

    CSRIND  = 0b0, // Not implemented yet
    AIA     = 0b0, // Not implemented yet
    IMSIC   = 0b0, // Not implemented yet
    CONTEXT = 0b0, // Not implemented yet
    P1P13   = 0b0, // Not implemented yet
    P1P14   = 0b0, // Not implemented yet
    CTR     = 0b0, // Not implemented yet

    JVT     = 0b0, // Not implemented yet
    FCSR    = if misa[F] == 0b1 then 0b0 else v[FCSR],
    C       = 0b0,
  ];
}

register mstateen0 : Mstateen0 = legalize_mstateen0(Mk_Mstateen0(zeros()), zeros())

mapping clause csr_name_map = 0x30C  <-> "mstateen0"
mapping clause csr_name_map = 0x31C  <-> "mstateen0h"

function clause is_CSR_defined(0x30C) = enable_mstateen()
function clause is_CSR_defined(0x31C) = enable_mstateen() & (xlen == 32)

function clause read_CSR(0x30C) = mstateen0.bits[xlen - 1 .. 0]
function clause read_CSR(0x31C if xlen == 32) = mstateen0.bits[63 .. 32]

function clause write_CSR((0x30C, value) if xlen == 32) = { mstateen0 = legalize_mstateen0(mstateen0, mstateen0.bits[63 .. 32] @ value); mstateen0.bits[31 .. 0] }
function clause write_CSR((0x30C, value) if xlen == 64) = { mstateen0 = legalize_mstateen0(mstateen0, value); mstateen0.bits }
function clause write_CSR((0x31C, value) if xlen == 32) = { mstateen0 = legalize_mstateen0(mstateen0, value @ mstateen0.bits[31 .. 0]); mstateen0.bits[63 .. 32] }

bitfield Mstateen1 : bits(64) = {
  SE1 : 63, // There is no official name for bit 63 yet
}

function legalize_mstateen1(m : Mstateen1, v : bits(64)) -> Mstateen1 = {
  let v = Mk_Mstateen1(v);

  [m with
    SE1 = 0b0
  ];
}

register mstateen1 : Mstateen1 = legalize_mstateen1(Mk_Mstateen1(zeros()), zeros())

mapping clause csr_name_map = 0x30D  <-> "mstateen1"
mapping clause csr_name_map = 0x31D  <-> "mstateen1h"

function clause is_CSR_defined(0x30D) = enable_mstateen()
function clause is_CSR_defined(0x31D) = enable_mstateen() & (xlen == 32)

function clause read_CSR(0x30D) = mstateen1.bits[xlen - 1 .. 0]
function clause read_CSR(0x31D if xlen == 32) = mstateen1.bits[63 .. 32]

function clause write_CSR((0x30D, value) if xlen == 32) = { mstateen1 = legalize_mstateen1(mstateen1, mstateen1.bits[63 .. 32] @ value); mstateen1.bits[31 .. 0] }
function clause write_CSR((0x30D, value) if xlen == 64) = { mstateen1 = legalize_mstateen1(mstateen1, value); mstateen1.bits }
function clause write_CSR((0x31D, value) if xlen == 32) = { mstateen1 = legalize_mstateen1(mstateen1, value @ mstateen1.bits[31 .. 0]); mstateen1.bits[63 .. 32] }

bitfield Mstateen2 : bits(64) = {
  SE2 : 63, // There is no official name for bit 63 yet
}

function legalize_mstateen2(m : Mstateen2, v : bits(64)) -> Mstateen2 = {
  let v = Mk_Mstateen2(v);

  [m with
    SE2 = 0b0
  ];
}

register mstateen2 : Mstateen2 = legalize_mstateen2(Mk_Mstateen2(zeros()), zeros())

mapping clause csr_name_map = 0x30E  <-> "mstateen2"
mapping clause csr_name_map = 0x31E  <-> "mstateen2h"

function clause is_CSR_defined(0x30E) = enable_mstateen()
function clause is_CSR_defined(0x31E) = enable_mstateen() & (xlen == 32)

function clause read_CSR(0x30E) = mstateen2.bits[xlen - 1 .. 0]
function clause read_CSR(0x31E if xlen == 32) = mstateen2.bits[63 .. 32]

function clause write_CSR((0x30E, value) if xlen == 32) = { mstateen2 = legalize_mstateen2(mstateen2, mstateen2.bits[63 .. 32] @ value); mstateen2.bits[31 .. 0] }
function clause write_CSR((0x30E, value) if xlen == 64) = { mstateen2 = legalize_mstateen2(mstateen2, value); mstateen2.bits }
function clause write_CSR((0x31E, value) if xlen == 32) = { mstateen2 = legalize_mstateen2(mstateen2, value @ mstateen2.bits[31 .. 0]); mstateen2.bits[63 .. 32] }

bitfield Mstateen3 : bits(64) = {
  SE3 : 63, // There is no official name for bit 63 yet
}

function legalize_mstateen3(m : Mstateen3, v : bits(64)) -> Mstateen3 = {
  let v = Mk_Mstateen3(v);

  [m with
    SE3 = 0b0
  ];
}

register mstateen3 : Mstateen3 = legalize_mstateen3(Mk_Mstateen3(zeros()), zeros())

mapping clause csr_name_map = 0x30F  <-> "mstateen3"
mapping clause csr_name_map = 0x31F  <-> "mstateen3h"

function clause is_CSR_defined(0x30F) = enable_mstateen()
function clause is_CSR_defined(0x31F) = enable_mstateen() & (xlen == 32)

function clause read_CSR(0x30F) = mstateen3.bits[xlen - 1 .. 0]
function clause read_CSR(0x31F if xlen == 32) = mstateen3.bits[63 .. 32]

function clause write_CSR((0x30F, value) if xlen == 32) = { mstateen3 = legalize_mstateen3(mstateen3, mstateen3.bits[63 .. 32] @ value); mstateen3.bits[31 .. 0] }
function clause write_CSR((0x30F, value) if xlen == 64) = { mstateen3 = legalize_mstateen3(mstateen3, value); mstateen3.bits }
function clause write_CSR((0x31F, value) if xlen == 32) = { mstateen3 = legalize_mstateen3(mstateen3, value @ mstateen3.bits[31 .. 0]); mstateen3.bits[63 .. 32] }

function get_mstateen(idx : {0, 1, 2, 3}) -> (bits(64)) = {
  if not(enable_mstateen()) then 0xFFFFFFFFFFFFFFFF
  else match idx {
    0 => mstateen0.bits,
    1 => mstateen1.bits,
    2 => mstateen2.bits,
    3 => mstateen3.bits,
  }
}

bitfield Hstateen0 : bits(64) = {
  SE0     : 63,
  ENVCFG  : 62,

  CSRIND  : 60,
  AIA     : 59,
  IMSIC   : 58,
  CONTEXT : 57,

  CTR     : 54,

  JVT     : 2,
  FCSR    : 1,
  C       : 0,
}

function legalize_hstateen0(h : Hstateen0, v : bits(64)) -> Hstateen0 = {
  let v = Mk_Hstateen0(v);

  let permission_mask : bits(64) = get_mstateen(0);

  [h with
    SE0     = if permission_mask[63] == bitone then v[SE0] else h[SE0],
    ENVCFG  = if currentlyEnabled(Ext_S) then (if permission_mask[62] == bitone then v[ENVCFG] else h[ENVCFG]) else 0b0,

    CSRIND  = 0b0, // Not implemented yet
    AIA     = 0b0, // Not implemented yet
    IMSIC   = 0b0, // Not implemented yet
    CONTEXT = 0b0, // Not implemented yet

    CTR     = 0b0, // Not implemented yet

    JVT     = 0b0, // Not implemented yet
    FCSR    = if misa[F] == 0b1 then 0b0 else (if permission_mask[1] == bitone then v[FCSR] else h[FCSR]),
    C       = 0b0,
  ];
}

register hstateen0 : Hstateen0 = legalize_hstateen0(Mk_Hstateen0(zeros()), zeros())

mapping clause csr_name_map = 0x60C  <-> "hstateen0"
mapping clause csr_name_map = 0x61C  <-> "hstateen0h"

function clause is_CSR_defined(0x60C) = enable_hstateen()
function clause is_CSR_defined(0x61C) = enable_hstateen() & (xlen == 32)

function clause read_CSR(0x60C) = hstateen0.bits[xlen - 1 .. 0]
function clause read_CSR(0x61C if xlen == 32) = hstateen0.bits[63 .. 32]

function clause write_CSR((0x60C, value) if xlen == 32) = { hstateen0 = legalize_hstateen0(hstateen0, hstateen0.bits[63 .. 32] @ value); hstateen0.bits[31 .. 0] }
function clause write_CSR((0x60C, value) if xlen == 64) = { hstateen0 = legalize_hstateen0(hstateen0, value); hstateen0.bits }
function clause write_CSR((0x61C, value) if xlen == 32) = { hstateen0 = legalize_hstateen0(hstateen0, value @ hstateen0.bits[31 .. 0]); hstateen0.bits[63 .. 32] }

bitfield Hstateen1 : bits(64) = {
  SE1 : 63, // There is no official name for bit 63 yet
}

function legalize_hstateen1(h : Hstateen1, v : bits(64)) -> Hstateen1 = {
  let v = Mk_Hstateen1(v);

  let permission_mask : bits(64) = get_mstateen(1);

  [h with
    SE1 = if permission_mask[63] == bitone then v[SE1] else h[SE1],
  ];
}

register hstateen1 : Hstateen1 = legalize_hstateen1(Mk_Hstateen1(zeros()), zeros())

mapping clause csr_name_map = 0x60D  <-> "hstateen1"
mapping clause csr_name_map = 0x61D  <-> "hstateen1h"

function clause is_CSR_defined(0x60D) = enable_hstateen()
function clause is_CSR_defined(0x61D) = enable_hstateen() & (xlen == 32)

function clause read_CSR(0x60D) = hstateen1.bits[xlen - 1 .. 0]
function clause read_CSR(0x61D if xlen == 32) = hstateen1.bits[63 .. 32]

function clause write_CSR((0x60D, value) if xlen == 32) = { hstateen1 = legalize_hstateen1(hstateen1, hstateen1.bits[63 .. 32] @ value); hstateen1.bits[31 .. 0] }
function clause write_CSR((0x60D, value) if xlen == 64) = { hstateen1 = legalize_hstateen1(hstateen1, value); hstateen1.bits }
function clause write_CSR((0x61D, value) if xlen == 32) = { hstateen1 = legalize_hstateen1(hstateen1, value @ hstateen1.bits[31 .. 0]); hstateen1.bits[63 .. 32] }

bitfield Hstateen2 : bits(64) = {
  SE2 : 63, // There is no official name for bit 63 yet
}

function legalize_hstateen2(h : Hstateen2, v : bits(64)) -> Hstateen2 = {
  let v = Mk_Hstateen2(v);

  let permission_mask : bits(64) = get_mstateen(2);

  [h with
    SE2 = if permission_mask[63] == bitone then v[SE2] else h[SE2],
  ];
}

register hstateen2 : Hstateen2 = legalize_hstateen2(Mk_Hstateen2(zeros()), zeros())

mapping clause csr_name_map = 0x60E  <-> "hstateen2"
mapping clause csr_name_map = 0x61E  <-> "hstateen2h"

function clause is_CSR_defined(0x60E) = enable_hstateen()
function clause is_CSR_defined(0x61E) = enable_hstateen() & (xlen == 32)

function clause read_CSR(0x60E) = hstateen2.bits[xlen - 1 .. 0]
function clause read_CSR(0x61E if xlen == 32) = hstateen2.bits[63 .. 32]

function clause write_CSR((0x60E, value) if xlen == 32) = { hstateen2 = legalize_hstateen2(hstateen2, hstateen2.bits[63 .. 32] @ value); hstateen2.bits[31 .. 0] }
function clause write_CSR((0x60E, value) if xlen == 64) = { hstateen2 = legalize_hstateen2(hstateen2, value); hstateen2.bits }
function clause write_CSR((0x61E, value) if xlen == 32) = { hstateen2 = legalize_hstateen2(hstateen2, value @ hstateen2.bits[31 .. 0]); hstateen2.bits[63 .. 32] }

bitfield Hstateen3 : bits(64) = {
  SE3 : 63, // There is no official name for bit 63 yet
}

function legalize_hstateen3(h : Hstateen3, v : bits(64)) -> Hstateen3 = {
  let v = Mk_Hstateen3(v);

  let permission_mask : bits(64) = get_mstateen(3);

  [h with
    SE3 = if permission_mask[63] == bitone then v[SE3] else h[SE3],
  ];
}

register hstateen3 : Hstateen3 = legalize_hstateen3(Mk_Hstateen3(zeros()), zeros())

mapping clause csr_name_map = 0x60F  <-> "hstateen3"
mapping clause csr_name_map = 0x61F  <-> "hstateen3h"

function clause is_CSR_defined(0x60F) = enable_hstateen()
function clause is_CSR_defined(0x61F) = enable_hstateen() & (xlen == 32)

function clause read_CSR(0x60F) = hstateen3.bits[xlen - 1 .. 0]
function clause read_CSR(0x61F if xlen == 32) = hstateen3.bits[63 .. 32]

function clause write_CSR((0x60F, value) if xlen == 32) = { hstateen3 = legalize_hstateen3(hstateen3, hstateen3.bits[63 .. 32] @ value); hstateen3.bits[31 .. 0] }
function clause write_CSR((0x60F, value) if xlen == 64) = { hstateen3 = legalize_hstateen3(hstateen3, value); hstateen3.bits }
function clause write_CSR((0x61F, value) if xlen == 32) = { hstateen3 = legalize_hstateen3(hstateen3, value @ hstateen3.bits[31 .. 0]); hstateen3.bits[63 .. 32] }

function get_hstateen(idx : {0, 1, 2, 3}) -> (bits(64)) = {
  if not(enable_hstateen()) then 0xFFFFFFFFFFFFFFFF
  else match idx {
    0 => hstateen0.bits,
    1 => hstateen1.bits,
    2 => hstateen2.bits,
    3 => hstateen3.bits,
  }
}

bitfield Sstateen0 : bits(32) = {
  JVT  : 2,
  FCSR : 1,
  C    : 0,
}

function legalize_sstateen0(s : Sstateen0, v : bits(32)) -> Sstateen0 = {
  let v = Mk_Sstateen0(v);

  /* TODO: The current handling of hstateen is incorrect.
   * This will need to be addressed when Hypervisor support is implemented.
   * For now, it effectively does nothing and has no impact on masking.
   */
  let permission_mask : bits(64) = get_mstateen(0) & get_hstateen(0);

  [s with
    JVT  = 0b0, // Not implemented yet
    FCSR = if misa[F] == 0b1 then 0b0 else (if permission_mask[1] == bitone then v[FCSR] else s[FCSR]),
    C    = 0b0,
  ];
}

register sstateen0 : Sstateen0 = legalize_sstateen0(Mk_Sstateen0(zeros()), zeros())
mapping clause csr_name_map = 0x10C  <-> "sstateen0"
function clause is_CSR_defined(0x10C) = enable_sstateen()
function clause read_CSR(0x10C) = zero_extend(sstateen0.bits)
function clause write_CSR(0x10C, value) = { sstateen0 = legalize_sstateen0(sstateen0, value[31 .. 0]); zero_extend(sstateen0.bits) }

type Sstateen1 = bits(32)

function legalize_sstateen1(s : Sstateen1, v : bits(32)) -> Sstateen1 = {
  s
}

register sstateen1 : Sstateen1 = legalize_sstateen1(zeros(), zeros())
mapping clause csr_name_map = 0x10D  <-> "sstateen1"
function clause is_CSR_defined(0x10D) = enable_sstateen()
function clause read_CSR(0x10D) = zero_extend(sstateen1)
function clause write_CSR(0x10D, value) = { sstateen1 = legalize_sstateen1(sstateen1, value[31 .. 0]); zero_extend(sstateen1) }

type Sstateen2 = bits(32)

function legalize_sstateen2(s : Sstateen2, v : bits(32)) -> Sstateen2 = {
  s
}

register sstateen2 : Sstateen2 = legalize_sstateen2(zeros(), zeros())
mapping clause csr_name_map = 0x10E  <-> "sstateen2"
function clause is_CSR_defined(0x10E) = enable_sstateen()
function clause read_CSR(0x10E) = zero_extend(sstateen2)
function clause write_CSR(0x10E, value) = { sstateen2 = legalize_sstateen2(sstateen2, value[31 .. 0]); zero_extend(sstateen2) }

type Sstateen3 = bits(32)

function legalize_sstateen3(s : Sstateen3, v : bits(32)) -> Sstateen3 = {
  s
}

register sstateen3 : Sstateen3 = legalize_sstateen3(zeros(), zeros())
mapping clause csr_name_map = 0x10F  <-> "sstateen3"
function clause is_CSR_defined(0x10F) = enable_sstateen()
function clause read_CSR(0x10F) = zero_extend(sstateen3)
function clause write_CSR(0x10F, value) = { sstateen3 = legalize_sstateen3(sstateen3, value[31 .. 0]); zero_extend(sstateen3) }

function get_sstateen(idx : {0, 1, 2, 3}) -> bits(64) = {
  if not(enable_sstateen()) then 0xFFFFFFFFFFFFFFFF
  else match idx {
    // Expanding sstateen from 32 to 64 bits simplifies permission mask handling.
    0 => 0xFFFFFFFF @ sstateen0.bits,
    // sstateen1, stateen2 and sstateen3 are read-only zero for now
    1 => 0xFFFFFFFF @ 0x00000000,
    2 => 0xFFFFFFFF @ 0x00000000,
    3 => 0xFFFFFFFF @ 0x00000000,
  }
}

mapping stateen_idx : {0, 1, 2, 3} <-> bits(4) = {
  0 <-> 0b1100, // 0xC
  1 <-> 0b1101, // 0xD
  2 <-> 0b1110, // 0xE
  3 <-> 0b1111, // 0xF
}

enum stateen_control_bits = {STATEEN_FCSR, STATEEN_ENVCFG, STATEEN_SE}

mapping csr_permission_idx : stateen_control_bits <-> {1, 62, 63} = {
  STATEEN_SE     <-> 63,
  /* stateen0 */
  STATEEN_ENVCFG <-> 62,
  STATEEN_FCSR   <-> 1,
}

/* Computes a bit-level permission mask by performing a bitwise AND across the
 * stateen bits from all higher privilege modes. Access to a corresponding bitfield
 * is granted only if each bit is set to 1 in the same bitfield of the stateen
 * registers at all higher privilege modes.
 */
function get_stateen_permission_mask (idx : {0, 1, 2, 3}) -> bits(64) = {
  let mstateen = get_mstateen(idx);
  let hstateen = get_hstateen(idx);
  let sstateen = get_sstateen(idx);
  match cur_privilege {
    Machine    => 0xFFFFFFFFFFFFFFFF,
    Supervisor => mstateen & hstateen,
    User       => mstateen & hstateen & sstateen,
  }
}

/*
 * Maps a CSR address to the corresponding stateen permission bit and stateen id
 *
 * Returns an optional tuple:
 *   (stateen bitfield, stateen id)
 *
 * Add more mappings as needed
 */
function csr_to_stateen_bit(csr : csreg) -> option((stateen_control_bits, {0, 1, 2, 3})) = {
  match csr {
    /* stateen0 */
    0x10C /* sstateen0 */ => Some((STATEEN_SE, 0)),
    0x10A /* senvcfg   */ => Some((STATEEN_ENVCFG, 0)),
    0x001 /* fflags    */ => if currentlyEnabled(Ext_Zfinx) then Some((STATEEN_FCSR, 0)) else None(),
    0x002 /* frm       */ => if currentlyEnabled(Ext_Zfinx) then Some((STATEEN_FCSR, 0)) else None(),
    0x003 /* fcsr      */ => if currentlyEnabled(Ext_Zfinx) then Some((STATEEN_FCSR, 0)) else None(),

    /* stateen1 */
    0x10D /* sstateen1 */ => Some((STATEEN_SE, 1)),

    /* stateen2 */
    0x10E /* sstateen2 */ => Some((STATEEN_SE, 2)),

    /* stateen3 */
    0x10F /* sstateen3 */ => Some((STATEEN_SE, 3)),

    _ => None(),
  }
}

/*
 * Verifies whether access to CSRs protected by the Smstateen or Ssstateen
 * extensions is allowed at the current privilege level.
 */
function check_CSR_stateen_permission(csr : csreg) -> bool = {
  match csr_to_stateen_bit(csr) {
    Some((bit_idx, stateen_register_index)) => {
      let mask = get_stateen_permission_mask(stateen_register_index);
      mask[csr_permission_idx(bit_idx)] == bitone
    },
    None() => true
  }
}

/*
 * Check if floating-point instructions using X registers
 * are permitted in the given privilege mode.
 *
 * Note: Machine mode can always perform floating-point instructions
 */
function check_fp_stateen() -> bool = {
  let mask = get_stateen_permission_mask(0);
  mask[csr_permission_idx(STATEEN_FCSR)] == bitone
}

function reset_stateen() -> unit = {
  if enable_mstateen() then {
    mstateen0 = Mk_Mstateen0(zeros());
    mstateen1 = Mk_Mstateen1(zeros());
    mstateen2 = Mk_Mstateen2(zeros());
    mstateen3 = Mk_Mstateen3(zeros());
  }
}
