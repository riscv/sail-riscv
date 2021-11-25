/* Programming Langauge Lab, Department of Computer Science, National Tsing-Hua University, Taiwan */
/* Academia Sinica, Taiwan*/
/* Andes Technology Corporation*/

/* *****************************************************************/
/* This file specifies the instruction added by the 'P' extension. */
/* *****************************************************************/

/* *****************************************************************/
/* ********************* auxiliary functions ***********************/
/* *****************************************************************/

val PEXT_ADD32 : (regidx, regidx, regidx) -> bool
  effect {escape, rreg, wreg}
function PEXT_ADD32 (rs2, rs1, rd) = {
  let result : bits(64) =
    (rW(rs1, 1) + rW(rs2, 1)) @ (rW(rs1, 0) + rW(rs2, 0));
  X(rd) = result;
  true
}

val PEXT_KADD32 : (regidx, regidx, regidx) -> bool
  effect {escape, rreg, wreg}
function PEXT_KADD32 (rs2, rs1, rd) = {
  let result : xlenbits =
    kadd (rW(rs1, 1), rW(rs2, 1)) @ kadd (rW(rs1, 0), rW(rs2, 0));
  X(rd) = result;
  true
}

val PEXT_UKADD32 : (regidx, regidx, regidx) -> bool
  effect {escape, rreg, wreg}
function PEXT_UKADD32 (rs2, rs1, rd) = {
  let result : xlenbits =
    ukadd (rW(rs1, 1), rW(rs2, 1)) @ ukadd (rW(rs1, 0), rW(rs2, 0));
  X(rd) = result;
  true
}

val PEXT_RADD32 : (regidx, regidx, regidx) -> bool
  effect {escape, rreg, wreg}
function PEXT_RADD32 (rs2, rs1, rd) = {
  let result : xlenbits =
    radd (rW(rs1, 1), rW(rs2, 1)) @ radd (rW(rs1, 0), rW(rs2, 0));
  X(rd) = result;
  true
}

val PEXT_URADD32 : (regidx, regidx, regidx) -> bool
  effect {escape, rreg, wreg}
function PEXT_URADD32 (rs2, rs1, rd) = {
  let result : xlenbits =
    uradd (rW(rs1, 1), rW(rs2, 1)) @ uradd (rW(rs1, 0), rW(rs2, 0));
  X(rd) = result;
  true
}

val PEXT_KSUB32 : (regidx, regidx, regidx) -> bool
  effect {escape, rreg, wreg}
function PEXT_KSUB32 (rs2, rs1, rd) = {
  let result : xlenbits =
    ksub (rW(rs1, 1), rW(rs2, 1)) @ ksub (rW(rs1, 0), rW(rs2, 0));
  X(rd) = result;
  true
}


val PEXT_RSUB32 : (regidx, regidx, regidx) -> bool
  effect {escape, rreg, wreg}
function PEXT_RSUB32 (rs2, rs1, rd) = {
  let result : xlenbits =
    rsub (rW(rs1, 1), rW(rs2, 1)) @ rsub (rW(rs1, 0), rW(rs2, 0));
  X(rd) = result;
  true
}

val PEXT_SUB32 : (regidx, regidx, regidx) -> bool
  effect {escape, rreg, wreg}
function PEXT_SUB32 (rs2, rs1, rd) = {
  let result : xlenbits =
    (rW(rs1, 1) - rW(rs2, 1)) @ (rW(rs1, 0) - rW(rs2, 0));
  X(rd) = result;
  true
}

val PEXT_UKSUB32 : (regidx, regidx, regidx) -> bool
  effect {escape, rreg, wreg}
function PEXT_UKSUB32 (rs2, rs1, rd) = {
  let result : xlenbits =
    uksub (rW(rs1, 1), rW(rs2, 1)) @ uksub (rW(rs1, 0), rW(rs2, 0));
  X(rd) = result;
  true
}


val PEXT_URSUB32 : (regidx, regidx, regidx) -> bool
  effect {escape, rreg, wreg}
function PEXT_URSUB32 (rs2, rs1, rd) = {
  let result : xlenbits =
    ursub (rW(rs1, 1), rW(rs2, 1)) @ ursub (rW(rs1, 0), rW(rs2, 0));
  X(rd) = result;
  true
}

/* *****************************************************************/

val PEXT_SMIN32 : (regidx, regidx, regidx) -> bool effect {escape,rreg,wreg}
function PEXT_SMIN32(rs2, rs1, rd) = {
  let result : xlenbits =
    smin (rW(rs1, 1), rW(rs2, 1)) @ smin (rW(rs1, 0), rW(rs2, 0));
  X(rd) = result;
  true
}

