/* ****************************************************************** */
/* This file specifies the instructions in the BitManip Zba, Zbb, Zbc and Zbs extensions */


/* ****************************************************************** */

union clause ast = BITIOPW : (bits(6), regidx, regidx, biopw)

mapping clause encdec = BITIOPW(shamt, rs1, rd, RISCV_SLLIUW)
      if sizeof(xlen) == 64
  <-> 0b000010 @ shamt @ rs1 @ 0b001 @ rd @ 0b0011011
      if sizeof(xlen) == 64
mapping clause encdec = BITIOPW(shamt, rs1, rd, RISCV_RORIW)
      if sizeof(xlen) == 64 & shamt[5] == bitzero
  <-> 0b011000 @ shamt @ rs1 @ 0b101 @ rd @ 0b0011011
      if sizeof(xlen) == 64 & shamt[5] == bitzero
      
function clause execute (BITIOPW(shamt, rs1, rd, op)) = {
  let rs1_val = X(rs1);
  let result : xlenbits = match op {
    RISCV_SLLIUW    => EXTZ(rs1_val[31..0]) << shamt,
    RISCV_RORIW     => EXTS((rs1_val[31..0] >> shamt[4..0]) | (rs1_val[31..0] << (0x20 - EXTZ(shamt[4..0]))))
  };
  X(rd) = result;
  RETIRE_SUCCESS
}

mapping bitiopw_mnemonic : biopw <-> string = {
  RISCV_SLLIUW    <-> "slli.uw",
  RISCV_RORIW     <-> "roriw"
}

mapping clause assembly = BITIOPW(shamt, rs1, rd, op)
      if sizeof(xlen) == 64
  <-> bitiopw_mnemonic(op) ^ spc() ^ reg_name(rd) ^ sep() ^ reg_name(rs1) ^ sep() ^ hex_bits_6(shamt)
      if sizeof(xlen) == 64

/* ****************************************************************** */
union clause ast = BITIOP : (bits(6), regidx, regidx, biop)

mapping clause encdec = BITIOP(shamt, rs1, rd, RISCV_BCLRI) <-> 0b010010 @ shamt @ rs1 @ 0b001 @ rd @ 0b0010011 if sizeof(xlen) == 64 | shamt[5] == bitzero
mapping clause encdec = BITIOP(shamt, rs1, rd, RISCV_BEXTI) <-> 0b010010 @ shamt @ rs1 @ 0b101 @ rd @ 0b0010011 if sizeof(xlen) == 64 | shamt[5] == bitzero
mapping clause encdec = BITIOP(shamt, rs1, rd, RISCV_BINVI) <-> 0b011010 @ shamt @ rs1 @ 0b001 @ rd @ 0b0010011 if sizeof(xlen) == 64 | shamt[5] == bitzero
mapping clause encdec = BITIOP(shamt, rs1, rd, RISCV_BSETI) <-> 0b001010 @ shamt @ rs1 @ 0b001 @ rd @ 0b0010011 if sizeof(xlen) == 64 | shamt[5] == bitzero
mapping clause encdec = BITIOP(shamt, rs1, rd, RISCV_RORI)  <-> 0b011000 @ shamt @ rs1 @ 0b101 @ rd @ 0b0010011 if sizeof(xlen) == 64 | shamt[5] == bitzero

function clause execute (BITIOP(shamt, rs1, rd, op)) = {
  let rs1_val = X(rs1);
  let result : xlenbits = match op {
    RISCV_BCLRI   => if   sizeof(xlen) == 32
                     then rs1_val & ( ~ (EXTZ(0b1 << shamt[4..0])))
                     else rs1_val & ( ~ (EXTZ(0b1 << shamt[5..0]))),
    RISCV_BEXTI   => if   sizeof(xlen) == 32
                     then (rs1_val >> shamt[4..0]) & EXTZ(0x1)
                     else (rs1_val >> shamt[5..0]) & EXTZ(0x1),
    RISCV_BINVI   => if   sizeof(xlen) == 32
                     then rs1_val ^ (EXTZ(0b1 << shamt[4..0]))
                     else rs1_val ^ (EXTZ(0b1 << shamt[5..0])),
    RISCV_BSETI   => if   sizeof(xlen) == 32
                     then rs1_val | (EXTZ(0b1 << shamt[4..0]))
                     else rs1_val | (EXTZ(0b1 << shamt[5..0])),
    RISCV_RORI    => if   sizeof(xlen) == 32
                     then (rs1_val >> shamt[4..0]) | (rs1_val << (0x20 - EXTZ(shamt[4..0])))
                     else (rs1_val >> shamt[5..0]) | (rs1_val << (0x40 - EXTZ(shamt[5..0]))) 
  };
  X(rd) = result;
  RETIRE_SUCCESS
}

