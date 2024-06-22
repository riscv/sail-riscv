/*=======================================================================================*/
/*  This Sail RISC-V architecture model, comprising all files and                        */
/*  directories except where otherwise noted is subject the BSD                          */
/*  two-clause license in the LICENSE file.                                              */
/*                                                                                       */
/*  SPDX-License-Identifier: BSD-2-Clause                                                */
/*=======================================================================================*/

/* Support CTR depths - if bit n is set then CTR depth 2^n is supported */
val sys_valid_ctr_depth = {c: "sys_valid_ctr_depth", ocaml: "Platform.valid_ctr_depth", _: "sys_valid_ctr_depth"} : unit -> bits(64)
/* Number of CCE bits - ranges from 0 to 4 */
val sys_num_cce_bits = {c: "sys_num_cce_bits", ocaml: "Platform.num_cce_bits", _: "sys_num_cce_bits"} : unit -> range(0, 4)
/* WARL mask for mctrctl - mask bit i is 1 if bit i of mctrctl is writable */
val sys_mctrctl_warl_mask = {c: "sys_mctrctl_warl_mask", ocaml: "Platform.mctrctl_warl_mask", _: "sys_mctrctl_warl_mask"} : unit -> bits(64)

/* Architectural state for the Ssctr and Smctr standard extension. */
bitfield Mctrctl : bits(64) = {
  DIRLJMPINH : 47,
  INDLJMPINH : 46,
  RETINH     : 45,
  CORSWAPINH : 44,
  DIRJMPINH  : 43,
  INDJMPINH  : 42,
  DIRCALLINH : 41,
  INDCALLINH : 40,
  TKBRINH    : 37,
  NTBREN     : 36,
  TRETINH    : 35,
  INTRINH    : 34,
  EXCINH     : 33,

  LCOFIFRZ   : 12,
  BPFRZ      : 11,

  MTE        : 9,
  STE        : 8,

  RASEMU     : 7,

  M          : 2,
  S          : 1,
  U          : 0
}
bitfield Sctrctl : bits(64) = {
  DIRLJMPINH : 47,
  INDLJMPINH : 46,
  RETINH     : 45,
  CORSWAPINH : 44,
  DIRJMPINH  : 43,
  INDJMPINH  : 42,
  DIRCALLINH : 41,
  INDCALLINH : 40,
  TKBRINH    : 37,
  NTBREN     : 36,
  TRETINH    : 35,
  INTRINH    : 34,
  EXCINH     : 33,

  LCOFIFRZ   : 12,
  BPFRZ      : 11,

  STE        : 8,

  RASEMU     : 7,

  S          : 1,
  U          : 0
}
bitfield Sctrdepth : bits(32) = {
  DEPTH      : 2 .. 0
}
bitfield Sctrstatus : bits(32) = {
  FROZEN     : 31,
  WRPTR      : 7 .. 0
}
bitfield Ctrsource : xlenbits = {
  PC         : xlen - 1 .. 1,
  V          : 0
}
bitfield Ctrtarget : xlenbits = {
  PC         : xlen - 1 .. 1,
  MISP       : 0
}
bitfield Ctrdata : bits(64) = {
  CCE        : 31 .. 28,
  CCM        : 27 .. 16,
  CCV        : 15,
  TYPE       : 3 .. 0
}

register sctrstatus : Sctrstatus
register sctrdepth  : Sctrdepth
register mctrctl    : Mctrctl
register ctrsource  : vector(256, dec, Ctrsource)
register ctrtarget  : vector(256, dec, Ctrtarget)
register ctrdata    : vector(256, dec, Ctrdata)

register ctr_cycle_counter : bits(27)
register ctr_cycle_counter_valid : bool

