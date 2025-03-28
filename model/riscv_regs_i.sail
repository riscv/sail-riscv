/*=======================================================================================*/
/*  This Sail RISC-V architecture model, comprising all files and                        */
/*  directories except where otherwise noted is subject the BSD                          */
/*  two-clause license in the LICENSE file.                                              */
/*                                                                                       */
/*  SPDX-License-Identifier: BSD-2-Clause                                                */
/*=======================================================================================*/

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

let xregs = [
  ref x1,
  ref x2,
  ref x3,
  ref x4,
  ref x5,
  ref x6,
  ref x7,
  ref x8,
  ref x9,
  ref x10,
  ref x11,
  ref x12,
  ref x13,
  ref x14,
  ref x15,
  ref x16,
  ref x17,
  ref x18,
  ref x19,
  ref x20,
  ref x21,
  ref x22,
  ref x23,
  ref x24,
  ref x25,
  ref x26,
  ref x27,
  ref x28,
  ref x29,
  ref x30,
  ref x31
]

function xreg_by_index (r) = xregs[r - 1]

/*
 * RV{32,64}I uses all five bits of register index operands, so its mapping
 * functions are total and just wrap and unwrap the regidx newtype.
 */

mapping encdec_reg : regidx <-> bits(5) = { Regidx(r) <-> r }

/* mappings for assembly */

mapping reg_name_raw : bits(5) <-> string = {
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
