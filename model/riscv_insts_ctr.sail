/*=======================================================================================*/
/*  This Sail RISC-V architecture model, comprising all files and                        */
/*  directories except where otherwise noted is subject the BSD                          */
/*  two-clause license in the LICENSE file.                                              */
/*                                                                                       */
/*  SPDX-License-Identifier: BSD-2-Clause                                                */
/*=======================================================================================*/

/* ***************************************************************************/
/* This file specifies the instruction added by the 'Smctr/Ssctr' extension. */

union clause ast = SCTRCLR : unit

mapping clause encdec = SCTRCLR()
  <-> 0b000100000100 @ 0b00000 @ 0b000 @ 0b00000 @ 0b1110011

function clause execute SCTRCLR() = {
  let sctrclr_illegal : bool = match cur_privilege {
    User       => true,
    Supervisor => not(haveSmctr()) | mstateen0[CTR] == 0b0,
    Machine    => not(haveSmctr())
  };
  if   sctrclr_illegal
  then { handle_illegal(); RETIRE_FAIL }
  else {
    foreach (i from 0 to 255) {
      ctrsource[i] = Mk_Ctrsource(zeros());
      ctrtarget[i] = Mk_Ctrtarget(zeros());
      ctrdata[i] = Mk_Ctrdata(zeros());
    };
    ctr_cycle_counter = zeros();
    ctr_cycle_counter_valid = false;
    RETIRE_SUCCESS
  }
}

mapping clause assembly = SCTRCLR() <-> "sctrclr"
/* ***************************************************************************/

val get_wrptr_mask : Sctrdepth -> bits(8)

/* The following functions are extensions to JAL/JALR instructions to
 * update control transfer records
 */
enum ctr_xfer_type  = {
  EXCEPTION,
  INTERRUPT,
  TRAP_RETURN,
  NOT_TAKEN_BRANCH,
  TAKEN_BRANCH,
  INDIRECT_CALL,
  DIRECT_CALL,
  INDIRECT_JUMP_NO_LINKAGE,
  DIRECT_JUMP_NO_LINKAGE,
  COROUTINE_SWAP,
  FUNCTION_RETURN,
  OTHER_INDIRECT_JUMP_WITH_LINKAGE,
  OTHER_DIRECT_JUMP_WITH_LINKAGE
  }

mapping encdec_ctr_xfer_type : ctr_xfer_type <-> bits(4) = {
  EXCEPTION                        <-> 0b0001,
  INTERRUPT                        <-> 0b0010,
  TRAP_RETURN                      <-> 0b0011,
  NOT_TAKEN_BRANCH                 <-> 0b0100,
  TAKEN_BRANCH                     <-> 0b0101,
  INDIRECT_CALL                    <-> 0b1000,
  DIRECT_CALL                      <-> 0b1001,
  INDIRECT_JUMP_NO_LINKAGE         <-> 0b1010,
  DIRECT_JUMP_NO_LINKAGE           <-> 0b1011,
  COROUTINE_SWAP                   <-> 0b1100,
  FUNCTION_RETURN                  <-> 0b1101,
  OTHER_INDIRECT_JUMP_WITH_LINKAGE <-> 0b1110,
  OTHER_DIRECT_JUMP_WITH_LINKAGE   <-> 0b1111
}

function is_ctr_active(priv : Privilege) -> bool =
  match priv {
    User       => haveSmctr() & mstateen0[CTR] == 0b1 & mctrctl[U] == 0b1 & sctrstatus[FROZEN] == 0b0,
    Supervisor => haveSmctr() & mstateen0[CTR] == 0b1 & mctrctl[S] == 0b1 & sctrstatus[FROZEN] == 0b0,
    Machine    => haveSmctr() & mctrctl[M] == 0b1 & sctrstatus[FROZEN] == 0b0
  }

function get_ctr_cce() -> bits(4) = {
  // CCE holds 0 if the CtrCycleCounter value is less than 4096, otherwise it
  // holds the index of the most significant one bit in the CtrCycleCounter
  // value, minus 12.
  if unsigned(ctr_cycle_counter) < 4096
  then 0b0000
  else {
    cce : nat = 0;
    foreach (i from 26 to 12) {
      if ctr_cycle_counter[i] == bitone & to_bits(4, cce) == 0b0000 then cce = i - 12;
    };
    to_bits(4, cce)
  }
}

