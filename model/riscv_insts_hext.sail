
/* ****************************************************************** */
/* This file specifies the instructions in the 'H' extension.         */

/* ****************************************************************** */

union clause ast = HLV : (word_width, bool, regidx, regidx)

mapping clause encdec = HLV(width, is_unsigned, rs1, rd)
  <-> 0b0110 @ size_bits(width) @ 0b0 @ 0b0000 @ bool_bits(is_unsigned) @ rs1 @ 0b100 @ rd @ 0b1110011

function clause execute(HLV(width, is_unsigned, rs1, rd)) =
  /* Unsigned loads are only valid for widths strictly less than xlen, signed loads also present for widths equal to xlen */
  if (is_unsigned & word_width_bytes(width) >= sizeof(xlen_bytes)) | (word_width_bytes(width) > sizeof(xlen_bytes))
  then { handle_illegal(); RETIRE_FAIL }
  else if (cur_virtualization == V1)
  then { handle_virtual_instr(); RETIRE_FAIL }
  else if (cur_privilege == User) & (hstatus.HU() == 0b0)
  then { handle_illegal(); RETIRE_FAIL }
  /* Extensions can perform additional checks on address validity. */
  else match ext_data_get_addr(rs1, zeros(), Read(Data), width) {
    Ext_DataAddr_Error(e)  => { ext_handle_data_check_error(e); RETIRE_FAIL },
    Ext_DataAddr_OK(vaddr) =>
      /* Address could be misaligned */
      if check_misaligned(vaddr, width)
      then { handle_mem_exception(vaddr, E_Load_Addr_Align()); RETIRE_FAIL }
      /* Address translation and protection should be performed as if V=1 */
      else match translateAddr_pv(vaddr, Read(Data), privLevel_of_bits(zero_extend(hstatus.SPVP())), V1) {
        TR_Failure(e, c, _)  => { handle_exception(e, c); RETIRE_FAIL },
        TR_Address(paddr, _) => match (width) {
          BYTE   => process_load(rd, vaddr, mem_read(Read(Data), paddr, 1, false, false, false), is_unsigned),
          HALF   => process_load(rd, vaddr, mem_read(Read(Data), paddr, 2, false, false, false), is_unsigned),
          WORD   => process_load(rd, vaddr, mem_read(Read(Data), paddr, 4, false, false, false), is_unsigned),
          DOUBLE if sizeof(xlen) >= 64 => process_load(rd, vaddr, mem_read(Read(Data), paddr, 8, false, false, false), is_unsigned),
          _ => report_invalid_width(__FILE__, __LINE__, width, "hlv")
        }
      }
  }

mapping clause assembly = HLV(width, is_unsigned, rs1, rd)
  <-> "hlv." ^ size_mnemonic(width) ^ maybe_u(is_unsigned) ^ spc() ^ reg_name(rd) ^ sep() ^ "(" ^ reg_name(rs1) ^ ")"

/* ****************************************************************** */

union clause ast = HLVX : (word_width, regidx, regidx)

mapping clause encdec = HLVX(width, rs1, rd)
  <-> 0b0110 @ size_bits(width) @ 0b0 @ 0b00011 @ rs1 @ 0b100 @ rd @ 0b1110011

