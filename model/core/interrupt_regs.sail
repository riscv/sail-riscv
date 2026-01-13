// =======================================================================================
// This Sail RISC-V architecture model, comprising all files and
// directories except where otherwise noted is subject the BSD
// two-clause license in the LICENSE file.
//
// SPDX-License-Identifier: BSD-2-Clause
// =======================================================================================

// State and access functions for hgeie, hgeip, hvip, mip, hip, sip, mie,
// hie, sie, medeleg, mideleg, hedeleg, hideleg, vsip and vsie.
// These are surprisingly complex, especially SEIP which also breaks the
// standard CSR read-modify-write system.

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

bitfield Minterrupts : xlenbits = {
  LCOFI: 13, // Local counter-overflow interrupt
  SGEI : 12, // Supervisor guest external interrupt
  MEI  : 11, // Machine external interrupt
  VSEI : 10, // Virtual Supervisor external interrupt
  SEI  : 9,  // Supervisor external interrupt

  MTI  : 7,  // Timer interrupt
  VSTI : 6,  // Virtual supervisor timer interrupt
  STI  : 5,  // Supervisor timer interrupt

  MSI  : 3,  // Software interrupt
  VSSI : 2,  // Virtual supervisor software interrupt
  SSI  : 1,  // Supervisor software interrupt
}

register hvip : Minterrupts

private function legalize_mip(o : Minterrupts, v : xlenbits) -> Minterrupts = {
  // The only writable bits are the S-mode bits.
  let v = Mk_Minterrupts(v);
  [o with
    LCOFI = if currentlyEnabled(Ext_Sscofpmf) then v[LCOFI] else 0b0,
    SEI = if currentlyEnabled(Ext_S) then v[SEI] else 0b0,
    SSI = if currentlyEnabled(Ext_S) then v[SSI] else 0b0,
    STI = if currentlyEnabled(Ext_S) then (
      // STI is read only if Sstc is enabled and STCE is set (it is equal to stimecmp <= mtime).
      if currentlyEnabled(Ext_Sstc) & menvcfg[STCE] == 0b1 then o[STI] else v[STI]
    ) else 0b0,
    SGEI = if currentlyEnabled(Ext_H) then bool_to_bit((hgeip & hgeie) != zeros()) else 0b0,
    // NOTE/TODO: "VSEIP is read-only in hip, and is the logical-OR of these interrupt sources.
    // * bit VSEIP of hvip;"
    // * the bit of hgeip selected by hstatus.VGEI; and (TODO)
    // * any other platform-specific external interrupt signal directed to VS-Level (TODO)"
    VSEI = if currentlyEnabled(Ext_H) then hvip[VSEI] else 0b0,
    // NOTE/TODO: "VSTIP is read-only in hip, and is the logical-OR of
    // * hvip.VSTIP; and
    // * any other platform-specfic timer interrupt signal directed to VS-Level (TODO)"
    VSTI = if currentlyEnabled(Ext_H) then hvip[VSTI] else 0b0,
    VSSI = if currentlyEnabled(Ext_H) then v[VSSI] else 0b0,
  ]
}

private function legalize_mie(o : Minterrupts, v : xlenbits) -> Minterrupts = {
  let v = Mk_Minterrupts(v);
  [o with
    LCOFI = if currentlyEnabled(Ext_Sscofpmf) then v[LCOFI] else 0b0,
    MEI  = v[MEI],
    MTI  = v[MTI],
    MSI  = v[MSI],
    SEI  = if currentlyEnabled(Ext_S) then v[SEI] else 0b0,
    STI  = if currentlyEnabled(Ext_S) then v[STI] else 0b0,
    SSI  = if currentlyEnabled(Ext_S) then v[SSI] else 0b0,
    SGEI = if currentlyEnabled(Ext_H) then v[SGEI] else 0b0,
    VSEI = if currentlyEnabled(Ext_H) then v[VSEI] else 0b0,
    VSTI = if currentlyEnabled(Ext_H) then v[VSTI] else 0b0,
    VSSI = if currentlyEnabled(Ext_H) then v[VSSI] else 0b0,
  ]
}