function legalize_mctrctl(m : Mctrctl, v : xlenbits) -> Mctrctl = {
  let i : Mctrctl = Mk_Mctrctl(zero_extend(v));
  let o : Mctrctl = Mk_Mctrctl(zeros());
  let o = [o with DIRLJMPINH = i[DIRLJMPINH]];
  let o = [o with INDLJMPINH = i[INDLJMPINH]];
  let o = [o with RETINH     = i[RETINH]];
  let o = [o with CORSWAPINH = i[CORSWAPINH]];
  let o = [o with DIRJMPINH  = i[DIRJMPINH]];
  let o = [o with INDJMPINH  = i[INDJMPINH]];
  let o = [o with DIRCALLINH = i[DIRCALLINH]];
  let o = [o with INDCALLINH = i[INDCALLINH]];
  let o = [o with TKBRINH    = i[TKBRINH]];
  let o = [o with NTBREN     = i[NTBREN]];
  let o = [o with TRETINH    = i[TRETINH]];
  let o = [o with INTRINH    = i[INTRINH]];
  let o = [o with EXCINH     = i[EXCINH]];
  let o = [o with LCOFIFRZ   = i[LCOFIFRZ]];
  let o = [o with BPFRZ      = i[BPFRZ]];
  let o = [o with MTE        = i[MTE]];
  let o = [o with STE        = i[STE]];
  let o = [o with RASEMU     = i[RASEMU]];
  let o = [o with M          = i[M]];
  let o = [o with S          = i[S]];
  let o = [o with U          = i[U]];
  let o = Mk_Mctrctl(o.bits & sys_mctrctl_warl_mask());
  o
}

function lower_sctrctl(m : Mctrctl) -> Sctrctl = {
  let s : Sctrctl = Mk_Sctrctl(zeros());
  let s = [s with DIRLJMPINH = m[DIRLJMPINH]];
  let s = [s with INDLJMPINH = m[INDLJMPINH]];
  let s = [s with RETINH     = m[RETINH]];
  let s = [s with CORSWAPINH = m[CORSWAPINH]];
  let s = [s with DIRJMPINH  = m[DIRJMPINH]];
  let s = [s with INDJMPINH  = m[INDJMPINH]];
  let s = [s with DIRCALLINH = m[DIRCALLINH]];
  let s = [s with INDCALLINH = m[INDCALLINH]];
  let s = [s with TKBRINH    = m[TKBRINH]];
  let s = [s with NTBREN     = m[NTBREN]];
  let s = [s with TRETINH    = m[TRETINH]];
  let s = [s with INTRINH    = m[INTRINH]];
  let s = [s with EXCINH     = m[EXCINH]];
  let s = [s with LCOFIFRZ   = m[LCOFIFRZ]];
  let s = [s with BPFRZ      = m[BPFRZ]];
  let s = [s with STE        = m[STE]];
  let s = [s with RASEMU     = m[RASEMU]];
  let s = [s with S          = m[S]];
  let s = [s with U          = m[U]];
  s
}

function legalize_sctrctl(m : Mctrctl, v : xlenbits) -> Mctrctl = {
  let i : Sctrctl = Mk_Sctrctl(zero_extend(v));
  let o : Sctrctl = Mk_Sctrctl(zeros());
  let o = [o with DIRLJMPINH = i[DIRLJMPINH]];
  let o = [o with INDLJMPINH = i[INDLJMPINH]];
  let o = [o with RETINH     = i[RETINH]];
  let o = [o with CORSWAPINH = i[CORSWAPINH]];
  let o = [o with DIRJMPINH  = i[DIRJMPINH]];
  let o = [o with INDJMPINH  = i[INDJMPINH]];
  let o = [o with DIRCALLINH = i[DIRCALLINH]];
  let o = [o with INDCALLINH = i[INDCALLINH]];
  let o = [o with TKBRINH    = i[TKBRINH]];
  let o = [o with NTBREN     = i[NTBREN]];
  let o = [o with TRETINH    = i[TRETINH]];
  let o = [o with INTRINH    = i[INTRINH]];
  let o = [o with EXCINH     = i[EXCINH]];
  let o = [o with LCOFIFRZ   = i[LCOFIFRZ]];
  let o = [o with BPFRZ      = i[BPFRZ]];
  let o = [o with STE        = i[STE]];
  let o = [o with RASEMU     = i[RASEMU]];
  let o = [o with S          = i[S]];
  let o = [o with U          = i[U]];
  let o = Mk_Mctrctl(o.bits & sys_mctrctl_warl_mask());
  o
}

function get_wrptr_mask(d : Sctrdepth) -> bits(8) =
  match(d[DEPTH]) {
    0b000 => 0b00001111,
    0b001 => 0b00011111,
    0b010 => 0b00111111,
    0b011 => 0b01111111,
    0b100 => 0b11111111,
        _ => internal_error(__FILE__, __LINE__, "Unexpected DEPTH encoding")
  }

function get_cur_ctr_depth() -> int =
  match(sctrdepth[DEPTH]) {
    0b000 => 16,
    0b001 => 32,
    0b010 => 64,
    0b011 => 128,
    0b100 => 256,
        _ => internal_error(__FILE__, __LINE__, "Unexpected DEPTH encoding")
  }

