/*=======================================================================================*/
/*  This Sail RISC-V architecture model, comprising all files and                        */
/*  directories except where otherwise noted is subject the BSD                          */
/*  two-clause license in the LICENSE file.                                              */
/*                                                                                       */
/*  SPDX-License-Identifier: BSD-2-Clause                                                */
/*=======================================================================================*/

// TODO: Ext_H depends on RV32I or RV64I, not RV32E or RV64E.
function clause currentlyEnabled(Ext_H) = hartSupports(Ext_H) & misa[H] == 0b1 & virtual_memory_supported()
