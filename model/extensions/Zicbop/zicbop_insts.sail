// =======================================================================================
//   This Sail RISC-V architecture model, comprising all files and
//   directories except where otherwise noted is subject the BSD
//   two-clause license in the LICENSE file.
//
//   SPDX-License-Identifier: BSD-2-Clause
// =======================================================================================

// Cache Block Operations - Prefetch

function clause currentlyEnabled(Ext_Zicbop) = hartSupports(Ext_Zicbop)

// ******************************************************************
union clause instruction = ZICBOP : (cbop_zicbop, regidx, bits(12))

mapping encdec_cbop_zicbop : cbop_zicbop <-> bits(5) = {
  PREFETCH_I <-> 0b00000,
  PREFETCH_R <-> 0b00001,
  PREFETCH_W <-> 0b00011,
}

$[wavedrom "offset[11:5] PREFETCH-OP base ORI offset[4:0] OP-IMM"]
mapping clause encdec = ZICBOP(cbop, rs1, offset11_5 @ 0b00000)
  <-> offset11_5 @ encdec_cbop_zicbop(cbop) @ encdec_reg(rs1) @ 0b110 @ 0b00000 @ 0b0010011
  when currentlyEnabled(Ext_Zicbop)

mapping prefetch_mnemonic : cbop_zicbop <-> string = {
  PREFETCH_I <-> "prefetch.i",
  PREFETCH_R <-> "prefetch.r",
  PREFETCH_W <-> "prefetch.w"
}

mapping clause assembly = ZICBOP(cbop, rs1, offset)
  <-> prefetch_mnemonic(cbop) ^ spc() ^ hex_bits_12(offset) ^ "(" ^ opt_spc() ^ reg_name(rs1) ^ opt_spc() ^ ")"

function clause execute ZICBOP(cbop, rs1, offset) = {
  let rs1_val = X(rs1);
  let cache_block_size = 2 ^ plat_cache_block_size_exp;
  let addr = rs1_val + sign_extend(offset);
  let cache_block_addr = addr & ~(zero_extend(ones(plat_cache_block_size_exp)));
  let offset = cache_block_addr - rs1_val;
  let access : MemoryAccessType(mem_payload) = CacheAccess(CB_prefetch(cbop));

  // TODO: This is incorrect since CHERI only requires at least one byte
  // to be in bounds here, whereas `ext_data_get_addr()` checks that all bytes
  // are in bounds. We will need to add a new function, parameter or access type.
  match ext_data_get_addr(rs1, offset, access, cache_block_size) {
    Ext_DataAddr_Error(_) => (), // No access to cache; no-op.

    Ext_DataAddr_OK(vaddr) => match translateAddr(vaddr, access) {
      Ok(paddr, _) => {
          // Check PMA and PMP access controls.
          let ep = effectivePrivilege(access, mstatus, cur_privilege);
          match phys_access_check(access, ep, paddr, cache_block_size, false) {
            Some(_e) => (), // No access to cache; no-op.
            None()   => (), // The model has no caches so there's no action required.
          }
      },
      Err(_) => (), // No access to cache; no-op.
    }
  };

  RETIRE_SUCCESS
}
