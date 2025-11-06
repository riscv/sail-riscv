// =======================================================================================
// This Sail RISC-V architecture model, comprising all files and
// directories except where otherwise noted is subject the BSD
// two-clause license in the LICENSE file.
//
// SPDX-License-Identifier: BSD-2-Clause
// =======================================================================================

termination_measure pt_walk(_,_,_,_,_,_,_,level,_, _) = level

// When adding a new extension X, we need to make sure that if X being enabled
// depends on Y being enabled, then the value associated to X is _greater_ than
// the value associated to Y. The default value is 2, so that if it does not
// depend on anything or only on extensions A, B, C, D, F, M, S, Zve32x, Zvl* or Zicsr,
// nothing needs to be done.
function currentlyEnabled_measure(ext : extension) -> int =
  match ext {
    Ext_Zicsr => 0,
    Ext_A => 1,
    Ext_B => 1,
    Ext_C => 1,
    Ext_D => 1,
    Ext_F => 1,
    Ext_M => 1,
    Ext_S => 1,
    Ext_V => 5,
    Ext_H => 4,
    Ext_Smcntrpmf => 3,
    Ext_Zabha => 3,
    Ext_Zacas => 3,
    Ext_Zcb => 3,
    Ext_Zcd => 3,
    Ext_Zcf => 3,
    Ext_Zcmop => 3,
    Ext_Zfhmin => 3,
    Ext_Zhinx => 3,
    Ext_Zicfilp => 3,
    Ext_Zvl32b => 0,
    Ext_Zvl64b => 0,
    Ext_Zvl128b => 0,
    Ext_Zvl256b => 0,
    Ext_Zvl512b => 0,
    Ext_Zvl1024b => 0,
    Ext_Zve32x => 1,
    Ext_Zvfbfmin => 3,
    Ext_Zvfbfwma => 4,
    Ext_Zve64f => 3,
    Ext_Zve64d => 4,
    Ext_Zvfh => 4,
    Ext_Zvfhmin => 5,
    Ext_Zvbb => 6,
    Ext_Zvbc => 6,
    Ext_Zvkb => 7,
    Ext_Zvkg => 6,
    Ext_Zvkned => 6,
    Ext_Zvknha => 6,
    Ext_Zvknhb => 6,
    Ext_Zvksed => 6,
    Ext_Zvksh => 6,
    Ext_Sscofpmf => 3,
    Ext_Svrsw60t59b => 3,
    Ext_Zhinxmin => 4,
    _ => 2
  }

termination_measure currentlyEnabled(ext) = currentlyEnabled_measure(ext)
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
