// =======================================================================================
// This Sail RISC-V architecture model, comprising all files and
// directories except where otherwise noted is subject the BSD
// two-clause license in the LICENSE file.
//
// SPDX-License-Identifier: BSD-2-Clause
// =======================================================================================

// Machine-mode and supervisor-mode functionality.

function effectivePrivilege(access : MemoryAccessType(mem_payload), m : Mstatus, priv : Privilege) -> Privilege =
  if   access != InstructionFetch() & m[MPRV] == 0b1
  then privLevel_bits(m[MPP], m[MPV])
  else priv

// CSR access control

function csrAccess(csr : csreg) -> csrRW = csr[11..10]
function csrPriv(csr : csreg) -> nom_priv_bits = csr[9..8]

// Check that the CSR access is made with sufficient privilege.
function check_CSR_priv(csr : csreg, p : Privilege) -> bool =
  if currentlyEnabled(Ext_H) & (privLevel_to_bits(p) == 0b01 & privLevel_to_virt_bit(p) == 0b0) then 0b10 >=_u csrPriv(csr)
  else privLevel_to_bits(p) >=_u csrPriv(csr)

// Check that the CSR access isn't a write to a read-only CSR.
function check_CSR_access(csr : csreg, access_type : CSRAccessType) -> bool =
  not((access_type == CSRWrite | access_type == CSRReadWrite) & (csrAccess(csr) == 0b11))

// FIXME: The cases below should probably be checked in unittests instead of listed here
//
// According to the spec. (V20211203 - Section 9.6), this should happen in the following cases:
//   [X] in VS-mode, attempts to access a non-high-half counter CSR when the corresponding bit
//       in hcounteren is 0 and the same bit in mcounteren is 1;
//   [ ] in VS-mode, if XLEN=32, attempts to access a high-half counter CSR when the
//       corresponding bit in hcounteren is 0 and the same bit in mcounteren is 1;
//   [X] in VU-mode, attempts to access a non-high-half counter CSR when the corresponding bit
//       in either hcounteren or scounteren is 0 and the same bit in mcounteren is 1;
//   [ ] in VU-mode, if XLEN=32, attempts to access a high-half counter CSR when the
//       corresponding bit in either hcounteren or scounteren is 0 and the same bit in
//       mcounteren is 1;
//   [x] in VS-mode or VU-mode, attempts to access an implemented non-high-half hypervisor CSR
//       or VS CSR when the same access (read/write) would be allowed in HS-mode, assuming
//       mstatus.TVM=0;
//   [ ] in VS-mode or VU-mode, if XLEN=32, attempts to access an implemented high-half
//       hypervisor CSR or high-half VS CSR when the same access (read/write) to the CSR’s
//       low-half partner would be allowed in HS-mode, assuming mstatus.TVM=0;
//   [x] in VU-mode, attempts to access an implemented non-high-half supervisor CSR when the
//       same access (read/write) would be allowed in HS-mode, assuming mstatus.TVM=0;
//   [ ] in VU-mode, if XLEN=32, attempts to access an implemented high-half supervisor CSR
//       when the same access to the CSR’s low-half
//       partner would be allowed in HS-mode, assuming mstatus.TVM=0;
//   [ ] in VS-mode, attempts to access satp, when hstatus.VTVM=1
// Determine if an illegal CSR access should raise a "virtual instruction exception" instead of an "illegal instruction exception"
function csr_access_raises_virtual_instr(csr : csreg, p : Privilege, access_type : CSRAccessType) -> bool = {
  if privLevel_to_virt_bit(p) == 0b0
  then false
  else is_CSR_accessible(csr, p, access_type) & check_CSR_access(csr, access_type)
}

/*! Is it legal for mtinst or htinst to hold a transformed instruction on a given fault */
function exc_causes_transformed_inst_in_xtinst(e : ExceptionType) -> bool =
  match e {
    E_Load_Addr_Align()   => true,
    E_Load_Access_Fault() => true,
    E_SAMO_Addr_Align()   => true,
    E_SAMO_Access_Fault() => true,
    E_Load_Page_Fault()   => true,
    E_SAMO_Page_Fault()   => true,
    E_Load_GPage_Fault()  => true,
    E_SAMO_GPage_Fault()  => true,
    _                     => false,
  }

// FIXME: Define proper platform parameter for this
val plat_xtinst_has_transformed_inst : unit -> bool
function plat_xtinst_has_transformed_inst() = currentlyEnabled(Ext_H)

