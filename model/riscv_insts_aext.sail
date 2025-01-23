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

function clause extensionEnabled(Ext_Zabha) = true

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
    BYTE   => extensionEnabled(Ext_Zabha),
    HALF   => extensionEnabled(Ext_Zabha),
    WORD   => true,
    DOUBLE => xlen >= 64,
  }
}

/* ****************************************************************** */
function clause extensionEnabled(Ext_Zalrsc) = misa[A] == 0b1

union clause ast = LOADRES : (bool, bool, regidx, word_width, regidx)

mapping clause encdec = LOADRES(aq, rl, rs1, size, rd)                                                if extensionEnabled(Ext_Zalrsc) & lrsc_width_valid(size)
  <-> 0b00010 @ bool_bits(aq) @ bool_bits(rl) @ 0b00000 @ rs1 @ 0b0 @ size_enc(size) @ rd @ 0b0101111 if extensionEnabled(Ext_Zalrsc) & lrsc_width_valid(size)

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
    Ext_DataAddr_Error(e)  => { ext_handle_data_check_error(e); RETIRE_FAIL },
    Ext_DataAddr_OK(vaddr) => {
      /* "LR faults like a normal load, even though it's in the AMO major opcode space."
        * - Andrew Waterman, isa-dev, 10 Jul 2018.
        */
      if not(is_aligned(virtaddr_bits(vaddr), width))
      then { handle_mem_exception(vaddr, E_Load_Addr_Align()); RETIRE_FAIL }
      else match translateAddr(vaddr, Read(Data)) {
        TR_Failure(e, _)    => { handle_mem_exception(vaddr, e); RETIRE_FAIL },
        TR_Address(addr, _) =>
          match mem_read(Read(Data), addr, width_bytes, aq, aq & rl, true) {
            Ok(result) => { load_reservation(physaddr_bits(addr)); X(rd) = sign_extend(result); RETIRE_SUCCESS },
            Err(e)     => { handle_mem_exception(vaddr, e); RETIRE_FAIL }
          },
      }
    }
  }
}

mapping clause assembly = LOADRES(aq, rl, rs1, size, rd)
  <-> "lr." ^ size_mnemonic(size) ^ maybe_aq(aq) ^ maybe_rl(rl) ^ spc() ^ reg_name(rd) ^ sep() ^ "(" ^ reg_name(rs1) ^ ")"

/* ****************************************************************** */
union clause ast = STORECON : (bool, bool, regidx, regidx, word_width, regidx)

mapping clause encdec = STORECON(aq, rl, rs2, rs1, size, rd)                                      if extensionEnabled(Ext_Zalrsc) & lrsc_width_valid(size)
  <-> 0b00011 @ bool_bits(aq) @ bool_bits(rl) @ rs2 @ rs1 @ 0b0 @ size_enc(size) @ rd @ 0b0101111 if extensionEnabled(Ext_Zalrsc) & lrsc_width_valid(size)

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
      Ext_DataAddr_Error(e)  => { ext_handle_data_check_error(e); RETIRE_FAIL },
      Ext_DataAddr_OK(vaddr) => {
        if not(is_aligned(virtaddr_bits(vaddr), width))
        then { handle_mem_exception(vaddr, E_SAMO_Addr_Align()); RETIRE_FAIL }
        else {
          match translateAddr(vaddr, Write(Data)) {  /* Write and ReadWrite are equivalent here:
                                                      * both result in a SAMO exception */
            TR_Failure(e, _) => { handle_mem_exception(vaddr, e); RETIRE_FAIL },
            TR_Address(addr, _) => {
              // Check reservation with physical address.
              if not(match_reservation(physaddr_bits(addr))) then {
                /* cannot happen in rmem */
                X(rd) = zero_extend(0b1); cancel_reservation(); RETIRE_SUCCESS
              } else {
                let eares = mem_write_ea(addr, width_bytes, aq & rl, rl, true);
                match eares {
                  Err(e) => { handle_mem_exception(vaddr, e); RETIRE_FAIL },
                  Ok(_)  => {
                    let rs2_val = X(rs2);
                    match mem_write_value(addr, width_bytes, rs2_val[width_bytes * 8 - 1 .. 0], aq & rl, rl, true) {
                      Ok(true)  => { X(rd) = zero_extend(0b0); cancel_reservation(); RETIRE_SUCCESS },
                      Ok(false) => { X(rd) = zero_extend(0b1); cancel_reservation(); RETIRE_SUCCESS },
                      Err(e)    => { handle_mem_exception(vaddr, e); RETIRE_FAIL }
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
function clause extensionEnabled(Ext_Zaamo) = misa[A] == 0b1

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

mapping clause encdec = AMO(op, aq, rl, rs2, rs1, size, rd)                                                if extensionEnabled(Ext_Zaamo) & amo_width_valid(size)
  <-> encdec_amoop(op) @ bool_bits(aq) @ bool_bits(rl) @ rs2 @ rs1 @ 0b0 @ size_enc(size) @ rd @ 0b0101111 if extensionEnabled(Ext_Zaamo) & amo_width_valid(size)

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
    Ext_DataAddr_Error(e)  => { ext_handle_data_check_error(e); RETIRE_FAIL },
    Ext_DataAddr_OK(vaddr) => {
      if not(is_aligned(virtaddr_bits(vaddr), width))
      then { handle_mem_exception(vaddr, E_SAMO_Addr_Align()); RETIRE_FAIL }
      else match translateAddr(vaddr, ReadWrite(Data, Data)) {
        TR_Failure(e, _) => { handle_mem_exception(vaddr, e); RETIRE_FAIL },
        TR_Address(addr, _) => {
          let eares = mem_write_ea(addr, width_bytes, aq & rl, rl, true);
          let rs2_val = X(rs2)[width_bytes * 8 - 1 .. 0];
          match eares {
            Err(e) => { handle_mem_exception(vaddr, e); RETIRE_FAIL },
            Ok(_) => {
              match mem_read(ReadWrite(Data, Data), addr, width_bytes, aq, aq & rl, true) {
                Err(e)     => { handle_mem_exception(vaddr, e); RETIRE_FAIL },
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
                    Err(e)    => { handle_mem_exception(vaddr, e); RETIRE_FAIL }
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
