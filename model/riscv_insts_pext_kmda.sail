/* Programming Langauge Lab, Department of Computer Science, National Tsing-Hua University, Taiwan */
/* Academia Sinica, Taiwan*/
/* Andes Technology Corporation*/

/* *****************************************************************/
/* This file specifies the instruction subed by the 'P' extension. */
/* *****************************************************************/

/* *****************************************************************/
/* ********************* auxiliary functions ***********************/
/* *****************************************************************/

val kmda : forall 'n, 'n == 16 | 'n == 32.
  (bits ('n), bits ('n), bits ('n), bits ('n)) -> bits ('n + 'n)
  effect {rreg,wreg}
function kmda (a, b, c, d) =
  let lb : bits ('n) = if 'n == 16 then 0x8000 else 0x80000000 in
  if (a == lb & b == lb & c == lb & d == lb) then {
    pext_write_OV (0b1);
    sail_ones (2 * 'n) >> 1
  } else
    let ab = to_bits (2 * 'n, signed (a) * signed (b)) in
    let cd = to_bits (2 * 'n, signed (c) * signed (d)) in
    ab + cd

/* *****************************************************************/

//val PEXT_KMDA : (regidx, regidx, regidx) -> unit
val PEXT_KMDA : (regidx, regidx, regidx) -> bool
  effect {escape, rreg, wreg}
function PEXT_KMDA (rs2, rs1, rd) = {
  let result : xlenbits =
    if sizeof(xlen) == 32
    then kmda (rH (rs1, 1), rH (rs2, 1), rH (rs1, 0), rH (rs2, 0))
    else kmda (rH (rs1, 3), rH (rs2, 3), rH (rs1, 2), rH (rs2, 2)) @
         kmda (rH (rs1, 1), rH (rs2, 1), rH (rs1, 0), rH (rs2, 0));
  X (rd) = result;
  true
}

//val PEXT_KMDA32 : (regidx, regidx, regidx) -> unit
val PEXT_KMDA32 : (regidx, regidx, regidx) -> bool
  effect {escape, rreg, wreg}
function PEXT_KMDA32 (rs2, rs1, rd) = {
  if sizeof (xlen) == 32 then {
    handle_illegal();
    false
    /* TODO: RETIRE_FAIL */
  } else {
    let result : xlenbits =
      kmda (rW (rs1, 1), rW (rs2, 1), rW (rs1, 0), rW (rs2, 0));
    X (rd) = result;
    true
  }
}

/* *****************************************************************/

val PEXT_KMXDA : (regidx, regidx, regidx) -> bool
  effect {escape, rreg, wreg}
function PEXT_KMXDA (rs2, rs1, rd) = {
  let result : xlenbits =
    if sizeof(xlen) == 32
    then kmda (rH (rs1, 1), rH (rs2, 0), rH (rs1, 0), rH (rs2, 1))
    else kmda (rH (rs1, 3), rH (rs2, 2), rH (rs1, 2), rH (rs2, 3)) @
         kmda (rH (rs1, 1), rH (rs2, 0), rH (rs1, 0), rH (rs2, 1));
  X (rd) = result;
  true
}

val PEXT_KMXDA32 : (regidx, regidx, regidx) -> bool
  effect {escape, rreg, wreg}
function PEXT_KMXDA32 (rs2, rs1, rd) = {
  if sizeof (xlen) == 32 then {
    false
  } else {
    let result : xlenbits =
      kmda (rW (rs1, 1), rW (rs2, 0), rW (rs1, 0), rW (rs2, 1));
    X (rd) = result;
    true
  }
}
