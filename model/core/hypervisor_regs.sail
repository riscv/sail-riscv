// =======================================================================================
// This Sail RISC-V architecture model, comprising all files and
// directories except where otherwise noted is subject the BSD
// two-clause license in the LICENSE file.
//
// SPDX-License-Identifier: BSD-2-Clause
// =======================================================================================

// HS-Mode register

// Hypervisor Interrupt Registers

function legalize_hvip(m : Minterrupts, v : xlenbits) -> Minterrupts = {
  let v = Mk_Minterrupts(v);
  [m with
    VSEI = v[VSEI],
    VSTI = v[VSTI],
    VSSI = v[VSSI],
  ]
}

function legalize_hie(m : Minterrupts, v : xlenbits) -> Minterrupts = {
  let v = Mk_Minterrupts(v);
  [m with
    SGEI = v[SGEI],
    VSEI = v[VSEI],
    VSTI = v[VSTI],
    VSSI = v[VSSI],
  ]
}

// Only VSSI is writable in hip (VSEI, VSTI, SGEI are read-only)
function legalize_hip(m : Minterrupts, v : xlenbits) -> Minterrupts = {
  let v = Mk_Minterrupts(v);
  [m with VSSI = v[VSSI]]
}

function lower_mip_to_hvip(m : Minterrupts) -> Minterrupts = {
  [Mk_Minterrupts(zeros()) with
    VSEI = m[VSEI],
    VSTI = m[VSTI],
    VSSI = m[VSSI],
  ]
}

function lower_mie_to_hie(m : Minterrupts) -> Minterrupts = {
  [Mk_Minterrupts(zeros()) with
    SGEI = m[SGEI],
    VSEI = m[VSEI],
    VSTI = m[VSTI],
    VSSI = m[VSSI],
  ]
}

function lower_mip_to_hip(m : Minterrupts) -> Minterrupts = {
  [Mk_Minterrupts(zeros()) with
    SGEI = m[SGEI],
    VSEI = m[VSEI],
    VSTI = m[VSTI],
    VSSI = m[VSSI],
  ]
}

mapping clause csr_name_map = 0x645 <-> "hvip"
mapping clause csr_name_map = 0x604 <-> "hie"
mapping clause csr_name_map = 0x644 <-> "hip"

function clause is_CSR_accessible(0x645, _, _) = currentlyEnabled(Ext_H) // hvip
function clause is_CSR_accessible(0x604, _, _) = currentlyEnabled(Ext_H) // hie
function clause is_CSR_accessible(0x644, _, _) = currentlyEnabled(Ext_H) // hip

function clause read_CSR(0x645) = lower_mip_to_hvip(mip).bits
function clause read_CSR(0x604) = lower_mie_to_hie(mie).bits
function clause read_CSR(0x644) = lower_mip_to_hip(mip).bits

function clause write_CSR(0x645, value) = { mip = legalize_hvip(mip, value); Ok(lower_mip_to_hvip(mip).bits) }
function clause write_CSR(0x604, value) = { mie = legalize_hie(mie, value); Ok(lower_mie_to_hie(mie).bits) }
function clause write_CSR(0x644, value) = { mip = legalize_hip(mip, value); Ok(lower_mip_to_hip(mip).bits) }

// Guest External Interrupt Registers

function legalize_hgeie(v : xlenbits) -> xlenbits = {
  [v with 0 = bitzero]
}

register hgeie : xlenbits
register hgeip : xlenbits

// TODO: Add GEILEN config
mapping clause csr_name_map = 0x607 <-> "hgeie"
mapping clause csr_name_map = 0xE12 <-> "hgeip"

function clause is_CSR_accessible(0x607, _, _) = currentlyEnabled(Ext_H) // hgeie
function clause is_CSR_accessible(0xE12, _, _) = currentlyEnabled(Ext_H) // hgeip

function clause read_CSR(0x607) = hgeie
function clause read_CSR(0xE12) = hgeip

function clause write_CSR(0x607, value) = { hgeie = legalize_hgeie(value); Ok(hgeie) }

// Hypervisor Environment Configuration

bitfield HEnvcfg : bits(64) = {
  STCE  : 63,
  PBMTE : 62,
  ADUE  : 61,
  DTE   : 59,
  PMM   : 33 .. 32,
  CBZE  : 7,
  CBCFE : 6,
  CBIE  : 5 .. 4,
  SSE   : 3,
  LPE   : 2,
  FIOM  : 0,
}

register henvcfg : HEnvcfg

