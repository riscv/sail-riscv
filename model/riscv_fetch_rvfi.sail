function fetch() -> FetchResult = {
  rvfi_exec->rvfi_order()    = minstret;
  rvfi_exec->rvfi_pc_rdata() = EXTZ(get_arch_pc());

  /* First allow extensions to check pc */
  match ext_fetch_check_pc(PC, PC) {
    Ext_FetchAddr_Error(e)   => F_Ext_Error(e),
    Ext_FetchAddr_OK(use_pc) => {
      /* then check PC alignment */
      if   (use_pc[0] != bitzero | (use_pc[1] != bitzero & (~ (haveRVC()))))
      then F_Error(E_Fetch_Addr_Align(), PC)
      else match translateAddr(use_pc, Execute()) {
        TR_Failure(e, _) => F_Error(e, PC),
        TR_Address(_, _) => {
          let i = rvfi_instruction.rvfi_insn();
          rvfi_exec->rvfi_insn()     = EXTZ(i);
          /* TODO: should we write these even if they're not really registers? */
          rvfi_exec->rvfi_rs1_data() = EXTZ(X(i[19 .. 15]));
          rvfi_exec->rvfi_rs2_data() = EXTZ(X(i[24 .. 20]));
          rvfi_exec->rvfi_rs1_addr() = sail_zero_extend(i[19 .. 15],8);
          rvfi_exec->rvfi_rs2_addr() = sail_zero_extend(i[24 .. 20],8);
          if   (i[1 .. 0] != 0b11)
          then F_RVC(i[15 .. 0])
          else {
            /* fetch PC check for the next instruction granule */
            PC_hi : xlenbits = PC + 2;
            match ext_fetch_check_pc(PC, PC_hi) {
              Ext_FetchAddr_Error(e)      => F_Ext_Error(e),
              Ext_FetchAddr_OK(use_pc_hi) =>
                match translateAddr(use_pc_hi, Execute()) {
                  TR_Failure(e, _) => F_Error(e, PC),
                  TR_Address(_, _) => F_Base(i)
              }
            }
          }
        }
      }
    }
  }
}
