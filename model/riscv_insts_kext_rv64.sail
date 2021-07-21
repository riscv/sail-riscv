/*
 * This file contains the 64-bit specific cryptography extension
 * instructions.
 *
 * This file must be included in the model build if XLEN=64
 */

/*
 * Scalar Cryptography Extension - Scalar 64-bit AES instructions
 * ----------------------------------------------------------------------
 */

union clause ast = AES64KS1I : (bits(4), regidx, regidx)
union clause ast = AES64KS2  : (regidx, regidx, regidx)
union clause ast = AES64IM   : (regidx, regidx)
union clause ast = AES64ESM  : (regidx, regidx, regidx)
union clause ast = AES64ES   : (regidx, regidx, regidx)
union clause ast = AES64DSM  : (regidx, regidx, regidx)
union clause ast = AES64DS   : (regidx, regidx, regidx)

mapping clause encdec = AES64KS1I (rnum, rs1, rd) 
  <-> 0b00 @ 0b11000 @ 0b1 @ rnum @ rs1 @ 0b001 @ rd @ 0b0010011

mapping clause encdec = AES64IM (rs1, rd) 
  <-> 0b00 @ 0b11000 @ 0b00000 @ rs1 @ 0b001 @ rd @ 0b0010011

mapping clause encdec = AES64KS2 (rs2, rs1, rd) 
  <-> 0b01 @ 0b11111 @ rs2 @ rs1 @ 0b000 @ rd @ 0b0110011

mapping clause encdec = AES64ESM (rs2, rs1, rd) 
  <-> 0b00 @ 0b11011 @ rs2 @ rs1 @ 0b000 @ rd @ 0b0110011

mapping clause encdec = AES64ES (rs2, rs1, rd) 
  <-> 0b00 @ 0b11001 @ rs2 @ rs1 @ 0b000 @ rd @ 0b0110011

mapping clause encdec = AES64DSM (rs2, rs1, rd) 
  <-> 0b00 @ 0b11111 @ rs2 @ rs1 @ 0b000 @ rd @ 0b0110011

mapping clause encdec = AES64DS (rs2, rs1, rd) 
  <-> 0b00 @ 0b11101 @ rs2 @ rs1 @ 0b000 @ rd @ 0b0110011

mapping clause assembly = AES64KS1I (rnum, rs1, rd)
  <-> "aes64ks1i" ^ spc() ^ reg_name(rd) ^ sep() ^ reg_name(rs1) ^ sep() ^ hex_bits_4(rnum)

mapping clause assembly = AES64KS2 (rs2, rs1, rd)
  <-> "aes64ks2" ^ spc() ^ reg_name(rd) ^ sep() ^ reg_name(rs1) ^ sep() ^ reg_name(rs2)

mapping clause assembly = AES64IM (rs1, rd) 
  <-> "aes64im" ^ spc() ^ reg_name(rd) ^ sep() ^ reg_name(rs1)

mapping clause assembly = AES64ESM (rs2, rs1, rd)
  <-> "aes64esm" ^ spc() ^ reg_name(rd) ^ sep() ^ reg_name(rs1) ^ sep() ^ reg_name(rs2)

mapping clause assembly = AES64ES (rs2, rs1, rd)
  <-> "aes64es" ^ spc() ^ reg_name(rd) ^ sep() ^ reg_name(rs1) ^ sep() ^ reg_name(rs2)

mapping clause assembly = AES64DSM (rs2, rs1, rd)
  <-> "aes64dsm" ^ spc() ^ reg_name(rd) ^ sep() ^ reg_name(rs1) ^ sep() ^ reg_name(rs2)

mapping clause assembly = AES64DS (rs2, rs1, rd)
  <-> "aes64ds" ^ spc() ^ reg_name(rd) ^ sep() ^ reg_name(rs1) ^ sep() ^ reg_name(rs2)

val crypto_aes64 : (regidx, regidx, regidx, bool, bool) -> Retired effect {escape, rreg, wreg}
function crypto_aes64(rd, rs1, rs2, enc, mix) = {
  let sr : bits(64) = match enc {
    true  => aes_rv64_shiftrows_fwd(X(rs2)[63..0], X(rs1)[63..0]), /*Encrypt*/
    false => aes_rv64_shiftrows_inv(X(rs2)[63..0], X(rs1)[63..0])  /*Decrypt*/
  };
  let wd : bits(64) = sr[63..0];
  let sb : bits(64) = match enc {
    true  => aes_apply_fwd_sbox_to_each_byte(wd), /* Encrypt */
    false => aes_apply_inv_sbox_to_each_byte(wd)  /* Decrypt */
  };
  X(rd)  = match (mix, enc) {
    (true, true ) => aes_mixcolumn_fwd(sb[63..32]) @ aes_mixcolumn_fwd(sb[31..0]),
    (true, false) => aes_mixcolumn_inv(sb[63..32]) @ aes_mixcolumn_inv(sb[31..0]),
    (false,  _  ) => sb
  };
  RETIRE_SUCCESS
}

function clause execute (AES64KS1I(rnum, rs1, rd)) = {
  if(unsigned(rnum) > 10) then {
    handle_illegal();  RETIRE_SUCCESS
  } else {
    let tmp1 : bits(32) = X(rs1)[63..32];
    let rc   : bits(32) = aes_rnum_to_rcon(rnum); /* round number -> round constant */
    let tmp2 : bits(32) = if (rnum ==0xA) then tmp1 else ror32(tmp1, 8);
    let tmp3 : bits(32) = aes_sbox_fwd(tmp2[31..24]) @ aes_sbox_fwd(tmp2[23..16]) @
                          aes_sbox_fwd(tmp2[15.. 8]) @ aes_sbox_fwd(tmp2[ 7.. 0]) ;
    let result : bits(64) = (tmp3 ^ rc) @ (tmp3 ^ rc);
    X(rd) = EXTZ(result);
    RETIRE_SUCCESS
  }
}

