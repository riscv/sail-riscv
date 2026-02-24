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

function sstc_CSRs_accessible(priv : Privilege) -> result(unit, (csr_access_failure, csr_access_failure_reason)) =
  match priv {
    Machine => Ok(()),
    Supervisor => if mcounteren[TM] == 0b1 & menvcfg[STCE] == 0b1
                  then Ok(()) else Err(CSR_Access_Illegal, CSR_Access_Failed_Condition()),
    VirtualSupervisor =>
      // This CSR address is proxying vstimecmp.
      if not(mcounteren[TM] == 0b1 & menvcfg[STCE] == 0b1)
      then return Err(CSR_Access_Illegal, CSR_Access_Failed_Condition())
      else
        // TODO: use the below instead for hypervisor
        // if not(hcounteren[TM] == 0b1 & henvcfg[STCE] == 0b1)
        // then return Err(CSR_Access_Virtual)
        // else Ok(())
        Err(CSR_Access_Illegal, CSR_Access_Failed_Condition()),
    User => Err(CSR_Access_Illegal, CSR_Access_Insufficient_Privilege()),
    VirtualUser => Err(CSR_Access_Illegal, CSR_Access_Insufficient_Privilege()),
  }

function clause is_CSR_accessible(0x14D, priv, _access_type) =
  if not(currentlyEnabled(Ext_S) & currentlyEnabled(Ext_Sstc))
  then return Err(CSR_Access_Illegal, CSR_Access_Disabled_Extension())
  else sstc_CSRs_accessible(priv)

function clause is_CSR_accessible(0x15D, priv, _) =
  if not(currentlyEnabled(Ext_S) & currentlyEnabled(Ext_Sstc) & xlen == 32)
  then Err(CSR_Access_Illegal, CSR_Access_Disabled_Extension())
  else sstc_CSRs_accessible(priv)

function clause read_CSR(0x14D) = stimecmp[xlen - 1 .. 0]
function clause read_CSR(0x15D if xlen == 32) = stimecmp[63 .. 32]

function clause write_CSR(0x14D, value) = { stimecmp[(xlen - 1) .. 0] = value; Ok(stimecmp[xlen - 1 ..0]) }
function clause write_CSR((0x15D, value) if xlen == 32) = { stimecmp[63 ..32] = value; Ok(stimecmp[63 .. 32]) }
