/* Programming Langauge Lab, Department of Computer Science, National Tsing-Hua University, Taiwan */
/* Academia Sinica, Taiwan*/
/* Andes Technology Corporation, Taiwan*/

/* *****************************************************************/
/* This file specifies the instruction added by the 'P' extension. */
/* *****************************************************************/

/* *****************************************************************/
/* ********************* auxiliary functions ***********************/
/* *****************************************************************/


val exts16 : forall 'n, 'n == 8.
  (bits ('n)) -> bits (16)
function exts16 (v) =
  let result : bits(16) = EXTS (v) in
  slice(result, 0, 16)

val extz16 : forall 'n, 'n == 8.
  (bits ('n)) -> bits (16)
function extz16 (v) =
  let result : bits(16) = EXTZ (v) in
  slice(result, 0, 16)


/* *****************************************************************/

val PEXT_SUNPKD810 : (regidx, regidx) -> bool effect {escape,rreg,wreg}
function PEXT_SUNPKD810 (rs1, rd) = {
  let result : xlenbits =
    if sizeof(xlen) == 32
    then exts16(rB(rs1, 1)) @ exts16(rB(rs1, 0))
    else exts16(rB(rs1, 5)) @ exts16(rB(rs1, 4)) @ exts16(rB(rs1, 1)) @ exts16(rB(rs1, 0));
  X(rd) = result;
  true
}

/* *****************************************************************/

val PEXT_SUNPKD820 : (regidx, regidx) -> bool effect {escape,rreg,wreg}
function PEXT_SUNPKD820 (rs1, rd) = {
  let result : xlenbits =
    if sizeof(xlen) == 32
    then exts16(rB(rs1, 2)) @ exts16(rB(rs1, 0))
    else exts16(rB(rs1, 6)) @ exts16(rB(rs1, 4)) @ exts16(rB(rs1, 2)) @ exts16(rB(rs1, 0));
  X(rd) = result;
  true
}

/* *****************************************************************/

val PEXT_SUNPKD830 : (regidx, regidx) -> bool effect {escape,rreg,wreg}
function PEXT_SUNPKD830 (rs1, rd) = {
  let result : xlenbits =
    if sizeof(xlen) == 32
    then exts16(rB(rs1, 3)) @ exts16(rB(rs1, 0))
    else exts16(rB(rs1, 7)) @ exts16(rB(rs1, 4)) @ exts16(rB(rs1, 3)) @ exts16(rB(rs1, 0));
  X(rd) = result;
  true
}

/* *****************************************************************/

val PEXT_SUNPKD831 : (regidx, regidx) -> bool effect {escape,rreg,wreg}
function PEXT_SUNPKD831 (rs1, rd) = {
  let result : xlenbits =
    if sizeof(xlen) == 32
    then exts16(rB(rs1, 3)) @ exts16(rB(rs1, 1))
    else exts16(rB(rs1, 7)) @ exts16(rB(rs1, 5)) @ exts16(rB(rs1, 3)) @ exts16(rB(rs1, 1));
  X(rd) = result;
  true
}

/* *****************************************************************/

val PEXT_SUNPKD832 : (regidx, regidx) -> bool effect {escape,rreg,wreg}
function PEXT_SUNPKD832 (rs1, rd) = {
  let result : xlenbits =
    if sizeof(xlen) == 32
    then exts16(rB(rs1, 3)) @ exts16(rB(rs1, 2))
    else exts16(rB(rs1, 7)) @ exts16(rB(rs1, 6)) @ exts16(rB(rs1, 3)) @ exts16(rB(rs1, 2));
  X(rd) = result;
  true
}

/* *****************************************************************/

val PEXT_ZUNPKD810: (regidx, regidx) -> bool effect {escape,rreg,wreg}
function PEXT_ZUNPKD810 (rs1, rd) = {
  let result : xlenbits =
    if sizeof(xlen) == 32
    then extz16(rB(rs1, 1)) @ extz16(rB(rs1, 0))
    else extz16(rB(rs1, 5)) @ extz16(rB(rs1, 4)) @ extz16(rB(rs1, 1)) @ extz16(rB(rs1, 0));
  X(rd) = result;
  true
}

/* *****************************************************************/

val PEXT_ZUNPKD820 : (regidx, regidx) -> bool effect {escape,rreg,wreg}
function PEXT_ZUNPKD820 (rs1, rd) = {
  let result : xlenbits =
    if sizeof(xlen) == 32
    then extz16(rB(rs1, 2)) @ extz16(rB(rs1, 0))
    else extz16(rB(rs1, 6)) @ extz16(rB(rs1, 4)) @ extz16(rB(rs1, 2)) @ extz16(rB(rs1, 0));
  X(rd) = result;
  true
}

/* *****************************************************************/

val PEXT_ZUNPKD830 : (regidx, regidx) -> bool effect {escape,rreg,wreg}
function PEXT_ZUNPKD830 (rs1, rd) = {
  let result : xlenbits =
    if sizeof(xlen) == 32
    then extz16(rB(rs1, 3)) @ extz16(rB(rs1, 0))
    else extz16(rB(rs1, 7)) @ extz16(rB(rs1, 4)) @ extz16(rB(rs1, 3)) @ extz16(rB(rs1, 0));
  X(rd) = result;
  true
}

/* *****************************************************************/

val PEXT_ZUNPKD831 : (regidx, regidx) -> bool effect {escape,rreg,wreg}
function PEXT_ZUNPKD831 (rs1, rd) = {
  let result : xlenbits =
    if sizeof(xlen) == 32
    then extz16(rB(rs1, 3)) @ extz16(rB(rs1, 1))
    else extz16(rB(rs1, 7)) @ extz16(rB(rs1, 5)) @ extz16(rB(rs1, 3)) @ extz16(rB(rs1, 1));
  X(rd) = result;
  true
}

/* *****************************************************************/

val PEXT_ZUNPKD832 : (regidx, regidx) -> bool effect {escape,rreg,wreg}
function PEXT_ZUNPKD832 (rs1, rd) = {
  let result : xlenbits =
    if sizeof(xlen) == 32
    then extz16(rB(rs1, 3)) @ extz16(rB(rs1, 2))
    else extz16(rB(rs1, 7)) @ extz16(rB(rs1, 6)) @ extz16(rB(rs1, 3)) @ extz16(rB(rs1, 2));
  X(rd) = result;
  true
}