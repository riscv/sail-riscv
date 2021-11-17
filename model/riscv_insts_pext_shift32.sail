/* *****************************************************************/
/* This file specifies the instruction added by the 'P' extension. */
/* *****************************************************************/

/* *****************************************************************/
/* ********************* auxiliary functions ***********************/
/* *****************************************************************/

val PEXT_SRA32 : (regidx, regidx, regidx) -> bool effect {escape,rreg,wreg}
function PEXT_SRA32(rs2, rs1, rd) = {
  let sa : byte = EXTZ(X(rs2)[4..0]) in
  X(rd) = shift_right_arith (rW(rs1, 1), sa) @ shift_right_arith (rW(rs1, 0), sa);
  true
}

/* *****************************************************************/

val PEXT_SRA32_U : (regidx, regidx, regidx) -> bool effect {escape,rreg,wreg}
function PEXT_SRA32_U(rs2, rs1, rd) = {
  let sa : byte = EXTZ(X(rs2)[4..0]) in
  X(rd) = shift_right_arith_u (rW(rs1, 1), sa) @ shift_right_arith_u (rW(rs1, 0), sa);
  true
}

/* *****************************************************************/

val PEXT_SRAI32 : (bits(5), regidx, regidx) -> bool effect {escape,rreg,wreg}
function PEXT_SRAI32 (imm5, rs1, rd) = {
  let sa : byte = EXTZ (imm5);
  X(rd) = shift_right_arith (rW(rs1, 1), sa) @ shift_right_arith (rW(rs1, 0), sa);
  true
}

/* *****************************************************************/

val PEXT_SRAI32_U : (bits(5), regidx, regidx) -> bool effect {escape,rreg,wreg}
function PEXT_SRAI32_U(imm5, rs1, rd) = {
  let sa : byte = EXTZ(imm5) in
  X(rd) = shift_right_arith_u (rW(rs1, 1), sa) @ shift_right_arith_u (rW(rs1, 0), sa);
  true
}

/* *****************************************************************/

val PEXT_SRL32 : (regidx, regidx, regidx) -> bool effect {escape,rreg,wreg}
function PEXT_SRL32(rs2, rs1, rd) = {
  let sa : byte = EXTZ(X(rs2)[4..0]) in
  X(rd) = shift_right_logic (rW(rs1, 1), sa) @ shift_right_logic (rW(rs1, 0), sa);
  true
}

/* *****************************************************************/

val PEXT_SRL32_U : (regidx, regidx, regidx) -> bool effect {escape,rreg,wreg}
function PEXT_SRL32_U(rs2, rs1, rd) = {
  let sa : byte = EXTZ(X(rs2)[4..0]) in
  X(rd) = shift_right_logic_u (rW(rs1, 1), sa) @ shift_right_logic_u (rW(rs1, 0), sa);
  true
}

/* *****************************************************************/

val PEXT_SRLI32 : (bits(5), regidx, regidx) -> bool effect {escape,rreg,wreg}
function PEXT_SRLI32 (imm5, rs1, rd) = {
  let sa : byte = EXTZ (imm5) in
  X(rd) = shift_right_logic (rW(rs1, 1), sa) @ shift_right_logic (rW(rs1, 0), sa);
  true
}

/* *****************************************************************/

val PEXT_SRLI32_U : (bits(5), regidx, regidx) -> bool effect {escape,rreg,wreg}
function PEXT_SRLI32_U(imm5, rs1, rd) = {
  let sa : byte = EXTZ(imm5) in
  X(rd) = shift_right_logic_u (rW(rs1, 1), sa) @ shift_right_logic_u (rW(rs1, 0), sa);
  true
}

/* *****************************************************************/

val PEXT_SLL32 : (regidx, regidx, regidx) -> bool effect {escape,rreg,wreg}
function PEXT_SLL32(rs2, rs1, rd) = {
  let sa : byte = EXTZ(X(rs2)[4..0]) in
  X(rd) = shift_left_logic (rW(rs1, 1), sa) @ shift_left_logic (rW(rs1, 0), sa);
  true
}

/* *****************************************************************/

val PEXT_SLLI32 : (bits(5), regidx, regidx) -> bool effect {escape,rreg,wreg}
function PEXT_SLLI32 (imm5, rs1, rd) = {
  let sa : byte = EXTZ (imm5) in
  X(rd) = shift_left_logic (rW(rs1, 1), sa) @ shift_left_logic (rW(rs1, 0), sa);
  true
}

/* *****************************************************************/

val PEXT_KSLL32 : (regidx, regidx, regidx) -> bool effect {escape,rreg,wreg}
function PEXT_KSLL32(rs2, rs1, rd) = {
  let sa : byte = EXTZ(X(rs2)[4..0]) in
  X(rd) = kshift_left_logic (rW(rs1, 1), sa) @ kshift_left_logic (rW(rs1, 0), sa);
  true
}

/* *****************************************************************/

val PEXT_KSLLI32 : (bits(5), regidx, regidx) -> bool effect {escape,rreg,wreg}
function PEXT_KSLLI32 (imm5, rs1, rd) = {
  let sa : byte = EXTZ (imm5) in
  X(rd) = kshift_left_logic (rW(rs1, 1), sa) @ kshift_left_logic (rW(rs1, 0), sa);
  true
}

/* *****************************************************************/

val PEXT_KSLRA32 : (regidx, regidx, regidx) -> bool effect {escape,rreg,wreg}
function PEXT_KSLRA32 (rs2, rs1, rd) = {
  let sa : byte = EXTS(X(rs2)[5..0]);
  X(rd) = kslra (rW(rs1, 1), sa) @ kslra (rW(rs1, 0), sa);
  true
}

/* *****************************************************************/

val PEXT_KSLRA32_U : (regidx, regidx, regidx) -> bool effect {escape,rreg,wreg}
function PEXT_KSLRA32_U (rs2, rs1, rd) = {
  let sa : byte = EXTS(X(rs2)[5..0]);
  X(rd) = kslra_u (rW(rs1, 1), sa) @ kslra_u (rW(rs1, 0), sa);
  true
}

/* *****************************************************************/

val PEXT_SRAIW_U : (bits(5), regidx, regidx) -> bool effect {escape,rreg,wreg}
function PEXT_SRAIW_U (imm5, rs1, rd) = {
  let sa : byte = EXTZ(imm5);
  X(rd) =
    if (sa == 0x00)
    then EXTS(rW(rs1, 0))
    else EXTS(shift_right_arith_u (rW(rs1, 0), sa)); 
  true
}

/* *****************************************************************/