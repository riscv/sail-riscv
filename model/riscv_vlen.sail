/*=======================================================================================*/
/*  This Sail RISC-V architecture model, comprising all files and                        */
/*  directories except where otherwise noted is subject the BSD                          */
/*  two-clause license in the LICENSE file.                                              */
/*                                                                                       */
/*  SPDX-License-Identifier: BSD-2-Clause                                                */
/*=======================================================================================*/

let ELEN_pow : range(3, 16) = config extensions.V.elen_exp

/* Note: ELEN=32 requires a different encoding of the CSR vtype.
 * The current version of vtype implementation corresponds to the ELEN=64 configuration.
 * TODO: the configurarion of ELEN and its corresponding vtype implementations.
 */

let VLEN_pow : range(3, 16) = config extensions.V.vlen_exp

type vlenmax : Int = 65536

let VLEN = 2 ^ VLEN_pow
