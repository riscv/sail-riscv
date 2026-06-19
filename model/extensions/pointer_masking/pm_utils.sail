
// =======================================================================================
// This Sail RISC-V architecture model, comprising all files and
// directories except where otherwise noted is subject the BSD
// two-clause license in the LICENSE file.
//
// SPDX-License-Identifier: BSD-2-Clause
// =======================================================================================

// Return the 2-bit PMM value based on the current effective privilege mode.
private function get_pmm(eff_privilege : Privilege) -> PointerMaskingMode = match eff_privilege {
  Machine    => pmm_mode(mseccfg[PMM]),
  Supervisor => pmm_mode(menvcfg[PMM]),
  User       => if currentlyEnabled(Ext_S) then pmm_mode(read_senvcfg()[PMM]) else pmm_mode(menvcfg[PMM]),
  // Under virtualization, a regular access in VS-mode takes its PMM from
  // henvcfg.PMM and in VU-mode from senvcfg.PMM.
  // NOTE: HLV/HSV executed from U-mode (hstatus.HU=1) instead take their PMM
  // from hstatus.HUPMM, not senvcfg.PMM. get_pmm cannot distinguish that case
  // from a regular VU access, so HLV/HSV use get_hlsv_pmlen below instead.
  VirtualSupervisor => pmm_mode(henvcfg[PMM]),
  VirtualUser       => pmm_mode(read_senvcfg()[PMM]),
}

// Check whether PMM is applicable.
// Pointer masking does not apply to implicit accesses (page-table walks),
// instruction fetches, outside RV64, or when MXR is in effect at the
// effective privilege mode. MXR does not disable pointer masking in M-mode.
//
// For a VS/VU access, "MXR in effect" means HS-level mstatus.MXR (which makes
// execute-only pages readable across both translation stages) OR vsstatus.MXR
// (VS-stage only), matching get_mxr(VS_Stage) in vmem.sail and the rules in
// hypervisor spec.
private function is_pmm_applicable(access : MemoryAccessType(mem_payload), eff_privilege : Privilege) -> bool = {
  let mxr_in_effect : bool = match eff_privilege {
    Machine           => false,
    VirtualSupervisor => mstatus[MXR] == 0b1 | vsstatus[MXR] == 0b1,
    VirtualUser       => mstatus[MXR] == 0b1 | vsstatus[MXR] == 0b1,
    _                 => mstatus[MXR] == 0b1,
  };
  access != InstructionFetch() & access != Load(PageTableEntry) &
  access != Store(PageTableEntry) & not(mxr_in_effect) & xlen == 64
}

// Map a pointer-masking mode to its PMLEN.
private function pmlen_of_mode(pmm : PointerMaskingMode) -> pm_len = match pmm {
  PMM_Disabled => 0,
  PMM_PMLEN_7  => 7,
  PMM_PMLEN_16 => 16,
  PMM_Reserved => { internal_error(__FILE__, __LINE__, "Invalid pointer masking mode"); 0 },
}

// Get the effective PMLEN for a regular explicit access.
function get_pmlen(access : MemoryAccessType(mem_payload), eff_privilege : Privilege) -> pm_len =
  if is_pmm_applicable(access, eff_privilege) then pmlen_of_mode(get_pmm(eff_privilege)) else 0

// Get the effective PMLEN for an HLV/HSV explicit access. These execute with an
// effective privilege of VS or VU (taken from hstatus.SPVP), when executed from
// U-mode the VU PMM is sourced from hstatus.HUPMM rather than senvcfg.PMM.
// HLVX.* pass access = InstructionFetch() and are therefore exempt via
// is_pmm_applicable (returning PMLEN 0).
function get_hlsv_pmlen(access : MemoryAccessType(mem_payload), eff_privilege : Privilege) -> pm_len = {
  let pmm = if eff_privilege == VirtualUser & cur_privilege == User
            then pmm_mode(hstatus[HUPMM])
            else get_pmm(eff_privilege);
  if is_pmm_applicable(access, eff_privilege) then pmlen_of_mode(pmm) else 0
}

// Transforms a virtual address by sign-extending the relevant upper bits.
function pm_transform_VA(Virtaddr(effective_address) : virtaddr, pmlen : {0, 7, 16}) -> virtaddr = Virtaddr(sign_extend(effective_address[xlen - pmlen - 1 .. 0]))

// Transforms a physical address by zero-extending the relevant upper bits.
function pm_transform_PA(Virtaddr(effective_address) : virtaddr, pmlen : {0, 7, 16}) -> virtaddr = Virtaddr(zero_extend(effective_address[xlen - pmlen - 1 .. 0]))
