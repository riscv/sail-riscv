// =======================================================================================
// This Sail RISC-V architecture model, comprising all files and
// directories except where otherwise noted is subject the BSD
// two-clause license in the LICENSE file.
//
// SPDX-License-Identifier: BSD-2-Clause
// =======================================================================================

newtype vregidx = Vregidx : bits(5)
newtype vregno = Vregno : range(0, 31)

function vregidx_to_vregno (Vregidx(b) : vregidx) -> vregno = Vregno(unsigned(b))
function vregno_to_vregidx (Vregno(b) : vregno) -> vregidx = Vregidx(to_bits(5, b))

function vregidx_offset(Vregidx(r) : vregidx, o : bits(5)) -> vregidx = Vregidx(r + o)
function vregidx_offset_range(Vregidx(r) : vregidx, o : range(0, 31)) -> vregidx = Vregidx(r + o)

overload operator + = { vregidx_offset, vregidx_offset_range }

function vregidx_bits (Vregidx(b) : vregidx) -> bits(5) = b

mapping encdec_vreg : vregidx <-> bits(5) = { Vregidx(r) <-> r }

val vreg_write_callback = pure {cpp: "vreg_write_callback"} : (vregidx, vlenbits) -> unit
function vreg_write_callback(_) = ()

let zvreg : vregidx = Vregidx(0b00000) // v0, zero register

// vector registers
register vr0 : vlenbits
register vr1 : vlenbits
register vr2 : vlenbits
register vr3 : vlenbits
register vr4 : vlenbits
register vr5 : vlenbits
register vr6 : vlenbits
register vr7 : vlenbits
register vr8 : vlenbits
register vr9 : vlenbits
register vr10 : vlenbits
register vr11 : vlenbits
register vr12 : vlenbits
register vr13 : vlenbits
register vr14 : vlenbits
register vr15 : vlenbits
register vr16 : vlenbits
register vr17 : vlenbits
register vr18 : vlenbits
register vr19 : vlenbits
register vr20 : vlenbits
register vr21 : vlenbits
register vr22 : vlenbits
register vr23 : vlenbits
register vr24 : vlenbits
register vr25 : vlenbits
register vr26 : vlenbits
register vr27 : vlenbits
register vr28 : vlenbits
register vr29 : vlenbits
register vr30 : vlenbits
register vr31 : vlenbits

mapping vreg_name_raw : bits(5) <-> string = {
    0b00000 <-> "v0",
    0b00001 <-> "v1",
    0b00010 <-> "v2",
    0b00011 <-> "v3",
    0b00100 <-> "v4",
    0b00101 <-> "v5",
    0b00110 <-> "v6",
    0b00111 <-> "v7",
    0b01000 <-> "v8",
    0b01001 <-> "v9",
    0b01010 <-> "v10",
    0b01011 <-> "v11",
    0b01100 <-> "v12",
    0b01101 <-> "v13",
    0b01110 <-> "v14",
    0b01111 <-> "v15",
    0b10000 <-> "v16",
    0b10001 <-> "v17",
    0b10010 <-> "v18",
    0b10011 <-> "v19",
    0b10100 <-> "v20",
    0b10101 <-> "v21",
    0b10110 <-> "v22",
    0b10111 <-> "v23",
    0b11000 <-> "v24",
    0b11001 <-> "v25",
    0b11010 <-> "v26",
    0b11011 <-> "v27",
    0b11100 <-> "v28",
    0b11101 <-> "v29",
    0b11110 <-> "v30",
    0b11111 <-> "v31"
}

mapping vreg_name : vregidx <-> string = { Vregidx(i) <-> vreg_name_raw(i) }

function rV (Vregno(r) : vregno) -> vlenbits = {
  match r {
    0 => vr0,
    1 => vr1,
    2 => vr2,
    3 => vr3,
    4 => vr4,
    5 => vr5,
    6 => vr6,
    7 => vr7,
    8 => vr8,
    9 => vr9,
    10 => vr10,
    11 => vr11,
    12 => vr12,
    13 => vr13,
    14 => vr14,
    15 => vr15,
    16 => vr16,
    17 => vr17,
    18 => vr18,
    19 => vr19,
    20 => vr20,
    21 => vr21,
    22 => vr22,
    23 => vr23,
    24 => vr24,
    25 => vr25,
    26 => vr26,
    27 => vr27,
    28 => vr28,
    29 => vr29,
    30 => vr30,
    31 => vr31,
  }
}

