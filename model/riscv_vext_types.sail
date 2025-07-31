/*=======================================================================================*/
/*  This Sail RISC-V architecture model, comprising all files and                        */
/*  directories except where otherwise noted is subject the BSD                          */
/*  two-clause license in the LICENSE file.                                              */
/*                                                                                       */
/*  SPDX-License-Identifier: BSD-2-Clause                                                */
/*=======================================================================================*/

/* NFIELDS Encoding
 * typically, nf is in range 1 to 8, but for 'Vector Load/Store Whole Register Instructions',
 * only NFIELDS values of 1, 2, 4, 8 are supported, with other values reserved.
 */
type nfields_range('q) = 'q > 0 & 'q <= 8
type nfields_range_pow2('q) = 'q in { 1, 2, 4, 8 }
type nfields = { 'q, nfields_range('q). int('q) }
type nfields_pow2 = { 'q, nfields_range_pow2('q). int('q) }

mapping encdec_nfields : bits(3) <-> nfields = {
  0b000 <-> 1,
  0b001 <-> 2,
  0b010 <-> 3,
  0b011 <-> 4,
  0b100 <-> 5,
  0b101 <-> 6,
  0b110 <-> 7,
  0b111 <-> 8,
}

mapping nfields_string : nfields <-> string = {
  1 <-> "",
  2 <-> "seg2",
  3 <-> "seg3",
  4 <-> "seg4",
  5 <-> "seg5",
  6 <-> "seg6",
  7 <-> "seg7",
  8 <-> "seg8",
}

// For some instructions non-power-of-two values are reserved.
mapping encdec_nfields_pow2 : bits(3) <-> nfields_pow2 = {
  0b000 <-> 1,
  0b001 <-> 2,
  0b011 <-> 4,
  0b111 <-> 8,
}

mapping nfields_pow2_string : nfields_pow2 <-> string = {
  1 <-> "1",
  2 <-> "2",
  4 <-> "4",
  8 <-> "8",
}
