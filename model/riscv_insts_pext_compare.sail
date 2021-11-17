/* *****************************************************************/
/* This file specifies the instruction added by the 'P' extension. */
/* *****************************************************************/

/* *****************************************************************/
/* ********************* auxiliary functions ***********************/
/* *****************************************************************/

val cmpeq16 : 
  (bits(16), bits(16)) -> bits(16)
function cmpeq16 (v1, v2) =
  if v1 == v2
  then 0xFFFF
  else 0x0000

val scmplt16 :
  (bits(16), bits(16)) -> bits(16)
function scmplt16 (v1, v2) =
  if signed(v1) < signed(v2)
  then 0xFFFF
  else 0x0000

val scmple16 :
  (bits(16), bits(16)) -> bits(16)
function scmple16 (v1, v2) =
  if signed(v1) <= signed(v2)
  then 0xFFFF
  else 0x0000

val ucmplt16 :
  (bits(16), bits(16)) -> bits(16)
function ucmplt16 (v1, v2) =
  if unsigned(v1) < unsigned(v2)
  then 0xFFFF
  else 0x0000

val ucmple16 :
  (bits(16), bits(16)) -> bits(16)
function ucmple16 (v1, v2) =
  if unsigned(v1) <= unsigned(v2)
  then 0xFFFF
  else 0x0000

val cmpeq8 : 
  (bits(8), bits(8)) -> bits(8)
function cmpeq8 (v1, v2) =
  if v1 == v2
  then 0xFF
  else 0x00

val scmplt8 :
  (bits(8), bits(8)) -> bits(8)
function scmplt8 (v1, v2) =
  if signed(v1) < signed(v2)
  then 0xFF
  else 0x00

val scmple8 :
  (bits(8), bits(8)) -> bits(8)
function scmple8 (v1, v2) =
  if signed(v1) <= signed(v2)
  then 0xFF
  else 0x00

val ucmplt8 :
  (bits(8), bits(8)) -> bits(8)
function ucmplt8 (v1, v2) =
  if unsigned(v1) < unsigned(v2)
  then 0xFF
  else 0x00

val ucmple8 :
  (bits(8), bits(8)) -> bits(8)
function ucmple8 (v1, v2) =
  if unsigned(v1) <= unsigned(v2)
  then 0xFF
  else 0x00


/******************************************************************/
val PEXT_CMPEQ16 : (regidx, regidx, regidx) -> bool effect {escape,rreg,wreg}
function PEXT_CMPEQ16(rs2, rs1, rd) =
{
  let result : xlenbits =
    if sizeof(xlen) == 32
    then  cmpeq16(rH(rs1, 1), rH(rs2, 1)) @ cmpeq16(rH(rs1, 0), rH(rs2, 0))
    else  cmpeq16(rH(rs1, 3), rH(rs2, 3)) @ cmpeq16(rH(rs1, 2), rH(rs2, 2)) @ cmpeq16(rH(rs1, 1), rH(rs2, 1)) @ cmpeq16(rH(rs1, 0), rH(rs2, 0));
  X(rd) = result;
 true
}

val PEXT_SCMPLT16 : (regidx, regidx, regidx) -> bool effect {escape,rreg,wreg}
function PEXT_SCMPLT16(rs2, rs1, rd) =
{
  let result : xlenbits =
    if sizeof(xlen) == 32
    then  scmplt16(rH(rs1, 1), rH(rs2, 1)) @ scmplt16(rH(rs1, 0), rH(rs2, 0))
    else  scmplt16(rH(rs1, 3), rH(rs2, 3)) @ scmplt16(rH(rs1, 2), rH(rs2, 2)) @ scmplt16(rH(rs1, 1), rH(rs2, 1)) @ scmplt16(rH(rs1, 0), rH(rs2, 0));
  X(rd) = result;
 true
}

