/*
 * This file contains the 32-bit specific cryptography extension
 * instructions.
 *
 * This file must be included in the model build if XLEN=32
 */

/*
 * Scalar Cryptography Extension - Scalar 32-bit AES instructions
 * ----------------------------------------------------------------------
 */

union clause ast = AES32ESMI : (bits(2),regidx,regidx,regidx)
union clause ast =  AES32ESI : (bits(2),regidx,regidx,regidx)
union clause ast = AES32DSMI : (bits(2),regidx,regidx,regidx)
union clause ast =  AES32DSI : (bits(2),regidx,regidx,regidx)

/* Encrypt/Decrypt mapping for 32-bit scalar AES instructions. */
mapping clause encdec = AES32ESMI (bs,rs2,rs1,rd) 
    <-> bs @ 0b11011 @ rs2 @ rs1 @ 0b000 @ rd @ 0b0110011

mapping clause encdec = AES32ESI (bs,rs2,rs1,rd) 
    <-> bs @ 0b11001 @ rs2 @ rs1 @ 0b000 @ rd @ 0b0110011

mapping clause encdec = AES32DSMI (bs,rs2,rs1,rd) 
    <-> bs @ 0b11111 @ rs2 @ rs1 @ 0b000 @ rd @ 0b0110011

mapping clause encdec = AES32DSI (bs,rs2,rs1,rd) 
    <-> bs @ 0b11101 @ rs2 @ rs1 @ 0b000 @ rd @ 0b0110011

/* Map between an AST representation of AES32 and a disassembly string. */
mapping clause assembly = AES32ESMI (bs,rs2,rs1,rd) <->
    "aes32esmi" ^ spc() ^ reg_name(rd) ^ sep() ^ reg_name(rs1) ^ sep() ^ reg_name(rs2) ^ sep() ^ hex_bits_2(bs)

mapping clause assembly = AES32ESI (bs,rs2,rs1,rd) <->
    "aes32esi" ^ spc() ^ reg_name(rd) ^ sep() ^ reg_name(rs1) ^ sep() ^ reg_name(rs2) ^ sep() ^ hex_bits_2(bs)

mapping clause assembly = AES32DSMI (bs,rs2,rs1,rd) <->
    "aes32dsmi" ^ spc() ^ reg_name(rd) ^ sep() ^ reg_name(rs1) ^ sep() ^ reg_name(rs2) ^ sep() ^ hex_bits_2(bs)

mapping clause assembly = AES32DSI (bs,rs2,rs1,rd) <->
    "aes32dsi" ^ spc() ^ reg_name(rd) ^ sep() ^ reg_name(rs1) ^ sep() ^ reg_name(rs2) ^ sep() ^ hex_bits_2(bs)


function clause execute (AES32ESMI (bs,rs2,rs1,rd)) = {
  let shamt   : bits( 5) = bs @ 0b000; /* shamt = bs*8 */
  let si      : bits( 8) = (X(rs2)[31..0] >> shamt)[7..0]; /* SBox Input */
  let so      : bits( 8) = aes_sbox_fwd(si);
  let mixed   : bits(32) = aes_mixcolumn_byte_fwd(so);
  let result  : bits(32) = X(rs1)[31..0] ^ rol32(mixed, unsigned(shamt));
  X(rd) = EXTS(result); RETIRE_SUCCESS
}

function clause execute (AES32ESI (bs,rs2,rs1,rd)) = {
  let shamt   : bits( 5) = bs @ 0b000; /* shamt = bs*8 */
  let si      : bits( 8) = (X(rs2)[31..0] >> shamt)[7..0]; /* SBox Input */
  let so      : bits(32) = 0x000000 @ aes_sbox_fwd(si);
  let result  : bits(32) = X(rs1)[31..0] ^ rol32(so, unsigned(shamt));
  X(rd) = EXTS(result); RETIRE_SUCCESS
}

function clause execute (AES32DSMI (bs,rs2,rs1,rd)) = {
  let shamt   : bits( 5) = bs @ 0b000; /* shamt = bs*8 */
  let si      : bits( 8) = (X(rs2)[31..0] >> shamt)[7..0]; /* SBox Input */
  let so      : bits( 8) = aes_sbox_inv(si);
  let mixed   : bits(32) = aes_mixcolumn_byte_inv(so);
  let result  : bits(32) = X(rs1)[31..0] ^ rol32(mixed, unsigned(shamt));
  X(rd) = EXTS(result); RETIRE_SUCCESS
}

function clause execute (AES32DSI (bs,rs2,rs1,rd)) = {
  let shamt   : bits( 5) = bs @ 0b000; /* shamt = bs*8 */
  let si      : bits( 8) = (X(rs2)[31..0] >> shamt)[7..0]; /* SBox Input */
  let so      : bits(32) = 0x000000 @ aes_sbox_inv(si);
  let result  : bits(32) = X(rs1)[31..0] ^ rol32(so, unsigned(shamt));
  X(rd) = EXTS(result); RETIRE_SUCCESS
}


/*
 * Scalar Cryptography Extension - Scalar 32-bit SHA512 instructions
 * ----------------------------------------------------------------------
 */

