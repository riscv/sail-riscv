/* Programming Langauge Lab, Department of Computer Science, National Tsing-Hua University, Taiwan */
/* Academia Sinica, Taiwan*/
/* Andes Technology Corporation, Taiwan*/

/* *****************************************************************/
/* This file specifies the instruction added by the 'P' extension. */
/* *****************************************************************/

/* *****************************************************************/
/* ********************* auxiliary functions ***********************/
/* *****************************************************************/

/* *****************************************************************/

val msbsmul :
  (bits(32), bits(32)) -> bits(32)
function msbsmul (v1, v2) =
  to_bits (64, signed(v1) * signed(v2))[63..32]

val msbsmul_u :
  (bits(32), bits(32)) -> bits(32)
function msbsmul_u (v1, v2) =
  add_bits(to_bits (64, signed(v1) * signed(v2))[63..31] , 0x00000000 @ 0b1)[32..1]

val kmsbmac :
  (bits (32), bits (32), bits (32)) -> bits (32) effect {rreg,wreg}
function kmsbmac (v1, v2, rd) =
  let ub : bits(33) = EXTS(sail_ones (32) >> 1) in
  let lb : bits(33) = not_vec (ub) in
  let res : bits(33) = add_bits(EXTS(msbsmul(v1, v2)), EXTS(rd)) in
  if res <_s lb then { pext_write_OV (0b1); not_vec (ones (32) >> 1) }
  else if ub <_s res then { pext_write_OV (0b1); ones (32) >> 1 }
  else { slice (res, 0, 32) }

val kmsbmac_u :
  (bits (32), bits (32), bits (32)) -> bits (32) effect {rreg,wreg}
function kmsbmac_u (v1, v2, rd) =
  let ub : bits(33) = EXTS(sail_ones (32) >> 1) in
  let lb : bits(33) = not_vec (ub) in
  let res : bits(33) = add_bits(EXTS(msbsmul_u(v1, v2)), EXTS(rd)) in
  if res <_s lb then { pext_write_OV (0b1); not_vec (ones (32) >> 1) }
  else if ub <_s res then { pext_write_OV (0b1); ones (32) >> 1 }
  else { slice (res, 0, 32) }

val kmsbsb :
  (bits (32), bits (32), bits (32)) -> bits (32) effect {rreg,wreg}
function kmsbsb (v1, v2, rd) =
  let ub : bits(33) = EXTS(sail_ones (32) >> 1) in
  let lb : bits(33) = not_vec (ub) in
  let res : bits(33) = sub_bits(EXTS(rd), EXTS(msbsmul(v1, v2))) in
  if res <_s lb then { pext_write_OV (0b1); not_vec (ones (32) >> 1) }
  else if ub <_s res then { pext_write_OV (0b1); ones (32) >> 1 }
  else { slice (res, 0, 32) }

val kmsbsb_u :
  (bits (32), bits (32), bits (32)) -> bits (32) effect {rreg,wreg}
function kmsbsb_u (v1, v2, rd) =
  let ub : bits(33) = EXTS(sail_ones (32) >> 1) in
  let lb : bits(33) = not_vec (ub) in
  let res : bits(33) = sub_bits(EXTS(rd), EXTS(msbsmul_u(v1, v2))) in
  if res <_s lb then { pext_write_OV (0b1); not_vec (ones (32) >> 1) }
  else if ub <_s res then { pext_write_OV (0b1); ones (32) >> 1 }
  else { slice (res, 0, 32) }

val kwmsbmul :
  (bits (32), bits (32)) -> bits (32) effect {rreg,wreg}
function kwmsbmul (v1, v2) =
  if (v1 != 0x80000000) | (v2 != 0x80000000)
  then smul(v1, v2)[62..31]
  else { pext_write_OV (0b1); 0x7FFFFFFF }

val kwmsbmul_u :
  (bits (32), bits (32)) -> bits (32) effect {rreg,wreg}
function kwmsbmul_u (v1, v2) =
  if (v1 != 0x80000000) | (v2 != 0x80000000)
  then
  let mres : bits(64) = smul(v1, v2) in
  let round33 : bits(34) = add_bits(mres[63..30], EXTZ(0x1)) in
  round33[32..1]
  else { pext_write_OV (0b1); 0x7FFFFFFF }

val smmw :
  (bits(32), bits(16)) -> bits(32)
function smmw (v1, v2) =
  to_bits (48, signed(v1) * signed(v2))[47..16]