val PEXT_SCMPLE16 : (regidx, regidx, regidx) -> bool effect {escape,rreg,wreg}
function PEXT_SCMPLE16(rs2, rs1, rd) =
{
  let result : xlenbits =
    if sizeof(xlen) == 32
    then  scmple16(rH(rs1, 1), rH(rs2, 1)) @ scmple16(rH(rs1, 0), rH(rs2, 0))
    else  scmple16(rH(rs1, 3), rH(rs2, 3)) @ scmple16(rH(rs1, 2), rH(rs2, 2)) @ scmple16(rH(rs1, 1), rH(rs2, 1)) @ scmple16(rH(rs1, 0), rH(rs2, 0));
  X(rd) = result;
 true
}

val PEXT_UCMPLT16 : (regidx, regidx, regidx) -> bool effect {escape,rreg,wreg}
function PEXT_UCMPLT16(rs2, rs1, rd) =
{
  let result : xlenbits =
    if sizeof(xlen) == 32
    then  ucmplt16(rH(rs1, 1), rH(rs2, 1)) @ ucmplt16(rH(rs1, 0), rH(rs2, 0))
    else  ucmplt16(rH(rs1, 3), rH(rs2, 3)) @ ucmplt16(rH(rs1, 2), rH(rs2, 2)) @ ucmplt16(rH(rs1, 1), rH(rs2, 1)) @ ucmplt16(rH(rs1, 0), rH(rs2, 0));
  X(rd) = result;
 true
}

val PEXT_UCMPLE16 : (regidx, regidx, regidx) -> bool effect {escape,rreg,wreg}
function PEXT_UCMPLE16(rs2, rs1, rd) =
{
  let result : xlenbits =
    if sizeof(xlen) == 32
    then  ucmple16(rH(rs1, 1), rH(rs2, 1)) @ ucmple16(rH(rs1, 0), rH(rs2, 0))
    else  ucmple16(rH(rs1, 3), rH(rs2, 3)) @ ucmple16(rH(rs1, 2), rH(rs2, 2)) @ ucmple16(rH(rs1, 1), rH(rs2, 1)) @ ucmple16(rH(rs1, 0), rH(rs2, 0));
  X(rd) = result;
 true
}

val PEXT_CMPEQ8 : (regidx, regidx, regidx) -> bool effect {escape,rreg,wreg}
function PEXT_CMPEQ8(rs2, rs1, rd) =
{
  let result : xlenbits =
    if sizeof(xlen) == 32
    then  cmpeq8(rB(rs1, 3), rB(rs2, 3)) @ cmpeq8(rB(rs1, 2), rB(rs2, 2)) @ cmpeq8(rB(rs1, 1), rB(rs2, 1)) @ cmpeq8(rB(rs1, 0), rB(rs2, 0))
    else  cmpeq8(rB(rs1, 7), rB(rs2, 7)) @ cmpeq8(rB(rs1, 6), rB(rs2, 6)) @ cmpeq8(rB(rs1, 5), rB(rs2, 5)) @ cmpeq8(rB(rs1, 4), rB(rs2, 4)) @ cmpeq8(rB(rs1, 3), rB(rs2, 3)) @ cmpeq8(rB(rs1, 2), rB(rs2, 2)) @ cmpeq8(rB(rs1, 1), rB(rs2, 1)) @ cmpeq8(rB(rs1, 0), rB(rs2, 0));
  X(rd) = result;
 true
}

val PEXT_SCMPLT8 : (regidx, regidx, regidx) -> bool effect {escape,rreg,wreg}
function PEXT_SCMPLT8(rs2, rs1, rd) =
{
  let result : xlenbits =
    if sizeof(xlen) == 32
    then  scmplt8(rB(rs1, 3), rB(rs2, 3)) @ scmplt8(rB(rs1, 2), rB(rs2, 2)) @ scmplt8(rB(rs1, 1), rB(rs2, 1)) @ scmplt8(rB(rs1, 0), rB(rs2, 0))
    else  scmplt8(rB(rs1, 7), rB(rs2, 7)) @ scmplt8(rB(rs1, 6), rB(rs2, 6)) @ scmplt8(rB(rs1, 5), rB(rs2, 5)) @ scmplt8(rB(rs1, 4), rB(rs2, 4)) @ scmplt8(rB(rs1, 3), rB(rs2, 3)) @ scmplt8(rB(rs1, 2), rB(rs2, 2)) @ scmplt8(rB(rs1, 1), rB(rs2, 1)) @ scmplt8(rB(rs1, 0), rB(rs2, 0));
  X(rd) = result;
 true
}

