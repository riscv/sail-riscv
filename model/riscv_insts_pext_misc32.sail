/* *****************************************************************/
/* This file specifies the instruction added by the 'P' extension. */
/* *****************************************************************/

/* *****************************************************************/
/* ********************* auxiliary functions ***********************/
/* *****************************************************************/

/* *****************************************************************/

val PEXT_SMIN32 : (regidx, regidx, regidx) -> bool effect {escape,rreg,wreg}
function PEXT_SMIN32(rs2, rs1, rd) = {
  let result : xlenbits =
    smin (rW(rs1, 1), rW(rs2, 1)) @ smin (rW(rs1, 0), rW(rs2, 0));
  X(rd) = result;
  true
}

/* *****************************************************************/

val PEXT_UMIN32 : (regidx, regidx, regidx) -> bool effect {escape,rreg,wreg}
function PEXT_UMIN32(rs2, rs1, rd) = {
  let result : xlenbits =
    umin (rW(rs1, 1), rW(rs2, 1)) @ umin (rW(rs1, 0), rW(rs2, 0));
  X(rd) = result;
  true
}

/* *****************************************************************/

val PEXT_SMAX32 : (regidx, regidx, regidx) -> bool effect {escape,rreg,wreg}
function PEXT_SMAX32(rs2, rs1, rd) = {
  let result : xlenbits =
    smax (rW(rs1, 1), rW(rs2, 1)) @ smax (rW(rs1, 0), rW(rs2, 0));
  X(rd) = result;
  true
}

/* *****************************************************************/

val PEXT_UMAX32 : (regidx, regidx, regidx) -> bool effect {escape,rreg,wreg}
function PEXT_UMAX32(rs2, rs1, rd) = {
  let result : xlenbits =
    umax (rW(rs1, 1), rW(rs2, 1)) @ umax (rW(rs1, 0), rW(rs2, 0));
  X(rd) = result;
  true
}

/* *****************************************************************/

val PEXT_KABS32 : (regidx, regidx) -> bool effect {escape,rreg,wreg}
function PEXT_KABS32(rs1, rd) = {
  let result : xlenbits =
    kabs (rW(rs1, 1)) @ kabs (rW(rs1, 0));
  X(rd) = result;
  true
}

/* *****************************************************************/