private function legalize_mideleg(o : Minterrupts, v : xlenbits) -> Minterrupts = {
  // M-mode interrupt delegation bits "should" be hardwired to 0.
  // TODO: Configuration options specifying whether M-mode interrupts
  // can be delegated.
  let v = Mk_Minterrupts(v);
  [o with
    LCOFI = if currentlyEnabled(Ext_Sscofpmf) then v[LCOFI] else 0b0,
    MEI   = 0b0,
    MTI   = 0b0,
    MSI   = 0b0,
    SEI   = if currentlyEnabled(Ext_S) then v[SEI] else 0b0,
    STI   = if currentlyEnabled(Ext_S) then v[STI] else 0b0,
    SSI   = if currentlyEnabled(Ext_S) then v[SSI] else 0b0,
    // VS-mode interrupts are always delegated when H-extension is present
    // TODO: Is this correct? else v[VSEI] ?
    VSEI = if currentlyEnabled(Ext_H) then 0b1 else v[VSEI],
    VSTI = if currentlyEnabled(Ext_H) then 0b1 else v[VSTI],
    VSSI = if currentlyEnabled(Ext_H) then 0b1 else v[VSSI],
    // TODO: SGEI is always delegated if GEILEN > 0
    SGEI = if currentlyEnabled(Ext_H) then 0b1 else v[SGEI],
  ]
}

bitfield Medeleg : bits(64) = {
  SAMO_GPage_Fault  : 23,
  Virtual_Instr     : 22,
  Load_GPage_Fault  : 21,
  Fetch_GPage_Fault : 20,
  Software_Check    : 19,
  SAMO_Page_Fault   : 15,
  Load_Page_Fault   : 13,
  Fetch_Page_Fault  : 12,
  MEnvCall          : 11,
  VSEnvCall         : 10,
  SEnvCall          : 9,
  UEnvCall          : 8,
  SAMO_Access_Fault : 7,
  SAMO_Addr_Align   : 6,
  Load_Access_Fault : 5,
  Load_Addr_Align   : 4,
  Breakpoint        : 3,
  Illegal_Instr     : 2,
  Fetch_Access_Fault: 1,
  Fetch_Addr_Align  : 0
}

private function legalize_medeleg(_o : Medeleg, v : bits(64)) -> Medeleg = {
  // M-EnvCalls delegation is not supported
  let v = Mk_Medeleg(v);
  [v with
    SAMO_GPage_Fault  = if currentlyEnabled(Ext_H) then v[SAMO_GPage_Fault]  else 0b0,
    Virtual_Instr     = if currentlyEnabled(Ext_H) then v[Virtual_Instr]     else 0b0,
    Load_GPage_Fault  = if currentlyEnabled(Ext_H) then v[Load_GPage_Fault]  else 0b0,
    Fetch_GPage_Fault = if currentlyEnabled(Ext_H) then v[Fetch_GPage_Fault] else 0b0,
    VSEnvCall         = if currentlyEnabled(Ext_H) then v[VSEnvCall]         else 0b0,
    MEnvCall = 0b0
  ]
}

register mie     : Minterrupts // Enabled
register mip     : Minterrupts // Pending
register medeleg : Medeleg     // Exception delegation to S-mode
register mideleg : Minterrupts // Interrupt delegation to S-mode

mapping clause csr_name_map = 0x304  <-> "mie"
mapping clause csr_name_map = 0x344  <-> "mip"
mapping clause csr_name_map = 0x302  <-> "medeleg"
mapping clause csr_name_map = 0x312  <-> "medelegh"
mapping clause csr_name_map = 0x303  <-> "mideleg"

function clause is_CSR_accessible(0x304, _, _) = true // mie
function clause is_CSR_accessible(0x344, _, _) = true // mip
function clause is_CSR_accessible(0x302, _, _) = currentlyEnabled(Ext_S) // medeleg
function clause is_CSR_accessible(0x312, _, _) = currentlyEnabled(Ext_S) & xlen == 32 // medelegh
function clause is_CSR_accessible(0x303, _, _) = currentlyEnabled(Ext_S) // mideleg

