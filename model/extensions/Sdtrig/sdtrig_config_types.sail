// =======================================================================================
// This Sail RISC-V architecture model, comprising all files and
// directories except where otherwise noted is subject the BSD
// two-clause license in the LICENSE file.
//
// SPDX-License-Identifier: BSD-2-Clause
// =======================================================================================

// If Sdtrig is implemented, at least one trigger is supported.
// Config validation ensures `num_triggers` > zero in that case,
// while schema validation ensures `num_triggers` is non-negative.

let data_access_size_supports_8bits   : bool = config extensions.Sdtrig.mcontrol6.supported_data_access_sizes.bits8
let data_access_size_supports_16bits  : bool = config extensions.Sdtrig.mcontrol6.supported_data_access_sizes.bits16
let data_access_size_supports_32bits  : bool = config extensions.Sdtrig.mcontrol6.supported_data_access_sizes.bits32
let data_access_size_supports_48bits  : bool = config extensions.Sdtrig.mcontrol6.supported_data_access_sizes.bits48
let data_access_size_supports_64bits  : bool = config extensions.Sdtrig.mcontrol6.supported_data_access_sizes.bits64

let address_access_size_supports_8bits   : bool = config extensions.Sdtrig.mcontrol6.supported_address_access_sizes.bits8
let address_access_size_supports_16bits  : bool = config extensions.Sdtrig.mcontrol6.supported_address_access_sizes.bits16
let address_access_size_supports_32bits  : bool = config extensions.Sdtrig.mcontrol6.supported_address_access_sizes.bits32
let address_access_size_supports_48bits  : bool = config extensions.Sdtrig.mcontrol6.supported_address_access_sizes.bits48
let address_access_size_supports_64bits  : bool = config extensions.Sdtrig.mcontrol6.supported_address_access_sizes.bits64
let address_access_size_supports_128bits : bool = config extensions.Sdtrig.mcontrol6.supported_address_access_sizes.bits128

let mhselect_mcontext_match : bool = config extensions.Sdtrig.textra.mhselect.mcontext_match
let mhselect_vmid_match : bool = config extensions.Sdtrig.textra.mhselect.vmid_match

let sselect_scontext_match : bool = config extensions.Sdtrig.textra.sselect.scontext_match
let sselect_asid_match : bool = config extensions.Sdtrig.textra.sselect.asid_match

let icount_count_is_hardwired_one : bool = config extensions.Sdtrig.icount.count_hardwired_one
let icount_self_write_sets_pending : bool = config extensions.Sdtrig.icount.self_write_sets_pending
