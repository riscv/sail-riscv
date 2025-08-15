/*=======================================================================================*/
/*  This Sail RISC-V architecture model, comprising all files and                        */
/*  directories except where otherwise noted is subject the BSD                          */
/*  two-clause license in the LICENSE file.                                              */
/*                                                                                       */
/*  SPDX-License-Identifier: BSD-2-Clause                                                */
/*=======================================================================================*/

type shamt_zba = bits(2)

enum brop_zbb = {ANDN, ORN, XNOR, MAX, MAXU, MIN, MINU, ROL, ROR}

enum brop_zbkb = {PACK, PACKH}

enum brop_zbs = {BCLR, BEXT, BINV, BSET}

enum bropw_zbb = {ROLW, RORW}

enum biop_zbs = {BCLRI, BEXTI, BINVI, BSETI}

enum extop_zbb = {SEXTB, SEXTH, ZEXTH}
