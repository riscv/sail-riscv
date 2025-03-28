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
  ref x15
]

function xreg_by_index (r) = xregs[r - 1]

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
