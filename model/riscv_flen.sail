// =======================================================================================
// This Sail RISC-V architecture model, comprising all files and
// directories except where otherwise noted is subject the BSD
// two-clause license in the LICENSE file.
//
// SPDX-License-Identifier: BSD-2-Clause
// =======================================================================================

// This is only a type because `if (config extensions.D.supported : bool) then 8 else 4`
// gives a syntax error: https://github.com/rems-project/sail/issues/1256
type ext_d_supported : Bool = config extensions.D.supported
type flen_bytes : Int = if ext_d_supported then 8 else 4

type flen       : Int = flen_bytes * 8
type flenbits         = bits(flen)

// Variable versions of the above types. Variables and types
// are disjoint in Sail so they are allowed to have the same name.
// This saves typing `sizeof()` everywhere.
let flen_bytes = sizeof(flen_bytes)
let flen = sizeof(flen)
