// =======================================================================================
// This Sail RISC-V architecture model, comprising all files and
// directories except where otherwise noted is subject the BSD
// two-clause license in the LICENSE file.
//
// SPDX-License-Identifier: BSD-2-Clause
// =======================================================================================

// Machine-mode and supervisor-mode state definitions.

// privilege level

register cur_privilege : Privilege

// current instruction bits, used for illegal instruction exceptions

register cur_inst : xlenbits

// State projections
//
// Some machine state is processed via projections from machine-mode views to
// views from lower privilege levels.  So, for e.g. when mstatus is read from
// lower privilege levels, we use 'lowering_' projections:
//
// mstatus  ->  sstatus
//
// Similarly, when machine state is written from lower privileges, that state is
// lifted into the appropriate value for the machine-mode state.
//
// sstatus  ->  mstatus
//
// In addition, several fields in machine state registers are WARL or WLRL,
// requiring that values written to the registers be legalized.  For each such
// register, there will be an associated 'legalize_' function.  These functions
// will need to be supplied externally, and will depend on the legal values
// supported by a platform/implementation (or misa).  The legalize_ functions
// generate a legal value from the current value and the written value.  In more
// complex cases, they will also implicitly read the current values of misa,
// mstatus, etc.
//
// Each register definition below is followed by custom projections
// and choice of legalizations if needed.  For now, we typically
// implement the simplest legalize_ alternatives.


// M-mode registers

bitfield Misa : xlenbits = {
  MXL  : xlen - 1 .. xlen - 2,

  Z    : 25,
  Y    : 24,
  X    : 23,
  W    : 22,
  V    : 21,
  U    : 20,
  T    : 19,
  S    : 18,
  R    : 17,
  Q    : 16,
  P    : 15,
  O    : 14,
  N    : 13,
  M    : 12,
  L    : 11,
  K    : 10,
  J    : 9,
  I    : 8,
  H    : 7,
  G    : 6,
  F    : 5,
  E    : 4,
  D    : 3,
  C    : 2,
  B    : 1,
  A    : 0
}
register misa : Misa =
  [ Mk_Misa(zeros()) with
    // MXL is a read-only field that specifies the native XLEN.
    MXL = architecture_bits(if xlen == 32 then RV32 else RV64),
  ]

// whether misa is R/W
let sys_enable_writable_misa : bool = config base.writable_misa

// Whether FIOM bit of menvcfg/senvcfg is enabled. It must be enabled if
// supervisor mode is implemented and non-bare addressing modes are supported.
let sys_enable_writable_fiom : bool = config base.writable_fiom

// Which HPM counters are supported (as a bit mask). Bits [2 .. 0] are ignored.
let sys_writable_hpm_counters : bits(32) = config base.writable_hpm_counters

// Supervisor timecmp
function clause currentlyEnabled(Ext_Sstc) = hartSupports(Ext_Sstc)

// This function allows an extension to veto a write to Misa
// if it would violate an alignment restriction on
// unsetting C. If it returns true the write will have no effect.
val ext_veto_disable_C : unit -> bool

private function legalize_misa(m : Misa, v : xlenbits) -> Misa = {
  let v = Mk_Misa(v);
  // Suppress updates to MISA if MISA is not writable or if by disabling C next PC would become misaligned or an extension vetoes
  if   not(sys_enable_writable_misa) | (v[C] == 0b0 & (nextPC[1] == 0b1 | ext_veto_disable_C()))
  then m
  else [m with
    A = if hartSupports(Ext_A) then v[A] else 0b0,
    B = if hartSupports(Ext_B) then v[B] else 0b0,
    C = if hartSupports(Ext_C) then v[C] else 0b0,
    D = if hartSupports(Ext_D) & v[F] == 0b1 then v[D] else 0b0,
    F = if hartSupports(Ext_F) then v[F] else 0b0,
    H = if hartSupports(Ext_H) then v[H] else 0b0, // TODO: Not fully supported yet
    // Writable I is not currently supported.
    I = bool_to_bit(not(base_E_enabled)),
    E = bool_to_bit(base_E_enabled),
    M = if hartSupports(Ext_M) then v[M] else 0b0,
    // Q = if hartSupports(Ext_Q) then v[Q] else 0b0, TODO: Not supported yet
    S = if hartSupports(Ext_S) & v[U] == 0b1 then v[S] else 0b0,
    U = if hartSupports(Ext_U) then v[U] else 0b0,
    V = if hartSupports(Ext_V) & v[F] == 0b1 & v[D] == 0b1 then v[V] else 0b0,
    // X = ... TODO: If custom extensions are present this should be 1
  ]
}

mapping clause csr_name_map = 0x301  <-> "misa"
function clause is_CSR_accessible(0x301, _, _) = true // misa
function clause read_CSR(0x301) = misa.bits
function clause write_CSR(0x301, value) = { misa = legalize_misa(misa, value); Ok(misa.bits) }

// Are supervisor/user mode currently enabled? Although
// unlikely and not currently supported by the model,
// you are technically allowed to have writable misa[U/S].
function clause currentlyEnabled(Ext_U) = hartSupports(Ext_U) & misa[U] == 0b1 & currentlyEnabled(Ext_Zicsr)
function clause currentlyEnabled(Ext_S) = hartSupports(Ext_S) & misa[S] == 0b1 & currentlyEnabled(Ext_Zicsr)
function clause currentlyEnabled(Ext_H) = hartSupports(Ext_H) & misa[H] == 0b1 & misa[I] == 0b1 & currentlyEnabled(Ext_S) & currentlyEnabled(Ext_Zicsr)
// This will need adjusting for dynamic XLEN.
function clause currentlyEnabled(Ext_Ssu64xl) = hartSupports(Ext_Ssu64xl) & currentlyEnabled(Ext_S)

