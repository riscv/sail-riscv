/*=======================================================================================*/
/*  This Sail RISC-V architecture model, comprising all files and                        */
/*  directories except where otherwise noted is subject the BSD                          */
/*  two-clause license in the LICENSE file.                                              */
/*                                                                                       */
/*  SPDX-License-Identifier: BSD-2-Clause                                                */
/*=======================================================================================*/

/* ****************************************************************** */
/* This file specifies the atomic instructions in the 'A' extension.  */

/* ****************************************************************** */

function clause currentlyEnabled(Ext_A) = hartSupports(Ext_A) & misa[A] == 0b1
function clause currentlyEnabled(Ext_Zabha) = hartSupports(Ext_Zabha) & currentlyEnabled(Ext_Zaamo)

// Some print utils for lr/sc.

function aqrl_str(aq : bool, rl : bool) -> string =
  match (aq, rl) {
    (false, false) => "",
    (false, true)  => ".rl",
    (true, false)  => ".aq",
    (true, true)   => ".aqrl"
  }

function lrsc_width_str(width : word_width) -> string =
  match width {
    BYTE   => ".b",
    HALF   => ".h",
    WORD   => ".w",
    DOUBLE => ".d"
  }

/**
 * RISC-V A-extension defines LR / SC / AMOs for word and double
 * RISC-V Zabha extension defines AMOs for byte and halfword
 */
function lrsc_width_valid(size : word_width) -> bool = {
  match size {
    WORD   => true,
    DOUBLE => xlen >= 64,
    _      => false
  }
}

function amo_width_valid(size : word_width) -> bool = {
  match size {
    BYTE   => currentlyEnabled(Ext_Zabha),
    HALF   => currentlyEnabled(Ext_Zabha),
    WORD   => true,
    DOUBLE => xlen >= 64,
  }
}

/* ****************************************************************** */
function clause currentlyEnabled(Ext_Zalrsc) = hartSupports(Ext_Zalrsc) | currentlyEnabled(Ext_A)

union clause ast = LOADRES : (bool, bool, regidx, word_width, regidx)

mapping clause encdec = LOADRES(aq, rl, rs1, size, rd)
  <-> 0b00010 @ bool_bits(aq) @ bool_bits(rl) @ 0b00000 @ encdec_reg(rs1) @ 0b0 @ size_enc(size) @ encdec_reg(rd) @ 0b0101111
  when currentlyEnabled(Ext_Zalrsc) & lrsc_width_valid(size)

/* We could set load-reservations on physical or virtual addresses.
 * However most chips (especially multi-core) will use physical addresses.
 * Additionally, matching on physical addresses allows as many SC's to
 * succeed as the spec allows. This simplifies verification against real chips
 * since you can force spurious failures from a DUT into the Sail model and
 * then compare the result (a kind of one-way waiver). Using virtual addresses
 * requires cancelling the reservation in some additional places, e.g. xRET, and
 * that will break comparison with a DUT that doesn't require cancellation there.
 */

function clause execute(LOADRES(aq, rl, rs1, width, rd)) = {
  let width_bytes = size_bytes(width);

  // This is checked during decoding.
  assert(width_bytes <= xlen_bytes);

  /* Get the address, X(rs1) (no offset).
    * Extensions might perform additional checks on address validity.
    */
  match ext_data_get_addr(rs1, zeros(), Read(Data), width_bytes) {
    Ext_DataAddr_Error(e)  => Ext_DataAddr_Check_Failure(e),
    Ext_DataAddr_OK(vaddr) => {
      /* "LR faults like a normal load, even though it's in the AMO major opcode space."
        * - Andrew Waterman, isa-dev, 10 Jul 2018.
        */
      if not(is_aligned(bits_of(vaddr), width))
      then Memory_Exception(vaddr, E_Load_Addr_Align())
      else match translateAddr(vaddr, Read(Data)) {
        TR_Failure(e, _)    => Memory_Exception(vaddr, e),
        TR_Address(addr, _) =>
          match mem_read(Read(Data), addr, width_bytes, aq, aq & rl, true) {
            Ok(result) => { load_reservation(bits_of(addr)); X(rd) = sign_extend(result); RETIRE_SUCCESS },
            Err(e)     => Memory_Exception(vaddr, e),
          },
      }
    }
  }
}

mapping clause assembly = LOADRES(aq, rl, rs1, size, rd)
  <-> "lr." ^ size_mnemonic(size) ^ maybe_aq(aq) ^ maybe_rl(rl) ^ spc() ^ reg_name(rd) ^ sep() ^ "(" ^ reg_name(rs1) ^ ")"

/* ****************************************************************** */
union clause ast = STORECON : (bool, bool, regidx, regidx, word_width, regidx)