/* *****************************************************************/

val PEXT_UMIN32 : (regidx, regidx, regidx) -> bool effect {escape,rreg,wreg}
function PEXT_UMIN32(rs2, rs1, rd) = {
  let result : xlenbits =
    umin (rW(rs1, 1), rW(rs2, 1)) @ umin (rW(rs1, 0), rW(rs2, 0));
  X(rd) = result;
  true
}

/* *****************************************************************/

val PEXT_SMAX32 : (regidx, regidx, regidx) -> bool effect {escape,rreg,wreg}
function PEXT_SMAX32(rs2, rs1, rd) = {
  let result : xlenbits =
    smax (rW(rs1, 1), rW(rs2, 1)) @ smax (rW(rs1, 0), rW(rs2, 0));
  X(rd) = result;
  true
}

/* *****************************************************************/

val PEXT_UMAX32 : (regidx, regidx, regidx) -> bool effect {escape,rreg,wreg}
function PEXT_UMAX32(rs2, rs1, rd) = {
  let result : xlenbits =
    umax (rW(rs1, 1), rW(rs2, 1)) @ umax (rW(rs1, 0), rW(rs2, 0));
  X(rd) = result;
  true
}

/* *****************************************************************/

val PEXT_KABS32 : (regidx, regidx) -> bool effect {escape,rreg,wreg}
function PEXT_KABS32(rs1, rd) = {
  let result : xlenbits =
    kabs (rW(rs1, 1)) @ kabs (rW(rs1, 0));
  X(rd) = result;
  true
}

/* *****************************************************************/

val PEXT_SMBT32 : (regidx, regidx, regidx) -> bool effect {escape,rreg,wreg}
function PEXT_SMBT32(rs2, rs1, rd) = {
  X(rd) = smul (rW(rs1, 0), rW(rs2, 1));
  true
}

/* *****************************************************************/

val PEXT_SMTT32 : (regidx, regidx, regidx) -> bool effect {escape,rreg,wreg}
function PEXT_SMTT32(rs2, rs1, rd) = {
  X(rd) = smul (rW(rs1, 1), rW(rs2, 1));
  true
}

/* *****************************************************************/

val PEXT_SMDS32 : (regidx, regidx, regidx) -> bool effect {escape,rreg,wreg}
function PEXT_SMDS32(rs2, rs1, rd) = {
  X(rd) = smul (rW(rs1, 1), rW(rs2, 1)) - smul (rW(rs1, 0), rW(rs2, 0));
  true
}

/* *****************************************************************/

val PEXT_SMDRS32 : (regidx, regidx, regidx) -> bool effect {escape,rreg,wreg}
function PEXT_SMDRS32(rs2, rs1, rd) = {
  X(rd) = smul (rW(rs1, 0), rW(rs2, 0)) - smul (rW(rs1, 1), rW(rs2, 1));
  true
}

/* *****************************************************************/

val PEXT_SMXDS32 : (regidx, regidx, regidx) -> bool effect {escape,rreg,wreg}
function PEXT_SMXDS32(rs2, rs1, rd) = {
  X(rd) = smul (rW(rs1, 1), rW(rs2, 0)) - smul (rW(rs1, 0), rW(rs2, 1));
  true
}

/* *****************************************************************/

val PEXT_KMABB32 : (regidx, regidx, regidx) -> bool effect {escape,rreg,wreg}
function PEXT_KMABB32(rs2, rs1, rd) = {
  X(rd) = kadd64 (smul (rW(rs1, 0), rW(rs2, 0)), rD(rd));
  true
}

/* *****************************************************************/

val PEXT_KMABT32 : (regidx, regidx, regidx) -> bool effect {escape,rreg,wreg}
function PEXT_KMABT32(rs2, rs1, rd) = {
  X(rd) = kadd64 (smul (rW(rs1, 0), rW(rs2, 1)), rD(rd));
  true
}

/* *****************************************************************/

val PEXT_KMATT32 : (regidx, regidx, regidx) -> bool effect {escape,rreg,wreg}
function PEXT_KMATT32(rs2, rs1, rd) = {
  X(rd) = kadd64 (smul (rW(rs1, 1), rW(rs2, 1)), rD(rd));
  true
}

/* *****************************************************************/

val PEXT_KMADA32 : (regidx, regidx, regidx) -> bool effect {escape,rreg,wreg}
function PEXT_KMADA32(rs2, rs1, rd) = {
  X(rd) = kmada(rD(rd), rW(rs1, 1), rW(rs2, 1), rW(rs1, 0), rW(rs2, 0));
  true
}

