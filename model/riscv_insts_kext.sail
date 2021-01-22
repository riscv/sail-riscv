/*
 * This file contains instructions whose definitions are independent of XLEN.
 */

/*
 * Scalar Cryptography Extension - Scalar SHA256 instructions
 * ----------------------------------------------------------------------
 */

/* AST clauses for the SHA256 instructions. */
union clause ast = SHA256SIG0 : (regidx, regidx)
union clause ast = SHA256SIG1 : (regidx, regidx)
union clause ast = SHA256SUM0 : (regidx, regidx)
union clause ast = SHA256SUM1 : (regidx, regidx)

/* Encode/decode mappings for the SHA256 instructions. */
mapping clause encdec = SHA256SUM0 (rs1, rd) 
  <-> 0b00 @ 0b01000 @ 0b00000 @ rs1 @ 0b001 @ rd @ 0b0010011

mapping clause encdec = SHA256SUM1 (rs1, rd) 
  <-> 0b00 @ 0b01000 @ 0b00001 @ rs1 @ 0b001 @ rd @ 0b0010011

mapping clause encdec = SHA256SIG0 (rs1, rd) 
  <-> 0b00 @ 0b01000 @ 0b00010 @ rs1 @ 0b001 @ rd @ 0b0010011

mapping clause encdec = SHA256SIG1 (rs1, rd) 
  <-> 0b00 @ 0b01000 @ 0b00011 @ rs1 @ 0b001 @ rd @ 0b0010011

/* Assembly string mappings for the SHA256 instructions. */
mapping clause assembly = SHA256SIG0 (rs1, rd)
  <-> "sha256sig0" ^ spc() ^ reg_name(rd) ^ sep() ^ reg_name(rs1)

mapping clause assembly = SHA256SIG1 (rs1, rd)
  <-> "sha256sig1" ^ spc() ^ reg_name(rd) ^ sep() ^ reg_name(rs1)

mapping clause assembly = SHA256SUM0 (rs1, rd)
  <-> "sha256sum0" ^ spc() ^ reg_name(rd) ^ sep() ^ reg_name(rs1)

mapping clause assembly = SHA256SUM1 (rs1, rd)
  <-> "sha256sum1" ^ spc() ^ reg_name(rd) ^ sep() ^ reg_name(rs1)

/* Execution clauses for the SHA256 instructions. */
function clause execute (SHA256SIG0(rs1,rd)) = {
  let inb    : bits(32) = X(rs1)[31..0];
  let result : bits(32) = ror32(inb,  7) ^ ror32(inb, 18) ^ (inb >>  3);
  X(rd)      = EXTZ(result);
  RETIRE_SUCCESS
}

function clause execute (SHA256SIG1(rs1,rd)) = {
  let inb    : bits(32) = X(rs1)[31..0];
  let result : bits(32) = ror32(inb, 17) ^ ror32(inb, 19) ^ (inb >> 10);
  X(rd)      = EXTZ(result);
  RETIRE_SUCCESS
}

function clause execute (SHA256SUM0(rs1,rd)) = {
  let inb    : bits(32) = X(rs1)[31..0];
  let result : bits(32) = ror32(inb,  2) ^ ror32(inb, 13) ^ ror32(inb, 22);
  X(rd)      = EXTZ(result);
  RETIRE_SUCCESS
}

function clause execute (SHA256SUM1(rs1,rd)) = {
  let inb    : bits(32) = X(rs1)[31..0];
  let result : bits(32) = ror32(inb,  6) ^ ror32(inb, 11) ^ ror32(inb, 25);
  X(rd)      = EXTZ(result);
  RETIRE_SUCCESS
}

/*
 * Scalar Cryptography Extension - Scalar SM3 instructions
 * ----------------------------------------------------------------------
 */

/* AST Types for SM3.p0/1 */
union clause ast = SM3P0 : (regidx, regidx)
union clause ast = SM3P1 : (regidx, regidx)

/* Decode clause for sm3.p0 */
mapping clause encdec = SM3P0 (rs1, rd) 
  <-> 0b00 @ 0b01000 @ 0b01000 @ rs1 @ 0b001 @ rd @ 0b0010011

/* Decode clause for sm3.p1 */
mapping clause encdec = SM3P1 (rs1, rd) 
  <-> 0b00 @ 0b01000 @ 0b01001 @ rs1 @ 0b001 @ rd @ 0b0010011

