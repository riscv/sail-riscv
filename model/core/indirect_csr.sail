// =======================================================================================
// This Sail RISC-V architecture model, comprising all files and
// directories except where otherwise noted is subject the BSD
// two-clause license in the LICENSE file.
//
// SPDX-License-Identifier: BSD-2-Clause
// =======================================================================================

// Indirect CSR access framework (Smcsrind / Sscsrind).
//
// This provides the miselect/mireg and siselect/sireg indirection
// registers, together with a scattered dispatch mechanism keyed on
// the current *iselect value. Extensions such as the AIA (Smaia/Ssaia)
// register clauses of indirect_read/indirect_write to expose their
// indirectly-accessed registers without having to touch this file.
//
// The dispatch functions take the privilege level at which the access
// is being performed (Machine or Supervisor), so that a single select
// value can map to different underlying state for the M and S views.
//
// See the "RISC-V Indirect CSR Access" specification (Smcsrind/Sscsrind)
// and the AIA specification for the required behaviour.

// The select registers are WARL. Without an IMSIC, the AIA only requires
// the iprio array region (0x30 .. 0x3F for the machine level and the
// analogous supervisor region). We allow the full low range so that
// future extensions (e.g. IMSIC file selects) can register handlers.
//
// The width of the select registers is xlen, but only a small number of
// low bits are meaningful in this configuration. Bits that are not needed
// to represent any implemented select value read as zero.

// Reset value is unspecified by the spec; we choose zero.
register miselect : xlenbits = zeros()
register siselect : xlenbits = zeros()

// A scattered function that indicates whether a given (privilege, select)
// pair has an implemented indirect register. Handlers register a clause
// returning true. The default (see postlude/csr_end.sail-style fallback
// below) returns false, which causes an illegal instruction.
val indirect_csr_implemented : (Privilege, xlenbits) -> bool
scattered function indirect_csr_implemented

// Read the indirectly-selected register. Only called when
// indirect_csr_implemented(priv, select) is true.
val indirect_read : (Privilege, xlenbits) -> xlenbits
scattered function indirect_read

// Write the indirectly-selected register. Only called when
// indirect_csr_implemented(priv, select) is true. The value is already
// the full xlen value to write; handlers apply their own WARL masking.
val indirect_write : (Privilege, xlenbits) -> unit
scattered function indirect_write

// Default fallbacks: no register implemented. NOTE: because scattered
// function clauses are matched in definition order, the catch-all
// defaults must be the LAST clauses. They are therefore defined in the
// postlude (postlude/csr_end.sail) after all extensions (e.g. AIA) have
// registered their specific clauses.


// Legalize a value written to an *iselect register. We keep it simple and
// store the value as-is (masked to xlen); illegal-select detection happens
// at *ireg access time via indirect_csr_implemented.
function legalize_iselect(v : xlenbits) -> xlenbits = v

// -------------------------------------------------------------------------
// miselect (0x350) and mireg (0x351)
// -------------------------------------------------------------------------

mapping clause csr_name_map = 0x350 <-> "miselect"
mapping clause csr_name_map = 0x351 <-> "mireg"

function clause is_CSR_accessible(0x350, _, _) = currentlyEnabled(Ext_Smcsrind)

function clause read_CSR(0x350) = miselect

function clause write_CSR(0x350, value) = {
  miselect = legalize_iselect(value);
  Ok(miselect)
}

function clause read_CSR(0x351) =
  if indirect_csr_implemented(Machine, miselect)
  then indirect_read(Machine, miselect)
  else zeros() // Should not be reached: access check below guards it.

// mireg is only accessible when the currently-selected value is
// implemented; otherwise accessing it raises an illegal instruction.
function clause is_CSR_accessible(0x351, _, _) =
  currentlyEnabled(Ext_Smcsrind) & indirect_csr_implemented(Machine, miselect)

function clause write_CSR(0x351, value) = {
  indirect_write(Machine, miselect);
  let _ = value;
  Ok(indirect_read(Machine, miselect))
}

// -------------------------------------------------------------------------
// siselect (0x150) and sireg (0x151)
// -------------------------------------------------------------------------

mapping clause csr_name_map = 0x150 <-> "siselect"
mapping clause csr_name_map = 0x151 <-> "sireg"

// Note: access to the supervisor-level indirect CSRs (siselect/sireg)
// from a privilege below M is additionally gated by the mstateen0.CSRIND
// bit (and hstateen0 for VS/VU) when Smstateen is implemented. Because of
// module interdependency (core cannot depend on Stateen), that gate is
// applied centrally in `stateen_allows_CSR_access`.
function clause is_CSR_accessible(0x150, _, _) = currentlyEnabled(Ext_Sscsrind)

function clause read_CSR(0x150) = siselect

function clause write_CSR(0x150, value) = {
  siselect = legalize_iselect(value);
  Ok(siselect)
}

function clause is_CSR_accessible(0x151, _, _) =
  currentlyEnabled(Ext_Sscsrind) & indirect_csr_implemented(Supervisor, siselect)

function clause read_CSR(0x151) =
  if indirect_csr_implemented(Supervisor, siselect)
  then indirect_read(Supervisor, siselect)
  else zeros()

function clause write_CSR(0x151, value) = {
  indirect_write(Supervisor, siselect);
  let _ = value;
  Ok(indirect_read(Supervisor, siselect))
}
