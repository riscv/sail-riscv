/*=======================================================================================*/
/*  This Sail RISC-V architecture model, comprising all files and                        */
/*  directories except where otherwise noted is subject the BSD                          */
/*  two-clause license in the LICENSE file.                                              */
/*                                                                                       */
/*  SPDX-License-Identifier: BSD-2-Clause                                                */
/*=======================================================================================*/

/* Machine-mode and supervisor-mode functionality. */

enum clause extension = Ext_Zkr
function clause extensionEnabled(Ext_Zkr) = true

/* CSR access control */

function csrAccess(csr : csreg) -> csrRW = csr[11..10]
function csrPriv(csr : csreg) -> priv_level = csr[9..8]

// TODO: These is_CSR_defined definitions should be moved to the files
// corresponding to their extensions rather than all be here.

/* machine mode: informational */
function clause is_CSR_defined(0xf11) = true // mvendorid
function clause is_CSR_defined(0xf12) = true // marchdid
function clause is_CSR_defined(0xf13) = true // mimpid
function clause is_CSR_defined(0xf14) = true // mhartid
function clause is_CSR_defined(0xf15) = true // mconfigptr
/* machine mode: trap setup */
function clause is_CSR_defined(0x300) = true // mstatus
function clause is_CSR_defined(0x301) = true // misa
function clause is_CSR_defined(0x302) = extensionEnabled(Ext_S) | extensionEnabled(Ext_N) // medeleg
function clause is_CSR_defined(0x303) = extensionEnabled(Ext_S) | extensionEnabled(Ext_N) // mideleg
function clause is_CSR_defined(0x304) = true // mie
function clause is_CSR_defined(0x305) = true // mtvec
function clause is_CSR_defined(0x306) = extensionEnabled(Ext_U) // mcounteren
function clause is_CSR_defined(0x30A) = extensionEnabled(Ext_U) // menvcfg
function clause is_CSR_defined(0x310) = xlen == 32 // mstatush
function clause is_CSR_defined(0x31A) = extensionEnabled(Ext_U) & (xlen == 32) // menvcfgh
function clause is_CSR_defined(0x320) = true // mcountinhibit


/* machine mode: trap handling */
function clause is_CSR_defined(0x340) = true // mscratch
function clause is_CSR_defined(0x341) = true // mepc
function clause is_CSR_defined(0x342) = true // mcause
function clause is_CSR_defined(0x343) = true // mtval
function clause is_CSR_defined(0x344) = true // mip

// pmpcfgN
function clause is_CSR_defined(0x3A) @ idx : bits(4) = sys_pmp_count() > unsigned(idx) & (idx[0] == bitzero | xlen == 32)

// pmpaddrN. Unfortunately the PMP index does not nicely align with the CSR index bits.
function clause is_CSR_defined(0x3B) @ idx : bits(4) = sys_pmp_count() > unsigned(0b00 @ idx)
function clause is_CSR_defined(0x3C) @ idx : bits(4) = sys_pmp_count() > unsigned(0b01 @ idx)
function clause is_CSR_defined(0x3D) @ idx : bits(4) = sys_pmp_count() > unsigned(0b10 @ idx)
function clause is_CSR_defined(0x3E) @ idx : bits(4) = sys_pmp_count() > unsigned(0b11 @ idx)

/* counters */
function clause is_CSR_defined(0b0011001 /* 0x320 */ @ index : bits(5) if unsigned(index) >= 3) = extensionEnabled(Ext_Zihpm) // mhpmevent3..31

function clause is_CSR_defined(0xB00) = true // mcycle
function clause is_CSR_defined(0xB02) = true // minstret

function clause is_CSR_defined(0b1011000 /* 0xB00 */ @ index : bits(5) if unsigned(index) >= 3) = extensionEnabled(Ext_Zihpm) // mhpmcounter3..31

function clause is_CSR_defined(0xB80) = xlen == 32 // mcycleh
function clause is_CSR_defined(0xB82) = xlen == 32 // minstreth

function clause is_CSR_defined(0b1011100 /* 0xB80 */ @ index : bits(5) if unsigned(index) >= 3) = extensionEnabled(Ext_Zihpm) & (xlen == 32) // mhpmcounterh3..31

/* trigger/debug module */
function clause is_CSR_defined(0x7a0) = true
function clause is_CSR_defined(0x7a1) = true
function clause is_CSR_defined(0x7a2) = true
function clause is_CSR_defined(0x7a3) = true
function clause is_CSR_defined(0x7a4) = true
function clause is_CSR_defined(0x7a5) = true

/* supervisor mode: trap setup */
function clause is_CSR_defined(0x100) = extensionEnabled(Ext_S) // sstatus
function clause is_CSR_defined(0x102) = extensionEnabled(Ext_S) & extensionEnabled(Ext_N) // sedeleg
function clause is_CSR_defined(0x103) = extensionEnabled(Ext_S) & extensionEnabled(Ext_N) // sideleg
function clause is_CSR_defined(0x104) = extensionEnabled(Ext_S) // sie
function clause is_CSR_defined(0x105) = extensionEnabled(Ext_S) // stvec
function clause is_CSR_defined(0x106) = extensionEnabled(Ext_S) // scounteren
function clause is_CSR_defined(0x10A) = extensionEnabled(Ext_S) // senvcfg