/* Asssembly code mapping for sm3p0 */
mapping clause assembly = SM3P0 (rs1, rd) <->
  "sm3p0" ^ spc() ^ reg_name(rd) ^ sep() ^ reg_name(rs1)

/* Asssembly code mapping for sm3p1 */
mapping clause assembly = SM3P1 (rs1, rd) <->
  "sm3p1" ^ spc() ^ reg_name(rd) ^ sep() ^ reg_name(rs1)

/* Execute clause for sm3.p0 */
function clause execute (SM3P0(rs1, rd)) = {
  let r1     : bits(32) = X(rs1)[31..0];
  let result : bits(32) =  r1 ^ rol32(r1,  9) ^ rol32(r1, 17);
  X(rd) = EXTZ(result);
  RETIRE_SUCCESS
}

/* Execute clause for sm3.p1 */
function clause execute (SM3P1(rs1, rd)) = {
  let r1     : bits(32) = X(rs1)[31..0];
  let result : bits(32) =  r1 ^ rol32(r1, 15) ^ rol32(r1, 23);
  X(rd) = EXTZ(result);
  RETIRE_SUCCESS
}

/*
 * Scalar Cryptography Extension - Scalar SM4 instructions
 * ----------------------------------------------------------------------
 */

/* AST clauses for the SM4 instructions. */
union clause ast = SM4ED : (bits(2),regidx,regidx,regidx)
union clause ast = SM4KS : (bits(2),regidx,regidx,regidx)

/* Encode / decode mappings for the SM4 instructions. */
mapping clause encdec = SM4ED (bs,rs2,rs1,rd) 
    <-> bs @ 0b11000 @ rs2 @ rs1 @ 0b000 @ rd @ 0b0110011

mapping clause encdec = SM4KS (bs,rs2,rs1,rd) 
    <-> bs @ 0b11010 @ rs2 @ rs1 @ 0b000 @ rd @ 0b0110011

/* Assembly string mappings for the SM4 instructions. */
mapping clause assembly = SM4ED (bs,rs2,rs1,rd) <->
    "sm4ed" ^ spc() ^ reg_name(rd) ^ sep() ^ reg_name(rs1) ^ sep() ^ reg_name(rs2) ^ sep() ^ hex_bits_2(bs)

mapping clause assembly = SM4KS (bs,rs2,rs1,rd) <->
    "sm4ks" ^ spc() ^ reg_name(rd) ^ sep() ^ reg_name(rs1) ^ sep() ^ reg_name(rs2) ^ sep() ^ hex_bits_2(bs)

/* Execute clause for the sm4 instructions. */
function clause execute (SM4ED (bs,rs2,rs1,rd)) = {
  let shamt : bits(6)  = (0b0 @ bs @ 0b000); /* shamt = bs*8 */
  let sb_in : bits(8)  = (X(rs2) >> shamt)[7..0];
  let x     : bits(32) = 0x000000 @ sm4_sbox(sb_in);
  let y     : bits(32) = x ^ (x               <<  8) ^ ( x               <<  2) ^
                             (x               << 18) ^ ((x & 0x0000003F) << 26) ^
                             ((x & 0x000000C0) << 10);
  let z     : bits(32) = (y << shamt) ^ (y >> (0b100000 - shamt));
  let result: bits(32) = z ^ X(rs1)[31..0];
  X(rd)                = EXTZ(result);
  RETIRE_SUCCESS
}

function clause execute (SM4KS (bs,rs2,rs1,rd)) = {
  let shamt : bits(6)  = (0b0 @ bs @ 0b000); /* shamt = bs*8 */
  let sb_in : bits(8)  = (X(rs2) >> shamt)[7..0];
  let x     : bits(32) = 0x000000 @ sm4_sbox(sb_in);
  let y     : bits(32) = x ^ ((x & 0x00000007) << 29) ^ ((x & 0x000000FE) <<  7) ^
                             ((x & 0x00000001) << 23) ^ ((x & 0x000000F8) << 13) ;
  let z     : bits(32) = (y << shamt) ^ (y >> (0b100000 - shamt));
  let result: bits(32) = z ^ X(rs1)[31..0];
  X(rd) = EXTZ(result);
  RETIRE_SUCCESS
}
