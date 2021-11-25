/* Programming Langauge Lab, Department of Computer Science, National Tsing-Hua University, Taiwan */
/* Academia Sinica, Taiwan*/
/* Andes Technology Corporation*/

/* *****************************************************************/
/* This file specifies the instruction added by the 'P' extension. */
/* *****************************************************************/

/* *****************************************************************/
/* ********************* auxiliary functions ***********************/
/* *****************************************************************/

val q15 : 
  bits(33) -> bits(16) effect {rreg, wreg}
function q15 (v) =
  let ub : bits(33) = EXTS(0x7FFF) in
  let lb : bits(33) = EXTS(0x8000) in
  if v <_s lb then { pext_write_OV (0b1); 0x8000;}
  else if ub <_s v then { pext_write_OV (0b1); 0x7FFF;}
  else v[15..0]

val q15_l_u : 
  bits(33) -> bits(16) effect {rreg, wreg}
function q15_l_u (v) =
  let ub : bits(33) = EXTZ(0xFFFF) in
  if ub <_u v then { pext_write_OV (0b1); 0xFFFF;}
  else v[15..0]

val q15_s_u : 
  bits(33) -> bits(16) effect {rreg, wreg}
function q15_s_u (v) =
  let ub : bits(33) = EXTZ(0xFFFF) in
  let lb : bits(33) = EXTZ(0x0000) in
  if ub <_s v then { pext_write_OV (0b1); 0xFFFF;}
  else if v <_s lb then { pext_write_OV (0b1); 0x0000;}
  else v[15..0]
  
val sshm :
  (bits(16), bits(16)) -> bits(16) effect {rreg, wreg}
function sshm (v1, v2)=
  if (v1 != 0x8000) | (v2 != 0x8000)
  then 
  let res : bits(32) = to_bits(32, signed(v1) * signed(v2)) in
  let rshift : bits(32) = EXTS(res >> 15) in 
  rshift[15..0]
  else { pext_write_OV (0b1); 0x7FFF;}

/* *****************************************************************/

val PEXT_KADDH: (regidx, regidx, regidx) -> bool effect {escape,rreg,wreg}
function PEXT_KADDH (rs2, rs1, rd) = {
  let tmp : bits(33) = add_bits(EXTS(rW(rs1, 0)), EXTS(rW(rs2, 0))) in
  X(rd) = EXTS(q15(tmp));
  true
}

/* *****************************************************************/

val PEXT_KSUBH: (regidx, regidx, regidx) -> bool effect {escape,rreg,wreg}
function PEXT_KSUBH (rs2, rs1, rd) = {
  let tmp : bits(33) = sub_bits(EXTS(rW(rs1, 0)), EXTS(rW(rs2, 0))) in
  X(rd) = EXTS(q15(tmp));
  true
}

/* *****************************************************************/

val PEXT_KHMBB: (regidx, regidx, regidx) -> bool effect {escape,rreg,wreg}
function PEXT_KHMBB (rs2, rs1, rd) = {
  X(rd) = EXTS(sshm(rH(rs1, 0), rH(rs2, 0)));
  true
}

/* *****************************************************************/

val PEXT_KHMBT: (regidx, regidx, regidx) -> bool effect {escape,rreg,wreg}
function PEXT_KHMBT (rs2, rs1, rd) = {
  X(rd) = EXTS(sshm(rH(rs1, 0), rH(rs2, 1)));
  true
}

/* *****************************************************************/

val PEXT_KHMTT: (regidx, regidx, regidx) -> bool effect {escape,rreg,wreg}
function PEXT_KHMTT (rs2, rs1, rd) = {
  X(rd) = EXTS(sshm(rH(rs1, 1), rH(rs2, 1)));
  true
}

/* *****************************************************************/

val PEXT_UKADDH: (regidx, regidx, regidx) -> bool effect {escape,rreg,wreg}
function PEXT_UKADDH (rs2, rs1, rd) = {
  let tmp : bits(33) = add_bits(EXTZ(rW(rs1, 0)), EXTZ(rW(rs2, 0))) in
  X(rd) = EXTS(q15_l_u(tmp));
  true
}

/* *****************************************************************/

val PEXT_UKSUBH: (regidx, regidx, regidx) -> bool effect {escape,rreg,wreg}
function PEXT_UKSUBH (rs2, rs1, rd) = {
  let tmp : bits(33) = sub_bits(EXTZ(rW(rs1, 0)), EXTZ(rW(rs2, 0))) in
  X(rd) = EXTS(q15_s_u(tmp));
  true
}