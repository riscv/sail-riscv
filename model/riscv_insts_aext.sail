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

/* ****************************************************************** */
union clause ast = LOADRES : (bool, bool, regbits, word_width, regbits)

mapping clause encdec = LOADRES(aq, rl, rs1, size, rd)
  <-> 0b00010 @ bool_bits(aq) @ bool_bits(rl) @ 0b00000 @ rs1 @ 0b0 @ size_bits(size) @ rd @ 0b0101111

/* We could set load-reservations on physical or virtual addresses.
 * For now we set them on virtual addresses, since it makes the
 * sequential model of SC a bit simpler, at the cost of an explicit
 * call to load_reservation in LR and cancel_reservation in SC.
 */

val process_loadres : forall 'n, 0 < 'n <= xlen_bytes. (regbits, xlenbits, MemoryOpResult(bits(8 * 'n)), bool) -> bool effect {escape, rreg, wreg}
function process_loadres(rd, addr, value, is_unsigned) =
  match extend_value(is_unsigned, value) {
    MemValue(result) => { load_reservation(addr); X(rd) = result; true },
    MemException(e)  => { handle_mem_exception(addr, e); false }
  }

function clause execute(LOADRES(aq, rl, rs1, width, rd)) = {
  if haveAtomics() then {
    let pre_vaddr : xlenbits = X(rs1);
    /* Let extensions get the first check on address validity. */
    match ext_data_check_addr(pre_vaddr, Read, Data, width) {
      Ext_DataAddr_Error(e)  => { ext_handle_data_check_error(e); false },
      Ext_DataAddr_OK(vaddr) => {
        let aligned : bool =
           /* BYTE and HALF would only occur due to invalid decodes, but it doesn't hurt
            * to treat them as valid here; otherwise we'd need to throw an internal_error.
            */
           match width {
             BYTE   => true,
             HALF   => vaddr[0]    == 0b0,
             WORD   => vaddr[1..0] == 0b00,
             DOUBLE => vaddr[2..0] == 0b000
           };
        /* "LR faults like a normal load, even though it's in the AMO major opcode space."
         * - Andrew Waterman, isa-dev, 10 Jul 2018.
         */
        if (~ (aligned))
        then { handle_mem_exception(vaddr, E_Load_Addr_Align); false }
        else match translateAddr(vaddr, Read, Data) {
               TR_Failure(e)    => { handle_mem_exception(vaddr, e); false },
               TR_Address(addr) =>
                 match (width, sizeof(xlen)) {
                   (WORD, _)    => process_loadres(rd, vaddr, mem_read(addr, 4, aq, rl, true), false),
                   (DOUBLE, 64) => process_loadres(rd, vaddr, mem_read(addr, 8, aq, rl, true), false),
                   _            => internal_error("LOADRES expected WORD or DOUBLE")
                 }
             }
      }
    }
  } else {
    handle_illegal();
    false
  }
}

mapping clause assembly = LOADRES(aq, rl, rs1, size, rd)
  <-> "lr." ^ size_mnemonic(size) ^ maybe_aq(aq) ^ maybe_rl(rl) ^ spc() ^ reg_name(rd) ^ sep() ^ reg_name(rs1)

/* ****************************************************************** */
union clause ast = STORECON : (bool, bool, regbits, regbits, word_width, regbits)

mapping clause encdec = STORECON(aq, rl, rs2, rs1, size, rd)
  <-> 0b00011 @ bool_bits(aq) @ bool_bits(rl) @ rs2 @ rs1 @ 0b0 @ size_bits(size) @ rd @ 0b0101111

/* NOTE: Currently, we only EA if address translation is successful. This may need revisiting. */
function clause execute (STORECON(aq, rl, rs2, rs1, width, rd)) = {
  if speculate_conditional () == false then {
    /* should only happen in rmem
     * rmem: allow SC to fail very early
     */
    X(rd) = EXTZ(0b1); true
  } else {
    if haveAtomics() then {
      /* normal non-rmem case
       * rmem: SC is allowed to succeed (but might fail later)
       */
      pre_vaddr : xlenbits = X(rs1);
      /* Let extensions get the first check on address validity. */
      match ext_data_check_addr(pre_vaddr, Read, Data, width) {
        Ext_DataAddr_Error(e)  => { ext_handle_data_check_error(e); false },
        Ext_DataAddr_OK(vaddr) => {
          let aligned : bool =
            /* BYTE and HALF would only occur due to invalid decodes, but it doesn't hurt
             * to treat them as valid here; otherwise we'd need to throw an internal_error.
             */
            match width {
              BYTE   => true,
              HALF   => vaddr[0]    == 0b0,
              WORD   => vaddr[1..0] == 0b00,
              DOUBLE => vaddr[2..0] == 0b000
            };
          if (~ (aligned))
          then { handle_mem_exception(vaddr, E_SAMO_Addr_Align); false }
          else {
            if match_reservation(vaddr) == false then {
              /* cannot happen in rmem */
              X(rd) = EXTZ(0b1); cancel_reservation(); true
            } else {
              match translateAddr(vaddr, Write, Data) {
                TR_Failure(e) => { handle_mem_exception(vaddr, e); false },
                TR_Address(addr) => {
                  let eares : MemoryOpResult(unit) = match (width, sizeof(xlen)) {
                    (WORD, _)    => mem_write_ea(addr, 4, aq, rl, true),
                    (DOUBLE, 64) => mem_write_ea(addr, 8, aq, rl, true),
                    _            => internal_error("STORECON expected word or double")
                  };
                  match (eares) {
                    MemException(e) => { handle_mem_exception(addr, e); false },
                    MemValue(_) => {
                      rs2_val = X(rs2);
                      let res : MemoryOpResult(bool) = match (width, sizeof(xlen)) {
                        (WORD, _)    => mem_write_value(addr, 4, rs2_val[31..0], aq, rl, true),
                        (DOUBLE, 64) => mem_write_value(addr, 8, rs2_val,        aq, rl, true),
                        _            => internal_error("STORECON expected word or double")
                      };
                      match (res) {
                        MemValue(true)  => { X(rd) = EXTZ(0b0); cancel_reservation(); true },
                        MemValue(false) => { X(rd) = EXTZ(0b1); cancel_reservation(); true },
                        MemException(e) => { handle_mem_exception(addr, e); false }
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
      false
    }
  }
}

mapping clause assembly = STORECON(aq, rl, rs2, rs1, size, rd)
  <-> "sc." ^ size_mnemonic(size) ^ maybe_aq(aq) ^ maybe_rl(rl) ^ spc() ^ reg_name(rd) ^ sep() ^ reg_name(rs1) ^ sep() ^ reg_name(rs2)

/* ****************************************************************** */
union clause ast = AMO : (amoop, bool, bool, regbits, regbits, word_width, regbits)

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
  <-> encdec_amoop(op) @ bool_bits(aq) @ bool_bits(rl) @ rs2 @ rs1 @ 0b0 @ size_bits(size) @ rd @ 0b0101111

/* NOTE: Currently, we only EA if address translation is successful.
   This may need revisiting. */
function clause execute (AMO(op, aq, rl, rs2, rs1, width, rd)) = {
  if haveAtomics() then {
    pre_vaddr : xlenbits = X(rs1);
    /* Let extensions get the first check on address validity. */
    match ext_data_check_addr(pre_vaddr, Read, Data, width) {
      Ext_DataAddr_Error(e)  => { ext_handle_data_check_error(e); false },
      Ext_DataAddr_OK(vaddr) => {
        match translateAddr(vaddr, ReadWrite, Data) {
          TR_Failure(e) => { handle_mem_exception(vaddr, e); false },
          TR_Address(addr) => {
            let eares : MemoryOpResult(unit) = match (width, sizeof(xlen)) {
              (WORD, _)    => mem_write_ea(addr, 4, aq & rl, rl, true),
              (DOUBLE, 64) => mem_write_ea(addr, 8, aq & rl, rl, true),
              _            => internal_error ("AMO expected WORD or DOUBLE")
            };
            rs2_val : xlenbits = X(rs2);
            match (eares) {
              MemException(e) => { handle_mem_exception(addr, e); false },
              MemValue(_) => {
                let rval : MemoryOpResult(xlenbits) = match (width, sizeof(xlen)) {
                  (WORD, _)    => extend_value(false, mem_read(addr, 4, aq, aq & rl, true)),
                  (DOUBLE, 64) => extend_value(false, mem_read(addr, 8, aq, aq & rl, true)),
                  _            => internal_error ("AMO expected WORD or DOUBLE")
                };
                match (rval) {
                  MemException(e)  => { handle_mem_exception(addr, e); false },
                  MemValue(loaded) => {
                    result  : xlenbits =
                      match op {
                        AMOSWAP => rs2_val,
                        AMOADD  => rs2_val + loaded,
                        AMOXOR  => rs2_val ^ loaded,
                        AMOAND  => rs2_val & loaded,
                        AMOOR   => rs2_val | loaded,

                        /* These operations convert bitvectors to integer values using [un]signed,
                         * and back using to_bits().
                         */
                        AMOMIN  => to_bits(sizeof(xlen), min(signed(rs2_val),   signed(loaded))),
                        AMOMAX  => to_bits(sizeof(xlen), max(signed(rs2_val),   signed(loaded))),
                        AMOMINU => to_bits(sizeof(xlen), min(unsigned(rs2_val), unsigned(loaded))),
                        AMOMAXU => to_bits(sizeof(xlen), max(unsigned(rs2_val), unsigned(loaded)))
                      };

                    let wval : MemoryOpResult(bool) = match (width, sizeof(xlen)) {
                      (WORD, _)    => mem_write_value(addr, 4, result[31..0], aq & rl, rl, true),
                      (DOUBLE, 64) => mem_write_value(addr, 8, result,        aq & rl, rl, true),
                      _            => internal_error("AMO expected WORD or DOUBLE")
                    };
                    match (wval) {
                      MemValue(true)  => { X(rd) = loaded; true },
                      MemValue(false) => { internal_error("AMO got false from mem_write_value") },
                      MemException(e) => { handle_mem_exception(addr, e); false }
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
    false
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
  <-> amo_mnemonic(op) ^ "." ^ size_mnemonic(width) ^ maybe_aq(aq) ^ maybe_rl(rl) ^ spc() ^ reg_name(rd) ^ sep() ^ reg_name(rs1) ^ sep() ^ reg_name(rs2)
