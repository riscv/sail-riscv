/*=======================================================================================*/
/*  This Sail RISC-V architecture model, comprising all files and                        */
/*  directories except where otherwise noted is subject the BSD                          */
/*  two-clause license in the LICENSE file.                                              */
/*                                                                                       */
/*  SPDX-License-Identifier: BSD-2-Clause                                                */
/*=======================================================================================*/

/* **************************************************************** */
/* This file implements the floating-point for some common helper   */
/* functions. They will be leveraged by other float sail implement. */
/*                                                                  */
/* **************************************************************** */

type bits_fflags = bits(5)    /* Accrued exceptions: NV,DZ,OF,UF,NX */

let float_flag_invalid : bits_fflags = 0b10000
