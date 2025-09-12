// =======================================================================================
// This Sail RISC-V architecture model, comprising all files and
// directories except where otherwise noted is subject the BSD
// two-clause license in the LICENSE file.
//
// SPDX-License-Identifier: BSD-2-Clause
// =======================================================================================

// Extensions may wish to interpose on fetch, control transfer, and data
// addresses used to access memory and perhaps modify them.  This file
// defines the return values used by functions that perform this interposition.
//
// The model defines defaults for these functions in riscv_addr_checks.sail;
// extensions would need to define their own functions to override them.

union Ext_DataAddr_Check ('a : Type) = {
  Ext_DataAddr_OK : virtaddr,    // Address to use for the data access
  Ext_DataAddr_Error : 'a
}
