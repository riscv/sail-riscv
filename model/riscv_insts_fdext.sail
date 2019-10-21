/* **************************************************************** */
/* This file specifies the instructions in the F and D extensions.  */
/* RISC-V follows IEEE 754-2008 floating point arithmetic standard  */

/* ****************************************************************** */
/* Rounding Mode
    Rounding modes occur as a 3-bit field in F,D instructions,
    and also as a 3-bit 'frm' field in the 'fcsr' CSR.
    RISC-V uses the following IEEE-defined rounding modes.
*/

enum rounding_mode = {RM_RNE, RM_RTZ, RM_RDN, RM_RUP, RM_RMM, RM_DYN}

mapping rounding_mode_bits : rounding_mode <-> bits(3) = {
  RM_RNE <-> 0b000,
  RM_RTZ <-> 0b001,
  RM_RDN <-> 0b010,
  RM_RUP <-> 0b011,
  RM_RMM <-> 0b100,
  RM_DYN <-> 0b111
}

mapping frm_mnemonic : rounding_mode <-> string = {
  RM_RNE <-> "rne",
  RM_RTZ <-> "rtz",
  RM_RDN <-> "rdn",
  RM_RUP <-> "rup",
  RM_RMM <-> "rmm",
  RM_DYN <-> "dyn"
}

/* **************************************************************** */
/* Help-functions for 'encdec()' to restrict to certain             */
/* combinations of {F,D} x {RV32,RV64}                              */

function is_RV32F_or_RV64F () -> bool = (haveFExt() & (sizeof(xlen) == 32 | sizeof(xlen) == 64))
function is_RV64F          () -> bool = (haveFExt() & sizeof(xlen) == 64)

function is_RV32D_or_RV64D () -> bool = (haveDExt() & (sizeof(xlen) == 32 | sizeof(xlen) == 64))
function is_RV64D          () -> bool = (haveDExt() & sizeof(xlen) == 64)

/* ****************************************************************** */
/* Floating-point loads */

/* AST */
/* FLW and FLD; W/D is encoded in 'word_width' */

union clause ast = LOAD_FP : (bits(12), regidx, regidx, word_width)

/* AST <-> Binary encoding ================================ */

mapping clause encdec = LOAD_FP(imm, rs1, rd, WORD)          if is_RV32F_or_RV64F()
                    <-> imm @ rs1 @ 0b010 @ rd @ 0b000_0111  if is_RV32F_or_RV64F()

mapping clause encdec = LOAD_FP(imm, rs1, rd, DOUBLE)        if is_RV32D_or_RV64D()
                    <-> imm @ rs1 @ 0b011 @ rd @ 0b000_0111  if is_RV32D_or_RV64D()

/* Execution semantics ================================ */