/* *****************************************************************/

val PEXT_KMAXDA32 : (regidx, regidx, regidx) -> bool effect {escape,rreg,wreg}
function PEXT_KMAXDA32(rs2, rs1, rd) = {
  X(rd) = kmada(rD(rd), rW(rs1, 1), rW(rs2, 0), rW(rs1, 0), rW(rs2, 1));
  true
}

/* *****************************************************************/

val PEXT_KMADS32 : (regidx, regidx, regidx) -> bool effect {escape,rreg,wreg}
function PEXT_KMADS32(rs2, rs1, rd) = {
  X(rd) = kmads(rD(rd), rW(rs1, 1), rW(rs2, 1), rW(rs1, 0), rW(rs2, 0));
  true
}

/* *****************************************************************/

val PEXT_KMADRS32 : (regidx, regidx, regidx) -> bool effect {escape,rreg,wreg}
function PEXT_KMADRS32(rs2, rs1, rd) = {
  X(rd) = kmads(rD(rd), rW(rs1, 0), rW(rs2, 0), rW(rs1, 1), rW(rs2, 1));
  true
}

/* *****************************************************************/

val PEXT_KMAXDS32 : (regidx, regidx, regidx) -> bool effect {escape,rreg,wreg}
function PEXT_KMAXDS32(rs2, rs1, rd) = {
  X(rd) = kmads(rD(rd), rW(rs1, 1), rW(rs2, 0), rW(rs1, 0), rW(rs2, 1));
  true
}

/* *****************************************************************/

val PEXT_KMSDA32 : (regidx, regidx, regidx) -> bool effect {escape,rreg,wreg}
function PEXT_KMSDA32(rs2, rs1, rd) = {
  X(rd) = kmsda(rD(rd), rW(rs1, 1), rW(rs2, 1), rW(rs1, 0), rW(rs2, 0));
  true
}

/* *****************************************************************/

val PEXT_KMSXDA32 : (regidx, regidx, regidx) -> bool effect {escape,rreg,wreg}
function PEXT_KMSXDA32(rs2, rs1, rd) = {
  X(rd) = kmsda(rD(rd), rW(rs1, 1), rW(rs2, 0), rW(rs1, 0), rW(rs2, 1));
  true
}

/* *****************************************************************/
val PEXT_PKBB32 : (regidx, regidx, regidx) -> bool effect {escape,rreg,wreg}
function PEXT_PKBB32 (rs2, rs1, rd) = {
  let result : xlenbits =
    rW(rs1, 0) @ rW(rs2, 0);
  X(rd) = result;
  true
}

/* *****************************************************************/

val PEXT_PKBT32 : (regidx, regidx, regidx) -> bool effect {escape,rreg,wreg}
function PEXT_PKBT32 (rs2, rs1, rd) = {
  let result : xlenbits =
    rW(rs1, 0) @ rW(rs2, 1);
  X(rd) = result;
  true
}

/* *****************************************************************/

val PEXT_PKTT32 : (regidx, regidx, regidx) -> bool effect {escape,rreg,wreg}
function PEXT_PKTT32 (rs2, rs1, rd) = {
  let result : xlenbits =
    rW(rs1, 1) @ rW(rs2, 1);
  X(rd) = result;
  true
}

/* *****************************************************************/

val PEXT_PKTB32 : (regidx, regidx, regidx) -> bool effect {escape,rreg,wreg}
function PEXT_PKTB32 (rs2, rs1, rd) = {
  let result : xlenbits =
    rW(rs1, 1) @ rW(rs2, 0);
  X(rd) = result;
  true
}

/* *****************************************************************/
val PEXT_SRA32 : (regidx, regidx, regidx) -> bool effect {escape,rreg,wreg}
function PEXT_SRA32(rs2, rs1, rd) = {
  let sa : byte = EXTZ(X(rs2)[4..0]) in
  X(rd) = shift_right_arith (rW(rs1, 1), sa) @ shift_right_arith (rW(rs1, 0), sa);
  true
}

/* *****************************************************************/

val PEXT_SRA32_U : (regidx, regidx, regidx) -> bool effect {escape,rreg,wreg}
function PEXT_SRA32_U(rs2, rs1, rd) = {
  let sa : byte = EXTZ(X(rs2)[4..0]) in
  X(rd) = shift_right_arith_u (rW(rs1, 1), sa) @ shift_right_arith_u (rW(rs1, 0), sa);
  true
}

/* *****************************************************************/

