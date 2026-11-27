// =======================================================================================
// This Sail RISC-V architecture model, comprising all files and
// directories except where otherwise noted is subject the BSD
// two-clause license in the LICENSE file.
//
// SPDX-License-Identifier: BSD-2-Clause
// =======================================================================================

// Zalasr: Atomic Load-Acquire and Store-Release Instructions, v1.0.

function clause currentlyEnabled(Ext_Zalasr) = hartSupports(Ext_Zalasr)

// The spec requires Zalasr accesses to be naturally aligned unless
// all accessed bytes lie within the same misaligned atomicity granule
// (in which case the access is performed atomically), and otherwise
// to raise an address-misaligned or access-fault exception.  These
// instructions use the `Load(Data)` / `Store(Data)` access types, but
// the memory layer identifies them by their aq/rl annotations and
// handles misalignment as for AMOs: the `amo` misaligned exception
// settings are used (see `plat_misaligned_exception` and
// `pma_misaligned_exception`), and the access is never split.

// *****************************************************************
// Load-Acquire: l{b,h,w,d}.{aq,aqrl}
//
// The aq bit is required; encodings with aq=0 are RESERVED and are
// not decoded. ld.{aq,aqrl} is RV64-only.

union clause instruction = LOAD_ACQUIRE : (bool, regidx, word_width, regidx)

$[wavedrom "LOAD_ACQUIRE aq rl _ addr _ width dest AMO"]
mapping clause encdec = LOAD_ACQUIRE(rl, rs1, width, rd)
  <-> 0b00110 @ 0b1 @ bool_bit(rl) @ 0b00000 @ encdec_reg(rs1) @ 0b0 @ width_enc(width) @ encdec_reg(rd) @ 0b0101111
  when currentlyEnabled(Ext_Zalasr) & width <= xlen_bytes

function clause execute LOAD_ACQUIRE(rl, rs1, width, rd) = {
  // This is checked during decoding.
  assert(width <= xlen_bytes);

  // Always acquire-RCsc; additionally release-RCsc if rl is set.
  match vmem_read(rs1, zeros(), width, Load(Data), true, rl, false) {
    Ok(data) => {
      // Zalasr loads always sign-extend.
      X(rd) = sign_extend(data);
      RETIRE_SUCCESS
    },
    Err(e) => e,
  }
}

mapping clause assembly = LOAD_ACQUIRE(rl, rs1, width, rd)
  <-> "l" ^ width_mnemonic(width) ^ maybe_aqrl(true, rl) ^ spc() ^ reg_name(rd) ^ sep() ^ "(" ^ opt_spc() ^ reg_name(rs1) ^ opt_spc() ^ ")"

// *****************************************************************
// Store-Release: s{b,h,w,d}.{rl,aqrl}
//
// The rl bit is required; encodings with rl=0 are RESERVED and are
// not decoded. sd.{rl,aqrl} is RV64-only.

union clause instruction = STORE_RELEASE : (bool, regidx, regidx, word_width)

$[wavedrom "STORE_RELEASE aq rl src addr _ width _ AMO"]
mapping clause encdec = STORE_RELEASE(aq, rs2, rs1, width)
  <-> 0b00111 @ bool_bit(aq) @ 0b1 @ encdec_reg(rs2) @ encdec_reg(rs1) @ 0b0 @ width_enc(width) @ 0b00000 @ 0b0101111
  when currentlyEnabled(Ext_Zalasr) & width <= xlen_bytes

function clause execute STORE_RELEASE(aq, rs2, rs1, width) = {
  // This is checked during decoding.
  assert(width <= xlen_bytes);

  // FIXME: the read of `rs2` should not be done before the
  // `mem_write_ea` of the effective address.
  // See https://github.com/riscv/sail-riscv/issues/1761.

  // Only the low bits of rs2 are stored.
  let data = X(rs2)[width * 8 - 1 .. 0];
  // Always release-RCsc; additionally acquire-RCsc if aq is set.
  match vmem_write(rs1, zeros(), width, data, Store(Data), aq, true, false) {
    Ok(_)  => RETIRE_SUCCESS,
    Err(e) => e,
  }
}

mapping clause assembly = STORE_RELEASE(aq, rs2, rs1, width)
  <-> "s" ^ width_mnemonic(width) ^ maybe_aqrl(aq, true) ^ spc() ^ reg_name(rs2) ^ sep() ^ "(" ^ opt_spc() ^ reg_name(rs1) ^ opt_spc() ^ ")"
