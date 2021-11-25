/* Programming Langauge Lab, Department of Computer Science, National Tsing-Hua University, Taiwan */
/* Academia Sinica, Taiwan*/
/* Andes Technology Corporation*/

/* *****************************************************************/
/* This file specifies the instruction added by the 'P' extension. */
/* *****************************************************************/

/* *****************************************************************/
/* ********************* auxiliary functions ***********************/
/* *****************************************************************/

val radd : forall 'n, 'n == 8 | 'n == 16 | 'n == 32.
  (bits('n), bits('n)) -> bits('n)
function radd (v1, v2) =
  let v1ext : bits(64) = EXTS(v1) in
  let v2ext : bits(64) = EXTS(v2) in
  slice ((v1ext + v2ext) >> 1, 0, 'n)

val radd64 :
  (bits(64), bits(64)) -> bits(64)
function radd64 (v1, v2) =
  let v1ext : bits(65) = EXTS(v1) in
  let v2ext : bits(65) = EXTS(v2) in
  slice (add_bits(v1ext, v2ext) >> 1, 0, 64)  

val uradd : forall 'n, 'n == 8 | 'n == 16 | 'n == 32.
  (bits('n), bits('n)) -> bits('n)
function uradd (v1, v2) =
  let v1ext : bits(64) = EXTZ(v1) in
  let v2ext : bits(64) = EXTZ(v2) in
  slice ((v1ext + v2ext) >> 1, 0, 'n)

val uradd64 :
  (bits(64), bits(64)) -> bits(64)
function uradd64 (v1, v2) =
  let v1ext : bits(65) = EXTZ(v1) in
  let v2ext : bits(65) = EXTZ(v2) in
  slice ((v1ext + v2ext) >> 1, 0, 64)

val kadd : forall 'n, 'n == 8 | 'n == 16 | 'n == 32.
  (bits('n), bits('n)) -> bits('n) effect {rreg,wreg}
function kadd (v1, v2) =
  let ub : bits(64) = EXTS(sail_ones ('n) >> 1) in
  let lb : bits(64) = not_vec (ub) in
  let v1ext : bits(64) = EXTS(v1) in
  let v2ext : bits(64) = EXTS(v2) in
  let sumext = v1ext + v2ext in
  if sumext <_s lb then { pext_write_OV (0b1); not_vec (ones ('n) >> 1) }
  else if ub <_s sumext then { pext_write_OV (0b1); ones ('n) >> 1 }
  else { slice (sumext, 0, 'n) }

val kadd64 :
  (bits(64), bits(64)) -> bits(64) effect {rreg,wreg}
function kadd64 (v1, v2) =
  let ub : bits(65) = EXTS(sail_ones (64) >> 1) in
  let lb : bits(65) = not_vec (ub) in
  let v1ext : bits(65) = EXTS(v1) in
  let v2ext : bits(65) = EXTS(v2) in
  let sumext = v1ext + v2ext in
  if sumext <_s lb then { pext_write_OV (0b1); not_vec (ones (64) >> 1) }
  else if ub <_s sumext then { pext_write_OV (0b1); ones (64) >> 1 }
  else { slice (sumext, 0, 64) }

val ukadd : forall 'n, 'n == 8 | 'n == 16 | 'n == 32.
  (bits('n), bits('n)) -> bits('n) effect {rreg,wreg}
function ukadd (v1, v2) =
  let ub : bits(64) = EXTZ(sail_ones ('n)) in
  let v1ext : bits(64) = EXTZ(v1) in
  let v2ext : bits(64) = EXTZ(v2) in
  let sumext = v1ext + v2ext in
  if ub <_u sumext then { pext_write_OV (0b1); ones('n) }
  else { slice (sumext, 0, 'n) }

val ukadd64 :
  (bits(64), bits(64)) -> bits(64) effect {rreg,wreg}
function ukadd64 (v1, v2) =
  let ub : bits(64) = EXTZ(sail_ones (64)) in
  let v1ext : bits(64) = EXTZ(v1) in
  let v2ext : bits(64) = EXTZ(v2) in
  let sumext = v1ext + v2ext in
  if ub <_u sumext then { pext_write_OV (0b1); ones(64) }
  else { slice (sumext, 0, 64) }

/* *****************************************************************/

val PEXT_ADD8 : (regidx, regidx, regidx) -> bool effect {escape, rreg, wreg}
function PEXT_ADD8 (rs2, rs1, rd) = {
  let result : xlenbits =
      if sizeof (xlen) == 32
      then (rB(rs1, 3) + rB(rs2, 3)) @ (rB(rs1, 2) + rB(rs2, 2)) @
           (rB(rs1, 1) + rB(rs2, 1)) @ (rB(rs1, 0) + rB(rs2, 0))
      else (rB(rs1, 7) + rB(rs2, 7)) @ (rB(rs1, 6) + rB(rs2, 6)) @
           (rB(rs1, 5) + rB(rs2, 5)) @ (rB(rs1, 4) + rB(rs2, 4)) @
           (rB(rs1, 3) + rB(rs2, 3)) @ (rB(rs1, 2) + rB(rs2, 2)) @
           (rB(rs1, 1) + rB(rs2, 1)) @ (rB(rs1, 0) + rB(rs2, 0));
  X(rd) = result;
  true
}

val PEXT_ADD16 : (regidx, regidx, regidx) -> bool
  effect {escape, rreg, wreg}
function PEXT_ADD16 (rs2, rs1, rd) = {
  let result : xlenbits =
    if sizeof(xlen) == 32
    then (rH(rs1, 1) + rH(rs2, 1)) @ (rH(rs1, 0) + rH(rs2, 0))
    else (rH(rs1, 3) + rH(rs2, 3)) @ (rH(rs1, 2) + rH(rs2, 2)) @
         (rH(rs1, 1) + rH(rs2, 1)) @ (rH(rs1, 0) + rH(rs2, 0));
  X(rd) = result;
  true
}

val PEXT_ADD64 : (regidx, regidx, regidx) -> bool
  effect {escape, rreg, wreg}
function PEXT_ADD64 (rs2, rs1, rd) = {
  let result : bits(64) = rD (rs1) + rD (rs2);
  set_rD (rd, result);
  true
}

/* *****************************************************************/

val PEXT_KADD8 : (regidx, regidx, regidx) -> bool
  effect {escape, rreg, wreg}
function PEXT_KADD8 (rs2, rs1, rd) = {
  let result : xlenbits =
    if sizeof(xlen) == 32
    then kadd (rB(rs1, 3), rB(rs2, 3)) @ kadd (rB(rs1, 2), rB(rs2, 2)) @
         kadd (rB(rs1, 1), rB(rs2, 1)) @ kadd (rB(rs1, 0), rB(rs2, 0))
    else kadd (rB(rs1, 7), rB(rs2, 7)) @ kadd (rB(rs1, 6), rB(rs2, 6)) @
         kadd (rB(rs1, 5), rB(rs2, 5)) @ kadd (rB(rs1, 4), rB(rs2, 4)) @
         kadd (rB(rs1, 3), rB(rs2, 3)) @ kadd (rB(rs1, 2), rB(rs2, 2)) @
         kadd (rB(rs1, 1), rB(rs2, 1)) @ kadd (rB(rs1, 0), rB(rs2, 0));
  X (rd) = result;
  true
}

val PEXT_KADD16 : (regidx, regidx, regidx) -> bool
  effect {escape, rreg, wreg}
function PEXT_KADD16 (rs2, rs1, rd) = {
  let result : xlenbits =
    if sizeof(xlen) == 32
    then kadd (rH(rs1, 1), rH(rs2, 1)) @ kadd (rH(rs1, 0), rH(rs2, 0))
    else kadd (rH(rs1, 3), rH(rs2, 3)) @ kadd (rH(rs1, 2), rH(rs2, 2)) @
         kadd (rH(rs1, 1), rH(rs2, 1)) @ kadd (rH(rs1, 0), rH(rs2, 0));
  X (rd) = result;
  true
}

val PEXT_KADD64 : (regidx, regidx, regidx) -> bool
  effect {escape, rreg, wreg}
function PEXT_KADD64 (rs2, rs1, rd) = {
  let result : bits(64) = kadd64 (rD (rs1), rD (rs2));
  set_rD (rd, result);
  true
}

/* *****************************************************************/

val PEXT_RADD8 : (regidx, regidx, regidx) -> bool
  effect {escape, rreg, wreg}
function PEXT_RADD8 (rs2, rs1, rd) = {
  let result : xlenbits =
    if sizeof(xlen) == 32
    then radd (rB(rs1, 3), rB(rs2, 3)) @ radd (rB(rs1, 2), rB(rs2, 2)) @
         radd (rB(rs1, 1), rB(rs2, 1)) @ radd (rB(rs1, 0), rB(rs2, 0))
    else radd (rB(rs1, 7), rB(rs2, 7)) @ radd (rB(rs1, 6), rB(rs2, 6)) @
         radd (rB(rs1, 5), rB(rs2, 5)) @ radd (rB(rs1, 4), rB(rs2, 4)) @
         radd (rB(rs1, 3), rB(rs2, 3)) @ radd (rB(rs1, 2), rB(rs2, 2)) @
         radd (rB(rs1, 1), rB(rs2, 1)) @ radd (rB(rs1, 0), rB(rs2, 0));
  X (rd) = result;
  true
}

val PEXT_RADD16 : (regidx, regidx, regidx) -> bool
  effect {escape, rreg, wreg}
function PEXT_RADD16 (rs2, rs1, rd) = {
  let result : xlenbits =
    if sizeof(xlen) == 32
    then radd (rH(rs1, 1), rH(rs2, 1)) @ radd (rH(rs1, 0), rH(rs2, 0))
    else radd (rH(rs1, 3), rH(rs2, 3)) @ radd (rH(rs1, 2), rH(rs2, 2)) @
         radd (rH(rs1, 1), rH(rs2, 1)) @ radd (rH(rs1, 0), rH(rs2, 0));
  X (rd) = result;
  true
}

val PEXT_RADD64 : (regidx, regidx, regidx) -> bool
  effect {escape, rreg, wreg}
function PEXT_RADD64 (rs2, rs1, rd) = {
  let result : bits(64) = radd64 (rD (rs1) , rD (rs2));
  set_rD (rd, result);
  true
}

/* *****************************************************************/

val PEXT_UKADD8 : (regidx, regidx, regidx) -> bool
  effect {escape, rreg, wreg}
function PEXT_UKADD8 (rs2, rs1, rd) = {
  let result : xlenbits =
    if sizeof(xlen) == 32
    then ukadd (rB(rs1, 3), rB(rs2, 3)) @ ukadd (rB(rs1, 2), rB(rs2, 2)) @
         ukadd (rB(rs1, 1), rB(rs2, 1)) @ ukadd (rB(rs1, 0), rB(rs2, 0))
    else ukadd (rB(rs1, 7), rB(rs2, 7)) @ ukadd (rB(rs1, 6), rB(rs2, 6)) @
         ukadd (rB(rs1, 5), rB(rs2, 5)) @ ukadd (rB(rs1, 4), rB(rs2, 4)) @
         ukadd (rB(rs1, 3), rB(rs2, 3)) @ ukadd (rB(rs1, 2), rB(rs2, 2)) @
         ukadd (rB(rs1, 1), rB(rs2, 1)) @ ukadd (rB(rs1, 0), rB(rs2, 0));
  X (rd) = result;
  true
}

val PEXT_UKADD16 : (regidx, regidx, regidx) -> bool
  effect {escape, rreg, wreg}
function PEXT_UKADD16 (rs2, rs1, rd) = {
  let result : xlenbits =
    if sizeof(xlen) == 32
    then ukadd (rH(rs1, 1), rH(rs2, 1)) @ ukadd (rH(rs1, 0), rH(rs2, 0))
    else ukadd (rH(rs1, 3), rH(rs2, 3)) @ ukadd (rH(rs1, 2), rH(rs2, 2)) @
         ukadd (rH(rs1, 1), rH(rs2, 1)) @ ukadd (rH(rs1, 0), rH(rs2, 0));
  X (rd) = result;
  true
}

val PEXT_UKADD32 : (regidx, regidx, regidx) -> bool
  effect {escape, rreg, wreg}
function PEXT_UKADD32 (rs2, rs1, rd) = {
  if (~ (haveZpsfoperand ()) | sizeof (xlen) == 32 ) then {
    false
  } else {
    let result : xlenbits =
      ukadd (rW(rs1, 1), rW(rs2, 1)) @ ukadd (rW(rs1, 0), rW(rs2, 0));
    X(rd) = result;
    true
  }
}

val PEXT_UKADD64 : (regidx, regidx, regidx) -> bool
  effect {escape, rreg, wreg}
function PEXT_UKADD64 (rs2, rs1, rd) = {
  let result : bits(64) = ukadd64 (rD (rs1), rD (rs2));
  set_rD (rd, result);
  true
}

/* *****************************************************************/

val PEXT_URADD8 : (regidx, regidx, regidx) -> bool
  effect {escape, rreg, wreg}
function PEXT_URADD8 (rs2, rs1, rd) = {
  let result : xlenbits =
    if sizeof(xlen) == 32
    then uradd (rB(rs1, 3), rB(rs2, 3)) @ uradd (rB(rs1, 2), rB(rs2, 2)) @
         uradd (rB(rs1, 1), rB(rs2, 1)) @ uradd (rB(rs1, 0), rB(rs2, 0))
    else uradd (rB(rs1, 7), rB(rs2, 7)) @ uradd (rB(rs1, 6), rB(rs2, 6)) @
         uradd (rB(rs1, 5), rB(rs2, 5)) @ uradd (rB(rs1, 4), rB(rs2, 4)) @
         uradd (rB(rs1, 3), rB(rs2, 3)) @ uradd (rB(rs1, 2), rB(rs2, 2)) @
         uradd (rB(rs1, 1), rB(rs2, 1)) @ uradd (rB(rs1, 0), rB(rs2, 0));
  X (rd) = result;
  true
}

val PEXT_URADD16 : (regidx, regidx, regidx) -> bool
  effect {escape, rreg, wreg}
function PEXT_URADD16 (rs2, rs1, rd) = {
  let result : xlenbits =
    if sizeof(xlen) == 32
    then uradd (rH(rs1, 1), rH(rs2, 1)) @ uradd (rH(rs1, 0), rH(rs2, 0))
    else uradd (rH(rs1, 3), rH(rs2, 3)) @ uradd (rH(rs1, 2), rH(rs2, 2)) @
         uradd (rH(rs1, 1), rH(rs2, 1)) @ uradd (rH(rs1, 0), rH(rs2, 0));
  X (rd) = result;
  true
}

val PEXT_URADD32 : (regidx, regidx, regidx) -> bool
  effect {escape, rreg, wreg}
function PEXT_URADD32 (rs2, rs1, rd) = {
  if (~ (haveZpsfoperand ()) | sizeof (xlen) == 32 ) then {
    false
  } else {
    let result : xlenbits =
      uradd (rW(rs1, 1), rW(rs2, 1)) @ uradd (rW(rs1, 0), rW(rs2, 0));
    X(rd) = result;
    true
  }
}

val PEXT_URADD64 : (regidx, regidx, regidx) -> bool
  effect {escape, rreg, wreg}
function PEXT_URADD64 (rs2, rs1, rd) = {
  let result : bits(64) = uradd64 (rD (rs1), rD (rs2));
  set_rD (rd, result);
  true
}
