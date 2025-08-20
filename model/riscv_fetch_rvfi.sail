/*=======================================================================================*/
/*  This Sail RISC-V architecture model, comprising all files and                        */
/*  directories except where otherwise noted is subject the BSD                          */
/*  two-clause license in the LICENSE file.                                              */
/*                                                                                       */
/*  SPDX-License-Identifier: BSD-2-Clause                                                */
/*=======================================================================================*/

function rvfi_fetch() -> FetchResult = {
  rvfi_set_pc_data_rdata(zero_extend(get_arch_pc()));
  rvfi_set_inst_data_order(minstret);
  rvfi_set_inst_data_mode(zero_extend(privLevel_to_bits(cur_privilege)));
  rvfi_set_inst_data_ixl(zero_extend(misa[MXL]));

  /* First allow extensions to check pc */
  match ext_fetch_check_pc(PC, PC) {
    Ext_FetchAddr_Error(e)   => F_Ext_Error(e),
    Ext_FetchAddr_OK(use_pc) => {
      /* then check PC alignment */
      let use_pc_bits = bits_of(use_pc);
      if   (use_pc_bits[0] != bitzero | (use_pc_bits[1] != bitzero & not(currentlyEnabled(Ext_Zca))))
      then F_Error(E_Fetch_Addr_Align(), PC)
      else match translateAddr(use_pc, InstructionFetch()) {
        Err(e, _) => F_Error(e, PC),
        Ok(_, _)  => {
          let i = rvfi_get_insn();
          rvfi_set_inst_data_insn(zero_extend(i));
          if   (i[1 .. 0] != 0b11)
          then F_RVC(i[15 .. 0])
          else {
            /* fetch PC check for the next instruction granule */
            let PC_hi = PC + 2;
            match ext_fetch_check_pc(PC, PC_hi) {
              Ext_FetchAddr_Error(e)      => F_Ext_Error(e),
              Ext_FetchAddr_OK(use_pc_hi) =>
                match translateAddr(use_pc_hi, InstructionFetch()) {
                  Err(e, _) => F_Error(e, PC),
                  Ok(_, _)  => F_Base(i)
              }
            }
          }
        }
      }
    }
  }
}
