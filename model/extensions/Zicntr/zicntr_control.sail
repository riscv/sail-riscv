// =======================================================================================
// This Sail RISC-V architecture model, comprising all files and
// directories except where otherwise noted is subject the BSD
// two-clause license in the LICENSE file.
//
// SPDX-License-Identifier: BSD-2-Clause
// =======================================================================================
function clause currentlyEnabled(Ext_Zicntr) = hartSupports(Ext_Zicntr) & currentlyEnabled(Ext_Zicsr)

// unprivileged counters/timers
mapping clause csr_name_map = 0xC00  <-> "cycle"
mapping clause csr_name_map = 0xC01  <-> "time"
mapping clause csr_name_map = 0xC02  <-> "instret"
mapping clause csr_name_map = 0xC80  <-> "cycleh"
mapping clause csr_name_map = 0xC81  <-> "timeh"
mapping clause csr_name_map = 0xC82  <-> "instreth"

function clause is_CSR_accessible(0xC00, priv, access_type) = {
  if not(currentlyEnabled(Ext_Zicntr)) then return Err(CSR_Access_Illegal, CSR_Access_Disabled_Extension());
  if not(privLevel_is_virtual(priv)) & default_CSR_access_allowed(0xC00, priv, access_type) & counter_enabled(0, priv) then return Ok(());
  // TODO: For VS/VU, check hcounteren and mcounteren.
  Err(CSR_Access_Illegal, CSR_Access_Failed_Condition())
}
function clause is_CSR_accessible(0xC01, priv, access_type) = {
  if not(currentlyEnabled(Ext_Zicntr)) then return Err(CSR_Access_Illegal, CSR_Access_Disabled_Extension());
  if not(privLevel_is_virtual(priv)) & default_CSR_access_allowed(0xC01, priv, access_type) & counter_enabled(1, priv) then return Ok(());
  // TODO: For VS/VU, check hcounteren and mcounteren.
  Err(CSR_Access_Illegal, CSR_Access_Failed_Condition())
}
function clause is_CSR_accessible(0xC02, priv, access_type) = {
  if not(currentlyEnabled(Ext_Zicntr)) then return Err(CSR_Access_Illegal, CSR_Access_Disabled_Extension());
  if not(privLevel_is_virtual(priv)) & default_CSR_access_allowed(0xC02, priv, access_type) & counter_enabled(2, priv) then return Ok(());
  // TODO: For VS/VU, check hcounteren and mcounteren.
  Err(CSR_Access_Illegal, CSR_Access_Failed_Condition())
}
function clause is_CSR_accessible(0xC80, priv, access_type) = {
  if not(currentlyEnabled(Ext_Zicntr) & xlen == 32) then return Err(CSR_Access_Illegal, CSR_Access_Disabled_Extension());
  if not(privLevel_is_virtual(priv)) & default_CSR_access_allowed(0xC80, priv, access_type) & counter_enabled(0, priv) then return Ok(());
  // TODO: For VS/VU, check hcounteren and mcounteren.
  Err(CSR_Access_Illegal, CSR_Access_Failed_Condition())
}
function clause is_CSR_accessible(0xC81, priv, access_type) = {
  if not(currentlyEnabled(Ext_Zicntr) & xlen == 32) then return Err(CSR_Access_Illegal, CSR_Access_Disabled_Extension());
  if not(privLevel_is_virtual(priv)) & default_CSR_access_allowed(0xC81, priv, access_type) & counter_enabled(1, priv) then return Ok(());
  // TODO: For VS/VU, check hcounteren and mcounteren.
  Err(CSR_Access_Illegal, CSR_Access_Failed_Condition())
}
function clause is_CSR_accessible(0xC82, priv, access_type) = {
  if not(currentlyEnabled(Ext_Zicntr) & xlen == 32) then return Err(CSR_Access_Illegal, CSR_Access_Disabled_Extension());
  if not(privLevel_is_virtual(priv)) & default_CSR_access_allowed(0xC82, priv, access_type) & counter_enabled(2, priv) then return Ok(());
  // TODO: For VS/VU, check hcounteren and mcounteren.
  Err(CSR_Access_Illegal, CSR_Access_Failed_Condition())
}

function clause read_CSR(0xC00) = mcycle[(xlen - 1) .. 0]
function clause read_CSR(0xC01) = mtime[(xlen - 1) .. 0]
function clause read_CSR(0xC02) = minstret[(xlen - 1) .. 0]
function clause read_CSR(0xC80 if xlen == 32) = mcycle[63 .. 32]
function clause read_CSR(0xC81 if xlen == 32) = mtime[63 .. 32]
function clause read_CSR(0xC82 if xlen == 32) = minstret[63 .. 32]


// machine counters/timers
mapping clause csr_name_map = 0xB00  <-> "mcycle"
mapping clause csr_name_map = 0xB02  <-> "minstret"
mapping clause csr_name_map = 0xB80  <-> "mcycleh"
mapping clause csr_name_map = 0xB82  <-> "minstreth"

function clause is_CSR_accessible(0xB00, priv, access_type) = // mcycle
  check_CSR_access(0xB00, priv, access_type, currentlyEnabled(Ext_Zicntr))
function clause is_CSR_accessible(0xB02, priv, access_type) = // minstret
  check_CSR_access(0xB02, priv, access_type, currentlyEnabled(Ext_Zicntr))
function clause is_CSR_accessible(0xB80, priv, access_type) = // mcycleh
  check_CSR_access(0xB80, priv, access_type, currentlyEnabled(Ext_Zicntr) & xlen == 32)
function clause is_CSR_accessible(0xB82, priv, access_type) = // minstreth
  check_CSR_access(0xB82, priv, access_type, currentlyEnabled(Ext_Zicntr) & xlen == 32)

function clause read_CSR(0xB00) = mcycle[(xlen - 1) .. 0]
function clause read_CSR(0xB02) = minstret[(xlen - 1) .. 0]
function clause read_CSR(0xB80 if xlen == 32)= mcycle[63 .. 32]
function clause read_CSR(0xB82 if xlen == 32) = minstret[63 .. 32]

function clause write_CSR(0xB00, value) = { mcycle[(xlen - 1) .. 0] = value; Ok(value) }
function clause write_CSR(0xB02, value) = { minstret[(xlen - 1) .. 0] = value; minstret_increment = false; Ok(value) }
function clause write_CSR((0xB80, value) if xlen == 32) = { mcycle[63 .. 32] = value; Ok(value) }
function clause write_CSR((0xB82, value) if xlen == 32) = { minstret[63 .. 32] = value; minstret_increment = false; Ok(value) }
