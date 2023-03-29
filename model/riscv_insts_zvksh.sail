/*
 * Vector Cryptography Extension - ShangMi Suite: SM3 Secure Hash
 * ----------------------------------------------------------------------
 */

/*
 * Helper functions.
 * ----------------------------------------------------------------------
 */

val	 rol32 : forall 'm, 32 - 'm >= 0 & 'm >= 0. (bits(32), int('m)) -> bits(32)
function rol32(X,N) = (X << N) | (X >> (32 - N))

val	 P0  : forall 'm, 'm == 32. (bits('m)) -> bits('m)
function P0(X) = ((X) ^ rol32((X),  9) ^ rol32((X), 17))

val	 P1 : forall 'm, 'm == 32. (bits('m)) -> bits('m)
function P1(X) = ((X) ^ rol32((X), 15) ^ rol32((X), 23))

val	 ZVKSH_W : forall 'm, 'm == 32. (bits('m), bits('m), bits('m), bits('m), bits('m)) -> bits('m)
function ZVKSH_W(M16, M9, M3, M13, M6) =
  (P1(M16 ^ M9 ^ rol32(M3, 15)) ^ rol32(M13, 7) ^ M6)

val	 rev8 : forall 'm, 'm == 32. (bits('m)) -> bits('m)
function rev8(x) = {     // endian swap
  output : bits('m) = zeros();
  foreach (k from 0 to ('m - 8) by 8) {
    output[(k + 7)..k] = x[('m - k - 1)..('m - k - 8)];
  };

  output
}

val	 FF1: forall 'm, 'm == 32. (bits('m), bits('m), bits('m)) -> bits('m)
function FF1(X, Y, Z) = ((X) ^ (Y) ^ (Z))

val	 FF2: forall 'm, 'm == 32. (bits('m), bits('m), bits('m)) -> bits('m)
function FF2(X, Y, Z) = (((X) & (Y)) | ((X) & (Z)) | ((Y) & (Z)))

val	 FF_j: forall 'm, 'm == 32. (bits('m), bits('m), bits('m), int) -> bits(32)
function FF_j(X, Y, Z, J) = if (J <= 15) then FF1(X, Y, Z) else FF2(X, Y, Z)

val	 GG1: forall 'm, 'm == 32. (bits('m), bits('m), bits('m)) -> bits('m)
function GG1(X, Y, Z) = ((X) ^ (Y) ^ (Z))

val	 GG2: forall 'm, 'm == 32. (bits('m), bits('m), bits('m)) -> bits('m)
function GG2(X, Y, Z) = (((X) & (Y)) | ((~(X)) & (Z)))

val	 GG_j: forall 'm, 'm == 32. (bits('m), bits('m), bits('m), int) -> bits(32)
function GG_j(X, Y, Z, J) = if (J <= 15) then GG1(X, Y, Z) else GG2(X, Y, Z)

val	 T_j : (int) -> bits(32)
function T_j(J) = if (J <= 15) then 0x79CC4519 else 0x7A879D8A