function legalize_sctrdepth(s : Sctrdepth, v : xlenbits) -> Sctrdepth = {
  let valid_ctr_depth : bits(64) = sys_valid_ctr_depth();
  let depth : bits(3) = match(v[2 .. 0]) {
    0b000 => if bit_to_bool(valid_ctr_depth[0]) then v[2 .. 0] else s[DEPTH],
    0b001 => if bit_to_bool(valid_ctr_depth[1]) then v[2 .. 0] else s[DEPTH],
    0b010 => if bit_to_bool(valid_ctr_depth[2]) then v[2 .. 0] else s[DEPTH],
    0b011 => if bit_to_bool(valid_ctr_depth[3]) then v[2 .. 0] else s[DEPTH],
    0b100 => if bit_to_bool(valid_ctr_depth[4]) then v[2 .. 0] else s[DEPTH],
        _ => s[DEPTH]
  };
  let o = Mk_Sctrdepth(zero_extend(depth));

  /* On depth change WRPTR assumes an unspecified but legal value */
  sctrstatus[WRPTR] = sctrstatus[WRPTR] & get_wrptr_mask(o);

  o
}
function legalize_sctrstatus(s : Sctrstatus, v : xlenbits) -> Sctrstatus = {
  let wrptr_mask : bits(8) = get_wrptr_mask(sctrdepth);
  let o = Mk_Sctrstatus(zeros());
  let o = [o with WRPTR = (v[7 .. 0] & wrptr_mask), FROZEN = v[31 .. 31]];
  o
}
function number_of_ctr() -> int = {
  let valid_ctr_depth : bits(64) = sys_valid_ctr_depth();
  let num = if bit_to_bool(valid_ctr_depth[0]) then 16 else 0;
  let num = if bit_to_bool(valid_ctr_depth[1]) then 32 else num;
  let num = if bit_to_bool(valid_ctr_depth[2]) then 64 else num;
  let num = if bit_to_bool(valid_ctr_depth[3]) then 128 else num;
  let num = if bit_to_bool(valid_ctr_depth[4]) then 256 else num;
  num
}
/* Logical entry N, selected by *iselect value of (0x200 | N), is
 * physically at ((WRPTR - N - 1) % depth) where depth = 2^(DEPTH+4)
 */
function get_ctr_idx(iselect : SMiselect) -> bits(8) = {
  let ctr_idx = sctrstatus[WRPTR] - iselect.bits[7 .. 0] - 1;
  ctr_idx & get_wrptr_mask(sctrdepth);
}

function get_ctr_sireg() -> xlenbits =
  if get_cur_ctr_depth() > unsigned(siselect.bits[7 .. 0])
  then ctrsource[unsigned(get_ctr_idx(siselect))].bits
  else zeros()

function get_ctr_sireg2() -> xlenbits =
  if get_cur_ctr_depth() > unsigned(siselect.bits[7 .. 0])
  then ctrtarget[unsigned(get_ctr_idx(siselect))].bits
  else zeros()

function get_ctr_sireg3() -> xlenbits =
  if get_cur_ctr_depth() > unsigned(siselect.bits[7 .. 0])
  then {
    if sizeof(xlen) == 32
    then ctrdata[unsigned(get_ctr_idx(siselect))].bits[31 .. 0]
    else ctrdata[unsigned(get_ctr_idx(siselect))].bits[63 .. 0]
  } else zeros()

function set_ctr_sireg(v: xlenbits) -> unit =
  if get_cur_ctr_depth() > unsigned(siselect.bits[7 .. 0])
  then ctrsource[unsigned(get_ctr_idx(siselect))] = Mk_Ctrsource(v)

function set_ctr_sireg2(v: xlenbits) -> unit =
  if get_cur_ctr_depth() > unsigned(siselect.bits[7 .. 0])
  then ctrtarget[unsigned(get_ctr_idx(siselect))] = Mk_Ctrtarget(v)

function set_ctr_sireg3(v: xlenbits) -> unit = {
  let cce_mask : bits(4) = match sys_num_cce_bits() {
    0 => 0b0000,
    1 => 0b0001,
    2 => 0b0011,
    3 => 0b0111,
    4 => 0b1111,
    _ => internal_error(__FILE__, __LINE__, "Unexpected CCE")
  };
  let d : Ctrdata = Mk_Ctrdata(zero_extend(v));
  let d = [d with CCE = d[CCE] & cce_mask];
  if get_cur_ctr_depth() > unsigned(siselect.bits[7 .. 0])
  then ctrdata[unsigned(get_ctr_idx(siselect))] = d;
}
