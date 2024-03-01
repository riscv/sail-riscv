/*=======================================================================================*/
/*  This Sail RISC-V architecture model, comprising all files and                        */
/*  directories except where otherwise noted is subject the BSD                          */
/*  two-clause license in the LICENSE file.                                              */
/*                                                                                       */
/*  SPDX-License-Identifier: BSD-2-Clause                                                */
/*=======================================================================================*/

/* Definitions for fast interrupt (Smclic extensions) */

/* default register type */
type ilbits = bits(8)

bitfield clicintattr_layout : bits(8) = {
  MODE : 7 .. 6,   /* privilege mode */
  TRIG : 2 .. 1,   /* 11 - negedge triggered */
                   /* 10 - active low */
                   /* 01 - posedge triggered */
                   /* 00 - active high */
  SHV  : 0         /* hardware vectored interrupt */
}

val is_shv : bitvector(1) -> bool
function is_shv (shv) =
  match (shv) {
    0b0 => false,
    0b1 => true
  }

let CLIC_MTI = 7
let CLIC_MSI = 3

union VectorTableFetchResult = {
  F_TableEntry      : xlenbits,                 /* Entry in vector table */
  F_TableError     : (ExceptionType, xlenbits)  /* standard exception and table entry addr */
}