function check_CSR(csr : csreg, p : Privilege, access_type : CSRAccessType) -> bool =
    check_CSR_priv(csr, p)
  & check_CSR_access(csr, access_type)
  & is_CSR_accessible(csr, p, access_type)
  & stateen_allows_CSR_access(csr, p, access_type)

// Exception delegation: given an exception and the privilege at which
// it occurred, returns the privilege at which it should be handled.
function exception_delegatee(e : ExceptionType, p : Privilege) -> Privilege = {
  let idx = unsigned(exceptionType_bits(e));
  let del_to_hs = bit_to_bool(medeleg.bits[idx]);
  let del_to_vs = bit_to_bool(hedeleg.bits[idx]);
  let deleg = if currentlyEnabled(Ext_S) & del_to_hs then
                if currentlyEnabled(Ext_H) & del_to_vs then
                  VirtualSupervisor
                else Supervisor
              else Machine;
  // We cannot transition to a less-privileged mode.
  if (privLevel_to_bits(deleg) <=_u privLevel_to_bits(p)) & (privLevel_to_virt_bit(deleg) >=_u privLevel_to_virt_bit(p))
  then p else deleg
}

// Interrupts are prioritized in privilege order, and for each
// privilege, in the order: external, software, timers.
function findPendingInterrupt(ip : xlenbits) -> option(InterruptType) = {
  let ip = Mk_Minterrupts(ip);
  if      ip[MEI]  == 0b1 then Some(I_M_External)
  else if ip[MSI]  == 0b1 then Some(I_M_Software)
  else if ip[MTI]  == 0b1 then Some(I_M_Timer)
  else if ip[SEI]  == 0b1 then Some(I_S_External)
  else if ip[SSI]  == 0b1 then Some(I_S_Software)
  else if ip[STI]  == 0b1 then Some(I_S_Timer)
  else if ip[SGEI] == 0b1 then Some(I_SG_External)
  else if ip[VSEI] == 0b1 then Some(I_VS_External)
  else if ip[VSSI] == 0b1 then Some(I_VS_Software)
  else if ip[VSTI] == 0b1 then Some(I_VS_Timer)
  else                         None()
}

/*! Translate VS-level interrupts to their S-level counterpart */
function translateVSInterrupts(i : Minterrupts) -> Minterrupts = {
  let t = i;
  let t = [[t with SEI = i[VSEI]] with VSEI = 0b0];
  let t = [[t with SSI = i[VSSI]] with VSSI = 0b0];
  let t = [[t with STI = i[VSTI]] with VSTI = 0b0];
  // TODO: add hook for extensions to translate interrupts as well
  t
}

// Given the current privilege level, return the pending set
// of interrupts for the highest privilege that has any pending.
//
// We don't use the lowered views of {xie,xip} here, since the spec
// allows for example the M_Timer to be delegated to the S-mode.
//
// This is used when the hart is in the Active state.
//
// TODO: check hip/hie if hypervisor enabled.
function getPendingSet(priv : Privilege) -> option((xlenbits, Privilege)) = {
  // mideleg can only be non-zero if we support Supervisor mode.
  assert(currentlyEnabled(Ext_S) | mideleg.bits == zeros());

  let pending = mip.bits & mie.bits;
  let pending_m = pending & ~(mideleg.bits);
  let pending_s = pending & mideleg.bits & ~(hideleg.bits);
  let pending_vs = pending & mideleg.bits & hideleg.bits;

  let mIE  = (priv == Machine &  mstatus[MIE] == 0b1) | priv != Machine;
  let sIE  = (priv == Supervisor & mstatus[SIE] == 0b1) | priv == User | priv == VirtualSupervisor | priv == VirtualUser;
  let vsIE = currentlyEnabled(Ext_H) & (priv == VirtualSupervisor & vsstatus[SIE] == 0b1) | priv == VirtualUser;

  if      mIE & (pending_m != zeros()) then Some((pending_m, Machine))
  else if sIE & (pending_s != zeros()) then Some((pending_s, Supervisor))
  else if vsIE & (pending_vs != zeros()) then Some((translateVSInterrupts(Mk_Minterrupts(pending_vs)).bits, VirtualSupervisor))
  else None()
}

