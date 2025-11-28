// =======================================================================================
// This Sail RISC-V architecture model, comprising all files and
// directories except where otherwise noted is subject the BSD
// two-clause license in the LICENSE file.
//
// SPDX-License-Identifier: BSD-2-Clause
// =======================================================================================

// The default metadata carries no information, and is implemented
// using a unit type.

type mem_meta = unit

let default_meta : mem_meta = ()

function __WriteRAM_Meta(_addr : physaddrbits, _width : mem_access_width, _meta : mem_meta) -> unit = ()

function __ReadRAM_Meta(_addr : physaddrbits, _width : mem_access_width) -> mem_meta = default_meta