function clause read_CSR(0x304) = mie.bits
function clause read_CSR(0x344) = mip.bits
function clause read_CSR(0x302) = medeleg.bits[xlen - 1 .. 0]
function clause read_CSR(0x312 if xlen == 32) = medeleg.bits[63 .. 32]
function clause read_CSR(0x303) = mideleg.bits

function clause write_CSR(0x304, value) = { mie = legalize_mie(mie, value); Ok(mie.bits) }
function clause write_CSR(0x344, value) = { mip = legalize_mip(mip, value); Ok(mip.bits) }
function clause write_CSR((0x302, value) if xlen == 64) = { medeleg = legalize_medeleg(medeleg, value); Ok(medeleg.bits) }
function clause write_CSR((0x302, value) if xlen == 32) = { medeleg = legalize_medeleg(medeleg, medeleg.bits[63 .. 32] @ value); Ok(medeleg.bits[31 .. 0]) }
function clause write_CSR((0x312, value) if xlen == 32) = { medeleg = legalize_medeleg(medeleg, value @ medeleg.bits[31 .. 0]); Ok(medeleg.bits[63 .. 32]) }
function clause write_CSR(0x303, value) = { mideleg = legalize_mideleg(mideleg, value); Ok(mideleg.bits) }

function legalize_hvip(h : Minterrupts, v : xlenbits) -> Minterrupts = {
  let v = Mk_Minterrupts(v);
  [h with
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

// NOTE: Only VSSI is writable in hip (SGEI, VSEI, VSTI are read-only)
function legalize_hip(m : Minterrupts, v : xlenbits) -> Minterrupts = {
  let v = Mk_Minterrupts(v);
  [m with VSSI = v[VSSI]]
}

// NOTE: hvip.vssi is an alias of mip.vssi, so always read the
// actual value from mip. The remaining bits come from hvip.
function lower_mip_to_hvip(m : Minterrupts, h : Minterrupts) -> Minterrupts = {
  [h with VSSI = m[VSSI]]
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

function clause is_CSR_accessible(0x645, _, _) = currentlyEnabled(Ext_H) // hvip
function clause is_CSR_accessible(0x604, _, _) = currentlyEnabled(Ext_H) // hie
function clause is_CSR_accessible(0x644, _, _) = currentlyEnabled(Ext_H) // hip

function clause read_CSR(0x645) = lower_mip_to_hvip(mip, hvip).bits
function clause read_CSR(0x604) = lower_mie_to_hie(mie).bits
function clause read_CSR(0x644) = lower_mip_to_hip(mip).bits

function clause write_CSR(0x645, value) = { hvip = legalize_hvip(hvip, value); mip[VSSI] = hvip[VSSI]; Ok(hvip.bits) }
function clause write_CSR(0x604, value) = { mie = legalize_hie(mie, value); Ok(lower_mie_to_hie(mie).bits) }
function clause write_CSR(0x644, value) = { mip = legalize_hip(mip, value); Ok(lower_mip_to_hip(mip).bits) }

function legalize_hedeleg(_m: Medeleg, v: bits(64)) -> Medeleg = {
  [Mk_Medeleg(v) with
    SAMO_GPage_Fault  = 0b0,
    Virtual_Instr     = 0b0,
    Load_GPage_Fault  = 0b0,
    Fetch_GPage_Fault = 0b0,
    // TODO: Double Trap are read-only 0
    MEnvCall          = 0b0,
    VSEnvCall         = 0b0,
    SEnvCall          = 0b0,
  ]
}

function legalize_hideleg(m : Minterrupts, v : xlenbits) -> Minterrupts = {
  let v = Mk_Minterrupts(v);
  [m with
    VSEI = v[VSEI],
    VSTI = v[VSTI],
    VSSI = v[VSSI],
  ]
}

register hedeleg : Medeleg
register hideleg : Minterrupts

mapping clause csr_name_map = 0x602  <-> "hedeleg"
mapping clause csr_name_map = 0x603  <-> "hideleg"
mapping clause csr_name_map = 0x612  <-> "hedelegh"

function clause is_CSR_accessible(0x602, _, _) = currentlyEnabled(Ext_H) // hedeleg
function clause is_CSR_accessible(0x612, _, _) = currentlyEnabled(Ext_H) & xlen == 32 // hedelegh
function clause is_CSR_accessible(0x603, _, _) = currentlyEnabled(Ext_H) // hideleg

function clause read_CSR(0x602) = hedeleg.bits[xlen - 1 .. 0]
function clause read_CSR(0x612 if xlen == 32) = hedeleg.bits[63 .. 32]
function clause read_CSR(0x603) = hideleg.bits[xlen - 1 .. 0]

function clause write_CSR((0x602, value) if xlen == 64) = { hedeleg = legalize_hedeleg(hedeleg, value); Ok(hedeleg.bits) }
function clause write_CSR((0x602, value) if xlen == 32) = { hedeleg = legalize_hedeleg(hedeleg, hedeleg.bits[63 .. 32] @ value); Ok(hedeleg.bits[31 .. 0]) }
function clause write_CSR((0x612, value) if xlen == 32) = { hedeleg = legalize_hedeleg(hedeleg, value @ hedeleg.bits[31 .. 0]); Ok(hedeleg.bits[63 .. 32]) }
function clause write_CSR(0x603, value) = { hideleg = legalize_hideleg(hideleg, value); Ok(hideleg.bits) }

bitfield Sinterrupts : xlenbits = {
  LCOFI : 13, // local-counter-overflow interrupts
  SEI   : 9,  // external interrupts

  STI   : 5,  // timers interrupts

  SSI   : 1,  // software interrupts
}

// sip
// Provides the sip read view of mip (m) as delegated by mideleg (d).
private function lower_mip(m : Minterrupts, d : Minterrupts) -> Sinterrupts = {
  let s : Sinterrupts = Mk_Sinterrupts(zeros());

  [s with
    LCOFI = m[LCOFI] & d[LCOFI],
    SEI = m[SEI] & d[SEI],
    STI = m[STI] & d[STI],
    SSI = m[SSI] & d[SSI],
  ]
}

// Provides the sie read view of mie (m) as delegated by mideleg (d).
private function lower_mie(m : Minterrupts, d : Minterrupts) -> Sinterrupts = {
  let s : Sinterrupts = Mk_Sinterrupts(zeros());

  [s with
    LCOFI = m[LCOFI] & d[LCOFI],
    SEI = m[SEI] & d[SEI],
    STI = m[STI] & d[STI],
    SSI = m[SSI] & d[SSI],
  ]
}

// Returns vsip view of mip (m) as delegated by hideleg (d)
// Standard S-mode bits in vsip are aliases of corresponding VS-mode bits in
// hip if delegated by hideleg
function lower_mip_to_vsip(m : Minterrupts, d : Minterrupts) -> Minterrupts = {
  [Mk_Minterrupts(zeros()) with
    SEI = m[VSEI] & d[VSEI],
    STI = m[VSTI] & d[VSTI],
    SSI = m[VSSI] & d[VSSI],
  ]
}

// Returns vsie view of mie (m) as delegated by hideleg (d)
function lower_mie_to_vsie(m : Minterrupts, d : Minterrupts) -> Minterrupts = {
  let vs = Mk_Minterrupts(zeros());
  // Standard S-mode bits in vsie are aliases of corresponding VS-mode bits in
  // hie if delegated by hideleg
  [vs with
    SEI = m[VSEI] & d[VSEI],
    STI = m[VSTI] & d[VSTI],
    SSI = m[VSSI] & d[VSSI],
  ]
}

// Returns the new value of mip from the previous mip (o) and the written sip (s) as delegated by mideleg (d).
private function lift_sip(o : Minterrupts, d : Minterrupts, s : Sinterrupts) -> Minterrupts = {
  [o with
    SSI   = if d[SSI] == 0b1 then s[SSI] else o[SSI],
    LCOFI = if d[LCOFI] == 0b1 then s[LCOFI] else o[LCOFI],
  ]
}

private function legalize_sip(m : Minterrupts, d : Minterrupts, v : xlenbits) -> Minterrupts = {
  lift_sip(m, d, Mk_Sinterrupts(v))
}

// Virtual Supervisor
// Returns new mip from previous mip (m) and the written vsip (v) as delegated by hideleg (d)
function legalize_vsip(m : Minterrupts, d : Minterrupts, v : xlenbits) -> Minterrupts = {
  let v = Mk_Minterrupts(v);
  [m with VSSI = v[SSI] & d[VSSI]]
}

mapping clause csr_name_map = 0x144  <-> "sip"
function clause is_CSR_accessible(0x144, _, _) = currentlyEnabled(Ext_S) // sip
function clause read_CSR(0x144) =
  if inVirtualPrivilege()
  then lower_mip_to_vsip(mip, hideleg).bits
  else lower_mip(mip, mideleg).bits
function clause write_CSR(0x144, value) =
  if inVirtualPrivilege()
  then { mip = legalize_vsip(mip, hideleg, value); Ok(lower_mip_to_vsip(mip, hideleg).bits) }
  else { mip = legalize_sip(mip, mideleg, value); Ok(lower_mip(mip, mideleg).bits) }

// sie
// Returns the new value of mie from the previous mie (o) and the written sie (s) as delegated by mideleg (d).
private function lift_sie(o : Minterrupts, d : Minterrupts, s : Sinterrupts) -> Minterrupts = {
  [o with
    SEI   = if d[SEI] == 0b1 then s[SEI] else o[SEI],
    STI   = if d[STI] == 0b1 then s[STI] else o[STI],
    SSI   = if d[SSI] == 0b1 then s[SSI] else o[SSI],
    LCOFI = if d[LCOFI] == 0b1 then s[LCOFI] else o[LCOFI],
  ]
}

private function legalize_sie(m : Minterrupts, d : Minterrupts, v : xlenbits) -> Minterrupts = {
  lift_sie(m, d, Mk_Sinterrupts(v))
}

// Returns new mie from previous mie (m) and the written vsie (v) as delegated by hideleg (d)
function legalize_vsie(m : Minterrupts, d : Minterrupts, v : xlenbits) -> Minterrupts = {
  let v = Mk_Minterrupts(v);
  [m with
    VSEI = v[SEI] & d[VSEI],
    VSTI = v[STI] & d[VSTI],
    VSSI = v[SSI] & d[VSSI],
  ]
}

mapping clause csr_name_map = 0x104  <-> "sie"
function clause is_CSR_accessible(0x104, _, _) = currentlyEnabled(Ext_S) // sie
function clause read_CSR(0x104) =
  if inVirtualPrivilege()
  then lower_mie_to_vsie(mie, hideleg).bits
  else lower_mie(mie, mideleg).bits
function clause write_CSR(0x104, value) =
  if inVirtualPrivilege()
  then { mie = legalize_vsie(mie, hideleg, value); Ok(lower_mie_to_vsie(mie, hideleg).bits) }
  else { mie = legalize_sie(mie, mideleg, value); Ok(lower_mie(mie, mideleg).bits) }

register vsie : xlenbits
register vsip : xlenbits

mapping clause csr_name_map = 0x204  <-> "vsie"
mapping clause csr_name_map = 0x244  <-> "vsip"

function clause is_CSR_accessible(0x204, _, _) = currentlyEnabled(Ext_H) // vsie
function clause is_CSR_accessible(0x244, _, _) = currentlyEnabled(Ext_H) // vsip

function clause read_CSR(0x204) = lower_mie_to_vsie(mie, hideleg).bits
function clause read_CSR(0x244) = lower_mip_to_vsip(mip, hideleg).bits

function clause write_CSR(0x204, value) = { mie = legalize_vsie(mie, hideleg, value); Ok(lower_mie_to_vsie(mie, hideleg).bits) }
function clause write_CSR(0x244, value) = { mip = legalize_vsip(mip, hideleg, value); Ok(lower_mip_to_vsip(mip, hideleg).bits) }