val smmw_u :
  (bits(32), bits(16)) -> bits(32)
function smmw_u (v1, v2) =
  add_bits(to_bits (48, signed(v1) * signed(v2))[47..15] , EXTZ(0x1))[32..1]

val kmmaw :
  (bits(32), bits(16), bits(32)) -> bits(32) effect {rreg,wreg}
function kmmaw (v1, v2, rd) =
  let mres : bits(48) = to_bits(48, signed(v1) * signed(v2)) in
  let res : bits(33) = add_bits(EXTS(rd), EXTS(mres[47..16])) in
  let ub : bits(33) = EXTS(sail_ones (32) >> 1) in
  let lb : bits(33) = not_vec (ub) in
  if res <_s lb then { pext_write_OV (0b1); not_vec (ones (32) >> 1) }
  else if ub <_s res then { pext_write_OV (0b1); ones (32) >> 1 }
  else { slice (res, 0, 32) }

val kmmaw_u :
  (bits(32), bits(16), bits(32)) -> bits(32) effect {rreg,wreg}
function kmmaw_u (v1, v2, rd) =
  let mres : bits(48) = to_bits(48, signed(v1) * signed(v2)) in
  let round33 : bits(33) = add_bits(mres[47..15], EXTS(0x1)) in
  let res : bits(33) = add_bits(EXTS(rd), EXTS(round33[32..1])) in
  let ub : bits(33) = EXTS(sail_ones (32) >> 1) in
  let lb : bits(33) = not_vec (ub) in
  if res <_s lb then { pext_write_OV (0b1); not_vec (ones (32) >> 1) }
  else if ub <_s res then { pext_write_OV (0b1); ones (32) >> 1 }
  else { slice (res, 0, 32) }

val kmmaw2 :
  (bits(32), bits(16), bits(32)) -> bits(32) effect {rreg,wreg}
function kmmaw2 (v1, v2, rd) =
  let addop : bits(32) =
  if (v1 != 0x80000000) | (v2 != 0x8000)
  then to_bits(48, signed(v1) * signed(v2))[46..15]
  else {pext_write_OV (0b1); 0x7FFFFFFF} in
  let res : bits(33) = add_bits(EXTS(rd), EXTS(addop)) in
  let ub : bits(33) = EXTS(sail_ones (32) >> 1) in
  let lb : bits(33) = not_vec (ub) in
  if res <_s lb then { pext_write_OV (0b1); not_vec (ones (32) >> 1) }
  else if ub <_s res then { pext_write_OV (0b1); ones (32) >> 1 }
  else { slice (res, 0, 32) }

val kmmaw2_u :
  (bits(32), bits(16), bits(32)) -> bits(32) effect {rreg,wreg}
function kmmaw2_u (v1, v2, rd) =
  let round34 : bits(34) = add_bits(to_bits(48, signed(v1) * signed(v2))[47..14], EXTS(0x1)) in
  let addop : bits(32) =
  if (v1 != 0x80000000) | (v2 != 0x8000)
  then round34[32..1]
  else {pext_write_OV (0b1); 0x7FFFFFFF} in
  let res : bits(33) = add_bits(EXTS(rd), EXTS(addop)) in
  let ub : bits(33) = EXTS(sail_ones (32) >> 1) in
  let lb : bits(33) = not_vec (ub) in
  if res <_s lb then { pext_write_OV (0b1); not_vec (ones (32) >> 1) }
  else if ub <_s res then { pext_write_OV (0b1); ones (32) >> 1 }
  else { slice (res, 0, 32) }

val kmmw2 :
  (bits(32), bits(16)) -> bits(32) effect {rreg,wreg}
function kmmw2 (v1, v2) =
  if (v1 == 0x80000000) & (v2 == 0x8000)
  then { pext_write_OV (0b1); 0x7FFFFFFF }
  else to_bits(48, signed(v1) * signed(v2))[46..15]

val kmmw2_u :
  (bits(32), bits(16)) -> bits(32) effect {rreg,wreg}
function kmmw2_u (v1, v2) =
  if (v1 == 0x80000000) & (v2 == 0x8000)
  then { pext_write_OV (0b1); 0x7FFFFFFF }
  else
  let round : bits(33) = add_bits( to_bits(48, signed(v1) * signed(v2))[46..14], EXTS(0x1)) in
  round[32..1]

/* *****************************************************************/