mapping clause encdec = STORECON(aq, rl, rs2, rs1, size, rd)
  <-> 0b00011 @ bool_bits(aq) @ bool_bits(rl) @ encdec_reg(rs2) @ encdec_reg(rs1) @ 0b0 @ size_enc(size) @ encdec_reg(rd) @ 0b0101111
  when currentlyEnabled(Ext_Zalrsc) & lrsc_width_valid(size)

/* NOTE: Currently, we only EA if address translation is successful. This may need revisiting. */
function clause execute (STORECON(aq, rl, rs2, rs1, width, rd)) = {
  let width_bytes = size_bytes(width);

  // This is checked during decoding.
  assert(width_bytes <= xlen_bytes);

  if speculate_conditional () == false then {
    /* should only happen in rmem
     * rmem: allow SC to fail very early
     */
    X(rd) = zero_extend(0b1); RETIRE_SUCCESS
  } else {
    /* normal non-rmem case
      * rmem: SC is allowed to succeed (but might fail later)
      */
    /* Get the address, X(rs1) (no offset).
      * Extensions might perform additional checks on address validity.
      */
    match ext_data_get_addr(rs1, zeros(), Write(Data), width_bytes) {
      Ext_DataAddr_Error(e)  => Ext_DataAddr_Check_Failure(e),
      Ext_DataAddr_OK(vaddr) => {
        if not(is_aligned(bits_of(vaddr), width))
        then Memory_Exception(vaddr, E_SAMO_Addr_Align())
        else {
          match translateAddr(vaddr, Write(Data)) {  /* Write and ReadWrite are equivalent here:
                                                      * both result in a SAMO exception */
            TR_Failure(e, _) => Memory_Exception(vaddr, e),
            TR_Address(addr, _) => {
              // Check reservation with physical address.
              if not(match_reservation(bits_of(addr))) then {
                /* cannot happen in rmem */
                X(rd) = zero_extend(0b1); cancel_reservation(); RETIRE_SUCCESS
              } else {
                match mem_write_ea(addr, width_bytes, aq & rl, rl, true) {
                  Err(e) => Memory_Exception(vaddr, e),
                  Ok(_)  => {
                    let rs2_val = X(rs2);
                    match mem_write_value(addr, width_bytes, rs2_val[width_bytes * 8 - 1 .. 0], aq & rl, rl, true) {
                      Ok(true)  => { X(rd) = zero_extend(0b0); cancel_reservation(); RETIRE_SUCCESS },
                      Ok(false) => { X(rd) = zero_extend(0b1); cancel_reservation(); RETIRE_SUCCESS },
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

mapping clause assembly = STORECON(aq, rl, rs2, rs1, size, rd)
  <-> "sc." ^ size_mnemonic(size) ^ maybe_aq(aq) ^ maybe_rl(rl) ^ spc() ^ reg_name(rd) ^ sep() ^ reg_name(rs2) ^ sep() ^ "(" ^ reg_name(rs1) ^ ")"

/* ****************************************************************** */
function clause currentlyEnabled(Ext_Zaamo) = hartSupports(Ext_Zaamo) | currentlyEnabled(Ext_A)

union clause ast = AMO : (amoop, bool, bool, regidx, regidx, word_width, regidx)

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
  let 'width_bytes = size_bytes(width);

  // This is checked during decoding.
  assert(width_bytes <= xlen_bytes);

  /* Get the address, X(rs1) (no offset).
    * Some extensions perform additional checks on address validity.
    */
  match ext_data_get_addr(rs1, zeros(), ReadWrite(Data, Data), width_bytes) {
    Ext_DataAddr_Error(e)  => Ext_DataAddr_Check_Failure(e),
    Ext_DataAddr_OK(vaddr) => {
      if not(is_aligned(bits_of(vaddr), width))
      then Memory_Exception(vaddr, E_SAMO_Addr_Align())
      else match translateAddr(vaddr, ReadWrite(Data, Data)) {
        TR_Failure(e, _) => Memory_Exception(vaddr, e),
        TR_Address(addr, _) => {
          let rs2_val = X(rs2)[width_bytes * 8 - 1 .. 0];
          match mem_write_ea(addr, width_bytes, aq & rl, rl, true) {
            Err(e) => Memory_Exception(vaddr, e),
            Ok(_) => {
              match mem_read(ReadWrite(Data, Data), addr, width_bytes, aq, aq & rl, true) {
                Err(e)     => Memory_Exception(vaddr, e),
                Ok(loaded) => {
                  let result : bits('width_bytes * 8) =
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
                  match mem_write_value(addr, width_bytes, sign_extend(result), aq & rl, rl, true) {
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

mapping clause assembly = AMO(op, aq, rl, rs2, rs1, width, rd)
  <-> amo_mnemonic(op) ^ "." ^ size_mnemonic(width) ^ maybe_aq(aq) ^ maybe_rl(rl) ^ spc() ^ reg_name(rd) ^ sep() ^ reg_name(rs2) ^ sep() ^ "(" ^ reg_name(rs1) ^ ")"