/* supervisor mode: trap handling */
function clause is_CSR_defined(0x140) = extensionEnabled(Ext_S) // sscratch
function clause is_CSR_defined(0x141) = extensionEnabled(Ext_S) // sepc
function clause is_CSR_defined(0x142) = extensionEnabled(Ext_S) // scause
function clause is_CSR_defined(0x143) = extensionEnabled(Ext_S) // stval
function clause is_CSR_defined(0x144) = extensionEnabled(Ext_S) // sip

/* supervisor mode: address translation */
function clause is_CSR_defined(0x180) = extensionEnabled(Ext_S) // satp

/* user mode: counters */
function clause is_CSR_defined(0xC00) = extensionEnabled(Ext_U) // cycle
function clause is_CSR_defined(0xC01) = extensionEnabled(Ext_U) // time
function clause is_CSR_defined(0xC02) = extensionEnabled(Ext_U) // instret

function clause is_CSR_defined(0b1100000 /* 0xC00 */ @ index : bits(5) if unsigned(index) >= 3) = extensionEnabled(Ext_Zihpm) & extensionEnabled(Ext_U) // hpmcounter3..31

function clause is_CSR_defined(0xC80) = extensionEnabled(Ext_U) & (xlen == 32) // cycleh
function clause is_CSR_defined(0xC81) = extensionEnabled(Ext_U) & (xlen == 32) // timeh
function clause is_CSR_defined(0xC82) = extensionEnabled(Ext_U) & (xlen == 32) // instreth

function clause is_CSR_defined(0b1100100 /* 0xC80 */ @ index : bits(5) if unsigned(index) >= 3) = extensionEnabled(Ext_Zihpm) & extensionEnabled(Ext_U) & (xlen == 32) // hpmcounterh3..31

/* user mode: Zkr */
function clause is_CSR_defined(0x015) = extensionEnabled(Ext_Zkr)


val check_CSR_access : (csrRW, priv_level, Privilege, bool) -> bool
function check_CSR_access(csrrw, csrpr, p, isWrite) =
    not(isWrite == true & csrrw == 0b11)  /* read/write */
  & (privLevel_to_bits(p) >=_u csrpr)      /* privilege */

function check_TVM_SATP(csr : csreg, p : Privilege) -> bool =
  not(csr == 0x180 & p == Supervisor & mstatus[TVM] == 0b1)

// There are several features that are controlled by machine/supervisor enable
// bits (m/senvcfg, m/scounteren, etc.). This abstracts that logic.
function feature_enabled_for_priv(p : Privilege, machine_enable_bit : bit, supervisor_enable_bit : bit) -> bool = match p {
  Machine => true,
  Supervisor => machine_enable_bit == bitone,
  User => machine_enable_bit == bitone & (not(extensionEnabled(Ext_S)) | supervisor_enable_bit == bitone),
}

// Return true if the counter is enabled OR the CSR is not a counter.
function check_Counteren(csr : csreg, p : Privilege) -> bool = {
  // Check if it is not a counter.
  if csr <_u 0xC00 | 0xC1F <_u csr
  then return true;

  // Check the relevant bit in m/scounteren.
  let index = unsigned(csr[4 .. 0]);
  feature_enabled_for_priv(p, mcounteren.bits[index], scounteren.bits[index])
}

/* Seed may only be accessed if we are doing a write, and access has been
 * allowed in the current priv mode
 */
function check_seed_CSR (csr : csreg, p : Privilege, isWrite : bool) -> bool = {
  if not(csr == 0x015) then {
    true
  } else if not(isWrite) then {
    /* Read-only access to the seed CSR is not allowed */
    false
  } else {
    match (p) {
      Machine => true,
      Supervisor => false, /* TODO: base this on mseccfg */
      User => false, /* TODO: base this on mseccfg */
    }
  }
}

function check_CSR(csr : csreg, p : Privilege, isWrite : bool) -> bool =
    is_CSR_defined(csr)
  & check_CSR_access(csrAccess(csr), csrPriv(csr), p, isWrite)
  & check_TVM_SATP(csr, p)
  & check_Counteren(csr, p)
  & check_seed_CSR(csr, p, isWrite)

/* Reservation handling for LR/SC.
 *
 * The reservation state is maintained external to the model since the
 * reservation behavior is platform-specific anyway and maintaining
 * this state outside the model simplifies the concurrency analysis.
 *
 * These are externs are defined here in the system module since
 * we currently perform reservation cancellation on privilege level
 * transition.  Ideally, the platform should get more visibility into
 * where cancellation can be performed.
 */

val speculate_conditional = impure {interpreter: "excl_res", c: "speculate_conditional", lem: "speculate_conditional_success"} : unit -> bool

val load_reservation = impure {interpreter: "Platform.load_reservation", c: "load_reservation", lem: "load_reservation"} : xlenbits -> unit
val match_reservation = pure {interpreter: "Platform.match_reservation", lem: "match_reservation", c: "match_reservation"} : xlenbits -> bool
val cancel_reservation = impure {interpreter: "Platform.cancel_reservation", c: "cancel_reservation", lem: "cancel_reservation"} : unit -> unit

