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
enum clause extension = Ext_Sstc
function clause extensionEnabled(Ext_Sstc) = sys_enable_sstc()

val sys_reent_opt1 = pure {c: "sys_reent_opt1", ocaml: "Platform.reent_opt1", _: "sys_reent_opt1"} : unit -> bool

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

enum clause extension = Ext_U
function clause extensionEnabled(Ext_U) = misa[U] == 0b1

enum clause extension = Ext_S
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

bitfield Mstatush : bits(32) = {
  MBE  : 5,
  SBE  : 4
}
register mstatush : Mstatush

bitfield Mstatus : xlenbits = {
  SD   : xlen - 1,

  // The MBE and SBE fields are in mstatus in RV64 and absent in RV32.
  // On RV32, they are in mstatush, which doesn't exist in RV64.  For now,
  // they are handled in an ad-hoc way.
  // MBE  : 37
  // SBE  : 36

  // The SXL and UXL fields don't exist on RV32, so they are modelled
  // via explicit getters and setters; see below.
  // SXL  : 35 .. 34,
  // UXL  : 33 .. 32,

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
  then arch_to_bits(RV32)
  else m.bits[35 .. 34]
}

function set_mstatus_SXL(m : Mstatus, a : arch_xlen) -> Mstatus = {
  if   xlen == 32
  then m
  else {
    let m = vector_update_subrange(m.bits, 35, 34,  a);
    Mk_Mstatus(m)
  }
}

function get_mstatus_UXL(m : Mstatus) -> arch_xlen = {
  if   xlen == 32
  then arch_to_bits(RV32)
  else m.bits[33 .. 32]
}

function set_mstatus_UXL(m : Mstatus, a : arch_xlen) -> Mstatus = {
  if   xlen == 32
  then m
  else {
    let m = vector_update_subrange(m.bits, 33, 32,  a);
    Mk_Mstatus(m)
  }
}

function legalize_mstatus(o : Mstatus, v : xlenbits) -> Mstatus = {
  /*
   * Populate all defined fields using the bits of v, stripping anything
   * that does not have a matching bitfield entry. All bits above 32 are handled
   * explicitly later.
   */
  // TODO: This method is error prone. We should instead explicitly copy the
  // fields that are implemented. See legalize_mie() for an example.
  let m : Mstatus = Mk_Mstatus(zero_extend(v[22 .. 7] @ 0b0 @ v[5 .. 5] @ 0b0 @ v[3 .. 3] @ 0b0 @ v[1 .. 1] @ 0b0));

  /* FS is WARL, and making FS writable can support the M-mode emulation of an FPU
   * to support code running in S/U-modes.  Spike does this, and for now, we match it,
   * but only if Zfinx isn't enabled.
   * FIXME: This should be made a platform parameter.
   */
  let m = [m with
    /* Legalize MPP */
    MPP = if have_privLevel(m[MPP]) then m[MPP] else privLevel_to_bits(lowest_supported_privLevel()),
    /* We don't have any extension context yet. */
    XS = extStatus_to_bits(Off),
    FS = if sys_enable_zfinx() then extStatus_to_bits(Off) else m[FS],
    MPRV = if extensionEnabled(Ext_U) then m[MPRV] else 0b0,
  ];

  // Set dirty bit to OR of other status bits.
  let m = [m with
    SD = bool_to_bits(extStatus_of_bits(m[FS]) == Dirty |
                      extStatus_of_bits(m[XS]) == Dirty |
                      extStatus_of_bits(m[VS]) == Dirty),
  ];

  /* We don't support dynamic changes to SXL and UXL. */
  let m = set_mstatus_SXL(m, get_mstatus_SXL(o));
  let m = set_mstatus_UXL(m, get_mstatus_UXL(o));

  /* We don't currently support changing MBE and SBE. */
  if xlen == 64 then {
    Mk_Mstatus([m.bits with 37 .. 36 = 0b00])
  } else m
}

mapping clause csr_name_map = 0x300  <-> "mstatus"

function clause is_CSR_defined(0x300) = true // mstatus
function clause is_CSR_defined(0x310) = xlen == 32 // mstatush

function clause read_CSR(0x300) = mstatus.bits
function clause read_CSR(0x310 if xlen == 32) = mstatush.bits