function clause execute(HLVX(width, rs1, rd)) =
  if (cur_virtualization == V1)
  then { handle_virtual_instr(); RETIRE_FAIL }
  else if (cur_privilege == User) & (hstatus.HU() == 0b0)
  then { handle_illegal(); RETIRE_FAIL }
  /* Extensions can perform additional checks on address validity. */
  else match ext_data_get_addr(rs1, zeros(), Read(Data), width) {
    Ext_DataAddr_Error(e)  => { ext_handle_data_check_error(e); RETIRE_FAIL },
    Ext_DataAddr_OK(vaddr) =>
      /* Address could be misaligned */
      if check_misaligned(vaddr, width)
      then { handle_mem_exception(vaddr, E_Load_Addr_Align()); RETIRE_FAIL }
      /* Address translation and protection should be performed as for an instruction fetch while V=1 */
      else match translateAddr_pv(vaddr, Execute(), privLevel_of_bits(zero_extend(hstatus.SPVP())), V1) {
        /* Update exception's access type because HLVX should raise load exceptions but translateAddr may return fetch exceptions */
        TR_Failure(e, c, _)  => { handle_exception(exceptionType_update_AccessType(e, Read(Data)), c); RETIRE_FAIL },
        TR_Address(paddr, _) => match (width) {
          /* AccessType is Read since HLVX should not override pmp */
          HALF   => process_load(rd, vaddr, mem_read(Read(Data), paddr, 2, false, false, false), true),
          WORD   => process_load(rd, vaddr, mem_read(Read(Data), paddr, 4, false, false, false), true),
          _ => report_invalid_width(__FILE__, __LINE__, width, "hlvx")
        }
      }
  }

mapping clause assembly = HLVX(width, rs1, rd)
<-> "hlvx." ^ size_mnemonic(width) ^ "u" ^ spc() ^ reg_name(rd) ^ sep() ^ "(" ^ reg_name(rs1) ^ ")"

/* ****************************************************************** */

union clause ast = HSV : (word_width, regidx, regidx)

mapping clause encdec = HSV(width, rs1, rs2)
  <-> 0b0110 @ size_bits(width) @ 0b1 @ rs2 @ rs1 @ 0b100 @ 0b00000 @ 0b1110011

function clause execute(HSV(width, rs1, rs2)) =
  if word_width_bytes(width) > sizeof(xlen_bytes)
  then { handle_illegal(); RETIRE_FAIL }
  else if (cur_virtualization == V1)
  then { handle_virtual_instr(); RETIRE_FAIL }
  else if (cur_privilege == User) & (hstatus.HU() == 0b0)
  then { handle_illegal(); RETIRE_FAIL }
  /* Extensions can perform additional checks on address validity. */
  else match ext_data_get_addr(rs1, zeros(), Write(Data), width) {
    Ext_DataAddr_Error(e)  => { ext_handle_data_check_error(e); RETIRE_FAIL },
    Ext_DataAddr_OK(vaddr) =>
      /* Address could be misaligned */
      if check_misaligned(vaddr, width)
      then { handle_mem_exception(vaddr, E_SAMO_Addr_Align()); RETIRE_FAIL }
      /* Address translation and protection should be performed as if V=1 */
      else match translateAddr_pv(vaddr, Write(Data), privLevel_of_bits(zero_extend(hstatus.SPVP())), V1) {
        TR_Failure(e, c, _)  => { handle_exception(e, c); RETIRE_FAIL },
        TR_Address(paddr, _) => {
          let eares : MemoryOpResult(unit) = match width {
            BYTE   => mem_write_ea(paddr, 1, false, false, false),
            HALF   => mem_write_ea(paddr, 2, false, false, false),
            WORD   => mem_write_ea(paddr, 4, false, false, false),
            DOUBLE => mem_write_ea(paddr, 8, false, false, false)
          };
          match (eares) {
            MemException(e) => { handle_mem_exception(vaddr, e); RETIRE_FAIL },
            MemValue(_) => {
              let rs2_val = X(rs2);
              let res : MemoryOpResult(bool) = match (width) {
                BYTE => mem_write_value(paddr, 1, rs2_val[7..0],  false, false, false),
                HALF => mem_write_value(paddr, 2, rs2_val[15..0], false, false, false),
                WORD => mem_write_value(paddr, 4, rs2_val[31..0], false, false, false),
                DOUBLE if sizeof(xlen) >= 64 => mem_write_value(paddr, 8, rs2_val, false, false, false),
                _ => report_invalid_width(__FILE__, __LINE__, width, "hsv"),
              };
              match (res) {
                MemValue(true)  => RETIRE_SUCCESS,
                MemValue(false) => internal_error(__FILE__, __LINE__, "hsv got false from mem_write_value"),
                MemException(e) => { handle_mem_exception(vaddr, e); RETIRE_FAIL }
              }
            }
          }
        },
      }
  }

