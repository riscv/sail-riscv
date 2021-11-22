/* Programming Langauge Lab, Department of Computer Science, National Tsing-Hua University, Taiwan */
/* Academia Sinica, Taiwan*/
/* Andes Technology Corporation, Taiwan*/

/* *****************************************************************/
/* This file specifies the instruction added by the 'P' extension. */
/* *****************************************************************/

/* *****************************************************************/
/* ********************* auxiliary functions ***********************/
/* *****************************************************************/


val shift_right_arith : forall 'n, 'n == 8 | 'n == 9 | 'n == 16 | 'n == 17 | 'n == 32 | 'n == 33 | 'n == 64.
  (bits ('n), byte) -> bits ('n)
function shift_right_arith (v, m) =
  let extv : bits(xlen + 65) = EXTS (v) in
  slice (extv >> m, 0, 'n)

val shift_right_arith_u : forall 'n, 'n == 8 | 'n == 16 | 'n == 32 | 'n == 64.
  (bits ('n), byte) -> bits ('n)
function shift_right_arith_u (v, m) =
  if m == 0x00 then v
  else let res : bits(65) = add_bits(EXTS(shift_right_arith(v, m - 0x01)), EXTZ(0b1)) in
  slice(res >> 1, 0, 'n)

val shift_right_logic : forall 'n, 'n == 8 | 'n == 9 | 'n == 16 | 'n == 17 | 'n == 32 | 'n == 33 | 'n == 64.
  (bits ('n), byte) -> bits ('n)
function shift_right_logic (v, m) =
  let extv : bits(xlen + 65) = EXTZ (v) in
  slice (extv >> m, 0, 'n)

val shift_right_logic_u : forall 'n, 'n == 8 | 'n == 16 | 'n == 32.
  (bits ('n), byte) -> bits ('n)
function shift_right_logic_u (v, m) =
  if m == 0x00 then v
  else let res : bits(65) = add_bits(EXTZ(shift_right_logic(v, m - 0x01)), EXTZ(0b1)) in slice(res >> 1, 0, 'n)

val shift_left_logic : forall 'n, 'n == 8 | 'n == 9 | 'n == 16 | 'n == 17 | 'n == 32 | 'n == 33.
  (bits ('n), byte) -> bits ('n)
function shift_left_logic (v, m) =
  let extv : bits(xlen + 32) = EXTZ (v) in
  slice (extv << m, 0, 'n)

val kshift_left_logic : forall 'n, 'n == 8 | 'n == 16 | 'n == 32.
  (bits ('n), byte) -> bits ('n) effect {rreg,wreg}
function kshift_left_logic (v, m) =
  let ub : bits(xlen + 32) = EXTS(sail_ones ('n) >> 1) in
  let lb : bits(xlen + 32) = not_vec (ub) in
  let vext : bits(xlen + 32) = EXTS(v) in
  let shiftext : bits(xlen + 32) = vext << m in
  if shiftext <_s lb then { pext_write_OV (0b1); not_vec (ones ('n) >> 1) }
  else if ub <_s shiftext then { pext_write_OV (0b1); ones ('n) >> 1 }
  else { slice (shiftext, 0, 'n) }

val kslra : forall 'n, 'n == 8 | 'n == 16 | 'n == 32.
  (bits ('n), byte) -> bits ('n) effect {rreg,wreg}
function kslra (v, m) =
  let rev : byte = if m <_s 0x00 then not_vec (m) + 0x01 else m in
  let sa : byte = if rev == to_bits(8, 'n) then to_bits(8, 'n) - 0x01 else rev in
  if m <_s 0x00 then shift_right_arith(v, sa)
  else kshift_left_logic(v, sa)

val kslra_u : forall 'n, 'n == 8 | 'n == 16 | 'n == 32.
  (bits ('n), byte) -> bits ('n) effect {rreg,wreg}
function kslra_u (v, m) =
  let rev : byte = if m <_s 0x00 then not_vec (m) + 0x01 else m in
  let sa : byte = if rev == to_bits(8, 'n) then to_bits(8, 'n) - 0x01 else rev in
  if m <_s 0x00 then shift_right_arith_u(v, sa)
  else kshift_left_logic(v, sa)

/* *****************************************************************/

val PEXT_SRA16 : (regidx, regidx, regidx) -> bool effect {escape,rreg,wreg}
function PEXT_SRA16(rs2, rs1, rd) = {
  let sa : byte = 0x0 @ X(rs2)[3..0];
  let result : xlenbits =
    if sizeof(xlen) == 32
    then  shift_right_arith (rH(rs1, 1), sa) @
          shift_right_arith (rH(rs1, 0), sa)
    else  shift_right_arith (rH(rs1, 3), sa) @
          shift_right_arith (rH(rs1, 2), sa) @
          shift_right_arith (rH(rs1, 1), sa) @
          shift_right_arith (rH(rs1, 0), sa);
  X(rd) = result;
  true
}

/* *****************************************************************/

val PEXT_SRA16_U : (regidx, regidx, regidx) -> bool effect {escape,rreg,wreg}
function PEXT_SRA16_U(rs2, rs1, rd) = {
  let sa : byte = 0x0 @ X(rs2)[3..0];
  let result : xlenbits =
    if sizeof(xlen) == 32
    then  shift_right_arith_u (rH(rs1, 1), sa) @
          shift_right_arith_u (rH(rs1, 0), sa)
    else  shift_right_arith_u (rH(rs1, 3), sa) @
          shift_right_arith_u (rH(rs1, 2), sa) @
          shift_right_arith_u (rH(rs1, 1), sa) @
          shift_right_arith_u (rH(rs1, 0), sa);
  X(rd) = result;
  true
}

/* *****************************************************************/

val PEXT_SRA8 : (regidx, regidx, regidx) -> bool effect {escape,rreg,wreg}
function PEXT_SRA8 (rs2, rs1, rd) = {
  let sa : byte = 0x0 @ 0b0 @ X(rs2)[2..0];
  let result : xlenbits =
    if sizeof(xlen) == 32
    then  shift_right_arith (rB(rs1, 3), sa) @
          shift_right_arith (rB(rs1, 2), sa) @
          shift_right_arith (rB(rs1, 1), sa) @
          shift_right_arith (rB(rs1, 0), sa)
    else  shift_right_arith (rB(rs1, 7), sa) @
          shift_right_arith (rB(rs1, 6), sa) @
          shift_right_arith (rB(rs1, 5), sa) @
          shift_right_arith (rB(rs1, 4), sa) @
          shift_right_arith (rB(rs1, 3), sa) @
          shift_right_arith (rB(rs1, 2), sa) @
          shift_right_arith (rB(rs1, 1), sa) @
          shift_right_arith (rB(rs1, 0), sa);
  X(rd) = result;
  true
}

/* *****************************************************************/

val PEXT_SRA8_U : (regidx, regidx, regidx) -> bool effect {escape,rreg,wreg}
function clause PEXT_SRA8_U (rs2, rs1, rd) = {
  let sa : byte = 0x0 @ 0b0 @ X(rs2)[2..0];
  let result : xlenbits =
    if sizeof(xlen) == 32
    then  shift_right_arith_u (rB(rs1, 3), sa) @
          shift_right_arith_u (rB(rs1, 2), sa) @
          shift_right_arith_u (rB(rs1, 1), sa) @
          shift_right_arith_u (rB(rs1, 0), sa)
    else  shift_right_arith_u (rB(rs1, 7), sa) @
          shift_right_arith_u (rB(rs1, 6), sa) @
          shift_right_arith_u (rB(rs1, 5), sa) @
          shift_right_arith_u (rB(rs1, 4), sa) @
          shift_right_arith_u (rB(rs1, 3), sa) @
          shift_right_arith_u (rB(rs1, 2), sa) @
          shift_right_arith_u (rB(rs1, 1), sa) @
          shift_right_arith_u (rB(rs1, 0), sa);
  X(rd) = result;
  true
}

/* *****************************************************************/

val PEXT_SRL16 : (regidx, regidx, regidx) -> bool effect {escape,rreg,wreg}
function PEXT_SRL16 (rs2, rs1, rd) = {
  let sa : byte = 0x0 @ X(rs2)[3..0];
  let result : xlenbits =
    if sizeof(xlen) == 32
    then  shift_right_logic (rH(rs1, 1), sa) @
          shift_right_logic (rH(rs1, 0), sa)
    else  shift_right_logic (rH(rs1, 3), sa) @
          shift_right_logic (rH(rs1, 2), sa) @
          shift_right_logic (rH(rs1, 1), sa) @
          shift_right_logic (rH(rs1, 0), sa);
  X(rd) = result;
  true
}

/* *****************************************************************/

val PEXT_SRL16_U : (regidx, regidx, regidx) -> bool effect {escape,rreg,wreg}
function PEXT_SRL16_U (rs2, rs1, rd) = {
  let sa : byte = 0x0 @ X(rs2)[3..0];
  let result : xlenbits =
    if sizeof(xlen) == 32
    then  shift_right_logic_u (rH(rs1, 1), sa) @
          shift_right_logic_u (rH(rs1, 0), sa)
    else  shift_right_logic_u (rH(rs1, 3), sa) @
          shift_right_logic_u (rH(rs1, 2), sa) @
          shift_right_logic_u (rH(rs1, 1), sa) @
          shift_right_logic_u (rH(rs1, 0), sa);
  X(rd) = result;
  true
}

/* *****************************************************************/

val PEXT_SRL8 : (regidx, regidx, regidx) -> bool effect {escape,rreg,wreg}
function PEXT_SRL8 (rs2, rs1, rd) = {
  let sa : byte = 0x0 @ 0b0 @ X(rs2)[2..0];
  let result : xlenbits =
    if sizeof(xlen) == 32
    then  shift_right_logic (rB(rs1, 3), sa) @
          shift_right_logic (rB(rs1, 2), sa) @
          shift_right_logic (rB(rs1, 1), sa) @
          shift_right_logic (rB(rs1, 0), sa)
    else  shift_right_logic (rB(rs1, 7), sa) @
          shift_right_logic (rB(rs1, 6), sa) @
          shift_right_logic (rB(rs1, 5), sa) @
          shift_right_logic (rB(rs1, 4), sa) @
          shift_right_logic (rB(rs1, 3), sa) @
          shift_right_logic (rB(rs1, 2), sa) @
          shift_right_logic (rB(rs1, 1), sa) @
          shift_right_logic (rB(rs1, 0), sa);
  X(rd) = result;
  true
}

/* *****************************************************************/

val PEXT_SRL8_U : (regidx, regidx, regidx) -> bool effect {escape,rreg,wreg}
function PEXT_SRL8_U (rs2, rs1, rd) = {
  let sa : byte = 0x0 @ 0b0 @ X(rs2)[2..0];
  let result : xlenbits =
    if sizeof(xlen) == 32
    then  shift_right_logic_u (rB(rs1, 3), sa) @
          shift_right_logic_u (rB(rs1, 2), sa) @
          shift_right_logic_u (rB(rs1, 1), sa) @
          shift_right_logic_u (rB(rs1, 0), sa)
    else  shift_right_logic_u (rB(rs1, 7), sa) @
          shift_right_logic_u (rB(rs1, 6), sa) @
          shift_right_logic_u (rB(rs1, 5), sa) @
          shift_right_logic_u (rB(rs1, 4), sa) @
          shift_right_logic_u (rB(rs1, 3), sa) @
          shift_right_logic_u (rB(rs1, 2), sa) @
          shift_right_logic_u (rB(rs1, 1), sa) @
          shift_right_logic_u (rB(rs1, 0), sa);
  X(rd) = result;
  true
}

/* *****************************************************************/

val PEXT_SLL16 : (regidx, regidx, regidx) -> bool effect {escape,rreg,wreg}
function PEXT_SLL16 (rs2, rs1, rd) = {
  let sa : byte = 0x0 @ X(rs2)[3..0];
  let result : xlenbits =
    if sizeof(xlen) == 32
    then  shift_left_logic (rH(rs1, 1), sa) @
          shift_left_logic (rH(rs1, 0), sa)
    else  shift_left_logic (rH(rs1, 3), sa) @
          shift_left_logic (rH(rs1, 2), sa) @
          shift_left_logic (rH(rs1, 1), sa) @
          shift_left_logic (rH(rs1, 0), sa);
  X(rd) = result;
  true
}

/* *****************************************************************/

val PEXT_SLL8 : (regidx, regidx, regidx) -> bool effect {escape,rreg,wreg}
function PEXT_SLL8 (rs2, rs1, rd) = {
  let sa : byte = 0x0 @ 0b0 @ X(rs2)[2..0];
  let result : xlenbits =
    if sizeof(xlen) == 32
    then  shift_left_logic (rB(rs1, 3), sa) @
          shift_left_logic (rB(rs1, 2), sa) @
          shift_left_logic (rB(rs1, 1), sa) @
          shift_left_logic (rB(rs1, 0), sa)
    else  shift_left_logic (rB(rs1, 7), sa) @
          shift_left_logic (rB(rs1, 6), sa) @
          shift_left_logic (rB(rs1, 5), sa) @
          shift_left_logic (rB(rs1, 4), sa) @
          shift_left_logic (rB(rs1, 3), sa) @
          shift_left_logic (rB(rs1, 2), sa) @
          shift_left_logic (rB(rs1, 1), sa) @
          shift_left_logic (rB(rs1, 0), sa);
  X(rd) = result;
  true
}

/* *****************************************************************/

val PEXT_SRAI16 : (bits(4), regidx, regidx) -> bool effect {escape,rreg,wreg}
function PEXT_SRAI16 (imm4, rs1, rd) = {
  let sa : byte = EXTZ (imm4);
  let result : xlenbits =
    if sizeof(xlen) == 32
    then  shift_right_arith (rH(rs1, 1), sa) @
          shift_right_arith (rH(rs1, 0), sa)
    else  shift_right_arith (rH(rs1, 3), sa) @
          shift_right_arith (rH(rs1, 2), sa) @
          shift_right_arith (rH(rs1, 1), sa) @
          shift_right_arith (rH(rs1, 0), sa);
  X(rd) = result;
  true
}

/* *****************************************************************/

val PEXT_SRAI16_U : (bits(4), regidx, regidx) -> bool effect {escape,rreg,wreg}
function PEXT_SRAI16_U (imm4, rs1, rd) = {
  let sa : byte = EXTZ (imm4);
  let result : xlenbits =
    if sizeof(xlen) == 32
    then  shift_right_arith_u (rH(rs1, 1), sa) @
          shift_right_arith_u (rH(rs1, 0), sa)
    else  shift_right_arith_u (rH(rs1, 3), sa) @
          shift_right_arith_u (rH(rs1, 2), sa) @
          shift_right_arith_u (rH(rs1, 1), sa) @
          shift_right_arith_u (rH(rs1, 0), sa);
  X(rd) = result;
  true
}

/* *****************************************************************/

val PEXT_SRAI8 : (bits(3), regidx, regidx) -> bool effect {escape,rreg,wreg}
function PEXT_SRAI8 (imm3, rs1, rd) = {
  let sa : byte = EXTZ(imm3);
  let result : xlenbits =
    if sizeof(xlen) == 32
    then  shift_right_arith (rB(rs1, 3), sa) @
          shift_right_arith (rB(rs1, 2), sa) @
          shift_right_arith (rB(rs1, 1), sa) @
          shift_right_arith (rB(rs1, 0), sa)
    else  shift_right_arith (rB(rs1, 7), sa) @
          shift_right_arith (rB(rs1, 6), sa) @
          shift_right_arith (rB(rs1, 5), sa) @
          shift_right_arith (rB(rs1, 4), sa) @
          shift_right_arith (rB(rs1, 3), sa) @
          shift_right_arith (rB(rs1, 2), sa) @
          shift_right_arith (rB(rs1, 1), sa) @
          shift_right_arith (rB(rs1, 0), sa);
  X(rd) = result;
  true
}

/* *****************************************************************/

val PEXT_SRAI8_U : (bits(3), regidx, regidx) -> bool effect {escape,rreg,wreg}
function PEXT_SRAI8_U (imm3, rs1, rd) = {
  let sa : byte = EXTZ(imm3);
  let result : xlenbits =
    if sizeof(xlen) == 32
    then  shift_right_arith_u (rB(rs1, 3), sa) @
          shift_right_arith_u (rB(rs1, 2), sa) @
          shift_right_arith_u (rB(rs1, 1), sa) @
          shift_right_arith_u (rB(rs1, 0), sa)
    else  shift_right_arith_u (rB(rs1, 7), sa) @
          shift_right_arith_u (rB(rs1, 6), sa) @
          shift_right_arith_u (rB(rs1, 5), sa) @
          shift_right_arith_u (rB(rs1, 4), sa) @
          shift_right_arith_u (rB(rs1, 3), sa) @
          shift_right_arith_u (rB(rs1, 2), sa) @
          shift_right_arith_u (rB(rs1, 1), sa) @
          shift_right_arith_u (rB(rs1, 0), sa);
  X(rd) = result;
  true
}

/* *****************************************************************/

val PEXT_SRLI16 : (bits(4), regidx, regidx) -> bool effect {escape,rreg,wreg}
function PEXT_SRLI16 (imm4, rs1, rd) = {
  let sa : byte = EXTZ(imm4);
  let result : xlenbits =
    if sizeof(xlen) == 32
    then  shift_right_logic (rH(rs1, 1), sa) @
          shift_right_logic (rH(rs1, 0), sa)
    else  shift_right_logic (rH(rs1, 3), sa) @
          shift_right_logic (rH(rs1, 2), sa) @
          shift_right_logic (rH(rs1, 1), sa) @
          shift_right_logic (rH(rs1, 0), sa);
  X(rd) = result;
  true
}

/* *****************************************************************/

val PEXT_SRLI16_U : (bits(4), regidx, regidx) -> bool effect {escape,rreg,wreg}
function PEXT_SRLI16_U (imm4, rs1, rd) = {
  let sa : byte = EXTZ(imm4);
  let result : xlenbits =
    if sizeof(xlen) == 32
    then  shift_right_logic_u (rH(rs1, 1), sa) @
          shift_right_logic_u (rH(rs1, 0), sa)
    else  shift_right_logic_u (rH(rs1, 3), sa) @
          shift_right_logic_u (rH(rs1, 2), sa) @
          shift_right_logic_u (rH(rs1, 1), sa) @
          shift_right_logic_u (rH(rs1, 0), sa);
  X(rd) = result;
  true
}

/* *****************************************************************/

val PEXT_SRLI8 : (bits(3), regidx, regidx) -> bool effect {escape,rreg,wreg}
function PEXT_SRLI8 (imm3, rs1, rd) = {
  let sa : byte = EXTZ(imm3);
  let result : xlenbits =
    if sizeof(xlen) == 32
    then  shift_right_logic (rB(rs1, 3), sa) @
          shift_right_logic (rB(rs1, 2), sa) @
          shift_right_logic (rB(rs1, 1), sa) @
          shift_right_logic (rB(rs1, 0), sa)
    else  shift_right_logic (rB(rs1, 7), sa) @
          shift_right_logic (rB(rs1, 6), sa) @
          shift_right_logic (rB(rs1, 5), sa) @
          shift_right_logic (rB(rs1, 4), sa) @
          shift_right_logic (rB(rs1, 3), sa) @
          shift_right_logic (rB(rs1, 2), sa) @
          shift_right_logic (rB(rs1, 1), sa) @
          shift_right_logic (rB(rs1, 0), sa);
  X(rd) = result;
  true
}

/* *****************************************************************/

val PEXT_SRLI8_U : (bits(3), regidx, regidx) -> bool effect {escape,rreg,wreg}
function PEXT_SRLI8_U (imm3, rs1, rd) = {
  let sa : byte = EXTZ(imm3);
  let result : xlenbits =
    if sizeof(xlen) == 32
    then  shift_right_logic_u (rB(rs1, 3), sa) @
          shift_right_logic_u (rB(rs1, 2), sa) @
          shift_right_logic_u (rB(rs1, 1), sa) @
          shift_right_logic_u (rB(rs1, 0), sa)
    else  shift_right_logic_u (rB(rs1, 7), sa) @
          shift_right_logic_u (rB(rs1, 6), sa) @
          shift_right_logic_u (rB(rs1, 5), sa) @
          shift_right_logic_u (rB(rs1, 4), sa) @
          shift_right_logic_u (rB(rs1, 3), sa) @
          shift_right_logic_u (rB(rs1, 2), sa) @
          shift_right_logic_u (rB(rs1, 1), sa) @
          shift_right_logic_u (rB(rs1, 0), sa);
  X(rd) = result;
  true
}

/* *****************************************************************/

val PEXT_SLLI16 : (bits(4), regidx, regidx) -> bool effect {escape,rreg,wreg}
function PEXT_SLLI16 (imm4, rs1, rd) = {
  let sa : byte = EXTZ(imm4);
  let result : xlenbits =
    if sizeof(xlen) == 32
    then  shift_left_logic (rH(rs1, 1), sa) @
          shift_left_logic (rH(rs1, 0), sa)
    else  shift_left_logic (rH(rs1, 3), sa) @
          shift_left_logic (rH(rs1, 2), sa) @
          shift_left_logic (rH(rs1, 1), sa) @
          shift_left_logic (rH(rs1, 0), sa);
  X(rd) = result;
  true
}

/* *****************************************************************/

val PEXT_SLLI8 : (bits(3), regidx, regidx) -> bool effect {escape,rreg,wreg}
function PEXT_SLLI8 (imm3, rs1, rd) = {
  let sa : byte = EXTZ(imm3);
  let result : xlenbits =
    if sizeof(xlen) == 32
    then  shift_left_logic (rB(rs1, 3), sa) @
          shift_left_logic (rB(rs1, 2), sa) @
          shift_left_logic (rB(rs1, 1), sa) @
          shift_left_logic (rB(rs1, 0), sa)
    else  shift_left_logic (rB(rs1, 7), sa) @
          shift_left_logic (rB(rs1, 6), sa) @
          shift_left_logic (rB(rs1, 5), sa) @
          shift_left_logic (rB(rs1, 4), sa) @
          shift_left_logic (rB(rs1, 3), sa) @
          shift_left_logic (rB(rs1, 2), sa) @
          shift_left_logic (rB(rs1, 1), sa) @
          shift_left_logic (rB(rs1, 0), sa);
  X(rd) = result;
  true
}

/* *****************************************************************/

val PEXT_KSLL16 : (regidx, regidx, regidx) -> bool effect {escape,rreg,wreg}
function PEXT_KSLL16 (rs2, rs1, rd) = {
  let sa : byte = 0x0 @ X(rs2)[3..0];
  let result : xlenbits =
    if sizeof(xlen) == 32
    then  kshift_left_logic (rH(rs1, 1), sa) @
          kshift_left_logic (rH(rs1, 0), sa)
    else  kshift_left_logic (rH(rs1, 3), sa) @
          kshift_left_logic (rH(rs1, 2), sa) @
          kshift_left_logic (rH(rs1, 1), sa) @
          kshift_left_logic (rH(rs1, 0), sa);
  X(rd) = result;
  true
}

/* *****************************************************************/

val PEXT_KSLLI16 : (bits(4), regidx, regidx) -> bool effect {escape,rreg,wreg}
function PEXT_KSLLI16 (imm4, rs1, rd) = {
  let sa : byte = EXTZ(imm4);
  let result : xlenbits =
    if sizeof(xlen) == 32
    then  kshift_left_logic (rH(rs1, 1), sa) @
          kshift_left_logic (rH(rs1, 0), sa)
    else  kshift_left_logic (rH(rs1, 3), sa) @
          kshift_left_logic (rH(rs1, 2), sa) @
          kshift_left_logic (rH(rs1, 1), sa) @
          kshift_left_logic (rH(rs1, 0), sa);
  X(rd) = result;
  true
}

/* *****************************************************************/

val PEXT_KSLL8 : (regidx, regidx, regidx) -> bool effect {escape,rreg,wreg}
function PEXT_KSLL8 (rs2, rs1, rd) = {
  let sa : byte = 0x0 @ 0b0 @ X(rs2)[2..0];
  let result : xlenbits =
    if sizeof(xlen) == 32
    then  kshift_left_logic (rB(rs1, 3), sa) @
          kshift_left_logic (rB(rs1, 2), sa) @
          kshift_left_logic (rB(rs1, 1), sa) @
          kshift_left_logic (rB(rs1, 0), sa)
    else  kshift_left_logic (rB(rs1, 7), sa) @
          kshift_left_logic (rB(rs1, 6), sa) @
          kshift_left_logic (rB(rs1, 5), sa) @
          kshift_left_logic (rB(rs1, 4), sa) @
          kshift_left_logic (rB(rs1, 3), sa) @
          kshift_left_logic (rB(rs1, 2), sa) @
          kshift_left_logic (rB(rs1, 1), sa) @
          kshift_left_logic (rB(rs1, 0), sa);
  X(rd) = result;
  true
}

/* *****************************************************************/

val PEXT_KSLLI8 : (bits(3), regidx, regidx) -> bool effect {escape,rreg,wreg}
function PEXT_KSLLI8 (imm3, rs1, rd) = {
  let sa : byte = EXTZ(imm3);
  let result : xlenbits =
    if sizeof(xlen) == 32
    then  kshift_left_logic (rB(rs1, 3), sa) @
          kshift_left_logic (rB(rs1, 2), sa) @
          kshift_left_logic (rB(rs1, 1), sa) @
          kshift_left_logic (rB(rs1, 0), sa)
    else  kshift_left_logic (rB(rs1, 7), sa) @
          kshift_left_logic (rB(rs1, 6), sa) @
          kshift_left_logic (rB(rs1, 5), sa) @
          kshift_left_logic (rB(rs1, 4), sa) @
          kshift_left_logic (rB(rs1, 3), sa) @
          kshift_left_logic (rB(rs1, 2), sa) @
          kshift_left_logic (rB(rs1, 1), sa) @
          kshift_left_logic (rB(rs1, 0), sa);
  X(rd) = result;
  true
}

/* *****************************************************************/

val PEXT_KSLRA16 : (regidx, regidx, regidx) -> bool effect {escape,rreg,wreg}
function PEXT_KSLRA16 (rs2, rs1, rd) = {
  let sa : byte = EXTS(X(rs2)[4..0]);
  let result : xlenbits =
    if sizeof(xlen) == 32
    then  kslra (rH(rs1, 1), sa) @
          kslra (rH(rs1, 0), sa)
    else  kslra (rH(rs1, 3), sa) @
          kslra (rH(rs1, 2), sa) @
          kslra (rH(rs1, 1), sa) @
          kslra (rH(rs1, 0), sa);
  X(rd) = result;
  true
}

/* *****************************************************************/

val PEXT_KSLRA8 : (regidx, regidx, regidx) -> bool effect {escape,rreg,wreg}
function PEXT_KSLRA8 (rs2, rs1, rd) = {
  let sa : byte = EXTS(X(rs2)[3..0]);
  let result : xlenbits =
    if sizeof(xlen) == 32
    then  kslra (rB(rs1, 3), sa) @
          kslra (rB(rs1, 2), sa) @
          kslra (rB(rs1, 1), sa) @
          kslra (rB(rs1, 0), sa)
    else  kslra (rB(rs1, 7), sa) @
          kslra (rB(rs1, 6), sa) @
          kslra (rB(rs1, 5), sa) @
          kslra (rB(rs1, 4), sa) @
          kslra (rB(rs1, 3), sa) @
          kslra (rB(rs1, 2), sa) @
          kslra (rB(rs1, 1), sa) @
          kslra (rB(rs1, 0), sa);
  X(rd) = result;
  true
}

/* *****************************************************************/

val PEXT_KSLRA16_U : (regidx, regidx, regidx) -> bool effect {escape,rreg,wreg}
function PEXT_KSLRA16_U (rs2, rs1, rd) = {
  let sa : byte = EXTS(X(rs2)[4..0]);
  let result : xlenbits =
    if sizeof(xlen) == 32
    then  kslra_u (rH(rs1, 1), sa) @
          kslra_u (rH(rs1, 0), sa)
    else  kslra_u (rH(rs1, 3), sa) @
          kslra_u (rH(rs1, 2), sa) @
          kslra_u (rH(rs1, 1), sa) @
          kslra_u (rH(rs1, 0), sa);
  X(rd) = result;
  true
}

/* *****************************************************************/

val PEXT_KSLRA8_U : (regidx, regidx, regidx) -> bool effect {escape,rreg,wreg}
function PEXT_KSLRA8_U (rs2, rs1, rd) = {
  let sa : byte = EXTS(X(rs2)[3..0]);
  let result : xlenbits =
    if sizeof(xlen) == 32
    then  kslra_u (rB(rs1, 3), sa) @
          kslra_u (rB(rs1, 2), sa) @
          kslra_u (rB(rs1, 1), sa) @
          kslra_u (rB(rs1, 0), sa)
    else  kslra_u (rB(rs1, 7), sa) @
          kslra_u (rB(rs1, 6), sa) @
          kslra_u (rB(rs1, 5), sa) @
          kslra_u (rB(rs1, 4), sa) @
          kslra_u (rB(rs1, 3), sa) @
          kslra_u (rB(rs1, 2), sa) @
          kslra_u (rB(rs1, 1), sa) @
          kslra_u (rB(rs1, 0), sa) ;
  X(rd) = result;
  true
}
