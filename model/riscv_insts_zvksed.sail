/*
 * Vector Cryptography Extension - Vector GCM/GMAC
 * ----------------------------------------------------------------------
 */

/*
 * Helper functions.
 * ----------------------------------------------------------------------
 */

val	 rol32 : forall 'm, 32 - 'm >= 0 & 'm >= 0. (bits(32), int('m)) -> bits(32)
function rol32(X,N) = (X << N) | (X >> (32 - N))

val	 round_key : (bits(32), bits(32)) -> bits(32)
function round_key(X, S) = ((X) ^ ((S) ^ rol32((S), 13) ^ rol32((S), 23)))

// SM4 Constant Key (CK)
let ck : list(bits(32)) = [|
      0x00070E15, 0x1C232A31, 0x383F464D, 0x545B6269,
      0x70777E85, 0x8C939AA1, 0xA8AFB6BD, 0xC4CBD2D9,
      0xE0E7EEF5, 0xFC030A11, 0x181F262D, 0x343B4249,
      0x50575E65, 0x6C737A81, 0x888F969D, 0xA4ABB2B9,
      0xC0C7CED5, 0xDCE3EAF1, 0xF8FF060D, 0x141B2229,
      0x30373E45, 0x4C535A61, 0x686F767D, 0x848B9299,
      0xA0A7AEB5, 0xBCC3CAD1, 0xD8DFE6ED, 0xF4FB0209,
      0x10171E25, 0x2C333A41, 0x484F565D, 0x646B7279
|]

/* Lookup function for Zvksed SM4 Contant Key;- takes an index and a list, and retrieves the
 * x'th element of that list.
 */
val	 zvksed_box_lookup : (bits(32), list(bits(32))) -> bits(32)
function zvksed_box_lookup(x, table) = {
  match (x, table) {
    (0x00000000, t0::tn) => t0,
    (	      _, t0::tn) => zvksed_box_lookup(x - 0x00000001, tn)
  }
}

val	 zvksed_sm4_sbox : (bits(32)) -> bits(32)
function zvksed_sm4_sbox(x) = zvksed_box_lookup(x, ck)

val	 sm4_subword : bits(32) -> bits(32)
function sm4_subword(x) = {
  sm4_sbox(x[31..24]) @
  sm4_sbox(x[23..16]) @
  sm4_sbox(x[15.. 8]) @
  sm4_sbox(x[ 7.. 0])
}

val	 sm4_round : (bits(32), bits(32)) -> bits(32)
function sm4_round(X, S) =
  ((X) ^ ((S) ^ rol32((S), 2) ^ rol32((S), 10) ^ rol32((S), 18) ^ rol32((S), 24)))