function update_ctr(transfer_type : ctr_xfer_type, src_recorded : bool, dst_recorded : bool) -> unit = {
  let src_pc  : xlenbits = if src_recorded then get_arch_pc() else zeros();
  let tgt_pc  : xlenbits = if dst_recorded then get_next_pc() else zeros();
  let ras_emu : bool     = mctrctl[RASEMU] == 0b1;
  let cce     : bits(4)  = get_ctr_cce();
  let ccm     : bits(12) = ctr_cycle_counter[11 .. 0];
  /* Presently model supports cycle counting when not in RAS emulation mode */
  let ccv     : bits(1)  = if ctr_cycle_counter_valid & not(ras_emu) then 0b1 else 0b0;

  /* Transfer type filtering */
  let is_transfer_type_enabled : bool = match transfer_type {
    EXCEPTION                        => mctrctl[EXCINH]     == 0b0 & not(ras_emu),
    INTERRUPT                        => mctrctl[INTRINH]    == 0b0 & not(ras_emu),
    TRAP_RETURN                      => mctrctl[TRETINH]    == 0b0 & not(ras_emu),
    NOT_TAKEN_BRANCH                 => mctrctl[NTBREN]     == 0b1 & not(ras_emu),
    TAKEN_BRANCH                     => mctrctl[TKBRINH]    == 0b0 & not(ras_emu),
    INDIRECT_CALL                    => mctrctl[INDCALLINH] == 0b0 | ras_emu,
    DIRECT_CALL                      => mctrctl[DIRCALLINH] == 0b0 | ras_emu,
    INDIRECT_JUMP_NO_LINKAGE         => mctrctl[INDJMPINH]  == 0b0 & not(ras_emu),
    DIRECT_JUMP_NO_LINKAGE           => mctrctl[DIRJMPINH]  == 0b0 & not(ras_emu),
    COROUTINE_SWAP                   => mctrctl[CORSWAPINH] == 0b0 | ras_emu,
    FUNCTION_RETURN                  => mctrctl[RETINH]     == 0b0 & not(ras_emu),
    OTHER_INDIRECT_JUMP_WITH_LINKAGE => mctrctl[INDLJMPINH] == 0b0 & not(ras_emu),
    OTHER_DIRECT_JUMP_WITH_LINKAGE   => mctrctl[DIRLJMPINH] == 0b0 & not(ras_emu),
  };

  /* In RAS emulation, function returns pop but coroutine swaps pop and then push */
  if ras_emu & (transfer_type == FUNCTION_RETURN | transfer_type == COROUTINE_SWAP) then {
    sctrstatus[WRPTR] = (sctrstatus[WRPTR] - 1) & get_wrptr_mask(sctrdepth);
    ctrsource[unsigned(sctrstatus[WRPTR])] = [ctrsource[unsigned(sctrstatus[WRPTR])] with V = 0b0];
  };

  if is_transfer_type_enabled then {
    cycle_counter_valid = false;
    ctr_cycle_counter = zeros();
    ctrsource[unsigned(sctrstatus[WRPTR])] = Mk_Ctrsource(src_pc[(sizeof(xlen) - 1) .. 1] @ 0b1);
    ctrtarget[unsigned(sctrstatus[WRPTR])] = Mk_Ctrtarget(tgt_pc[(sizeof(xlen) - 1) .. 1] @ 0b0);
    ctrdata[unsigned(sctrstatus[WRPTR])]   =
      Mk_Ctrdata(zero_extend(cce @ ccm @ ccv @ 0b00000000000 @ encdec_ctr_xfer_type(transfer_type)));
    sctrstatus[WRPTR]                      = (sctrstatus[WRPTR] + 1) & get_wrptr_mask(sctrdepth);
  }
}

function update_ctr_jal(rd : regidx) -> unit = {
  if   rd == 0b00000 & is_ctr_active(cur_privilege)
  then update_ctr(DIRECT_JUMP_NO_LINKAGE, true, true)
  else if (rd == 0b00001 | rd == 0b00101) & is_ctr_active(cur_privilege)
  then update_ctr(DIRECT_CALL, true, true)
  else if is_ctr_active(cur_privilege)
  then update_ctr(OTHER_DIRECT_JUMP_WITH_LINKAGE, true, true);
}

function update_ctr_jalr(rs1 : regidx, rd : regidx) -> unit = {
  if   ((rs1 != 0b00101 & rd == 0b00001) | (rs1 != 0b00001 & rd == 0b00101)) & is_ctr_active(cur_privilege)
  then update_ctr(INDIRECT_CALL, true, true)
  else if (rs1 != 0b00101 & rs1 != 0b00001 & rd == 0b00000) & is_ctr_active(cur_privilege)
  then update_ctr(INDIRECT_JUMP_NO_LINKAGE, true, true)
  else if ((rs1 == 0b00001 & rd == 0b00101) | (rs1 == 0b00101 & rd == 0b00001)) & is_ctr_active(cur_privilege)
  then update_ctr(COROUTINE_SWAP, true, true)
  else if ((rs1 == 0b00001 | rs1 == 0b00101) & rd != 0b00101 & rd != 0b00001) & is_ctr_active(cur_privilege)
  then update_ctr(FUNCTION_RETURN, true, true)
  else if is_ctr_active(cur_privilege)
  then update_ctr(OTHER_INDIRECT_JUMP_WITH_LINKAGE, true, true);
}

