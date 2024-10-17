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

/* Note: At present, the values of elen and vlen need to be manually speficied
 * in the init_sys() function of riscv_sys_control.sail before compiling the emulators,
 * e.g.,
 *  vlen = 0b0101;
 *  elen = 0b1;
 * means VLEN = 1024 and ELEN = 64,
 * They will be configurable when user-specified configuration is supported in Sail.
 *
 * Also, VLEN >= ELEN must be satisfied and this condition check should be added
 * after their initialization.
 */