/* Exception delegation: given an exception and the privilege at which
 * it occured, returns the privilege at which it should be handled.
 */
function exception_delegatee(e : ExceptionType, p : Privilege) -> Privilege = {
  let idx   = num_of_ExceptionType(e);
  let super = bit_to_bool(medeleg.bits[idx]);
  /* if S-mode is absent, medeleg delegates to U-mode if 'N' is supported. */
  let user  = if   extensionEnabled(Ext_S)
              then super & extensionEnabled(Ext_N) & bit_to_bool(sedeleg.bits[idx])
              else super & extensionEnabled(Ext_N);
  let deleg = if      extensionEnabled(Ext_U) & user  then User
              else if extensionEnabled(Ext_S) & super then Supervisor
              else                               Machine;
  /* We cannot transition to a less-privileged mode. */
  if   privLevel_to_bits(deleg) <_u privLevel_to_bits(p)
  then p else deleg
}

/* Interrupts are prioritized in privilege order, and for each
 * privilege, in the order: external, software, timers.
 */
function findPendingInterrupt(ip : xlenbits) -> option(InterruptType) = {
  let ip = Mk_Minterrupts(ip);
  if      ip[MEI] == 0b1 then Some(I_M_External)
  else if ip[MSI] == 0b1 then Some(I_M_Software)
  else if ip[MTI] == 0b1 then Some(I_M_Timer)
  else if ip[SEI] == 0b1 then Some(I_S_External)
  else if ip[SSI] == 0b1 then Some(I_S_Software)
  else if ip[STI] == 0b1 then Some(I_S_Timer)
  else if ip[UEI] == 0b1 then Some(I_U_External)
  else if ip[USI] == 0b1 then Some(I_U_Software)
  else if ip[UTI] == 0b1 then Some(I_U_Timer)
  else                         None()
}

/* Process the pending interrupts xip at a privilege according to
 * the enabled flags xie and the delegation in xideleg. Return
 * either the set of pending interrupts, or the set of interrupts
 * delegated to the next lower privilege.
 */
union interrupt_set = {
  Ints_Pending   : xlenbits,
  Ints_Delegated : xlenbits,
  Ints_Empty     : unit
}
function processPending(xip : Minterrupts, xie : Minterrupts, xideleg : xlenbits,
                        priv_enabled : bool) -> interrupt_set = {
  /* interrupts that are enabled but not delegated are pending */
  let  effective_pend = xip.bits & xie.bits & (~ (xideleg));
  /* the others are delegated */
  let  effective_delg = xip.bits & xideleg;
  /* we have pending interrupts if this privilege is enabled */
  if      priv_enabled & (effective_pend != zero_extend(0b0))
  then    Ints_Pending(effective_pend)
  else if effective_delg != zero_extend(0b0)
  then    Ints_Delegated(effective_delg)
  else    Ints_Empty()
}

/* Given the current privilege level, iterate over privileges to get a
 * pending set for an enabled privilege. This is only called for M/U or
 * M/S/U systems.
 *
 * We don't use the lowered views of {xie,xip} here, since the spec
 * allows for example the M_Timer to be delegated to the U-mode.
 */
function getPendingSet(priv : Privilege) -> option((xlenbits, Privilege)) = {
  assert(extensionEnabled(Ext_U), "no user mode: M/U or M/S/U system required");
  let effective_pending = mip.bits & mie.bits;
  if  effective_pending == zero_extend(0b0) then None() /* fast path */
  else {
    /* Higher privileges than the current one are implicitly enabled,
     * while lower privileges are blocked.  An unsupported privilege is
     * considered blocked.
     */
    let mIE = priv != Machine | (priv == Machine & mstatus[MIE] == 0b1);
    let sIE = extensionEnabled(Ext_S) & (priv == User | (priv == Supervisor & mstatus[SIE] == 0b1));
    let uIE = extensionEnabled(Ext_N) & (priv == User & mstatus[UIE] == 0b1);
    match processPending(mip, mie, mideleg.bits, mIE) {
      Ints_Empty()      => None(),
      Ints_Pending(p)   => let r = (p, Machine) in Some(r),
      Ints_Delegated(d) =>
        if not(extensionEnabled(Ext_S)) then {
          if uIE then let r = (d, User) in Some(r)
          else                             None()
        } else {
          /* the delegated bits are pending for S-mode */
          match processPending(Mk_Minterrupts(d), mie, sideleg.bits, sIE) {
            Ints_Empty()      => None(),
            Ints_Pending(p)   => let r = (p, Supervisor) in Some(r),
            Ints_Delegated(d) => if   uIE
                                 then let r = (d, User) in Some(r)
                                 else None()
          }
        }
    }
  }
}

/* Examine the current interrupt state and return an interrupt to be *
 * handled (if any), and the privilege it should be handled at.
 */