mapping bitiop_mnemonic : biop <-> string = {
  RISCV_BCLRI    <-> "bclri",
  RISCV_BEXTI    <-> "bexti",
  RISCV_BINVI    <-> "binvi",
  RISCV_BSETI    <-> "bseti",
  RISCV_RORI     <-> "rori"
}

mapping clause assembly = BITIOP(shamt, rs1, rd, op)
  <-> bitiop_mnemonic(op) ^ spc() ^ reg_name(rd) ^ sep() ^ reg_name(rs1) ^ sep() ^ hex_bits_6(shamt)

/* ****************************************************************** */
union clause ast = BRTYPEW : (regidx, regidx, regidx, bropw)

mapping clause encdec = BRTYPEW(rs2, rs1, rd, RISCV_ADDUW)
      if sizeof(xlen) == 64
  <-> 0b0000100 @ rs2 @ rs1 @ 0b000 @ rd @ 0b0111011
      if sizeof(xlen) == 64
mapping clause encdec = BRTYPEW(rs2, rs1, rd, RISCV_SH1ADDUW)
      if sizeof(xlen) == 64
  <-> 0b0010000 @ rs2 @ rs1 @ 0b010 @ rd @ 0b0111011
      if sizeof(xlen) == 64
mapping clause encdec = BRTYPEW(rs2, rs1, rd, RISCV_SH2ADDUW)
      if sizeof(xlen) == 64
  <-> 0b0010000 @ rs2 @ rs1 @ 0b100 @ rd @ 0b0111011
      if sizeof(xlen) == 64
mapping clause encdec = BRTYPEW(rs2, rs1, rd, RISCV_SH3ADDUW)
      if sizeof(xlen) == 64
  <-> 0b0010000 @ rs2 @ rs1 @ 0b110 @ rd @ 0b0111011
      if sizeof(xlen) == 64
mapping clause encdec = BRTYPEW(rs2, rs1, rd, RISCV_ROLW)
      if sizeof(xlen) == 64
  <-> 0b0110000 @ rs2 @ rs1 @ 0b001 @ rd @ 0b0111011
      if sizeof(xlen) == 64
mapping clause encdec = BRTYPEW(rs2, rs1, rd, RISCV_RORW)
      if sizeof(xlen) == 64
  <-> 0b0110000 @ rs2 @ rs1 @ 0b101 @ rd @ 0b0111011
      if sizeof(xlen) == 64

function clause execute (BRTYPEW(rs2, rs1, rd, op)) = {
  let rs1_val = X(rs1);
  let rs2_val = X(rs2);
  let result : xlenbits = match op {
    RISCV_ADDUW    => EXTZ(rs1_val[31..0]) + rs2_val,
    RISCV_SH1ADDUW => (EXTZ(rs1_val[31..0]) << 1) + rs2_val,
    RISCV_SH2ADDUW => (EXTZ(rs1_val[31..0]) << 2) + rs2_val,
    RISCV_SH3ADDUW => (EXTZ(rs1_val[31..0]) << 3) + rs2_val,
    RISCV_ROLW     => EXTS((rs1_val[31..0] << rs2_val[4..0]) | (rs1_val[31..0] >> (0x20 - EXTZ(rs2_val[4..0])))),
    RISCV_RORW     => EXTS((rs1_val[31..0] >> rs2_val[4..0]) | (rs1_val[31..0] << (0x20 - EXTZ(rs2_val[4..0]))))
  };
  X(rd) = EXTS(result);
  RETIRE_SUCCESS
}

