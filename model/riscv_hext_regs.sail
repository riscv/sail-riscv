/*=======================================================================================*/
/*  This Sail RISC-V architecture model, comprising all files and                        */
/*  directories except where otherwise noted is subject the BSD                          */
/*  two-clause license in the LICENSE file.                                              */
/*                                                                                       */
/*  SPDX-License-Identifier: BSD-2-Clause                                                */
/*=======================================================================================*/

/* Current Virtualization Mode */

register cur_virtualization : Virtualization

/* Hypervisor Status Register */

bitfield Hstatus : xlenbits = {
  /* VSXL only exists if HSXLEN == 64 so it's modelled via
   * explicit an getter and setter below. */
  /* VSXL : 33 .. 32 */
  VTSR  : 22,
  VTW   : 21,
  VTVM  : 20,
  VGEIN : 17 .. 12,
  HU    : 9,
  SPVP  : 8,
  SPV   : 7,
  GVA   : 6,
  VSBE  : 5
}
register hstatus : Hstatus

function get_hstatus_VSXL(h : Hstatus) -> arch_xlen = {
  if sizeof(xlen) == 32
  then arch_to_bits(RV32)
  else h.bits[33 .. 32]
}

function set_hstatus_VSXL(h : Hstatus, a : arch_xlen) -> Hstatus = {
  if sizeof(xlen) == 32
  then h
  else Mk_Hstatus([h.bits with 33..32 = a])
}

function legalize_hstatus(o : Hstatus, v : xlenbits) -> Hstatus = {
  let v = Mk_Hstatus(v);

  let h = [Mk_Hstatus(zeros()) with
    VTSR = v[VTSR],
    VTW = v[VTW],
    VTVM = v[VTVM],
    VGEIN = v[VGEIN], /* Note: 0 <= hstatus.VGEIN <= GEILEN */
    HU = v[HU],
    SPVP = v[SPVP],
    SPV = v[SPV],
    GVA = v[GVA],
    VSBE = v[VSBE]
  ];

  /* Dynamic XLEN changes are not (yet) supported */
  let h = set_hstatus_VSXL(h, get_hstatus_VSXL(o));

  h
}

/* Hypervisor Trap Delegation Registers */

register hedeleg : Medeleg

function legalize_hedeleg(o: Medeleg, v: xlenbits) -> Medeleg = {
  let h = Mk_Medeleg(v);
  /* Mask read-only zero bits */
  let h = [h with SAMO_GPage_Fault  = 0b0];
  let h = [h with Virtual_Instr     = 0b0];
  let h = [h with Load_GPage_Fault  = 0b0];
  let h = [h with Fetch_GPage_Fault = 0b0];
  let h = [h with MEnvCall          = 0b0];
  let h = [h with VSEnvCall         = 0b0];
  let h = [h with SEnvCall          = 0b0];
  h
}

register hideleg : Minterrupts

function legalize_hideleg(h : Minterrupts, v : xlenbits) -> Minterrupts = {
  let v = Mk_Minterrupts(v);
  /* VS-level interrupts can be delegated */
  let h = [h with VSEI = v[VSEI]];
  let h = [h with VSTI = v[VSTI]];
  let h = [h with VSSI = v[VSSI]];
  /* Other interrupts can't be delegated to VS-mode */
  h
}

/* Hypervisor Interrupt enable/pending registers */

/*! Returns new mip from the previous mip (m) and the written hvip (v) */
function legalize_hvip(m: Minterrupts, v : xlenbits) -> Minterrupts = {
  let v = Mk_Minterrupts(v);
  let m = [m with VSEI = v[VSEI]];
  let m = [m with VSTI = v[VSTI]];
  let m = [m with VSSI = v[VSSI]];
  // TODO: Hook to update non-standard portion
  m
}

/*! Returns hvip view of mip (m) */
function lower_mip_to_hvip(m : Minterrupts) -> Minterrupts = {
  let h = Mk_Minterrupts(zeros());
  let h = [h with VSEI = m[VSEI]];
  let h = [h with VSTI = m[VSTI]];
  let h = [h with VSSI = m[VSSI]];
  // TODO: Hook to read non-standard portion
  h
}

