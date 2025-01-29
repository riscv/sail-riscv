/*=======================================================================================*/
/*  This Sail RISC-V architecture model, comprising all files and                        */
/*  directories except where otherwise noted is subject the BSD                          */
/*  two-clause license in the LICENSE file.                                              */
/*                                                                                       */
/*  SPDX-License-Identifier: BSD-2-Clause                                                */
/*=======================================================================================*/

/* Machine-mode and supervisor-mode state definitions. */

/* privilege level */

register cur_privilege : Privilege

/* current instruction bits, used for illegal instruction exceptions */

register cur_inst : xlenbits

/* State projections
 *
 * Some machine state is processed via projections from machine-mode views to
 * views from lower privilege levels.  So, for e.g. when mstatus is read from
 * lower privilege levels, we use 'lowering_' projections:
 *
 *   mstatus  ->  sstatus  ->  ustatus
 *
 * Similarly, when machine state is written from lower privileges, that state is
 * lifted into the appropriate value for the machine-mode state.
 *
 *   ustatus  ->  sstatus  ->  mstatus
 *
 * In addition, several fields in machine state registers are WARL or WLRL,
 * requiring that values written to the registers be legalized.  For each such
 * register, there will be an associated 'legalize_' function.  These functions
 * will need to be supplied externally, and will depend on the legal values
 * supported by a platform/implementation (or misa).  The legalize_ functions
 * generate a legal value from the current value and the written value.  In more
 * complex cases, they will also implicitly read the current values of misa,
 * mstatus, etc.
 *
 * Each register definition below is followed by custom projections
 * and choice of legalizations if needed.  For now, we typically
 * implement the simplest legalize_ alternatives.
 */


/* M-mode registers */

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
register misa : Misa

/* whether misa is R/W */
val sys_enable_writable_misa = pure "sys_enable_writable_misa" : unit -> bool
/* whether misa.c was enabled at boot */
val sys_enable_rvc = pure "sys_enable_rvc" : unit -> bool
/* whether misa.{f,d} were enabled at boot */
val sys_enable_fdext = pure "sys_enable_fdext" : unit -> bool
/* whether Svinval was enabled at boot */
val sys_enable_svinval = pure "sys_enable_svinval" : unit -> bool
/* whether Zcb was enabled at boot */
val sys_enable_zcb = pure "sys_enable_zcb" : unit -> bool
/* whether zfinx was enabled at boot */
val sys_enable_zfinx = pure "sys_enable_zfinx" : unit -> bool
/* Whether FIOM bit of menvcfg/senvcfg is enabled. It must be enabled if
   supervisor mode is implemented and non-bare addressing modes are supported. */
val sys_enable_writable_fiom = pure "sys_enable_writable_fiom" : unit -> bool

/* How many PMP entries are implemented. This must be 0, 16 or 64 (this is checked at runtime). */
val sys_pmp_count = pure "sys_pmp_count" : unit -> range(0, 64)
/* G parameter that specifies the PMP grain size. The grain size is 2^(G+2), e.g.
   G=0 -> 4 bytes, G=10 -> 4096 bytes. */
val sys_pmp_grain = pure "sys_pmp_grain" : unit -> range(0, 63)

/* Which HPM counters are supported (as a bit mask). Bits [2 .. 0] are ignored. */
val sys_writable_hpm_counters = pure "sys_writable_hpm_counters" : unit -> bits(32)

/* whether misa.v was enabled at boot */
val sys_enable_vext = pure "sys_enable_vext" : unit -> bool

/* whether misa.b was enabled at boot */
val sys_enable_bext = pure "sys_enable_bext" : unit -> bool

// CBO extensions. Zicbop cannot be enabled/disabled because it has no effect
// at all on this model.
val sys_enable_zicbom = pure "sys_enable_zicbom" : unit -> bool
val sys_enable_zicboz = pure "sys_enable_zicboz" : unit -> bool

// Is the Sstc stimecmp extension supported.
val sys_enable_sstc = pure "sys_enable_sstc" : unit -> bool

// Supervisor timecmp
function clause extensionEnabled(Ext_Sstc) = sys_enable_sstc()

/* This function allows an extension to veto a write to Misa
   if it would violate an alignment restriction on
   unsetting C. If it returns true the write will have no effect. */
val ext_veto_disable_C : unit -> bool

