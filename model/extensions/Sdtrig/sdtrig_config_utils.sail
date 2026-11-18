// =======================================================================================
// This Sail RISC-V architecture model, comprising all files and
// directories except where otherwise noted is subject the BSD
// two-clause license in the LICENSE file.
//
// SPDX-License-Identifier: BSD-2-Clause
// =======================================================================================

function is_supported_match_size(s : bits(3), select : Compare_Selection) -> bool = {
  if not(trig_match_size_forwards_matches(s)) then return false;
  match select {
    // data compares are limited by the size of `tdata2`,
    // which is validated in `validate_config`.
    Compare_Data    => match trig_match_size(s) {
      0   => true,
      8   => data_access_size_supports_8bits,
      16  => data_access_size_supports_16bits,
      32  => data_access_size_supports_32bits,
      48  => data_access_size_supports_48bits,
      64  => data_access_size_supports_64bits,
      128 => false,
    },
    Compare_Address => match trig_match_size(s) {
      0   => true,
      8   => address_access_size_supports_8bits,
      16  => address_access_size_supports_16bits,
      32  => address_access_size_supports_32bits,
      48  => address_access_size_supports_48bits,
      64  => address_access_size_supports_64bits,
      128 => address_access_size_supports_128bits,
    },
  }
}
