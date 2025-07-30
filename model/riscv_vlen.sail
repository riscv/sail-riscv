/*=======================================================================================*/
/*  This Sail RISC-V architecture model, comprising all files and                        */
/*  directories except where otherwise noted is subject the BSD                          */
/*  two-clause license in the LICENSE file.                                              */
/*                                                                                       */
/*  SPDX-License-Identifier: BSD-2-Clause                                                */
/*=======================================================================================*/

type vlen_exp : Int = config extensions.V.vlen_exp
constraint 3 <= vlen_exp <= 16

/* Note: ELEN=32 requires a different encoding of the CSR vtype.
 * The current version of vtype implementation corresponds to the ELEN=64 configuration.
 * TODO: the configurarion of ELEN and its corresponding vtype implementations.
 */
type elen_exp : Int = config extensions.V.elen_exp
constraint 3 <= elen_exp <= 16 & elen_exp <= vlen_exp

let vlen_exp = sizeof(vlen_exp)
let elen_exp = sizeof(elen_exp)

type vlen : Int = 2 ^ vlen_exp
type elen : Int = 2 ^ elen_exp

let vlen = sizeof(vlen)
let elen = sizeof(elen)
