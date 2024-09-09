/*=======================================================================================*/
/*  This Sail RISC-V architecture model, comprising all files and                        */
/*  directories except where otherwise noted is subject the BSD                          */
/*  two-clause license in the LICENSE file.                                              */
/*                                                                                       */
/*  SPDX-License-Identifier: BSD-2-Clause                                                */
/*=======================================================================================*/

// Cache Block Operations - Prefetch

enum clause extension = Ext_Zicbop
function clause extensionEnabled(Ext_Zicbop) = sys_enable_zicbop()

function prefetch_i_enabled(p : Privilege) -> bool = feature_enabled_for_priv(p, menvcfg[CBCFE][0], senvcfg[CBCFE][0])
function prefetch_r_enabled(p : Privilege) -> bool = feature_enabled_for_priv(p, menvcfg[CBCFE][0], senvcfg[CBCFE][0])
function prefetch_w_enabled(p : Privilege) -> bool = feature_enabled_for_priv(p, menvcfg[CBCFE][0], senvcfg[CBCFE][0])

/* ****************************************************************** */
union clause ast = RISCV_ZICBOP : (cbop_zicbop, regidx, imm12)

mapping encdec_cbop_zicbop : cbop_zicbop <-> bits(5) = {
  PREFETCH_I <-> 0b00000,
  PREFETCH_R <-> 0b00001,
  PREFETCH_W <-> 0b00011,
}

mapping clause encdec = RISCV_ZICBOP(cbop, rs1, offset @ 0b00000)           if extensionEnabled(Ext_Zicbop)
  <-> offset @ encdec_cbop_zicbop(cbop) @ rs1 @ 0b110 @ 0b00000 @ 0b0001101 if extensionEnabled(Ext_Zicbop)

mapping prefetch_mnemonic : cbop_zicbop <-> string = {
  PREFETCH_I <-> "prefetch.i",
  PREFETCH_R <-> "prefetch.r",
  PREFETCH_W <-> "prefetch.w"
}

mapping clause assembly = RISCV_ZICBOP(cbop, rs1, offset)
  <-> prefetch_mnemonic(cbop) ^ spc() ^ hex_bits_12(offset) ^ "(" ^ opt_spc() ^ reg_name(rs1) ^ opt_spc() ^ ")"

val process_prefetch : (regidx, imm12, AccessType(ext_access_type)) -> Retired
function process_prefetch(rs1, offset, ac) = {
  let offset_val = X(rs1) + zero_extend(offset);
  let cache_block_size_exp = plat_cache_block_size_exp();
  let cache_block_size = 2 ^ cache_block_size_exp;

  // Offset from offset_val to the beginning of the cache block. This is 0 if offset_val
  // is aligned to the cache block, or negative if offset_val is misaligned.
  let offset = (offset_val & ~(zero_extend(ones(cache_block_size_exp)))) - offset_val;

  match ext_data_get_addr(rs1, offset, ac, cache_block_size) {
    Ext_DataAddr_Error(e) => { ext_handle_data_check_error(e); RETIRE_FAIL },
    Ext_DataAddr_OK(vaddr) => {

      // "An implementation may opt to cache a copy of the cache block in a cache
		  //  accessed by an instruction fetch in order to improve memory access latency,
		  //  but this behavior is not required."
      //
      // This implementation do nothing.
      match translateAddr(vaddr, ac) {
        TR_Failure(e, _) => { handle_mem_exception(vaddr, e); RETIRE_FAIL },
        TR_Address(paddr, _) => RETIRE_SUCCESS
      }
    },
  }
}

function clause execute(RISCV_ZICBOP(cbop, rs1, offset)) =
  match cbop {
    PREFETCH_I if prefetch_i_enabled(cur_privilege) =>
      process_prefetch(rs1, offset, Execute(Data)),
    PREFETCH_R if prefetch_r_enabled(cur_privilege) =>
      process_prefetch(rs1, offset, Read(Data)),
    PREFETCH_W if prefetch_w_enabled(cur_privilege) =>
      process_prefetch(rs1, offset, Write(Data)),
    _ => {
      handle_illegal();
      RETIRE_FAIL
    },
  }
