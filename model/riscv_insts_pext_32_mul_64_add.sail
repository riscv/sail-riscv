/* Programming Langauge Lab, Department of Computer Science, National Tsing-Hua University, Taiwan */
/* Academia Sinica, Taiwan*/
/* Andes Technology Corporation*/

/* *****************************************************************/
/* This file specifies the instruction added by the 'P' extension. */
/* *****************************************************************/

/* *****************************************************************/
/* ********************* auxiliary functions ***********************/
/* *****************************************************************/

/* *****************************************************************/

val PEXT_SMAR64: (regidx, regidx, regidx) -> bool effect {escape,rreg,wreg}
function PEXT_SMAR64 (rs2, rs1, rd) = {
  if sizeof(xlen) == 32
  then
    let rd0 = (rd >> 1) << 1 in
    let rd1 = rd0 + 1 in
    let rdcon : bits(64) = X(rd1) @ X(rd0) in
    let res : bits(64) = add_bits(rdcon, to_bits(64, signed(X(rs1)) * signed(X(rs2)))) in
    {X(rd0) = res[31..0]; X(rd1) = res[63..32];}
  else  
    X(rd) = X(rd) + to_bits(64, signed(rW(rs1, 1)) * signed(rW(rs2, 1))) + to_bits(64, signed(rW(rs1, 0)) * signed(rW(rs2, 0)));
  true
}

/* *****************************************************************/

val PEXT_SMSR64: (regidx, regidx, regidx) -> bool effect {escape,rreg,wreg}
function PEXT_SMSR64 (rs2, rs1, rd) = {
  if sizeof(xlen) == 32
  then
    let rd0 = (rd >> 1) << 1 in
    let rd1 = rd0 + 1 in
    let rdcon : bits(64) = X(rd1) @ X(rd0) in
    let res : bits(64) = sub_bits(rdcon, to_bits(64, signed(X(rs1)) * signed(X(rs2)))) in
    {X(rd0) = res[31..0]; X(rd1) = res[63..32];}
  else  
    X(rd) = X(rd) - to_bits(64, signed(rW(rs1, 1)) * signed(rW(rs2, 1))) - to_bits(64, signed(rW(rs1, 0)) * signed(rW(rs2, 0)));
  true
}

/* *****************************************************************/

val PEXT_UMAR64: (regidx, regidx, regidx) -> bool effect {escape,rreg,wreg}
function PEXT_UMAR64 (rs2, rs1, rd) = {
  if sizeof(xlen) == 32
  then
    let rd0 = (rd >> 1) << 1 in
    let rd1 = rd0 + 1 in
    let rdcon : bits(64) = X(rd1) @ X(rd0) in
    let res : bits(64) = add_bits(rdcon, to_bits(64, unsigned(X(rs1)) * unsigned(X(rs2)))) in
    {X(rd0) = res[31..0]; X(rd1) = res[63..32];}
  else  
    X(rd) = X(rd) + to_bits(64, unsigned(rW(rs1, 1)) * unsigned(rW(rs2, 1))) + to_bits(64, unsigned(rW(rs1, 0)) * unsigned(rW(rs2, 0)));
  true
}

/* *****************************************************************/

val PEXT_UMSR64: (regidx, regidx, regidx) -> bool effect {escape,rreg,wreg}
function PEXT_UMSR64 (rs2, rs1, rd) = {
  if sizeof(xlen) == 32
  then
    let rd0 = (rd >> 1) << 1 in
    let rd1 = rd0 + 1 in
    let rdcon : bits(64) = X(rd1) @ X(rd0) in
    let res : bits(64) = sub_bits(rdcon, to_bits(64, unsigned(X(rs1)) * unsigned(X(rs2)))) in
    {X(rd0) = res[31..0]; X(rd1) = res[63..32];}
  else  
    X(rd) = X(rd) - to_bits(64, unsigned(rW(rs1, 1)) * unsigned(rW(rs2, 1))) - to_bits(64, unsigned(rW(rs1, 0)) * unsigned(rW(rs2, 0)));
  true
}

/* *****************************************************************/

val PEXT_KMAR64: (regidx, regidx, regidx) -> bool effect {escape,rreg,wreg}
function PEXT_KMAR64 (rs2, rs1, rd) = {
  if sizeof(xlen) == 32
  then
    let rd0 = (rd >> 1) << 1 in
    let rd1 = rd0 + 1 in
    let mul65 : bits(65) = EXTS(to_bits(64, signed(X(rs1)) * signed(X(rs2)))) in
    let top65 : bits(65) = EXTS(X(rd1) @ X(rd0)) in
    let res65 : bits(65) = mul65 + top65 in
    if res65 <_s (0b1 @ 0x8000000000000000) then {X(rd0) = 0x00000000; X(rd1) = 0x80000000; pext_write_OV (0b1);}
    else if (0b0 @ 0x7FFFFFFFFFFFFFFF) <_s res65  then {X(rd0) = 0xFFFFFFFF; X(rd1) = 0x7FFFFFFF; pext_write_OV (0b1);}
    else {X(rd0) = res65[31..0]; X(rd1) = res65[63..32];}
  else  
    let mula66 : bits(66) = EXTS(to_bits(64, signed(rW(rs1, 0)) * signed(rW(rs2, 0)))) in 
    let mulb66 : bits(66) = EXTS(to_bits(64, signed(rW(rs1, 1)) * signed(rW(rs2, 1)))) in
    let res66 : bits(66) = EXTS(X(rd)) + mula66 + mulb66 in
    if res66 <_s (0b11 @ 0x8000000000000000) then {X(rd) = 0x8000000000000000; pext_write_OV (0b1);}
    else if (0b00 @ 0x7FFFFFFFFFFFFFFF) <_s res66  then {X(rd) = 0x7FFFFFFFFFFFFFFF; pext_write_OV (0b1);}
    else X(rd) = res66[63..0];
  true
}

