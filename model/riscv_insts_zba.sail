/* ****************************************************************** */
/* This file specifies the instructions in the BitManip Zba extension */


/* ****************************************************************** */
union clause ast = RISCV_SLLIUW : (bits(6), regidx, regidx)

mapping clause encdec = RISCV_SLLIUW(shamt, rs1, rd) if haveZba() & sizeof(xlen) == 64
  <-> 0b000010 @ shamt @ rs1 @ 0b001 @ rd @ 0b0011011

mapping clause assembly = RISCV_SLLIUW(shamt, rs1, rd)
  <-> "slli.uw" ^ spc() ^ reg_name(rd) ^ sep() ^ reg_name(rs1) ^ sep() ^ hex_bits_6(shamt)

function clause execute (RISCV_SLLIUW(shamt, rs1, rd)) = {
  let rs1_val = X(rs1);
  let result : xlenbits = EXTZ(rs1_val[31..0]) << shamt;
  X(rd) = result;
  RETIRE_SUCCESS
}

/* ****************************************************************** */
union clause ast = ZBA_RTYPEW : (regidx, regidx, regidx, bropw)

mapping clause encdec = ZBA_RTYPEW(rs2, rs1, rd, RISCV_ADDUW) if haveZba() & sizeof(xlen) == 64
  <-> 0b0000100 @ rs2 @ rs1 @ 0b000 @ rd @ 0b0111011

mapping clause encdec = ZBA_RTYPEW(rs2, rs1, rd, RISCV_SH1ADDUW) if haveZba() & sizeof(xlen) == 64
  <-> 0b0010000 @ rs2 @ rs1 @ 0b010 @ rd @ 0b0111011

mapping clause encdec = ZBA_RTYPEW(rs2, rs1, rd, RISCV_SH2ADDUW) if haveZba() & sizeof(xlen) == 64
  <-> 0b0010000 @ rs2 @ rs1 @ 0b100 @ rd @ 0b0111011

mapping clause encdec = ZBA_RTYPEW(rs2, rs1, rd, RISCV_SH3ADDUW) if haveZba() & sizeof(xlen) == 64
  <-> 0b0010000 @ rs2 @ rs1 @ 0b110 @ rd @ 0b0111011

mapping zba_rtypew_mnemonic : bropw <-> string = {
  RISCV_ADDUW    <-> "add.uw",
  RISCV_SH1ADDUW <-> "sh1add.uw",
  RISCV_SH2ADDUW <-> "sh2add.uw",
  RISCV_SH3ADDUW <-> "sh3add.uw"
}

mapping clause assembly = ZBA_RTYPEW(rs2, rs1, rd, op)
  <-> zba_rtypew_mnemonic(op) ^ spc() ^ reg_name(rd) ^ sep() ^ reg_name(rs1) ^ sep() ^ reg_name(rs2)

function clause execute (ZBA_RTYPEW(rs2, rs1, rd, op)) = {
  let rs1_val = X(rs1);
  let rs2_val = X(rs2);
  let result : xlenbits = match op {
    RISCV_ADDUW    => EXTZ(rs1_val[31..0]) + rs2_val,
    RISCV_SH1ADDUW => (EXTZ(rs1_val[31..0]) << 1) + rs2_val,
    RISCV_SH2ADDUW => (EXTZ(rs1_val[31..0]) << 2) + rs2_val,
    RISCV_SH3ADDUW => (EXTZ(rs1_val[31..0]) << 3) + rs2_val
  };
  X(rd) = EXTS(result);
  RETIRE_SUCCESS
}

/* ****************************************************************** */
union clause ast = ZBA_RTYPE : (regidx, regidx, regidx, brop)

mapping clause encdec = ZBA_RTYPE(rs2, rs1, rd, RISCV_SH1ADD) if haveZba()
  <-> 0b0010000 @ rs2 @ rs1 @ 0b010 @ rd @ 0b0110011
mapping clause encdec = ZBA_RTYPE(rs2, rs1, rd, RISCV_SH2ADD) if haveZba()
  <-> 0b0010000 @ rs2 @ rs1 @ 0b100 @ rd @ 0b0110011
mapping clause encdec = ZBA_RTYPE(rs2, rs1, rd, RISCV_SH3ADD) if haveZba()
  <-> 0b0010000 @ rs2 @ rs1 @ 0b110 @ rd @ 0b0110011

mapping zba_rtype_mnemonic : brop <-> string = {
  RISCV_SH1ADD <-> "sh1add",
  RISCV_SH2ADD <-> "sh2add",
  RISCV_SH3ADD <-> "sh3add"
}

mapping clause assembly = ZBA_RTYPE(rs2, rs1, rd, op)
  <-> zba_rtype_mnemonic(op) ^ spc() ^ reg_name(rd) ^ sep() ^ reg_name(rs1) ^ sep() ^ reg_name(rs2)

function clause execute (ZBA_RTYPE(rs2, rs1, rd, op)) = {
  let rs1_val = X(rs1);
  let rs2_val = X(rs2);
  let result : xlenbits = match op {
    RISCV_SH1ADD => rs2_val + (rs1_val << 1),
    RISCV_SH2ADD => rs2_val + (rs1_val << 2),
    RISCV_SH3ADD => rs2_val + (rs1_val << 3)
  };
  X(rd) = result;
  RETIRE_SUCCESS
}
