// =======================================================================================
// This Sail RISC-V architecture model, comprising all files and
// directories except where not noted, is subject the BSD
// two-clause license in the LICENSE file.
//
// SPDX-License-Identifier: BSD-2-Clause
// =======================================================================================

// Maximum SDID bit width per the spec (SDIDMAX = 6).
// The actual implemented SDID width (SDIDLEN), determined by hardware.
// For the simulator we use the maximum.
let sdidlen : range(0, 6) = config extensions.Smsdid.sdid_len

enum MmptMode = {
  SmmptBare,
  Smmpt34,
  Smmpt43,
  Smmpt52,
  Smmpt64,
}

bitfield Mmpt32 : bits(32) = {
  MODE : 31 .. 30,
  SDID : 27 .. 22,
  PPN  : 21 .. 0,
}

bitfield Mmpt64 : bits(64) = {
  MODE : 63 .. 60,
  SDID : 57 .. 52,
  PPN  : 43 .. 0,
}

// Extract MODE field from mmpt CSR value.
function extract_mmpt_mode(value : xlenbits) -> MmptMode = {
  if xlen == 32 then {
    let v = Mk_Mmpt32(value);
    match v[MODE] {
      0b00 => SmmptBare,
      0b01 => Smmpt34,
      _    => internal_error(__FILE__, __LINE__, "Reserved for future use"),
    }
  }
  else {
    let v = Mk_Mmpt64(value);
    match v[MODE] {
      0b0000 => SmmptBare,
      0b0001 => Smmpt43,
      0b0010 => Smmpt52,
      0b0011 => Smmpt64,
      _      => internal_error(__FILE__, __LINE__, "Reserved for future use"),
    }
  }
}