function dirty_v_context() -> unit = {
  assert(hartSupports(Ext_V));
  mstatus[VS] = extStatus_to_bits(Dirty);
  mstatus[SD] = 0b1;
  long_csr_write_callback("mstatus", "mstatush", mstatus.bits);
}

function wV (Vregno(r) : vregno, v : vlenbits) -> unit = {
  match r {
    0 => vr0 = v,
    1 => vr1 = v,
    2 => vr2 = v,
    3 => vr3 = v,
    4 => vr4 = v,
    5 => vr5 = v,
    6 => vr6 = v,
    7 => vr7 = v,
    8 => vr8 = v,
    9 => vr9 = v,
    10 => vr10 = v,
    11 => vr11 = v,
    12 => vr12 = v,
    13 => vr13 = v,
    14 => vr14 = v,
    15 => vr15 = v,
    16 => vr16 = v,
    17 => vr17 = v,
    18 => vr18 = v,
    19 => vr19 = v,
    20 => vr20 = v,
    21 => vr21 = v,
    22 => vr22 = v,
    23 => vr23 = v,
    24 => vr24 = v,
    25 => vr25 = v,
    26 => vr26 = v,
    27 => vr27 = v,
    28 => vr28 = v,
    29 => vr29 = v,
    30 => vr30 = v,
    31 => vr31 = v,
  };

  dirty_v_context();

  vreg_write_callback(vregno_to_vregidx(Vregno(r)), v);
}

function rV_bits(i: vregidx) -> vlenbits = rV(vregidx_to_vregno(i))

function wV_bits(i: vregidx, data: vlenbits) -> unit = {
  wV(vregidx_to_vregno(i)) = data
}

overload V = {rV_bits, wV_bits, rV, wV}

val init_vregs : unit -> unit
function init_vregs () = {
  let zero_vreg : vlenbits = zeros();
  vr0  = zero_vreg;
  vr1  = zero_vreg;
  vr2  = zero_vreg;
  vr3  = zero_vreg;
  vr4  = zero_vreg;
  vr5  = zero_vreg;
  vr6  = zero_vreg;
  vr7  = zero_vreg;
  vr8  = zero_vreg;
  vr9  = zero_vreg;
  vr10 = zero_vreg;
  vr11 = zero_vreg;
  vr12 = zero_vreg;
  vr13 = zero_vreg;
  vr14 = zero_vreg;
  vr15 = zero_vreg;
  vr16 = zero_vreg;
  vr17 = zero_vreg;
  vr18 = zero_vreg;
  vr19 = zero_vreg;
  vr20 = zero_vreg;
  vr21 = zero_vreg;
  vr22 = zero_vreg;
  vr23 = zero_vreg;
  vr24 = zero_vreg;
  vr25 = zero_vreg;
  vr26 = zero_vreg;
  vr27 = zero_vreg;
  vr28 = zero_vreg;
  vr29 = zero_vreg;
  vr30 = zero_vreg;
  vr31 = zero_vreg
}

// vector csrs

register vstart : xlenbits
register vl     : xlenbits

let VLENB : xlenbits = to_bits(vlen / 8)

bitfield Vtype  : xlenbits = {
  vill      : xlen - 1,
  reserved  : xlen - 2 .. 8,
  vma       : 7,
  vta       : 6,
  vsew      : 5 .. 3,
  vlmul     : 2 .. 0
}
register vtype : Vtype

type SEW_pow = range(3, 6)

mapping sew_pow_val : bits(3) <-> SEW_pow = {
  0b000 <-> 3,
  0b001 <-> 4,
  0b010 <-> 5,
  0b011 <-> 6,
}

type LMUL_pow = range(-3, 3)

mapping lmul_pow_val : bits(3) <-> LMUL_pow = {
  0b101 <-> -3,
  0b110 <-> -2,
  0b111 <-> -1,
  0b000 <-> 0,
  0b001 <-> 1,
  0b010 <-> 2,
  0b011 <-> 3,
}

function is_invalid_sew_pow(v : bits(3)) -> bool =
  v >_u 0b011

function is_invalid_lmul_pow(v : bits(3)) -> bool =
  v == 0b100

// the dynamic selected element width (SEW)
// this returns the power of 2 for SEW
function get_sew_pow() -> SEW_pow = {
  let sew_pow = vtype[vsew];
  sew_pow_val(sew_pow)
}

