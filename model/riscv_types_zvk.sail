/*=======================================================================================*/
/*  This Sail RISC-V architecture model, comprising all files and                        */
/*  directories except where otherwise noted is subject the BSD                          */
/*  two-clause license in the LICENSE file.                                              */
/*                                                                                       */
/*  SPDX-License-Identifier: BSD-2-Clause                                                */
/*=======================================================================================*/

function zvk_check_encdec(EGW: {128, 256}, EGS: {4, 8}) -> bool = (unsigned(vl) % EGS == 0) & (unsigned(vstart) % EGS == 0) & (2 ^ get_lmul_pow() * VLEN) >= EGW