mapping clause assembly = HSV(width, rs1, rs2)
  <-> "hsv."  ^ size_mnemonic(width) ^ spc() ^ reg_name(rs2) ^ sep() ^ "(" ^ reg_name(rs1) ^ ")"

/* ****************************************************************** */

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
    (Supervisor, V0) => { flush_TLB(asid, VS, addr); RETIRE_SUCCESS },
    (Machine, _)     => { flush_TLB(asid, VS, addr); RETIRE_SUCCESS }
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
    (Supervisor, V0) => match mstatus.TVM() {
      0b1 => { handle_illegal(); RETIRE_FAIL },
      0b0 => { flush_TLB(vmid, G, addr); RETIRE_SUCCESS }
      },
    (Machine, _)    => { flush_TLB(vmid, G, addr); RETIRE_SUCCESS }
  }
}

mapping clause assembly = HFENCE_GVMA(rs1, rs2)
  <-> "hfence.gvma" ^ spc() ^ reg_name(rs1) ^ sep() ^ reg_name(rs2)

/* ****************************************************************** */
/* Transformed instruction mappings                                   */

// Note: Should enc_transformed be implemented here since it originates from H-ext or next to the relevant instruction definitions?

function clause enc_transformed(LOAD(_, _, rd, uns, size, _, _), addr_offset) =
  0b0000000 @ 0b00000 @ addr_offset @ bool_bits(uns) @ size_bits(size) @ rd @ 0b0000011

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
  0b0000000 @ 0b00000 @ addr_offset @ 0b0 @ size_bits(size) @ rd @ 0b0000111

function clause enc_transformed(STORE(_, rs2, _, size, _, _), addr_offset) =
  0b0000000 @ rs2 @ addr_offset @ 0b0 @ size_bits(size) @ 0b00000 @ 0b0100011

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
  0b0000000 @ rs2 @ addr_offset @ 0b0 @ size_bits(size) @ 0b00000 @ 0b0100111

function clause enc_transformed(LOADRES(aq, rl, _, size, rd), addr_offset) =
  0b00010 @ bool_bits(aq) @ bool_bits(rl) @ 0b00000 @ addr_offset @ 0b0 @ size_bits(size) @ rd @ 0b0101111

function clause enc_transformed(STORECON(aq, rl, rs2, _, size, rd), addr_offset) =
  0b00011 @ bool_bits(aq) @ bool_bits(rl) @ rs2 @ addr_offset @ 0b0 @ size_bits(size) @ rd @ 0b0101111

function clause enc_transformed(AMO(op, aq, rl, rs2, _, size, rd), addr_offset) =
  encdec_amoop(op) @ bool_bits(aq) @ bool_bits(rl) @ rs2 @ addr_offset @ 0b0 @ size_bits(size) @ rd @ 0b0101111

function clause enc_transformed(HLV(width, is_unsigned, _, rd), addr_offset) =
  0b0110 @ size_bits(width) @ 0b0 @ 0b0000 @ bool_bits(is_unsigned) @ addr_offset @ 0b100 @ rd @ 0b1110011

function clause enc_transformed(HSV(width, _, rs2), addr_offset) =
  0b0110 @ size_bits(width) @ 0b1 @ rs2 @ addr_offset @ 0b100 @ 0b00000 @ 0b1110011

function clause enc_transformed(HLVX(width, _, rd), addr_offset) =
  0b0110 @ size_bits(width) @ 0b0 @ 0b00011 @ addr_offset @ 0b100 @ rd @ 0b1110011
