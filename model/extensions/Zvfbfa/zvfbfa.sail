// =======================================================================================
// This Sail RISC-V architecture model, comprising all files and
// directories except where otherwise noted is subject the BSD
// two-clause license in the LICENSE file.
//
// SPDX-License-Identifier: BSD-2-Clause
// =======================================================================================

function clause currentlyEnabled(Ext_Zvfbfa) =
  hartSupports(Ext_Zvfbfa) & currentlyEnabled(Ext_Zve32f) & currentlyEnabled(Ext_Zvfbfmin)