function legalize_misa(m : Misa, v : xlenbits) -> Misa = {
  let  v = Mk_Misa(v);
  /* Suppress updates to MISA if MISA is not writable or if by disabling C next PC would become misaligned or an extension vetoes */
  if   not(sys_enable_writable_misa()) | (v[C] == 0b0 & (nextPC[1] == bitone | ext_veto_disable_C()))
  then m
  else {
    /* Suppress enabling C if C was disabled at boot (i.e. not supported) */
    let m = if not(sys_enable_rvc()) then m else [m with C = v[C]];
    /* Suppress updates to misa.{f,d} if disabled at boot */
    if   not(sys_enable_fdext())
    then m
    else [m with F = v[F], D = v[D] & v[F]]
  }
}

mapping clause csr_name_map = 0x301  <-> "misa"
function clause is_CSR_defined(0x301) = true // misa
function clause read_CSR(0x301) = misa.bits
function clause write_CSR(0x301, value) = { misa = legalize_misa(misa, value); misa.bits }

function clause extensionEnabled(Ext_U) = misa[U] == 0b1

function clause extensionEnabled(Ext_S) = misa[S] == 0b1

/*
 * Illegal values legalized to least privileged mode supported.
 * Note: the only valid combinations of supported modes are M, M+U, M+S+U.
 */
function lowest_supported_privLevel() -> Privilege =
  if extensionEnabled(Ext_U) then User else Machine

function have_privLevel(priv : priv_level) -> bool =
  match priv {
    0b00 => extensionEnabled(Ext_U),
    0b01 => extensionEnabled(Ext_S),
    0b10 => false,
    0b11 => true,
  }