// Check if a locally enabled interrupt is pending.
//
// This does not examine the global enable bits (MIE and SIE in
// mstatus) and their delegation in mideleg. It does honor the
// local interrupt enables in mie.
//
// This is used when the hart is in the Waiting state, caused by
// instructions such as WFI and WRS.{NTO,STO}.
//
// The relevant detail in the privileged spec is:
// https://riscv.github.io/riscv-isa-manual/snapshot/privileged/#wfi
//
// "The operation of WFI must be unaffected by the global interrupt
// bits in mstatus (MIE and SIE) and the delegation register mideleg
// (i.e., the hart must resume if a locally enabled interrupt becomes
// pending, even if it has been delegated to a less-privileged mode),
// but should honor the individual interrupt enables (e.g, MTIE)
// (i.e., implementations should avoid resuming the hart if the
// interrupt is pending but not individually enabled)."
function shouldWakeForInterrupt() -> bool = {
  (mip.bits & mie.bits) != zeros()
}

// Examine the current interrupt state and return an interrupt to be *
// handled (if any), and the privilege it should be handled at.
function dispatchInterrupt(priv : Privilege) -> option((InterruptType, Privilege)) = {
  match getPendingSet(priv) {
    None()      => None(),
    Some(ip, p) => match findPendingInterrupt(ip) {
                     None()  => None(),
                     Some(i) => Some((i, p))
                   },
  }
}

// types of privilege transitions

union ctl_result = {
  CTL_TRAP : (ExceptionType, ExceptionContext),
  CTL_SRET : unit,
  CTL_MRET : unit,
}

function track_trap(p : Privilege) -> unit = {
  long_csr_write_callback("mstatus", "mstatush", mstatus.bits);
  match (p) {
    Machine => {
      csr_write_callback("mcause", mcause.bits);
      csr_write_callback("mtval", mtval);
      csr_write_callback("mepc", mepc);
    },
    Supervisor => {
      csr_write_callback("scause", scause.bits);
      csr_write_callback("stval", stval);
      csr_write_callback("sepc", sepc);
    },
    User              => internal_error(__FILE__, __LINE__, "Invalid privilege level User"),
    VirtualUser       => internal_error(__FILE__, __LINE__, "Invalid privilege level VirtualUser"),
    VirtualSupervisor => {
      csr_write_callback("vscause", vscause.bits);
      csr_write_callback("vstval", vstval);
      csr_write_callback("vsepc", vsepc);
    },
  };
}

// handle exceptional ctl flow by updating nextPC and operating privilege
function trap_handler(del_priv : Privilege, pc : xlenbits, c : TrapCause, context : ExceptionContext)
                     -> xlenbits = {
  let is_interrupt = trapCause_is_interrupt(c);
  let cause        = trapCause_bits(c);

  trap_callback(is_interrupt, cause);

  if   get_config_print_exception() | get_config_print_interrupt()
  then print_log("handling " ^ to_str(c)
                      ^ " at priv " ^ to_str(del_priv)
                      ^ " with tval " ^ bits_str(some_or_zero(context.excinfo))
                      ^ " and tinst " ^ bits_str(some_or_zero(context.excinst)));

  if hartSupports(Ext_Zicfilp) then zicfilp_preserve_elp_on_trap(del_priv);

  match (del_priv) {
    Machine => {
      mcause[IsInterrupt] = bool_to_bit(is_interrupt);
      mcause[Cause]       = zero_extend(cause);

      mstatus[MPIE] = mstatus[MIE];
      mstatus[MIE]  = 0b0;
      mstatus[MPP]  = privLevel_to_bits(cur_privilege);
      mstatus[MPV]  = if currentlyEnabled(Ext_H) & privLevel_is_virtual(cur_privilege) then 0b1 else 0b0;
      mstatus[GVA]  = if context.info_is_gva then 0b1 else 0b0;
      mtval         = some_or_zero(context.excinfo);
      mepc          = pc;
      mtval2        = some_or_zero(context.excinfo2);
      mtinst        = some_or_zero(context.excinst);

      cur_privilege = del_priv;

      handle_trap_extension(del_priv, pc, context.ext);

      track_trap(del_priv);

      prepare_trap_vector(del_priv, mcause)
    },
    Supervisor => {
      assert (currentlyEnabled(Ext_S), "no supervisor mode present for delegation");

      scause[IsInterrupt] = bool_to_bit(is_interrupt);
      scause[Cause]       = zero_extend(cause);

      mstatus[SPIE] = mstatus[SIE];
      mstatus[SIE]  = 0b0;
      mstatus[SPP]  = match cur_privilege {
        User              => 0b0,
        Supervisor        => 0b1,
        Machine           => internal_error(__FILE__, __LINE__, "invalid privilege for s-mode trap"),
        VirtualUser       => 0b0,
        VirtualSupervisor => 0b1,
      };
      hstatus[SPV]    = if currentlyEnabled(Ext_H) & privLevel_is_virtual(cur_privilege) then 0b1 else 0b0;
      hstatus[SPVP]   = if currentlyEnabled(Ext_H) & privLevel_is_virtual(cur_privilege) then mstatus[SPP] else hstatus[SPVP];
      hstatus[GVA]    = if currentlyEnabled(Ext_H) then bool_to_bit(context.info_is_gva) else 0b0;
      stval           = some_or_zero(context.excinfo);
      sepc            = pc;
      stval           = some_or_zero(context.excinfo);
      htval           = some_or_zero(context.excinfo2);
      htinst          = some_or_zero(context.excinst);

      cur_privilege   = del_priv;

      handle_trap_extension(del_priv, pc, context.ext);

      track_trap(del_priv);

      prepare_trap_vector(del_priv, scause)
    },
    VirtualSupervisor => {
      assert (currentlyEnabled(Ext_H), "Hypervisor extension not supported");
      vscause[IsInterrupt] = bool_to_bit(is_interrupt);
      vscause[Cause]       = zero_extend(cause);

      vsstatus[SPIE] = vsstatus[SIE];
      vsstatus[SIE]  = 0b0;
      vsstatus[SPP]  = match cur_privilege {
        User              => 0b0,
        Supervisor        => 0b1,
        Machine           => internal_error(__FILE__, __LINE__, "invalid privilege for vs-mode trap"),
        VirtualUser       => 0b0,
        VirtualSupervisor => 0b1,
      };
      vsepc          = pc;
      vstval         = some_or_zero(context.excinfo);

      cur_privilege  = del_priv;

      handle_trap_extension(del_priv, pc, context.ext);
      track_trap(del_priv);
      prepare_trap_vector(del_priv, vscause)
    },
    User              => internal_error(__FILE__, __LINE__, "Invalid privilege level"),
    VirtualUser       => internal_error(__FILE__, __LINE__, "Invalid privilege level"),
  };
}

