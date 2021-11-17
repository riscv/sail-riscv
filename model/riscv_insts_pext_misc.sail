/* *****************************************************************/
/* This file specifies the instruction added by the 'P' extension. */
/* *****************************************************************/

/* *****************************************************************/
/* ********************* auxiliary functions ***********************/
/* *****************************************************************/

val smin : forall 'n, 'n == 8 | 'n == 16 | 'n == 32.
  (bits('n), bits('n)) -> bits('n)
function smin (v1, v2) =
  if v1 <_s v2 then v1
  else v2

val umin : forall 'n, 'n == 8 | 'n == 16 | 'n == 32.
  (bits('n), bits('n)) -> bits('n)
function umin (v1, v2) =
  if v1 <_u v2 then v1
  else v2

val smax : forall 'n, 'n == 8 | 'n == 16 | 'n == 32.
  (bits('n), bits('n)) -> bits('n)
function smax (v1, v2) =
  if v2 <_s v1 then v1
  else v2

val umax : forall 'n, 'n == 8 | 'n == 16 | 'n == 32.
  (bits('n), bits('n)) -> bits('n)
function umax (v1, v2) =
  if v2 <_u v1 then v1
  else v2

val sclip : forall 'n, 'n == 8 | 'n == 16 | 'n == 32.
  (bits('n), byte) -> bits('n) effect {rreg, wreg}
function sclip (v, m) =
  let ub : bits('n) = ((zeros('n) + 1) << m) - 1 in
  let lb : bits('n) = not_vec (ub) in
  if v <_s lb then { pext_write_OV (0b1); lb }
  else if ub <_s v then { pext_write_OV (0b1); ub }
  else v

val uclip : forall 'n, 'n == 8 | 'n == 16 | 'n == 32.
  (bits('n), byte) -> bits('n) effect {rreg, wreg}
function uclip (v, m) =
  let ub : bits('n) = ((zeros('n) + 1) << m) - 1 in
  let lb : bits('n) = zeros('n) in
  if ub <_s v then { pext_write_OV (0b1); ub }
  else if v <_s lb then { pext_write_OV (0b1); lb }
  else v

val kabs : forall 'n, 'n == 8 | 'n == 16 | 'n == 32.
  (bits('n)) -> bits('n) effect {rreg, wreg}
function kabs (v) =
  let lb : bits('n) = not_vec( sail_ones ('n) >> 1) in
  if v == lb then { pext_write_OV (0b1); not_vec(lb) }
  else if v <_s zeros('n) then { pext_write_OV (0b1); not_vec(v) + 1 }
  else v

val clrs : forall 'n, 'n == 8 | 'n == 16 | 'n == 32.
  (bits('n)) -> bits('n)
function clrs (v) = {
  var vpos : bits(32) = if v <_s zeros('n) then not_vec(EXTS(v)) else EXTZ(v);
  if vpos == zeros(32) then to_bits('n, 'n - 1)
  else {
  var cnt : bits('n) = zeros('n);
  if vpos[31..16] == 0x0000 then { cnt = cnt + 16; vpos = vpos << 16 };
  if vpos[31..24] == 0x00   then { cnt = cnt + 8;  vpos = vpos << 8 };
  if vpos[31..28] == 0x0    then { cnt = cnt + 4;  vpos = vpos << 4 };
  if vpos[31..30] == 0b00   then { cnt = cnt + 2;  vpos = vpos << 2 };
  if vpos[31..31] == 0b0    then { cnt = cnt + 1 };
  cnt = cnt + 'n - 33; cnt } }

val clz : forall 'n, 'n == 8 | 'n == 16 | 'n == 32.
  (bits('n)) -> bits('n)
function clz (v) = {
  var vext : bits(32) = EXTZ(v);
  if vext == zeros(32) then to_bits('n, 'n)
  else {
  var cnt : bits('n) = zeros('n);
  if vext[31..16] == 0x0000 then { cnt = cnt + 16; vext = vext << 16 };
  if vext[31..24] == 0x00   then { cnt = cnt + 8;  vext = vext << 8 };
  if vext[31..28] == 0x0    then { cnt = cnt + 4;  vext = vext << 4 };
  if vext[31..30] == 0b00   then { cnt = cnt + 2;  vext = vext << 2 };
  if vext[31..31] == 0b0    then { cnt = cnt + 1 };
  cnt = cnt + 'n - 32; cnt } }

val clo : forall 'n, 'n == 8 | 'n == 16 | 'n == 32.
  (bits('n)) -> bits('n)
function clo (v) = {
  var vcpl : bits(32) = not_vec(EXTZ(not_vec(v)));
  if vcpl == ones(32) then to_bits('n, 'n)
  else {
  var cnt : bits('n) = zeros('n);
  if vcpl[31..16] == 0xFFFF then { cnt = cnt + 16; vcpl = vcpl << 16 };
  if vcpl[31..24] == 0xFF   then { cnt = cnt + 8;  vcpl = vcpl << 8 };
  if vcpl[31..28] == 0xF    then { cnt = cnt + 4;  vcpl = vcpl << 4 };
  if vcpl[31..30] == 0b11   then { cnt = cnt + 2;  vcpl = vcpl << 2 };
  if vcpl[31..31] == 0b1    then { cnt = cnt + 1 };
  cnt = cnt + 'n - 32; cnt } }

val pbsad32 : forall 'n, 'n == 8.
  (bits('n), bits('n)) -> bits(32)
function pbsad32 (v1, v2) =
  let v1ext : bits(9) = EXTZ(v1) in
  let v2ext : bits(9) = EXTZ(v2) in
  let pos : bits(32) = EXTS (v1ext - v2ext) in
  if pos <_s zeros(32) then not_vec(pos) + 1 else pos

val pbsad64 : forall 'n, 'n == 8.
  (bits('n), bits('n)) -> bits(64)
function pbsad64 (v1, v2) =
  let v1ext : bits(9) = EXTZ(v1) in
  let v2ext : bits(9) = EXTZ(v2) in
  let pos : bits(64) = EXTS (v1ext - v2ext) in
  if pos <_s zeros(64) then not_vec(pos) + 1 else pos

val bitrev32 :
  (bits(32)) -> bits(32)
function bitrev32 (v) = {
  var tmp : bits(64) = 0x0000 @ v @ 0x0000;
  tmp = 0x0000 @ ((tmp[48..17] & 0x55555555) | (tmp[46..15] & 0xAAAAAAAA)) @ 0x0000;
  tmp = 0x0000 @ ((tmp[49..18] & 0x33333333) | (tmp[45..14] & 0xCCCCCCCC)) @ 0x0000;
  tmp = 0x0000 @ ((tmp[51..20] & 0x0F0F0F0F) | (tmp[43..12] & 0xF0F0F0F0)) @ 0x0000;
  tmp = 0x0000 @ ((tmp[55..24] & 0x00FF00FF) | (tmp[39..8]  & 0xFF00FF00)) @ 0x0000;
  ((tmp[63..32] & 0x0000FFFF) | (tmp[31..0]  & 0xFFFF0000))
}

val bitrev64 :
  (bits(64)) -> bits(64)
function bitrev64 (v) = {
  var tmp : bits(128) = 0x00000000 @ v @ 0x00000000;
  tmp = 0x00000000 @ ((tmp[96..33]  & 0x5555555555555555) | (tmp[94..31] & 0xAAAAAAAAAAAAAAAA)) @ 0x00000000;
  tmp = 0x00000000 @ ((tmp[97..34]  & 0x3333333333333333) | (tmp[93..30] & 0xCCCCCCCCCCCCCCCC)) @ 0x00000000;
  tmp = 0x00000000 @ ((tmp[99..36]  & 0x0F0F0F0F0F0F0F0F) | (tmp[91..28] & 0xF0F0F0F0F0F0F0F0)) @ 0x00000000;
  tmp = 0x00000000 @ ((tmp[103..40] & 0x00FF00FF00FF00FF) | (tmp[87..24] & 0xFF00FF00FF00FF00)) @ 0x00000000;
  tmp = 0x00000000 @ ((tmp[111..48] & 0x0000FFFF0000FFFF) | (tmp[79..16] & 0xFFFF0000FFFF0000)) @ 0x00000000;
  ((tmp[127..64] & 0x00000000FFFFFFFF) | (tmp[63..0]  & 0xFFFFFFFF00000000))
}

val insb :
  (byte, byte, bits(64)) -> bits(64)
function insb (vbyte, vbpos, vrd) = {
  let insbyte : bits(64) = (0x00000000000000 @ vbyte) << (vbpos << 3) in
  let mask : bits(64) = not_vec((0x00000000000000FF) << (vbpos << 3)) in
  (vrd & mask) + insbyte
}

/* *****************************************************************/

val PEXT_SMIN8 : (regidx, regidx, regidx) -> bool effect {escape,rreg,wreg}
function PEXT_SMIN8(rs2, rs1, rd) = {
  let result : xlenbits =
  if sizeof(xlen) == 32
  then smin (rB(rs1, 3), rB(rs2, 3)) @ smin (rB(rs1, 2), rB(rs2, 2)) @
       smin (rB(rs1, 1), rB(rs2, 1)) @ smin (rB(rs1, 0), rB(rs2, 0))
  else smin (rB(rs1, 7), rB(rs2, 7)) @ smin (rB(rs1, 6), rB(rs2, 6)) @
       smin (rB(rs1, 5), rB(rs2, 5)) @ smin (rB(rs1, 4), rB(rs2, 4)) @
       smin (rB(rs1, 3), rB(rs2, 3)) @ smin (rB(rs1, 2), rB(rs2, 2)) @
       smin (rB(rs1, 1), rB(rs2, 1)) @ smin (rB(rs1, 0), rB(rs2, 0));
  X(rd) = result;
  true
}

/* *****************************************************************/

val PEXT_UMIN8 : (regidx, regidx, regidx) -> bool effect {escape,rreg,wreg}
function PEXT_UMIN8(rs2, rs1, rd) = {
  let result : xlenbits =
  if sizeof(xlen) == 32
  then umin (rB(rs1, 3), rB(rs2, 3)) @ umin (rB(rs1, 2), rB(rs2, 2)) @
       umin (rB(rs1, 1), rB(rs2, 1)) @ umin (rB(rs1, 0), rB(rs2, 0))
  else umin (rB(rs1, 7), rB(rs2, 7)) @ umin (rB(rs1, 6), rB(rs2, 6)) @
       umin (rB(rs1, 5), rB(rs2, 5)) @ umin (rB(rs1, 4), rB(rs2, 4)) @
       umin (rB(rs1, 3), rB(rs2, 3)) @ umin (rB(rs1, 2), rB(rs2, 2)) @
       umin (rB(rs1, 1), rB(rs2, 1)) @ umin (rB(rs1, 0), rB(rs2, 0));
  X(rd) = result;
  true
}

/* *****************************************************************/

val PEXT_SMAX8 : (regidx, regidx, regidx) -> bool effect {escape,rreg,wreg}
function PEXT_SMAX8(rs2, rs1, rd) = {
  let result : xlenbits =
  if sizeof(xlen) == 32
  then smax (rB(rs1, 3), rB(rs2, 3)) @ smax (rB(rs1, 2), rB(rs2, 2)) @
       smax (rB(rs1, 1), rB(rs2, 1)) @ smax (rB(rs1, 0), rB(rs2, 0))
  else smax (rB(rs1, 7), rB(rs2, 7)) @ smax (rB(rs1, 6), rB(rs2, 6)) @
       smax (rB(rs1, 5), rB(rs2, 5)) @ smax (rB(rs1, 4), rB(rs2, 4)) @
       smax (rB(rs1, 3), rB(rs2, 3)) @ smax (rB(rs1, 2), rB(rs2, 2)) @
       smax (rB(rs1, 1), rB(rs2, 1)) @ smax (rB(rs1, 0), rB(rs2, 0));
  X(rd) = result;
  true
}

/* *****************************************************************/

val PEXT_UMAX8 : (regidx, regidx, regidx) -> bool effect {escape,rreg,wreg}
function PEXT_UMAX8(rs2, rs1, rd) = {
  let result : xlenbits =
  if sizeof(xlen) == 32
  then umax (rB(rs1, 3), rB(rs2, 3)) @ umax (rB(rs1, 2), rB(rs2, 2)) @
       umax (rB(rs1, 1), rB(rs2, 1)) @ umax (rB(rs1, 0), rB(rs2, 0))
  else umax (rB(rs1, 7), rB(rs2, 7)) @ umax (rB(rs1, 6), rB(rs2, 6)) @
       umax (rB(rs1, 5), rB(rs2, 5)) @ umax (rB(rs1, 4), rB(rs2, 4)) @
       umax (rB(rs1, 3), rB(rs2, 3)) @ umax (rB(rs1, 2), rB(rs2, 2)) @
       umax (rB(rs1, 1), rB(rs2, 1)) @ umax (rB(rs1, 0), rB(rs2, 0));
  X(rd) = result;
  true
}

/* *****************************************************************/

val PEXT_SCLIP8 : (bits(3), regidx, regidx) -> bool effect {escape,rreg,wreg}
function PEXT_SCLIP8(imm3, rs1, rd) = {
  let sa : byte = EXTZ(imm3);
  let result : xlenbits =
  if sizeof(xlen) == 32
  then sclip (rB(rs1, 3), sa) @ sclip (rB(rs1, 2), sa) @
       sclip (rB(rs1, 1), sa) @ sclip (rB(rs1, 0), sa)
  else sclip (rB(rs1, 7), sa) @ sclip (rB(rs1, 6), sa) @
       sclip (rB(rs1, 5), sa) @ sclip (rB(rs1, 4), sa) @
       sclip (rB(rs1, 3), sa) @ sclip (rB(rs1, 2), sa) @
       sclip (rB(rs1, 1), sa) @ sclip (rB(rs1, 0), sa);
  X(rd) = result;
  true
}

/* *****************************************************************/

val PEXT_UCLIP8 : (bits(3), regidx, regidx) -> bool effect {escape,rreg,wreg}
function PEXT_UCLIP8(imm3, rs1, rd) = {
let sa : byte = EXTZ(imm3);
let result : xlenbits =
  if sizeof(xlen) == 32
  then uclip (rB(rs1, 3), sa) @ uclip (rB(rs1, 2), sa) @
       uclip (rB(rs1, 1), sa) @ uclip (rB(rs1, 0), sa)
  else uclip (rB(rs1, 7), sa) @ uclip (rB(rs1, 6), sa) @
       uclip (rB(rs1, 5), sa) @ uclip (rB(rs1, 4), sa) @
       uclip (rB(rs1, 3), sa) @ uclip (rB(rs1, 2), sa) @
       uclip (rB(rs1, 1), sa) @ uclip (rB(rs1, 0), sa);
  X(rd) = result;
  true
}

/* *****************************************************************/

val PEXT_KABS8 : (regidx, regidx) -> bool effect {escape,rreg,wreg}
function PEXT_KABS8(rs1, rd) = {
  let result : xlenbits =
  if sizeof(xlen) == 32
  then kabs (rB(rs1, 3)) @ kabs (rB(rs1, 2)) @
       kabs (rB(rs1, 1)) @ kabs (rB(rs1, 0))
  else kabs (rB(rs1, 7)) @ kabs (rB(rs1, 6)) @
       kabs (rB(rs1, 5)) @ kabs (rB(rs1, 4)) @
       kabs (rB(rs1, 3)) @ kabs (rB(rs1, 2)) @
       kabs (rB(rs1, 1)) @ kabs (rB(rs1, 0));
  X(rd) = result;
  true
}

/* *****************************************************************/

val PEXT_CLRS8 : (regidx, regidx) -> bool effect {escape,rreg,wreg}
function PEXT_CLRS8(rs1, rd) = {
  let result : xlenbits =
  if sizeof(xlen) == 32
  then clrs (rB(rs1, 3)) @ clrs (rB(rs1, 2)) @
       clrs (rB(rs1, 1)) @ clrs (rB(rs1, 0))
  else clrs (rB(rs1, 7)) @ clrs (rB(rs1, 6)) @
       clrs (rB(rs1, 5)) @ clrs (rB(rs1, 4)) @
       clrs (rB(rs1, 3)) @ clrs (rB(rs1, 2)) @
       clrs (rB(rs1, 1)) @ clrs (rB(rs1, 0));
  X(rd) = result;
  true
}

/* *****************************************************************/

val PEXT_CLZ8 : (regidx, regidx) -> bool effect {escape,rreg,wreg}
function PEXT_CLZ8(rs1, rd) = {
  let result : xlenbits =
  if sizeof(xlen) == 32
  then clz (rB(rs1, 3)) @ clz (rB(rs1, 2)) @
       clz (rB(rs1, 1)) @ clz (rB(rs1, 0))
  else clz (rB(rs1, 7)) @ clz (rB(rs1, 6)) @
       clz (rB(rs1, 5)) @ clz (rB(rs1, 4)) @
       clz (rB(rs1, 3)) @ clz (rB(rs1, 2)) @
       clz (rB(rs1, 1)) @ clz (rB(rs1, 0));
  X(rd) = result;
  true
}

/* *****************************************************************/

val PEXT_CLO8 : (regidx, regidx) -> bool effect {escape,rreg,wreg}
function PEXT_CLO8(rs1, rd) = {
  let result : xlenbits =
  if sizeof(xlen) == 32
  then clo (rB(rs1, 3)) @ clo (rB(rs1, 2)) @
       clo (rB(rs1, 1)) @ clo (rB(rs1, 0))
  else clo (rB(rs1, 7)) @ clo (rB(rs1, 6)) @
       clo (rB(rs1, 5)) @ clo (rB(rs1, 4)) @
       clo (rB(rs1, 3)) @ clo (rB(rs1, 2)) @
       clo (rB(rs1, 1)) @ clo (rB(rs1, 0));
  X(rd) = result;
  true
}

/* *****************************************************************/

val PEXT_SWAP8 : (regidx, regidx) -> bool effect {escape,rreg,wreg}
function PEXT_SWAP8(rs1, rd) = {
  let result : xlenbits =
  if sizeof(xlen) == 32
  then rB(rs1, 2) @ rB(rs1, 3) @
       rB(rs1, 0) @ rB(rs1, 1)
  else rB(rs1, 6) @ rB(rs1, 7) @
       rB(rs1, 4) @ rB(rs1, 5) @
       rB(rs1, 2) @ rB(rs1, 3) @
       rB(rs1, 0) @ rB(rs1, 1);
  X(rd) = result;
  true
}

/* *****************************************************************/

val PEXT_SMIN16 : (regidx, regidx, regidx) -> bool effect {escape,rreg,wreg}
function PEXT_SMIN16(rs2, rs1, rd) = {
  let result : xlenbits =
  if sizeof(xlen) == 32
  then smin (rH(rs1, 1), rH(rs2, 1)) @ smin (rH(rs1, 0), rH(rs2, 0))
  else smin (rH(rs1, 3), rH(rs2, 3)) @ smin (rH(rs1, 2), rH(rs2, 2)) @
       smin (rH(rs1, 1), rH(rs2, 1)) @ smin (rH(rs1, 0), rH(rs2, 0));
  X(rd) = result;
  true
}

/* *****************************************************************/

val PEXT_UMIN16 : (regidx, regidx, regidx) -> bool effect {escape,rreg,wreg}
function PEXT_UMIN16(rs2, rs1, rd) = {
  let result : xlenbits =
  if sizeof(xlen) == 32
  then umin (rH(rs1, 1), rH(rs2, 1)) @ umin (rH(rs1, 0), rH(rs2, 0))
  else umin (rH(rs1, 3), rH(rs2, 3)) @ umin (rH(rs1, 2), rH(rs2, 2)) @
       umin (rH(rs1, 1), rH(rs2, 1)) @ umin (rH(rs1, 0), rH(rs2, 0));
  X(rd) = result;
  true
}

/* *****************************************************************/

val PEXT_SMAX16 : (regidx, regidx, regidx) -> bool effect {escape,rreg,wreg}
function PEXT_SMAX16(rs2, rs1, rd) = {
  let result : xlenbits =
  if sizeof(xlen) == 32
  then smax (rH(rs1, 1), rH(rs2, 1)) @ smax (rH(rs1, 0), rH(rs2, 0))
  else smax (rH(rs1, 3), rH(rs2, 3)) @ smax (rH(rs1, 2), rH(rs2, 2)) @
       smax (rH(rs1, 1), rH(rs2, 1)) @ smax (rH(rs1, 0), rH(rs2, 0));
  X(rd) = result;
  true
}

/* *****************************************************************/

val PEXT_UMAX16 : (regidx, regidx, regidx) -> bool effect {escape,rreg,wreg}
function PEXT_UMAX16(rs2, rs1, rd) = {
  let result : xlenbits =
  if sizeof(xlen) == 32
  then umax (rH(rs1, 1), rH(rs2, 1)) @ umax (rH(rs1, 0), rH(rs2, 0))
  else umax (rH(rs1, 3), rH(rs2, 3)) @ umax (rH(rs1, 2), rH(rs2, 2)) @
       umax (rH(rs1, 1), rH(rs2, 1)) @ umax (rH(rs1, 0), rH(rs2, 0));
  X(rd) = result;
  true
}

/* *****************************************************************/

val PEXT_SCLIP16 : (bits(4), regidx, regidx) -> bool effect {escape,rreg,wreg}
function PEXT_SCLIP16(imm4, rs1, rd) = {
  let sa : byte = EXTZ(imm4);
  let result : xlenbits =
  if sizeof(xlen) == 32
  then sclip (rH(rs1, 1), sa) @ sclip (rH(rs1, 0), sa)
  else sclip (rH(rs1, 3), sa) @ sclip (rH(rs1, 2), sa) @
       sclip (rH(rs1, 1), sa) @ sclip (rH(rs1, 0), sa);
  X(rd) = result;
  true
}

/* *****************************************************************/

val PEXT_UCLIP16 : (bits(4), regidx, regidx) -> bool effect {escape,rreg,wreg}
function PEXT_UCLIP16(imm4, rs1, rd) = {
  let sa : byte = EXTZ(imm4);
  let result : xlenbits =
  if sizeof(xlen) == 32
  then uclip (rH(rs1, 1), sa) @ uclip (rH(rs1, 0), sa)
  else uclip (rH(rs1, 3), sa) @ uclip (rH(rs1, 2), sa) @
       uclip (rH(rs1, 1), sa) @ uclip (rH(rs1, 0), sa);
  X(rd) = result;
  true
}

/* *****************************************************************/

val PEXT_KABS16 : (regidx, regidx) -> bool effect {escape,rreg,wreg}
function PEXT_KABS16(rs1, rd) = {
  let result : xlenbits =
  if sizeof(xlen) == 32
  then kabs (rH(rs1, 1)) @ kabs (rH(rs1, 0))
  else kabs (rH(rs1, 3)) @ kabs (rH(rs1, 2)) @
       kabs (rH(rs1, 1)) @ kabs (rH(rs1, 0));
  X(rd) = result;
  true
}

/* *****************************************************************/

val PEXT_CLRS16 : (regidx, regidx) -> bool effect {escape,rreg,wreg}
function PEXT_CLRS16(rs1, rd) = {
  let result : xlenbits =
  if sizeof(xlen) == 32
  then clrs (rH(rs1, 1)) @ clrs (rH(rs1, 0))
  else clrs (rH(rs1, 3)) @ clrs (rH(rs1, 2)) @
       clrs (rH(rs1, 1)) @ clrs (rH(rs1, 0));
  X(rd) = result;
  true
}

/* *****************************************************************/

val PEXT_CLZ16 : (regidx, regidx) -> bool effect {escape,rreg,wreg}
function PEXT_CLZ16(rs1, rd) = {
  let result : xlenbits =
  if sizeof(xlen) == 32
  then clz (rH(rs1, 1)) @ clz (rH(rs1, 0))
  else clz (rH(rs1, 3)) @ clz (rH(rs1, 2)) @
       clz (rH(rs1, 1)) @ clz (rH(rs1, 0));
  X(rd) = result;
  true
}

/* *****************************************************************/

val PEXT_CLO16 : (regidx, regidx) -> bool effect {escape,rreg,wreg}
function PEXT_CLO16(rs1, rd) = {
  let result : xlenbits =
  if sizeof(xlen) == 32
  then clo (rH(rs1, 1)) @ clo (rH(rs1, 0))
  else clo (rH(rs1, 3)) @ clo (rH(rs1, 2)) @
       clo (rH(rs1, 1)) @ clo (rH(rs1, 0));
  X(rd) = result;
  true
}

/* *****************************************************************/

val PEXT_SCLIP32 : (bits(5), regidx, regidx) -> bool effect {escape,rreg,wreg}
function PEXT_SCLIP32(imm5, rs1, rd) = {
  let sa : byte = EXTZ(imm5);
  let result : xlenbits =
  if sizeof(xlen) == 32
  then sclip (rW(rs1, 0), sa)
  else sclip (rW(rs1, 1), sa) @ sclip (rW(rs1, 0), sa);
  X(rd) = result;
  true
}

/* *****************************************************************/

val PEXT_UCLIP32 : (bits(5), regidx, regidx) -> bool effect {escape,rreg,wreg}
function PEXT_UCLIP32(imm5, rs1, rd) = {
  let sa : byte = EXTZ(imm5);
  let result : xlenbits =
  if sizeof(xlen) == 32
  then uclip (rW(rs1, 0), sa)
  else uclip (rW(rs1, 1), sa) @ uclip (rW(rs1, 0), sa);
  X(rd) = result;
  true
}

/* *****************************************************************/

val PEXT_CLRS32 : (regidx, regidx) -> bool effect {escape,rreg,wreg}
function PEXT_CLRS32(rs1, rd) = {
  let result : xlenbits =
  if sizeof(xlen) == 32
  then clrs (rW(rs1, 0))
  else clrs (rW(rs1, 1)) @ clrs (rW(rs1, 0));
  X(rd) = result;
  true
}

/* *****************************************************************/

val PEXT_CLZ32 : (regidx, regidx) -> bool effect {escape,rreg,wreg}
function PEXT_CLZ32(rs1, rd) = {
  let result : xlenbits =
  if sizeof(xlen) == 32
  then clz (rW(rs1, 0))
  else clz (rW(rs1, 1)) @ clz (rW(rs1, 0));
  X(rd) = result;
  true
}

/* *****************************************************************/

val PEXT_CLO32 : (regidx, regidx) -> bool effect {escape,rreg,wreg}
function PEXT_CLO32(rs1, rd) = {
  let result : xlenbits =
  if sizeof(xlen) == 32
  then clo (rW(rs1, 0))
  else clo (rW(rs1, 1)) @ clo (rW(rs1, 0));
  X(rd) = result;
  true
}

/* *****************************************************************/

val PEXT_PBSAD : (regidx, regidx, regidx) -> bool effect {escape,rreg,wreg}
function PEXT_PBSAD(rs2, rs1, rd) = {
  let result : xlenbits =
  if sizeof(xlen) == 32
  then pbsad32 (rB(rs1, 3), rB(rs2, 3)) + pbsad32 (rB(rs1, 2), rB(rs2, 2)) +
       pbsad32 (rB(rs1, 1), rB(rs2, 1)) + pbsad32 (rB(rs1, 0), rB(rs2, 0))
  else pbsad64 (rB(rs1, 7), rB(rs2, 7)) + pbsad64 (rB(rs1, 6), rB(rs2, 6)) +
       pbsad64 (rB(rs1, 5), rB(rs2, 5)) + pbsad64 (rB(rs1, 4), rB(rs2, 4)) +
       pbsad64 (rB(rs1, 3), rB(rs2, 3)) + pbsad64 (rB(rs1, 2), rB(rs2, 2)) +
       pbsad64 (rB(rs1, 1), rB(rs2, 1)) + pbsad64 (rB(rs1, 0), rB(rs2, 0));
  X(rd) = result;
  true
}

/* *****************************************************************/

val PEXT_PBSADA : (regidx, regidx, regidx) -> bool effect {escape,rreg,wreg}
function PEXT_PBSADA(rs2, rs1, rd) = {
  let result : xlenbits =
  if sizeof(xlen) == 32
  then pbsad32 (rB(rs1, 3), rB(rs2, 3)) + pbsad32 (rB(rs1, 2), rB(rs2, 2)) +
       pbsad32 (rB(rs1, 1), rB(rs2, 1)) + pbsad32 (rB(rs1, 0), rB(rs2, 0))
  else pbsad64 (rB(rs1, 7), rB(rs2, 7)) + pbsad64 (rB(rs1, 6), rB(rs2, 6)) +
       pbsad64 (rB(rs1, 5), rB(rs2, 5)) + pbsad64 (rB(rs1, 4), rB(rs2, 4)) +
       pbsad64 (rB(rs1, 3), rB(rs2, 3)) + pbsad64 (rB(rs1, 2), rB(rs2, 2)) +
       pbsad64 (rB(rs1, 1), rB(rs2, 1)) + pbsad64 (rB(rs1, 0), rB(rs2, 0));
  X(rd) = X(rd) + result;
  true
}

/* *****************************************************************/

val PEXT_AVE : (regidx, regidx, regidx) -> bool effect {escape,rreg,wreg}
function PEXT_AVE(rs2, rs1, rd) = {
  if sizeof(xlen) == 32
  then {
    let result : bits(xlen + 1) = EXTS(rW(rs1, 0)) + EXTS(rW(rs2, 0)) + EXTS(0x1);
    X(rd) = result[32..1];
  } else {
    let result : bits(xlen + 1) = EXTS(rD(rs1)) + EXTS(rD(rs2)) + EXTS(0x1);
    X(rd) = result[64..1];
  };
  true
}

/* *****************************************************************/

val PEXT_SRA_U : (regidx, regidx, regidx) -> bool effect {escape,rreg,wreg}
function PEXT_SRA_U(rs2, rs1, rd) = {
  let result : xlenbits =
    if sizeof(xlen) == 32
    then
    let sa : byte = 0b000 @ X(rs2)[4..0] in
    if  (sa == 0x00)
    then  X(rs1)
    else  (add_bits(shift_right_arith (rW(rs1, 0) @ 0b0, sa), 0b0 @ 0x00000001))[32..1]
    else
    let sa : byte = 0b00 @ X(rs2)[5..0] in
    if  (sa == 0x00)
    then  X(rs1)
    else  (add_bits(shift_right_arith (rD(rs1) @ 0b0, sa), 0b0 @ 0x0000000000000001))[64..1];
  X(rd) = result;
  true
}

/* *****************************************************************/

val PEXT_SRAI_U : (bits(6), regidx, regidx) -> bool effect {escape,rreg,wreg}
function PEXT_SRAI_U (imm6, rs1, rd) = {
  let sa : byte = EXTZ(imm6);
  let result : xlenbits =
    if sizeof(xlen) == 32
    then
    if  (sa == 0x00)
    then  X(rs1)
    else  (add_bits(shift_right_arith (rW(rs1, 0) @ 0b0, sa), 0b0 @ 0x00000001))[32..1]
    else
    if  (sa == 0x00)
    then  X(rs1)
    else  (add_bits(shift_right_arith (rD(rs1) @ 0b0, sa), 0b0 @ 0x0000000000000001))[64..1];
  X(rd) = result;
  true
}

/* *****************************************************************/

val PEXT_BITREV : (regidx, regidx, regidx) -> bool effect {escape,rreg,wreg}
function PEXT_BITREV(rs2, rs1, rd) = {
  if sizeof(xlen) == 32
  then {
    let msb : byte = EXTZ(rB(rs2, 0)[4..0]);
    X(rd) = shift_right_logic(bitrev32(rW(rs1, 0)), 0x1F - msb);
  } else {
    let msb : byte = EXTZ(rB(rs2, 0)[5..0]);
    X(rd) = shift_right_logic(bitrev64(rD(rs1)), 0x3F - msb);
  };
  true
}

/* *****************************************************************/

val PEXT_BITREVI : (bits(6), regidx, regidx) -> bool effect {escape,rreg,wreg}
function PEXT_BITREVI(imm6, rs1, rd) = {
  let msb : byte = EXTZ(imm6) in
  if sizeof(xlen) == 32
  then {
    X(rd) = shift_right_logic(bitrev32(rW(rs1, 0)), 0x1F - msb);
  } else {
    X(rd) = shift_right_logic(bitrev64(rD(rs1)), 0x3F - msb);
  };
  true
}

/* *****************************************************************/

val PEXT_WEXT : (regidx, regidx, regidx) -> bool effect {escape,rreg,wreg}
function PEXT_WEXT(rs2, rs1, rd) = {
  let rs10 = (rs1 >> 1) << 1 in
  let rs11 = rs10 + 1 in
  if sizeof(xlen) == 32
  then {
    let lsb : byte = EXTZ(rB(rs2, 0)[4..0]);
    X(rd) = shift_right_logic(X(rs11) @ X(rs10), lsb)[31..0];
  } else {
    let lsb : byte = EXTZ(rB(rs2, 0)[4..0]);
    X(rd) = EXTS(shift_right_logic(rD(rs1), lsb)[31..0]);
  };
  true
}

/* *****************************************************************/

val PEXT_WEXTI : (bits(5), regidx, regidx) -> bool effect {escape,rreg,wreg}
function PEXT_WEXTI(imm5, rs1, rd) = {
  let lsb : byte = EXTZ(imm5) in
  let rs10 = (rs1 >> 1) << 1 in
  let rs11 = rs10 + 1 in
  if sizeof(xlen) == 32
  then {
    X(rd) = shift_right_logic(X(rs11) @ X(rs10), lsb)[31..0];
  } else {
    X(rd) = EXTS(shift_right_logic(rD(rs1), lsb)[31..0]);
  };
  true
}

/* *****************************************************************/

val PEXT_BPICK : (regidx, regidx, regidx, regidx) -> bool effect {escape,rreg,wreg}
function PEXT_BPICK(rs3, rs2, rs1, rd) = {
  if sizeof(xlen) == 32
  then {
    X(rd) = rW(rs1, 0) & rW(rs3, 0) | rW(rs2, 0) & not_vec(rW(rs3, 0));
  } else {
    X(rd) = rD(rs1) & rD(rs3) | rD(rs2) & not_vec(rD(rs3));
  };
  true
}

/* *****************************************************************/

val PEXT_INSB : (bits(3), regidx, regidx) -> bool effect {escape,rreg,wreg}
function PEXT_INSB(imm3, rs1, rd) = {
  let bpos : byte = EXTZ(imm3) in
  if sizeof(xlen) == 32
  then {
    X(rd) = insb(rB(rs1, 0), bpos, 0x00000000 @ rW(rd, 0))[31..0];
  } else {
    X(rd) = insb(rB(rs1, 0), bpos, rD(rd));
  };
  true
}

/* *****************************************************************/

val PEXT_MADDR32 : (regidx, regidx, regidx) -> bool effect {escape,rreg,wreg}
function PEXT_MADDR32(rs2, rs1, rd) = {
  if sizeof(xlen) == 32
  then {
    X(rd) = rW(rd, 0) + smul(rW(rs1, 0), rW(rs2, 0))[31..0];
  } else {
    X(rd) = EXTS(rW(rd, 0) + smul(rW(rs1, 0), rW(rs2, 0))[31..0]);
  };
  true
}

/* *****************************************************************/