val PEXT_SMMUL: (regidx, regidx, regidx) -> bool effect {escape,rreg,wreg}
function PEXT_SMMUL (rs2, rs1, rd) = {
  let result : xlenbits =
    if sizeof(xlen) == 32
    then  msbsmul(X(rs1), X(rs2))
    else  msbsmul(rW(rs1, 1), rW(rs2, 1)) @ msbsmul(rW(rs1, 0), rW(rs2, 0));
  X(rd) = result;
  true
}

/* *****************************************************************/

val PEXT_SMMUL_U : (regidx, regidx, regidx) -> bool effect {escape,rreg,wreg}
function PEXT_SMMUL_U (rs2, rs1, rd) = {
  let result : xlenbits =
    if sizeof(xlen) == 32
    then  msbsmul_u(X(rs1), X(rs2))
    else  msbsmul_u(rW(rs1, 1), rW(rs2, 1)) @ msbsmul_u(rW(rs1, 0), rW(rs2, 0));
  X(rd) = result;
  true
}

/* *****************************************************************/

val PEXT_KMMAC : (regidx, regidx, regidx) -> bool effect {escape,rreg,wreg}
function PEXT_KMMAC (rs2, rs1, rd) = {
  let result : xlenbits =
    if sizeof(xlen) == 32
    then  kmsbmac(X(rs1), X(rs2), X(rd))
    else  kmsbmac(rW(rs1, 1), rW(rs2, 1), rW(rd, 1)) @ kmsbmac(rW(rs1, 0), rW(rs2, 0), rW(rd, 0));
  X(rd) = result;
  true
}

/* *****************************************************************/

val PEXT_KMMAC_U : (regidx, regidx, regidx) -> bool effect {escape,rreg,wreg}
function PEXT_KMMAC_U (rs2, rs1, rd) = {
  let result : xlenbits =
    if sizeof(xlen) == 32
    then  kmsbmac_u(X(rs1), X(rs2), X(rd))
    else  kmsbmac_u(rW(rs1, 1), rW(rs2, 1), rW(rd, 1)) @ kmsbmac_u(rW(rs1, 0), rW(rs2, 0), rW(rd, 0));
  X(rd) = result;
  true
}

/* *****************************************************************/

val PEXT_KMMSB : (regidx, regidx, regidx) -> bool effect {escape,rreg,wreg}
function PEXT_KMMSB (rs2, rs1, rd) = {
  let result : xlenbits =
    if sizeof(xlen) == 32
    then  kmsbsb(X(rs1), X(rs2), X(rd))
    else  kmsbsb(rW(rs1, 1), rW(rs2, 1), rW(rd, 1)) @ kmsbsb(rW(rs1, 0), rW(rs2, 0), rW(rd, 0));
  X(rd) = result;
  true
}

/* *****************************************************************/

val PEXT_KMMSB_U : (regidx, regidx, regidx) -> bool effect {escape,rreg,wreg}
function PEXT_KMMSB_U (rs2, rs1, rd) = {
  let result : xlenbits =
    if sizeof(xlen) == 32
    then  kmsbsb_u(X(rs1), X(rs2), X(rd))
    else  kmsbsb_u(rW(rs1, 1), rW(rs2, 1), rW(rd, 1)) @ kmsbsb_u(rW(rs1, 0), rW(rs2, 0), rW(rd, 0));
  X(rd) = result;
  true
}

/* *****************************************************************/

val PEXT_KWMMUL : (regidx, regidx, regidx) -> bool effect {escape,rreg,wreg}
function clause PEXT_KWMMUL (rs2, rs1, rd) = {
  let result : xlenbits =
    if sizeof(xlen) == 32
    then  kwmsbmul(X(rs1), X(rs2))
    else  kwmsbmul(rW(rs1, 1), rW(rs2, 1)) @ kwmsbmul(rW(rs1, 0), rW(rs2, 0));
  X(rd) = result;
  true
}

/* *****************************************************************/

val PEXT_KWMMUL_U : (regidx, regidx, regidx) -> bool effect {escape,rreg,wreg}
function PEXT_KWMMUL_U (rs2, rs1, rd) = {
  let result : xlenbits =
    if sizeof(xlen) == 32
    then  kwmsbmul_u(X(rs1), X(rs2))
    else  kwmsbmul_u(rW(rs1, 1), rW(rs2, 1)) @ kwmsbmul_u(rW(rs1, 0), rW(rs2, 0));
  X(rd) = result;
  true
}

/* *****************************************************************/

