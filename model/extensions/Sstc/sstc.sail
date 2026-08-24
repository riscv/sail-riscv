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

private function is_stimecmp_accessible(priv : Privilege) -> bool =
  currentlyEnabled(Ext_S) & currentlyEnabled(Ext_Sstc) &
  (match priv {
    Machine           => true,
    Supervisor        => mcounteren[TM] == 0b1 & menvcfg[STCE] == 0b1,
    User              => false,
    VirtualSupervisor => mcounteren[TM] == 0b1 & menvcfg[STCE] == 0b1 &
                         hcounteren[TM] == 0b1 & read_henvcfg()[STCE] == 0b1,
    VirtualUser       => false,
  })

// The `stimecmp` and `vstimecmp` CSRs are defined in `core/interrupt_regs.sail`.
// Timer interrupts due to `stimecmp` and `vstimecsmp` are updated in
// `core/interrupt_regs:update_mip()`.

function clause is_CSR_accessible(0x14D, priv, _) = is_stimecmp_accessible(priv)
function clause is_CSR_accessible(0x15D, priv, _) = is_stimecmp_accessible(priv) & xlen == 32

function clause read_CSR(0x14D) =  if inVirtualPrivilege() then vstimecmp[xlen - 1 .. 0] else stimecmp[xlen - 1 .. 0]
function clause read_CSR(0x15D if xlen == 32) = if inVirtualPrivilege() then vstimecmp[63 .. 32] else stimecmp[63 .. 32]

function clause write_CSR(0x14D, value) =
  if inVirtualPrivilege()
  then { vstimecmp[(xlen - 1) .. 0] = value; Ok(vstimecmp[xlen - 1 .. 0]) }
  else { stimecmp[(xlen - 1) .. 0] = value; Ok(stimecmp[xlen - 1 .. 0]) }

function clause write_CSR((0x15D, value) if xlen == 32) =
  if inVirtualPrivilege()
  then { vstimecmp[63 .. 32] = value; Ok(vstimecmp[63 .. 32]) }
  else { stimecmp[63 .. 32] = value; Ok(stimecmp[63 .. 32]) }

// virtual supervisor timer compare
mapping clause csr_name_map = 0x24D  <-> "vstimecmp"
mapping clause csr_name_map = 0x25D  <-> "vstimecmph"

// "when the TM bit in the mcounteren register is clear, attempts to access the
// stimecmp or vstimecmp register while executing in a mode less privileged than
// M will cause an illegal-instruction exception."
private function is_vstimecmp_accessible(priv : Privilege) -> bool =
  currentlyEnabled(Ext_H) & currentlyEnabled(Ext_Sstc) &
  (priv == Machine | (mcounteren[TM] == 0b1 & menvcfg[STCE] == 0b1))

function clause is_CSR_accessible(0x24D, priv, _) = is_vstimecmp_accessible(priv)
function clause is_CSR_accessible(0x25D, priv, _) = is_vstimecmp_accessible(priv) & xlen == 32

function clause read_CSR(0x24D) = vstimecmp[xlen - 1 .. 0]
function clause read_CSR(0x25D if xlen == 32) = vstimecmp[63 .. 32]

function clause write_CSR(0x24D, value) = { vstimecmp[(xlen - 1) .. 0] = value; Ok(vstimecmp[xlen - 1 ..0]) }
function clause write_CSR((0x25D, value) if xlen == 32) = { vstimecmp[63 ..32] = value; Ok(vstimecmp[63 .. 32]) }
