//=======================================================================================
//  This Sail RISC-V architecture model, comprising all files and
//  directories except where otherwise noted is subject the BSD
//  two-clause license in the LICENSE file.
//
//  SPDX-License-Identifier: BSD-2-Clause
//=======================================================================================

union clause instruction = HLV : (word_width, bool, regidx, regidx)

mapping clause encdec = HLV(width, is_unsigned, rs1, rd)
  <-> 0b0110 @ width_enc(width) @ 0b0 @ 0b0000 @ bool_bit(is_unsigned) @ encdec_reg(rs1) @ 0b100 @ encdec_reg(rd) @ 0b1110011
  when currentlyEnabled(Ext_H)

function clause execute(HLV(width, is_unsigned, rs1, rd)) =
  // Unsigned loads are only valid for widths strictly less than xlen, signed loads also present for widths equal to xlen
  if (is_unsigned & width >= xlen_bytes) | (width > xlen_bytes)
  then { Illegal_Instruction() }
  else if (privLevel_is_virtual(cur_privilege))
  then { Virtual_Instruction() }
  else if (cur_privilege == User) & (hstatus[HU] == 0b0)
  then { Illegal_Instruction() }
  else {
    let width_bytes = width;
    assert(width_bytes <= xlen_bytes);
    // Extensions can perform additional checks on address validity.
    match ext_data_get_addr(rs1, zeros(), Load(Data), width_bytes) {
      Ext_DataAddr_Error(e)  => { Ext_DataAddr_Check_Failure(e) },
      Ext_DataAddr_OK(vaddr) =>
        // Address could be misaligned
        if check_misaligned(vaddr, width)
        then { memory_exception_with_gva(E_Load_Addr_Align(), vaddr) }
        // Address translation and protection should be performed as if V=1
        else match translateAddr_pv(vaddr, Load(Data), privLevel_bits(zero_extend(hstatus[SPVP]), 0b1)) {
          Err((e, c), _) => { handle_exception(e, c); RETIRE_SUCCESS },
          Ok(paddr, _) => match mem_read(Load(Data), paddr, width_bytes, false, false, false) {
            Ok(result) => { X(rd) = extend_value(is_unsigned, result); RETIRE_SUCCESS },
            Err(e) => { memory_exception_with_gva(e, vaddr) },
          },
        }
    }
  }

mapping clause assembly = HLV(width, is_unsigned, rs1, rd)
  <-> "hlv." ^ width_mnemonic(width) ^ maybe_u(is_unsigned) ^ spc() ^ reg_name(rd) ^ sep() ^ "(" ^ reg_name(rs1) ^ ")"

// ******************************************************************

union clause instruction = HLVX : (word_width, regidx, regidx)

mapping clause encdec = HLVX(width, rs1, rd)
  <-> 0b0110 @ width_enc(width) @ 0b0 @ 0b00011 @ encdec_reg(rs1) @ 0b100 @ encdec_reg(rd) @ 0b1110011
  when currentlyEnabled(Ext_H)

function clause execute(HLVX(width, rs1, rd)) =
  if privLevel_is_virtual(cur_privilege)
  then { Virtual_Instruction() }
  else if (cur_privilege == User) & (hstatus[HU] == 0b0)
  then { Illegal_Instruction() }
  else {
    let width_bytes = width;
    assert(width_bytes <= xlen_bytes);
    // Extensions can perform additional checks on address validity.
    match ext_data_get_addr(rs1, zeros(), Load(Data), width_bytes) {
    Ext_DataAddr_Error(e)  => { Ext_DataAddr_Check_Failure(e) },
    Ext_DataAddr_OK(vaddr) =>
      // Address could be misaligned
      if check_misaligned(vaddr, width)
      then { memory_exception_with_gva(E_Load_Addr_Align(), vaddr) }
      // Address translation and protection should be performed as for an instruction fetch while V=1
      else match translateAddr_pv(vaddr, InstructionFetch(), privLevel_bits(zero_extend(hstatus[SPVP]), 0b1)) {
        // Update exception's access type because HLVX should raise load exceptions but translateAddr may return fetch exceptions
        // TODO: delay all handle_exception to step done
        Err((e, c), _)  => { handle_exception(exceptionType_update_AccessType(e, Load(Data)), c); RETIRE_SUCCESS },
        Ok(paddr, _) => match mem_read(Load(Data), paddr, width_bytes, false, false, false) {
            // AccessType is Read since HLVX should not override pmp
            Ok(result) => { X(rd) = extend_value(true, result); RETIRE_SUCCESS },
            Err(e) => { memory_exception_with_gva(e, vaddr) },
          },
        }
    }
  }

mapping clause assembly = HLVX(width, rs1, rd)
<-> "hlvx." ^ width_mnemonic(width) ^ "u" ^ spc() ^ reg_name(rd) ^ sep() ^ "(" ^ reg_name(rs1) ^ ")"

