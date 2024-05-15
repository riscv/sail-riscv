/*=======================================================================================*/
/*  This Sail RISC-V architecture model, comprising all files and                        */
/*  directories except where otherwise noted is subject the BSD                          */
/*  two-clause license in the LICENSE file.                                              */
/*                                                                                       */
/*  SPDX-License-Identifier: BSD-2-Clause                                                */
/*=======================================================================================*/

// Cache Block Operations - Zero
//
// Note that the CBOP prefetch instructions are existing base instructions that
// are just defined to be hints, so there is not need to add any code for them
// (since this model has no caches to prefetch into and the encodings already
// exist).

function cbo_zero_enabled(p : Privilege) -> bool = feature_enabled_for_priv(p, menvcfg.CBZE()[0], senvcfg.CBZE()[0])

/* ****************************************************************** */
union clause ast = RISCV_ZICBOZ : (regidx)

mapping clause encdec = RISCV_ZICBOZ(rs1)                if haveZicboz()
  <-> 0b000000000100 @ rs1 @ 0b010 @ 0b00000 @ 0b0001111 if haveZicboz()

mapping clause assembly = RISCV_ZICBOZ(rs1)
  <-> "cbo.zero" ^ spc() ^ "(" ^ opt_spc() ^ reg_name(rs1) ^ opt_spc() ^ ")"

function clause execute(RISCV_ZICBOZ(rs1)) = {
  if cbo_zero_enabled(cur_privilege) then {
    let rs1_val = X(rs1);
    let cache_block_size_exp = plat_cache_block_size_exp();
    let cache_block_size = 2 ^ cache_block_size_exp;

    // Offset from the beginning of the cache block.
    let offset = (rs1_val & ~(zero_extend(ones(cache_block_size_exp)))) - rs1_val;

    // TODO: This may not be correct since CHERI may treat CBO operations
    // differently to normal accesses with respect to bounds checks.
    match ext_data_get_addr(rs1, offset, Write(Data), cache_block_size) {
      Ext_DataAddr_Error(e) => { ext_handle_data_check_error(e); RETIRE_FAIL },
      Ext_DataAddr_OK(vaddr) => {
        // "An implementation may update the bytes in any order and with any granularity
        //  and atomicity, including individual bytes."
        //
        // This implementation does a single atomic write.
        match translateAddr(vaddr, Write(Data)) {
          TR_Failure(e, _) => { handle_mem_exception(vaddr, e); RETIRE_FAIL },
          TR_Address(paddr, _) => {
            let eares : MemoryOpResult(unit) = mem_write_ea(paddr, cache_block_size, false, false, false);
            match (eares) {
              MemException(e) => { handle_mem_exception(vaddr, e); RETIRE_FAIL },
              MemValue(_) => {
                let res : MemoryOpResult(bool) = mem_write_value(paddr, cache_block_size, zeros(), false, false, false);
                match (res) {
                  MemValue(true) => RETIRE_SUCCESS,
                  MemValue(false) => internal_error(__FILE__, __LINE__, "store got false from mem_write_value"),
                  MemException(e) => { handle_mem_exception(vaddr, e); RETIRE_FAIL }
                }
              }
            }
          }
        }
      },
    }
  } else {
    handle_illegal();
    RETIRE_FAIL
  }
}
