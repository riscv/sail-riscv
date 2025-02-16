/*=======================================================================================*/
/*  This Sail RISC-V architecture model, comprising all files and                        */
/*  directories except where otherwise noted is subject the BSD                          */
/*  two-clause license in the LICENSE file.                                              */
/*                                                                                       */
/*  SPDX-License-Identifier: BSD-2-Clause                                                */
/*=======================================================================================*/

/* ****************************************************************** */
/* This file specifies the instructions in the 'Zicsr' extension.     */
/* ****************************************************************** */
union clause ast = CSR  : (csreg, regidx, regidx, bool, csrop)

mapping encdec_csrop : csrop <-> bits(2) = {
  CSRRW <-> 0b01,
  CSRRS <-> 0b10,
  CSRRC <-> 0b11
}

mapping clause encdec = CSR(csr, rs1, rd, is_imm, op)
  <-> csr @ rs1 @ bool_bits(is_imm) @ encdec_csrop(op) @ rd @ 0b1110011

function clause execute CSR(csr, rs1, rd, is_imm, op) = {
  let rs1_val : xlenbits = if is_imm then zero_extend(rs1) else X(rs1);
  let is_CSR_Write = op == CSRRW | rs1 != zeros();
  if not(check_CSR(csr, cur_privilege, is_CSR_Write))
  then RETIRE_FAIL(Illegal_Instruction())
  else if not(ext_check_CSR(csr, cur_privilege, is_CSR_Write))
  then RETIRE_FAIL(Ext_CSR_Check_Failure())
  else {
    /* CSRRW should not generate read side-effects if rd == 0 */
    let is_CSR_Read = not(op == CSRRW & rd == zeros());
    let csr_val : xlenbits = if is_CSR_Read then read_CSR(csr) else zeros();
    if is_CSR_Write then {
      let new_val : xlenbits = match op {
        CSRRW => rs1_val,
        CSRRS => csr_val | rs1_val,
        CSRRC => csr_val & ~(rs1_val)
      };
      let final_val = write_CSR(csr, new_val);
      if get_config_print_reg()
      then print_reg("CSR " ^ to_str(csr) ^ " <- " ^ bits_str(final_val) ^ " (input: " ^ bits_str(new_val) ^ ")")
    } else {
      if get_config_print_reg()
      then print_reg("CSR " ^ to_str(csr) ^ " -> " ^ bits_str(csr_val));
    };
    X(rd) = csr_val;
    RETIRE_SUCCESS()
  }
}

mapping csr_mnemonic : csrop <-> string = {
  CSRRW <-> "csrrw",
  CSRRS <-> "csrrs",
  CSRRC <-> "csrrc"
}

mapping clause assembly = CSR(csr, rs1, rd, true, op)
  <-> csr_mnemonic(op) ^ "i" ^ spc() ^ reg_name(rd)  ^ sep() ^ csr_name_map(csr) ^ sep() ^ hex_bits_5(rs1)
mapping clause assembly = CSR(csr, rs1, rd, false, op)
  <-> csr_mnemonic(op) ^ spc() ^ reg_name(rd) ^ sep() ^ csr_name_map(csr) ^ sep() ^ reg_name(rs1)
