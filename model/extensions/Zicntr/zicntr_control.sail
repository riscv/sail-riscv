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

function clause is_CSR_accessible(0xC00, priv, _) = if currentlyEnabled(Ext_Zicntr) then
                                                        if counter_enabled(0, priv) then CSRAccessSuccess else CSRAccessIllegal
                                                    else CSRNotExist // cycle
function clause is_CSR_accessible(0xC01, priv, _) = if currentlyEnabled(Ext_Zicntr) then
                                                        if counter_enabled(1, priv) then CSRAccessSuccess else CSRAccessIllegal
                                                    else CSRNotExist // time
function clause is_CSR_accessible(0xC02, priv, _) = if currentlyEnabled(Ext_Zicntr) then
                                                        if currentlyEnabled(Ext_Zicntr) & counter_enabled(2, priv) then CSRAccessSuccess else CSRAccessIllegal
                                                    else CSRNotExist // instret
function clause is_CSR_accessible(0xC80, priv, _) = if currentlyEnabled(Ext_Zicntr) & xlen == 32 then
                                                        if counter_enabled(0, priv) then CSRAccessSuccess else CSRAccessIllegal
                                                    else CSRNotExist // cycleh
function clause is_CSR_accessible(0xC81, priv, _) = if currentlyEnabled(Ext_Zicntr) & xlen == 32 then
                                                        if counter_enabled(1, priv) then CSRAccessSuccess else CSRAccessIllegal
                                                    else CSRNotExist // timeh
function clause is_CSR_accessible(0xC82, priv, _) = if currentlyEnabled(Ext_Zicntr) & xlen == 32 then
                                                        if counter_enabled(2, priv) then CSRAccessSuccess else CSRAccessIllegal
                                                    else CSRNotExist // instreth

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

function clause is_CSR_accessible(0xB00, _, _) = if currentlyEnabled(Ext_Zicntr) then CSRAccessSuccess else CSRNotExist // mcycle
function clause is_CSR_accessible(0xB02, _, _) = if currentlyEnabled(Ext_Zicntr) then CSRAccessSuccess else CSRNotExist // minstret
function clause is_CSR_accessible(0xB80, _, _) = if currentlyEnabled(Ext_Zicntr) & xlen == 32 then CSRAccessSuccess else CSRNotExist // mcycleh
function clause is_CSR_accessible(0xB82, _, _) = if currentlyEnabled(Ext_Zicntr) & xlen == 32 then CSRAccessSuccess else CSRNotExist // minstreth

function clause read_CSR(0xB00) = mcycle[(xlen - 1) .. 0]
function clause read_CSR(0xB02) = minstret[(xlen - 1) .. 0]
function clause read_CSR(0xB80 if xlen == 32)= mcycle[63 .. 32]
function clause read_CSR(0xB82 if xlen == 32) = minstret[63 .. 32]

function clause write_CSR(0xB00, value) = { mcycle[(xlen - 1) .. 0] = value; Ok(value) }
function clause write_CSR(0xB02, value) = { minstret[(xlen - 1) .. 0] = value; minstret_increment = false; Ok(value) }
function clause write_CSR((0xB80, value) if xlen == 32) = { mcycle[63 .. 32] = value; Ok(value) }
function clause write_CSR((0xB82, value) if xlen == 32) = { minstret[63 .. 32] = value; minstret_increment = false; Ok(value) }
