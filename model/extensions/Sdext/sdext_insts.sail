//=======================================================================================
//  This Sail RISC-V architecture model, comprising all files and
//  directories except where otherwise noted is subject the BSD
//  two-clause license in the LICENSE file.
//
//  SPDX-License-Identifier: BSD-2-Clause
//=======================================================================================

// This file specifies the `dret` instruction in the `Sdext` extension.

union clause instruction = DRET : unit

mapping clause encdec = DRET()
  <-> 0b01111011001000000000000001110011
  when currentlyEnabled(Ext_Sdext) & not(in_debug_abstract_command())

function clause execute DRET() =
  Debug(Exit_Debug_Mode())