mapping brtypew_mnemonic : bropw <-> string = {
  RISCV_ADDUW    <-> "add.uw",
  RISCV_SH1ADDUW <-> "sh1add.uw",
  RISCV_SH2ADDUW <-> "sh2add.uw",
  RISCV_SH3ADDUW <-> "sh3add.uw",
  RISCV_ROLW     <-> "rolw",
  RISCV_RORW     <-> "rorw"
}

mapping clause assembly = BRTYPEW(rs2, rs1, rd, op)
      if sizeof(xlen) == 64
  <-> brtypew_mnemonic(op) ^ spc() ^ reg_name(rd) ^ sep() ^ reg_name(rs1) ^ sep() ^ reg_name(rs2)
      if sizeof(xlen) == 64

/* ****************************************************************** */
union clause ast = BRTYPE : (regidx, regidx, regidx, brop)

mapping clause encdec = BRTYPE(rs2, rs1, rd, RISCV_SH1ADD)  <-> 0b0010000 @ rs2 @ rs1 @ 0b010 @ rd @ 0b0110011
mapping clause encdec = BRTYPE(rs2, rs1, rd, RISCV_SH2ADD)  <-> 0b0010000 @ rs2 @ rs1 @ 0b100 @ rd @ 0b0110011
mapping clause encdec = BRTYPE(rs2, rs1, rd, RISCV_SH3ADD)  <-> 0b0010000 @ rs2 @ rs1 @ 0b110 @ rd @ 0b0110011
mapping clause encdec = BRTYPE(rs2, rs1, rd, RISCV_BCLR)    <-> 0b0100100 @ rs2 @ rs1 @ 0b001 @ rd @ 0b0110011
mapping clause encdec = BRTYPE(rs2, rs1, rd, RISCV_BEXT)    <-> 0b0100100 @ rs2 @ rs1 @ 0b101 @ rd @ 0b0110011
mapping clause encdec = BRTYPE(rs2, rs1, rd, RISCV_BINV)    <-> 0b0110100 @ rs2 @ rs1 @ 0b001 @ rd @ 0b0110011
mapping clause encdec = BRTYPE(rs2, rs1, rd, RISCV_BSET)    <-> 0b0010100 @ rs2 @ rs1 @ 0b001 @ rd @ 0b0110011
mapping clause encdec = BRTYPE(rs2, rs1, rd, RISCV_ANDN)    <-> 0b0100000 @ rs2 @ rs1 @ 0b111 @ rd @ 0b0110011
mapping clause encdec = BRTYPE(rs2, rs1, rd, RISCV_ORN)     <-> 0b0100000 @ rs2 @ rs1 @ 0b110 @ rd @ 0b0110011
mapping clause encdec = BRTYPE(rs2, rs1, rd, RISCV_XNOR)    <-> 0b0100000 @ rs2 @ rs1 @ 0b100 @ rd @ 0b0110011
mapping clause encdec = BRTYPE(rs2, rs1, rd, RISCV_MAX)     <-> 0b0000101 @ rs2 @ rs1 @ 0b110 @ rd @ 0b0110011
mapping clause encdec = BRTYPE(rs2, rs1, rd, RISCV_MAXU)    <-> 0b0000101 @ rs2 @ rs1 @ 0b111 @ rd @ 0b0110011
mapping clause encdec = BRTYPE(rs2, rs1, rd, RISCV_MIN)     <-> 0b0000101 @ rs2 @ rs1 @ 0b100 @ rd @ 0b0110011
mapping clause encdec = BRTYPE(rs2, rs1, rd, RISCV_MINU)    <-> 0b0000101 @ rs2 @ rs1 @ 0b101 @ rd @ 0b0110011
mapping clause encdec = BRTYPE(rs2, rs1, rd, RISCV_ROL)     <-> 0b0110000 @ rs2 @ rs1 @ 0b001 @ rd @ 0b0110011
mapping clause encdec = BRTYPE(rs2, rs1, rd, RISCV_ROR)     <-> 0b0110000 @ rs2 @ rs1 @ 0b101 @ rd @ 0b0110011

