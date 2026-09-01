// =======================================================================================
// This Sail RISC-V architecture model, comprising all files and
// directories except where otherwise noted is subject the BSD
// two-clause license in the LICENSE file.
//
// SPDX-License-Identifier: BSD-2-Clause
// =======================================================================================

// Architectural state and enablement for the Zimt memory tagging
// extension and the Svatag/Smvatag tag storage extensions (v0.2, DRAFT).
// https://github.com/riscv/riscv-memory-tagging

// "The Zimt extension depends on Zicsr, Zimop and pointer masking
// extensions and is applicable only for XLEN=64."
function clause currentlyEnabled(Ext_Zimt) =
  hartSupports(Ext_Zimt) & currentlyEnabled(Ext_Zicsr) & currentlyEnabled(Ext_Zimop)
  & (currentlyEnabled(Ext_Ssnpm) | currentlyEnabled(Ext_Smnpm) | currentlyEnabled(Ext_Smmpm))

// Svatag defines the virtually indexed tag table (VITT) for
// S/HS/U/VS/VU modes; Smvatag defines it for M-mode.
function clause currentlyEnabled(Ext_Svatag) = hartSupports(Ext_Svatag) & currentlyEnabled(Ext_Zimt)
function clause currentlyEnabled(Ext_Smvatag) = hartSupports(Ext_Smvatag) & currentlyEnabled(Ext_Zimt)

// ---------------------------------------------------------------------
// MT_MODE lookup ("Enabling memory tagging", MEM_TAG_EN)
//
// Return the MemTaggingMode controlling regular explicit accesses and
// Zimt instructions at the given (effective) privilege:
//   M    : mseccfg.MT_MODE
//   HS/S : menvcfg.MT_MODE
//   U    : senvcfg.MT_MODE
//   VS   : henvcfg.MT_MODE
//   VU   : senvcfg.MT_MODE
// HLV*/HSV* executed from HU with effective privilege VU use
// hstatus.VUMT_MODE instead; that case is handled by the (future)
// HLV/HSV tag check plumbing, not here.
function get_mt_mode(priv : Privilege) -> MemTaggingMode = {
  if not(currentlyEnabled(Ext_Zimt)) then return MT_MODE_Disabled;
  match priv {
    Machine    => mt_mode(mseccfg[MT_MODE]),
    Supervisor => mt_mode(menvcfg[MT_MODE]),
    User       => if currentlyEnabled(Ext_S) then mt_mode(read_senvcfg()[MT_MODE]) else mt_mode(menvcfg[MT_MODE]),
    VirtualSupervisor => mt_mode(read_henvcfg()[MT_MODE]),
    VirtualUser       => mt_mode(read_senvcfg()[MT_MODE]),
  }
}

// Whether memory tagging is active at the given privilege. When
// inactive, the Zimt instructions implement their Zimop fallback
// behavior (see zimt_insts.sail).
function zimt_active(priv : Privilege) -> bool =
  get_mt_mode(priv) != MT_MODE_Disabled

// ---------------------------------------------------------------------
// !!! PLACEHOLDER CSR ADDRESSES - TG ALLOCATION NEEDED !!!
//
// The v0.2 draft specification explicitly leaves the CSR addresses of
// the tag-generation exclusion mask CSRs and the VITT base CSRs
// unallocated ("CSR addresses for these registers are to be
// allocated"). The addresses below are placeholders taken from the
// custom read/write ranges (machine 0x7C0+, supervisor 0x5C0+,
// hypervisor/VS 0x6C0+) and MUST be updated once the memory tagging
// TG obtains allocations.
//
// TODO: Smstateen/Ssstateen gating of the U/VU-controlling CSRs via
// mstateen0.MT / hstateen0.MT is NOT implemented: the spec carries an
// explicit warning that the MT bit position in [mh]stateen0 is not
// fixed yet.

