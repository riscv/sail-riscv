/* *****************************************************************/
/* This file specifies the instruction added by the 'P' extension. */
/* *****************************************************************/

/* *****************************************************************/
/* ********************* auxiliary functions ***********************/
/* *****************************************************************/

val PEXT_PKBB32 : (regidx, regidx, regidx) -> bool effect {escape,rreg,wreg}
function PEXT_PKBB32 (rs2, rs1, rd) = {
  let result : xlenbits =
    rW(rs1, 0) @ rW(rs2, 0);
  X(rd) = result;
  true
}

/* *****************************************************************/

val PEXT_PKBT32 : (regidx, regidx, regidx) -> bool effect {escape,rreg,wreg}
function PEXT_PKBT32 (rs2, rs1, rd) = {
  let result : xlenbits =
    rW(rs1, 0) @ rW(rs2, 1);
  X(rd) = result;
  true
}

/* *****************************************************************/

val PEXT_PKTT32 : (regidx, regidx, regidx) -> bool effect {escape,rreg,wreg}
function PEXT_PKTT32 (rs2, rs1, rd) = {
  let result : xlenbits =
    rW(rs1, 1) @ rW(rs2, 1);
  X(rd) = result;
  true
}

/* *****************************************************************/

val PEXT_PKTB32 : (regidx, regidx, regidx) -> bool effect {escape,rreg,wreg}
function PEXT_PKTB32 (rs2, rs1, rd) = {
  let result : xlenbits =
    rW(rs1, 1) @ rW(rs2, 0);
  X(rd) = result;
  true
}