function clause execute (AES64KS2(rs2, rs1, rd)) = {
  let w0 : bits(32) = X(rs1)[63..32] ^ X(rs2)[31..0];
  let w1 : bits(32) = X(rs1)[63..32] ^ X(rs2)[31..0] ^ X(rs2)[63..32];
  X(rd)  = w1 @ w0;
  RETIRE_SUCCESS
}

function clause execute (AES64IM(rs1, rd)) = {
  let w0 : bits(32) = aes_mixcolumn_inv(X(rs1)[31.. 0]);
  let w1 : bits(32) = aes_mixcolumn_inv(X(rs1)[63..32]);
  X(rd)  = w1 @ w0;
  RETIRE_SUCCESS
}

function clause execute (AES64ESM(rs2, rs1, rd)) = {
  let sr : bits(64) = aes_rv64_shiftrows_fwd(X(rs2)[63..0], X(rs1)[63..0]);
  let wd : bits(64) = sr[63..0];
  let sb : bits(64) = aes_apply_fwd_sbox_to_each_byte(wd);
  X(rd)  =  aes_mixcolumn_fwd(sb[63..32]) @ aes_mixcolumn_fwd(sb[31..0]);
  RETIRE_SUCCESS
}

function clause execute (AES64ES(rs2, rs1, rd)) = {
  let sr : bits(64) = aes_rv64_shiftrows_fwd(X(rs2)[63..0], X(rs1)[63..0]);
  let wd : bits(64) = sr[63..0];
  X(rd) = aes_apply_fwd_sbox_to_each_byte(wd);
  RETIRE_SUCCESS
}

function clause execute (AES64DSM(rs2, rs1, rd)) = {
  let sr : bits(64) = aes_rv64_shiftrows_inv(X(rs2)[63..0], X(rs1)[63..0]);
  let wd : bits(64) = sr[63..0];
  let sb : bits(64) = aes_apply_inv_sbox_to_each_byte(wd);
  X(rd)  = aes_mixcolumn_inv(sb[63..32]) @ aes_mixcolumn_inv(sb[31..0]);
  RETIRE_SUCCESS
}

function clause execute (AES64DS(rs2, rs1, rd)) = {
  let sr : bits(64) = aes_rv64_shiftrows_inv(X(rs2)[63..0], X(rs1)[63..0]);
  let wd : bits(64) = sr[63..0];
  X(rd) = aes_apply_inv_sbox_to_each_byte(wd);
  RETIRE_SUCCESS
}

/*
 * Scalar Cryptography Extension - Scalar 64-bit SHA512 instructions
 * ----------------------------------------------------------------------
 */

union clause ast = SHA512SIG0 : (regidx, regidx)
union clause ast = SHA512SIG1 : (regidx, regidx)
union clause ast = SHA512SUM0 : (regidx, regidx)
union clause ast = SHA512SUM1 : (regidx, regidx)

mapping clause encdec = SHA512SUM0 (rs1, rd) 
   <-> 0b00 @ 0b01000 @ 0b00100 @ rs1 @ 0b001 @ rd @ 0b0010011

mapping clause encdec = SHA512SUM1 (rs1, rd) 
  <-> 0b00 @ 0b01000 @ 0b00101 @ rs1 @ 0b001 @ rd @ 0b0010011

mapping clause encdec = SHA512SIG0 (rs1, rd) 
  <-> 0b00 @ 0b01000 @ 0b00110 @ rs1 @ 0b001 @ rd @ 0b0010011

mapping clause encdec = SHA512SIG1 (rs1, rd) 
  <-> 0b00 @ 0b01000 @ 0b00111 @ rs1 @ 0b001 @ rd @ 0b0010011

mapping clause assembly = SHA512SIG0 (rs1, rd)
  <-> "sha512sig0" ^ spc() ^ reg_name(rd) ^ sep() ^ reg_name(rs1)

mapping clause assembly = SHA512SIG1 (rs1, rd)
  <-> "sha512sig1" ^ spc() ^ reg_name(rd) ^ sep() ^ reg_name(rs1)

mapping clause assembly = SHA512SUM0 (rs1, rd)
  <-> "sha512sum0" ^ spc() ^ reg_name(rd) ^ sep() ^ reg_name(rs1)

mapping clause assembly = SHA512SUM1 (rs1, rd)
  <-> "sha512sum1" ^ spc() ^ reg_name(rd) ^ sep() ^ reg_name(rs1)

function clause execute (SHA512SIG0(rs1, rd)) = {
  X(rd) = ror64(X(rs1),  1) ^ ror64(X(rs1),  8) ^ (X(rs1) >> 7);
  RETIRE_SUCCESS
}

function clause execute (SHA512SIG1(rs1, rd)) = {
  X(rd) = ror64(X(rs1), 19) ^ ror64(X(rs1), 61) ^ (X(rs1) >> 6);
  RETIRE_SUCCESS
}

function clause execute (SHA512SUM0(rs1, rd)) = {
  X(rd) = ror64(X(rs1), 28) ^ ror64(X(rs1), 34) ^ ror64(X(rs1) ,39);
  RETIRE_SUCCESS
}

function clause execute (SHA512SUM1(rs1, rd)) = {
  X(rd) = ror64(X(rs1), 14) ^ ror64(X(rs1), 18) ^ ror64(X(rs1) ,41);
  RETIRE_SUCCESS
}
