// =======================================================================================
// This Sail RISC-V architecture model, comprising all files and
// directories except where otherwise noted is subject the BSD
// two-clause license in the LICENSE file.
//
// SPDX-License-Identifier: BSD-2-Clause
// =======================================================================================

// Snapshot support functions for saving and restoring architectural state.

// Get PC values
function snapshot_get_pc() -> (xlenbits, xlenbits) = (PC, nextPC)

// Set PC values
function snapshot_set_pc(pc : xlenbits, next_pc : xlenbits) -> unit = {
  PC = pc;
  nextPC = next_pc;
}

// Get all integer registers
function snapshot_get_xregs() -> vector(32, xlenbits) = {
  var regs : vector(32, xlenbits) = vector_init(32, zeros());
  foreach (i from 0 to 31) {
    regs[i] = rX_bits(regidx_offset_range(zreg, i));
  };
  regs
}

// Set all integer registers
function snapshot_set_xregs(regs : vector(32, xlenbits)) -> unit = {
  foreach (i from 0 to 31) {
    wX_bits(regidx_offset_range(zreg, i), regs[i]);
  }
}

// Get all floating point registers (if extension enabled)
function snapshot_get_fregs() -> vector(32, flenbits) = {
  if hartSupports(Ext_F) | hartSupports(Ext_D) then {
    var regs : vector(32, flenbits) = vector_init(32, zeros());
    foreach (i from 0 to 31) {
      regs[i] = rF_bits(Fregidx(to_bits(5, i)));
    };
    regs
  } else {
    vector_init(32, zeros())
  }
}

// Set all floating point registers (if extension enabled)
function snapshot_set_fregs(regs : vector(32, flenbits)) -> unit = {
  if hartSupports(Ext_F) | hartSupports(Ext_D) then {
    foreach (i from 0 to 31) {
      wF_bits(Fregidx(to_bits(5, i)), regs[i]);
    }
  }
}

// Get all vector registers (if extension enabled)
function snapshot_get_vregs() -> vector(32, vlenbits) = {
  if hartSupports(Ext_V) then {
    var regs : vector(32, vlenbits) = vector_init(32, zeros());
    foreach (i from 0 to 31) {
      regs[i] = rV_bits(Vregidx(to_bits(5, i)));
    };
    regs
  } else {
    vector_init(32, zeros())
  }
}

// Set all vector registers (if extension enabled)
function snapshot_set_vregs(regs : vector(32, vlenbits)) -> unit = {
  if hartSupports(Ext_V) then {
    foreach (i from 0 to 31) {
      wV_bits(Vregidx(to_bits(5, i)), regs[i]);
    }
  }
}

// Check if a CSR is readable and get its value
// Returns Some(value) if accessible, None otherwise
function snapshot_try_read_csr(addr : bits(12)) -> option(xlenbits) = {
  if is_CSR_accessible(addr, cur_privilege, CSRRead) then {
    // Note: read_CSR may fail if no clause exists, but is_CSR_accessible
    // should prevent this. The C++ side will handle any exceptions.
    Some(read_CSR(addr))
  } else {
    None()
  }
}

// Set a CSR value
function snapshot_set_csr(addr : bits(12), value : xlenbits) -> unit = {
  match write_CSR(addr, value) {
    Ok(_) => (),
    Err(_) => internal_error(__FILE__, __LINE__, "Failed to write CSR in snapshot restore")
  }
}

