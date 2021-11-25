/* Programming Langauge Lab, Department of Computer Science, National Tsing-Hua University, Taiwan */
/* Academia Sinica, Taiwan*/
/* Andes Technology Corporation*/

/* *****************************************************************/
/* This file specifies the instruction added by the 'P' extension. */
/* *****************************************************************/

/* *****************************************************************/
/* ********************* auxiliary functions ***********************/
/* *****************************************************************/

val kmada : forall 'n, 'n == 16 | 'n == 32.
  (bits(2 * 'n), bits ('n), bits ('n), bits ('n), bits ('n)) -> bits (2 * 'n)
  effect {rreg,wreg}
function kmada (rd, rs11, rs21, rs10, rs20) =
  let lb : bits(66) = not_vec(EXTS(sail_ones (2 * 'n) >> 1)) in
  let ub : bits(66) = EXTS(sail_ones (2 * 'n) >> 1) in
  let res : bits(66) = EXTS(rd) + EXTS(smul(rs11, rs21)) + EXTS(smul(rs10, rs20)) in
  if res <_s lb then { pext_write_OV (0b1); slice (lb, 0, 2 * 'n) }
  else if ub <_s res then { pext_write_OV (0b1); slice (ub, 0, 2 * 'n) }
  else { slice (res, 0, 2 * 'n) }

val kmads : forall 'n, 'n == 16 | 'n == 32.
  (bits(2 * 'n), bits ('n), bits ('n), bits ('n), bits ('n)) -> bits (2 * 'n)
  effect {rreg,wreg}
function kmads (rd, rs11, rs21, rs10, rs20) =
  let lb : bits(66) = not_vec(EXTS(sail_ones (2 * 'n) >> 1)) in
  let ub : bits(66) = EXTS(sail_ones (2 * 'n) >> 1) in
  let res : bits(66) = EXTS(rd) + EXTS(smul(rs11, rs21)) - EXTS(smul(rs10, rs20)) in
  if res <_s lb then { pext_write_OV (0b1); slice (lb, 0, 2 * 'n) }
  else if ub <_s res then { pext_write_OV (0b1); slice (ub, 0, 2 * 'n) }
  else { slice (res, 0, 2 * 'n) }

val kmsda : forall 'n, 'n == 16 | 'n == 32.
  (bits(2 * 'n), bits ('n), bits ('n), bits ('n), bits ('n)) -> bits (2 * 'n)
  effect {rreg,wreg}
function kmsda (rd, rs11, rs21, rs10, rs20) =
  let lb : bits(66) = not_vec(EXTS(sail_ones (2 * 'n) >> 1)) in
  let ub : bits(66) = EXTS(sail_ones (2 * 'n) >> 1) in
  let res : bits(66) = EXTS(rd) - EXTS(smul(rs11, rs21)) - EXTS(smul(rs10, rs20)) in
  if res <_s lb then { pext_write_OV (0b1); slice (lb, 0, 2 * 'n) }
  else if ub <_s res then { pext_write_OV (0b1); slice (ub, 0, 2 * 'n) }
  else { slice (res, 0, 2 * 'n) }

val sumul : forall 'n, 'n == 8.
  (bits('n), bits('n)) -> bits(32)
function sumul (v1, v2) =
  to_bits (32, signed(v1) * signed(0b0 @ v2))

/* *****************************************************************/

val PEXT_SMBB16 : (regidx, regidx, regidx) -> bool effect {escape,rreg,wreg}
function PEXT_SMBB16(rs2, rs1, rd) = {
let result : xlenbits =
  if sizeof(xlen) == 32
  then smul (rH(rs1, 0), rH(rs2, 0))
  else smul (rH(rs1, 2), rH(rs2, 2)) @ smul (rH(rs1, 0), rH(rs2, 0));
  X(rd) = result;
  true
}

/* *****************************************************************/

val PEXT_SMBT16 : (regidx, regidx, regidx) -> bool effect {escape,rreg,wreg}
function PEXT_SMBT16(rs2, rs1, rd) = {
let result : xlenbits =
  if sizeof(xlen) == 32
  then smul (rH(rs1, 0), rH(rs2, 1))
  else smul (rH(rs1, 2), rH(rs2, 3)) @ smul (rH(rs1, 0), rH(rs2, 1));
  X(rd) = result;
  true
}

/* *****************************************************************/

val PEXT_SMTT16 : (regidx, regidx, regidx) -> bool effect {escape,rreg,wreg}
function PEXT_SMTT16(rs2, rs1, rd) = {
let result : xlenbits =
  if sizeof(xlen) == 32
  then smul (rH(rs1, 1), rH(rs2, 1))
  else smul (rH(rs1, 3), rH(rs2, 3)) @ smul (rH(rs1, 1), rH(rs2, 1));
  X(rd) = result;
  true
}

/* *****************************************************************/

val PEXT_SMDS : (regidx, regidx, regidx) -> bool effect {escape,rreg,wreg}
function PEXT_SMDS(rs2, rs1, rd) = {
let result : xlenbits =
  if sizeof(xlen) == 32
  then smul (rH(rs1, 1), rH(rs2, 1)) - smul (rH(rs1, 0), rH(rs2, 0))
  else smul (rH(rs1, 3), rH(rs2, 3)) - smul (rH(rs1, 2), rH(rs2, 2)) @
       smul (rH(rs1, 1), rH(rs2, 1)) - smul (rH(rs1, 0), rH(rs2, 0));
  X(rd) = result;
  true
}

/* *****************************************************************/

val PEXT_SMDRS : (regidx, regidx, regidx) -> bool effect {escape,rreg,wreg}
function PEXT_SMDRS(rs2, rs1, rd) = {
let result : xlenbits =
  if sizeof(xlen) == 32
  then smul (rH(rs1, 0), rH(rs2, 0)) - smul (rH(rs1, 1), rH(rs2, 1))
  else smul (rH(rs1, 2), rH(rs2, 2)) - smul (rH(rs1, 3), rH(rs2, 3)) @
       smul (rH(rs1, 0), rH(rs2, 0)) - smul (rH(rs1, 1), rH(rs2, 1));
  X(rd) = result;
  true
}

/* *****************************************************************/

val PEXT_SMXDS : (regidx, regidx, regidx) -> bool effect {escape,rreg,wreg}
function PEXT_SMXDS(rs2, rs1, rd) = {
let result : xlenbits =
  if sizeof(xlen) == 32
  then smul (rH(rs1, 1), rH(rs2, 0)) - smul (rH(rs1, 0), rH(rs2, 1))
  else smul (rH(rs1, 3), rH(rs2, 2)) - smul (rH(rs1, 2), rH(rs2, 3)) @
       smul (rH(rs1, 1), rH(rs2, 0)) - smul (rH(rs1, 0), rH(rs2, 1));
  X(rd) = result;
  true
}

/* *****************************************************************/

val PEXT_KMABB : (regidx, regidx, regidx) -> bool effect {escape,rreg,wreg}
function PEXT_KMABB(rs2, rs1, rd) = {
let result : xlenbits =
  if sizeof(xlen) == 32
  then kadd (smul (rH(rs1, 0), rH(rs2, 0)), rW(rd, 0))
  else kadd (smul (rH(rs1, 2), rH(rs2, 2)), rW(rd, 1)) @
       kadd (smul (rH(rs1, 0), rH(rs2, 0)), rW(rd, 0));
  X(rd) = result;
  true
}

/* *****************************************************************/

val PEXT_KMABT : (regidx, regidx, regidx) -> bool effect {escape,rreg,wreg}
function PEXT_KMABT(rs2, rs1, rd) = {
let result : xlenbits =
  if sizeof(xlen) == 32
  then kadd (smul (rH(rs1, 0), rH(rs2, 1)), rW(rd, 0))
  else kadd (smul (rH(rs1, 2), rH(rs2, 3)), rW(rd, 1)) @
       kadd (smul (rH(rs1, 0), rH(rs2, 1)), rW(rd, 0));
  X(rd) = result;
  true
}

/* *****************************************************************/

val PEXT_KMATT : (regidx, regidx, regidx) -> bool effect {escape,rreg,wreg}
function PEXT_KMATT(rs2, rs1, rd) = {
let result : xlenbits =
  if sizeof(xlen) == 32
  then kadd (smul (rH(rs1, 1), rH(rs2, 1)), rW(rd, 0))
  else kadd (smul (rH(rs1, 3), rH(rs2, 3)), rW(rd, 1)) @
       kadd (smul (rH(rs1, 1), rH(rs2, 1)), rW(rd, 0));
  X(rd) = result;
  true
}

/* *****************************************************************/

val PEXT_KMADA : (regidx, regidx, regidx) -> bool effect {escape,rreg,wreg}
function PEXT_KMADA(rs2, rs1, rd) = {
let result : xlenbits =
  if sizeof(xlen) == 32
  then kmada(rW(rd, 0), rH(rs1, 1), rH(rs2, 1), rH(rs1, 0), rH(rs2, 0))
  else kmada(rW(rd, 1), rH(rs1, 3), rH(rs2, 3), rH(rs1, 2), rH(rs2, 2)) @
       kmada(rW(rd, 0), rH(rs1, 1), rH(rs2, 1), rH(rs1, 0), rH(rs2, 0));
  X(rd) = result;
  true
}

/* *****************************************************************/

val PEXT_KMAXDA : (regidx, regidx, regidx) -> bool effect {escape,rreg,wreg}
function PEXT_KMAXDA(rs2, rs1, rd) = {
let result : xlenbits =
  if sizeof(xlen) == 32
  then kmada(rW(rd, 0), rH(rs1, 1), rH(rs2, 0), rH(rs1, 0), rH(rs2, 1))
  else kmada(rW(rd, 1), rH(rs1, 3), rH(rs2, 2), rH(rs1, 2), rH(rs2, 3)) @
       kmada(rW(rd, 0), rH(rs1, 1), rH(rs2, 0), rH(rs1, 0), rH(rs2, 1));
  X(rd) = result;
  true
}

/* *****************************************************************/

val PEXT_KMADS : (regidx, regidx, regidx) -> bool effect {escape,rreg,wreg}
function PEXT_KMADS(rs2, rs1, rd) = {
let result : xlenbits =
  if sizeof(xlen) == 32
  then kmads(rW(rd, 0), rH(rs1, 1), rH(rs2, 1), rH(rs1, 0), rH(rs2, 0))
  else kmads(rW(rd, 1), rH(rs1, 3), rH(rs2, 3), rH(rs1, 2), rH(rs2, 2)) @
       kmads(rW(rd, 0), rH(rs1, 1), rH(rs2, 1), rH(rs1, 0), rH(rs2, 0));
  X(rd) = result;
  true
}

/* *****************************************************************/

val PEXT_KMADRS : (regidx, regidx, regidx) -> bool effect {escape,rreg,wreg}
function PEXT_KMADRS(rs2, rs1, rd) = {
let result : xlenbits =
  if sizeof(xlen) == 32
  then kmads(rW(rd, 0), rH(rs1, 0), rH(rs2, 0), rH(rs1, 1), rH(rs2, 1))
  else kmads(rW(rd, 1), rH(rs1, 2), rH(rs2, 2), rH(rs1, 3), rH(rs2, 3)) @
       kmads(rW(rd, 0), rH(rs1, 0), rH(rs2, 0), rH(rs1, 1), rH(rs2, 1));
  X(rd) = result;
  true
}

/* *****************************************************************/

val PEXT_KMAXDS : (regidx, regidx, regidx) -> bool effect {escape,rreg,wreg}
function PEXT_KMAXDS(rs2, rs1, rd) = {
let result : xlenbits =
  if sizeof(xlen) == 32
  then kmads(rW(rd, 0), rH(rs1, 1), rH(rs2, 0), rH(rs1, 0), rH(rs2, 1))
  else kmads(rW(rd, 1), rH(rs1, 3), rH(rs2, 2), rH(rs1, 2), rH(rs2, 3)) @
       kmads(rW(rd, 0), rH(rs1, 1), rH(rs2, 0), rH(rs1, 0), rH(rs2, 1));
  X(rd) = result;
  true
}

/* *****************************************************************/

val PEXT_KMSDA : (regidx, regidx, regidx) -> bool effect {escape,rreg,wreg}
function PEXT_KMSDA(rs2, rs1, rd) = {
let result : xlenbits =
  if sizeof(xlen) == 32
  then kmsda(rW(rd, 0), rH(rs1, 1), rH(rs2, 1), rH(rs1, 0), rH(rs2, 0))
  else kmsda(rW(rd, 1), rH(rs1, 3), rH(rs2, 3), rH(rs1, 2), rH(rs2, 2)) @
       kmsda(rW(rd, 0), rH(rs1, 1), rH(rs2, 1), rH(rs1, 0), rH(rs2, 0));
  X(rd) = result;
  true
}

/* *****************************************************************/

val PEXT_KMSXDA : (regidx, regidx, regidx) -> bool effect {escape,rreg,wreg}
function PEXT_KMSXDA(rs2, rs1, rd) = {
let result : xlenbits =
  if sizeof(xlen) == 32
  then kmsda(rW(rd, 0), rH(rs1, 1), rH(rs2, 0), rH(rs1, 0), rH(rs2, 1))
  else kmsda(rW(rd, 1), rH(rs1, 3), rH(rs2, 2), rH(rs1, 2), rH(rs2, 3)) @
       kmsda(rW(rd, 0), rH(rs1, 1), rH(rs2, 0), rH(rs1, 0), rH(rs2, 1));
  X(rd) = result;
  true
}

/* *****************************************************************/

val PEXT_SMAL : (regidx, regidx, regidx) -> bool effect {escape,rreg,wreg}
function PEXT_SMAL(rs2, rs1, rd) = {
  let rs10 = (rs1 >> 1) << 1 in
  let rs11 = rs10 + 1 in
  let rd0 = (rd >> 1) << 1 in
  let rd1 = rd0 + 1 in
  if sizeof(xlen) == 32
  then {
    let result : bits(64) = (X(rs11) @ X(rs10)) + EXTS(smul(rH(rs2, 1), rH(rs2, 0)));
    X(rd1) = result[63..32];
    X(rd0) = result[31..0];
  } else
    X(rd)  = rD(rs1) + EXTS(smul(rH(rs2, 3), rH(rs2, 2))) + EXTS(smul(rH(rs2, 1), rH(rs2, 0)));
  true
}

/* *****************************************************************/

val PEXT_SMALBB : (regidx, regidx, regidx) -> bool effect {escape,rreg,wreg}
function PEXT_SMALBB(rs2, rs1, rd) = {
  let rd0 = (rd >> 1) << 1 in
  let rd1 = rd0 + 1 in
  if sizeof(xlen) == 32
  then {
    let result : bits(64) = (X(rd1) @ X(rd0)) + EXTS(smul(rH(rs1, 0), rH(rs2, 0)));
    X(rd1) = result[63..32];
    X(rd0) = result[31..0];
  } else
    X(rd)  = rD(rd) + EXTS(smul(rH(rs1, 0), rH(rs2, 0))) + EXTS(smul(rH(rs1, 2), rH(rs2, 2)));
  true
}

/* *****************************************************************/

val PEXT_SMALBT : (regidx, regidx, regidx) -> bool effect {escape,rreg,wreg}
function PEXT_SMALBT(rs2, rs1, rd) = {
  let rd0 = (rd >> 1) << 1 in
  let rd1 = rd0 + 1 in
  if sizeof(xlen) == 32
  then {
    let result : bits(64) = (X(rd1) @ X(rd0)) + EXTS(smul(rH(rs1, 0), rH(rs2, 1)));
    X(rd1) = result[63..32];
    X(rd0) = result[31..0];
  } else
    X(rd)  = rD(rd) + EXTS(smul(rH(rs1, 0), rH(rs2, 1))) + EXTS(smul(rH(rs1, 2), rH(rs2, 3)));
  true
}

/* *****************************************************************/

val PEXT_SMALTT : (regidx, regidx, regidx) -> bool effect {escape,rreg,wreg}
function PEXT_SMALTT(rs2, rs1, rd) = {
  let rd0 = (rd >> 1) << 1 in
  let rd1 = rd0 + 1 in
  if sizeof(xlen) == 32
  then {
    let result : bits(64) = (X(rd1) @ X(rd0)) + EXTS(smul(rH(rs1, 1), rH(rs2, 1)));
    X(rd1) = result[63..32];
    X(rd0) = result[31..0];
  } else
    X(rd)  = rD(rd) + EXTS(smul(rH(rs1, 1), rH(rs2, 1))) + EXTS(smul(rH(rs1, 3), rH(rs2, 3)));
  true
}

/* *****************************************************************/

val PEXT_SMALDA : (regidx, regidx, regidx) -> bool effect {escape,rreg,wreg}
function PEXT_SMALDA(rs2, rs1, rd) = {
  let rd0 = (rd >> 1) << 1 in
  let rd1 = rd0 + 1 in
  if sizeof(xlen) == 32
  then {
    let result : bits(64) = (X(rd1) @ X(rd0)) + EXTS(smul(rH(rs1, 0), rH(rs2, 0))) + EXTS(smul(rH(rs1, 1), rH(rs2, 1)));
    X(rd1) = result[63..32];
    X(rd0) = result[31..0];
  } else
    X(rd)  = rD(rd) + EXTS(smul(rH(rs1, 0), rH(rs2, 0))) + EXTS(smul(rH(rs1, 1), rH(rs2, 1))) + EXTS(smul(rH(rs1, 2), rH(rs2, 2))) + EXTS(smul(rH(rs1, 3), rH(rs2, 3)));
  true
}

/* *****************************************************************/

val PEXT_SMALXDA : (regidx, regidx, regidx) -> bool effect {escape,rreg,wreg}
function PEXT_SMALXDA(rs2, rs1, rd) = {
  let rd0 = (rd >> 1) << 1 in
  let rd1 = rd0 + 1 in
  if sizeof(xlen) == 32
  then {
    let result : bits(64) = (X(rd1) @ X(rd0)) + EXTS(smul(rH(rs1, 0), rH(rs2, 1))) + EXTS(smul(rH(rs1, 1), rH(rs2, 0)));
    X(rd1) = result[63..32];
    X(rd0) = result[31..0];
  } else
    X(rd)  = rD(rd) + EXTS(smul(rH(rs1, 0), rH(rs2, 1))) + EXTS(smul(rH(rs1, 1), rH(rs2, 0))) + EXTS(smul(rH(rs1, 2), rH(rs2, 3))) + EXTS(smul(rH(rs1, 3), rH(rs2, 2)));
  true
}

/* *****************************************************************/

val PEXT_SMALDS : (regidx, regidx, regidx) -> bool effect {escape,rreg,wreg}
function PEXT_SMALDS(rs2, rs1, rd) = {
  let rd0 = (rd >> 1) << 1 in
  let rd1 = rd0 + 1 in
  if sizeof(xlen) == 32
  then {
    let result : bits(64) = (X(rd1) @ X(rd0)) + EXTS(smul(rH(rs1, 1), rH(rs2, 1)) - smul(rH(rs1, 0), rH(rs2, 0)));
    X(rd1) = result[63..32];
    X(rd0) = result[31..0];
  } else
    X(rd)  = rD(rd) + EXTS(smul(rH(rs1, 1), rH(rs2, 1)) - smul(rH(rs1, 0), rH(rs2, 0))) + EXTS(smul(rH(rs1, 3), rH(rs2, 3)) - smul(rH(rs1, 2), rH(rs2, 2)));
  true
}

/* *****************************************************************/

val PEXT_SMALDRS : (regidx, regidx, regidx) -> bool effect {escape,rreg,wreg}
function PEXT_SMALDRS(rs2, rs1, rd) = {
  let rd0 = (rd >> 1) << 1 in
  let rd1 = rd0 + 1 in
  if sizeof(xlen) == 32
  then {
    let result : bits(64) = (X(rd1) @ X(rd0)) + EXTS(smul(rH(rs1, 0), rH(rs2, 0)) - smul(rH(rs1, 1), rH(rs2, 1)));
    X(rd1) = result[63..32];
    X(rd0) = result[31..0];
  } else
    X(rd)  = rD(rd) + EXTS(smul(rH(rs1, 0), rH(rs2, 0)) - smul(rH(rs1, 1), rH(rs2, 1))) + EXTS(smul(rH(rs1, 2), rH(rs2, 2)) - smul(rH(rs1, 3), rH(rs2, 3)));
  true
}

/* *****************************************************************/

val PEXT_SMALXDS : (regidx, regidx, regidx) -> bool effect {escape,rreg,wreg}
function PEXT_SMALXDS(rs2, rs1, rd) = {
  let rd0 = (rd >> 1) << 1 in
  let rd1 = rd0 + 1 in
  if sizeof(xlen) == 32
  then {
    let result : bits(64) = (X(rd1) @ X(rd0)) + EXTS(smul(rH(rs1, 1), rH(rs2, 0)) - smul(rH(rs1, 0), rH(rs2, 1)));
    X(rd1) = result[63..32];
    X(rd0) = result[31..0];
  } else
    X(rd)  = rD(rd) + EXTS(smul(rH(rs1, 1), rH(rs2, 0)) - smul(rH(rs1, 0), rH(rs2, 1))) + EXTS(smul(rH(rs1, 3), rH(rs2, 2)) - smul(rH(rs1, 2), rH(rs2, 3)));
  true
}

/* *****************************************************************/

val PEXT_SMSLDA : (regidx, regidx, regidx) -> bool effect {escape,rreg,wreg}
function PEXT_SMSLDA(rs2, rs1, rd) = {
  let rd0 = (rd >> 1) << 1 in
  let rd1 = rd0 + 1 in
  if sizeof(xlen) == 32
  then {
    let result : bits(64) = (X(rd1) @ X(rd0)) - EXTS(smul(rH(rs1, 0), rH(rs2, 0))) - EXTS(smul(rH(rs1, 1), rH(rs2, 1)));
    X(rd1) = result[63..32];
    X(rd0) = result[31..0];
  } else
    X(rd)  = rD(rd) - EXTS(smul(rH(rs1, 0), rH(rs2, 0))) - EXTS(smul(rH(rs1, 1), rH(rs2, 1))) - EXTS(smul(rH(rs1, 2), rH(rs2, 2))) - EXTS(smul(rH(rs1, 3), rH(rs2, 3)));
  true
}

/* *****************************************************************/

val PEXT_SMSLXDA : (regidx, regidx, regidx) -> bool effect {escape,rreg,wreg}
function PEXT_SMSLXDA(rs2, rs1, rd) = {
  let rd0 = (rd >> 1) << 1 in
  let rd1 = rd0 + 1 in
  if sizeof(xlen) == 32
  then {
    let result : bits(64) = (X(rd1) @ X(rd0)) - EXTS(smul(rH(rs1, 0), rH(rs2, 1))) - EXTS(smul(rH(rs1, 1), rH(rs2, 0)));
    X(rd1) = result[63..32];
    X(rd0) = result[31..0];
  } else
    X(rd)  = rD(rd) - EXTS(smul(rH(rs1, 0), rH(rs2, 1))) - EXTS(smul(rH(rs1, 1), rH(rs2, 0))) - EXTS(smul(rH(rs1, 2), rH(rs2, 3))) - EXTS(smul(rH(rs1, 3), rH(rs2, 2)));
  true
}

/* *****************************************************************/

val PEXT_SMAQA : (regidx, regidx, regidx) -> bool effect {escape,rreg,wreg}
function PEXT_SMAQA(rs2, rs1, rd) = {
let result : xlenbits =
  if sizeof(xlen) == 32
  then rW(rd, 0) + EXTS(smul (rB(rs1, 3), rB(rs2, 3))) + EXTS(smul (rB(rs1, 2), rB(rs2, 2))) +
                   EXTS(smul (rB(rs1, 1), rB(rs2, 1))) + EXTS(smul (rB(rs1, 0), rB(rs2, 0)))
  else rW(rd, 1) + EXTS(smul (rB(rs1, 7), rB(rs2, 7))) + EXTS(smul (rB(rs1, 6), rB(rs2, 6))) +
                   EXTS(smul (rB(rs1, 5), rB(rs2, 5))) + EXTS(smul (rB(rs1, 4), rB(rs2, 4))) @
       rW(rd, 0) + EXTS(smul (rB(rs1, 3), rB(rs2, 3))) + EXTS(smul (rB(rs1, 2), rB(rs2, 2))) +
                   EXTS(smul (rB(rs1, 1), rB(rs2, 1))) + EXTS(smul (rB(rs1, 0), rB(rs2, 0)));
  X(rd) = result;
  true
}

/* *****************************************************************/

val PEXT_UMAQA : (regidx, regidx, regidx) -> bool effect {escape,rreg,wreg}
function PEXT_UMAQA(rs2, rs1, rd) = {
let result : xlenbits =
  if sizeof(xlen) == 32
  then rW(rd, 0) + EXTZ(umul (rB(rs1, 3), rB(rs2, 3))) + EXTZ(umul (rB(rs1, 2), rB(rs2, 2))) +
                   EXTZ(umul (rB(rs1, 1), rB(rs2, 1))) + EXTZ(umul (rB(rs1, 0), rB(rs2, 0)))
  else rW(rd, 1) + EXTZ(umul (rB(rs1, 7), rB(rs2, 7))) + EXTZ(umul (rB(rs1, 6), rB(rs2, 6))) +
                   EXTZ(umul (rB(rs1, 5), rB(rs2, 5))) + EXTZ(umul (rB(rs1, 4), rB(rs2, 4))) @
       rW(rd, 0) + EXTZ(umul (rB(rs1, 3), rB(rs2, 3))) + EXTZ(umul (rB(rs1, 2), rB(rs2, 2))) +
                   EXTZ(umul (rB(rs1, 1), rB(rs2, 1))) + EXTZ(umul (rB(rs1, 0), rB(rs2, 0)));
  X(rd) = result;
  true
}

/* *****************************************************************/

val PEXT_SMAQA_SU : (regidx, regidx, regidx) -> bool effect {escape,rreg,wreg}
function PEXT_SMAQA_SU(rs2, rs1, rd) = {
let result : xlenbits =
  if sizeof(xlen) == 32
  then rW(rd, 0) + EXTS(sumul (rB(rs1, 3), rB(rs2, 3))) + EXTS(sumul (rB(rs1, 2), rB(rs2, 2))) +
                   EXTS(sumul (rB(rs1, 1), rB(rs2, 1))) + EXTS(sumul (rB(rs1, 0), rB(rs2, 0)))
  else rW(rd, 1) + EXTS(sumul (rB(rs1, 7), rB(rs2, 7))) + EXTS(sumul (rB(rs1, 6), rB(rs2, 6))) +
                   EXTS(sumul (rB(rs1, 5), rB(rs2, 5))) + EXTS(sumul (rB(rs1, 4), rB(rs2, 4))) @
       rW(rd, 0) + EXTS(sumul (rB(rs1, 3), rB(rs2, 3))) + EXTS(sumul (rB(rs1, 2), rB(rs2, 2))) +
                   EXTS(sumul (rB(rs1, 1), rB(rs2, 1))) + EXTS(sumul (rB(rs1, 0), rB(rs2, 0)));
  X(rd) = result;
  true
}

/* *****************************************************************/