function legalize_henvcfg(h : HEnvcfg, v : bits(64)) -> HEnvcfg = {
  let v = Mk_HEnvcfg(v);
  [h with
    STCE  = if currentlyEnabled(Ext_Sstc) & menvcfg[STCE] == 0b1 then v[STCE]  else 0b0,
    PBMTE = if currentlyEnabled(Ext_Svpbmt)  then v[PBMTE] else 0b0,
    // ADUE  = if currentlyEnabled(Ext_Svadu) then v[ADUE] else 0b0,
    // DTE   = if currentlyEnabled(Ext_Ssdbltrp) then v[DTE] else 0b0,
    // PMM   = if currentlyEnabled(Ext_Ssnpm) then v[PMM] else 0b0,
    CBZE  = if currentlyEnabled(Ext_Zicboz)  then v[CBZE]  else 0b0,
    CBCFE = if currentlyEnabled(Ext_Zicbom)  then v[CBCFE] else 0b0,
    CBIE  = if currentlyEnabled(Ext_Zicbom)  then v[CBIE]  else 0b00,
    // SSE = if currentlyEnabled(Ext_Zicfiss) then v[SSE] else 0b0,
    LPE   = if currentlyEnabled(Ext_Zicfilp) then v[LPE]   else 0b0,
    FIOM  = if sys_enable_writable_fiom      then v[FIOM]  else 0b0,
  ]
}

mapping clause csr_name_map = 0x60A <-> "henvcfg"
mapping clause csr_name_map = 0x61A <-> "henvcfgh"

function clause is_CSR_accessible(0x60A, _, _) = currentlyEnabled(Ext_H) // henvcfg
function clause is_CSR_accessible(0x61A, _, _) = currentlyEnabled(Ext_H) & xlen == 32 // henvcfgh

function clause read_CSR(0x60A) = henvcfg.bits[xlen - 1 .. 0]
function clause read_CSR(0x61A if xlen == 32) = henvcfg.bits[63 .. 32]

function clause write_CSR((0x60A, value) if xlen == 32) = { henvcfg = legalize_henvcfg(henvcfg, henvcfg.bits[63 .. 32] @ value); Ok(henvcfg.bits[xlen - 1 .. 0]) }
function clause write_CSR((0x60A, value) if xlen == 64) = { henvcfg = legalize_henvcfg(henvcfg, value); Ok(henvcfg.bits[xlen - 1 .. 0]) }
function clause write_CSR((0x61A, value) if xlen == 32) = { henvcfg = legalize_henvcfg(henvcfg, value @ henvcfg.bits[31 .. 0]); Ok(henvcfg.bits[63 .. 32]) }

// Hypervisor Counter Enable

function legalize_hcounteren(_c : Counteren, v : xlenbits) -> Counteren = {
  let supported_counters = sys_writable_hpm_counters[31 .. 3] @ 0b111;
  Mk_Counteren(v[31 .. 0] & supported_counters)
}

register hcounteren : Counteren

mapping clause csr_name_map = 0x606 <-> "hcounteren"
function clause is_CSR_accessible(0x606, _, _) = currentlyEnabled(Ext_H)
function clause read_CSR(0x606) = zero_extend(hcounteren.bits)
function clause write_CSR(0x606, value) = { hcounteren = legalize_hcounteren(hcounteren, value); Ok(zero_extend(hcounteren.bits)) }

// Hypervisor Time Delta

register htimedelta : bits(64)

mapping clause csr_name_map = 0x605 <-> "htimedelta"
mapping clause csr_name_map = 0x615 <-> "htimedeltah"

// TODO: Should raise virtual instruction exception if accessed by VU/VS-Mode.
// Needs refactoring of CSR access logic.
// TODO: Time CSR needs to modified and shall return htimedelta + mtime
function clause is_CSR_accessible(0x605, _, _) = currentlyEnabled(Ext_H) // htimedelta
function clause is_CSR_accessible(0x615, _, _) = currentlyEnabled(Ext_H) & xlen == 32 // htimedeltah

function clause read_CSR(0x605) = htimedelta[xlen - 1 .. 0]
function clause read_CSR(0x615 if xlen == 32) = htimedelta[63 .. 32]

function clause write_CSR(0x605, value) = { htimedelta[xlen - 1 .. 0] = value; Ok(htimedelta[xlen - 1 .. 0]) }
function clause write_CSR((0x615, value) if xlen == 32) = { htimedelta[63 .. 32] = value; Ok(htimedelta[63 .. 32]) }

// Hypervisor Trap Handling

register htval  : xlenbits
register htinst : xlenbits

