//=======================================================================================
// This Sail RISC-V architecture model, comprising all files and
// directories except where otherwise noted is subject the BSD
// two-clause license in the LICENSE file.
//
// SPDX-License-Identifier: BSD-2-Clause
//=======================================================================================

function clause currentlyEnabled(Ext_Smstateen) = hartSupports(Ext_Smstateen) & currentlyEnabled(Ext_Zicsr)
function clause currentlyEnabled(Ext_Ssstateen) = hartSupports(Ext_Ssstateen) & currentlyEnabled(Ext_Zicsr)

function is_mstateen_accessible() -> bool = hartSupports(Ext_Smstateen)
function is_hstateen_accessible() -> bool = currentlyEnabled(Ext_H) & (currentlyEnabled(Ext_Smstateen) | currentlyEnabled(Ext_Ssstateen))
function is_sstateen_accessible() -> bool = currentlyEnabled(Ext_S) & (currentlyEnabled(Ext_Smstateen) | currentlyEnabled(Ext_Ssstateen))

termination_measure is_hstateen_accessible() = 5 // > Ext_H
termination_measure is_sstateen_accessible() = 2 // > Ext_S

enum stateen_bit = {STATEEN_FCSR, STATEEN_ENVCFG, STATEEN_SE}

mapping stateen_bit_index : stateen_bit <-> range(0, 63) = {
  STATEEN_SE     <-> 63,
  STATEEN_ENVCFG <-> 62,
  STATEEN_FCSR   <-> 1,
}

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

bitfield Mstateen1 : bits(64) = { SE1 : 63 }
bitfield Mstateen2 : bits(64) = { SE2 : 63 }
bitfield Mstateen3 : bits(64) = { SE3 : 63 }

register mstateen0 : Mstateen0 = Mk_Mstateen0(zeros())
register mstateen1 : Mstateen1 = Mk_Mstateen1(zeros())
register mstateen2 : Mstateen2 = Mk_Mstateen2(zeros())
register mstateen3 : Mstateen3 = Mk_Mstateen3(zeros())

private function get_mstateen(idx : range(0, 3)) -> bits(64) = {
  if not(is_mstateen_accessible()) then ones()
  else match idx {
    0 => mstateen0.bits,
    1 => mstateen1.bits,
    2 => mstateen2.bits,
    3 => mstateen3.bits,
  }
}

// TODO: Update when Zcmt is implemented (JVT bit)
private function is_mstateen_SE0_readonly_zero() -> bool = {
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

function legalize_mstateen1(m : Mstateen1, _v : bits(64)) -> Mstateen1 = { m }
function legalize_mstateen2(m : Mstateen2, _v : bits(64)) -> Mstateen2 = { m }
function legalize_mstateen3(m : Mstateen3, _v : bits(64)) -> Mstateen3 = { m }

register hstateen0 : Mstateen0 = Mk_Mstateen0(zeros())
register hstateen1 : Mstateen1 = Mk_Mstateen1(zeros())
register hstateen2 : Mstateen2 = Mk_Mstateen2(zeros())
register hstateen3 : Mstateen3 = Mk_Mstateen3(zeros())

private function get_hstateen(idx : range(0, 3)) -> bits(64) = {
  if not(is_hstateen_accessible()) then ones()
  else match idx {
    0 => hstateen0.bits,
    1 => hstateen1.bits,
    2 => hstateen2.bits,
    3 => hstateen3.bits,
  }
}

termination_measure get_hstateen(_) = 6 // > is_hstateen_accessible

function get_hstateen_mask(idx : range(0, 3)) -> bits(64) = get_mstateen(idx)

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

bitfield Sstateen0 : bits(32) = {
  JVT  : 2,
  FCSR : 1,
  C    : 0,
}

bitfield Sstateen1 : bits(32) = {}
bitfield Sstateen2 : bits(32) = {}
bitfield Sstateen3 : bits(32) = {}

register sstateen0 : Sstateen0 = Mk_Sstateen0(zeros())
register sstateen1 : Sstateen1 = Mk_Sstateen1(zeros())
register sstateen2 : Sstateen2 = Mk_Sstateen2(zeros())
register sstateen3 : Sstateen3 = Mk_Sstateen3(zeros())

private function get_sstateen(idx : range(0, 3)) -> bits(64) =
  0xFFFFFFFF @ (
    if not(is_sstateen_accessible()) then ones()
    else match idx {
      0 => sstateen0.bits,
      1 => sstateen1.bits,
      2 => sstateen2.bits,
      3 => sstateen3.bits,
    }
  )

termination_measure get_sstateen(_) = 3 // > is_sstateen_accessible

function get_sstateen_mask(idx : range(0, 3)) -> bits(64) = get_mstateen(idx) & get_hstateen(idx)

function legalize_sstateen0(s : Sstateen0, v : bits(32)) -> Sstateen0 = {
  let v = Mk_Sstateen0(v);
  let mask = get_sstateen_mask(0);
  let legalized = [s with
    FCSR = if misa[F] == 0b1 then 0b0 else v[FCSR],
  ];
  Mk_Sstateen0(legalized.bits & mask[31..0])
}

function legalize_sstateen1(s : Sstateen1, _v : bits(32)) -> Sstateen1 = { s }
function legalize_sstateen2(s : Sstateen2, _v : bits(32)) -> Sstateen2 = { s }
function legalize_sstateen3(s : Sstateen3, _v : bits(32)) -> Sstateen3 = { s }

function check_stateen_bit(priv : Privilege, bit_idx : stateen_bit, stateen_reg : range(0, 3)) -> bool = {
  let mask : bits(64) = match priv {
    Machine           => ones(),
    Supervisor        => get_mstateen(stateen_reg),
    User              => get_mstateen(stateen_reg) & get_sstateen(stateen_reg),
    VirtualSupervisor => get_mstateen(stateen_reg) & get_hstateen(stateen_reg),
    VirtualUser       => get_mstateen(stateen_reg) & get_hstateen(stateen_reg) & get_sstateen(stateen_reg),
  };
  mask[stateen_bit_index(bit_idx)] == bitone
}

termination_measure check_stateen_bit(_, _, _) = 7 // > get_hstateen

function is_zfinx_enabled_by_stateen() -> bool = check_stateen_bit(cur_privilege, STATEEN_FCSR, 0)

termination_measure is_zfinx_enabled_by_stateen() = 8 // > check_stateen_bit

function reset_stateen() -> unit = {
  mstateen0.bits = zeros();
  mstateen1.bits = zeros();
  mstateen2.bits = zeros();
  mstateen3.bits = zeros();
}
