/*=======================================================================================*/
/*  This Sail RISC-V architecture model, comprising all files and                        */
/*  directories except where otherwise noted is subject the BSD                          */
/*  two-clause license in the LICENSE file.                                              */
/*                                                                                       */
/*  SPDX-License-Identifier: BSD-2-Clause                                                */
/*=======================================================================================*/

/* register file and accessors */

register x1  : regtype
register x2  : regtype
register x3  : regtype
register x4  : regtype
register x5  : regtype
register x6  : regtype
register x7  : regtype
register x8  : regtype
register x9  : regtype
register x10 : regtype
register x11 : regtype
register x12 : regtype
register x13 : regtype
register x14 : regtype
register x15 : regtype

function rX (Regno(r) : regno) -> xlenbits = {
  let v : regtype =
    match r {
      0 => zero_reg,
      1 => x1,
      2 => x2,
      3 => x3,
      4 => x4,
      5 => x5,
      6 => x6,
      7 => x7,
      8 => x8,
      9 => x9,
      10 => x10,
      11 => x11,
      12 => x12,
      13 => x13,
      14 => x14,
      15 => x15,
      _  => {assert(false, "invalid register number"); zero_reg}
    };
  regval_from_reg(v)
}

$ifdef RVFI_DII
function rvfi_wX (Regno(r) : regno, v : xlenbits) -> unit = {
  rvfi_int_data[rvfi_rd_wdata] = zero_extend(v);
  rvfi_int_data[rvfi_rd_addr] = to_bits(8,r);
  rvfi_int_data_present = true;
}
$else
function rvfi_wX (r : regno, v : xlenbits) -> unit = ()
$endif

function wX (Regno(r) : regno, in_v : xlenbits) -> unit = {
  let v = regval_into_reg(in_v);
  match r {
    0  => (),
    1  => x1 = v,
    2  => x2 = v,
    3  => x3 = v,
    4  => x4 = v,
    5  => x5 = v,
    6  => x6 = v,
    7  => x7 = v,
    8  => x8 = v,
    9  => x9 = v,
    10 => x10 = v,
    11 => x11 = v,
    12 => x12 = v,
    13 => x13 = v,
    14 => x14 = v,
    15 => x15 = v,
    _  => assert(false, "invalid register number")
  };
  if (r != 0) then {
     rvfi_wX(Regno(r), in_v);
     if   get_config_print_reg()
     then print_reg("x" ^ dec_str(r) ^ " <- " ^ RegStr(v));
  }
}

/*
 * RV{32,64}E uses only the bottom four bits of register index operands, so its
 * encoding function is total but its decoding function is partial, requiring a
 * 0b0 at the start of the field to apply.
 */

mapping encdec_reg : regidx <-> bits(5) = { Regidx(r) <-> 0b0 @ r }

/* mappings for assembly */

mapping reg_name_raw : bits(4) <-> string = {
    0b0000 <-> "zero",
    0b0001 <-> "ra",
    0b0010 <-> "sp",
    0b0011 <-> "gp",
    0b0100 <-> "tp",
    0b0101 <-> "t0",
    0b0110 <-> "t1",
    0b0111 <-> "t2",
    0b1000 <-> "fp",
    0b1001 <-> "s1",
    0b1010 <-> "a0",
    0b1011 <-> "a1",
    0b1100 <-> "a2",
    0b1101 <-> "a3",
    0b1110 <-> "a4",
    0b1111 <-> "a5",
}

mapping reg_name : regidx <-> string = { Regidx(i) <-> reg_name_raw(i) }

/* mapping RVC register indices into normal indices */
val creg2reg_idx : cregidx -> regidx
function creg2reg_idx(Cregidx(i) : cregidx) -> regidx = Regidx(0b1 @ i)

/* some architecture and ABI relevant register identifiers */
let zreg : regidx = Regidx(0b0000) /* x0, zero register  */
let ra   : regidx = Regidx(0b0001) /* x1, return address */
let sp   : regidx = Regidx(0b0010) /* x2, stack pointer  */

function init_base_regs () = {
  x1  = zero_reg;
  x2  = zero_reg;
  x3  = zero_reg;
  x4  = zero_reg;
  x5  = zero_reg;
  x6  = zero_reg;
  x7  = zero_reg;
  x8  = zero_reg;
  x9  = zero_reg;
  x10 = zero_reg;
  x11 = zero_reg;
  x12 = zero_reg;
  x13 = zero_reg;
  x14 = zero_reg;
  x15 = zero_reg;
}