// ******************************************************************

union clause instruction = HSV : (word_width, regidx, regidx)

mapping clause encdec = HSV(width, rs1, rs2)
  <-> 0b0110 @ width_enc(width) @ 0b1 @ encdec_reg(rs2) @ encdec_reg(rs1) @ 0b100 @ 0b00000 @ 0b1110011
  when currentlyEnabled(Ext_H)

function clause execute(HSV(width, rs1, rs2)) =
  if width > xlen_bytes
  then { Illegal_Instruction() }
  else if privLevel_is_virtual(cur_privilege)
  then { Virtual_Instruction() }
  else if (cur_privilege == User) & (hstatus[HU] == 0b0)
  then { Illegal_Instruction() }
  // Extensions can perform additional checks on address validity.
  else match ext_data_get_addr(rs1, zeros(), Store(Data), width) {
    Ext_DataAddr_Error(e)  => { Ext_DataAddr_Check_Failure(e) },
    Ext_DataAddr_OK(vaddr) =>
      // Address could be misaligned
      if check_misaligned(vaddr, width)
      then { memory_exception_with_gva(E_SAMO_Addr_Align(), vaddr) }
      // Address translation and protection should be performed as if V=1
      else match translateAddr_pv(vaddr, Store(Data), privLevel_bits(zero_extend(hstatus[SPVP]), 0b1)) {
        Err((e, c), _)  => { handle_exception(e, c); RETIRE_SUCCESS },
        Ok(paddr, _) => {
          let eares : MemoryOpResult(unit) = mem_write_ea(paddr, width, false, false, false);
          match (eares) {
            Err(e) => { memory_exception_with_gva(e, vaddr) },
            Ok(_) => {
              let rs2_val = X(rs2);
              if (width == 8 & xlen < 64) then {
                internal_error(__FILE__, __LINE__,
                  "Invalid width = " ^ width_mnemonic(width) ^ ", for hsv"
                  ^ " with xlen=" ^ dec_str(xlen));
              };
              let res : MemoryOpResult(bool) = mem_write_value(paddr, width, rs2_val[8 * width - 1..0],  false, false, false);
              match (res) {
                Ok(true)  => RETIRE_SUCCESS,
                Ok(false) => internal_error(__FILE__, __LINE__, "hsv got false from mem_write_value"),
                Err(e) => { memory_exception_with_gva(e, vaddr) }
              }
            }
          }
        },
      }
  }

mapping clause assembly = HSV(width, rs1, rs2)
  <-> "hsv."  ^ width_mnemonic(width) ^ spc() ^ reg_name(rs2) ^ sep() ^ "(" ^ reg_name(rs1) ^ ")"

// ******************************************************************

union clause instruction = HFENCE_VVMA : (regidx, regidx)

mapping clause encdec = HFENCE_VVMA(rs1, rs2)
  <-> 0b0010001 @ encdec_reg(rs2) @ encdec_reg(rs1) @ 0b000 @ 0b00000 @ 0b1110011
  when currentlyEnabled(Ext_H)

function clause execute HFENCE_VVMA(rs1, rs2) = {
  let addr : option(xlenbits) = if regidx_bits(rs1) == zeros() then None() else Some(X(rs1));
  let asid : option(xxidbits) = if regidx_bits(rs2) == zeros() then None() else Some(X(rs2)[15 .. 0]);
  match cur_privilege {
    VirtualUser       => { Virtual_Instruction() },
    User              => { Illegal_Instruction() },
    VirtualSupervisor => { Virtual_Instruction() },
    Supervisor        => { flush_TLB(asid, Stage_VS, addr); RETIRE_SUCCESS },
    Machine           => { flush_TLB(asid, Stage_VS, addr); RETIRE_SUCCESS }
  }
}

mapping clause assembly = HFENCE_VVMA(rs1, rs2)
  <-> "hfence.vvma" ^ spc() ^ reg_name(rs1) ^ sep() ^ reg_name(rs2)

/* ****************************************************************** */

union clause instruction = HFENCE_GVMA : (regidx, regidx)

mapping clause encdec = HFENCE_GVMA(rs1, rs2)
  <-> 0b0110001 @ encdec_reg(rs2) @ encdec_reg(rs1) @ 0b000 @ 0b00000 @ 0b1110011
  when currentlyEnabled(Ext_H)

