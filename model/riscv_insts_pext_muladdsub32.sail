/* *****************************************************************/
/* This file specifies the instruction added by the 'P' extension. */
/* *****************************************************************/

/* *****************************************************************/
/* ********************* auxiliary functions ***********************/
/* *****************************************************************/

/* *****************************************************************/

val PEXT_SMBT32 : (regidx, regidx, regidx) -> bool effect {escape,rreg,wreg}
function PEXT_SMBT32(rs2, rs1, rd) = {
  X(rd) = smul (rW(rs1, 0), rW(rs2, 1));
  true
}

/* *****************************************************************/

val PEXT_SMTT32 : (regidx, regidx, regidx) -> bool effect {escape,rreg,wreg}
function PEXT_SMTT32(rs2, rs1, rd) = {
  X(rd) = smul (rW(rs1, 1), rW(rs2, 1));
  true
}

/* *****************************************************************/

val PEXT_SMDS32 : (regidx, regidx, regidx) -> bool effect {escape,rreg,wreg}
function PEXT_SMDS32(rs2, rs1, rd) = {
  X(rd) = smul (rW(rs1, 1), rW(rs2, 1)) - smul (rW(rs1, 0), rW(rs2, 0));
  true
}

/* *****************************************************************/

val PEXT_SMDRS32 : (regidx, regidx, regidx) -> bool effect {escape,rreg,wreg}
function PEXT_SMDRS32(rs2, rs1, rd) = {
  X(rd) = smul (rW(rs1, 0), rW(rs2, 0)) - smul (rW(rs1, 1), rW(rs2, 1));
  true
}

/* *****************************************************************/

val PEXT_SMXDS32 : (regidx, regidx, regidx) -> bool effect {escape,rreg,wreg}
function PEXT_SMXDS32(rs2, rs1, rd) = {
  X(rd) = smul (rW(rs1, 1), rW(rs2, 0)) - smul (rW(rs1, 0), rW(rs2, 1));
  true
}

/* *****************************************************************/

val PEXT_KMABB32 : (regidx, regidx, regidx) -> bool effect {escape,rreg,wreg}
function PEXT_KMABB32(rs2, rs1, rd) = {
  X(rd) = kadd (smul (rW(rs1, 0), rW(rs2, 0)), rD(rd));
  true
}

/* *****************************************************************/

val PEXT_KMABT32 : (regidx, regidx, regidx) -> bool effect {escape,rreg,wreg}
function PEXT_KMABT32(rs2, rs1, rd) = {
  X(rd) = kadd (smul (rW(rs1, 0), rW(rs2, 1)), rD(rd));
  true
}

/* *****************************************************************/

val PEXT_KMATT32 : (regidx, regidx, regidx) -> bool effect {escape,rreg,wreg}
function PEXT_KMATT32(rs2, rs1, rd) = {
  X(rd) = kadd (smul (rW(rs1, 1), rW(rs2, 1)), rD(rd));
  true
}

/* *****************************************************************/

val PEXT_KMADA32 : (regidx, regidx, regidx) -> bool effect {escape,rreg,wreg}
function PEXT_KMADA32(rs2, rs1, rd) = {
  X(rd) = kmada(rD(rd), rW(rs1, 1), rW(rs2, 1), rW(rs1, 0), rW(rs2, 0));
  true
}

/* *****************************************************************/

val PEXT_KMAXDA32 : (regidx, regidx, regidx) -> bool effect {escape,rreg,wreg}
function PEXT_KMAXDA32(rs2, rs1, rd) = {
  X(rd) = kmada(rD(rd), rW(rs1, 1), rW(rs2, 0), rW(rs1, 0), rW(rs2, 1));
  true
}

/* *****************************************************************/

val PEXT_KMADS32 : (regidx, regidx, regidx) -> bool effect {escape,rreg,wreg}
function PEXT_KMADS32(rs2, rs1, rd) = {
  X(rd) = kmads(rD(rd), rW(rs1, 1), rW(rs2, 1), rW(rs1, 0), rW(rs2, 0));
  true
}

/* *****************************************************************/

val PEXT_KMADRS32 : (regidx, regidx, regidx) -> bool effect {escape,rreg,wreg}
function PEXT_KMADRS32(rs2, rs1, rd) = {
  X(rd) = kmads(rD(rd), rW(rs1, 0), rW(rs2, 0), rW(rs1, 1), rW(rs2, 1));
  true
}

/* *****************************************************************/

val PEXT_KMAXDS32 : (regidx, regidx, regidx) -> bool effect {escape,rreg,wreg}
function PEXT_KMAXDS32(rs2, rs1, rd) = {
  X(rd) = kmads(rD(rd), rW(rs1, 1), rW(rs2, 0), rW(rs1, 0), rW(rs2, 1));
  true
}

/* *****************************************************************/

val PEXT_KMSDA32 : (regidx, regidx, regidx) -> bool effect {escape,rreg,wreg}
function PEXT_KMSDA32(rs2, rs1, rd) = {
  X(rd) = kmsda(rD(rd), rW(rs1, 1), rW(rs2, 1), rW(rs1, 0), rW(rs2, 0));
  true
}

/* *****************************************************************/

val PEXT_KMSXDA32 : (regidx, regidx, regidx) -> bool effect {escape,rreg,wreg}
function PEXT_KMSXDA32(rs2, rs1, rd) = {
  X(rd) = kmsda(rD(rd), rW(rs1, 1), rW(rs2, 0), rW(rs1, 0), rW(rs2, 1));
  true
}

/* *****************************************************************/