function clause currentlyEnabled(Ext_Svbare) = currentlyEnabled(Ext_S)
function clause currentlyEnabled(Ext_Sv32) = hartSupports(Ext_Sv32) &  currentlyEnabled(Ext_S)
function clause currentlyEnabled(Ext_Sv39) = hartSupports(Ext_Sv39) &  currentlyEnabled(Ext_S)
function clause currentlyEnabled(Ext_Sv48) = hartSupports(Ext_Sv48) &  currentlyEnabled(Ext_S)
function clause currentlyEnabled(Ext_Sv57) = hartSupports(Ext_Sv57) &  currentlyEnabled(Ext_S)

function virtual_memory_supported() -> bool = {
  currentlyEnabled(Ext_Sv32) | currentlyEnabled(Ext_Sv39) | currentlyEnabled(Ext_Sv48) | currentlyEnabled(Ext_Sv57)
}

// This measure needs to be > currentlyEnabled_measure(Ext_Sv{32,39,48,57}),
// currently all equal to 2, see currentlyEnabled_measure in extensions.sail
termination_measure virtual_memory_supported(_) = 3

//
// Illegal values legalized to least privileged mode supported.
// Note: the only valid combinations of supported modes are M, M+U, M+S+U.
function lowest_supported_privLevel() -> Privilege =
  if currentlyEnabled(Ext_U) then User else Machine

function have_nominal_privLevel(priv : nom_priv_bits) -> bool =
  match priv {
    0b00 => currentlyEnabled(Ext_U),
    0b01 => currentlyEnabled(Ext_S),
    0b10 => false,
    0b11 => true,
  }

bitfield Mstatus : bits(64) = {
  SD   : xlen - 1,

  //MDT  : 42,
  MPELP: 41,

  MPV  : 39,
  GVA  : 38,

  MBE  : 37,
  SBE  : 36,

  SXL  : 35 .. 34,
  UXL  : 33 .. 32,

  //SDT  : 24,
  SPELP: 23,
  TSR  : 22,
  TW   : 21,
  TVM  : 20,
  MXR  : 19,
  SUM  : 18,
  MPRV : 17,

  XS   : 16 .. 15,
  FS   : 14 .. 13,

  MPP  : 12 .. 11,
  VS   : 10 .. 9,
  SPP  : 8,

  MPIE : 7,
  SPIE : 5,

  MIE  : 3,
  SIE  : 1,
}

private function legalize_mstatus(o : Mstatus, v : bits(64)) -> Mstatus = {
  // Populate all defined fields using the bits of v, stripping anything
  // that does not have a matching bitfield entry. The SD bits are handled
  // explicitly later depending on xlen.
  let v = Mk_Mstatus(v);

  let o = [o with
    // MDT = v[MDT],
    MPELP = if hartSupports(Ext_Zicfilp) then v[MPELP] else 0b0,
    MPV   = if currentlyEnabled(Ext_H) then v[MPV] else 0b0,
    GVA   = if currentlyEnabled(Ext_H) then v[GVA] else 0b0,
    // We don't currently support changing MBE and SBE.
    // MBE = v[MBE],
    // SBE = v[SBE],
    // We don't support dynamic changes to SXL and UXL.
    // SXL = if xlen == 64 then v[SXL] else o[SXL],
    // UXL = if xlen == 64 then v[UXL] else o[UXL],
    // SDT = v[SDT],
    SPELP = if hartSupports(Ext_Zicfilp) then v[SPELP] else 0b0,
    TSR = if currentlyEnabled(Ext_S) then v[TSR] else 0b0,
    TW = if currentlyEnabled(Ext_U) then v[TW] else 0b0,
    TVM = if currentlyEnabled(Ext_S) then v[TVM] else 0b0,
    MXR = if currentlyEnabled(Ext_S) then v[MXR] else 0b0,
    SUM = if virtual_memory_supported() then v[SUM] else 0b0,
    MPRV = if currentlyEnabled(Ext_U) then v[MPRV] else 0b0,
    // We don't have any extension context yet.
    XS = extStatus_to_bits(Off),
    // FS is WARL, and making FS writable can support the M-mode emulation of an FPU
    // to support code running in S/U-modes.  Spike does this, and for now, we match it,
    // but only if Zfinx isn't enabled.
    // FIXME: This should be made a platform parameter.
    FS = if hartSupports(Ext_Zfinx) then extStatus_to_bits(Off) else v[FS],
    MPP = if have_nominal_privLevel(v[MPP]) then v[MPP] else privLevel_to_bits(lowest_supported_privLevel()),
    SPP = if currentlyEnabled(Ext_S) then v[SPP] else 0b0,
    // TODO: make this configurable
    // If neither the v registers nor S-mode is implemented, then VS is
    // read-only zero. If S-mode is implemented but the v registers are not,
    // VS may optionally be read-only zero.
    VS = if hartSupports(Ext_Zve32x) then v[VS] else 0b00,
    MPIE = v[MPIE],
    SPIE = if currentlyEnabled(Ext_S) then v[SPIE] else 0b0,
    MIE = v[MIE],
    SIE = if currentlyEnabled(Ext_S) then v[SIE] else 0b0,
  ];

  // Set dirty bit to OR of other status bits.
  let dirty = extStatus_of_bits(o[FS]) == Dirty |
              extStatus_of_bits(o[XS]) == Dirty |
              extStatus_of_bits(o[VS]) == Dirty;

  [o with SD = bool_to_bit(dirty)]
}

