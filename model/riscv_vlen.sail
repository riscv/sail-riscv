/*=======================================================================================*/
/*  This Sail RISC-V architecture model, comprising all files and                        */
/*  directories except where otherwise noted is subject the BSD                          */
/*  two-clause license in the LICENSE file.                                              */
/*                                                                                       */
/*  SPDX-License-Identifier: BSD-2-Clause                                                */
/*=======================================================================================*/

val sys_vector_elen_exp = pure "sys_vector_elen_exp" : unit -> range(3, 16)

function get_elen_pow() -> range(3, 16) = sys_vector_elen_exp()

/* Note: ELEN=32 requires a different encoding of the CSR vtype.
 * The current version of vtype implementation corresponds to the ELEN=64 configuration.
 * TODO: the configurarion of ELEN and its corresponding vtype implementations.
 */

val sys_vector_vlen_exp = pure "sys_vector_vlen_exp" : unit -> range(3, 16)

function get_vlen_pow() -> range(3, 16) = sys_vector_vlen_exp()

type vlenmax : Int = 65536

let VLEN = 2 ^ get_vlen_pow()
