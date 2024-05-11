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
// Some print utils for lr/sc.

function aqrl_str(aq : bool, rl : bool) -> string =
  match (aq, rl) {
    (false, false) => "",
    (false, true)  => ".rl",
    (true, false)  => ".aq",
    (true, true)   => ".aqrl"
  }

function lrsc_width_str(width : word_width) -> string =
  match (width) {
    BYTE   => ".b",
    HALF   => ".h",
    WORD   => ".w",
    DOUBLE => ".d"
  }

/**
 * RISC-V only appears to define LR / SC / AMOs for word and double, although
 * there seem to be encodings reserved for other widths.
 */
function lrsc_width_valid(size : word_width) -> bool = {
  match(size) {
    WORD   => true,
    DOUBLE => sizeof(xlen) >= 64,
    _      => false
  }
}

/* ****************************************************************** */
union clause ast = LOADRES : (bool, bool, regidx, word_width, regidx)

mapping clause encdec = LOADRES(aq, rl, rs1, size, rd) if lrsc_width_valid(size)
  <-> 0b00010 @ bool_bits(aq) @ bool_bits(rl) @ 0b00000 @ rs1 @ 0b0 @ size_enc(size) @ rd @ 0b0101111 if lrsc_width_valid(size)

/* We could set load-reservations on physical or virtual addresses.
 * For now we set them on virtual addresses, since it makes the
 * sequential model of SC a bit simpler, at the cost of an explicit
 * call to load_reservation in LR and cancel_reservation in SC.
 */

