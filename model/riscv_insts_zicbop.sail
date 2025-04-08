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

/* ****************************************************************** */
union clause ast = RISCV_ZICBOP : (cbop_zicbop, regidx, imm12)

mapping encdec_cbop_zicbop : cbop_zicbop <-> bits(5) = {
  PREFETCH_I <-> 0b00000,
  PREFETCH_R <-> 0b00001,
  PREFETCH_W <-> 0b00011,
}

mapping clause encdec = RISCV_ZICBOP(cbop, rs1, offset11_5 @ 0b00000)
  <-> offset11_5 @ encdec_cbop_zicbop(cbop) @ encdec_reg(rs1) @ 0b110 @ 0b00000 @ 0b0010011
  when extensionEnabled(Ext_Zicbop)

mapping prefetch_mnemonic : cbop_zicbop <-> string = {
  PREFETCH_I <-> "prefetch.i",
  PREFETCH_R <-> "prefetch.r",
  PREFETCH_W <-> "prefetch.w"
}

mapping clause assembly = RISCV_ZICBOP(cbop, rs1, offset)
  <-> prefetch_mnemonic(cbop) ^ spc() ^ hex_bits_12(offset) ^ "(" ^ opt_spc() ^ reg_name(rs1) ^ opt_spc() ^ ")"

val process_prefetch : (regidx, imm12, AccessType(ext_access_type)) -> Retired
function process_prefetch(rs1, offset, ac) = {
  let offset_val = X(rs1) + sign_extend(offset);
  let cache_block_size_exp = plat_cache_block_size_exp();
  let cache_block_size = 2 ^ cache_block_size_exp;

  // Offset from offset_val to the beginning of the cache block. This is 0 if offset_val
  // is aligned to the cache block, or negative if offset_val is misaligned.
  let offset = (offset_val & ~(zero_extend(ones(cache_block_size_exp)))) - offset_val;

  match ext_data_get_addr(rs1, offset, ac, cache_block_size) {
    Ext_DataAddr_Error(e) => { ext_handle_data_check_error(e); RETIRE_FAIL },
    Ext_DataAddr_OK(vaddr) => RETIRE_SUCCESS
  }
}

function clause execute(RISCV_ZICBOP(cbop, rs1, offset)) =
  process_prefetch(rs1, offset, match cbop {
    PREFETCH_I => Execute(Data),
    PREFETCH_R => Read(Data),
    PREFETCH_W => Write(Data),
  })