register mstatus : Mstatus = {
  // Initialise SXL and UXL.
  let mxl = architecture_bits(if xlen == 32 then RV32 else RV64);
  [ Mk_Mstatus(zeros()) with
    // These fields do not exist on RV32 and are read-only zero
    // if the corresponding mode is not supported.
    SXL = if xlen != 32 & hartSupports(Ext_S) then mxl else zeros(),
    UXL = if xlen != 32 & hartSupports(Ext_U) then mxl else zeros(),
  ]
}

mapping clause csr_name_map = 0x300  <-> "mstatus"
mapping clause csr_name_map = 0x310  <-> "mstatush"

function clause is_CSR_accessible(0x300, _, _) = true // mstatus
function clause is_CSR_accessible(0x310, _, _) = xlen == 32 // mstatush

function clause read_CSR(0x300) = mstatus.bits[xlen - 1 .. 0]
function clause read_CSR(0x310 if xlen == 32) = mstatus.bits[63 .. 32]

function clause write_CSR((0x300, value) if xlen == 64) = { mstatus = legalize_mstatus(mstatus, value); Ok(mstatus.bits) }
function clause write_CSR((0x300, value) if xlen == 32) = { mstatus = legalize_mstatus(mstatus, mstatus.bits[63 .. 32] @ value); Ok(mstatus.bits[31 .. 0]) }
function clause write_CSR((0x310, value) if xlen == 32) = { mstatus = legalize_mstatus(mstatus, value @ mstatus.bits[31 .. 0]); Ok(mstatus.bits[63 .. 32]) }

bitfield Hstatus : bits(64) = {
  HUPMM : 49 .. 48,
  VSXL  : 33 .. 32,
  VTSR  : 22,
  VTW   : 21,
  VTVM  : 20,
  VGEIN : 17 .. 12,
  HU    : 9,
  SPVP  : 8,
  SPV   : 7,
  GVA   : 6,
  VSBE  : 5,
}

function legalize_hstatus(h : Hstatus, v : bits(64)) -> Hstatus = {
  let v = Mk_Hstatus(v);
  [h with
    // HUPMM = if currentlyEnabled(Ext_Ssnpm) & xlen == 64 then v[HUPMM] else 0b00,
    // We don't currently support changing VSXL
    // VSXL = v[VSXL]
    VTSR  = v[VTSR],
    VTW   = v[VTW],
    VTVM  = v[VTVM],
    VGEIN = v[VGEIN], // TODO: Add config option
    HU    = v[HU],
    SPVP  = v[SPVP],
    SPV   = v[SPV],
    GVA   = v[GVA],
    // We don't currently support changing VSBE
    // VSBE  = v[VSBE],
  ]
}

register hstatus : Hstatus = [Mk_Hstatus(zeros()) with
  VSXL = architecture_bits(if xlen == 32 then RV32 else RV64)
]

mapping clause csr_name_map = 0x600 <-> "hstatus"
function clause is_CSR_accessible(0x600, _, _) = currentlyEnabled(Ext_H) //hstatus
function clause read_CSR(0x600) = hstatus.bits[xlen - 1 .. 0]
function clause write_CSR(0x600, value) = { hstatus = legalize_hstatus(hstatus, zero_extend(value)); Ok(hstatus.bits[xlen - 1 .. 0]) }

// architecture and extension checks

bitfield Seccfg : bits(64) = {
  // Enable Zicfilp in M-mode
  MLPE   : 10,
  // Enable access to SEED in S-mode
  SSEED  : 9,
  // Enable access to SEED in U-mode
  USEED  : 8,
}

private function legalize_mseccfg(o : Seccfg, v : bits(64)) -> Seccfg = {
  let sseed_read_only_zero =
      (config extensions.Zkr.sseed_read_only_zero : bool)
    | not(currentlyEnabled(Ext_S))
    | not(currentlyEnabled(Ext_Zkr));
  let useed_read_only_zero =
      (config extensions.Zkr.useed_read_only_zero : bool)
    | not(currentlyEnabled(Ext_U))
    | not(currentlyEnabled(Ext_Zkr));

  let v = Mk_Seccfg(v);
  [o with
    MLPE  = if hartSupports(Ext_Zicfilp) then v[MLPE] else 0b0,
    SSEED = if sseed_read_only_zero then 0b0 else v[SSEED],
    USEED = if useed_read_only_zero then 0b0 else v[USEED],
  ]
}

register mseccfg : Seccfg = legalize_mseccfg(Mk_Seccfg(zeros()), zeros())

mapping clause csr_name_map = 0x747  <-> "mseccfg"
mapping clause csr_name_map = 0x757  <-> "mseccfgh"

// "mseccfg exists if Zkr is implemented, or if it is required by other processor features."
function clause is_CSR_accessible(0x747, _, _) = currentlyEnabled(Ext_Zkr) | hartSupports(Ext_Zicfilp) // mseccfg
function clause is_CSR_accessible(0x757, _, _) = (currentlyEnabled(Ext_Zkr) | hartSupports(Ext_Zicfilp)) & xlen == 32 // mseccfgh

function clause read_CSR(0x747) = mseccfg.bits[xlen - 1 .. 0]
function clause read_CSR(0x757 if xlen == 32) = mseccfg.bits[63 .. 32]

