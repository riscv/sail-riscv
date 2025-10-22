// =======================================================================================
// This Sail RISC-V architecture model, comprising all files and
// directories except where otherwise noted is subject the BSD
// two-clause license in the LICENSE file.
//
// SPDX-License-Identifier: BSD-2-Clause
// =======================================================================================

// *****************************************************************
// This file specifies the instructions in the 'Zicsr' extension.
// *****************************************************************
function clause currentlyEnabled(Ext_Zicsr) = hartSupports(Ext_Zicsr)

union clause instruction = CSRReg  : (csreg, regidx, regidx, csrop)
union clause instruction = CSRImm  : (csreg, bits(5), regidx, csrop)

mapping encdec_csrop : csrop <-> bits(2) = {
  CSRRW <-> 0b01,
  CSRRS <-> 0b10,
  CSRRC <-> 0b11
}

mapping clause encdec = CSRReg(csr, rs1, rd, op)
  <-> csr @ encdec_reg(rs1) @ 0b0 @ encdec_csrop(op) @ encdec_reg(rd) @ 0b1110011
  when currentlyEnabled(Ext_Zicsr)

mapping clause encdec = CSRImm(csr, imm, rd, op)
  <-> csr @ imm @ 0b1 @ encdec_csrop(op) @ encdec_reg(rd) @ 0b1110011
  when currentlyEnabled(Ext_Zicsr)

function makeCSRAccessType(op : csrop, rs1_is_zero : bool, rd_is_zero : bool) -> CSRAccessType = {
  match (op, rs1_is_zero, rd_is_zero) {
    (CSRRW, true ,     _) => CSRWrite,
    (CSRRW, false,     _) => CSRReadWrite,
    (    _,     _, true ) => CSRRead,
    (    _,     _, false) => CSRReadWrite,
  }
}

function doCSR(csr : csreg, rs1_val : xlenbits, rd : regidx, op : csrop, ac: CSRAccessType) -> ExecutionResult = {
  match check_CSR(csr, cur_privilege, ac) {
    CSRAccessSuccess => (),
    CSRAccessIllegal => return Illegal_Instruction(),
    CSRNotExist => return Illegal_Instruction(),
  };
  if not(ext_check_CSR(csr, cur_privilege, ac))
  then Ext_CSR_Check_Failure()
  else {
    // CSRRW should not generate read side-effects if rd == 0
    let is_CSR_Read = not(op == CSRRW & rd == zreg);
    let csr_val : xlenbits = if is_CSR_Read then read_CSR(csr) else zeros();
    match ac {
      CSRRead => {
        csr_read_callback(csr, csr_val);
        X(rd) = csr_val;
        RETIRE_SUCCESS
      },
      _ => {
        let new_val : xlenbits = match op {
          CSRRW => rs1_val,
          CSRRS => csr_val | rs1_val,
          CSRRC => csr_val & ~(rs1_val)
        };
        match write_CSR(csr, new_val) {
          Ok(final_val) => {
            csr_write_callback(csr, final_val);
            X(rd) = csr_val;
            RETIRE_SUCCESS
          },
          Err(()) => Illegal_Instruction()
        }
      }
    }
  }
}

function clause execute CSRReg(csr, rs1, rd, op) =
  doCSR(csr, X(rs1), rd, op, makeCSRAccessType(op, rs1 == zreg, rd == zreg))

function clause execute CSRImm(csr, imm, rd, op) =
  doCSR(csr, zero_extend(imm), rd, op, makeCSRAccessType(op, imm != zeros(), rd == zreg))

mapping csr_mnemonic : csrop <-> string = {
  CSRRW <-> "csrrw",
  CSRRS <-> "csrrs",
  CSRRC <-> "csrrc"
}

mapping clause assembly = CSRImm(csr, imm, rd, op)
  <-> csr_mnemonic(op) ^ "i" ^ spc() ^ reg_name(rd)  ^ sep() ^ csr_name_map(csr) ^ sep() ^ hex_bits_5(imm)
mapping clause assembly = CSRReg(csr, rs1, rd, op)
  <-> csr_mnemonic(op) ^ spc() ^ reg_name(rd) ^ sep() ^ csr_name_map(csr) ^ sep() ^ reg_name(rs1)