function clause execute (BRTYPE(rs2, rs1, rd, op)) = {
  let rs1_val = X(rs1);
  let rs2_val = X(rs2);
  let result : xlenbits = match op {
    RISCV_SH1ADD  => rs2_val + (rs2_val << 1),
    RISCV_SH2ADD  => rs2_val + (rs2_val << 2),
    RISCV_SH3ADD  => rs2_val + (rs2_val << 3),
    RISCV_BCLR    => if   sizeof(xlen) == 32
                     then rs1_val & ( ~ (EXTZ(0b1 << rs2_val[4..0])))
                     else rs1_val & ( ~ (EXTZ(0b1 << rs2_val[5..0]))),
    RISCV_BEXT    => if   sizeof(xlen) == 32
                     then (rs1_val >> rs2_val[4..0]) & EXTZ(0x1)
                     else (rs1_val >> rs2_val[5..0]) & EXTZ(0x1),
    RISCV_BINV    => if   sizeof(xlen) == 32
                     then rs1_val ^ (EXTZ(0b1 << rs2_val[4..0]))
                     else rs1_val ^ (EXTZ(0b1 << rs2_val[5..0])),
    RISCV_BSET    => if   sizeof(xlen) == 32
                     then rs1_val | (EXTZ(0b1 << rs2_val[4..0]))
                     else rs1_val | (EXTZ(0b1 << rs2_val[5..0])),
    RISCV_ANDN    => rs1_val & ( ~ (rs2_val)),
    RISCV_ORN     => rs1_val | ( ~ (rs2_val)),
    RISCV_XNOR    => ~ (rs1_val ^ rs2_val),
    RISCV_MAX     => if (rs1_val <_s rs2_val)
                     then rs2_val
                     else rs1_val,
    RISCV_MAXU    => if (rs1_val <_u rs2_val)
                     then rs2_val
                     else rs1_val,
    RISCV_MIN     => if (rs1_val <_s rs2_val)
                     then rs1_val
                     else rs2_val,
    RISCV_MINU    => if (rs1_val <_u rs2_val)
                     then rs1_val
                     else rs2_val,
    RISCV_ROL     => if   sizeof(xlen) == 32
                     then (rs1_val << rs2_val[4..0]) | (rs1_val >> (0x20 - EXTZ(rs2_val[4..0])))
                     else (rs1_val << rs2_val[5..0]) | (rs1_val >> (0x40 - EXTZ(rs2_val[5..0]))),
    RISCV_ROR     => if   sizeof(xlen) == 32
                     then (rs1_val >> rs2_val[4..0]) | (rs1_val << (0x20 - EXTZ(rs2_val[4..0])))
                     else (rs1_val >> rs2_val[5..0]) | (rs1_val << (0x40 - EXTZ(rs2_val[5..0])))
  };
  X(rd) = result;
  RETIRE_SUCCESS
}



mapping brtype_mnemonic : brop <-> string = {
  RISCV_SH1ADD  <-> "sh1add",
  RISCV_SH2ADD  <-> "sh2add",
  RISCV_SH3ADD  <-> "sh3add",
  RISCV_BCLR    <-> "bclr",
  RISCV_BEXT    <-> "bext",
  RISCV_BINV    <-> "binv",
  RISCV_BSET    <-> "bset",
  RISCV_ANDN    <-> "andn",
  RISCV_ORN     <-> "orn",
  RISCV_XNOR    <-> "xnor",
  RISCV_MAX     <-> "max",
  RISCV_MAXU    <-> "maxu",
  RISCV_MIN     <-> "min",
  RISCV_MINU    <-> "minu",
  RISCV_ROL     <-> "rol",
  RISCV_ROR     <-> "ror"
}

mapping clause assembly = BRTYPE(rs2, rs1, rd, op)
  <-> brtype_mnemonic(op) ^ spc() ^ reg_name(rd) ^ sep() ^ reg_name(rs1) ^ sep() ^ reg_name(rs2)
  
/* ****************************************************************** */
union clause ast = BMRTYPE : (regidx, regidx, regidx, brop)

