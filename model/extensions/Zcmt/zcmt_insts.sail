// =======================================================================================
// This Sail RISC-V architecture model, comprising all files and
// directories except where otherwise noted is subject the BSD
// two-clause license in the LICENSE file.
//
// SPDX-License-Identifier: BSD-2-Clause
// =======================================================================================

union clause instruction = CM_JALT : (bits(8))

mapping clause encdec_compressed = CM_JALT(index)
  <-> 0b101 @ 0b000 @ index : bits(8) @ 0b10
  when currentlyEnabled(Ext_Zcmt) & 32 <= unsigned(index)

// NOTE: Currently, neither cm.jalt nor cm.jt call ext_data_get_addr().

function clause execute (CM_JALT(index)) = {
  let base  : xlenbits = jvt[base] @ 0b000000;
  let index : xlenbits = zero_extend(index);
  if jvt[mode] == 0b000000 then {
    let table_address = base + (index << (if xlen == 32 then 2 else 3));
    // TODO: The jump table entries follow data endianness, not instruction fetch endianness.
    // This is currently using InstructionFetch() which is always little-endian.
    // This may need to be revisited if big-endian support is added (same applies to cm.jt).
    match vmem_read_addr(Virtaddr(table_address), xlen_bytes, InstructionFetch(), false, false, false) {
      Err(e)     => return e,
      Ok(target) => {
        let link_address = get_next_pc();
        match jump_to([target with 0 = bitzero]) {
          Retire_Success() => { X(ra) = link_address; RETIRE_SUCCESS },
          failure          => failure,
        }
      }
    }
  } else {
    Illegal_Instruction()
  }
}

mapping clause assembly = CM_JALT(index)
   <-> "cm.jalt" ^ spc() ^ hex_bits_8(index)

union clause instruction = CM_JT : (bits(8))

mapping clause encdec_compressed = CM_JT(index)
  <-> 0b101 @ 0b000 @ index : bits(8) @ 0b10
  when currentlyEnabled(Ext_Zcmt) & 32 > unsigned(index)

function clause execute (CM_JT(index)) = {
  let base  : xlenbits = jvt[base] @ 0b000000;
  let index : xlenbits = zero_extend(index);
  if jvt[mode] == 0b000000 then {
    let table_address = base + (index << (if xlen == 32 then 2 else 3));
    match vmem_read_addr(Virtaddr(table_address), xlen_bytes, InstructionFetch(), false, false, false) {
      Err(e)     => return e,
      Ok(target) => jump_to([target with 0 = bitzero]),
    }
  } else {
    Illegal_Instruction()
  }
}

mapping clause assembly = CM_JT(index)
  <-> "cm.jt" ^ spc() ^ hex_bits_8(index)
