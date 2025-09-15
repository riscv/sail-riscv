// =======================================================================================
// This Sail RISC-V architecture model, comprising all files and
// directories except where otherwise noted is subject the BSD
// two-clause license in the LICENSE file.
//
// SPDX-License-Identifier: BSD-2-Clause
// =======================================================================================

// ***************************************************************
// Floating point register file and accessors for F, D extensions
// Floating point CSR and accessors
// ***************************************************************

// Original version written by Rishiyur S. Nikhil, Sept-Oct 2019

// ***************************************************************
// NaN boxing/unboxing.

// Canonical NaNs are used when an invalid boxed value is unboxed.
val canonical_NaN : forall 'n, 'n in {16, 32, 64, 128} . (implicit('n)) -> bits('n)
function canonical_NaN(n) =
  match 'n {
    //     sign  exponent    significand
    16  => 0b0 @ ones(5)  @ 0b1 @ zeros(9),
    32  => 0b0 @ ones(8)  @ 0b1 @ zeros(22),
    64  => 0b0 @ ones(11) @ 0b1 @ zeros(51),
    128 => 0b0 @ ones(15) @ 0b1 @ zeros(111),
  }

// For backwards compatibility with code that existed before the
// generic version above.
function canonical_NaN_H() -> bits(16)  = canonical_NaN(16)
function canonical_NaN_S() -> bits(32)  = canonical_NaN(32)
function canonical_NaN_D() -> bits(64)  = canonical_NaN(64)
function canonical_NaN_Q() -> bits(128) = canonical_NaN(128)