function exception_handler(cur_priv : Privilege, ctl : ctl_result,
                           pc: xlenbits) -> xlenbits = {
  match ctl {
    CTL_TRAP(e, c) => {
      let del_priv = exception_delegatee(e, cur_priv);
      if   get_config_print_exception()
      then print_log("trapping from " ^ to_str(cur_priv) ^ " to " ^ to_str(del_priv)
                          ^ " to handle " ^ to_str(e));
      trap_handler(del_priv, pc, Exception(e), c)
    },
    CTL_MRET()  => {

      let prev_priv = cur_privilege;
      cur_privilege = privLevel_bits(mstatus[MPP], mstatus[MPV]);

      mstatus[MIE]  = mstatus[MPIE];
      mstatus[MPIE] = 0b1;
      mstatus[MPP]  = privLevel_to_bits(if currentlyEnabled(Ext_U) then User else Machine);
      mstatus[MPV]  = if privLevel_is_virtual(cur_privilege) then 0b1 else 0b0;

      if   cur_privilege != Machine
      then mstatus[MPRV] = 0b0;

      if   hartSupports(Ext_Zicfilp)
      then zicfilp_restore_elp_on_xret(mRET, cur_privilege);

      long_csr_write_callback("mstatus", "mstatush", mstatus.bits);

      if   get_config_print_exception()
      then print_log("ret-ing from " ^ to_str(prev_priv) ^ " to " ^ to_str(cur_privilege));

      prepare_xret_target(Machine)
    },
    CTL_SRET()  => {
      let prev_priv = cur_privilege;

      let ret =
      if privLevel_is_virtual(cur_privilege) then {
        cur_privilege = privLevel_bits(0b0 @ mstatus[SPP], if currentlyEnabled(Ext_H) then hstatus[SPV] else 0b0);
        vsstatus[SIE]  = vsstatus[SPIE];
        vsstatus[SPIE] = 0b1;
        cur_privilege  = if vsstatus[SPP] == 0b1 then VirtualSupervisor else VirtualUser;
        vsstatus[SPP]  = 0b0;
        VirtualSupervisor
      } else {
        mstatus[SIE]  = mstatus[SPIE];
        mstatus[SPIE] = 0b1;
        cur_privilege = privLevel_bits(0b0 @ mstatus[SPP], if currentlyEnabled(Ext_H) then hstatus[SPV] else 0b0);
        mstatus[SPP]  = 0b0;
        hstatus[SPV]  = 0b0;
        if   cur_privilege != Machine
        then mstatus[MPRV] = 0b0;
        Supervisor
      };

      if   hartSupports(Ext_Zicfilp)
      then zicfilp_restore_elp_on_xret(sRET, cur_privilege);

      long_csr_write_callback("mstatus", "mstatush", mstatus.bits);

      if   get_config_print_exception()
      then print_log("ret-ing from " ^ to_str(prev_priv)
                          ^ " to " ^ to_str(cur_privilege));

      prepare_xret_target(ret)
    },
  }
}