val PEXT_SRAI32 : (bits(5), regidx, regidx) -> bool effect {escape,rreg,wreg}
function PEXT_SRAI32 (imm5, rs1, rd) = {
  let sa : byte = EXTZ (imm5);
  X(rd) = shift_right_arith (rW(rs1, 1), sa) @ shift_right_arith (rW(rs1, 0), sa);
  true
}

/* *****************************************************************/

val PEXT_SRAI32_U : (bits(5), regidx, regidx) -> bool effect {escape,rreg,wreg}
function PEXT_SRAI32_U(imm5, rs1, rd) = {
  let sa : byte = EXTZ(imm5) in
  X(rd) = shift_right_arith_u (rW(rs1, 1), sa) @ shift_right_arith_u (rW(rs1, 0), sa);
  true
}

/* *****************************************************************/

val PEXT_SRL32 : (regidx, regidx, regidx) -> bool effect {escape,rreg,wreg}
function PEXT_SRL32(rs2, rs1, rd) = {
  let sa : byte = EXTZ(X(rs2)[4..0]) in
  X(rd) = shift_right_logic (rW(rs1, 1), sa) @ shift_right_logic (rW(rs1, 0), sa);
  true
}

/* *****************************************************************/

val PEXT_SRL32_U : (regidx, regidx, regidx) -> bool effect {escape,rreg,wreg}
function PEXT_SRL32_U(rs2, rs1, rd) = {
  let sa : byte = EXTZ(X(rs2)[4..0]) in
  X(rd) = shift_right_logic_u (rW(rs1, 1), sa) @ shift_right_logic_u (rW(rs1, 0), sa);
  true
}

/* *****************************************************************/

val PEXT_SRLI32 : (bits(5), regidx, regidx) -> bool effect {escape,rreg,wreg}
function PEXT_SRLI32 (imm5, rs1, rd) = {
  let sa : byte = EXTZ (imm5) in
  X(rd) = shift_right_logic (rW(rs1, 1), sa) @ shift_right_logic (rW(rs1, 0), sa);
  true
}

/* *****************************************************************/

val PEXT_SRLI32_U : (bits(5), regidx, regidx) -> bool effect {escape,rreg,wreg}
function PEXT_SRLI32_U(imm5, rs1, rd) = {
  let sa : byte = EXTZ(imm5) in
  X(rd) = shift_right_logic_u (rW(rs1, 1), sa) @ shift_right_logic_u (rW(rs1, 0), sa);
  true
}

/* *****************************************************************/

val PEXT_SLL32 : (regidx, regidx, regidx) -> bool effect {escape,rreg,wreg}
function PEXT_SLL32(rs2, rs1, rd) = {
  let sa : byte = EXTZ(X(rs2)[4..0]) in
  X(rd) = shift_left_logic (rW(rs1, 1), sa) @ shift_left_logic (rW(rs1, 0), sa);
  true
}

/* *****************************************************************/

val PEXT_SLLI32 : (bits(5), regidx, regidx) -> bool effect {escape,rreg,wreg}
function PEXT_SLLI32 (imm5, rs1, rd) = {
  let sa : byte = EXTZ (imm5) in
  X(rd) = shift_left_logic (rW(rs1, 1), sa) @ shift_left_logic (rW(rs1, 0), sa);
  true
}

/* *****************************************************************/

val PEXT_KSLL32 : (regidx, regidx, regidx) -> bool effect {escape,rreg,wreg}
function PEXT_KSLL32(rs2, rs1, rd) = {
  let sa : byte = EXTZ(X(rs2)[4..0]) in
  X(rd) = kshift_left_logic (rW(rs1, 1), sa) @ kshift_left_logic (rW(rs1, 0), sa);
  true
}

/* *****************************************************************/

val PEXT_KSLLI32 : (bits(5), regidx, regidx) -> bool effect {escape,rreg,wreg}
function PEXT_KSLLI32 (imm5, rs1, rd) = {
  let sa : byte = EXTZ (imm5) in
  X(rd) = kshift_left_logic (rW(rs1, 1), sa) @ kshift_left_logic (rW(rs1, 0), sa);
  true
}

/* *****************************************************************/

val PEXT_KSLRA32 : (regidx, regidx, regidx) -> bool effect {escape,rreg,wreg}
function PEXT_KSLRA32 (rs2, rs1, rd) = {
  let sa : byte = EXTS(X(rs2)[5..0]);
  X(rd) = kslra (rW(rs1, 1), sa) @ kslra (rW(rs1, 0), sa);
  true
}

/* *****************************************************************/