// n-bit writes to a >n-bit floating point register "box" the value
// by prepending 1s, which turn it into a qNaN.
val nan_box : forall 'n 'm, 'n <= 'm . (implicit('m), bits('n)) -> bits('m)
function nan_box(n, x) = ones('m - 'n) @ x

// Except for floating-point transfer instructions (FSn and FMV.n.X),
// n-bit reads of a >n-bit floating point register "unbox" the value stored
// in the register. If the register does not contain a valid boxed value
// then a canonical NaN value is returned instead.
// TODO: Use right-open interval when available. See https://github.com/rems-project/sail/issues/471
val nan_unbox : forall 'n 'm, 'm in {16, 32, 64, 128} & 'n >= 'm . (implicit('m), bits('n)) -> bits('m)
function nan_unbox(m, x) = if 'n == 'm then x else (
  if x['n - 1 .. 'm] == ones() then x['m - 1 .. 0] else canonical_NaN()
)

// ***************************************************************
// Floating point register file

newtype fregidx = Fregidx : bits(5)
newtype fregno = Fregno : range(0, 31)
// identifiers in RVC floating-point instructions
newtype cfregidx = Cfregidx : bits(3)

function fregidx_bits(Fregidx(r) : fregidx) -> bits(5) = r

function cfregidx_to_fregidx (Cfregidx(b) : cfregidx) -> fregidx = Fregidx(0b01 @ b)

mapping encdec_cfreg : cfregidx <-> bits(3) = { Cfregidx(r) <-> r }

// TODO: This is not quite right for having both Zfinx and E, but at least it
// marks the places we need to consider it
function fregidx_to_regidx (Fregidx(b) : fregidx) -> regidx =
  Regidx(trunc(b))

mapping encdec_freg : fregidx <-> bits(5) = { Fregidx(r) <-> r }

val freg_write_callback = pure {cpp: "freg_write_callback"} : (fregidx, flenbits) -> unit
function freg_write_callback(_) = ()

register f0  : fregtype
register f1  : fregtype
register f2  : fregtype
register f3  : fregtype
register f4  : fregtype
register f5  : fregtype
register f6  : fregtype
register f7  : fregtype
register f8  : fregtype
register f9  : fregtype
register f10 : fregtype
register f11 : fregtype
register f12 : fregtype
register f13 : fregtype
register f14 : fregtype
register f15 : fregtype
register f16 : fregtype
register f17 : fregtype
register f18 : fregtype
register f19 : fregtype
register f20 : fregtype
register f21 : fregtype
register f22 : fregtype
register f23 : fregtype
register f24 : fregtype
register f25 : fregtype
register f26 : fregtype
register f27 : fregtype
register f28 : fregtype
register f29 : fregtype
register f30 : fregtype
register f31 : fregtype

function dirty_fd_context() -> unit = {
  assert(hartSupports(Ext_F));
  mstatus[FS] = extStatus_to_bits(Dirty);
  mstatus[SD] = 0b1;
  long_csr_write_callback("mstatus", "mstatush", mstatus.bits);
}

function dirty_fd_context_if_present() -> unit = {
  assert(hartSupports(Ext_F) != hartSupports(Ext_Zfinx));
  if hartSupports(Ext_F) then dirty_fd_context()
}

function rF (Fregno(r) : fregno) -> flenbits = {
  assert(hartSupports(Ext_F));
  let v : fregtype =
    match r {
      0 => f0,
      1 => f1,
      2 => f2,
      3 => f3,
      4 => f4,
      5 => f5,
      6 => f6,
      7 => f7,
      8 => f8,
      9 => f9,
      10 => f10,
      11 => f11,
      12 => f12,
      13 => f13,
      14 => f14,
      15 => f15,
      16 => f16,
      17 => f17,
      18 => f18,
      19 => f19,
      20 => f20,
      21 => f21,
      22 => f22,
      23 => f23,
      24 => f24,
      25 => f25,
      26 => f26,
      27 => f27,
      28 => f28,
      29 => f29,
      30 => f30,
      31 => f31,
      _  => {assert(false, "invalid floating point register number"); zero_freg}
    };
  fregval_from_freg(v)
}

function wF (Fregno(r) : fregno, in_v : flenbits) -> unit = {
  assert(hartSupports(Ext_F));
  let v = fregval_into_freg(in_v);
  match r {
    0  => f0 = v,
    1  => f1 = v,
    2  => f2 = v,
    3  => f3 = v,
    4  => f4 = v,
    5  => f5 = v,
    6  => f6 = v,
    7  => f7 = v,
    8  => f8 = v,
    9  => f9 = v,
    10 => f10 = v,
    11 => f11 = v,
    12 => f12 = v,
    13 => f13 = v,
    14 => f14 = v,
    15 => f15 = v,
    16 => f16 = v,
    17 => f17 = v,
    18 => f18 = v,
    19 => f19 = v,
    20 => f20 = v,
    21 => f21 = v,
    22 => f22 = v,
    23 => f23 = v,
    24 => f24 = v,
    25 => f25 = v,
    26 => f26 = v,
    27 => f27 = v,
    28 => f28 = v,
    29 => f29 = v,
    30 => f30 = v,
    31 => f31 = v,
  };

  freg_write_callback(Fregidx(to_bits(r)), in_v);
  dirty_fd_context();
}

function rF_bits(Fregidx(i) : fregidx) -> flenbits = rF(Fregno(unsigned(i)))

function wF_bits(Fregidx(i) : fregidx, data: flenbits) -> unit = {
  wF(Fregno(unsigned(i))) = data
}

overload F = {rF_bits, wF_bits, rF, wF}

val rF_BF16 : fregidx -> bits(16)
function rF_BF16(i) = {
  nan_unbox(F(i))
}

val wF_BF16 : (fregidx, bits(16)) -> unit
function wF_BF16(i, data) = {
  F(i) = nan_box(data)
}

val rF_H : fregidx -> bits(16)
function rF_H(i) = {
  assert(flen >= 16);
  assert(hartSupports(Ext_F) & not(hartSupports(Ext_Zfinx)));
  nan_unbox(F(i))
}

val wF_H : (fregidx, bits(16)) -> unit
function wF_H(i, data) = {
  assert(flen >= 16);
  assert(hartSupports(Ext_F) & not(hartSupports(Ext_Zfinx)));
  F(i) = nan_box(data)
}

val rF_S : fregidx -> bits(32)
function rF_S(i) = {
  assert(flen >= 32);
  assert(hartSupports(Ext_F) & not(hartSupports(Ext_Zfinx)));
  nan_unbox(F(i))
}

val wF_S : (fregidx, bits(32)) -> unit
function wF_S(i, data) = {
  assert(flen >= 32);
  assert(hartSupports(Ext_F) & not(hartSupports(Ext_Zfinx)));
  F(i) = nan_box(data)
}

val rF_D : fregidx -> bits(64)
function rF_D(i) = {
  assert(flen >= 64);
  assert(hartSupports(Ext_F) & not(hartSupports(Ext_Zfinx)));
  F(i)
}

val wF_D : (fregidx, bits(64)) -> unit
function wF_D(i, data) = {
  assert(flen >= 64);
  assert(hartSupports(Ext_F) & not(hartSupports(Ext_Zfinx)));
  F(i) = data
}

overload F_BF16 = { rF_BF16, wF_BF16 }
overload F_H = { rF_H, wF_H }
overload F_S = { rF_S, wF_S }
overload F_D = { rF_D, wF_D }

val rF_or_X_H : fregidx -> bits(16)
function rF_or_X_H(i) = {
  assert(flen >= 16);
  assert(hartSupports(Ext_F) != hartSupports(Ext_Zfinx));
  if   hartSupports(Ext_F)
  then F_H(i)
  else X(fregidx_to_regidx(i))[15..0]
}

val rF_or_X_S : fregidx -> bits(32)
function rF_or_X_S(i) = {
  assert(flen >= 32);
  assert(hartSupports(Ext_F) != hartSupports(Ext_Zfinx));
  if   hartSupports(Ext_F)
  then F_S(i)
  else X(fregidx_to_regidx(i))[31..0]
}

val rF_or_X_D : fregidx -> bits(64)
function rF_or_X_D(i) = {
  assert(flen >= 64);
  assert(hartSupports(Ext_F) != hartSupports(Ext_Zfinx));
  if   hartSupports(Ext_F)
  then F_D(i)
  else if xlen >= 64
  then X(fregidx_to_regidx(i))[63..0]
  else {
    let ridx = fregidx_to_regidx(i);
    assert(regidx_bits(ridx)[0] == bitzero);
    if ridx == zreg then zeros() else X(ridx + 1) @ X(ridx)
  }
}

val wF_or_X_H : (fregidx, bits(16)) -> unit
function wF_or_X_H(i, data) = {
  assert(flen >= 16);
  assert(hartSupports(Ext_F) != hartSupports(Ext_Zfinx));
  if   hartSupports(Ext_F)
  then F_H(i) = data
  else X(fregidx_to_regidx(i)) = sign_extend(data)
}

val wF_or_X_S : (fregidx, bits(32)) -> unit
function wF_or_X_S(i, data) = {
  assert(flen >= 32);
  assert(hartSupports(Ext_F) != hartSupports(Ext_Zfinx));
  if   hartSupports(Ext_F)
  then F_S(i) = data
  else X(fregidx_to_regidx(i)) = sign_extend(data)
}

val wF_or_X_D : (fregidx, bits(64)) -> unit
function wF_or_X_D(i, data) = {
  assert (flen >= 64);
  assert(hartSupports(Ext_F) != hartSupports(Ext_Zfinx));
  if   hartSupports(Ext_F)
  then F_D(i) = data
  else if xlen >= 64
  then X(fregidx_to_regidx(i)) = sign_extend(data)
  else {
    let ridx = fregidx_to_regidx(i);
    assert (regidx_bits(ridx)[0] == bitzero);
    if ridx != zreg then {
      X(ridx) = data[31..0];
      X(ridx + 1) = data[63..32];
    }
  }
}

overload F_or_X_H = { rF_or_X_H, wF_or_X_H }
overload F_or_X_S = { rF_or_X_S, wF_or_X_S }
overload F_or_X_D = { rF_or_X_D, wF_or_X_D }

// mappings for assembly

mapping freg_abi_name_raw : bits(5) <-> string = {
    0b00000 <-> "ft0",
    0b00001 <-> "ft1",
    0b00010 <-> "ft2",
    0b00011 <-> "ft3",
    0b00100 <-> "ft4",
    0b00101 <-> "ft5",
    0b00110 <-> "ft6",
    0b00111 <-> "ft7",
    0b01000 <-> "fs0",
    0b01001 <-> "fs1",
    0b01010 <-> "fa0",
    0b01011 <-> "fa1",
    0b01100 <-> "fa2",
    0b01101 <-> "fa3",
    0b01110 <-> "fa4",
    0b01111 <-> "fa5",
    0b10000 <-> "fa6",
    0b10001 <-> "fa7",
    0b10010 <-> "fs2",
    0b10011 <-> "fs3",
    0b10100 <-> "fs4",
    0b10101 <-> "fs5",
    0b10110 <-> "fs6",
    0b10111 <-> "fs7",
    0b11000 <-> "fs8",
    0b11001 <-> "fs9",
    0b11010 <-> "fs10",
    0b11011 <-> "fs11",
    0b11100 <-> "ft8",
    0b11101 <-> "ft9",
    0b11110 <-> "ft10",
    0b11111 <-> "ft11"
}

mapping freg_arch_name_raw : bits(5) <-> string = {
    0b00000 <-> "f0",
    0b00001 <-> "f1",
    0b00010 <-> "f2",
    0b00011 <-> "f3",
    0b00100 <-> "f4",
    0b00101 <-> "f5",
    0b00110 <-> "f6",
    0b00111 <-> "f7",
    0b01000 <-> "f8",
    0b01001 <-> "f9",
    0b01010 <-> "f10",
    0b01011 <-> "f11",
    0b01100 <-> "f12",
    0b01101 <-> "f13",
    0b01110 <-> "f14",
    0b01111 <-> "f15",
    0b10000 <-> "f16",
    0b10001 <-> "f17",
    0b10010 <-> "f18",
    0b10011 <-> "f19",
    0b10100 <-> "f20",
    0b10101 <-> "f21",
    0b10110 <-> "f22",
    0b10111 <-> "f23",
    0b11000 <-> "f24",
    0b11001 <-> "f25",
    0b11010 <-> "f26",
    0b11011 <-> "f27",
    0b11100 <-> "f28",
    0b11101 <-> "f29",
    0b11110 <-> "f30",
    0b11111 <-> "f31",
}

mapping freg_name : fregidx <-> string = {
  Fregidx(i) if get_config_use_abi_names()      <-> freg_abi_name_raw(i),
  Fregidx(i) if not(get_config_use_abi_names()) <-> freg_arch_name_raw(i),
}

mapping freg_or_reg_name : fregidx <-> string = {
  forwards f if hartSupports(Ext_Zfinx) => reg_name(fregidx_to_regidx(f)),
  backwards reg_name(Regidx(i)) if hartSupports(Ext_Zfinx) => Fregidx(zero_extend(i)),
  f <-> freg_name(f)
}

mapping cfreg_name : cfregidx <-> string = { Cfregidx(i) <-> freg_name(Fregidx(0b01 @ i)) }

// ***************************************************************
// Floating Point CSR
// fflags    address 0x001    same as fcrs [4..0]
// frm       address 0x002    same as fcrs [7..5]
// fcsr      address 0x003


bitfield Fcsr : bits(32) = {
  FRM    : 7 .. 5,
  FFLAGS : 4 .. 0,
}

register fcsr : Fcsr

val write_fcsr : (bits(3), bits(5)) -> unit
function write_fcsr (frm, fflags) = {
  fcsr[FRM]    = frm;      // Note: frm can be an illegal value, 101, 110, 111
  fcsr[FFLAGS] = fflags;
  dirty_fd_context_if_present();
}

// OR flags into the fflags register.
val accrue_fflags : (bits(5)) -> unit
function accrue_fflags(flags) = {
  let f = fcsr[FFLAGS] | flags;
  if  fcsr[FFLAGS] != f
  then {
    fcsr[FFLAGS] = f;
    dirty_fd_context_if_present();
  }
}
