/* **************************************************************** */
/* This file specifies the instructions in the F and D extensions.  */
/* RISC-V follows IEEE 754-2008 floating point arithmetic standard  */

/* Original author: Rishiyur S. Nikhil, Sept-Oct 2019               */

/* **************************************************************** */
/* Rounding Mode
    Rounding modes occur as a 3-bit field in F,D instructions,
    and also as a 3-bit 'frm' field in the 'fcsr' CSR.
    RISC-V uses the following IEEE-defined rounding modes.
*/

enum rounding_mode = {RM_RNE, RM_RTZ, RM_RDN, RM_RUP, RM_RMM, RM_DYN}

mapping encdec_rounding_mode : rounding_mode <-> bits(3) = {
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

val       select_instr_or_fcsr_rm : rounding_mode -> rounding_mode effect {rreg}
function  select_instr_or_fcsr_rm   instr_rm =
  if (instr_rm == RM_DYN)
  then {
      let fcsr = readCSR (csr_name_map ("frm"));
      encdec_rounding_mode (fcsr [7..5])
  }
  else instr_rm

/* **************************************************************** */
/* Floating point accrued exception flags                           */

function nxFlag() -> bits(5) = 0b_00001
function ufFlag() -> bits(5) = 0b_00010
function ofFlag() -> bits(5) = 0b_00100
function dzFlag() -> bits(5) = 0b_01000
function nvFlag() -> bits(5) = 0b_10000

/* **************************************************************** */
/* S and D value structure (sign, exponent, mantissa)               */

/* TODO: this should be a 'mapping' */
val      fsplit_S : bits(32) -> (bits(1), bits(8), bits(23))
function fsplit_S   x32 = (x32[31..31], x32[30..23], x32[22..0])

val      fmake_S  : (bits(1), bits(8), bits(23)) -> bits(32)
function fmake_S (sign, exp, mant) = sign @ exp @ mant

/* TODO: this should be a 'mapping' */
val      fsplit_D : bits(64) -> (bits(1), bits(11), bits(52))
function fsplit_D   x64 = (x64[63..63], x64[62..52], x64[51..0])

val      fmake_D  : (bits(1), bits(11), bits(52)) -> bits(64)
function fmake_D (sign, exp, mant) = sign @ exp @ mant

/* NaNs and structure tests */

function canonical_NaN_S() -> bits(32) = 0x_7fc0_0000
function canonical_NaN_D() -> bits(64) = 0x_7ff8_0000_0000_0000

/* ---- Test S value for signalling NaN */
val      s_is_SNaN : bits(32) -> bool
function s_is_SNaN   x32 = {
  let (sign, exp, mant) = fsplit_S (x32);
  (  (exp == ones())
   & (mant [22] == bitzero)
   & (mant != zeros()))
}

/* ---- Test S value for quiet NaN */
val      s_is_QNaN : bits(32) -> bool
function s_is_QNaN   x32 = {
  let (sign, exp, mant) = fsplit_S (x32);
  (  (exp == ones())
   & (mant [22] == bitone))
}

/* ---- Test for positive zero */
val      s_is_pos_zero : bits(32) -> bool
function s_is_pos_zero   x32 = {
  let (sign, exp, mant) = fsplit_S (x32);
  (  (sign == zeros())
   & (exp  == zeros())
   & (mant == zeros()))
}

/* ---- Test for negative zero */
val      s_is_neg_zero : bits(32) -> bool
function s_is_neg_zero   x32 = {
  let (sign, exp, mant) = fsplit_S (x32);
  (  (sign == ones())
   & (exp  == zeros())
   & (mant == zeros()))
}

/* ---- Test D value for signalling NaN */
val      d_is_SNaN : bits(64) -> bool
function d_is_SNaN   x64 = {
  let (sign, exp, mant) = fsplit_D (x64);
  (  (exp == ones())
   & (mant [22] == bitzero)
   & (mant != zeros()))
}

/* ---- Test S value for quiet NaN */
val      d_is_QNaN : bits(64) -> bool
function d_is_QNaN   x64 = {
  let (sign, exp, mant) = fsplit_D (x64);
  (  (exp == ones())
   & (mant [22] == bitone))
}

/* ---- Test for positive zero */
val      d_is_pos_zero : bits(64) -> bool
function d_is_pos_zero   x64 = {
  let (sign, exp, mant) = fsplit_D (x64);
  (  (sign == zeros())
   & (exp  == zeros())
   & (mant == zeros()))
}

/* ---- Test for negative zero */
val      d_is_neg_zero : bits(64) -> bool
function d_is_neg_zero   x64 = {
  let (sign, exp, mant) = fsplit_D (x64);
  (  (sign == ones())
   & (exp  == zeros())
   & (mant == zeros()))
}

/* **************************************************************** */
/* Help functions used in the semantic functions                    */

val      negate_S : bits(32) -> bits(32)
function negate_S (x32) = {
  let (sign, exp, mant) = fsplit_S (x32);
  let new_sign = if (sign == 0b0) then 0b1 else 0b0;
  fmake_S (new_sign, exp, mant)
}

val      negate_D : bits(64) -> bits(64)
function negate_D (x64) = {
  let (sign, exp, mant) = fsplit_D (x64);
  let new_sign = if (sign == 0b0) then 0b1 else 0b0;
  fmake_D (new_sign, exp, mant)
}

val      feq_quiet_S : (bits(32), bits (32)) -> (bool, bits(5))
function feq_quiet_S   (v1,       v2) = {
  let (s1, e1, m1) = fsplit_S (v1);
  let (s2, e2, m2) = fsplit_S (v2);

  let v1Is0    = s_is_neg_zero(v1)  | s_is_pos_zero(v1);
  let v2Is0    = s_is_neg_zero(v2)  | s_is_pos_zero(v2);

  let result = ((v1 == v2) | (v1Is0 & v2Is0));

  let fflags = if (s_is_SNaN(v1) | s_is_SNaN(v2)) then
	         nvFlag()
	       else
		   zeros();

  (result, fflags)
}

val      flt_S : (bits(32), bits (32), bool) -> (bool, bits(5))
function flt_S   (v1,       v2,        is_quiet) = {
  let (s1, e1, m1) = fsplit_S (v1);
  let (s2, e2, m2) = fsplit_S (v2);

  let v1IsNaN  = s_is_QNaN(v1) | s_is_SNaN(v1);
  let v2IsNaN  = s_is_QNaN(v2) | s_is_SNaN(v2);

  /* TODO: SAIL bug? Inlining these below raises type errors */
  let m1_lt_m2 = unsigned (m1) < unsigned (m2);
  let e1_lt_e2 = unsigned (e1) < unsigned (e2);
  let m1_gt_m2 = unsigned (m1) > unsigned (m2);
  let e1_gt_e2 = unsigned (e1) > unsigned (e2);

  let result = if (s1 == 0b0) & (s2 == 0b0) then
                 if (e1 == e2) then
                   m1_lt_m2
                 else
		   e1_lt_e2
               else if (s1 == 0b0) & (s2 == 0b1) then
                 false
               else if (s1 == 0b1) & (s2 == 0b0) then
                 true
               else
                 if (e1 == e2) then
                   m1_gt_m2
                 else
		   e1_gt_e2;

  let fflags = if is_quiet then 
                 if (s_is_SNaN(v1) | s_is_SNaN(v2)) then
		   nvFlag()
		 else
		   zeros()
               else
                 if (v1IsNaN | v2IsNaN) then
		   nvFlag()
		 else
		   zeros();

  (result, fflags)
}

val      fle_S : (bits(32), bits (32), bool) -> (bool, bits(5))
function fle_S   (v1,       v2,        is_quiet) = {
  let (s1, e1, m1) = fsplit_S (v1);
  let (s2, e2, m2) = fsplit_S (v2);

  let v1IsNaN  = s_is_QNaN(v1) | s_is_SNaN(v1);
  let v2IsNaN  = s_is_QNaN(v2) | s_is_SNaN(v2);

  let v1Is0    = s_is_neg_zero(v1)  | s_is_pos_zero(v1);
  let v2Is0    = s_is_neg_zero(v2)  | s_is_pos_zero(v2);

  /* TODO: SAIL bug? Inlining these below raises type errors */
  let m1_le_m2 = unsigned (m1) <=  unsigned (m2);
  let e1_lt_e2 = unsigned (e1)  <  unsigned (e2);
  let m1_ge_m2 = unsigned (m1) >=  unsigned (m2);
  let e1_gt_e2 = unsigned (e1)  >  unsigned (e2);

  let result = if (s1 == 0b0) & (s2 == 0b0) then
                 if (e1 == e2) then
                   m1_le_m2
                 else
		   e1_lt_e2
               else if (s1 == 0b0) & (s2 == 0b1) then
                 (v1Is0 & v2Is0)                         /* Equal in this case (+0=-0) */
               else if (s1 == 0b1) & (s2 == 0b0) then
                 true
               else
                 if (e1 == e2) then
                   m1_ge_m2
                 else
		   e1_gt_e2;

  let fflags = if is_quiet then 
                 if (s_is_SNaN(v1) | s_is_SNaN(v2)) then
		   nvFlag()
		 else
		   zeros()
               else
                 if (v1IsNaN | v2IsNaN) then
		   nvFlag()
		 else
		   zeros();

  (result, fflags)
}

/* ---- */

val      feq_quiet_D : (bits(64), bits (64)) -> (bool, bits(5))
function feq_quiet_D   (v1,       v2) = {
  let (s1, e1, m1) = fsplit_D (v1);
  let (s2, e2, m2) = fsplit_D (v2);

  let v1Is0    = d_is_neg_zero(v1)  | d_is_pos_zero(v1);
  let v2Is0    = d_is_neg_zero(v2)  | d_is_pos_zero(v2);

  let result = ((v1 == v2) | (v1Is0 & v2Is0));

  let fflags = if (d_is_SNaN(v1) | d_is_SNaN(v2)) then
	         nvFlag()
	       else
		 zeros();

  (result, fflags)
}

val      flt_D : (bits(64), bits (64), bool) -> (bool, bits(5))
function flt_D   (v1,       v2,        is_quiet) = {
  let (s1, e1, m1) = fsplit_D (v1);
  let (s2, e2, m2) = fsplit_D (v2);

  let v1IsNaN  = d_is_QNaN(v1) | d_is_SNaN(v1);
  let v2IsNaN  = d_is_QNaN(v2) | d_is_SNaN(v2);

  /* TODO: SAIL bug? Inlining these below raises type errors */
  let m1_lt_m2 = unsigned (m1) < unsigned (m2);
  let e1_lt_e2 = unsigned (e1) < unsigned (e2);
  let m1_gt_m2 = unsigned (m1) > unsigned (m2);
  let e1_gt_e2 = unsigned (e1) > unsigned (e2);

  let result = if (s1 == 0b0) & (s2 == 0b0) then
                 if (e1 == e2) then
                   m1_lt_m2
                 else
		   e1_lt_e2
               else if (s1 == 0b0) & (s2 == 0b1) then
                 false
               else if (s1 == 0b1) & (s2 == 0b0) then
                 true
               else
                 if (e1 == e2) then
                   m1_gt_m2
                 else
		   e1_gt_e2;

  let fflags = if is_quiet then 
                 if (d_is_SNaN(v1) | d_is_SNaN(v2)) then
		   nvFlag()
		 else
		   zeros()
               else
                 if (v1IsNaN | v2IsNaN) then
		   nvFlag()
		 else
		   zeros();

  (result, fflags)
}

val      fle_D : (bits(64), bits (64), bool) -> (bool, bits(5))
function fle_D   (v1,       v2,        is_quiet) = {
  let (s1, e1, m1) = fsplit_D (v1);
  let (s2, e2, m2) = fsplit_D (v2);

  let v1IsNaN  = d_is_QNaN(v1) | d_is_SNaN(v1);
  let v2IsNaN  = d_is_QNaN(v2) | d_is_SNaN(v2);

  let v1Is0    = d_is_neg_zero(v1)  | d_is_pos_zero(v1);
  let v2Is0    = d_is_neg_zero(v2)  | d_is_pos_zero(v2);

  /* TODO: SAIL bug? Inlining these below raises type errors */
  let m1_le_m2 = unsigned (m1) <=  unsigned (m2);
  let e1_lt_e2 = unsigned (e1)  <  unsigned (e2);
  let m1_ge_m2 = unsigned (m1) >=  unsigned (m2);
  let e1_gt_e2 = unsigned (e1)  >  unsigned (e2);

  let result = if (s1 == 0b0) & (s2 == 0b0) then
                 if (e1 == e2) then
                   m1_le_m2
                 else
		   e1_lt_e2
               else if (s1 == 0b0) & (s2 == 0b1) then
                 (v1Is0 & v2Is0)                         /* Equal in this case (+0=-0) */
               else if (s1 == 0b1) & (s2 == 0b0) then
                 true
               else
                 if (e1 == e2) then
                   m1_ge_m2
                 else
		   e1_gt_e2;

  let fflags = if is_quiet then 
                 if (d_is_SNaN(v1) | d_is_SNaN(v2)) then
		   nvFlag()
		 else
		   zeros()
               else
                 if (v1IsNaN | v2IsNaN) then
		   nvFlag()
		 else
		   zeros();

  (result, fflags)
}

/* **************************************************************** */
/* NaN boxing/unboxing.                                             */
/* When 32-bit floats (single-precision) are stored in 64-bit regs  */
/* they must be 'NaN boxed' (upper 32b all ones).                   */
/* When 32-bit floats (single-precision) are read from 64-bit regs  */
/* they must be 'NaN unboxed'.                                      */

val      nan_box : bits(32) -> flenbits
function nan_box   val_32b =
  if (sizeof(flen) == 32)
  then val_32b
  else 0x_FFFF_FFFF @ val_32b

val      nan_unbox : flenbits -> bits(32)
function nan_unbox   regval =
  if (sizeof(flen) == 32)
  then regval
  else if regval [63..32] == 0x_FFFF_FFFF
       then regval [31..0]
       else canonical_NaN_S()

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

enum f_madd_op_S = {FMADD_S, FMSUB_S, FNMSUB_S, FNMADD_S}

union clause ast = F_MADD_TYPE_S : (regidx, regidx, regidx, rounding_mode, regidx, f_madd_op_S)

enum f_madd_op_D = {FMADD_D, FMSUB_D, FNMSUB_D, FNMADD_D}

union clause ast = F_MADD_TYPE_D : (regidx, regidx, regidx, rounding_mode, regidx, f_madd_op_D)

/* AST <-> Binary encoding ================================ */

/* F instructions */

mapping clause encdec =
    F_MADD_TYPE_S(rs3, rs2, rs1, rm, rd, FMADD_S)                         if is_RV32F_or_RV64F()
<-> rs3 @ 0b00 @ rs2 @ rs1 @ encdec_rounding_mode (rm) @ rd @ 0b100_0011  if is_RV32F_or_RV64F()

mapping clause encdec =
    F_MADD_TYPE_S(rs3, rs2, rs1, rm, rd, FMSUB_S)                         if is_RV32F_or_RV64F()
<-> rs3 @ 0b00 @ rs2 @ rs1 @ encdec_rounding_mode (rm) @ rd @ 0b100_0111  if is_RV32F_or_RV64F()

mapping clause encdec =
    F_MADD_TYPE_S(rs3, rs2, rs1, rm, rd, FNMSUB_S)                        if is_RV32F_or_RV64F()
<-> rs3 @ 0b00 @ rs2 @ rs1 @ encdec_rounding_mode (rm) @ rd @ 0b100_1011  if is_RV32F_or_RV64F()

mapping clause encdec =
    F_MADD_TYPE_S(rs3, rs2, rs1, rm, rd, FNMADD_S)                        if is_RV32F_or_RV64F()
<-> rs3 @ 0b00 @ rs2 @ rs1 @ encdec_rounding_mode (rm) @ rd @ 0b100_1111  if is_RV32F_or_RV64F()

/* D instructions */

mapping clause encdec =
    F_MADD_TYPE_D(rs3, rs2, rs1, rm, rd, FMADD_D)                         if is_RV32D_or_RV64D()
<-> rs3 @ 0b01 @ rs2 @ rs1 @ encdec_rounding_mode (rm) @ rd @ 0b100_0011  if is_RV32D_or_RV64D()

mapping clause encdec =
    F_MADD_TYPE_D(rs3, rs2, rs1, rm, rd, FMSUB_D)                         if is_RV32D_or_RV64D()
<-> rs3 @ 0b01 @ rs2 @ rs1 @ encdec_rounding_mode (rm) @ rd @ 0b100_0111  if is_RV32D_or_RV64D()

mapping clause encdec =
    F_MADD_TYPE_D(rs3, rs2, rs1, rm, rd, FNMSUB_D)                        if is_RV32D_or_RV64D()
<-> rs3 @ 0b01 @ rs2 @ rs1 @ encdec_rounding_mode (rm) @ rd @ 0b100_1011  if is_RV32D_or_RV64D()

mapping clause encdec =
    F_MADD_TYPE_D(rs3, rs2, rs1, rm, rd, FNMADD_D)                        if is_RV32D_or_RV64D()
<-> rs3 @ 0b01 @ rs2 @ rs1 @ encdec_rounding_mode (rm) @ rd @ 0b100_1111  if is_RV32D_or_RV64D()

/* Execution semantics ================================ */

function clause execute (F_MADD_TYPE_S(rs3, rs2, rs1, rm, rd, op)) = {
  let rs1_val_32b = nan_unbox (F(rs1));
  let rs2_val_32b = nan_unbox (F(rs2));
  let rs3_val_32b = nan_unbox (F(rs3));
  let rm_3b       = encdec_rounding_mode (select_instr_or_fcsr_rm  (rm));
  let (fflags, rd_val_32b) : (bits(5), bits(32)) =
    match op {
      FMADD_S  => external_f32MulAdd (rm_3b, rs1_val_32b, rs2_val_32b, rs3_val_32b),
      FMSUB_S  => external_f32MulAdd (rm_3b, rs1_val_32b, rs2_val_32b, negate_S (rs3_val_32b)),
      FNMSUB_S => external_f32MulAdd (rm_3b, negate_S (rs1_val_32b), rs2_val_32b, rs3_val_32b),
      FNMADD_S => external_f32MulAdd (rm_3b, negate_S (rs1_val_32b), rs2_val_32b, negate_S (rs3_val_32b))
    };
  writeCSR (csr_name_map ("fflags"), EXTZ (fflags));
  F(rd) = nan_box (rd_val_32b);
  RETIRE_SUCCESS
}

function clause execute (F_MADD_TYPE_D(rs3, rs2, rs1, rm, rd, op)) = {
  let rs1_val_64b = F(rs1);
  let rs2_val_64b = F(rs2);
  let rs3_val_64b = F(rs3);
  let rm_3b       = encdec_rounding_mode (select_instr_or_fcsr_rm  (rm));
  let (fflags, rd_val_64b) : (bits(5), bits(64)) =
    match op {
      FMADD_D  => external_f64MulAdd (rm_3b, rs1_val_64b, rs2_val_64b, rs3_val_64b),
      FMSUB_D  => external_f64MulAdd (rm_3b, rs1_val_64b, rs2_val_64b, negate_D (rs3_val_64b)),
      FNMSUB_D => external_f64MulAdd (rm_3b, negate_D (rs1_val_64b), rs2_val_64b, rs3_val_64b),
      FNMADD_D => external_f64MulAdd (rm_3b, negate_D (rs1_val_64b), rs2_val_64b, negate_D (rs3_val_64b))
    };
  writeCSR (csr_name_map ("fflags"), EXTZ (fflags));
  F(rd) = rd_val_64b;
  RETIRE_SUCCESS
}

/* AST -> Assembly notation ================================ */

mapping f_madd_type_mnemonic_S : f_madd_op_S <-> string = {
    FMADD_S  <-> "fmadd.s",
    FMSUB_S  <-> "fmsub.s",
    FNMSUB_S <-> "fnmsub.s",
    FNMADD_S <-> "fnmadd.s"
}

mapping clause assembly = F_MADD_TYPE_S(rs3, rs2, rs1, rm, rd, op)
                      <-> f_madd_type_mnemonic_S(op)
		          ^ spc() ^ reg_name(rd)
			  ^ sep() ^ reg_name(rs1)
			  ^ sep() ^ reg_name(rs2)
			  ^ sep() ^ reg_name(rs3)
			  ^ sep() ^ frm_mnemonic(rm)

mapping f_madd_type_mnemonic_D : f_madd_op_D <-> string = {
    FMADD_D  <-> "fmadd.d",
    FMSUB_D  <-> "fmsub.d",
    FNMSUB_D <-> "fnmsub.d",
    FNMADD_D <-> "fnmadd.d"
}

mapping clause assembly = F_MADD_TYPE_D(rs3, rs2, rs1, rm, rd, op)
                      <-> f_madd_type_mnemonic_D(op)
		          ^ spc() ^ reg_name(rd)
			  ^ sep() ^ reg_name(rs1)
			  ^ sep() ^ reg_name(rs2)
			  ^ sep() ^ reg_name(rs3)
			  ^ sep() ^ frm_mnemonic(rm)

/* ****************************************************************** */
/* Binary ops with rounding mode */

/* AST */

enum f_bin_rm_op_S = {FADD_S, FSUB_S, FMUL_S, FDIV_S}

union clause ast = F_BIN_RM_TYPE_S : (regidx, regidx, rounding_mode, regidx, f_bin_rm_op_S)

enum f_bin_rm_op_D = {FADD_D, FSUB_D, FMUL_D, FDIV_D}

union clause ast = F_BIN_RM_TYPE_D : (regidx, regidx, rounding_mode, regidx, f_bin_rm_op_D)

/* AST <-> Binary encoding ================================ */

/* F instructions */

mapping clause encdec =
    F_BIN_RM_TYPE_S(rs2, rs1, rm, rd, FADD_S)                             if is_RV32F_or_RV64F()
<-> 0b000_0000 @ rs2 @ rs1 @ encdec_rounding_mode (rm) @ rd @ 0b101_0011  if is_RV32F_or_RV64F()

mapping clause encdec =
    F_BIN_RM_TYPE_S(rs2, rs1, rm, rd, FSUB_S)                             if is_RV32F_or_RV64F()
<-> 0b000_0100 @ rs2 @ rs1 @ encdec_rounding_mode (rm) @ rd @ 0b101_0011  if is_RV32F_or_RV64F()

mapping clause encdec =
    F_BIN_RM_TYPE_S(rs2, rs1, rm, rd, FMUL_S)                             if is_RV32F_or_RV64F()
<-> 0b000_1000 @ rs2 @ rs1 @ encdec_rounding_mode (rm) @ rd @ 0b101_0011  if is_RV32F_or_RV64F()

mapping clause encdec =
    F_BIN_RM_TYPE_S(rs2, rs1, rm, rd, FDIV_S)                             if is_RV32F_or_RV64F()
<-> 0b000_1100 @ rs2 @ rs1 @ encdec_rounding_mode (rm) @ rd @ 0b101_0011  if is_RV32F_or_RV64F()

/* D instructions */

mapping clause encdec =
    F_BIN_RM_TYPE_D(rs2, rs1, rm, rd, FADD_D)                             if is_RV32D_or_RV64D()
<-> 0b000_0001 @ rs2 @ rs1 @ encdec_rounding_mode (rm) @ rd @ 0b101_0011  if is_RV32D_or_RV64D()

mapping clause encdec =
    F_BIN_RM_TYPE_D(rs2, rs1, rm, rd, FSUB_D)                             if is_RV32D_or_RV64D()
<-> 0b000_0101 @ rs2 @ rs1 @ encdec_rounding_mode (rm) @ rd @ 0b101_0011  if is_RV32D_or_RV64D()

mapping clause encdec =
    F_BIN_RM_TYPE_D(rs2, rs1, rm, rd, FMUL_D)                             if is_RV32D_or_RV64D()
<-> 0b000_1001 @ rs2 @ rs1 @ encdec_rounding_mode (rm) @ rd @ 0b101_0011  if is_RV32D_or_RV64D()

mapping clause encdec =
    F_BIN_RM_TYPE_D(rs2, rs1, rm, rd, FDIV_D)                             if is_RV32D_or_RV64D()
<-> 0b000_1101 @ rs2 @ rs1 @ encdec_rounding_mode (rm) @ rd @ 0b101_0011  if is_RV32D_or_RV64D()

/* Execution semantics ================================ */

function clause execute (F_BIN_RM_TYPE_S(rs2, rs1, rm, rd, op)) = {
  let rs1_val_32b = nan_unbox (F(rs1));
  let rs2_val_32b = nan_unbox (F(rs2));
  let rm_3b       = encdec_rounding_mode (select_instr_or_fcsr_rm  (rm));
  let (fflags, rd_val_32b) : (bits(5), bits(32)) = match op {
    FADD_S  => external_f32Add (rm_3b, rs1_val_32b, rs2_val_32b),
    FSUB_S  => external_f32Sub (rm_3b, rs1_val_32b, rs2_val_32b),
    FMUL_S  => external_f32Mul (rm_3b, rs1_val_32b, rs2_val_32b),
    FDIV_S  => external_f32Div (rm_3b, rs1_val_32b, rs2_val_32b)
  };
  writeCSR (csr_name_map ("fflags"), EXTZ (fflags));
  F(rd) = nan_box (rd_val_32b);
  RETIRE_SUCCESS
}

function clause execute (F_BIN_RM_TYPE_D(rs2, rs1, rm, rd, op)) = {
  let rs1_val_64b = F(rs1);
  let rs2_val_64b = F(rs2);
  let rm_3b       = encdec_rounding_mode (select_instr_or_fcsr_rm  (rm));
  let (fflags, rd_val_64b) : (bits(5), bits(64)) = match op {
    FADD_D  => external_f64Add (rm_3b, rs1_val_64b, rs2_val_64b),
    FSUB_D  => external_f64Sub (rm_3b, rs1_val_64b, rs2_val_64b),
    FMUL_D  => external_f64Mul (rm_3b, rs1_val_64b, rs2_val_64b),
    FDIV_D  => external_f64Div (rm_3b, rs1_val_64b, rs2_val_64b)
  };
  writeCSR (csr_name_map ("fflags"), EXTZ (fflags));
  F(rd) = rd_val_64b;
  RETIRE_SUCCESS
}

/* AST -> Assembly notation ================================ */

mapping f_bin_rm_type_mnemonic_S : f_bin_rm_op_S <-> string = {
  FADD_S  <-> "fadd.s",
  FSUB_S  <-> "fsub.s",
  FMUL_S  <-> "fmul.s",
  FDIV_S  <-> "fdiv.s"
}

mapping clause assembly = F_BIN_RM_TYPE_S(rs2, rs1, rm, rd, op)
                      <-> f_bin_rm_type_mnemonic_S(op)
		          ^ spc() ^ reg_name(rd)
			  ^ sep() ^ reg_name(rs1)
			  ^ sep() ^ reg_name(rs2)
			  ^ sep() ^ frm_mnemonic(rm)

mapping f_bin_rm_type_mnemonic_D : f_bin_rm_op_D <-> string = {
  FADD_D  <-> "fadd.d",
  FSUB_D  <-> "fsub.d",
  FMUL_D  <-> "fmul.d",
  FDIV_D  <-> "fdiv.d"
}

mapping clause assembly = F_BIN_RM_TYPE_D(rs2, rs1, rm, rd, op)
                      <-> f_bin_rm_type_mnemonic_D(op)
		          ^ spc() ^ reg_name(rd)
			  ^ sep() ^ reg_name(rs1)
			  ^ sep() ^ reg_name(rs2)
			  ^ sep() ^ frm_mnemonic(rm)

/* ****************************************************************** */
/* Unary with rounding mode */

/* AST */

enum f_un_rm_op_S = {FSQRT_S, FCVT_W_S, FCVT_WU_S, FCVT_S_W, FCVT_S_WU,    // RV32 and RV64
                     FCVT_L_S, FCVT_LU_S, FCVT_S_L, FCVT_S_LU}             // RV64 only

union clause ast = F_UN_RM_TYPE_S : (regidx, rounding_mode, regidx, f_un_rm_op_S)

enum f_un_rm_op_D = {FSQRT_D, FCVT_W_D, FCVT_WU_D, FCVT_D_W, FCVT_D_WU,    // RV32 and RV64
                     FCVT_L_D, FCVT_LU_D, FCVT_D_L, FCVT_D_LU}             // RV64 only

union clause ast = F_UN_RM_TYPE_D : (regidx, rounding_mode, regidx, f_un_rm_op_D)

/* AST <-> Binary encoding ================================ */

/* F instructions */

mapping clause encdec =
    F_UN_RM_TYPE_S(rs1, rm, rd, FSQRT_S)                                      if is_RV32F_or_RV64F()
<-> 0b010_1100 @ 0b00000 @ rs1 @ encdec_rounding_mode (rm) @ rd @ 0b101_0011  if is_RV32F_or_RV64F()

mapping clause encdec =
    F_UN_RM_TYPE_S(rs1, rm, rd, FCVT_W_S)                                     if is_RV32F_or_RV64F()
<-> 0b110_0000 @ 0b00000 @ rs1 @ encdec_rounding_mode (rm) @ rd @ 0b101_0011  if is_RV32F_or_RV64F()

mapping clause encdec =
    F_UN_RM_TYPE_S(rs1, rm, rd, FCVT_WU_S)                                    if is_RV32F_or_RV64F()
<-> 0b110_0000 @ 0b00001 @ rs1 @ encdec_rounding_mode (rm) @ rd @ 0b101_0011  if is_RV32F_or_RV64F()

mapping clause encdec =
    F_UN_RM_TYPE_S(rs1, rm, rd, FCVT_S_W)                                     if is_RV32F_or_RV64F()
<-> 0b110_1000 @ 0b00000 @ rs1 @ encdec_rounding_mode (rm) @ rd @ 0b101_0011  if is_RV32F_or_RV64F()

mapping clause encdec =
    F_UN_RM_TYPE_S(rs1, rm, rd, FCVT_S_WU)                                    if is_RV32F_or_RV64F()
<-> 0b110_1000 @ 0b00001 @ rs1 @ encdec_rounding_mode (rm) @ rd @ 0b101_0011  if is_RV32F_or_RV64F()

/* D instructions */

mapping clause encdec =
    F_UN_RM_TYPE_D(rs1, rm, rd, FSQRT_D)                                      if is_RV32D_or_RV64D()
<-> 0b010_1101 @ 0b00000 @ rs1 @ encdec_rounding_mode (rm) @ rd @ 0b101_0011  if is_RV32D_or_RV64D()

mapping clause encdec =
    F_UN_RM_TYPE_D(rs1, rm, rd, FCVT_W_D)                                     if is_RV32D_or_RV64D()
<-> 0b110_0001 @ 0b00000 @ rs1 @ encdec_rounding_mode (rm) @ rd @ 0b101_0011  if is_RV32D_or_RV64D()

mapping clause encdec =
    F_UN_RM_TYPE_D(rs1, rm, rd, FCVT_WU_D)                                    if is_RV32D_or_RV64D()
<-> 0b110_0001 @ 0b00001 @ rs1 @ encdec_rounding_mode (rm) @ rd @ 0b101_0011  if is_RV32D_or_RV64D()

mapping clause encdec =
    F_UN_RM_TYPE_D(rs1, rm, rd, FCVT_D_W)                                     if is_RV32D_or_RV64D()
<-> 0b110_1001 @ 0b00000 @ rs1 @ encdec_rounding_mode (rm) @ rd @ 0b101_0011  if is_RV32D_or_RV64D()

mapping clause encdec =
    F_UN_RM_TYPE_D(rs1, rm, rd, FCVT_D_WU)                                    if is_RV32D_or_RV64D()
<-> 0b110_1001 @ 0b00001 @ rs1 @ encdec_rounding_mode (rm) @ rd @ 0b101_0011  if is_RV32D_or_RV64D()

/* F instructions, RV64 only */

mapping clause encdec =
    F_UN_RM_TYPE_S(rs1, rm, rd, FCVT_L_S)                                     if is_RV64F()
<-> 0b110_0000 @ 0b00010 @ rs1 @ encdec_rounding_mode (rm) @ rd @ 0b101_0011  if is_RV64F()

mapping clause encdec =
    F_UN_RM_TYPE_S(rs1, rm, rd, FCVT_LU_S)                                    if is_RV64F()
<-> 0b110_0000 @ 0b00011 @ rs1 @ encdec_rounding_mode (rm) @ rd @ 0b101_0011  if is_RV64F()

mapping clause encdec =
    F_UN_RM_TYPE_S(rs1, rm, rd, FCVT_S_L)                                     if is_RV64F()
<-> 0b110_1000 @ 0b00010 @ rs1 @ encdec_rounding_mode (rm) @ rd @ 0b101_0011  if is_RV64F()

mapping clause encdec =
    F_UN_RM_TYPE_S(rs1, rm, rd, FCVT_S_LU)                                    if is_RV64F()
<-> 0b110_1000 @ 0b00011 @ rs1 @ encdec_rounding_mode (rm) @ rd @ 0b101_0011  if is_RV64F()

/* D instructions, RV64 only */

mapping clause encdec =
    F_UN_RM_TYPE_D(rs1, rm, rd, FCVT_L_D)                                     if is_RV64D()
<-> 0b110_0001 @ 0b00010 @ rs1 @ encdec_rounding_mode (rm) @ rd @ 0b101_0011  if is_RV64D()

mapping clause encdec =
    F_UN_RM_TYPE_D(rs1, rm, rd, FCVT_LU_D)                                    if is_RV64D()
<-> 0b110_0001 @ 0b00011 @ rs1 @ encdec_rounding_mode (rm) @ rd @ 0b101_0011  if is_RV64D()

mapping clause encdec =
    F_UN_RM_TYPE_D(rs1, rm, rd, FCVT_D_L)                                     if is_RV64D()
<-> 0b110_1001 @ 0b00010 @ rs1 @ encdec_rounding_mode (rm) @ rd @ 0b101_0011  if is_RV64D()

mapping clause encdec =
    F_UN_RM_TYPE_D(rs1, rm, rd, FCVT_D_LU)                                    if is_RV64D()
<-> 0b110_1001 @ 0b00011 @ rs1 @ encdec_rounding_mode (rm) @ rd @ 0b101_0011  if is_RV64D()

/* Execution semantics ================================ */

function clause execute (F_UN_RM_TYPE_S(rs1, rm, rd, FSQRT_S)) = {
  let rs1_val_S = nan_unbox (F(rs1));
  let rm_3b     = encdec_rounding_mode (select_instr_or_fcsr_rm  (rm));

  let (fflags, rd_val_S) = external_f32Sqrt   (rm_3b, rs1_val_S);

  writeCSR (csr_name_map ("fflags"), EXTZ (fflags));
  F(rd) = nan_box (rd_val_S);
  RETIRE_SUCCESS
}

function clause execute (F_UN_RM_TYPE_S(rs1, rm, rd, FCVT_W_S)) = {
  let rs1_val_S = nan_unbox (F(rs1));
  let rm_3b     = encdec_rounding_mode (select_instr_or_fcsr_rm  (rm));

  let (fflags, rd_val_W) = external_f32ToI32 (rm_3b, rs1_val_S);

  writeCSR (csr_name_map ("fflags"), EXTZ (fflags));
  X(rd) = EXTS (rd_val_W);
  RETIRE_SUCCESS
}

function clause execute (F_UN_RM_TYPE_S(rs1, rm, rd, FCVT_WU_S)) = {
  let rs1_val_S = nan_unbox (F(rs1));
  let rm_3b     = encdec_rounding_mode (select_instr_or_fcsr_rm  (rm));

  let (fflags, rd_val_WU) = external_f32ToUi32 (rm_3b, rs1_val_S);

  writeCSR (csr_name_map ("fflags"), EXTZ (fflags));
  X(rd) = EXTZ (rd_val_WU);
  RETIRE_SUCCESS
}

function clause execute (F_UN_RM_TYPE_S(rs1, rm, rd, FCVT_S_W)) = {
  let rs1_val_W = X(rs1) [31..0];
  let rm_3b     = encdec_rounding_mode (select_instr_or_fcsr_rm  (rm));

  let (fflags, rd_val_S) = external_i32ToF32 (rm_3b, rs1_val_W);

  writeCSR (csr_name_map ("fflags"), EXTZ (fflags));
  F(rd) = nan_box (rd_val_S);
  RETIRE_SUCCESS
}

function clause execute (F_UN_RM_TYPE_S(rs1, rm, rd, FCVT_S_WU)) = {
  let rs1_val_WU = X(rs1) [31..0];
  let rm_3b      = encdec_rounding_mode (select_instr_or_fcsr_rm  (rm));

  let (fflags, rd_val_S) = external_ui32ToF32 (rm_3b, rs1_val_WU);

  writeCSR (csr_name_map ("fflags"), EXTZ (fflags));
  F(rd) = nan_box (rd_val_S);
  RETIRE_SUCCESS
}

function clause execute (F_UN_RM_TYPE_S(rs1, rm, rd, FCVT_L_S)) = {
  let rs1_val_S = nan_unbox (F(rs1));
  let rm_3b     = encdec_rounding_mode (select_instr_or_fcsr_rm  (rm));

  let (fflags, rd_val_L) = external_f32ToI64 (rm_3b, rs1_val_S);

  writeCSR (csr_name_map ("fflags"), EXTZ (fflags));
  X(rd) = rd_val_L;
  RETIRE_SUCCESS
}

function clause execute (F_UN_RM_TYPE_S(rs1, rm, rd, FCVT_LU_S)) = {
  let rs1_val_S = nan_unbox (F(rs1));
  let rm_3b     = encdec_rounding_mode (select_instr_or_fcsr_rm  (rm));

  let (fflags, rd_val_LU) = external_f32ToUi64 (rm_3b, rs1_val_S);

  writeCSR (csr_name_map ("fflags"), EXTZ (fflags));
  X(rd) = rd_val_LU;
  RETIRE_SUCCESS
}

function clause execute (F_UN_RM_TYPE_S(rs1, rm, rd, FCVT_S_L)) = {
  let rs1_val_L = X(rs1);
  let rm_3b     = encdec_rounding_mode (select_instr_or_fcsr_rm  (rm));

  let (fflags, rd_val_S) = external_i64ToF32 (rm_3b, rs1_val_L);

  writeCSR (csr_name_map ("fflags"), EXTZ (fflags));
  F(rd) = nan_box (rd_val_S);
  RETIRE_SUCCESS
}

function clause execute (F_UN_RM_TYPE_S(rs1, rm, rd, FCVT_S_LU)) = {
  let rs1_val_LU = X(rs1);
  let rm_3b      = encdec_rounding_mode (select_instr_or_fcsr_rm  (rm));

  let (fflags, rd_val_S) = external_ui64ToF32 (rm_3b, rs1_val_LU);

  writeCSR (csr_name_map ("fflags"), EXTZ (fflags));
  F(rd) = nan_box (rd_val_S);
  RETIRE_SUCCESS
}

function clause execute (F_UN_RM_TYPE_D(rs1, rm, rd, FSQRT_D)) = {
  let rs1_val_D = F(rs1);
  let rm_3b     = encdec_rounding_mode (select_instr_or_fcsr_rm  (rm));

  let (fflags, rd_val_D) = external_f64Sqrt   (rm_3b, rs1_val_D);

  writeCSR (csr_name_map ("fflags"), EXTZ (fflags));
  F(rd) = rd_val_D;
  RETIRE_SUCCESS
}

function clause execute (F_UN_RM_TYPE_D(rs1, rm, rd, FCVT_W_D)) = {
  let rs1_val_D = F(rs1);
  let rm_3b     = encdec_rounding_mode (select_instr_or_fcsr_rm  (rm));

  let (fflags, rd_val_W) = external_f64ToI32 (rm_3b, rs1_val_D);

  writeCSR (csr_name_map ("fflags"), EXTZ (fflags));
  X(rd) = EXTS (rd_val_W);
  RETIRE_SUCCESS
}

function clause execute (F_UN_RM_TYPE_D(rs1, rm, rd, FCVT_WU_D)) = {
  let rs1_val_D = F(rs1);
  let rm_3b     = encdec_rounding_mode (select_instr_or_fcsr_rm  (rm));

  let (fflags, rd_val_WU) = external_f64ToUi32 (rm_3b, rs1_val_D);

  writeCSR (csr_name_map ("fflags"), EXTZ (fflags));
  X(rd) = EXTZ (rd_val_WU);
  RETIRE_SUCCESS
}

function clause execute (F_UN_RM_TYPE_D(rs1, rm, rd, FCVT_D_W)) = {
  let rs1_val_W = X(rs1) [31..0];
  let rm_3b     = encdec_rounding_mode (select_instr_or_fcsr_rm  (rm));

  let (fflags, rd_val_D) = external_i32ToF64 (rm_3b, rs1_val_W);

  writeCSR (csr_name_map ("fflags"), EXTZ (fflags));
  F(rd) = rd_val_D;
  RETIRE_SUCCESS
}

function clause execute (F_UN_RM_TYPE_D(rs1, rm, rd, FCVT_D_WU)) = {
  let rs1_val_WU = X(rs1) [31..0];
  let rm_3b      = encdec_rounding_mode (select_instr_or_fcsr_rm  (rm));

  let (fflags, rd_val_D) = external_ui32ToF64 (rm_3b, rs1_val_WU);

  writeCSR (csr_name_map ("fflags"), EXTZ (fflags));
  F(rd) = rd_val_D;
  RETIRE_SUCCESS
}

function clause execute (F_UN_RM_TYPE_D(rs1, rm, rd, FCVT_L_D)) = {
  let rs1_val_D = F(rs1);
  let rm_3b     = encdec_rounding_mode (select_instr_or_fcsr_rm  (rm));

  let (fflags, rd_val_L) = external_f64ToI64 (rm_3b, rs1_val_D);

  writeCSR (csr_name_map ("fflags"), EXTZ (fflags));
  X(rd) = rd_val_L;
  RETIRE_SUCCESS
}

function clause execute (F_UN_RM_TYPE_D(rs1, rm, rd, FCVT_LU_D)) = {
  let rs1_val_D = F(rs1);
  let rm_3b     = encdec_rounding_mode (select_instr_or_fcsr_rm  (rm));

  let (fflags, rd_val_LU) = external_f64ToUi64 (rm_3b, rs1_val_D);

  writeCSR (csr_name_map ("fflags"), EXTZ (fflags));
  X(rd) = rd_val_LU;
  RETIRE_SUCCESS
}

function clause execute (F_UN_RM_TYPE_D(rs1, rm, rd, FCVT_D_L)) = {
  let rs1_val_L = X(rs1);
  let rm_3b     = encdec_rounding_mode (select_instr_or_fcsr_rm  (rm));

  let (fflags, rd_val_D) = external_i64ToF64 (rm_3b, rs1_val_L);

  writeCSR (csr_name_map ("fflags"), EXTZ (fflags));
  F(rd) = rd_val_D;
  RETIRE_SUCCESS
}

function clause execute (F_UN_RM_TYPE_D(rs1, rm, rd, FCVT_D_LU)) = {
  let rs1_val_LU = X(rs1);
  let rm_3b      = encdec_rounding_mode (select_instr_or_fcsr_rm  (rm));

  let (fflags, rd_val_D) = external_ui64ToF64 (rm_3b, rs1_val_LU);

  writeCSR (csr_name_map ("fflags"), EXTZ (fflags));
  F(rd) = rd_val_D;
  RETIRE_SUCCESS
}

/* AST -> Assembly notation ================================ */

mapping f_un_rm_type_mnemonic_S : f_un_rm_op_S <-> string = {
    FSQRT_S   <-> "fsqrt.s",
    FCVT_W_S  <-> "fcvt.w.s",
    FCVT_WU_S <-> "fcvt.wu.s",
    FCVT_S_W  <-> "fcvt.s.w",
    FCVT_S_WU <-> "fcvt.s.wu",

    FCVT_L_S  <-> "fcvt.l.s",
    FCVT_LU_S <-> "fcvt.lu.s",
    FCVT_S_L  <-> "fcvt.s.l",
    FCVT_S_LU <-> "fcvt.s.lu"
}

mapping clause assembly = F_UN_RM_TYPE_S(rs1, rm, rd, op)
                      <-> f_un_rm_type_mnemonic_S(op)
		          ^ spc() ^ reg_name(rd)
			  ^ sep() ^ reg_name(rs1)
			  ^ sep() ^ frm_mnemonic(rm)

mapping f_un_rm_type_mnemonic_D : f_un_rm_op_D <-> string = {
    FSQRT_D   <-> "fsqrt.d",
    FCVT_W_D  <-> "fcvt.w.d",
    FCVT_WU_D <-> "fcvt.wu.d",
    FCVT_D_W  <-> "fcvt.d.w",
    FCVT_D_WU <-> "fcvt.d.wu",

    FCVT_L_D  <-> "fcvt.l.d",
    FCVT_LU_D <-> "fcvt.lu.d",
    FCVT_D_L  <-> "fcvt.d.l",
    FCVT_D_L  <-> "fcvt.d.lu"
}

mapping clause assembly = F_UN_RM_TYPE_D(rs1, rm, rd, op)
                      <-> f_un_rm_type_mnemonic_D(op)
		          ^ spc() ^ reg_name(rd)
			  ^ sep() ^ reg_name(rs1)
			  ^ sep() ^ frm_mnemonic(rm)

/* ****************************************************************** */
/* Binary, no rounding mode */

/* AST */

enum f_bin_op_S = {FSGNJ_S, FSGNJN_S, FSGNJX_S, FMIN_S, FMAX_S, FEQ_S, FLT_S, FLE_S}

union clause ast = F_BIN_TYPE_S : (regidx, regidx, regidx, f_bin_op_S)

enum f_bin_op_D = {FSGNJ_D, FSGNJN_D, FSGNJX_D, FMIN_D, FMAX_D, FEQ_D, FLT_D, FLE_D}

union clause ast = F_BIN_TYPE_D : (regidx, regidx, regidx, f_bin_op_D)

/* AST <-> Binary encoding ================================ */

/* F instructions */

mapping clause encdec = F_BIN_TYPE_S(rs2, rs1, rd, FSGNJ_S)               if is_RV32F_or_RV64F()
                    <-> 0b001_0000 @ rs2 @ rs1 @ 0b000 @ rd @ 0b101_0011  if is_RV32F_or_RV64F()

mapping clause encdec = F_BIN_TYPE_S(rs2, rs1, rd, FSGNJN_S)              if is_RV32F_or_RV64F()
                    <-> 0b001_0000 @ rs2 @ rs1 @ 0b001 @ rd @ 0b101_0011  if is_RV32F_or_RV64F()

mapping clause encdec = F_BIN_TYPE_S(rs2, rs1, rd, FSGNJX_S)              if is_RV32F_or_RV64F()
                    <-> 0b001_0000 @ rs2 @ rs1 @ 0b010 @ rd @ 0b101_0011  if is_RV32F_or_RV64F()

mapping clause encdec = F_BIN_TYPE_S(rs2, rs1, rd, FMIN_S)                if is_RV32F_or_RV64F()
                    <-> 0b001_0100 @ rs2 @ rs1 @ 0b000 @ rd @ 0b101_0011  if is_RV32F_or_RV64F()

mapping clause encdec = F_BIN_TYPE_S(rs2, rs1, rd, FMAX_S)                if is_RV32F_or_RV64F()
                    <-> 0b001_0100 @ rs2 @ rs1 @ 0b001 @ rd @ 0b101_0011  if is_RV32F_or_RV64F()

mapping clause encdec = F_BIN_TYPE_S(rs2, rs1, rd, FEQ_S)                 if is_RV32F_or_RV64F()
                    <-> 0b101_0000 @ rs2 @ rs1 @ 0b010 @ rd @ 0b101_0011  if is_RV32F_or_RV64F()

mapping clause encdec = F_BIN_TYPE_S(rs2, rs1, rd, FLT_S)                 if is_RV32F_or_RV64F()
                    <-> 0b101_0000 @ rs2 @ rs1 @ 0b001 @ rd @ 0b101_0011  if is_RV32F_or_RV64F()

mapping clause encdec = F_BIN_TYPE_S(rs2, rs1, rd, FLE_S)                 if is_RV32F_or_RV64F()
                    <-> 0b101_0000 @ rs2 @ rs1 @ 0b000 @ rd @ 0b101_0011  if is_RV32F_or_RV64F()


/* D instructions */

mapping clause encdec = F_BIN_TYPE_D(rs2, rs1, rd, FSGNJ_D)               if is_RV32D_or_RV64D()
                    <-> 0b001_0001 @ rs2 @ rs1 @ 0b000 @ rd @ 0b101_0011  if is_RV32D_or_RV64D()

mapping clause encdec = F_BIN_TYPE_D(rs2, rs1, rd, FSGNJN_D)              if is_RV32D_or_RV64D()
                    <-> 0b001_0001 @ rs2 @ rs1 @ 0b001 @ rd @ 0b101_0011  if is_RV32D_or_RV64D()

mapping clause encdec = F_BIN_TYPE_D(rs2, rs1, rd, FSGNJX_D)              if is_RV32D_or_RV64D()
                    <-> 0b001_0001 @ rs2 @ rs1 @ 0b010 @ rd @ 0b101_0011  if is_RV32D_or_RV64D()

mapping clause encdec = F_BIN_TYPE_D(rs2, rs1, rd, FMIN_D)                if is_RV32D_or_RV64D()
                    <-> 0b001_0101 @ rs2 @ rs1 @ 0b000 @ rd @ 0b101_0011  if is_RV32D_or_RV64D()

mapping clause encdec = F_BIN_TYPE_D(rs2, rs1, rd, FMAX_D)                if is_RV32D_or_RV64D()
                    <-> 0b001_0101 @ rs2 @ rs1 @ 0b001 @ rd @ 0b101_0011  if is_RV32D_or_RV64D()

mapping clause encdec = F_BIN_TYPE_D(rs2, rs1, rd, FEQ_D)                 if is_RV32D_or_RV64D()
                    <-> 0b101_0001 @ rs2 @ rs1 @ 0b010 @ rd @ 0b101_0011  if is_RV32D_or_RV64D()

mapping clause encdec = F_BIN_TYPE_D(rs2, rs1, rd, FLT_D)                 if is_RV32D_or_RV64D()
                    <-> 0b101_0001 @ rs2 @ rs1 @ 0b001 @ rd @ 0b101_0011  if is_RV32D_or_RV64D()

mapping clause encdec = F_BIN_TYPE_D(rs2, rs1, rd, FLE_D)                 if is_RV32D_or_RV64D()
                    <-> 0b101_0001 @ rs2 @ rs1 @ 0b000 @ rd @ 0b101_0011  if is_RV32D_or_RV64D()


/* Execution semantics ================================ */

function clause execute (F_BIN_TYPE_S(rs2, rs1, rd, FSGNJ_S)) = {
  let rs1_val_S    = nan_unbox (F(rs1));
  let rs2_val_S    = nan_unbox (F(rs2));
  let (s1, e1, m1) = fsplit_S (rs1_val_S);
  let (s2, e2, m2) = fsplit_S (rs2_val_S);
  let rd_val_S     = fmake_S (s2, e1, m1);
  let fflags       = 0b_00000;
  writeCSR (csr_name_map ("fflags"), EXTZ (fflags));
  F(rd) = nan_box (rd_val_S);
  RETIRE_SUCCESS
}

function clause execute (F_BIN_TYPE_S(rs2, rs1, rd, FSGNJN_S)) = {
  let rs1_val_S    = nan_unbox (F(rs1));
  let rs2_val_S    = nan_unbox (F(rs2));
  let (s1, e1, m1) = fsplit_S (rs1_val_S);
  let (s2, e2, m2) = fsplit_S (rs2_val_S);
  let rd_val_S     = fmake_S (0b1 ^ s2, e1, m1);
  let fflags       = 0b_00000;
  writeCSR (csr_name_map ("fflags"), EXTZ (fflags));
  F(rd) = nan_box (rd_val_S);
  RETIRE_SUCCESS
}

function clause execute (F_BIN_TYPE_S(rs2, rs1, rd, FSGNJX_S)) = {
  let rs1_val_S    = nan_unbox (F(rs1));
  let rs2_val_S    = nan_unbox (F(rs2));
  let (s1, e1, m1) = fsplit_S (rs1_val_S);
  let (s2, e2, m2) = fsplit_S (rs2_val_S);
  let rd_val_S     = fmake_S (s1 ^ s2, e1, m1);
  let fflags       = 0b_00000;
  writeCSR (csr_name_map ("fflags"), EXTZ (fflags));
  F(rd) = nan_box (rd_val_S);
  RETIRE_SUCCESS
}

function clause execute (F_BIN_TYPE_S(rs2, rs1, rd, FMIN_S)) = {
  let rs1_val_S = nan_unbox (F(rs1));
  let rs2_val_S = nan_unbox (F(rs2));

  let is_quiet  = true;
  let (rs1_lt_rs2, fflags) = fle_S (rs1_val_S, rs2_val_S, is_quiet);

  let rd_val_S  = if      (s_is_SNaN(rs1_val_S) & s_is_SNaN(rs2_val_S))         then canonical_NaN_S()
                  else if s_is_SNaN(rs1_val_S)                                  then rs2_val_S
		  else if s_is_SNaN(rs2_val_S)                                  then rs1_val_S
		  else if (s_is_QNaN(rs1_val_S) & s_is_QNaN(rs2_val_S))         then canonical_NaN_S()
		  else if s_is_QNaN(rs1_val_S)                                  then rs2_val_S
                  else if s_is_QNaN(rs2_val_S)                                  then rs1_val_S
                  else if (s_is_neg_zero(rs1_val_S) & s_is_pos_zero(rs2_val_S)) then rs1_val_S
                  else if (s_is_neg_zero(rs2_val_S) & s_is_pos_zero(rs1_val_S)) then rs2_val_S
                  else if rs1_lt_rs2                                            then rs1_val_S
                  else /* (not rs1_lt_rs2) */                                        rs2_val_S;

  writeCSR (csr_name_map ("fflags"), EXTZ (fflags));
  F(rd) = nan_box (rd_val_S);
  RETIRE_SUCCESS
}

function clause execute (F_BIN_TYPE_S(rs2, rs1, rd, FMAX_S)) = {
  let rs1_val_S = nan_unbox (F(rs1));
  let rs2_val_S = nan_unbox (F(rs2));

  let is_quiet  = true;
  let (rs2_lt_rs1, fflags) = fle_S (rs2_val_S, rs1_val_S, is_quiet);

  let rd_val_S  = if      (s_is_SNaN(rs1_val_S) & s_is_SNaN(rs2_val_S))         then canonical_NaN_S()
                  else if s_is_SNaN(rs1_val_S)                                  then rs2_val_S
		  else if s_is_SNaN(rs2_val_S)                                  then rs1_val_S
		  else if (s_is_QNaN(rs1_val_S) & s_is_QNaN(rs2_val_S))         then canonical_NaN_S()
		  else if s_is_QNaN(rs1_val_S)                                  then rs2_val_S
                  else if s_is_QNaN(rs2_val_S)                                  then rs1_val_S
                  else if (s_is_neg_zero(rs1_val_S) & s_is_pos_zero(rs2_val_S)) then rs2_val_S
                  else if (s_is_neg_zero(rs2_val_S) & s_is_pos_zero(rs1_val_S)) then rs1_val_S
                  else if rs2_lt_rs1                                            then rs1_val_S
                  else /* (not rs2_lt_rs1) */                                        rs2_val_S;

  writeCSR (csr_name_map ("fflags"), EXTZ (fflags));
  F(rd) = nan_box (rd_val_S);
  RETIRE_SUCCESS
}

function clause execute (F_BIN_TYPE_S(rs2, rs1, rd, FEQ_S)) = {
  let rs1_val_S = nan_unbox (F(rs1));
  let rs2_val_S = nan_unbox (F(rs2));

  let (rs1_eq_rs2, fflags) = feq_quiet_S (rs1_val_S, rs2_val_S);

  let rd_val : xlenbits =
      if      (s_is_SNaN(rs1_val_S) | s_is_SNaN(rs2_val_S)) then zeros()
      else if (s_is_QNaN(rs1_val_S) | s_is_QNaN(rs2_val_S)) then zeros()
      else if rs1_eq_rs2                                    then ones()
      else                                                  zeros();

  writeCSR (csr_name_map ("fflags"), EXTZ (fflags));
  X(rd) = rd_val;
  RETIRE_SUCCESS
}

function clause execute (F_BIN_TYPE_S(rs2, rs1, rd, FLT_S)) = {
  let rs1_val_S = nan_unbox (F(rs1));
  let rs2_val_S = nan_unbox (F(rs2));

  let is_quiet  = false;
  let (rs1_lt_rs2, fflags) = flt_S (rs1_val_S, rs2_val_S, is_quiet);

  let rd_val : xlenbits =
      if      (s_is_SNaN(rs1_val_S) | s_is_SNaN(rs2_val_S)) then zeros()
      else if (s_is_QNaN(rs1_val_S) | s_is_QNaN(rs2_val_S)) then zeros()
      else if rs1_lt_rs2                                    then ones()
      else                                                  zeros();

  writeCSR (csr_name_map ("fflags"), EXTZ (fflags));
  X(rd) = rd_val;
  RETIRE_SUCCESS
}

function clause execute (F_BIN_TYPE_S(rs2, rs1, rd, FLE_S)) = {
  let rs1_val_S = nan_unbox (F(rs1));
  let rs2_val_S = nan_unbox (F(rs2));

  let is_quiet  = false;
  let (rs1_le_rs2, fflags) = fle_S (rs1_val_S, rs2_val_S, is_quiet);

  let rd_val : xlenbits =
      if      (s_is_SNaN(rs1_val_S) | s_is_SNaN(rs2_val_S)) then zeros()
      else if (s_is_QNaN(rs1_val_S) | s_is_QNaN(rs2_val_S)) then zeros()
      else if rs1_le_rs2                                    then ones()
      else                                                  zeros();

  writeCSR (csr_name_map ("fflags"), EXTZ (fflags));
  X(rd) = rd_val;
  RETIRE_SUCCESS
}

/* ---- */

function clause execute (F_BIN_TYPE_D(rs2, rs1, rd, FSGNJ_D)) = {
  let rs1_val_D    = F(rs1);
  let rs2_val_D    = F(rs2);
  let (s1, e1, m1) = fsplit_D (rs1_val_D);
  let (s2, e2, m2) = fsplit_D (rs2_val_D);
  let rd_val_D     = fmake_D (s2, e1, m1);
  let fflags       = 0b_00000;
  writeCSR (csr_name_map ("fflags"), EXTZ (fflags));
  F(rd) = rd_val_D;
  RETIRE_SUCCESS
}

function clause execute (F_BIN_TYPE_D(rs2, rs1, rd, FSGNJN_D)) = {
  let rs1_val_D    = F(rs1);
  let rs2_val_D    = F(rs2);
  let (s1, e1, m1) = fsplit_D (rs1_val_D);
  let (s2, e2, m2) = fsplit_D (rs2_val_D);
  let rd_val_D     = fmake_D (0b1 ^ s2, e1, m1);
  let fflags       = 0b_00000;
  writeCSR (csr_name_map ("fflags"), EXTZ (fflags));
  F(rd) = rd_val_D;
  RETIRE_SUCCESS
}

function clause execute (F_BIN_TYPE_D(rs2, rs1, rd, FSGNJX_D)) = {
  let rs1_val_D    = F(rs1);
  let rs2_val_D    = F(rs2);
  let (s1, e1, m1) = fsplit_D (rs1_val_D);
  let (s2, e2, m2) = fsplit_D (rs2_val_D);
  let rd_val_D     = fmake_D (s1 ^ s2, e1, m1);
  let fflags       = 0b_00000;
  writeCSR (csr_name_map ("fflags"), EXTZ (fflags));
  F(rd) = rd_val_D;
  RETIRE_SUCCESS
}

function clause execute (F_BIN_TYPE_D(rs2, rs1, rd, FMIN_D)) = {
  let rs1_val_D = F(rs1);
  let rs2_val_D = F(rs2);

  let is_quiet  = true;
  let (rs1_lt_rs2, fflags) = fle_D (rs1_val_D, rs2_val_D, is_quiet);

  let rd_val_D  = if      (d_is_SNaN(rs1_val_D) & d_is_SNaN(rs2_val_D))         then canonical_NaN_D()
                  else if d_is_SNaN(rs1_val_D)                                  then rs2_val_D
		  else if d_is_SNaN(rs2_val_D)                                  then rs1_val_D
		  else if (d_is_QNaN(rs1_val_D) & d_is_QNaN(rs2_val_D))         then canonical_NaN_D()
		  else if d_is_QNaN(rs1_val_D)                                  then rs2_val_D
                  else if d_is_QNaN(rs2_val_D)                                  then rs1_val_D
                  else if (d_is_neg_zero(rs1_val_D) & d_is_pos_zero(rs2_val_D)) then rs1_val_D
                  else if (d_is_neg_zero(rs2_val_D) & d_is_pos_zero(rs1_val_D)) then rs2_val_D
                  else if rs1_lt_rs2                                            then rs1_val_D
                  else /* (not rs1_lt_rs2) */                                        rs2_val_D;

  writeCSR (csr_name_map ("fflags"), EXTZ (fflags));
  F(rd) = rd_val_D;
  RETIRE_SUCCESS
}

function clause execute (F_BIN_TYPE_D(rs2, rs1, rd, FMAX_D)) = {
  let rs1_val_D = F(rs1);
  let rs2_val_D = F(rs2);

  let is_quiet  = true;
  let (rs2_lt_rs1, fflags) = fle_D (rs2_val_D, rs1_val_D, is_quiet);

  let rd_val_D  = if      (d_is_SNaN(rs1_val_D) & d_is_SNaN(rs2_val_D))         then canonical_NaN_D()
                  else if d_is_SNaN(rs1_val_D)                                  then rs2_val_D
		  else if d_is_SNaN(rs2_val_D)                                  then rs1_val_D
		  else if (d_is_QNaN(rs1_val_D) & d_is_QNaN(rs2_val_D))         then canonical_NaN_D()
		  else if d_is_QNaN(rs1_val_D)                                  then rs2_val_D
                  else if d_is_QNaN(rs2_val_D)                                  then rs1_val_D
                  else if (d_is_neg_zero(rs1_val_D) & d_is_pos_zero(rs2_val_D)) then rs2_val_D
                  else if (d_is_neg_zero(rs2_val_D) & d_is_pos_zero(rs1_val_D)) then rs1_val_D
                  else if rs2_lt_rs1                                            then rs1_val_D
                  else /* (not rs2_lt_rs1) */                                        rs2_val_D;

  writeCSR (csr_name_map ("fflags"), EXTZ (fflags));
  F(rd) = rd_val_D;
  RETIRE_SUCCESS
}

function clause execute (F_BIN_TYPE_D(rs2, rs1, rd, FEQ_D)) = {
  let rs1_val_D = F(rs1);
  let rs2_val_D = F(rs2);

  let (rs1_eq_rs2, fflags) = feq_quiet_D (rs1_val_D, rs2_val_D);

  let rd_val : xlenbits =
      if      (d_is_SNaN(rs1_val_D) | d_is_SNaN(rs2_val_D)) then zeros()
      else if (d_is_QNaN(rs1_val_D) | d_is_QNaN(rs2_val_D)) then zeros()
      else if rs1_eq_rs2                                    then ones()
      else                                                  zeros();

  writeCSR (csr_name_map ("fflags"), EXTZ (fflags));
  X(rd) = rd_val;
  RETIRE_SUCCESS
}

function clause execute (F_BIN_TYPE_D(rs2, rs1, rd, FLT_D)) = {
  let rs1_val_D = F(rs1);
  let rs2_val_D = F(rs2);

  let is_quiet  = false;
  let (rs1_lt_rs2, fflags) = flt_D (rs1_val_D, rs2_val_D, is_quiet);

  let rd_val : xlenbits =
      if      (d_is_SNaN(rs1_val_D) | d_is_SNaN(rs2_val_D)) then zeros()
      else if (d_is_QNaN(rs1_val_D) | d_is_QNaN(rs2_val_D)) then zeros()
      else if rs1_lt_rs2                                    then ones()
      else                                                  zeros();

  writeCSR (csr_name_map ("fflags"), EXTZ (fflags));
  X(rd) = rd_val;
  RETIRE_SUCCESS
}

function clause execute (F_BIN_TYPE_D(rs2, rs1, rd, FLE_D)) = {
  let rs1_val_D = F(rs1);
  let rs2_val_D = F(rs2);

  let is_quiet  = false;
  let (rs1_le_rs2, fflags) = fle_D (rs1_val_D, rs2_val_D, is_quiet);

  let rd_val : xlenbits =
      if      (d_is_SNaN(rs1_val_D) | d_is_SNaN(rs2_val_D)) then zeros()
      else if (d_is_QNaN(rs1_val_D) | d_is_QNaN(rs2_val_D)) then zeros()
      else if rs1_le_rs2                                    then ones()
      else                                                  zeros();

  writeCSR (csr_name_map ("fflags"), EXTZ (fflags));
  X(rd) = rd_val;
  RETIRE_SUCCESS
}

/* AST -> Assembly notation ================================ */

mapping f_bin_type_mnemonic_S : f_bin_op_S <-> string = {
    FSGNJ_S  <-> "fsgnj.s",
    FSGNJN_S <-> "fsgnjn.s",
    FSGNJX_S <-> "fsgnjx.s",
    FMIN_S   <-> "fmin.s",
    FMAX_S   <-> "fmax.s",
    FEQ_S    <-> "feq.s",
    FLT_S    <-> "flt.s",
    FLE_S    <-> "fle.s"
}

mapping clause assembly = F_BIN_TYPE_S(rs2, rs1, rd, op)
                      <-> f_bin_type_mnemonic_S(op)
		          ^ spc() ^ reg_name(rd)
			  ^ sep() ^ reg_name(rs1)
			  ^ sep() ^ reg_name(rs2)

mapping f_bin_type_mnemonic_D : f_bin_op_D <-> string = {
    FSGNJ_D  <-> "fsgnj.d",
    FSGNJN_D <-> "fsgnjn.d",
    FSGNJX_D <-> "fsgnjx.d",
    FMIN_D   <-> "fmin.d",
    FMAX_D   <-> "fmax.d",
    FEQ_D    <-> "feq.d",
    FLT_D    <-> "flt.d",
    FLE_D    <-> "fle.d"
}

mapping clause assembly = F_BIN_TYPE_D(rs2, rs1, rd, op)
                      <-> f_bin_type_mnemonic_D(op)
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