mapping clause encdec = BMRTYPE(rs2, rs1, rd, RISCV_CLMUL)   <-> 0b0000101 @ rs2 @ rs1 @ 0b001 @ rd @ 0b0110011
mapping clause encdec = BMRTYPE(rs2, rs1, rd, RISCV_CLMULH)  <-> 0b0000101 @ rs2 @ rs1 @ 0b011 @ rd @ 0b0110011
mapping clause encdec = BMRTYPE(rs2, rs1, rd, RISCV_CLMULR)  <-> 0b0000101 @ rs2 @ rs1 @ 0b010 @ rd @ 0b0110011


function clause execute (BMRTYPE(rs2, rs1, rd, op)) = {
  let rs1_val = X(rs1);
  let rs2_val = X(rs2);
  result : xlenbits = EXTZ(0x0);
  foreach (i from 0 to (xlen_val - 1) by 1) {
      result = match op {
        RISCV_CLMUL  => if ((rs2_val >> i)[0] == bitone)
                        then result ^ (rs1_val << i)
                        else result,
        RISCV_CLMULH => if ((rs2_val >> i)[0] == bitone)
                        then result ^ (rs1_val >> (xlen_val - i))
                        else result,
        RISCV_CLMULR => if ((rs2_val >> i)[0] == bitone)
                        then result ^ (rs1_val >> (xlen_val - i - 1))
                        else result
      };
  };
  
  X(rd) = result;
  RETIRE_SUCCESS
}

mapping bmrtype_mnemonic : brop <-> string = {
  RISCV_CLMUL    <-> "clmul",
  RISCV_CLMULH   <-> "clmulh",
  RISCV_CLMULR   <-> "clmulr"
}

mapping clause assembly = BMRTYPE(rs2, rs1, rd, op)
  <-> bmrtype_mnemonic(op) ^ spc() ^ reg_name(rd) ^ sep() ^ reg_name(rs1) ^ sep() ^ reg_name(rs2)
  
/* ****************************************************************** */
union clause ast = BEXTOP : (regidx, regidx, extop)

mapping clause encdec = BEXTOP(rs1, rd, RISCV_SEXTB)  <-> 0b0110000 @ 0b00100 @ rs1 @ 0b001 @ rd @ 0b0010011
mapping clause encdec = BEXTOP(rs1, rd, RISCV_SEXTH)  <-> 0b0110000 @ 0b00101 @ rs1 @ 0b001 @ rd @ 0b0010011
mapping clause encdec = BEXTOP(rs1, rd, RISCV_ZEXTH)  <-> 0b0000100 @ 0b00000 @ rs1 @ 0b100 @ rd @ 0b0110011 if sizeof(xlen) == 32
mapping clause encdec = BEXTOP(rs1, rd, RISCV_ZEXTH)  <-> 0b0000100 @ 0b00000 @ rs1 @ 0b100 @ rd @ 0b0111011 if sizeof(xlen) == 64

function clause execute (BEXTOP(rs1, rd, op)) = {
  let rs1_val = X(rs1);
  let result : xlenbits = match op {
    RISCV_SEXTB  => EXTS(rs1_val[7..0]),
    RISCV_SEXTH  => EXTS(rs1_val[15..0]),
    RISCV_ZEXTH  => EXTZ(rs1_val[15..0])
  };
  X(rd) = result;
  RETIRE_SUCCESS
}

mapping bextop_mnemonic : extop <-> string = {
  RISCV_SEXTB  <-> "sext.b",
  RISCV_SEXTH  <-> "sext.h",
  RISCV_ZEXTH  <-> "zext.h"
}

mapping clause assembly = BEXTOP(rs1, rd, op)
  <-> bextop_mnemonic(op) ^ spc() ^ reg_name(rd) ^ sep() ^ reg_name(rs1)
  
/* ****************************************************************** */
union clause ast = RISCV_REV8 : (regidx, regidx)     

mapping clause encdec = RISCV_REV8(rs1, rd)   <-> 0b011010011000 @ rs1 @ 0b101 @ rd @ 0b0010011 if sizeof(xlen) == 32
mapping clause encdec = RISCV_REV8(rs1, rd)   <-> 0b011010111000 @ rs1 @ 0b101 @ rd @ 0b0010011 if sizeof(xlen) == 64