function clause write_CSR(0x300, value) = { mstatus = legalize_mstatus(mstatus, value); mstatus.bits }
function clause write_CSR((0x310, value) if xlen == 32) = { mstatush.bits } // ignore writes for now

/* architecture and extension checks */

function cur_Architecture() -> Architecture = {
  let a : arch_xlen =
    match (cur_privilege) {
      Machine    => misa[MXL],
      Supervisor => get_mstatus_SXL(mstatus),
      User       => get_mstatus_UXL(mstatus)
    };
  match architecture(a) {
    Some(a) => a,
    None()  => internal_error(__FILE__, __LINE__, "Invalid current architecture")
  }
}

function in32BitMode() -> bool = {
  cur_Architecture() == RV32
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
    STCE = if extensionEnabled(Ext_Sstc) then v[STCE] else 0b0,
    // Other extensions are not implemented yet so all other fields are read only zero.
  ]
}

function legalize_senvcfg(o : SEnvcfg, v : xlenbits) -> SEnvcfg = {
  let v = Mk_SEnvcfg(v);
  [o with
    FIOM = if sys_enable_writable_fiom() then v[FIOM] else 0b0,
    // Other extensions are not implemented yet so all other fields are read only zero.
  ];
}

register menvcfg : MEnvcfg
register senvcfg : SEnvcfg

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