/* *****************************************************************/

val PEXT_UKMAR64: (regidx, regidx, regidx) -> bool effect {escape,rreg,wreg}
function PEXT_UKMAR64 (rs2, rs1, rd) = {
  if sizeof(xlen) == 32
  then
    let rd0 = (rd >> 1) << 1 in
    let rd1 = rd0 + 1 in
    let mul65 : bits(65) = EXTZ(to_bits(64, unsigned(X(rs1)) * unsigned(X(rs2)))) in
    let top65 : bits(65) = EXTZ(X(rd1) @ X(rd0)) in
    let res65 : bits(65) = mul65 + top65 in
    if (0b0 @ 0xFFFFFFFFFFFFFFFF) <_u res65  then {X(rd0) = 0xFFFFFFFF; X(rd1) = 0xFFFFFFFF; pext_write_OV (0b1);}
    else {X(rd0) = res65[31..0]; X(rd1) = res65[63..32];}
  else  
    let mula66 : bits(66) = EXTZ(to_bits(64, unsigned(rW(rs1, 0)) * unsigned(rW(rs2, 0)))) in 
    let mulb66 : bits(66) = EXTZ(to_bits(64, unsigned(rW(rs1, 1)) * unsigned(rW(rs2, 1)))) in
    let res66 : bits(66) = EXTZ(X(rd)) + mula66 + mulb66 in
    if (0b00 @ 0xFFFFFFFFFFFFFFFF) <_u res66  then {X(rd) = 0xFFFFFFFFFFFFFFFF; pext_write_OV (0b1);}
    else X(rd) = res66[63..0];
  true
}

/* *****************************************************************/

val PEXT_KMSR64: (regidx, regidx, regidx) -> bool effect {escape,rreg,wreg}
function PEXT_KMSR64 (rs2, rs1, rd) = {
  if sizeof(xlen) == 32
  then
    let rd0 = (rd >> 1) << 1 in
    let rd1 = rd0 + 1 in
    let mul65 : bits(65) = EXTS(to_bits(64, signed(X(rs1)) * signed(X(rs2)))) in
    let top65 : bits(65) = EXTS(X(rd1) @ X(rd0)) in
    let res65 : bits(65) = top65 - mul65 in
    if res65 <_s (0b1 @ 0x8000000000000000) then {X(rd0) = 0x00000000; X(rd1) = 0x80000000; pext_write_OV (0b1);}
    else if (0b0 @ 0x7FFFFFFFFFFFFFFF) <_s res65  then {X(rd0) = 0xFFFFFFFF; X(rd1) = 0x7FFFFFFF; pext_write_OV (0b1);}
    else {X(rd0) = res65[31..0]; X(rd1) = res65[63..32];}
  else  
    let mula66 : bits(66) = EXTS(to_bits(64, signed(rW(rs1, 0)) * signed(rW(rs2, 0)))) in 
    let mulb66 : bits(66) = EXTS(to_bits(64, signed(rW(rs1, 1)) * signed(rW(rs2, 1)))) in
    let res66 : bits(66) = EXTS(X(rd)) - mula66 - mulb66 in
    if res66 <_s (0b11 @ 0x8000000000000000) then {X(rd) = 0x8000000000000000; pext_write_OV (0b1);}
    else if (0b00 @ 0x7FFFFFFFFFFFFFFF) <_s res66  then {X(rd) = 0x7FFFFFFFFFFFFFFF; pext_write_OV (0b1);}
    else X(rd) = res66[63..0];
  true
}

/* *****************************************************************/

val PEXT_UKMSR64: (regidx, regidx, regidx) -> bool effect {escape,rreg,wreg}
function PEXT_UKMSR64 (rs2, rs1, rd) = {
  if sizeof(xlen) == 32
  then
    let rd0 = (rd >> 1) << 1 in
    let rd1 = rd0 + 1 in
    let mul65 : bits(65) = EXTZ(to_bits(64, unsigned(X(rs1)) * unsigned(X(rs2)))) in
    let top65 : bits(65) = EXTZ(X(rd1) @ X(rd0)) in
    let res65 : bits(65) = top65 - mul65 in
    if res65 <_s (0b0 @ 0x0000000000000000)  then {X(rd0) = 0x00000000; X(rd1) = 0x00000000; pext_write_OV (0b1);}
    else {X(rd0) = res65[31..0]; X(rd1) = res65[63..32];}
  else  
    let mula66 : bits(66) = EXTZ(to_bits(64, unsigned(rW(rs1, 0)) * unsigned(rW(rs2, 0)))) in 
    let mulb66 : bits(66) = EXTZ(to_bits(64, unsigned(rW(rs1, 1)) * unsigned(rW(rs2, 1)))) in
    let res66 : bits(66) = EXTZ(X(rd)) - mula66 - mulb66 in
    if res66 <_s (0b00 @ 0x0000000000000000)  then {X(rd) = 0x0000000000000000; pext_write_OV (0b1);}
    else X(rd) = res66[63..0];
  true
}