function clause write_CSR((0x747, value) if xlen == 32) = {
  mseccfg = legalize_mseccfg(mseccfg, mseccfg.bits[63 .. 32] @ value);
  Ok(mseccfg.bits[31 .. 0])
}
function clause write_CSR((0x747, value) if xlen == 64) = {
  mseccfg = legalize_mseccfg(mseccfg, value);
  Ok(mseccfg.bits)
}
function clause write_CSR((0x757, value) if xlen == 32) = {
  mseccfg = legalize_mseccfg(mseccfg, value @ mseccfg.bits[31 .. 0]);
  Ok(mseccfg.bits[63 .. 32])
}


// envcfg Resisters
bitfield MEnvcfg : bits(64) = {
  // Supervisor TimeCmp Extension
  STCE   : 63,
  // Page Based Memory Types Extension
  PBMTE  : 62,
  // Cache Block Zero instruction Enable
  CBZE   : 7,
  // Cache Block Clean and Flush instruction Enable
  CBCFE  : 6,
  // Cache Block Invalidate instruction Enable
  CBIE   : 5 .. 4,
  // Landing Pad Enable
  LPE    : 2,
  // Fence of I/O implies Memory
  FIOM   : 0,
}

bitfield SEnvcfg : xlenbits = {
  // Cache Block Zero instruction Enable
  CBZE   : 7,
  // Cache Block Clean and Flush instruction Enable
  CBCFE  : 6,
  // Cache Block Invalidate instruction Enable
  CBIE   : 5 .. 4,
  // Landing Pad Enable
  LPE    : 2,
  // Fence of I/O implies Memory
  FIOM   : 0,
}

private function legalize_xenvcfg_cbie(cbie : bits(2)) -> bits(2) = {
  if cbie != 0b10 then {
    cbie
  } else match xenvcfg_cbie_reserved_behavior {
      Xenvcfg_Fatal => reserved_behavior("xenvcfg.CBIE = 0b10"),
      Xenvcfg_ClearPermissions => 0b00,
    }
}

private function legalize_menvcfg(o : MEnvcfg, v : bits(64)) -> MEnvcfg = {
  let v = Mk_MEnvcfg(v);
  [o with
    FIOM = if sys_enable_writable_fiom then v[FIOM] else 0b0,
    LPE  = if hartSupports(Ext_Zicfilp) then v[LPE] else 0b0,
    CBZE = if currentlyEnabled(Ext_Zicboz) then v[CBZE] else 0b0,
    CBCFE = if currentlyEnabled(Ext_Zicbom) then v[CBCFE] else 0b0,
    CBIE = if currentlyEnabled(Ext_Zicbom) then legalize_xenvcfg_cbie(v[CBIE]) else 0b00,
    STCE = if currentlyEnabled(Ext_Sstc) then v[STCE] else 0b0,
    // Other extensions are not implemented yet so all other fields are read only zero.
  ]
}

private function legalize_senvcfg(o : SEnvcfg, v : xlenbits) -> SEnvcfg = {
  let v = Mk_SEnvcfg(v);
  [o with
    FIOM = if sys_enable_writable_fiom then v[FIOM] else 0b0,
    LPE = if hartSupports(Ext_Zicfilp) then v[LPE] else 0b0,
    CBZE = if currentlyEnabled(Ext_Zicboz) then v[CBZE] else 0b0,
    CBCFE = if currentlyEnabled(Ext_Zicbom) then v[CBCFE] else 0b0,
    CBIE = if currentlyEnabled(Ext_Zicbom) then legalize_xenvcfg_cbie(v[CBIE]) else 0b00,
    // Other extensions are not implemented yet so all other fields are read only zero.
  ]
}

// Initialised to legal values in case some bits are hard-coded to 1.
register menvcfg : MEnvcfg = legalize_menvcfg(Mk_MEnvcfg(zeros()), zeros())
register senvcfg : SEnvcfg = legalize_senvcfg(Mk_SEnvcfg(zeros()), zeros())

mapping clause csr_name_map = 0x30A  <-> "menvcfg"
mapping clause csr_name_map = 0x31A  <-> "menvcfgh"
mapping clause csr_name_map = 0x10A  <-> "senvcfg"

function clause is_CSR_accessible(0x30A, _, _) = currentlyEnabled(Ext_U) // menvcfg
function clause is_CSR_accessible(0x31A, _, _) = currentlyEnabled(Ext_U) & (xlen == 32) // menvcfgh

// This should ideally also check `xstateen.ENVCFG`, but due to module
// interdependency issues, that is handled by `stateen_allows_CSR_access`.
function clause is_CSR_accessible(0x10A, _, _) = currentlyEnabled(Ext_S) // senvcfg

function clause read_CSR(0x30A) = menvcfg.bits[xlen - 1 .. 0]
function clause read_CSR(0x31A if xlen == 32) = menvcfg.bits[63 .. 32]
function clause read_CSR(0x10A) = senvcfg.bits[xlen - 1 .. 0]

function clause write_CSR((0x30A, value) if xlen == 32) = { menvcfg = legalize_menvcfg(menvcfg, menvcfg.bits[63 .. 32] @ value); Ok(menvcfg.bits[31 .. 0]) }
function clause write_CSR((0x30A, value) if xlen == 64) = { menvcfg = legalize_menvcfg(menvcfg, value); Ok(menvcfg.bits) }
function clause write_CSR((0x31A, value) if xlen == 32) = { menvcfg = legalize_menvcfg(menvcfg, value @ menvcfg.bits[31 .. 0]); Ok(menvcfg.bits[63 .. 32]) }
function clause write_CSR(0x10A, value) = { senvcfg = legalize_senvcfg(senvcfg, zero_extend(value)); Ok(senvcfg.bits[xlen - 1 .. 0]) }

