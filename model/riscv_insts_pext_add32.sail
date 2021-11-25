/* Programming Langauge Lab, Department of Computer Science, National Tsing-Hua University, Taiwan */
/* Academia Sinica, Taiwan*/
/* Andes Technology Corporation*/

/* *****************************************************************/
/* This file specifies the instruction added by the 'P' extension. */
/* *****************************************************************/

/* *****************************************************************/
/* ********************* auxiliary functions ***********************/
/* *****************************************************************/

val PEXT_ADD32 : (regidx, regidx, regidx) -> bool
  effect {escape, rreg, wreg}
function PEXT_ADD32 (rs2, rs1, rd) = {
  let result : bits(64) =
    (rW(rs1, 1) + rW(rs2, 1)) @ (rW(rs1, 0) + rW(rs2, 0));
  X(rd) = result;
  true
}

val PEXT_KADD32 : (regidx, regidx, regidx) -> bool
  effect {escape, rreg, wreg}
function PEXT_KADD32 (rs2, rs1, rd) = {
  let result : xlenbits =
    kadd (rW(rs1, 1), rW(rs2, 1)) @ kadd (rW(rs1, 0), rW(rs2, 0));
  X(rd) = result;
  true
}

val PEXT_UKADD32 : (regidx, regidx, regidx) -> bool
  effect {escape, rreg, wreg}
function PEXT_UKADD32 (rs2, rs1, rd) = {
  let result : xlenbits =
    ukadd (rW(rs1, 1), rW(rs2, 1)) @ ukadd (rW(rs1, 0), rW(rs2, 0));
  X(rd) = result;
  true
}

val PEXT_RADD32 : (regidx, regidx, regidx) -> bool
  effect {escape, rreg, wreg}
function PEXT_RADD32 (rs2, rs1, rd) = {
  let result : xlenbits =
    radd (rW(rs1, 1), rW(rs2, 1)) @ radd (rW(rs1, 0), rW(rs2, 0));
  X(rd) = result;
  true
}

val PEXT_URADD32 : (regidx, regidx, regidx) -> bool
  effect {escape, rreg, wreg}
function PEXT_URADD32 (rs2, rs1, rd) = {
  let result : xlenbits =
    uradd (rW(rs1, 1), rW(rs2, 1)) @ uradd (rW(rs1, 0), rW(rs2, 0));
  X(rd) = result;
  true
}