function update_ctr_conditional(taken : bool) -> unit = {
  if   taken & is_ctr_active(cur_privilege)
  then update_ctr(TAKEN_BRANCH, true, true)
  else if is_ctr_active(cur_privilege)
  then update_ctr(NOT_TAKEN_BRANCH, true, true);
}

function update_ctr_traps(intr : bool, c : exc_code, del_priv : Privilege) -> unit = {
  /* A breakpoint exception that traps to M-mode or S-mode with sctrctl.BPFRZ=1
   * sets FROZEN. The breakpoint exception itself is not recorded
   * A local counter overflow interrupt (LCOFI) that traps to M-mode or S-mode
   * with sctrctl.LCOFIFRZ=1 sets FROZEN. The LCOFI trap itself is not recorded.
   */
  if (not(intr) & exceptionType_to_bits(E_Breakpoint()) == c) |
     (intr      & interruptType_to_bits(I_L_LCOFI) == c)
  then sctrstatus[FROZEN] = mctrctl[BPFRZ];

  let is_src_ctr_enabled : bool     = is_ctr_active(cur_privilege);
  let is_dst_ctr_enabled : bool     = is_ctr_active(del_priv);
  let transfer_type : ctr_xfer_type = if intr then INTERRUPT else EXCEPTION;

  let effective_xte : bool = match  (cur_privilege, del_priv) {
    (User,       Supervisor) => mctrctl[STE] == 0b1,
    (User,       Machine)    => mctrctl[STE] == 0b1 & mctrctl[MTE] == 0b1,
    (Supervisor, Machine)    => mctrctl[MTE] == 0b1,
    (_, _)                   => false
  };

  /* Traps between enabled privilege modes are recorded as normal.
   * Traps from a disabled privilege mode to an enabled privilege mode
   * are partially recorded, such that the ctrsource.PC is 0. Traps from
   * an enabled mode to a disabled mode, known as external traps, are
   * recorded with ctrtarget.PC as 0 if the effective xTE bit is 1
   */
  if   is_src_ctr_enabled & is_dst_ctr_enabled
  then update_ctr(transfer_type, true, true)
  else if not(is_src_ctr_enabled) & is_dst_ctr_enabled
  then update_ctr(transfer_type, false, true)
  else if is_src_ctr_enabled & not(is_dst_ctr_enabled) & effective_xte
  then update_ctr(transfer_type, true, false)
}

function update_ctr_trap_return(prev_priv : Privilege) -> unit = {
  let is_src_ctr_enabled : bool     = is_ctr_active(prev_priv);
  let is_dst_ctr_enabled : bool     = is_ctr_active(cur_privilege);

  /* Trap returns between enabled privilege modes are recorded
   * as normal. Trap returns from an enabled mode back to a disabled mode are
   * partially recorded, such that ctrtarget.PC is 0. Trap returns from a
   * disabled mode to an enabled mode are not recorded.
   */
  if   is_src_ctr_enabled & is_dst_ctr_enabled
  then update_ctr(TRAP_RETURN, true, true)
  else if is_src_ctr_enabled & not(is_dst_ctr_enabled)
  then update_ctr(TRAP_RETURN, true, false)
}
/* model implements a 13-bit cycle counter */
function count_ctr_cycles() -> unit = {
  if is_ctr_active(cur_privilege) then {
    // num_cce_bits is number of implemented CCE bits and ranges from
    // 0 to 4. The ctr_cycle_counter for each CCE width:
    // 0 - 12 bit, 1 - 13 bit, 2 - 15 bit, 3 - 19 bit, 4 - 27 bit
    let ctr_cc_width_mask : bits(27) = match sys_num_cce_bits() {
      0 => zero_extend(ones(12)),
      1 => zero_extend(ones(13)),
      2 => zero_extend(ones(15)),
      3 => zero_extend(ones(19)),
      4 => zero_extend(ones(27)),
      _ => internal_error(__FILE__, __LINE__, "Unexpected CCE")
    };
    ctr_cycle_counter = (ctr_cycle_counter + 1) & ctr_cc_width_mask;
    ctr_cycle_counter_valid = true;
  }
}