val PEXT_SCMPLE8 : (regidx, regidx, regidx) -> bool effect {escape,rreg,wreg}
function PEXT_SCMPLE8(rs2, rs1, rd) =
{
  let result : xlenbits =
    if sizeof(xlen) == 32
    then  scmple8(rB(rs1, 3), rB(rs2, 3)) @ scmple8(rB(rs1, 2), rB(rs2, 2)) @ scmple8(rB(rs1, 1), rB(rs2, 1)) @ scmple8(rB(rs1, 0), rB(rs2, 0))
    else  scmple8(rB(rs1, 7), rB(rs2, 7)) @ scmple8(rB(rs1, 6), rB(rs2, 6)) @ scmple8(rB(rs1, 5), rB(rs2, 5)) @ scmple8(rB(rs1, 4), rB(rs2, 4)) @ scmple8(rB(rs1, 3), rB(rs2, 3)) @ scmple8(rB(rs1, 2), rB(rs2, 2)) @ scmple8(rB(rs1, 1), rB(rs2, 1)) @ scmple8(rB(rs1, 0), rB(rs2, 0));
  X(rd) = result;
 true
}

val PEXT_UCMPLT8 : (regidx, regidx, regidx) -> bool effect {escape,rreg,wreg}
function PEXT_UCMPLT8(rs2, rs1, rd) =
{
  let result : xlenbits =
    if sizeof(xlen) == 32
    then  ucmplt8(rB(rs1, 3), rB(rs2, 3)) @ ucmplt8(rB(rs1, 2), rB(rs2, 2)) @ ucmplt8(rB(rs1, 1), rB(rs2, 1)) @ ucmplt8(rB(rs1, 0), rB(rs2, 0))
    else  ucmplt8(rB(rs1, 7), rB(rs2, 7)) @ ucmplt8(rB(rs1, 6), rB(rs2, 6)) @ ucmplt8(rB(rs1, 5), rB(rs2, 5)) @ ucmplt8(rB(rs1, 4), rB(rs2, 4)) @ ucmplt8(rB(rs1, 3), rB(rs2, 3)) @ ucmplt8(rB(rs1, 2), rB(rs2, 2)) @ ucmplt8(rB(rs1, 1), rB(rs2, 1)) @ ucmplt8(rB(rs1, 0), rB(rs2, 0));
  X(rd) = result;
 true
}

val PEXT_UCMPLE8 : (regidx, regidx, regidx) -> bool effect {escape,rreg,wreg}
function PEXT_UCMPLE8(rs2, rs1, rd) =
{
  let result : xlenbits =
    if sizeof(xlen) == 32
    then  ucmple8(rB(rs1, 3), rB(rs2, 3)) @ ucmple8(rB(rs1, 2), rB(rs2, 2)) @ ucmple8(rB(rs1, 1), rB(rs2, 1)) @ ucmple8(rB(rs1, 0), rB(rs2, 0))
    else  ucmple8(rB(rs1, 7), rB(rs2, 7)) @ ucmple8(rB(rs1, 6), rB(rs2, 6)) @ ucmple8(rB(rs1, 5), rB(rs2, 5)) @ ucmple8(rB(rs1, 4), rB(rs2, 4)) @ ucmple8(rB(rs1, 3), rB(rs2, 3)) @ ucmple8(rB(rs1, 2), rB(rs2, 2)) @ ucmple8(rB(rs1, 1), rB(rs2, 1)) @ ucmple8(rB(rs1, 0), rB(rs2, 0));
  X(rd) = result;
 true
}