function clause execute (RISCV_REV8(rs1, rd)) = {
  let rs1_val = X(rs1);
  let result : xlenbits = match sizeof(xlen) {
    32  => ( (rs1_val & 0xff000000) >> 24) | ( (rs1_val & 0x00ff0000) >>  8 ) | 
           ( (rs1_val & 0x0000ff00) <<  8) | ( (rs1_val & 0x000000ff) << 24 ),
    64  => ( (rs1_val & 0xff00000000000000) >> 56) | ( (rs1_val & 0x00ff000000000000) >> 40) | 
           ( (rs1_val & 0x0000ff0000000000) >> 24) | ( (rs1_val & 0x000000ff00000000) >> 8 ) |
           ( (rs1_val & 0x00000000ff000000) << 8 ) | ( (rs1_val & 0x0000000000ff0000) << 24) | 
           ( (rs1_val & 0x000000000000ff00) << 40) | ( (rs1_val & 0x00000000000000ff) << 56)
  };
  
  X(rd) = result;
  RETIRE_SUCCESS
}

mapping clause assembly = RISCV_REV8(rs1, rd)
  <-> "rev8" ^ spc() ^ reg_name(rd) ^ sep() ^ reg_name(rs1)
  
/* ****************************************************************** */
union clause ast = RISCV_ORCB : (regidx, regidx)

mapping clause encdec = RISCV_ORCB(rs1, rd)   <-> 0b001010000111 @ rs1 @ 0b101 @ rd @ 0b0010011

function clause execute (RISCV_ORCB(rs1, rd)) = {
  rs1_val = X(rs1);
  result : xlenbits = EXTZ(0x0);
  foreach (i from 0 to (xlen_val - 8) by 8) {
      result[7..0] = match sizeof(xlen) {
        32  => if (rs1_val[31..24] == 0x00)
               then 0x00
               else 0xFF,
        64  => if (rs1_val[63..56] == 0x00)
               then 0x00
               else 0xFF
      };
      result  = if (i < (xlen_val - 8))
                then result << 8
                else result;
      rs1_val = if (i < (xlen_val - 8))
                then rs1_val << 8
                else rs1_val;
  };
  
  X(rd) = result;
  RETIRE_SUCCESS
}

mapping clause assembly = RISCV_ORCB(rs1, rd)
  <-> "orc.b" ^ spc() ^ reg_name(rd) ^ sep() ^ reg_name(rs1)
  
/* ****************************************************************** */
union clause ast = RISCV_CPOP : (regidx, regidx)

mapping clause encdec = RISCV_CPOP(rs1, rd)   <-> 0b011000000010 @ rs1 @ 0b001 @ rd @ 0b0010011

function clause execute (RISCV_CPOP(rs1, rd)) = {
  let rs1_val = X(rs1);
  result : xlenbits = EXTZ(0x0);
  foreach (i from 0 to (xlen_val - 1) by 1) {
    result = if (rs1_val[i] == bitone)
               then result + EXTZ(0b1)
               else result;
  };
  
  X(rd) = result;
  RETIRE_SUCCESS
}

mapping clause assembly = RISCV_CPOP(rs1, rd)
  <-> "cpop" ^ spc() ^ reg_name(rd) ^ sep() ^ reg_name(rs1)
  
/* ****************************************************************** */
union clause ast = RISCV_CPOPW : (regidx, regidx)

mapping clause encdec = RISCV_CPOPW(rs1, rd) 
      if sizeof(xlen) == 64 
  <-> 0b011000000010 @ rs1 @ 0b001 @ rd @ 0b0011011 
      if sizeof(xlen) == 64

function clause execute (RISCV_CPOPW(rs1, rd)) = {
  let rs1_val = X(rs1);
  result : xlenbits = EXTZ(0x0);
  foreach (i from 0 to 31 by 1) {
    result = if (rs1_val[i] == bitone)
               then result + EXTZ(0b1)
               else result;
  };
  
  X(rd) = result;
  RETIRE_SUCCESS
}

mapping clause assembly = RISCV_CPOPW(rs1, rd)
      if sizeof(xlen) == 64
  <-> "cpopw" ^ spc() ^ reg_name(rd) ^ sep() ^ reg_name(rs1)
      if sizeof(xlen) == 64
