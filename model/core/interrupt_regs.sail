// =======================================================================================
// This Sail RISC-V architecture model, comprising all files and
// directories except where otherwise noted is subject the BSD
// two-clause license in the LICENSE file.
//
// SPDX-License-Identifier: BSD-2-Clause
// =======================================================================================

// State and access functions for mip, sip, mie, sie, medeleg and mideleg.
// These are surprisingly complex, especially SEIP which also breaks the
// standard CSR read-modify-write system.

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
  ]
}

private function legalize_mie(o : Minterrupts, v : xlenbits) -> Minterrupts = {
  let v = Mk_Minterrupts(v);
  [o with
    LCOFI = if currentlyEnabled(Ext_Sscofpmf) then v[LCOFI] else 0b0,
    MEI = v[MEI],
    MTI = v[MTI],
    MSI = v[MSI],
    SEI = if currentlyEnabled(Ext_S) then v[SEI] else 0b0,
    STI = if currentlyEnabled(Ext_S) then v[STI] else 0b0,
    SSI = if currentlyEnabled(Ext_S) then v[SSI] else 0b0,
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
  ]
}

bitfield Medeleg : bits(64) = {
  SAMO_Page_Fault   : 15,
  Load_Page_Fault   : 13,
  Fetch_Page_Fault  : 12,
  MEnvCall          : 11,
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
  [Mk_Medeleg(v) with MEnvCall = 0b0]
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

mapping clause csr_name_map = 0x144  <-> "sip"
function clause is_CSR_accessible(0x144, _, _) = currentlyEnabled(Ext_S) // sip
function clause read_CSR(0x144) = lower_mip(mip, mideleg).bits
function clause write_CSR(0x144, value) = { mip = legalize_sip(mip, mideleg, value); Ok(lower_mip(mip, mideleg).bits) }

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

mapping clause csr_name_map = 0x104  <-> "sie"
function clause is_CSR_accessible(0x104, _, _) = currentlyEnabled(Ext_S) // sie
function clause read_CSR(0x104) = lower_mie(mie, mideleg).bits
function clause write_CSR(0x104, value) = { mie = legalize_sie(mie, mideleg, value); Ok(lower_mie(mie, mideleg).bits) }
