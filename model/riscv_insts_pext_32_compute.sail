/* *****************************************************************/
/* This file specifies the instruction added by the 'P' extension. */
/* *****************************************************************/

/* *****************************************************************/
/* ********************* auxiliary functions ***********************/
/* *****************************************************************/

val umul33_64 :
  (bits(33), bits(33)) -> bits(64)
function umul33_64 (v1, v2) =
  to_bits (66, unsigned(v1) * unsigned(v2))[63..0]

val mul32_64 :
  (bits(32), bits(32)) -> bits(64)
function mul32_64 (v1, v2) =
  to_bits (64, signed(v1) * signed(v2))

val mulb :
  (bits(32), bits(32)) -> bits(32)
function mulb (v1, v2) =
  to_bits (64, unsigned(v1) * unsigned(v2))[31..0]



/* *****************************************************************/

val PEXT_RADDW: (regidx, regidx, regidx) -> bool effect {escape,rreg,wreg}
function PEXT_RADDW (rs2, rs1, rd) = {
  let res33 : bits(33) = add_bits(EXTS(rW(rs1, 0)), EXTS(rW(rs2, 0))) in
  if sizeof(xlen) == 32
  then X(rd) = res33[32..1]
  else X(rd) = EXTS(res33[32..1]);    
  true
}

/* *****************************************************************/

val PEXT_URADDW: (regidx, regidx, regidx) -> bool effect {escape,rreg,wreg}
function PEXT_URADDW (rs2, rs1, rd) = {
  let res33 : bits(33) = add_bits(EXTZ(rW(rs1, 0)), EXTZ(rW(rs2, 0))) in
  if sizeof(xlen) == 32
  then X(rd) = res33[32..1]
  else X(rd) = EXTS(res33[32..1]);    
  true
}

/* *****************************************************************/

val PEXT_RSUBW: (regidx, regidx, regidx) -> bool effect {escape,rreg,wreg}
function PEXT_RSUBW (rs2, rs1, rd) = {
  let res33 : bits(33) = sub_bits(EXTS(rW(rs1, 0)), EXTS(rW(rs2, 0))) in
  if sizeof(xlen) == 32
  then X(rd) = res33[32..1]
  else X(rd) = EXTS(res33[32..1]);    
  true
}

/* *****************************************************************/

val PEXT_URSUBW: (regidx, regidx, regidx) -> bool effect {escape,rreg,wreg}
function PEXT_URSUBW (rs2, rs1, rd) = {
  let res33 : bits(33) = sub_bits(EXTZ(rW(rs1, 0)), EXTZ(rW(rs2, 0))) in
  if sizeof(xlen) == 32
  then X(rd) = res33[32..1]
  else X(rd) = EXTS(res33[32..1]);    
  true
}

/* *****************************************************************/

val PEXT_MAXW: (regidx, regidx, regidx) -> bool effect {escape,rreg,wreg}
function PEXT_MAXW (rs2, rs1, rd) = {
  let res : bits(32) =  if rW(rs1, 0) <_s rW(rs2, 0) then rW(rs2, 0) else rW(rs1, 0) in
  if sizeof(xlen) == 32
  then X(rd) = res
  else X(rd) = EXTS(res);    
  true
}

/* *****************************************************************/

val PEXT_MINW: (regidx, regidx, regidx) -> bool effect {escape,rreg,wreg}
function PEXT_MINW (rs2, rs1, rd) = {
  let res : bits(32) =  if rW(rs1, 0) <_s rW(rs2, 0) then rW(rs1, 0) else rW(rs2, 0) in
  if sizeof(xlen) == 32
  then X(rd) = res
  else X(rd) = EXTS(res);    
  true
}

/* *****************************************************************/

val PEXT_MULR64: (regidx, regidx, regidx) -> bool effect {escape,rreg,wreg}
function PEXT_MULR64 (rs2, rs1, rd) = {
  let res : bits(64) = umul33_64(EXTZ(rW(rs1, 0)), EXTZ(rW(rs2, 0))) in
  if sizeof(xlen) == 32
  then 
  let rd0 = (rd >> 1) << 1 in
  let rd1 = rd0 + 1 in
  {X(rd0) = res[31..0]; X(rd1) = res[63..32];}
  else X(rd) = res;    
  true
}

/* *****************************************************************/

val PEXT_MULSR64: (regidx, regidx, regidx) -> bool effect {escape,rreg,wreg}
function PEXT_MULSR64 (rs2, rs1, rd) = {
  let res : bits(64) = mul32_64(rW(rs1, 0), rW(rs2, 0)) in
  if sizeof(xlen) == 32
  then 
  let rd0 = (rd >> 1) << 1 in
  let rd1 = rd0 + 1 in
  {X(rd0) = res[31..0]; X(rd1) = res[63..32];}
  else X(rd) = res;    
  true
}

/* *****************************************************************/

val PEXT_MSUBR32: (regidx, regidx, regidx) -> bool effect {escape,rreg,wreg}
function PEXT_MSUBR32 (rs2, rs1, rd) = {
  let mres : bits(32) = mulb(rW(rs1, 0), rW(rs2, 0)) in
  let res : bits(32) = sub_bits(rW(rd, 0), mres) in
  if sizeof(xlen) == 32
  then X(rd) = res
  else X(rd) = EXTS(res);    
  true
}