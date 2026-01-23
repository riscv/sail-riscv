// =======================================================================================
// This Sail RISC-V architecture model, comprising all files and
// directories except where otherwise noted is subject the BSD
// two-clause license in the LICENSE file.
//
// SPDX-License-Identifier: BSD-2-Clause
// =======================================================================================

function clause currentlyEnabled(Ext_Zicfiss) =
  hartSupports(Ext_Zicfiss) & currentlyEnabled(Ext_Zicsr) & currentlyEnabled(Ext_Zimop) & currentlyEnabled(Ext_Zaamo)

// The term `xSSE` is used to determine if backward-edge CFI using
// shadow stacks provided by the Zicfiss extension is enabled at a
// privilege mode. (See "Shadow-Stack-Enabled (SSE) State".)
//
// This is used as a predicate for decoding Zicfiss instructions (see
// the specification of {mhs}envcfg.SSE).  This should really be part
// of `currentlyEnabled(Ext_Zicfiss)` but is separate to match the use of
// `xSSE` in the specification.

function zicfiss_xSSE(priv : Privilege) -> bool =
  match priv {
    Machine           => // "Use of Zicfiss in M-mode is not supported."
                         false,
    Supervisor        => { assert(currentlyEnabled(Ext_S)); bool_bit(menvcfg[SSE]) },
    // TODO: needs currentlyEnabled(Ext_H) & read_henvcfg()[SSE]
    VirtualSupervisor => internal_error(__FILE__, __LINE__, "Hypervisor extension not supported"),
    User              => currentlyEnabled(Ext_S) & bool_bit(read_senvcfg()[SSE]),
    // TODO: read_henvcfg()[SSE]
    VirtualUser       => currentlyEnabled(Ext_H) & bool_bit(read_senvcfg()[SSE]),
  }

// See "Shadow Stack Pointer (ssp) CSR access control".
function is_ssp_accessible(priv : Privilege) -> bool =
  match priv {
    Machine           => true,
    // raises illegal instruction otherwise
    Supervisor        => bool_bit(menvcfg[SSE]),
    // needs bool_bit(read_henvcfg()[SSE])
    // raises virtual instruction otherwise
    VirtualSupervisor => internal_error(__FILE__, __LINE__, "Hypervisor extension not supported"),
    // needs bool_bit(read_henvcfg()[SSE]) & bool_bit(read_senvcfg()[SSE])
    // raises virtual instruction otherwise
    VirtualUser       => internal_error(__FILE__, __LINE__, "Hypervisor extension not supported"),
    // raises illegal instruction otherwise
    User              => bool_bit(read_senvcfg()[SSE])
  }


register ssp : xlenbits = zeros()

// "There is no high CSR defined as the ssp is always as wide as the
// XLEN of the current privilege mode."
mapping clause csr_name_map = 0x011  <-> "ssp"
// TODO: handle throwing VirtualInstruction when required by `is_ssp_accessible()`.
function clause is_CSR_accessible(0x011, _, _) = currentlyEnabled(Ext_Zicfiss) & is_ssp_accessible(cur_privilege)

// "The bits 1:0 of ssp are read-only zero. If the UXLEN or SXLEN may
// never be 32, then the bit 2 is also read-only zero."
function clause read_CSR(0x011) = ssp
function clause write_CSR(0x011, value) = {
  ssp = if xlen == 32 then [value with 1..0 = 0b00] else [value with 2..0 = 0b000];
  Ok(ssp)
}
