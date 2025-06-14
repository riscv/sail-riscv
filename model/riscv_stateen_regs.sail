/*=======================================================================================*/
/*  This Sail RISC-V architecture model, comprising all files and                        */
/*  directories except where otherwise noted is subject the BSD                          */
/*  two-clause license in the LICENSE file.                                              */
/*                                                                                       */
/*  SPDX-License-Identifier: BSD-2-Clause                                                */
/*=======================================================================================*/

function enable_mstateen() -> bool = hartSupports(Ext_Smstateen)
function enable_sstateen() -> bool = hartSupports(Ext_S) & (hartSupports(Ext_Smstateen) | hartSupports(Ext_Ssstateen))
// Hypervisor extension is not implemented yet
function enable_hstateen() -> bool = false & (hartSupports(Ext_Smstateen) | hartSupports(Ext_Ssstateen))

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

function legalize_mstateen0(m : Mstateen0, v : bits(64)) -> Mstateen0 = {
  let v = Mk_Mstateen0(v);
  // mstateen0 = [mstateen0 with
  //   SE0     = if v[SE0] == 0b0 then 0b0 else mstateen0[SE0],
  //   ENVCFG  = if v[ENVCFG] == 0b0 then 0b0 else mstateen0[ENVCFG],

  //   CSRIND  = if v[CSRIND] == 0b0 then 0b0 else mstateen0[CSRIND],
  //   AIA     = if v[AIA] == 0b0 then 0b0 else mstateen0[AIA],
  //   IMSIC   = if v[IMSIC] == 0b0 then 0b0 else mstateen0[IMSIC],
  //   CONTEXT = if v[CONTEXT] == 0b0 then 0b0 else mstateen0[CONTEXT],
  //   P1P13   = if v[P1P13] == 0b0 then 0b0 else mstateen0[P1P13],
  //   P1P14   = if v[P1P14] == 0b0 then 0b0 else mstateen0[P1P14],
  //   CTR     = if v[CTR] == 0b0 then 0b0 else mstateen0[CTR],

  //   JVT     = if v[JVT] == 0b0 then 0b0 else mstateen0[JVT],
  //   FCSR    = if misa[F] == 0b1 then if v[FCSR] == 0b0 then 0b0 else mstateen0[FCSR] else 0b0,
  //   C       = if v[C] == 0b0 then 0b0 else mstateen0[C],
  // ];
  [m with
    SE0     = v[SE0],
    ENVCFG  = v[ENVCFG],

    CSRIND  = v[CSRIND],
    AIA     = v[AIA],
    IMSIC   = v[IMSIC],
    CONTEXT = v[CONTEXT],
    P1P13   = v[P1P13],
    P1P14   = v[P1P14],
    CTR     = v[CTR],

    JVT     = v[JVT],
    FCSR    = if misa[F] == 0b1 then v[FCSR] else 0b0,
    C       = v[C],
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

type Mstateen1 = bits(64)

function legalize_mstateen1(m : Mstateen1, v : bits(64)) -> Mstateen1 = {
  m
}

register mstateen1 : Mstateen1 = legalize_mstateen1(zeros(), zeros())

mapping clause csr_name_map = 0x30D  <-> "mstateen1"
mapping clause csr_name_map = 0x31D  <-> "mstateen1h"

function clause is_CSR_defined(0x30D) = enable_mstateen()
function clause is_CSR_defined(0x31D) = enable_mstateen() & (xlen == 32)

function clause read_CSR(0x30D) = mstateen1[xlen - 1 .. 0]
function clause read_CSR(0x31D if xlen == 32) = mstateen1[63 .. 32]

function clause write_CSR((0x30D, value) if xlen == 32) = { mstateen1 = legalize_mstateen1(mstateen1, mstateen1[63 .. 32] @ value); mstateen1[31 .. 0] }
function clause write_CSR((0x30D, value) if xlen == 64) = { mstateen1 = legalize_mstateen1(mstateen1, value); mstateen1 }
function clause write_CSR((0x31D, value) if xlen == 32) = { mstateen1 = legalize_mstateen1(mstateen1, value @ mstateen1[31 .. 0]); mstateen1[63 .. 32] }

type Mstateen2 = bits(64)

function legalize_mstateen2(m : Mstateen2, v : bits(64)) -> Mstateen2 = {
  m
}

register mstateen2 : Mstateen2 = legalize_mstateen2(zeros(), zeros())

mapping clause csr_name_map = 0x30E  <-> "mstateen2"
mapping clause csr_name_map = 0x31E  <-> "mstateen2h"

function clause is_CSR_defined(0x30E) = enable_mstateen()
function clause is_CSR_defined(0x31E) = enable_mstateen() & (xlen == 32)

function clause read_CSR(0x30E) = mstateen2[xlen - 1 .. 0]
function clause read_CSR(0x31E if xlen == 32) = mstateen2[63 .. 32]

function clause write_CSR((0x30E, value) if xlen == 32) = { mstateen2 = legalize_mstateen2(mstateen2, mstateen2[63 .. 32] @ value); mstateen2[31 .. 0] }
function clause write_CSR((0x30E, value) if xlen == 64) = { mstateen2 = legalize_mstateen2(mstateen2, value); mstateen2 }
function clause write_CSR((0x31E, value) if xlen == 32) = { mstateen2 = legalize_mstateen2(mstateen2, value @ mstateen2[31 .. 0]); mstateen2[63 .. 32] }

type Mstateen3 = bits(64)

function legalize_mstateen3(m : Mstateen3, v : bits(64)) -> Mstateen3 = {
  m
}

register mstateen3 : Mstateen3 = legalize_mstateen3(zeros(), zeros())

mapping clause csr_name_map = 0x30F  <-> "mstateen3"
mapping clause csr_name_map = 0x31F  <-> "mstateen3h"

function clause is_CSR_defined(0x30F) = enable_mstateen()
function clause is_CSR_defined(0x31F) = enable_mstateen() & (xlen == 32)

function clause read_CSR(0x30F) = mstateen3[xlen - 1 .. 0]
function clause read_CSR(0x31F if xlen == 32) = mstateen3[63 .. 32]

function clause write_CSR((0x30F, value) if xlen == 32) = { mstateen3 = legalize_mstateen3(mstateen3, mstateen3[63 .. 32] @ value); mstateen3[31 .. 0] }
function clause write_CSR((0x30F, value) if xlen == 64) = { mstateen3 = legalize_mstateen3(mstateen3, value); mstateen3 }
function clause write_CSR((0x31F, value) if xlen == 32) = { mstateen3 = legalize_mstateen3(mstateen3, value @ mstateen3[31 .. 0]); mstateen3[63 .. 32] }

bitfield Sstateen0 : bits(32) = {
    JVT  : 2,
    FCSR : 1,
    C    : 0,
}

function legalize_sstateen0(s : Sstateen0, v : bits(32)) -> Sstateen0 = {
  let v = Mk_Sstateen0(v);
  if mstateen0[SE0] == 0b0 then {
    s
  } else {
    [s with
      JVT  = if mstateen0[JVT]  == 0b0 then v[JVT] else 0b0,
      FCSR = if mstateen0[FCSR] == 0b0 & misa[F] == 0b1 then v[FCSR] else 0b0,
      C    = if mstateen0[C]    == 0b0 then v[C]   else 0b0,
    ]
  }
}

// For the supervisor-level sstateen registers, high-half CSRs are not added at this time
// because it is expected the upper 32 bits of these registers will always be zeros
register sstateen0 : Sstateen0 = legalize_sstateen0(Mk_Sstateen0(zeros()), zeros())
mapping clause csr_name_map = 0x10C  <-> "sstateen0"
function clause is_CSR_defined(0x10C) = enable_sstateen()
function clause read_CSR(0x10C) = zero_extend(sstateen0.bits)
function clause write_CSR(0x10C, value) = { sstateen0 = legalize_sstateen0(sstateen0, value[31 .. 0]); zero_extend(sstateen0.bits) }

type Sstateen1 = bits(32)

function legalize_sstateen1(c : Sstateen1, v : bits(32)) -> Sstateen1 = {
  c
}

register sstateen1 : Sstateen1 = legalize_sstateen1(zeros(), zeros())
mapping clause csr_name_map = 0x10D  <-> "sstateen1"
function clause is_CSR_defined(0x10D) = enable_sstateen()
function clause read_CSR(0x10D) = zero_extend(sstateen1)
function clause write_CSR(0x10D, value) = { sstateen1 = legalize_sstateen1(sstateen1, value[31 .. 0]); zero_extend(sstateen1) }

type Sstateen2 = bits(32)

function legalize_sstateen2(c : Sstateen2, v : bits(32)) -> Sstateen2 = {
  c
}

register sstateen2 : Sstateen2 = legalize_sstateen2(zeros(), zeros())
mapping clause csr_name_map = 0x10E  <-> "sstateen2"
function clause is_CSR_defined(0x10E) = enable_sstateen()
function clause read_CSR(0x10E) = zero_extend(sstateen2)
function clause write_CSR(0x10E, value) = { sstateen2 = legalize_sstateen2(sstateen2, value[31 .. 0]); zero_extend(sstateen2) }

type Sstateen3 = bits(32)

function legalize_sstateen3(c : Sstateen3, v : bits(32)) -> Sstateen3 = {
  c
}

register sstateen3 : Sstateen3 = legalize_sstateen3(zeros(), zeros())
mapping clause csr_name_map = 0x10F  <-> "sstateen3"
function clause is_CSR_defined(0x10F) = enable_sstateen()
function clause read_CSR(0x10F) = zero_extend(sstateen3)
function clause write_CSR(0x10F, value) = { sstateen3 = legalize_sstateen3(sstateen3, value[31 .. 0]); zero_extend(sstateen3) }

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
  if mstateen0[SE0] == 0b0 then {
    h
  } else {
    [ h with
      SE0     = if mstateen0[SE0]     == 0b0 then v[SE0]     else 0b0,
      ENVCFG  = if mstateen0[ENVCFG]  == 0b0 then v[ENVCFG]  else 0b0,

      CSRIND  = if mstateen0[CSRIND]  == 0b0 then v[CSRIND]  else 0b0,
      AIA     = if mstateen0[AIA]     == 0b0 then v[AIA]     else 0b0,
      IMSIC   = if mstateen0[IMSIC]   == 0b0 then v[IMSIC]   else 0b0,
      CONTEXT = if mstateen0[CONTEXT] == 0b0 then v[CONTEXT] else 0b0,
      CTR     = if mstateen0[CTR]     == 0b0 then v[CTR]     else 0b0,

      JVT     = if mstateen0[JVT]     == 0b0 then v[JVT] else 0b0,
      FCSR    = if mstateen0[FCSR] == 0b0 & misa[F] == 0b1 then v[FCSR] else 0b0,
      C       = if mstateen0[C]       == 0b0 then v[C]   else 0b0,
    ]
  }
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

type Hstateen1 = bits(64)

function legalize_hstateen1(h : Hstateen1, v : bits(64)) -> Hstateen1 = {
  h
}

register hstateen1 : Hstateen1 = legalize_hstateen1(zeros(), zeros())

mapping clause csr_name_map = 0x60D  <-> "hstateen1"
mapping clause csr_name_map = 0x61D  <-> "hstateen1h"

function clause is_CSR_defined(0x60D) = enable_hstateen()
function clause is_CSR_defined(0x61D) = enable_hstateen() & (xlen == 32)

function clause read_CSR(0x60D) = hstateen1[xlen - 1 .. 0]
function clause read_CSR(0x61D if xlen == 32) = hstateen1[63 .. 32]

function clause write_CSR((0x60D, value) if xlen == 32) = { hstateen1 = legalize_hstateen1(hstateen1, hstateen1[63 .. 32] @ value); hstateen1[31 .. 0] }
function clause write_CSR((0x60D, value) if xlen == 64) = { hstateen1 = legalize_hstateen1(hstateen1, value); hstateen1 }
function clause write_CSR((0x61D, value) if xlen == 32) = { hstateen1 = legalize_hstateen1(hstateen1, value @ hstateen1[31 .. 0]); hstateen1[63 .. 32] }

type Hstateen2 = bits(64)

function legalize_hstateen2(h : Hstateen2, v : bits(64)) -> Hstateen2 = {
  h
}

register hstateen2 : Hstateen2 = legalize_hstateen2(zeros(), zeros())

mapping clause csr_name_map = 0x60E  <-> "hstateen2"
mapping clause csr_name_map = 0x61E  <-> "hstateen2h"

function clause is_CSR_defined(0x60E) = enable_hstateen()
function clause is_CSR_defined(0x61E) = enable_hstateen() & (xlen == 32)

function clause read_CSR(0x60E) = hstateen2[xlen - 1 .. 0]
function clause read_CSR(0x61E if xlen == 32) = hstateen2[63 .. 32]

function clause write_CSR((0x60E, value) if xlen == 32) = { hstateen2 = legalize_hstateen2(hstateen2, hstateen2[63 .. 32] @ value); hstateen2[31 .. 0] }
function clause write_CSR((0x60E, value) if xlen == 64) = { hstateen2 = legalize_hstateen2(hstateen2, value); hstateen2 }
function clause write_CSR((0x61E, value) if xlen == 32) = { hstateen2 = legalize_hstateen2(hstateen2, value @ hstateen2[31 .. 0]); hstateen2[63 .. 32] }

type Hstateen3 = bits(64)

function legalize_hstateen3(h : Hstateen3, v : bits(64)) -> Hstateen3 = {
  h
}

register hstateen3 : Hstateen3 = legalize_hstateen3(zeros(), zeros())

mapping clause csr_name_map = 0x60F  <-> "hstateen3"
mapping clause csr_name_map = 0x61F  <-> "hstateen3h"

function clause is_CSR_defined(0x60F) = enable_hstateen()
function clause is_CSR_defined(0x61F) = enable_hstateen() & (xlen == 32)

function clause read_CSR(0x60F) = hstateen3[xlen - 1 .. 0]
function clause read_CSR(0x61F if xlen == 32) = hstateen3[63 .. 32]

function clause write_CSR((0x60F, value) if xlen == 32) = { hstateen3 = legalize_hstateen3(hstateen3, hstateen3[63 .. 32] @ value); hstateen3[31 .. 0] }
function clause write_CSR((0x60F, value) if xlen == 64) = { hstateen3 = legalize_hstateen3(hstateen3, value); hstateen3 }
function clause write_CSR((0x61F, value) if xlen == 32) = { hstateen3 = legalize_hstateen3(hstateen3, value @ hstateen3[31 .. 0]); hstateen3[63 .. 32] }
