function fetch() -> FetchResult =
  /* check for legal PC */
  if   (PC[0] != 0b0 | (PC[1] != 0b0 & (~ (haveRVC()))))
  then F_Error(E_Fetch_Addr_Align, PC)
  else {
    let i = rvfi_instruction.rvfi_insn();
    rvfi_exec->rvfi_order()    = minstret;
    rvfi_exec->rvfi_pc_rdata() = PC;
    rvfi_exec->rvfi_insn()     = sail_zero_extend(i,64);

    /* TODO: should we write these even if they're not really registers? */
    rvfi_exec->rvfi_rs1_data() = X(i[19 .. 15]);
    rvfi_exec->rvfi_rs2_data() = X(i[24 .. 20]);
    rvfi_exec->rvfi_rs1_addr() = sail_zero_extend(i[19 .. 15],8);
    rvfi_exec->rvfi_rs2_addr() = sail_zero_extend(i[24 .. 20],8);

    if   (i[1 .. 0] == 0b11)
    then F_Base(i)
    else F_RVC(i[15 .. 0])
  }

