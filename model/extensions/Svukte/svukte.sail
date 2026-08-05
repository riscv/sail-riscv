//=======================================================================================
// This Sail RISC-V architecture model, comprising all files and
// directories except where otherwise noted is subject the BSD
// two-clause license in the LICENSE file.
//
// SPDX-License-Identifier: BSD-2-Clause
//=======================================================================================

function is_svukte_qualified(effectivePrivilege : Privilege) -> bool =
  read_senvcfg()[UKTE] == 0b1 &
  translationMode(effectivePrivilege) != Bare &
  effectivePrivilege == User
