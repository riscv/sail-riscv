// =======================================================================================
// This Sail RISC-V architecture model, comprising all files and
// directories except where otherwise noted is subject the BSD
// two-clause license in the LICENSE file.
//
// SPDX-License-Identifier: BSD-2-Clause
// =======================================================================================

// Type constraint that checks if 'v is a valid virtual memory mode size.
type is_sv_mode('v) -> Bool = 'v in {32, 39, 48, 57}

// Range of possible page levels depending on the virtual memory mode:
//
//   Sv32 = range(0, 1)
//   Sv39 = range(0, 2)
//   Sv48 = range(0, 3)
//   Sv57 = range(0, 4)
//
type level_range('v), is_sv_mode('v) =
  range(0, (if 'v == 32 then 1 else (if 'v == 39 then 2 else (if 'v == 48 then 3 else 4))))

// Size of a Page Table Entry, depending on the virtual memory mode.
type pte_bits('v), is_sv_mode('v) = bits(if 'v == 32 then 32 else 64)

// Number of Physical Page Number bits, depending on the virtual memory mode.
type ppn_bits('v), is_sv_mode('v) = bits(if 'v == 32 then 22 else 44)

// Number of Virtual Page Number bits, depending on the virtual memory mode.
type vpn_bits('v), is_sv_mode('v) = bits('v - pagesize_bits)


// Extensions for memory Accesstype.

type ext_access_type = unit

let Data  : ext_access_type = ()

let default_write_acc : ext_access_type = Data

function accessType_to_str(a : MemoryAccessType(ext_access_type)) -> string =
  match (a) {
    Load(_)            => "R",
    Store(_)           => "W",
    LoadStore(_, _)    => "RW",
    InstructionFetch() => "X",
  }

overload to_str = {accessType_to_str}