/*! Returns new mip from the previous mip (m) and the written hip (v) */
function legalize_hip(m : Minterrupts, v : xlenbits) -> Minterrupts = {
  let v = Mk_Minterrupts(v);
  let m = [m with VSSI = v[VSSI]];
  // TODO: Hook to update non-standard portion
  m
}

/*! Returns hip view of mip (m) */
function lower_mip_to_hip(m : Minterrupts) -> Minterrupts = {
  let h = Mk_Minterrupts(zeros());
  let h = [h with SGEI = m[SGEI]];
  let h = [h with VSEI = m[VSEI]];
  let h = [h with VSTI = m[VSTI]];
  let h = [h with VSSI = m[VSSI]];
  // TODO: Hook to read non-standard portion
  h
}

/*! Returns new mie from the previous mie (m) and the written hie (v) */
function legalize_hie(m : Minterrupts, v : xlenbits) -> Minterrupts = {
  let v = Mk_Minterrupts(v);
  let m = [m with SGEI = v[SGEI]];
  let m = [m with VSEI = v[VSEI]];
  let m = [m with VSTI = v[VSTI]];
  let m = [m with VSSI = v[VSSI]];
  /* Note: Writable bits in sie are read-only zero in hie */
  // TODO: Hook to update non-standard portion
  m
}

/*! Returns hie view of mie */
function lower_mie_to_hie(m : Minterrupts) -> Minterrupts = {
  let h = Mk_Minterrupts(zeros());
  let h = [h with SGEI = m[SGEI]];
  let h = [h with VSEI = m[VSEI]];
  let h = [h with VSTI = m[VSTI]];
  let h = [h with VSSI = m[VSSI]];
  /* Note: Writable bits in sie are read-only zero in hie */
  // TODO: Hook to read non-standard portion
  h
}

/* Hypervisor Guest External Interrupts */

register hgeie : xlenbits
register hgeip : xlenbits

// FIXME: hgeip should be written by interrupt controller
// TODO: hip.SGEI is 1 if bitwise and of hgeip and hgeie is nonzero in any bit
// TODO: hip.VSEI is 1 if hgeip[hstatus.VGEIN] is 1

function legalize_hgeie(v : xlenbits) -> xlenbits = {
  [v with 0 = bitzero]
}

/* Hypervisor environment configuration register */

bitfield HEnvcfg : bits(64) = {
  // Supervisor TimeCmp Extension
  STCE   : 63,
  // Page Based Memory Types Extension
  PBMTE  : 62,
  // Reserved WPRI bits.
  wpri_1 : 61 .. 8,
  // Cache Block Zero instruction Enable
  CBZE   : 7,
  // Cache Block Clean and Flush instruction Enable
  CBCFE  : 6,
  // Cache Block Invalidate instruction Enable
  CBIE   : 5 .. 4,
  // Reserved WPRI bits.
  wpri_0 : 3 .. 1,
  // Fence of I/O implies Memory
  FIOM   : 0,
}
register henvcfg : HEnvcfg

function legalize_henvcfg(o : HEnvcfg, v : bits(64)) -> HEnvcfg = {
  let v = Mk_HEnvcfg(v);
  let o = [o with FIOM = if sys_enable_writable_fiom() then v[FIOM] else 0b0];
  // Other extensions are not implemented yet so all other fields are read only zero.
  o
}

/* Hypervisor hpm-related registers */

register hcounteren : Counteren

function legalize_hcounteren(c : Counteren, v : xlenbits) -> Counteren = {
  /* no HPM counters yet */
  [c with IR = [v[2]], TM = [v[1]], CY = [v[0]]]
}

register htimedelta : bits(64)

/* Machine & Hypervisor trap information */

register mtinst : xlenbits
register mtval2 : xlenbits

register htinst : xlenbits
register htval  : xlenbits

/* Hypervisor Guest Address Translation and Protection */

bitfield Hgatp64 : bits(64) = {
  Mode : 63 .. 60,
  Vmid : 57 .. 44,
  PPN  : 43 .. 0
}