// Return whether or not FIOM is currently active, based on the current
// privilege and the menvcfg/senvcfg settings. This means that I/O fences
// imply memory fence.
function is_fiom_active() -> bool = {
  match cur_privilege {
    Machine           => false,
    Supervisor        => menvcfg[FIOM] == 0b1,
    User              => (menvcfg[FIOM] | senvcfg[FIOM]) == 0b1,
    VirtualUser       => internal_error(__FILE__, __LINE__, "Hypervisor extension not supported"),
    VirtualSupervisor => internal_error(__FILE__, __LINE__, "Hypervisor extension not supported"),
  }
}

// interrupt processing state

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
<<<<<<< HEAD
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
=======
  let v = Mk_Minterrupts(v);
  [v with
    // FIXME: needs verification against eventual spec language.
    MEI = 0b0,
    MTI = 0b0,
    MSI = 0b0,
    // VS-mode interrupts are always delegated when H-extension is present
    VSEI = if currentlyEnabled(Ext_H) then 0b1 else v[VSEI],
    VSTI = if currentlyEnabled(Ext_H) then 0b1 else v[VSTI],
    VSSI = if currentlyEnabled(Ext_H) then 0b1 else v[VSSI],
    // TODO: SGEI is always delegated if GEILEN > 0
    SGEI = if currentlyEnabled(Ext_H) then 0b1 else v[SGEI],
>>>>>>> 9c01ebb4 (Add hypervisor CSRs and legalization logic)
  ]
}
// exception processing state

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

// registers for trap handling

bitfield Mtvec : xlenbits = {
  Base : xlen - 1 .. 2,
  Mode : 1 .. 0
}
register mtvec : Mtvec  // Trap Vector

// PUBLIC: invoked from set_{ms}tvec() [exceptions/sys_exceptions.sail]
function legalize_tvec(o : Mtvec, v : xlenbits) -> Mtvec = {
 let v = Mk_Mtvec(v);
 match (trapVectorMode_of_bits(v[Mode])) {
   TV_Direct => v,
   TV_Vector => v,
   _         => [v with Mode = o[Mode]]
 }
}

bitfield Mcause : xlenbits = {
  IsInterrupt : xlen - 1,
  Cause       : xlen - 2 .. 0
}
register mcause : Mcause
mapping clause csr_name_map = 0x342  <-> "mcause"
function clause is_CSR_accessible(0x342, _, _) = true // mcause
function clause read_CSR(0x342) = mcause.bits
function clause write_CSR(0x342, value) = { mcause.bits = value; Ok(mcause.bits) }

// Interpreting the trap-vector address
function tvec_addr(m : Mtvec, c : Mcause) -> option(xlenbits) = {
  let base : xlenbits = m[Base] @ 0b00;
  match (trapVectorMode_of_bits(m[Mode])) {
    TV_Direct => Some(base),
    TV_Vector => if   c[IsInterrupt] == 0b1
                 then Some(base + (zero_extend(c[Cause]) << 2))
                 else Some(base),
    TV_Reserved => None()
  }
}

function clause currentlyEnabled(Ext_Sstvecd) = hartSupports(Ext_Sstvecd) & currentlyEnabled(Ext_S)

// Exception PC

register mepc : xlenbits

// The xepc legalization zeroes xepc[1:0] when Zca is not supported.
// When Zca is supported (whether it is enabled or not), it zeroes only xepc[0].
// PUBLIC: invoked from set_xepc() [exceptions/sys_exceptions.sail]
function legalize_xepc(v : xlenbits) -> xlenbits = {
  if   hartSupports(Ext_Zca)
  then [v with 0 = 0b0]
  else [v with 1..0 = zeros()]
}

// Align value to min supported PC alignment. This is used to
// legalize xepc reads.
function align_pc(addr : xlenbits) -> xlenbits = {
  if currentlyEnabled(Ext_Zca)
  then [addr with 0 = 0b0]
  else [addr with 1..0 = zeros()]
}

// auxiliary exception registers

register mtval    : xlenbits
register mscratch : xlenbits

mapping clause csr_name_map = 0x343  <-> "mtval"
mapping clause csr_name_map = 0x340  <-> "mscratch"

function clause is_CSR_accessible(0x343, _, _) = true // mtval
function clause is_CSR_accessible(0x340, _, _) = true // mscratch

function clause read_CSR(0x343) = mtval
function clause read_CSR(0x340) = mscratch

function clause write_CSR(0x343, value) = { mtval = value; Ok(mtval) }
function clause write_CSR(0x340, value) = { mscratch = value; Ok(mscratch) }

// counters

bitfield Counteren : bits(32) = {
  HPM  : 31 .. 3,
  IR   : 2,
  TM   : 1,
  CY   : 0
}

// scounteren
private function legalize_scounteren(_c : Counteren, v : xlenbits) -> Counteren = {
  let supported_counters = sys_writable_hpm_counters[31 .. 3] @ 0b111;
  Mk_Counteren(v[31 .. 0] & supported_counters)
}

register scounteren : Counteren
mapping clause csr_name_map = 0x106  <-> "scounteren"
function clause is_CSR_accessible(0x106, _, _) = currentlyEnabled(Ext_S) // scounteren
function clause read_CSR(0x106) = zero_extend(scounteren.bits)
function clause write_CSR(0x106, value) = { scounteren = legalize_scounteren(scounteren, value); Ok(zero_extend(scounteren.bits)) }

// mcounteren
function legalize_mcounteren(_c : Counteren, v : xlenbits) -> Counteren = {
  let supported_counters = sys_writable_hpm_counters[31 .. 3] @ 0b111;
  Mk_Counteren(v[31 .. 0] & supported_counters)
}