// Compute the value to write to mtval on a trap.
function xtval_exception_value(e : ExceptionType, excinfo : xlenbits) -> option(xlenbits) = {
  if match e {
    E_Illegal_Instr() => illegal_instruction_writes_xtval,
    E_Virtual_Instr() => virtual_instruction_writes_xtval,
    E_Breakpoint(Brk_Software) => software_breakpoint_writes_xtval,
    E_Breakpoint(Brk_Hardware) => hardware_breakpoint_writes_xtval,
    E_Load_Addr_Align() => misaligned_load_writes_xtval,
    E_Load_Access_Fault() => load_access_fault_writes_xtval,
    E_Load_Page_Fault() => load_page_fault_writes_xtval,
    E_Load_GPage_Fault() => load_guest_page_fault_writes_xtval,
    E_SAMO_Addr_Align() => misaligned_samo_writes_xtval,
    E_SAMO_Access_Fault() => samo_access_fault_writes_xtval,
    E_SAMO_Page_Fault() => samo_page_fault_writes_xtval,
    E_SAMO_GPage_Fault() => samo_guest_page_fault_writes_xtval,
    E_Fetch_Addr_Align() => misaligned_fetch_writes_xtval,
    E_Fetch_Access_Fault() => fetch_access_fault_writes_xtval,
    E_Fetch_Page_Fault() => fetch_page_fault_writes_xtval,
    E_Fetch_GPage_Fault() => fetch_guest_page_fault_writes_xtval,
    E_Software_Check() => software_check_fault_writes_xtval,
    E_U_EnvCall()  => false,
    E_S_EnvCall()  => false,
    E_VS_EnvCall() => false,
    E_M_EnvCall()  => false,
    E_Extension(_) => true,
    // the rest are all reserved exceptions
    E_Reserved_14() => reserved_exceptions_write_xtval,
    E_Reserved_16() => reserved_exceptions_write_xtval,
    E_Reserved_17() => reserved_exceptions_write_xtval,
    E_Reserved_19() => reserved_exceptions_write_xtval,
  } then Some(excinfo) else None()
}

function handle_exception(e : ExceptionType, c : ExceptionContext) -> unit = {
                                    // excinfo = xtval_exception_value(e, xtval),
  let c = {c with excinst = if c.excinst != None()
                            then c.excinst
                            else if (plat_xtinst_has_transformed_inst() & exc_causes_transformed_inst_in_xtinst(e))
                            then Some(zero_extend(instbits_transformed))
                            else None(),
                  ext     = None()};
  set_next_pc(exception_handler(cur_privilege, CTL_TRAP(e, c), PC))
}

function handle_interrupt(i : InterruptType, del_priv : Privilege) -> unit =
  set_next_pc(trap_handler(del_priv, PC, Interrupt(i), empty_exception_context()))

// Reset misa to enable the maximal set of supported extensions.
function reset_misa() -> unit = {
  misa[A]   = bool_to_bit(hartSupports(Ext_A));   // atomics
  misa[C]   = bool_to_bit(hartSupports(Ext_C));   // RVC
  misa[B]   = bool_to_bit(hartSupports(Ext_B));   // Bit-manipulation
  misa[M]   = bool_to_bit(hartSupports(Ext_M));   // integer multiply/divide
  misa[U]   = bool_to_bit(hartSupports(Ext_U));   // user-mode
  misa[H]   = bool_to_bit(hartSupports(Ext_H));   // hypervisor-mode
  misa[S]   = bool_to_bit(hartSupports(Ext_S));   // supervisor-mode
  misa[V]   = bool_to_bit(hartSupports(Ext_V));   // vector extension

  // Base integer ISA (disabled if we only support the 16-register E base).
  misa[E] = bool_to_bit(base_E_enabled);
  misa[I] = ~(misa[E]);

  if   hartSupports(Ext_F) & hartSupports(Ext_Zfinx)
  then internal_error(__FILE__, __LINE__, "F and Zfinx cannot both be enabled!");

  // TODO: Additions to Hypervisor defined by N extension

  // We currently support both F and D
  misa[F]   = bool_to_bit(hartSupports(Ext_F));      // single-precision
  misa[D]   = if   flen >= 64
              then bool_to_bit(hartSupports(Ext_D))  // double-precision
              else 0b0;
  csr_write_callback("misa", misa.bits);
}