function legalize_hgatp64(a : Architecture, o : bits(64), v : bits(64)) -> bits(64) = {
  let h = Mk_Hgatp64(v[63 .. 60] @ 0b00 @ v[57 .. 44] @ v[43 .. 2] @ 0b00);
  match hgatp64Mode_of_bits(a, h[Mode]) {
    Some(Bare)   => h[Mode] @ zeros(60), /* remaining fields should be zero when hgatp.Mode is Bare */
    Some(Sv32x4) => o,                   /* Sv32x4 is currently unsupported for hgatp64 */
    Some(Sv39x4) => h.bits,
    Some(Sv48x4) => h.bits,
    Some(Sv57x4) => o,                   /* Sv57x4 is not yet implemented */
    _            => o,                   /* (V)S-stage modes are illegal for hgatp */
  }
}

bitfield Hgatp32 : bits(32) = {
  Mode : 31,
  Vmid : 28 .. 22,
  PPN  : 21 .. 0
}

function legalize_hgatp32(a : Architecture, o : bits(32), v : bits(32)) -> bits(32) = {
  let h = Mk_Hgatp32(v[31 .. 31] @ 0b00 @ v[28 .. 22] @ v[21 .. 2] @ 0b00);
  match hgatp64Mode_of_bits(a, zero_extend(h[Mode])) {
    None()     => o,
    Some(Bare) => h[Mode] @ zeros(31), /* remaining fields should be zero when hgatp.Mode is Bare */
    Some(_)    => h.bits
  }
}

/* Virtual Supervisor Status Register */

register vsstatus : Sstatus

function legalize_vsstatus(vs: Sstatus, v: xlenbits) -> Sstatus = {
  let m = Mk_Mstatus(vs.bits);    /* Convert to Mstatus   */
  let s = legalize_sstatus(m, v); /* Legalize Mstatus for sstatus */
  Mk_Sstatus(s.bits)              /* Convert back to Sstatus  */
}

/* Virtual Supervisor Trap Vector Base Address Register */

register vstvec : Mtvec

/* Virtual Supervisor Scratch Register */

register vsscratch : xlenbits

/* Virtual Supervisor Exception Program Counter */

register vsepc : xlenbits

/* Virtual Supervisor Cause Register */

register vscause : Mcause

/* Virtual Supervisor Trap Value Register */

register vstval : xlenbits

/* Virtual Supervisor interrupt enable/pending registers */

/*! Returns new mip from the previous mip (m) and the written vsip (v) as delegated by hideleg (d) */
function legalize_vsip(m: Minterrupts, d : Minterrupts, v : xlenbits) -> Minterrupts = {
  let v = Mk_Minterrupts(v);
  /* Since S-mode bits in vsip are aliases for their corresponding VS-mode bits
     in hip when delegated by hideleg, only vsip.SSIP (hip.VSSIP) might be writable */
  let m = [m with VSSI = v[SSI] & d[VSSI]];
  m
}

/*! Returns vsip view of mip (m) as delegated by hideleg (d) */
function lower_mip_to_vsip(m : Minterrupts, d : Minterrupts) -> Minterrupts = {
  let vs = Mk_Minterrupts(zeros());
  /* Standard S-mode bits in vsip are aliases of corresponding VS-mode bits in
     hip if delegated by hideleg */
  let vs = [vs with SEI = m[VSEI] & d[VSEI]];
  let vs = [vs with STI = m[VSTI] & d[VSTI]];
  let vs = [vs with SSI = m[VSSI] & d[VSSI]];
  vs
}

/*! Returns new mie from previous mie (m) and the written vsie (v) as delegated by hideleg (d) */
function legalize_vsie(m : Minterrupts, d : Minterrupts, v : xlenbits) -> Minterrupts = {
  let v = Mk_Minterrupts(v);
  let m = [m with VSEI = v[SEI] & d[VSEI]];
  let m = [m with VSTI = v[STI] & d[VSTI]];
  let m = [m with VSSI = v[SSI] & d[VSSI]];
  m
}

/*! Returns vsie view of mie (m) as delegated by hideleg (d) */
function lower_mie_to_vsie(m : Minterrupts, d : Minterrupts) -> Minterrupts = {
  let vs = Mk_Minterrupts(zeros());
  /* Standard S-mode bits in vsie are aliases of corresponding VS-mode bits in
    hie if delegated by hideleg */
  let vs = [vs with SEI = m[VSEI] & d[VSEI]];
  let vs = [vs with STI = m[VSTI] & d[VSTI]];
  let vs = [vs with SSI = m[VSSI] & d[VSSI]];
  vs
}

/* Virtual Supervisor address translation & Protection */

register vsatp : xlenbits