register mcounteren : Counteren
mapping clause csr_name_map = 0x306  <-> "mcounteren"
function clause is_CSR_accessible(0x306, _, _) = currentlyEnabled(Ext_U) // mcounteren
function clause read_CSR(0x306) = zero_extend(mcounteren.bits)
function clause write_CSR(0x306, value) = { mcounteren = legalize_mcounteren(mcounteren, value); Ok(zero_extend(mcounteren.bits)) }


// mcountinhibit
bitfield Counterin : bits(32) = {
  HPM  : 31 .. 3,
  IR : 2,
  CY : 0
}

private function legalize_mcountinhibit(_c : Counterin, v : xlenbits) -> Counterin = {
  // Note the 0 in 0b101 is because the mtimer counter can't be paused.
  let supported_counters = sys_writable_hpm_counters[31 .. 3] @ 0b101;
  Mk_Counterin(v[31 .. 0] & supported_counters)
}

register mcountinhibit : Counterin
mapping clause csr_name_map = 0x320  <-> "mcountinhibit"
function clause is_CSR_accessible(0x320, _, _) = true // mcountinhibit
function clause read_CSR(0x320) = zero_extend(mcountinhibit.bits)
function clause write_CSR(0x320, value) = { mcountinhibit = legalize_mcountinhibit(mcountinhibit, value); Ok(zero_extend(mcountinhibit.bits)) }

register mcycle : bits(64)
register mtime : bits(64)

// minstret
//
// minstret is an architectural register, and can be written to.  The
// spec says that minstret increments on instruction retires need to
// occur before any explicit writes to instret.  However, in our
// simulation loop, we need to execute an instruction to find out
// whether it retired, and hence can only increment instret after
// execution.  To avoid doing this in the case minstret was explicitly
// written to, we track whether it should increment in a separate
// model-internal register.
register minstret : bits(64)

// Should minstret be incremented when the instruction is retired.
register minstret_increment : bool

// machine information registers
register mvendorid : bits(32) = to_bits_checked(config platform.vendorid : int)
register mimpid    : xlenbits = to_bits_checked(config platform.impid : int)
register marchid   : xlenbits = to_bits_checked(config platform.archid : int)
register mhartid   : xlenbits = to_bits_checked(config platform.hartid : int)

register mconfigptr : xlenbits = zeros()

mapping clause csr_name_map = 0xF11  <-> "mvendorid"
mapping clause csr_name_map = 0xF12  <-> "marchid"
mapping clause csr_name_map = 0xF13  <-> "mimpid"
mapping clause csr_name_map = 0xF14  <-> "mhartid"
mapping clause csr_name_map = 0xF15  <-> "mconfigptr"

function clause is_CSR_accessible(0xf11, _, _) = true // mvendorid
function clause is_CSR_accessible(0xf12, _, _) = true // marchdid
function clause is_CSR_accessible(0xf13, _, _) = true // mimpid
function clause is_CSR_accessible(0xf14, _, _) = true // mhartid
function clause is_CSR_accessible(0xf15, _, _) = true // mconfigptr

function clause read_CSR(0xF11) = zero_extend(mvendorid)
function clause read_CSR(0xF12) = marchid
function clause read_CSR(0xF13) = mimpid
function clause read_CSR(0xF14) = mhartid
function clause read_CSR(0xF15) = mconfigptr

// Additional M-mode registers
register mtinst : xlenbits
register mtval2 : xlenbits

mapping clause csr_name_map = 0x34A  <-> "mtinst"
mapping clause csr_name_map = 0x34B  <-> "mtval2"

function clause is_CSR_accessible(0x34A, _, _) = currentlyEnabled(Ext_H) // mtinst
function clause is_CSR_accessible(0x34B, _, _) = currentlyEnabled(Ext_H) // mtval2

function clause read_CSR(0x34A) = mtinst
function clause read_CSR(0x34B) = mtval2

function clause write_CSR(0x34A, value) = { mtinst = value; Ok(mtinst) }
function clause write_CSR(0x34B, value) = { mtval2 = value; Ok(mtval2) }

// S-mode registers

// sstatus reveals a subset of mstatus
bitfield Sstatus : bits(64) = {
  SD    : xlen - 1,

  UXL   : 33 .. 32,
//  SDT   : 24,
  SPELP : 23,
  MXR   : 19,
  SUM   : 18,
  XS    : 16 .. 15,
  FS    : 14 .. 13,
  VS    : 10 .. 9,
  SPP   : 8,
  SPIE  : 5,
  SIE   : 1,
}
// sstatus is a view of mstatus, so there is no register defined.

private function lower_mstatus(m : Mstatus) -> Sstatus = {
  let s = Mk_Sstatus(zeros());

  [s with
    SD = m[SD],
    UXL = m[UXL],
    //SDT = m[SDT],
    SPELP = m[SPELP],
    MXR = m[MXR],
    SUM = m[SUM],
    XS = m[XS],
    FS = m[FS],
    VS = m[VS],
    SPP = m[SPP],
    SPIE = m[SPIE],
    SIE = m[SIE],
  ]
}

private function legalize_vsstatus(o : Sstatus, v : xlenbits) -> Sstatus = {
  let s = Mk_Sstatus(zero_extend(v));

  let dirty = extStatus_of_bits(s[FS]) == Dirty |
              extStatus_of_bits(s[XS]) == Dirty |
              extStatus_of_bits(s[VS]) == Dirty;
  [o with
    SD   = bool_to_bit(dirty),
    // UXL
    UXL  = s[UXL],
    MXR  = s[MXR],
    SUM  = s[SUM],
    XS   = s[XS],
    FS   = s[FS],
    VS   = s[VS],
    SPP  = s[SPP],
    SPIE = s[SPIE],
    SIE  = s[SIE],
  ]
}