val process_fload : forall 'n, 0 < 'n <= xlen_bytes.
                      (regidx, xlenbits, MemoryOpResult(bits(8 * 'n)), bool)
		      -> Retired effect {escape, rreg, wreg}
function process_fload(rd, addr, value, is_unsigned) =
  match extend_value(is_unsigned, value) {
    MemValue(result) => { F(rd) = result; RETIRE_SUCCESS },
    MemException(e)  => { handle_mem_exception(addr, e); RETIRE_FAIL }
  }

function clause execute(LOAD_FP(imm, rs1, rd, width)) = {
  let offset : xlenbits = EXTS(imm);
  /* Get the address, X(rs1) + offset.
     Some extensions perform additional checks on address validity. */
  match ext_data_get_addr(rs1, offset, Read(Data), width) {
    Ext_DataAddr_Error(e)  => { ext_handle_data_check_error(e); RETIRE_FAIL },
    Ext_DataAddr_OK(vaddr) =>
      if   check_misaligned(vaddr, width)
      then { handle_mem_exception(vaddr, E_Load_Addr_Align()); RETIRE_FAIL }
      else match translateAddr(vaddr, Read(Data)) {
        TR_Failure(e, _) => { handle_mem_exception(vaddr, e); RETIRE_FAIL },
        TR_Address(addr, _) => {
          let (aq, rl, res, is_unsigned) = (false, false, false, false);
          match (width, sizeof(xlen)) {
            (BYTE, _)   => { handle_illegal(); RETIRE_FAIL },
            (HALF, _)   => { handle_illegal(); RETIRE_FAIL },
            (WORD, _)   =>
               process_fload(rd, vaddr, mem_read(Read(Data), addr, 4, aq, rl, res), is_unsigned),
            (DOUBLE, 64) =>
               process_fload(rd, vaddr, mem_read(Read(Data), addr, 8, aq, rl, res), is_unsigned)
          }
	}
      }
  }
}

/* AST -> Assembly notation ================================ */

mapping clause assembly = LOAD_FP(imm, rs1, rd, width)
                      <-> "fl" ^ size_mnemonic(width)
		          ^ spc() ^ reg_name(rd)
			  ^ sep() ^ hex_bits_12(imm)
			  ^ opt_spc() ^ "(" ^ opt_spc() ^ reg_name(rs1) ^ opt_spc() ^ ")"

/* ****************************************************************** */
/* Floating-point stores */

/* AST */
/* FLW and FLD; W/D is encoded in 'width' */

union clause ast = STORE_FP : (bits(12), regidx, regidx, word_width)

/* AST <-> Binary encoding ================================ */

mapping clause encdec = STORE_FP(imm7 @ imm5, rs2, rs1, WORD)                             if is_RV32F_or_RV64F()
                    <-> imm7 : bits(7) @ rs2 @ rs1 @ 0b010 @ imm5 : bits(5) @ 0b010_0111  if is_RV32F_or_RV64F()

mapping clause encdec = STORE_FP(imm7 @ imm5, rs2, rs1, DOUBLE)                           if is_RV32D_or_RV64D()
                    <-> imm7 : bits(7) @ rs2 @ rs1 @ 0b011 @ imm5 : bits(5) @ 0b010_0111  if is_RV32D_or_RV64D()

/* Execution semantics ================================ */

val process_fstore : (xlenbits, MemoryOpResult(bool)) -> Retired effect {escape, rreg, wreg}
function process_fstore(vaddr, value) =
  match value {
    MemValue(true)  => { RETIRE_SUCCESS },
    MemValue(false) => { internal_error("store got false from mem_write_value") },
    MemException(e) => { handle_mem_exception(vaddr, e); RETIRE_FAIL }
  }

function clause execute (STORE_FP(imm, rs2, rs1, width)) = {
  let offset : xlenbits = EXTS(imm);
  let (aq, rl, con) = (false, false, false);
  /* Get the address, X(rs1) + offset.
     Some extensions perform additional checks on address validity. */
  match ext_data_get_addr(rs1, offset, Write(Data), width) {
    Ext_DataAddr_Error(e)  => { ext_handle_data_check_error(e); RETIRE_FAIL },
    Ext_DataAddr_OK(vaddr) =>
      if   check_misaligned(vaddr, width)
      then { handle_mem_exception(vaddr, E_SAMO_Addr_Align()); RETIRE_FAIL }
      else match translateAddr(vaddr, Write(Data)) {
        TR_Failure(e, _)    => { handle_mem_exception(vaddr, e); RETIRE_FAIL },
        TR_Address(addr, _) => {
          let eares : MemoryOpResult(unit) = match width {
            BYTE   => MemValue () /* bogus placeholder for illegal size */,
            HALF   => MemValue () /* bogus placeholder for illegal size */,
            WORD   => mem_write_ea(addr, 4, aq, rl, false),
            DOUBLE => mem_write_ea(addr, 8, aq, rl, false)
          };
          match (eares) {
            MemException(e) => { handle_mem_exception(addr, e); RETIRE_FAIL },
            MemValue(_) => {
              let rs2_val = F(rs2);
              match (width, sizeof(xlen)) {
                (BYTE, _)    => { handle_illegal(); RETIRE_FAIL },
                (HALF, _)    => { handle_illegal(); RETIRE_FAIL },
                (WORD, _)    => process_fstore (vaddr, mem_write_value(addr, 4, rs2_val[31..0], aq, rl, con)),
                (DOUBLE, 64) => process_fstore (vaddr, mem_write_value(addr, 8, rs2_val,        aq, rl, con))
              };
            }
          }
        }
      }
  }
}

/* AST -> Assembly notation ================================ */

mapping clause assembly = STORE_FP(imm, rs2, rs1, width)
                      <-> "fs" ^ size_mnemonic(width)
		          ^ spc() ^ reg_name(rs2)
			  ^ sep() ^ hex_bits_12(imm)
			  ^ opt_spc() ^ "(" ^ opt_spc() ^ reg_name(rs1) ^ opt_spc() ^ ")"

/* ****************************************************************** */
/* Fused multiply-add */

/* AST */

enum f_madd_op = {FMADD_S, FMSUB_S, FNMSUB_S, FNMADD_S,
                  FMADD_D, FMSUB_D, FNMSUB_D, FNMADD_D}

union clause ast = F_MADD_TYPE : (regidx, regidx, regidx, rounding_mode, regidx, f_madd_op)

/* AST <-> Binary encoding ================================ */

/* F instructions */

mapping clause encdec =
    F_MADD_TYPE(rs3, rs2, rs1, rm, rd, FMADD_S)                         if is_RV32F_or_RV64F()
<-> rs3 @ 0b00 @ rs2 @ rs1 @ rounding_mode_bits (rm) @ rd @ 0b100_0011  if is_RV32F_or_RV64F()

mapping clause encdec =
    F_MADD_TYPE(rs3, rs2, rs1, rm, rd, FMSUB_S)                         if is_RV32F_or_RV64F()
<-> rs3 @ 0b00 @ rs2 @ rs1 @ rounding_mode_bits (rm) @ rd @ 0b100_0111  if is_RV32F_or_RV64F()

mapping clause encdec =
    F_MADD_TYPE(rs3, rs2, rs1, rm, rd, FNMSUB_S)                        if is_RV32F_or_RV64F()
<-> rs3 @ 0b00 @ rs2 @ rs1 @ rounding_mode_bits (rm) @ rd @ 0b100_1011  if is_RV32F_or_RV64F()

mapping clause encdec =
    F_MADD_TYPE(rs3, rs2, rs1, rm, rd, FNMADD_S)                        if is_RV32F_or_RV64F()
<-> rs3 @ 0b00 @ rs2 @ rs1 @ rounding_mode_bits (rm) @ rd @ 0b100_1111  if is_RV32F_or_RV64F()

/* D instructions */

mapping clause encdec =
    F_MADD_TYPE(rs3, rs2, rs1, rm, rd, FMADD_D)                         if is_RV32D_or_RV64D()
<-> rs3 @ 0b01 @ rs2 @ rs1 @ rounding_mode_bits (rm) @ rd @ 0b100_0011  if is_RV32D_or_RV64D()

mapping clause encdec =
    F_MADD_TYPE(rs3, rs2, rs1, rm, rd, FMSUB_D)                         if is_RV32D_or_RV64D()
<-> rs3 @ 0b01 @ rs2 @ rs1 @ rounding_mode_bits (rm) @ rd @ 0b100_0111  if is_RV32D_or_RV64D()

mapping clause encdec =
    F_MADD_TYPE(rs3, rs2, rs1, rm, rd, FNMSUB_D)   if is_RV32D_or_RV64D()
<-> rs3 @ 0b01 @ rs2 @ rs1 @ rounding_mode_bits (rm) @ rd @ 0b100_1011  if is_RV32D_or_RV64D()

mapping clause encdec =
    F_MADD_TYPE(rs3, rs2, rs1, rm, rd, FNMADD_D)   if is_RV32D_or_RV64D()
<-> rs3 @ 0b01 @ rs2 @ rs1 @ rounding_mode_bits (rm) @ rd @ 0b100_1111  if is_RV32D_or_RV64D()

/* Execution semantics ================================ */

function clause execute (F_MADD_TYPE(rs3, rs2, rs1, rm, rd, op)) = {
  /* TODO */
  handle_illegal();
  RETIRE_FAIL
}

/* AST -> Assembly notation ================================ */

mapping f_madd_type_mnemonic : f_madd_op <-> string = {
    FMADD_S  <-> "fmadd.s",
    FMSUB_S  <-> "fmsub.s",
    FNMSUB_S <-> "fnmsub.s",
    FNMADD_S <-> "fnmadd.s",

    FMADD_D  <-> "fmadd.d",
    FMSUB_D  <-> "fmsub.d",
    FNMSUB_D <-> "fnmsub.d",
    FNMADD_D <-> "fnmadd.d"
}

mapping clause assembly = F_MADD_TYPE(rs3, rs2, rs1, rm, rd, op)
                      <-> f_madd_type_mnemonic(op)
		          ^ spc() ^ reg_name(rd)
			  ^ sep() ^ reg_name(rs1)
			  ^ sep() ^ reg_name(rs2)
			  ^ sep() ^ reg_name(rs3)
			  ^ sep() ^ frm_mnemonic(rm)



/* ****************************************************************** */
/* Binary ops with rounding mode */

/* AST */

enum f_bin_rm_op = {FADD_S, FSUB_S, FMUL_S, FDIV_S,
                    FADD_D, FSUB_D, FMUL_D, FDIV_D}

union clause ast = F_BIN_RM_TYPE : (regidx, regidx, rounding_mode, regidx, f_bin_rm_op)

/* AST <-> Binary encoding ================================ */

/* F instructions */

mapping clause encdec =
    F_BIN_RM_TYPE(rs2, rs1, rm, rd, FADD_S)                             if is_RV32F_or_RV64F()
<-> 0b000_0000 @ rs2 @ rs1 @ rounding_mode_bits (rm) @ rd @ 0b101_0011  if is_RV32F_or_RV64F()

mapping clause encdec =
    F_BIN_RM_TYPE(rs2, rs1, rm, rd, FSUB_S)                             if is_RV32F_or_RV64F()
<-> 0b000_0100 @ rs2 @ rs1 @ rounding_mode_bits (rm) @ rd @ 0b101_0011  if is_RV32F_or_RV64F()

mapping clause encdec =
    F_BIN_RM_TYPE(rs2, rs1, rm, rd, FMUL_S)                             if is_RV32F_or_RV64F()
<-> 0b000_1000 @ rs2 @ rs1 @ rounding_mode_bits (rm) @ rd @ 0b101_0011  if is_RV32F_or_RV64F()

mapping clause encdec =
    F_BIN_RM_TYPE(rs2, rs1, rm, rd, FDIV_S)                             if is_RV32F_or_RV64F()
<-> 0b000_1100 @ rs2 @ rs1 @ rounding_mode_bits (rm) @ rd @ 0b101_0011  if is_RV32F_or_RV64F()

/* D instructions */

mapping clause encdec =
    F_BIN_RM_TYPE(rs2, rs1, rm, rd, FADD_D)                             if is_RV32D_or_RV64D()
<-> 0b000_0001 @ rs2 @ rs1 @ rounding_mode_bits (rm) @ rd @ 0b101_0011  if is_RV32D_or_RV64D()

mapping clause encdec =
    F_BIN_RM_TYPE(rs2, rs1, rm, rd, FSUB_D)                             if is_RV32D_or_RV64D()
<-> 0b000_0101 @ rs2 @ rs1 @ rounding_mode_bits (rm) @ rd @ 0b101_0011  if is_RV32D_or_RV64D()

mapping clause encdec =
    F_BIN_RM_TYPE(rs2, rs1, rm, rd, FMUL_D)                             if is_RV32D_or_RV64D()
<-> 0b000_1001 @ rs2 @ rs1 @ rounding_mode_bits (rm) @ rd @ 0b101_0011  if is_RV32D_or_RV64D()

mapping clause encdec =
    F_BIN_RM_TYPE(rs2, rs1, rm, rd, FDIV_D)                             if is_RV32D_or_RV64D()
<-> 0b000_1101 @ rs2 @ rs1 @ rounding_mode_bits (rm) @ rd @ 0b101_0011  if is_RV32D_or_RV64D()

/* Execution semantics ================================ */

function clause execute (F_BIN_RM_TYPE(rs2, rs1, rm, rd, op)) = {
  /* TODO */
  handle_illegal();
  RETIRE_FAIL

  /* fill in primitive op using soft-float
  let rs1_val = F(rs1);
  let rs2_val = F(rs2);
  let result : xlenbits = match op {
    FADD_S  => prim_fadd_s (rs1_val, rs2_val),
    FSUB_S  => prim_fsub_s (rs1_val, rs2_val),
    FMUL_S  => prim_fmul_s (rs1_val, rs2_val),
    FDIV_S  => prim_fdiv_s (rs1_val, rs2_val)
  };
  F(rd) = result;
  RETIRE_SUCCESS
  */
}

/* AST -> Assembly notation ================================ */

mapping f_bin_rm_type_mnemonic : f_bin_rm_op <-> string = {
  FADD_S  <-> "fadd.s",
  FSUB_S  <-> "fsub.s",
  FMUL_S  <-> "fmul.s",
  FDIV_S  <-> "fdiv.s"
}

mapping clause assembly = F_BIN_RM_TYPE(rs2, rs1, rm, rd, op)
                      <-> f_bin_rm_type_mnemonic(op)
		          ^ spc() ^ reg_name(rd)
			  ^ sep() ^ reg_name(rs1)
			  ^ sep() ^ reg_name(rs2)
			  ^ sep() ^ frm_mnemonic(rm)

/* ****************************************************************** */
/* Unary with rounding mode */

/* AST */

enum f_un_rm_op = {FSQRT_S, FCVT_W_S, FCVT_WU_S, FCVT_S_W, FCVT_S_WU,    // RV32 and RV64
                   FSQRT_D, FCVT_W_D, FCVT_WU_D, FCVT_D_W, FCVT_D_WU,    // RV32 and RV64
                   FCVT_L_S, FCVT_LU_S, FCVT_S_L, FCVT_S_LU,             // RV64 only
                   FCVT_L_D, FCVT_LU_D, FCVT_D_L, FCVT_D_LU}             // RV64 only

union clause ast = F_UN_RM_TYPE : (regidx, rounding_mode, regidx, f_un_rm_op)

/* AST <-> Binary encoding ================================ */

/* F instructions */

mapping clause encdec =
    F_UN_RM_TYPE(rs1, rm, rd, FSQRT_S)                                      if is_RV32F_or_RV64F()
<-> 0b010_1100 @ 0b00000 @ rs1 @ rounding_mode_bits (rm) @ rd @ 0b101_0011  if is_RV32F_or_RV64F()

mapping clause encdec =
    F_UN_RM_TYPE(rs1, rm, rd, FCVT_W_S)                                     if is_RV32F_or_RV64F()
<-> 0b110_0000 @ 0b00000 @ rs1 @ rounding_mode_bits (rm) @ rd @ 0b101_0011  if is_RV32F_or_RV64F()

mapping clause encdec =
    F_UN_RM_TYPE(rs1, rm, rd, FCVT_WU_S)                                    if is_RV32F_or_RV64F()
<-> 0b110_0000 @ 0b00001 @ rs1 @ rounding_mode_bits (rm) @ rd @ 0b101_0011  if is_RV32F_or_RV64F()

mapping clause encdec =
    F_UN_RM_TYPE(rs1, rm, rd, FCVT_S_W)                                     if is_RV32F_or_RV64F()
<-> 0b110_1000 @ 0b00000 @ rs1 @ rounding_mode_bits (rm) @ rd @ 0b101_0011  if is_RV32F_or_RV64F()

mapping clause encdec =
    F_UN_RM_TYPE(rs1, rm, rd, FCVT_S_WU)                                    if is_RV32F_or_RV64F()
<-> 0b110_1000 @ 0b00001 @ rs1 @ rounding_mode_bits (rm) @ rd @ 0b101_0011  if is_RV32F_or_RV64F()

/* D instructions */

mapping clause encdec =
    F_UN_RM_TYPE(rs1, rm, rd, FSQRT_D)                                      if is_RV32D_or_RV64D()
<-> 0b010_1101 @ 0b00000 @ rs1 @ rounding_mode_bits (rm) @ rd @ 0b101_0011  if is_RV32D_or_RV64D()

mapping clause encdec =
    F_UN_RM_TYPE(rs1, rm, rd, FCVT_W_D)                                     if is_RV32D_or_RV64D()
<-> 0b110_0001 @ 0b00000 @ rs1 @ rounding_mode_bits (rm) @ rd @ 0b101_0011  if is_RV32D_or_RV64D()

mapping clause encdec =
    F_UN_RM_TYPE(rs1, rm, rd, FCVT_WU_D)                                    if is_RV32D_or_RV64D()
<-> 0b110_0001 @ 0b00001 @ rs1 @ rounding_mode_bits (rm) @ rd @ 0b101_0011  if is_RV32D_or_RV64D()

mapping clause encdec =
    F_UN_RM_TYPE(rs1, rm, rd, FCVT_D_W)                                     if is_RV32D_or_RV64D()
<-> 0b110_1001 @ 0b00000 @ rs1 @ rounding_mode_bits (rm) @ rd @ 0b101_0011  if is_RV32D_or_RV64D()

mapping clause encdec =
    F_UN_RM_TYPE(rs1, rm, rd, FCVT_D_WU)                                    if is_RV32D_or_RV64D()
<-> 0b110_1001 @ 0b00001 @ rs1 @ rounding_mode_bits (rm) @ rd @ 0b101_0011  if is_RV32D_or_RV64D()

/* F instructions, RV64 only */

mapping clause encdec =
    F_UN_RM_TYPE(rs1, rm, rd, FCVT_L_S)                                     if is_RV64F()
<-> 0b110_0000 @ 0b00010 @ rs1 @ rounding_mode_bits (rm) @ rd @ 0b101_0011  if is_RV64F()

mapping clause encdec =
    F_UN_RM_TYPE(rs1, rm, rd, FCVT_LU_S)                                    if is_RV64F()
<-> 0b110_0000 @ 0b00011 @ rs1 @ rounding_mode_bits (rm) @ rd @ 0b101_0011  if is_RV64F()

mapping clause encdec =
    F_UN_RM_TYPE(rs1, rm, rd, FCVT_S_L)                                     if is_RV64F()
<-> 0b110_1000 @ 0b00010 @ rs1 @ rounding_mode_bits (rm) @ rd @ 0b101_0011  if is_RV64F()

mapping clause encdec =
    F_UN_RM_TYPE(rs1, rm, rd, FCVT_S_LU)                                    if is_RV64F()
<-> 0b110_1000 @ 0b00011 @ rs1 @ rounding_mode_bits (rm) @ rd @ 0b101_0011  if is_RV64F()

/* D instructions, RV64 only */

mapping clause encdec =
    F_UN_RM_TYPE(rs1, rm, rd, FCVT_L_D)                                     if is_RV64D()
<-> 0b110_0001 @ 0b00010 @ rs1 @ rounding_mode_bits (rm) @ rd @ 0b101_0011  if is_RV64D()

mapping clause encdec =
    F_UN_RM_TYPE(rs1, rm, rd, FCVT_LU_D)                                    if is_RV64D()
<-> 0b110_0001 @ 0b00011 @ rs1 @ rounding_mode_bits (rm) @ rd @ 0b101_0011  if is_RV64D()

mapping clause encdec =
    F_UN_RM_TYPE(rs1, rm, rd, FCVT_D_L)                                     if is_RV64D()
<-> 0b110_1001 @ 0b00010 @ rs1 @ rounding_mode_bits (rm) @ rd @ 0b101_0011  if is_RV64D()

mapping clause encdec =
    F_UN_RM_TYPE(rs1, rm, rd, FCVT_D_LU)                                    if is_RV64D()
<-> 0b110_1001 @ 0b00011 @ rs1 @ rounding_mode_bits (rm) @ rd @ 0b101_0011  if is_RV64D()

/* Execution semantics ================================ */

function clause execute (F_UN_RM_TYPE(rs1, rm, rd, op)) = {
  /* TODO */
  handle_illegal();
  RETIRE_FAIL
}

/* AST -> Assembly notation ================================ */

mapping f_un_rm_type_mnemonic : f_un_rm_op <-> string = {
    FSQRT_S   <-> "fsqrt.s",
    FCVT_W_S  <-> "fcvt.w.s",
    FCVT_WU_S <-> "fcvt.wu.s",
    FCVT_S_W  <-> "fcvt.s.w",
    FCVT_S_WU <-> "fcvt.s.wu",

    FSQRT_D   <-> "fsqrt.d",
    FCVT_W_D  <-> "fcvt.w.d",
    FCVT_WU_D <-> "fcvt.wu.d",
    FCVT_D_W  <-> "fcvt.d.w",
    FCVT_D_WU <-> "fcvt.d.wu",

    FCVT_L_S  <-> "fcvt.l.s",
    FCVT_LU_S <-> "fcvt.lu.s",
    FCVT_S_L  <-> "fcvt.s.l",
    FCVT_S_LU <-> "fcvt.s.lu",

    FCVT_L_D  <-> "fcvt.l.d",
    FCVT_LU_D <-> "fcvt.lu.d",
    FCVT_D_L  <-> "fcvt.d.l",
    FCVT_D_L  <-> "fcvt.d.lu"
}

mapping clause assembly = F_UN_RM_TYPE(rs1, rm, rd, op)
                      <-> f_un_rm_type_mnemonic(op)
		          ^ spc() ^ reg_name(rd)
			  ^ sep() ^ reg_name(rs1)
			  ^ sep() ^ frm_mnemonic(rm)

/* ****************************************************************** */
/* Binary, no rounding mode */

/* AST */

enum f_bin_op = {FSGNJ_S, FSGNJN_S, FSGNJX_S, FMIN_S, FMAX_S, FEQ_S, FLT_S, FLE_S,
                 FSGNJ_D, FSGNJN_D, FSGNJX_D, FMIN_D, FMAX_D, FEQ_D, FLT_D, FLE_D}

union clause ast = F_BIN_TYPE : (regidx, regidx, regidx, f_bin_op)

/* AST <-> Binary encoding ================================ */

/* F instructions */

mapping clause encdec = F_BIN_TYPE(rs2, rs1, rd, FSGNJ_S)                 if is_RV32F_or_RV64F()
                    <-> 0b001_0000 @ rs2 @ rs1 @ 0b000 @ rd @ 0b101_0011  if is_RV32F_or_RV64F()

mapping clause encdec = F_BIN_TYPE(rs2, rs1, rd, FSGNJN_S)                if is_RV32F_or_RV64F()
                    <-> 0b001_0000 @ rs2 @ rs1 @ 0b001 @ rd @ 0b101_0011  if is_RV32F_or_RV64F()

mapping clause encdec = F_BIN_TYPE(rs2, rs1, rd, FSGNJX_S)                if is_RV32F_or_RV64F()
                    <-> 0b001_0000 @ rs2 @ rs1 @ 0b010 @ rd @ 0b101_0011  if is_RV32F_or_RV64F()

mapping clause encdec = F_BIN_TYPE(rs2, rs1, rd, FMIN_S)                  if is_RV32F_or_RV64F()
                    <-> 0b001_0100 @ rs2 @ rs1 @ 0b000 @ rd @ 0b101_0011  if is_RV32F_or_RV64F()

mapping clause encdec = F_BIN_TYPE(rs2, rs1, rd, FMAX_S)                  if is_RV32F_or_RV64F()
                    <-> 0b001_0100 @ rs2 @ rs1 @ 0b001 @ rd @ 0b101_0011  if is_RV32F_or_RV64F()

mapping clause encdec = F_BIN_TYPE(rs2, rs1, rd, FEQ_S)                   if is_RV32F_or_RV64F()
                    <-> 0b101_0000 @ rs2 @ rs1 @ 0b010 @ rd @ 0b101_0011  if is_RV32F_or_RV64F()

mapping clause encdec = F_BIN_TYPE(rs2, rs1, rd, FLT_S)                   if is_RV32F_or_RV64F()
                    <-> 0b101_0000 @ rs2 @ rs1 @ 0b001 @ rd @ 0b101_0011  if is_RV32F_or_RV64F()

mapping clause encdec = F_BIN_TYPE(rs2, rs1, rd, FLE_S)                   if is_RV32F_or_RV64F()
                    <-> 0b101_0000 @ rs2 @ rs1 @ 0b000 @ rd @ 0b101_0011  if is_RV32F_or_RV64F()


/* D instructions */

mapping clause encdec = F_BIN_TYPE(rs2, rs1, rd, FSGNJ_D)                 if is_RV32D_or_RV64D()
                    <-> 0b001_0001 @ rs2 @ rs1 @ 0b000 @ rd @ 0b101_0011  if is_RV32D_or_RV64D()

mapping clause encdec = F_BIN_TYPE(rs2, rs1, rd, FSGNJN_D)                if is_RV32D_or_RV64D()
                    <-> 0b001_0001 @ rs2 @ rs1 @ 0b001 @ rd @ 0b101_0011  if is_RV32D_or_RV64D()

mapping clause encdec = F_BIN_TYPE(rs2, rs1, rd, FSGNJX_D)                if is_RV32D_or_RV64D()
                    <-> 0b001_0001 @ rs2 @ rs1 @ 0b010 @ rd @ 0b101_0011  if is_RV32D_or_RV64D()

mapping clause encdec = F_BIN_TYPE(rs2, rs1, rd, FMIN_D)                  if is_RV32D_or_RV64D()
                    <-> 0b001_0101 @ rs2 @ rs1 @ 0b000 @ rd @ 0b101_0011  if is_RV32D_or_RV64D()

mapping clause encdec = F_BIN_TYPE(rs2, rs1, rd, FMAX_D)                  if is_RV32D_or_RV64D()
                    <-> 0b001_0101 @ rs2 @ rs1 @ 0b001 @ rd @ 0b101_0011  if is_RV32D_or_RV64D()

mapping clause encdec = F_BIN_TYPE(rs2, rs1, rd, FEQ_D)                   if is_RV32D_or_RV64D()
                    <-> 0b101_0001 @ rs2 @ rs1 @ 0b010 @ rd @ 0b101_0011  if is_RV32D_or_RV64D()

mapping clause encdec = F_BIN_TYPE(rs2, rs1, rd, FLT_D)                   if is_RV32D_or_RV64D()
                    <-> 0b101_0001 @ rs2 @ rs1 @ 0b001 @ rd @ 0b101_0011  if is_RV32D_or_RV64D()

mapping clause encdec = F_BIN_TYPE(rs2, rs1, rd, FLE_D)                   if is_RV32D_or_RV64D()
                    <-> 0b101_0001 @ rs2 @ rs1 @ 0b000 @ rd @ 0b101_0011  if is_RV32D_or_RV64D()


/* Execution semantics ================================ */

function clause execute (F_BIN_TYPE(rs2, rs1, rd, op)) = {
  /* TODO */
  handle_illegal();
  RETIRE_FAIL
}

/* AST -> Assembly notation ================================ */

mapping f_bin_type_mnemonic : f_bin_op <-> string = {
    FSGNJ_S  <-> "fsgnj.s",
    FSGNJN_S <-> "fsgnjn.s",
    FSGNJX_S <-> "fsgnjx.s",
    FMIN_S   <-> "fmin.s",
    FMAX_S   <-> "fmax.s",
    FEQ_S    <-> "feq.s",
    FLT_S    <-> "flt.s",
    FLE_S    <-> "fle.s",

    FSGNJ_D  <-> "fsgnj.d",
    FSGNJN_D <-> "fsgnjn.d",
    FSGNJX_D <-> "fsgnjx.d",
    FMIN_D   <-> "fmin.d",
    FMAX_D   <-> "fmax.d",
    FEQ_D    <-> "feq.d",
    FLT_D    <-> "flt.d",
    FLE_D    <-> "fl._d"
}

mapping clause assembly = F_BIN_TYPE(rs2, rs1, rd, op)
                      <-> f_bin_type_mnemonic(op)
		          ^ spc() ^ reg_name(rd)
			  ^ sep() ^ reg_name(rs1)
			  ^ sep() ^ reg_name(rs2)

/* ****************************************************************** */
/* Unary, no rounding mode */
enum f_un_op = {FMV_X_W, FCLASS_S, FMV_W_X,    /* RV32 and RV64 */
                FMV_X_D, FCLASS_D, FMV_D_X}    /* RV64 only */

union clause ast = F_UN_TYPE     : (        regidx,                regidx, f_un_op)          /* unary, no RM */

/* AST <-> Binary encoding ================================ */

/* F instructions, RV32 and RV64 */

mapping clause encdec = F_UN_TYPE(rs1, rd, FMV_X_W)                           if haveFExt() & sizeof(xlen) == 32
                    <-> 0b111_0000 @ 0b00000 @ rs1 @ 0b000 @ rd @ 0b101_0011  if haveFExt() & sizeof(xlen) == 32

mapping clause encdec = F_UN_TYPE(rs1, rd, FCLASS_S)                          if haveFExt() & sizeof(xlen) == 32
                    <-> 0b111_0000 @ 0b00000 @ rs1 @ 0b001 @ rd @ 0b101_0011  if haveFExt() & sizeof(xlen) == 32

mapping clause encdec = F_UN_TYPE(rs1, rd, FMV_W_X)                           if haveFExt() & sizeof(xlen) == 32
                    <-> 0b111_1000 @ 0b00000 @ rs1 @ 0b000 @ rd @ 0b101_0011  if haveFExt() & sizeof(xlen) == 32

/* D instructions, RV64 only */

mapping clause encdec = F_UN_TYPE(rs1, rd, FMV_X_D)                           if is_RV64D()
                    <-> 0b111_0001 @ 0b00000 @ rs1 @ 0b000 @ rd @ 0b101_0011  if is_RV64D()

mapping clause encdec = F_UN_TYPE(rs1, rd, FMV_D_X)                           if is_RV64D()
                    <-> 0b111_1001 @ 0b00000 @ rs1 @ 0b000 @ rd @ 0b101_0011  if is_RV64D()

/* Execution semantics ================================ */

function clause execute (F_UN_TYPE(rs1, rd, op)) = {
  /* TODO */
  handle_illegal();
  RETIRE_FAIL
}

/* AST -> Assembly notation ================================ */

mapping f_un_type_mnemonic : f_un_op <-> string = {
    FMV_X_W  <-> "fmv.x.w",
    FCLASS_S <-> "fclass.s",
    FMV_W_X  <-> "fmv.w.x",
    FMV_X_D  <-> "fmv.x.d",
    FCLASS_D <-> "fclass.d",
    FMV_D_X  <-> "fmv.d.x"
}

mapping clause assembly = F_UN_TYPE(rs1, rd, op)
                      <-> f_un_type_mnemonic(op)
		          ^ spc() ^ reg_name(rd)
			  ^ sep() ^ reg_name(rs1)

/* ****************************************************************** */