// ---------------------------------------------------------------------
// Tag-generation exclusion mask CSR pairs.
//
// Bit i of the active 128-bit mask (high @ low) set means gentag must
// not generate pointer_tag value i. With pointer_tag_width = 4 only
// bits [15:0] are active. Zimt is RV64-only, so these registers are
// modelled at xlen bits (they are inaccessible on RV32).
register mmtagexclude0    : xlenbits = zeros()
register mmtagexclude1    : xlenbits = zeros()
register menvmtagexclude0 : xlenbits = zeros()
register menvmtagexclude1 : xlenbits = zeros()
register senvmtagexclude0 : xlenbits = zeros()
register senvmtagexclude1 : xlenbits = zeros()
register henvmtagexclude0 : xlenbits = zeros()
register henvmtagexclude1 : xlenbits = zeros()

// "At least one bit in [15:0] must remain clear" (WARL): if software
// attempts to exclude all 16 low tag values, this implementation
// clears bit 0.
function legalize_mtagexclude0(v : xlenbits) -> xlenbits =
  if v[15 .. 0] == ones() then [v with 0 = bitzero] else v

mapping clause csr_name_map = 0x7C0 <-> "mmtagexclude0"
mapping clause csr_name_map = 0x7C1 <-> "mmtagexclude1"
mapping clause csr_name_map = 0x7C2 <-> "menvmtagexclude0"
mapping clause csr_name_map = 0x7C3 <-> "menvmtagexclude1"
mapping clause csr_name_map = 0x5C0 <-> "senvmtagexclude0"
mapping clause csr_name_map = 0x5C1 <-> "senvmtagexclude1"
mapping clause csr_name_map = 0x6C0 <-> "henvmtagexclude0"
mapping clause csr_name_map = 0x6C1 <-> "henvmtagexclude1"

function clause is_CSR_accessible(0x7C0, _, _) = currentlyEnabled(Ext_Zimt)
function clause is_CSR_accessible(0x7C1, _, _) = currentlyEnabled(Ext_Zimt)
function clause is_CSR_accessible(0x7C2, _, _) = currentlyEnabled(Ext_Zimt) & currentlyEnabled(Ext_S)
function clause is_CSR_accessible(0x7C3, _, _) = currentlyEnabled(Ext_Zimt) & currentlyEnabled(Ext_S)
function clause is_CSR_accessible(0x5C0, _, _) = currentlyEnabled(Ext_Zimt) & currentlyEnabled(Ext_S)
function clause is_CSR_accessible(0x5C1, _, _) = currentlyEnabled(Ext_Zimt) & currentlyEnabled(Ext_S)
function clause is_CSR_accessible(0x6C0, _, _) = currentlyEnabled(Ext_Zimt) & currentlyEnabled(Ext_H)
function clause is_CSR_accessible(0x6C1, _, _) = currentlyEnabled(Ext_Zimt) & currentlyEnabled(Ext_H)

function clause read_CSR(0x7C0) = mmtagexclude0
function clause read_CSR(0x7C1) = mmtagexclude1
function clause read_CSR(0x7C2) = menvmtagexclude0
function clause read_CSR(0x7C3) = menvmtagexclude1
function clause read_CSR(0x5C0) = senvmtagexclude0
function clause read_CSR(0x5C1) = senvmtagexclude1
function clause read_CSR(0x6C0) = henvmtagexclude0
function clause read_CSR(0x6C1) = henvmtagexclude1

function clause write_CSR(0x7C0, value) = { mmtagexclude0 = legalize_mtagexclude0(value); Ok(mmtagexclude0) }
function clause write_CSR(0x7C1, value) = { mmtagexclude1 = value; Ok(mmtagexclude1) }
function clause write_CSR(0x7C2, value) = { menvmtagexclude0 = legalize_mtagexclude0(value); Ok(menvmtagexclude0) }
function clause write_CSR(0x7C3, value) = { menvmtagexclude1 = value; Ok(menvmtagexclude1) }
function clause write_CSR(0x5C0, value) = { senvmtagexclude0 = legalize_mtagexclude0(value); Ok(senvmtagexclude0) }
function clause write_CSR(0x5C1, value) = { senvmtagexclude1 = value; Ok(senvmtagexclude1) }
function clause write_CSR(0x6C0, value) = { henvmtagexclude0 = legalize_mtagexclude0(value); Ok(henvmtagexclude0) }
function clause write_CSR(0x6C1, value) = { henvmtagexclude1 = value; Ok(henvmtagexclude1) }