// Valid SEW sizes in bits.
type sew_bitsize = {8, 16, 32, 64}
type is_sew_bitsize('n) -> Bool = 'n in {8, 16, 32, 64}

// this returns the actual value of SEW
function get_sew() -> sew_bitsize =
  2 ^ get_sew_pow()

// this returns the value of SEW in bytes
function get_sew_bytes() -> {1, 2, 4, 8} =
  get_sew() / 8

// the vector register group multiplier (LMUL)
// this returns the power of 2 for LMUL
val get_lmul_pow : unit -> LMUL_pow
function get_lmul_pow() = {
  let lmul_pow = vtype[vlmul];
  lmul_pow_val(lmul_pow)
}

enum agtype = { UNDISTURBED, AGNOSTIC }

val decode_agtype : bits(1) -> agtype
function decode_agtype(ag) = {
  match ag {
    0b0 => UNDISTURBED,
    0b1 => AGNOSTIC
  }
}

val get_vtype_vma : unit -> agtype
function get_vtype_vma() = decode_agtype(vtype[vma])

val get_vtype_vta : unit -> agtype
function get_vtype_vta() = decode_agtype(vtype[vta])

bitfield Vcsr : bits(3) = {
  vxrm  : 2 .. 1,
  vxsat : 0
}
register vcsr : Vcsr

mapping clause csr_name_map = 0x008  <-> "vstart"
mapping clause csr_name_map = 0x009  <-> "vxsat"
mapping clause csr_name_map = 0x00A  <-> "vxrm"
mapping clause csr_name_map = 0x00F  <-> "vcsr"
mapping clause csr_name_map = 0xC20  <-> "vl"
mapping clause csr_name_map = 0xC21  <-> "vtype"
mapping clause csr_name_map = 0xC22  <-> "vlenb"

function clause is_CSR_accessible(0x008, _, _) = currentlyEnabled(Ext_V) // vstart
function clause is_CSR_accessible(0x009, _, _) = currentlyEnabled(Ext_V) // vxsat
function clause is_CSR_accessible(0x00A, _, _) = currentlyEnabled(Ext_V) // vxrm
function clause is_CSR_accessible(0x00F, _, _) = currentlyEnabled(Ext_V) // vcsr
function clause is_CSR_accessible(0xC20, _, _) = currentlyEnabled(Ext_V) // vl
function clause is_CSR_accessible(0xC21, _, _) = currentlyEnabled(Ext_V) // vtype
function clause is_CSR_accessible(0xC22, _, _) = currentlyEnabled(Ext_V) // vlenb

function clause read_CSR(0x008) = vstart
function clause read_CSR(0x009) = zero_extend(vcsr[vxsat])
function clause read_CSR(0x00A) = zero_extend(vcsr[vxrm])
function clause read_CSR(0x00F) = zero_extend(vcsr.bits)
function clause read_CSR(0xC20) = vl
function clause read_CSR(0xC21) = vtype.bits
function clause read_CSR(0xC22) = VLENB

// Note: The spec recommends trapping if vstart is out of bounds but the
// current implementation does not yet do that.

function set_vstart(value : bits(16)) -> unit = {
  dirty_v_context();
  vstart = zero_extend(value[(vlen_exp - 1) .. 0]);
  csr_write_callback("vstart", vstart);
}

val ext_write_vcsr : (bits(2), bits(1)) -> unit
function ext_write_vcsr (vxrm_val, vxsat_val) = {
  vcsr[vxrm]  = vxrm_val; // Note: frm can be an illegal value, 101, 110, 111
  vcsr[vxsat] = vxsat_val;
  dirty_v_context()
}

function clause write_CSR(0x008, value) = { set_vstart(value[15 .. 0]); Ok(vstart) }
function clause write_CSR(0x009, value) = { ext_write_vcsr (vcsr[vxrm], value[0 .. 0]); Ok(zero_extend(vcsr[vxsat])) }
function clause write_CSR(0x00A, value) = { ext_write_vcsr (value[1 .. 0], vcsr[vxsat]); Ok(zero_extend(vcsr[vxrm])) }
function clause write_CSR(0x00F, value) = { ext_write_vcsr (value [2 .. 1], value [0 .. 0]); Ok(zero_extend(vcsr.bits)) }