val PEXT_KSLRA32_U : (regidx, regidx, regidx) -> bool effect {escape,rreg,wreg}
function PEXT_KSLRA32_U (rs2, rs1, rd) = {
  let sa : byte = EXTS(X(rs2)[5..0]);
  X(rd) = kslra_u (rW(rs1, 1), sa) @ kslra_u (rW(rs1, 0), sa);
  true
}

/* *****************************************************************/

val PEXT_SRAIW_U : (bits(5), regidx, regidx) -> bool effect {escape,rreg,wreg}
function PEXT_SRAIW_U (imm5, rs1, rd) = {
  let sa : byte = EXTZ(imm5);
  X(rd) =
    if (sa == 0x00)
    then EXTS(rW(rs1, 0))
    else EXTS(shift_right_arith_u (rW(rs1, 0), sa)); 
  true
}

/* *****************************************************************/

val sshmexts :
  (bits(16), bits(16)) -> bits(32) effect {rreg, wreg}
function sshmexts (v1, v2) =
  EXTS(sshm (v1, v2))

/* *****************************************************************/

val PEXT_KHMBB16: (regidx, regidx, regidx) -> bool effect {escape,rreg,wreg}
function PEXT_KHMBB16 (rs2, rs1, rd) = {
  X(rd) = sshmexts(rH(rs1, 2), rH(rs2, 2)) @ sshmexts(rH(rs1, 0), rH(rs2, 0));
  true
}

/* *****************************************************************/

val PEXT_KHMBT16: (regidx, regidx, regidx) -> bool effect {escape,rreg,wreg}
function PEXT_KHMBT16 (rs2, rs1, rd) = {
  X(rd) = sshmexts(rH(rs1, 2), rH(rs2, 3)) @ sshmexts(rH(rs1, 0), rH(rs2, 1));
  true
}

/* *****************************************************************/

val PEXT_KHMTT16: (regidx, regidx, regidx) -> bool effect {escape,rreg,wreg}
function PEXT_KHMTT16 (rs2, rs1, rd) = {
  X(rd) = sshmexts(rH(rs1, 3), rH(rs2, 3)) @ sshmexts(rH(rs1, 1), rH(rs2, 1));
  true
}

/* *****************************************************************/

val PEXT_KDMBB16 : (regidx, regidx, regidx) -> bool effect {escape, rreg, wreg}
function PEXT_KDMBB16 (rs2, rs1, rd) = {
  X(rd) = kdm(rH(rs1, 2), rH(rs2, 2)) @ kdm(rH(rs1, 0), rH(rs2, 0));
  true
}

/* *****************************************************************/

val PEXT_KDMBT16 : (regidx, regidx, regidx) -> bool effect {escape, rreg, wreg}
function PEXT_KDMBT16 (rs2, rs1, rd) = {
  X(rd) = kdm(rH(rs1, 2), rH(rs2, 3)) @ kdm(rH(rs1, 0), rH(rs2, 1));
  true
}

/* *****************************************************************/

val PEXT_KDMTT16 : (regidx, regidx, regidx) -> bool effect {escape, rreg, wreg}
function PEXT_KDMTT16 (rs2, rs1, rd) = {
  X(rd) = kdm(rH(rs1, 3), rH(rs2, 3)) @ kdm(rH(rs1, 1), rH(rs2, 1));
  true
}

/* *****************************************************************/

val PEXT_KDMABB16 : (regidx, regidx, regidx) -> bool effect {escape,rreg,wreg}
function PEXT_KDMABB16 (rs2, rs1, rd) = {
  X(rd) = kdmaw(rH(rs1, 2), rH(rs2, 2), rW(rd, 1)) @ kdmaw(rH(rs1, 0), rH(rs2, 0), rW(rd, 0));
  true
}

/* *****************************************************************/

val PEXT_KDMABT16 : (regidx, regidx, regidx) -> bool effect {escape,rreg,wreg}
function PEXT_KDMABT16 (rs2, rs1, rd) = {
  X(rd) = kdmaw(rH(rs1, 2), rH(rs2, 3), rW(rd, 1)) @ kdmaw(rH(rs1, 0), rH(rs2, 1), rW(rd, 0));
  true
}

/* *****************************************************************/

val PEXT_KDMATT16 : (regidx, regidx, regidx) -> bool effect {escape,rreg,wreg}
function PEXT_KDMATT16 (rs2, rs1, rd) = {
  X(rd) = kdmaw(rH(rs1, 3), rH(rs2, 3), rW(rd, 1)) @ kdmaw(rH(rs1, 1), rH(rs2, 1), rW(rd, 0));
  true
}

/* *****************************************************************/