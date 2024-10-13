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

// TODO: These csr_name_map definitions should be moved to the files
// corresponding to their extensions rather than all be here.

val csr_name : csreg -> string
overload to_str = {csr_name}

/* Extensions may want to add additional CSR registers to the CSR address map.
 * These scattered functions support access to such registers.
 *
 * The default implementation provides access to the CSRs added by the 'N'
 * extension.
 */


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
