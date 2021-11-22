/* Programming Langauge Lab, Department of Computer Science, National Tsing-Hua University, Taiwan */
/* Academia Sinica, Taiwan*/
/* Andes Technology Corporation, Taiwan*/

/* *****************************************************************/
/* This file specifies the instruction added by the 'P' extension. */
/* *****************************************************************/

/* *****************************************************************/
/* ********************* auxiliary functions ***********************/
/* *****************************************************************/

val sshmexts :
  (bits(16), bits(16)) -> bits(32) effect {rreg, wreg}
function sshmexts (v1, v2) =
  EXTS(sshm (v1, v2))

/* *****************************************************************/

val PEXT_KHMBB16: (regidx, regidx, regidx) -> bool effect {escape,rreg,wreg}
function PEXT_KHMBB16 (rs2, rs1, rd) = {
  X(rd) = sshmexts(rH(rs1, 2), rH(rs2, 2)) @ sshmexts(rH(rs1, 0), rH(rs2, 0));
  true
}

/* *****************************************************************/

val PEXT_KHMBT16: (regidx, regidx, regidx) -> bool effect {escape,rreg,wreg}
function PEXT_KHMBT16 (rs2, rs1, rd) = {
  X(rd) = sshmexts(rH(rs1, 2), rH(rs2, 3)) @ sshmexts(rH(rs1, 0), rH(rs2, 1));
  true
}

/* *****************************************************************/

val PEXT_KHMTT16: (regidx, regidx, regidx) -> bool effect {escape,rreg,wreg}
function PEXT_KHMTT16 (rs2, rs1, rd) = {
  X(rd) = sshmexts(rH(rs1, 3), rH(rs2, 3)) @ sshmexts(rH(rs1, 1), rH(rs2, 1));
  true
}

/* *****************************************************************/

val PEXT_KDMBB16 : (regidx, regidx, regidx) -> bool effect {escape, rreg, wreg}
function PEXT_KDMBB16 (rs2, rs1, rd) = {
  X(rd) = kdm(rH(rs1, 2), rH(rs2, 2)) @ kdm(rH(rs1, 0), rH(rs2, 0));
  true
}

/* *****************************************************************/

val PEXT_KDMBT16 : (regidx, regidx, regidx) -> bool effect {escape, rreg, wreg}
function PEXT_KDMBT16 (rs2, rs1, rd) = {
  X(rd) = kdm(rH(rs1, 2), rH(rs2, 3)) @ kdm(rH(rs1, 0), rH(rs2, 1));
  true
}

/* *****************************************************************/

val PEXT_KDMTT16 : (regidx, regidx, regidx) -> bool effect {escape, rreg, wreg}
function PEXT_KDMTT16 (rs2, rs1, rd) = {
  X(rd) = kdm(rH(rs1, 3), rH(rs2, 3)) @ kdm(rH(rs1, 1), rH(rs2, 1));
  true
}

/* *****************************************************************/

val PEXT_KDMABB16 : (regidx, regidx, regidx) -> bool effect {escape,rreg,wreg}
function PEXT_KDMABB16 (rs2, rs1, rd) = {
  X(rd) = kdmaw(rH(rs1, 2), rH(rs2, 2), rW(rd, 1)) @ kdmaw(rH(rs1, 0), rH(rs2, 0), rW(rd, 0));
  true
}

/* *****************************************************************/

val PEXT_KDMABT16 : (regidx, regidx, regidx) -> bool effect {escape,rreg,wreg}
function PEXT_KDMABT16 (rs2, rs1, rd) = {
  X(rd) = kdmaw(rH(rs1, 2), rH(rs2, 3), rW(rd, 1)) @ kdmaw(rH(rs1, 0), rH(rs2, 1), rW(rd, 0));
  true
}

/* *****************************************************************/

val PEXT_KDMATT16 : (regidx, regidx, regidx) -> bool effect {escape,rreg,wreg}
function PEXT_KDMATT16 (rs2, rs1, rd) = {
  X(rd) = kdmaw(rH(rs1, 3), rH(rs2, 3), rW(rd, 1)) @ kdmaw(rH(rs1, 1), rH(rs2, 1), rW(rd, 0));
  true
}

/* *****************************************************************/
