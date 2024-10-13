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

// TODO: These read/write_CSR definitions should be moved to the files
// corresponding to their extensions rather than all be here.

/* machine mode */
function clause read_CSR(0x301) = misa.bits
function clause read_CSR(0x305) = get_mtvec()
function clause read_CSR(0x341) = get_xret_target(Machine) & pc_alignment_mask()

/* supervisor mode */
function clause read_CSR(0x104) = lower_mie(mie, mideleg).bits
function clause read_CSR(0x105) = get_stvec()
function clause read_CSR(0x140) = sscratch
function clause read_CSR(0x141) = get_xret_target(Supervisor) & pc_alignment_mask()
function clause read_CSR(0x142) = scause.bits
function clause read_CSR(0x143) = stval
function clause read_CSR(0x144) = lower_mip(mip, mideleg).bits

/* machine mode */
function clause write_CSR(0x301, value) = { misa = legalize_misa(misa, value); misa.bits }
function clause write_CSR(0x305, value) = { set_mtvec(value) }
function clause write_CSR(0x341, value) = { set_xret_target(Machine, value) }

/* supervisor mode */
function clause write_CSR(0x104, value) = { mie = legalize_sie(mie, mideleg, value); mie.bits }
function clause write_CSR(0x105, value) = { set_stvec(value) }
function clause write_CSR(0x140, value) = { sscratch = value; sscratch }
function clause write_CSR(0x141, value) = { set_xret_target(Supervisor, value) }
function clause write_CSR(0x142, value) = { scause.bits = value; scause.bits }
function clause write_CSR(0x143, value) = { stval = value; stval }
function clause write_CSR(0x144, value) = { mip = legalize_sip(mip, mideleg, value); mip.bits }


function clause execute CSR(csr, rs1, rd, is_imm, op) = {
  let rs1_val : xlenbits = if is_imm then zero_extend(rs1) else X(rs1);
  let isWrite : bool = match op {
    CSRRW  => true,
    _      => if is_imm then unsigned(rs1_val) != 0 else unsigned(rs1) != 0
  };
  if not(check_CSR(csr, cur_privilege, isWrite))
  then { handle_illegal(); RETIRE_FAIL }
  else if not(ext_check_CSR(csr, cur_privilege, isWrite))
  then { ext_check_CSR_fail(); RETIRE_FAIL }
  else {
    let csr_val = read_CSR(csr); /* could have side-effects, so technically shouldn't perform for CSRW[I] with rd == 0 */
    if isWrite then {
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
    RETIRE_SUCCESS
  }
}

mapping maybe_i : bool <-> string = {
  true  <-> "i",
  false <-> ""
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
