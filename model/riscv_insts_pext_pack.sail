/* Programming Langauge Lab, Department of Computer Science, National Tsing-Hua University, Taiwan */
/* Academia Sinica, Taiwan*/
/* Andes Technology Corporation*/

/* *****************************************************************/
/* This file specifies the instruction added by the 'P' extension. */
/* *****************************************************************/

/* *****************************************************************/
/* ********************* auxiliary functions ***********************/
/* *****************************************************************/


/* *****************************************************************/

val PEXT_PKBB16 : (regidx, regidx, regidx) -> bool effect {escape,rreg,wreg}
function PEXT_PKBB16 (rs2, rs1, rd) = {
  let result : xlenbits =
    if sizeof(xlen) == 32
    then  rH(rs1, 0) @ rH(rs2, 0)
    else  rH(rs1, 2) @ rH(rs2, 2) @ rH(rs1, 0) @ rH(rs2, 0);
  X(rd) = result;
  true
}

/* *****************************************************************/

val PEXT_PKBT16 : (regidx, regidx, regidx) -> bool effect {escape,rreg,wreg}
function PEXT_PKBT16 (rs2, rs1, rd) = {
  let result : xlenbits =
    if sizeof(xlen) == 32
    then  rH(rs1, 0) @ rH(rs2, 1)
    else  rH(rs1, 2) @ rH(rs2, 3) @ rH(rs1, 0) @ rH(rs2, 1);
  X(rd) = result;
  true
}

/* *****************************************************************/

val PEXT_PKTB16 : (regidx, regidx, regidx) -> bool effect {escape,rreg,wreg}
function PEXT_PKTB16 (rs2, rs1, rd) = {
  let result : xlenbits =
    if sizeof(xlen) == 32
    then  rH(rs1, 1) @ rH(rs2, 0)
    else  rH(rs1, 3) @ rH(rs2, 2) @ rH(rs1, 1) @ rH(rs2, 0);
  X(rd) = result;
  true
}

/* *****************************************************************/

val PEXT_PKTT16 : (regidx, regidx, regidx) -> bool effect {escape,rreg,wreg}
function PEXT_PKTT16 (rs2, rs1, rd) = {
  let result : xlenbits =
    if sizeof(xlen) == 32
    then  rH(rs1, 1) @ rH(rs2, 1)
    else  rH(rs1, 3) @ rH(rs2, 3) @ rH(rs1, 1) @ rH(rs2, 1);
  X(rd) = result;
  true
}