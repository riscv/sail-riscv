/*=======================================================================================*/
/*  This Sail RISC-V architecture model, comprising all files and                        */
/*  directories except where otherwise noted is subject the BSD                          */
/*  two-clause license in the LICENSE file.                                              */
/*                                                                                       */
/*  SPDX-License-Identifier: BSD-2-Clause                                                */
/*=======================================================================================*/

/* program counter */

register PC       : xlenbits
register nextPC   : xlenbits

/* internal state to hold instruction bits for faulting instructions */
register instbits : xlenbits

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
register x16 : regtype
register x17 : regtype
register x18 : regtype
register x19 : regtype
register x20 : regtype
register x21 : regtype
register x22 : regtype
register x23 : regtype
register x24 : regtype
register x25 : regtype
register x26 : regtype
register x27 : regtype
register x28 : regtype
register x29 : regtype
register x30 : regtype
register x31 : regtype

function rX (r : regno) -> xlenbits = {
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
      16 => x16,
      17 => x17,
      18 => x18,
      19 => x19,
      20 => x20,
      21 => x21,
      22 => x22,
      23 => x23,
      24 => x24,
      25 => x25,
      26 => x26,
      27 => x27,
      28 => x28,
      29 => x29,
      30 => x30,
      31 => x31,
      _  => {assert(false, "invalid register number"); zero_reg}
    };
  regval_from_reg(v)
}

function wX (r : regno, in_v : xlenbits) -> unit = {
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
    16 => x16 = v,
    17 => x17 = v,
    18 => x18 = v,
    19 => x19 = v,
    20 => x20 = v,
    21 => x21 = v,
    22 => x22 = v,
    23 => x23 = v,
    24 => x24 = v,
    25 => x25 = v,
    26 => x26 = v,
    27 => x27 = v,
    28 => x28 = v,
    29 => x29 = v,
    30 => x30 = v,
    31 => x31 = v,
    _  => assert(false, "invalid register number")
  };
  if (r != 0) then {
    xreg_write_callback(regno_to_regidx(r), in_v);
  }
}

function rX_bits(i: regidx) -> xlenbits = rX(unsigned(i))

function wX_bits(i: regidx, data: xlenbits) -> unit = {
  wX(unsigned(i)) = data
}

overload X = {rX_bits, wX_bits, rX, wX}

/* mappings for assembly */

val reg_name : regidx <-> string
mapping reg_name = {
    0b00000 <-> "zero",
    0b00001 <-> "ra",
    0b00010 <-> "sp",
    0b00011 <-> "gp",
    0b00100 <-> "tp",
    0b00101 <-> "t0",
    0b00110 <-> "t1",
    0b00111 <-> "t2",
    0b01000 <-> "fp",
    0b01001 <-> "s1",
    0b01010 <-> "a0",
    0b01011 <-> "a1",
    0b01100 <-> "a2",
    0b01101 <-> "a3",
    0b01110 <-> "a4",
    0b01111 <-> "a5",
    0b10000 <-> "a6",
    0b10001 <-> "a7",
    0b10010 <-> "s2",
    0b10011 <-> "s3",
    0b10100 <-> "s4",
    0b10101 <-> "s5",
    0b10110 <-> "s6",
    0b10111 <-> "s7",
    0b11000 <-> "s8",
    0b11001 <-> "s9",
    0b11010 <-> "s10",
    0b11011 <-> "s11",
    0b11100 <-> "t3",
    0b11101 <-> "t4",
    0b11110 <-> "t5",
    0b11111 <-> "t6"
}

mapping creg_name : cregidx <-> string = {
  0b000 <-> "s0",
  0b001 <-> "s1",
  0b010 <-> "a0",
  0b011 <-> "a1",
  0b100 <-> "a2",
  0b101 <-> "a3",
  0b110 <-> "a4",
  0b111 <-> "a5"
}

val init_base_regs : unit -> unit
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
  x16 = zero_reg;
  x17 = zero_reg;
  x18 = zero_reg;
  x19 = zero_reg;
  x20 = zero_reg;
  x21 = zero_reg;
  x22 = zero_reg;
  x23 = zero_reg;
  x24 = zero_reg;
  x25 = zero_reg;
  x26 = zero_reg;
  x27 = zero_reg;
  x28 = zero_reg;
  x29 = zero_reg;
  x30 = zero_reg;
  x31 = zero_reg
}