function clause execute HFENCE_GVMA(rs1, rs2) = {
  let addr : option(xlenbits) = if regidx_bits(rs1) == zeros() then None() else Some(X(rs1));
  let vmid : option(xxidbits) = if regidx_bits(rs2) == zeros() then None() else Some(X(rs2)[15 .. 0]);
  match cur_privilege {
    VirtualUser       => { Virtual_Instruction() },
    User              => { Illegal_Instruction() },
    VirtualSupervisor => { Virtual_Instruction() },
    Supervisor        => match mstatus[TVM] {
                            0b1 => { Illegal_Instruction() },
                            0b0 => { flush_TLB(vmid, Stage_G, addr); RETIRE_SUCCESS }
                        },
    Machine           => { flush_TLB(vmid, Stage_G, addr); RETIRE_SUCCESS }
  }
}

mapping clause assembly = HFENCE_GVMA(rs1, rs2)
  <-> "hfence.gvma" ^ spc() ^ reg_name(rs1) ^ sep() ^ reg_name(rs2)

// ******************************************************************
// Transformed instruction mappings

function clause enc_transformed(LOAD(_, _, rd, uns, width), addr_offset) =
  0b0000000 @ 0b00000 @ addr_offset @ bool_bit(uns) @ width_enc(width) @ encdec_reg(rd) @ 0b0000011

function clause enc_transformed(C_LW(_, _, rd), addr_offset) = {
  let expanded_inst = LOAD(zeros(), Regidx(zeros()), creg2reg_idx(rd), false, 4);
  let transformed_inst = enc_transformed(expanded_inst, addr_offset);
  [transformed_inst with 1 = bitzero] // Set transformed_inst[1] to 0b0
}

function clause enc_transformed(C_LD(_, _, rd), addr_offset) = {
  let expanded_inst = LOAD(zeros(), Regidx(zeros()), creg2reg_idx(rd), false, 8);
  let transformed_inst = enc_transformed(expanded_inst, addr_offset);
  [transformed_inst with 1 = bitzero] // Set transformed_inst[1] to 0b0
}

function clause enc_transformed(LOAD_FP(_, _, rd, size), addr_offset) =
  0b0000000 @ 0b00000 @ addr_offset @ 0b0 @ width_enc(size) @ encdec_freg(rd) @ 0b0000111

function clause enc_transformed(STORE(_, rs2, _, size), addr_offset) =
  0b0000000 @ encdec_reg(rs2) @ addr_offset @ 0b0 @ width_enc(size) @ 0b00000 @ 0b0100011

function clause enc_transformed(C_SW(_, _, rs2), addr_offset) = {
  let expanded_inst = STORE(zeros(), creg2reg_idx(rs2), Regidx(zeros()), 4);
  let transformed_inst = enc_transformed(expanded_inst, addr_offset);
  [transformed_inst with 1 = bitzero] // Set transformed_inst[1] to 0b0
}
function clause enc_transformed(C_SD(_, _, rs2), addr_offset) = {
  let expanded_inst = STORE(zeros(), creg2reg_idx(rs2), Regidx(zeros()), 8);
  let transformed_inst = enc_transformed(expanded_inst, addr_offset);
  [transformed_inst with 1 = bitzero] // Set transformed_inst[1] to 0b0
}

function clause enc_transformed(STORE_FP(_, rs2, _, size), addr_offset) =
  0b0000000 @ encdec_freg(rs2) @ addr_offset @ 0b0 @ width_enc(size) @ 0b00000 @ 0b0100111

function clause enc_transformed(LOADRES(aq, rl, _, size, rd), addr_offset) =
  0b00010 @ bool_bit(aq) @ bool_bit(rl) @ 0b00000 @ addr_offset @ 0b0 @ width_enc(size) @ encdec_reg(rd) @ 0b0101111

function clause enc_transformed(STORECON(aq, rl, rs2, _, size, rd), addr_offset) =
  0b00011 @ bool_bit(aq) @ bool_bit(rl) @ encdec_reg(rs2) @ addr_offset @ 0b0 @ width_enc(size) @ encdec_reg(rd) @ 0b0101111

function clause enc_transformed(AMO(op, aq, rl, rs2, _, size, rd), addr_offset) =
  encdec_amoop(op) @ bool_bit(aq) @ bool_bit(rl) @ encdec_reg(rs2) @ addr_offset @ width_enc_wide(size) @ encdec_reg(rd) @ 0b0101111

function clause enc_transformed(HLV(width, is_unsigned, _, rd), addr_offset) =
  0b0110 @ width_enc(width) @ 0b0 @ 0b0000 @ bool_bit(is_unsigned) @ addr_offset @ 0b100 @ encdec_reg(rd) @ 0b1110011

function clause enc_transformed(HSV(width, _, rs2), addr_offset) =
  0b0110 @ width_enc(width) @ 0b1 @ encdec_reg(rs2) @ addr_offset @ 0b100 @ 0b00000 @ 0b1110011

function clause enc_transformed(HLVX(width, _, rd), addr_offset) =
  0b0110 @ width_enc(width) @ 0b0 @ 0b00011 @ addr_offset @ 0b100 @ encdec_reg(rd) @ 0b1110011
