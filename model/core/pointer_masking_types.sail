//=======================================================================================
//  This Sail RISC-V architecture model, comprising all files and
//  directories except where otherwise noted is subject the BSD
//  two-clause license in the LICENSE file.
//
//  SPDX-License-Identifier: BSD-2-Clause
//=======================================================================================

function clause currentlyEnabled(Ext_Ssnpm) = hartSupports(Ext_Ssnpm) & currentlyEnabled(Ext_S) & (xlen != 32)
function clause currentlyEnabled(Ext_Smmpm) = hartSupports(Ext_Smmpm) & (xlen != 32)
function clause currentlyEnabled(Ext_Smnpm) = hartSupports(Ext_Smnpm) & (xlen != 32)

function clause currentlyEnabled(Ext_Sspm) = hartSupports(Ext_Sspm) & currentlyEnabled(Ext_S)
function clause currentlyEnabled(Ext_Supm) = hartSupports(Ext_Supm) & currentlyEnabled(Ext_U)

enum PM_Ext = {PM_SSNPM, PM_SMNPM, PM_SMMPM}

enum PointerMaskingMode = {
  PMM_Disabled,
  PMM_Reserved,
  PMM_XLEN_57,
  PMM_XLEN_48,
}

mapping pmm_mode : PointerMaskingMode <-> bits(2) = {
  PMM_Disabled <-> 0b00,
  PMM_Reserved <-> 0b01,
  PMM_XLEN_57  <-> 0b10,
  PMM_XLEN_48  <-> 0b11,
}

function is_valid_pmm(ext : PM_Ext, pmm : PointerMaskingMode) -> bool = match (ext, pmm) {
  (_, PMM_Disabled) => true,
  (_, PMM_Reserved) => false,
  // SSNPM
  (PM_SSNPM, PMM_XLEN_57) => config extensions.Ssnpm.supported_xlen_57,
  (PM_SSNPM, PMM_XLEN_48) => config extensions.Ssnpm.supported_xlen_48,
  // SMMPM
  (PM_SMMPM, PMM_XLEN_57) => config extensions.Smmpm.supported_xlen_57,
  (PM_SMMPM, PMM_XLEN_48) => config extensions.Smmpm.supported_xlen_48,
  // SMNPM
  (PM_SMNPM, PMM_XLEN_57) => config extensions.Smnpm.supported_xlen_57,
  (PM_SMNPM, PMM_XLEN_48) => config extensions.Smnpm.supported_xlen_48,
}