/* AST clauses for the RV32 SHA512 instructions. */
union clause ast = SHA512SIG0L : (regidx, regidx, regidx)
union clause ast = SHA512SIG0H : (regidx, regidx, regidx)
union clause ast = SHA512SIG1L : (regidx, regidx, regidx)
union clause ast = SHA512SIG1H : (regidx, regidx, regidx)
union clause ast = SHA512SUM0R : (regidx, regidx, regidx)
union clause ast = SHA512SUM1R : (regidx, regidx, regidx)

/* Encode / decode mappings for the RV32 SHA512 instructions. */
mapping clause encdec = SHA512SUM0R (rs2, rs1, rd) 
  <-> 0b01 @ 0b01000 @ rs2 @ rs1 @ 0b000 @ rd @ 0b0110011

mapping clause encdec = SHA512SUM1R (rs2, rs1, rd) 
  <-> 0b01 @ 0b01001 @ rs2 @ rs1 @ 0b000 @ rd @ 0b0110011

mapping clause encdec = SHA512SIG0L (rs2, rs1, rd) 
  <-> 0b01 @ 0b01010 @ rs2 @ rs1 @ 0b000 @ rd @ 0b0110011

mapping clause encdec = SHA512SIG0H (rs2, rs1, rd) 
  <-> 0b01 @ 0b01110 @ rs2 @ rs1 @ 0b000 @ rd @ 0b0110011

mapping clause encdec = SHA512SIG1L (rs2, rs1, rd) 
  <-> 0b01 @ 0b01011 @ rs2 @ rs1 @ 0b000 @ rd @ 0b0110011

mapping clause encdec = SHA512SIG1H (rs2, rs1, rd) 
  <-> 0b01 @ 0b01111 @ rs2 @ rs1 @ 0b000 @ rd @ 0b0110011

/* Assembly string mappings for the RV32 SHA512 instructions. */
mapping clause assembly = SHA512SIG0L (rs2, rs1, rd)
  <-> "sha512sig0l" ^ spc() ^ reg_name(rd) ^ sep() ^ reg_name(rs1) ^ sep() ^ reg_name(rs2)

mapping clause assembly = SHA512SIG0H (rs2, rs1, rd)
  <-> "sha512sig0h" ^ spc() ^ reg_name(rd) ^ sep() ^ reg_name(rs1) ^ sep() ^ reg_name(rs2)

mapping clause assembly = SHA512SIG1L (rs2, rs1, rd)
  <-> "sha512sig1l" ^ spc() ^ reg_name(rd) ^ sep() ^ reg_name(rs1) ^ sep() ^ reg_name(rs2)

mapping clause assembly = SHA512SIG1H (rs2, rs1, rd)
  <-> "sha512sig1h" ^ spc() ^ reg_name(rd) ^ sep() ^ reg_name(rs1) ^ sep() ^ reg_name(rs2)

mapping clause assembly = SHA512SUM0R (rs2, rs1, rd)
  <-> "sha512sum0r" ^ spc() ^ reg_name(rd) ^ sep() ^ reg_name(rs1) ^ sep() ^ reg_name(rs2)

mapping clause assembly = SHA512SUM1R (rs2, rs1, rd)
  <-> "sha512sum1r" ^ spc() ^ reg_name(rd) ^ sep() ^ reg_name(rs1) ^ sep() ^ reg_name(rs2)

/*
 * Execute clauses for the 32-bit SHA512 instructions.
 */

function clause execute (SHA512SIG0L(rs2, rs1, rd)) = {
  X(rd) = EXTS((X(rs1) >>  1) ^ (X(rs1) >>  7) ^ (X(rs1) >>  8) ^
               (X(rs2) << 31) ^ (X(rs2) << 25) ^ (X(rs2) << 24) );
  RETIRE_SUCCESS
}

function clause execute (SHA512SIG0H(rs2, rs1, rd)) = {
  X(rd) = EXTS((X(rs1) >>  1) ^ (X(rs1) >>  7) ^ (X(rs1) >>  8) ^
               (X(rs2) << 31)                  ^ (X(rs2) << 24) );
  RETIRE_SUCCESS
}

function clause execute (SHA512SIG1L(rs2, rs1, rd)) = {
  X(rd) = EXTS((X(rs1) <<  3) ^ (X(rs1) >>  6) ^ (X(rs1) >> 19) ^
               (X(rs2) >> 29) ^ (X(rs2) << 26) ^ (X(rs2) << 13) );
  RETIRE_SUCCESS
}

function clause execute (SHA512SIG1H(rs2, rs1, rd)) = {
  X(rd) = EXTS((X(rs1) <<  3) ^ (X(rs1) >>  6) ^ (X(rs1) >> 19) ^
               (X(rs2) >> 29)                  ^ (X(rs2) << 13) );
  RETIRE_SUCCESS
}

function clause execute (SHA512SUM0R(rs2, rs1, rd)) = {
  X(rd) = EXTS((X(rs1) << 25) ^ (X(rs1) << 30) ^ (X(rs1) >> 28) ^
               (X(rs2) >>  7) ^ (X(rs2) >>  2) ^ (X(rs2) <<  4) );
  RETIRE_SUCCESS
}

function clause execute (SHA512SUM1R(rs2, rs1, rd)) = {
  X(rd) = EXTS((X(rs1) << 23) ^ (X(rs1) >> 14) ^ (X(rs1) >> 18) ^
               (X(rs2) >>  9) ^ (X(rs2) << 18) ^ (X(rs2) << 14) );
  RETIRE_SUCCESS
}
