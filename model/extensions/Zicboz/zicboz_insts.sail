// =======================================================================================
// This Sail RISC-V architecture model, comprising all files and
// directories except where otherwise noted is subject the BSD
// two-clause license in the LICENSE file.
//
// SPDX-License-Identifier: BSD-2-Clause
// =======================================================================================

// Cache Block Operations - Zero

function clause currentlyEnabled(Ext_Zicboz) = hartSupports(Ext_Zicboz)

function cbo_zero_enabled(p : Privilege) -> bool = feature_enabled_for_priv(p, menvcfg[CBZE][0], senvcfg[CBZE][0])

// *****************************************************************
union clause instruction = ZICBOZ : (regidx)

$[wavedrom "CBO.ZERO base CBO _ MISC-MEM"]
mapping clause encdec = ZICBOZ(rs1)
  <-> 0b000000000100 @ encdec_reg(rs1) @ 0b010 @ 0b00000 @ 0b0001111
  when currentlyEnabled(Ext_Zicboz)

mapping clause assembly = ZICBOZ(rs1)
  <-> "cbo.zero" ^ spc() ^ "(" ^ opt_spc() ^ reg_name(rs1) ^ opt_spc() ^ ")"

function clause execute ZICBOZ(rs1) = {
  if cbo_zero_enabled(cur_privilege) then {
    let rs1_val = X(rs1);
    let cache_block_size = 2 ^ plat_cache_block_size_exp;

    // Offset from rs1 to the beginning of the cache block. This is 0 if rs1
    // is aligned to the cache block, or negative if rs1 is misaligned.
    let negative_offset = (rs1_val & ~(zero_extend(ones(plat_cache_block_size_exp)))) - rs1_val;

    match ext_data_get_addr(rs1, negative_offset, Store(Data), cache_block_size) {
      Ext_DataAddr_Error(e) => Ext_DataAddr_Check_Failure(e),
      Ext_DataAddr_OK(vaddr) => {
        let vaddr = transform_effective_address(vaddr, Store(Data));
        // "An implementation may update the bytes in any order and with any granularity
        //  and atomicity, including individual bytes."
        //
        // This implementation does a single atomic write.
        match translateAddr(vaddr, Store(Data)) {
          // vaddr is the aligned address, but errors report the address that
          // was encoded in the instruction. We subtract the negative offset
          // (add the positive offset) to get it. Normally this will be
          // equal to rs1, but pointer masking can change that.
          Err(e, _) => Memory_Exception(vaddr - negative_offset, e),
          Ok(paddr, _) => {
            match mem_write_ea(paddr, cache_block_size, false, false, false) {
              Err(e) => Memory_Exception(vaddr - negative_offset, e),
              Ok(_)  => {
                match mem_write_value(paddr, cache_block_size, zeros(), false, false, false) {
                  Ok(true)  => RETIRE_SUCCESS,
                  Ok(false) => internal_error(__FILE__, __LINE__, "store got false from mem_write_value"),
                  Err(e)    => Memory_Exception(vaddr - negative_offset, e)
                }
              }
            }
          }
        }
      },
    }
  } else {
    Illegal_Instruction()
  }
}