/* ****************************************************************** */
union clause ast = RISCV_CLZ : (regidx, regidx)

mapping clause encdec = RISCV_CLZ(rs1, rd)   <-> 0b011000000000 @ rs1 @ 0b001 @ rd @ 0b0010011

function clause execute (RISCV_CLZ(rs1, rd)) = {
  let rs1_val = X(rs1);
  result : xlenbits = EXTZ(0x0);
  done : bits(1) = 0b0;
  msb : xlenbits = (EXTZ(0b1) << (xlen_val - 1));
  foreach (i from 0 to (xlen_val - 1) by 1) {
       if (((rs1_val << i) & msb) != msb) & (done == 0b0)
       then result = result + EXTZ(0b1)
       else done = 0b1;
  };
  
  X(rd) = result;
  RETIRE_SUCCESS
}

mapping clause assembly = RISCV_CLZ(rs1, rd)
  <-> "clz" ^ spc() ^ reg_name(rd) ^ sep() ^ reg_name(rs1)
  
/* ****************************************************************** */
union clause ast = RISCV_CLZW : (regidx, regidx)

mapping clause encdec = RISCV_CLZW(rs1, rd) 
      if sizeof(xlen) == 64  
  <-> 0b011000000000 @ rs1 @ 0b001 @ rd @ 0b0011011 
      if sizeof(xlen) == 64

function clause execute (RISCV_CLZW(rs1, rd)) = {
  let rs1_val = X(rs1);
  result : xlenbits = EXTZ(0x0);
  done : bits(1) = 0b0;
  msb : bits(32) = (EXTZ(0b1) << 31);
  foreach (i from 0 to 31 by 1) {
       if (((rs1_val[31..0] << i) & msb) != msb) & (done == 0b0)
       then result = result + EXTZ(0b1)
       else done = 0b1;
  };
  
  X(rd) = result;
  RETIRE_SUCCESS
}

mapping clause assembly = RISCV_CLZW(rs1, rd)
      if sizeof(xlen) == 64
  <-> "clzw" ^ spc() ^ reg_name(rd) ^ sep() ^ reg_name(rs1)
      if sizeof(xlen) == 64
      
/* ****************************************************************** */
union clause ast = RISCV_CTZ : (regidx, regidx) 

mapping clause encdec = RISCV_CTZ(rs1, rd)   <-> 0b011000000001 @ rs1 @ 0b001 @ rd @ 0b0010011

function clause execute (RISCV_CTZ(rs1, rd)) = {
  let rs1_val = X(rs1);
  result : xlenbits = EXTZ(0x0);
  done : bits(1) = 0b0;
  foreach (i from 0 to (xlen_val - 1) by 1) {
       if ((rs1_val >> i)[0] != bitone) & (done == 0b0)
       then result = result + EXTZ(0b1)
       else done = 0b1;
  };
  
  X(rd) = result;
  RETIRE_SUCCESS
}

mapping clause assembly = RISCV_CTZ(rs1, rd)
  <-> "ctz" ^ spc() ^ reg_name(rd) ^ sep() ^ reg_name(rs1)
  
/* ****************************************************************** */
union clause ast = RISCV_CTZW : (regidx, regidx)

mapping clause encdec = RISCV_CTZW(rs1, rd) 
      if sizeof(xlen) == 64  
  <-> 0b011000000001 @ rs1 @ 0b001 @ rd @ 0b0011011 
      if sizeof(xlen) == 64

function clause execute (RISCV_CTZW(rs1, rd)) = {
  let rs1_val = X(rs1);
  result : xlenbits = EXTZ(0x0);
  done : bits(1) = 0b0;
  foreach (i from 0 to 31 by 1) {
       if ((rs1_val[31..0] >> i)[0] != bitone) & (done == 0b0)
       then result = result + EXTZ(0b1)
       else done = 0b1;
  };
  
  X(rd) = result;
  RETIRE_SUCCESS
}

mapping clause assembly = RISCV_CTZW(rs1, rd)
      if sizeof(xlen) == 64
  <-> "ctzw" ^ spc() ^ reg_name(rd) ^ sep() ^ reg_name(rs1)
      if sizeof(xlen) == 64