function dispatchInterrupt(priv : Privilege) -> option((InterruptType, Privilege)) = {
  /* If we don't have different privilege levels, we don't need to check delegation.
   * Absence of U-mode implies absence of S-mode.
   */
  let multipleModesSupported = extensionEnabled(Ext_U);
  if not(multipleModesSupported) then {
    assert(priv == Machine, "invalid current privilege")
  };
  /* Even with U-mode, we don't need to check delegation when M-mode is the only
     one that can take interrupts, i.e. when we don't have S-mode and don't have
     the N extension
  */
  let delegationPossible = extensionEnabled(Ext_S) | extensionEnabled(Ext_N);
  if multipleModesSupported & delegationPossible then {
    match getPendingSet(priv) {
      None()      => None(),
      Some(ip, p) => match findPendingInterrupt(ip) {
                       None()  => None(),
                       Some(i) => let r = (i, p) in Some(r)
                     }
    }
  } else {
    let enabled_pending = mip.bits & mie.bits;
    match findPendingInterrupt(enabled_pending) {
      Some(i) => let r = (i, Machine) in Some(r),
      None()  => None()
    }
  }
}

/* types of privilege transitions */

union ctl_result = {
  CTL_TRAP : sync_exception,
  CTL_SRET : unit,
  CTL_MRET : unit,
  CTL_URET : unit
}

/* trap value */

function tval(excinfo : option(xlenbits)) -> xlenbits = {
  match (excinfo) {
    Some(e) => e,
    None()  => zero_extend(0b0)
  }
}

$ifdef RVFI_DII
val rvfi_trap : unit -> unit
// TODO: record rvfi_trap_data
function rvfi_trap () =
  rvfi_inst_data[rvfi_trap] = 0x01
$else
val rvfi_trap : unit -> unit
function rvfi_trap () = ()
$endif

/* Disable trigger firing in trap handler */
function TriggerFireMatch(cur_priv : Privilege) -> bool = {
  /* Second solution of reenterancy problem */
  if (sys_reent_opt1()) then {
    match cur_priv {
      Machine => bits_to_bool(tcontrol[mte]),
      _       => true
    }
  }
  /* First solution of reenterancy problem */
  else {
    match cur_privilege {
      Machine    => bits_to_bool(mstatus[MIE]),
      Supervisor => if (medeleg[Breakpoint] == 0b1) then { bits_to_bool(mstatus[SIE]) } else { true },
      _          => true
    }
  }
}

/* Instruction Count Trigger Match */
function icount_trigger_match(cur_priv : Privilege) -> unit = {
  /* Traverse through all the triggers */
  foreach (i from 0 to (sizeof(N_TRIGGERS) - 1)) {
    let trigger_type : bits(4) = tdata1_x.tdata1[i][(xlen - 1) .. (xlen - 4)];
    /* If Instruction Count trigger is found */
    if (trigger_type == triggerType_to_bits(TRIG_ICOUNT)) then {
      var InstrCount : InstructionCount  = Mk_InstructionCount(tdata1_x.tdata1[i][26 .. 0]);
      /* Check that trigger matches */
      if ((((InstrCount[m] == 0b1) & (cur_priv == Machine))     | /* Trigger is enabled in M-mode */
           ((InstrCount[s] == 0b1) & (cur_priv == Supervisor))  | /* Trigger is enabled in S-mode */
           ((InstrCount[u] == 0b1) & (cur_priv == User)) )      & /* Trigger is enabled in U-mode */
          (InstrCount[count] != zero_extend(14, 0b0))           &
          (TriggerFireMatch(cur_priv))) then { /* Trigger Match valid? check re-enterancy */
        /* Decrement the counter */
        if (InstrCount[count] == zero_extend(14, 0b1)) then {
          InstrCount[pending] = 0b1;
        };
        InstrCount[count]           = InstrCount[count] - 1;
        tdata1_x.tdata1[i][26 .. 0] = InstrCount.bits;
      }
    }
  }
}