val PEXT_SMMWB : (regidx, regidx, regidx) -> bool effect {escape,rreg,wreg}
function PEXT_SMMWB (rs2, rs1, rd) = {
  let result : xlenbits =
    if sizeof(xlen) == 32
    then  smmw(X(rs1), rH(rs2, 0))
    else  smmw(rW(rs1, 1), rH(rs2, 2)) @ smmw(rW(rs1, 0), rH(rs2, 0));
  X(rd) = result;
  true
}

/* *****************************************************************/

val PEXT_SMMWB_U : (regidx, regidx, regidx) -> bool effect {escape,rreg,wreg}
function PEXT_SMMWB_U (rs2, rs1, rd) = {
  let result : xlenbits =
    if sizeof(xlen) == 32
    then  smmw_u(X(rs1), rH(rs2, 0))
    else  smmw_u(rW(rs1, 1), rH(rs2, 2)) @ smmw_u(rW(rs1, 0), rH(rs2, 0));
  X(rd) = result;
  true
}

/* *****************************************************************/

val PEXT_SMMWT : (regidx, regidx, regidx) -> bool effect {escape,rreg,wreg}
function clause PEXT_SMMWT (rs2, rs1, rd) = {
  let result : xlenbits =
    if sizeof(xlen) == 32
    then  smmw(X(rs1), rH(rs2, 1))
    else  smmw(rW(rs1, 1), rH(rs2, 3)) @ smmw(rW(rs1, 0), rH(rs2, 1));
  X(rd) = result;
  true
}

/* *****************************************************************/

val PEXT_SMMWT_U : (regidx, regidx, regidx) -> bool effect {escape,rreg,wreg}
function clause PEXT_SMMWT_U (rs2, rs1, rd) = {
  let result : xlenbits =
    if sizeof(xlen) == 32
    then  smmw_u(X(rs1), rH(rs2, 1))
    else  smmw_u(rW(rs1, 1), rH(rs2, 3)) @ smmw_u(rW(rs1, 0), rH(rs2, 1));
  X(rd) = result;
  true
}

/* *****************************************************************/

val PEXT_KMMAWB : (regidx, regidx, regidx) -> bool effect {escape,rreg,wreg}
function PEXT_KMMAWB (rs2, rs1, rd) = {
  let result : xlenbits =
    if sizeof(xlen) == 32
    then  kmmaw(X(rs1), rH(rs2, 0), X(rd))
    else  kmmaw(rW(rs1, 1), rH(rs2, 2), rW(rd, 1)) @ kmmaw(rW(rs1, 0), rH(rs2, 0), rW(rd, 0));
  X(rd) = result;
  true
}

/* *****************************************************************/

val PEXT_KMMAWB_U : (regidx, regidx, regidx) -> bool effect {escape,rreg,wreg}
function PEXT_KMMAWB_U (rs2, rs1, rd) = {
  let result : xlenbits =
    if sizeof(xlen) == 32
    then  kmmaw_u(X(rs1), rH(rs2, 0), X(rd))
    else  kmmaw_u(rW(rs1, 1), rH(rs2, 2), rW(rd, 1)) @ kmmaw_u(rW(rs1, 0), rH(rs2, 0), rW(rd, 0));
  X(rd) = result;
  true
}

/* *****************************************************************/

val PEXT_KMMAWT : (regidx, regidx, regidx) -> bool effect {escape,rreg,wreg}
function PEXT_KMMAWT (rs2, rs1, rd) = {
  let result : xlenbits =
    if sizeof(xlen) == 32
    then  kmmaw(X(rs1), rH(rs2, 1), X(rd))
    else  kmmaw(rW(rs1, 1), rH(rs2, 3), rW(rd, 1)) @ kmmaw(rW(rs1, 0), rH(rs2, 1), rW(rd, 0));
  X(rd) = result;
  true
}

/* *****************************************************************/

val PEXT_KMMAWT_U : (regidx, regidx, regidx) -> bool effect {escape,rreg,wreg}
function PEXT_KMMAWT_U (rs2, rs1, rd) = {
  let result : xlenbits =
    if sizeof(xlen) == 32
    then  kmmaw_u(X(rs1), rH(rs2, 1), X(rd))
    else  kmmaw_u(rW(rs1, 1), rH(rs2, 3), rW(rd, 1)) @ kmmaw_u(rW(rs1, 0), rH(rs2, 1), rW(rd, 0));
  X(rd) = result;
  true
}

/* *****************************************************************/

