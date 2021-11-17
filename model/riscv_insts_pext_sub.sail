/* *****************************************************************/
/* This file specifies the instruction subed by the 'P' extension. */
/* *****************************************************************/

/* *****************************************************************/
/* ********************* auxiliary functions ***********************/
/* *****************************************************************/

val rsub : forall 'n, 'n == 8 | 'n == 16 | 'n == 32 | 'n == 64.
  (bits('n), bits('n)) -> bits('n)
function rsub (v1, v2) =
  let v1ext : bits(xlen+32) = EXTS(v1) in
  let v2ext : bits(xlen+32) = EXTS(v2) in
  slice ((v1ext - v2ext) >> 1, 0, 'n)

val ursub : forall 'n, 'n == 8 | 'n == 16 | 'n == 32 | 'n == 64.
  (bits('n), bits('n)) -> bits('n)
function ursub (v1, v2) =
  let v1ext : bits(xlen+32) = EXTZ(v1) in
  let v2ext : bits(xlen+32) = EXTZ(v2) in
  slice ((v1ext - v2ext) >> 1, 0, 'n)

val ksub : forall 'n, 'n == 8 | 'n == 16 | 'n == 32 | 'n == 64.
  (bits('n), bits('n)) -> bits('n) effect {rreg,wreg}
function ksub (v1, v2) =
  let ub : bits(xlen+32) = EXTS(sail_ones ('n) >> 1) in
  let lb : bits(xlen+32) = not_vec (ub) in
  let v1ext : bits(xlen+32) = EXTS(v1) in
  let v2ext : bits(xlen+32) = EXTS(v2) in
  let diffext = v1ext - v2ext in
  if diffext <_s lb then { pext_write_OV (0b1); not_vec (ones ('n) >> 1) }
  else if ub <_s diffext then { pext_write_OV (0b1); ones ('n) >> 1 }
  else { slice (diffext, 0, 'n) }

val uksub : forall 'n, 'n == 8 | 'n == 16 | 'n == 32 | 'n == 64.
  (bits('n), bits('n)) -> bits('n) effect {rreg,wreg}
function uksub (v1, v2) =
  let ub : bits(xlen+32) = EXTZ(sail_ones ('n)) in
  let v1ext : bits(xlen+32) = EXTZ(v1) in
  let v2ext : bits(xlen+32) = EXTZ(v2) in
  let diffext = v1ext - v2ext in
  if ub <_u diffext then { pext_write_OV (0b1); zeros('n) }
  else { slice (diffext, 0, 'n) }

/* *****************************************************************/

val PEXT_KSUB8 : (regidx, regidx, regidx) -> bool
  effect {escape, rreg, wreg}
function PEXT_KSUB8 (rs2, rs1, rd) = {
  let result : xlenbits =
    if sizeof(xlen) == 32
    then ksub (rB(rs1, 3), rB(rs2, 3)) @ ksub (rB(rs1, 2), rB(rs2, 2)) @
         ksub (rB(rs1, 1), rB(rs2, 1)) @ ksub (rB(rs1, 0), rB(rs2, 0))
    else ksub (rB(rs1, 7), rB(rs2, 7)) @ ksub (rB(rs1, 6), rB(rs2, 6)) @
         ksub (rB(rs1, 5), rB(rs2, 5)) @ ksub (rB(rs1, 4), rB(rs2, 4)) @
         ksub (rB(rs1, 3), rB(rs2, 3)) @ ksub (rB(rs1, 2), rB(rs2, 2)) @
         ksub (rB(rs1, 1), rB(rs2, 1)) @ ksub (rB(rs1, 0), rB(rs2, 0));
  X (rd) = result;
  true
}

val PEXT_KSUB16 : (regidx, regidx, regidx) -> bool
  effect {escape, rreg, wreg}
function PEXT_KSUB16 (rs2, rs1, rd) = {
  let result : xlenbits =
    if sizeof(xlen) == 32
    then ksub (rH(rs1, 1), rH(rs2, 1)) @ ksub (rH(rs1, 0), rH(rs2, 0))
    else ksub (rH(rs1, 3), rH(rs2, 3)) @ ksub (rH(rs1, 2), rH(rs2, 2)) @
         ksub (rH(rs1, 1), rH(rs2, 1)) @ ksub (rH(rs1, 0), rH(rs2, 0));
  X (rd) = result;
  true
}

val PEXT_KSUB32 : (regidx, regidx, regidx) -> bool
  effect {escape, rreg, wreg}
function PEXT_KSUB32 (rs2, rs1, rd) = {
  if ~ (haveZpsfoperand ()) | sizeof (xlen) == 32 then {
    false
  } else {
    let result : xlenbits =
      ksub (rW(rs1, 1), rW(rs2, 1)) @ ksub (rW(rs1, 0), rW(rs2, 0));
    X(rd) = result;
    true
  }
}

val PEXT_KSUB64 : (regidx, regidx, regidx) -> bool
  effect {escape, rreg, wreg}
function PEXT_KSUB64 (rs2, rs1, rd) = {
  let result : bits(64) = ksub (rD (rs1), rD (rs2));
  set_rD (rd, result);
  true
}

/* *****************************************************************/

val PEXT_RSUB8 : (regidx, regidx, regidx) -> bool
  effect {escape, rreg, wreg}
function PEXT_RSUB8 (rs2, rs1, rd) = {
  let result : xlenbits =
    if sizeof(xlen) == 32
    then rsub (rB(rs1, 3), rB(rs2, 3)) @ rsub (rB(rs1, 2), rB(rs2, 2)) @
         rsub (rB(rs1, 1), rB(rs2, 1)) @ rsub (rB(rs1, 0), rB(rs2, 0))
    else rsub (rB(rs1, 7), rB(rs2, 7)) @ rsub (rB(rs1, 6), rB(rs2, 6)) @
         rsub (rB(rs1, 5), rB(rs2, 5)) @ rsub (rB(rs1, 4), rB(rs2, 4)) @
         rsub (rB(rs1, 3), rB(rs2, 3)) @ rsub (rB(rs1, 2), rB(rs2, 2)) @
         rsub (rB(rs1, 1), rB(rs2, 1)) @ rsub (rB(rs1, 0), rB(rs2, 0));
  X (rd) = result;
  true
}

val PEXT_RSUB16 : (regidx, regidx, regidx) -> bool
  effect {escape, rreg, wreg}
function PEXT_RSUB16 (rs2, rs1, rd) = {
  let result : xlenbits =
    if sizeof(xlen) == 32
    then rsub (rH(rs1, 1), rH(rs2, 1)) @ rsub (rH(rs1, 0), rH(rs2, 0))
    else rsub (rH(rs1, 3), rH(rs2, 3)) @ rsub (rH(rs1, 2), rH(rs2, 2)) @
         rsub (rH(rs1, 1), rH(rs2, 1)) @ rsub (rH(rs1, 0), rH(rs2, 0));
  X (rd) = result;
  true
}

val PEXT_RSUB32 : (regidx, regidx, regidx) -> bool
  effect {escape, rreg, wreg}
function PEXT_RSUB32 (rs2, rs1, rd) = {
  if ~ (haveZpsfoperand ()) | sizeof (xlen) == 32 then {
    false
  } else {
    let result : xlenbits =
      rsub (rW(rs1, 1), rW(rs2, 1)) @ rsub (rW(rs1, 0), rW(rs2, 0));
    X(rd) = result;
    true
  }
}

val PEXT_RSUB64 : (regidx, regidx, regidx) -> bool
  effect {escape, rreg, wreg}
function PEXT_RSUB64 (rs2, rs1, rd) = {
  let result : bits(64) = rsub (rD (rs1), rD (rs2));
  set_rD (rd, result);
  true
}

/* *****************************************************************/

val PEXT_SUB8 : (regidx, regidx, regidx) -> bool
  effect {escape, rreg, wreg}
function PEXT_SUB8 (rs2, rs1, rd) = {
  let result : xlenbits =
    if sizeof(xlen) == 32
    then (rB(rs1, 3) - rB(rs2, 3)) @ (rB(rs1, 2) - rB(rs2, 2)) @
         (rB(rs1, 1) - rB(rs2, 1)) @ (rB(rs1, 0) - rB(rs2, 0))
    else (rB(rs1, 7) - rB(rs2, 7)) @ (rB(rs1, 6) - rB(rs2, 6)) @
         (rB(rs1, 5) - rB(rs2, 5)) @ (rB(rs1, 4) - rB(rs2, 4)) @
         (rB(rs1, 3) - rB(rs2, 3)) @ (rB(rs1, 2) - rB(rs2, 2)) @
         (rB(rs1, 1) - rB(rs2, 1)) @ (rB(rs1, 0) - rB(rs2, 0));
  X (rd) = result;
  true
}

val PEXT_SUB16 : (regidx, regidx, regidx) -> bool
  effect {escape, rreg, wreg}
function PEXT_SUB16 (rs2, rs1, rd) = {
  let result : xlenbits =
    if sizeof(xlen) == 32
    then (rH(rs1, 1) - rH(rs2, 1)) @ (rH(rs1, 0) - rH(rs2, 0))
    else (rH(rs1, 3) - rH(rs2, 3)) @ (rH(rs1, 2) - rH(rs2, 2)) @
         (rH(rs1, 1) - rH(rs2, 1)) @ (rH(rs1, 0) - rH(rs2, 0));
  X (rd) = result;
  true
}

val PEXT_SUB32 : (regidx, regidx, regidx) -> bool
  effect {escape, rreg, wreg}
function PEXT_SUB32 (rs2, rs1, rd) = {
  if ~ (haveZpsfoperand ()) | sizeof (xlen) == 32 then {
    false
  } else {
    let result : xlenbits =
      (rW(rs1, 1) - rW(rs2, 1)) @ (rW(rs1, 0) - rW(rs2, 0));
    X(rd) = result;
    true
  }
}

val PEXT_SUB64 : (regidx, regidx, regidx) -> bool
  effect {escape, rreg, wreg}
function PEXT_SUB64 (rs2, rs1, rd) = {
  let result : bits(64) = rD (rs1) - rD (rs2);
  set_rD (rd, result);
  true
}

/* *****************************************************************/

val PEXT_UKSUB8 : (regidx, regidx, regidx) -> bool
  effect {escape, rreg, wreg}
function PEXT_UKSUB8 (rs2, rs1, rd) = {
  let result : xlenbits =
    if sizeof(xlen) == 32
    then uksub (rB(rs1, 3), rB(rs2, 3)) @ uksub (rB(rs1, 2), rB(rs2, 2)) @
         uksub (rB(rs1, 1), rB(rs2, 1)) @ uksub (rB(rs1, 0), rB(rs2, 0))
    else uksub (rB(rs1, 7), rB(rs2, 7)) @ uksub (rB(rs1, 6), rB(rs2, 6)) @
         uksub (rB(rs1, 5), rB(rs2, 5)) @ uksub (rB(rs1, 4), rB(rs2, 4)) @
         uksub (rB(rs1, 3), rB(rs2, 3)) @ uksub (rB(rs1, 2), rB(rs2, 2)) @
         uksub (rB(rs1, 1), rB(rs2, 1)) @ uksub (rB(rs1, 0), rB(rs2, 0));
  X (rd) = result;
  true
}

val PEXT_UKSUB16 : (regidx, regidx, regidx) -> bool
  effect {escape, rreg, wreg}
function PEXT_UKSUB16 (rs2, rs1, rd) = {
  let result : xlenbits =
    if sizeof(xlen) == 32
    then uksub (rH(rs1, 1), rH(rs2, 1)) @ uksub (rH(rs1, 0), rH(rs2, 0))
    else uksub (rH(rs1, 3), rH(rs2, 3)) @ uksub (rH(rs1, 2), rH(rs2, 2)) @
         uksub (rH(rs1, 1), rH(rs2, 1)) @ uksub (rH(rs1, 0), rH(rs2, 0));
  X (rd) = result;
  true
}

val PEXT_UKSUB32 : (regidx, regidx, regidx) -> bool
  effect {escape, rreg, wreg}
function PEXT_UKSUB32 (rs2, rs1, rd) = {
  if ~ (haveZpsfoperand ()) | sizeof (xlen) == 32 then {
    false
  } else {
    let result : xlenbits =
      uksub (rW(rs1, 1), rW(rs2, 1)) @ uksub (rW(rs1, 0), rW(rs2, 0));
    X(rd) = result;
    true
  }
}

val PEXT_UKSUB64 : (regidx, regidx, regidx) -> bool
  effect {escape, rreg, wreg}
function PEXT_UKSUB64 (rs2, rs1, rd) = {
  let result : bits(64) = uksub (rD (rs1), rD (rs2));
  set_rD (rd, result);
  true
}

/* *****************************************************************/

val PEXT_URSUB8 : (regidx, regidx, regidx) -> bool
  effect {escape, rreg, wreg}
function PEXT_URSUB8 (rs2, rs1, rd) = {
  let result : xlenbits =
    if sizeof(xlen) == 32
    then ursub (rB(rs1, 3), rB(rs2, 3)) @ ursub (rB(rs1, 2), rB(rs2, 2)) @
         ursub (rB(rs1, 1), rB(rs2, 1)) @ ursub (rB(rs1, 0), rB(rs2, 0))
    else ursub (rB(rs1, 7), rB(rs2, 7)) @ ursub (rB(rs1, 6), rB(rs2, 6)) @
         ursub (rB(rs1, 5), rB(rs2, 5)) @ ursub (rB(rs1, 4), rB(rs2, 4)) @
         ursub (rB(rs1, 3), rB(rs2, 3)) @ ursub (rB(rs1, 2), rB(rs2, 2)) @
         ursub (rB(rs1, 1), rB(rs2, 1)) @ ursub (rB(rs1, 0), rB(rs2, 0));
  X (rd) = result;
  true
}

val PEXT_URSUB16 : (regidx, regidx, regidx) -> bool
  effect {escape, rreg, wreg}
function PEXT_URSUB16 (rs2, rs1, rd) = {
  let result : xlenbits =
    if sizeof(xlen) == 32
    then ursub (rH(rs1, 1), rH(rs2, 1)) @ ursub (rH(rs1, 0), rH(rs2, 0))
    else ursub (rH(rs1, 3), rH(rs2, 3)) @ ursub (rH(rs1, 2), rH(rs2, 2)) @
         ursub (rH(rs1, 1), rH(rs2, 1)) @ ursub (rH(rs1, 0), rH(rs2, 0));
  X (rd) = result;
  true
}

val PEXT_URSUB32 : (regidx, regidx, regidx) -> bool
  effect {escape, rreg, wreg}
function PEXT_URSUB32 (rs2, rs1, rd) = {
  if ~ (haveZpsfoperand ()) | sizeof (xlen) == 32 then {
    false
  } else {
    let result : xlenbits =
      ursub (rW(rs1, 1), rW(rs2, 1)) @ ursub (rW(rs1, 0), rW(rs2, 0));
    X(rd) = result;
    true
  }
}

val PEXT_URSUB64 : (regidx, regidx, regidx) -> bool
  effect {escape, rreg, wreg}
function PEXT_URSUB64 (rs2, rs1, rd) = {
  let result : bits(64) = ursub (rD (rs1), rD (rs2));
  set_rD (rd, result);
  true
}