val process_loadres : forall 'n, 0 < 'n <= xlen_bytes. (regidx, xlenbits, MemoryOpResult(bits(8 * 'n)), bool) -> Retired
function process_loadres(rd, addr, value, is_unsigned) =
  match extend_value(is_unsigned, value) {
    MemValue(result) => { load_reservation(addr); X(rd) = result; RETIRE_SUCCESS },
    MemException(e)  => { handle_mem_exception(addr, e); RETIRE_FAIL }
  }

function clause execute(LOADRES(aq, rl, rs1, width, rd)) = {
  if haveAtomics() then {
    /* Get the address, X(rs1) (no offset).
     * Extensions might perform additional checks on address validity.
     */
    match ext_data_get_addr(rs1, zeros(), Read(Data), width) {
      Ext_DataAddr_Error(e)  => { ext_handle_data_check_error(e); RETIRE_FAIL },
      Ext_DataAddr_OK(vaddr) => {
        let aligned : bool =
           /* BYTE and HALF would only occur due to invalid decodes, but it doesn't hurt
            * to treat them as valid here; otherwise we'd need to throw an internal_error.
            */
           match width {
             BYTE   => true,
             HALF   => vaddr[0..0] == 0b0,
             WORD   => vaddr[1..0] == 0b00,
             DOUBLE => vaddr[2..0] == 0b000
           };
        /* "LR faults like a normal load, even though it's in the AMO major opcode space."
         * - Andrew Waterman, isa-dev, 10 Jul 2018.
         */
        if not(aligned)
        then { handle_mem_exception(vaddr, E_Load_Addr_Align()); RETIRE_FAIL }
        else match translateAddr(vaddr, Read(Data)) {
               TR_Failure(e, _)    => { handle_mem_exception(vaddr, e); RETIRE_FAIL },
               TR_Address(addr, _) =>
                 match (width, sizeof(xlen)) {
                   (BYTE, _)    => process_loadres(rd, vaddr, mem_read(Read(Data), addr, 1, aq, aq & rl, true), false),
                   (HALF, _)    => process_loadres(rd, vaddr, mem_read(Read(Data), addr, 2, aq, aq & rl, true), false),
                   (WORD, _)    => process_loadres(rd, vaddr, mem_read(Read(Data), addr, 4, aq, aq & rl, true), false),
                   (DOUBLE, 64) => process_loadres(rd, vaddr, mem_read(Read(Data), addr, 8, aq, aq & rl, true), false),
                   _            => internal_error(__FILE__, __LINE__, "Unexpected AMO width")
                 }
             }
      }
    }
  } else {
    handle_illegal();
    RETIRE_FAIL
  }
}

mapping clause assembly = LOADRES(aq, rl, rs1, size, rd)
  <-> "lr." ^ size_mnemonic(size) ^ maybe_aq(aq) ^ maybe_rl(rl) ^ spc() ^ reg_name(rd) ^ sep() ^ "(" ^ reg_name(rs1) ^ ")"

/* ****************************************************************** */
union clause ast = STORECON : (bool, bool, regidx, regidx, word_width, regidx)

mapping clause encdec = STORECON(aq, rl, rs2, rs1, size, rd) if lrsc_width_valid(size)
  <-> 0b00011 @ bool_bits(aq) @ bool_bits(rl) @ rs2 @ rs1 @ 0b0 @ size_enc(size) @ rd @ 0b0101111 if lrsc_width_valid(size)

/* NOTE: Currently, we only EA if address translation is successful. This may need revisiting. */
function clause execute (STORECON(aq, rl, rs2, rs1, width, rd)) = {
  if speculate_conditional () == false then {
    /* should only happen in rmem
     * rmem: allow SC to fail very early
     */
    X(rd) = zero_extend(0b1); RETIRE_SUCCESS
  } else {
    if haveAtomics() then {
      /* normal non-rmem case
       * rmem: SC is allowed to succeed (but might fail later)
       */
      /* Get the address, X(rs1) (no offset).
       * Extensions might perform additional checks on address validity.
       */
      match ext_data_get_addr(rs1, zeros(), Write(Data), width) {
        Ext_DataAddr_Error(e)  => { ext_handle_data_check_error(e); RETIRE_FAIL },
        Ext_DataAddr_OK(vaddr) => {
          let aligned : bool =
            /* BYTE and HALF would only occur due to invalid decodes, but it doesn't hurt
             * to treat them as valid here; otherwise we'd need to throw an internal_error.
             */
            match width {
              BYTE   => true,
              HALF   => vaddr[0..0] == 0b0,
              WORD   => vaddr[1..0] == 0b00,
              DOUBLE => vaddr[2..0] == 0b000
            };
          if not(aligned)
          then { handle_mem_exception(vaddr, E_SAMO_Addr_Align()); RETIRE_FAIL }
          else {
            if match_reservation(vaddr) == false then {
              /* cannot happen in rmem */
              X(rd) = zero_extend(0b1); cancel_reservation(); RETIRE_SUCCESS
            } else {
              match translateAddr(vaddr, Write(Data)) {  /* Write and ReadWrite are equivalent here:
                                                          * both result in a SAMO exception */
                TR_Failure(e, _) => { handle_mem_exception(vaddr, e); RETIRE_FAIL },
                TR_Address(addr, _) => {
                  let eares : MemoryOpResult(unit) = match (width, sizeof(xlen)) {
                    (BYTE, _)    => mem_write_ea(addr, 1, aq & rl, rl, true),
                    (HALF, _)    => mem_write_ea(addr, 2, aq & rl, rl, true),
                    (WORD, _)    => mem_write_ea(addr, 4, aq & rl, rl, true),
                    (DOUBLE, 64) => mem_write_ea(addr, 8, aq & rl, rl, true),
                    _            => internal_error(__FILE__, __LINE__, "STORECON expected word or double")
                  };
                  match (eares) {
                    MemException(e) => { handle_mem_exception(vaddr, e); RETIRE_FAIL },
                    MemValue(_) => {
                      rs2_val = X(rs2);
                      let res : MemoryOpResult(bool) = match (width, sizeof(xlen)) {
                        (BYTE, _)    => mem_write_value(addr, 1, rs2_val[7..0], aq & rl, rl, true),
                        (HALF, _)    => mem_write_value(addr, 2, rs2_val[15..0], aq & rl, rl, true),
                        (WORD, _)    => mem_write_value(addr, 4, rs2_val[31..0], aq & rl, rl, true),
                        (DOUBLE, 64) => mem_write_value(addr, 8, rs2_val,        aq & rl, rl, true),
                        _            => internal_error(__FILE__, __LINE__, "STORECON expected word or double")
                      };
                      match (res) {
                        MemValue(true)  => { X(rd) = zero_extend(0b0); cancel_reservation(); RETIRE_SUCCESS },
                        MemValue(false) => { X(rd) = zero_extend(0b1); cancel_reservation(); RETIRE_SUCCESS },
                        MemException(e) => { handle_mem_exception(vaddr, e); RETIRE_FAIL }
                      }
                    }
                  }
                }
              }
            }
          }
        }
      }
    } else {
      handle_illegal();
      RETIRE_FAIL
    }
  }
}

mapping clause assembly = STORECON(aq, rl, rs2, rs1, size, rd)
  <-> "sc." ^ size_mnemonic(size) ^ maybe_aq(aq) ^ maybe_rl(rl) ^ spc() ^ reg_name(rd) ^ sep() ^ reg_name(rs2) ^ sep() ^ "(" ^ reg_name(rs1) ^ ")"

/* ****************************************************************** */
union clause ast = AMO : (amoop, bool, bool, regidx, regidx, amo_word_width, regidx)

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
  AMOCAS  <-> 0b00101
}

/**
 * RISC-V only appears to define AMO for word and double, although
 * there seem to be encodings reserved for other widths.
 * zacas: amocas.d supported for RV32 and amocas.q for RV64
 * amocas that operate on 2*XLEN data requires the first register
 * of the register pair to be even numbered. RV32 supports amocas.d.
 */
function amo_encoding_valid(size : amo_word_width, op : amoop, rs2 : regidx, rd : regidx ) -> bool = {
  match(size, sizeof(xlen), op) {
    (AMO_WORD,   32, AMOCAS) => haveZacas(),
    (AMO_WORD,   64, AMOCAS) => haveZacas(),
    (AMO_WORD,    _, _)      => true,
    (AMO_DOUBLE, 32, AMOCAS) => if rs2[0..0] != 0b0 | rd[0..0] != 0b0 then false else haveZacas(),
    (AMO_DOUBLE, 64, AMOCAS) => haveZacas(),
    (AMO_DOUBLE,  _, _)      => sizeof(xlen) >= 64,
    (AMO_QUAD,   64, AMOCAS) => if rs2[0..0] != 0b0 | rd[0..0] != 0b0 then false else haveZacas(),
    (AMO_QUAD,    _, _)      => false,
     _                       => false
  }
}

mapping clause encdec = AMO(op, aq, rl, rs2, rs1, size, rd) if amo_encoding_valid(size, op, rs2, rd)
  <-> encdec_amoop(op) @ bool_bits(aq) @ bool_bits(rl) @ rs2 @ rs1 @ amo_size_enc(size) @ rd @ 0b0101111 if amo_encoding_valid(size, op, rs2, rd)

/* NOTE: Currently, we only EA if address translation is successful.
   This may need revisiting. */
function clause execute (AMO(op, aq, rl, rs2, rs1, width, rd)) = {
  if haveAtomics() then {
    /* Get the address, X(rs1) (no offset).
     * Some extensions perform additional checks on address validity.
     */
    match ext_data_get_amo_addr(rs1, ReadWrite(Data, Data), width) {
      Ext_DataAddr_Error(e)  => { ext_handle_data_check_error(e); RETIRE_FAIL },
      Ext_DataAddr_OK(vaddr) => {
        match translateAddr(vaddr, ReadWrite(Data, Data)) {
          TR_Failure(e, _) => { handle_mem_exception(vaddr, e); RETIRE_FAIL },
          TR_Address(addr, _) => {
            let eares : MemoryOpResult(unit) = match (width, sizeof(xlen)) {
              (AMO_BYTE, _)    => mem_write_ea(addr, 1, aq & rl, rl, true),
              (AMO_HALF, _)    => mem_write_ea(addr, 2, aq & rl, rl, true),
              (AMO_WORD, _)    => mem_write_ea(addr, 4, aq & rl, rl, true),
              (AMO_DOUBLE, _)  => mem_write_ea(addr, 8, aq & rl, rl, true),
              (AMO_QUAD, 64)   => mem_write_ea(addr, 16, aq & rl, rl, true),
              _            => internal_error(__FILE__, __LINE__, "Unexpected AMO width")
            };
            let is_unsigned : bool = match op {
              AMOMINU => true,
              AMOMAXU => true,
              _       => false
            };
            let rd_val : xlenbits = match width {
              AMO_BYTE   => if is_unsigned then zero_extend(X(rd)[7..0])  else sign_extend(X(rd)[7..0]),
              AMO_HALF   => if is_unsigned then zero_extend(X(rd)[15..0]) else sign_extend(X(rd)[15..0]),
              AMO_WORD   => if is_unsigned then zero_extend(X(rd)[31..0]) else sign_extend(X(rd)[31..0]),
              AMO_DOUBLE => X(rd),
              AMO_QUAD   => X(rd)
            };
            let rs2_val : xlenbits = match width {
              AMO_BYTE   => if is_unsigned then zero_extend(X(rs2)[7..0])  else sign_extend(X(rs2)[7..0]),
              AMO_HALF   => if is_unsigned then zero_extend(X(rs2)[15..0]) else sign_extend(X(rs2)[15..0]),
              AMO_WORD   => if is_unsigned then zero_extend(X(rs2)[31..0]) else sign_extend(X(rs2)[31..0]),
              AMO_DOUBLE => X(rs2),
              AMO_QUAD   => X(rs2)
            };
            /* AMOCAS.W for RV32 and AMOCAS.Q for RV64 operate on a pair of
             * register. When the first register of a source register pair is
             * x0, then both halves of the pair read as zero.
             */
            let rd_plus_one  : regidx =
              match (width, sizeof(xlen), op) {
                (AMO_DOUBLE, 32, AMOCAS) => if (rd != zreg) then (rd + 1) else zeros(),
                (AMO_QUAD,   64, AMOCAS) => if (rd != zreg) then (rd + 1) else zeros(),
                _ => zeros()
              };
            let rs2_plus_one : regidx =
              match (width, sizeof(xlen), op) {
                (AMO_DOUBLE, 32, AMOCAS) => if (rs2 != zreg) then (rs2 + 1) else zeros(),
                (AMO_QUAD,   64, AMOCAS) => if (rs2 != zreg) then (rs2 + 1) else zeros(),
                _ => zeros()
              };
            let rd_plus_one_val  : xlenbits = zero_extend(X(rd_plus_one));
            let rs2_plus_one_val : xlenbits = zero_extend(X(rs2_plus_one));
            /* AMOCAS has release semantics only if AMOCAS is successful */
            let amo_rd_rl : bool = match op {
                AMOCAS => false,
                _      => aq & rl
            };
            match (eares) {
              MemException(e) => { handle_mem_exception(vaddr, e); RETIRE_FAIL },
              MemValue(_) => {
                let mval : MemoryOpResult(xlenbits) = match (width, sizeof(xlen)) {
                  (AMO_BYTE, _)    => extend_value(is_unsigned, mem_read(ReadWrite(Data, Data), addr, 1, aq, amo_rd_rl, true)),
                  (AMO_HALF, _)    => extend_value(is_unsigned, mem_read(ReadWrite(Data, Data), addr, 2, aq, amo_rd_rl, true)),
                  (AMO_WORD, _)    => extend_value(is_unsigned, mem_read(ReadWrite(Data, Data), addr, 4, aq, amo_rd_rl, true)),
                  (AMO_DOUBLE, 64) => extend_value(is_unsigned, mem_read(ReadWrite(Data, Data), addr, 8, aq, amo_rd_rl, true)),
                  (AMO_DOUBLE, 32) => extend_value(is_unsigned, mem_read(ReadWrite(Data, Data), addr, 4, aq, amo_rd_rl, true)),
                  (AMO_QUAD,   64) => extend_value(is_unsigned, mem_read(ReadWrite(Data, Data), addr, 8, aq, amo_rd_rl, true)),
                  _            => internal_error(__FILE__, __LINE__, "Unexpected AMO width")
                };
                let mval_high : MemoryOpResult(xlenbits) = match (width, sizeof(xlen)) {
                  (AMO_DOUBLE, 32) => extend_value(is_unsigned, mem_read(ReadWrite(Data, Data), addr+4, 4, aq, amo_rd_rl, true)),
                  (AMO_QUAD,   64) => extend_value(is_unsigned, mem_read(ReadWrite(Data, Data), addr+8, 8, aq, amo_rd_rl, true)),
                  _                => MemValue(zeros())
                };
                match (mval) {
                  MemException(e)  => { handle_mem_exception(vaddr, e); RETIRE_FAIL },
                  MemValue(loaded) => {
                    match (mval_high) {
                      MemException(e)  => { handle_mem_exception(addr, e); RETIRE_FAIL },
                      MemValue(loaded_high) => {
                        let result : xlenbits =
                          match op {
                            AMOSWAP => rs2_val,
                            AMOADD  => rs2_val + loaded,
                            AMOXOR  => rs2_val ^ loaded,
                            AMOAND  => rs2_val & loaded,
                            AMOOR   => rs2_val | loaded,
                            AMOCAS  => rs2_val,

                            /* These operations convert bitvectors to integer values using [un]signed,
                             * and back using to_bits().
                             */
                            AMOMIN  => to_bits(sizeof(xlen), min(signed(rs2_val),   signed(loaded))),
                            AMOMAX  => to_bits(sizeof(xlen), max(signed(rs2_val),   signed(loaded))),
                            AMOMINU => to_bits(sizeof(xlen), min(unsigned(rs2_val), unsigned(loaded))),
                            AMOMAXU => to_bits(sizeof(xlen), max(unsigned(rs2_val), unsigned(loaded)))
                          };
                        let result_high : xlenbits =
                          match op {
                            AMOCAS  => rs2_plus_one_val,
                            _       => zeros(),
                          };
                        let amo_does_write : bool =
                          match (op, sizeof(xlen), width) {
                            (AMOCAS, 32, AMO_WORD)   => if ( loaded == rd_val ) then true else false,
                            (AMOCAS, 32, AMO_DOUBLE) => if ( loaded == rd_val & loaded_high == rd_plus_one_val ) then true else false,
                            (AMOCAS, 64, AMO_WORD)   => if ( loaded == rd_val ) then true else false,
                            (AMOCAS, 64, AMO_DOUBLE) => if ( loaded == rd_val ) then true else false,
                            (AMOCAS, 64, AMO_QUAD)   => if ( loaded == rd_val & loaded_high == rd_plus_one_val ) then true else false,
                            (_,      _, _)           => true
                          };
                        let rval : xlenbits = match width {
                          AMO_BYTE   => sign_extend(loaded[7..0]),
                          AMO_HALF   => sign_extend(loaded[15..0]),
                          AMO_WORD   => sign_extend(loaded[31..0]),
                          AMO_DOUBLE => loaded,
                          AMO_QUAD   => loaded
                        };
                        let rval_high : xlenbits = match width {
                          AMO_DOUBLE => loaded_high,
                          AMO_QUAD   => loaded_high,
                          _          => zeros()
                        };
                        let wval : MemoryOpResult(bool) = match (width, sizeof(xlen), amo_does_write) {
                          (AMO_BYTE,    _, true)  => mem_write_value(addr, 1, result[7..0],  aq & rl, rl, true),
                          (AMO_HALF,    _, true)  => mem_write_value(addr, 2, result[15..0], aq & rl, rl, true),
                          (AMO_WORD,    _, true)  => mem_write_value(addr, 4, result[31..0], aq & rl, rl, true),
                          (AMO_DOUBLE, 32, true)  => mem_write_value(addr, 4, result,        aq & rl, rl, true),
                          (AMO_DOUBLE, 64, true)  => mem_write_value(addr, 8, result,        aq & rl, rl, true),
                          (AMO_QUAD,   64, true)  => mem_write_value(addr, 8, result,        aq & rl, rl, true),
                          _                       => MemValue(true)
                        };
                        match (wval) {
                          MemValue(true)  => {
                            let wval_high : MemoryOpResult(bool) =
                              match (width, sizeof(xlen), amo_does_write) {
                                (AMO_DOUBLE, 32, true) => mem_write_value(addr+4, 4, result_high, aq & rl, rl, true),
                                (AMO_QUAD,   64, true) => mem_write_value(addr+8, 8, result_high, aq & rl, rl, true),
                                _                      => MemValue(true)
                              };
                            match (wval_high) {
                              MemValue(true)  => { X(rd) = rval; X(rd_plus_one) = rval_high; RETIRE_SUCCESS},
                              MemValue(false) => { internal_error(__FILE__, __LINE__, "AMO got false from mem_write_value") },
                              MemException(e) => { handle_mem_exception(vaddr, e); RETIRE_FAIL }
                            }
                          },
                          MemValue(false) => { internal_error(__FILE__, __LINE__, "AMO got false from mem_write_value") },
                          MemException(e) => { handle_mem_exception(vaddr, e); RETIRE_FAIL }
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
  } else {
    handle_illegal();
    RETIRE_FAIL
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
  AMOCAS  <-> "amocas"
}

mapping clause assembly = AMO(op, aq, rl, rs2, rs1, width, rd)
  <-> amo_mnemonic(op) ^ "." ^ amo_size_mnemonic(width) ^ maybe_aq(aq) ^ maybe_rl(rl) ^ spc() ^ reg_name(rd) ^ sep() ^ reg_name(rs2) ^ sep() ^ "(" ^ reg_name(rs1) ^ ")"
