/* *****************************************************************/
/* This file specifies the instruction added by the 'P' extension. */
/* *****************************************************************/

/* *****************************************************************/
/* ********************* auxiliary functions ***********************/
/* *****************************************************************/

val kdm : forall 'n, 'n == 16.
  (bits('n), bits('n)) -> bits(2 * 'n) effect {rreg,wreg}
function kdm (v1, v2) =
  let lb : bits('n) = not_vec(EXTS(sail_ones ('n) >> 1)) in
  if v1 == lb & v2 == lb then { pext_write_OV (0b1); ones (2 * 'n) >> 1 }
  else { to_bits (2 * 'n - 1, signed(v1) * signed(v2)) @ 0b0 }

val kslraw :
  (bits (32), byte) -> bits (32) effect {rreg,wreg}
function kslraw (v, m) =
  let rev : byte = if m <_s 0x00 then not_vec (m) + 0x01 else m in
  let sa : byte = if rev == 0x20 then 0x1F else rev in
  if m <_s 0x00 then shift_right_arith(v, sa)
  else kshift_left_logic(v, sa)

val kslraw_u :
  (bits (32), byte) -> bits (32) effect {rreg,wreg}
function kslraw_u (v, m) =
  let rev : byte = if m <_s 0x00 then not_vec (m) + 0x01 else m in
  let sa : byte = if rev == 0x20 then 0x1F else rev in
  if m <_s 0x00
  then
  let res33 : bits(33) = add_bits(EXTS(shift_right_arith(v, sa - 0x01)), EXTS(0x1)) in
  res33[32..1]
  else kshift_left_logic(v, sa)

val kdmaw :
  (bits(16), bits(16), bits(32)) -> bits(32) effect {rreg,wreg}
function kdmaw (v1, v2, rd) = {
  let resQ31 : bits(32) = kdm(v1, v2);
  let tmp : bits(33) = EXTS(resQ31) + EXTS(rd);
  let ub : bits(33) = EXTS(sail_ones (32) >> 1) in
  let lb : bits(33) = not_vec (ub) in
  if tmp <_s lb then { pext_write_OV (0b1); not_vec (ones (32) >> 1) }
  else if ub <_s tmp then { pext_write_OV (0b1); ones (32) >> 1 }
  else { slice (tmp, 0, 32) }
}

/* *****************************************************************/

val PEXT_KADDW : (regidx, regidx, regidx) -> bool effect {escape, rreg, wreg}
function PEXT_KADDW (rs2, rs1, rd) = {
  if sizeof(xlen) == 32
  then X(rd) = kadd(rW(rs1, 0), rW(rs2, 0))
  else X(rd) = EXTS(kadd(rW(rs1, 0), rW(rs2, 0)));
  true
}

/* *****************************************************************/

val PEXT_UKADDW : (regidx, regidx, regidx) -> bool effect {escape, rreg, wreg}
function PEXT_UKADDW (rs2, rs1, rd) = {
  if sizeof(xlen) == 32
  then X(rd) = ukadd(rW(rs1, 0), rW(rs2, 0))
  else X(rd) = EXTS(ukadd(rW(rs1, 0), rW(rs2, 0)));
  true
}

/* *****************************************************************/

val PEXT_KSUBW : (regidx, regidx, regidx) -> bool effect {escape, rreg, wreg}
function PEXT_KSUBW (rs2, rs1, rd) = {
  if sizeof(xlen) == 32
  then X(rd) = ksub(rW(rs1, 0), rW(rs2, 0))
  else X(rd) = EXTS(ksub(rW(rs1, 0), rW(rs2, 0)));
  true
}

/* *****************************************************************/

val PEXT_UKSUBW : (regidx, regidx, regidx) -> bool effect {escape, rreg, wreg}
function PEXT_UKSUBW (rs2, rs1, rd) = {
  if sizeof(xlen) == 32
  then X(rd) = uksub(rW(rs1, 0), rW(rs2, 0))
  else X(rd) = EXTS(uksub(rW(rs1, 0), rW(rs2, 0)));
  true
}

/* *****************************************************************/

val PEXT_KDMBB : (regidx, regidx, regidx) -> bool effect {escape, rreg, wreg}
function PEXT_KDMBB (rs2, rs1, rd) = {
  if sizeof(xlen) == 32
  then X(rd) = kdm(rH(rs1, 0), rH(rs2, 0))
  else X(rd) = EXTS(kdm(rH(rs1, 0), rH(rs2, 0)));
  true
}

/* *****************************************************************/

val PEXT_KDMBT : (regidx, regidx, regidx) -> bool effect {escape, rreg, wreg}
function PEXT_KDMBT (rs2, rs1, rd) = {
  if sizeof(xlen) == 32
  then X(rd) = kdm(rH(rs1, 0), rH(rs2, 1))
  else X(rd) = EXTS(kdm(rH(rs1, 0), rH(rs2, 1)));
  true
}

/* *****************************************************************/

val PEXT_KDMTT : (regidx, regidx, regidx) -> bool effect {escape, rreg, wreg}
function PEXT_KDMTT (rs2, rs1, rd) = {
  if sizeof(xlen) == 32
  then X(rd) = kdm(rH(rs1, 1), rH(rs2, 1))
  else X(rd) = EXTS(kdm(rH(rs1, 1), rH(rs2, 1)));
  true
}

/* *****************************************************************/

val PEXT_KSLRAW : (regidx, regidx, regidx) -> bool effect {escape,rreg,wreg}
function PEXT_KSLRAW (rs2, rs1, rd) = {
  let sa : byte = EXTS(X(rs2)[5..0]);
  if sizeof(xlen) == 32
  then X(rd) = kslraw(rW(rs1, 0), sa)
  else X(rd) = EXTS(kslraw(rW(rs1, 0), sa));
  true
}

/* *****************************************************************/

val PEXT_KSLRAW_U : (regidx, regidx, regidx) -> bool effect {escape,rreg,wreg}
function PEXT_KSLRAW_U (rs2, rs1, rd) = {
  let sa : byte = EXTS(X(rs2)[5..0]);
  if sizeof(xlen) == 32
  then X(rd) = kslraw_u(rW(rs1, 0), sa)
  else X(rd) = EXTS(kslraw_u(rW(rs1, 0), sa));
  true
}

/* *****************************************************************/

val PEXT_KSLLW : (regidx, regidx, regidx) -> bool effect {escape,rreg,wreg}
function PEXT_KSLLW (rs2, rs1, rd) = {
  let sa : byte = EXTZ(X(rs2)[4..0]);
  if sizeof(xlen) == 32
  then X(rd) = kshift_left_logic(rW(rs1, 0), sa)
  else X(rd) = EXTS(kshift_left_logic(rW(rs1, 0), sa));
  true
}

/* *****************************************************************/

val PEXT_KSLLIW : (bits(5), regidx, regidx) -> bool effect {escape,rreg,wreg}
function PEXT_KSLLIW (imm5, rs1, rd) = {
  let sa : byte = EXTZ(imm5);
  if sizeof(xlen) == 32
  then X(rd) = kshift_left_logic(rW(rs1, 0), sa)
  else X(rd) = EXTS(kshift_left_logic(rW(rs1, 0), sa));
  true
}

/* *****************************************************************/

val PEXT_KDMABB : (regidx, regidx, regidx) -> bool effect {escape,rreg,wreg}
function PEXT_KDMABB (rs2, rs1, rd) = {
  if sizeof(xlen) == 32
  then X(rd) = kdmaw(rH(rs1, 0), rH(rs2, 0), rW(rd, 0))
  else X(rd) = EXTS(kdmaw(rH(rs1, 0), rH(rs2, 0), rW(rd, 0)));
  true
}

/* *****************************************************************/

val PEXT_KDMABT : (regidx, regidx, regidx) -> bool effect {escape,rreg,wreg}
function PEXT_KDMABT (rs2, rs1, rd) = {
  if sizeof(xlen) == 32
  then X(rd) = kdmaw(rH(rs1, 0), rH(rs2, 1), rW(rd, 0))
  else X(rd) = EXTS(kdmaw(rH(rs1, 0), rH(rs2, 1), rW(rd, 0)));
  true
}

/* *****************************************************************/

val PEXT_KDMATT : (regidx, regidx, regidx) -> bool effect {escape,rreg,wreg}
function PEXT_KDMATT (rs2, rs1, rd) = {
  if sizeof(xlen) == 32
  then X(rd) = kdmaw(rH(rs1, 1), rH(rs2, 1), rW(rd, 0))
  else X(rd) = EXTS(kdmaw(rH(rs1, 1), rH(rs2, 1), rW(rd, 0)));
  true
}

/* *****************************************************************/

val PEXT_KABSW : (regidx, regidx) -> bool effect {escape,rreg,wreg}
function PEXT_KABSW(rs1, rd) = {
  if sizeof(xlen) == 32
  then X(rd) = kabs(rW(rs1, 0))
  else X(rd) = EXTS(kabs(rW(rs1, 0)));
  true
}

/* *****************************************************************/