val PEXT_KMMAWB2 : (regidx, regidx, regidx) -> bool effect {escape,rreg,wreg}
function PEXT_KMMAWB2 (rs2, rs1, rd) = {
  let result : xlenbits =
    if sizeof(xlen) == 32
    then  kmmaw2(X(rs1), rH(rs2, 0), X(rd))
    else  kmmaw2(rW(rs1, 1), rH(rs2, 2), rW(rd, 1)) @ kmmaw2(rW(rs1, 0), rH(rs2, 0), rW(rd, 0));
  X(rd) = result;
  true
}

/* *****************************************************************/

val PEXT_KMMAWB2_U : (regidx, regidx, regidx) -> bool effect {escape,rreg,wreg}
function PEXT_KMMAWB2_U (rs2, rs1, rd) = {
  let result : xlenbits =
    if sizeof(xlen) == 32
    then  kmmaw2_u(X(rs1), rH(rs2, 0), X(rd))
    else  kmmaw2_u(rW(rs1, 1), rH(rs2, 2), rW(rd, 1)) @ kmmaw2_u(rW(rs1, 0), rH(rs2, 0), rW(rd, 0));
  X(rd) = result;
  true
}

/* *****************************************************************/

val PEXT_KMMAWT2 : (regidx, regidx, regidx) -> bool effect {escape,rreg,wreg}
function PEXT_KMMAWT2 (rs2, rs1, rd) = {
  let result : xlenbits =
    if sizeof(xlen) == 32
    then  kmmaw2(X(rs1), rH(rs2, 1), X(rd))
    else  kmmaw2(rW(rs1, 1), rH(rs2, 3), rW(rd, 1)) @ kmmaw2(rW(rs1, 0), rH(rs2, 1), rW(rd, 0));
  X(rd) = result;
  true
}

/* *****************************************************************/

val PEXT_KMMAWT2_U : (regidx, regidx, regidx) -> bool effect {escape,rreg,wreg}
function PEXT_KMMAWT2_U (rs2, rs1, rd) = {
  let result : xlenbits =
    if sizeof(xlen) == 32
    then  kmmaw2_u(X(rs1), rH(rs2, 1), X(rd))
    else  kmmaw2_u(rW(rs1, 1), rH(rs2, 3), rW(rd, 1)) @ kmmaw2_u(rW(rs1, 0), rH(rs2, 1), rW(rd, 0));
  X(rd) = result;
  true
}

/* *****************************************************************/

val PEXT_KMMWB2 : (regidx, regidx, regidx) -> bool effect {escape,rreg,wreg}
function PEXT_KMMWB2 (rs2, rs1, rd) = {
  let result : xlenbits =
    if sizeof(xlen) == 32
    then  kmmw2(X(rs1), rH(rs2, 0))
    else  kmmw2(rW(rs1, 1), rH(rs2, 2)) @ kmmw2(rW(rs1, 0), rH(rs2, 0));
  X(rd) = result;
  true
}

/* *****************************************************************/

val PEXT_KMMWB2_U : (regidx, regidx, regidx) -> bool effect {escape,rreg,wreg}
function PEXT_KMMWB2_U (rs2, rs1, rd) = {
  let result : xlenbits =
    if sizeof(xlen) == 32
    then  kmmw2_u(X(rs1), rH(rs2, 0))
    else  kmmw2_u(rW(rs1, 1), rH(rs2, 2)) @ kmmw2_u(rW(rs1, 0), rH(rs2, 0));
  X(rd) = result;
  true
}

/* *****************************************************************/

val PEXT_KMMWT2 : (regidx, regidx, regidx) -> bool effect {escape,rreg,wreg}
function PEXT_KMMWT2 (rs2, rs1, rd) = {
  let result : xlenbits =
    if sizeof(xlen) == 32
    then  kmmw2(X(rs1), rH(rs2, 1))
    else  kmmw2(rW(rs1, 1), rH(rs2, 3)) @ kmmw2(rW(rs1, 0), rH(rs2, 1));
  X(rd) = result;
  true
}

/* *****************************************************************/

val PEXT_KMMWT2_U : (regidx, regidx, regidx) -> bool effect {escape,rreg,wreg}
function PEXT_KMMWT2_U (rs2, rs1, rd) = {
  let result : xlenbits =
    if sizeof(xlen) == 32
    then  kmmw2_u(X(rs1), rH(rs2, 1))
    else  kmmw2_u(rW(rs1, 1), rH(rs2, 3)) @ kmmw2_u(rW(rs1, 0), rH(rs2, 1));
  X(rd) = result;
  true
}