/* Interrupt/Exception Trigger */
function IEtrigger_match(cur_priv : Privilege, idx : {'n, (0 <= 'n < xlen). int('n)}) -> unit = {
  /* Traverse through all the triggers */
  foreach (i from 0 to (sizeof(N_TRIGGERS) - 1)) {
    let trigger_type : bits(4) = tdata1_x.tdata1[i][(xlen - 1) .. (xlen - 4)];
    /* If Interrupt / Exception trigger found */
    if ((trigger_type == triggerType_to_bits(TRIG_ETRIGGER)) |
        (trigger_type == triggerType_to_bits(TRIG_ITRIGGER))) then {
      var IEtrigger : InterruptTrigger  = Mk_InterruptTrigger(tdata1_x.tdata1[i]);
      if ((((IEtrigger[m] == 0b1) & (cur_priv == Machine))     | /* Trigger is enabled in M-mode */
           ((IEtrigger[s] == 0b1) & (cur_priv == Supervisor))  | /* Trigger is enabled in S-mode */
           ((IEtrigger[u] == 0b1) & (cur_priv == User)) )      & /* Trigger is enabled in U-mode */
           (bit_to_bool(tdata2_x.tdata2[i][idx]))              &
           (TriggerFireMatch(cur_priv))) then { /* Trigger match valid? check re-enterancy */
            IEtrigger[hit]     = 0b1;
            tdata1_x.tdata1[i] = IEtrigger.bits;
      }
    }
  }
}

/* handle exceptional ctl flow by updating nextPC and operating privilege */

function trap_handler(del_priv : Privilege, intr : bool, c : exc_code, pc : xlenbits, info : option(xlenbits), ext : option(ext_exception))
                     -> xlenbits = {
  rvfi_trap();
  if   get_config_print_platform()
  then print_platform("handling " ^ (if intr then "int#" else "exc#")
                      ^ BitStr(c) ^ " at priv " ^ to_str(del_priv)
                      ^ " with tval " ^ BitStr(tval(info)));

  match (del_priv) {
    Machine => {
       mcause[IsInterrupt] = bool_to_bits(intr);
       mcause[Cause]       = zero_extend(c);

       mstatus[MPIE] = mstatus[MIE];
       mstatus[MIE]  = 0b0;
       mstatus[MPP]  = privLevel_to_bits(cur_privilege);
       tcontrol[mpte]  = tcontrol[mte];
       tcontrol[mte]   = 0b0;
       mtval           = tval(info);
       mepc            = pc;

       cur_privilege   = del_priv;

       handle_trap_extension(del_priv, pc, ext);

       if   get_config_print_reg()
       then print_reg("CSR mstatus <- " ^ BitStr(mstatus.bits));

       prepare_trap_vector(del_priv, mcause)
    },
    Supervisor => {
       assert (extensionEnabled(Ext_S), "no supervisor mode present for delegation");

       scause[IsInterrupt] = bool_to_bits(intr);
       scause[Cause]       = zero_extend(c);

       mstatus[SPIE] = mstatus[SIE];
       mstatus[SIE]  = 0b0;
       mstatus[SPP]  = match cur_privilege {
                           User => 0b0,
                           Supervisor => 0b1,
                           Machine => internal_error(__FILE__, __LINE__, "invalid privilege for s-mode trap")
                         };
       stval           = tval(info);
       sepc            = pc;

       cur_privilege   = del_priv;

       handle_trap_extension(del_priv, pc, ext);

       if   get_config_print_reg()
       then print_reg("CSR mstatus <- " ^ BitStr(mstatus.bits));

       prepare_trap_vector(del_priv, scause)
    },
    User => {
       assert(extensionEnabled(Ext_U), "no user mode present for delegation");

       ucause[IsInterrupt] = bool_to_bits(intr);
       ucause[Cause]       = zero_extend(c);

       mstatus[UPIE] = mstatus[UIE];
       mstatus[UIE]  = 0b0;
       utval           = tval(info);
       uepc            = pc;

       cur_privilege   = del_priv;

       handle_trap_extension(del_priv, pc, ext);

       if   get_config_print_reg()
       then print_reg("CSR mstatus <- " ^ BitStr(mstatus.bits));

       prepare_trap_vector(del_priv, ucause)
    }
  };
}

function exception_handler(cur_priv : Privilege, ctl : ctl_result,
                           pc: xlenbits) -> xlenbits = {
  match (cur_priv, ctl) {
    (_, CTL_TRAP(e)) => {
      let del_priv = exception_delegatee(e.trap, cur_priv);
      if   get_config_print_platform()
      then print_platform("trapping from " ^ to_str(cur_priv) ^ " to " ^ to_str(del_priv)
                          ^ " to handle " ^ to_str(e.trap));
      IEtrigger_match(cur_priv, num_of_ExceptionType(e.trap));
      trap_handler(del_priv, false, exceptionType_to_bits(e.trap), pc, e.excinfo, e.ext)
    },
    (_, CTL_MRET())  => {
      let prev_priv   = cur_privilege;
      mstatus[MIE]  = mstatus[MPIE];
      mstatus[MPIE] = 0b1;
      tcontrol[mte] = tcontrol[mpte];
      cur_privilege   = privLevel_of_bits(mstatus[MPP]);
      mstatus[MPP]  = privLevel_to_bits(if extensionEnabled(Ext_U) then User else Machine);
      if   cur_privilege != Machine
      then mstatus[MPRV] = 0b0;

      if   get_config_print_reg()
      then print_reg("CSR mstatus <- " ^ BitStr(mstatus.bits));
      if   get_config_print_platform()
      then print_platform("ret-ing from " ^ to_str(prev_priv) ^ " to " ^ to_str(cur_privilege));

      prepare_xret_target(Machine) & pc_alignment_mask()
    },
    (_, CTL_SRET())  => {
      let prev_priv   = cur_privilege;
      mstatus[SIE]  = mstatus[SPIE];
      mstatus[SPIE] = 0b1;
      cur_privilege   = if mstatus[SPP] == 0b1 then Supervisor else User;
      mstatus[SPP]  = 0b0;
      if   cur_privilege != Machine
      then mstatus[MPRV] = 0b0;

      if   get_config_print_reg()
      then print_reg("CSR mstatus <- " ^ BitStr(mstatus.bits));
      if   get_config_print_platform()
      then print_platform("ret-ing from " ^ to_str(prev_priv)
                          ^ " to " ^ to_str(cur_privilege));

      prepare_xret_target(Supervisor) & pc_alignment_mask()
    },
    (_, CTL_URET())  => {
      let prev_priv   = cur_privilege;
      mstatus[UIE]  = mstatus[UPIE];
      mstatus[UPIE] = 0b1;
      cur_privilege   = User;

      if   get_config_print_reg()
      then print_reg("CSR mstatus <- " ^ BitStr(mstatus.bits));
      if   get_config_print_platform()
      then print_platform("ret-ing from " ^ to_str(prev_priv) ^ " to " ^ to_str(cur_privilege));

      prepare_xret_target(User) & pc_alignment_mask()
    }
  }
}

function handle_mem_exception(addr : xlenbits, e : ExceptionType) -> unit = {
  let t : sync_exception = struct { trap    = e,
                                    excinfo = Some(addr),
                                    ext     = None() } in
  set_next_pc(exception_handler(cur_privilege, CTL_TRAP(t), PC))
}

function handle_exception(e: ExceptionType) -> unit = {
  let t : sync_exception = struct { trap    = e,
                                    excinfo = None(),
                                    ext     = None() } in
  set_next_pc(exception_handler(cur_privilege, CTL_TRAP(t), PC))
}

function handle_interrupt(i : InterruptType, del_priv : Privilege) -> unit = {
  IEtrigger_match(cur_privilege, num_of_interruptType(i));
  set_next_pc(trap_handler(del_priv, true, interruptType_to_bits(i), PC, None(), None()))
}

function find_first_zero(v: xlenbits) -> {'n, (1 <= 'n < xlen). int('n)} = {
  foreach (i from 1 to (xlen - 1)) {
    if v[i .. i] == 0b0 then return i;
  };
  return 1;
}

/* Match Control Type 6 Trigger Match */
function instrDataMatch(cur_priv : Privilege, addr : xlenbits, data : xlenbits, match_size : matchSize, match_type : MatchType) -> bool = {
  var raise_exception : bool = false;
  let half_xlen = sizeof(half_xlen);
  /* Traverse through all tirggers */
  foreach (i from 0 to (sizeof(N_TRIGGERS) - 1)) {
    let trigger_type : bits(4) = tdata1_x.tdata1[i][(xlen - 1) .. (xlen - 4)];
    var data_matched : bool = false;
    var size_matched : bool = false;
    /* Match Control Type 6 Trigger found */
    if (trigger_type == triggerType_to_bits(TRIG_MCONTROL6)) then {
      var MCtrl6 : MatchControlType6  = Mk_MatchControlType6(tdata1_x.tdata1[i][26 .. 0]);
      let matchOption : bits(4) = MCtrl6[match_opt];
      /* Decide content to match address/data based on select bit */
      let tdata2_content : xlenbits = match (MCtrl6[select]) {
        0b0 => { size_matched = true; addr },
        0b1 => {
          size_matched = match matchSize_of_bits(MCtrl6[size]) {
            ANY => true,
            _   => (match_size == matchSize_of_bits(MCtrl6[size])),
          };
          data
        }
      };
      /* Data matched according to the select match options */
      data_matched = match (matchOpt_of_bits(matchOption)) {
        MOPT_EQUAL => { (tdata2_x.tdata2[i] == tdata2_content) },
        MOPT_NAPOT => {
          let idx : {'n, (1 <= 'n < xlen). int('n)} = find_first_zero(tdata2_x.tdata2[i]);
          tdata2_x.tdata2[i][(xlen - 1) .. idx] == tdata2_content[(xlen - 1) .. idx]
        },
        MOPT_GE    => { (tdata2_content >=_u tdata2_x.tdata2[i][(xlen - 1) .. 0]) },
        MOPT_LT    => { (tdata2_content <_u  tdata2_x.tdata2[i][(xlen - 1) .. 0]) },
        MOPT_MASK_LOW => {
          let intemrd_cmpr_val : half_xlenbits = tdata2_content[(half_xlen - 1) .. 0] & tdata2_x.tdata2[i][(xlen - 1) .. half_xlen];
          intemrd_cmpr_val == tdata2_x.tdata2[i][(half_xlen - 1) .. 0]
        },
        MOPT_MASK_HIGH => {
          let intemrd_cmpr_val : half_xlenbits = tdata2_content[(xlen - 1) .. half_xlen] & tdata2_x.tdata2[i][(xlen - 1) .. half_xlen];
          intemrd_cmpr_val == tdata2_x.tdata2[i][(half_xlen - 1) .. 0]
        },
        MOPT_NOT_EQUAL => { (tdata2_x.tdata2[i] != tdata2_content) },
        MOPT_NOT_NAPOT => {
          let idx : {'n, (1 <= 'n < xlen). int('n)} = find_first_zero(tdata2_x.tdata2[i]);
          tdata2_x.tdata2[i][(xlen - 1) .. idx] != tdata2_content[(xlen - 1) .. idx]
        },
        MOPT_NOT_MASK_LOW => {
          let intemrd_cmpr_val : half_xlenbits = tdata2_content[(half_xlen - 1) .. 0] & tdata2_x.tdata2[i][(xlen - 1) .. half_xlen];
          intemrd_cmpr_val != tdata2_x.tdata2[i][(half_xlen - 1) .. 0]
        },
        MOPT_NOT_MASK_HIGH => {
          let intemrd_cmpr_val : half_xlenbits = tdata2_content[(xlen - 1) .. half_xlen] & tdata2_x.tdata2[i][(xlen - 1) .. half_xlen];
          intemrd_cmpr_val != tdata2_x.tdata2[i][(half_xlen - 1) .. 0]
        },
        _          => false
      };
      if ((((MCtrl6[m] == 0b1) & (cur_priv == Machine))     | /* Trigger is enabled in M-mode */
           ((MCtrl6[s] == 0b1) & (cur_priv == Supervisor))  | /* Trigger is enabled in S-mode */
           ((MCtrl6[u] == 0b1) & (cur_priv == User)) )      & /* Trigger is enabled in U-mode */
           (TriggerFireMatch(cur_priv))) then { /* Trigger match valid? check re-enternacy */
            match match_type {
              /* Check For PC or Instruction Match */
              INSTR_MATCH => {
                if (data_matched & size_matched & (MCtrl6[execute] == 0b1)) then {
                  MCtrl6[hit0] = 0b1;
                  tdata1_x.tdata1[i][26 .. 0] = MCtrl6.bits;
                  raise_exception = true;
                }
              },
              /* Check for Load Address match */
              LOAD_MATCH_BEFORE => { 
                if (data_matched & size_matched & (MCtrl6[load] == 0b1)) then {
                    MCtrl6[hit0] = 0b1;
                    tdata1_x.tdata1[i][26 .. 0] = MCtrl6.bits;
                    raise_exception = true;
                }
              },
              /* Check for load data match */
              LOAD_MATCH_AFTER => {
                if (data_matched & size_matched & (MCtrl6[load] == 0b1)) then {
                    MCtrl6[hit1] = 0b1;
                    tdata1_x.tdata1[i][26 .. 0] = MCtrl6.bits;
                }
              },
              /* Check for store address and data match */
              STORE_MATCH => {
                if (data_matched & size_matched & (MCtrl6[store] == 0b1)) then {
                    MCtrl6[hit0] = 0b1;
                    tdata1_x.tdata1[i][26 .. 0] = MCtrl6.bits;
                    raise_exception = true;
                }
              },
            };
            
      }
    }
  };
  if (raise_exception) then {
    handle_mem_exception(zero_extend(addr), E_Breakpoint());
  };
  raise_exception
}

/* Check for Etrigger, Icount, Itrigger and Mcontrol6 After, Trigger Firing */
function check_trigger_firing(cur_priv : Privilege) -> bool = {
  var trigger_fire_match : bool = false;
  var icountTrigFired    : bool = false;
  var ITrigFired         : bool = false;
  var ETrigFired         : bool = false;
  var MCtrlTrigFired     : bool = false;
  var fired_trigger_idx  : vector(2, dec, {'n, (0 <= 'n < 7). int('n)}) = [0, 0];
  var InstrCount         : InstructionCount  = Mk_InstructionCount(zero_extend(0b0));
  var IEtrigger          : InterruptTrigger  = Mk_InterruptTrigger(zero_extend(0b0));
  var MCtrl6             : MatchControlType6 = Mk_MatchControlType6(zero_extend(0b0));
  /* Traverse through each trigger */
  foreach (i from 0 to (sizeof(N_TRIGGERS) - 1)) 
  {
    InstrCount = Mk_InstructionCount(tdata1_x.tdata1[i][26 .. 0]);
    IEtrigger  = Mk_InterruptTrigger(tdata1_x.tdata1[i]);
    MCtrl6     = Mk_MatchControlType6(tdata1_x.tdata1[i][26 .. 0]);
    let trigger_type : bits(4) = tdata1_x.tdata1[i][(xlen - 1) .. (xlen - 4)];
    match triggerType_of_bits(trigger_type) {
      /* Check Exception Trigger Firing */
      TRIG_ETRIGGER => {
        if ((IEtrigger[hit] == 0b1) & (TriggerFireMatch(cur_priv)) & not(ETrigFired)) then {
          ETrigFired = true;
        }
      },
      /* Check instruction count trigger firing */
      TRIG_ICOUNT   => {
        if ((InstrCount[pending] == 0b1) & TriggerFireMatch(cur_priv) & not(icountTrigFired)) then {
          InstrCount[pending] = 0b0;
          tdata1_x.tdata1[i][26 .. 0] = InstrCount.bits;
          icountTrigFired     = true;
          fired_trigger_idx[0] = i;
        }
      },
      /* Check interrupt trigger firing */
      TRIG_ITRIGGER  => { 
        if ((IEtrigger[hit] == 0b1) & (TriggerFireMatch(cur_priv)) & not(ITrigFired)) then {
          ITrigFired = true;
        }
      },
      /* Check Match Control 6 After Trigger Firing */
      TRIG_MCONTROL6 => {
        if ((MCtrl6[hit1] == 0b1) & TriggerFireMatch(cur_priv) & not(MCtrlTrigFired)) then {
          MCtrlTrigFired       = true;
          fired_trigger_idx[1] = i;
        }
      },
      _ => ()
    }
  };
  if (ETrigFired | icountTrigFired | ITrigFired | MCtrlTrigFired) then {
    trigger_fire_match = true;
    handle_mem_exception(zero_extend(0b0), E_Breakpoint());
  };
  if (icountTrigFired) then {
    InstrCount = Mk_InstructionCount(tdata1_x.tdata1[fired_trigger_idx[0]][26 .. 0]);
    InstrCount[hit] = 0b1;
    tdata1_x.tdata1[fired_trigger_idx[0]][26 .. 0] = InstrCount.bits;
  } else if (ETrigFired | ITrigFired) then {
    MCtrl6 = Mk_MatchControlType6(tdata1_x.tdata1[fired_trigger_idx[1]][26 .. 0]);
    MCtrl6[hit1] = 0b0;
    MCtrl6[hit0] = 0b0;
    tdata1_x.tdata1[fired_trigger_idx[1]][26 .. 0] = MCtrl6.bits;
  };
  ETrigFired | icountTrigFired | ITrigFired | MCtrlTrigFired
}

/* state state initialization */

function init_sys() -> unit = {
  cur_privilege = Machine;

  mhartid     = zero_extend(0b0);
  mconfigptr  = zero_extend(0b0);

  misa[MXL] = arch_to_bits(if xlen == 32 then RV32 else RV64);
  misa[A]   = 0b1;                             /* atomics */
  misa[C]   = bool_to_bits(sys_enable_rvc());  /* RVC */
  misa[B]   = bool_to_bits(sys_enable_bext()); /* Bit-manipulation */
  misa[I]   = 0b1;                             /* base integer ISA */
  misa[M]   = 0b1;                             /* integer multiply/divide */
  misa[U]   = 0b1;                             /* user-mode */
  misa[S]   = 0b1;                             /* supervisor-mode */
  misa[V]   = bool_to_bits(sys_enable_vext()); /* vector extension */

  if   sys_enable_fdext() & sys_enable_zfinx()
  then internal_error(__FILE__, __LINE__, "F and Zfinx cannot both be enabled!");

  /* We currently support both F and D */
  misa[F]   = bool_to_bits(sys_enable_fdext());      /* single-precision */
  misa[D]   = if   flen >= 64
                then bool_to_bits(sys_enable_fdext())  /* double-precision */
                else 0b0;

  mstatus = set_mstatus_SXL(mstatus, misa[MXL]);
  mstatus = set_mstatus_UXL(mstatus, misa[MXL]);
  mstatus[SD]   = 0b0;
  mstatus[MPP] = privLevel_to_bits(lowest_supported_privLevel());

  /* set to little-endian mode */
  if xlen == 64 then {
    mstatus = Mk_Mstatus([mstatus.bits with 37 .. 36 = 0b00])
  };
  mstatush.bits = zero_extend(0b0);

  mip.bits     = zero_extend(0b0);
  mie.bits     = zero_extend(0b0);
  mideleg.bits = zero_extend(0b0);
  medeleg.bits = zero_extend(0b0);
  mtvec.bits   = zero_extend(0b0);
  mcause.bits  = zero_extend(0b0);
  mepc            = zero_extend(0b0);
  mtval           = zero_extend(0b0);
  mscratch        = zero_extend(0b0);

  mcycle          = zero_extend(0b0);
  mtime           = zero_extend(0b0);

  mcounteren.bits = zero_extend(0b0);

  minstret           = zero_extend(0b0);
  minstret_increment = true;

  menvcfg.bits = zero_extend(0b0);
  senvcfg.bits = zero_extend(0b0);
  /* initialize vector csrs */
  elen               = 0b1; /* ELEN=64 as the common case */
  vlen               = 0b0100; /* VLEN=512 as a default value */
  vlenb              = to_bits(xlen, 2 ^ (get_vlen_pow() - 3)); /* vlenb holds the constant value VLEN/8 */
  /* VLEN value needs to be manually changed currently.
   * See riscv_vlen.sail for details.
   */
  vstart             = zero_extend(0b0);
  vl                 = zero_extend(0b0);
  vcsr[vxrm]       = 0b00;
  vcsr[vxsat]      = 0b0;
  vtype[vill]      = 0b1;
  vtype[reserved]  = zero_extend(0b0);
  vtype[vma]       = 0b0;
  vtype[vta]       = 0b0;
  vtype[vsew]      = 0b000;
  vtype[vlmul]     = 0b000;

  foreach (i from 0 to 6) {
    tdata1_x.tdata1[i][(xlen - 1) .. (xlen - 4)] = 0xf;
  };

  // PMP's L and A fields are set to 0 on reset.
  init_pmp();

  // log compatibility with spike
  if   get_config_print_reg()
  then print_reg("CSR mstatus <- " ^ BitStr(mstatus.bits) ^ " (input: " ^ BitStr(zero_extend(0b0) : xlenbits) ^ ")")
}

/* memory access exceptions, defined here for use by the platform model. */

union MemoryOpResult ('a : Type) = {
  MemValue     : 'a,
  MemException : ExceptionType
}

val MemoryOpResult_add_meta : forall ('t : Type). (MemoryOpResult('t), mem_meta) -> MemoryOpResult(('t, mem_meta))
function MemoryOpResult_add_meta(r, m) = match r {
  MemValue(v)     => MemValue(v, m),
  MemException(e) => MemException(e)
}

val MemoryOpResult_drop_meta : forall ('t : Type). MemoryOpResult(('t, mem_meta)) -> MemoryOpResult('t)
function MemoryOpResult_drop_meta(r) = match r {
  MemValue(v, m)  => MemValue(v),
  MemException(e) => MemException(e)
}
