// =======================================================================================
// This Sail RISC-V architecture model, comprising all files and
// directories except where otherwise noted is subject the BSD
// two-clause license in the LICENSE file.
//
// SPDX-License-Identifier: BSD-2-Clause
// =======================================================================================

// Sscpuutil - CPU Utilization counters
function clause currentlyEnabled(Ext_Sscpuutil) = hartSupports(Ext_Sscpuutil) & currentlyEnabled(Ext_Zicntr)

register macttime : bits(64)

// FIXME: Waiting for CSR address allocation
mapping clause csr_name_map = 0xC23 <-> "acttime"
mapping clause csr_name_map = 0xCA3 <-> "acttimeh"
mapping clause csr_name_map = 0xF00 <-> "macttime"
mapping clause csr_name_map = 0xF80 <-> "macttimeh"

private function acttime_accessible(priv : Privilege) -> bool =
  currentlyEnabled(Ext_Sscpuutil) & (
    match priv {
      Machine           => true,
      Supervisor        => true,
      User              => counter_enabled(0, priv),
      VirtualSupervisor => true,
      VirtualUser       => counter_enabled(0, priv),
    }
  )

function clause is_CSR_accessible(0xC23, priv, _) = acttime_accessible(priv)
function clause is_CSR_accessible(0xCA3, priv, _) = xlen == 32 & acttime_accessible(priv)
function clause is_CSR_accessible(0xF00, _, _) = currentlyEnabled(Ext_Sscpuutil)
function clause is_CSR_accessible(0xF80, _, _) = xlen == 32 & currentlyEnabled(Ext_Sscpuutil)

function clause read_CSR(0xC23) = macttime[xlen - 1 .. 0]
function clause read_CSR(0xCA3 if xlen == 32) = macttime[63 .. 32]
function clause read_CSR(0xF00) = macttime[xlen - 1 .. 0]
function clause read_CSR(0xF80 if xlen == 32) = macttime[63 .. 32]