bitfield Mstatus : bits(64) = {
  SD_64: 63,

  //MDT  : 42,
  //MPELP: 41,

  //MPV  : 39,
  //GVA  : 38,

  MBE  : 37,
  SBE  : 36,

  SXL  : 35 .. 34,
  UXL  : 33 .. 32,

  SD_32: 31,

  //SDT  : 24,
  //SPELP: 23,
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
register mstatus : Mstatus

function effectivePrivilege(t : AccessType(ext_access_type), m : Mstatus, priv : Privilege) -> Privilege =
  if   t != Execute() & m[MPRV] == 0b1
  then privLevel_of_bits(m[MPP])
  else priv

function get_mstatus_SXL(m : Mstatus) -> arch_xlen = {
  if   xlen == 32
  then architecture(RV32)
  else m[SXL]
}

function get_mstatus_UXL(m : Mstatus) -> arch_xlen = {
  if   xlen == 32
  then architecture(RV32)
  else m[UXL]
}

function get_mstatus_SD(m : Mstatus) -> bits(1) = {
  if   xlen == 32 then m[SD_32]
  else m[SD_64]
}

function set_mstatus_SD(m : Mstatus, v : bits(1)) -> Mstatus = {
  if   xlen == 32
  then [m with SD_32 = v]
  else [m with SD_64 = v]
}

function legalize_mstatus(o : Mstatus, v : bits(64)) -> Mstatus = {
  /*
   * Populate all defined fields using the bits of v, stripping anything
   * that does not have a matching bitfield entry. The SD bits are handled
   * explicitly later depending on xlen.
   */
  let v = Mk_Mstatus(v);

  let o = [o with
    // MDT = v[MDT],
    // MPELP = v[MPELP],
    // MPV = v[MPV],
    // GVA = v[GVA],
    /* We don't currently support changing MBE and SBE. */
    // MBE = v[MBE],
    // SBE = v[SBE],
    /* We don't support dynamic changes to SXL and UXL. */
    // SXL = if xlen == 64 then v[SXL] else o[SXL],
    // UXL = if xlen == 64 then v[UXL] else o[UXL],
    // SDT = v[SDT],
    // SPELP = v[SPELP],
    TSR = v[TSR],
    TW = v[TW],
    TVM = v[TVM],
    MXR = v[MXR],
    SUM = v[SUM],
    MPRV = if extensionEnabled(Ext_U) then v[MPRV] else 0b0,
    /* We don't have any extension context yet. */
    XS = extStatus_to_bits(Off),
  /* FS is WARL, and making FS writable can support the M-mode emulation of an FPU
   * to support code running in S/U-modes.  Spike does this, and for now, we match it,
   * but only if Zfinx isn't enabled.
   * FIXME: This should be made a platform parameter.
   */
    FS = if sys_enable_zfinx() then extStatus_to_bits(Off) else v[FS],
    MPP = if have_privLevel(v[MPP]) then v[MPP] else privLevel_to_bits(lowest_supported_privLevel()),
    VS = v[VS],
    SPP = v[SPP],
    MPIE = v[MPIE],
    SPIE = v[SPIE],
    MIE = v[MIE],
    SIE = v[SIE],
  ];

  // Set dirty bit to OR of other status bits.
  let dirty = extStatus_of_bits(o[FS]) == Dirty |
              extStatus_of_bits(o[XS]) == Dirty |
              extStatus_of_bits(o[VS]) == Dirty;

  [o with
    SD_64 = if xlen == 64 then bool_to_bits(dirty) else o[SD_64],
    SD_32 = if xlen == 32 then bool_to_bits(dirty) else o[SD_32],
  ]
}

mapping clause csr_name_map = 0x300  <-> "mstatus"

function clause is_CSR_defined(0x300) = true // mstatus
function clause is_CSR_defined(0x310) = xlen == 32 // mstatush

function clause read_CSR(0x300) = mstatus.bits[xlen - 1 .. 0]
function clause read_CSR(0x310 if xlen == 32) = mstatus.bits[63 .. 32]

function clause write_CSR((0x300, value) if xlen == 64) = { mstatus = legalize_mstatus(mstatus, value); mstatus.bits }
function clause write_CSR((0x300, value) if xlen == 32) = { mstatus = legalize_mstatus(mstatus, mstatus.bits[63 .. 32] @ value); mstatus.bits[31 .. 0] }
function clause write_CSR((0x310, value) if xlen == 32) = { mstatus = legalize_mstatus(mstatus, value @ mstatus.bits[31 .. 0]); mstatus.bits[63 .. 32] }

/* architecture and extension checks */

function cur_architecture() -> Architecture = {
  let a : arch_xlen =
    match cur_privilege {
      Machine    => misa[MXL],
      Supervisor => get_mstatus_SXL(mstatus),
      User       => get_mstatus_UXL(mstatus)
    };
  architecture(a)
}

function in32BitMode() -> bool = {
  cur_architecture() == RV32
}

// envcfg Resisters
bitfield MEnvcfg : bits(64) = {
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

bitfield SEnvcfg : xlenbits = {
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

function legalize_menvcfg(o : MEnvcfg, v : bits(64)) -> MEnvcfg = {
  let v = Mk_MEnvcfg(v);
  [o with
    FIOM = if sys_enable_writable_fiom() then v[FIOM] else 0b0,
    CBZE = if extensionEnabled(Ext_Zicboz) then v[CBZE] else 0b0,
    CBCFE = if extensionEnabled(Ext_Zicbom) then v[CBCFE] else 0b0,
    CBIE = if extensionEnabled(Ext_Zicbom) then (if v[CBIE] != 0b10 then v[CBIE] else 0b00) else 0b00,
    STCE = if extensionEnabled(Ext_Sstc) then v[STCE] else 0b0,
    // Other extensions are not implemented yet so all other fields are read only zero.
  ]
}

function legalize_senvcfg(o : SEnvcfg, v : xlenbits) -> SEnvcfg = {
  let v = Mk_SEnvcfg(v);
  [o with
    FIOM = if sys_enable_writable_fiom() then v[FIOM] else 0b0,
    CBZE = if extensionEnabled(Ext_Zicboz) then v[CBZE] else 0b0,
    CBCFE = if extensionEnabled(Ext_Zicbom) then v[CBCFE] else 0b0,
    CBIE = if extensionEnabled(Ext_Zicbom) then (if v[CBIE] != 0b10 then v[CBIE] else 0b00) else 0b00,
    // Other extensions are not implemented yet so all other fields are read only zero.
  ]
}

// Initialised to legal values in case some bits are hard-coded to 1.
register menvcfg : MEnvcfg = legalize_menvcfg(Mk_MEnvcfg(zeros()), zeros())
register senvcfg : SEnvcfg = legalize_senvcfg(Mk_SEnvcfg(zeros()), zeros())

mapping clause csr_name_map = 0x30A  <-> "menvcfg"
mapping clause csr_name_map = 0x31A  <-> "menvcfgh"
mapping clause csr_name_map = 0x10A  <-> "senvcfg"

function clause is_CSR_defined(0x30A) = extensionEnabled(Ext_U) // menvcfg
function clause is_CSR_defined(0x31A) = extensionEnabled(Ext_U) & (xlen == 32) // menvcfgh
function clause is_CSR_defined(0x10A) = extensionEnabled(Ext_S) // senvcfg

function clause read_CSR(0x30A) = menvcfg.bits[xlen - 1 .. 0]
function clause read_CSR(0x31A if xlen == 32) = menvcfg.bits[63 .. 32]
function clause read_CSR(0x10A) = senvcfg.bits[xlen - 1 .. 0]

function clause write_CSR((0x30A, value) if xlen == 32) = { menvcfg = legalize_menvcfg(menvcfg, menvcfg.bits[63 .. 32] @ value); menvcfg.bits[31 .. 0] }
function clause write_CSR((0x30A, value) if xlen == 64) = { menvcfg = legalize_menvcfg(menvcfg, value); menvcfg.bits }
function clause write_CSR((0x31A, value) if xlen == 32) = { menvcfg = legalize_menvcfg(menvcfg, value @ menvcfg.bits[31 .. 0]); menvcfg.bits[63 .. 32] }
function clause write_CSR(0x10A, value) = { senvcfg = legalize_senvcfg(senvcfg, zero_extend(value)); senvcfg.bits[xlen - 1 .. 0] }

// Return whether or not FIOM is currently active, based on the current
// privilege and the menvcfg/senvcfg settings. This means that I/O fences
// imply memory fence.
function is_fiom_active() -> bool = {
  match cur_privilege {
    Machine => false,
    Supervisor => menvcfg[FIOM] == 0b1,
    User => (menvcfg[FIOM] | senvcfg[FIOM]) == 0b1,
  }
}

/* interrupt processing state */

bitfield Minterrupts : xlenbits = {
  MEI : 11, /* external interrupts */
  SEI : 9,

  MTI : 7,  /* timers interrupts */
  STI : 5,

  MSI : 3,  /* software interrupts */
  SSI : 1,
}

function legalize_mip(o : Minterrupts, v : xlenbits) -> Minterrupts = {
  /* The only writable bits are the S-mode bits, and with the 'N'
   * extension, the U-mode bits. */
  let v = Mk_Minterrupts(v);
  [o with
    SEI = if extensionEnabled(Ext_S) then v[SEI] else 0b0,
    SSI = if extensionEnabled(Ext_S) then v[SSI] else 0b0,
    STI = if extensionEnabled(Ext_S) then (
      // STI is read only if Sstc is enabled and STCE is set (it is equal to stimecmp <= mtime).
      if extensionEnabled(Ext_Sstc) & menvcfg[STCE] == 0b1 then o[STI] else v[STI]
    ) else 0b0,
  ]
}

function legalize_mie(o : Minterrupts, v : xlenbits) -> Minterrupts = {
  let v = Mk_Minterrupts(v);
  [o with
    MEI = v[MEI],
    MTI = v[MTI],
    MSI = v[MSI],
    SEI = if extensionEnabled(Ext_S) then v[SEI] else 0b0,
    STI = if extensionEnabled(Ext_S) then v[STI] else 0b0,
    SSI = if extensionEnabled(Ext_S) then v[SSI] else 0b0,
  ]
}

function legalize_mideleg(o : Minterrupts, v : xlenbits) -> Minterrupts = {
  /* M-mode interrupt delegation bits "should" be hardwired to 0. */
  /* FIXME: needs verification against eventual spec language. */
  [Mk_Minterrupts(v) with MEI = 0b0, MTI = 0b0, MSI = 0b0]
}

/* exception processing state */

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

function legalize_medeleg(o : Medeleg, v : bits(64)) -> Medeleg = {
  /* M-EnvCalls delegation is not supported */
  [Mk_Medeleg(v) with MEnvCall = 0b0]
}

register mie     : Minterrupts /* Enabled */
register mip     : Minterrupts /* Pending */
register medeleg : Medeleg     /* Exception delegation to S-mode */
register mideleg : Minterrupts /* Interrupt delegation to S-mode */

mapping clause csr_name_map = 0x304  <-> "mie"
mapping clause csr_name_map = 0x344  <-> "mip"
mapping clause csr_name_map = 0x302  <-> "medeleg"
mapping clause csr_name_map = 0x312  <-> "medelegh"
mapping clause csr_name_map = 0x303  <-> "mideleg"

function clause is_CSR_defined(0x304) = true // mie
function clause is_CSR_defined(0x344) = true // mip
function clause is_CSR_defined(0x302) = extensionEnabled(Ext_S) // medeleg
function clause is_CSR_defined(0x312) = extensionEnabled(Ext_S) & xlen == 32 // medelegh
function clause is_CSR_defined(0x303) = extensionEnabled(Ext_S) // mideleg

function clause read_CSR(0x304) = mie.bits
function clause read_CSR(0x344) = mip.bits
function clause read_CSR(0x302) = medeleg.bits[xlen - 1 .. 0]
function clause read_CSR(0x312 if xlen == 32) = medeleg.bits[63 .. 32]
function clause read_CSR(0x303) = mideleg.bits

function clause write_CSR(0x304, value) = { mie = legalize_mie(mie, value); mie.bits }
function clause write_CSR(0x344, value) = { mip = legalize_mip(mip, value); mip.bits }
function clause write_CSR((0x302, value) if xlen == 64) = { medeleg = legalize_medeleg(medeleg, value); medeleg.bits }
function clause write_CSR((0x302, value) if xlen == 32) = { medeleg = legalize_medeleg(medeleg, medeleg.bits[63 .. 32] @ value); medeleg.bits[31 .. 0] }
function clause write_CSR((0x312, value) if xlen == 32) = { medeleg = legalize_medeleg(medeleg, value @ medeleg.bits[31 .. 0]); medeleg.bits[63 .. 32] }
function clause write_CSR(0x303, value) = { mideleg = legalize_mideleg(mideleg, value); mideleg.bits }

/* registers for trap handling */

bitfield Mtvec : xlenbits = {
  Base : xlen - 1 .. 2,
  Mode : 1 .. 0
}
register mtvec : Mtvec  /* Trap Vector */

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
function clause is_CSR_defined(0x342) = true // mcause
function clause read_CSR(0x342) = mcause.bits
function clause write_CSR(0x342, value) = { mcause.bits = value; mcause.bits }

/* Interpreting the trap-vector address */
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

/* Exception PC */

register mepc : xlenbits

/* The xepc legalization zeroes xepc[1:0] when misa.C is hardwired to 0.
 * When misa.C is writable, it zeroes only xepc[0].
 */
function legalize_xepc(v : xlenbits) -> xlenbits = {
  // allow writing xepc[1] only if misa.C is enabled or could be enabled.
  if   sys_enable_rvc()
  then [v with 0 = bitzero]
  else [v with 1..0 = zeros()]
}

// Align value to min supported PC alignment. This is used to
// legalize xepc reads.
function align_pc(addr : xlenbits) -> xlenbits = {
  if misa[C] == 0b1
  then [addr with 0 = bitzero]
  else [addr with 1..0 = zeros()]
}

/* auxiliary exception registers */

register mtval    : xlenbits
register mscratch : xlenbits

mapping clause csr_name_map = 0x343  <-> "mtval"
mapping clause csr_name_map = 0x340  <-> "mscratch"

function clause is_CSR_defined(0x343) = true // mtval
function clause is_CSR_defined(0x340) = true // mscratch

function clause read_CSR(0x343) = mtval
function clause read_CSR(0x340) = mscratch

function clause write_CSR(0x343, value) = { mtval = value; mtval }
function clause write_CSR(0x340, value) = { mscratch = value; mscratch }

/* counters */

bitfield Counteren : bits(32) = {
  HPM  : 31 .. 3,
  IR   : 2,
  TM   : 1,
  CY   : 0
}

// scounteren
function legalize_scounteren(c : Counteren, v : xlenbits) -> Counteren = {
  let supported_counters = sys_writable_hpm_counters()[31 .. 3] @ 0b111;
  Mk_Counteren(v[31 .. 0] & supported_counters)
}

register scounteren : Counteren
mapping clause csr_name_map = 0x106  <-> "scounteren"
function clause is_CSR_defined(0x106) = extensionEnabled(Ext_S) // scounteren
function clause read_CSR(0x106) = zero_extend(scounteren.bits)
function clause write_CSR(0x106, value) = { scounteren = legalize_scounteren(scounteren, value); zero_extend(scounteren.bits) }

// mcounteren
function legalize_mcounteren(c : Counteren, v : xlenbits) -> Counteren = {
  let supported_counters = sys_writable_hpm_counters()[31 .. 3] @ 0b111;
  Mk_Counteren(v[31 .. 0] & supported_counters)
}

register mcounteren : Counteren
mapping clause csr_name_map = 0x306  <-> "mcounteren"
function clause is_CSR_defined(0x306) = extensionEnabled(Ext_U) // mcounteren
function clause read_CSR(0x306) = zero_extend(mcounteren.bits)
function clause write_CSR(0x306, value) = { mcounteren = legalize_mcounteren(mcounteren, value); zero_extend(mcounteren.bits) }


// mcountinhibit
bitfield Counterin : bits(32) = {
  HPM  : 31 .. 3,
  IR : 2,
  CY : 0
}

function legalize_mcountinhibit(c : Counterin, v : xlenbits) -> Counterin = {
  // Note the 0 in 0b101 is because the mtimer counter can't be paused.
  let supported_counters = sys_writable_hpm_counters()[31 .. 3] @ 0b101;
  Mk_Counterin(v[31 .. 0] & supported_counters)
}

register mcountinhibit : Counterin
mapping clause csr_name_map = 0x320  <-> "mcountinhibit"
function clause is_CSR_defined(0x320) = true // mcountinhibit
function clause read_CSR(0x320) = zero_extend(mcountinhibit.bits)
function clause write_CSR(0x320, value) = { mcountinhibit = legalize_mcountinhibit(mcountinhibit, value); zero_extend(mcountinhibit.bits) }

register mcycle : bits(64)
register mtime : bits(64)

/* minstret
 *
 * minstret is an architectural register, and can be written to.  The
 * spec says that minstret increments on instruction retires need to
 * occur before any explicit writes to instret.  However, in our
 * simulation loop, we need to execute an instruction to find out
 * whether it retired, and hence can only increment instret after
 * execution.  To avoid doing this in the case minstret was explicitly
 * written to, we track whether it should increment in a separate
 * model-internal register.
 */
register minstret : bits(64)

/* Should minstret be incremented when the instruction is retired. */
register minstret_increment : bool

function retire_instruction() -> unit = {
  if minstret_increment then minstret = minstret + 1;
}

/* machine information registers */
register mvendorid : bits(32)
register mimpid : xlenbits
register marchid : xlenbits
/* TODO: this should be readonly, and always 0 for now */
register mhartid : xlenbits
register mconfigptr : xlenbits

mapping clause csr_name_map = 0xF11  <-> "mvendorid"
mapping clause csr_name_map = 0xF12  <-> "marchid"
mapping clause csr_name_map = 0xF13  <-> "mimpid"
mapping clause csr_name_map = 0xF14  <-> "mhartid"
mapping clause csr_name_map = 0xF15  <-> "mconfigptr"

function clause is_CSR_defined(0xf11) = true // mvendorid
function clause is_CSR_defined(0xf12) = true // marchdid
function clause is_CSR_defined(0xf13) = true // mimpid
function clause is_CSR_defined(0xf14) = true // mhartid
function clause is_CSR_defined(0xf15) = true // mconfigptr

function clause read_CSR(0xF11) = zero_extend(mvendorid)
function clause read_CSR(0xF12) = marchid
function clause read_CSR(0xF13) = mimpid
function clause read_CSR(0xF14) = mhartid
function clause read_CSR(0xF15) = mconfigptr

/* S-mode registers */

/* sstatus reveals a subset of mstatus */
bitfield Sstatus : bits(64) = {
  SD_64 : 63,

  UXL   : 33 .. 32,
  SD_32 : 31,
//  SDT   : 24,
//  SPELP : 23,
  MXR   : 19,
  SUM   : 18,
  XS    : 16 .. 15,
  FS    : 14 .. 13,
  VS    : 10 .. 9,
  SPP   : 8,
  SPIE  : 5,
  SIE   : 1,
}
/* sstatus is a view of mstatus, so there is no register defined. */

function lower_mstatus(m : Mstatus) -> Sstatus = {
  let s = Mk_Sstatus(zeros());

  [s with
    SD_64 = m[SD_64],
    UXL = m[UXL],
    SD_32 = m[SD_32],
    //SDT = m[SDT],
    //SPELP = m[SPELP],
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

function lift_sstatus(m : Mstatus, s : Sstatus) -> Mstatus = {
  let dirty = extStatus_of_bits(s[FS]) == Dirty | extStatus_of_bits(s[XS]) == Dirty |
              extStatus_of_bits(s[VS]) == Dirty;

  [m with
    SD_64 = if xlen == 64 then bool_to_bits(dirty) else m[SD_64],
    SD_32 = if xlen == 32 then bool_to_bits(dirty) else m[SD_32],
    UXL = s[UXL],
    //SDT = s[SDT],
    //SPELP = s[SPELP],
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

function legalize_sstatus(m : Mstatus, v : xlenbits) -> Mstatus = {
  legalize_mstatus(m, lift_sstatus(m, Mk_Sstatus(zero_extend(v))).bits)
}

mapping clause csr_name_map = 0x100  <-> "sstatus"
function clause is_CSR_defined(0x100) = extensionEnabled(Ext_S) // sstatus
function clause read_CSR(0x100) = lower_mstatus(mstatus).bits[xlen - 1 .. 0]
function clause write_CSR(0x100, value) = { mstatus = legalize_sstatus(mstatus, value); mstatus.bits[xlen - 1 .. 0] }


bitfield Sinterrupts : xlenbits = {
  SEI : 9,  /* external interrupts */

  STI : 5,  /* timers interrupts */

  SSI : 1,  /* software interrupts */
}

// sip
/* Provides the sip read view of mip (m) as delegated by mideleg (d). */
function lower_mip(m : Minterrupts, d : Minterrupts) -> Sinterrupts = {
  let s : Sinterrupts = Mk_Sinterrupts(zeros());

  [s with
    SEI = m[SEI] & d[SEI],
    STI = m[STI] & d[STI],
    SSI = m[SSI] & d[SSI],
  ]
}

/* Provides the sie read view of mie (m) as delegated by mideleg (d). */
function lower_mie(m : Minterrupts, d : Minterrupts) -> Sinterrupts = {
  let s : Sinterrupts = Mk_Sinterrupts(zeros());

  [s with
    SEI = m[SEI] & d[SEI],
    STI = m[STI] & d[STI],
    SSI = m[SSI] & d[SSI],
  ]
}

/* Returns the new value of mip from the previous mip (o) and the written sip (s) as delegated by mideleg (d). */
function lift_sip(o : Minterrupts, d : Minterrupts, s : Sinterrupts) -> Minterrupts = {
  let m : Minterrupts = o;
  let m = if d[SSI] == 0b1 then [m with SSI = s[SSI]] else m;
  m
}

function legalize_sip(m : Minterrupts, d : Minterrupts, v : xlenbits) -> Minterrupts = {
  lift_sip(m, d, Mk_Sinterrupts(v))
}

mapping clause csr_name_map = 0x144  <-> "sip"
function clause is_CSR_defined(0x144) = extensionEnabled(Ext_S) // sip
function clause read_CSR(0x144) = lower_mip(mip, mideleg).bits
function clause write_CSR(0x144, value) = { mip = legalize_sip(mip, mideleg, value); mip.bits }


// sie
/* Returns the new value of mie from the previous mie (o) and the written sie (s) as delegated by mideleg (d). */
function lift_sie(o : Minterrupts, d : Minterrupts, s : Sinterrupts) -> Minterrupts = {
  let m : Minterrupts = o;
  [m with
    SEI = if d[SEI] == 0b1 then s[SEI] else m[SEI],
    STI = if d[STI] == 0b1 then s[STI] else m[STI],
    SSI = if d[SSI] == 0b1 then s[SSI] else m[SSI],
  ]
}

function legalize_sie(m : Minterrupts, d : Minterrupts, v : xlenbits) -> Minterrupts = {
  lift_sie(m, d, Mk_Sinterrupts(v))
}


mapping clause csr_name_map = 0x104  <-> "sie"
function clause is_CSR_defined(0x104) = extensionEnabled(Ext_S) // sie
function clause read_CSR(0x104) = lower_mie(mie, mideleg).bits
function clause write_CSR(0x104, value) = { mie = legalize_sie(mie, mideleg, value); mie.bits }


/* other non-VM related supervisor state */
register stvec    : Mtvec
register sscratch : xlenbits
register sepc     : xlenbits
register scause   : Mcause
register stval    : xlenbits

mapping clause csr_name_map = 0x140  <-> "sscratch"
mapping clause csr_name_map = 0x142  <-> "scause"
mapping clause csr_name_map = 0x143  <-> "stval"

function clause is_CSR_defined(0x140) = extensionEnabled(Ext_S) // sscratch
function clause is_CSR_defined(0x142) = extensionEnabled(Ext_S) // scause
function clause is_CSR_defined(0x143) = extensionEnabled(Ext_S) // stval

function clause read_CSR(0x140) = sscratch
function clause read_CSR(0x142) = scause.bits
function clause read_CSR(0x143) = stval

function clause write_CSR(0x140, value) = { sscratch = value; sscratch }
function clause write_CSR(0x142, value) = { scause.bits = value; scause.bits }
function clause write_CSR(0x143, value) = { stval = value; stval }

/*
 * S-mode address translation and protection (satp) layout.
 * The actual satp register is defined in an architecture-specific file.
 */

bitfield Satp64 : bits(64) = {
  Mode : 63 .. 60,
  Asid : 59 .. 44,
  PPN  : 43 .. 0
}

function legalize_satp64(a : Architecture, o : bits(64), v : bits(64)) -> bits(64) = {
  let s = Mk_Satp64(v);
  match satp64Mode_of_bits(a, s[Mode]) {
    None()     => o,
    Some(Sv32) => o,  /* Sv32 is unsupported for now */
    Some(_)    => s.bits
  }
}

bitfield Satp32 : bits(32) = {
  Mode : 31,
  Asid : 30 .. 22,
  PPN  : 21 .. 0
}

function legalize_satp32(a : Architecture, o : bits(32), v : bits(32)) -> bits(32) = {
  /* all 32-bit satp modes are valid */
  v
}

/* disabled trigger/debug module */
register tselect : xlenbits

mapping clause csr_name_map = 0x7a0  <-> "tselect"
mapping clause csr_name_map = 0x7a1  <-> "tdata1"
mapping clause csr_name_map = 0x7a2  <-> "tdata2"
mapping clause csr_name_map = 0x7a3  <-> "tdata3"

function clause is_CSR_defined(0x7a0) = true
function clause read_CSR(0x7a0) = ~(tselect)  /* this indicates we don't have any trigger support */
function clause write_CSR(0x7a0, value) = { tselect = value; tselect }

/*
 * Entropy Source - Platform access to random bits.
 * WARNING: This function currently lacks a proper side-effect annotation.
 *          If you are using theorem prover tool flows, you
 *          may need to modify or stub out this function for now.
 * NOTE: This would be better placed in riscv_platform.sail, but that file
 *       appears _after_ this one in the compile order meaning the valspec
 *       for this function is unavailable when it's first encountered in
 *       read_seed_csr. Hence it appears here.
 */
val get_16_random_bits = impure {
    interpreter: "Platform.get_16_random_bits",
    c: "plat_get_16_random_bits",
    lem: "plat_get_16_random_bits"
} : unit -> bits(16)

/* vector csrs */
register vstart : bits(16) /* use the largest possible length of vstart */
register vl     : xlenbits

function get_vlenb() -> xlenbits = {
  to_bits(xlen, (2 ^ (get_vlen_pow()) / 8))
}

bitfield Vtype  : xlenbits = {
  vill      : xlen - 1,
  reserved  : xlen - 2 .. 8,
  vma       : 7,
  vta       : 6,
  vsew      : 5 .. 3,
  vlmul     : 2 .. 0
}
register vtype : Vtype

/* the dynamic selected element width (SEW) */
/* this returns the power of 2 for SEW */
val get_sew_pow : unit -> {3, 4, 5, 6}
function get_sew_pow() = {
  let SEW_pow : {3, 4, 5, 6} = match vtype[vsew] {
    0b000 => 3,
    0b001 => 4,
    0b010 => 5,
    0b011 => 6,
    _     => {assert(false, "invalid vsew field in vtype"); 0}
  };
  SEW_pow
}
/* this returns the actual value of SEW */
val get_sew : unit -> {8, 16, 32, 64}
function get_sew() = {
  match get_sew_pow() {
    3 => 8,
    4 => 16,
    5 => 32,
    6 => 64,
    _ => {internal_error(__FILE__, __LINE__, "invalid SEW"); 8}
  }
}
/* this returns the value of SEW in bytes */
val get_sew_bytes : unit -> {1, 2, 4, 8}
function get_sew_bytes() = {
  match get_sew_pow() {
    3 => 1,
    4 => 2,
    5 => 4,
    6 => 8,
    _ => {internal_error(__FILE__, __LINE__, "invalid SEW"); 1}
  }
}

/* the vector register group multiplier (LMUL) */
/* this returns the power of 2 for LMUL */
val get_lmul_pow : unit -> {-3, -2, -1, 0, 1, 2, 3}
function get_lmul_pow() = {
  match vtype[vlmul] {
    0b101 => -3,
    0b110 => -2,
    0b111 => -1,
    0b000 => 0,
    0b001 => 1,
    0b010 => 2,
    0b011 => 3,
    _     => {assert(false, "invalid vlmul field in vtype"); 0}
  }
}

enum agtype = { UNDISTURBED, AGNOSTIC }

val decode_agtype : bits(1) -> agtype
function decode_agtype(ag) = {
  match ag {
    0b0 => UNDISTURBED,
    0b1 => AGNOSTIC
  }
}

val get_vtype_vma : unit -> agtype
function get_vtype_vma() = decode_agtype(vtype[vma])

val get_vtype_vta : unit -> agtype
function get_vtype_vta() = decode_agtype(vtype[vta])