// Address to reset PC to on reset.
register pc_reset_address : xlenbits = zeros()
// This is called externally to set the PC reset address to the ELF entry point.
// bits(64) is used because it's easier to deal with in C.
function set_pc_reset_address(addr : bits(64)) -> unit = pc_reset_address = trunc(addr)

// This function is called on reset, so it should only perform the reset actions
// described in the "Reset" section of the privileged architecture specification.
function reset_sys() -> unit = {

  // "Upon reset, a hart's privilege mode is set to M."
  cur_privilege = Machine;

  // "The mstatus fields MIE and MPRV are reset to 0."
  mstatus[MIE] = 0b0;
  mstatus[MPRV] = 0b0;
  // set to little-endian mode
  mstatus[MBE] = 0b0;
  mstatus[SBE] = 0b0;

  // "If little-endian memory accesses are supported, the mstatus/mstatush field
  // MBE is reset to 0."
  // TODO: The handling of mstatush is a bit awkward currently, but the model
  // currently only supports little endian so MBE is always 0.
  // See https://github.com/riscv/sail-riscv/issues/639
  // mstatus[MBE] = 0b0;

  long_csr_write_callback("mstatus", "mstatush", mstatus.bits);

  // "The misa register is reset to enable the maximal set of supported extensions"
  reset_misa();
  if currentlyEnabled(Ext_H) then reset_hext();

  // "For implementations with the "A" standard extension, there is no valid load reservation."
  cancel_reservation();

  // "The pc is set to an implementation-defined reset vector."
  PC = pc_reset_address;
  nextPC = pc_reset_address;

  // "The mcause register is set to a value indicating the cause of the reset."
  // "The mcause values after reset have implementation-specific interpretation,
  // but the value 0 should be returned on implementations that do not
  // distinguish different reset conditions."
  mcause.bits = zeros();
  csr_write_callback("mcause", mcause.bits);

  // "Writable PMP registers’ A and L fields are set to 0, unless the platform
  // mandates a different reset value for some PMP registers’ A and L fields."
  reset_pmp();

  // "The [s,u]seed bits must have a defined reset value. The system must
  // not allow them to be in an undefined state after a reset."
  mseccfg[SSEED] = bool_to_bit(config extensions.Zkr.sseed_reset_value : bool);
  mseccfg[USEED] = bool_to_bit(config extensions.Zkr.useed_reset_value : bool);

  // If the Zicfilp extension is implemented, the mseccfg.MLPE field is reset to 0.
  if hartSupports(Ext_Zicfilp) then mseccfg[MLPE] = 0b0;

  // "On reset, all writable mstateen bits are initialized by the hardware to zeros."
  reset_stateen();

  // TODO: Probably need to remove these vector resets too but it needs
  // refactoring anyway. See https://github.com/riscv/sail-riscv/issues/566 etc.
  // If they are kept then callbacks need to be added.

  // initialize vector csrs
  vstart           = zeros();
  vl               = zeros();
  vcsr[vxrm]       = 0b00;
  vcsr[vxsat]      = 0b0;
  vtype[vill]      = 0b1;
  vtype[reserved]  = zeros();
  vtype[vma]       = 0b0;
  vtype[vta]       = 0b0;
  vtype[vsew]      = 0b000;
  vtype[vlmul]     = 0b000;
}

// memory access exceptions, defined here for use by the platform model.

type MemoryOpResult('a : Type) = result('a, ExceptionType)

val MemoryOpResult_add_meta : forall ('t : Type). (MemoryOpResult('t), mem_meta) -> MemoryOpResult(('t, mem_meta))
function MemoryOpResult_add_meta(r, m) = match r {
  Ok(v)  => Ok(v, m),
  Err(e) => Err(e)
}

val MemoryOpResult_drop_meta : forall ('t : Type). MemoryOpResult(('t, mem_meta)) -> MemoryOpResult('t)
function MemoryOpResult_drop_meta(r) = match r {
  Ok(v, _m)  => Ok(v),
  Err(e) => Err(e)
}
