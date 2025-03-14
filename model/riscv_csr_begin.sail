/*=======================================================================================*/
/*  This Sail RISC-V architecture model, comprising all files and                        */
/*  directories except where otherwise noted is subject the BSD                          */
/*  two-clause license in the LICENSE file.                                              */
/*                                                                                       */
/*  SPDX-License-Identifier: BSD-2-Clause                                                */
/*=======================================================================================*/

/* Mapping of csr addresses to their names. */

val csr_name_map : csreg <-> string

scattered mapping csr_name_map

val csr_name : csreg -> string
function csr_name(csr) = csr_name_map(csr)
overload to_str = {csr_name}

/* returns whether a CSR exists
 */
val is_CSR_defined : (csreg) -> bool
scattered function is_CSR_defined

/* returns the value of the CSR if it is defined */
val read_CSR : csreg -> xlenbits
scattered function read_CSR

/* returns new value (after legalisation) if the CSR is defined */
val write_CSR : (csreg, xlenbits) -> xlenbits
scattered function write_CSR
