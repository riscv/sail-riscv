/*=======================================================================================*/
/*  This Sail RISC-V architecture model, comprising all files and                        */
/*  directories except where otherwise noted is subject the BSD                          */
/*  two-clause license in the LICENSE file.                                              */
/*                                                                                       */
/*  SPDX-License-Identifier: BSD-2-Clause                                                */
/*=======================================================================================*/

function clause currentlyEnabled(Ext_A) = hartSupports(Ext_A) & misa[A] == 0b1 // TODO: Move currentlyEnabled(Ext_A) to a more central file
function clause currentlyEnabled(Ext_Zaamo) = hartSupports(Ext_Zaamo) | currentlyEnabled(Ext_A)
function clause currentlyEnabled(Ext_Zabha) = hartSupports(Ext_Zabha) & currentlyEnabled(Ext_Zaamo)

// Zaamo defines AMOs for word and double
// Zabha defines AMOs for byte and halfword
function amo_width_valid(size : word_width) -> bool = {
  match size {
    1 => currentlyEnabled(Ext_Zabha),
    2 => currentlyEnabled(Ext_Zabha),
    4 => true,
    8 => xlen >= 64,
  }
}

/* ****************************************************************** */

union clause instruction = AMO : (amoop, bool, bool, regidx, regidx, word_width, regidx)

mapping encdec_amoop : amoop <-> bits(5) = {
  AMOSWAP <-> 0b00001,
  AMOADD  <-> 0b00000,
  AMOXOR  <-> 0b00100,
  AMOAND  <-> 0b01100,
  AMOOR   <-> 0b01000,
  AMOMIN  <-> 0b10000,
  AMOMAX  <-> 0b10100,
  AMOMINU <-> 0b11000,
  AMOMAXU <-> 0b11100
}

mapping clause encdec = AMO(op, aq, rl, rs2, rs1, size, rd)
  <-> encdec_amoop(op) @ bool_bits(aq) @ bool_bits(rl) @ encdec_reg(rs2) @ encdec_reg(rs1) @ 0b0 @ size_enc(size) @ encdec_reg(rd) @ 0b0101111
  when currentlyEnabled(Ext_Zaamo) & amo_width_valid(size)

/* NOTE: Currently, we only EA if address translation is successful.
   This may need revisiting. */
function clause execute (AMO(op, aq, rl, rs2, rs1, width, rd)) = {
  let 'width = width;

  // This is checked during decoding.
  assert(width <= xlen_bytes);

  /* Get the address, X(rs1) (no offset).
    * Some extensions perform additional checks on address validity.
    */
  match ext_data_get_addr(rs1, zeros(), ReadWrite(Data, Data), width) {
    Ext_DataAddr_Error(e)  => Ext_DataAddr_Check_Failure(e),
    Ext_DataAddr_OK(vaddr) => {
      if not(is_aligned_addr(bits_of(vaddr), width))
      then Memory_Exception(vaddr, E_SAMO_Addr_Align())
      else match translateAddr(vaddr, ReadWrite(Data, Data)) {
        Err(e, _) => Memory_Exception(vaddr, e),
        Ok(addr, _) => {
          let rs2_val = X(rs2)[width * 8 - 1 .. 0];
          match mem_write_ea(addr, width, aq & rl, rl, true) {
            Err(e) => Memory_Exception(vaddr, e),
            Ok(_) => {
              match mem_read(ReadWrite(Data, Data), addr, width, aq, aq & rl, true) {
                Err(e)     => Memory_Exception(vaddr, e),
                Ok(loaded) => {
                  let result : bits('width * 8) =
                    match op {
                      AMOSWAP => rs2_val,
                      AMOADD  => rs2_val + loaded,
                      AMOXOR  => rs2_val ^ loaded,
                      AMOAND  => rs2_val & loaded,
                      AMOOR   => rs2_val | loaded,
                      AMOMIN  => if rs2_val <_s loaded then rs2_val else loaded,
                      AMOMAX  => if rs2_val >_s loaded then rs2_val else loaded,
                      AMOMINU => if rs2_val <_u loaded then rs2_val else loaded,
                      AMOMAXU => if rs2_val >_u loaded then rs2_val else loaded,
                    };
                  match mem_write_value(addr, width, sign_extend(result), aq & rl, rl, true) {
                    Ok(true)  => { X(rd) = sign_extend(loaded); RETIRE_SUCCESS },
                    Ok(false) => { internal_error(__FILE__, __LINE__, "AMO got false from mem_write_value") },
                    Err(e)    => Memory_Exception(vaddr, e),
                  }
                }
              }
            }
          }
        }
      }
    }
  }
}

mapping amo_mnemonic : amoop <-> string = {
  AMOSWAP <-> "amoswap",
  AMOADD  <-> "amoadd",
  AMOXOR  <-> "amoxor",
  AMOAND  <-> "amoand",
  AMOOR   <-> "amoor",
  AMOMIN  <-> "amomin",
  AMOMAX  <-> "amomax",
  AMOMINU <-> "amominu",
  AMOMAXU <-> "amomaxu"
}

mapping maybe_aqrl : (bool, bool) <-> string = {
  (true, true)   <-> ".aqrl",
  (true, false)  <-> ".aq",
  (false, true)  <-> ".rl",
  (false, false) <-> "",
}

mapping clause assembly = AMO(op, aq, rl, rs2, rs1, width, rd)
  <-> amo_mnemonic(op) ^ "." ^ size_mnemonic(width) ^ maybe_aqrl(aq, rl) ^ spc() ^ reg_name(rd) ^ sep() ^ reg_name(rs2) ^ sep() ^ "(" ^ reg_name(rs1) ^ ")"
