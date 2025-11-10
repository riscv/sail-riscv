// =======================================================================================
// This Sail RISC-V architecture model, comprising all files and
// directories except where otherwise noted is subject the BSD
// two-clause license in the LICENSE file.
//
// SPDX-License-Identifier: BSD-2-Clause
// =======================================================================================

// Return the 2-bit PMM value based on the current effective privilege mode.
function get_pmm(eff_privilege : Privilege) -> PointerMaskingMode = match eff_privilege {
  Machine    => pmm_mode(mseccfg[PMM]),
  Supervisor => pmm_mode(menvcfg[PMM]),
  User       => if currentlyEnabled(Ext_S) then pmm_mode(senvcfg[PMM]) else pmm_mode(menvcfg[PMM]),
  VirtualUser       => internal_error(__FILE__, __LINE__, "Hypervisor extension not supported"),
  VirtualSupervisor => internal_error(__FILE__, __LINE__, "Hypervisor extension not supported"),
}

// Check whether PMM is applicable.
// NOTE: mstatus[MXR] == 1'b1 disables pointer masking in S and U mode, but not in M-mode.
function is_pmm_applicable(typ : MemoryAccessType(ext_access_type), eff_privilege : Privilege) -> bool =
  typ != InstructionFetch() & (eff_privilege == Machine | mstatus[MXR] == 0b0) & xlen == 64

// Get the effective PMLEN value
function get_pmlen(typ : MemoryAccessType(ext_access_type), eff_privilege : Privilege) -> {0, 7, 16} = {
  let pmm = get_pmm(eff_privilege);
  if is_pmm_applicable(typ, eff_privilege) then {
    match pmm {
      PMM_Disabled => 0,
      PMM_PMLEN_7  => 7,
      PMM_PMLEN_16 => 16,
      PMM_Reserved => { internal_error(__FILE__, __LINE__, "Invalid pointer masking mode"); 0}
    }
  } else {
    // PMM not active
    0
  }
}

// Transforms a virtual address by sign-extending the relevant upper bits.
function transform_VA(Virtaddr(effective_address) : virtaddr, pmlen : {0, 7, 16}) -> virtaddr = Virtaddr(sign_extend(effective_address[xlen - pmlen - 1 .. 0]))

// Transforms a physical address by zero-extending the relevant upper bits.
function transform_PA(Virtaddr(effective_address) : virtaddr, pmlen : {0, 7, 16}) -> virtaddr = Virtaddr(zero_extend(effective_address[xlen - pmlen - 1 .. 0]))
