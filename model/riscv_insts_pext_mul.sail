/* Programming Langauge Lab, Department of Computer Science, National Tsing-Hua University, Taiwan */
/* Academia Sinica, Taiwan*/
/* Andes Technology Corporation, Taiwan*/

/* *****************************************************************/
/* This file specifies the instruction added by the 'P' extension. */
/* *****************************************************************/

/* *****************************************************************/
/* ********************* auxiliary functions ***********************/
/* *****************************************************************/

val smul : forall 'n, 'n == 8 | 'n == 16 | 'n == 32.
  (bits('n), bits('n)) -> bits(2 * 'n)
function smul (v1, v2) =
  to_bits (2 * 'n, signed(v1) * signed(v2))

val umul : forall 'n, 'n == 8 | 'n == 16 | 'n == 32.
  (bits('n), bits('n)) -> bits(2 * 'n)
function umul (v1, v2) =
  to_bits (2 * 'n, unsigned(v1) * unsigned(v2))

val khm : forall 'n, 'n == 8 | 'n == 16.
  (bits('n), bits('n)) -> bits('n) effect {rreg,wreg}
function khm (v1, v2) =
  let lb : bits('n) = not_vec(EXTS(sail_ones ('n) >> 1)) in
  if v1 == lb & v2 == lb then { pext_write_OV (0b1); ones ('n) >> 1 }
  else { if 'n == 8 then { to_bits (2 * 'n, signed(v1) * signed(v2))[14..7] }
         else { to_bits (2 * 'n, signed(v1) * signed(v2))[30..15] } }

/* *****************************************************************/

val PEXT_SMUL8 : (regidx, regidx, regidx) -> bool effect {escape,rreg,wreg}
function PEXT_SMUL8(rs2, rs1, rd) = {
  let rd0 = (rd >> 1) << 1 in
  let rd1 = rd0 + 1 in
  if sizeof(xlen) == 32
  then {
    X(rd1) = smul (rB(rs1, 3), rB(rs2, 3)) @ smul (rB(rs1, 2), rB(rs2, 2));
    X(rd0) = smul (rB(rs1, 1), rB(rs2, 1)) @ smul (rB(rs1, 0), rB(rs2, 0)); }
  else
    X(rd)  = smul (rB(rs1, 3), rB(rs2, 3)) @ smul (rB(rs1, 2), rB(rs2, 2)) @
             smul (rB(rs1, 1), rB(rs2, 1)) @ smul (rB(rs1, 0), rB(rs2, 0));
  true
}

/* *****************************************************************/

val PEXT_SMULX8 : (regidx, regidx, regidx) -> bool effect {escape,rreg,wreg}
function PEXT_SMULX8(rs2, rs1, rd) = {
  let rd0 = (rd >> 1) << 1 in
  let rd1 = rd0 + 1 in
  if sizeof(xlen) == 32
  then {
    X(rd1) = smul (rB(rs1, 3), rB(rs2, 2)) @ smul (rB(rs1, 2), rB(rs2, 3));
    X(rd0) = smul (rB(rs1, 1), rB(rs2, 0)) @ smul (rB(rs1, 0), rB(rs2, 1)); }
  else
    X(rd)  = smul (rB(rs1, 3), rB(rs2, 2)) @ smul (rB(rs1, 2), rB(rs2, 3)) @
             smul (rB(rs1, 1), rB(rs2, 0)) @ smul (rB(rs1, 0), rB(rs2, 1));
  true
}

/* *****************************************************************/

val PEXT_UMUL8 : (regidx, regidx, regidx) -> bool effect {escape,rreg,wreg}
function PEXT_UMUL8(rs2, rs1, rd) = {
  let rd0 = (rd >> 1) << 1 in
  let rd1 = rd0 + 1 in
  if sizeof(xlen) == 32
  then {
    X(rd1) = umul (rB(rs1, 3), rB(rs2, 3)) @ umul (rB(rs1, 2), rB(rs2, 2));
    X(rd0) = umul (rB(rs1, 1), rB(rs2, 1)) @ umul (rB(rs1, 0), rB(rs2, 0)); }
  else
    X(rd)  = umul (rB(rs1, 3), rB(rs2, 3)) @ umul (rB(rs1, 2), rB(rs2, 2)) @
             umul (rB(rs1, 1), rB(rs2, 1)) @ umul (rB(rs1, 0), rB(rs2, 0));
  true
}

/* *****************************************************************/

val PEXT_UMULX8 : (regidx, regidx, regidx) -> bool effect {escape,rreg,wreg}
function PEXT_UMULX8(rs2, rs1, rd) = {
  let rd0 = (rd >> 1) << 1 in
  let rd1 = rd0 + 1 in
  if sizeof(xlen) == 32
  then {
    X(rd1) = umul (rB(rs1, 3), rB(rs2, 2)) @ umul (rB(rs1, 2), rB(rs2, 3));
    X(rd0) = umul (rB(rs1, 1), rB(rs2, 0)) @ umul (rB(rs1, 0), rB(rs2, 1)); }
  else
    X(rd) = umul (rB(rs1, 3), rB(rs2, 2)) @ umul (rB(rs1, 2), rB(rs2, 3)) @
            umul (rB(rs1, 1), rB(rs2, 0)) @ umul (rB(rs1, 0), rB(rs2, 1));
  true
}

/* *****************************************************************/

val PEXT_KHM8 : (regidx, regidx, regidx) -> bool effect {escape,rreg,wreg}
function PEXT_KHM8(rs2, rs1, rd) = {
  let result : xlenbits =
    if sizeof(xlen) == 32
    then khm (rB(rs1, 3), rB(rs2, 3)) @ khm (rB(rs1, 2), rB(rs2, 2)) @
         khm (rB(rs1, 1), rB(rs2, 1)) @ khm (rB(rs1, 0), rB(rs2, 0))
    else khm (rB(rs1, 7), rB(rs2, 7)) @ khm (rB(rs1, 6), rB(rs2, 6)) @
         khm (rB(rs1, 5), rB(rs2, 5)) @ khm (rB(rs1, 4), rB(rs2, 4)) @
         khm (rB(rs1, 3), rB(rs2, 3)) @ khm (rB(rs1, 2), rB(rs2, 2)) @
         khm (rB(rs1, 1), rB(rs2, 1)) @ khm (rB(rs1, 0), rB(rs2, 0));
  X(rd) = result;
  true
}

/* *****************************************************************/

val PEXT_KHMX8 : (regidx, regidx, regidx) -> bool effect {escape,rreg,wreg}
function PEXT_KHMX8(rs2, rs1, rd) = {
  let result : xlenbits =
    if sizeof(xlen) == 32
    then khm (rB(rs1, 3), rB(rs2, 2)) @ khm (rB(rs1, 2), rB(rs2, 3)) @
         khm (rB(rs1, 1), rB(rs2, 0)) @ khm (rB(rs1, 0), rB(rs2, 1))
    else khm (rB(rs1, 7), rB(rs2, 6)) @ khm (rB(rs1, 6), rB(rs2, 7)) @
         khm (rB(rs1, 5), rB(rs2, 4)) @ khm (rB(rs1, 4), rB(rs2, 5)) @
         khm (rB(rs1, 3), rB(rs2, 2)) @ khm (rB(rs1, 2), rB(rs2, 3)) @
         khm (rB(rs1, 1), rB(rs2, 0)) @ khm (rB(rs1, 0), rB(rs2, 1));
  X(rd) = result;
  true
}

/* *****************************************************************/

val PEXT_SMUL16 : (regidx, regidx, regidx) -> bool effect {escape,rreg,wreg}
function PEXT_SMUL16(rs2, rs1, rd) = {
  let rd0 = (rd >> 1) << 1 in
  let rd1 = rd0 + 1 in
  if sizeof(xlen) == 32
  then {
    X(rd1) = smul (rH(rs1, 1), rH(rs2, 1));
    X(rd0) = smul (rH(rs1, 0), rH(rs2, 0)); }
  else
    X(rd)  = smul (rH(rs1, 1), rH(rs2, 1)) @ smul (rH(rs1, 0), rH(rs2, 0));
  true
}

/* *****************************************************************/

val PEXT_SMULX16 : (regidx, regidx, regidx) -> bool effect {escape,rreg,wreg}
function PEXT_SMULX16(rs2, rs1, rd) = {
  let rd0 = (rd >> 1) << 1 in
  let rd1 = rd0 + 1 in
  if sizeof(xlen) == 32
  then {
    X(rd1) = smul (rH(rs1, 1), rH(rs2, 0));
    X(rd0) = smul (rH(rs1, 0), rH(rs2, 1)); }
  else
    X(rd)  = smul (rH(rs1, 1), rH(rs2, 0)) @ smul (rH(rs1, 0), rH(rs2, 1));
  true
}

/* *****************************************************************/

val PEXT_UMUL16 : (regidx, regidx, regidx) -> bool effect {escape,rreg,wreg}
function PEXT_UMUL16(rs2, rs1, rd) = {
  let rd0 = (rd >> 1) << 1 in
  let rd1 = rd0 + 1 in
  if sizeof(xlen) == 32
  then {
    X(rd1) = umul (rH(rs1, 1), rH(rs2, 1));
    X(rd0) = umul (rH(rs1, 0), rH(rs2, 0)); }
  else
    X(rd)  = umul (rH(rs1, 1), rH(rs2, 1)) @ umul (rH(rs1, 0), rH(rs2, 0));
  true
}

/* *****************************************************************/

val PEXT_UMULX16 : (regidx, regidx, regidx) -> bool effect {escape,rreg,wreg}
function PEXT_UMULX16(rs2, rs1, rd) = {
  let rd0 = (rd >> 1) << 1 in
  let rd1 = rd0 + 1 in
  if sizeof(xlen) == 32
  then {
    X(rd1) = umul (rH(rs1, 1), rH(rs2, 0));
    X(rd0) = umul (rH(rs1, 0), rH(rs2, 1)); }
  else
    X(rd)  = umul (rH(rs1, 1), rH(rs2, 0)) @ umul (rH(rs1, 0), rH(rs2, 1));
  true
}

/* *****************************************************************/

val PEXT_KHM16 : (regidx, regidx, regidx) -> bool effect {escape,rreg,wreg}
function PEXT_KHM16(rs2, rs1, rd) = {
  let result : xlenbits =
    if sizeof(xlen) == 32
    then khm (rH(rs1, 1), rH(rs2, 1)) @ khm (rH(rs1, 0), rH(rs2, 0))
    else khm (rH(rs1, 3), rH(rs2, 3)) @ khm (rH(rs1, 2), rH(rs2, 2)) @
         khm (rH(rs1, 1), rH(rs2, 1)) @ khm (rH(rs1, 0), rH(rs2, 0));
  X(rd) = result;
  true
}

/* *****************************************************************/

val PEXT_KHMX16 : (regidx, regidx, regidx) -> bool effect {escape,rreg,wreg}
function PEXT_KHMX16(rs2, rs1, rd) = {
  let result : xlenbits =
    if sizeof(xlen) == 32
    then khm (rH(rs1, 1), rH(rs2, 0)) @ khm (rH(rs1, 0), rH(rs2, 1))
    else khm (rH(rs1, 3), rH(rs2, 2)) @ khm (rH(rs1, 2), rH(rs2, 3)) @
         khm (rH(rs1, 1), rH(rs2, 0)) @ khm (rH(rs1, 0), rH(rs2, 1));
  X(rd) = result;
  true
}
