// =======================================================================================
// This Sail RISC-V architecture model, comprising all files and
// directories except where not noted, is subject the BSD
// two-clause license in the LICENSE file.
//
// SPDX-License-Identifier: BSD-2-Clause
// =======================================================================================

function clause currentlyEnabled(Ext_Smsdid) = hartSupports(Ext_Smsdid) & currentlyEnabled(Ext_Zicsr)

private function legalize_mmpt(o : xlenbits, v : xlenbits) -> xlenbits = {
  if xlen == 32 then {
    let v = Mk_Mmpt32(v);
    let o = Mk_Mmpt32(o);
    let legal_mode = if v[MODE][1] != zeros() then o[MODE] else v[MODE];
    let final_sdid : bits(6) = if sdidlen == 0 then zeros() else zero_extend(v[SDID][sdidlen - 1 .. 0]);
    [v with
      MODE = legal_mode,
      SDID = if legal_mode == zeros() then zeros() else final_sdid,
      PPN = if legal_mode == zeros() then zeros() else v[PPN]
    ].bits
  }
  else {
    let v = Mk_Mmpt64(v);
    let o = Mk_Mmpt64(o);
    let legal_mode = if v[MODE][3 .. 2] != zeros() then o[MODE] else v[MODE];
    let final_sdid : bits(6) = if sdidlen == 0 then zeros() else zero_extend(v[SDID][sdidlen - 1 .. 0]);
    [v with
      MODE = legal_mode,
      SDID = if legal_mode == zeros() then zeros() else final_sdid,
      PPN = if legal_mode == zeros() then zeros() else v[PPN]
    ].bits
  }
}

register mmpt : xlenbits

bitfield Msdcfg_ent : xlenbits = {
  // Higher bits are WPRI
  SML  : 31 .. 28,  // Supervisor domain Monitor Level
  SRL  : 27 .. 24,  // Supervisor domain Resource Level
  SSMM : 23,        // Supervisor domain M-mode Resource monitor
  SSRM : 22,        // Supervisor domain S-mode Resource monitor
  // [21:8] WPRI
  SETA : 7,         // Supervisor External Trace Allow
  SEDA : 6,         // Supervisor External Debug Allow
  SIDN : 5 .. 0,    // Supervisor Interrupt Domain Number
}

register msdcfg : Msdcfg_ent

mapping clause csr_name_map = 0x382  <-> "mmpt"
mapping clause csr_name_map = 0x74E  <-> "msdcfg"

// mmpt (0x382) - Machine-mode Memory Protection Table
function clause is_CSR_accessible(0x382, p, _) = currentlyEnabled(Ext_Smsdid) & (p == Machine)

function clause read_CSR(0x382) = mmpt

function clause write_CSR(0x382, value) = { mmpt = legalize_mmpt(mmpt, value); Ok(mmpt) }

// msdcfg (0x74E) - Machine supervisor domain configuration
// The SIDN, SEDA, SETA fields are controlled by sub-extensions.
// When no sub-extensions are implemented, this CSR is read-only zero
// except for fields controlled by Smsdid itself.
function clause is_CSR_accessible(0x74E, p, _) = currentlyEnabled(Ext_Smsdid) & (p == Machine)

function clause read_CSR(0x74E) = msdcfg.bits

function clause write_CSR(0x74E, value) = {
  // Only fields belonging to implemented extensions are writable.
  // For Phase 1, all sub-extension fields are read-only zero,
  // so this is effectively a no-op write (WARL behavior).
  // SIDN, SEDA, SETA, SSRM, SSMM, SRL, SML are all controlled by
  // sub-extensions not yet implemented. Preserve old value.
  Ok(msdcfg.bits)
}
