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

// Implements the table in the Zicsr specification determining whether
// a CSR instruction reads or writes the specified CSR.
function csr_access_type(op : csrop, rd_is_x0 : bool, rs1_imm_is_zero : bool) -> CSRAccessType =
  match (op, rd_is_x0, rs1_imm_is_zero) {
    (CSRRW, true, _)  => CSRWrite,
    (CSRRW, false, _) => CSRReadWrite,
    (CSRRS, _, true)  => CSRRead,
    (CSRRC, _, true)  => CSRRead,
    (CSRRS, _, false) => CSRReadWrite,
    (CSRRC, _, false) => CSRReadWrite,
  }

function doCSR(csr : csreg, rs1_val : xlenbits, rd : regidx, op : csrop, access_type : CSRAccessType) -> ExecutionResult = {
  match check_CSR_result(csr, cur_privilege, access_type) {
    CSR_Illegal()  => Illegal_Instruction(),
    CSR_Virtual()  => Virtual_Instruction(),
    CSR_Check_OK() => {
      if not(ext_check_CSR(csr, cur_privilege, access_type))
      then Ext_CSR_Check_Failure()
      else {
        // A pure write (i.e. CSRRW with rd == 0) should not generate read side-effects.
        let read_val : xlenbits = if access_type != CSRWrite then read_CSR(csr) else zeros();

        // `read_val` is the value used in the read-modify-write. `dest_val` is the
        // value written to `rd`. These are almost always the same.
        //
        // An exception is mip and sip which have delightfully unique behaviour
        // for the SEIP bit. The value written into `X(rd)` has the external
        // platform interrupt bit (e.g. from PLIC) ORed into SEIP. But that
        // *isn't* the case for the "read" value of the CSR used in the
        // read-modify write cycle.
        //
        // read_CSR() returns read_mip/sip(ExcludePlatformInterrupts) so we
        // override that here for `dest_val`.
        //
        // We treat MEIP the same as SEIP for consistency. It doesn't actually matter
        // since it is read-only.
        //
        let dest_val : xlenbits = match csr {
          0x344 => read_mip(IncludePlatformInterrupts).bits,
          0x144 => read_sip(IncludePlatformInterrupts).bits,
          _ => read_val,
        };

        if access_type == CSRRead then {
          csr_read_callback(csr, dest_val);
          X(rd) = dest_val;
          RETIRE_SUCCESS
        } else {
          let write_val : xlenbits = match op {
            CSRRW => rs1_val,
            CSRRS => read_val | rs1_val,
            CSRRC => read_val & ~(rs1_val)
          };
          match write_CSR(csr, write_val) {
            Ok(final_val) => {
              X(rd) = dest_val;
              csr_write_callback(csr, final_val);
              RETIRE_SUCCESS
            },
            Err(()) => Illegal_Instruction(),
          }
        }
      }
    }
  }
}

function clause execute CSRReg(csr, rs1, rd, op) = {
  let access_type = csr_access_type(op, rd == zreg, rs1 == zreg);
  doCSR(csr, X(rs1), rd, op, access_type)
}

function clause execute CSRImm(csr, imm, rd, op) = {
  let access_type = csr_access_type(op, rd == zreg, imm == zeros());
  doCSR(csr, zero_extend(imm), rd, op, access_type)
}

mapping csr_mnemonic : csrop <-> string = {
  CSRRW <-> "csrrw",
  CSRRS <-> "csrrs",
  CSRRC <-> "csrrc"
}

mapping clause assembly = CSRImm(csr, imm, rd, op)
  <-> csr_mnemonic(op) ^ "i" ^ spc() ^ reg_name(rd)  ^ sep() ^ csr_name_map(csr) ^ sep() ^ hex_bits_5(imm)
mapping clause assembly = CSRReg(csr, rs1, rd, op)
  <-> csr_mnemonic(op) ^ spc() ^ reg_name(rd) ^ sep() ^ csr_name_map(csr) ^ sep() ^ reg_name(rs1)
