// =======================================================================================
// This Sail RISC-V architecture model, comprising all files and
// directories except where otherwise noted is subject the BSD
// two-clause license in the LICENSE file.
//
// SPDX-License-Identifier: BSD-2-Clause
// =======================================================================================

// The term `xSSE` is used to determine if backward-edge CFI using
// shadow stacks provided by the Zicfiss extension is enabled at a
// privilege mode. (See "Shadow-Stack-Enabled (SSE) State".)
function zicfiss_xSSE(priv : Privilege) -> bool =
  match priv {
    Machine           => false,
    Supervisor        => currentlyEnabled(Ext_S) & bool_bits(menvcfg[SSE]),
    // needs currentlyEnabled(Ext_S) & henvcfg[SSE]
    VirtualSupervisor => internal_error(__FILE__, __LINE__, "Hypervisor extension not supported"),
    User              => currentlyEnabled(Ext_S) & bool_bits(senvcfg[SSE]),
    VirtualUser       => currentlyEnabled(Ext_S) & bool_bits(senvcfg[SSE]),
  }

function clause currentlyEnabled(Ext_Zicfiss) =
  hartSupports(Ext_Zicfiss) & currentlyEnabled(Ext_Zicsr) & currentlyEnabled(Ext_Zimop)

// See "Shadow Stack Pointer (ssp) CSR access control".
// Note this is slightly different from `xSSE`.
function is_ssp_accessible(priv : Privilege) -> bool =
  match priv {
    Machine           => true,
    // raises illegal instruction otherwise
    Supervisor        => bool_bits(menvcfg[SSE]),
    // needs bool_bit(menvcfg[SSE]) & bool_bit(henvcfg[SSE])
    // raises virtual instruction otherwise
    VirtualSupervisor => internal_error(__FILE__, __LINE__, "Hypervisor extension not supported"),
    // needs bool_bit(menvcfg[SSE]) & bool_bit(henvcfg[SSE]) & bool_bit(senvcfg[SSE])
    // raises virtual instruction otherwise
    VirtualUser       => internal_error(__FILE__, __LINE__, "Hypervisor extension not supported"),
    // raises illegal instruction otherwise
    User              => bool_bits(menvcfg[SSE]) & bool_bits(senvcfg[SSE])
  }

register ssp : virtaddr = Virtaddr(zeros())

mapping clause csr_name_map = 0x011  <-> "ssp"
function clause is_CSR_accessible(0x011, _, _) = hartSupports(Ext_Zicfiss) & currentlyEnabled(Ext_Zicsr) & currentlyEnabled(Ext_Zimop) & is_ssp_accessible(cur_privilege)
function clause read_CSR(0x011) = bits_of_virtaddr(ssp)
function clause write_CSR(0x011, value) = {
  // The bits 1:0 of ssp are read-only zero. If the UXLEN or SXLEN may
  // never be 32, then the bit 2 is also read-only zero.
  // TODO: handle dynamic XLEN
  let ret : xlenbits = if xlen == 32 then [value with 1..0 = 0b00] else [value with 2..0 = 0b000];
  ssp = Virtaddr(ret);
  Ok(ret)
}
