// =======================================================================================
// This Sail RISC-V architecture model, comprising all files and
// directories except where otherwise noted is subject the BSD
// two-clause license in the LICENSE file.
//
// SPDX-License-Identifier: BSD-2-Clause
// =======================================================================================

// Cache Block Operations - Management

function clause currentlyEnabled(Ext_Zicbom) = hartSupports(Ext_Zicbom)

private function cbo_clean_flush_enabled(p : Privilege) -> bool = feature_enabled_for_priv(p, menvcfg[CBCFE][0], senvcfg[CBCFE][0])

// *****************************************************************
union clause instruction = ZICBOM : (cbop_zicbom, regidx)

mapping encdec_cbop : cbop_zicbom <-> bits(12) = {
  CBO_CLEAN <-> 0b000000000001,
  CBO_FLUSH <-> 0b000000000010,
  CBO_INVAL <-> 0b000000000000,
}

$[wavedrom "CBO-OP base CBO _ MISC-MEM"]
mapping clause encdec = ZICBOM(cbop, rs1)
  <-> encdec_cbop(cbop) @ encdec_reg(rs1) @ 0b010 @ 0b00000 @ 0b0001111
  when currentlyEnabled(Ext_Zicbom)

mapping cbop_mnemonic : cbop_zicbom <-> string = {
  CBO_CLEAN <-> "cbo.clean",
  CBO_FLUSH <-> "cbo.flush",
  CBO_INVAL <-> "cbo.inval"
}

mapping clause assembly = ZICBOM(cbop, rs1)
  <-> cbop_mnemonic(cbop) ^ spc() ^ "(" ^ opt_spc() ^ reg_name(rs1) ^ opt_spc() ^ ")"

// CBIE from xenvcfg
private enum cbie = {CBIE_ILLEGAL, CBIE_EXEC_FLUSH, CBIE_EXEC_INVAL}

private mapping encdec_cbie : cbie <-> bits(2) = {
  CBIE_ILLEGAL    <-> 0b00,
  CBIE_EXEC_FLUSH <-> 0b01,
  CBIE_EXEC_INVAL <-> 0b11,
  backwards 0b10   => internal_error(__FILE__, __LINE__, "reserved CBIE"),
}

// Illegal-Virtual will be needed by the hypervisor mode, but is currently unused.
private enum checked_cbop = {CBOP_ILLEGAL, CBOP_ILLEGAL_VIRTUAL, CBOP_INVAL_FLUSH, CBOP_INVAL_INVAL}

// Select the cbop to perform based on the privilege.
private function cbop_priv_check(p: Privilege) -> checked_cbop = {
  let mCBIE : cbie = encdec_cbie(menvcfg[CBIE]);
  // TODO: check henvcfg after hypervisor is implemented
  let sCBIE : cbie = if   currentlyEnabled(Ext_S)
                     then encdec_cbie(senvcfg[CBIE])
                     else encdec_cbie(menvcfg[CBIE]);
  match (p, mCBIE, sCBIE) {
    (VirtualUser, _, _)       => internal_error(__FILE__, __LINE__, "Hypervisor extension not supported"),
    (VirtualSupervisor, _, _) => internal_error(__FILE__, __LINE__, "Hypervisor extension not supported"),
    (Machine, _,               _              ) => CBOP_INVAL_INVAL,
    (_,       CBIE_ILLEGAL,    _              ) => CBOP_ILLEGAL,      // (priv_mode != M) && mCBIE == 00
    (User,    _,               CBIE_ILLEGAL   ) => CBOP_ILLEGAL,      // (priv_mode == U) && sCBIE == 00
    (_,       CBIE_EXEC_FLUSH, _              ) => CBOP_INVAL_FLUSH,  // (priv_mode != M) && mCBIE == 01
    (User,    _,               CBIE_EXEC_FLUSH) => CBOP_INVAL_FLUSH,  // (priv_mode == U) && sCBIE == 01
    _                                           => CBOP_INVAL_INVAL,
  }
}

private function process_clean_inval(rs1 : regidx, cbop : cbop_zicbom) -> ExecutionResult = {
  let rs1_val = X(rs1);
  let cache_block_size = 2 ^ plat_cache_block_size_exp;
  let access : MemoryAccessType(mem_payload) = CacheAccess(CB_manage(cbop));

  // Offset from rs1 to the beginning of the cache block. This is 0 if rs1
  // is aligned to the cache block, or negative if rs1 is misaligned.
  let negative_offset = (rs1_val & ~(zero_extend(ones(plat_cache_block_size_exp)))) - rs1_val;

  // TODO: This is incorrect since CHERI only requires at least one byte
  // to be in bounds here, whereas `ext_data_get_addr()` checks that all bytes
  // are in bounds. We will need to add a new function, parameter or access type.
  match ext_data_get_addr(rs1, negative_offset, access, cache_block_size) {
    Ext_DataAddr_Error(e) => Ext_DataAddr_Check_Failure(e),
    Ext_DataAddr_OK(vaddr) => {
      // vaddr is the aligned address, but errors report the address that
      // was encoded in the instruction. We subtract the negative offset
      // (add the positive offset) to get it. Normally this will be
      // equal to rs1, but pointer masking can change that.
      let vaddr_for_error = vaddr - negative_offset;
      match translateAddr(vaddr, access) {
        Ok(paddr, _) => {
          // Check PMA and PMP access controls.
          let ep = effectivePrivilege(access, mstatus, cur_privilege);
          match phys_access_check(access, ep, paddr, cache_block_size, false) {
            Some(e) => Memory_Exception(vaddr_for_error, e),
            // If there is no error, the model has no caches so there's no
            // more action required.
            None()  => RETIRE_SUCCESS
          }
        },
        Err(e, _) => Memory_Exception(vaddr_for_error, e),
      }
    }
  }
}

function clause execute ZICBOM(CBO_CLEAN, rs1) =
  if   cbo_clean_flush_enabled(cur_privilege)
  then process_clean_inval(rs1, CBO_CLEAN)
  else Illegal_Instruction()

function clause execute ZICBOM(CBO_FLUSH, rs1) =
  if   cbo_clean_flush_enabled(cur_privilege)
  then process_clean_inval(rs1, CBO_FLUSH)
  else Illegal_Instruction()

function clause execute ZICBOM(CBO_INVAL, rs1) =
  match cbop_priv_check(cur_privilege) {
    CBOP_ILLEGAL         => Illegal_Instruction(),
    CBOP_ILLEGAL_VIRTUAL => internal_error(__FILE__, __LINE__, "unimplemented"),
    CBOP_INVAL_INVAL     => process_clean_inval(rs1, CBO_INVAL),
    CBOP_INVAL_FLUSH     => process_clean_inval(rs1, CBO_FLUSH),
  }
