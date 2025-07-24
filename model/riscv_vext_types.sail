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