bitfield Medeleg : xlenbits = {
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

function legalize_medeleg(o : Medeleg, v : xlenbits) -> Medeleg = {
  /* M-EnvCalls delegation is not supported */
  let m = Mk_Medeleg(v);
  let m = [m with MEnvCall = 0b0];
  /* medeleg[3] <-> Breakpoint Exception is hard-wire to 0 for second solution
     of re-enterancy problem */
  if (sys_reent_opt1()) then { let m = [m with Breakpoint = bool_bits(not(sys_reent_opt1()))]; m } else { m }
}

register mie     : Minterrupts /* Enabled */
register mip     : Minterrupts /* Pending */
register medeleg : Medeleg  /* Delegation to S-mode */
register mideleg : Minterrupts /* Delegation to S-mode */

mapping clause csr_name_map = 0x304  <-> "mie"
mapping clause csr_name_map = 0x344  <-> "mip"
mapping clause csr_name_map = 0x302  <-> "medeleg"
mapping clause csr_name_map = 0x303  <-> "mideleg"

function clause is_CSR_defined(0x304) = true // mie
function clause is_CSR_defined(0x344) = true // mip
function clause is_CSR_defined(0x302) = extensionEnabled(Ext_S) // medeleg
function clause is_CSR_defined(0x303) = extensionEnabled(Ext_S) // mideleg

function clause read_CSR(0x304) = mie.bits
function clause read_CSR(0x344) = mip.bits
function clause read_CSR(0x302) = medeleg.bits
function clause read_CSR(0x303) = mideleg.bits

function clause write_CSR(0x304, value) = { mie = legalize_mie(mie, value); mie.bits }
function clause write_CSR(0x344, value) = { mip = legalize_mip(mip, value); mip.bits }
function clause write_CSR(0x302, value) = { medeleg = legalize_medeleg(medeleg, value); medeleg.bits }
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
bitfield Sstatus : xlenbits = {
  SD   : xlen - 1,
  // The UXL field does not exist on RV32, so we define an explicit
  // getter and setter below.
  // UXL  : 30 .. 29,
  MXR  : 19,
  SUM  : 18,
  XS   : 16 .. 15,
  FS   : 14 .. 13,
  VS   : 10 .. 9,
  SPP  : 8,
  SPIE : 5,
  SIE  : 1,
}
/* sstatus is a view of mstatus, so there is no register defined. */

function get_sstatus_UXL(s : Sstatus) -> arch_xlen = {
  let m = Mk_Mstatus(s.bits);
  get_mstatus_UXL(m)
}

function set_sstatus_UXL(s : Sstatus, a : arch_xlen) -> Sstatus = {
  let m = Mk_Mstatus(s.bits);
  let m = set_mstatus_UXL(m, a);
  Mk_Sstatus(m.bits)
}

function lower_mstatus(m : Mstatus) -> Sstatus = {
  let s = Mk_Sstatus(zeros());
  let s = set_sstatus_UXL(s, get_mstatus_UXL(m));

  [s with
    SD = m[SD],
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
    SD = bool_to_bits(dirty),
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
  legalize_mstatus(m, lift_sstatus(m, Mk_Sstatus(v)).bits)
}

mapping clause csr_name_map = 0x100  <-> "sstatus"
function clause is_CSR_defined(0x100) = extensionEnabled(Ext_S) // sstatus
function clause read_CSR(0x100) = lower_mstatus(mstatus).bits
function clause write_CSR(0x100, value) = { mstatus = legalize_sstatus(mstatus, value); mstatus.bits }


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

/*  Legalize TSELECT */
function legalize_tselect(o : xlenbits, v : xlenbits) -> xlenbits = {
  let t : xlenbits = o;
  // TODO: Avoid hardcode value
  if (unsigned(v) <= (sizeof(N_TRIGGERS) - 1)) then { v } else { t }
}

struct N_TDATA1 = {
  tdata1 : vector(N_TRIGGERS, xlenbits)
}

struct N_TDATA2 = {
  tdata2 : vector(N_TRIGGERS, xlenbits)
}

struct N_TDATA3 = {
  tdata3 : vector(N_TRIGGERS, xlenbits)
}

register tdata1_x : N_TDATA1 = undefined

register tdata2_x : N_TDATA2 = undefined

register tdata3_x : N_TDATA3 = undefined

register tdata1 : xlenbits = undefined

register tdata2 : xlenbits

register tdata3 : xlenbits

/* Match Control Type 6 Trigger Bit fields */
bitfield MatchControlType6 : bits(27) = {
  /* Trigger perfectly satisfied or not */
  uncertain   : 26,
  /* Sets when mcontrol6 fire after the instruction retires */
  hit1        : 25,
  /* Enable Mcontrol6 trigger in VS-mode */
  vs          : 24,
  /* Enable Mcontrol6 trigger in VU-mode */
  vu          : 23,
  /* Sets when mcontrol6 fire before the instruction retires */
  hit0        : 22,
  /* 0: address match, 1: data match */
  select      : 21,
  /* Reserved bits */
  rsvd1       : 20 .. 19,
  /* Access Size */
  size        : 18 .. 16,
  /* Trigger Action */
  action      : 15 .. 12,
  /* trigger chaning */
  chain       : 11,
  /* Trigger match options */
  match_opt   : 10 .. 7,
  /* Enable Mcontrol6 trigger in M-mode */
  m           : 6,
  /* Enable uncertain matches */
  uncertainen : 5,
  /* Enable Mcontrol6 trigger in S-mode */
  s           : 4,
  /* Enable Mcontrol6 trigger in U-mode */
  u           : 3,
  /* Trigger fires on the virtual address or opcode WARL
     of an instruction that is executed */
  execute     : 2,
  /* Trigger fires on the virtual address or data of WARL
     any store */
  store       : 1,
  /* Trigger fires on the virtual address or data of WARL
     any load */
  load        : 0
}

/* Instruction Count Trigger Bit fields */
bitfield InstructionCount : bits(27) = {
  /* Enable Instruction Count trigger in VS-mode */
  vs      : 26,
  /* Enable Instruction Count trigger in VU-mode */
  vu      : 25,
  /* Sets it when trigger fires */
  hit     : 24,
  /* Number of instructions to count */
  count   : 23 .. 10,
  /* Enable Instruction Count trigger in M-mode */
  m       : 9,
  /* Sets when count decremented from 1 to 0 */
  pending : 8,
  /* Enable Instruction Count trigger in S-mode */
  s       : 7,
  /* Enable Instruction Count trigger in U-mode */
  u       : 6,
  /* Trigger Action */
  action  : 5 .. 0
}

/* Interrupt/Exception Trigger Bit fields */
bitfield InterruptTrigger : xlenbits = {
  /* Sets it when this trigger matches */
  hit    : xlen - 6,
  /* Reserved bits */
  rsvd2  : xlen - 19,
  /* Enable Exception/Interrupt trigger from VS-mode */
  vs     : 12,
  /* Enable Exception/Interrupt trigger from VU-mode */
  vu     : 11,
  /* Non-maskable interrupts cause the trigger to fire - Only for Itrigger*/
  nmi    : 10,
  /* Enable Exception/Interrupr trigger from M-mode */
  m      : 9,
  /* Reserved bits */
  rsvd1  : 8,
  /* Enable Exception/Interrupr trigger from S-mode */
  s      : 7,
  /* Enable Exception/Interrupr trigger from U-mode */
  u      : 6, 
  /* Trigger Action */
  action : 5 .. 0
}

/* Legalize Tdata1 */
function legalize_tdata1(o : xlenbits, v : xlenbits) -> xlenbits = {
  let trigger_type   : bits(4)           = v[(sizeof(xlen) - 1) .. (sizeof(xlen) - 4)];
  let trigger_dmode  : bits(1)           = v[(sizeof(xlen) - 5) .. (sizeof(xlen) - 5)];
  /* TODO: Update trigger action when remaining trigger action option will add */
  let trigger_action : bits(6)           = (0b00 @ 0x0);
  let MCtrl6         : MatchControlType6 = Mk_MatchControlType6(v[26 .. 0]);
  let InstrCount     : InstructionCount  = Mk_InstructionCount(v[26 .. 0]);
  let IntrptTrigger  : InterruptTrigger  = Mk_InterruptTrigger(v);
  let ExcepTrigger   : InterruptTrigger  = Mk_InterruptTrigger(v);
  var new_value      : xlenbits          = o;

  new_value[(sizeof(xlen) - 1) .. (sizeof(xlen) - 4)] = trigger_type;
  new_value[(sizeof(xlen) - 5) .. (sizeof(xlen) - 5)] = trigger_dmode;
  match triggerType_of_bits(trigger_type){
    TRIG_ICOUNT    => {
      /* Trigger action */
      new_value[5 .. 0]  = trigger_action;
      /* vs | vu | hit | count | m | pending | s | u */
      new_value[24 .. 6] = InstrCount.bits[24 .. 6];
      new_value
    },
    TRIG_ITRIGGER  => {
      /* Trigger action  */
      new_value[5 .. 0]  = trigger_action;
      /* s | u */
      new_value[7 .. 6]  = (IntrptTrigger[s] @ IntrptTrigger[u]);
      /* nmi | m */
      new_value[10 .. 9] = (IntrptTrigger[nmi] @ IntrptTrigger[m]);
      /* hit */
      new_value[(sizeof(xlen) - 6) .. (sizeof(xlen) - 6)] = IntrptTrigger[hit];
      new_value
    },
    TRIG_ETRIGGER  => {
      /* trigger action */
      new_value[5 .. 0] = trigger_action;
      /* s | u */
      new_value[7 .. 6] = (IntrptTrigger[s] @ IntrptTrigger[u]);
      /* m */
      new_value[9 .. 9] = IntrptTrigger[m];
      /* hit */
      new_value[(sizeof(xlen) - 6) .. (sizeof(xlen) - 6)] = IntrptTrigger[hit];
      new_value
    },
    TRIG_MCONTROL6 => {
      let match_option : MATCH_OPTIONS = matchOpt_of_bits(v[10 .. 7]);
      /* m | uncertainen | s | u | execute | store | load */
      new_value[6 .. 0]   = MCtrl6.bits[6 .. 0];
      /* match */
      new_value[10 .. 7]  = v[10 .. 7];
      /* size | action | chain */
      new_value[18 .. 11] = (MCtrl6[size] @ trigger_action[3 .. 0] @ MCtrl6[chain]);
      /* hit0 | select */
      new_value[22 .. 21] = (MCtrl6[hit0] @ MCtrl6[select]);
      /* uncertain | hit1 */
      new_value[26 .. 25] = (MCtrl6[uncertain] @ MCtrl6[hit1]);
      new_value
    },
    TRIG_DISABLED  => {v},
    _ => { new_value = o; new_value }
  }
  
}

/* Write tdata1 of current trigger */
function tdata1_write(tselect_val : xlenbits, o : xlenbits, new_value : xlenbits) -> xlenbits = {
  let index : int = unsigned(tselect[2 .. 0]);
  let v : xlenbits = legalize_tdata1(o, new_value);
  if ((index >= 0) & (index < vector_length(tdata1_x.tdata1))) then 
  { tdata1_x.tdata1[index] = v; v } else { o }
}

/* Read tdata1 of current trigger */
function tdata1_read(tselect_val : xlenbits) -> xlenbits = {
  let index : int = unsigned(tselect[2 .. 0]);
  if ((index >= 0) & (index < vector_length(tdata1_x.tdata1))) then 
  { tdata1_x.tdata1[index]; } else { zero_extend(0b0); }
}

/* Write tdata2 of current trigger */
function tdata2_write(tselect_val : xlenbits, o : xlenbits, v : xlenbits) -> xlenbits = {
  let index : int = unsigned(tselect[2 .. 0]);
  if ((index >= 0) & (index < vector_length(tdata2_x.tdata2))) then 
  { tdata2_x.tdata2[index] = v; v } else { o }
}

/* Read TData2 of current trigger */
function tdata2_read(tselect_val : xlenbits) -> xlenbits = {
  let index : int = unsigned(tselect[2 .. 0]);
  if ((index >= 0) & (index < vector_length(tdata2_x.tdata2))) then 
  { tdata2_x.tdata2[index]; } else { zero_extend(0b0); }
}

/* Write tdata3 of current trigger */
function tdata3_write(tselect_val : xlenbits, o : xlenbits, v : xlenbits) -> xlenbits = {
  let index : int = unsigned(tselect[2 .. 0]);
  if ((index >= 0) & (index < vector_length(tdata3_x.tdata3))) then 
  { tdata3_x.tdata3[index] = v; v } else { o }
}

/* Read TData3 of current trigger */
function tdata3_read(tselect_val : xlenbits) -> xlenbits = {
  let index : int = unsigned(tselect[2 .. 0]);
  if ((index >= 0) & (index < vector_length(tdata3_x.tdata3))) then 
  { tdata3_x.tdata3[index]; } else { zero_extend(0b0); }
}

register tinfo : xlenbits

function tinfo_read(tselect_val : xlenbits) -> xlenbits = {
  let tinfo_info    : bits(16) = zero_extend(
    (0x0001 << triggerType_to_bits(TRIG_ICOUNT))    |
    (0x0001 << triggerType_to_bits(TRIG_ITRIGGER))  |
    (0x0001 << triggerType_to_bits(TRIG_ETRIGGER))  |
    (0x0001 << triggerType_to_bits(TRIG_MCONTROL6)) |
    (0x0001 << triggerType_to_bits(TRIG_DISABLED))
  );
  let tinfo_version : bits(8)  = zero_extend(0b1);

  zero_extend(tinfo_version @ 0x00 @ tinfo_info)
}


bitfield Tcontrol : xlenbits = {
  mpte  : 7,
  rsvd2 : 6 .. 4,
  mte   : 3,
  rsvd1 : 2 .. 0
}

function legalize_tcontrol(v : xlenbits) -> xlenbits = {
  zero_extend(v[7 .. 7] @ 0b000 @ v[3 .. 3] @ 0b000)
}

register tcontrol : Tcontrol

/*
 * The seed CSR (entropy source)
 * ------------------------------------------------------------
 */

/* trigger/debug module */
function clause is_CSR_defined(0x7a0) = true
function clause is_CSR_defined(0x7a1) = true
function clause is_CSR_defined(0x7a2) = true
function clause is_CSR_defined(0x7a3) = true
function clause is_CSR_defined(0x7a4) = true
function clause is_CSR_defined(0x7a5) = true

/* trigger/debug CSR read */
function clause read_CSR(0x7a0) = tselect
function clause read_CSR(0x7a1) = tdata1_read(tselect)
function clause read_CSR(0x7a2) = tdata2_read(tselect)
function clause read_CSR(0x7a3) = tdata3_read(tselect)
function clause read_CSR(0x7a4) = tinfo_read(tselect)
function clause read_CSR(0x7a5) = tcontrol.bits

/* trigger/debug CSR write */
function clause write_CSR(0x7a0, value) = { tselect = legalize_tselect(tselect, value); tselect }
function clause write_CSR(0x7a1, value) = { tdata1 = tdata1_write(tselect, tdata1_read(tselect), value); tdata1 }
function clause write_CSR(0x7a2, value) = { tdata2 = tdata2_write(tselect, tdata2_read(tselect), value); tdata2 }
function clause write_CSR(0x7a3, value) = { tdata3 = tdata3_write(tselect, tdata3_read(tselect), value); tdata3 }
function clause write_CSR(0x7a5, value) = { tcontrol.bits = legalize_tcontrol(value); tcontrol.bits }

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
