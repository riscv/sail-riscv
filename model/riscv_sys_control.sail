/*=======================================================================================*/
/*  This Sail RISC-V architecture model, comprising all files and                        */
/*  directories except where otherwise noted is subject the BSD                          */
/*  two-clause license in the LICENSE file.                                              */
/*                                                                                       */
/*  SPDX-License-Identifier: BSD-2-Clause                                                */
/*=======================================================================================*/

/* Machine-mode and supervisor-mode functionality. */

/* CSR access control */

function csrAccess(csr : csreg) -> csrRW = csr[11..10]
function csrPriv(csr : csreg) -> priv_level = csr[9..8]

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
  if csr <_u 0xC00 | 0xC1F <_u csr then return true;

  // Check the relevant bit in m/scounteren.
  let index = unsigned(csr[4 .. 0]);
  feature_enabled_for_priv(p, mcounteren.bits[index], scounteren.bits[index])
}

// Return true if the stimecmp[h] CSR is accessible OR the CSR is not stimecmp[h].
function check_Stimecmp(csr : csreg, p : Privilege) -> bool = {
  // Check if it is not stimecmp.
  if csr != 0x14D & csr != 0x15D then return true;

  p == Machine | (p == Supervisor & mcounteren[TM] == 0b1 & menvcfg[STCE] == 0b1)
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
  // TODO: If we add `p` back to is_CSR_defined() we could move these three
  // check_ functions back there. We should also rename is_CSR_defined()
  // to is_CSR_accessible() or similar.
  & check_TVM_SATP(csr, p)
  & check_Counteren(csr, p)
  & check_Stimecmp(csr, p)
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

val load_reservation = impure {interpreter: "Platform.load_reservation", c: "load_reservation", lem: "load_reservation"} : physaddrbits -> unit
val match_reservation = pure {interpreter: "Platform.match_reservation", lem: "match_reservation", c: "match_reservation"} : physaddrbits -> bool
val cancel_reservation = impure {interpreter: "Platform.cancel_reservation", c: "cancel_reservation", lem: "cancel_reservation"} : unit -> unit

/* Exception delegation: given an exception and the privilege at which
 * it occured, returns the privilege at which it should be handled.
 */
function exception_delegatee(e : ExceptionType, p : Privilege) -> Privilege = {
  let idx   = num_of_ExceptionType(e);
  let super = bit_to_bool(medeleg.bits[idx]);
  let deleg = if extensionEnabled(Ext_S) & super then Supervisor else Machine;
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
  else                        None()
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
  let  effective_pend = xip.bits & xie.bits & ~(xideleg);
  /* the others are delegated */
  let  effective_delg = xip.bits & xideleg;
  /* we have pending interrupts if this privilege is enabled */
  if      priv_enabled & (effective_pend != zeros())
  then    Ints_Pending(effective_pend)
  else if effective_delg != zeros()
  then    Ints_Delegated(effective_delg)
  else    Ints_Empty()
}

/* Given the current privilege level, iterate over privileges to get a
 * pending set for an enabled privilege.
 *
 * We don't use the lowered views of {xie,xip} here, since the spec
 * allows for example the M_Timer to be delegated to the S-mode.
 */
function getPendingSet(priv : Privilege) -> option((xlenbits, Privilege)) = {
  let effective_pending = mip.bits & mie.bits;
  if  effective_pending == zeros() then None() /* fast path */
  else {
    /* Higher privileges than the current one are implicitly enabled,
     * while lower privileges are blocked.  An unsupported privilege is
     * considered blocked.
     */
    let mIE = priv != Machine | (priv == Machine & mstatus[MIE] == 0b1);
    let sIE = extensionEnabled(Ext_S) & (priv == User | (priv == Supervisor & mstatus[SIE] == 0b1));
    match processPending(mip, mie, mideleg.bits, mIE) {
      Ints_Empty()      => None(),
      Ints_Pending(p)   => Some((p, Machine)),
      Ints_Delegated(d) => {
        if not(extensionEnabled(Ext_S)) then {
          // Can't delegate to user mode. This code is unreachable because
          // `mideleg.bits` is 0 without supervisor mode.
          internal_error(__FILE__, __LINE__, "N extension not supported");
        } else {
          /* the delegated bits are pending for S-mode */
          match processPending(Mk_Minterrupts(d), mie, zeros(), sIE) {
            Ints_Empty()      => None(),
            Ints_Pending(p)   => Some((p, Supervisor)),
            Ints_Delegated(d) => internal_error(__FILE__, __LINE__, "N extension not supported"),
          }
        }
      }
    }
  }
}

/* Examine the current interrupt state and return an interrupt to be *
 * handled (if any), and the privilege it should be handled at.
 */
function dispatchInterrupt(priv : Privilege) -> option((InterruptType, Privilege)) = {
  match getPendingSet(priv) {
    None()       => None(),
    Some(ip, p)  => match findPendingInterrupt(ip) {
                      None()  => None(),
                      Some(i) => Some((i, p)),
                    }
  }
}

/* types of privilege transitions */

union ctl_result = {
  CTL_TRAP : sync_exception,
  CTL_SRET : unit,
  CTL_MRET : unit,
}

/* trap value */

function tval(excinfo : option(xlenbits)) -> xlenbits = {
  match (excinfo) {
    Some(e) => e,
    None()  => zeros()
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
  /* Second solution of re-enterancy problem */
  if (sys_reent_opt1()) then {
    bits_to_bool(tcontrol[mte])
  }
  /* First solution of re-enterancy problem */
  else {
    match cur_privilege {
      Machine    => bits_to_bool(mstatus[MIE]),
      Supervisor => bits_to_bool(mstatus[SIE]),
      _          => true
    }
  }
}

/* Instruction Count Trigger Match */
function icount_trigger_match(cur_priv : Privilege) -> unit = {
  /* Traverse through all the triggers */
  foreach (i from 0 to (sizeof(N_TRIGGERS) - 1)) {
    let trigger_type : bits(4) = tdata1_x.tdata1[i][(sizeof(xlen) - 1) .. (sizeof(xlen) - 4)];
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
    let trigger_type : bits(4) = tdata1_x.tdata1[i][(sizeof(xlen) - 1) .. (sizeof(xlen) - 4)];
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
    User => internal_error(__FILE__, __LINE__, "Invalid privilege level"),
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

      prepare_xret_target(Machine)
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

      prepare_xret_target(Supervisor)
    },
  }
}

function handle_mem_exception(virtaddr(addr) : virtaddr, e : ExceptionType) -> unit = {
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
  foreach (i from 1 to (sizeof(xlen) - 1)) {
    if v[i .. i] == 0b0 then return i;
  };
  return 1;
}

/* Match Control Type 6 Trigger Match */
function instrDataMatch(cur_priv : Privilege, addr : xlenbits, data : xlenbits, match_size : matchSize, match_type : MatchType) -> bool = {
  var raise_exception : bool = false;
  /* Traverse through all tirggers */
  foreach (i from 0 to (sizeof(N_TRIGGERS) - 1)) {
    let trigger_type : bits(4) = tdata1_x.tdata1[i][(sizeof(xlen) - 1) .. (sizeof(xlen) - 4)];
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
          let idx : {'n, (1 <= 'n < xlen). int('n)} = find_first_zero(tdata2_content);
          tdata2_x.tdata2[i][(xlen - 1) .. (xlen - idx)] == tdata2_content[(xlen - 1) .. (xlen - idx)]
        },
        MOPT_GE    => { (tdata2_content >=_u tdata2_x.tdata2[i][(sizeof(xlen) - 1) .. 0]) },
        MOPT_LT    => { (tdata2_content <_u  tdata2_x.tdata2[i][(sizeof(xlen) - 1) .. 0]) },
        MOPT_MASK_LOW => {
          let intemrd_cmpr_val : half_xlenbits = tdata2_content[((sizeof(xlen) / 2) - 1) .. 0] & tdata2_x.tdata2[i][(sizeof(xlen) - 1) .. (sizeof(xlen) / 2)];
          intemrd_cmpr_val == tdata2_x.tdata2[i][((sizeof(xlen) / 2) - 1) .. 0]
        },
        MOPT_MASK_HIGH => {
          let intemrd_cmpr_val : half_xlenbits = tdata2_content[(sizeof(xlen) - 1) .. (sizeof(xlen) / 2)] & tdata2_x.tdata2[i][(sizeof(xlen) - 1) .. (sizeof(xlen) / 2)];
          intemrd_cmpr_val == tdata2_x.tdata2[i][((sizeof(xlen) / 2) - 1) .. 0]
        },
        MOPT_NOT_EQUAL => { (tdata2_x.tdata2[i] != tdata2_content) },
        MOPT_NOT_MASK_LOW => {
          let intemrd_cmpr_val : half_xlenbits = tdata2_content[((sizeof(xlen) / 2) - 1) .. 0] & tdata2_x.tdata2[i][(sizeof(xlen) - 1) .. (sizeof(xlen) / 2)];
          intemrd_cmpr_val != tdata2_x.tdata2[i][((sizeof(xlen) / 2) - 1) .. 0]
        },
        MOPT_NOT_MASK_HIGH => {
          let intemrd_cmpr_val : half_xlenbits = tdata2_content[(sizeof(xlen) - 1) .. (sizeof(xlen) / 2)] & tdata2_x.tdata2[i][(sizeof(xlen) - 1) .. (sizeof(xlen) / 2)];
          intemrd_cmpr_val != tdata2_x.tdata2[i][((sizeof(xlen) / 2) - 1) .. 0]
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

function checkIE_trigger(cur_priv : Privilege, IEtrigger : InterruptTrigger) -> bool = {
  let exec_deleg : bool = match (cur_priv) {
    Machine    => bits_to_bool(medeleg[Breakpoint]),
    Supervisor => not(bits_to_bool(medeleg[Breakpoint])),
    _          => true
  };
  if ((IEtrigger[hit] == 0b1) & (TriggerFireMatch(cur_priv) | exec_deleg)) then {
    true
  } else { false }
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
    let trigger_type : bits(4) = tdata1_x.tdata1[i][(sizeof(xlen) - 1) .. (sizeof(xlen) - 4)];
    match triggerType_of_bits(trigger_type) {
      /* Check Exception Trigger Firing */
      TRIG_ETRIGGER => { 
        if not(ETrigFired) then { ETrigFired = checkIE_trigger(cur_privilege, IEtrigger); }
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
        if not(ITrigFired) then { ITrigFired = checkIE_trigger(cur_privilege, IEtrigger); }
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

  mhartid     = zeros();
  mconfigptr  = zeros();

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
  mstatush.bits = zeros();

  mip.bits     = zeros();
  mie.bits     = zeros();
  mideleg.bits = zeros();
  medeleg.bits = zeros();
  mtvec.bits   = zeros();
  mcause.bits  = zeros();
  mepc            = zeros();
  mtval           = zeros();
  mscratch        = zeros();

  mcycle          = zeros();
  mtime           = zeros();

  mcounteren.bits = zeros();

  minstret           = zeros();
  minstret_increment = true;

  menvcfg.bits = zeros();
  senvcfg.bits = zeros();
  /* initialize vector csrs */
  vstart             = zeros();
  vl                 = zeros();
  vcsr[vxrm]       = 0b00;
  vcsr[vxsat]      = 0b0;
  vtype[vill]      = 0b1;
  vtype[reserved]  = zeros();
  vtype[vma]       = 0b0;
  vtype[vta]       = 0b0;
  vtype[vsew]      = 0b000;
  vtype[vlmul]     = 0b000;

  foreach (i from 0 to 6) {
    tdata1_x.tdata1[i][(sizeof(xlen) - 1) .. (sizeof(xlen) - 4)] = 0xf;
  };

  // PMP's L and A fields are set to 0 on reset.
  init_pmp();

  // log compatibility with spike
  if   get_config_print_reg()
  then print_reg("CSR mstatus <- " ^ BitStr(mstatus.bits) ^ " (input: " ^ BitStr(zeros() : xlenbits) ^ ")")
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
