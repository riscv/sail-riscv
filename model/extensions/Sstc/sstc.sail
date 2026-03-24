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

private function stimecmp_accessible(priv : Privilege) -> bool =
  currentlyEnabled(Ext_S) & currentlyEnabled(Ext_Sstc) &
  (match priv {
    Machine           => true,
    Supervisor        => mcounteren[TM] == 0b1 & menvcfg[STCE] == 0b1,
    User              => false,
    VirtualSupervisor => mcounteren[TM] == 0b1 & menvcfg[STCE] == 0b1,
                         /* TODO: & hcounteren[TM] == 0b1 & henvcfg[STCE] == 0b1 */
    VirtualUser       => false,
  })

function clause is_CSR_accessible(0x14D, priv, _) = stimecmp_accessible(priv)
function clause is_CSR_accessible(0x15D, priv, _) = stimecmp_accessible(priv) & xlen == 32

// stimecmp raises virtual instruction exception in VS mode when
// mcounteren/menvcfg allow access but hcounteren/henvcfg block it
function clause is_CSR_exception_virtual(0x14D, p, _) =
  p == VirtualSupervisor &
  currentlyEnabled(Ext_S) & currentlyEnabled(Ext_Sstc) &
   mcounteren[TM] == 0b1  & menvcfg[STCE] == 0b1
   /* TODO: & (hcounteren[TM] == 0b0  | henvcfg[STCE] == 0b0) */

function clause is_CSR_exception_virtual(0x15D, p, _) =
  is_CSR_exception_virtual(0x14D, p, CSRRead) & xlen == 32

function clause read_CSR(0x14D) = stimecmp[xlen - 1 .. 0]
function clause read_CSR(0x15D if xlen == 32) = stimecmp[63 .. 32]

function clause write_CSR(0x14D, value) = { stimecmp[(xlen - 1) .. 0] = value; Ok(stimecmp[xlen - 1 .. 0]) }
function clause write_CSR((0x15D, value) if xlen == 32) = { stimecmp[63 .. 32] = value; Ok(stimecmp[63 .. 32]) }
