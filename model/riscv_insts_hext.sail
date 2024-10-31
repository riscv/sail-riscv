/*=======================================================================================*/
/*  This Sail RISC-V architecture model, comprising all files and                        */
/*  directories except where otherwise noted is subject the BSD                          */
/*  two-clause license in the LICENSE file.                                              */
/*                                                                                       */
/*  SPDX-License-Identifier: BSD-2-Clause                                                */
/*=======================================================================================*/

union clause ast = HFENCE_VVMA : (regidx, regidx)

mapping clause encdec = HFENCE_VVMA(rs1, rs2)
  <-> 0b0010001 @ rs2 @ rs1 @ 0b000 @ 0b00000 @ 0b1110011

function clause execute HFENCE_VVMA(rs1, rs2) = {
  let addr : option(xlenbits) = if rs1 == 0b00000 then None() else Some(X(rs1));
  let asid : option(xlenbits) = if rs2 == 0b00000 then None() else Some(X(rs2));
  match (cur_privilege, cur_virtualization) {
    (User, V1)       => { handle_virtual_instr(); RETIRE_FAIL },
    (User, V0)       => { handle_illegal(); RETIRE_FAIL },
    (Supervisor, V1) => { handle_virtual_instr(); RETIRE_FAIL },
    (Supervisor, V0) => { flush_TLB(asid, Stage_VS, addr); RETIRE_SUCCESS },
    (Machine, _)     => { flush_TLB(asid, Stage_VS, addr); RETIRE_SUCCESS }
  }
}

mapping clause assembly = HFENCE_VVMA(rs1, rs2)
  <-> "hfence.vvma" ^ spc() ^ reg_name(rs1) ^ sep() ^ reg_name(rs2)

/* ****************************************************************** */

union clause ast = HFENCE_GVMA : (regidx, regidx)

mapping clause encdec = HFENCE_GVMA(rs1, rs2)
  <-> 0b0110001 @ rs2 @ rs1 @ 0b000 @ 0b00000 @ 0b1110011

function clause execute HFENCE_GVMA(rs1, rs2) = {
  let addr : option(xlenbits) = if rs1 == 0b00000 then None() else Some(X(rs1));
  let vmid : option(xlenbits) = if rs2 == 0b00000 then None() else Some(X(rs2));
  match (cur_privilege, cur_virtualization) {
    (User, V1)       => { handle_virtual_instr(); RETIRE_FAIL },
    (User, V0)       => { handle_illegal(); RETIRE_FAIL },
    (Supervisor, V1) => { handle_virtual_instr(); RETIRE_FAIL },
    (Supervisor, V0) => match mstatus[TVM] {
                            0b1 => { handle_illegal(); RETIRE_FAIL },
                            0b0 => { flush_TLB(vmid, Stage_G, addr); RETIRE_SUCCESS }
                        },
    (Machine, _)    => { flush_TLB(vmid, Stage_G, addr); RETIRE_SUCCESS }
  }
}

mapping clause assembly = HFENCE_GVMA(rs1, rs2)
  <-> "hfence.gvma" ^ spc() ^ reg_name(rs1) ^ sep() ^ reg_name(rs2)

/* ****************************************************************** */
/* Transformed instruction mappings                                   */

// Note: Should enc_transformed be implemented here since it originates from H-ext or next to the relevant instruction definitions?

function clause enc_transformed(LOAD(_, _, rd, uns, size, _, _), addr_offset) =
  0b0000000 @ 0b00000 @ addr_offset @ bool_bits(uns) @ size_enc(size) @ rd @ 0b0000011

function clause enc_transformed(C_LW(_, _, rd), addr_offset) = {
  let expanded_inst = LOAD(zeros(), zeros(), 0b01 @ rd, false, WORD, false, false);
  let transformed_inst = enc_transformed(expanded_inst, addr_offset);
  [transformed_inst with 1 = bitzero] /* Set transformed_inst[1] to 0b0 */
}

function clause enc_transformed(C_LD(_, _, rd), addr_offset) = {
  let expanded_inst = LOAD(zeros(), zeros(), 0b01 @ rd, false, DOUBLE, false, false);
  let transformed_inst = enc_transformed(expanded_inst, addr_offset);
  [transformed_inst with 1 = bitzero] /* Set transformed_inst[1] to 0b0 */
}

function clause enc_transformed(LOAD_FP(_, _, rd, size), addr_offset) =
  0b0000000 @ 0b00000 @ addr_offset @ 0b0 @ size_enc(size) @ rd @ 0b0000111

function clause enc_transformed(STORE(_, rs2, _, size, _, _), addr_offset) =
  0b0000000 @ rs2 @ addr_offset @ 0b0 @ size_enc(size) @ 0b00000 @ 0b0100011

function clause enc_transformed(C_SW(_, _, rs2), addr_offset) = {
  let expanded_inst = STORE(zeros(), 0b01 @ rs2, zeros(), WORD, false, false);
  let transformed_inst = enc_transformed(expanded_inst, addr_offset);
  [transformed_inst with 1 = bitzero] /* Set transformed_inst[1] to 0b0 */
}
function clause enc_transformed(C_SD(_, _, rs2), addr_offset) = {
  let expanded_inst = STORE(zeros(), 0b01 @ rs2, zeros(), DOUBLE, false, false);
  let transformed_inst = enc_transformed(expanded_inst, addr_offset);
  [transformed_inst with 1 = bitzero] /* Set transformed_inst[1] to 0b0 */
}

function clause enc_transformed(STORE_FP(_, rs2, _, size), addr_offset) =
  0b0000000 @ rs2 @ addr_offset @ 0b0 @ size_enc(size) @ 0b00000 @ 0b0100111

function clause enc_transformed(LOADRES(aq, rl, _, size, rd), addr_offset) =
  0b00010 @ bool_bits(aq) @ bool_bits(rl) @ 0b00000 @ addr_offset @ 0b0 @ size_enc(size) @ rd @ 0b0101111

function clause enc_transformed(STORECON(aq, rl, rs2, _, size, rd), addr_offset) =
  0b00011 @ bool_bits(aq) @ bool_bits(rl) @ rs2 @ addr_offset @ 0b0 @ size_enc(size) @ rd @ 0b0101111

function clause enc_transformed(AMO(op, aq, rl, rs2, _, size, rd), addr_offset) =
  encdec_amoop(op) @ bool_bits(aq) @ bool_bits(rl) @ rs2 @ addr_offset @ 0b0 @ size_enc(size) @ rd @ 0b0101111

// function clause enc_transformed(HLV(width, is_unsigned, _, rd), addr_offset) =
//   0b0110 @ size_enc(width) @ 0b0 @ 0b0000 @ bool_bits(is_unsigned) @ addr_offset @ 0b100 @ rd @ 0b1110011

// function clause enc_transformed(HSV(width, _, rs2), addr_offset) =
//   0b0110 @ size_enc(width) @ 0b1 @ rs2 @ addr_offset @ 0b100 @ 0b00000 @ 0b1110011

// function clause enc_transformed(HLVX(width, _, rd), addr_offset) =
//   0b0110 @ size_enc(width) @ 0b0 @ 0b00011 @ addr_offset @ 0b100 @ rd @ 0b1110011