register vsstatus : Sstatus

mapping clause csr_name_map = 0x200  <-> "vsstatus"
function clause is_CSR_accessible(0x200, _, _) = currentlyEnabled(Ext_H) // vsstatus
function clause read_CSR(0x200) = vsstatus.bits[xlen - 1 .. 0]
function clause write_CSR(0x200, value) = { vsstatus = legalize_vsstatus(vsstatus, value); Ok(vsstatus.bits[xlen - 1 .. 0]) }

private function lift_sstatus(m : Mstatus, s : Sstatus) -> Mstatus = {
  let dirty = extStatus_of_bits(s[FS]) == Dirty | extStatus_of_bits(s[XS]) == Dirty |
              extStatus_of_bits(s[VS]) == Dirty;

  [m with
    SD = bool_to_bit(dirty),
    UXL = s[UXL],
    //SDT = s[SDT],
    SPELP = s[SPELP],
    MXR = s[MXR],
    SUM = s[SUM],
    XS = s[XS],
    FS = s[FS],
    VS = s[VS],
    SPP = s[SPP],
    SPIE = s[SPIE],
    SIE = s[SIE],
  ]
}

private function legalize_sstatus(m : Mstatus, v : xlenbits) -> Mstatus = {
  legalize_mstatus(m, lift_sstatus(m, Mk_Sstatus(zero_extend(v))).bits)
}

mapping clause csr_name_map = 0x100  <-> "sstatus"
function clause is_CSR_accessible(0x100, _, _) = currentlyEnabled(Ext_S) // sstatus

function clause read_CSR(0x100) = if privLevel_is_virtual(cur_privilege) then vsstatus.bits[xlen - 1 .. 0] else lower_mstatus(mstatus).bits[xlen - 1 .. 0]
function clause write_CSR(0x100, value) =
  if privLevel_is_virtual(cur_privilege)
  then { vsstatus = legalize_vsstatus(vsstatus, zero_extend(value)); Ok(vsstatus.bits[xlen - 1 .. 0]) }
  else { mstatus  = legalize_sstatus(mstatus, value); Ok(lower_mstatus(mstatus).bits[xlen - 1 .. 0]) }

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

// ! Returns vsie view of mie (m) as delegated by hideleg (d)
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

// Returns new mie from previous mie (m) and the written vsie (v) as delegated by hideleg (d)
function legalize_vsie(m : Minterrupts, d : Minterrupts, v : xlenbits) -> Minterrupts = {
  let v = Mk_Minterrupts(v);
  [m with
    VSEI = v[SEI] & d[VSEI],
    VSTI = v[STI] & d[VSTI],
    VSSI = v[SSI] & d[VSSI],
  ]
}

function legalize_vsip(m: Minterrupts, d : Minterrupts, v : xlenbits) -> Minterrupts = {
  let v = Mk_Minterrupts(v);
  [m with VSSI = v[SSI] & d[VSSI]]
}

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

private function legalize_sip(m : Minterrupts, d : Minterrupts, v : xlenbits) -> Minterrupts = {
  lift_sip(m, d, Mk_Sinterrupts(v))
}

mapping clause csr_name_map = 0x144  <-> "sip"
function clause is_CSR_accessible(0x144, _, _) = currentlyEnabled(Ext_S) // sip
function clause read_CSR(0x144) =
if privLevel_is_virtual(cur_privilege)
  then lower_mip_to_vsip(mip, hideleg).bits
  else lower_mip(mip, mideleg).bits
function clause write_CSR(0x144, value) =
  if privLevel_is_virtual(cur_privilege)
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

mapping clause csr_name_map = 0x104  <-> "sie"
function clause is_CSR_accessible(0x104, _, _) = currentlyEnabled(Ext_S) // sie
function clause read_CSR(0x104) =
  if privLevel_is_virtual(cur_privilege)
  then lower_mie_to_vsie(mie, hideleg).bits
  else lower_mie(mie, mideleg).bits
function clause write_CSR(0x104, value) =
  if privLevel_is_virtual(cur_privilege)
  then { mie = legalize_vsie(mie, hideleg, value); Ok(lower_mie_to_vsie(mie, hideleg).bits) }
  else { mie = legalize_sie(mie, mideleg, value); Ok(lower_mie(mie, mideleg).bits) }


register vsscratch : xlenbits
register vscause   : Mcause
register vstval    : xlenbits

mapping clause csr_name_map = 0x240  <-> "vsscratch"
mapping clause csr_name_map = 0x242  <-> "vscause"
mapping clause csr_name_map = 0x243  <-> "vstval"

function clause is_CSR_accessible(0x240, _, _) = currentlyEnabled(Ext_H) // vsscratch
function clause is_CSR_accessible(0x242, _, _) = currentlyEnabled(Ext_H) // vscause
function clause is_CSR_accessible(0x243, _, _) = currentlyEnabled(Ext_H) // vstval

function clause read_CSR(0x240) = vsscratch
function clause read_CSR(0x242) = vscause.bits
function clause read_CSR(0x243) = vstval

function clause write_CSR(0x240, value) = { vsscratch = value; Ok(vsscratch) }
function clause write_CSR(0x242, value) = { vscause.bits = value; Ok(vscause.bits) }
function clause write_CSR(0x243, value) = { vstval = value; Ok(vstval) }

// other non-VM related supervisor state
register stvec    : Mtvec
register sscratch : xlenbits
register sepc     : xlenbits
register scause   : Mcause
register stval    : xlenbits