// The 128-bit tag-generation exclusion mask (high @ low) active at
// `priv`. Zimt is RV64-only, so xlen is 64 whenever this is
// reachable; zero_extend keeps the RV32 build type-correct.
function mtag_exclusion_pair(hi : xlenbits, lo : xlenbits) -> bits(128) = {
  let hi64 : bits(64) = zero_extend(hi);
  let lo64 : bits(64) = zero_extend(lo);
  hi64 @ lo64
}

function get_mtag_exclusion_mask(priv : Privilege) -> bits(128) =
  match priv {
    Machine           => mtag_exclusion_pair(mmtagexclude1, mmtagexclude0),
    Supervisor        => mtag_exclusion_pair(menvmtagexclude1, menvmtagexclude0),
    User              => mtag_exclusion_pair(senvmtagexclude1, senvmtagexclude0),
    VirtualSupervisor => mtag_exclusion_pair(henvmtagexclude1, henvmtagexclude0),
    VirtualUser       => mtag_exclusion_pair(senvmtagexclude1, senvmtagexclude0),
  }

// ---------------------------------------------------------------------
// VITT (virtually indexed tag table) base CSRs, Svatag/Smvatag.
// "Tag table base address must be 4K aligned" - bits [11:0] are WARL
// read-only zero.
register mvitt   : xlenbits = zeros()
register svitts  : xlenbits = zeros()
register svittu  : xlenbits = zeros()
register vsvitts : xlenbits = zeros()
register vsvittu : xlenbits = zeros()

function legalize_vitt(v : xlenbits) -> xlenbits = [v with 11 .. 0 = zeros()]

mapping clause csr_name_map = 0x7C4 <-> "mvitt"
mapping clause csr_name_map = 0x5C2 <-> "svitts"
mapping clause csr_name_map = 0x5C3 <-> "svittu"
mapping clause csr_name_map = 0x6C2 <-> "vsvitts"
mapping clause csr_name_map = 0x6C3 <-> "vsvittu"

function clause is_CSR_accessible(0x7C4, _, _) = currentlyEnabled(Ext_Smvatag)
function clause is_CSR_accessible(0x5C2, _, _) = currentlyEnabled(Ext_Svatag) & currentlyEnabled(Ext_S)
function clause is_CSR_accessible(0x5C3, _, _) = currentlyEnabled(Ext_Svatag) & currentlyEnabled(Ext_S)
function clause is_CSR_accessible(0x6C2, _, _) = currentlyEnabled(Ext_Svatag) & currentlyEnabled(Ext_H)
function clause is_CSR_accessible(0x6C3, _, _) = currentlyEnabled(Ext_Svatag) & currentlyEnabled(Ext_H)

function clause read_CSR(0x7C4) = mvitt
function clause read_CSR(0x5C2) = svitts
function clause read_CSR(0x5C3) = svittu
function clause read_CSR(0x6C2) = vsvitts
function clause read_CSR(0x6C3) = vsvittu

function clause write_CSR(0x7C4, value) = { mvitt = legalize_vitt(value); Ok(mvitt) }
function clause write_CSR(0x5C2, value) = { svitts = legalize_vitt(value); Ok(svitts) }
function clause write_CSR(0x5C3, value) = { svittu = legalize_vitt(value); Ok(svittu) }
function clause write_CSR(0x6C2, value) = { vsvitts = legalize_vitt(value); Ok(vsvitts) }
function clause write_CSR(0x6C3, value) = { vsvittu = legalize_vitt(value); Ok(vsvittu) }

// The VITT base used for tag load/store operations on behalf of
// accesses at the given (effective) privilege. None() if the relevant
// tag-table extension is not enabled.
function get_vitt_base(priv : Privilege) -> option(xlenbits) =
  match priv {
    Machine    => if currentlyEnabled(Ext_Smvatag) then Some(mvitt) else None(),
    Supervisor => if currentlyEnabled(Ext_Svatag) then Some(svitts) else None(),
    User       => if currentlyEnabled(Ext_Svatag) then Some(svittu) else None(),
    VirtualSupervisor => if currentlyEnabled(Ext_Svatag) then Some(vsvitts) else None(),
    VirtualUser       => if currentlyEnabled(Ext_Svatag) then Some(vsvittu) else None(),
  }
