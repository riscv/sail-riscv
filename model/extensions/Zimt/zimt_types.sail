// =======================================================================================
// This Sail RISC-V architecture model, comprising all files and
// directories except where otherwise noted is subject the BSD
// two-clause license in the LICENSE file.
//
// SPDX-License-Identifier: BSD-2-Clause
// =======================================================================================

// Types for the Zimt memory tagging extension (v0.2, DRAFT).
// https://github.com/riscv/riscv-memory-tagging

// Width in bits of the tag carried in the masked bits of a pointer.
// 0 means memory tagging is disabled.
type pointer_tag_width_t = {0, 4, 7}

// Width in bits of the tag associated with a memory chunk in the tag
// table. 0 means memory tagging is disabled.
type mc_tag_width_t = {0, 4, 8}

// Encodings of the 2-bit MT_MODE field in mseccfg, menvcfg, senvcfg
// and henvcfg (and of hstatus.VUMT_MODE).
enum MemTaggingMode = {
  MT_MODE_Disabled,
  MT_MODE_Reserved,
  MT_MODE_Tag4,     // pointer_tag_width = 4, mc_tag_width = 4
  MT_MODE_Tag7,     // pointer_tag_width = 7, mc_tag_width = 8
}

mapping mt_mode : MemTaggingMode <-> bits(2) = {
  MT_MODE_Disabled <-> 0b00,
  MT_MODE_Reserved <-> 0b01,
  MT_MODE_Tag4     <-> 0b10,
  MT_MODE_Tag7     <-> 0b11,
}

// Return whether the given MT_MODE value is supported. An
// implementation of Zimt must support pointer_tag_width = 4;
// pointer_tag_width = 7 is optional.
function is_supported_mt_mode(mode : MemTaggingMode) -> bool = match mode {
  MT_MODE_Disabled => true,
  MT_MODE_Reserved => false,
  MT_MODE_Tag4     => config extensions.Zimt.supported_pointer_tag_width_4,
  MT_MODE_Tag7     => config extensions.Zimt.supported_pointer_tag_width_7,
}

function pointer_tag_width(mode : MemTaggingMode) -> pointer_tag_width_t = match mode {
  MT_MODE_Disabled => 0,
  MT_MODE_Reserved => 0,
  MT_MODE_Tag4     => 4,
  MT_MODE_Tag7     => 7,
}

function mc_tag_width(mode : MemTaggingMode) -> mc_tag_width_t = match mode {
  MT_MODE_Disabled => 0,
  MT_MODE_Reserved => 0,
  MT_MODE_Tag4     => 4,
  MT_MODE_Tag7     => 8,
}

// pointer_tag width of an enabled (non-disabled, non-reserved) mode.
type zimt_tag_width = {4, 7}

function enabled_pointer_tag_width(mode : MemTaggingMode) -> zimt_tag_width =
  match mode {
    MT_MODE_Tag7 => 7,
    _            => 4,
  }