mapping clause csr_name_map = 0x140  <-> "sscratch"
mapping clause csr_name_map = 0x142  <-> "scause"
mapping clause csr_name_map = 0x143  <-> "stval"

function clause is_CSR_accessible(0x140, _, _) = currentlyEnabled(Ext_S) // sscratch
function clause is_CSR_accessible(0x142, _, _) = currentlyEnabled(Ext_S) // scause
function clause is_CSR_accessible(0x143, _, _) = currentlyEnabled(Ext_S) // stval

function clause read_CSR(0x140) = if privLevel_is_virtual(cur_privilege) then vsscratch else sscratch
function clause read_CSR(0x142) = if privLevel_is_virtual(cur_privilege) then vscause.bits else scause.bits
function clause read_CSR(0x143) = if privLevel_is_virtual(cur_privilege) then vstval else stval

function clause write_CSR(0x140, value) = if privLevel_is_virtual(cur_privilege) then { vsscratch = value; Ok(vsscratch) } else { sscratch = value; Ok(sscratch) }
function clause write_CSR(0x142, value) = if privLevel_is_virtual(cur_privilege) then { vscause.bits = value; Ok(vscause.bits) } else { scause.bits = value; Ok(scause.bits) }
function clause write_CSR(0x143, value) = if privLevel_is_virtual(cur_privilege) then { vstval = value; Ok(vstval) } else { stval = value; Ok(stval) }

//
// S-mode address translation and protection (satp) layout.
// The actual satp register is defined in an architecture-specific file.

bitfield Satp64 : bits(64) = {
  Mode : 63 .. 60,
  Asid : 59 .. 44,
  PPN  : 43 .. 0
}

bitfield Satp32 : bits(32) = {
  Mode : 31,
  Asid : 30 .. 22,
  PPN  : 21 .. 0
}

// TODO: This currently assumes all ASID bits are implemented
// and does not legalize the asid field if asidlen is not the maximum.
function legalize_satp(
  arch : Architecture,
  prev_value : xlenbits,
  written_value : xlenbits,
) -> xlenbits = {
  if xlen == 32 then {
    let s = Mk_Satp32(written_value);
    match satpMode_of_bits(arch, 0b000 @ s[Mode]) {
      None()  => prev_value,
      Some(Sv_mode) => match Sv_mode {
        Bare if currentlyEnabled(Ext_Svbare) => s.bits,
        Sv32 if currentlyEnabled(Ext_Sv32) => s.bits,
        _ => prev_value,
      }
    }
  } else if xlen == 64 then {
    let s = Mk_Satp64(written_value);
    match satpMode_of_bits(arch, s[Mode]) {
      None()  => prev_value,
      Some(Sv_mode) =>  match Sv_mode {
        Bare if currentlyEnabled(Ext_Svbare) => s.bits,
        Sv39 if currentlyEnabled(Ext_Sv39) => s.bits,
        Sv48 if currentlyEnabled(Ext_Sv48) => s.bits,
        Sv57 if currentlyEnabled(Ext_Sv57) => s.bits,
        _ => prev_value,
      }
    }
  } else {
    internal_error(__FILE__, __LINE__, "Unsupported xlen" ^ dec_str(xlen))
  }
}

// disabled trigger/debug module
register tselect : xlenbits

mapping clause csr_name_map = 0x7a0  <-> "tselect"
mapping clause csr_name_map = 0x7a1  <-> "tdata1"
mapping clause csr_name_map = 0x7a2  <-> "tdata2"
mapping clause csr_name_map = 0x7a3  <-> "tdata3"

function clause is_CSR_accessible(0x7a0, _, _) = true
function clause read_CSR(0x7a0) = ~(tselect)  // this indicates we don't have any trigger support
function clause write_CSR(0x7a0, value) = { tselect = value; Ok(tselect) }

//
// Entropy Source - Platform access to random bits.
// NOTE: This would be better placed in platform.sail, but that file
// appears _after_ this one in the compile order meaning the valspec
// for this function is unavailable when it's first encountered in
// read_seed_csr. Hence it appears here.
val get_16_random_bits = impure {
    interpreter: "Platform.get_16_random_bits",
    cpp: "plat_get_16_random_bits",
    lem: "plat_get_16_random_bits"
} : unit -> bits(16)


// There are several features that are controlled by machine/supervisor enable
// bits (m/senvcfg, m/scounteren, etc.). This abstracts that logic.
function feature_enabled_for_priv(p : Privilege, machine_enable_bit : bits(1), supervisor_enable_bit : bits(1)) -> bool = match p {
  Machine => true,
  Supervisor => machine_enable_bit == 0b1,
  User => machine_enable_bit == 0b1 & (not(currentlyEnabled(Ext_S)) | supervisor_enable_bit == 0b1),
  VirtualSupervisor => internal_error(__FILE__, __LINE__, "Hypervisor extension not supported"),
  VirtualUser => internal_error(__FILE__, __LINE__, "Hypervisor extension not supported"),
}

// Return true if the counter is enabled.
function counter_enabled(index: range(0, 31), priv : Privilege) -> bool =
  feature_enabled_for_priv(priv, mcounteren.bits[index], scounteren.bits[index])

// Return the effective architecture for the given privilege mode
function architecture(priv : Privilege) -> Architecture = {
  if   xlen == 32
  then return RV32;

  architecture_bits(match priv {
    Machine           => misa[MXL],
    Supervisor        => mstatus[SXL],
    User              => mstatus[UXL],
    VirtualSupervisor => hstatus[VSXL],
    VirtualUser       => vsstatus[UXL],
  })
}

function in32BitMode() -> bool = {
  architecture(cur_privilege) == RV32
}
