/* Programming Langauge Lab, Department of Computer Science, National Tsing-Hua University, Taiwan */
/* Academia Sinica, Taiwan*/
/* Andes Technology Corporation, Taiwan*/

/* *****************************************************************/
/* This file specifies the instruction added by the 'P' extension. */
/* *****************************************************************/

/* *****************************************************************/
/************************ additional types *************************/
/* *****************************************************************/

type byte = bits(8)
type dword = bits(64)

let PEXT_SIG = 0b1110111

/* *****************************************************************/
/* ************************* shorthands ****************************/
/* *****************************************************************/

val rB : forall 'sidx,
  (0 <= 'sidx & 'sidx < xlen_bytes).
  (regidx, int('sidx)) -> byte effect {escape, rreg}

function rB (ridx, sidx) = slice (X(ridx), 8 * sidx, 8)

val rH : forall 'sidx,
  (0 <= 'sidx & 2 * 'sidx < xlen_bytes).
  (regidx, int('sidx)) -> half effect {escape, rreg}

function rH (ridx, sidx) = slice (X(ridx), sidx * 16, 16)

val rW : forall 'sidx,
  (0 <= 'sidx & 4 * 'sidx < xlen_bytes).
  (regidx, int('sidx)) -> word effect {escape, rreg}

function rW (ridx, sidx) = slice (X(ridx), sidx * 32, 32)

val rD : regidx -> dword effect {escape, rreg}

function rD (ridx) =
  if sizeof (xlen) == 32 then
    X(ridx | 0b00001) @ X(ridx & 0b11110)
  else
    X(ridx)

val set_rD : (regidx, bits (64)) -> unit effect {escape, wreg}

function set_rD (ridx, value) =
  if sizeof (xlen) == 32 then
    { X(ridx & 0b11110) = slice (value,  0, 32);
      X(ridx | 0b00001) = slice (value, 32, 32) }
  else
    X(ridx) = value

mapping pext_width_mnemonic : word_width <-> string = {
    BYTE <->  "8",
    HALF <-> "16",
    WORD <-> "32",
  DOUBLE <-> "64"
}