mapping clause csr_name_map = 0x643 <-> "htval"
mapping clause csr_name_map = 0x64A <-> "htinst"

function clause is_CSR_accessible(0x643, _, _) = currentlyEnabled(Ext_H) // htval
function clause is_CSR_accessible(0x64A, _, _) = currentlyEnabled(Ext_H) // htinst

function clause read_CSR(0x643) = htval
function clause read_CSR(0x64A) = htinst

function clause write_CSR(0x643, value) = { htval = value; Ok(htval) }
function clause write_CSR(0x64A, value) = { htinst = value; Ok(htinst) }

// Hypervisor Guest Address Translation and Protection

// TODO: Consolidate with SATPMode to get rid of HBare
type hgatp_mode = bits(4)
enum HGATPMode = {HBare, Sv32x4, Sv39x4, Sv48x4, Sv57x4}

function hgatpMode_of_bits(a : Architecture, m : hgatp_mode) -> option(HGATPMode) =
  match (a, m) {
    (_,    0x0) => Some(HBare),
    (RV32, 0x1) => Some(Sv32x4),
    (RV64, 0x8) => Some(Sv39x4),
    (RV64, 0x9) => Some(Sv48x4),
    (RV64, 0xA) => Some(Sv57x4),
    (_, _)      => None()
  }

bitfield Hgatp64 : bits(64) = {
  Mode : 63 .. 60,
  VMID : 57 .. 44,
  PPN  : 43 .. 0
}

bitfield Hgatp32 : bits(32) = {
  Mode : 31,
  VMID : 28 .. 22,
  PPN  : 21 .. 0
}

// TODO: Consolidate with legalize_satp
// TODO: Add VMIDLEN config option and mask VMID field to implemented width
function legalize_hgatp(
  arch : Architecture,
  prev_value : xlenbits,
  written_value : xlenbits,
) -> xlenbits = {
  if xlen == 32 then {
    let v = Mk_Hgatp32(written_value);
    // Force 16 KiB alignment with PPN[1:0] = 0b00
    let h = Mk_Hgatp32(v[Mode] @ 0b00 @ v[VMID] @ v[PPN][21 .. 2] @ 0b00);
    match hgatpMode_of_bits(arch, 0b000 @ h[Mode]) {
      None() => prev_value,
      Some(mode) => match mode {
        HBare  if currentlyEnabled(Ext_Svbare) => h.bits,
        Sv32x4 if currentlyEnabled(Ext_Sv32)   => h.bits,
        _ => prev_value,
      }
    }
  } else if xlen == 64 then {
    let v = Mk_Hgatp64(written_value);
    // Force 16 KiB alignment with PPN[1:0] = 0b00
    let h = Mk_Hgatp64(v[Mode] @ 0b00 @ v[VMID] @ v[PPN][43 .. 2] @ 0b00);
    match hgatpMode_of_bits(arch, h[Mode]) {
      None() => prev_value,
      Some(mode) => match mode {
        HBare  if currentlyEnabled(Ext_Svbare) => h.bits,
        Sv39x4 if currentlyEnabled(Ext_Sv39)   => h.bits,
        Sv48x4 if currentlyEnabled(Ext_Sv48)   => h.bits,
        Sv57x4 if currentlyEnabled(Ext_Sv57)   => h.bits,
        _ => prev_value,
      }
    }
  } else {
    internal_error(__FILE__, __LINE__, "Unsupported xlen " ^ dec_str(xlen))
  }
}

register hgatp : xlenbits

mapping clause csr_name_map = 0x680 <-> "hgatp"

// TODO: Should raise virtual instruction exception if accessed by VU/VS-Mode.
// Needs refactoring of CSR access logic.
function clause is_CSR_accessible(0x680, priv, _) = currentlyEnabled(Ext_H) & (priv == Machine | (priv == Supervisor & mstatus[TVM] == 0b0))
function clause read_CSR(0x680) = hgatp
function clause write_CSR(0x680, value) = { hgatp = legalize_hgatp(architecture(cur_privilege), hgatp, value); Ok(hgatp) }

// Virtual Supervisor Registers

register vsatp : xlenbits

mapping clause csr_name_map = 0x280 <-> "vsatp"
function clause is_CSR_accessible(0x280, _, _) = currentlyEnabled(Ext_H)
function clause read_CSR(0x280) = vsatp
function clause write_CSR(0x280, value) = { vsatp = legalize_satp(architecture(cur_privilege), vsatp, value); Ok(vsatp) }

register vstvec : Mtvec
register vsepc  : xlenbits
