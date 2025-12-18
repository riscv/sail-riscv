// =======================================================================================
// This Sail RISC-V architecture model, comprising all files and
// directories except where otherwise noted is subject the BSD
// two-clause license in the LICENSE file.
//
// SPDX-License-Identifier: BSD-2-Clause
// =======================================================================================

private function rvfi_fetch() -> FetchResult = {
  rvfi_inst_data[rvfi_order] = minstret;
  rvfi_pc_data[rvfi_pc_rdata] = zero_extend(get_arch_pc());
  rvfi_inst_data[rvfi_mode] = zero_extend(privLevel_to_bits(cur_privilege));
  rvfi_inst_data[rvfi_ixl] = zero_extend(misa[MXL]);

  // First allow extensions to check pc
  match ext_fetch_check_pc(PC, PC) {
    Some(e) => return F_Ext_Error(e),
    None()  => (),
  };

  // Then check PC alignment
  if   (PC[0] != bitzero | (PC[1] != bitzero & not(currentlyEnabled(Ext_Zca))))
  then return F_Error(E_Fetch_Addr_Align(), PC);

  match translateAddr(Virtaddr(PC), InstructionFetch()) {
    Err(e, _) => return F_Error(e, PC),
    Ok(_, _)  => (),
  };

  let i = rvfi_instruction[rvfi_insn];
  rvfi_inst_data[rvfi_insn]   = zero_extend(i);
  if   (i[1 .. 0] != 0b11)
  then return F_RVC(i[15 .. 0]);

  // fetch PC check for the next instruction granule
  let PC_hi = PC + 2;
  match ext_fetch_check_pc(PC, PC_hi) {
    Some(e) => return F_Ext_Error(e),
    None()  => (),
  };

  match translateAddr(Virtaddr(PC_hi), InstructionFetch()) {
    Err(e, _) => F_Error(e, PC),
    Ok(_, _)  => F_Base(i)
  }
}
