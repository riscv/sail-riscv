// =======================================================================================
// This Sail RISC-V architecture model, comprising all files and
// directories except where otherwise noted is subject the BSD
// two-clause license in the LICENSE file.
//
// SPDX-License-Identifier: BSD-2-Clause
// =======================================================================================

termination_measure virtual_memory_supported(_) = 3

// get_xLPE() and currentlyEnabled() are mutually recursive
termination_measure get_xLPE(_) = 2

function hartSupports_measure(ext : extension) -> int =
  match ext {
    Ext_D => 1,
    Ext_V => 1,
    Ext_Zvkn => 1,
    Ext_Zvks => 1,
    Ext_C => 2,
    Ext_Zvknc => 2,
    Ext_Zvkng => 2,
    Ext_Zvksc => 2,
    Ext_Zvksg => 2,
    _ => 0,
  }

termination_measure hartSupports(ext) = hartSupports_measure(ext)

// Termination measures for loops are not supported by the Lean backend, so they
// should be guarded by this condition:
$iftarget coq

termination_measure vmem_write_addr repeat n
termination_measure vmem_read_addr repeat n

// The top-level loop isn't terminating, but we put a limit so that it can still be included in the Coq output
termination_measure loop while 100

$endif
