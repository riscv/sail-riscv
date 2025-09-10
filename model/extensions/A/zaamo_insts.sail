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
function clause currentlyEnabled(Ext_Zacas) = hartSupports(Ext_Zacas) & currentlyEnabled(Ext_Zaamo)

// Zaamo defines AMOs for 32-bit and 64-bit.
// Zabha defines AMOs for 8-bit and 16-bit.
//
// The Zacas extension adds a CAS operation which support 32, 64
// and 128-bit operands. Only sizes up to XLEN*2 are supported
// (so 128-bit is RV64-only). When XLEN*2 is used the operands
// are stored in even-numbered register pairs.
//
// If Zabha and Zacas are implemented then CAS supports 8 and
// 16-bit operands.
//
function amo_encoding_valid(width : word_width_wide, op : amoop, Regidx(rs2) : regidx, Regidx(rd) : regidx) -> bool =
  // If AMOCAS, check that extension is enabled.
  (if op == AMOCAS then currentlyEnabled(Ext_Zacas) else currentlyEnabled(Ext_Zaamo))
  &
  // Check the size and register alignment.
  (if width < 4 then currentlyEnabled(Ext_Zabha) else (
    width <= xlen_bytes | (op == AMOCAS & width <= xlen_bytes * 2 & rs2[0] == bitzero & rd[0] == bitzero)
  ))

/* ****************************************************************** */

union clause instruction = AMO : (amoop, bool, bool, regidx, regidx, word_width_wide, regidx)

mapping encdec_amoop : amoop <-> bits(5) = {
  AMOSWAP <-> 0b00001,
  AMOADD  <-> 0b00000,
  AMOXOR  <-> 0b00100,
  AMOAND  <-> 0b01100,
  AMOOR   <-> 0b01000,
  AMOMIN  <-> 0b10000,
  AMOMAX  <-> 0b10100,
  AMOMINU <-> 0b11000,
  AMOMAXU <-> 0b11100,
  AMOCAS  <-> 0b00101,
}

mapping clause encdec = AMO(op, aq, rl, rs2, rs1, size, rd)
  <-> encdec_amoop(op) @ bool_bits(aq) @ bool_bits(rl) @ encdec_reg(rs2) @ encdec_reg(rs1) @ width_enc_wide(size) @ encdec_reg(rd) @ 0b0101111
  when amo_encoding_valid(size, op, rs2, rd)

/* NOTE: Currently, we only EA if address translation is successful.
   This may need revisiting. */
function clause execute (AMO(op, aq, rl, rs2, rs1, width, rd)) = {
  let 'width = width;

  // This is checked during decoding.
  assert(width <= xlen_bytes * 2);

  /* Get the address, X(rs1) (no offset).
    * Some extensions perform additional checks on address validity.
    */
  match ext_data_get_addr(rs1, zeros(), ReadWrite(Data, Data), width) {
    Ext_DataAddr_Error(e)  => Ext_DataAddr_Check_Failure(e),
    Ext_DataAddr_OK(vaddr) => {
      if not(is_aligned_addr(vaddr, width))
      then Memory_Exception(vaddr, E_SAMO_Addr_Align())
      else match translateAddr(vaddr, ReadWrite(Data, Data)) {
        Err(e, _) => Memory_Exception(vaddr, e),
        Ok(addr, _) => {
          // AMOCAS.D for RV32 and AMOCAS.Q for RV64 operate on a pair of
          // registers. When the first register of a register pair is
          // x0, then both halves of the pair read/write as zero.
          let rs2_val : bits('width * 8) = if width <= xlen_bytes then trunc(X(rs2)) else trunc(X_pair(rs2));
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
                      // If it *does* store a value, CAS always stores rs2.
                      AMOCAS  => rs2_val,
                    };

                  // All operations except CAS where loaded != X(rd) write their value back.
                  if op == AMOCAS & loaded != (if width <= xlen_bytes then trunc(X(rd)) else trunc(X_pair(rd))) then {
                    // Compared, but didn't swap.
                    if width <= xlen_bytes
                    then X(rd) = sign_extend(loaded)
                    else X_pair(rd) = sign_extend(loaded);
                    RETIRE_SUCCESS
                  } else {
                    match mem_write_value(addr, width, sign_extend(result), aq & rl, rl, true) {
                      Ok(true)  => {
                        if width <= xlen_bytes
                        then X(rd) = sign_extend(loaded)
                        else X_pair(rd) = sign_extend(loaded);
                        RETIRE_SUCCESS
                      },
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
  AMOMAXU <-> "amomaxu",
  AMOCAS  <-> "amocas",
}

mapping clause assembly = AMO(op, aq, rl, rs2, rs1, width, rd)
  <-> amo_mnemonic(op) ^ "." ^ width_mnemonic_wide(width) ^ maybe_aqrl(aq, rl) ^ spc() ^ reg_name(rd) ^ sep() ^ reg_name(rs2) ^ sep() ^ "(" ^ reg_name(rs1) ^ ")"
