// =======================================================================================
// This Sail RISC-V architecture model, comprising all files and
// directories except where otherwise noted is subject the BSD
// two-clause license in the LICENSE file.
//
// SPDX-License-Identifier: BSD-2-Clause
// =======================================================================================

// Sstc - supervisor time compare
mapping clause csr_name_map = 0x14D  <-> "stimecmp"
mapping clause csr_name_map = 0x15D  <-> "stimecmph"

function sstc_CSRs_accessible(priv : Privilege) -> bool =
    priv == Machine | (priv == Supervisor & mcounteren[TM] == 0b1 & menvcfg[STCE] == 0b1)

function clause is_CSR_accessible(0x14D, priv, _) =
    if currentlyEnabled(Ext_S) & currentlyEnabled(Ext_Sstc) then
        if sstc_CSRs_accessible(priv) then CSRAccessSuccess else CSRAccessIllegal
    else CSRNotExist

function clause is_CSR_accessible(0x15D, priv, _) =
    if currentlyEnabled(Ext_S) & currentlyEnabled(Ext_Sstc) & xlen == 32 then
        if sstc_CSRs_accessible(priv) then CSRAccessSuccess else CSRAccessIllegal
    else CSRNotExist

function clause read_CSR(0x14D) = stimecmp[xlen - 1 .. 0]
function clause read_CSR(0x15D if xlen == 32) = stimecmp[63 .. 32]

function clause write_CSR(0x14D, value) = { stimecmp[(xlen - 1) .. 0] = value; Ok(stimecmp[xlen - 1 ..0]) }
function clause write_CSR((0x15D, value) if xlen == 32) = { stimecmp[63 ..32] = value; Ok(stimecmp[63 .. 32]) }
