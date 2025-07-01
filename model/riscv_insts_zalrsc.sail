/*=======================================================================================*/
/*  This Sail RISC-V architecture model, comprising all files and                        */
/*  directories except where otherwise noted is subject the BSD                          */
/*  two-clause license in the LICENSE file.                                              */
/*                                                                                       */
/*  SPDX-License-Identifier: BSD-2-Clause                                                */
/*=======================================================================================*/

function clause currentlyEnabled(Ext_Zalrsc) = hartSupports(Ext_Zalrsc) | currentlyEnabled(Ext_A)

// Zalrsc defines LR/SC for word and double
function lrsc_width_valid(size : word_width) -> bool = {
  match size {
    4 => true,
    8 => xlen >= 64,
    _ => false,
  }
}

/* ****************************************************************** */

union clause ast = LOADRES : (bool, bool, regidx, word_width, regidx)

mapping clause encdec = LOADRES(aq, rl, rs1, size, rd)
  <-> 0b00010 @ bool_bits(aq) @ bool_bits(rl) @ 0b00000 @ encdec_reg(rs1) @ 0b0 @ size_enc(size) @ encdec_reg(rd) @ 0b0101111
  when currentlyEnabled(Ext_Zalrsc) & lrsc_width_valid(size)

/* We could set load-reservations on physical or virtual addresses.
 * However most chips (especially multi-core) will use physical addresses.
 * Additionally, matching on physical addresses allows as many SC's to
 * succeed as the spec allows. This simplifies verification against real chips
 * since you can force spurious failures from a DUT into the Sail model and
 * then compare the result (a kind of one-way waiver). Using virtual addresses
 * requires cancelling the reservation in some additional places, e.g. xRET, and
 * that will break comparison with a DUT that doesn't require cancellation there.
 */

function clause execute(LOADRES(aq, rl, rs1, width, rd)) = {
  // This is checked during decoding.
  assert(width <= xlen_bytes);

  match vmem_read(rs1, zeros(), width, Read(Data), aq, aq & rl, true) {
    Ok(data) => {
      X(rd) = sign_extend(data);
      RETIRE_SUCCESS
    },
    Err(e) => e,
  }
}

mapping clause assembly = LOADRES(aq, rl, rs1, size, rd)
  <-> "lr." ^ size_mnemonic(size) ^ maybe_aqrl(aq, rl) ^ spc() ^ reg_name(rd) ^ sep() ^ "(" ^ reg_name(rs1) ^ ")"

/* ****************************************************************** */

union clause ast = STORECON : (bool, bool, regidx, regidx, word_width, regidx)

mapping clause encdec = STORECON(aq, rl, rs2, rs1, size, rd)
  <-> 0b00011 @ bool_bits(aq) @ bool_bits(rl) @ encdec_reg(rs2) @ encdec_reg(rs1) @ 0b0 @ size_enc(size) @ encdec_reg(rd) @ 0b0101111
  when currentlyEnabled(Ext_Zalrsc) & lrsc_width_valid(size)

/* NOTE: Currently, we only EA if address translation is successful. This may need revisiting. */
function clause execute (STORECON(aq, rl, rs2, rs1, width, rd)) = {
  // This is checked during decoding.
  assert(width <= xlen_bytes);

  /* normal non-rmem case
   * RMEM: SC is allowed to succeed (but might fail later)
   */
  let data = X(rs2)[width * 8 - 1 .. 0];
  match vmem_write(rs1, zeros(), width, data, Write(Data), aq & rl, rl, true) {
    Ok(b) => {
      X(rd) = zero_extend(bool_bits(~(b)));
      cancel_reservation();
      RETIRE_SUCCESS
    },
    Err(e) => e,
  }
}

mapping clause assembly = STORECON(aq, rl, rs2, rs1, size, rd)
  <-> "sc." ^ size_mnemonic(size) ^ maybe_aqrl(aq, rl) ^ spc() ^ reg_name(rd) ^ sep() ^ reg_name(rs2) ^ sep() ^ "(" ^ reg_name(rs1) ^ ")"
